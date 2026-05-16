import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Graph, EdgeEvent, NodeEvent } from '@antv/g6';
import type { EdgeData, GraphData, NodeData as G6NodeData } from '@antv/g6';
import { Button, Empty, Tag, Tooltip, message } from 'antd';
import { FileTextOutlined } from '@ant-design/icons';
import { Activity, ArrowDown, ArrowUp, Focus, GitBranch, Info, Layers3, Maximize2, Network, PanelRight, Route, Table2 } from 'lucide-react';
import { getLineageGraph, LineageGraphResponse } from '@/api/lineage';
import { LinkData, NodeData, RELATION_STYLES } from '../types';
import CodeModal from './CodeModal';
import G6NodeSearch from './G6NodeSearch';

interface G6LineageDiagramProps {
    mode?: 'trace' | 'impact';
    nodes: NodeData[];
    links: LinkData[];
    selectedTable: string | null;
    selectedField: { nodeId: string; colId: string } | null;
    graphMeta?: Partial<LineageGraphResponse> | null;
    onGenerateReport?: () => void;
}

interface AggregatedEdgeData extends EdgeData {
    data: {
        count: number;
        relationType: string;
        links: LinkData[];
        sourceTable: string;
        targetTable: string;
    };
}

interface GraphSummary {
    upstreamCount: number;
    downstreamCount: number;
    connectedEdgeCount: number;
    relationStats: { type: string; label: string; count: number; color: string }[];
}

const buildColumnKey = (nodeId: string, colId?: string) => `${nodeId}||${colId || ''}`;

const traceLineage = (
    selectedField: { nodeId: string; colId: string },
    incomingByColumn: Map<string, LinkData[]>,
    outgoingByColumn: Map<string, LinkData[]>,
) => {
    const visitedLinks = new Set<string>();
    const visitedColumns = new Set<string>();
    const visitedNodes = new Set<string>();
    const queue: { nodeId: string; colId: string; direction: 'up' | 'down' | 'both' }[] = [
        { nodeId: selectedField.nodeId, colId: selectedField.colId, direction: 'both' },
    ];
    visitedColumns.add(buildColumnKey(selectedField.nodeId, selectedField.colId));
    visitedNodes.add(selectedField.nodeId);
    while (queue.length > 0) {
        const { nodeId, colId, direction } = queue.shift()!;
        const currentKey = buildColumnKey(nodeId, colId);
        const tableLevelKey = buildColumnKey(nodeId);
        if (direction === 'both' || direction === 'up') {
            const incomingLinks = [
                ...(incomingByColumn.get(currentKey) || []),
                ...(incomingByColumn.get(tableLevelKey) || []),
            ];
            incomingLinks.forEach(link => {
                if (visitedLinks.has(link.id)) {
                    return;
                }
                visitedLinks.add(link.id);
                const sourceCol = link.sourceColumnId || '';
                const sourceKey = buildColumnKey(link.sourceNodeId, sourceCol);
                if (!visitedColumns.has(sourceKey)) {
                    visitedColumns.add(sourceKey);
                    visitedNodes.add(link.sourceNodeId);
                    queue.push({ nodeId: link.sourceNodeId, colId: sourceCol, direction: 'up' });
                }
            });
        }
        if (direction === 'both' || direction === 'down') {
            const outgoingLinks = [
                ...(outgoingByColumn.get(currentKey) || []),
                ...(outgoingByColumn.get(tableLevelKey) || []),
            ];
            outgoingLinks.forEach(link => {
                if (visitedLinks.has(link.id)) {
                    return;
                }
                visitedLinks.add(link.id);
                const targetCol = link.targetColumnId || '';
                const targetKey = buildColumnKey(link.targetNodeId, targetCol);
                if (!visitedColumns.has(targetKey)) {
                    visitedColumns.add(targetKey);
                    visitedNodes.add(link.targetNodeId);
                    queue.push({ nodeId: link.targetNodeId, colId: targetCol, direction: 'down' });
                }
            });
        }
    }
    return { visitedLinks, visitedNodes };
};

