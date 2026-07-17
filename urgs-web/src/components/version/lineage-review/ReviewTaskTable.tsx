import React from 'react';
import { Alert, Button, Card, Progress, Space, Table, Tag, Tooltip, Typography } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { LineageAnalysisRecordItem, LineageReviewTask } from '@/api/lineage';
import { Activity, Download, RefreshCw } from 'lucide-react';
import { statusColorMap, statusLabelMap } from './reviewConstants';
import {
    buildShardLabel,
    formatDateTime,
    getTaskExecutionRate,
    getTaskIssueTotal,
    getTaskReviewedTotal,
    TaskSourceMeta
} from './reviewUtils';

const { Paragraph } = Typography;

interface ReviewTaskTableProps {
    selectedRecord?: LineageAnalysisRecordItem;
    selectedTask?: LineageReviewTask;
    selectedTaskId?: number;
    tasks: LineageReviewTask[];
    loading: boolean;
    triggerLoading: boolean;
    reportDownloading: boolean;
    canTrigger: boolean;
    canExport: boolean;
    taskPage: number;
    taskPageSize: number;
    getTaskSourceMeta: (task: LineageReviewTask) => TaskSourceMeta;
    onRefresh: () => void;
    onForceRerun: () => void;
    onDownloadMarkdown: () => void;
    onOpenSqlPreview: (task: LineageReviewTask) => void;
    onTaskSelect: (taskId: number) => void;
    onPageChange: (page: number, pageSize: number) => void;
}

