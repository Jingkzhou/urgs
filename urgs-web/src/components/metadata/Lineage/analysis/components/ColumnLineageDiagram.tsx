import React, { useMemo, useState } from 'react';
import { Empty, Tag } from 'antd';
import { LinkData, NodeData, RELATION_STYLES } from '../types';

interface ColumnLineageDiagramProps {
    nodes: NodeData[];
    links: LinkData[];
    selectedTable: string | null;
    selectedField: { nodeId: string; colId: string } | null;
}

interface LayoutNode {
    node: NodeData;
    x: number;
    y: number;
    height: number;
    rank: number;
    columns: { id: string; name: string; synthetic?: boolean }[];
}

const TABLE_LEVEL_COLUMN = '__table_level__';
const CARD_WIDTH = 290;
const HEADER_HEIGHT = 36;
const OWNER_HEIGHT = 28;
const ROW_HEIGHT = 28;
const RANK_GAP = 190;
const NODE_GAP = 56;
const PADDING = 72;

const splitQualifiedTitle = (title: string) => {
    const index = title.lastIndexOf('.');
    if (index <= 0 || index === title.length - 1) {
        return { owner: '', table: title };
    }
    return {
        owner: title.slice(0, index),
        table: title.slice(index + 1),
    };
};

const sameTable = (left: string, right?: string | null) => (
    !!right && left.toLowerCase() === right.toLowerCase()
);

const getRelationStyle = (type?: string) => (
    RELATION_STYLES[type || 'DERIVES_TO'] || RELATION_STYLES.DERIVES_TO
);

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

const buildDownstreamHighlight = (startKey: string | null, links: LinkData[]) => {
    const activeLinks = new Set<string>();
    const activeColumns = new Set<string>();
    if (!startKey) {
        return { activeLinks, activeColumns };
    }

    const outgoing = new Map<string, LinkData[]>();
    const connected = new Map<string, LinkData[]>();
    links.forEach(link => {
        const sourceKey = getColumnKey(link.sourceNodeId, link.sourceColumnId);
        const targetKey = getColumnKey(link.targetNodeId, link.targetColumnId);
        outgoing.set(sourceKey, [...(outgoing.get(sourceKey) || []), link]);
        connected.set(sourceKey, [...(connected.get(sourceKey) || []), link]);
        connected.set(targetKey, [...(connected.get(targetKey) || []), link]);
    });

    activeColumns.add(startKey);
    const queue = [startKey];
    while (queue.length > 0) {
        const currentKey = queue.shift()!;
        (outgoing.get(currentKey) || []).forEach(link => {
            if (activeLinks.has(link.id)) {
                return;
            }
            activeLinks.add(link.id);
            const targetKey = getColumnKey(link.targetNodeId, link.targetColumnId);
            activeColumns.add(targetKey);
            queue.push(targetKey);
        });
    }

    if (activeLinks.size === 0) {
        (connected.get(startKey) || []).forEach(link => {
            activeLinks.add(link.id);
            activeColumns.add(getColumnKey(link.sourceNodeId, link.sourceColumnId));
            activeColumns.add(getColumnKey(link.targetNodeId, link.targetColumnId));
        });
    }

    return { activeLinks, activeColumns };
};

