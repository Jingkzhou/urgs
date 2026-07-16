import React, { useEffect, useRef, useState } from 'react';
import { AlertCircle, CheckCircle2, Clock3, Eye, Loader2, RotateCcw, XCircle } from 'lucide-react';
import {
    AssetMaintenanceRecord,
    getPendingReviewTasks,
    getReviewHistoryTasks,
    getTaskDetail,
    reviewTask,
    TaskMarketDTO,
    TaskReviewDTO,
    TaskReviewHistoryDTO,
} from '../../api/marketplace';
import TaskDetailDrawer from './TaskDetailDrawer';
import { getTaskStageLabel, getTaskStatusLabel } from './marketplaceLabels';
import { MarketplaceTodoFocus } from './marketplaceTodoFocus';
import AssetObjectDetailLink from './AssetObjectDetailLink';
import TaskVersionMergeRequests from './TaskVersionMergeRequests';

interface ReviewCenterProps {
    todoFocus?: MarketplaceTodoFocus | null;
}

type ReviewExecutionStatus = 'idle' | 'running' | 'success' | 'error';

const getRequestErrorMessage = (error: unknown, fallback: string) => {
    const rawMessage = error instanceof Error ? error.message : '';
    if (!rawMessage) return fallback;
    try {
        const response = JSON.parse(rawMessage);
        return response?.message || fallback;
    } catch {
        return rawMessage;
    }
};