const getSourceFile = (link: LinkData) => {
    const sourceFiles = link.properties?.sourceFiles;
    if (Array.isArray(sourceFiles)) {
        return sourceFiles[0];
    }
    return sourceFiles || link.properties?.source_file || link.properties?.sourceFile;
};

const getTableName = (node: any) => String(node?.properties?.name || node?.label || '').toUpperCase();

const splitQualifiedTitle = (title: string) => {
    const index = title.lastIndexOf('.');
    if (index <= 0 || index === title.length - 1) {
        return { owner: 'DEFAULT', table: title };
    }
    return {
        owner: title.slice(0, index),
        table: title.slice(index + 1),
    };
};

const getRelationStyle = (type?: string) => RELATION_STYLES[type || 'DERIVES_TO'] || RELATION_STYLES.DERIVES_TO;

const formatRelationLabel = (count: number) => `${count} 个字段关系`;

const parseTableGraph = (response: LineageGraphResponse) => {
    const parsedNodes: NodeData[] = (response.nodes || [])
        .filter(node => Array.isArray(node.labels) && node.labels.includes('Table'))
        .map(node => ({
            id: node.id,
            x: 0,
            y: 0,
            width: 240,
            type: 'default',
            title: getTableName(node),
            isCollapsed: true,
            columns: [],
        }));

    const tableIds = new Set(parsedNodes.map(node => node.id));
    const parsedLinks: LinkData[] = (response.edges || [])
        .filter(edge => edge.type !== 'BELONGS_TO' && tableIds.has(edge.source) && tableIds.has(edge.target))
        .map(edge => ({
            id: edge.id,
            sourceNodeId: edge.source,
            sourceColumnId: '',
            targetNodeId: edge.target,
            targetColumnId: '',
            type: edge.type,
            properties: edge.properties || {},
        }));

    return { nodes: parsedNodes, links: parsedLinks };
};

const mergeGraphData = (baseNodes: NodeData[], baseLinks: LinkData[], nextNodes: NodeData[], nextLinks: LinkData[]) => {
    const mergedNodeMap = new Map<string, NodeData>();
    baseNodes.forEach(node => mergedNodeMap.set(node.id, node));
    nextNodes.forEach(node => {
        if (!mergedNodeMap.has(node.id)) {
            mergedNodeMap.set(node.id, node);
        }
    });
    const mergedLinkMap = new Map<string, LinkData>();
    baseLinks.forEach(link => mergedLinkMap.set(link.id, link));
    nextLinks.forEach(link => {
        if (!mergedLinkMap.has(link.id)) {
            mergedLinkMap.set(link.id, link);
        }
    });
    return {
        nodes: Array.from(mergedNodeMap.values()),
        links: Array.from(mergedLinkMap.values()),
    };
};

const buildNodeSummary = (nodeId: string | null, links: LinkData[]): GraphSummary => {
    if (!nodeId) {
        return { upstreamCount: 0, downstreamCount: 0, connectedEdgeCount: 0, relationStats: [] };
    }

    const upstream = new Set<string>();
    const downstream = new Set<string>();
    const relationCounts = new Map<string, number>();
    let connectedEdgeCount = 0;
    links.forEach(link => {
        if (link.targetNodeId === nodeId) {
            upstream.add(link.sourceNodeId);
            connectedEdgeCount += 1;
            relationCounts.set(link.type || 'DERIVES_TO', (relationCounts.get(link.type || 'DERIVES_TO') || 0) + 1);
        }
        if (link.sourceNodeId === nodeId) {
            downstream.add(link.targetNodeId);
            connectedEdgeCount += 1;
            relationCounts.set(link.type || 'DERIVES_TO', (relationCounts.get(link.type || 'DERIVES_TO') || 0) + 1);
        }
    });
    return {
        upstreamCount: upstream.size,
        downstreamCount: downstream.size,
        connectedEdgeCount,
        relationStats: Array.from(relationCounts.entries())
            .map(([type, count]) => {
                const style = getRelationStyle(type);
                return { type, count, label: style.label, color: style.color };
            })
            .sort((a, b) => b.count - a.count),
    };
};

