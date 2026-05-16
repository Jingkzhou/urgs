import React, { useEffect, useMemo, useState } from 'react';
import { Button, Input, Tooltip } from 'antd';
import { DownOutlined, SearchOutlined, UpOutlined } from '@ant-design/icons';
import { NodeData } from '../types';

interface G6NodeSearchProps {
    nodes: NodeData[];
    onFocusNode: (nodeId: string) => void;
}

const G6NodeSearch: React.FC<G6NodeSearchProps> = ({ nodes, onFocusNode }) => {
    const [keyword, setKeyword] = useState('');
    const [currentIndex, setCurrentIndex] = useState(0);
    const normalizedKeyword = keyword.trim().toLowerCase();
    const matches = useMemo(() => {
        if (!normalizedKeyword) {
            return [];
        }
        return nodes.filter(node => node.title.toLowerCase().includes(normalizedKeyword));
    }, [nodes, normalizedKeyword]);

    useEffect(() => {
        setCurrentIndex(0);
    }, [normalizedKeyword, matches.length]);

    useEffect(() => {
        const target = matches[currentIndex];
        if (target) {
            onFocusNode(target.id);
        }
    }, [currentIndex, matches, onFocusNode]);

    const move = (step: number) => {
        if (matches.length === 0) {
            return;
        }
        setCurrentIndex(prev => (prev + step + matches.length) % matches.length);
    };

    return (
        <div className="ml-auto flex min-w-[260px] items-center gap-1 rounded-md border border-slate-200 bg-slate-50 px-1.5 py-1">
            <Input
                size="small"
                allowClear
                prefix={<SearchOutlined />}
                placeholder="搜索并定位表"
                value={keyword}
                onChange={event => setKeyword(event.target.value)}
                onPressEnter={() => move(1)}
                className="border-0 bg-transparent shadow-none"
            />
            <span className="min-w-[42px] text-center text-[11px] text-slate-500">
                {normalizedKeyword ? `${matches.length ? currentIndex + 1 : 0}/${matches.length}` : '-/-'}
            </span>
            <Tooltip title="上一个匹配">
                <Button size="small" type="text" icon={<UpOutlined />} disabled={matches.length < 2} onClick={() => move(-1)} />
            </Tooltip>
            <Tooltip title="下一个匹配">
                <Button size="small" type="text" icon={<DownOutlined />} disabled={matches.length < 2} onClick={() => move(1)} />
            </Tooltip>
        </div>
    );
};

export default G6NodeSearch;
