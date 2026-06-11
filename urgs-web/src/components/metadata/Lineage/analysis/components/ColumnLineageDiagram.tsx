import React, { useEffect, useMemo, useRef, useState } from 'react';
import ELK from 'elkjs/lib/elk.bundled.js';
import type { ElkNode } from 'elkjs/lib/elk-api';
import { Button, Descriptions, Empty, Modal, Tag, Tooltip } from 'antd';
import { Maximize2, ZoomIn, ZoomOut } from 'lucide-react';
import { LinkData, NodeData, RELATION_STYLES } from '../types';
import CodeModal from './CodeModal';
import LineageImpactPanel from './LineageImpactPanel';
import {
    TABLE_LEVEL_COLUMN,
    buildDensityGraph,
    buildImpactRows,
    buildLocalFieldTraceGraph,
    buildNodeRanks,
    collectRelationOptions,
    getRelationLabel,
    getRelationStyle,
    normalizeArray,
    normalizeRelationType,
    resolveNodeTableIdentity,
    sameTableLoose,
} from '../utils/lineageGraphDensity';

interface ColumnLineageDiagramProps {
    nodes: NodeData[];
    links: LinkData[];
    fieldNodes?: NodeData[];
    fieldLinks?: LinkData[];
    fieldLoading?: boolean;
    fieldDetailsLoaded?: boolean;
    selectedTable: string | null;
    selectedField: { nodeId: string; colId: string } | null;
    onLoadFieldDetails?: () => Promise<void>;
    onTableDoubleClick?: (tableName: string, qualifiedName: string) => void;
    onFieldDoubleClick?: (tableName: string, qualifiedName: string, columnName: string) => void;
}

interface LayoutNode {
    node: NodeData;
    x: number;
    y: number;
    height: number;
    rank: number;
    columns: { id: string; name: string; synthetic?: boolean }[];
}

interface SelectedCode {
    code: string;
    sourceFile?: string;
    linkType?: string;
    searchTerm?: string;
}

interface SelectedRelation {
    link: LinkData;
    sourceTable: string;
    targetTable: string;
    sourceColumns: string[];
    targetColumns: string[];
    sourceFile?: string;
}

interface NodeMetric {
    node: NodeData;
    columns: { id: string; name: string; synthetic?: boolean }[];
    height: number;
    rank: number;
}

const CARD_WIDTH = 290;
const HEADER_HEIGHT = 36;
const OWNER_HEIGHT = 28;
const ROW_HEIGHT = 28;
const RANK_GAP = 190;
const NODE_GAP = 56;
const PADDING = 72;
const MIN_ZOOM = 0.35, MAX_ZOOM = 2.5, ZOOM_STEP = 0.15;
const clampZoom = (value: number) => Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, value));
const elk = new ELK();

const getRelationMarkerId = (type?: string) => (
    `column-lineage-arrow-${normalizeRelationType(type).replace(/[^a-zA-Z0-9_-]/g, '-')}`
);

const getLinkCode = (link: LinkData) => {
    const value = link.properties?.snippet
        || link.properties?.sql
        || link.properties?.expression
        || link.properties?.logic
        || link.properties?.sourceCode
        || link.properties?.code;
    return value ? String(value) : '';
};

const getSourceFile = (link: LinkData) => {
    const sourceFiles = link.properties?.sourceFiles;
    if (Array.isArray(sourceFiles)) {
        return sourceFiles[0] ? String(sourceFiles[0]) : undefined;
    }
    const value = sourceFiles || link.properties?.source_file || link.properties?.sourceFile;
    return value ? String(value) : undefined;
};

const formatColumnSummary = (columns: string[], fallback: string) => {
    if (columns.length === 0) {
        return fallback;
    }
    if (columns.length <= 2) {
        return columns.join('、');
    }
    return `${columns.slice(0, 2).join('、')} 等 ${columns.length} 个字段`;
};

const formatDetailList = (items: string[]) => (items.length > 0 ? items.join('、') : '-');

const getRelationLevelLabel = (level?: string) => {
    switch (level) {
        case 'table_fallback':
            return '表级兜底';
        case 'table_mixed':
            return '字段聚合 + 表级兜底';
        case 'table_from_column':
            return '字段关系聚合';
        case 'table_evidence':
            return '表级解析证据';
        default:
            return level || '字段/表级聚合';
    }
};

