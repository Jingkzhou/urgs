import React from 'react';
import { Card, Input, Select, Space, Table, Tag, Typography } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { LineageReviewIssue } from '@/api/lineage';
import {
    issueTypeLabelMap,
    reviewStatusColorMap,
    reviewStatusLabelMap,
    severityColorMap,
    severityLabelMap,
    toDisplayLabel,
    verdictLabelMap
} from './reviewConstants';

const { Paragraph } = Typography;

interface ReviewIssueTableProps {
    issues: LineageReviewIssue[];
    loading: boolean;
    selectedTaskId?: number;
    searchTerm: string;
    severityFilter?: string;
    reviewStatusFilter?: string;
    showingAllPending?: boolean;
    onSearchChange: (value: string) => void;
    onSeverityChange: (value?: string) => void;
    onReviewStatusChange: (value?: string) => void;
    onSelectIssue: (issue: LineageReviewIssue) => void;
}

const ReviewIssueTable: React.FC<ReviewIssueTableProps> = ({
    issues,
    loading,
    selectedTaskId,
    searchTerm,
    severityFilter,
    reviewStatusFilter,
    showingAllPending = false,
    onSearchChange,
    onSeverityChange,
    onReviewStatusChange,
    onSelectIssue
}) => {
    const issueColumns: ColumnsType<LineageReviewIssue> = [
        {
            title: '目标对象',
            key: 'target',
            render: (_, record) => (
                <div>
                    <div className="font-semibold text-slate-700">
                        {record.tableName}
                        {record.columnName ? `.${record.columnName}` : ''}
                    </div>
                    <div className="text-xs text-slate-400">{record.objectType}</div>
                </div>
            )
        },
        {
            title: '疑点类型',
            dataIndex: 'issueType',
            width: 180,
            render: (value?: string) => <Tag>{toDisplayLabel(value, issueTypeLabelMap)}</Tag>
        },
        {
            title: '严重级别',
            dataIndex: 'severity',
            width: 110,
            render: (value?: string) => (
                <Tag color={severityColorMap[value || ''] || 'default'}>
                    {toDisplayLabel(value, severityLabelMap)}
                </Tag>
            )
        },
        {
            title: 'AI 判定',
            key: 'verdict',
            width: 150,
            render: (_, record) => (
                <div>
                    <div className="text-sm font-medium text-slate-700">
                        {toDisplayLabel(record.verdict, verdictLabelMap)}
                    </div>
                    <div className="text-xs text-slate-400">置信度 {Number(record.confidence || 0).toFixed(2)}</div>
                </div>
            )
        },
        {
            title: '人工状态',
            dataIndex: 'reviewStatus',
            width: 130,
            render: (value?: string) => (
                <Tag color={reviewStatusColorMap[value || ''] || 'default'}>
                    {toDisplayLabel(value, reviewStatusLabelMap)}
                </Tag>
            )
        },
        {
            title: 'AI 结论',
            key: 'summary',
            render: (_, record) => {
                const summary = record.graphSnapshot?.aiReview?.summary
                    || record.reason?.split(/\r?\n/)[0]?.replace(/^结论：/, '')
                    || '-';
                return (
                    <div>
                        <Paragraph className="!mb-1 !text-slate-600" ellipsis={{ rows: 2 }}>
                            {summary}
                        </Paragraph>
                        <div className="text-xs text-slate-400">
                            可定位证据 {(record.evidenceRefs || []).length} 条
                        </div>
                    </div>
                );
            }
        }
    ];

    return (
        <Card
            title={showingAllPending ? '待处理疑点（全部分片）' : '疑点清单'}
            bordered={false}
            className="shadow-sm"
            extra={
                <Space wrap>
                    <Input.Search
                        allowClear
                        placeholder="搜索表名、字段或原因"
                        style={{ width: 220 }}
                        value={searchTerm}
                        onChange={e => onSearchChange(e.target.value)}
                    />
                    <Select
                        allowClear
                        placeholder="严重级别"
                        style={{ width: 120 }}
                        value={severityFilter}
                        onChange={onSeverityChange}
                        options={[
                            { label: '高', value: 'HIGH' },
                            { label: '中', value: 'MEDIUM' },
                            { label: '低', value: 'LOW' }
                        ]}
                    />
                    <Select
                        allowClear
                        placeholder="人工状态"
                        style={{ width: 140 }}
                        value={reviewStatusFilter}
                        onChange={onReviewStatusChange}
                        options={[
                            { label: '待处理', value: 'PENDING' },
                            { label: '已确认', value: 'CONFIRMED' },
                            { label: '误报', value: 'FALSE_POSITIVE' },
                            { label: '已忽略', value: 'IGNORED' },
                            { label: '已处理', value: 'RESOLVED' }
                        ]}
                    />
                </Space>
            }
        >
            <Table
                rowKey="id"
                dataSource={issues}
                columns={issueColumns}
                loading={loading}
                pagination={{ pageSize: 8 }}
                locale={{ emptyText: selectedTaskId ? '当前任务暂无疑点' : '请先选择一个分片任务' }}
                rowClassName="cursor-pointer"
                onRow={record => ({
                    onClick: () => onSelectIssue(record)
                })}
            />
        </Card>
    );
};

export default ReviewIssueTable;
