import React, { useState, useEffect } from 'react';
import {
    getKpiSummary,
    getMyTasks,
    releaseTask,
    updateTaskStatus,
    submitTaskForReview,
    createTaskAppeal,
    WorkTask,
    TaskSubmissionDTO,
    KpiSummaryDTO,
} from '../../api/marketplace';
import { Award, CheckCircle, Clock, Gauge, ListTodo, Star, TrendingUp, X } from 'lucide-react';
import TaskDetailDrawer from './TaskDetailDrawer';
import { getTaskStatusLabel } from './marketplaceLabels';

const formatDateInput = (date: Date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
};

const getCurrentMonthRange = () => {
    const now = new Date();
    return {
        startDate: formatDateInput(new Date(now.getFullYear(), now.getMonth(), 1)),
        endDate: formatDateInput(new Date(now.getFullYear(), now.getMonth() + 1, 0)),
    };
};

const MyTasks: React.FC = () => {
    const [tasks, setTasks] = useState<WorkTask[]>([]);
    const [kpiSummary, setKpiSummary] = useState<KpiSummaryDTO | null>(null);
    const [dateRange, setDateRange] = useState(getCurrentMonthRange);
    const [loading, setLoading] = useState(false);
    const [selectedTaskId, setSelectedTaskId] = useState<string | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);
    const [submitTask, setSubmitTask] = useState<WorkTask | null>(null);
    const [submitForm, setSubmitForm] = useState<TaskSubmissionDTO>({});
    const [appealTask, setAppealTask] = useState<WorkTask | null>(null);
    const [appealForm, setAppealForm] = useState({ reason: '', expectedResult: '' });

    const fetchTasks = async () => {
        setLoading(true);
        try {
            const [taskRes, kpiRes] = await Promise.all([
                getMyTasks({ current: 1, size: 20 }),
                getKpiSummary(dateRange),
            ]);
            setTasks(taskRes?.records || []);
            setKpiSummary(kpiRes || null);
        } catch (error) {
            console.error('Failed to fetch personal dashboard', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTasks();
    }, [dateRange.startDate, dateRange.endDate]);

    const resetToCurrentMonth = () => {
        setDateRange(getCurrentMonthRange());
    };

    const handleUpdateStatus = async (id: string, newStatus: string) => {
        try {
            await updateTaskStatus(id, newStatus);
            fetchTasks();
        } catch (error) {
            alert("更新状态失败");
        }
    };

    const handleReleaseTask = async (task: WorkTask) => {
        if (!window.confirm(`确定要解除承接「${task.title}」吗？解除后任务将返回任务大厅。`)) return;
        try {
            await releaseTask(task.id);
            fetchTasks();
        } catch (error) {
            alert('解除承接失败');
        }
    };

    const handleSubmitReview = async () => {
        if (!submitTask) return;
        if (!submitForm.completionDescription || !submitForm.deliverables) {
            alert('请填写完成说明和交付物');
            return;
        }
        try {
            await submitTaskForReview(submitTask.id, submitForm);
            setSubmitTask(null);
            setSubmitForm({});
            fetchTasks();
        } catch (error) {
            alert('提交验收失败');
        }
    };

    const handleAppeal = async () => {
        if (!appealTask) return;
        if (!appealForm.reason) {
            alert('请填写申诉原因');
            return;
        }
        try {
            await createTaskAppeal(appealTask.id, appealForm);
            setAppealTask(null);
            setAppealForm({ reason: '', expectedResult: '' });
            alert('申诉已提交');
        } catch (error) {
            alert('提交申诉失败');
        }
    };

    return (
        <div className="h-full flex flex-col p-6 overflow-y-auto">
            <div className="mb-6">
                <h2 className="text-xl font-bold text-slate-800">个人看板</h2>
                <p className="text-sm text-slate-500 mt-1">我的 KPI 积分、质量表现和承接任务</p>
            </div>

            <div className="flex flex-wrap items-center gap-3 mb-4 bg-slate-50 border border-slate-100 rounded-xl px-4 py-3">
                <span className="text-sm font-bold text-slate-700">KPI 周期</span>
                <input
                    type="date"
                    value={dateRange.startDate}
                    onChange={e => setDateRange(prev => ({ ...prev, startDate: e.target.value }))}
                    className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm"
                />
                <span className="text-slate-400 text-sm">至</span>
                <input
                    type="date"
                    value={dateRange.endDate}
                    onChange={e => setDateRange(prev => ({ ...prev, endDate: e.target.value }))}
                    className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm"
                />
                <button
                    onClick={resetToCurrentMonth}
                    className="px-3 py-1.5 text-sm font-bold text-red-600 bg-red-50 hover:bg-red-100 rounded-lg"
                >
                    本月
                </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
                <div className="bg-orange-50 border border-orange-100 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-orange-700 text-sm font-bold mb-3">
                        <Award size={18} /> 最终 KPI 积分
                    </div>
                    <div className="text-3xl font-black text-orange-700">{kpiSummary?.finalPoints ?? 0}</div>
                    <div className="text-xs text-orange-600 mt-1">基础积分 {kpiSummary?.basePoints ?? 0}</div>
                </div>
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-blue-700 text-sm font-bold mb-3">
                        <ListTodo size={18} /> 完成任务
                    </div>
                    <div className="text-3xl font-black text-blue-700">{kpiSummary?.completedTaskCount ?? 0}</div>
                    <div className="text-xs text-blue-600 mt-1">进行中 {kpiSummary?.activeTaskCount ?? 0}</div>
                </div>
                <div className="bg-green-50 border border-green-100 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-green-700 text-sm font-bold mb-3">
                        <Gauge size={18} /> 准时率
                    </div>
                    <div className="text-3xl font-black text-green-700">{kpiSummary?.onTimeRate ?? 0}%</div>
                    <div className="text-xs text-green-600 mt-1">延期 {kpiSummary?.overdueCount ?? 0} 次</div>
                </div>
                <div className="bg-slate-50 border border-slate-200 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-slate-700 text-sm font-bold mb-3">
                        <Star size={18} /> 质量与返工
                    </div>
                    <div className="text-3xl font-black text-slate-800">{kpiSummary?.averageQualityScore ?? 0}</div>
                    <div className="text-xs text-slate-500 mt-1">返工 {kpiSummary?.reworkCount ?? 0} 次 · 高优先级 {kpiSummary?.highPriorityTaskCount ?? 0}</div>
                </div>
            </div>

            <div className="flex items-center gap-2 mb-4">
                <TrendingUp size={18} className="text-slate-500" />
                <h3 className="font-bold text-slate-800">我的任务</h3>
            </div>

            {loading ? (
                <div className="text-center py-10 text-slate-400">加载中...</div>
            ) : tasks.length === 0 ? (
                <div className="text-center py-10 text-slate-400 bg-slate-50 rounded-2xl border border-dashed border-slate-200">
                    您还没有领取的任务，去大厅逛逛吧。
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {tasks.map(task => (
                        <div key={task.id} className="bg-white border text-left border-slate-200 rounded-xl p-5 shadow-sm">
                            <div className="flex items-center justify-between mb-2">
                                <h3
                                    onClick={() => {
                                        setSelectedTaskId(task.id);
                                        setIsDetailOpen(true);
                                    }}
                                    className="font-bold text-slate-800 hover:text-red-600 cursor-pointer transition-colors"
                                >
                                    {task.title}
                                </h3>
                                <span className={`px-2 py-0.5 rounded text-xs font-bold uppercase ${task.status === 'COMPLETED' ? 'bg-green-100 text-green-700' :
                                    task.status === 'IN_PROGRESS' ? 'bg-blue-100 text-blue-700' :
                                        task.status === 'REVIEW' ? 'bg-orange-100 text-orange-700' : 'bg-slate-100 text-slate-600'
                                    }`}>
                                    {getTaskStatusLabel(task.status)}
                                </span>
                            </div>
                            <p className="text-sm text-slate-500 mb-4 line-clamp-2">{task.description}</p>

                            <div className="flex items-center justify-between mt-auto pt-4 border-t border-slate-100">
                                <div className="flex items-center gap-1.5 text-xs text-slate-500 font-medium">
                                    <Clock size={14} />
                                    <span>{task.deadline ? new Date(task.deadline).toLocaleDateString() : '无期限'}</span>
                                    <span className="mx-2 text-slate-300">|</span>
                                    <span className="text-orange-500 font-bold">{task.points} 积分</span>
                                </div>

                                <div className="flex gap-2">
                                    {task.status === 'ASSIGNED' && (
                                        <>
                                            <button
                                                onClick={() => handleReleaseTask(task)}
                                                className="px-3 py-1 bg-slate-100 text-slate-600 hover:bg-slate-200 rounded text-xs font-bold transition-colors"
                                            >
                                                解除承接
                                            </button>
                                            <button
                                                onClick={() => handleUpdateStatus(task.id, 'IN_PROGRESS')}
                                                className="px-3 py-1 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded text-xs font-bold transition-colors"
                                            >
                                                开始开发
                                            </button>
                                        </>
                                    )}
                                    {task.status === 'IN_PROGRESS' && (
                                        <button
                                            onClick={() => setSubmitTask(task)}
                                            className="px-3 py-1 bg-red-600 text-white hover:bg-red-700 rounded text-xs font-bold transition-colors flex items-center gap-1"
                                        >
                                            <CheckCircle size={14} /> 提交审核
                                        </button>
                                    )}
                                    {task.status === 'REJECTED' && (
                                        <>
                                            <button
                                                onClick={() => setSubmitTask(task)}
                                                className="px-3 py-1 bg-red-600 text-white hover:bg-red-700 rounded text-xs font-bold transition-colors"
                                            >
                                                重新提交
                                            </button>
                                            <button
                                                onClick={() => setAppealTask(task)}
                                                className="px-3 py-1 bg-slate-100 text-slate-600 hover:bg-slate-200 rounded text-xs font-bold transition-colors"
                                            >
                                                申诉
                                            </button>
                                        </>
                                    )}
                                    {task.status === 'REVIEW' && (
                                        <span className="text-xs text-orange-500 font-medium px-2 py-1 bg-orange-50 rounded">审核中...</span>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            <TaskDetailDrawer
                taskId={selectedTaskId}
                isOpen={isDetailOpen}
                onClose={() => setIsDetailOpen(false)}
                onClaimSuccess={fetchTasks}
            />

            {submitTask && (
                <div className="fixed inset-0 bg-black/30 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-2xl">
                        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                            <div>
                                <h3 className="font-bold text-slate-800">提交验收</h3>
                                <p className="text-xs text-slate-500 mt-1">{submitTask.title}</p>
                            </div>
                            <button onClick={() => setSubmitTask(null)} className="p-1.5 hover:bg-slate-100 rounded">
                                <X size={18} />
                            </button>
                        </div>
                        <div className="p-5 space-y-4">
                            <textarea
                                value={submitForm.completionDescription || ''}
                                onChange={e => setSubmitForm({ ...submitForm, completionDescription: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[90px]"
                                placeholder="完成说明 *"
                            />
                            <textarea
                                value={submitForm.deliverables || ''}
                                onChange={e => setSubmitForm({ ...submitForm, deliverables: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[70px]"
                                placeholder="交付物链接、附件、代码或文档地址 *"
                            />
                            <div className="grid grid-cols-1 gap-3">
                                <label className="flex items-center gap-2 text-sm text-slate-600 border border-slate-200 rounded-lg px-3 py-2">
                                    <input
                                        type="checkbox"
                                        checked={!!submitForm.delayReported}
                                        onChange={e => setSubmitForm({ ...submitForm, delayReported: e.target.checked })}
                                    />
                                    已提前报备延期
                                </label>
                            </div>
                            <textarea
                                value={submitForm.impactScope || ''}
                                onChange={e => setSubmitForm({ ...submitForm, impactScope: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[60px]"
                                placeholder="影响范围"
                            />
                            <textarea
                                value={submitForm.delayReason || ''}
                                onChange={e => setSubmitForm({ ...submitForm, delayReason: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[60px]"
                                placeholder="延期原因或风险说明"
                            />
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end gap-2">
                            <button onClick={() => setSubmitTask(null)} className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg">取消</button>
                            <button onClick={handleSubmitReview} className="px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg">提交验收</button>
                        </div>
                    </div>
                </div>
            )}

            {appealTask && (
                <div className="fixed inset-0 bg-black/30 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-lg">
                        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                            <h3 className="font-bold text-slate-800">发起申诉</h3>
                            <button onClick={() => setAppealTask(null)} className="p-1.5 hover:bg-slate-100 rounded">
                                <X size={18} />
                            </button>
                        </div>
                        <div className="p-5 space-y-4">
                            <textarea
                                value={appealForm.reason}
                                onChange={e => setAppealForm({ ...appealForm, reason: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[90px]"
                                placeholder="申诉原因 *"
                            />
                            <textarea
                                value={appealForm.expectedResult}
                                onChange={e => setAppealForm({ ...appealForm, expectedResult: e.target.value })}
                                className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm min-h-[70px]"
                                placeholder="期望处理结果"
                            />
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end gap-2">
                            <button onClick={() => setAppealTask(null)} className="px-4 py-2 text-sm font-bold text-slate-500 hover:bg-slate-50 rounded-lg">取消</button>
                            <button onClick={handleAppeal} className="px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg">提交申诉</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default MyTasks;
