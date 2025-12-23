import React, { useState } from 'react';
import { RELATION_STYLES } from '../types';

interface GraphLinkProps {
    id: string;
    x1: number;
    y1: number;
    x2: number;
    y2: number;
    highlighted: boolean;
    linkType?: string;  // 关系类型: DERIVES_TO, FILTERS, JOINS 等
    snippet?: string;   // SQL 代码片段
    onLinkHover: (id: string | null) => void;
    onLinkClick?: (event: React.MouseEvent, id: string, snippet?: string, linkType?: string) => void;
}

const GraphLink: React.FC<GraphLinkProps> = ({ id, x1, y1, x2, y2, highlighted, linkType = 'DERIVES_TO', snippet, onLinkHover, onLinkClick }) => {
    const dist = Math.abs(x2 - x1);
    const controlOffset = dist * 0.55;

    const path = `
    M ${x1} ${y1}
    C ${x1 + controlOffset} ${y1},
      ${x2 - controlOffset} ${y2},
      ${x2} ${y2}
  `;

    // 获取关系类型的样式配置
    const style = RELATION_STYLES[linkType] || RELATION_STYLES.DERIVES_TO;
    const strokeColor = highlighted ? style.highlightColor : style.color;
    const strokeDasharray = style.strokeDasharray;

    // 高亮时使用对应颜色，否则使用淡色
    const normalColor = highlighted ? strokeColor : '#CBD5E1';
    const glowColor = strokeColor;

    const handleClick = (event: React.MouseEvent) => {
        event.stopPropagation(); // Prevent clearing selection when clicking the link itself
        if (onLinkClick) {
            onLinkClick(event, id, snippet, linkType);
        }
    };

    return (
        <g
            style={{ opacity: highlighted ? 1 : 0.4, transition: 'opacity 0.3s ease', cursor: snippet ? 'pointer' : 'default' }}
            onMouseEnter={() => onLinkHover(id)}
            onMouseLeave={() => onLinkHover(null)}
            onClick={handleClick}
        >
            {/* Invisible thick path for easier interaction/hover area */}
            <path
                d={path}
                fill="none"
                stroke="transparent"
                strokeWidth={16}
            />

            {/* Shadow/Glow for highlighted links */}
            {highlighted && (
                <path
                    d={path}
                    fill="none"
                    stroke={glowColor}
                    strokeWidth={4}
                    strokeOpacity={0.3}
                    strokeDasharray={strokeDasharray}
                    style={{ filter: 'blur(2px)' }}
                    className="pointer-events-none"
                />
            )}

            {/* Main visible path */}
            <path
                d={path}
                fill="none"
                stroke={highlighted ? strokeColor : normalColor}
                strokeWidth={highlighted ? 2.5 : 1.5}
                strokeLinecap="round"
                strokeDasharray={strokeDasharray}
                className="transition-all duration-300 ease-in-out pointer-events-none"
            />

            {/* Arrow marker at the end */}
            <polygon
                points={`${x2},${y2} ${x2 - 8},${y2 - 4} ${x2 - 8},${y2 + 4}`}
                fill={highlighted ? strokeColor : normalColor}
                className="pointer-events-none transition-all duration-300"
            />
        </g>
    );
};

export default GraphLink;

