import React, { useState, useEffect } from 'react';
import { getDeveloperKpis, DeveloperKpiVO } from '../../api/version';
import { Trophy, Activity, GitCommit, FileText, Bug } from 'lucide-react';

const ReleaseStats: React.FC = () => {
    const [kpis, setKpis] = useState<DeveloperKpiVO[]>([]);
    const [loading, setLoading] = useState(false);

    const fetchKpis = async () => {
        setLoading(true);
        try {
            const data = await getDeveloperKpis();
            // Sort by score desc by default
            const sorted = (data || []).sort((a, b) => (b.averageCodeScore || 0) - (a.averageCodeScore || 0));
            setKpis(sorted);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchKpis();
    }, []);

    return (
        <div className="p-4">
            <div className="mb-6 flex items-center justify-between">
                <div>
                    <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2">
                        <Trophy className="text-amber-500" />
                        团队绩效统计
                    </h2>
                    <p className="text-sm text-slate-500 mt-1">根据代码提交与 AI 审查评分自动生成的开发质量报表</p>
                </div>
                <div className="flex gap-4">
                    <div className="bg-white px-4 py-2 rounded-lg border border-slate-200 shadow-sm text-center">
                        <div className="text-xs text-slate-400">Total Commits</div>
                        <div className="text-lg font-bold text-slate-800">
                            {kpis.reduce((acc, curr) => acc + (curr.totalCommits || 0), 0)}
                        </div>
                    </div>
                    <div className="bg-white px-4 py-2 rounded-lg border border-slate-200 shadow-sm text-center">
                        <div className="text-xs text-slate-400">Active Devs</div>
                        <div className="text-lg font-bold text-slate-800">{kpis.length}</div>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {kpis.map((kpi, index) => (
                    <div key={kpi.userId} className="bg-white rounded-xl border border-slate-200 shadow-sm p-6 relative overflow-hidden">
                        {index < 3 && (
                            <div className={`absolute top-0 right-0 px-3 py-1 text-xs font-bold text-white rounded-bl-lg
                                ${index === 0 ? 'bg-amber-400' : index === 1 ? 'bg-slate-400' : 'bg-amber-700'}
                            `}>
                                TOP {index + 1}
                            </div>
                        )}

                        <div className="flex items-center gap-4 mb-6">
                            <div className="w-12 h-12 rounded-full bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-xl">
                                {kpi.name ? kpi.name.charAt(0) : '?'}
                            </div>
                            <div>
                                <h3 className="font-bold text-slate-800">{kpi.name}</h3>
                                <p className="text-xs text-slate-400">{kpi.email}</p>
                            </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-1">
                                <div className="text-xs text-slate-400 flex items-center gap-1">
                                    <GitCommit size={12} /> Commits
                                </div>
                                <div className="text-lg font-semibold text-slate-700">{kpi.totalCommits}</div>
                            </div>
                            <div className="space-y-1">
                                <div className="text-xs text-slate-400 flex items-center gap-1">
                                    <FileText size={12} /> Reviews
                                </div>
                                <div className="text-lg font-semibold text-slate-700">{kpi.totalReviews}</div>
                            </div>
                            <div className="space-y-1">
                                <div className="text-xs text-slate-400 flex items-center gap-1">
                                    <Activity size={12} /> Quality Score
                                </div>
                                <div className={`text-lg font-semibold ${kpi.averageCodeScore >= 90 ? 'text-green-600' :
                                        kpi.averageCodeScore >= 75 ? 'text-amber-600' : 'text-red-600'
                                    }`}>
                                    {kpi.averageCodeScore ? kpi.averageCodeScore.toFixed(1) : '-'}
                                </div>
                            </div>
                            <div className="space-y-1">
                                <div className="text-xs text-slate-400 flex items-center gap-1">
                                    <Bug size={12} /> Bugs
                                </div>
                                <div className="text-lg font-semibold text-slate-700">{kpi.bugCount}</div>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {loading && (
                <div className="text-center py-10 text-slate-400">Loading KPIs...</div>
            )}
        </div>
    );
};

export default ReleaseStats;
