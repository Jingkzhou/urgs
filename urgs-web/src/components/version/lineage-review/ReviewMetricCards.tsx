import React from 'react';
import { Card, Progress, Typography } from 'antd';
import type { LineageAnalysisRecordItem, LineageReviewTask } from '@/api/lineage';
import { AlertTriangle, Bot, Database, FolderTree } from 'lucide-react';
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
}

const ReviewMetricCards: React.FC<ReviewMetricCardsProps> = ({
    records,
    tasks,
    selectedTask,
    selectedTaskSourceMeta
}) => {
    const metrics = calculateReviewProgressSummary(tasks);

    return (
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-4">
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
                <div className="flex items-start justify-between">
                    <div>
                        <Text type="secondary">分片任务</Text>
                        <Title level={3} className="!mb-0 !mt-2">{metrics.totalTasks}</Title>
                        <div className="text-xs text-slate-400">
                            终态 {metrics.terminalTasks} · 降级 {metrics.degradedTasks}
                        </div>
                    </div>
                    <FolderTree className="text-indigo-500" size={22} />
                </div>
            </Card>
            <Card bordered={false} className="shadow-sm">
                <div className="flex items-start justify-between gap-4">
                    <div className="min-w-0 flex-1">
                        <Text type="secondary">走查完成度</Text>
                        <Title level={3} className="!mb-0 !mt-2">{metrics.reviewRate}%</Title>
                        <Progress percent={metrics.reviewRate} size="small" showInfo={false} />
                        <div className="text-xs text-slate-400">
                            已走查 {metrics.reviewedIssues}/{metrics.totalIssues} · 待确认 {metrics.pendingIssues}
                        </div>
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
