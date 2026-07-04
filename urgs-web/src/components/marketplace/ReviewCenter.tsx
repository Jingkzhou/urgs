import React, { useEffect, useState } from 'react';
import { CheckCircle2, Clock3, Eye, RotateCcw, XCircle } from 'lucide-react';
import {
    AssetMaintenanceRecord,
    getPendingReviewTasks,
    getReviewHistoryTasks,
    listAssetMaintenanceRecords,
    reviewTask,
    TaskMarketDTO,
    TaskReviewDTO,
} from '../../api/marketplace';
import TaskDetailDrawer from './TaskDetailDrawer';
import { getTaskStageLabel, getTaskStatusLabel } from './marketplaceLabels';

const ReviewCenter: React.FC = () => {
    const [tasks, setTasks] = useState<TaskMarketDTO[]>([]);
    const [historyTasks, setHistoryTasks] = useState<TaskMarketDTO[]>([]);
    const [loading, setLoading] = useState(false);
    const [activeTask, setActiveTask] = useState<TaskMarketDTO | null>(null);
    const [detailTaskId, setDetailTaskId] = useState<string | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);
    const [activeTab, setActiveTab] = useState<'pending' | 'history'>('pending');
    const [form, setForm] = useState<TaskReviewDTO>({ decision: 'APPROVE', qualityScore: 4, bonusPoints: 0, penaltyPoints: 0 });
    const [assetReviewRecords, setAssetReviewRecords] = useState<AssetMaintenanceRecord[]>([]);
    const [assetReviewLoading, setAssetReviewLoading] = useState(false);
    const [assetReviewError, setAssetReviewError] = useState('');

    const fetchTasks = async () => {
        setLoading(true);
        try {
            const [pendingRes, historyRes] = await Promise.all([
                getPendingReviewTasks({ current: 1, size: 50 }),
                getReviewHistoryTasks({ current: 1, size: 20 }),
            ]);
            setTasks(pendingRes?.records || []);
            setHistoryTasks(historyRes?.records || []);
        } catch (error) {
            console.error('Failed to fetch review tasks', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTasks();
    }, []);

    const isAssetReviewTask = (task?: TaskMarketDTO | null) =>
        task?.status === 'WAITING_REVIEW' && task.currentStage === 'ASSET_REVIEW';

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
            let res = await listAssetMaintenanceRecords({ reqId, page: 1, size: 100 });
            let records = res?.records || [];
            if ((res?.total || 0) > records.length) {
                res = await listAssetMaintenanceRecords({ reqId, page: 1, size: res.total });
                records = res?.records || [];
            }
            setAssetReviewRecords(records);
            if (records.length === 0) {
                setAssetReviewError(`未找到需求编号 ${reqId} 的资产管理维护记录`);
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
        setActiveTask(null);
        setAssetReviewRecords([]);
        setAssetReviewLoading(false);
        setAssetReviewError('');
    };

    const submitReview = async () => {
        if (!activeTask) return;
        if (form.decision === 'APPROVE' && !isAssetReviewTask(activeTask) && !form.qualityScore) {
            alert('通过验收必须填写质量评分');
            return;
        }
        try {
            await reviewTask(activeTask.id, form);
            closeReview();
            fetchTasks();
        } catch (error) {
            alert('验收处理失败');
        }
    };

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
                                        <div>{getTaskStageLabel(task.currentStage)}</div>
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

        return (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                {historyTasks.map(task => (
                    <div key={task.id} className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm">
                        <div className="flex items-start justify-between gap-3 mb-3">
                            <div className="min-w-0">
                                <button
                                    onClick={() => openDetail(task.id)}
                                    className="font-bold text-slate-800 hover:text-red-600 text-left transition-colors truncate block max-w-full"
                                >
                                    {task.title}
                                </button>
                                <div className="text-xs text-slate-400 mt-1">
                                    {task.reviewedAt ? new Date(task.reviewedAt).toLocaleString() : '-'}
                                </div>
                            </div>
                            <span className="px-2 py-0.5 rounded bg-slate-100 text-slate-600 text-xs font-bold shrink-0">
                                {getTaskStatusLabel(task.status)}
                            </span>
                        </div>
                        <div className="grid grid-cols-3 gap-2 text-xs mb-3">
                            <div className="bg-slate-50 rounded-lg p-2">
                                <div className="text-slate-400 mb-1">质量分</div>
                                <div className="font-bold text-slate-800">{task.qualityScore || '-'}</div>
                            </div>
                            <div className="bg-slate-50 rounded-lg p-2">
                                <div className="text-slate-400 mb-1">最终积分</div>
                                <div className="font-bold text-orange-600">{task.finalPoints || 0}</div>
                            </div>
                            <div className="bg-slate-50 rounded-lg p-2">
                                <div className="text-slate-400 mb-1">返工</div>
                                <div className="font-bold text-slate-800">{task.reworkCount || 0} 次</div>
                            </div>
                        </div>
                        <div className="text-xs text-slate-500 bg-slate-50 rounded-lg p-3 min-h-[44px]">
                            {task.reviewComment || '暂无验收意见'}
                        </div>
                    </div>
                ))}
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
                            <span className="text-xs text-slate-400">({historyTasks.length})</span>
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
                                                <div className="text-xs text-slate-400">工作名称</div>
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
                                                <div className="mt-0.5 text-xs text-slate-400">核对本次资产变更与任务提交说明</div>
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
                                                                        <div className="font-bold">{record.tableCnName || record.tableName || '-'}</div>
                                                                        <div className="mt-1 font-mono text-slate-400">{record.tableName || '-'}</div>
                                                                        {(record.fieldName || record.fieldCnName) && (
                                                                            <div className="mt-1 text-slate-500">
                                                                                字段：{record.fieldCnName || record.fieldName}
                                                                                {record.fieldName && record.fieldCnName ? ` (${record.fieldName})` : ''}
                                                                            </div>
                                                                        )}
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
                            <div className="border-t border-slate-100 pt-4">
                                <div className="mb-2 text-sm font-bold text-slate-800">审核处理</div>
                                <select
                                    value={form.decision}
                                    onChange={e => setForm({ ...form, decision: e.target.value as TaskReviewDTO['decision'] })}
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
                                            className="border border-slate-200 rounded-lg px-3 py-2 text-sm"
                                            placeholder="质量评分1-5"
                                        />
                                        <input
                                            type="number"
                                            value={form.bonusPoints || ''}
                                            onChange={e => setForm({ ...form, bonusPoints: Number(e.target.value) || 0 })}
                                            className="border border-slate-200 rounded-lg px-3 py-2 text-sm"
                                            placeholder="奖励积分"
                                        />
                                        <input
                                            type="number"
                                            value={form.penaltyPoints || ''}
                                            onChange={e => setForm({ ...form, penaltyPoints: Number(e.target.value) || 0 })}
                                            className="border border-slate-200 rounded-lg px-3 py-2 text-sm"
                                            placeholder="惩罚积分"
                                        />
                                    </div>
                                )}
                            </div>
                            <textarea
                                value={form.reviewComment || ''}
                                onChange={e => setForm({ ...form, reviewComment: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[90px]"
                                placeholder={isAssetReviewTask(activeTask) ? '资产同步审核意见、退回原因或取消原因' : '验收意见、退回原因或取消原因'}
                            />
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end gap-2">
                            <button onClick={closeReview} className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg">取消</button>
                            <button onClick={submitReview} className="px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg">确认处理</button>
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
