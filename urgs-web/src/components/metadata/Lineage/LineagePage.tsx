import React, { useEffect, useRef, useState } from 'react';
import { Layout, Input, Button, Drawer, message, Empty, Tag, Pagination, Tooltip, Segmented } from 'antd';
import {
    SearchOutlined,
    TableOutlined,
    RightOutlined,
    DownOutlined,
    FileTextOutlined,
    DownloadOutlined,
    UserOutlined,
    RobotOutlined,
} from '@ant-design/icons';
import dagre from 'dagre';
import {
    getLineageGraph,
    searchTables,
    exportLineage,
    LineageSearchOwnerGroup,
    LineageSearchTableItem,
} from '@/api/lineage';
import LineageReportModal from './analysis/components/LineageReportModal';
import { NodeData, LinkData, ViewportState } from './analysis/types';
import { NODE_HEADER_HEIGHT, COLUMN_ROW_HEIGHT } from './analysis/constants';
import LineageGraphContent from './analysis/components/LineageGraphContent';
import LineageEngineToolbar from './analysis/components/LineageEngineToolbar';
import { useLineageEngineController } from './analysis/hooks/useLineageEngineController';
import { hasPermission } from '@/utils/permission';
import AICodeReport from '@/components/version/AICodeReport';

const { Sider, Content } = Layout;

interface LineagePageProps {
    mode?: 'trace' | 'impact';
}

