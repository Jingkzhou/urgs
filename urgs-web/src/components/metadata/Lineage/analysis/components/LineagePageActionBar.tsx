import React from 'react';
import { Checkbox, Segmented } from 'antd';
import { FileTextOutlined, TableOutlined } from '@ant-design/icons';
import LineageEngineToolbar from './LineageEngineToolbar';
import type { UseLineageEngineControllerResult } from '../hooks/useLineageEngineController';

export type LineageViewMode = 'canvas' | 'list';
export type LineageDirectionOption = 'upstream' | 'downstream';

interface LineagePageActionBarProps {
    viewMode: LineageViewMode;
    directionOptions: LineageDirectionOption[];
    controller: UseLineageEngineControllerResult;
    canOpenAuditBoard: boolean;
    onViewModeChange: (value: LineageViewMode) => void;
    onDirectionChange: (values: LineageDirectionOption[]) => void;
    onOpenAuditBoard: () => void;
}

const LineagePageActionBar: React.FC<LineagePageActionBarProps> = ({
    viewMode,
    directionOptions,
    controller,
    canOpenAuditBoard,
    onViewModeChange,
    onDirectionChange,
    onOpenAuditBoard,
}) => (
    <div className="lineage-action-bar">
        <Segmented
            options={[
                { label: '流程图', value: 'canvas', icon: <TableOutlined /> },
                { label: '列表', value: 'list', icon: <FileTextOutlined /> },
            ]}
            value={viewMode}
            onChange={(val: any) => onViewModeChange(val)}
        />
        <div className="lineage-direction-filter">
            <span style={{ fontSize: 13, color: '#4b5563' }}>查询方向</span>
            <Checkbox.Group value={directionOptions} onChange={(values) => onDirectionChange(values as LineageDirectionOption[])}>
                <Checkbox value="upstream">上游</Checkbox>
                <Checkbox value="downstream">下游</Checkbox>
            </Checkbox.Group>
        </div>
        <LineageEngineToolbar
            controller={controller}
            canOpenAuditBoard={canOpenAuditBoard}
            onOpenAuditBoard={onOpenAuditBoard}
        />
    </div>
);

export default LineagePageActionBar;