const buildRanks = (nodes: NodeData[], links: LinkData[], selectedTable: string | null, selectedField: ColumnLineageDiagramProps['selectedField']) => {
    const nodeIds = new Set(nodes.map(node => node.id));
    const selectedNode = nodes.find(node => node.id === selectedField?.nodeId)
        || nodes.find(node => sameTable(node.title, selectedTable))
        || nodes[0];
    const ranks = new Map<string, number>();
    if (!selectedNode) {
        return ranks;
    }

    const outgoing = new Map<string, string[]>();
    const incoming = new Map<string, string[]>();
    links.forEach(link => {
        if (!nodeIds.has(link.sourceNodeId) || !nodeIds.has(link.targetNodeId)) {
            return;
        }
        outgoing.set(link.sourceNodeId, [...(outgoing.get(link.sourceNodeId) || []), link.targetNodeId]);
        incoming.set(link.targetNodeId, [...(incoming.get(link.targetNodeId) || []), link.sourceNodeId]);
    });

    const queue = [selectedNode.id];
    ranks.set(selectedNode.id, 0);
    while (queue.length > 0) {
        const current = queue.shift()!;
        const currentRank = ranks.get(current) || 0;
        (incoming.get(current) || []).forEach(sourceId => {
            if (!ranks.has(sourceId)) {
                ranks.set(sourceId, currentRank - 1);
                queue.push(sourceId);
            }
        });
        (outgoing.get(current) || []).forEach(targetId => {
            if (!ranks.has(targetId)) {
                ranks.set(targetId, currentRank + 1);
                queue.push(targetId);
            }
        });
    }

    nodes.forEach(node => {
        if (!ranks.has(node.id)) {
            ranks.set(node.id, Math.round((node.x || 0) / 480));
        }
    });
    return ranks;
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
    const result = columns.map(col => ({ id: col.id, name: col.name }));
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
    selectedTable,
    selectedField,
}) => {
    const [activeLinkId, setActiveLinkId] = useState<string | null>(null);
    const [activeColumnKey, setActiveColumnKey] = useState<string | null>(null);

    const layout = useMemo(() => {
        const columnUsage = buildColumnUsage(links);
        const ranks = buildRanks(nodes, links, selectedTable, selectedField);
        const grouped = new Map<number, NodeData[]>();
        nodes.forEach(node => {
            const rank = ranks.get(node.id) || 0;
            grouped.set(rank, [...(grouped.get(rank) || []), node]);
        });

        const sortedRanks = Array.from(grouped.keys()).sort((a, b) => a - b);
        const minRank = sortedRanks[0] || 0;
        const layoutNodes: LayoutNode[] = [];
        const rowAnchors = new Map<string, { left: { x: number; y: number }; right: { x: number; y: number } }>();

        sortedRanks.forEach(rank => {
            const rankNodes = (grouped.get(rank) || []).slice().sort((a, b) => (a.y - b.y) || a.title.localeCompare(b.title));
            let y = PADDING;
            rankNodes.forEach(node => {
                const columns = getVisibleColumns(node, columnUsage, selectedField);
                const ownerHeight = splitQualifiedTitle(node.title).owner ? OWNER_HEIGHT : 0;
                const height = HEADER_HEIGHT + ownerHeight + Math.max(1, columns.length) * ROW_HEIGHT;
                const x = PADDING + (rank - minRank) * (CARD_WIDTH + RANK_GAP);
                const layoutNode = { node, x, y, height, rank, columns };
                layoutNodes.push(layoutNode);

                columns.forEach((col, index) => {
                    const rowY = y + HEADER_HEIGHT + ownerHeight + index * ROW_HEIGHT + ROW_HEIGHT / 2;
                    rowAnchors.set(getColumnKey(node.id, col.id), {
                        left: { x, y: rowY },
                        right: { x: x + CARD_WIDTH, y: rowY },
                    });
                });
                y += height + NODE_GAP;
            });
        });

        const width = Math.max(1200, ...layoutNodes.map(item => item.x + CARD_WIDTH + PADDING));
        const height = Math.max(640, ...layoutNodes.map(item => item.y + item.height + PADDING));
        return { layoutNodes, rowAnchors, width, height };
    }, [links, nodes, selectedField, selectedTable]);

    const selectedFieldKey = selectedField ? `${selectedField.nodeId}::${selectedField.colId}` : '';
    const highlighted = useMemo(() => (
        buildDownstreamHighlight(activeColumnKey, links)
    ), [activeColumnKey, links]);
    const hasColumnHover = !!activeColumnKey;

    if (nodes.length === 0) {
        return <Empty description="暂无流程图数据" style={{ marginTop: 100 }} />;
    }

    return (
        <div className="h-full w-full overflow-auto bg-[#f1f2f4]" style={{ minHeight: 640 }}>
            <div className="relative" style={{ width: layout.width, height: layout.height }}>
                <svg className="absolute inset-0" width={layout.width} height={layout.height}>
                    <defs>
                        <marker id="lineage-arrow" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto" markerUnits="strokeWidth">
                            <path d="M 0 0 L 10 4 L 0 8 z" fill="#a6a8ab" />
                        </marker>
                        <marker id="lineage-arrow-active" markerWidth="10" markerHeight="8" refX="9" refY="4" orient="auto" markerUnits="strokeWidth">
                            <path d="M 0 0 L 10 4 L 0 8 z" fill="#111827" />
                        </marker>
                    </defs>
                    {links.map(link => {
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
                        const style = getRelationStyle(link.type);
                        return (
                            <path
                                key={link.id}
                                d={buildPath(source, target)}
                                fill="none"
                                stroke={isActive ? '#111827' : '#b8babf'}
                                strokeWidth={isActive ? 2.8 : 1.5}
                                strokeDasharray={isActive ? undefined : style.strokeDasharray}
                                markerEnd={`url(#${isActive ? 'lineage-arrow-active' : 'lineage-arrow'})`}
                                opacity={(activeLinkId || hasColumnHover) && !isActive ? 0.18 : 1}
                                style={{ pointerEvents: 'stroke' }}
                                onMouseEnter={() => setActiveLinkId(link.id)}
                                onMouseLeave={() => setActiveLinkId(null)}
                            />
                        );
                    })}
                </svg>

                {layout.layoutNodes.map(item => {
                    const { owner, table } = splitQualifiedTitle(item.node.title);
                    const isSelectedTable = sameTable(item.node.title, selectedTable) || item.node.id === selectedField?.nodeId;
                    const hasOutgoing = links.some(link => link.sourceNodeId === item.node.id);
                    const hasIncoming = links.some(link => link.targetNodeId === item.node.id);
                    const headerColor = isSelectedTable ? '#b84f83' : (!hasOutgoing && hasIncoming ? '#d66b59' : '#8bc34a');
                    return (
                        <div
                            key={item.node.id}
                            className="absolute overflow-hidden border bg-white shadow-sm"
                            style={{
                                left: item.x,
                                top: item.y,
                                width: CARD_WIDTH,
                                minHeight: item.height,
                                borderColor: headerColor,
                            }}
                        >
                            <div
                                className="flex h-9 items-center justify-center px-3 text-base font-semibold text-white"
                                style={{ background: headerColor }}
                                title={item.node.title}
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
                                    const isLinkActive = links.some(link => (
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
                                                opacity: hasColumnHover && !isActive ? 0.46 : 1,
                                            }}
                                            onMouseEnter={() => setActiveColumnKey(rowKey)}
                                            onMouseLeave={() => setActiveColumnKey(null)}
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
            </div>
        </div>
    );
};

export default ColumnLineageDiagram;
