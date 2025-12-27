import React, { useEffect, useState } from 'react';
import { X, GitBranch, ArrowUpCircle, AlertTriangle, Clock, CheckCircle2 } from 'lucide-react';
import { getAppVersionMatrix, getAppActiveBranches } from '../../api/version';

interface AppSystemDetailProps {
    system: any;
    onClose: () => void;
}

const AppSystemDetail: React.FC<AppSystemDetailProps> = ({ system, onClose }) => {
    const [matrix, setMatrix] = useState<any[]>([]);
    const [branches, setBranches] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchData = async () => {
            setLoading(true);
            try {
                const [matrixData, branchData] = await Promise.all([
                    getAppVersionMatrix(system.id),
                    getAppActiveBranches(system.id)
                ]);
                setMatrix(matrixData);
                setBranches(branchData);
            } catch (error) {
                console.error('Failed to fetch details', error);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, [system.id]);

    return (
        <div className="fixed inset-0 bg-slate-900/50 flex justify-end z-50 animate-fade-in" onClick={onClose}>
            <div className="w-[600px] bg-white h-full shadow-2xl overflow-y-auto animate-slide-in-right" onClick={e => e.stopPropagation()}>
                {/* Header */}
                <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between sticky top-0 bg-white z-10">
                    <div>
                        <h2 className="text-xl font-bold text-slate-800">{system.name}</h2>
                        <p className="text-xs text-slate-500 mt-1">系统详情与研发治理</p>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-full transition-colors">
                        <X size={20} className="text-slate-500" />
                    </button>
                </div>

                <div className="p-6 space-y-8">
                    {loading ? (
                        <div className="text-center py-10 text-slate-500">加载中...</div>
                    ) : (
                        <>
                            {/* Environment Matrix */}
                            <section>
                                <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wide mb-4 flex items-center gap-2">
                                    <Clock size={16} className="text-blue-500" /> 环境版本矩阵
                                </h3>
                                <div className="bg-slate-50 rounded-xl border border-slate-200 overflow-hidden">
                                    <table className="w-full text-sm">
                                        <thead>
                                            <tr className="border-b border-slate-200 text-slate-500 text-left bg-slate-100/50">
                                                <th className="px-4 py-3 font-medium">环境</th>
                                                <th className="px-4 py-3 font-medium">当前版本</th>
                                                <th className="px-4 py-3 font-medium">部署时间</th>
                                                <th className="px-4 py-3 font-medium w-24">当前状态</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-slate-200">
                                            {matrix.map((row) => (
                                                <tr key={row.envName} className="hover:bg-white transition-colors">
                                                    <td className="px-4 py-3 font-semibold text-slate-700">{row.envName}</td>
                                                    <td className="px-4 py-3 font-mono text-blue-600">
                                                        {row.version}
                                                        {row.commitLag > 0 && row.envName !== 'SIT' && (
                                                            <span className="ml-2 inline-flex items-center gap-0.5 text-[10px] bg-orange-100 text-orange-700 px-1.5 py-0.5 rounded-full">
                                                                <ArrowUpCircle size={10} /> 落后 {row.commitLag}
                                                            </span>
                                                        )}
                                                    </td>
                                                    <td className="px-4 py-3 text-slate-500 text-xs">{row.deployTime}</td>
                                                    <td className="px-4 py-3">
                                                        {row.status === 'SUCCESS' ? (
                                                            <span className="text-green-600 flex items-center gap-1 text-xs"><CheckCircle2 size={12} /> 正常</span>
                                                        ) : (
                                                            <span className="text-slate-400 text-xs">{row.status}</span>
                                                        )}
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </section>

                            {/* Branch Governance */}
                            <section>
                                <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wide mb-4 flex items-center gap-2">
                                    <GitBranch size={16} className="text-purple-500" /> 分支治理
                                </h3>
                                <div className="space-y-3">
                                    {branches.map((branch, idx) => (
                                        <div key={idx} className="flex items-center justify-between p-3 rounded-lg border border-slate-200 hover:border-slate-300 transition-colors">
                                            <div className="flex items-center gap-3">
                                                <div className={`w-8 h-8 rounded-full flex items-center justify-center ${branch.status === 'STALE' ? 'bg-red-50 text-red-500' : 'bg-purple-50 text-purple-600'}`}>
                                                    <GitBranch size={16} />
                                                </div>
                                                <div>
                                                    <p className="font-medium text-slate-800 text-sm">{branch.branchName}</p>
                                                    <p className="text-xs text-slate-500">
                                                        {branch.author} · 最后提交 {branch.lastCommitTime}
                                                    </p>
                                                </div>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                {branch.behindCount > 0 && (
                                                    <span className="text-[10px] px-2 py-1 bg-yellow-50 text-yellow-700 rounded border border-yellow-100">
                                                        落后 {branch.behindCount}
                                                    </span>
                                                )}
                                                {branch.status === 'STALE' && (
                                                    <span className="text-[10px] px-2 py-1 bg-red-50 text-red-700 rounded border border-red-100 flex items-center gap-1">
                                                        <AlertTriangle size={10} /> 僵尸分支
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </section>
                        </>
                    )}
                </div>
            </div>
        </div>
    );
};

export default AppSystemDetail;
