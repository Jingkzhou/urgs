import React from 'react';
import { Card, Progress, Typography } from 'antd';
import type { LineageAnalysisRecordItem, LineageReviewTask } from '@/api/lineage';
import { AlertTriangle, Bot, Database, FolderTree, ScanSearch } from 'lucide-react';
import {
    buildShardLabel,
    calculateReviewProgressSummary,
    TaskSourceMeta
} from './reviewUtils';

const { Text, Title } = Typography;

interface ReviewMetricCardsProps {
    records: LineageAnalysisRecordItem[];
    tasks: LineageReviewTask[];
    selectedTask?: LineageReviewTask;
    selectedTaskSourceMeta?: TaskSourceMeta;
    onPendingIssuesClick?: () => void;
}

const ReviewMetricCards: React.FC<ReviewMetricCardsProps> = ({
    records,
    tasks,
    selectedTask,
    selectedTaskSourceMeta,
    onPendingIssuesClick
}) => {
    const metrics = calculateReviewProgressSummary(tasks);
    const canOpenPendingIssues = metrics.pendingIssues > 0 && !!onPendingIssuesClick;

    return (
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-5">
            <Card bordered={false} className="shadow-sm">
                <div className="flex items-start justify-between">
                    <div>
                        <Text type="secondary">分析批次</Text>
                        <Title level={3} className="!mb-0 !mt-2">{records.length}</Title>
                    </div>
                    <Database className="text-sky-500" size={22} />
                </div>
            </Card>
            <Card bordered={false} className="shadow-sm">
                <div className="flex items-start justify-between gap-4">
                    <div className="min-w-0 flex-1">
                        <Text type="secondary">AI 已检查 SQL</Text>
                        <Title level={3} className="!mb-0 !mt-2">{metrics.coveredStatements} 个</Title>
                        {metrics.totalStatements > 0 && (
                            <Progress percent={metrics.statementCoverageRate} size="small" showInfo={false} />
                        )}
                        <div className="text-xs text-slate-400">
                            {metrics.totalStatements > 0
                                ? `共 ${metrics.totalStatements} 个 SQL${metrics.verifiedStatements > 0 ? ` · 精审 ${metrics.verifiedStatements} 个` : ''}`
                                : '暂无待检查 SQL'}
                        </div>
                        {(metrics.skippedStatements > 0 || metrics.failedStatementAudits > 0) && (
                            <div className="text-xs text-amber-600">
                                {metrics.skippedStatements > 0 && `跳过 ${metrics.skippedStatements} 个`}
                                {metrics.skippedStatements > 0 && metrics.failedStatementAudits > 0 && ' · '}
                                {metrics.failedStatementAudits > 0 && `失败 ${metrics.failedStatementAudits} 个`}
                            </div>
                        )}
                    </div>
                    <ScanSearch className="mt-1 text-violet-500" size={22} />
                </div>
            </Card>
            <Card bordered={false} className="shadow-sm">
                <div className="flex items-start justify-between">
                    <div>
                        <Text type="secondary">分片任务</Text>
                        <Title level={3} className="!mb-0 !mt-2">{metrics.totalTasks}</Title>
                        <div className="text-xs text-slate-400">
                            已完成 {metrics.completedTasks} 个
                            {metrics.degradedTasks > 0 && ` · 降级 ${metrics.degradedTasks} 个`}
                        </div>
                    </div>
                    <FolderTree className="text-indigo-500" size={22} />
                </div>
            </Card>
            <Card
                bordered={false}
                hoverable={canOpenPendingIssues}
                className={`shadow-sm ${canOpenPendingIssues ? 'cursor-pointer' : ''}`}
                role={canOpenPendingIssues ? 'button' : undefined}
                tabIndex={canOpenPendingIssues ? 0 : undefined}
                aria-label={canOpenPendingIssues ? `查看 ${metrics.pendingIssues} 条待处理疑点` : undefined}
                onClick={canOpenPendingIssues ? onPendingIssuesClick : undefined}
                onKeyDown={canOpenPendingIssues ? event => {
                    if (event.key === 'Enter' || event.key === ' ') {
                        event.preventDefault();
                        onPendingIssuesClick?.();
                    }
                } : undefined}
            >
                <div className="flex items-start justify-between gap-4">
                    <div className="min-w-0 flex-1">
                        <Text type="secondary">疑点处理</Text>
                        <Title level={3} className="!mb-0 !mt-2">
                            {metrics.totalIssues > 0 ? `${metrics.pendingIssues} 条待处理` : '未发现疑点'}
                        </Title>
                        {metrics.totalIssues > 0 && (
                            <Progress percent={metrics.reviewRate} size="small" showInfo={false} />
                        )}
                        <div className="text-xs text-slate-400">
                            {metrics.totalIssues > 0
                                ? `已处理 ${metrics.reviewedIssues} 条 · 共 ${metrics.totalIssues} 条`
                                : '当前 AI 检查结果正常'}
                        </div>
                        {canOpenPendingIssues && (
                            <div className="mt-2 text-xs font-medium text-amber-600">点击查看待处理内容</div>
                        )}
                    </div>
                    <AlertTriangle className="mt-1 text-amber-500" size={22} />
                </div>
            </Card>
            <Card bordered={false} className="shadow-sm">
                <div className="flex items-start justify-between">
                    <div>
                        <Text type="secondary">当前任务</Text>
                        <Title level={5} className="!mb-0 !mt-2">
                            {selectedTask ? buildShardLabel(selectedTask) : '未选择'}
                        </Title>
                        <div className="text-xs text-slate-400">
                            {selectedTask ? selectedTaskSourceMeta?.text : '请选择任务查看明细'}
                        </div>
                    </div>
                    <Bot className="text-emerald-500" size={22} />
                </div>
            </Card>
        </div>
    );
};

export default ReviewMetricCards;
