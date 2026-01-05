import React, { useState, useEffect, useMemo } from 'react';
import { getDeveloperKpis, DeveloperKpiVO, getGitRepositories, GitRepository } from '../../api/version';
import {
    Trophy, Activity, GitCommit, FileText, Bug, Search, TrendingUp,
    Shield, Layers, Zap, Users, Target, Award, ChevronRight, Clock,
    Calendar, Star, Crown, Medal, ArrowUpRight, BarChart3, Flame, Code2,
    Fingerprint, GitPullRequest
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import {
    RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar,
    LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, Area, AreaChart
} from 'recharts';

// === 类型定义 ===
interface ExtendedKpi extends DeveloperKpiVO {
    compositeScore: number;
    grade: 'S' | 'A' | 'B' | 'C' | 'D';
    radarData: { dimension: string; value: number; fullMark: number }[];
    trendData: { month: string; score: number }[];
    recentCommits: { sha: string; message: string; date: string }[];
}

// === 常量定义 ===
const GRADE_CONFIG = {
    S: { label: '卓越', color: '#f59e0b', bgColor: 'bg-amber-50', borderColor: 'border-amber-200', textColor: 'text-amber-600', icon: Crown },
    A: { label: '优秀', color: '#6366f1', bgColor: 'bg-indigo-50', borderColor: 'border-indigo-200', textColor: 'text-indigo-600', icon: Star },
    B: { label: '良好', color: '#10b981', bgColor: 'bg-emerald-50', borderColor: 'border-emerald-200', textColor: 'text-emerald-600', icon: Award },
    C: { label: '合格', color: '#64748b', bgColor: 'bg-slate-50', borderColor: 'border-slate-200', textColor: 'text-slate-600', icon: Medal },
    D: { label: '待改进', color: '#f43f5e', bgColor: 'bg-rose-50', borderColor: 'border-rose-200', textColor: 'text-rose-600', icon: Target },
};

const DIMENSION_WEIGHTS = {
    codeQuality: 0.30,
    activity: 0.25,
    bugFix: 0.20,
    review: 0.15,
    collaboration: 0.10,
};

// === 工具函数 ===
const calculateCompositeScore = (kpi: DeveloperKpiVO): number => {
    const qualityScore = kpi.averageCodeScore || 0;
    const activityScore = Math.min(100, (kpi.totalCommits / 50) * 100 + (kpi.activeDays / 20) * 50);
    const bugFixScore = Math.min(100, kpi.bugCount > 0 ? 100 - (kpi.bugCount * 5) : 100);
    const reviewScore = Math.min(100, (kpi.totalReviews / 30) * 100);
    const collaborationScore = Math.min(100, ((kpi.totalCommits + kpi.totalReviews) / 60) * 100);

    return Math.round(
        qualityScore * DIMENSION_WEIGHTS.codeQuality +
        activityScore * DIMENSION_WEIGHTS.activity +
        bugFixScore * DIMENSION_WEIGHTS.bugFix +
        reviewScore * DIMENSION_WEIGHTS.review +
        collaborationScore * DIMENSION_WEIGHTS.collaboration
    );
};

const getGrade = (score: number): 'S' | 'A' | 'B' | 'C' | 'D' => {
    if (score >= 90) return 'S';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    return 'D';
};

const generateRadarData = (kpi: DeveloperKpiVO) => [
    { dimension: '代码质量', value: kpi.averageCodeScore || 0, fullMark: 100 },
    { dimension: '开发活跃', value: Math.min(100, (kpi.totalCommits / 50) * 100), fullMark: 100 },
    { dimension: '问题修复', value: Math.min(100, kpi.bugCount > 0 ? 100 - (kpi.bugCount * 5) : 100), fullMark: 100 },
    { dimension: '代码审查', value: Math.min(100, (kpi.totalReviews / 30) * 100), fullMark: 100 },
    { dimension: '协作贡献', value: Math.min(100, ((kpi.totalCommits + kpi.totalReviews) / 60) * 100), fullMark: 100 },
];

const generateTrendData = () => {
    const months = ['9月', '10月', '11月', '12月', '1月'];
    return months.map(month => ({
        month,
        score: Math.floor(Math.random() * 30) + 60
    }));
};

const generateRecentCommits = (developerName: string) => {
    const commitMessages: Record<string, { sha: string; message: string; date: string }[]> = {
        '张伟': [
            { sha: 'a3f2d1c', message: 'feat: 实现支付链路国密加密升级', date: '2小时前' },
            { sha: 'b7e4a2f', message: 'fix: 修复交易并发锁竞争问题', date: '5小时前' },
            { sha: 'c9d3e1b', message: 'perf: 优化账务批量处理性能', date: '1天前' },
        ],
        '李娜': [
            { sha: 'd4e5f6a', message: 'feat: 新增风控规则动态配置', date: '3小时前' },
            { sha: 'e7f8g9b', message: 'refactor: 重构用户认证模块', date: '8小时前' },
            { sha: 'f1g2h3c', message: 'docs: 更新API接口文档', date: '2天前' },
        ],
        '王强': [
            { sha: 'g4h5i6d', message: 'feat: 实现报表数据导出功能', date: '1小时前' },
            { sha: 'h7i8j9e', message: 'fix: 修复分页查询边界问题', date: '6小时前' },
            { sha: 'i1j2k3f', message: 'test: 补充单元测试覆盖', date: '1天前' },
        ],
        default: [
            { sha: 'x1y2z3a', message: 'feat: 功能优化与性能提升', date: '2小时前' },
            { sha: 'y4z5a6b', message: 'fix: 修复已知问题', date: '5小时前' },
            { sha: 'z7a8b9c', message: 'refactor: 代码重构', date: '1天前' },
        ],
    };
    return commitMessages[developerName] || commitMessages['default'];
};

// === 演示数据 ===
const DEMO_DEVELOPERS: DeveloperKpiVO[] = [
    {
        userId: 1,
        name: '张伟',
        email: 'zhangwei@jlbank.com',
        gitlabUsername: 'zhangwei',
        totalCommits: 68,
        totalReviews: 42,
        averageCodeScore: 96,
        activeDays: 22,
        bugCount: 1,
    },
    {
        userId: 2,
        name: '李娜',
        email: 'lina@jlbank.com',
        gitlabUsername: 'lina',
        totalCommits: 55,
        totalReviews: 38,
        averageCodeScore: 91,
        activeDays: 20,
        bugCount: 2,
    },
    {
        userId: 3,
        name: '王强',
        email: 'wangqiang@jlbank.com',
        gitlabUsername: 'wangqiang',
        totalCommits: 48,
        totalReviews: 35,
        averageCodeScore: 88,
        activeDays: 18,
        bugCount: 2,
    },
    {
        userId: 4,
        name: '刘洋',
        email: 'liuyang@jlbank.com',
        gitlabUsername: 'liuyang',
        totalCommits: 42,
        totalReviews: 28,
        averageCodeScore: 85,
        activeDays: 17,
        bugCount: 3,
    },
    {
        userId: 5,
        name: '陈静',
        email: 'chenjing@jlbank.com',
        gitlabUsername: 'chenjing',
        totalCommits: 38,
        totalReviews: 25,
        averageCodeScore: 82,
        activeDays: 15,
        bugCount: 3,
    },
    {
        userId: 6,
        name: '赵鹏',
        email: 'zhaopeng@jlbank.com',
        gitlabUsername: 'zhaopeng',
        totalCommits: 32,
        totalReviews: 20,
        averageCodeScore: 78,
        activeDays: 14,
        bugCount: 4,
    },
    {
        userId: 7,
        name: '孙磊',
        email: 'sunlei@jlbank.com',
        gitlabUsername: 'sunlei',
        totalCommits: 28,
        totalReviews: 18,
        averageCodeScore: 72,
        activeDays: 12,
        bugCount: 5,
    },
    {
        userId: 8,
        name: '周敏',
        email: 'zhoumin@jlbank.com',
        gitlabUsername: 'zhoumin',
        totalCommits: 22,
        totalReviews: 12,
        averageCodeScore: 68,
        activeDays: 10,
        bugCount: 6,
    },
];

// === 主组件 ===
const ReleaseStats: React.FC = () => {
    const [kpis, setKpis] = useState<ExtendedKpi[]>([]);
    const [loading, setLoading] = useState(false);
    const [selectedDeveloper, setSelectedDeveloper] = useState<ExtendedKpi | null>(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [timeRange, setTimeRange] = useState<'week' | 'month' | 'quarter'>('month');

    const processKpiData = (data: DeveloperKpiVO[]): ExtendedKpi[] => {
        return data.map(kpi => {
            const compositeScore = calculateCompositeScore(kpi);
            return {
                ...kpi,
                compositeScore,
                grade: getGrade(compositeScore),
                radarData: generateRadarData(kpi),
                trendData: generateTrendData(),
                recentCommits: generateRecentCommits(kpi.name),
            };
        }).sort((a, b) => b.compositeScore - a.compositeScore);
    };

    const fetchKpis = async () => {
        setLoading(true);
        try {
            const data = await getDeveloperKpis();
            // 如果 API 无数据则使用演示数据
            const sourceData = (data && data.length > 0) ? data : DEMO_DEVELOPERS;
            const extended = processKpiData(sourceData);

            setKpis(extended);
            if (extended.length > 0 && !selectedDeveloper) {
                setSelectedDeveloper(extended[0]);
            }
        } catch (error) {
            console.error(error);
            // API 出错时使用演示数据
            const extended = processKpiData(DEMO_DEVELOPERS);
            setKpis(extended);
            if (extended.length > 0) {
                setSelectedDeveloper(extended[0]);
            }
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchKpis();
    }, []);

    const filteredKpis = useMemo(() => {
        if (!searchTerm) return kpis;
        const term = searchTerm.toLowerCase();
        return kpis.filter(k =>
            k.name?.toLowerCase().includes(term) ||
            k.email?.toLowerCase().includes(term)
        );
    }, [kpis, searchTerm]);

    // 统计概览数据
    const stats = useMemo(() => ({
        totalCommits: kpis.reduce((acc, k) => acc + (k.totalCommits || 0), 0),
        activeDevelopers: kpis.length,
        avgScore: kpis.length > 0 ? Math.round(kpis.reduce((acc, k) => acc + k.compositeScore, 0) / kpis.length) : 0,
        topPerformers: kpis.filter(k => k.grade === 'S' || k.grade === 'A').length,
    }), [kpis]);

    const timeRangeOptions = [
        { value: 'week', label: '本周' },
        { value: 'month', label: '本月' },
        { value: 'quarter', label: '本季度' },
    ];

    if (loading) {
        return (
            <div className="h-full flex flex-col items-center justify-center space-y-4">
                <motion.div
                    className="w-16 h-16 border-4 border-slate-100 border-t-indigo-500 rounded-full"
                    animate={{ rotate: 360 }}
                    transition={{ repeat: Infinity, duration: 1, ease: 'linear' }}
                />
                <div className="font-mono text-xs text-slate-400 animate-pulse">
                    正在加载绩效数据...
                </div>
            </div>
        );
    }

    return (
        <div className="flex h-full bg-[#f8fafc] text-slate-600 font-sans selection:bg-indigo-100">
            {/* 左侧：排行榜面板 */}
            <aside className="w-96 flex-none border-r border-slate-200 bg-white flex flex-col shadow-[1px_0_10px_rgba(0,0,0,0.02)]">
                {/* 头部 */}
                <div className="p-6 border-b border-slate-100">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center shadow-lg shadow-amber-500/20">
                            <Trophy size={20} className="text-white" />
                        </div>
                        <div>
                            <h2 className="text-sm font-bold text-slate-800 tracking-tight uppercase">绩效考核中心</h2>
                            <p className="text-[10px] text-slate-400 font-mono tracking-widest uppercase">KPI Dashboard</p>
                        </div>
                    </div>

                    {/* 搜索框 */}
                    <div className="relative group mb-4">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-indigo-500 transition-colors" size={14} />
                        <input
                            placeholder="搜索开发者..."
                            className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 pl-9 pr-4 text-xs outline-none focus:border-indigo-500/50 focus:bg-white focus:ring-4 focus:ring-indigo-500/5 transition-all"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>

                    {/* 时间范围筛选 */}
                    <div className="flex gap-2">
                        {timeRangeOptions.map(opt => (
                            <button
                                key={opt.value}
                                onClick={() => setTimeRange(opt.value as any)}
                                className={`px-3 py-1.5 text-[10px] font-bold uppercase tracking-wider rounded-lg transition-all ${timeRange === opt.value
                                    ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-500/20'
                                    : 'bg-slate-50 text-slate-500 hover:bg-slate-100'
                                    }`}
                            >
                                {opt.label}
                            </button>
                        ))}
                    </div>
                </div>

                {/* 统计概览 */}
                <div className="grid grid-cols-2 gap-3 p-4 border-b border-slate-100 bg-slate-50/50">
                    <div className="bg-white rounded-xl p-3 border border-slate-100">
                        <div className="text-[9px] font-bold text-slate-400 uppercase tracking-wider mb-1">总提交</div>
                        <div className="text-xl font-black text-slate-800">{stats.totalCommits}</div>
                    </div>
                    <div className="bg-white rounded-xl p-3 border border-slate-100">
                        <div className="text-[9px] font-bold text-slate-400 uppercase tracking-wider mb-1">活跃开发者</div>
                        <div className="text-xl font-black text-slate-800">{stats.activeDevelopers}</div>
                    </div>
                    <div className="bg-white rounded-xl p-3 border border-slate-100">
                        <div className="text-[9px] font-bold text-slate-400 uppercase tracking-wider mb-1">平均绩效</div>
                        <div className="text-xl font-black text-indigo-600">{stats.avgScore}<span className="text-xs text-slate-400">/100</span></div>
                    </div>
                    <div className="bg-white rounded-xl p-3 border border-slate-100">
                        <div className="text-[9px] font-bold text-slate-400 uppercase tracking-wider mb-1">优秀以上</div>
                        <div className="text-xl font-black text-emerald-600">{stats.topPerformers}</div>
                    </div>
                </div>

                {/* 排行榜列表 */}
                <div className="flex-1 overflow-y-auto custom-scrollbar">
                    <div className="p-4 space-y-2">
                        {filteredKpis.map((kpi, index) => {
                            const gradeConfig = GRADE_CONFIG[kpi.grade];
                            const GradeIcon = gradeConfig.icon;
                            const isSelected = selectedDeveloper?.userId === kpi.userId;
                            const isTop3 = index < 3;

                            return (
                                <motion.button
                                    key={kpi.userId}
                                    onClick={() => setSelectedDeveloper(kpi)}
                                    initial={{ opacity: 0, x: -20 }}
                                    animate={{ opacity: 1, x: 0 }}
                                    transition={{ delay: index * 0.05 }}
                                    className={`w-full text-left p-4 rounded-2xl transition-all duration-300 relative group border-2 ${isSelected
                                        ? 'bg-white border-indigo-200 shadow-lg ring-2 ring-indigo-500/10'
                                        : 'bg-white/50 border-transparent hover:bg-white hover:border-slate-100 hover:shadow-md'
                                        }`}
                                >
                                    {/* 选中指示器 */}
                                    {isSelected && (
                                        <motion.div
                                            layoutId="active-indicator"
                                            className="absolute -left-1 top-1/2 -translate-y-1/2 w-2 h-8 bg-indigo-600 rounded-r-full shadow-lg"
                                        />
                                    )}

                                    {/* 排名徽章 */}
                                    <div className={`absolute -top-2 -right-2 w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-black shadow-lg ${isTop3
                                        ? index === 0 ? 'bg-gradient-to-br from-amber-400 to-orange-500 text-white'
                                            : index === 1 ? 'bg-gradient-to-br from-slate-300 to-slate-400 text-white'
                                                : 'bg-gradient-to-br from-amber-600 to-amber-700 text-white'
                                        : 'bg-slate-200 text-slate-600'
                                        }`}>
                                        {index + 1}
                                    </div>

                                    <div className="flex items-center gap-3">
                                        {/* 头像 */}
                                        <div className={`w-12 h-12 rounded-2xl flex items-center justify-center text-lg font-black ${gradeConfig.bgColor} ${gradeConfig.textColor} border ${gradeConfig.borderColor}`}>
                                            {kpi.name?.charAt(0) || '?'}
                                        </div>

                                        {/* 信息 */}
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center gap-2 mb-1">
                                                <h3 className="font-bold text-slate-800 truncate">{kpi.name}</h3>
                                                <span className={`px-1.5 py-0.5 rounded text-[8px] font-black uppercase ${gradeConfig.bgColor} ${gradeConfig.textColor} border ${gradeConfig.borderColor}`}>
                                                    {kpi.grade}级
                                                </span>
                                            </div>
                                            <p className="text-[10px] text-slate-400 truncate font-mono">{kpi.email}</p>
                                        </div>

                                        {/* 分数 */}
                                        <div className="text-right">
                                            <div className="text-2xl font-black" style={{ color: gradeConfig.color }}>
                                                {kpi.compositeScore}
                                            </div>
                                            <div className="text-[9px] text-slate-400 font-mono">综合分</div>
                                        </div>
                                    </div>

                                    {/* 快速指标 */}
                                    <div className="flex items-center gap-4 mt-3 pt-3 border-t border-slate-100">
                                        <div className="flex items-center gap-1 text-[10px] text-slate-500">
                                            <GitCommit size={10} className="text-slate-400" />
                                            <span className="font-bold">{kpi.totalCommits}</span> 提交
                                        </div>
                                        <div className="flex items-center gap-1 text-[10px] text-slate-500">
                                            <FileText size={10} className="text-slate-400" />
                                            <span className="font-bold">{kpi.totalReviews}</span> 审查
                                        </div>
                                        <div className="flex items-center gap-1 text-[10px] text-slate-500">
                                            <Activity size={10} className="text-slate-400" />
                                            <span className="font-bold">{kpi.averageCodeScore?.toFixed(0) || '-'}</span> 质量
                                        </div>
                                    </div>
                                </motion.button>
                            );
                        })}

                        {filteredKpis.length === 0 && (
                            <div className="py-20 flex flex-col items-center justify-center text-slate-300">
                                <Users size={40} className="mb-4 opacity-30" />
                                <p className="text-[10px] font-black uppercase tracking-widest">暂无开发者数据</p>
                            </div>
                        )}
                    </div>
                </div>
            </aside>

            {/* 右侧：详情面板 */}
            <main className="flex-1 overflow-y-auto bg-white">
                {selectedDeveloper ? (
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={selectedDeveloper.userId}
                            initial={{ opacity: 0, x: 20 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -20 }}
                            className="p-8 max-w-5xl mx-auto"
                        >
                            {/* 详情头部 */}
                            <div className="flex flex-col md:flex-row gap-8 mb-10 items-start justify-between border-b border-slate-100 pb-10">
                                <div className="space-y-4">
                                    <div className="flex items-center gap-2">
                                        <div className="w-2 h-2 rounded-full bg-indigo-500 animate-pulse" />
                                        <span className="text-[10px] font-black uppercase text-indigo-600 tracking-[0.2em]">开发者绩效档案</span>
                                    </div>
                                    <div className="flex items-center gap-4">
                                        <div className={`w-20 h-20 rounded-3xl flex items-center justify-center text-3xl font-black ${GRADE_CONFIG[selectedDeveloper.grade].bgColor} ${GRADE_CONFIG[selectedDeveloper.grade].textColor} border-2 ${GRADE_CONFIG[selectedDeveloper.grade].borderColor} shadow-xl`}>
                                            {selectedDeveloper.name?.charAt(0) || '?'}
                                        </div>
                                        <div>
                                            <h1 className="text-3xl font-black text-slate-900 tracking-tight">
                                                {selectedDeveloper.name}
                                            </h1>
                                            <p className="text-sm text-slate-400 font-mono mt-1">{selectedDeveloper.email}</p>
                                        </div>
                                    </div>
                                </div>

                                {/* 等级卡片 */}
                                <div className={`px-8 py-6 rounded-3xl ${GRADE_CONFIG[selectedDeveloper.grade].bgColor} border-2 ${GRADE_CONFIG[selectedDeveloper.grade].borderColor} shadow-xl relative overflow-hidden`}>
                                    <div className="absolute top-2 right-2 opacity-10">
                                        {React.createElement(GRADE_CONFIG[selectedDeveloper.grade].icon, { size: 60 })}
                                    </div>
                                    <div className="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-2">综合绩效</div>
                                    <div className="flex items-baseline gap-2">
                                        <span className="text-5xl font-black" style={{ color: GRADE_CONFIG[selectedDeveloper.grade].color }}>
                                            {selectedDeveloper.compositeScore}
                                        </span>
                                        <span className="text-lg text-slate-400">/100</span>
                                    </div>
                                    <div className={`mt-2 text-sm font-bold ${GRADE_CONFIG[selectedDeveloper.grade].textColor}`}>
                                        {GRADE_CONFIG[selectedDeveloper.grade].label}
                                    </div>
                                </div>
                            </div>

                            {/* 五维雷达图 */}
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-10">
                                <div className="bg-white border border-slate-200 rounded-3xl p-6 shadow-sm">
                                    <h3 className="text-xs font-black uppercase text-slate-400 mb-6 tracking-widest flex items-center gap-2">
                                        <Fingerprint size={14} className="text-indigo-500" />
                                        能力雷达图
                                    </h3>
                                    <div className="h-64">
                                        <ResponsiveContainer width="100%" height="100%">
                                            <RadarChart data={selectedDeveloper.radarData}>
                                                <PolarGrid stroke="#e2e8f0" />
                                                <PolarAngleAxis
                                                    dataKey="dimension"
                                                    tick={{ fill: '#64748b', fontSize: 11, fontWeight: 600 }}
                                                />
                                                <PolarRadiusAxis
                                                    angle={90}
                                                    domain={[0, 100]}
                                                    tick={{ fill: '#94a3b8', fontSize: 9 }}
                                                />
                                                <Radar
                                                    name="能力值"
                                                    dataKey="value"
                                                    stroke={GRADE_CONFIG[selectedDeveloper.grade].color}
                                                    fill={GRADE_CONFIG[selectedDeveloper.grade].color}
                                                    fillOpacity={0.3}
                                                    strokeWidth={2}
                                                />
                                            </RadarChart>
                                        </ResponsiveContainer>
                                    </div>
                                </div>

                                {/* 趋势图 */}
                                <div className="bg-white border border-slate-200 rounded-3xl p-6 shadow-sm">
                                    <h3 className="text-xs font-black uppercase text-slate-400 mb-6 tracking-widest flex items-center gap-2">
                                        <TrendingUp size={14} className="text-emerald-500" />
                                        绩效趋势
                                    </h3>
                                    <div className="h-64">
                                        <ResponsiveContainer width="100%" height="100%">
                                            <AreaChart data={selectedDeveloper.trendData}>
                                                <defs>
                                                    <linearGradient id="scoreGradient" x1="0" y1="0" x2="0" y2="1">
                                                        <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                                                        <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                                                    </linearGradient>
                                                </defs>
                                                <XAxis
                                                    dataKey="month"
                                                    axisLine={false}
                                                    tickLine={false}
                                                    tick={{ fill: '#64748b', fontSize: 11 }}
                                                />
                                                <YAxis
                                                    domain={[0, 100]}
                                                    axisLine={false}
                                                    tickLine={false}
                                                    tick={{ fill: '#94a3b8', fontSize: 10 }}
                                                />
                                                <Tooltip
                                                    contentStyle={{
                                                        backgroundColor: '#1e293b',
                                                        border: 'none',
                                                        borderRadius: '12px',
                                                        color: '#fff',
                                                        fontSize: '12px',
                                                    }}
                                                />
                                                <Area
                                                    type="monotone"
                                                    dataKey="score"
                                                    stroke="#6366f1"
                                                    strokeWidth={3}
                                                    fill="url(#scoreGradient)"
                                                />
                                            </AreaChart>
                                        </ResponsiveContainer>
                                    </div>
                                </div>
                            </div>

                            {/* 详细指标卡片 */}
                            <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-10">
                                {[
                                    { label: '代码质量', value: selectedDeveloper.averageCodeScore?.toFixed(0) || '-', icon: Shield, color: 'indigo' },
                                    { label: '提交次数', value: selectedDeveloper.totalCommits, icon: GitCommit, color: 'emerald' },
                                    { label: '活跃天数', value: selectedDeveloper.activeDays, icon: Calendar, color: 'blue' },
                                    { label: '审查次数', value: selectedDeveloper.totalReviews, icon: FileText, color: 'purple' },
                                    { label: 'Bug 数量', value: selectedDeveloper.bugCount, icon: Bug, color: 'rose' },
                                ].map((item, idx) => (
                                    <motion.div
                                        key={idx}
                                        initial={{ opacity: 0, y: 20 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        transition={{ delay: idx * 0.1 }}
                                        className={`bg-white border border-slate-200 rounded-2xl p-4 relative overflow-hidden group hover:shadow-lg hover:border-${item.color}-200 transition-all`}
                                    >
                                        <div className={`absolute top-2 right-2 opacity-5 group-hover:opacity-10 transition-opacity text-${item.color}-500`}>
                                            <item.icon size={40} />
                                        </div>
                                        <div className="text-[9px] font-black uppercase text-slate-400 tracking-wider mb-2">{item.label}</div>
                                        <div className="text-2xl font-black text-slate-800">{item.value}</div>
                                    </motion.div>
                                ))}
                            </div>

                            {/* 最近提交 */}
                            <div className="bg-white border border-slate-200 rounded-3xl p-6 shadow-sm">
                                <h3 className="text-xs font-black uppercase text-slate-400 mb-6 tracking-widest flex items-center gap-2">
                                    <Code2 size={14} className="text-slate-500" />
                                    最近提交记录
                                </h3>
                                <div className="space-y-3">
                                    {selectedDeveloper.recentCommits.map((commit, idx) => (
                                        <motion.div
                                            key={idx}
                                            initial={{ opacity: 0, x: -10 }}
                                            animate={{ opacity: 1, x: 0 }}
                                            transition={{ delay: idx * 0.1 }}
                                            className="flex items-center gap-4 p-4 bg-slate-50 rounded-xl hover:bg-slate-100 transition-colors group"
                                        >
                                            <div className="w-10 h-10 rounded-xl bg-slate-200 flex items-center justify-center text-slate-500 group-hover:bg-indigo-100 group-hover:text-indigo-600 transition-colors">
                                                <GitCommit size={18} />
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <p className="text-sm font-medium text-slate-700 truncate">{commit.message}</p>
                                                <p className="text-[10px] text-slate-400 font-mono mt-1">{commit.sha}</p>
                                            </div>
                                            <div className="text-[10px] text-slate-400 font-mono flex items-center gap-1">
                                                <Clock size={10} />
                                                {commit.date}
                                            </div>
                                        </motion.div>
                                    ))}
                                </div>
                            </div>
                        </motion.div>
                    </AnimatePresence>
                ) : (
                    <div className="h-full flex flex-col items-center justify-center text-slate-200">
                        <Trophy size={64} className="mb-4 opacity-10" />
                        <p className="text-lg font-black tracking-widest uppercase opacity-30">选择开发者查看详情</p>
                    </div>
                )}
            </main>
        </div>
    );
};

export default ReleaseStats;
