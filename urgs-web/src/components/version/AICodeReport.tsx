import React, { useEffect, useMemo, useState } from 'react';
import {
    Alert,
    Button,
    Card,
    Descriptions,
    Drawer,
    Empty,
    Input,
    message,
    Pagination,
    Select,
    Space,
    Spin,
    Table,
    Tag,
    Tooltip,
    Typography
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
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
import { Activity, AlertTriangle, Bot, Database, Download, FolderTree, ShieldCheck } from 'lucide-react';

const { Paragraph, Text, Title } = Typography;

const statusColorMap: Record<string, string> = {
    PENDING: 'default',
    RUNNING: 'processing',
    COMPLETED: 'success',
    DEGRADED: 'warning',
    FAILED: 'error'
};

const severityColorMap: Record<string, string> = {
    HIGH: 'red',
    MEDIUM: 'orange',
    LOW: 'blue'
};

const reviewStatusColorMap: Record<string, string> = {
    PENDING: 'default',
    CONFIRMED: 'success',
    FALSE_POSITIVE: 'error',
    IGNORED: 'default',
    RESOLVED: 'processing'
};

const formatDateTime = (value?: string) => {
    if (!value) {
        return '-';
    }
    return new Date(value).toLocaleString('zh-CN', { hour12: false });
};

const buildRecordSummary = (record: LineageAnalysisRecordItem) => {
    const pathCount = record.paths?.length || 0;
    const pathPreview = pathCount === 0
        ? '未记录路径'
        : pathCount <= 2
            ? (record.paths || []).join('、')
            : `${record.paths?.slice(0, 2).join('、')} 等 ${pathCount} 个路径`;
    const sourceType = record.repoId ? 'Git 分析' : '上传导入';
    return {
        title: `${sourceType} · ${record.language || '未指定方言'}`,
        description: `版本 ${record.versionId || '-'} · ${pathPreview}`,
        meta: `创建于 ${formatDateTime(record.createTime)}`
    };
};

const buildTaskSourceSummary = (task: LineageReviewTask) => {
    if (task.pathPrefix) {
        return task.pathPrefix;
    }
    if (task.systemKey && task.systemKey !== 'GLOBAL') {
        return `${task.systemKey} 系统相关 SQL`;
    }
    return '当前批次全部解析 SQL';
};

const buildShardLabel = (task: LineageReviewTask) => {
    const raw = task.pathPrefix || '';
    if (!raw) {
        return task.systemKey && task.systemKey !== 'GLOBAL' ? task.systemKey : '全量分片';
    }

    if (!raw.includes('/')) {
        return task.systemKey && task.systemKey !== 'GLOBAL' ? task.systemKey : '根目录文件组';
    }

    return raw.split('/')[0] || raw;
};

const isFileLikePath = (value?: string) => {
    if (!value) {
        return false;
    }
    return /\.[a-z0-9]+$/i.test(value);
};

const resolveReviewStatus = (record: LineageAnalysisRecordItem, relatedTasks: LineageReviewTask[]) => {
    if (!relatedTasks.length) {
        return {
            text: record.status === 'SUCCESS' ? '未走查' : '待分析完成',
            color: record.status === 'SUCCESS' ? 'default' : 'warning'
        };
    }

    const statuses = relatedTasks.map(task => task.status || 'PENDING');
    if (statuses.some(status => status === 'RUNNING')) {
        return { text: '走查中', color: 'processing' };
    }
    if (statuses.every(status => status === 'COMPLETED')) {
        return { text: '已完成', color: 'success' };
    }
    if (statuses.some(status => status === 'DEGRADED')) {
        return { text: '部分失败', color: 'warning' };
    }
    if (statuses.some(status => status === 'FAILED')) {
        return { text: '走查失败', color: 'error' };
    }
    return { text: '待执行', color: 'default' };
};

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

    const selectedRecord = useMemo(
        () => records.find(item => item.id === selectedRecordId),
        [records, selectedRecordId]
    );

    const selectedTask = useMemo(
        () => tasks.find(item => item.id === selectedTaskId),
        [tasks, selectedTaskId]
    );

    const buildTaskSourceMeta = (task: LineageReviewTask) => {
        const currentRecord = records.find(item => item.id === task.analysisRecordId);
        const paths = currentRecord?.paths || [];

        let matchedPaths = paths;
        if (task.pathPrefix) {
            matchedPaths = paths.filter(path => {
                if (task.pathPrefix && path.startsWith(task.pathPrefix)) {
                    return true;
                }
                if (!task.pathPrefix.includes('/') && isFileLikePath(task.pathPrefix)) {
                    return path === task.pathPrefix;
                }
                return false;
            });
        }

        if (!matchedPaths.length && task.pathPrefix) {
            matchedPaths = [task.pathPrefix];
        }

        const uniquePaths = Array.from(new Set(matchedPaths));
        if (!uniquePaths.length) {
            return {
                text: '未记录源码',
                tooltip: '当前任务没有关联到可展示的源码路径'
            };
        }

        if (uniquePaths.length === 1) {
            return {
                text: '1 个源码文件',
                tooltip: uniquePaths[0]
            };
        }

        return {
            text: `${uniquePaths.length} 个源码文件`,
            tooltip: uniquePaths.slice(0, 20).join('\n')
        };
    };

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

    const pagedRecords = useMemo(() => {
        const start = (recordPage - 1) * recordPageSize;
        return records.slice(start, start + recordPageSize);
    }, [records, recordPage, recordPageSize]);

    const pagedTasks = useMemo(() => {
        const start = (taskPage - 1) * taskPageSize;
        return tasks.slice(start, start + taskPageSize);
    }, [tasks, taskPage, taskPageSize]);

    const metrics = useMemo(() => {
        const totalTasks = tasks.length;
        const completedTasks = tasks.filter(item => item.status === 'COMPLETED').length;
        const degradedTasks = tasks.filter(item => item.status === 'DEGRADED').length;
        const totalIssues = tasks.reduce((sum, item) => sum + (item.issueCount || 0), 0);
        return { totalTasks, completedTasks, degradedTasks, totalIssues };
    }, [tasks]);

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
                const sourceMeta = buildTaskSourceMeta(record);
                return (
                    <div className="space-y-1">
                        <Button type="link" className="!h-auto !p-0" onClick={() => handleOpenSqlPreview(record)}>
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
            render: (value?: string) => <Tag color={statusColorMap[value || ''] || 'default'}>{value || '-'}</Tag>
        },
        {
            title: '进度',
            key: 'progress',
            width: 180,
            render: (_, record) => {
                const total = record.objectCount || 0;
                const processed = record.processedCount || 0;
                return (
                    <div>
                        <div className="text-sm font-medium text-slate-700">{processed}/{total || '-'}</div>
                        <div className="text-xs text-slate-400">
                            疑点 {record.issueCount || 0} · AI {record.aiCallCount || 0} · 缓存 {record.cacheHitCount || 0}
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
            render: (value?: string) => <Tag>{value || '-'}</Tag>
        },
        {
            title: '严重级别',
            dataIndex: 'severity',
            width: 110,
            render: (value?: string) => <Tag color={severityColorMap[value || ''] || 'default'}>{value || '-'}</Tag>
        },
        {
            title: 'AI 判定',
            key: 'verdict',
            width: 150,
            render: (_, record) => (
                <div>
                    <div className="text-sm font-medium text-slate-700">{record.verdict || '-'}</div>
                    <div className="text-xs text-slate-400">置信度 {Number(record.confidence || 0).toFixed(2)}</div>
                </div>
            )
        },
        {
            title: '人工状态',
            dataIndex: 'reviewStatus',
            width: 130,
            render: (value?: string) => <Tag color={reviewStatusColorMap[value || ''] || 'default'}>{value || '-'}</Tag>
        },
        {
            title: '原因摘要',
            dataIndex: 'reason',
            render: (value?: string) => (
                <Paragraph className="!mb-0 !text-slate-500" ellipsis={{ rows: 2 }}>
                    {value || '-'}
                </Paragraph>
            )
        }
    ];

    return (
        <div className="space-y-6">
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
                            <div className="text-xs text-slate-400">完成 {metrics.completedTasks} · 降级 {metrics.degradedTasks}</div>
                        </div>
                        <FolderTree className="text-indigo-500" size={22} />
                    </div>
                </Card>
                <Card bordered={false} className="shadow-sm">
                    <div className="flex items-start justify-between">
                        <div>
                            <Text type="secondary">疑点总数</Text>
                            <Title level={3} className="!mb-0 !mt-2">{metrics.totalIssues}</Title>
                        </div>
                        <AlertTriangle className="text-amber-500" size={22} />
                    </div>
                </Card>
                <Card bordered={false} className="shadow-sm">
                    <div className="flex items-start justify-between">
                        <div>
                            <Text type="secondary">当前任务</Text>
                            <Title level={5} className="!mb-0 !mt-2">{selectedTask ? buildShardLabel(selectedTask) : '未选择'}</Title>
                            <div className="text-xs text-slate-400">{selectedTask ? buildTaskSourceMeta(selectedTask).text : '请选择任务查看明细'}</div>
                        </div>
                        <Bot className="text-emerald-500" size={22} />
                    </div>
                </Card>
            </div>

            <div className="grid grid-cols-1 gap-6 xl:grid-cols-[360px_minmax(0,1fr)]">
                <Card
                    title={
                        <div className="flex items-center gap-2">
                            <ShieldCheck size={16} className="text-indigo-500" />
                            <span>校验批次</span>
                        </div>
                    }
                    extra={
                        <Space>
                            <Button size="small" onClick={loadRecords} loading={recordLoading}>刷新</Button>
                            <Button
                                type="primary"
                                size="small"
                                loading={triggerLoading}
                                disabled={!canTrigger}
                                title={canTrigger ? '' : '缺少 version:ai:trigger 权限'}
                                onClick={() => handleTrigger(false)}
                            >
                                触发走查
                            </Button>
                        </Space>
                    }
                    bordered={false}
                    className="shadow-sm"
                >
                    {recordLoading ? (
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
                                return (
                                    <button
                                        key={record.id}
                                        onClick={() => setSelectedRecordId(record.id)}
                                        className={`w-full rounded-xl border p-4 text-left transition ${isActive ? 'border-indigo-300 bg-indigo-50' : 'border-slate-200 bg-white hover:border-slate-300'}`}
                                    >
                                        <div className="flex items-center justify-between">
                                            <div className="font-semibold text-slate-700">{summary.title}</div>
                                            <Space size={6}>
                                                <Tag color={reviewStatus.color}>{reviewStatus.text}</Tag>
                                                <Tag color={statusColorMap[record.status || ''] || 'default'}>{record.status}</Tag>
                                            </Space>
                                        </div>
                                        <div className="mt-2 text-sm text-slate-600">
                                            {summary.description}
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
                                        onChange={(page, size) => {
                                            setRecordPage(page);
                                            if (size && size !== recordPageSize) {
                                                setRecordPageSize(size);
                                            }
                                        }}
                                    />
                                </div>
                            )}
                        </div>
                    )}
                </Card>

                <div className="space-y-6">
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
                                    loading={triggerLoading}
                                    disabled={!selectedRecord || !canTrigger}
                                    title={canTrigger ? '' : '缺少 version:ai:trigger 权限'}
                                    onClick={() => handleTrigger(true)}
                                >
                                    强制重跑
                                </Button>
                                <Button
                                    size="small"
                                    icon={<Download size={14} />}
                                    loading={reportDownloading}
                                    disabled={!selectedTask || !canExport}
                                    title={canExport ? '' : '缺少 version:ai:export 权限'}
                                    onClick={handleDownloadMarkdownReport}
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
                            dataSource={pagedTasks}
                            columns={taskColumns}
                            loading={taskLoading}
                            pagination={{
                                current: taskPage,
                                pageSize: taskPageSize,
                                total: tasks.length,
                                size: 'small',
                                showSizeChanger: true,
                                pageSizeOptions: ['10', '20', '50'],
                                onChange: (page, size) => {
                                    setTaskPage(page);
                                    if (size && size !== taskPageSize) {
                                        setTaskPageSize(size);
                                    }
                                }
                            }}
                            locale={{ emptyText: '当前批次暂无校验任务' }}
                            rowSelection={{
                                type: 'radio',
                                selectedRowKeys: selectedTaskId ? [selectedTaskId] : [],
                                onChange: keys => setSelectedTaskId(Number(keys[0]))
                            }}
                        />
                    </Card>

                    <Card
                        title="疑点清单"
                        bordered={false}
                        className="shadow-sm"
                        extra={
                            <Space wrap>
                                <Input.Search
                                    allowClear
                                    placeholder="搜索表名、字段或原因"
                                    style={{ width: 220 }}
                                    value={searchTerm}
                                    onChange={e => setSearchTerm(e.target.value)}
                                />
                                <Select
                                    allowClear
                                    placeholder="严重级别"
                                    style={{ width: 120 }}
                                    value={severityFilter}
                                    onChange={setSeverityFilter}
                                    options={[
                                        { label: 'HIGH', value: 'HIGH' },
                                        { label: 'MEDIUM', value: 'MEDIUM' },
                                        { label: 'LOW', value: 'LOW' }
                                    ]}
                                />
                                <Select
                                    allowClear
                                    placeholder="人工状态"
                                    style={{ width: 140 }}
                                    value={reviewStatusFilter}
                                    onChange={setReviewStatusFilter}
                                    options={[
                                        { label: 'PENDING', value: 'PENDING' },
                                        { label: 'CONFIRMED', value: 'CONFIRMED' },
                                        { label: 'FALSE_POSITIVE', value: 'FALSE_POSITIVE' },
                                        { label: 'IGNORED', value: 'IGNORED' },
                                        { label: 'RESOLVED', value: 'RESOLVED' }
                                    ]}
                                />
                            </Space>
                        }
                    >
                        <Table
                            rowKey="id"
                            dataSource={filteredIssues}
                            columns={issueColumns}
                            loading={issueLoading}
                            pagination={{ pageSize: 8 }}
                            locale={{ emptyText: selectedTaskId ? '当前任务暂无疑点' : '请先选择一个分片任务' }}
                            onRow={record => ({
                                onClick: () => setSelectedIssue(record)
                            })}
                        />
                    </Card>
                </div>
            </div>

            <Drawer
                open={!!selectedIssue}
                onClose={() => setSelectedIssue(null)}
                width={620}
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
                width={860}
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