const ReviewTaskTable: React.FC<ReviewTaskTableProps> = ({
    selectedRecord,
    selectedTask,
    selectedTaskId,
    tasks,
    loading,
    triggerLoading,
    reportDownloading,
    canTrigger,
    canExport,
    taskPage,
    taskPageSize,
    getTaskSourceMeta,
    onRefresh,
    onForceRerun,
    onDownloadMarkdown,
    onOpenSqlPreview,
    onTaskSelect,
    onPageChange
}) => {
    const taskColumns: ColumnsType<LineageReviewTask> = [
        {
            title: '分片',
            key: 'path',
            render: (_, record) => (
                <div>
                    <div className="font-semibold text-slate-700">{buildShardLabel(record)}</div>
                    <div className="text-xs text-slate-400">{record.systemKey || 'GLOBAL'}</div>
                </div>
            )
        },
        {
            title: '源码',
            key: 'source',
            width: 240,
            render: (_, record) => {
                const sourceMeta = getTaskSourceMeta(record);
                return (
                    <div className="space-y-1">
                        <Button
                            type="link"
                            className="!h-auto !p-0"
                            onClick={event => {
                                event.stopPropagation();
                                onOpenSqlPreview(record);
                            }}
                        >
                            查看 SQL 片段
                        </Button>
                        <Tooltip title={<div style={{ whiteSpace: 'pre-wrap' }}>{sourceMeta.tooltip}</div>}>
                            <Paragraph className="!mb-0 !text-slate-500" ellipsis={{ rows: 2 }}>
                                {sourceMeta.text}
                            </Paragraph>
                        </Tooltip>
                    </div>
                );
            }
        },
        {
            title: '状态',
            dataIndex: 'status',
            width: 110,
            render: (value?: string) => (
                <Tag color={statusColorMap[value || ''] || 'default'}>
                    {statusLabelMap[value || ''] || value || '-'}
                </Tag>
            )
        },
        {
            title: '进度',
            key: 'progress',
            width: 300,
            render: (_, record) => {
                const executionRate = getTaskExecutionRate(record);
                const executionTotal = record.objectCount || 0;
                const executionProcessed = executionTotal > 0
                    ? Math.min(record.processedCount || 0, executionTotal)
                    : (record.processedCount || 0);
                const coveredStatements = record.screenedStatementCount || 0;
                const verifiedStatements = record.verifiedStatementCount || 0;
                const highRiskStatements = record.highRiskStatementCount || 0;
                const skippedStatements = record.skippedStatementCount || 0;
                const failedStatements = record.failedStatementAuditCount || 0;
                const hasAiReview = (record.tokenBudget || 0) > 0;
                const isCompleted = ['COMPLETED', 'DEGRADED'].includes(record.status || '');
                return (
                    <div className="space-y-2.5">
                        {executionTotal > 0 ? (
                            <div>
                                <div className="mb-1 flex items-center justify-between text-xs text-slate-500">
                                    <span>已处理 {executionProcessed}/{executionTotal} 个 SQL</span>
                                    <span>{executionRate}%</span>
                                </div>
                                <Progress percent={executionRate} size="small" showInfo={false} />
                            </div>
                        ) : (
                            <div className="mb-1 flex items-center justify-between text-xs text-slate-500">
                                <span>
                                    {record.status === 'FAILED'
                                        ? '未获取到可处理的 SQL'
                                        : (isCompleted ? '没有需要处理的 SQL' : '正在准备 SQL')}
                                </span>
                            </div>
                        )}
                        {hasAiReview && (
                            <div className="text-xs leading-5 text-slate-500">
                                <div>
                                    AI 已检查 <span className="font-medium text-slate-700">{coveredStatements}</span> 个 SQL
                                    {verifiedStatements > 0 && ` · 精审 ${verifiedStatements} 个`}
                                    {highRiskStatements > 0 && ` · 高风险 ${highRiskStatements} 个`}
                                </div>
                                {(skippedStatements > 0 || failedStatements > 0) && (
                                    <div className="text-amber-600">
                                        {skippedStatements > 0 && `跳过 ${skippedStatements} 个`}
                                        {skippedStatements > 0 && failedStatements > 0 && ' · '}
                                        {failedStatements > 0 && `失败 ${failedStatements} 个`}
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                );
            }
        },
        {
            title: '疑点状态',
            key: 'issueSummary',
            width: 230,
            render: (_, record) => {
                const issueTotal = getTaskIssueTotal(record);
                const reviewed = getTaskReviewedTotal(record);
                if (issueTotal <= 0) {
                    const isCompleted = ['COMPLETED', 'DEGRADED'].includes(record.status || '');
                    return <Tag color={isCompleted ? 'green' : 'default'}>{isCompleted ? '未发现疑点' : '暂未发现疑点'}</Tag>;
                }
                return (
                    <div className="space-y-1.5 text-xs">
                        <div className="text-slate-500">共 {issueTotal} 条 · 已处理 {reviewed} 条</div>
                        <div className="flex flex-wrap gap-1">
                            {(record.pendingIssueCount || 0) > 0 && <Tag>待处理 {record.pendingIssueCount}</Tag>}
                            {(record.confirmedIssueCount || 0) > 0 && <Tag color="green">确认问题 {record.confirmedIssueCount}</Tag>}
                            {(record.falsePositiveIssueCount || 0) > 0 && <Tag color="red">误报 {record.falsePositiveIssueCount}</Tag>}
                            {(record.resolvedIssueCount || 0) > 0 && <Tag color="blue">已解决 {record.resolvedIssueCount}</Tag>}
                        </div>
                    </div>
                );
            }
        },
        {
            title: '完成时间',
            dataIndex: 'finishedAt',
            width: 180,
            render: (value?: string) => <span className="text-xs text-slate-500">{formatDateTime(value)}</span>
        }
    ];

    return (
        <Card
            title={
                <div className="flex items-center gap-2">
                    <Activity size={16} className="text-sky-500" />
                    <span>分片任务</span>
                </div>
            }
            extra={
                <Space>
                    <Button
                        size="small"
                        icon={<RefreshCw size={14} />}
                        loading={loading}
                        disabled={!selectedRecord}
                        onClick={onRefresh}
                    >
                        刷新
                    </Button>
                    <Button
                        size="small"
                        loading={triggerLoading}
                        disabled={!selectedRecord || !canTrigger}
                        title={canTrigger ? '' : '缺少 version:ai:trigger 权限'}
                        onClick={onForceRerun}
                    >
                        重新校验
                    </Button>
                    <Button
                        size="small"
                        icon={<Download size={14} />}
                        loading={reportDownloading}
                        disabled={!selectedTask || !canExport}
                        title={canExport ? '' : '缺少 version:ai:export 权限'}
                        onClick={onDownloadMarkdown}
                    >
                        下载 Markdown
                    </Button>
                </Space>
            }
            bordered={false}
            className="shadow-sm"
        >
            {selectedRecord && selectedRecord.status !== 'SUCCESS' && (
                <Alert
                    className="mb-4"
                    type="warning"
                    showIcon
                    message="当前分析记录尚未成功完成"
                    description="只有 SUCCESS 状态的血缘分析记录才会自动创建事后校验任务。"
                />
            )}
            <Table
                rowKey="id"
                dataSource={tasks}
                columns={taskColumns}
                loading={loading}
                pagination={{
                    current: taskPage,
                    pageSize: taskPageSize,
                    total: tasks.length,
                    size: 'small',
                    showSizeChanger: true,
                    pageSizeOptions: ['10', '20', '50'],
                    onChange: onPageChange
                }}
                locale={{ emptyText: '当前批次暂无校验任务' }}
                rowSelection={{
                    type: 'radio',
                    selectedRowKeys: selectedTaskId == null ? [] : [selectedTaskId],
                    onChange: keys => {
                        if (keys.length > 0) {
                            onTaskSelect(Number(keys[0]));
                        }
                    }
                }}
                onRow={record => ({
                    onClick: () => {
                        onTaskSelect(record.id);
                    }
                })}
            />
        </Card>
    );
};

export default ReviewTaskTable;
