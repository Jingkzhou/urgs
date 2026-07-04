import React, { useEffect, useState } from 'react';
import {
    applyForTask,
    claimTask,
    getMarketTasks,
    getMyTaskApplications,
    TaskApplication,
    TaskMarketDTO,
    withdrawApplication,
} from '../../api/marketplace';
import { Award, ChevronRight, Clock, FileText, Search, Users, X } from 'lucide-react';
import TaskDetailDrawer from './TaskDetailDrawer';
import { getTaskStatusLabel } from './marketplaceLabels';

type MarketTab = 'AVAILABLE' | 'READY' | 'APPLICATIONS';

const applicationStatusLabel: Record<string, string> = {
    PENDING: '待审批',
    ACCEPTED: '已中标',
    REJECTED: '未中标',
    WITHDRAWN: '已撤回',
};

const applicationStatusClass: Record<string, string> = {
    PENDING: 'bg-amber-50 text-amber-700 border-amber-100',
    ACCEPTED: 'bg-green-50 text-green-700 border-green-100',
    REJECTED: 'bg-slate-100 text-slate-500 border-slate-200',
    WITHDRAWN: 'bg-slate-100 text-slate-400 border-slate-200',
};

const TaskMarket: React.FC = () => {
    const [tasks, setTasks] = useState<TaskMarketDTO[]>([]);
    const [applications, setApplications] = useState<TaskApplication[]>([]);
    const [loading, setLoading] = useState(false);
    const [keyword, setKeyword] = useState('');
    const [activeTab, setActiveTab] = useState<MarketTab>('AVAILABLE');
    const [selectedTaskId, setSelectedTaskId] = useState<string | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);
    const [applyingTask, setApplyingTask] = useState<TaskMarketDTO | null>(null);
    const [applicationForm, setApplicationForm] = useState({
        message: '',
        solution: '',
        expectedCompletionTime: '',
    });
    const [submittingApplication, setSubmittingApplication] = useState(false);

    useEffect(() => {
        if (activeTab === 'APPLICATIONS') {
            fetchApplications();
        } else {
            fetchTasks();
        }
    }, [activeTab]);

    const fetchTasks = async () => {
        setLoading(true);
        try {
            const res = await getMarketTasks({
                current: 1,
                size: 20,
                keyword: keyword || undefined,
                status: activeTab === 'AVAILABLE' ? 'AVAILABLE' : 'READY',
            });
            setTasks(res?.records || []);
        } catch (error) {
            console.error('Failed to fetch tasks', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchApplications = async () => {
        setLoading(true);
        try {
            const res = await getMyTaskApplications({ current: 1, size: 50 });
            setApplications(res?.records || []);
        } catch (error) {
            console.error('Failed to fetch applications', error);
        } finally {
            setLoading(false);
        }
    };

    const handleClaim = async (taskId: string) => {
        if (!window.confirm('确定要领取该任务吗？')) return;
        try {
            await claimTask(taskId);
            alert('领取成功');
            fetchTasks();
        } catch (error) {
            console.error('Failed to claim task', error);
            alert('领取失败');
        }
    };

    const openApplyModal = (task: TaskMarketDTO) => {
        setApplyingTask(task);
        setApplicationForm({ message: '', solution: '', expectedCompletionTime: '' });
    };

    const handleApply = async () => {
        if (!applyingTask) return;
        if (!applicationForm.message.trim() || !applicationForm.solution.trim()) {
            alert('请填写申请理由和实施方案');
            return;
        }
        setSubmittingApplication(true);
        try {
            await applyForTask({
                taskId: applyingTask.id,
                message: applicationForm.message.trim(),
                solution: applicationForm.solution.trim(),
                expectedCompletionTime: applicationForm.expectedCompletionTime || undefined,
            });
            alert('竞标申请已提交，等待发布人审批');
            setApplyingTask(null);
            fetchTasks();
        } catch (error) {
            console.error('Failed to apply task', error);
            alert('提交竞标失败，请检查是否已申请或名额已满');
        } finally {
            setSubmittingApplication(false);
        }
    };

    const handleWithdraw = async (applicationId: string) => {
        if (!window.confirm('确认撤回该竞标申请吗？')) return;
        try {
            await withdrawApplication(applicationId);
            await fetchApplications();
        } catch (error) {
            console.error('Failed to withdraw application', error);
            alert('撤回失败，申请可能已被处理');
        }
    };

    const handleSearch = () => {
        if (activeTab === 'APPLICATIONS') {
            fetchApplications();
        } else {
            fetchTasks();
        }
    };

    return (
        <div className="h-full flex flex-col bg-slate-50/50">
            <div className="flex bg-white px-6 pt-4 gap-8">
                {[
                    ['AVAILABLE', '可承接/竞标'],
                    ['READY', '已被领取'],
                    ['APPLICATIONS', '我的竞标'],
                ].map(([key, label]) => (
                    <button
                        key={key}
                        onClick={() => setActiveTab(key as MarketTab)}
                        className={`pb-3 text-sm font-bold transition-all relative ${activeTab === key
                            ? 'text-red-600'
                            : 'text-slate-400 hover:text-slate-600'
                            }`}
                    >
                        {label}
                        {activeTab === key && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-full" />}
                    </button>
                ))}
            </div>

            <div className="p-6 border-b border-slate-100 bg-white">
                <div className="relative max-w-xl">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                    <input
                        type="text"
                        placeholder="搜索任务名称、技能..."
                        value={keyword}
                        onChange={(e) => setKeyword(e.target.value)}
                        onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                        className="w-full pl-12 pr-4 py-3 bg-slate-50 rounded-xl border-none focus:ring-2 focus:ring-red-100 text-slate-700 font-medium transition-all"
                    />
                </div>
            </div>

            <div className="flex-1 overflow-y-auto p-6">
                {loading ? (
                    <div className="flex justify-center items-center h-40 text-slate-400">加载中...</div>
                ) : activeTab === 'APPLICATIONS' ? (
                    renderApplicationList(applications, handleWithdraw)
                ) : tasks.length === 0 ? (
                    <div className="flex flex-col items-center justify-center h-40 text-slate-400">
                        <p>暂无任务</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {tasks.map(task => (
                            <div key={task.id} className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm hover:shadow-md transition-all flex flex-col group">
                                <div className="flex items-start justify-between mb-4">
                                    <div className="flex items-center gap-2 flex-wrap">
                                        <span className={`px-3 py-1 rounded-lg text-xs font-bold uppercase tracking-wider ${task.assignMode === 'OPEN' ? 'bg-blue-50 text-blue-600' : 'bg-amber-50 text-amber-700'}`}>
                                            {task.assignMode === 'OPEN' ? '直接领取' : '竞争竞标'}
                                        </span>
                                        {(task.applicationCount || 0) > 0 && (
                                            <span className="px-2 py-1 rounded-lg text-xs font-bold bg-orange-50 text-orange-600">
                                                竞标中
                                            </span>
                                        )}
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <Award size={16} className="text-orange-500" />
                                        <span className="font-bold text-slate-700">{task.points || 0} 积分</span>
                                    </div>
                                </div>

                                <h3
                                    onClick={() => {
                                        setSelectedTaskId(task.id);
                                        setIsDetailOpen(true);
                                    }}
                                    className="text-lg font-bold text-slate-800 mb-2 group-hover:text-red-600 cursor-pointer transition-colors line-clamp-2"
                                >
                                    {task.title}
                                </h3>

                                <p className="text-sm text-slate-500 mb-6 line-clamp-2 flex-1">
                                    {task.description || '无详细描述'}
                                </p>

                                <div className="space-y-3 mb-6">
                                    {task.workTitle && (
                                        <div className="flex flex-col text-xs text-slate-500 bg-slate-50 p-2.5 rounded-xl">
                                            <span className="font-bold">所属工作：</span>
                                            <span className="truncate">{task.workTitle}</span>
                                        </div>
                                    )}
                                    <div className="flex items-center justify-between text-xs text-slate-500">
                                        <div className="flex items-center gap-1.5">
                                            <Clock size={14} />
                                            <span>{task.deadline ? new Date(task.deadline).toLocaleDateString() : '无期限'}</span>
                                        </div>
                                        {task.assignMode === 'COMPETE' && (
                                            <div className="flex items-center gap-1.5">
                                                <Users size={14} />
                                                <span>{task.applicationCount}/{task.maxApplicants || '不限'} 人申请</span>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                <div className="pt-4 border-t border-slate-100 flex items-center justify-between mt-auto">
                                    <div className="flex items-center gap-3">
                                        <img src={task.publisherAvatar || 'https://api.dicebear.com/7.x/avataaars/svg?seed=' + task.publisherName} alt="" className="w-8 h-8 rounded-full bg-slate-100" />
                                        <div className="flex flex-col">
                                            <span className="text-[10px] text-slate-400 font-medium">发布者</span>
                                            <span className="text-xs font-bold text-slate-700 truncate max-w-[100px]">{task.publisherName}</span>
                                        </div>
                                    </div>

                                    {activeTab === 'AVAILABLE' ? (
                                        <button
                                            onClick={() => task.assignMode === 'OPEN' ? handleClaim(task.id) : openApplyModal(task)}
                                            className="flex items-center gap-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-bold transition-colors shadow-sm"
                                        >
                                            <span>{task.assignMode === 'OPEN' ? '立即领取' : '参与竞标'}</span>
                                            <ChevronRight size={16} />
                                        </button>
                                    ) : (
                                        <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-100 rounded-lg">
                                            <span className="text-xs font-bold text-slate-500">{getTaskStatusLabel(task.status)}</span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            <TaskDetailDrawer
                taskId={selectedTaskId}
                isOpen={isDetailOpen}
                onClose={() => setIsDetailOpen(false)}
                onClaimSuccess={fetchTasks}
            />

            {applyingTask && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 px-4">
                    <div className="w-full max-w-xl rounded-2xl bg-white shadow-2xl border border-slate-200">
                        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
                            <div>
                                <h3 className="font-black text-slate-800">参与竞标</h3>
                                <p className="text-xs text-slate-500 mt-1">{applyingTask.title} · {applyingTask.points || 0} 积分</p>
                            </div>
                            <button onClick={() => setApplyingTask(null)} className="p-2 text-slate-400 hover:bg-slate-100 rounded-lg">
                                <X size={18} />
                            </button>
                        </div>
                        <div className="p-5 space-y-4">
                            <div>
                                <label className="block text-xs font-bold text-slate-500 mb-1">申请理由</label>
                                <textarea
                                    value={applicationForm.message}
                                    onChange={e => setApplicationForm(prev => ({ ...prev, message: e.target.value }))}
                                    rows={3}
                                    className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm resize-none focus:ring-1 focus:ring-red-500 outline-none"
                                    placeholder="说明为什么适合承接该任务"
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-slate-500 mb-1">实施方案</label>
                                <textarea
                                    value={applicationForm.solution}
                                    onChange={e => setApplicationForm(prev => ({ ...prev, solution: e.target.value }))}
                                    rows={4}
                                    className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm resize-none focus:ring-1 focus:ring-red-500 outline-none"
                                    placeholder="简述拆解思路、交付物、风险和协作方式"
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-slate-500 mb-1">预计完成时间</label>
                                <input
                                    type="datetime-local"
                                    value={applicationForm.expectedCompletionTime}
                                    onChange={e => setApplicationForm(prev => ({ ...prev, expectedCompletionTime: e.target.value }))}
                                    className="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:ring-1 focus:ring-red-500 outline-none"
                                />
                            </div>
                        </div>
                        <div className="px-5 py-4 border-t border-slate-100 flex justify-end gap-2">
                            <button
                                onClick={() => setApplyingTask(null)}
                                className="px-4 py-2 text-sm font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg"
                            >
                                取消
                            </button>
                            <button
                                onClick={handleApply}
                                disabled={submittingApplication}
                                className="px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg disabled:opacity-60"
                            >
                                {submittingApplication ? '提交中...' : '提交竞标'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

const renderApplicationList = (
    applications: TaskApplication[],
    onWithdraw: (applicationId: string) => void,
) => {
    if (applications.length === 0) {
        return (
            <div className="flex flex-col items-center justify-center h-40 text-slate-400">
                <p>暂无竞标申请</p>
            </div>
        );
    }

    return (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {applications.map(application => (
                <div key={application.id} className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
                    <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0">
                            <div className="flex items-center gap-2 mb-2">
                                <span className={`text-xs font-bold px-2.5 py-1 rounded-lg border ${applicationStatusClass[application.status] || applicationStatusClass.REJECTED}`}>
                                    {applicationStatusLabel[application.status] || application.status}
                                </span>
                                <span className="text-xs text-slate-400">{application.taskPoints || 0} 积分</span>
                            </div>
                            <h3 className="font-black text-slate-800 truncate">{application.taskTitle || application.taskId}</h3>
                            <p className="text-xs text-slate-500 mt-1 truncate">{application.workTitle || '未关联工作'}</p>
                        </div>
                        {application.status === 'PENDING' && (
                            <button
                                onClick={() => onWithdraw(application.id)}
                                className="px-3 py-1.5 text-xs font-bold text-slate-500 bg-slate-100 hover:bg-slate-200 rounded-lg shrink-0"
                            >
                                撤回
                            </button>
                        )}
                    </div>

                    <div className="grid grid-cols-2 gap-3 mt-4 text-xs">
                        <div className="bg-slate-50 rounded-lg p-3">
                            <div className="font-bold text-slate-700 mb-1 flex items-center gap-1"><FileText size={13} /> 申请理由</div>
                            <p className="text-slate-500 line-clamp-3 whitespace-pre-wrap">{application.message || '-'}</p>
                        </div>
                        <div className="bg-slate-50 rounded-lg p-3">
                            <div className="font-bold text-slate-700 mb-1">预计完成</div>
                            <p className="text-slate-500">
                                {application.expectedCompletionTime ? new Date(application.expectedCompletionTime).toLocaleString() : '-'}
                            </p>
                        </div>
                    </div>

                    {application.reviewComment && (
                        <div className="mt-3 rounded-lg bg-slate-50 px-3 py-2 text-xs text-slate-500">
                            审批意见：{application.reviewComment}
                        </div>
                    )}
                </div>
            ))}
        </div>
    );
};

export default TaskMarket;
