import React, { useEffect, useState } from 'react';
import { BarChart3, GitBranch, Server, Clock, TrendingUp, AlertCircle, CheckCircle2, Package, Terminal as TerminalIcon, Cpu, Activity, Hash, ArrowUpRight } from 'lucide-react';
import { motion } from 'framer-motion';
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
            // Simulate delay for effect
            await new Promise(resolve => setTimeout(resolve, 600));
            const data = await getOverviewStats();
            setStats(data);
        } catch (error) {
            console.error('Failed to fetch overview stats:', error);
        } finally {
            setLoading(false);
        }
    };

    const AnimatedCounter = ({ value, suffix = '' }: { value: number, suffix?: string }) => {
        return (
            <span className="flex items-baseline">
                <motion.span
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, type: 'spring' }}
                >
                    {value}
                </motion.span>
                <span className="text-sm font-normal ml-1 opacity-60 text-slate-500">{suffix}</span>
            </span>
        );
    };

    const statCards = stats ? [
        { label: '活跃系统', value: stats.totalApps, icon: Server, color: 'blue', suffix: '个' },
        { label: '累计发布', value: stats.totalReleases, icon: Package, color: 'emerald', suffix: '次' },
        { label: '本月增速', value: stats.thisMonthReleases, icon: TrendingUp, color: 'indigo', suffix: '次' },
        { label: '待审批', value: stats.pendingReleases, icon: Clock, color: 'amber', suffix: '项' },
    ] : [];

    const getStatusIndicator = (status: string) => {
        switch (status) {
            case 'success':
                return <span className="text-emerald-700 font-mono text-[10px] uppercase font-bold tracking-wider flex items-center gap-1"><span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse"></span>成功</span>;
            case 'pending':
                return <span className="text-amber-700 font-mono text-[10px] uppercase font-bold tracking-wider flex items-center gap-1"><span className="w-1.5 h-1.5 bg-amber-500 rounded-full animate-pulse"></span>处理中</span>;
            case 'failed':
                return <span className="text-red-700 font-mono text-[10px] uppercase font-bold tracking-wider flex items-center gap-1"><span className="w-1.5 h-1.5 bg-red-500 rounded-full animate-ping"></span>失败</span>;
            default:
                return <span className="text-slate-500 font-mono text-[10px] uppercase font-bold tracking-wider">{status}</span>;
        }
    };

    if (loading) {
        return (
            <div className="h-full flex flex-col items-center justify-center space-y-4">
                <div className="relative w-16 h-16">
                    <motion.span
                        className="absolute inset-0 border-4 border-slate-100 border-t-blue-500 rounded-full"
                        animate={{ rotate: 360 }}
                        transition={{ repeat: Infinity, duration: 1, ease: 'linear' }}
                    />
                </div>
                <div className="font-mono text-xs text-slate-400 animate-pulse">
                    正在初始化系统数据...
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-8 animate-fade-in max-w-7xl mx-auto">
            {/* Header Identity */}
            <div className="flex items-end justify-between border-b-2 border-slate-100 pb-4">
                <div>
                    <h1 className="text-2xl font-black text-slate-800 tracking-tight flex items-center gap-2">
                        <Activity className="text-blue-600" />
                        系统概览
                    </h1>
                    <p className="font-mono text-xs text-slate-400 mt-1 pl-1">
                        DASHBOARD // V.2.4.0 // CONNECTED
                    </p>
                </div>
                <div className="hidden sm:block text-right">
                    <p className="font-mono text-xs font-bold text-slate-500">
                        正常运行时间: <span className="text-emerald-600">99.98%</span>
                    </p>
                    <p className="font-mono text-[10px] text-slate-400">
                        最后更新: {new Date().toLocaleTimeString()}
                    </p>
                </div>
            </div>

            {/* HUD Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {statCards.map((card, idx) => {
                    const Icon = card.icon;
                    return (
                        <motion.div
                            key={idx}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: idx * 0.1 }}
                            className="bg-white p-5 rounded-lg border border-slate-200 relative overflow-hidden group hover:border-blue-400 hover:shadow-lg transition-all"
                        >
                            {/* Decorative Background Metrics */}
                            <div className="absolute right-2 top-2 opacity-[0.03] pointer-events-none transform rotate-12 scale-150">
                                <Icon size={64} className="text-slate-900" />
                            </div>

                            <div className="flex justify-between items-start relative z-10">
                                <div>
                                    <p className="font-mono text-[10px] text-slate-500 font-bold uppercase tracking-widest mb-1">
                                        {card.label}
                                    </p>
                                    <div className="text-4xl font-black text-slate-800 tracking-tighter">
                                        <AnimatedCounter value={card.value} suffix={card.suffix} />
                                    </div>
                                </div>
                                <div className={`p-2 rounded-lg bg-${card.color}-50 text-${card.color}-600`}>
                                    <Icon size={20} />
                                </div>
                            </div>

                            {/* Micro-sparkline or bar (simulated) */}
                            <div className="mt-4 flex gap-1">
                                {Array.from({ length: 6 }).map((_, i) => (
                                    <div key={i} className={`h-1.5 w-full rounded-sm ${i < 4 ? `bg-${card.color}-500 opacity-80` : 'bg-slate-100'}`} />
                                ))}
                            </div>
                        </motion.div>
                    );
                })}
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Terminal Stream (Recent Releases) */}
                <div className="lg:col-span-2 bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
                    <div className="px-5 py-3 border-b border-slate-100 bg-slate-50/50 flex items-center justify-between">
                        <div className="flex items-center gap-2">
                            <TerminalIcon className="text-slate-400" size={16} />
                            <h3 className="font-bold text-sm text-slate-700 font-mono uppercase">发布日志流</h3>
                        </div>
                        <div className="flex gap-1.5">
                            <div className="w-2.5 h-2.5 rounded-full bg-slate-200"></div>
                            <div className="w-2.5 h-2.5 rounded-full bg-slate-200"></div>
                        </div>
                    </div>

                    <div className="font-mono text-sm max-h-[400px] overflow-y-auto">
                        <table className="w-full text-left">
                            <thead className="bg-[#F8FAFC] text-slate-500 font-bold text-[10px] uppercase tracking-wider border-b border-slate-200 sticky top-0">
                                <tr>
                                    <th className="px-5 py-3 w-16">ID</th>
                                    <th className="px-5 py-3">系统/制品</th>
                                    <th className="px-5 py-3">版本号</th>
                                    <th className="px-5 py-3">时间戳</th>
                                    <th className="px-5 py-3 text-right">状态</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100 bg-white">
                                {stats?.recentReleases.map((release, i) => (
                                    <motion.tr
                                        key={release.id}
                                        initial={{ opacity: 0, x: -10 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        transition={{ delay: i * 0.05 }}
                                        className="hover:bg-slate-50 transition-colors group cursor-default"
                                    >
                                        <td className="px-5 py-3 text-slate-400 text-xs">#{release.id}</td>
                                        <td className="px-5 py-3 font-semibold text-slate-700 flex items-center gap-2">
                                            <Package size={14} className="text-slate-400" />
                                            {release.appName}
                                        </td>
                                        <td className="px-5 py-3">
                                            <span className="px-2 py-0.5 bg-slate-100 rounded text-[10px] font-bold text-slate-600 border border-slate-200">
                                                {release.version}
                                            </span>
                                        </td>
                                        <td className="px-5 py-3 text-slate-500 text-xs">{release.releaseDate}</td>
                                        <td className="px-5 py-3 text-right">
                                            <div className="flex justify-end">
                                                {getStatusIndicator(release.status)}
                                            </div>
                                        </td>
                                    </motion.tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* System Diagnostics / Side Panel */}
                <div className="space-y-4">
                    <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm relative overflow-hidden group">
                        <h4 className="text-xs font-mono font-bold text-slate-500 uppercase tracking-widest mb-4 flex items-center gap-2">
                            <Cpu size={14} /> 核心指标
                        </h4>

                        <div className="space-y-5">
                            <div>
                                <div className="flex justify-between text-xs font-bold text-slate-700 mb-1.5">
                                    <span>CPU 负载</span>
                                    <span className="text-emerald-600">42%</span>
                                </div>
                                <div className="h-2 bg-slate-100 rounded-full overflow-hidden border border-slate-200">
                                    <div className="h-full bg-emerald-500 w-[42%]" />
                                </div>
                            </div>
                            <div>
                                <div className="flex justify-between text-xs font-bold text-slate-700 mb-1.5">
                                    <span>内存使用</span>
                                    <span className="text-blue-600">68%</span>
                                </div>
                                <div className="h-2 bg-slate-100 rounded-full overflow-hidden border border-slate-200">
                                    <div className="h-full bg-blue-500 w-[68%]" />
                                </div>
                            </div>
                            <div>
                                <div className="flex justify-between text-xs font-bold text-slate-700 mb-1.5">
                                    <span>存储 I/O</span>
                                    <span className="text-amber-600">12%</span>
                                </div>
                                <div className="h-2 bg-slate-100 rounded-full overflow-hidden border border-slate-200">
                                    <div className="h-full bg-amber-500 w-[12%]" />
                                </div>
                            </div>
                        </div>

                        <button className="mt-8 w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold uppercase tracking-wider rounded-lg transition-colors flex items-center justify-center gap-2 shadow-lg shadow-slate-900/10">
                            运行诊断 <ArrowUpRight size={14} />
                        </button>
                    </div>

                    <div className="bg-gradient-to-br from-white to-blue-50 p-5 rounded-xl border border-blue-100 shadow-sm">
                        <h4 className="text-xs font-bold text-blue-900 uppercase tracking-wide mb-3 flex items-center gap-2">
                            <BadgeIcon /> 最新提交
                        </h4>
                        <div className="p-3 bg-white border border-blue-100 rounded-lg text-xs text-slate-600 shadow-sm">
                            <span className="text-blue-600 font-bold bg-blue-50 px-1 rounded">feat(core):</span> 优化数据库连接池配置参数
                            <div className="mt-2 text-[10px] text-slate-400 flex items-center gap-1 font-mono">
                                <GitBranch size={10} /> master <span className="mx-1">•</span> 2d8f9a2
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

// Helper for icon
const BadgeIcon = () => (
    <div className="w-4 h-4 bg-blue-100 rounded flex items-center justify-center">
        <div className="w-1.5 h-1.5 bg-blue-600 rounded-full" />
    </div>
);

export default VersionOverview;
