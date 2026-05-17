import React, { useMemo, useState } from 'react';
import { Descriptions, Empty, Modal, Tag } from 'antd';
import { LinkData, NodeData, RELATION_STYLES } from '../types';
import CodeModal from './CodeModal';

interface ColumnLineageDiagramProps {
    nodes: NodeData[];
    links: LinkData[];
    selectedTable: string | null;
    selectedField: { nodeId: string; colId: string } | null;
    onTableDoubleClick?: (tableName: string, qualifiedName: string) => void;
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

const TABLE_LEVEL_COLUMN = '__table_level__';
const CARD_WIDTH = 290;
const HEADER_HEIGHT = 36;
const OWNER_HEIGHT = 28;
const ROW_HEIGHT = 28;
const RANK_GAP = 190;
const NODE_GAP = 56;
const PADDING = 72;
const DEFAULT_RELATION_TYPE = 'DERIVES_TO';

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

const normalizeRelationType = (type?: string) => type || DEFAULT_RELATION_TYPE;

const getRelationStyle = (type?: string) => (
    RELATION_STYLES[normalizeRelationType(type)] || RELATION_STYLES[DEFAULT_RELATION_TYPE]
);

const getRelationLabel = (type?: string) => (
    RELATION_STYLES[normalizeRelationType(type)]?.label || normalizeRelationType(type)
);

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

const normalizeArray = (value: any): string[] => {
    if (Array.isArray(value)) {
        return value.filter(Boolean).map(String);
    }
    return value ? [String(value)] : [];
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
    onTableDoubleClick,
}) => {
    const [activeLinkId, setActiveLinkId] = useState<string | null>(null);
    const [activeColumnKey, setActiveColumnKey] = useState<string | null>(null);
    const [pinnedColumnKey, setPinnedColumnKey] = useState<string | null>(null);
    const [codeModalVisible, setCodeModalVisible] = useState(false);
    const [selectedCode, setSelectedCode] = useState<SelectedCode | null>(null);
    const [relationModalVisible, setRelationModalVisible] = useState(false);
    const [selectedRelation, setSelectedRelation] = useState<SelectedRelation | null>(null);

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
    const focusColumnKey = pinnedColumnKey || activeColumnKey;
    const highlighted = useMemo(() => (
        buildLineageHighlight(focusColumnKey, links)
    ), [focusColumnKey, links]);
    const hasColumnFocus = !!focusColumnKey;
    const relationLegend = useMemo(() => {
        const order = new Map(Object.keys(RELATION_STYLES).map((type, index) => [type, index]));
        return Array.from(new Set(links.map(link => normalizeRelationType(link.type))))
            .sort((a, b) => (order.get(a) ?? 99) - (order.get(b) ?? 99) || a.localeCompare(b))
            .map(type => ({ type, style: getRelationStyle(type), label: getRelationLabel(type) }));
    }, [links]);

    if (nodes.length === 0) {
        return <Empty description="暂无流程图数据" style={{ marginTop: 100 }} />;
    }

    const handleLinkClick = (link: LinkData) => {
        const code = getLinkCode(link);
        if (!code) {
            const sourceNode = nodes.find(node => node.id === link.sourceNodeId);
            const targetNode = nodes.find(node => node.id === link.targetNodeId);
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
            searchTerm: getSourceColumnSearchTerm(link, nodes),
        });
        setCodeModalVisible(true);
    };

    return (
        <div className="h-full w-full overflow-auto bg-[#f1f2f4]" style={{ minHeight: 640 }}>
            <div
                className="relative"
                style={{ width: layout.width, height: layout.height }}
                onClick={() => setPinnedColumnKey(null)}
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
                        const relationType = normalizeRelationType(link.type);
                        const style = getRelationStyle(relationType);
                        const hasCode = !!getLinkCode(link);
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
                                style={{ cursor: hasCode ? 'pointer' : 'default', pointerEvents: 'stroke' }}
                                onMouseEnter={() => setActiveLinkId(link.id)}
                                onMouseLeave={() => setActiveLinkId(null)}
                                onClick={() => handleLinkClick(link)}
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
                                style={{ background: headerColor, cursor: onTableDoubleClick ? 'pointer' : 'default' }}
                                title={`${item.node.title}（双击切换为当前表）`}
                                onDoubleClick={(event) => {
                                    event.stopPropagation();
                                    onTableDoubleClick?.(table, item.node.title);
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