const waitForFrame = () => new Promise<void>(resolve => {
    window.requestAnimationFrame(() => resolve());
});

const G6LineageDiagram: React.FC<G6LineageDiagramProps> = ({
    nodes,
    links,
    selectedTable,
    selectedField,
    graphMeta,
    onGenerateReport,
}) => {
    const containerRef = useRef<HTMLDivElement>(null);
    const graphRef = useRef<InstanceType<typeof Graph> | null>(null);
    const mountedRef = useRef(false);
    const renderQueueRef = useRef(Promise.resolve());
    const [displayNodes, setDisplayNodes] = useState<NodeData[]>(nodes);
    const [displayLinks, setDisplayLinks] = useState<LinkData[]>(links);
    const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
    const [selectedEdgeId, setSelectedEdgeId] = useState<string | null>(null);
    const [expandingDirection, setExpandingDirection] = useState<'upstream' | 'downstream' | null>(null);
    const [lastExpansionMeta, setLastExpansionMeta] = useState<Partial<LineageGraphResponse> | null>(null);
    const [selectedCode, setSelectedCode] = useState<{
        code: string;
        sourceFile?: string;
        linkType?: string;
        searchTerm?: string;
    } | null>(null);
    const [codeModalVisible, setCodeModalVisible] = useState(false);

    useEffect(() => {
        setDisplayNodes(nodes);
        setDisplayLinks(links);
        setSelectedNodeId(null);
        setSelectedEdgeId(null);
        setLastExpansionMeta(null);
    }, [nodes, links]);

    const nodeMap = useMemo(() => new Map(displayNodes.map(node => [node.id, node])), [displayNodes]);
    const nodeMapRef = useRef(nodeMap);

    useEffect(() => {
        nodeMapRef.current = nodeMap;
    }, [nodeMap]);

    const lineageIndexes = useMemo(() => {
        const incomingByColumn = new Map<string, LinkData[]>();
        const outgoingByColumn = new Map<string, LinkData[]>();

        displayLinks.forEach(link => {
            const incomingKey = buildColumnKey(link.targetNodeId, link.targetColumnId);
            const outgoingKey = buildColumnKey(link.sourceNodeId, link.sourceColumnId);

            if (!incomingByColumn.has(incomingKey)) {
                incomingByColumn.set(incomingKey, []);
            }
            incomingByColumn.get(incomingKey)!.push(link);

            if (!outgoingByColumn.has(outgoingKey)) {
                outgoingByColumn.set(outgoingKey, []);
            }
            outgoingByColumn.get(outgoingKey)!.push(link);
        });

        return { incomingByColumn, outgoingByColumn };
    }, [displayLinks]);

    const activeTrace = useMemo(() => {
        if (!selectedField) {
            return null;
        }
        return traceLineage(selectedField, lineageIndexes.incomingByColumn, lineageIndexes.outgoingByColumn);
    }, [selectedField, lineageIndexes]);

    const graphData = useMemo<GraphData>(() => {
        const visibleLinks = activeTrace
            ? displayLinks.filter(link => activeTrace.visitedLinks.has(link.id))
            : displayLinks;

        const visibleNodeIds = new Set<string>();
        visibleLinks.forEach(link => {
            visibleNodeIds.add(link.sourceNodeId);
            visibleNodeIds.add(link.targetNodeId);
        });
        if (!activeTrace && visibleNodeIds.size === 0) {
            displayNodes.forEach(node => visibleNodeIds.add(node.id));
        }

        if (activeTrace) {
            activeTrace.visitedNodes.forEach(nodeId => visibleNodeIds.add(nodeId));
        }

        const selectedTableLower = selectedTable?.toLowerCase();
        const activeNodeIds = new Set<string>();
        const activeEdgeKeys = new Set<string>();

        if (selectedNodeId) {
            activeNodeIds.add(selectedNodeId);
            visibleLinks.forEach(link => {
                if (link.sourceNodeId === selectedNodeId || link.targetNodeId === selectedNodeId) {
                    activeNodeIds.add(link.sourceNodeId);
                    activeNodeIds.add(link.targetNodeId);
                    activeEdgeKeys.add(`${link.sourceNodeId}::${link.targetNodeId}`);
                }
            });
        }

        if (selectedEdgeId) {
            visibleLinks.forEach(link => {
                const key = `${link.sourceNodeId}::${link.targetNodeId}`;
                if (key === selectedEdgeId) {
                    activeNodeIds.add(link.sourceNodeId);
                    activeNodeIds.add(link.targetNodeId);
                    activeEdgeKeys.add(key);
                }
            });
        }

        const hasActiveSelection = activeNodeIds.size > 0 || activeEdgeKeys.size > 0;
        const g6Nodes: G6NodeData[] = displayNodes
            .filter(node => visibleNodeIds.has(node.id))
            .map(node => {
                const isSelected = selectedNodeId === node.id || (!!selectedTableLower && node.title.toLowerCase() === selectedTableLower);
                const isNeighbor = !isSelected && activeNodeIds.has(node.id);
                const isInactive = hasActiveSelection && !activeNodeIds.has(node.id) && !isSelected;
                const titleParts = splitQualifiedTitle(node.title);
                return {
                    id: node.id,
                    data: {
                        title: node.title,
                        owner: titleParts.owner,
                        table: titleParts.table,
                        columnCount: node.columns.length,
                    },
                    states: [
                        ...(isSelected ? ['selected'] : []),
                        ...(isNeighbor ? ['neighbor'] : []),
                        ...(isInactive ? ['inactive'] : []),
                    ],
                };
            });

        const edgeMap = new Map<string, AggregatedEdgeData>();
        visibleLinks.forEach(link => {
            const sourceNode = nodeMap.get(link.sourceNodeId);
            const targetNode = nodeMap.get(link.targetNodeId);
            if (!sourceNode || !targetNode) {
                return;
            }

            const key = `${link.sourceNodeId}::${link.targetNodeId}`;
            const relationType = link.type || 'DERIVES_TO';
            const current = edgeMap.get(key);
            if (current) {
                current.data.count += 1;
                current.data.links.push(link);
                return;
            }

            edgeMap.set(key, {
                id: key,
                source: link.sourceNodeId,
                target: link.targetNodeId,
                data: {
                    count: 1,
                    relationType,
                    links: [link],
                    sourceTable: sourceNode.title,
                    targetTable: targetNode.title,
                },
                states: [
                    ...(selectedEdgeId === key || activeEdgeKeys.has(key) ? ['selected'] : []),
                    ...(hasActiveSelection && !activeEdgeKeys.has(key) ? ['inactive'] : []),
                ],
            });
        });

        return {
            nodes: g6Nodes,
            edges: Array.from(edgeMap.values()),
        };
    }, [activeTrace, displayLinks, displayNodes, nodeMap, selectedEdgeId, selectedNodeId, selectedTable]);

    const selectedNode = selectedNodeId ? nodeMap.get(selectedNodeId) : null;
    const selectedNodeTitle = selectedNode ? splitQualifiedTitle(selectedNode.title) : null;
    const selectedNodeSummary = useMemo(
        () => buildNodeSummary(selectedNodeId, displayLinks),
        [displayLinks, selectedNodeId]
    );
    const overviewStats = useMemo(() => {
        const relationCounts = new Map<string, number>();
        displayLinks.forEach(link => {
            const type = link.type || 'DERIVES_TO';
            relationCounts.set(type, (relationCounts.get(type) || 0) + 1);
        });
        return Array.from(relationCounts.entries())
            .map(([type, count]) => {
                const style = getRelationStyle(type);
                return { type, count, label: style.label, color: style.color };
            })
            .sort((a, b) => b.count - a.count);
    }, [displayLinks]);
    const activeMeta = lastExpansionMeta || graphMeta;
    const isTruncated = !!activeMeta?.truncated;
    const graphModeLabel = '血缘图';

    const focusNode = React.useCallback((nodeId: string) => {
        const graph = graphRef.current;
        setSelectedNodeId(nodeId);
        setSelectedEdgeId(null);
        if (graph && mountedRef.current) void graph.focusElement(nodeId, { duration: 300 }).catch(() => undefined);
    }, []);

    const renderGraph = React.useCallback((graph: InstanceType<typeof Graph>) => {
        renderQueueRef.current = renderQueueRef.current.then(async () => {
            await waitForFrame();
            await waitForFrame();
            const container = containerRef.current;
            const rect = container?.getBoundingClientRect();
            if (rect && rect.width > 0 && rect.height > 0) {
                graph.setSize(Math.floor(rect.width), Math.floor(rect.height));
            }
            if (graphRef.current === graph && mountedRef.current) {
                await graph.render();
                await graph.fitView({ padding: 56 }, { duration: 0 }).catch(() => undefined);
            }
        }).catch(() => undefined);
    }, []);

    const handleExpand = async (direction: 'upstream' | 'downstream') => {
        if (!selectedNode) {
            return;
        }

        setExpandingDirection(direction);
        try {
            const response = await getLineageGraph(selectedNode.title, undefined, {
                depth: 1,
                direction,
                limit: 1000,
                relationLevel: 'table',
            });
            const parsedGraph = parseTableGraph(response);
            const merged = mergeGraphData(displayNodes, displayLinks, parsedGraph.nodes, parsedGraph.links);
            setDisplayNodes(merged.nodes);
            setDisplayLinks(merged.links);
            setLastExpansionMeta(response);
            if (response.truncated) {
                message.warning('本次展开已达到返回上限，请继续按节点分层展开。');
            }
        } finally {
            setExpandingDirection(null);
        }
    };

    useEffect(() => {
        const container = containerRef.current;
        if (!container) {
            return;
        }
        mountedRef.current = true;

        const graph = new Graph({
            container,
            autoResize: true,
            autoFit: 'view',
            padding: 48,
            background: '#f8fafc',
            animation: false,
            data: graphData,
            layout: {
                type: 'dagre',
                rankdir: 'LR',
                nodesep: 64,
                ranksep: 180,
            },
            node: {
                type: 'rect',
                style: (datum) => {
                    const data = datum.data as { table?: string; owner?: string; columnCount?: number };
                    return {
                        size: [260, 82],
                        radius: 8,
                        fill: '#ffffff',
                        stroke: '#d6e4ff',
                        lineWidth: 1,
                        shadowColor: 'rgba(15, 23, 42, 0.08)',
                        shadowBlur: 12,
                        shadowOffsetY: 4,
                        labelText: `${data.table || datum.id}\n${data.owner || 'DEFAULT'} · ${data.columnCount || 0} 字段`,
                        labelFontSize: 12,
                        labelFontWeight: 600,
                        labelFill: '#0f172a',
                        labelLineHeight: 18,
                        labelWordWrap: true,
                        labelMaxWidth: 228,
                        port: false,
                    };
                },
                state: {
                    selected: {
                        stroke: '#2563eb',
                        lineWidth: 2,
                        halo: true,
                        haloStroke: '#93c5fd',
                        haloLineWidth: 8,
                    },
                    neighbor: {
                        stroke: '#38bdf8',
                        lineWidth: 1.5,
                    },
                    inactive: {
                        opacity: 0.28,
                    },
                },
            },
            edge: {
                type: 'cubic-horizontal',
                style: (datum) => {
                    const data = datum.data as AggregatedEdgeData['data'] | undefined;
                    const relationStyle = RELATION_STYLES[data?.relationType || 'DERIVES_TO'] || RELATION_STYLES.DERIVES_TO;
                    return {
                        stroke: relationStyle.color,
                        lineWidth: 1.8,
                        endArrow: true,
                        labelText: data && data.count > 1 ? formatRelationLabel(data.count) : '',
                        labelFill: '#475569',
                        labelFontSize: 11,
                        labelBackground: true,
                        labelBackgroundFill: '#ffffff',
                        labelBackgroundRadius: 4,
                    };
                },
                state: {
                    selected: {
                        lineWidth: 3,
                        stroke: '#2563eb',
                    },
                    inactive: {
                        opacity: 0.14,
                    },
                },
            },
            behaviors: ['drag-canvas', 'zoom-canvas', 'drag-element'],
        });

        graph.on(NodeEvent.CLICK, event => {
            focusNode(String(event.target.id));
        });

        graph.on(EdgeEvent.CLICK, event => {
            const edgeId = String(event.target.id);
            setSelectedEdgeId(edgeId);
            setSelectedNodeId(null);
            const edge = graph.getElementData(edgeId) as AggregatedEdgeData;
            const linkWithCode = edge.data.links.find(link => !!link.properties?.snippet);
            if (linkWithCode?.properties?.snippet) {
                const sourceNode = nodeMapRef.current.get(linkWithCode.sourceNodeId);
                const sourceColumn = sourceNode?.columns.find(col => col.id === linkWithCode.sourceColumnId);
                setSelectedCode({
                    code: linkWithCode.properties.snippet,
                    sourceFile: getSourceFile(linkWithCode),
                    linkType: linkWithCode.type,
                    searchTerm: sourceColumn?.name || linkWithCode.sourceColumnId,
                });
                setCodeModalVisible(true);
            }
        });

        graphRef.current = graph;
        renderGraph(graph);

        return () => {
            mountedRef.current = false;
            graphRef.current = null;
            graph.destroy();
        };
    }, [focusNode, renderGraph]);

    useEffect(() => {
        const graph = graphRef.current;
        if (!graph) {
            return;
        }
        graph.setData(graphData);
        renderGraph(graph);
    }, [graphData, renderGraph]);

    if (displayNodes.length === 0) {
        return <Empty description="暂无血缘图数据" style={{ marginTop: 100 }} />;
    }

    return (
        <div className="relative h-full w-full overflow-hidden bg-[#f8fafc]" style={{ minHeight: 640 }}>
            <div className="absolute inset-y-0 left-0 right-[340px]">
                <div ref={containerRef} className="h-full w-full" />
            </div>

            <div className="absolute left-4 top-4 right-[364px] flex flex-wrap items-center gap-2 rounded-lg border border-slate-200 bg-white/95 px-3 py-2 text-xs shadow-sm backdrop-blur">
                <div className="flex items-center gap-1.5 font-semibold text-slate-700">
                    <Network size={14} className="text-blue-600" />
                    G6 {graphModeLabel}
                </div>
                <span className="h-4 w-px bg-slate-200" />
                <span className="flex items-center gap-1 text-slate-600">
                    <Table2 size={13} />
                    {graphData.nodes?.length || 0} 表
                </span>
                <span className="flex items-center gap-1 text-slate-600">
                    <GitBranch size={13} />
                    {displayLinks.length} 关系
                </span>
                <span className="flex items-center gap-1 text-slate-600">
                    <Layers3 size={13} />
                    {graphData.edges?.length || 0} 聚合边
                </span>
                {selectedField && <Tag color="geekblue">字段路径</Tag>}
                {isTruncated && (
                    <Tag color="gold" className="ml-auto">
                        仅展示前 {activeMeta?.limit || 1000} 条
                    </Tag>
                )}
                <G6NodeSearch nodes={displayNodes} onFocusNode={focusNode} />
            </div>

            <aside className="absolute bottom-0 right-0 top-0 w-[340px] border-l border-slate-200 bg-white shadow-[-10px_0_30px_rgba(15,23,42,0.06)]">
                <div className="flex h-full flex-col">
                    <div className="border-b border-slate-200 px-4 py-3">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2 font-semibold text-slate-800">
                                <PanelRight size={16} className="text-blue-600" />
                                图谱详情
                            </div>
                            <Tag color={selectedNode ? 'blue' : 'default'}>{selectedNode ? '已选中' : '总览'}</Tag>
                        </div>
                    </div>

                    <div className="min-h-0 flex-1 overflow-auto px-4 py-4">
                        {selectedNode && selectedNodeTitle ? (
                            <>
                                <div className="rounded-lg border border-blue-100 bg-blue-50/70 p-3">
                                    <div className="text-xs font-medium text-blue-700">{selectedNodeTitle.owner}</div>
                                    <div className="mt-1 break-words text-base font-semibold text-slate-900">{selectedNodeTitle.table}</div>
                                </div>

                                <div className="mt-4 grid grid-cols-3 gap-2">
                                    <div className="rounded-lg border border-slate-200 bg-slate-50 p-2">
                                        <div className="text-[11px] text-slate-500">上游</div>
                                        <div className="mt-1 text-lg font-semibold text-slate-900">{selectedNodeSummary.upstreamCount}</div>
                                    </div>
                                    <div className="rounded-lg border border-slate-200 bg-slate-50 p-2">
                                        <div className="text-[11px] text-slate-500">下游</div>
                                        <div className="mt-1 text-lg font-semibold text-slate-900">{selectedNodeSummary.downstreamCount}</div>
                                    </div>
                                    <div className="rounded-lg border border-slate-200 bg-slate-50 p-2">
                                        <div className="text-[11px] text-slate-500">关系</div>
                                        <div className="mt-1 text-lg font-semibold text-slate-900">{selectedNodeSummary.connectedEdgeCount}</div>
                                    </div>
                                </div>

                                <div className="mt-4 flex gap-2">
                                    <Button
                                        block
                                        icon={<ArrowUp size={14} />}
                                        loading={expandingDirection === 'upstream'}
                                        onClick={() => handleExpand('upstream')}
                                    >
                                        展开上游
                                    </Button>
                                    <Button
                                        block
                                        type="primary"
                                        icon={<ArrowDown size={14} />}
                                        loading={expandingDirection === 'downstream'}
                                        onClick={() => handleExpand('downstream')}
                                    >
                                        展开下游
                                    </Button>
                                </div>

                                <div className="mt-5">
                                    <div className="mb-2 flex items-center gap-2 text-sm font-semibold text-slate-700">
                                        <Route size={14} className="text-slate-500" />
                                        关系类型
                                    </div>
                                    <div className="space-y-2">
                                        {selectedNodeSummary.relationStats.length > 0 ? selectedNodeSummary.relationStats.map(item => (
                                            <div key={item.type} className="flex items-center justify-between rounded-md bg-slate-50 px-2.5 py-2">
                                                <div className="flex items-center gap-2">
                                                    <span className="h-2.5 w-2.5 rounded-full" style={{ background: item.color }} />
                                                    <span className="text-xs font-medium text-slate-700">{item.label}</span>
                                                </div>
                                                <span className="text-xs font-semibold text-slate-900">{item.count}</span>
                                            </div>
                                        )) : (
                                            <div className="rounded-md bg-slate-50 px-3 py-6 text-center text-xs text-slate-500">暂无直接关系</div>
                                        )}
                                    </div>
                                </div>
                            </>
                        ) : (
                            <>
                                <div className="grid grid-cols-2 gap-2">
                                    <div className="rounded-lg border border-slate-200 bg-slate-50 p-3">
                                        <div className="flex items-center gap-1.5 text-xs text-slate-500">
                                            <Table2 size={13} />
                                            表节点
                                        </div>
                                        <div className="mt-2 text-2xl font-semibold text-slate-900">{graphData.nodes?.length || 0}</div>
                                    </div>
                                    <div className="rounded-lg border border-slate-200 bg-slate-50 p-3">
                                        <div className="flex items-center gap-1.5 text-xs text-slate-500">
                                            <Activity size={13} />
                                            字段关系
                                        </div>
                                        <div className="mt-2 text-2xl font-semibold text-slate-900">{displayLinks.length}</div>
                                    </div>
                                </div>

                                {isTruncated && (
                                    <div className="mt-4 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800">
                                        <div className="flex items-center gap-2 font-semibold">
                                            <Info size={14} />
                                            已达到返回上限
                                        </div>
                                        <div className="mt-1 leading-5">当前返回上限为 {activeMeta?.limit || 1000} 条关系，可选中关键表继续按上游或下游展开。</div>
                                    </div>
                                )}

                                <div className="mt-5">
                                    <div className="mb-2 flex items-center gap-2 text-sm font-semibold text-slate-700">
                                        <Route size={14} className="text-slate-500" />
                                        关系分布
                                    </div>
                                    <div className="space-y-2">
                                        {overviewStats.map(item => (
                                            <div key={item.type} className="flex items-center justify-between rounded-md bg-slate-50 px-2.5 py-2">
                                                <div className="flex items-center gap-2">
                                                    <span className="h-2.5 w-2.5 rounded-full" style={{ background: item.color }} />
                                                    <span className="text-xs font-medium text-slate-700">{item.label}</span>
                                                </div>
                                                <span className="text-xs font-semibold text-slate-900">{item.count}</span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            </aside>

            <div className="absolute bottom-6 right-[364px] flex flex-col gap-3">
                <Tooltip title="适配当前视图">
                    <Button
                        shape="circle"
                        icon={<Maximize2 size={16} />}
                        onClick={() => graphRef.current?.fitView({ padding: 56 }, { duration: 250 })}
                    />
                </Tooltip>
                {selectedNode && (
                    <Tooltip title="聚焦选中表">
                        <Button
                            shape="circle"
                            icon={<Focus size={16} />}
                            onClick={() => graphRef.current?.fitView({ padding: 80 }, { duration: 250 })}
                        />
                    </Tooltip>
                )}
                {selectedField && onGenerateReport && (
                    <Tooltip title="生成 AI 血缘影响报告">
                        <Button
                            type="primary"
                            shape="circle"
                            icon={<FileTextOutlined />}
                            onClick={onGenerateReport}
                        />
                    </Tooltip>
                )}
            </div>

            <div className="absolute bottom-6 left-4 flex flex-wrap items-center gap-2 rounded-lg border border-slate-200 bg-white/95 px-3 py-2 text-xs text-slate-600 shadow-sm backdrop-blur">
                <span className="font-medium text-slate-700">图例</span>
                {Object.entries(RELATION_STYLES).slice(0, 5).map(([type, style]) => (
                    <span key={type} className="flex items-center gap-1.5">
                        <span className="h-2 w-5 rounded-full" style={{ background: style.color }} />
                        {style.label}
                    </span>
                ))}
            </div>

            {selectedCode && (
                <CodeModal
                    visible={codeModalVisible}
                    onClose={() => setCodeModalVisible(false)}
                    code={selectedCode.code}
                    sourceFile={selectedCode.sourceFile}
                    linkType={selectedCode.linkType}
                    searchTerm={selectedCode.searchTerm}
                />
            )}
        </div>
    );
};

export default G6LineageDiagram;
