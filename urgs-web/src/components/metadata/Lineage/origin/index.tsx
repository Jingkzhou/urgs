import React, { useState, useEffect } from 'react';
import { Layout, Input, Button, message, Empty, Spin, Tag, Badge, Pagination } from 'antd';
import { SearchOutlined, TableOutlined, RightOutlined, DownOutlined } from '@ant-design/icons';
import { getLineageGraph, searchTables } from '@/api/lineage';
import LineageDiagram from './components/LineageDiagram';
import { NodeData, LinkData, ViewportState } from './types';
import dagre from 'dagre';
import { NODE_HEADER_HEIGHT, COLUMN_ROW_HEIGHT } from './constants';

const { Sider, Content } = Layout;

interface LineagePageProps {
    mode?: 'trace' | 'impact';
}

const LineagePage: React.FC<LineagePageProps> = ({ mode = 'trace' }) => {
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

    const processLayout = (rawNodes: any[], rawEdges: any[], mainTableName: string) => {
        const dagreGraph = new dagre.graphlib.Graph();
        dagreGraph.setGraph({ rankdir: 'LR', nodesep: 100, ranksep: 300 });
        dagreGraph.setDefaultEdgeLabel(() => ({}));

        const nodeMap = new Map<string, any>();
        const tableMap = new Map<string, NodeData>(); // Key: Table Name
        const tableIdMap = new Map<string, NodeData>(); // Key: Table Element ID

        // Helper to find table node for a column
        const colToTableId = new Map<string, string>(); // Col ElementID -> Table ElementID
        const uniqueLinkSet = new Set<string>(); // Track unique table-table pairs for deduplication

        // 0. Pre-process edges
        rawEdges.forEach(e => {
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
        rawNodes.forEach(n => {
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
                        isCollapsed: true // Default collapsed as per user request to hide fields on table click
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
        rawNodes.forEach(n => {
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
                            isCollapsed: false // Default open all
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
        rawEdges.forEach(e => {
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

            // Strict Rule: Only visualize Table-to-Table lineage once per pair.
            if (!sourceColId || !targetColId) return;

            if (sourceTable && targetTable && sourceTable.id !== targetTable.id) {
                const linkId = `${sourceTable.id}::${targetTable.id}`;

                // Deduplicate for Layout Graph only (Dagre)
                if (!uniqueLinkSet.has(linkId)) {
                    uniqueLinkSet.add(linkId);
                    dagreGraph.setEdge(sourceTable.id, targetTable.id);
                }

                // Pass ALL links to the diagram component so it has data for field tracing.
                // The diagram component will handle visual consolidation.
                links.push({
                    id: e.id,
                    sourceNodeId: sourceTable.id,
                    sourceColumnId: sourceColId || '',
                    targetNodeId: targetTable.id,
                    targetColumnId: targetColId || ''
                });
            }
        });

        // 3. Set Nodes in Dagre
        tableMap.forEach(node => {
            const height = node.isCollapsed
                ? NODE_HEADER_HEIGHT + 20 // Collapsed height + padding
                : NODE_HEADER_HEIGHT + (node.columns.length * COLUMN_ROW_HEIGHT) + 20; // Full height + padding
            dagreGraph.setNode(node.id, { width: node.width, height });
        });

        // 4. Run Layout
        dagre.layout(dagreGraph);

        // 5. 过滤孤立节点：只保留有连线的节点或主表本身
        const connectedNodeIds = new Set<string>();
        links.forEach(l => {
            connectedNodeIds.add(l.sourceNodeId);
            connectedNodeIds.add(l.targetNodeId);
        });
        // 主表始终保留
        connectedNodeIds.add(mainTableName);

        // 6. Apply positions (只处理有连线的节点)
        const layoutedNodes: NodeData[] = [];
        tableMap.forEach(node => {
            // 过滤掉没有连线的孤立节点
            if (!connectedNodeIds.has(node.id)) {
                return;
            }
            const dagreNode = dagreGraph.node(node.id);
            if (dagreNode) {
                node.x = dagreNode.x - node.width / 2;
                node.y = dagreNode.y - dagreNode.height / 2;
                layoutedNodes.push(node);
            }
        });

        return { layoutedNodes, layoutedLinks: links };
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
                                                        className="hover:text-blue-500 hover:border-blue-500"
                                                        style={{
                                                            cursor: 'pointer',
                                                            margin: 0,
                                                            // 高亮匹配的字段
                                                            ...(searchText && col.toLowerCase().includes(searchText.toLowerCase()) ? {
                                                                backgroundColor: '#e6f7ff',
                                                                borderColor: '#1890ff'
                                                            } : {})
                                                        }}
                                                    >
                                                        {col}
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
                    {/* 分页组件 */}
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
                            />
                        ) : (
                            !graphLoading && <Empty description="请从左侧选择表查看血缘" style={{ marginTop: '100px' }} />
                        )}
                    </div>
                </Spin>
            </Content>
        </Layout>
    );
};

export default LineagePage;
