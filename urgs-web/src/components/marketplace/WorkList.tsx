import React, { useState, useEffect } from 'react';
import { listWorks, publishWork, cancelWork, Work, WorkTask, getWorkTasks } from '../../api/marketplace';
import { Clock3, ListTodo, Plus, Play, XCircle } from 'lucide-react';
import CreateWorkDrawer from './CreateWorkDrawer';
import WorkDetailDrawer from './WorkDetailDrawer';
import { getWorkStatusLabel } from './marketplaceLabels';

interface WorkTaskSummary {
    taskCount: number;
    totalHours: number;
    taskHours: number[];
}

const WorkList: React.FC = () => {
    const [works, setWorks] = useState<Work[]>([]);
    const [taskSummaries, setTaskSummaries] = useState<Record<string, WorkTaskSummary>>({});
    const [loading, setLoading] = useState(false);
    const [isDrawerOpen, setIsDrawerOpen] = useState(false);
    const [selectedWorkId, setSelectedWorkId] = useState<string | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);

    const fetchWorks = async () => {
        setLoading(true);
        try {
            const res = await listWorks({ current: 1, size: 20 });
            if (res?.records) {
                setWorks(res.records);
                const entries = await Promise.all(
                    res.records.map(async (work: Work) => {
                        const tasks = await getWorkTasks(work.id);
                        return [work.id, buildTaskSummary(tasks || [])] as const;
                    })
                );
                setTaskSummaries(Object.fromEntries(entries));
            }
        } catch (error) {
            console.error('Failed to fetch works', error);
        } finally {
            setLoading(false);
        }
    };

    const buildTaskSummary = (tasks: WorkTask[]): WorkTaskSummary => {
        const taskHours = tasks.map(task => task.estimatedHours ?? task.actualHours ?? 0);
        return {
            taskCount: tasks.length,
            taskHours,
            totalHours: taskHours.reduce((sum, hours) => sum + hours, 0),
        };
    };

    useEffect(() => {
        fetchWorks();
    }, []);

    const handlePublish = async (id: string) => {
        if (!window.confirm("确认要发布该工作到市场吗？发布后不能撤回。")) return;
        try {
            await publishWork(id);
            alert("发布成功");
            fetchWorks();
        } catch (error) {
            alert("发布失败");
        }
    };

    const handleCancel = async (id: string) => {
        if (!window.confirm("确定要取消该工作吗？")) return;
        try {
            await cancelWork(id);
            alert("取消成功");
            fetchWorks();
        } catch (error) {
            alert("取消失败");
        }
    };

    return (
        <div className="h-full flex flex-col p-6 overflow-y-auto relative">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-slate-800">我发布的工作</h2>
                <button
                    onClick={() => setIsDrawerOpen(true)}
                    className="flex items-center gap-2 px-4 py-2 bg-slate-800 text-white rounded-lg hover:bg-slate-700 transition-colors text-sm font-bold"
                >
                    <Plus size={16} />新建工作
                </button>
            </div>

            <CreateWorkDrawer
                isOpen={isDrawerOpen}
                onClose={() => setIsDrawerOpen(false)}
                onSuccess={() => {
                    setIsDrawerOpen(false);
                    fetchWorks();
                }}
            />

            {loading ? (
                <div className="text-center py-10 text-slate-400">加载中...</div>
            ) : works.length === 0 ? (
                <div className="text-center py-10 text-slate-400 bg-slate-50 rounded-2xl border border-dashed border-slate-200">
                    您还没有发布过工作，点击右上角新建一个吧。
                </div>
            ) : (
                <div className="space-y-4">
                    {works.map(work => (
                        <div key={work.id} className="bg-white border text-left border-slate-200 rounded-xl p-5 shadow-sm flex items-center justify-between gap-5">
                            <div className="min-w-0 flex-1">
                                <div className="flex items-center gap-3 mb-2">
                                    <h3
                                        onClick={() => {
                                            setSelectedWorkId(work.id);
                                            setIsDetailOpen(true);
                                        }}
                                        className="text-lg font-bold text-slate-800 hover:text-red-600 cursor-pointer transition-colors"
                                    >
                                        {work.title}
                                    </h3>
                                    <span className={`px-2 py-0.5 rounded text-xs font-bold uppercase ${work.status === 'PUBLISHED' ? 'bg-green-100 text-green-700' :
                                        work.status === 'IN_PROGRESS' ? 'bg-blue-100 text-blue-700' :
                                            work.status === 'DRAFT' ? 'bg-slate-100 text-slate-600' : 'bg-red-100 text-red-600'
                                        }`}>
                                        {getWorkStatusLabel(work.status)}
                                    </span>
                                </div>
                                <div className="flex items-center gap-4 text-sm text-slate-500">
                                    <span>总积分: {work.totalPoints}</span>
                                    <span>优先级: <span className="text-red-500 font-medium">{work.priority}</span></span>
                                    <span>创建时间: {new Date(work.createTime).toLocaleDateString()}</span>
                                </div>
                                <div className="flex flex-wrap items-center gap-3 mt-3 text-xs text-slate-500">
                                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded bg-slate-50 border border-slate-100">
                                        <ListTodo size={13} /> 子任务 {taskSummaries[work.id]?.taskCount ?? 0} 个
                                    </span>
                                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded bg-slate-50 border border-slate-100">
                                        <Clock3 size={13} /> 汇总工时 {taskSummaries[work.id]?.totalHours ?? 0} 小时
                                    </span>
                                    <span className="truncate max-w-full">
                                        子任务工时: {(taskSummaries[work.id]?.taskHours || []).length > 0
                                            ? taskSummaries[work.id].taskHours.map((hours, index) => `#${index + 1} ${hours}h`).join(' / ')
                                            : '-'}
                                    </span>
                                </div>
                            </div>

                            <div className="flex items-center gap-3">
                                {work.status === 'DRAFT' && (
                                    <button
                                        onClick={() => handlePublish(work.id)}
                                        className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors tooltip"
                                        title="发布到市场"
                                    >
                                        <Play size={20} />
                                    </button>
                                )}
                                {(work.status === 'DRAFT' || work.status === 'PUBLISHED') && (
                                    <button
                                        onClick={() => handleCancel(work.id)}
                                        className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors tooltip"
                                        title="取消工作"
                                    >
                                        <XCircle size={20} />
                                    </button>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            )}

            <WorkDetailDrawer
                workId={selectedWorkId}
                isOpen={isDetailOpen}
                onClose={() => setIsDetailOpen(false)}
            />
        </div>
    );
};

export default WorkList;