const getSourceColumnSearchTerm = (link: LinkData, nodes: NodeData[]) => {
    const sourceNode = nodes.find(node => node.id === link.sourceNodeId);
    const sourceCol = sourceNode?.columns.find(col => col.id === link.sourceColumnId);
    const relationCount = Number(link.properties?.relationCount || 0);
    const sourceColumns = normalizeArray(link.properties?.sourceColumns);
    return sourceCol?.name
        || link.properties?.sourceColumn
        || link.properties?.sourceColumnName
        || formatColumnSummary(sourceColumns, link.sourceColumnId || `表级关系(${relationCount || 1})`);
};

const buildColumnUsage = (links: LinkData[]) => {
    const usage = new Map<string, Set<string>>();
    const addUsage = (nodeId: string, colId: string) => {
        const next = usage.get(nodeId) || new Set<string>();
        next.add(colId || TABLE_LEVEL_COLUMN);
        usage.set(nodeId, next);
    };

    links.forEach(link => {
        addUsage(link.sourceNodeId, link.sourceColumnId);
        addUsage(link.targetNodeId, link.targetColumnId);
    });

    return usage;
};

const getColumnKey = (nodeId: string, colId?: string) => `${nodeId}::${colId || TABLE_LEVEL_COLUMN}`;

const buildLineageHighlight = (startKey: string | null, links: LinkData[]) => {
    const activeLinks = new Set<string>();
    const activeColumns = new Set<string>();
    if (!startKey) {
        return { activeLinks, activeColumns };
    }

    const outgoing = new Map<string, LinkData[]>();
    const incoming = new Map<string, LinkData[]>();
    links.forEach(link => {
        const sourceKey = getColumnKey(link.sourceNodeId, link.sourceColumnId);
        const targetKey = getColumnKey(link.targetNodeId, link.targetColumnId);
        outgoing.set(sourceKey, [...(outgoing.get(sourceKey) || []), link]);
        incoming.set(targetKey, [...(incoming.get(targetKey) || []), link]);
    });

    activeColumns.add(startKey);

    const walk = (
        edgeMap: Map<string, LinkData[]>,
        getNextKey: (link: LinkData) => string
    ) => {
        const visitedColumns = new Set<string>([startKey]);
        const queue = [startKey];
        while (queue.length > 0) {
            const currentKey = queue.shift()!;
            (edgeMap.get(currentKey) || []).forEach(link => {
                activeLinks.add(link.id);
                const sourceKey = getColumnKey(link.sourceNodeId, link.sourceColumnId);
                const targetKey = getColumnKey(link.targetNodeId, link.targetColumnId);
                activeColumns.add(sourceKey);
                activeColumns.add(targetKey);

                const nextKey = getNextKey(link);
                if (!visitedColumns.has(nextKey)) {
                    visitedColumns.add(nextKey);
                    queue.push(nextKey);
                }
            });
        }
    };

    walk(outgoing, link => getColumnKey(link.targetNodeId, link.targetColumnId));
    walk(incoming, link => getColumnKey(link.sourceNodeId, link.sourceColumnId));

    return { activeLinks, activeColumns };
};

const getVisibleColumns = (
    node: NodeData,
    columnUsage: Map<string, Set<string>>,
    selectedField: ColumnLineageDiagramProps['selectedField']
) => {
    const used = columnUsage.get(node.id) || new Set<string>();
    const shouldShowAll = node.id === selectedField?.nodeId || node.columns.length <= 16;
    const baseColumns = shouldShowAll
        ? node.columns
        : node.columns.filter(col => used.has(col.id));
    const columns = baseColumns.length > 0 ? baseColumns : node.columns.slice(0, 16);
    const result: Array<{ id: string; name: string; synthetic?: boolean }> = columns.map(col => ({ id: col.id, name: col.name }));
    if (used.has(TABLE_LEVEL_COLUMN)) {
        result.unshift({ id: TABLE_LEVEL_COLUMN, name: '表级关系', synthetic: true });
    }
    return result;
};

const buildPath = (source: { x: number; y: number }, target: { x: number; y: number }) => {
    const forward = source.x <= target.x;
    const distance = Math.max(80, Math.abs(target.x - source.x) * 0.45);
    const c1x = forward ? source.x + distance : source.x - distance;
    const c2x = forward ? target.x - distance : target.x + distance;
    return `M ${source.x} ${source.y} C ${c1x} ${source.y}, ${c2x} ${target.y}, ${target.x} ${target.y}`;
};

