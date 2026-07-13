import React, { useMemo, useState } from 'react';
import { Button, Checkbox, Empty, Input, Select, Space, Table, Tag, Tooltip, Typography } from 'antd';
import { LeftOutlined, RightOutlined, SearchOutlined } from '@ant-design/icons';
import { ImpactRow, LineageGraphStats, getRelationLabel, getRelationStyle } from '../utils/lineageGraphDensity';

const { Text } = Typography;

interface LineageImpactPanelProps {
    rows: ImpactRow[];
    stats: LineageGraphStats;
    relationOptions: string[];
    selectedRelationTypes: string[];
    fieldTraceEnabled: boolean;
    fieldTraceLoading: boolean;
    onRelationTypesChange: (types: string[]) => void;
    onToggleFieldTrace: () => void;
    onFocusTable: (nodeId: string) => void;
    onOpenTable?: (tableName: string, qualifiedName: string, objectUid?: string) => void;
}

const directionLabel: Record<ImpactRow['direction'], string> = {
    upstream: '上游',
    downstream: '下游',
    same: '同层',
};

const directionColor: Record<ImpactRow['direction'], string> = {
    upstream: 'blue',
    downstream: 'green',
    same: 'default',
};

const LineageImpactPanel: React.FC<LineageImpactPanelProps> = ({
    rows,
    stats,
    relationOptions,
    selectedRelationTypes,
    fieldTraceEnabled,
    fieldTraceLoading,
    onRelationTypesChange,
    onToggleFieldTrace,
    onFocusTable,
    onOpenTable,
}) => {
    const [keyword, setKeyword] = useState('');
    const [direction, setDirection] = useState<'all' | ImpactRow['direction']>('all');
    const [collapsed, setCollapsed] = useState(true);

    const filteredRows = useMemo(() => {
        const normalizedKeyword = keyword.trim().toLowerCase();
        return rows.filter(row => {
            const keywordMatched = !normalizedKeyword
                || row.qualifiedName.toLowerCase().includes(normalizedKeyword)
                || row.tableName.toLowerCase().includes(normalizedKeyword)
                || row.owner.toLowerCase().includes(normalizedKeyword);
            const directionMatched = direction === 'all' || row.direction === direction;
            return keywordMatched && directionMatched;
        });
    }, [direction, keyword, rows]);

    const relationCheckboxOptions = relationOptions.map(type => ({
        value: type,
        label: (
            <span className="inline-flex items-center gap-1">
                <span
                    className="inline-block h-2 w-2 rounded-full"
                    style={{ background: getRelationStyle(type).color }}
                />
                {getRelationLabel(type)}
            </span>
        ),
    }));

    const columns = [
        {
            title: '表',
            dataIndex: 'qualifiedName',
            key: 'qualifiedName',
            width: 190,
            render: (_: string, record: ImpactRow) => (
                <div className="min-w-0">
                    <div className="truncate font-semibold text-slate-800" title={record.qualifiedName}>
                        {record.tableName}
                    </div>
                    <div className="truncate text-xs text-slate-400" title={record.owner}>
                        {record.owner || '-'}
                    </div>
                </div>
            ),
            sorter: (a: ImpactRow, b: ImpactRow) => a.qualifiedName.localeCompare(b.qualifiedName),
        },
        {
            title: '方向',
            dataIndex: 'direction',
            key: 'direction',
            width: 70,
            render: (value: ImpactRow['direction']) => (
                <Tag color={directionColor[value]} style={{ margin: 0 }}>
                    {directionLabel[value]}
                </Tag>
            ),
            sorter: (a: ImpactRow, b: ImpactRow) => a.hop - b.hop,
        },
        {
            title: '类型',
            dataIndex: 'relationLabels',
            key: 'relationLabels',
            width: 92,
            render: (_: string, record: ImpactRow) => (
                <Tooltip title={record.relationLabels}>
                    <Space size={4} wrap>
                        {record.relationTypes.slice(0, 2).map(type => (
                            <Tag key={type} color={getRelationStyle(type).color} style={{ margin: 0 }}>
                                {getRelationLabel(type)}
                            </Tag>
                        ))}
                        {record.relationTypes.length > 2 ? <Tag style={{ margin: 0 }}>+{record.relationTypes.length - 2}</Tag> : null}
                    </Space>
                </Tooltip>
            ),
        },
        {
            title: '关系',
            dataIndex: 'relationCount',
            key: 'relationCount',
            width: 68,
            align: 'right' as const,
            render: (value: number) => <Text>{value}</Text>,
            sorter: (a: ImpactRow, b: ImpactRow) => a.relationCount - b.relationCount,
        },
    ];

    if (collapsed) {
        return (
            <div className="absolute right-4 top-4 z-30 flex flex-col items-center gap-2 rounded-md border border-slate-200 bg-white/95 px-2 py-3 shadow-lg backdrop-blur">
                <Tooltip title="展开影响清单" placement="left">
                    <Button
                        size="small"
                        type="text"
                        icon={<LeftOutlined />}
                        onClick={() => setCollapsed(false)}
                    />
                </Tooltip>
                <div style={{ writingMode: 'vertical-rl', letterSpacing: 0 }} className="text-xs font-semibold text-slate-600">
                    影响清单
                </div>
                <Tag color="blue" style={{ margin: 0 }}>
                    {rows.length}
                </Tag>
            </div>
        );
    }

    return (
        <aside className="absolute right-4 top-4 z-30 flex max-h-[calc(100%-32px)] w-[380px] flex-col overflow-hidden rounded-md border border-slate-200 bg-white/95 shadow-lg backdrop-blur">
            <div className="border-b border-slate-100 px-3 py-3">
                <div className="mb-2 flex items-center justify-between gap-2">
                    <div>
                        <div className="text-sm font-semibold text-slate-800">影响清单</div>
                        <div className="text-xs text-slate-400">
                            {rows.length} 张表，{stats.originalLinkCount} 条关系
                            {stats.compactApplied ? `，已隐藏 ${stats.hiddenNodeCount} 张` : ''}
                        </div>
                    </div>
                    <Space size={4}>
                        <Button size="small" loading={fieldTraceLoading} type={fieldTraceEnabled ? 'primary' : 'default'} onClick={onToggleFieldTrace}>
                            {fieldTraceEnabled ? '退出字段' : '字段追踪'}
                        </Button>
                        <Tooltip title="收起影响清单">
                            <Button
                                size="small"
                                type="text"
                                icon={<RightOutlined />}
                                onClick={() => setCollapsed(true)}
                            />
                        </Tooltip>
                    </Space>
                </div>
                <Input
                    allowClear
                    size="small"
                    prefix={<SearchOutlined />}
                    placeholder="搜索表、Schema"
                    value={keyword}
                    onChange={event => setKeyword(event.target.value)}
                />
                <div className="mt-2 flex items-center gap-2">
                    <Select
                        size="small"
                        value={direction}
                        style={{ width: 92 }}
                        onChange={setDirection}
                        options={[
                            { value: 'all', label: '全部' },
                            { value: 'upstream', label: '上游' },
                            { value: 'downstream', label: '下游' },
                            { value: 'same', label: '同层' },
                        ]}
                    />
                </div>
                {relationOptions.length > 0 ? (
                    <div className="mt-2 rounded border border-slate-100 bg-slate-50 px-2 py-1">
                        <Checkbox.Group
                            className="flex flex-wrap gap-x-3 gap-y-1 text-xs"
                            options={relationCheckboxOptions}
                            value={selectedRelationTypes}
                            onChange={values => {
                                const next = values.map(String);
                                if (next.length > 0) {
                                    onRelationTypesChange(next);
                                }
                            }}
                        />
                    </div>
                ) : null}
            </div>
            <div className="min-h-0 flex-1 overflow-auto">
                {filteredRows.length > 0 ? (
                    <Table
                        rowKey="key"
                        size="small"
                        columns={columns}
                        dataSource={filteredRows}
                        pagination={{ pageSize: 10, size: 'small', showSizeChanger: false }}
                        onRow={(record) => ({
                            onClick: () => onFocusTable(record.nodeId),
                            onDoubleClick: () => onOpenTable?.(record.tableName, record.qualifiedName, record.objectUid),
                        })}
                    />
                ) : (
                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无匹配表" style={{ padding: '24px 0' }} />
                )}
            </div>
        </aside>
    );
};

export default LineageImpactPanel;