const ReviewCenter: React.FC<ReviewCenterProps> = ({ todoFocus }) => {
    const [tasks, setTasks] = useState<TaskMarketDTO[]>([]);
    const [historyTasks, setHistoryTasks] = useState<TaskReviewHistoryDTO[]>([]);
    const [historyPage, setHistoryPage] = useState(1);
    const [historyTotal, setHistoryTotal] = useState(0);
    const [loading, setLoading] = useState(false);
    const [activeTask, setActiveTask] = useState<TaskMarketDTO | null>(null);
    const [detailTaskId, setDetailTaskId] = useState<string | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);
    const [activeTab, setActiveTab] = useState<'pending' | 'history'>('pending');
    const [form, setForm] = useState<TaskReviewDTO>({ decision: 'APPROVE', qualityScore: 4, bonusPoints: 0, penaltyPoints: 0 });
    const [assetReviewRecords, setAssetReviewRecords] = useState<AssetMaintenanceRecord[]>([]);
    const [assetReviewLoading, setAssetReviewLoading] = useState(false);
    const [assetReviewError, setAssetReviewError] = useState('');
    const [reviewExecutionStatus, setReviewExecutionStatus] = useState<ReviewExecutionStatus>('idle');
    const [reviewExecutionLogs, setReviewExecutionLogs] = useState<string[]>([]);
    const [reviewExecutionError, setReviewExecutionError] = useState('');
    const [reviewElapsedSeconds, setReviewElapsedSeconds] = useState(0);
    const reviewSubmittingRef = useRef(false);

    const reviewSubmitting = reviewExecutionStatus === 'running';

    useEffect(() => {
        if (!reviewSubmitting) return;
        const timer = window.setInterval(() => setReviewElapsedSeconds(value => value + 1), 1000);
        return () => window.clearInterval(timer);
    }, [reviewSubmitting]);

    const appendExecutionLog = (message: string) => {
        const time = new Date().toLocaleTimeString([], { hour12: false });
        setReviewExecutionLogs(logs => [...logs, `${time}  ${message}`]);
    };

    const fetchTasks = async () => {
        setLoading(true);
        try {
            const [pendingRes, historyRes] = await Promise.all([
                getPendingReviewTasks({ current: 1, size: 50 }),
                getReviewHistoryTasks({ current: historyPage, size: 20 }),
            ]);
            setTasks(pendingRes?.records || []);
            setHistoryTasks(historyRes?.records || []);
            setHistoryTotal(historyRes?.total || 0);
        } catch (error) {
            console.error('Failed to fetch review tasks', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTasks();
    }, [historyPage]);

    useEffect(() => {
        if (!todoFocus || todoFocus.targetTab !== 'review') return;

        setActiveTab('pending');
    }, [todoFocus?.sequence]);

    const isAssetReviewTask = (task?: TaskMarketDTO | null) =>
        task?.status === 'WAITING_REVIEW' && task.currentStage === 'ASSET_REVIEW';

    const getReviewDecisionLabel = (decision: TaskReviewHistoryDTO['decision']) => {
        if (decision === 'APPROVE') return '通过';
        if (decision === 'REJECT') return '退回';
        if (decision === 'CANCEL') return '取消';
        if (decision === 'TRANSFER') return '转派';
        return decision;
    };

    const getReviewDecisionStyle = (decision: TaskReviewHistoryDTO['decision']) => {
        if (decision === 'APPROVE') return 'bg-green-50 text-green-700';
        if (decision === 'REJECT') return 'bg-orange-50 text-orange-700';
        if (decision === 'CANCEL') return 'bg-slate-100 text-slate-600';
        if (decision === 'TRANSFER') return 'bg-blue-50 text-blue-700';
        return 'bg-slate-100 text-slate-600';
    };

    const formatRecordTime = (value?: string) => {
        if (!value) return '-';
        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
    };

    const getModTypeLabel = (modType?: string) => {
        if (!modType) return '-';
        if (modType === 'CREATE') return '新增资产';
        if (modType === 'UPDATE') return '修改调整';
        if (modType === 'DELETE') return '删除资产';
        return modType;
    };

    const loadAssetReviewRecords = async (task: TaskMarketDTO) => {
        setAssetReviewRecords([]);
        setAssetReviewError('');
        setAssetReviewLoading(false);
        if (!isAssetReviewTask(task)) return;

        const reqId = (task.requirementNumber || '').trim();
        if (!reqId) {
            setAssetReviewError('当前任务缺少需求编号，无法匹配资产管理维护记录');
            return;
        }

        setAssetReviewLoading(true);
        try {
            const taskDetail = await getTaskDetail(task.id);
            const records = taskDetail?.assetMaintenanceRecords || [];
            setAssetReviewRecords(records);
            if (records.length === 0) {
                setAssetReviewError(`未找到需求编号 ${reqId} 下由当前任务承接人操作的资产维护记录`);
            }
        } catch (error) {
            console.error('Failed to load asset maintenance records', error);
            setAssetReviewError('资产管理维护记录加载失败');
        } finally {
            setAssetReviewLoading(false);
        }
    };

    const openReview = (task: TaskMarketDTO, decision: TaskReviewDTO['decision']) => {
        setActiveTask(task);
        setReviewExecutionStatus('idle');
        setReviewExecutionLogs([]);
        setReviewExecutionError('');
        setReviewElapsedSeconds(0);
        reviewSubmittingRef.current = false;
        setForm({
            decision,
            qualityScore: decision === 'APPROVE' && !isAssetReviewTask(task) ? 4 : undefined,
            bonusPoints: 0,
            penaltyPoints: 0,
        });
        loadAssetReviewRecords(task);
    };

    const openDetail = (taskId: string) => {
        setDetailTaskId(taskId);
        setIsDetailOpen(true);
    };

    const closeReview = () => {
        if (reviewSubmittingRef.current) return;
        setActiveTask(null);
        setAssetReviewRecords([]);
        setAssetReviewLoading(false);
        setAssetReviewError('');
        setReviewExecutionStatus('idle');
        setReviewExecutionLogs([]);
        setReviewExecutionError('');
        setReviewElapsedSeconds(0);
        reviewSubmittingRef.current = false;
    };

    const submitReview = async () => {
        if (!activeTask || reviewSubmittingRef.current) return;
        if (form.decision === 'APPROVE' && !isAssetReviewTask(activeTask) && !form.qualityScore) {
            alert('通过验收必须填写质量评分');
            return;
        }
        reviewSubmittingRef.current = true;
        const assetApprove = form.decision === 'APPROVE' && isAssetReviewTask(activeTask);
        setReviewExecutionStatus('running');
        setReviewExecutionLogs([]);
        setReviewExecutionError('');
        setReviewElapsedSeconds(0);
        appendExecutionLog('审核请求已发送，操作按钮已锁定');
        if (assetApprove) {
            appendExecutionLog('后台将依次匹配仓库、合并 master MR 并固化版本快照');
        } else {
            appendExecutionLog('后台正在保存审核决定与任务状态');
        }

        const phaseTimers = assetApprove ? [
            window.setTimeout(() => appendExecutionLog('正在扫描当前审核人可访问的 Git 仓库'), 800),
            window.setTimeout(() => appendExecutionLog('正在等待仓库合并和版本快照处理完成'), 2500),
        ] : [];

        try {
            await reviewTask(activeTask.id, form);
            phaseTimers.forEach(timer => window.clearTimeout(timer));
            appendExecutionLog('审核处理完成');
            setReviewExecutionStatus('success');
            reviewSubmittingRef.current = false;
            if (historyPage === 1) {
                await fetchTasks();
            } else {
                setHistoryPage(1);
            }
            await new Promise(resolve => window.setTimeout(resolve, 700));
            setActiveTask(null);
            setAssetReviewRecords([]);
        } catch (error) {
            phaseTimers.forEach(timer => window.clearTimeout(timer));
            const message = getRequestErrorMessage(error, '验收处理失败');
            console.error('验收处理失败:', error);
            appendExecutionLog(`处理失败：${message}`);
            setReviewExecutionError(message);
            setReviewExecutionStatus('error');
            reviewSubmittingRef.current = false;
        }
    };

    const reviewExecutionProgress = reviewExecutionStatus === 'success'
        ? 100
        : Math.min(90, 12 + reviewElapsedSeconds * 3);

    const renderPendingTasks = () => {
        if (tasks.length === 0) {
            return (
                <div className="text-center py-10 text-slate-400 bg-slate-50 rounded-xl border border-dashed border-slate-200">
                    暂无待审核任务
                </div>
            );
        }

        return (
            <div className="space-y-4">
                {tasks.map(task => (
                    <div key={task.id} className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm">
                        <div className="flex items-start justify-between gap-4">
                            <div className="min-w-0">
                                <div className="flex items-center gap-2 mb-2">
                                    <button
                                        onClick={() => openDetail(task.id)}
                                        className="font-bold text-slate-800 hover:text-red-600 text-left transition-colors"
                                    >
                                        {task.title}
                                    </button>
                                    <span className={`px-2 py-0.5 rounded text-xs font-bold ${isAssetReviewTask(task) ? 'bg-cyan-50 text-cyan-700' : 'bg-orange-50 text-orange-600'}`}>
                                        {isAssetReviewTask(task) ? '资产同步审核' : '待验收'}
                                    </span>
                                </div>
                                <p className="text-sm text-slate-500 mb-3">{task.completionDescription || task.description}</p>
                                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3 text-xs text-slate-500">
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">审核类型</div>
                                        <div>{isAssetReviewTask(task) ? '资产同步' : '上线验收'}</div>
                                    </div>
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">当前阶段</div>
                                        <div>{getTaskStageLabel(task.currentStage, task.status)}</div>
                                    </div>
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">任务归属系统</div>
                                        <div>{task.owningSystem || task.primarySystemName || '-'}</div>
                                    </div>
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">负责人</div>
                                        <div>{task.assigneeName || '-'}</div>
                                    </div>
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">终止日期</div>
                                        <div>{formatRecordTime(task.deadline)}</div>
                                    </div>
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">返工/延期</div>
                                        <div>{task.reworkCount || 0} 次 / {task.delayReported ? '已报备' : '未报备'}</div>
                                    </div>
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">{isAssetReviewTask(task) ? '需求编号' : '任务积分'}</div>
                                        <div>{isAssetReviewTask(task) ? (task.requirementNumber || '-') : `${task.points || 0} 基础积分`}</div>
                                    </div>
                                </div>
                                {isAssetReviewTask(task) && task.reviewComment && (
                                    <div className="mt-3 rounded-lg border border-slate-100 bg-slate-50 px-3 py-2 text-xs text-slate-600">
                                        <span className="font-bold text-slate-700">提交说明：</span>
                                        <span className="whitespace-pre-wrap break-words">{task.reviewComment}</span>
                                    </div>
                                )}
                            </div>
                            <div className="flex flex-col gap-2 shrink-0">
                                <button onClick={() => openDetail(task.id)} className="px-3 py-2 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-lg text-xs font-bold flex items-center gap-1">
                                    <Eye size={14} /> 详情
                                </button>
                                <button onClick={() => openReview(task, 'APPROVE')} className="px-3 py-2 bg-green-50 text-green-700 hover:bg-green-100 rounded-lg text-xs font-bold flex items-center gap-1">
                                    <CheckCircle2 size={14} /> {isAssetReviewTask(task) ? '通过进入上线' : '通过'}
                                </button>
                                <button onClick={() => openReview(task, 'REJECT')} className="px-3 py-2 bg-orange-50 text-orange-700 hover:bg-orange-100 rounded-lg text-xs font-bold flex items-center gap-1">
                                    <RotateCcw size={14} /> {isAssetReviewTask(task) ? '退回维护' : '退回'}
                                </button>
                                <button onClick={() => openReview(task, 'CANCEL')} className="px-3 py-2 bg-slate-100 text-slate-600 hover:bg-slate-200 rounded-lg text-xs font-bold flex items-center gap-1">
                                    <XCircle size={14} /> 取消
                                </button>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        );
    };

    const renderHistoryTasks = () => {
        if (historyTasks.length === 0) {
            return (
                <div className="text-center py-8 text-slate-400 bg-slate-50 rounded-xl border border-dashed border-slate-200">
                    暂无历史审核记录
                </div>
            );
        }

        const totalPages = Math.max(1, Math.ceil(historyTotal / 20));
        return (
            <div className="space-y-4">
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                    {historyTasks.map(record => (
                        <div key={record.id} className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm">
                            <div className="flex items-start justify-between gap-3 mb-3">
                                <div className="min-w-0">
                                    <button
                                        onClick={() => openDetail(record.taskId)}
                                        className="font-bold text-slate-800 hover:text-red-600 text-left transition-colors truncate block max-w-full"
                                    >
                                        {record.taskTitle}
                                    </button>
                                    <div className="mt-1 truncate text-xs text-slate-400">
                                        {record.workTitle || '-'}
                                        {record.requirementNumber ? ` · ${record.requirementNumber}` : ''}
                                    </div>
                                </div>
                                <div className="flex shrink-0 items-center gap-1.5">
                                    <span className={`rounded px-2 py-0.5 text-xs font-bold ${
                                        record.reviewType === 'ASSET_REVIEW'
                                            ? 'bg-cyan-50 text-cyan-700'
                                            : 'bg-purple-50 text-purple-700'
                                    }`}>
                                        {record.reviewType === 'ASSET_REVIEW' ? '资产同步审核' : '上线验收'}
                                    </span>
                                    <span className={`rounded px-2 py-0.5 text-xs font-bold ${getReviewDecisionStyle(record.decision)}`}>
                                        {getReviewDecisionLabel(record.decision)}
                                    </span>
                                </div>
                            </div>
                            <div className="grid grid-cols-1 gap-2 text-xs sm:grid-cols-3">
                                <div className="rounded-lg bg-slate-50 p-2">
                                    <div className="mb-1 text-slate-400">审核人</div>
                                    <div className="font-bold text-slate-700">{record.reviewerName || record.reviewerId || '-'}</div>
                                </div>
                                <div className="rounded-lg bg-slate-50 p-2">
                                    <div className="mb-1 text-slate-400">审核时间</div>
                                    <div className="font-bold text-slate-700">{formatRecordTime(record.reviewedAt)}</div>
                                </div>
                                <div className="rounded-lg bg-slate-50 p-2">
                                    <div className="mb-1 text-slate-400">任务当前状态</div>
                                    <div className="font-bold text-slate-700">
                                        {record.taskStatus ? getTaskStatusLabel(record.taskStatus) : '-'}
                                    </div>
                                </div>
                            </div>
                            <div className="mt-3 min-h-[52px] whitespace-pre-wrap break-words rounded-lg bg-slate-50 p-3 text-xs text-slate-600">
                                {record.detail || '暂无审核说明'}
                            </div>
                            <button
                                onClick={() => openDetail(record.taskId)}
                                className="mt-3 inline-flex items-center gap-1 text-xs font-bold text-blue-700 hover:text-blue-800"
                            >
                                <Eye size={14} /> 查看任务变更与完整审核轨迹
                            </button>
                        </div>
                    ))}
                </div>
                <div className="flex items-center justify-between rounded-lg border border-slate-100 bg-slate-50 px-3 py-2 text-xs text-slate-500">
                    <span>共 {historyTotal} 条审核记录，第 {historyPage} / {totalPages} 页</span>
                    <div className="flex gap-2">
                        <button
                            onClick={() => setHistoryPage(page => Math.max(1, page - 1))}
                            disabled={historyPage <= 1}
                            className="rounded border border-slate-200 bg-white px-3 py-1.5 font-bold text-slate-600 disabled:cursor-not-allowed disabled:opacity-40"
                        >
                            上一页
                        </button>
                        <button
                            onClick={() => setHistoryPage(page => Math.min(totalPages, page + 1))}
                            disabled={historyPage >= totalPages}
                            className="rounded border border-slate-200 bg-white px-3 py-1.5 font-bold text-slate-600 disabled:cursor-not-allowed disabled:opacity-40"
                        >
                            下一页
                        </button>
                    </div>
                </div>
            </div>
        );
    };

    return (
        <div className="h-full flex flex-col p-6 overflow-y-auto">
            <div className="mb-6">
                <h2 className="text-xl font-bold text-slate-800">审核中心</h2>
                <p className="text-sm text-slate-500 mt-1">集中处理资产同步审核和上线验收</p>
            </div>

            {loading ? (
                <div className="text-center py-10 text-slate-400">加载中...</div>
            ) : (
                <div>
                    <div className="flex items-center gap-2 mb-4 border-b border-slate-100">
                        <button
                            onClick={() => setActiveTab('pending')}
                            className={`px-4 py-3 text-sm font-bold border-b-2 transition-colors flex items-center gap-2 ${activeTab === 'pending'
                                ? 'border-red-600 text-red-600'
                                : 'border-transparent text-slate-500 hover:text-slate-800'
                                }`}
                        >
                            <CheckCircle2 size={16} /> 待审核任务
                            <span className="text-xs text-slate-400">({tasks.length})</span>
                        </button>
                        <button
                            onClick={() => setActiveTab('history')}
                            className={`px-4 py-3 text-sm font-bold border-b-2 transition-colors flex items-center gap-2 ${activeTab === 'history'
                                ? 'border-red-600 text-red-600'
                                : 'border-transparent text-slate-500 hover:text-slate-800'
                                }`}
                        >
                            <Clock3 size={16} /> 历史审核
                            <span className="text-xs text-slate-400">({historyTotal})</span>
                        </button>
                    </div>

                    {activeTab === 'pending' ? renderPendingTasks() : renderHistoryTasks()}
                </div>
            )}

            {activeTask && (
                <div className="fixed inset-0 bg-black/30 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-5xl max-h-[86vh] flex flex-col">
                        <div className="px-5 py-4 border-b border-slate-100">
                            <h3 className="font-bold text-slate-800">{isAssetReviewTask(activeTask) ? '资产同步审核' : '验收处理'}</h3>
                            {!isAssetReviewTask(activeTask) && (
                                <p className="text-xs text-slate-500 mt-1">{activeTask.title}</p>
                            )}
                        </div>
                        <div className="p-5 space-y-4 overflow-y-auto">
                            {isAssetReviewTask(activeTask) && (
                                <div className="space-y-4">
                                    <section className="rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
                                        <div className="text-xs font-bold text-slate-500">任务信息</div>
                                        <div className="mt-2 grid grid-cols-1 gap-3 md:grid-cols-[200px_1fr]">
                                            <div>
                                                <div className="text-xs text-slate-400">需求编号</div>
                                                <div className="mt-1 break-all font-mono text-sm font-bold text-slate-800">
                                                    {activeTask.requirementNumber || '-'}
                                                </div>
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400">需求名称</div>
                                                <div className="mt-1 text-sm font-bold text-slate-800">
                                                    {activeTask.workTitle || activeTask.title}
                                                </div>
                                            </div>
                                        </div>
                                    </section>

                                    <section>
                                        <div className="mb-2 flex items-center justify-between">
                                            <div>
                                                <div className="text-sm font-bold text-slate-800">审核依据</div>
                                                <div className="mt-0.5 text-xs text-slate-400">核对本次版本变更、资产变更与任务提交说明</div>
                                            </div>
                                            {!assetReviewLoading && (
                                                <span className={`rounded px-2 py-1 text-xs font-bold ${
                                                    assetReviewRecords.length > 0
                                                        ? 'bg-cyan-50 text-cyan-700'
                                                        : 'bg-slate-100 text-slate-600'
                                                }`}>
                                                    {assetReviewRecords.length > 0 ? `${assetReviewRecords.length} 条资产变更` : '无资产变更'}
                                                </span>
                                            )}
                                        </div>

                                        <div className="mb-4">
                                            <TaskVersionMergeRequests
                                                requirementNumber={activeTask.requirementNumber}
                                                assigneeId={activeTask.assigneeId}
                                                detailFullscreen
                                            />
                                        </div>

                                        {assetReviewLoading ? (
                                            <div className="rounded-lg border border-slate-200 bg-slate-50 py-10 text-center text-sm text-slate-400">
                                                正在加载审核依据...
                                            </div>
                                        ) : assetReviewRecords.length === 0 ? (
                                            <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-4">
                                                <div className="text-sm font-bold text-amber-800">
                                                    {assetReviewError === '资产管理维护记录加载失败'
                                                        ? '资产变更记录加载失败'
                                                        : '本次未关联资产变更记录'}
                                                </div>
                                                <div className="mt-1 text-xs text-amber-700">
                                                    {assetReviewError === '资产管理维护记录加载失败'
                                                        ? '请稍后重试，或退回任务后重新提交。'
                                                        : '请依据任务提交说明判断本次是否确实无需资产同步。'}
                                                </div>
                                                <div className="mt-3 border-t border-amber-200 pt-3">
                                                    <div className="text-xs font-bold text-amber-700">提交说明</div>
                                                    <div className="mt-1 whitespace-pre-wrap break-words text-sm text-slate-800">
                                                        {activeTask.reviewComment || '未填写提交说明'}
                                                    </div>
                                                </div>
                                            </div>
                                        ) : (
                                            <div className="overflow-hidden rounded-lg border border-slate-200">
                                                <div className="overflow-x-auto">
                                                    <table className="min-w-full text-xs">
                                                        <thead className="bg-slate-50 text-slate-500">
                                                            <tr className="border-b border-slate-200">
                                                                <th className="px-3 py-2 text-left font-bold">变更类型</th>
                                                                <th className="px-3 py-2 text-left font-bold">资产对象</th>
                                                                <th className="px-3 py-2 text-left font-bold">操作信息</th>
                                                                <th className="px-3 py-2 text-left font-bold">变更说明</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody>
                                                            {assetReviewRecords.map((record, index) => (
                                                                <tr key={record.id || `${record.reqId}-${index}`} className="border-b border-slate-100 last:border-b-0 align-top">
                                                                    <td className="whitespace-nowrap px-3 py-3 font-bold text-cyan-700">
                                                                        {getModTypeLabel(record.modType)}
                                                                    </td>
                                                                    <td className="min-w-[220px] px-3 py-3 text-slate-700">
                                                                        <AssetObjectDetailLink record={record} className="hover:bg-blue-50/60">
                                                                            <div className="font-bold">{record.tableCnName || record.tableName || '-'}</div>
                                                                            <div className="mt-1 font-mono text-slate-400">{record.tableName || '-'}</div>
                                                                            {(record.fieldName || record.fieldCnName) && (
                                                                                <div className="mt-1 text-slate-500">
                                                                                    字段：{record.fieldCnName || record.fieldName}
                                                                                    {record.fieldName && record.fieldCnName ? ` (${record.fieldName})` : ''}
                                                                                </div>
                                                                            )}
                                                                        </AssetObjectDetailLink>
                                                                    </td>
                                                                    <td className="min-w-[150px] px-3 py-3 text-slate-600">
                                                                        <div>{record.operator || '-'}</div>
                                                                        <div className="mt-1 text-slate-400">{formatRecordTime(record.time)}</div>
                                                                    </td>
                                                                    <td className="min-w-[260px] px-3 py-3 text-slate-700">
                                                                        <div className="whitespace-pre-wrap break-words">{record.description || '-'}</div>
                                                                    </td>
                                                                </tr>
                                                            ))}
                                                        </tbody>
                                                    </table>
                                                </div>
                                                {activeTask.reviewComment && (
                                                    <div className="border-t border-slate-200 bg-slate-50 px-4 py-3">
                                                        <div className="text-xs font-bold text-slate-500">提交说明</div>
                                                        <div className="mt-1 whitespace-pre-wrap break-words text-sm text-slate-700">
                                                            {activeTask.reviewComment}
                                                        </div>
                                                    </div>
                                                )}
                                            </div>
                                        )}
                                    </section>
                                </div>
                            )}
                            {reviewExecutionStatus !== 'idle' && (
                                <section className={`rounded-xl border px-4 py-3 ${
                                    reviewExecutionStatus === 'error'
                                        ? 'border-red-200 bg-red-50'
                                        : reviewExecutionStatus === 'success'
                                            ? 'border-green-200 bg-green-50'
                                            : 'border-blue-200 bg-blue-50'
                                }`} aria-live="polite">
                                    <div className="flex items-center justify-between gap-3">
                                        <div className="flex items-center gap-2 text-sm font-bold text-slate-800">
                                            {reviewExecutionStatus === 'running' && <Loader2 size={17} className="animate-spin text-blue-600" />}
                                            {reviewExecutionStatus === 'success' && <CheckCircle2 size={17} className="text-green-600" />}
                                            {reviewExecutionStatus === 'error' && <AlertCircle size={17} className="text-red-600" />}
                                            {reviewExecutionStatus === 'running' && '正在执行审核处理'}
                                            {reviewExecutionStatus === 'success' && '审核处理完成'}
                                            {reviewExecutionStatus === 'error' && '审核处理失败'}
                                        </div>
                                        <span className="text-xs font-mono text-slate-500">
                                            {reviewExecutionStatus === 'running' ? `已等待 ${reviewElapsedSeconds} 秒` : `${reviewElapsedSeconds} 秒`}
                                        </span>
                                    </div>
                                    <div className="mt-3 h-2 overflow-hidden rounded-full bg-white/80">
                                        <div
                                            className={`h-full rounded-full transition-all duration-500 ${
                                                reviewExecutionStatus === 'error' ? 'bg-red-500' : reviewExecutionStatus === 'success' ? 'bg-green-500' : 'bg-blue-500'
                                            }`}
                                            style={{ width: `${reviewExecutionProgress}%` }}
                                        />
                                    </div>
                                    <div className="mt-3 max-h-32 space-y-1 overflow-y-auto rounded-lg bg-slate-950 px-3 py-2 font-mono text-[11px] text-slate-200">
                                        {reviewExecutionLogs.map((log, index) => (
                                            <div key={`${index}-${log}`}>{log}</div>
                                        ))}
                                    </div>
                                    {reviewExecutionError && (
                                        <div className="mt-2 break-words text-xs font-medium text-red-700">{reviewExecutionError}</div>
                                    )}
                                </section>
                            )}
                            <div className="border-t border-slate-100 pt-4">
                                <div className="mb-2 text-sm font-bold text-slate-800">审核处理</div>
                                <select
                                    value={form.decision}
                                    onChange={e => setForm({ ...form, decision: e.target.value as TaskReviewDTO['decision'] })}
                                    disabled={reviewSubmitting}
                                    className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm"
                                >
                                    <option value="APPROVE">{isAssetReviewTask(activeTask) ? '通过并进入上线' : '通过并结算积分'}</option>
                                    <option value="REJECT">{isAssetReviewTask(activeTask) ? '退回补充维护记录' : '退回修改'}</option>
                                    <option value="CANCEL">取消任务</option>
                                </select>
                                {form.decision === 'APPROVE' && !isAssetReviewTask(activeTask) && (
                                    <div className="mt-3 grid grid-cols-3 gap-3">
                                        <input
                                            type="number"
                                            min={1}
                                            max={5}
                                            value={form.qualityScore || ''}
                                            onChange={e => setForm({ ...form, qualityScore: Number(e.target.value) || undefined })}
                                            disabled={reviewSubmitting}
                                            className="border border-slate-200 rounded-lg px-3 py-2 text-sm"
                                            placeholder="质量评分1-5"
                                        />
                                        <input
                                            type="number"
                                            value={form.bonusPoints || ''}
                                            onChange={e => setForm({ ...form, bonusPoints: Number(e.target.value) || 0 })}
                                            disabled={reviewSubmitting}
                                            className="border border-slate-200 rounded-lg px-3 py-2 text-sm"
                                            placeholder="奖励积分"
                                        />
                                        <input
                                            type="number"
                                            value={form.penaltyPoints || ''}
                                            onChange={e => setForm({ ...form, penaltyPoints: Number(e.target.value) || 0 })}
                                            disabled={reviewSubmitting}
                                            className="border border-slate-200 rounded-lg px-3 py-2 text-sm"
                                            placeholder="惩罚积分"
                                        />
                                    </div>
                                )}
                            </div>
                            <textarea
                                value={form.reviewComment || ''}
                                onChange={e => setForm({ ...form, reviewComment: e.target.value })}
                                disabled={reviewSubmitting}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[90px]"
                                placeholder={isAssetReviewTask(activeTask) ? '资产同步审核意见、退回原因或取消原因' : '验收意见、退回原因或取消原因'}
                            />
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end gap-2">
                            <button
                                onClick={closeReview}
                                disabled={reviewSubmitting}
                                className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg disabled:cursor-not-allowed disabled:opacity-40"
                            >
                                取消
                            </button>
                            <button
                                onClick={submitReview}
                                disabled={reviewSubmitting || assetReviewLoading}
                                className="inline-flex min-w-32 items-center justify-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-bold text-white hover:bg-red-700 disabled:cursor-not-allowed disabled:bg-red-400"
                            >
                                {reviewSubmitting && <Loader2 size={16} className="animate-spin" />}
                                {reviewSubmitting ? `处理中 ${reviewElapsedSeconds}s` : '确认处理'}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            <TaskDetailDrawer
                taskId={detailTaskId}
                isOpen={isDetailOpen}
                onClose={() => setIsDetailOpen(false)}
                onClaimSuccess={fetchTasks}
            />
        </div>
    );
};

export default ReviewCenter;