const ColumnLineageDiagram: React.FC<ColumnLineageDiagramProps> = ({
    nodes,
    links,
    fieldNodes = [],
    fieldLinks = [],
    fieldLoading = false,
    fieldDetailsLoaded = false,
    selectedTable,
    selectedField,
    onLoadFieldDetails,
    onTableDoubleClick,
    onFieldDoubleClick,
}) => {
    const scrollContainerRef = useRef<HTMLDivElement>(null);
    const panStartRef = useRef({ clientX: 0, clientY: 0, x: 0, y: 0 });
    const zoomRef = useRef(1);
    const panOffsetRef = useRef({ x: 0, y: 0 });
    const [activeLinkId, setActiveLinkId] = useState<string | null>(null);
    const [activeColumnKey, setActiveColumnKey] = useState<string | null>(null);
    const [pinnedColumnKey, setPinnedColumnKey] = useState<string | null>(null);
    const [focusedNodeId, setFocusedNodeId] = useState<string | null>(null);
    const [focusedLinkId, setFocusedLinkId] = useState<string | null>(null);
    const [fieldTraceEnabled, setFieldTraceEnabled] = useState(false);
    const [zoom, setZoom] = useState(1);
    const [panOffset, setPanOffset] = useState({ x: 0, y: 0 });
    const [isPanning, setIsPanning] = useState(false);
    const [elkPositions, setElkPositions] = useState<Map<string, { y: number }> | null>(null);
    const relationOptions = useMemo(() => collectRelationOptions(links), [links]);
    const relationOptionsKey = relationOptions.join('|');
    const [selectedRelationTypes, setSelectedRelationTypes] = useState<string[]>([]);
    const [codeModalVisible, setCodeModalVisible] = useState(false);
    const [selectedCode, setSelectedCode] = useState<SelectedCode | null>(null);
    const [relationModalVisible, setRelationModalVisible] = useState(false);
    const [selectedRelation, setSelectedRelation] = useState<SelectedRelation | null>(null);

    useEffect(() => {
        setSelectedRelationTypes(relationOptions);
    }, [relationOptionsKey]);

    useEffect(() => {
        zoomRef.current = zoom;
    }, [zoom]);

    useEffect(() => {
        panOffsetRef.current = panOffset;
    }, [panOffset]);

    const activeRelationTypes = selectedRelationTypes.length > 0 ? selectedRelationTypes : relationOptions;
    const graphInput = useMemo(() => (
        fieldTraceEnabled
            ? buildLocalFieldTraceGraph({
                tableNodes: nodes,
                tableLinks: links,
                fieldNodes,
                fieldLinks,
                selectedTable,
                focusedNodeId,
                focusedLinkId,
            })
            : { nodes, links }
    ), [fieldLinks, fieldNodes, fieldTraceEnabled, focusedLinkId, focusedNodeId, links, nodes, selectedTable]);

    const densityGraph = useMemo(() => (
        buildDensityGraph({
            nodes: graphInput.nodes,
            links: graphInput.links,
            selectedTable,
            selectedField,
            focusedNodeId,
            compactEnabled: false,
            perLayerLimit: Number.MAX_SAFE_INTEGER,
            relationTypes: activeRelationTypes,
        })
    ), [activeRelationTypes, focusedNodeId, graphInput, selectedField, selectedTable]);

    const displayNodes = densityGraph.nodes;
    const displayLinks = densityGraph.links;
    const impactRows = useMemo(() => (
        buildImpactRows(nodes, links, selectedTable, selectedField)
    ), [links, nodes, selectedField, selectedTable]);

    const layoutInput = useMemo(() => {
        const columnUsage = buildColumnUsage(displayLinks);
        const ranks = buildNodeRanks(displayNodes, displayLinks, selectedTable, selectedField);
        const sortedRanks = Array.from(new Set(displayNodes.map(node => ranks.get(node.id) || 0))).sort((a, b) => a - b);
        const minRank = sortedRanks[0] || 0;

        const nodeMetrics: NodeMetric[] = displayNodes.map(node => {
            const columns = getVisibleColumns(node, columnUsage, selectedField);
            const ownerHeight = resolveNodeTableIdentity(node).owner ? OWNER_HEIGHT : 0;
            const height = HEADER_HEIGHT + ownerHeight + Math.max(1, columns.length) * ROW_HEIGHT;
            const rank = ranks.get(node.id) || 0;
            return { node, columns, height, rank };
        });

        return { nodeMetrics, minRank };
    }, [displayLinks, displayNodes, selectedField, selectedTable]);

    useEffect(() => {
        if (layoutInput.nodeMetrics.length === 0) {
            setElkPositions(new Map());
            return;
        }

        let cancelled = false;
        const nodeIds = new Set(layoutInput.nodeMetrics.map(item => item.node.id));
        const graph: ElkNode = {
            id: 'column-lineage-root',
            layoutOptions: {
                'elk.algorithm': 'layered',
                'elk.direction': 'RIGHT',
                'elk.edgeRouting': 'SPLINES',
                'elk.spacing.nodeNode': String(NODE_GAP),
                'elk.layered.spacing.nodeNodeBetweenLayers': String(RANK_GAP),
                'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
                'elk.layered.nodePlacement.strategy': 'NETWORK_SIMPLEX',
                'elk.layered.considerModelOrder.strategy': 'NODES_AND_EDGES',
                'elk.layered.cycleBreaking.strategy': 'GREEDY',
                'elk.padding': `[top=${PADDING},left=${PADDING},bottom=${PADDING},right=${PADDING}]`,
            },
            children: layoutInput.nodeMetrics.map(item => ({
                id: item.node.id,
                width: CARD_WIDTH,
                height: item.height,
            })),
            edges: displayLinks
                .filter(link => nodeIds.has(link.sourceNodeId) && nodeIds.has(link.targetNodeId))
                .map(link => ({
                    id: link.id,
                    sources: [link.sourceNodeId],
                    targets: [link.targetNodeId],
                })),
        };

        elk.layout(graph)
            .then(result => {
                if (cancelled) {
                    return;
                }
                const nextPositions = new Map<string, { y: number }>();
                result.children?.forEach(child => {
                    nextPositions.set(child.id, { y: child.y || 0 });
                });
                setElkPositions(nextPositions);
            })
            .catch(() => {
                if (!cancelled) {
                    setElkPositions(new Map());
                }
            });

        return () => {
            cancelled = true;
        };
    }, [displayLinks, layoutInput]);

    const layout = useMemo(() => {
        const rowAnchors = new Map<string, { left: { x: number; y: number }; right: { x: number; y: number } }>();
        const rawLayoutNodes = layoutInput.nodeMetrics.map(({ node, columns, height, rank }, index) => {
            const x = PADDING + (rank - layoutInput.minRank) * (CARD_WIDTH + RANK_GAP);
            const y = elkPositions?.get(node.id)?.y ?? PADDING + index * (height + NODE_GAP);
            const ownerHeight = resolveNodeTableIdentity(node).owner ? OWNER_HEIGHT : 0;
            return { node, x, y, height, rank, columns, ownerHeight };
        });
        const nodesByRank = new Map<number, typeof rawLayoutNodes>();
        rawLayoutNodes.forEach(item => {
            nodesByRank.set(item.rank, [...(nodesByRank.get(item.rank) || []), item]);
        });

        const stackedLayoutNodes = Array.from(nodesByRank.entries()).flatMap(([, rankNodes]) => {
            let nextY = PADDING;
            return rankNodes
                .slice()
                .sort((a, b) => a.y - b.y || a.node.title.localeCompare(b.node.title))
                .map(item => {
                    const y = Math.max(item.y, nextY);
                    nextY = y + item.height + NODE_GAP;
                    return { ...item, y };
                });
        });

        const minY = Math.min(PADDING, ...stackedLayoutNodes.map(item => item.y));
        const yShift = PADDING - minY;
        const layoutNodes: LayoutNode[] = stackedLayoutNodes
            .map(({ ownerHeight, ...item }) => ({
                ...item,
                y: item.y + yShift,
                ownerHeight,
            }))
            .sort((a, b) => a.rank - b.rank || a.y - b.y || a.node.title.localeCompare(b.node.title));

        layoutNodes.forEach(item => {
            const ownerHeight = resolveNodeTableIdentity(item.node).owner ? OWNER_HEIGHT : 0;
            item.columns.forEach((col, index) => {
                const rowY = item.y + HEADER_HEIGHT + ownerHeight + index * ROW_HEIGHT + ROW_HEIGHT / 2;
                rowAnchors.set(getColumnKey(item.node.id, col.id), {
                    left: { x: item.x, y: rowY },
                    right: { x: item.x + CARD_WIDTH, y: rowY },
                });
            });
        });

        const width = Math.max(1200, ...layoutNodes.map(item => item.x + CARD_WIDTH + PADDING));
        const height = Math.max(640, ...layoutNodes.map(item => item.y + item.height + PADDING));
        return { layoutNodes, rowAnchors, width, height };
    }, [elkPositions, layoutInput]);

    const selectedFieldKey = selectedField ? `${selectedField.nodeId}::${selectedField.colId}` : '';
    const focusColumnKey = pinnedColumnKey || activeColumnKey;
    const highlighted = useMemo(() => (
        buildLineageHighlight(focusColumnKey, displayLinks)
    ), [displayLinks, focusColumnKey]);
    const hasColumnFocus = !!focusColumnKey;
    const relationLegend = useMemo(() => {
        const order = new Map(Object.keys(RELATION_STYLES).map((type, index) => [type, index]));
        return Array.from(new Set(displayLinks.map(link => normalizeRelationType(link.type))))
            .sort((a, b) => (order.get(a) ?? 99) - (order.get(b) ?? 99) || a.localeCompare(b))
            .map(type => ({ type, style: getRelationStyle(type), label: getRelationLabel(type) }));
    }, [displayLinks]);

    useEffect(() => {
        if (!focusedNodeId || !scrollContainerRef.current) {
            return;
        }
        const item = layout.layoutNodes.find(node => node.node.id === focusedNodeId);
        if (!item) {
            return;
        }
        const currentZoom = zoomRef.current;
        setPanOffset({
            x: 120 - item.x * currentZoom,
            y: 120 - item.y * currentZoom,
        });
    }, [focusedNodeId, layout]);

    useEffect(() => {
        if (!isPanning) {
            return;
        }

        const handleMouseMove = (event: MouseEvent) => {
            const deltaX = event.clientX - panStartRef.current.clientX;
            const deltaY = event.clientY - panStartRef.current.clientY;
            setPanOffset({
                x: panStartRef.current.x + deltaX,
                y: panStartRef.current.y + deltaY,
            });
        };

        const handleMouseUp = () => setIsPanning(false);

        window.addEventListener('mousemove', handleMouseMove);
        window.addEventListener('mouseup', handleMouseUp);
        return () => {
            window.removeEventListener('mousemove', handleMouseMove);
            window.removeEventListener('mouseup', handleMouseUp);
        };
    }, [isPanning]);

    if (nodes.length === 0) {
        return <Empty description="暂无流程图数据" style={{ marginTop: 100 }} />;
    }

    const handleFocusNode = (nodeId: string) => {
        setFocusedNodeId(nodeId);
        setFocusedLinkId(null);
        setPinnedColumnKey(null);
    };

    const handleToggleFieldTrace = async () => {
        if (fieldTraceEnabled) {
            setFieldTraceEnabled(false);
            return;
        }
        if (!fieldDetailsLoaded) {
            await onLoadFieldDetails?.();
        }
        setFieldTraceEnabled(true);
    };

    const handleLinkClick = (link: LinkData) => {
        setFocusedLinkId(link.id);
        setFocusedNodeId(null);
        const code = getLinkCode(link);
        if (!code) {
            const sourceNode = displayNodes.find(node => node.id === link.sourceNodeId) || nodes.find(node => node.id === link.sourceNodeId);
            const targetNode = displayNodes.find(node => node.id === link.targetNodeId) || nodes.find(node => node.id === link.targetNodeId);
            setSelectedRelation({
                link,
                sourceTable: sourceNode?.title || link.properties?.sourceTable || '-',
                targetTable: targetNode?.title || link.properties?.targetTable || '-',
                sourceColumns: normalizeArray(link.properties?.sourceColumns),
                targetColumns: normalizeArray(link.properties?.targetColumns),
                sourceFile: getSourceFile(link),
            });
            setRelationModalVisible(true);
            return;
        }
        setSelectedCode({
            code,
            sourceFile: getSourceFile(link),
            linkType: normalizeRelationType(link.type),
            searchTerm: getSourceColumnSearchTerm(link, displayNodes),
        });
        setCodeModalVisible(true);
    };

    const updateZoom = (
        nextZoom: number | ((currentZoom: number) => number),
        clientPoint?: { x: number; y: number }
    ) => {
        const container = scrollContainerRef.current;
        setZoom(currentZoom => {
            const resolvedZoom = clampZoom(typeof nextZoom === 'function' ? nextZoom(currentZoom) : nextZoom);
            if (Math.abs(resolvedZoom - currentZoom) < 0.001) {
                return currentZoom;
            }

            if (container) {
                const rect = container.getBoundingClientRect();
                const pointerX = clientPoint ? clientPoint.x - rect.left : Math.max(120, (rect.width - 420) / 2);
                const pointerY = clientPoint ? clientPoint.y - rect.top : rect.height / 2;
                const currentPan = panOffsetRef.current;
                const graphX = (pointerX - currentPan.x) / currentZoom;
                const graphY = (pointerY - currentPan.y) / currentZoom;
                setPanOffset({
                    x: pointerX - graphX * resolvedZoom,
                    y: pointerY - graphY * resolvedZoom,
                });
            }

            return resolvedZoom;
        });
    };

    const handleCanvasMouseDown = (event: React.MouseEvent<SVGRectElement>) => {
        if (event.button !== 0 || !scrollContainerRef.current) {
            return;
        }
        event.preventDefault();
        setPinnedColumnKey(null);
        panStartRef.current = {
            clientX: event.clientX,
            clientY: event.clientY,
            x: panOffsetRef.current.x,
            y: panOffsetRef.current.y,
        };
        setIsPanning(true);
    };

    const handleResetViewport = () => {
        setZoom(1);
        setPanOffset({ x: 0, y: 0 });
    };

    return (
        <div className="relative h-full w-full bg-[#f1f2f4]" style={{ minHeight: 640 }}>
            <div
                ref={scrollContainerRef}
                className="h-full w-full overflow-hidden pr-[420px]"
                style={{ minHeight: 640, cursor: isPanning ? 'grabbing' : undefined, userSelect: isPanning ? 'none' : undefined }}
            >
            <div
                className="relative"
                style={{ width: '100%', height: '100%', minHeight: 640 }}
                onClick={() => setPinnedColumnKey(null)}
            >
                <div
                    className="absolute left-0 top-0"
                    style={{
                        width: layout.width,
                        height: layout.height,
                        transform: `translate(${panOffset.x}px, ${panOffset.y}px) scale(${zoom})`,
                        transformOrigin: '0 0',
                    }}
                >
                <svg className="absolute inset-0" width={layout.width} height={layout.height}>
                    <defs>
                        {relationLegend.map(({ type, style }) => (
                            <marker
                                key={type}
                                id={getRelationMarkerId(type)}
                                markerWidth="10"
                                markerHeight="8"
                                refX="9"
                                refY="4"
                                orient="auto"
                                markerUnits="strokeWidth"
                            >
                                <path d="M 0 0 L 10 4 L 0 8 z" fill={style.highlightColor} />
                            </marker>
                        ))}
                    </defs>
                    <rect
                        x={0}
                        y={0}
                        width={layout.width}
                        height={layout.height}
                        fill="transparent"
                        style={{ cursor: isPanning ? 'grabbing' : 'grab' }}
                        onMouseDown={handleCanvasMouseDown}
                    />
                    {displayLinks.map(link => {
                        const sourceKey = getColumnKey(link.sourceNodeId, link.sourceColumnId);
                        const targetKey = getColumnKey(link.targetNodeId, link.targetColumnId);
                        const sourceAnchor = layout.rowAnchors.get(sourceKey) || layout.rowAnchors.get(getColumnKey(link.sourceNodeId));
                        const targetAnchor = layout.rowAnchors.get(targetKey) || layout.rowAnchors.get(getColumnKey(link.targetNodeId));
                        if (!sourceAnchor || !targetAnchor) {
                            return null;
                        }
                        const source = sourceAnchor.right.x <= targetAnchor.left.x ? sourceAnchor.right : sourceAnchor.left;
                        const target = sourceAnchor.right.x <= targetAnchor.left.x ? targetAnchor.left : targetAnchor.right;
                        const isActive = activeLinkId === link.id
                            || highlighted.activeLinks.has(link.id)
                            || sourceKey === selectedFieldKey
                            || targetKey === selectedFieldKey;
                        const relationType = normalizeRelationType(link.type);
                        const style = getRelationStyle(relationType);
                        return (
                            <path
                                key={link.id}
                                d={buildPath(source, target)}
                                fill="none"
                                stroke={isActive ? style.highlightColor : style.color}
                                strokeWidth={isActive ? 3 : 1.6}
                                strokeDasharray={style.strokeDasharray}
                                markerEnd={`url(#${getRelationMarkerId(relationType)})`}
                                opacity={(activeLinkId || hasColumnFocus) && !isActive ? 0.12 : (isActive ? 1 : 0.62)}
                                style={{ cursor: 'pointer', pointerEvents: 'stroke' }}
                                onMouseEnter={() => setActiveLinkId(link.id)}
                                onMouseLeave={() => setActiveLinkId(null)}
                                onClick={() => handleLinkClick(link)}
                            />
                        );
                    })}
                </svg>

                {layout.layoutNodes.map(item => {
                    const { owner, table } = resolveNodeTableIdentity(item.node);
                    const isSelectedTable = sameTableLoose(item.node.title, selectedTable) || item.node.id === selectedField?.nodeId;
                    const hasOutgoing = displayLinks.some(link => link.sourceNodeId === item.node.id);
                    const hasIncoming = displayLinks.some(link => link.targetNodeId === item.node.id);
                    const isFocusedTable = focusedNodeId === item.node.id;
                    const headerColor = item.node.isGroupNode
                        ? '#64748b'
                        : (isSelectedTable ? '#b84f83' : (!hasOutgoing && hasIncoming ? '#d66b59' : '#8bc34a'));
                    return (
                        <div
                            key={item.node.id}
                            className="absolute overflow-hidden border bg-white shadow-sm"
                            style={{
                                left: item.x,
                                top: item.y,
                                width: CARD_WIDTH,
                                minHeight: item.height,
                                borderColor: isFocusedTable ? '#1677ff' : headerColor,
                                boxShadow: isFocusedTable ? '0 0 0 3px rgba(22, 119, 255, 0.18)' : undefined,
                            }}
                        >
                            <div
                                className="flex h-9 items-center justify-center px-3 text-base font-semibold text-white"
                                style={{ background: headerColor, cursor: item.node.isGroupNode ? 'default' : 'pointer' }}
                                title={item.node.isGroupNode ? item.node.title : `${item.node.title}（单击定位，双击切换为当前表）`}
                                onClick={(event) => {
                                    event.stopPropagation();
                                    if (!item.node.isGroupNode) {
                                        handleFocusNode(item.node.id);
                                    }
                                }}
                                onDoubleClick={(event) => {
                                    event.stopPropagation();
                                    if (!item.node.isGroupNode) {
                                        onTableDoubleClick?.(table, item.node.title);
                                    }
                                }}
                            >
                                <span className="truncate">{table}</span>
                            </div>
                            {owner ? (
                                <div className="flex h-7 items-center border-b border-slate-100 bg-slate-50 px-3 text-[11px] text-slate-500">
                                    {owner}
                                </div>
                            ) : null}
                            <div>
                                {item.columns.map(col => {
                                    const rowKey = getColumnKey(item.node.id, col.id);
                                    const isSelected = rowKey === selectedFieldKey;
                                    const isLinkActive = displayLinks.some(link => (
                                        link.id === activeLinkId
                                        && ((link.sourceNodeId === item.node.id && (link.sourceColumnId || TABLE_LEVEL_COLUMN) === col.id)
                                            || (link.targetNodeId === item.node.id && (link.targetColumnId || TABLE_LEVEL_COLUMN) === col.id))
                                    ));
                                    const isActive = isLinkActive || highlighted.activeColumns.has(rowKey) || activeColumnKey === rowKey;
                                    return (
                                        <div
                                            key={rowKey}
                                            className="flex h-7 items-center border-b border-slate-100 px-3 text-sm text-slate-800 last:border-b-0"
                                            style={{
                                                background: isSelected ? '#fdebd3' : (isActive ? '#e5e7eb' : '#ffffff'),
                                                fontWeight: isSelected || isActive ? 600 : 400,
                                                opacity: hasColumnFocus && !isActive ? 0.46 : 1,
                                                cursor: 'pointer',
                                            }}
                                            onMouseEnter={() => {
                                                if (!pinnedColumnKey) {
                                                    setActiveColumnKey(rowKey);
                                                }
                                            }}
                                            onMouseLeave={() => {
                                                if (!pinnedColumnKey) {
                                                    setActiveColumnKey(null);
                                                }
                                            }}
                                            onClick={(event) => {
                                                event.stopPropagation();
                                                setPinnedColumnKey(rowKey);
                                                setActiveColumnKey(null);
                                            }}
                                            onDoubleClick={(event) => {
                                                event.stopPropagation();
                                                if (!item.node.isGroupNode && !col.synthetic) {
                                                    onFieldDoubleClick?.(table, item.node.title, col.name);
                                                }
                                            }}
                                        >
                                            <span className="truncate" title={col.name}>{col.name}</span>
                                            {col.synthetic ? <Tag className="ml-auto" color="default">表级</Tag> : null}
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    );
                })}
                {relationLegend.length > 0 ? (
                    <div className="sticky left-5 top-5 z-20 inline-flex max-w-[520px] flex-wrap gap-x-4 gap-y-2 rounded-md border border-slate-200 bg-white/92 px-3 py-2 text-xs text-slate-600 shadow-sm backdrop-blur">
                        {relationLegend.map(({ type, style, label }) => (
                            <div key={type} className="flex items-center gap-2">
                                <svg width="34" height="10" viewBox="0 0 34 10" aria-hidden="true">
                                    <line
                                        x1="1"
                                        y1="5"
                                        x2="31"
                                        y2="5"
                                        stroke={style.color}
                                        strokeWidth="2"
                                        strokeLinecap="round"
                                        strokeDasharray={style.strokeDasharray}
                                    />
                                    <path d="M 28 1 L 34 5 L 28 9 z" fill={style.color} />
                                </svg>
                                <span>{label}</span>
                            </div>
                        ))}
                    </div>
                ) : null}
                </div>
            </div>
            </div>
            <div className="absolute bottom-6 left-6 z-30 flex gap-2 rounded-xl border border-slate-200 bg-white/90 p-2 shadow-lg backdrop-blur">
                <Tooltip title="放大" placement="top">
                    <Button
                        shape="circle"
                        icon={<ZoomIn size={16} />}
                        disabled={zoom >= MAX_ZOOM}
                        onClick={() => updateZoom(currentZoom => currentZoom + ZOOM_STEP)}
                    />
                </Tooltip>
                <Tooltip title="缩小" placement="top">
                    <Button
                        shape="circle"
                        icon={<ZoomOut size={16} />}
                        disabled={zoom <= MIN_ZOOM}
                        onClick={() => updateZoom(currentZoom => currentZoom - ZOOM_STEP)}
                    />
                </Tooltip>
                <Tooltip title="重置视图" placement="top">
                    <Button
                        shape="circle"
                        icon={<Maximize2 size={16} />}
                        onClick={handleResetViewport}
                    />
                </Tooltip>
            </div>
            <LineageImpactPanel
                rows={impactRows}
                stats={densityGraph.stats}
                relationOptions={relationOptions}
                selectedRelationTypes={activeRelationTypes}
                fieldTraceEnabled={fieldTraceEnabled}
                fieldTraceLoading={fieldLoading}
                onRelationTypesChange={setSelectedRelationTypes}
                onToggleFieldTrace={handleToggleFieldTrace}
                onFocusTable={handleFocusNode}
                onOpenTable={onTableDoubleClick}
            />
            {selectedCode ? (
                <CodeModal
                    visible={codeModalVisible}
                    onClose={() => setCodeModalVisible(false)}
                    code={selectedCode.code}
                    title="逻辑/源码"
                    sourceFile={selectedCode.sourceFile}
                    linkType={selectedCode.linkType}
                    searchTerm={selectedCode.searchTerm}
                />
            ) : null}
            {selectedRelation ? (
                <Modal
                    open={relationModalVisible}
                    title="关系来源详情"
                    footer={null}
                    width={720}
                    onCancel={() => setRelationModalVisible(false)}
                >
                    <Descriptions size="small" bordered column={1}>
                        <Descriptions.Item label="源表">{selectedRelation.sourceTable}</Descriptions.Item>
                        <Descriptions.Item label="目标表">{selectedRelation.targetTable}</Descriptions.Item>
                        <Descriptions.Item label="关联类型">
                            <Tag color={getRelationStyle(selectedRelation.link.type).color}>
                                {getRelationLabel(selectedRelation.link.type)}
                            </Tag>
                        </Descriptions.Item>
                        <Descriptions.Item label="证据层级">
                            {getRelationLevelLabel(selectedRelation.link.properties?.relationLevel)}
                        </Descriptions.Item>
                        <Descriptions.Item label="关系数量">
                            共 {selectedRelation.link.properties?.relationCount || 1} 条
                            {selectedRelation.link.properties?.fieldRelationCount !== undefined
                                ? `，字段级 ${selectedRelation.link.properties.fieldRelationCount} 条`
                                : ''}
                            {selectedRelation.link.properties?.fallbackRelationCount
                                ? `，表级兜底 ${selectedRelation.link.properties.fallbackRelationCount} 条`
                                : ''}
                        </Descriptions.Item>
                        <Descriptions.Item label="源字段">
                            {formatDetailList(selectedRelation.sourceColumns)}
                        </Descriptions.Item>
                        <Descriptions.Item label="目标字段">
                            {formatDetailList(selectedRelation.targetColumns)}
                        </Descriptions.Item>
                        <Descriptions.Item label="源文件">
                            {selectedRelation.sourceFile || '-'}
                        </Descriptions.Item>
                        <Descriptions.Item label="解析来源">
                            {formatDetailList(normalizeArray(selectedRelation.link.properties?.lineageOrigins))}
                        </Descriptions.Item>
                        <Descriptions.Item label="说明">
                            数据库中存在该血缘关系，但该关系没有保存可打开的 SQL snippet。若证据层级为表级兜底，表示解析器识别到了表到表影响，但没有拿到字段级映射。
                        </Descriptions.Item>
                    </Descriptions>
                </Modal>
            ) : null}
        </div>
    );
};

export default ColumnLineageDiagram;
