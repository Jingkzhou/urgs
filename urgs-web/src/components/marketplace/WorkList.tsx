import React, { useState, useEffect } from 'react';
import { listWorks, publishWork, cancelWork, Work } from '../../api/marketplace';
import { Plus, Play, XCircle } from 'lucide-react';

const WorkList: React.FC = () => {
    const [works, setWorks] = useState<Work[]>([]);
    const [loading, setLoading] = useState(false);

    const fetchWorks = async () => {
        setLoading(true);
        try {
            const res = await listWorks({ current: 1, size: 20 });
            if (res.data?.records) {
                setWorks(res.data.records);
            }
        } catch (error) {
            console.error('Failed to fetch works', error);
        } finally {
            setLoading(false);
        }
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
        <div className="h-full flex flex-col p-6 overflow-y-auto">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-slate-800">我发布的工作</h2>
                <button
                    onClick={() => alert("创建工作表单即将上线")}
                    className="flex items-center gap-2 px-4 py-2 bg-slate-800 text-white rounded-lg hover:bg-slate-700 transition-colors text-sm font-bold"
                >
                    <Plus size={16} />新建工作
                </button>
            </div>

            {loading ? (
                <div className="text-center py-10 text-slate-400">加载中...</div>
            ) : works.length === 0 ? (
                <div className="text-center py-10 text-slate-400 bg-slate-50 rounded-2xl border border-dashed border-slate-200">
                    您还没有发布过工作，点击右上角新建一个吧。
                </div>
            ) : (
                <div className="space-y-4">
                    {works.map(work => (
                        <div key={work.id} className="bg-white border text-left border-slate-200 rounded-xl p-5 shadow-sm flex items-center justify-between">
                            <div>
                                <div className="flex items-center gap-3 mb-2">
                                    <h3 className="text-lg font-bold text-slate-800">{work.title}</h3>
                                    <span className={`px-2 py-0.5 rounded text-xs font-bold uppercase ${work.status === 'PUBLISHED' ? 'bg-green-100 text-green-700' :
                                            work.status === 'IN_PROGRESS' ? 'bg-blue-100 text-blue-700' :
                                                work.status === 'DRAFT' ? 'bg-slate-100 text-slate-600' : 'bg-red-100 text-red-600'
                                        }`}>
                                        {work.status}
                                    </span>
                                </div>
                                <div className="flex items-center gap-4 text-sm text-slate-500">
                                    <span>总积分: {work.totalPoints}</span>
                                    <span>优先级: <span className="text-red-500 font-medium">{work.priority}</span></span>
                                    <span>创建时间: {new Date(work.createTime).toLocaleDateString()}</span>
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
        </div>
    );
};

export default WorkList;
