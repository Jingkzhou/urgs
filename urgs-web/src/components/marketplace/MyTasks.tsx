import React, { useState, useEffect } from 'react';
import { getMyTasks, updateTaskStatus, WorkTask } from '../../api/marketplace';
import { CheckCircle, Clock } from 'lucide-react';

const MyTasks: React.FC = () => {
    const [tasks, setTasks] = useState<WorkTask[]>([]);
    const [loading, setLoading] = useState(false);

    const fetchTasks = async () => {
        setLoading(true);
        try {
            const res = await getMyTasks({ current: 1, size: 20 });
            if (res?.records) {
                setTasks(res.records);
            }
        } catch (error) {
            console.error('Failed to fetch my tasks', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTasks();
    }, []);

    const handleUpdateStatus = async (id: string, newStatus: string) => {
        try {
            await updateTaskStatus(id, newStatus);
            fetchTasks();
        } catch (error) {
            alert("更新状态失败");
        }
    };

    return (
        <div className="h-full flex flex-col p-6 overflow-y-auto">
            <div className="mb-6">
                <h2 className="text-xl font-bold text-slate-800">我的任务</h2>
                <p className="text-sm text-slate-500 mt-1">您领取或被指派的任务列表</p>
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
                                <h3 className="font-bold text-slate-800">{task.title}</h3>
                                <span className={`px-2 py-0.5 rounded text-xs font-bold uppercase ${task.status === 'COMPLETED' ? 'bg-green-100 text-green-700' :
                                    task.status === 'IN_PROGRESS' ? 'bg-blue-100 text-blue-700' :
                                        task.status === 'REVIEW' ? 'bg-orange-100 text-orange-700' : 'bg-slate-100 text-slate-600'
                                    }`}>
                                    {task.status}
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
                                        <button
                                            onClick={() => handleUpdateStatus(task.id, 'IN_PROGRESS')}
                                            className="px-3 py-1 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded text-xs font-bold transition-colors"
                                        >
                                            开始开发
                                        </button>
                                    )}
                                    {task.status === 'IN_PROGRESS' && (
                                        <button
                                            onClick={() => handleUpdateStatus(task.id, 'REVIEW')}
                                            className="px-3 py-1 bg-red-600 text-white hover:bg-red-700 rounded text-xs font-bold transition-colors flex items-center gap-1"
                                        >
                                            <CheckCircle size={14} /> 提交审核
                                        </button>
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
        </div>
    );
};

export default MyTasks;
