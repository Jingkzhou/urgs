import React from 'react';
import { Checkbox, Segmented } from 'antd';
import { BranchesOutlined, FileTextOutlined, TableOutlined } from '@ant-design/icons';
import LineageEngineToolbar from './LineageEngineToolbar';
import type { UseLineageEngineControllerResult } from '../hooks/useLineageEngineController';
import type { LineageDisplayMode } from '../utils/endToEndLineage';

export type LineageViewMode = 'canvas' | 'list';
export type LineageDirectionOption = 'upstream' | 'downstream';

interface LineagePageActionBarProps {
    viewMode: LineageViewMode;
    displayMode: LineageDisplayMode;
    directionOptions: LineageDirectionOption[];
    controller: UseLineageEngineControllerResult;
    canOpenAuditBoard: boolean;
    onViewModeChange: (value: LineageViewMode) => void;
    onDisplayModeChange: (value: LineageDisplayMode) => void;
    onDirectionChange: (values: LineageDirectionOption[]) => void;
    onOpenAuditBoard: () => void;
}

const LineagePageActionBar: React.FC<LineagePageActionBarProps> = ({
    viewMode,
    displayMode,
    directionOptions,
    controller,
    canOpenAuditBoard,
    onViewModeChange,
    onDisplayModeChange,
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
        <div className="lineage-display-mode-filter">
            <span style={{ fontSize: 13, color: '#4b5563' }}>显示模式</span>
            <Segmented
                options={[
                    { label: '完整链路', value: 'full', icon: <BranchesOutlined /> },
                    { label: '端到端视图', value: 'endToEnd', icon: <TableOutlined /> },
                ]}
                value={displayMode}
                onChange={(val: any) => onDisplayModeChange(val)}
            />
        </div>
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
