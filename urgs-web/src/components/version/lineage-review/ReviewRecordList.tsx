import React from 'react';
import { Button, Card, Empty, Pagination, Progress, Space, Spin, Tag } from 'antd';
import type { LineageAnalysisRecordItem, LineageReviewTask } from '@/api/lineage';
import { ShieldCheck } from 'lucide-react';
import { statusColorMap } from './reviewConstants';
import {
    buildRecordSummary,
    calculateReviewProgressSummary,
    resolveReviewStatus
} from './reviewUtils';

interface ReviewRecordListProps {
    records: LineageAnalysisRecordItem[];
    pagedRecords: LineageAnalysisRecordItem[];
    taskSummaryMap: Record<string, LineageReviewTask[]>;
    selectedRecordId?: string;
    loading: boolean;
    triggerLoading: boolean;
    canTrigger: boolean;
    recordPage: number;
    recordPageSize: number;
    onRefresh: () => void;
    onTrigger: () => void;
    onSelectRecord: (recordId: string) => void;
    onPageChange: (page: number, pageSize: number) => void;
}

const ReviewRecordList: React.FC<ReviewRecordListProps> = ({
    records,
    pagedRecords,
    taskSummaryMap,
    selectedRecordId,
    loading,
    triggerLoading,
    canTrigger,
    recordPage,
    recordPageSize,
    onRefresh,
    onTrigger,
    onSelectRecord,
    onPageChange
}) => (
    <Card
        title={
            <div className="flex items-center gap-2">
                <ShieldCheck size={16} className="text-indigo-500" />
                <span>校验批次</span>
            </div>
        }
        extra={
            <Space>
                <Button size="small" onClick={onRefresh} loading={loading}>刷新</Button>
                <Button
                    type="primary"
                    size="small"
                    loading={triggerLoading}
                    disabled={!canTrigger}
                    title={canTrigger ? '' : '缺少 version:ai:trigger 权限'}
                    onClick={onTrigger}
                >
                    触发走查
                </Button>
            </Space>
        }
        bordered={false}
        className="shadow-sm"
    >
        {loading ? (
            <div className="py-10 text-center"><Spin /></div>
        ) : records.length === 0 ? (
            <Empty description="暂无血缘分析记录" />
        ) : (
            <div className="space-y-3">
                {pagedRecords.map(record => {
                    const isActive = record.id === selectedRecordId;
                    const summary = buildRecordSummary(record);
                    const relatedTasks = taskSummaryMap[record.id] || [];
                    const reviewStatus = resolveReviewStatus(record, relatedTasks);
                    const progress = calculateReviewProgressSummary(relatedTasks);
                    return (
                        <button
                            key={record.id}
                            onClick={() => onSelectRecord(record.id)}
                            className={`w-full rounded-xl border p-4 text-left transition ${isActive ? 'border-indigo-300 bg-indigo-50' : 'border-slate-200 bg-white hover:border-slate-300'}`}
                        >
                            <div className="flex items-center justify-between gap-3">
                                <div className="min-w-0 font-semibold text-slate-700">{summary.title}</div>
                                <Space size={6}>
                                    <Tag color={reviewStatus.color}>{reviewStatus.text}</Tag>
                                    <Tag color={statusColorMap[record.status || ''] || 'default'}>{record.status}</Tag>
                                </Space>
                            </div>
                            <div className="mt-2 text-sm text-slate-600">
                                {summary.description}
                            </div>
                            <div className="mt-3">
                                <div className="mb-1 flex justify-between text-xs text-slate-400">
                                    <span>走查完成度</span>
                                    <span>{progress.reviewedIssues}/{progress.totalIssues || 0}</span>
                                </div>
                                <Progress percent={progress.reviewRate} size="small" showInfo={false} />
                            </div>
                            <div className="mt-2 flex items-center justify-between text-xs text-slate-400">
                                <span>{summary.meta}</span>
                                <span>分片 {relatedTasks.length} 个</span>
                            </div>
                            <div className="mt-2 text-xs text-slate-400">
                                批次号: {record.id}
                            </div>
                        </button>
                    );
                })}
                {records.length > recordPageSize && (
                    <div className="flex justify-center pt-2">
                        <Pagination
                            size="small"
                            current={recordPage}
                            pageSize={recordPageSize}
                            total={records.length}
                            showSizeChanger
                            pageSizeOptions={['6', '10', '20']}
                            onChange={onPageChange}
                        />
                    </div>
                )}
            </div>
        )}
    </Card>
);

export default ReviewRecordList;
