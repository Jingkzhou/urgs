import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import ELK from 'elkjs/lib/elk.bundled.js';
import type { ElkNode, ElkPoint } from 'elkjs/lib/elk-api';
import { Button, Descriptions, Empty, Modal, Tag, Tooltip } from 'antd';
import { Maximize2, ZoomIn, ZoomOut } from 'lucide-react';
import { LinkData, NodeData, RELATION_STYLES } from '../types';
import LineageImpactPanel from './LineageImpactPanel';
import RelationEvidencePanel, { getLinkEvidenceCount } from './RelationEvidencePanel';
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
    onTableDoubleClick?: (tableName: string, qualifiedName: string, objectUid?: string) => void;
    onFieldDoubleClick?: (tableName: string, qualifiedName: string, columnName: string, objectUid?: string) => void;
}

interface LayoutNode {
    node: NodeData;
    x: number;
    y: number;
    height: number;
    rank: number;
    columns: { id: string; name: string; synthetic?: boolean }[];
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

interface ElkLayoutState {
    nodePositions: Map<string, { x: number; y: number }>;
    width: number;
    height: number;
}

interface CurveGeometry {
    path: string;
    midpoint: ElkPoint;
}

const CARD_WIDTH = 290;
const HEADER_HEIGHT = 36;
const OWNER_HEIGHT = 28;
const ROW_HEIGHT = 28;
const RANK_GAP = 190;
const NODE_GAP = 56;
const PADDING = 120;
const MIN_ZOOM = 0.35, MAX_ZOOM = 2.5, ZOOM_STEP = 0.15;
const clampZoom = (value: number) => Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, value));
const elk = new ELK();

const getRelationMarkerId = (type?: string) => (
    `column-lineage-arrow-${normalizeRelationType(type).replace(/[^a-zA-Z0-9_-]/g, '-')}`
);

