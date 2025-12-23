import React, { useState, useRef, useMemo, useEffect, useCallback } from 'react';
import { NODE_HEADER_HEIGHT, COLUMN_ROW_HEIGHT } from '../constants';
import { ViewportState, NodeData, LinkData } from '../types';
import GraphNode from './GraphNode';
import GraphLink from './GraphLink';

interface LineageDiagramProps {
    viewport: ViewportState;
    setViewport: React.Dispatch<React.SetStateAction<ViewportState>>;
    nodes: NodeData[];
    setNodes: React.Dispatch<React.SetStateAction<NodeData[]>>;
    links: LinkData[]; // Dynamic links prop
    selectedTable: string | null; // The table being focused/searched
    selectedField: { nodeId: string, colId: string } | null;
    onFieldSelect: (field: { nodeId: string, colId: string } | null) => void;
}

// Helper function to trace lineage upstream and downstream
const traceLineage = (startNodeId: string, startColId: string, allLinks: LinkData[]) => {
    const visitedLinks = new Set<string>();
    const visitedColumns = new Set<string>();
    const visitedNodes = new Set<string>();

    // key format: "nodeId||colId"
    const startKey = `${startNodeId}||${startColId}`;

    const queue: { nodeId: string, colId: string, direction: 'up' | 'down' | 'both' }[] = [
        { nodeId: startNodeId, colId: startColId, direction: 'both' }
    ];

    visitedColumns.add(startKey);
    visitedNodes.add(startNodeId);

    while (queue.length > 0) {
        const { nodeId, colId, direction } = queue.shift()!;

        // Upstream
        if (direction === 'both' || direction === 'up') {
            const incomingLinks = allLinks.filter(l =>
                l.targetNodeId === nodeId &&
                ((l.targetColumnId || '') === (colId || ''))
            );
            for (const link of incomingLinks) {
                if (!visitedLinks.has(link.id)) {
                    visitedLinks.add(link.id);
                    const sourceCol = link.sourceColumnId || '';
                    const sourceKey = `${link.sourceNodeId}||${sourceCol}`;
                    if (!visitedColumns.has(sourceKey)) {
                        visitedColumns.add(sourceKey);
                        visitedNodes.add(link.sourceNodeId);
                        queue.push({ nodeId: link.sourceNodeId, colId: sourceCol, direction: 'up' });
                    }
                }
            }
        }

        // Downstream
        if (direction === 'both' || direction === 'down') {
            const outgoingLinks = allLinks.filter(l =>
                l.sourceNodeId === nodeId &&
                ((l.sourceColumnId || '') === (colId || ''))
            );
            for (const link of outgoingLinks) {
                if (!visitedLinks.has(link.id)) {
                    visitedLinks.add(link.id);
                    const targetCol = link.targetColumnId || '';
                    const targetKey = `${link.targetNodeId}||${targetCol}`;
                    if (!visitedColumns.has(targetKey)) {
                        visitedColumns.add(targetKey);
                        visitedNodes.add(link.targetNodeId);
                        queue.push({ nodeId: link.targetNodeId, colId: targetCol, direction: 'down' });
                    }
                }
            }
        }
    }
    return { visitedLinks, visitedColumns, visitedNodes };
};

