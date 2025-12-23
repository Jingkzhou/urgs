import React from 'react';

interface GraphLinkProps {
    id: string;
    x1: number;
    y1: number;
    x2: number;
    y2: number;
    highlighted: boolean;
    onLinkHover: (id: string | null) => void;
}

const GraphLink: React.FC<GraphLinkProps> = ({ id, x1, y1, x2, y2, highlighted, onLinkHover }) => {
    const dist = Math.abs(x2 - x1);
    const controlOffset = dist * 0.55;

    const path = `
    M ${x1} ${y1}
    C ${x1 + controlOffset} ${y1},
      ${x2 - controlOffset} ${y2},
      ${x2} ${y2}
  `;

    return (
        <g
            style={{ opacity: highlighted ? 1 : 0.4, transition: 'opacity 0.3s ease' }}
            onMouseEnter={() => onLinkHover(id)}
            onMouseLeave={() => onLinkHover(null)}
        >
            {/* Invisible thick path for easier interaction/hover area */}
            <path
                d={path}
                fill="none"
                stroke="transparent"
                strokeWidth={16}
                className="cursor-pointer"
            />

            {/* Shadow/Glow for highlighted links */}
            {highlighted && (
                <path
                    d={path}
                    fill="none"
                    stroke="#818CF8"
                    strokeWidth={4}
                    strokeOpacity={0.3}
                    style={{ filter: 'blur(2px)' }}
                    className="pointer-events-none"
                />
            )}

            {/* Main visible path */}
            <path
                d={path}
                fill="none"
                stroke={highlighted ? "#6366F1" : "#CBD5E1"} // Indigo-500 vs Slate-300
                strokeWidth={highlighted ? 2 : 1.5}
                strokeLinecap="round"
                className="transition-all duration-300 ease-in-out pointer-events-none"
            />
        </g>
    );
};

export default GraphLink;
