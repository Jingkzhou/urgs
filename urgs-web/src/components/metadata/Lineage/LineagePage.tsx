import React, { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { Layout, Input, Button, message, Empty, Spin, Tag, Badge, Pagination, Tooltip, Space, Modal, Switch, Segmented } from 'antd';
import {
    SearchOutlined,
    TableOutlined,
    RightOutlined,
    DownOutlined,
    FileTextOutlined,
    DownloadOutlined,
    PlayCircleOutlined,
    ReloadOutlined,
    PoweroffOutlined,
} from '@ant-design/icons';
import dagre from 'dagre';
import {
    getLineageGraph,
    searchTables,
    exportLineage,
    getLineageEngineStatus,
    startLineageEngine,
    restartLineageEngine,
    stopLineageEngine,
    getLineageEngineLogs,
} from '@/api/lineage';
import { hasPermission } from '@/utils/permission';
import LineageDiagramImpact from './analysis/components/LineageDiagram';
import LineageDiagramTrace from './origin/components/LineageDiagram';
import LineageReportModal from './analysis/components/LineageReportModal';
import { NodeData, LinkData, ViewportState } from './analysis/types';
import { NODE_HEADER_HEIGHT, COLUMN_ROW_HEIGHT } from './analysis/constants';
import EngineLogViewer from './analysis/components/EngineLogViewer';
import LineageListView from './analysis/components/LineageListView';

const { Sider, Content } = Layout;

interface LineagePageProps {
    mode?: 'trace' | 'impact';
}

const RunDuration: React.FC<{ startTime: string }> = ({ startTime }) => {
    const [duration, setDuration] = useState<string>('');

    useEffect(() => {
        const update = () => {
            if (!startTime) return;
            const start = new Date(startTime).getTime();
            const now = new Date().getTime();
            const diff = Math.max(0, Math.floor((now - start) / 1000));

            const hours = Math.floor(diff / 3600);
            const minutes = Math.floor((diff % 3600) / 60);
            const seconds = diff % 60;

            setDuration(
                `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
            );
        };

        update();
        const timer = setInterval(update, 1000);
        return () => clearInterval(timer);
    }, [startTime]);

    if (!duration) return null;
    return <span style={{ fontFamily: 'monospace' }}>{duration}</span>;
};

const LineagePage: React.FC<LineagePageProps> = ({ mode = 'impact' }) => {
    const containerRef = useRef<HTMLDivElement>(null);
    const [searchText, setSearchText] = useState('');
    const [searchResults, setSearchResults] = useState<any[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(20);
    const [total, setTotal] = useState(0);
    const [selectedTable, setSelectedTable] = useState<string | null>(null);
    const [selectedField, setSelectedField] = useState<{ nodeId: string, colId: string } | null>(null);
    const [nodes, setNodes] = useState<NodeData[]>([]);
    const [links, setLinks] = useState<LinkData[]>([]);
    const [viewport, setViewport] = useState<ViewportState>({ x: 0, y: 0, zoom: 0.85 });
    const [loading, setLoading] = useState(false);
    const [graphLoading, setGraphLoading] = useState(false);
    const [expandedTables, setExpandedTables] = useState<Set<string>>(new Set());
    const [showReportModal, setShowReportModal] = useState(false);
    const [showLogModal, setShowLogModal] = useState(false);
    const [engineStatus, setEngineStatus] = useState<'running' | 'stopped' | 'starting'>('stopped');
    const [engineActionLoading, setEngineActionLoading] = useState<'start' | 'stop' | 'restart' | null>(null);
    const [engineLogs, setEngineLogs] = useState<string[]>([]);
    const [engineLogsLoading, setEngineLogsLoading] = useState(false);
    const [engineMeta, setEngineMeta] = useState<{ lastStartedAt?: string; lastStoppedAt?: string; pid?: number }>({});
    const [autoRefresh, setAutoRefresh] = useState(true);
    const [viewMode, setViewMode] = useState<'canvas' | 'list'>('list');
    const engineStatusMeta = {
        running: { badge: 'success' as const, label: '运行中' },
        stopped: { badge: 'default' as const, label: '未启动' },
        starting: { badge: 'processing' as const, label: '启动中' },
    };
    const engineStatusInfo = engineStatusMeta[engineStatus];
    const pageTitle = mode === 'trace' ? '血缘溯源' : '影响分析';
    const canExport = mode === 'impact';
    const canViewEngineStatus = hasPermission('metadata:lineage:engine:logs');
    const canStartEngine = hasPermission('metadata:lineage:engine:start');
    const canRestartEngine = hasPermission('metadata:lineage:engine:restart');
    const canStopEngine = hasPermission('metadata:lineage:engine:stop');
    const canViewEngineLogs = hasPermission('metadata:lineage:engine:logs');

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

    const fetchEngineStatus = async () => {
        if (!canViewEngineStatus) {
            return;
        }
        try {
            const res = await getLineageEngineStatus();
            if (res) {
                const status = res.status as 'running' | 'stopped' | 'starting' | undefined;
                if (status) {
                    setEngineStatus(status);
                }
                setEngineMeta({
                    lastStartedAt: res.lastStartedAt,
                    lastStoppedAt: res.lastStoppedAt,
                    pid: res.pid,
                });
            }
        } catch (error) {
            message.error('获取引擎状态失败');
        }
    };

    const fetchEngineLogs = async (silent: boolean = false) => {
        if (!canViewEngineLogs) {
            message.error('无权限查看日志');
            return;
        }
        if (!silent) setEngineLogsLoading(true);
        try {
            const res = await getLineageEngineLogs(200);
            const lines = Array.isArray(res?.lines) ? res.lines : [];
            setEngineLogs(lines);
        } catch (error) {
            if (!silent) message.error('获取日志失败');
        } finally {
            if (!silent) setEngineLogsLoading(false);
        }
    };

    useEffect(() => {
        handleSearch();
    }, []);

    useEffect(() => {
        handleSearch();
    }, []);


    useEffect(() => {
        if (!canViewEngineStatus) {
            return;
        }
        fetchEngineStatus();
        const timer = window.setInterval(() => {
            fetchEngineStatus();
        }, 15000);
        return () => window.clearInterval(timer);
    }, [canViewEngineStatus]);

    useEffect(() => {
        if (showLogModal && autoRefresh) {
            const timer = setInterval(() => {
                fetchEngineLogs(true);
            }, 3000);
            return () => clearInterval(timer);
        }
    }, [showLogModal, autoRefresh]);



    const handleStartEngine = async () => {
        if (!canStartEngine) {
            message.error('无权限启动引擎');
            return;
        }
        setEngineActionLoading('start');
        setEngineStatus('starting');
        try {
            const res = await startLineageEngine();
            if (res?.success === false) {
                message.error(res.message || '引擎启动失败');
            } else if (res?.message) {
                message.success(res.message);
            } else {
                message.success('引擎启动中');
            }
            await fetchEngineStatus();
        } catch (error) {
            message.error('引擎启动失败');
            await fetchEngineStatus();
        } finally {
            setEngineActionLoading(null);
        }
    };

    const handleRestartEngine = async () => {
        if (!canRestartEngine) {
            message.error('无权限重启引擎');
            return;
        }
        setEngineActionLoading('restart');
        setEngineStatus('starting');
        try {
            const res = await restartLineageEngine();
            if (res?.success === false) {
                message.error(res.message || '引擎重启失败');
            } else if (res?.message) {
                message.success(res.message);
            } else {
                message.success('引擎重启中');
            }
            await fetchEngineStatus();
        } catch (error) {
            message.error('引擎重启失败');
            await fetchEngineStatus();
        } finally {
            setEngineActionLoading(null);
        }
    };

    const handleStopEngine = async () => {
        if (!canStopEngine) {
            message.error('无权限停止引擎');
            return;
        }
        setEngineActionLoading('stop');
        try {
            const res = await stopLineageEngine();
            if (res?.success === false) {
                message.error(res.message || '引擎停止失败');
            } else if (res?.message) {
                message.success(res.message);
            } else {
                message.success('引擎已停止');
            }
            await fetchEngineStatus();
        } catch (error) {
            message.error('引擎停止失败');
            await fetchEngineStatus();
        } finally {
            setEngineActionLoading(null);
        }
    };

    const handleOpenLogs = () => {
        if (!canViewEngineLogs) {
            message.error('无权限查看日志');
            return;
        }
        setShowLogModal(true);
        setShowLogModal(true);
        fetchEngineLogs(false);
    };

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
        setSelectedTable(tableName);
        try {
            const res = await getLineageGraph(tableName, targetColName);
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
            console.error(error);
            message.error(`加载血缘失败: ${error.message}`);
        } finally {
            setGraphLoading(false);
        }
    };

    const handleExport = async (tableName: string, e: React.MouseEvent, columnName?: string) => {
        e.stopPropagation();
        if (!canExport) {
            return;
        }
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

    const processLayoutImpact = (rawNodes: any[], rawEdges: any[], mainTableName: string) => {
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
            target: e.target
        })));

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

        console.log('========== 最终链接数据 ==========');
        console.log('生成的 links 数量:', links.length);
        const linkTypeCount: Record<string, number> = {};
        links.forEach(l => {
            linkTypeCount[l.type || 'unknown'] = (linkTypeCount[l.type || 'unknown'] || 0) + 1;
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
                    {selectedTable && <Tag color="blue">{selectedTable}</Tag>}
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
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px', border: '1px solid #f0f0f0', borderRadius: 8, background: '#fafafa' }}>
                            <span style={{ fontSize: 12, color: '#8c8c8c' }}>引擎控制</span>
                            {canViewEngineStatus ? (
                                <>
                                    <Badge status={engineStatusInfo.badge} text={engineStatusInfo.label} />
                                    {engineMeta.pid ? <span style={{ fontSize: 11, color: '#94a3b8', marginLeft: 4 }}>PID {engineMeta.pid}</span> : null}
                                    {engineMeta.lastStartedAt && engineStatus === 'running' ? (
                                        <span style={{ fontSize: 11, color: '#94a3b8', marginLeft: 8 }} title={engineMeta.lastStartedAt}>
                                            启动于 {new Date(engineMeta.lastStartedAt).toLocaleString('zh-CN', { hour12: false })}
                                            <span style={{ margin: '0 4px' }}>·</span>
                                            已运行 <RunDuration startTime={engineMeta.lastStartedAt} />
                                        </span>
                                    ) : null}
                                </>
                            ) : (
                                <Badge status="default" text="无权限" />
                            )}
                        </div>
                        <Space>
                            {canStartEngine ? (
                                <Button
                                    type="primary"
                                    icon={<PlayCircleOutlined />}
                                    loading={engineActionLoading === 'start'}
                                    disabled={engineStatus === 'running' || engineStatus === 'starting'}
                                    onClick={handleStartEngine}
                                >
                                    启动引擎
                                </Button>
                            ) : null}
                            {canRestartEngine ? (
                                <Button
                                    icon={<ReloadOutlined />}
                                    loading={engineActionLoading === 'restart'}
                                    disabled={engineStatus !== 'running'}
                                    onClick={handleRestartEngine}
                                >
                                    重启
                                </Button>
                            ) : null}
                            {canStopEngine ? (
                                <Button
                                    danger
                                    icon={<PoweroffOutlined />}
                                    loading={engineActionLoading === 'stop'}
                                    disabled={engineStatus !== 'running'}
                                    onClick={handleStopEngine}
                                >
                                    停止
                                </Button>
                            ) : null}
                            {canViewEngineLogs ? (
                                <Button icon={<FileTextOutlined />} onClick={handleOpenLogs}>
                                    查看日志
                                </Button>
                            ) : null}
                        </Space>
                    </div>
                </div>
            </div>
            <Layout style={{ flex: 1, minHeight: 0 }}>
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
                                                {canExport ? (
                                                    <Tooltip title="导出血缘 Excel">
                                                        <Button
                                                            type="text"
                                                            size="small"
                                                            icon={<DownloadOutlined />}
                                                            onClick={(e) => handleExport(item.tableName, e)}
                                                        />
                                                    </Tooltip>
                                                ) : null}
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
                                                                        onClick={(e) => handleExport(item.tableName, e, col)}
                                                                    />
                                                                </Tooltip>
                                                            ) : null}
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
                <Content style={{ background: '#fff', position: 'relative', minHeight: 0 }}>
                    <Spin spinning={graphLoading} tip="加载血缘关系...">
                        <div style={{ height: '100%', width: '100%' }}>
                            {nodes.length > 0 ? (
                                viewMode === 'canvas' ? (
                                    mode === 'impact' ? (
                                        <LineageDiagramImpact
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
                                        <LineageDiagramTrace
                                            viewport={viewport}
                                            setViewport={setViewport}
                                            nodes={nodes}
                                            setNodes={setNodes}
                                            links={links}
                                            selectedTable={selectedTable}
                                            selectedField={selectedField}
                                            onFieldSelect={setSelectedField}
                                        />
                                    )
                                ) : (
                                    <LineageListView
                                        nodes={nodes}
                                        links={links}
                                        selectedTable={selectedTable}
                                        selectedField={selectedField}
                                    />
                                )
                            ) : (
                                !graphLoading && <Empty description="请从左侧选择表查看血缘" style={{ marginTop: '100px' }} />
                            )}
                        </div>
                    </Spin>
                </Content>
                {canExport && showReportModal && selectedField && (
                    <LineageReportModal
                        visible={showReportModal}
                        tableName={nodes.find(n => n.id === selectedField.nodeId)?.title || ''}
                        columnName={nodes.find(n => n.id === selectedField.nodeId)?.columns.find(c => c.id === selectedField.colId)?.name || ''}
                        onClose={() => setShowReportModal(false)}
                    />
                )}
                <Modal
                    title={<div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><FileTextOutlined /> 引擎执行日志</div>}
                    open={showLogModal}
                    onCancel={() => setShowLogModal(false)}
                    footer={null}
                    width={840}
                    styles={{ body: { padding: 0 } }}
                >
                    <EngineLogViewer
                        logs={engineLogs}
                        loading={engineLogsLoading}
                        autoRefresh={autoRefresh}
                        onAutoRefreshChange={setAutoRefresh}
                        onRefresh={() => fetchEngineLogs(false)}
                    />
                </Modal>


            </Layout>
        </div>
    );
};

export default LineagePage;

