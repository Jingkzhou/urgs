import React, { useState, useEffect } from 'react';
import { getMarketTasks, claimTask, TaskMarketDTO } from '../../api/marketplace';
import { Search, Clock, Award, Users, ChevronRight } from 'lucide-react';
import TaskDetailDrawer from './TaskDetailDrawer';

const TaskMarket: React.FC = () => {
    const [tasks, setTasks] = useState<TaskMarketDTO[]>([]);
    const [loading, setLoading] = useState(false);
    const [keyword, setKeyword] = useState('');
    const [activeStatus, setActiveStatus] = useState<'OPEN' | 'ASSIGNED'>('OPEN');
    const [selectedTaskId, setSelectedTaskId] = useState<string | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);

    const fetchTasks = async (status?: string) => {
        setLoading(true);
        try {
            const currentStatus = status || activeStatus;
            const res = await getMarketTasks({
                current: 1,
                size: 20,
                keyword: keyword || undefined,
                status: currentStatus
            });
            if (res?.records) {
                setTasks(res.records);
            }
        } catch (error) {
            console.error('Failed to fetch tasks', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTasks();
    }, [activeStatus]);

    const handleClaim = async (taskId: string) => {
        if (!window.confirm("确定要领取该任务吗？")) return;
        try {
            await claimTask(taskId);
            alert("领取成功");
            fetchTasks();
        } catch (error) {
            console.error('Failed to claim task', error);
            alert("领取失败");
        }
    };

    const handleStatusChange = (status: 'OPEN' | 'ASSIGNED') => {
        setActiveStatus(status);
    };

    return (
        <div className="h-full flex flex-col bg-slate-50/50">
            {/* Tab Header */}
            <div className="flex bg-white px-6 pt-4 gap-8">
                <button
                    onClick={() => handleStatusChange('OPEN')}
                    className={`pb-3 text-sm font-bold transition-all relative ${activeStatus === 'OPEN'
                        ? 'text-red-600'
                        : 'text-slate-400 hover:text-slate-600'
                        }`}
                >
                    待领取
                    {activeStatus === 'OPEN' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-full" />}
                </button>
                <button
                    onClick={() => handleStatusChange('ASSIGNED')}
                    className={`pb-3 text-sm font-bold transition-all relative ${activeStatus === 'ASSIGNED'
                        ? 'text-red-600'
                        : 'text-slate-400 hover:text-slate-600'
                        }`}
                >
                    已被领取
                    {activeStatus === 'ASSIGNED' && <div className="absolute bottom-0 left-0 w-full h-0.5 bg-red-600 rounded-full" />}
                </button>
            </div>
            {/* Search Bar */}
            <div className="p-6 border-b border-slate-100 bg-white">
                <div className="relative max-w-xl">
                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                    <input
                        type="text"
                        placeholder="搜索任务名称、技能..."
                        value={keyword}
                        onChange={(e) => setKeyword(e.target.value)}
                        onKeyDown={(e) => e.key === 'Enter' && fetchTasks()}
                        className="w-full pl-12 pr-4 py-3 bg-slate-50 rounded-xl border-none focus:ring-2 focus:ring-red-100 text-slate-700 font-medium transition-all"
                    />
                </div>
            </div>

            {/* Task Grid */}
            <div className="flex-1 overflow-y-auto p-6">
                {loading ? (
                    <div className="flex justify-center items-center h-40 text-slate-400">加载中...</div>
                ) : tasks.length === 0 ? (
                    <div className="flex flex-col items-center justify-center h-40 text-slate-400">
                        <p>暂无开放的任务</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {tasks.map(task => (
                            <div key={task.id} className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm hover:shadow-md transition-all flex flex-col group">
                                <div className="flex items-start justify-between mb-4">
                                    <span className="px-3 py-1 bg-blue-50 text-blue-600 rounded-lg text-xs font-bold uppercase tracking-wider">
                                        {task.assignMode === 'OPEN' ? '直接领取' : '竞争竞标'}
                                    </span>
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
                                    {task.description || "无详细描述"}
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

                                    {activeStatus === 'OPEN' ? (
                                        <button
                                            onClick={() => task.assignMode === 'OPEN' ? handleClaim(task.id) : alert("竞标功能即将上线")}
                                            className="flex items-center gap-1 px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm font-bold transition-colors shadow-sm"
                                        >
                                            <span>{task.assignMode === 'OPEN' ? '立即领取' : '参与竞标'}</span>
                                            <ChevronRight size={16} />
                                        </button>
                                    ) : (
                                        <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-100 rounded-lg">
                                            <div className="w-5 h-5 rounded-full bg-slate-300 flex items-center justify-center text-[10px] text-white">
                                                {task.assigneeId ? 'L' : '?'}
                                            </div>
                                            <span className="text-xs font-bold text-slate-500">已领用</span>
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
        </div>
    );
};

export default TaskMarket;
