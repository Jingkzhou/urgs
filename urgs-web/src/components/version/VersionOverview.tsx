import React, { useEffect, useState } from 'react';
import { BarChart3, GitBranch, Server, Clock, TrendingUp, AlertCircle, CheckCircle2, Package } from 'lucide-react';
import { getOverviewStats } from '../../api/version';

interface OverviewStats {
    totalApps: number;
    totalReleases: number;
    thisMonthReleases: number;
    pendingReleases: number;
    successRate: number;
    recentReleases: {
        id: number;
        appName: string;
        version: string;
        releaseDate: string;
        status: string;
    }[];
}

const VersionOverview: React.FC = () => {
    const [stats, setStats] = useState<OverviewStats | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        setLoading(true);
        try {
            const data = await getOverviewStats();
            setStats(data);
        } catch (error) {
            console.error('Failed to fetch overview stats:', error);
        } finally {
            setLoading(false);
        }
    };

    const statCards = stats ? [
        { label: '应用系统', value: stats.totalApps, icon: Server, color: 'blue', suffix: '个' },
        { label: '累计发布', value: stats.totalReleases, icon: Package, color: 'green', suffix: '次' },
        { label: '本月发布', value: stats.thisMonthReleases, icon: TrendingUp, color: 'purple', suffix: '次' },
        { label: '待发布', value: stats.pendingReleases, icon: Clock, color: 'orange', suffix: '项' },
    ] : [];

    const getStatusBadge = (status: string) => {
        switch (status) {
            case 'success':
                return <span className="px-2 py-1 text-xs rounded-full bg-green-100 text-green-700 flex items-center gap-1"><CheckCircle2 size={12} />成功</span>;
            case 'pending':
                return <span className="px-2 py-1 text-xs rounded-full bg-yellow-100 text-yellow-700 flex items-center gap-1"><Clock size={12} />进行中</span>;
            case 'failed':
                return <span className="px-2 py-1 text-xs rounded-full bg-red-100 text-red-700 flex items-center gap-1"><AlertCircle size={12} />失败</span>;
            default:
                return <span className="px-2 py-1 text-xs rounded-full bg-slate-100 text-slate-600">{status}</span>;
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* 统计卡片 */}
            <div className="grid grid-cols-4 gap-4">
                {statCards.map((card, idx) => {
                    const Icon = card.icon;
                    const colorClasses: Record<string, string> = {
                        blue: 'bg-blue-50 text-blue-600 border-blue-100',
                        green: 'bg-green-50 text-green-600 border-green-100',
                        purple: 'bg-purple-50 text-purple-600 border-purple-100',
                        orange: 'bg-orange-50 text-orange-600 border-orange-100',
                    };
                    return (
                        <div key={idx} className={`p-5 rounded-xl border ${colorClasses[card.color]} transition-all hover:shadow-md`}>
                            <div className="flex items-center justify-between">
                                <div>
                                    <p className="text-sm text-slate-500 mb-1">{card.label}</p>
                                    <p className="text-3xl font-bold">{card.value}<span className="text-sm font-normal ml-1">{card.suffix}</span></p>
                                </div>
                                <div className={`p-3 rounded-lg ${colorClasses[card.color]}`}>
                                    <Icon size={24} />
                                </div>
                            </div>
                        </div>
                    );
                })}
            </div>



            {/* 近期发布 */}
            <div className="bg-white rounded-xl border border-slate-200">
                <div className="px-5 py-4 border-b border-slate-100 flex items-center gap-2">
                    <GitBranch className="text-slate-500" size={18} />
                    <h3 className="font-semibold text-slate-800">近期发布</h3>
                </div>
                <div className="divide-y divide-slate-100">
                    {stats?.recentReleases.map(release => (
                        <div key={release.id} className="px-5 py-3 flex items-center justify-between hover:bg-slate-50 transition-colors">
                            <div className="flex items-center gap-4">
                                <div className="w-10 h-10 bg-slate-100 rounded-lg flex items-center justify-center">
                                    <Package className="text-slate-500" size={18} />
                                </div>
                                <div>
                                    <p className="font-medium text-slate-800">{release.appName}</p>
                                    <p className="text-sm text-slate-500">{release.version}</p>
                                </div>
                            </div>
                            <div className="flex items-center gap-4">
                                <span className="text-sm text-slate-500">{release.releaseDate}</span>
                                {getStatusBadge(release.status)}
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default VersionOverview;