const LineageDiagram: React.FC<LineageDiagramProps> = ({ viewport, setViewport, nodes, setNodes, links, selectedTable, selectedField, onFieldSelect }) => {
    const svgRef = useRef<SVGSVGElement>(null);

    // State for Viewport Panning
    const [isViewportDragging, setIsViewportDragging] = useState(false);
    const [viewportDragStart, setViewportDragStart] = useState({ x: 0, y: 0 });

    // State for Node Dragging
    const [draggingNodeId, setDraggingNodeId] = useState<string | null>(null);
    const [dragNodeOffset, setDragNodeOffset] = useState({ x: 0, y: 0 });

    // State for interaction
    const [hoveredNodeId, setHoveredNodeId] = useState<string | null>(null);
    const [hoveredColumn, setHoveredColumn] = useState<{ nodeId: string, colId: string } | null>(null);
    // selectedField moved to props
    const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
    const [hoveredLinkId, setHoveredLinkId] = useState<string | null>(null);

    const toggleNodeCollapse = (nodeId: string) => {
        setNodes(prev => prev.map(n =>
            n.id === nodeId ? { ...n, isCollapsed: !n.isCollapsed } : n
        ));
    };

    // Stable callbacks for GraphNode optimization
    const handleNodeHover = useCallback((id: string | null) => setHoveredNodeId(id), []);

    // We need to change the signature of passed functions to allow stable references
    const handleColumnHover = useCallback((nodeId: string, colId: string | null) => {
        setHoveredColumn(colId ? { nodeId, colId } : null);
        // Also clear link hover if column hover changes?
    }, []);

    const handleColumnSelect = useCallback((nodeId: string, colId: string) => {
        onFieldSelect({ nodeId, colId });
        setSelectedNodeId(null);
    }, [onFieldSelect]);

    const handleNodeSelect = useCallback((nodeId: string) => {
        // 在血缘聚焦模式下（有 selectedField），点击表节点不应清除聚焦
        // 只更新 selectedNodeId 用于视觉反馈，不影响血缘过滤
        setSelectedNodeId(nodeId);
        // 注意：不调用 onFieldSelect(null)，保持血缘聚焦模式
    }, []);

    const handleToggleCollapse = useCallback((nodeId: string) => {
        setNodes(prev => prev.map(n =>
            n.id === nodeId ? { ...n, isCollapsed: !n.isCollapsed } : n
        ));
    }, [setNodes]);

    // Keyboard Shortcuts
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            // Avoid conflict with inputs
            if (['INPUT', 'TEXTAREA'].includes((e.target as HTMLElement).tagName)) return;

            if (e.metaKey || e.ctrlKey) {
                if (e.key === '0') {
                    e.preventDefault();
                    setViewport({ x: 0, y: 0, zoom: 0.85 });
                } else if (e.key === '=' || e.key === '+') {
                    e.preventDefault();
                    setViewport(prev => ({ ...prev, zoom: Math.min(3, prev.zoom + 0.1) }));
                } else if (e.key === '-') {
                    e.preventDefault();
                    setViewport(prev => ({ ...prev, zoom: Math.max(0.1, prev.zoom - 0.1) }));
                }
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [setViewport]);

    // Calculate active lineage based on hover or selection
    const { activeLinks, activeNodes, activeColumns } = useMemo(() => {
        if (hoveredColumn) {
            const { visitedLinks, visitedNodes, visitedColumns } = traceLineage(hoveredColumn.nodeId, hoveredColumn.colId, links);
            return { activeLinks: visitedLinks, activeNodes: visitedNodes, activeColumns: visitedColumns };
        }
        if (selectedField) {
            const { visitedLinks, visitedNodes, visitedColumns } = traceLineage(selectedField.nodeId, selectedField.colId, links);
            return { activeLinks: visitedLinks, activeNodes: visitedNodes, activeColumns: visitedColumns };
        }
        return { activeLinks: new Set<string>(), activeNodes: new Set<string>(), activeColumns: new Set<string>() };
    }, [hoveredColumn, selectedField, links]);

    // Auto-expand nodes when they become part of an active lineage (Focus Mode)
    useEffect(() => {
        const isColumnTrace = selectedField || hoveredColumn;
        if (activeNodes.size > 0 && isColumnTrace) {
            setNodes(prev => {
                const needsUpdate = prev.some(n => activeNodes.has(n.id) && n.isCollapsed);
                if (needsUpdate) {
                    return prev.map(n =>
                        activeNodes.has(n.id) ? { ...n, isCollapsed: false } : n
                    );
                }
                return prev;
            });
        }
    }, [activeNodes, setNodes, selectedField, hoveredColumn]);

    // Pre-calculate node traces for fast lookup
    const nodeTraceMap = useMemo(() => {
        const map = new Map<string, Set<string>>();
        activeColumns.forEach(key => {
            const [nId, cId] = key.split('||'); // Use || separator
            if (!map.has(nId)) map.set(nId, new Set());
            map.get(nId)!.add(cId);
        });
        return map;
    }, [activeColumns]);

    // Helper to get visible columns for a node
    const getVisibleColumns = (node: NodeData) => {
        // Always show all columns for visible nodes
        // (Unrelated nodes are hidden entirely by the map loop)
        return node.columns;
    };

    // Helper to calculate connection points
    const NODE_HEADER_OFFSET = NODE_HEADER_HEIGHT + 4; // Matches GraphNode render
    const getConnectionPoint = (nodeId: string, colId: string, type: 'source' | 'target') => {
        const node = nodes.find(n => n.id === nodeId);
        if (!node) return { x: 0, y: 0 };

        // Determine effective columns for layout
        const visibleCols = getVisibleColumns(node);
        const colIndex = visibleCols.findIndex(c => c.id === colId);

        // If column is not visible (hidden by filter), point to header center
        // This handles cases where a link exists but we are hiding the column (rare in this logic, but safe)
        if (node.isCollapsed || colIndex === -1) {
            const y = node.y + (NODE_HEADER_HEIGHT / 2);
            const x = type === 'source' ? node.x + node.width : node.x;
            return { x, y };
        }

        const validIndex = colIndex;

        // Y position calculation to match the center of the column row
        const y = node.y + NODE_HEADER_OFFSET + (validIndex * COLUMN_ROW_HEIGHT) + (COLUMN_ROW_HEIGHT / 2);
        const x = type === 'source' ? node.x + node.width : node.x;

        return { x, y };
    };

    const handleViewportMouseDown = (e: React.MouseEvent) => {
        setIsViewportDragging(true);
        setViewportDragStart({ x: e.clientX, y: e.clientY });
    };

    const handleNodeMouseDown = (e: React.MouseEvent, nodeId: string) => {
        e.stopPropagation(); // Prevent viewport drag

        // Node Selection Logic - 只更新节点选中状态用于拖拽
        // 在血缘聚焦模式下（有 selectedField），不清除聚焦
        setSelectedNodeId(nodeId);
        // 注意：不调用 onFieldSelect(null)，保持血缘聚焦模式

        const node = nodes.find(n => n.id === nodeId);
        if (!node) return;

        // Calculate mouse position in SVG coordinates
        const svgMouseX = (e.clientX - viewport.x) / viewport.zoom;
        const svgMouseY = (e.clientY - viewport.y) / viewport.zoom;

        setDraggingNodeId(nodeId);
        setDragNodeOffset({
            x: svgMouseX - node.x,
            y: svgMouseY - node.y
        });
    };

    const handleMouseMove = (e: React.MouseEvent) => {
        // 1. Handle Node Dragging
        if (draggingNodeId) {
            const svgMouseX = (e.clientX - viewport.x) / viewport.zoom;
            const svgMouseY = (e.clientY - viewport.y) / viewport.zoom;

            const newX = svgMouseX - dragNodeOffset.x;
            const newY = svgMouseY - dragNodeOffset.y;

            setNodes(prev => prev.map(n =>
                n.id === draggingNodeId
                    ? { ...n, x: newX, y: newY }
                    : n
            ));
            return;
        }

        // 2. Handle Viewport Panning
        if (isViewportDragging) {
            const dx = e.clientX - viewportDragStart.x;
            const dy = e.clientY - viewportDragStart.y;

            setViewport(prev => ({
                ...prev,
                x: prev.x + dx,
                y: prev.y + dy
            }));

            setViewportDragStart({ x: e.clientX, y: e.clientY });
        }
    };

    const handleMouseUp = () => {
        setIsViewportDragging(false);
        setDraggingNodeId(null);
    };

    const handleWheel = (e: React.WheelEvent) => {
        // Zoom if Ctrl/Cmd is pressed
        if (e.ctrlKey || e.metaKey) {
            e.preventDefault();
            const zoomSensitivity = 0.001;
            const newZoom = Math.max(0.1, Math.min(3, viewport.zoom - e.deltaY * zoomSensitivity));
            setViewport(prev => ({ ...prev, zoom: newZoom }));
        } else {
            // Pan otherwise
            // e.deltaX/Y represents scroll amount. Panning subtracts delta to move viewport.
            setViewport(prev => ({
                ...prev,
                x: prev.x - e.deltaX,
                y: prev.y - e.deltaY
            }));
        }
    };

    const isLinkHighlighted = (link: LinkData) => {
        // If lineage trace is active (column selected/hovered), show only those links
        if (activeLinks.size > 0) {
            return activeLinks.has(link.id);
        }

        // If hovering a specific link
        if (hoveredLinkId === link.id) return true;

        // If hovering a node (and NOT a column), show all links for that node
        if (hoveredNodeId && !hoveredColumn && !selectedField && !hoveredLinkId) {
            return link.sourceNodeId === hoveredNodeId || link.targetNodeId === hoveredNodeId;
        }
        return false;
    };

    const isNodeHighlighted = (nodeId: string) => {
        if (selectedNodeId === nodeId) return true;

        // If lineage trace is active
        if (activeNodes.size > 0) {
            return activeNodes.has(nodeId);
        }

        // If hovering a link, highlight its connected nodes
        if (hoveredLinkId) {
            const link = links.find(l => l.id === hoveredLinkId);
            if (link) {
                return link.sourceNodeId === nodeId || link.targetNodeId === nodeId;
            }
        }

        // If hovering a node (and not in column mode), highlight its neighbors
        if (hoveredNodeId && !hoveredColumn && !selectedField && !hoveredLinkId) {
            return links.some(
                l => (l.sourceNodeId === hoveredNodeId && l.targetNodeId === nodeId) ||
                    (l.targetNodeId === hoveredNodeId && l.sourceNodeId === nodeId)
            );
        }

        if (hoveredNodeId === nodeId) return true;
        return false;
    }

    // Smart Link Consolidation: 
    // If we are NOT tracing specific columns (no active lineage), consolidate links to Table-to-Table only.
    // This improves performance and visual clarity (prevents "thick lines").
    // If we ARE tracing (hovering/selecting column), show full details.
    const renderableLinks = useMemo(() => {
        const isInteracting = activeLinks.size > 0;

        if (isInteracting) {
            return links;
        }

        const unique = new Map<string, LinkData>();
        links.forEach(l => {
            const key = `${l.sourceNodeId}::${l.targetNodeId}`;
            if (!unique.has(key)) {
                unique.set(key, {
                    ...l,
                    id: `consolidated-${key}`,
                    sourceColumnId: '',
                    targetColumnId: ''
                });
            }
        });
        return Array.from(unique.values());
    }, [links, activeLinks]);

    return (
        <div
            className="w-full h-full overflow-hidden cursor-grab active:cursor-grabbing bg-slate-50"
            onMouseDown={handleViewportMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
            onWheel={handleWheel}
        >
            <svg
                ref={svgRef}
                width="100%"
                height="100%"
            >
                <defs>
                    {/* Dot Grid Pattern */}
                    <pattern id="dot-grid" width={24 * viewport.zoom} height={24 * viewport.zoom} patternUnits="userSpaceOnUse">
                        <circle cx={2 * viewport.zoom} cy={2 * viewport.zoom} r={1.5 * viewport.zoom} fill="#CBD5E1" />
                    </pattern>
                </defs>

                {/* Background Click Handler */}
                <rect
                    width="100%"
                    height="100%"
                    fill="url(#dot-grid)"
                    onClick={() => {
                        // 只清除节点选中状态，保留字段选择（血缘聚焦模式）
                        // 用户需要点击其他字段来切换，或从侧边栏重新选择
                        setSelectedNodeId(null);
                    }}
                />

                <g transform={`translate(${viewport.x}, ${viewport.y}) scale(${viewport.zoom})`}>
                    {/* Links Layer */}
                    {renderableLinks.map(link => {
                        // Strict Field Mode visibility check
                        if (selectedField && !activeLinks.has(link.id)) return null;

                        const start = getConnectionPoint(link.sourceNodeId, link.sourceColumnId, 'source');
                        const end = getConnectionPoint(link.targetNodeId, link.targetColumnId || '', 'target');
                        const isActive = isLinkHighlighted(link);

                        // Table Mode: Dim unrelated links if hovering
                        // activeLinks is populated by traceLineage when hovered or selected.
                        // But here selectedField is active, so we already returned null above if not active.
                        // So only dimming logic applies when generated by HOVER in Table Mode.
                        const isDimmed = !selectedField && activeLinks.size > 0 && !isActive;

                        return (
                            <g key={link.id} opacity={isDimmed ? 0.05 : 1} style={{ transition: 'opacity 0.3s' }}>
                                <GraphLink
                                    id={link.id}
                                    x1={start.x}
                                    y1={start.y}
                                    x2={end.x}
                                    y2={end.y}
                                    highlighted={isActive}
                                    onLinkHover={setHoveredLinkId}
                                />
                            </g>
                        );
                    })}

                    {/* Nodes Layer */}
                    {nodes.map(node => {
                        // Strict Field Mode visibility check: Hide nodes not in the lineage path
                        if (selectedField && !activeNodes.has(node.id)) return null;

                        const isParticipating = activeNodes.has(node.id);

                        // Always show all columns for visible nodes
                        const displayColumns = node.columns;
                        const displayNode = { ...node, columns: displayColumns };

                        // Auto-expand if participating in a trace, otherwise respect collapse state
                        const effectiveCollapsed = node.isCollapsed && !isParticipating;

                        // Calculate dimmed columns for Focus Mode
                        let dimmedColumnIds: Set<string> | undefined;
                        if (selectedField && isParticipating) {
                            const traceCols = nodeTraceMap.get(node.id);
                            // If we have trace info and it's NOT a table-level match (empty string),
                            // then dim all non-trace columns.
                            if (traceCols && !traceCols.has('')) {
                                dimmedColumnIds = new Set(
                                    node.columns
                                        .filter(c => !traceCols.has(c.id))
                                        .map(c => c.id)
                                );
                            }
                        }

                        return (
                            <GraphNode
                                key={node.id}
                                node={displayNode}
                                highlighted={isNodeHighlighted(node.id)}
                                selected={selectedNodeId === node.id}
                                onNodeHover={handleNodeHover}
                                hoveredColumnId={hoveredColumn?.nodeId === node.id ? hoveredColumn.colId : null}
                                selectedColumnId={selectedField?.nodeId === node.id ? selectedField.colId : null}
                                traceColumnIds={nodeTraceMap.get(node.id)}
                                dimmedColumnIds={dimmedColumnIds}
                                onColumnHover={handleColumnHover}
                                onColumnSelect={handleColumnSelect}
                                onNodeSelect={handleNodeSelect}
                                isCollapsed={effectiveCollapsed}
                                onToggleCollapse={handleToggleCollapse}
                                onMouseDown={handleNodeMouseDown}
                            />
                        );
                    })}

                    {/* Drag Indicator Bounding Box */}
                    {draggingNodeId && (() => {
                        const node = nodes.find(n => n.id === draggingNodeId);
                        if (!node) return null;

                        const height = node.isCollapsed
                            ? NODE_HEADER_HEIGHT
                            : NODE_HEADER_HEIGHT + (node.columns.length * COLUMN_ROW_HEIGHT) + 8;

                        return (
                            <rect
                                x={node.x - 6}
                                y={node.y - 6}
                                width={node.width + 12}
                                height={height + 12}
                                rx={16}
                                ry={16}
                                fill="none"
                                stroke="#6366F1"
                                strokeWidth={2}
                                strokeDasharray="6 4"
                                className="pointer-events-none opacity-80"
                            />
                        );
                    })()}

                </g>
            </svg>

            {/* Modern Zoom Controls */}
            <div className="absolute bottom-8 right-8 flex flex-col space-y-3">
                <div className="flex flex-col bg-white/90 backdrop-blur shadow-lg border border-slate-200 rounded-2xl overflow-hidden p-1">
                    <button
                        className="w-10 h-10 flex items-center justify-center hover:bg-slate-100 text-slate-600 rounded-xl transition-colors"
                        onClick={() => setViewport(v => ({ ...v, zoom: Math.min(3, v.zoom + 0.1) }))}
                        title="Zoom In (Ctrl +)"
                    >
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                    </button>
                    <button
                        className="w-10 h-10 flex items-center justify-center hover:bg-slate-100 text-slate-600 rounded-xl transition-colors"
                        onClick={() => setViewport(v => ({ ...v, zoom: Math.max(0.1, v.zoom - 0.1) }))}
                        title="Zoom Out (Ctrl -)"
                    >
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                    </button>
                </div>
                <button
                    className="w-10 h-10 bg-white/90 backdrop-blur shadow-lg border border-slate-200 rounded-2xl flex items-center justify-center hover:bg-slate-100 text-slate-600 font-bold transition-transform active:scale-95"
                    onClick={() => setViewport({ x: 0, y: 0, zoom: 0.85 })}
                    title="Reset View (Ctrl 0)"
                >
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 4 23 10 17 10"></polyline><polyline points="1 20 1 14 7 14"></polyline><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg>
                </button>
            </div>
        </div>
    );
};

export default LineageDiagram;
