import React, { useEffect, useState } from 'react';
import {
    BarChart3, GitBranch, Server, Clock, TrendingUp, AlertCircle,
    CheckCircle2, Package, Terminal as TerminalIcon, Cpu, Activity,
    Hash, ArrowUpRight, Zap, Database, Globe
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
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

// --- Sub-components ---

interface StatCardProps {
    label: string;
    value: number | string;
    suffix?: string;
    icon: React.ElementType;
    color: string; // e.g., 'blue', 'emerald'
    bgClass: string;
    textClass: string;
    delay?: number;
}

const StatCard: React.FC<StatCardProps> = ({ label, value, suffix, icon: Icon, color, bgClass, textClass, delay = 0 }) => (
    <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay, duration: 0.4 }}
        className="bg-white/80 backdrop-blur-md p-5 rounded-2xl border border-white/20 shadow-sm hover:shadow-lg hover:-translate-y-1 transition-all duration-300 relative overflow-hidden group"
    >
        <div className={`absolute -right-4 -top-4 opacity-[0.05] group-hover:opacity-10 transition-opacity duration-300 transform rotate-12 scale-150 p-4 rounded-full ${bgClass}`}>
            <Icon size={80} className={textClass} />
        </div>

        <div className="flex justify-between items-start relative z-10">
            <div>
                <p className="font-bold text-[11px] text-slate-400 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                    {label}
                </p>
                <div className="text-3xl font-black text-slate-800 tracking-tight flex items-baseline gap-1">
                    <AnimatedCounter value={typeof value === 'number' ? value : 0} />
                    {suffix && <span className="text-sm font-bold text-slate-400">{suffix}</span>}
                </div>
            </div>
            <div className={`p-3 rounded-xl ${bgClass} ${textClass} shadow-inner`}>
                <Icon size={20} className="stroke-[2.5px]" />
            </div>
        </div>

        {/* Simple Sparkline simulation */}
        <div className="mt-4 flex gap-1 items-end h-1.5 opacity-50">
            {[40, 70, 50, 90, 60, 80].map((h, i) => (
                <div
                    key={i}
                    className={`flex-1 rounded-full ${textClass.replace('text-', 'bg-')}`}
                    style={{ height: `${h}%`, opacity: 0.3 + (i * 0.1) }}
                />
            ))}
        </div>
    </motion.div>
);

