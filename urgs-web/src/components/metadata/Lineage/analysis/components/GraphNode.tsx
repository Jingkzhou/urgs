import React, { useMemo } from 'react';
import { NodeData } from '../types';
import { NODE_HEADER_HEIGHT as HEADER_H, COLUMN_ROW_HEIGHT as ROW_H } from '../constants';
import { ChevronDown, ChevronRight } from 'lucide-react';

interface GraphNodeProps {
    node: NodeData;
    highlighted: boolean;
    selected: boolean;
    onNodeHover: (id: string | null) => void;
    hoveredColumnId: string | null;
    selectedColumnId: string | null;
    traceColumnIds?: Set<string>;
    dimmedColumnIds?: Set<string>; // New prop for dimming unselected columns
    onColumnHover: (nodeId: string, colId: string | null) => void;
    onColumnSelect: (nodeId: string, colId: string) => void;
    onNodeSelect: (nodeId: string) => void; // New prop for table selection
    isCollapsed: boolean;
    onToggleCollapse: (id: string) => void;
    onMouseDown: (e: React.MouseEvent, nodeId: string) => void;
}

const GraphNode: React.FC<GraphNodeProps> = ({
    node,
    highlighted,
    selected,
    onNodeHover,
    hoveredColumnId,
    selectedColumnId,
    traceColumnIds,
    dimmedColumnIds,
    onColumnHover,
    onColumnSelect,
    isCollapsed,
    onToggleCollapse,
    onMouseDown
}) => {

    const height = isCollapsed ? HEADER_H : HEADER_H + (node.columns.length * ROW_H) + 8; // +8 for bottom padding if expanded
    const canCollapse = node.type === 'transform';

    const style = useMemo(() => {
        switch (node.type) {
            case 'source':
                return {
                    headerBg: '#EFF6FF', // Blue 50
                    stroke: '#BFDBFE',   // Blue 200
                    text: '#1E40AF',     // Blue 800
                    accent: '#3B82F6',   // Blue 500
                    icon: '📄'
                };
            case 'transform':
                return {
                    headerBg: '#F5F3FF', // Violet 50
                    stroke: '#DDD6FE',   // Violet 200
                    text: '#5B21B6',     // Violet 800
                    accent: '#8B5CF6',   // Violet 500
                    icon: '⚡'
                };
            case 'aggregation':
            case 'result':
                return {
                    headerBg: '#FFF1F2', // Rose 50
                    stroke: '#FECDD3',   // Rose 200
                    text: '#9F1239',     // Rose 800
                    accent: '#F43F5E',   // Rose 500
                    icon: '📊'
                };
            default:
                return {
                    headerBg: '#F8FAFC',
                    stroke: '#E2E8F0',
                    text: '#475569',
                    accent: '#64748B',
                    icon: '📦'
                };
        }
    }, [node.type]);

    const isNodeActive = highlighted || selected;
    const currentFill = isCollapsed ? style.headerBg : 'white';

    return (
        <g
            transform={`translate(${node.x}, ${node.y})`}
            onMouseEnter={() => onNodeHover(node.id)}
            onMouseLeave={() => onNodeHover(null)}
            onMouseDown={(e) => onMouseDown(e, node.id)}
            onClick={(e) => {
                e.stopPropagation();
                onNodeSelect(node.id);
            }}
            className="cursor-move"
        // Note: We intentionally do not put a transition on this group to ensure instant drag response
        >
            {/* Inner group for scaling effect which can have transition */}
            <g
                style={{
                    transform: isNodeActive ? 'scale(1.02)' : 'scale(1)',
                    transformOrigin: 'center center',
                    transition: 'transform 0.3s ease-out'
                }}
            >
                <defs>
                    <filter id={`shadow-${node.id}`} x="-20%" y="-20%" width="140%" height="140%">
                        <feDropShadow dx="0" dy="4" stdDeviation="6" floodColor={style.accent} floodOpacity={selected ? 0.3 : 0.15} />
                    </filter>
                </defs>

                {/* Main Card Background */}
                <rect
                    width={node.width}
                    height={height}
                    fill={currentFill}
                    stroke={selected ? style.accent : (isNodeActive ? style.accent : style.stroke)}
                    strokeWidth={selected ? 3 : (isNodeActive ? 2 : 1)}
                    rx={12}
                    ry={12}
                    filter={isNodeActive ? `url(#shadow-${node.id})` : ''}
                    className="transition-all duration-300"
                />

                {/* Header Section (Only if expanded, otherwise rect acts as header) */}
                {!isCollapsed && (
                    <path
                        d={`M 1 ${HEADER_H} L ${node.width - 1} ${HEADER_H} L ${node.width - 1} 12 Q ${node.width - 1} 1 ${node.width - 12} 1 L 12 1 Q 1 1 1 12 Z`}
                        fill={selected ? style.stroke : style.headerBg}
                        opacity={0.8}
                        className="transition-colors duration-300"
                    />
                )}

                {!isCollapsed && (
                    <line x1="1" y1={HEADER_H} x2={node.width - 1} y2={HEADER_H} stroke={style.stroke} strokeWidth={0.5} />
                )}

                {/* Title */}
                <text
                    x={12}
                    y={HEADER_H / 2}
                    dy=".35em"
                    fill={style.text}
                    fontSize="11"
                    fontWeight="600"
                    fontFamily="'Inter', sans-serif"
                    style={{ pointerEvents: 'none', letterSpacing: '0.01em' }}
                >
                    {style.icon}  {node.title} {isCollapsed && `(${node.columns.length})`}
                </text>

                {/* Collapse Toggle */}
                {canCollapse && (
                    <g
                        transform={`translate(${node.width - 24}, 8)`}
                        onClick={(e) => {
                            e.stopPropagation();
                            onToggleCollapse(node.id);
                        }}
                        onMouseDown={(e) => e.stopPropagation()} // Prevent drag start when clicking toggle
                        className="cursor-pointer opacity-60 hover:opacity-100"
                    >
                        <rect width="16" height="16" fill="transparent" /> {/* Hit area */}
                        {isCollapsed ? (
                            <ChevronRight size={16} color={style.text} />
                        ) : (
                            <ChevronDown size={16} color={style.text} />
                        )}
                    </g>
                )}

                {/* Columns */}
                {!isCollapsed && (
                    <g transform={`translate(0, ${HEADER_H + 4})`}>
                        {node.columns.map((col, idx) => {
                            const isHovered = hoveredColumnId === col.id;
                            const isSelected = selectedColumnId === col.id;
                            const isTrace = traceColumnIds?.has(col.id);
                            const isDimmed = dimmedColumnIds?.has(col.id);

                            let bgFill = 'transparent';
                            if (isSelected) bgFill = style.headerBg;
                            else if (isTrace) bgFill = '#F8FAFC';
                            else if (isHovered) bgFill = '#F1F5F9';

                            return (
                                <g
                                    key={col.id}
                                    transform={`translate(0, ${idx * ROW_H})`}
                                    onMouseEnter={() => onColumnHover(node.id, col.id)}
                                    onMouseLeave={() => onColumnHover(node.id, null)}
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        onColumnSelect(node.id, col.id);
                                    }}
                                    className="transition-opacity duration-300"
                                    style={{ opacity: isDimmed ? 0.3 : 1 }}
                                // We allow drag start on columns, so we don't stop propagation here for onMouseDown
                                >
                                    {/* Interaction Area / Background */}
                                    <rect
                                        x={4}
                                        y={0}
                                        width={node.width - 8}
                                        height={ROW_H}
                                        rx={6}
                                        fill={bgFill}
                                        className="transition-colors duration-200"
                                    />

                                    {/* Indicator dot for trace/selection */}
                                    {(isSelected || isTrace) && (
                                        <circle
                                            cx={10}
                                            cy={ROW_H / 2}
                                            r={isSelected ? 3.5 : 2.5}
                                            fill={style.accent}
                                            fillOpacity={isSelected ? 1 : 0.6}
                                        />
                                    )}

                                    <text
                                        x={isSelected || isTrace ? 20 : 12}
                                        y={ROW_H / 2}
                                        dy=".35em"
                                        fill={isSelected ? style.text : (isTrace ? '#334155' : '#64748B')}
                                        fontSize="11"
                                        fontFamily="'JetBrains Mono', monospace"
                                        fontWeight={isSelected ? '500' : '400'}
                                        style={{ pointerEvents: 'none', transition: 'all 0.2s' }}
                                    >
                                        {col.name}
                                    </text>
                                </g>
                            );
                        })}
                    </g>
                )}
            </g>
        </g>
    );
};

export default React.memo(GraphNode);