const getSourceFile = (link: LinkData) => {
    const sourceFiles = link.properties?.sourceFiles;
    if (Array.isArray(sourceFiles)) {
        return sourceFiles[0] ? String(sourceFiles[0]) : undefined;
    }
    const value = sourceFiles || link.properties?.source_file || link.properties?.sourceFile;
    return value ? String(value) : undefined;
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
const getPortId = (nodeId: string, colId: string | undefined, side: 'left' | 'right') => (
    `${getColumnKey(nodeId, colId)}::${side}`
);
const getEdgePortId = (
    linkId: string,
    nodeId: string,
    colId: string | undefined,
    side: 'left' | 'right',
    role: 'source' | 'target'
) => (
    `${getPortId(nodeId, colId, side)}::${linkId}::${role}`
);

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

const buildLinkLaneOffsets = (links: LinkData[]) => {
    const directions = new Set<string>();
    const endpointGroups = new Map<string, { sourceNodeId: string; targetNodeId: string; links: LinkData[] }>();
    links.forEach(link => {
        directions.add(`${link.sourceNodeId}=>${link.targetNodeId}`);
        const endpointKey = [
            link.sourceNodeId,
            link.sourceColumnId || TABLE_LEVEL_COLUMN,
            link.targetNodeId,
            link.targetColumnId || TABLE_LEVEL_COLUMN,
        ].join('=>');
        const group = endpointGroups.get(endpointKey) || {
            sourceNodeId: link.sourceNodeId,
            targetNodeId: link.targetNodeId,
            links: [],
        };
        group.links.push(link);
        endpointGroups.set(endpointKey, group);
    });

    const offsets = new Map<string, number>();
    endpointGroups.forEach(({ sourceNodeId, targetNodeId, links: group }) => {
        const hasReverse = directions.has(`${targetNodeId}=>${sourceNodeId}`);
        const directionOffset = hasReverse ? (sourceNodeId.localeCompare(targetNodeId) <= 0 ? -18 : 18) : 0;
        const orderedGroup = group.slice().sort((a, b) => (
            (a.sourceColumnId || '').localeCompare(b.sourceColumnId || '')
            || (a.targetColumnId || '').localeCompare(b.targetColumnId || '')
            || normalizeRelationType(a.type).localeCompare(normalizeRelationType(b.type))
            || a.id.localeCompare(b.id)
        ));
        orderedGroup.forEach((link, index) => {
            const sameDirectionOffset = (index - (orderedGroup.length - 1) / 2) * 9;
            offsets.set(link.id, directionOffset + sameDirectionOffset);
        });
    });
    return offsets;
};

const getCubicPoint = (
    start: ElkPoint,
    control1: ElkPoint,
    control2: ElkPoint,
    end: ElkPoint,
    t: number
): ElkPoint => {
    const inverse = 1 - t;
    return {
        x: inverse ** 3 * start.x
            + 3 * inverse ** 2 * t * control1.x
            + 3 * inverse * t ** 2 * control2.x
            + t ** 3 * end.x,
        y: inverse ** 3 * start.y
            + 3 * inverse ** 2 * t * control1.y
            + 3 * inverse * t ** 2 * control2.y
            + t ** 3 * end.y,
    };
};

const buildCurveGeometry = (
    source: ElkPoint,
    target: ElkPoint,
    laneOffset = 0,
    sameRankSide: 'left' | 'right' | null = null
): CurveGeometry => {
    const laneBend = laneOffset * 2.4;
    let control1: ElkPoint;
    let control2: ElkPoint;
    if (sameRankSide) {
        const sideDirection = sameRankSide === 'right' ? 1 : -1;
        const controlDistance = 88 + Math.min(160, Math.abs(target.y - source.y) * 0.35) + Math.abs(laneOffset);
        control1 = {
            x: source.x + sideDirection * controlDistance,
            y: source.y + laneBend,
        };
        control2 = {
            x: target.x + sideDirection * controlDistance,
            y: target.y + laneBend,
        };
    } else {
        const direction = target.x >= source.x ? 1 : -1;
        const controlDistance = Math.max(72, Math.abs(target.x - source.x) * 0.42);
        control1 = {
            x: source.x + direction * controlDistance,
            y: source.y + laneBend,
        };
        control2 = {
            x: target.x - direction * controlDistance,
            y: target.y + laneBend,
        };
    }
    return {
        path: `M ${source.x} ${source.y} C ${control1.x} ${control1.y}, ${control2.x} ${control2.y}, ${target.x} ${target.y}`,
        midpoint: getCubicPoint(source, control1, control2, target, 0.5),
    };
};

const getLinkPortSides = (
    link: LinkData,
    ranks: Map<string, number>,
    directions: Set<string>
): { source: 'left' | 'right'; target: 'left' | 'right' } => {
    const sourceRank = ranks.get(link.sourceNodeId) || 0;
    const targetRank = ranks.get(link.targetNodeId) || 0;
    if (sourceRank < targetRank) {
        return { source: 'right', target: 'left' };
    }
    if (sourceRank > targetRank) {
        return { source: 'left', target: 'right' };
    }
    const hasReverse = directions.has(`${link.targetNodeId}=>${link.sourceNodeId}`);
    const side = !hasReverse || link.sourceNodeId.localeCompare(link.targetNodeId) <= 0 ? 'right' : 'left';
    return { source: side, target: side };
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
    const nodeDragStartRef = useRef<{ nodeId: string; clientX: number; clientY: number; x: number; y: number } | null>(null);
    const suppressNodeClickRef = useRef(false);
    const lastAutoFitKeyRef = useRef('');
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
    const [draggingNodeId, setDraggingNodeId] = useState<string | null>(null);
    const [manualNodePositions, setManualNodePositions] = useState<Map<string, { x: number; y: number }>>(new Map());
    const [elkLayout, setElkLayout] = useState<ElkLayoutState | null>(null);
    const relationOptions = useMemo(() => collectRelationOptions(links), [links]);
    const relationOptionsKey = relationOptions.join('|');
    const [selectedRelationTypes, setSelectedRelationTypes] = useState<string[]>([]);
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
    const linkLaneOffsets = useMemo(() => buildLinkLaneOffsets(displayLinks), [displayLinks]);
    const linkDirections = useMemo(() => new Set(
        displayLinks.map(link => `${link.sourceNodeId}=>${link.targetNodeId}`)
    ), [displayLinks]);
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
            setElkLayout({ nodePositions: new Map(), width: 0, height: 0 });
            return;
        }

        let cancelled = false;
        setElkLayout(null);
        const nodeIds = new Set(layoutInput.nodeMetrics.map(item => item.node.id));
        const ranks = new Map(layoutInput.nodeMetrics.map(item => [item.node.id, item.rank]));
        const metricsByNodeId = new Map(layoutInput.nodeMetrics.map(item => [item.node.id, item]));
        const nodeColumnKeys = new Map(layoutInput.nodeMetrics.map(item => [
            item.node.id,
            new Set(item.columns.map(column => getColumnKey(item.node.id, column.id))),
        ]));
        const edgePortAssignments = new Map(displayLinks.flatMap(link => {
            const sourceMetric = metricsByNodeId.get(link.sourceNodeId);
            const targetMetric = metricsByNodeId.get(link.targetNodeId);
            const sourceColumnId = link.sourceColumnId || TABLE_LEVEL_COLUMN;
            const targetColumnId = link.targetColumnId || TABLE_LEVEL_COLUMN;
            const sourceIndex = sourceMetric?.columns.findIndex(column => column.id === sourceColumnId) ?? -1;
            const targetIndex = targetMetric?.columns.findIndex(column => column.id === targetColumnId) ?? -1;
            if (!sourceMetric || !targetMetric || sourceIndex < 0 || targetIndex < 0) {
                return [];
            }
            const sides = getLinkPortSides(link, ranks, linkDirections);
            const laneOffset = Math.max(-8, Math.min(8, linkLaneOffsets.get(link.id) || 0));
            const sourceOwnerHeight = resolveNodeTableIdentity(sourceMetric.node).owner ? OWNER_HEIGHT : 0;
            const targetOwnerHeight = resolveNodeTableIdentity(targetMetric.node).owner ? OWNER_HEIGHT : 0;
            return [[link.id, {
                source: {
                    id: getEdgePortId(link.id, link.sourceNodeId, link.sourceColumnId, sides.source, 'source'),
                    side: sides.source,
                    y: HEADER_HEIGHT + sourceOwnerHeight + sourceIndex * ROW_HEIGHT + ROW_HEIGHT / 2 + laneOffset,
                },
                target: {
                    id: getEdgePortId(link.id, link.targetNodeId, link.targetColumnId, sides.target, 'target'),
                    side: sides.target,
                    y: HEADER_HEIGHT + targetOwnerHeight + targetIndex * ROW_HEIGHT + ROW_HEIGHT / 2 + laneOffset,
                },
            }] as const];
        }));
        const graph: ElkNode = {
            id: 'column-lineage-root',
            layoutOptions: {
                'elk.algorithm': 'layered',
                'elk.direction': 'RIGHT',
                'elk.edgeRouting': 'SPLINES',
                'elk.spacing.nodeNode': String(NODE_GAP),
                'elk.spacing.edgeEdge': '12',
                'elk.layered.spacing.nodeNodeBetweenLayers': String(RANK_GAP),
                'elk.layered.spacing.edgeNodeBetweenLayers': '28',
                'elk.layered.crossingMinimization.strategy': 'LAYER_SWEEP',
                'elk.layered.nodePlacement.strategy': 'NETWORK_SIMPLEX',
                'elk.layered.considerModelOrder.strategy': 'NODES_AND_EDGES',
                'elk.layered.cycleBreaking.strategy': 'GREEDY',
                'elk.layered.mergeEdges': 'false',
                'elk.randomSeed': '1',
                'elk.padding': `[top=${PADDING},left=${PADDING},bottom=${PADDING},right=${PADDING}]`,
            },
            children: layoutInput.nodeMetrics.map(item => ({
                id: item.node.id,
                width: CARD_WIDTH,
                height: item.height,
                layoutOptions: {
                    'elk.portConstraints': 'FIXED_POS',
                },
                ports: displayLinks.flatMap(link => {
                    const assignment = edgePortAssignments.get(link.id);
                    if (!assignment) {
                        return [];
                    }
                    const ports = [];
                    if (link.sourceNodeId === item.node.id) {
                        ports.push({
                            id: assignment.source.id,
                            x: assignment.source.side === 'right' ? CARD_WIDTH : 0,
                            y: assignment.source.y,
                            width: 1,
                            height: 1,
                            layoutOptions: { 'elk.port.side': assignment.source.side === 'right' ? 'EAST' : 'WEST' },
                        });
                    }
                    if (link.targetNodeId === item.node.id) {
                        ports.push({
                            id: assignment.target.id,
                            x: assignment.target.side === 'right' ? CARD_WIDTH : 0,
                            y: assignment.target.y,
                            width: 1,
                            height: 1,
                            layoutOptions: { 'elk.port.side': assignment.target.side === 'right' ? 'EAST' : 'WEST' },
                        });
                    }
                    return ports;
                }),
            })),
            edges: displayLinks
                .filter(link => {
                    const sourceKey = getColumnKey(link.sourceNodeId, link.sourceColumnId);
                    const targetKey = getColumnKey(link.targetNodeId, link.targetColumnId);
                    return nodeIds.has(link.sourceNodeId)
                        && nodeIds.has(link.targetNodeId)
                        && nodeColumnKeys.get(link.sourceNodeId)?.has(sourceKey)
                        && nodeColumnKeys.get(link.targetNodeId)?.has(targetKey);
                })
                .flatMap(link => {
                    const assignment = edgePortAssignments.get(link.id);
                    return assignment ? [{
                        id: link.id,
                        sources: [assignment.source.id],
                        targets: [assignment.target.id],
                    }] : [];
                }),
        };

        elk.layout(graph)
            .then(result => {
                if (cancelled) {
                    return;
                }
                const nextPositions = new Map<string, { x: number; y: number }>();
                result.children?.forEach(child => {
                    nextPositions.set(child.id, { x: child.x || 0, y: child.y || 0 });
                });
                setElkLayout({
                    nodePositions: nextPositions,
                    width: result.width || 0,
                    height: result.height || 0,
                });
            })
            .catch(() => {
                if (!cancelled) {
                    setElkLayout({ nodePositions: new Map(), width: 0, height: 0 });
                }
            });

        return () => {
            cancelled = true;
        };
    }, [displayLinks, layoutInput, linkDirections, linkLaneOffsets]);

    const layout = useMemo(() => {
        const rowAnchors = new Map<string, { left: { x: number; y: number }; right: { x: number; y: number } }>();
        const hasElkGeometry = elkLayout?.nodePositions.size === layoutInput.nodeMetrics.length;
        const rawLayoutNodes = layoutInput.nodeMetrics.map(({ node, columns, height, rank }, index) => {
            const elkPosition = elkLayout?.nodePositions.get(node.id);
            const manualPosition = manualNodePositions.get(node.id);
            const x = manualPosition?.x ?? elkPosition?.x ?? PADDING + (rank - layoutInput.minRank) * (CARD_WIDTH + RANK_GAP);
            const y = manualPosition?.y ?? elkPosition?.y ?? PADDING + index * (height + NODE_GAP);
            const ownerHeight = resolveNodeTableIdentity(node).owner ? OWNER_HEIGHT : 0;
            return { node, x, y, height, rank, columns, ownerHeight };
        });
        const nodesByRank = new Map<number, typeof rawLayoutNodes>();
        rawLayoutNodes.forEach(item => {
            nodesByRank.set(item.rank, [...(nodesByRank.get(item.rank) || []), item]);
        });

        const stackedLayoutNodes = hasElkGeometry ? rawLayoutNodes : Array.from(nodesByRank.entries()).flatMap(([, rankNodes]) => {
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
        const yShift = hasElkGeometry ? 0 : PADDING - minY;
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

        const width = Math.max(1200, elkLayout?.width || 0, ...layoutNodes.map(item => item.x + CARD_WIDTH + PADDING));
        const height = Math.max(640, elkLayout?.height || 0, ...layoutNodes.map(item => item.y + item.height + PADDING));
        return { layoutNodes, rowAnchors, width, height };
    }, [elkLayout, layoutInput, manualNodePositions]);

    const fitViewport = useCallback(() => {
        const container = scrollContainerRef.current;
        if (!container || layout.width <= 0 || layout.height <= 0) {
            return;
        }
        const viewportWidth = Math.max(320, container.clientWidth - 420);
        const viewportHeight = Math.max(320, container.clientHeight);
        const margin = 48;
        const nextZoom = clampZoom(Math.min(
            1,
            (viewportWidth - margin * 2) / layout.width,
            (viewportHeight - margin * 2) / layout.height
        ));
        setZoom(nextZoom);
        setPanOffset({
            x: Math.max(margin, (viewportWidth - layout.width * nextZoom) / 2),
            y: Math.max(margin, (viewportHeight - layout.height * nextZoom) / 2),
        });
    }, [layout.height, layout.width]);

    useEffect(() => {
        if (!elkLayout || elkLayout.nodePositions.size === 0 || manualNodePositions.size > 0) {
            return;
        }
        const autoFitKey = `${displayNodes.map(node => node.id).join('|')}::${displayLinks.map(link => link.id).join('|')}::${layout.width}x${layout.height}`;
        if (lastAutoFitKeyRef.current === autoFitKey) {
            return;
        }
        lastAutoFitKeyRef.current = autoFitKey;
        const frame = window.requestAnimationFrame(fitViewport);
        return () => window.cancelAnimationFrame(frame);
    }, [displayLinks, displayNodes, elkLayout, fitViewport, layout.height, layout.width, manualNodePositions.size]);

    const selectedFieldKey = selectedField ? `${selectedField.nodeId}::${selectedField.colId}` : '';
    const focusColumnKey = pinnedColumnKey || activeColumnKey;
    const highlighted = useMemo(() => (
        buildLineageHighlight(focusColumnKey, displayLinks)
    ), [displayLinks, focusColumnKey]);
    const hasColumnFocus = !!focusColumnKey;
    const hasPinnedColumnFocus = !!pinnedColumnKey;
    const relationLegend = useMemo(() => {
        const order = new Map(Object.keys(RELATION_STYLES).map((type, index) => [type, index]));
        return Array.from(new Set(displayLinks.map(link => normalizeRelationType(link.type))))
            .sort((a, b) => (order.get(a) ?? 99) - (order.get(b) ?? 99) || a.localeCompare(b))
            .map(type => ({ type, style: getRelationStyle(type), label: getRelationLabel(type) }));
    }, [displayLinks]);

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

    useEffect(() => {
        if (!draggingNodeId) {
            return;
        }

        const handleMouseMove = (event: MouseEvent) => {
            const start = nodeDragStartRef.current;
            if (!start) {
                return;
            }
            const deltaX = (event.clientX - start.clientX) / zoomRef.current;
            const deltaY = (event.clientY - start.clientY) / zoomRef.current;
            if (Math.abs(deltaX) > 2 || Math.abs(deltaY) > 2) {
                suppressNodeClickRef.current = true;
            }
            setManualNodePositions(current => {
                const next = new Map(current);
                next.set(start.nodeId, {
                    x: Math.max(PADDING / 2, start.x + deltaX),
                    y: Math.max(PADDING / 2, start.y + deltaY),
                });
                return next;
            });
        };
        const handleMouseUp = () => {
            nodeDragStartRef.current = null;
            setDraggingNodeId(null);
        };

        window.addEventListener('mousemove', handleMouseMove);
        window.addEventListener('mouseup', handleMouseUp);
        return () => {
            window.removeEventListener('mousemove', handleMouseMove);
            window.removeEventListener('mouseup', handleMouseUp);
        };
    }, [draggingNodeId]);

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

    const handleAnalyzeTableRelation = async () => {
        if (!fieldDetailsLoaded) {
            await onLoadFieldDetails?.();
        }
        setFieldTraceEnabled(true);
        setRelationModalVisible(false);
    };

    const handleLinkClick = (link: LinkData) => {
        setFocusedLinkId(link.id);
        setFocusedNodeId(null);
        const sourceNode = displayNodes.find(node => node.id === link.sourceNodeId)
            || nodes.find(node => node.id === link.sourceNodeId);
        const targetNode = displayNodes.find(node => node.id === link.targetNodeId)
            || nodes.find(node => node.id === link.targetNodeId);
        const sourceColumn = sourceNode?.columns.find(column => column.id === link.sourceColumnId)?.name;
        const targetColumn = targetNode?.columns.find(column => column.id === link.targetColumnId)?.name;
        setSelectedRelation({
            link,
            sourceTable: sourceNode?.title || link.properties?.sourceTable || '-',
            targetTable: targetNode?.title || link.properties?.targetTable || '-',
            sourceColumns: sourceColumn ? [sourceColumn] : normalizeArray(link.properties?.sourceColumns),
            targetColumns: targetColumn ? [targetColumn] : normalizeArray(link.properties?.targetColumns),
            sourceFile: getSourceFile(link),
        });
        setRelationModalVisible(true);
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

    const handleNodeMouseDown = (event: React.MouseEvent<HTMLDivElement>, item: LayoutNode) => {
        if (event.button !== 0) {
            return;
        }
        event.preventDefault();
        event.stopPropagation();
        suppressNodeClickRef.current = false;
        nodeDragStartRef.current = {
            nodeId: item.node.id,
            clientX: event.clientX,
            clientY: event.clientY,
            x: item.x,
            y: item.y,
        };
        setManualNodePositions(current => {
            const next = new Map(current);
            next.set(item.node.id, { x: item.x, y: item.y });
            return next;
        });
        setDraggingNodeId(item.node.id);
    };

    const handleResetViewport = fitViewport;

    return (
        <div className="relative h-full w-full bg-[#f1f2f4]" style={{ minHeight: 640 }}>
            <div
                ref={scrollContainerRef}
                className="h-full w-full overflow-hidden pr-[420px]"
                style={{
                    minHeight: 640,
                    cursor: isPanning ? 'grabbing' : undefined,
                    userSelect: isPanning || draggingNodeId ? 'none' : undefined,
                }}
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
                                markerWidth="8"
                                markerHeight="6"
                                refX="7"
                                refY="3"
                                orient="auto"
                                markerUnits="strokeWidth"
                            >
                                <path d="M 0 0 L 8 3 L 0 6 z" fill={style.highlightColor} />
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
                        const sameRank = Math.abs(sourceAnchor.left.x - targetAnchor.left.x) < 1;
                        const hasReverse = linkDirections.has(`${link.targetNodeId}=>${link.sourceNodeId}`);
                        const sameRankSide = sameRank
                            ? (!hasReverse || link.sourceNodeId.localeCompare(link.targetNodeId) <= 0 ? 'right' : 'left')
                            : null;
                        const source = sameRank
                            ? (sameRankSide === 'right' ? sourceAnchor.right : sourceAnchor.left)
                            : (sourceAnchor.right.x <= targetAnchor.left.x ? sourceAnchor.right : sourceAnchor.left);
                        const target = sameRank
                            ? (sameRankSide === 'right' ? targetAnchor.right : targetAnchor.left)
                            : (sourceAnchor.right.x <= targetAnchor.left.x ? targetAnchor.left : targetAnchor.right);
                        const isActive = highlighted.activeLinks.has(link.id)
                            || (!hasPinnedColumnFocus && activeLinkId === link.id)
                            || (!hasColumnFocus && focusedLinkId === link.id)
                            || (!hasColumnFocus && (sourceKey === selectedFieldKey || targetKey === selectedFieldKey));
                        const relationType = normalizeRelationType(link.type);
                        const style = getRelationStyle(relationType);
                        const geometry = buildCurveGeometry(
                            source,
                            target,
                            linkLaneOffsets.get(link.id) || 0,
                            sameRankSide
                        );
                        const hasRelationshipFocus = Boolean(activeLinkId || hasColumnFocus || focusedLinkId || selectedFieldKey);
                        const strokeColor = isActive ? style.highlightColor : style.color;
                        const markerId = getRelationMarkerId(relationType);
                        const opacity = hasRelationshipFocus && !isActive ? 0.3 : 1;
                        const evidenceCount = getLinkEvidenceCount(link);
                        return (
                            <g key={link.id}>
                                <title>{`${getRelationLabel(relationType)}：${sourceKey} → ${targetKey}${evidenceCount > 0 ? `，SQL 证据 ${evidenceCount} 段` : ''}`}</title>
                                <path
                                    d={geometry.path}
                                    fill="none"
                                    stroke={strokeColor}
                                    strokeWidth={isActive ? 2.6 : 1.7}
                                    strokeLinecap="round"
                                    strokeDasharray={style.strokeDasharray}
                                    markerEnd={`url(#${markerId})`}
                                    opacity={opacity}
                                    pointerEvents="none"
                                />
                                {evidenceCount > 1 ? (
                                    <g opacity={opacity} pointerEvents="none">
                                        <rect
                                            x={geometry.midpoint.x - 15}
                                            y={geometry.midpoint.y - 10}
                                            width={30}
                                            height={20}
                                            rx={10}
                                            fill="#ffffff"
                                            stroke={strokeColor}
                                            strokeWidth={1.5}
                                        />
                                        <text
                                            x={geometry.midpoint.x}
                                            y={geometry.midpoint.y + 4}
                                            textAnchor="middle"
                                            fontSize={11}
                                            fontWeight={700}
                                            fill={strokeColor}
                                        >
                                            {evidenceCount}
                                        </text>
                                    </g>
                                ) : (
                                    <circle
                                        cx={geometry.midpoint.x}
                                        cy={geometry.midpoint.y}
                                        r={isActive ? 5 : 4}
                                        fill={strokeColor}
                                        stroke="#f1f2f4"
                                        strokeWidth={2}
                                        opacity={opacity}
                                        pointerEvents="none"
                                    />
                                )}
                                <path
                                    d={geometry.path}
                                    fill="none"
                                    stroke="transparent"
                                    strokeWidth={14}
                                    style={{ cursor: 'pointer', pointerEvents: 'stroke' }}
                                    onMouseEnter={() => setActiveLinkId(link.id)}
                                    onMouseLeave={() => setActiveLinkId(null)}
                                    onClick={() => handleLinkClick(link)}
                                />
                            </g>
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
                                zIndex: draggingNodeId === item.node.id ? 30 : 10,
                            }}
                        >
                            <div
                                className="flex h-9 items-center justify-center px-3 text-base font-semibold text-white"
                                style={{
                                    background: headerColor,
                                    cursor: draggingNodeId === item.node.id ? 'grabbing' : 'grab',
                                    userSelect: 'none',
                                }}
                                title={item.node.isGroupNode
                                    ? `${item.node.title}（拖动调整位置）`
                                    : `${item.node.title}（拖动调整位置，单击高亮，双击切换为当前表）`}
                                onMouseDown={event => handleNodeMouseDown(event, item)}
                                onClick={(event) => {
                                    event.stopPropagation();
                                    if (suppressNodeClickRef.current) {
                                        suppressNodeClickRef.current = false;
                                        return;
                                    }
                                    if (!item.node.isGroupNode) {
                                        handleFocusNode(item.node.id);
                                    }
                                }}
                                onDoubleClick={(event) => {
                                    event.stopPropagation();
                                    if (!item.node.isGroupNode) {
                                        onTableDoubleClick?.(table, item.node.title, item.node.objectUid);
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
                                    const isPinned = rowKey === pinnedColumnKey;
                                    const isSelected = !hasColumnFocus && rowKey === selectedFieldKey;
                                    const isLinkActive = !hasPinnedColumnFocus && displayLinks.some(link => (
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
                                                background: isPinned ? '#dbeafe' : (isSelected ? '#fdebd3' : (isActive ? '#eff6ff' : '#ffffff')),
                                                fontWeight: isPinned || isSelected || isActive ? 600 : 400,
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
                                                    onFieldDoubleClick?.(table, item.node.title, col.name, item.node.objectUid);
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
                <Tooltip title="适应画布" placement="top">
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
            {selectedRelation ? (
                <Modal
                    open={relationModalVisible}
                    title="关系来源详情"
                    footer={!selectedRelation.link.sourceColumnId && !selectedRelation.link.targetColumnId ? (
                        <Button type="primary" onClick={() => void handleAnalyzeTableRelation()} loading={fieldLoading}>
                            字段级分析该表关系
                        </Button>
                    ) : null}
                    width={920}
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
                            {selectedRelation.link.properties?.relationLevel === 'end_to_end'
                                ? '当前是端到端汇总线路，请切换到完整链路，逐步查看每条实际关系对应的 SQL 证据。'
                                : selectedRelation.link.sourceColumnId || selectedRelation.link.targetColumnId
                                ? '每段 SQL 都是当前字段关系的独立证据，不会与其他处理步骤拼接。'
                                : '当前是表级归并关系，SQL 作为多份独立证据展示；进入字段级分析可查看实际字段边。'}
                        </Descriptions.Item>
                    </Descriptions>
                    {selectedRelation.link.properties?.relationLevel !== 'end_to_end' && (
                        <RelationEvidencePanel
                            active={relationModalVisible}
                            link={selectedRelation.link}
                            sourceTable={selectedRelation.sourceTable}
                            targetTable={selectedRelation.targetTable}
                            sourceColumn={selectedRelation.sourceColumns[0]}
                            targetColumn={selectedRelation.targetColumns[0]}
                        />
                    )}
                </Modal>
            ) : null}
        </div>
    );
};

export default ColumnLineageDiagram;