const AnimatedCounter = ({ value }: { value: number }) => {
    return (
        <motion.span
            initial={{ opacity: 0, y: 5 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
        >
            {value}
        </motion.span>
    );
};

const StatusBadge = ({ status }: { status: string }) => {
    const config = {
        success: { color: 'emerald', icon: CheckCircle2, text: '发布成功' },
        pending: { color: 'amber', icon: Clock, text: '处理中' },
        failed: { color: 'rose', icon: AlertCircle, text: '发布失败' },
        default: { color: 'slate', icon: Activity, text: status }
    };

    const type = (status in config ? status : 'default') as keyof typeof config;
    const { color, icon: Icon, text } = config[type];

    // Tailwind dynamic classes workaround or just map explicitly
    const colorClasses = {
        emerald: 'bg-emerald-50 text-emerald-700 border-emerald-100',
        amber: 'bg-amber-50 text-amber-700 border-amber-100',
        rose: 'bg-rose-50 text-rose-700 border-rose-100',
        slate: 'bg-slate-50 text-slate-600 border-slate-100'
    };

    return (
        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg border text-[11px] font-bold ${colorClasses[color as keyof typeof colorClasses]}`}>
            <Icon size={12} className="stroke-[2.5px]" />
            {text}
        </span>
    );
};

const ResourceBar = ({ label, value, colorClass }: { label: string, value: number, colorClass: string }) => (
    <div className="group">
        <div className="flex justify-between text-xs font-bold text-slate-600 mb-2 group-hover:text-slate-800 transition-colors">
            <span>{label}</span>
            <span className="font-mono">{value}%</span>
        </div>
        <div className="h-2 bg-slate-100 rounded-full overflow-hidden border border-slate-100/50">
            <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${value}%` }}
                transition={{ duration: 1, ease: 'easeOut' }}
                className={`h-full rounded-full ${colorClass} shadow-[0_0_10px_rgba(0,0,0,0.1)]`}
            />
        </div>
    </div>
);

// --- Main Component ---

const VersionOverview: React.FC = () => {
    const [stats, setStats] = useState<OverviewStats | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        setLoading(true);
        try {
            await new Promise(resolve => setTimeout(resolve, 800)); // Slightly longer for dramatic effect
            const data = await getOverviewStats();
            setStats(data);
        } catch (error) {
            console.error('Failed to fetch overview stats:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="min-h-[60vh] flex flex-col items-center justify-center space-y-6">
                <div className="relative">
                    <div className="w-16 h-16 rounded-2xl bg-blue-500/20 animate-ping absolute inset-0" />
                    <div className="w-16 h-16 rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center shadow-xl shadow-blue-200">
                        <Activity className="text-white animate-pulse" size={32} />
                    </div>
                </div>
                <div className="flex flex-col items-center gap-2">
                    <h3 className="text-slate-800 font-bold text-lg">正在连接控制台...</h3>
                    <p className="font-mono text-xs text-slate-400">ESTABLISHING SECURE CONNECTION</p>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-8 animate-fade-in max-w-[1600px] mx-auto p-1">
            {/* Header Section */}
            <header className="flex flex-col md:flex-row md:items-end justify-between gap-6 pb-2 border-b border-slate-100/60 pb-6">
                <div className="space-y-2">
                    <motion.div
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        className="flex items-center gap-2"
                    >
                        <span className="flex h-2 w-2 rounded-full bg-emerald-500 shadow-[0_0_8px_2px_rgba(16,185,129,0.3)] animate-pulse" />
                        <span className="text-[10px] font-extrabold uppercase tracking-widest text-slate-400">
                            System Operational
                        </span>
                    </motion.div>
                    <h1 className="text-4xl font-black text-slate-800 tracking-tight flex items-center gap-3">
                        系统概览
                        <span className="text-blue-500 text-5xl leading-none">.</span>
                    </h1>
                    <p className="text-slate-500 font-medium max-w-xl text-lg">
                        实时监控应用状态，追踪版本发布与系统健康度。
                    </p>
                </div>

                <div className="hidden sm:block text-right bg-slate-50/50 p-4 rounded-2xl border border-slate-100 backdrop-blur-sm">
                    <div className="flex items-center justify-end gap-2 mb-1">
                        <span className="text-emerald-500"><CheckCircle2 size={14} /></span>
                        <p className="font-mono text-xs font-bold text-slate-600 uppercase tracking-wider">
                            Uptime 99.98%
                        </p>
                    </div>
                    <p className="font-mono text-[10px] text-slate-400">
                        LAST UPDATED: {new Date().toLocaleTimeString()}
                    </p>
                </div>
            </header>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {stats && [
                    { label: '活跃系统', value: stats.totalApps, suffix: '个', icon: Server, color: 'blue', bg: 'bg-blue-50', text: 'text-blue-600' },
                    { label: '累计发布', value: stats.totalReleases, suffix: '次', icon: Package, color: 'indigo', bg: 'bg-indigo-50', text: 'text-indigo-600' },
                    { label: '本月增速', value: stats.thisMonthReleases, suffix: '次', icon: Zap, color: 'violet', bg: 'bg-violet-50', text: 'text-violet-600' },
                    { label: '待审批', value: stats.pendingReleases, suffix: '项', icon: Clock, color: 'amber', bg: 'bg-amber-50', text: 'text-amber-600' },
                ].map((item, idx) => (
                    <StatCard
                        key={idx}
                        label={item.label}
                        value={item.value}
                        suffix={item.suffix}
                        icon={item.icon}
                        color={item.color}
                        bgClass={item.bg}
                        textClass={item.text}
                        delay={idx * 0.1}
                    />
                ))}
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Recent Releases Table (2/3 width) */}
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.4 }}
                    className="lg:col-span-2 bg-white rounded-[2rem] border border-slate-100 shadow-xl shadow-slate-200/40 overflow-hidden flex flex-col"
                >
                    <div className="px-8 py-6 border-b border-slate-100 flex items-center justify-between bg-gradient-to-r from-white to-slate-50/50">
                        <div className="flex items-center gap-3">
                            <div className="p-2 bg-slate-100 rounded-lg text-slate-500">
                                <TerminalIcon size={18} />
                            </div>
                            <div>
                                <h3 className="font-bold text-base text-slate-800">发布日志流</h3>
                                <p className="text-xs text-slate-400 font-medium">RECENT DEPLOYMENT ACTIVITY</p>
                            </div>
                        </div>
                        <div className="flex gap-2">
                            <div className="h-2 w-2 rounded-full bg-rose-400/80" />
                            <div className="h-2 w-2 rounded-full bg-amber-400/80" />
                            <div className="h-2 w-2 rounded-full bg-emerald-400/80" />
                        </div>
                    </div>

                    <div className="flex-1 overflow-x-auto">
                        <table className="w-full text-left">
                            <thead className="bg-slate-50/80 text-slate-500 font-bold text-[11px] uppercase tracking-wider border-b border-slate-100 sticky top-0 backdrop-blur-sm z-10">
                                <tr>
                                    <th className="px-8 py-4 w-20">ID</th>
                                    <th className="px-6 py-4">系统 / 制品</th>
                                    <th className="px-6 py-4">版本号</th>
                                    <th className="px-6 py-4">发布时间</th>
                                    <th className="px-8 py-4 text-right">状态</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-50">
                                {stats?.recentReleases.map((release, i) => (
                                    <motion.tr
                                        key={release.id}
                                        initial={{ opacity: 0, x: -10 }}
                                        animate={{ opacity: 1, x: 0 }}
                                        transition={{ delay: 0.5 + (i * 0.05) }}
                                        className="hover:bg-blue-50/30 transition-colors group"
                                    >
                                        <td className="px-8 py-4 text-slate-400 text-xs font-mono">#{release.id}</td>
                                        <td className="px-6 py-4">
                                            <div className="flex items-center gap-3">
                                                <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center text-slate-400 group-hover:bg-blue-100 group-hover:text-blue-600 transition-colors">
                                                    <Package size={16} />
                                                </div>
                                                <span className="font-bold text-slate-700 text-sm">{release.appName}</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className="bg-slate-100 border border-slate-200 text-slate-600 px-2 py-1 rounded-md text-[11px] font-mono font-bold">
                                                {release.version}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 text-xs font-medium">
                                            {release.releaseDate}
                                        </td>
                                        <td className="px-8 py-4 text-right">
                                            <div className="flex justify-end">
                                                <StatusBadge status={release.status} />
                                            </div>
                                        </td>
                                    </motion.tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </motion.div>

                {/* Side Panel (1/3 width) */}
                <motion.div
                    initial={{ opacity: 0, y: 30 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.5 }}
                    className="space-y-6"
                >
                    {/* System Resources */}
                    <div className="bg-white rounded-[2rem] border border-slate-100 shadow-lg p-6 relative overflow-hidden">
                        <div className="flex items-center justify-between mb-6">
                            <h4 className="text-sm font-bold text-slate-800 flex items-center gap-2">
                                <Cpu size={18} className="text-slate-400" />
                                系统负载
                            </h4>
                            <span className="px-2 py-0.5 bg-emerald-50 text-emerald-600 text-[10px] font-extrabold rounded-full border border-emerald-100">
                                NORMAL
                            </span>
                        </div>

                        <div className="space-y-6 relative z-10">
                            <ResourceBar label="CPU Usage" value={42} colorClass="bg-gradient-to-r from-emerald-400 to-emerald-500" />
                            <ResourceBar label="Memory" value={68} colorClass="bg-gradient-to-r from-blue-400 to-blue-500" />
                            <ResourceBar label="Storage I/O" value={12} colorClass="bg-gradient-to-r from-amber-400 to-amber-500" />
                        </div>

                        <div className="mt-8 pt-6 border-t border-slate-50">
                            <button className="w-full py-3 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold uppercase tracking-wider rounded-xl transition-all shadow-lg shadow-slate-900/20 flex items-center justify-center gap-2 group">
                                <Activity size={14} className="group-hover:animate-pulse" />
                                完整诊断报告
                            </button>
                        </div>
                    </div>

                    {/* Latest Commit Card */}
                    <div className="bg-gradient-to-br from-blue-600 to-indigo-700 rounded-[2rem] p-6 text-white shadow-xl shadow-blue-200 relative overflow-hidden">
                        {/* Decorative Patterns */}
                        <div className="absolute top-0 right-0 p-4 opacity-10 transform translate-x-1/3 -translate-y-1/3">
                            <GitBranch size={120} />
                        </div>

                        <div className="relative z-10">
                            <div className="flex items-center gap-2 mb-4 opacity-80">
                                <GitBranch size={16} />
                                <span className="text-xs font-bold uppercase tracking-wider">Latest Commit</span>
                            </div>

                            <p className="font-medium text-lg mb-4 leading-relaxed">
                                <span className="bg-white/20 px-1.5 py-0.5 rounded text-sm font-bold mr-1.5">feat(core)</span>
                                优化数据库连接池配置参数，提升并发处理能力
                            </p>

                            <div className="flex items-center justify-between mt-6 pt-4 border-t border-white/10">
                                <div className="flex items-center gap-2 text-xs font-mono opacity-60">
                                    <Hash size={12} />
                                    master • 2d8f9a2
                                </div>
                                <span className="text-xs font-bold bg-white/10 px-2 py-1 rounded-lg backdrop-blur-sm">
                                    2 mins ago
                                </span>
                            </div>
                        </div>
                    </div>
                </motion.div>
            </div>
        </div>
    );
};

export default VersionOverview;
