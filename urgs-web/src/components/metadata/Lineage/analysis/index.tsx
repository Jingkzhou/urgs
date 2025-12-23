import React, { useState, useEffect, useMemo } from 'react';
import { Layout, Input, Button, message, Empty, Spin, Tag, Badge, Pagination, Tooltip } from 'antd';
import { SearchOutlined, TableOutlined, RightOutlined, DownOutlined, FileTextOutlined, DownloadOutlined } from '@ant-design/icons';
import { getLineageGraph, searchTables, exportLineage } from '@/api/lineage';
import LineageDiagram from './components/LineageDiagram';
import LineageReportModal from './components/LineageReportModal';
import { NodeData, LinkData, ViewportState } from './types';
import dagre from 'dagre';
import { NODE_HEADER_HEIGHT, COLUMN_ROW_HEIGHT } from './constants';

const { Sider, Content } = Layout;

interface LineagePageProps {
    mode?: 'trace' | 'impact';
}

const LineagePage: React.FC<LineagePageProps> = ({ mode = 'impact' }) => {
    const [searchText, setSearchText] = useState('');
    const [searchResults, setSearchResults] = useState<any[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(20);
    const [total, setTotal] = useState(0);
    const [selectedTable, setSelectedTable] = useState<string | null>(null); // Add state for main table
    const [selectedField, setSelectedField] = useState<{ nodeId: string, colId: string } | null>(null); // Lifted state for field selection
    const [nodes, setNodes] = useState<NodeData[]>([]);
    const [links, setLinks] = useState<LinkData[]>([]);
    const [viewport, setViewport] = useState<ViewportState>({ x: 0, y: 0, zoom: 0.85 });
    const [loading, setLoading] = useState(false);
    const [graphLoading, setGraphLoading] = useState(false);
    const [expandedTables, setExpandedTables] = useState<Set<string>>(new Set());
    const [showReportModal, setShowReportModal] = useState(false);

    const toggleTableExpand = (tableName: string) => {
        setExpandedTables(prev => {
            const next = new Set(prev);
            if (next.has(tableName)) {
                next.delete(tableName);
            } else {
                next.add(tableName);
            }
            return next;
        });
    };

    // Load default tables on mount
    useEffect(() => {
        handleSearch();
    }, []);

    const handleSearch = async (page: number = 1) => {
        setLoading(true);
        try {
            const res: any = await searchTables(searchText, page, pageSize);
            if (res && res.list) {
                setSearchResults(res.list);
                setTotal(res.total || 0);
                setCurrentPage(page);
            } else {
                setSearchResults([]);
                setTotal(0);
                if (searchText.trim()) {
                    message.info('未找到相关表');
                }
            }
        } catch (error: any) {
            console.error(error);
            message.error(`查询失败: ${error.message || '未知错误'}`);
        } finally {
            setLoading(false);
        }
    };

    const handleSelectTable = async (tableName: string, targetColName?: string) => {
        setGraphLoading(true);
        setSelectedTable(tableName); // Set selected table
        try {
            const res = await getLineageGraph(tableName, targetColName);
            if (res) {
                if (res.nodes && res.nodes.length === 0) {
                    message.info('未找到血缘信息');
                    setNodes([]);
                    setLinks([]);
                } else {
                    // Pass the main table name to keep it expanded
                    const { layoutedNodes, layoutedLinks } = processLayout(res.nodes, res.edges, tableName);
                    setNodes(layoutedNodes);
                    setLinks(layoutedLinks);
                    setViewport({ x: 100, y: 100, zoom: 0.85 });

                    // Default to select column if requested
                    if (targetColName) {
                        const tableNode = layoutedNodes.find(n => n.title === tableName);
                        if (tableNode) {
                            const col = tableNode.columns.find(c => c.name === targetColName);
                            if (col) {
                                setSelectedField({ nodeId: tableNode.id, colId: col.id });
                            }
                        }
                    } else {
                        setSelectedField(null);
                    }
                }
            }
        } catch (error: any) {
            console.error(error);
            message.error(`加载血缘失败: ${error.message}`);
        } finally {
            setGraphLoading(false);
        }
    };

    const handleExport = async (tableName: string, e: React.MouseEvent, columnName?: string) => {
        e.stopPropagation();
        try {
            message.loading({ content: '正在导出...', key: 'export' });
            const blob = await exportLineage(tableName, columnName);
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            let filename = `${tableName}`;
            if (columnName) {
                filename += `_${columnName}`;
            }
            filename += `_血缘导出.xlsx`;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
            message.success({ content: '导出成功', key: 'export' });
        } catch (error) {
            console.error(error);
            message.error({ content: '导出失败', key: 'export' });
        }
    };

    const processLayout = (rawNodes: any[], rawEdges: any[], mainTableName: string) => {
        console.log('========== 血缘数据调试 ==========');
        console.log('原始节点数量:', rawNodes.length);
        console.log('原始边数量:', rawEdges.length);

        // === 下游过滤：只保留从主表出发的下游依赖 ===
        // 1. 建立节点ID映射和表名归属
        const nodeIdToInfo = new Map<string, { type: 'Table' | 'Column', tableName: string }>();
        rawNodes.forEach(n => {
            if (n.labels.includes('Table')) {
                nodeIdToInfo.set(n.id, { type: 'Table', tableName: n.properties.name });
            } else if (n.labels.includes('Column')) {
                nodeIdToInfo.set(n.id, { type: 'Column', tableName: n.properties.table || '' });
            }
        });

        // 2. 建立边的 source -> edges 索引（排除 BELONGS_TO）
        const edgesBySource = new Map<string, any[]>();
        rawEdges.forEach(e => {
            if (e.type !== 'BELONGS_TO') {
                const list = edgesBySource.get(e.source) || [];
                list.push(e);
                edgesBySource.set(e.source, list);
            }
        });

        // 3. BFS 从主表出发收集所有下游节点和边
        const downstreamNodeIds = new Set<string>();
        const downstreamEdges: any[] = [];
        const processedSources = new Set<string>();

        // 找到主表相关的所有起始节点（主表本身和其字段）
        const startNodeIds: string[] = [];
        rawNodes.forEach(n => {
            const info = nodeIdToInfo.get(n.id);
            if (info && info.tableName.toLowerCase() === mainTableName.toLowerCase()) {
                startNodeIds.push(n.id);
                downstreamNodeIds.add(n.id);
            }
        });

        const queue = [...startNodeIds];
        while (queue.length > 0) {
            const currentId = queue.shift()!;
            if (processedSources.has(currentId)) continue;
            processedSources.add(currentId);

            const outEdges = edgesBySource.get(currentId) || [];
            for (const edge of outEdges) {
                downstreamEdges.push(edge);
                downstreamNodeIds.add(edge.target);
                if (!processedSources.has(edge.target)) {
                    queue.push(edge.target);
                }
            }
        }

        // 4. 过滤节点：只保留下游节点 + BELONGS_TO 的相关表
        const filteredNodes = rawNodes.filter(n => downstreamNodeIds.has(n.id));

        // 5. 保留 BELONGS_TO 边（用于字段归属关系）
        const belongsToEdges = rawEdges.filter(e => e.type === 'BELONGS_TO' && downstreamNodeIds.has(e.source));
        const filteredEdges = [...downstreamEdges, ...belongsToEdges];

        console.log('过滤后节点数量:', filteredNodes.length);
        console.log('过滤后边数量:', filteredEdges.length);

        // === 使用过滤后的数据继续处理 ===
        const processedNodes = filteredNodes;
        const processedEdges = filteredEdges;

        // 统计边类型
        const edgeTypeCount: Record<string, number> = {};
        processedEdges.forEach(e => {
            edgeTypeCount[e.type] = (edgeTypeCount[e.type] || 0) + 1;
        });
        console.log('边类型分布:', edgeTypeCount);

        // 打印所有非 BELONGS_TO 的边详情
        const lineageEdges = processedEdges.filter(e => e.type !== 'BELONGS_TO');
        console.log('血缘边详情 (非BELONGS_TO):', lineageEdges.map(e => ({
            id: e.id,
            type: e.type,
            source: e.source,
            target: e.target,
            properties: e.properties
        })));

        const dagreGraph = new dagre.graphlib.Graph();

        // 动态计算布局参数：根据表格数量自动调整间距
        const tableNodeCount = processedNodes.filter(n => n.labels.includes('Table')).length;

        // 自动紧凑布局：节点少时间距小，节点多时适当放宽
        let nodeSep = 20;  // 默认紧凑的垂直间距
        let rankSep = 50;  // 默认紧凑的水平间距

        if (tableNodeCount > 15) {
            nodeSep = 30;
            rankSep = 70;
        } else if (tableNodeCount > 30) {
            nodeSep = 40;
            rankSep = 90;
        }

        dagreGraph.setGraph({ rankdir: 'LR', nodesep: nodeSep, ranksep: rankSep });
        dagreGraph.setDefaultEdgeLabel(() => ({}));

        const nodeMap = new Map<string, any>();
        const tableMap = new Map<string, NodeData>(); // Key: Table Name
        const tableIdMap = new Map<string, NodeData>(); // Key: Table Element ID

        // Helper to find table node for a column
        const colToTableId = new Map<string, string>(); // Col ElementID -> Table ElementID
        const uniqueLinkSet = new Set<string>(); // Track unique table-table pairs for deduplication

        // 0. Pre-process edges
        processedEdges.forEach(e => {
            if (e.type === 'BELONGS_TO') {
                // Assuming (Column)-[:BELONGS_TO]->(Table) direction based on typical Neo4j modeling
                // Or (Table)<-[:BELONGS_TO]-(c:Column)
                // In our query: (t:Table)<-[:BELONGS_TO]-(c:Column)
                // Neo4j driver returns relationships with start/end IDs.
                // Start = Column, End = Table.
                colToTableId.set(e.source, e.target);
            }
            // Lineage edges don't need tracking for filtering anymore as backend handles it
        });

        // 1. Pass 1: Create Table Nodes
        processedNodes.forEach(n => {
            nodeMap.set(n.id, n);
            if (n.labels.includes('Table')) {
                const tableName = n.properties.name;
                if (!tableMap.has(tableName)) {
                    const tableNode: NodeData = {
                        id: tableName, // Use name as ID for standard consistency
                        x: 0, y: 0, width: 220,
                        type: 'default',
                        title: tableName,
                        columns: [],
                        isCollapsed: true // Default collapsed as per user request to hide fields
                    };
                    tableMap.set(tableName, tableNode);
                    tableIdMap.set(n.id, tableNode);
                } else {
                    // Map existing (if dupe?)
                    tableIdMap.set(n.id, tableMap.get(tableName)!);
                }
            }
        });

        // 2. Pass 2: Process Columns and assign to Tables
        processedNodes.forEach(n => {
            if (n.labels.includes('Column')) {
                // Trust Backend: Include all columns returned by API


                let tableNode: NodeData | undefined;

                // Strategy A: Use BELONGS_TO edge
                const parentTableId = colToTableId.get(n.id);
                if (parentTableId) {
                    tableNode = tableIdMap.get(parentTableId);
                }

                // Strategy B: Use 'table' property fallback
                if (!tableNode && n.properties.table) {
                    tableNode = tableMap.get(n.properties.table);
                    // If table exists by name but wasn't in the graph nodes list?
                    // We might need to create it strictly speaking, but usually graph data should be complete.
                    if (!tableNode) {
                        // Create placeholder table if missing?
                        const tableName = n.properties.table;
                        tableNode = {
                            id: tableName,
                            x: 0, y: 0, width: 220,
                            type: 'default',
                            title: tableName,
                            columns: [],
                            isCollapsed: true // Default collapsed
                        };
                        tableMap.set(tableName, tableNode);
                        // We don't have element ID for this shadow table, so can't update tableIdMap
                    }
                }

                if (tableNode) {
                    // Add column if not exists
                    if (!tableNode.columns.find(c => c.id === n.id)) {
                        tableNode.columns.push({ id: n.id, name: n.properties.name });
                    }
                }
            }
        });

        const links: LinkData[] = [];
        // 3. Process Lineage Edges (DERIVES_TO, etc)
        processedEdges.forEach(e => {
            if (e.type === 'BELONGS_TO') return; // Skip structure edges

            const sourceNode = nodeMap.get(e.source);
            const targetNode = nodeMap.get(e.target);

            if (!sourceNode || !targetNode) return;

            let sourceTable: NodeData | undefined, targetTable: NodeData | undefined, sourceColId: string | undefined, targetColId: string | undefined;

            // Resolve Source
            if (sourceNode.labels.includes('Column')) {
                // Find parent table
                const pid = colToTableId.get(sourceNode.id);
                if (pid) sourceTable = tableIdMap.get(pid);
                if (!sourceTable && sourceNode.properties.table) sourceTable = tableMap.get(sourceNode.properties.table);

                sourceColId = sourceNode.id;
            } else if (sourceNode.labels.includes('Table')) {
                sourceTable = tableIdMap.get(sourceNode.id);
                sourceColId = '';
            }

            // Resolve Target
            if (targetNode.labels.includes('Column')) {
                const pid = colToTableId.get(targetNode.id);
                if (pid) targetTable = tableIdMap.get(pid);
                if (!targetTable && targetNode.properties.table) targetTable = tableMap.get(targetNode.properties.table);

                targetColId = targetNode.id;
            } else if (targetNode.labels.includes('Table')) {
                targetTable = tableIdMap.get(targetNode.id);
                targetColId = '';
            }

            // 对于 DERIVES_TO 关系：仅显示列到列的连接
            // 对于其他关系类型（FILTERS, JOINS 等）：允许源列到目标表的连接
            const isDirectLineage = e.type === 'DERIVES_TO' || e.type === 'CASE_WHEN';

            if (isDirectLineage) {
                // 直接数据流需要有明确的源列和目标列
                if (!sourceColId || !targetColId) return;
            } else {
                // 间接依赖只需要有源列，目标可以是表级别
                if (!sourceColId) return;
            }

            if (sourceTable && targetTable && sourceTable.id !== targetTable.id) {
                const linkId = `${sourceTable.id}::${targetTable.id}`;

                // Deduplicate for Layout Graph only
                if (!uniqueLinkSet.has(linkId)) {
                    uniqueLinkSet.add(linkId);
                    dagreGraph.setEdge(sourceTable.id, targetTable.id);
                }

                links.push({
                    id: e.id,
                    sourceNodeId: sourceTable.id,
                    sourceColumnId: sourceColId || '',
                    targetNodeId: targetTable.id,
                    targetColumnId: targetColId || '',  // 对于间接依赖可能为空
                    type: e.type,  // 保留关系类型 (DERIVES_TO, FILTERS, JOINS 等)
                    properties: e.properties  // 保留关系属性 (version, sourceFile 等)
                });
            }
        });

        // 3. Set Nodes in Dagre - 始终使用展开高度进行布局，避免折叠/展开切换导致重叠
        tableMap.forEach(node => {
            // Always use expanded height for layout calculation to prevent visual overlap
            const height = NODE_HEADER_HEIGHT + (node.columns.length * COLUMN_ROW_HEIGHT) + 20; // Full expanded height
            dagreGraph.setNode(node.id, { width: node.width, height });
        });

        // 4. Run Layout
        dagre.layout(dagreGraph);

        // 5. 过滤孤立节点和旁支节点：只保留主表的直系亲属 (Ancestors + Descendants)
        // Siblings (Parents' other children) and Spouses (Children's other parents) should be excluded.
        // Unless they are also ancestors or descendants via another path.

        const validNodeIds = new Set<string>();
        validNodeIds.add(mainTableName);

        // Build adjacency list for graph traversal
        const upstreamAdjacency = new Map<string, string[]>(); // Target -> Sources
        const downstreamAdjacency = new Map<string, string[]>(); // Source -> Targets

        links.forEach(l => {
            // Upstream: Target depends on Source
            if (!upstreamAdjacency.has(l.targetNodeId)) upstreamAdjacency.set(l.targetNodeId, []);
            upstreamAdjacency.get(l.targetNodeId)?.push(l.sourceNodeId);

            // Downstream: Source derives to Target
            if (!downstreamAdjacency.has(l.sourceNodeId)) downstreamAdjacency.set(l.sourceNodeId, []);
            downstreamAdjacency.get(l.sourceNodeId)?.push(l.targetNodeId);
        });

        // Traverse Upstream (Find Ancestors)
        const qUp = [mainTableName];
        const visitedUp = new Set<string>([mainTableName]);
        while (qUp.length > 0) {
            const curr = qUp.shift()!;
            const parents = upstreamAdjacency.get(curr) || [];
            parents.forEach(p => {
                if (!visitedUp.has(p)) {
                    visitedUp.add(p);
                    validNodeIds.add(p);
                    qUp.push(p);
                }
            });
        }

        // Traverse Downstream (Find Descendants)
        const qDown = [mainTableName];
        const visitedDown = new Set<string>([mainTableName]);
        while (qDown.length > 0) {
            const curr = qDown.shift()!;
            const children = downstreamAdjacency.get(curr) || [];
            children.forEach(c => {
                if (!visitedDown.has(c)) {
                    visitedDown.add(c);
                    validNodeIds.add(c);
                    qDown.push(c);
                }
            });
        }

        // 6. Apply positions (只处理有效的节点)
        const layoutedNodes: NodeData[] = [];
        tableMap.forEach(node => {
            // 过滤掉不在直系血缘上的节点
            if (!validNodeIds.has(node.id)) {
                return;
            }
            const dagreNode = dagreGraph.node(node.id);
            if (dagreNode) {
                node.x = dagreNode.x - node.width / 2;
                node.y = dagreNode.y - dagreNode.height / 2;
                layoutedNodes.push(node);
            }
        });

        // 7. Filter links to only show connections between valid nodes
        const filteredLinks = links.filter(l =>
            validNodeIds.has(l.sourceNodeId) && validNodeIds.has(l.targetNodeId)
        );

        // 打印最终生成的 links 信息
        console.log('========== 最终链接数据 ==========');
        console.log('生成的 links 数量:', links.length);
        const linkTypeCount: Record<string, number> = {};
        links.forEach(l => {
            linkTypeCount[l.type] = (linkTypeCount[l.type] || 0) + 1;
        });
        console.log('链接类型分布:', linkTypeCount);
        console.log('链接详情:', links.map(l => ({
            sourceNode: l.sourceNodeId,
            sourceCol: l.sourceColumnId,
            targetNode: l.targetNodeId,
            targetCol: l.targetColumnId,
            type: l.type
        })));
        console.log('===================================');

        return { layoutedNodes, layoutedLinks: filteredLinks };
    };

    return (
        <Layout style={{ height: 'calc(100vh - 100px)' }}>
            <Sider width={300} theme="light" style={{ borderRight: '1px solid #f0f0f0' }}>
                <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
                    <div style={{ padding: '16px', borderBottom: '1px solid #f0f0f0' }}>
                        <div style={{ marginBottom: 16 }}>
                            <h3>血缘搜索</h3>
                            <p style={{ color: '#888', fontSize: '12px' }}>输入表名查询上下游血缘关系</p>
                        </div>
                        <div style={{ display: 'flex', gap: '8px' }}>
                            <Input
                                placeholder="输入关键词"
                                value={searchText}
                                onChange={e => setSearchText(e.target.value)}
                                onPressEnter={() => handleSearch(1)}
                            />
                            <Button type="primary" icon={<SearchOutlined />} onClick={() => handleSearch(1)} loading={loading}>
                            </Button>
                        </div>
                    </div>
                    <div style={{ flex: 1, overflowY: 'auto', padding: '0' }}>
                        {(() => {
                            // 服务端分页，直接渲染列表
                            return [...searchResults]
                                .sort((a, b) => a.tableName.localeCompare(b.tableName))
                                .map((item: any) => (
                                    <div key={item.tableName} style={{ borderBottom: '1px solid #f5f5f5' }}>
                                        <div
                                            style={{
                                                padding: '12px 16px',
                                                display: 'flex',
                                                alignItems: 'center',
                                                gap: '8px'
                                            }}
                                        >
                                            <div
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    toggleTableExpand(item.tableName);
                                                }}
                                                style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', padding: '4px' }}
                                            >
                                                {expandedTables.has(item.tableName) ?
                                                    <DownOutlined style={{ fontSize: 10, color: '#666' }} /> :
                                                    <RightOutlined style={{ fontSize: 10, color: '#666' }} />
                                                }
                                            </div>
                                            <div
                                                onClick={() => handleSelectTable(item.tableName)}
                                                className="hover:text-blue-500 cursor-pointer transition-colors"
                                                style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: 1 }}
                                            >
                                                <TableOutlined style={{ color: '#1890ff' }} />
                                                <span style={{ fontWeight: 500 }}>{item.tableName}</span>
                                            </div>
                                            <Tooltip title="导出血缘 Excel">
                                                <Button
                                                    type="text"
                                                    size="small"
                                                    icon={<DownloadOutlined />}
                                                    onClick={(e) => handleExport(item.tableName, e)}
                                                />
                                            </Tooltip>
                                        </div>
                                        {expandedTables.has(item.tableName) && item.columns && item.columns.length > 0 && (
                                            <div style={{ padding: '0 16px 12px 36px', display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                                                {item.columns.map((col: string) => (
                                                    <Tag
                                                        key={col}
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            handleSelectTable(item.tableName, col);
                                                        }}
                                                        className="group hover:text-blue-500 hover:border-blue-500"
                                                        style={{
                                                            cursor: 'pointer',
                                                            margin: 0,
                                                            display: 'inline-flex',
                                                            alignItems: 'center',
                                                            gap: '4px',
                                                            // 高亮匹配的字段
                                                            ...(searchText && col.toLowerCase().includes(searchText.toLowerCase()) ? {
                                                                backgroundColor: '#e6f7ff',
                                                                borderColor: '#1890ff'
                                                            } : {})
                                                        }}
                                                    >
                                                        {col}
                                                        <Tooltip title="导出字段血缘">
                                                            <DownloadOutlined
                                                                className="opacity-0 group-hover:opacity-100 transition-opacity"
                                                                style={{ fontSize: '10px', color: '#666' }}
                                                                onClick={(e) => handleExport(item.tableName, e, col)}
                                                            />
                                                        </Tooltip>
                                                    </Tag>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                ));
                        })()}
                        {searchResults.length === 0 && !loading && (
                            <div style={{ padding: '24px 0' }}>
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无搜索结果" />
                            </div>
                        )}
                    </div>
                    <div style={{ padding: '8px 16px', borderTop: '1px solid #f0f0f0', textAlign: 'center' }}>
                        <Pagination
                            simple
                            size="small"
                            current={currentPage}
                            pageSize={pageSize}
                            total={total}
                            onChange={(page) => handleSearch(page)}
                        />
                    </div>
                </div>
            </Sider>
            <Content style={{ background: '#fff', position: 'relative' }}>
                <Spin spinning={graphLoading} tip="加载血缘关系...">
                    <div style={{ height: 'calc(100vh - 100px)', width: '100%' }}>
                        {nodes.length > 0 ? (
                            <LineageDiagram
                                viewport={viewport}
                                setViewport={setViewport}
                                nodes={nodes}
                                setNodes={setNodes}
                                links={links}
                                selectedTable={selectedTable}
                                selectedField={selectedField}
                                onFieldSelect={setSelectedField}
                                onGenerateReport={() => setShowReportModal(true)}
                            />
                        ) : (
                            !graphLoading && <Empty description="请从左侧选择表查看血缘" style={{ marginTop: '100px' }} />
                        )}
                    </div>
                </Spin>
            </Content>
            {/* AI 报告 Modal */}
            {showReportModal && selectedField && (
                <LineageReportModal
                    visible={showReportModal}
                    tableName={nodes.find(n => n.id === selectedField.nodeId)?.title || ''}
                    columnName={nodes.find(n => n.id === selectedField.nodeId)?.columns.find(c => c.id === selectedField.colId)?.name || ''}
                    onClose={() => setShowReportModal(false)}
                />
            )}
        </Layout>
    );
};

export default LineagePage;
