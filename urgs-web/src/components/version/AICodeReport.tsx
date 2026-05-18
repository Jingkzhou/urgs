import React, { useEffect, useMemo, useState } from 'react';
import { Button, Card, Descriptions, Drawer, Empty, message, Space, Spin, Tag } from 'antd';
import {
    decideLineageReviewIssue,
    downloadLineageReviewReportMarkdown,
    getLineageReviewIssues,
    getLineageReviewRecords,
    getLineageReviewTaskSqlPreview,
    getLineageReviewTasks,
    triggerLineageReview,
    LineageAnalysisRecordItem,
    LineageReviewIssue,
    LineageReviewTask
} from '@/api/lineage';
import { hasPermission } from '@/utils/permission';
import ReviewIssueTable from './lineage-review/ReviewIssueTable';
import ReviewMetricCards from './lineage-review/ReviewMetricCards';
import ReviewRecordList from './lineage-review/ReviewRecordList';
import ReviewTaskTable from './lineage-review/ReviewTaskTable';
import { reviewStatusColorMap, severityColorMap } from './lineage-review/reviewConstants';
import { buildShardLabel, buildTaskSourceMeta } from './lineage-review/reviewUtils';

const AICodeReport: React.FC = () => {
    const [records, setRecords] = useState<LineageAnalysisRecordItem[]>([]);
    const [tasks, setTasks] = useState<LineageReviewTask[]>([]);
    const [taskSummaryMap, setTaskSummaryMap] = useState<Record<string, LineageReviewTask[]>>({});
    const [issues, setIssues] = useState<LineageReviewIssue[]>([]);
    const [recordLoading, setRecordLoading] = useState(false);
    const [taskLoading, setTaskLoading] = useState(false);
    const [issueLoading, setIssueLoading] = useState(false);
    const [triggerLoading, setTriggerLoading] = useState(false);
    const [selectedRecordId, setSelectedRecordId] = useState<string>();
    const [selectedTaskId, setSelectedTaskId] = useState<number>();
    const [severityFilter, setSeverityFilter] = useState<string>();
    const [reviewStatusFilter, setReviewStatusFilter] = useState<string>();
    const [searchTerm, setSearchTerm] = useState('');
    const [recordPage, setRecordPage] = useState(1);
    const [recordPageSize, setRecordPageSize] = useState(6);
    const [taskPage, setTaskPage] = useState(1);
    const [taskPageSize, setTaskPageSize] = useState(10);
    const [selectedIssue, setSelectedIssue] = useState<LineageReviewIssue | null>(null);
    const [decisionLoading, setDecisionLoading] = useState<string>('');
    const [sqlPreviewOpen, setSqlPreviewOpen] = useState(false);
    const [sqlPreviewLoading, setSqlPreviewLoading] = useState(false);
    const [sqlPreviewTask, setSqlPreviewTask] = useState<LineageReviewTask | null>(null);
    const [reportDownloading, setReportDownloading] = useState(false);
    const [sqlPreviews, setSqlPreviews] = useState<Array<{
        snippet: string;
        sourceFiles: string[];
        relationCount: number;
    }>>([]);

    const canTrigger = hasPermission('version:ai:trigger');
    const canExport = hasPermission('version:ai:export');

    const selectedRecord = useMemo(
        () => records.find(item => item.id === selectedRecordId),
        [records, selectedRecordId]
    );

    const selectedTask = useMemo(
        () => tasks.find(item => item.id === selectedTaskId),
        [tasks, selectedTaskId]
    );

    const selectedTaskSourceMeta = useMemo(
        () => selectedTask ? buildTaskSourceMeta(selectedTask, records) : undefined,
        [records, selectedTask]
    );

    const pagedRecords = useMemo(() => {
        const start = (recordPage - 1) * recordPageSize;
        return records.slice(start, start + recordPageSize);
    }, [records, recordPage, recordPageSize]);

    const filteredIssues = useMemo(() => {
        const keyword = searchTerm.trim().toLowerCase();
        if (!keyword) {
            return issues;
        }
        return issues.filter(issue => {
            const target = [issue.tableName, issue.columnName, issue.issueType, issue.reason]
                .filter(Boolean)
                .join(' ')
                .toLowerCase();
            return target.includes(keyword);
        });
    }, [issues, searchTerm]);

    const downloadBlob = (blob: Blob, fileName: string) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
    };

    const loadTaskSummaries = async () => {
        try {
            const data = await getLineageReviewTasks();
            const grouped = (data || []).reduce<Record<string, LineageReviewTask[]>>((acc, item) => {
                const key = item.analysisRecordId || 'UNKNOWN';
                if (!acc[key]) {
                    acc[key] = [];
                }
                acc[key].push(item);
                return acc;
            }, {});
            setTaskSummaryMap(grouped);
        } catch (error: any) {
            message.error(error?.message || '加载走查状态失败');
        }
    };

    const loadRecords = async () => {
        setRecordLoading(true);
        try {
            const data = await getLineageReviewRecords();
            setRecords(data || []);
            await loadTaskSummaries();
            setRecordPage(1);
            if (!selectedRecordId && data?.length) {
                setSelectedRecordId(data[0].id);
            }
        } catch (error: any) {
            message.error(error?.message || '加载分析记录失败');
        } finally {
            setRecordLoading(false);
        }
    };

    const loadTasks = async (analysisRecordId?: string) => {
        setTaskLoading(true);
        try {
            const data = await getLineageReviewTasks({ analysisRecordId });
            setTasks(data || []);
            setTaskPage(1);
            if (!selectedTaskId || !(data || []).some(item => item.id === selectedTaskId)) {
                setSelectedTaskId(data?.[0]?.id);
            }
        } catch (error: any) {
            message.error(error?.message || '加载校验任务失败');
        } finally {
            setTaskLoading(false);
        }
    };

    const loadIssues = async (taskId?: number) => {
        if (!taskId) {
            setIssues([]);
            return;
        }
        setIssueLoading(true);
        try {
            const data = await getLineageReviewIssues({
                taskId,
                severity: severityFilter,
                reviewStatus: reviewStatusFilter
            });
            setIssues(data || []);
        } catch (error: any) {
            message.error(error?.message || '加载疑点失败');
        } finally {
            setIssueLoading(false);
        }
    };

    useEffect(() => {
        loadRecords();
    }, []);

    useEffect(() => {
        if (selectedRecordId) {
            loadTasks(selectedRecordId);
        }
    }, [selectedRecordId]);

    useEffect(() => {
        loadIssues(selectedTaskId);
    }, [selectedTaskId, severityFilter, reviewStatusFilter]);

    const handleTrigger = async (forceRerun: boolean) => {
        if (!selectedRecordId) {
            message.warning('请先选择一个血缘分析记录');
            return;
        }
        setTriggerLoading(true);
        try {
            const result = await triggerLineageReview({ analysisRecordId: selectedRecordId, forceRerun });
            message.success(result.message || '校验任务已提交');
            await loadTaskSummaries();
            await loadTasks(selectedRecordId);
        } catch (error: any) {
            message.error(error?.message || '触发校验失败');
        } finally {
            setTriggerLoading(false);
        }
    };

    const handleDecision = async (reviewStatus: string) => {
        if (!selectedIssue) {
            return;
        }
        setDecisionLoading(reviewStatus);
        try {
            const updated = await decideLineageReviewIssue(selectedIssue.id, {
                reviewStatus,
                reviewerNote: ''
            });
            setSelectedIssue(updated);
            await loadIssues(selectedTaskId);
            await loadTaskSummaries();
            if (selectedRecordId) {
                await loadTasks(selectedRecordId);
            }
            message.success('人工判定已保存');
        } catch (error: any) {
            message.error(error?.message || '保存判定失败');
        } finally {
            setDecisionLoading('');
        }
    };

    const handleOpenSqlPreview = async (task: LineageReviewTask) => {
        setSqlPreviewTask(task);
        setSqlPreviewOpen(true);
        setSqlPreviewLoading(true);
        try {
            const data = await getLineageReviewTaskSqlPreview(task.id);
            const normalized = (data || [])
                .map(item => ({
                    snippet: String(item.snippet || '').trim(),
                    sourceFiles: Array.from(new Set((item.sourceFiles || []).filter(Boolean))),
                    relationCount: item.relationCount || 0
                }))
                .filter(item => item.snippet.length > 0);
            setSqlPreviews(normalized);
        } catch (error: any) {
            message.error(error?.message || '加载 SQL 片段失败');
            setSqlPreviews([]);
        } finally {
            setSqlPreviewLoading(false);
        }
    };

    const handleDownloadMarkdownReport = async () => {
        if (!selectedTask) {
            return;
        }
        setReportDownloading(true);
        try {
            const blob = await downloadLineageReviewReportMarkdown(selectedTask.id);
            downloadBlob(blob, `lineage-review-${selectedTask.id}.md`);
            message.success('Markdown 报告下载开始');
        } catch (error: any) {
            message.error(error?.message || '下载 Markdown 报告失败');
        } finally {
            setReportDownloading(false);
        }
    };

    return (
        <div className="space-y-6">
            <ReviewMetricCards
                records={records}
                tasks={tasks}
                selectedTask={selectedTask}
                selectedTaskSourceMeta={selectedTaskSourceMeta}
            />

            <div className="grid grid-cols-1 gap-6 xl:grid-cols-[360px_minmax(0,1fr)]">
                <ReviewRecordList
                    records={records}
                    pagedRecords={pagedRecords}
                    taskSummaryMap={taskSummaryMap}
                    selectedRecordId={selectedRecordId}
                    loading={recordLoading}
                    triggerLoading={triggerLoading}
                    canTrigger={canTrigger}
                    recordPage={recordPage}
                    recordPageSize={recordPageSize}
                    onRefresh={loadRecords}
                    onTrigger={() => handleTrigger(false)}
                    onSelectRecord={setSelectedRecordId}
                    onPageChange={(page, size) => {
                        setRecordPage(page);
                        if (size && size !== recordPageSize) {
                            setRecordPageSize(size);
                        }
                    }}
                />

                <div className="space-y-6">
                    <ReviewTaskTable
                        selectedRecord={selectedRecord}
                        selectedTask={selectedTask}
                        selectedTaskId={selectedTaskId}
                        tasks={tasks}
                        loading={taskLoading}
                        triggerLoading={triggerLoading}
                        reportDownloading={reportDownloading}
                        canTrigger={canTrigger}
                        canExport={canExport}
                        taskPage={taskPage}
                        taskPageSize={taskPageSize}
                        getTaskSourceMeta={task => buildTaskSourceMeta(task, records)}
                        onForceRerun={() => handleTrigger(true)}
                        onDownloadMarkdown={handleDownloadMarkdownReport}
                        onOpenSqlPreview={handleOpenSqlPreview}
                        onTaskSelect={setSelectedTaskId}
                        onPageChange={(page, size) => {
                            setTaskPage(page);
                            if (size && size !== taskPageSize) {
                                setTaskPageSize(size);
                            }
                        }}
                    />

                    <ReviewIssueTable
                        issues={filteredIssues}
                        loading={issueLoading}
                        selectedTaskId={selectedTaskId}
                        searchTerm={searchTerm}
                        severityFilter={severityFilter}
                        reviewStatusFilter={reviewStatusFilter}
                        onSearchChange={setSearchTerm}
                        onSeverityChange={setSeverityFilter}
                        onReviewStatusChange={setReviewStatusFilter}
                        onSelectIssue={setSelectedIssue}
                    />
                </div>
            </div>

            <Drawer
                open={!!selectedIssue}
                onClose={() => setSelectedIssue(null)}
                size="large"
                title="疑点详情"
                extra={
                    selectedIssue && (
                        <Space>
                            <Button
                                size="small"
                                loading={decisionLoading === 'CONFIRMED'}
                                onClick={() => handleDecision('CONFIRMED')}
                            >
                                确认问题
                            </Button>
                            <Button
                                size="small"
                                loading={decisionLoading === 'FALSE_POSITIVE'}
                                onClick={() => handleDecision('FALSE_POSITIVE')}
                            >
                                标记误报
                            </Button>
                            <Button
                                size="small"
                                loading={decisionLoading === 'RESOLVED'}
                                onClick={() => handleDecision('RESOLVED')}
                            >
                                已处理
                            </Button>
                        </Space>
                    )
                }
            >
                {!selectedIssue ? null : (
                    <div className="space-y-6">
                        <Descriptions column={1} size="small" bordered>
                            <Descriptions.Item label="目标对象">
                                {selectedIssue.tableName}
                                {selectedIssue.columnName ? `.${selectedIssue.columnName}` : ''}
                            </Descriptions.Item>
                            <Descriptions.Item label="疑点类型">{selectedIssue.issueType}</Descriptions.Item>
                            <Descriptions.Item label="严重级别">
                                <Tag color={severityColorMap[selectedIssue.severity] || 'default'}>{selectedIssue.severity}</Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="AI 判定">
                                {selectedIssue.verdict} / {Number(selectedIssue.confidence || 0).toFixed(2)}
                            </Descriptions.Item>
                            <Descriptions.Item label="人工状态">
                                <Tag color={reviewStatusColorMap[selectedIssue.reviewStatus || ''] || 'default'}>
                                    {selectedIssue.reviewStatus || 'PENDING'}
                                </Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="原因说明">{selectedIssue.reason || '-'}</Descriptions.Item>
                        </Descriptions>

                        <Card size="small" title="规则命中">
                            {(selectedIssue.ruleHits || []).length > 0 ? (
                                <Space wrap>
                                    {selectedIssue.ruleHits?.map(item => <Tag key={item}>{item}</Tag>)}
                                </Space>
                            ) : (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="无规则命中" />
                            )}
                        </Card>

                        <Card size="small" title="建议来源">
                            {(selectedIssue.suggestedSources || []).length > 0 ? (
                                <div className="space-y-2">
                                    {selectedIssue.suggestedSources?.map(item => (
                                        <div key={item} className="rounded-lg bg-slate-50 px-3 py-2 text-sm text-slate-600">{item}</div>
                                    ))}
                                </div>
                            ) : (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="无建议来源" />
                            )}
                        </Card>

                        <Card size="small" title="证据引用">
                            {(selectedIssue.evidenceRefs || []).length > 0 ? (
                                <div className="space-y-2">
                                    {selectedIssue.evidenceRefs?.map(item => (
                                        <div key={item} className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600">
                                            {item}
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="无证据引用" />
                            )}
                        </Card>

                        <Card size="small" title="局部证据包">
                            <pre className="max-h-80 overflow-auto rounded-xl bg-slate-900 p-4 text-xs text-slate-100">
                                {JSON.stringify(selectedIssue.graphSnapshot || {}, null, 2)}
                            </pre>
                        </Card>
                    </div>
                )}
            </Drawer>

            <Drawer
                open={sqlPreviewOpen}
                onClose={() => setSqlPreviewOpen(false)}
                size="large"
                title={`源码 SQL 片段${sqlPreviewTask ? ` · ${buildShardLabel(sqlPreviewTask)}` : ''}`}
            >
                {sqlPreviewLoading ? (
                    <div className="flex items-center justify-center py-20">
                        <Spin />
                    </div>
                ) : sqlPreviews.length === 0 ? (
                    <Empty description="当前分片暂未记录可展示的 SQL 片段" />
                ) : (
                    <div className="space-y-4">
                        {sqlPreviews.map((item, index) => (
                            <Card
                                key={`${index}-${item.relationCount}`}
                                size="small"
                                title={`SQL 片段 ${index + 1}`}
                                extra={<span className="text-xs text-slate-400">关联关系 {item.relationCount}</span>}
                            >
                                <div className="mb-3 text-xs text-slate-500">
                                    来源文件：{item.sourceFiles?.length ? item.sourceFiles.join('、') : '未记录'}
                                </div>
                                <pre className="max-h-96 overflow-auto whitespace-pre-wrap rounded-xl bg-slate-900 p-4 text-xs text-slate-100">
                                    {item.snippet || '未返回 SQL 片段内容'}
                                </pre>
                            </Card>
                        ))}
                    </div>
                )}
            </Drawer>
        </div>
    );
};

export default AICodeReport;