const LineagePage: React.FC<LineagePageProps> = ({ mode = 'impact' }) => {
    const containerRef = useRef<HTMLDivElement>(null);
    const [searchText, setSearchText] = useState('');
    const [searchResults, setSearchResults] = useState<LineageSearchOwnerGroup[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(20);
    const [total, setTotal] = useState(0);
    const [totalOwners, setTotalOwners] = useState(0);
    const [selectedTable, setSelectedTable] = useState<string | null>(null);
    const [selectedQualifiedName, setSelectedQualifiedName] = useState<string | null>(null);
    const [selectedField, setSelectedField] = useState<{ nodeId: string, colId: string } | null>(null);
    const [nodes, setNodes] = useState<NodeData[]>([]);
    const [links, setLinks] = useState<LinkData[]>([]);
    const [viewport, setViewport] = useState<ViewportState>({ x: 0, y: 0, zoom: 0.85 });
    const [loading, setLoading] = useState(false);
    const [graphLoading, setGraphLoading] = useState(false);
    const [expandedTables, setExpandedTables] = useState<Set<string>>(new Set());
    const [expandedOwners, setExpandedOwners] = useState<Set<string>>(new Set());
    const [showReportModal, setShowReportModal] = useState(false);
    const [viewMode, setViewMode] = useState<'canvas' | 'list'>('list');
    const pageTitle = mode === 'trace' ? '血缘溯源' : '影响分析';
    const canExport = mode === 'impact';
    const canOpenAuditBoard = hasPermission('version:ai:audit');
    const engineController = useLineageEngineController();
    const [showAuditBoard, setShowAuditBoard] = useState(false);

    const toggleTableExpand = (qualifiedName: string) => {
        setExpandedTables(prev => {
            const next = new Set(prev);
            if (next.has(qualifiedName)) {
                next.delete(qualifiedName);
            } else {
                next.add(qualifiedName);
            }
            return next;
        });
    };

    const toggleOwnerExpand = (ownerName: string) => {
        setExpandedOwners(prev => {
            const next = new Set(prev);
            if (next.has(ownerName)) {
                next.delete(ownerName);
            } else {
                next.add(ownerName);
            }
            return next;
        });
    };

    useEffect(() => {
        handleSearch();
    }, []);


    const handleSearch = async (page: number = 1) => {
        setLoading(true);
        try {
            const res = await searchTables(searchText, page, pageSize);
            if (res && res.groupedList) {
                setSearchResults(res.groupedList);
                setTotal(res.total || 0);
                setTotalOwners(res.totalOwners || 0);
                setCurrentPage(page);
                setExpandedOwners(new Set((res.groupedList || []).map(group => group.ownerName)));
            } else {
                setSearchResults([]);
                setTotal(0);
                setTotalOwners(0);
                if (searchText.trim()) {
                    message.info('未找到相关表');
                }
            }
        } catch (error: any) {
            message.error(`查询失败: ${error.message || '未知错误'}`);
        } finally {
            setLoading(false);
        }
    };

    const handleSelectTable = async (tableName: string, qualifiedName?: string, targetColName?: string) => {
        setGraphLoading(true);
        setSelectedTable(tableName);
        setSelectedQualifiedName(qualifiedName || tableName);
        try {
            const res = await getLineageGraph(tableName, targetColName, -1, qualifiedName);
            if (res) {
                if (res.nodes && res.nodes.length === 0) {
                    message.info('未找到血缘信息');
                    setNodes([]);
                    setLinks([]);
                } else {
                    const layoutResult = mode === 'impact'
                        ? processLayoutImpact(res.nodes, res.edges, tableName)
                        : processLayoutTrace(res.nodes, res.edges, tableName);
                    setNodes(layoutResult.layoutedNodes);
                    setLinks(layoutResult.layoutedLinks);
                    setViewport({ x: 100, y: 100, zoom: 0.85 });

                    if (targetColName) {
                        const tableNode = layoutResult.layoutedNodes.find(n => n.title === tableName);
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
            message.error(`加载血缘失败: ${error.message}`);
        } finally {
            setGraphLoading(false);
        }
    };

    const handleExport = async (tableName: string, e: React.MouseEvent, columnName?: string, qualifiedName?: string) => {
        e.stopPropagation();
        if (!canExport) {
            return;
        }
        try {
            message.loading({ content: '正在导出...', key: 'export' });
            const blob = await exportLineage(tableName, columnName, qualifiedName);
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            let filename = `${qualifiedName || tableName}`;
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
            message.error({ content: '导出失败', key: 'export' });
        }
    };

    const processLayoutImpact = (rawNodes: any[], rawEdges: any[], mainTableName: string) => {
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

        // 3.5. [Fix] 补充下游字段所属的表节点
        // 遍历所有找到的 downstreamNodeIds，如果是 Column，找到其所属 Table 并加入
        // nodeIdToInfo 已经有映射关系，但这里我们需要确保 Table 节点本身也被加入
        const additionalTableIds = new Set<string>();
        downstreamNodeIds.forEach(nodeId => {
            const info = nodeIdToInfo.get(nodeId);
            if (info && info.type === 'Column') {
                // 找到该 Column 对应的 BELONGS_TO 边
                // 注意：BELONGS_TO 是从 Column -> Table
                const parentTableEdges = rawEdges.filter(e => e.type === 'BELONGS_TO' && e.source === nodeId);
                parentTableEdges.forEach(e => {
                    additionalTableIds.add(e.target);
                });
            }
        });
        additionalTableIds.forEach(id => downstreamNodeIds.add(id));

        // 4. 过滤节点：只保留下游节点 + BELONGS_TO 的相关表
        const filteredNodes = rawNodes.filter(n => downstreamNodeIds.has(n.id));

        // 5. 保留 BELONGS_TO 边（用于字段归属关系）
        const belongsToEdges = rawEdges.filter(e => e.type === 'BELONGS_TO' && downstreamNodeIds.has(e.source));
        const filteredEdges = [...downstreamEdges, ...belongsToEdges];

        // === 使用过滤后的数据继续处理 ===
        const processedNodes = filteredNodes;
        const processedEdges = filteredEdges;

        // 统计边类型
        const edgeTypeCount: Record<string, number> = {};
        processedEdges.forEach(e => {
            edgeTypeCount[e.type] = (edgeTypeCount[e.type] || 0) + 1;
        });

        // 打印所有非 BELONGS_TO 的边详情
        const lineageEdges = processedEdges.filter(e => e.type !== 'BELONGS_TO');

        const dagreGraph = new dagre.graphlib.Graph();
        dagreGraph.setGraph({ rankdir: 'LR', nodesep: 100, ranksep: 300 });
        dagreGraph.setDefaultEdgeLabel(() => ({}));

        const nodeMap = new Map<string, any>();
        const tableMap = new Map<string, NodeData>(); // Key: Table Name
        const tableIdMap = new Map<string, NodeData>(); // Key: Table Element ID

        // Helper to find table node for a column
        const colToTableId = new Map<string, string>(); // Col ElementID -> Table ElementID

        processedNodes.forEach(node => {
            if (node.labels.includes('Table')) {
                const tableName = node.properties.name;
                const tableId = node.id;
                const tableNode: NodeData = {
                    id: tableId,
                    type: 'default',
                    title: tableName,
                    columns: [],
                    x: 0,
                    y: 0,
                    width: 240,
                    isCollapsed: false
                };
                tableMap.set(tableName, tableNode);
                tableIdMap.set(tableId, tableNode);
            }
        });

        processedEdges.forEach(e => {
            if (e.type === 'BELONGS_TO') {
                // Assuming (Column)-[:BELONGS_TO]->(Table)
                const colId = e.source;
                const tableId = e.target;
                colToTableId.set(colId, tableId);
            }
        });

        processedNodes.forEach(node => {
            if (node.labels.includes('Column')) {
                const colId = node.id;
                const tableId = colToTableId.get(colId);
                if (tableId) {
                    const tableNode = tableIdMap.get(tableId);
                    if (tableNode) {
                        tableNode.columns.push({
                            id: colId,
                            name: node.properties.name
                        });
                    }
                }
            }
        });

        // Filter out empty tables and calculate table sizes
        tableMap.forEach((node, tableName) => {
            if (node.columns.length === 0) {
                tableMap.delete(tableName);
                return;
            }
            // Sort columns for consistency
            node.columns.sort((a, b) => a.name.localeCompare(b.name));
            node.width = 240;
        });

        // Create nodes for dagre
        tableMap.forEach(node => {
            const height = NODE_HEADER_HEIGHT + node.columns.length * COLUMN_ROW_HEIGHT;
            dagreGraph.setNode(node.id, { width: node.width, height });
            nodeMap.set(node.id, node);
        });

        // Create links from lineage edges (exclude BELONGS_TO)
        const links: LinkData[] = [];
        processedEdges.forEach(e => {
            if (e.type === 'BELONGS_TO') return;
            const sourceColId = e.source;
            const targetColId = e.target;
            const sourceTableId = colToTableId.get(sourceColId);
            const targetTableId = colToTableId.get(targetColId);
            if (!sourceTableId || !targetTableId) return;

            links.push({
                id: e.id,
                sourceNodeId: sourceTableId,
                sourceColumnId: sourceColId,
                targetNodeId: targetTableId,
                targetColumnId: targetColId,
                type: e.type,
                properties: e.properties
            });
            dagreGraph.setEdge(sourceTableId, targetTableId);
        });

        // Run layout
        dagre.layout(dagreGraph);

        // 过滤孤立节点和旁支节点：只保留主表的直系亲属 (Ancestors + Descendants)
        const lineageNodeIds = new Set<string>();
        const lineageQueue: string[] = [];
        const mainTableNode = [...tableMap.values()].find(n => n.title.toLowerCase() === mainTableName.toLowerCase());
        if (mainTableNode) {
            lineageQueue.push(mainTableNode.id);
            lineageNodeIds.add(mainTableNode.id);
        }

        const linkMapBySource = new Map<string, string[]>();
        const linkMapByTarget = new Map<string, string[]>();
        links.forEach(l => {
            const sourceList = linkMapBySource.get(l.sourceNodeId) || [];
            sourceList.push(l.targetNodeId);
            linkMapBySource.set(l.sourceNodeId, sourceList);
            const targetList = linkMapByTarget.get(l.targetNodeId) || [];
            targetList.push(l.sourceNodeId);
            linkMapByTarget.set(l.targetNodeId, targetList);
        });

        while (lineageQueue.length > 0) {
            const currentId = lineageQueue.shift()!;
            const downstream = linkMapBySource.get(currentId) || [];
            const upstream = linkMapByTarget.get(currentId) || [];
            [...downstream, ...upstream].forEach(nextId => {
                if (!lineageNodeIds.has(nextId)) {
                    lineageNodeIds.add(nextId);
                    lineageQueue.push(nextId);
                }
            });
        }

        const validNodeIds = new Set<string>(lineageNodeIds);

        // Apply positions (只处理有效的节点)
        const layoutedNodes: NodeData[] = [];
        tableMap.forEach(node => {
            if (!validNodeIds.has(node.id)) {
                return;
            }
            const dagreNode = dagreGraph.node(node.id);
            if (dagreNode) {
                node.x = dagreNode.x - node.width / 2;
                node.y = dagreNode.y - (NODE_HEADER_HEIGHT + node.columns.length * COLUMN_ROW_HEIGHT) / 2;
                layoutedNodes.push(node);
            }
        });

        const filteredLinks = links.filter(l =>
            validNodeIds.has(l.sourceNodeId) && validNodeIds.has(l.targetNodeId)
        );

        return { layoutedNodes, layoutedLinks: filteredLinks };
    };

    const processLayoutTrace = (rawNodes: any[], rawEdges: any[], mainTableName: string) => {
        const dagreGraph = new dagre.graphlib.Graph();
        dagreGraph.setGraph({ rankdir: 'LR', nodesep: 100, ranksep: 300 });
        dagreGraph.setDefaultEdgeLabel(() => ({}));

        const nodeMap = new Map<string, any>();
        const tableMap = new Map<string, NodeData>(); // Key: Table Name
        const tableIdMap = new Map<string, NodeData>(); // Key: Table Element ID

        // Helper to find table node for a column
        const colToTableId = new Map<string, string>(); // Col ElementID -> Table ElementID

        rawNodes.forEach(node => {
            if (node.labels.includes('Table')) {
                const tableName = node.properties.name;
                const tableId = node.id;
                const tableNode: NodeData = {
                    id: tableId,
                    type: 'default',
                    title: tableName,
                    columns: [],
                    x: 0,
                    y: 0,
                    width: 240,
                    isCollapsed: false
                };
                tableMap.set(tableName, tableNode);
                tableIdMap.set(tableId, tableNode);
            }
        });

        rawEdges.forEach(e => {
            if (e.type === 'BELONGS_TO') {
                // Assuming (Column)-[:BELONGS_TO]->(Table)
                const colId = e.source;
                const tableId = e.target;
                colToTableId.set(colId, tableId);
            }
        });

        rawNodes.forEach(node => {
            if (node.labels.includes('Column')) {
                const colId = node.id;
                const tableId = colToTableId.get(colId);
                if (tableId) {
                    const tableNode = tableIdMap.get(tableId);
                    if (tableNode) {
                        tableNode.columns.push({
                            id: colId,
                            name: node.properties.name
                        });
                    }
                }
            }
        });

        // Filter out empty tables and calculate table sizes
        tableMap.forEach((node, tableName) => {
            if (node.columns.length === 0) {
                tableMap.delete(tableName);
                return;
            }
            // Sort columns for consistency
            node.columns.sort((a, b) => a.name.localeCompare(b.name));
            node.width = 240;
        });

        // Create nodes for dagre
        tableMap.forEach(node => {
            const height = NODE_HEADER_HEIGHT + node.columns.length * COLUMN_ROW_HEIGHT;
            dagreGraph.setNode(node.id, { width: node.width, height });
            nodeMap.set(node.id, node);
        });

        // Create links from lineage edges (exclude BELONGS_TO)
        const links: LinkData[] = [];
        rawEdges.forEach(e => {
            if (e.type === 'BELONGS_TO') return;
            const sourceColId = e.source;
            const targetColId = e.target;
            const sourceTableId = colToTableId.get(sourceColId);
            const targetTableId = colToTableId.get(targetColId);
            if (!sourceTableId || !targetTableId) return;

            links.push({
                id: e.id,
                sourceNodeId: sourceTableId,
                sourceColumnId: sourceColId,
                targetNodeId: targetTableId,
                targetColumnId: targetColId,
                type: e.type,
                properties: e.properties
            });
            dagreGraph.setEdge(sourceTableId, targetTableId);
        });

        // Run layout
        dagre.layout(dagreGraph);

        // 过滤孤立节点：只保留有连线的节点或主表本身
        const validNodeIds = new Set<string>();
        links.forEach(l => {
            validNodeIds.add(l.sourceNodeId);
            validNodeIds.add(l.targetNodeId);
        });

        const mainTableNode = [...tableMap.values()].find(n => n.title.toLowerCase() === mainTableName.toLowerCase());
        if (mainTableNode) {
            validNodeIds.add(mainTableNode.id);
        }

        const layoutedNodes: NodeData[] = [];
        tableMap.forEach(node => {
            if (!validNodeIds.has(node.id)) {
                return;
            }
            const dagreNode = dagreGraph.node(node.id);
            if (dagreNode) {
                node.x = dagreNode.x - node.width / 2;
                node.y = dagreNode.y - (NODE_HEADER_HEIGHT + node.columns.length * COLUMN_ROW_HEIGHT) / 2;
                layoutedNodes.push(node);
            }
        });

        const filteredLinks = links.filter(l =>
            validNodeIds.has(l.sourceNodeId) && validNodeIds.has(l.targetNodeId)
        );

        return { layoutedNodes, layoutedLinks: filteredLinks };
    };

    return (
        <div
            ref={containerRef}
            style={{
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                minHeight: 0
            }}
        >
            <style>{`
                .ant-spin-nested-loading, .ant-spin-container {
                    height: 100% !important;
                }
            `}</style>
            <div style={{ padding: '12px 16px', borderBottom: '1px solid #f0f0f0', background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div>
                        <div style={{ fontSize: 14, fontWeight: 600, color: '#1f2937' }}>SQL Lineage</div>
                        <div style={{ fontSize: 12, color: '#8c8c8c' }}>{pageTitle}</div>
                    </div>
                    {selectedQualifiedName && <Tag color="blue">{selectedQualifiedName}</Tag>}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                    <Segmented
                        options={[
                            { label: '流程图', value: 'canvas', icon: <TableOutlined /> },
                            { label: '列表', value: 'list', icon: <FileTextOutlined /> },
                        ]}
                        value={viewMode}
                        onChange={(val: any) => setViewMode(val)}
                    />
                    <Button
                        icon={<RobotOutlined />}
                        disabled={!canOpenAuditBoard}
                        title={canOpenAuditBoard ? '在当前血缘页面打开 SQL 血缘事后校验看板' : '缺少 version:ai:audit 权限'}
                        onClick={() => setShowAuditBoard(true)}
                    >
                        打开事后校验
                    </Button>
                    <LineageEngineToolbar controller={engineController} />
                </div>
            </div>
            <Layout style={{ flex: 1, minHeight: 0 }}>
                <Sider width={300} theme="light" style={{ borderRight: '1px solid #f0f0f0' }}>

                    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
                        <div style={{ padding: '16px', borderBottom: '1px solid #f0f0f0' }}>
                            <div style={{ marginBottom: 16 }}>
                                <h3>血缘搜索</h3>
                                <p style={{ color: '#888', fontSize: '12px' }}>按用户/Schema 分组浏览，支持搜索用户、表、字段</p>
                            </div>
                            <div style={{ display: 'flex', gap: '8px' }}>
                                <Input
                                    placeholder="输入用户、表或字段关键词"
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
                                return [...searchResults]
                                    .sort((a, b) => a.ownerName.localeCompare(b.ownerName))
                                    .map((group) => (
                                        <div key={group.ownerName} style={{ borderBottom: '1px solid #f0f0f0' }}>
                                            <div
                                                onClick={() => toggleOwnerExpand(group.ownerName)}
                                                style={{
                                                    padding: '12px 16px',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    gap: '8px',
                                                    background: '#fafafa',
                                                    cursor: 'pointer'
                                                }}
                                            >
                                                {expandedOwners.has(group.ownerName)
                                                    ? <DownOutlined style={{ fontSize: 10, color: '#666' }} />
                                                    : <RightOutlined style={{ fontSize: 10, color: '#666' }} />}
                                                <UserOutlined style={{ color: '#8c8c8c' }} />
                                                <span style={{ fontWeight: 600, flex: 1 }}>{group.ownerName}</span>
                                                <Tag>{group.tableCount} 张表</Tag>
                                            </div>
                                            {expandedOwners.has(group.ownerName) && group.tables
                                                .slice()
                                                .sort((a, b) => a.tableName.localeCompare(b.tableName))
                                                .map((item: LineageSearchTableItem) => (
                                                    <div key={item.qualifiedName} style={{ borderTop: '1px solid #f5f5f5' }}>
                                                        <div
                                                            style={{
                                                                padding: '12px 16px 12px 32px',
                                                                display: 'flex',
                                                                alignItems: 'center',
                                                                gap: '8px'
                                                            }}
                                                        >
                                                            <div
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    toggleTableExpand(item.qualifiedName);
                                                                }}
                                                                style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', padding: '4px' }}
                                                            >
                                                                {expandedTables.has(item.qualifiedName)
                                                                    ? <DownOutlined style={{ fontSize: 10, color: '#666' }} />
                                                                    : <RightOutlined style={{ fontSize: 10, color: '#666' }} />}
                                                            </div>
                                                            <div
                                                                onClick={() => handleSelectTable(item.tableName, item.qualifiedName)}
                                                                className="hover:text-blue-500 cursor-pointer transition-colors"
                                                                style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: 1 }}
                                                            >
                                                                <TableOutlined style={{ color: '#1890ff' }} />
                                                                <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                                                                    <span style={{ fontWeight: 500 }}>{item.tableName}</span>
                                                                    <span style={{ color: '#999', fontSize: 12 }}>{item.qualifiedName}</span>
                                                                </div>
                                                            </div>
                                                            {canExport ? (
                                                                <Tooltip title="导出血缘 Excel">
                                                                    <Button
                                                                        type="text"
                                                                        size="small"
                                                                        icon={<DownloadOutlined />}
                                                                        onClick={(e) => handleExport(item.tableName, e, undefined, item.qualifiedName)}
                                                                    />
                                                                </Tooltip>
                                                            ) : null}
                                                        </div>
                                                        {expandedTables.has(item.qualifiedName) && item.columns && item.columns.length > 0 && (
                                                            <div style={{ padding: '0 16px 12px 52px', display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                                                                {item.columns.map((col: string) => (
                                                                    <Tag
                                                                        key={`${item.qualifiedName}.${col}`}
                                                                        onClick={(e) => {
                                                                            e.stopPropagation();
                                                                            handleSelectTable(item.tableName, item.qualifiedName, col);
                                                                        }}
                                                                        className="group hover:text-blue-500 hover:border-blue-500"
                                                                        style={{
                                                                            cursor: 'pointer',
                                                                            margin: 0,
                                                                            display: 'inline-flex',
                                                                            alignItems: 'center',
                                                                            gap: '4px',
                                                                            ...(searchText && col.toLowerCase().includes(searchText.toLowerCase()) ? {
                                                                                backgroundColor: '#e6f7ff',
                                                                                borderColor: '#1890ff'
                                                                            } : {})
                                                                        }}
                                                                    >
                                                                        {col}
                                                                        {canExport ? (
                                                                            <Tooltip title="导出字段血缘">
                                                                                <DownloadOutlined
                                                                                    className="opacity-0 group-hover:opacity-100 transition-opacity"
                                                                                    style={{ fontSize: '10px', color: '#666' }}
                                                                                    onClick={(e) => handleExport(item.tableName, e, col, item.qualifiedName)}
                                                                                />
                                                                            </Tooltip>
                                                                        ) : null}
                                                                    </Tag>
                                                                ))}
                                                            </div>
                                                        )}
                                                    </div>
                                                ))}
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
                            <div style={{ color: '#999', fontSize: 12, marginBottom: 8 }}>
                                共 {totalOwners} 个用户/Schema，{total} 张表
                            </div>
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
                <Content style={{ background: '#fff', position: 'relative', minHeight: 0 }}>
                    <LineageGraphContent
                        graphLoading={graphLoading}
                        nodes={nodes}
                        links={links}
                        mode={mode}
                        viewMode={viewMode}
                        viewport={viewport}
                        setViewport={setViewport}
                        setNodes={setNodes}
                        selectedTable={selectedTable}
                        selectedField={selectedField}
                        setSelectedField={setSelectedField}
                        onGenerateReport={() => setShowReportModal(true)}
                    />
                </Content>
                {canExport && showReportModal && selectedField && (
                    <LineageReportModal
                        visible={showReportModal}
                        tableName={nodes.find(n => n.id === selectedField.nodeId)?.title || ''}
                        columnName={nodes.find(n => n.id === selectedField.nodeId)?.columns.find(c => c.id === selectedField.colId)?.name || ''}
                        onClose={() => setShowReportModal(false)}
                    />
                )}
                <Drawer
                    title="SQL 血缘事后校验"
                    open={showAuditBoard}
                    onClose={() => setShowAuditBoard(false)}
                    width="92vw"
                    destroyOnHidden
                    styles={{ body: { padding: 16, background: '#f8fafc' } }}
                >
                    <AICodeReport />
                </Drawer>
            </Layout>
        </div>
    );
};

export default LineagePage;
