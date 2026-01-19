import React, { useState } from 'react';
import { Database } from 'lucide-react';

export const ActiveLineageGraph = () => {
    const [hoveredNode, setHoveredNode] = useState<string | null>(null);

    // Data structure based on the user's uploaded image
    const nodes = [
        { id: 'root', label: 'SMTMODS.L_ACCT_OBS_LOAN', field: 'SECURITY_AMT', x: 50, y: 180, type: 'table' },
        { id: 'l1_top', label: 'YBT_DATACORE.T_6_11', field: 'F110001', x: 350, y: 80, type: 'table' },
        { id: 'l1_mid', label: 'YBT_DATACORE.TM_L_ACCT_OBS_TEMP', field: 'SECURITY_AMT', x: 350, y: 180, type: 'table' },
        { id: 'l1_bot', label: 'YBT_DATACORE.T_6_12', field: 'F120007', x: 350, y: 280, type: 'table' },
        { id: 'l2_mid', label: 'YBT_DATACORE.TM_L_ACCT_OBS_SX', field: 'SECURITY_AMT', x: 650, y: 180, type: 'table' },
        { id: 'l3_mid', label: 'YBT_DATACORE.T_8_13', field: 'R130004', x: 920, y: 180, type: 'table' },
    ];

    const connections = [
        { from: 'root', to: 'l1_top', type: 'dataflow' },
        { from: 'root', to: 'l1_mid', type: 'dataflow' },
        { from: 'root', to: 'l1_bot', type: 'dataflow' },
        { from: 'l1_mid', to: 'l2_mid', type: 'dataflow' },
        { from: 'l2_mid', to: 'l3_mid', type: 'filter' }, // Representing the dashed/colored line
    ];

    const legend = [
        { label: '数据流', color: '#3b82f6', dashed: false },
        { label: '过滤', color: '#f97316', dashed: true },
        { label: '关联', color: '#84cc16', dashed: true },
        { label: '条件', color: '#ef4444', dashed: true },
    ];

    return (
        <div className="relative w-full h-[400px] bg-slate-50/50 rounded-xl border border-slate-200 overflow-hidden font-sans select-none">
            {/* Grid Background */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-30">
                <defs>
                    <pattern id="dot-grid" width="20" height="20" patternUnits="userSpaceOnUse">
                        <circle cx="2" cy="2" r="1" fill="#cbd5e1" />
                    </pattern>
                </defs>
                <rect width="100%" height="100%" fill="url(#dot-grid)" />
            </svg>

            {/* Main Graph */}
            <svg className="w-full h-full" viewBox="0 0 1100 400">
                {/* Connections */}
                {connections.map((conn, i) => {
                    const from = nodes.find(n => n.id === conn.from)!;
                    const to = nodes.find(n => n.id === conn.to)!;

                    // Calculate precise connection points (right side of from, left side of to)
                    const startX = from.x + 200; // Node width is approx 200
                    const startY = from.y + 30;  // Mid-height of node (approx 60 height)
                    const endX = to.x;
                    const endY = to.y + 30;

                    const controlPoint1X = startX + (endX - startX) / 2;
                    const controlPoint1Y = startY;
                    const controlPoint2X = endX - (endX - startX) / 2;
                    const controlPoint2Y = endY;

                    const pathFn = `M ${startX} ${startY} C ${controlPoint1X} ${controlPoint1Y}, ${controlPoint2X} ${controlPoint2Y}, ${endX} ${endY}`;
                    const isFilter = conn.type === 'filter';

                    return (
                        <g key={i}>
                            <path
                                d={pathFn}
                                fill="none"
                                stroke={isFilter ? '#f97316' : '#3b82f6'}
                                strokeWidth="2"
                                strokeDasharray={isFilter ? "5,3" : "none"}
                                className="opacity-80 drop-shadow-sm"
                            />
                            {/* Animated flow particle */}
                            <circle r="4" fill={isFilter ? '#f97316' : '#3b82f6'} filter="url(#glow)">
                                <animateMotion
                                    dur="1.5s"
                                    repeatCount="indefinite"
                                    path={pathFn}
                                    begin={`${i * 0.5}s`}
                                />
                            </circle>
                        </g>
                    );
                })}
                <defs>
                    <filter id="glow">
                        <feGaussianBlur stdDeviation="2.5" result="coloredBlur" />
                        <feMerge>
                            <feMergeNode in="coloredBlur" />
                            <feMergeNode in="SourceGraphic" />
                        </feMerge>
                    </filter>
                </defs>

                {/* Nodes */}
                {nodes.map((node) => (
                    <foreignObject x={node.x} y={node.y} width="200" height="80" key={node.id}>
                        <div
                            className={`w-[200px] bg-white rounded-lg border shadow-sm transition-all duration-300 hover:shadow-md hover:scale-105 cursor-pointer ${hoveredNode === node.id ? 'border-indigo-500 ring-2 ring-indigo-100' : 'border-slate-300'}`}
                            onMouseEnter={() => setHoveredNode(node.id)}
                            onMouseLeave={() => setHoveredNode(null)}
                        >
                            <div className="flex items-center gap-2 px-3 py-2 bg-slate-50 border-b border-slate-100 rounded-t-lg">
                                <Database className="w-3 h-3 text-indigo-500" />
                                <span className="text-[10px] font-bold text-slate-700 truncate" title={node.label}>{node.label}</span>
                            </div>
                            <div className="px-3 py-2">
                                <div className="flex items-center gap-1.5 text-[10px] text-slate-500">
                                    <div className="w-1 h-1 rounded-full bg-slate-400"></div>
                                    {node.field}
                                </div>
                            </div>
                        </div>
                    </foreignObject>
                ))}
            </svg>

            {/* Legend */}
            <div className="absolute top-4 right-4 bg-white p-4 rounded-xl shadow-lg border border-slate-100 w-32">
                <h6 className="text-xs font-bold text-slate-800 mb-3">关系类型</h6>
                <div className="space-y-2">
                    {legend.map((item, i) => (
                        <div key={i} className="flex items-center gap-2 text-[10px] text-slate-600">
                            <div
                                className="w-4 h-0.5"
                                style={{
                                    backgroundColor: item.dashed ? 'transparent' : item.color,
                                    borderTop: item.dashed ? `2px dashed ${item.color}` : 'none'
                                }}
                            />
                            <span>{item.label}</span>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};
