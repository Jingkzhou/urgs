import React, { useState, useEffect, useMemo } from 'react';
import { getAICodeReviews, AICodeReview, getGitRepositories, GitRepository } from '../../api/version';
import {
    Bot, CheckCircle, Clock, GitCommit, Search, FileCode,
    Shield, Activity, Zap, Layers, AlertTriangle, Terminal, User,
    ArrowUpRight, Loader, ChevronRight, Layout, Fingerprint, Radar,
    ChevronDown, Package
} from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { Progress, Badge, Modal, Tooltip, Empty } from 'antd';
import { motion, AnimatePresence } from 'framer-motion';

// --- Types ---
interface AuditIssue {
    severity: 'critical' | 'major' | 'minor';
    title: string;
    line?: number;
    description?: string;
    recommendation?: string;
    codeSnippet?: string;
}

interface ExtendedReview extends AICodeReview {
    scoreBreakdown: {
        security: number;
        reliability: number;
        maintainability: number;
        performance: number;
    };
    issues: AuditIssue[];
    language?: string;
}

// --- Mock Data for Presentation ---
const PRESENTATION_SYSTEMS = [
    { id: 1, name: '核心支付系统 (Core Payment)' },
    { id: 2, name: '风控预警平台 (Risk Monitor)' },
    { id: 3, name: '互联网金融门户 (e-Banking)' }
];

const PRESENTATION_REPOS: (GitRepository & { systemId: number })[] = [
    { id: 1, systemId: 1, name: 'banking-gateway-v4', platform: 'gitlab', ssoId: 1, cloneUrl: '' },
    { id: 2, systemId: 1, name: 'ledger-service', platform: 'gitlab', ssoId: 1, cloneUrl: '' },
    { id: 3, systemId: 2, name: 'risk-scoring-engine', platform: 'gitlab', ssoId: 1, cloneUrl: '' },
    { id: 4, systemId: 3, name: 'retail-portal-web', platform: 'github', ssoId: 1, cloneUrl: '' }
];

const PRESENTATION_REVIEWS: ExtendedReview[] = [
    {
        id: 1001,
        repoId: 1,
        commitSha: '8d2a1c',
        branch: 'master',
        score: 95,
        status: 'COMPLETED',
        summary: '支付链路加密升级',
        developerEmail: 'safety@jlbank.com',
        createdAt: '2024-03-26T10:00:00Z',
        language: 'Java',
        scoreBreakdown: { security: 100, reliability: 92, maintainability: 90, performance: 95 },
        issues: [],
        content: '## 🚀 安全审计：卓越\n\n成功引入国密算法替代通用算法，关键业务链路已全部实现加密透传，未发现逻辑漏洞。'
    },
    {
        id: 1002,
        repoId: 2,
        commitSha: 'fe330a',
        branch: 'feat/batch-ledger',
        score: 82,
        status: 'COMPLETED',
        summary: '大批量账务平账逻辑优化',
        developerEmail: 'ledger-dev@jlbank.com',
        createdAt: '2024-03-25T14:20:00Z',
        language: 'Go',
        scoreBreakdown: { security: 85, reliability: 78, maintainability: 82, performance: 88 },
        issues: [
            {
                severity: 'major',
                title: '数据库连接未及时释放',
                description: '在处理异步回调时，部分 db 链接在异常路径下可能无法闭合，高并发下会导致连接池枯竭。',
                recommendation: '使用 defer 确保链接始终关闭。',
                line: 320,
                codeSnippet: 'conn, _ := db.GetConn();\n// Missing: defer conn.Close()'
            }
        ],
        content: '## 📊 性能审计：良好\n\n通过批量更新策略显著降低了 IOPS，但需注意资源释放的一致性问题。'
    },
    {
        id: 1003,
        repoId: 3,
        commitSha: '6c7b2e',
        branch: 'fix/model-overfit',
        score: 45,
        status: 'COMPLETED',
        summary: '风控模型过拟合风险修复',
        developerEmail: 'data-sci@jlbank.com',
        createdAt: '2024-03-24T09:15:00Z',
        language: 'Python',
        scoreBreakdown: { security: 60, reliability: 30, maintainability: 55, performance: 45 },
        issues: [
            {
                severity: 'critical',
                title: '检测到非线程安全的字典操作',
                description: '在多线程评估风险评分时，直接操作了全局配置字典，可能导致运行时崩溃。',
                recommendation: '使用 threading.Lock 或本地线程变量。',
                line: 12,
                codeSnippet: 'GLOBAL_CONFIG["last_run"] = time.time()'
            }
        ],
        content: '## ⚠️ 稳定性警告：高危\n\n数据处理脚本在高并发环境下极不稳定，建议立即重构并发控制模型。'
    },
    {
        id: 1004,
        repoId: 4,
        commitSha: '99aa0b',
        branch: 'refactor/ui-kit',
        score: 91,
        status: 'COMPLETED',
        summary: '门户组件库性能重构',
        developerEmail: 'fe-architect@jlbank.com',
        createdAt: '2024-03-23T16:00:00Z',
        language: 'TypeScript',
        scoreBreakdown: { security: 95, reliability: 88, maintainability: 98, performance: 85 },
        issues: [],
        content: '## 🎨 架构审计：通过\n\n前端组件化程度大幅提升，代码复用率提高 40%，首屏加载耗时缩短 300ms。'
    }
];

const AICodeReport: React.FC = () => {
    const [repos, setRepos] = useState<(GitRepository & { systemId: number })[]>(PRESENTATION_REPOS);
    const [reviews, setReviews] = useState<ExtendedReview[]>(PRESENTATION_REVIEWS);
    const [loading, setLoading] = useState(false);
    const [selectedReview, setSelectedReview] = useState<ExtendedReview | null>(PRESENTATION_REVIEWS[0]);
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedIssue, setSelectedIssue] = useState<AuditIssue | null>(null);
    const [expandedRepos, setExpandedRepos] = useState<Set<number>>(new Set([1, 2, 3, 4]));

    useEffect(() => {
        // Presentation mode logic
    }, []);

    const toggleRepo = (repoId: number) => {
        const next = new Set(expandedRepos);
        if (next.has(repoId)) next.delete(repoId);
        else next.add(repoId);
        setExpandedRepos(next);
    };

    const groupedData = useMemo(() => {
        const term = searchTerm.toLowerCase();

        return PRESENTATION_SYSTEMS.map(sys => {
            const sysRepos = repos.filter(r => r.systemId === sys.id);
            const filteredSysRepos = sysRepos.map(repo => ({
                ...repo,
                items: reviews.filter(rev =>
                    rev.repoId === repo.id &&
                    (repo.name.toLowerCase().includes(term) || rev.summary?.toLowerCase().includes(term) || rev.branch?.toLowerCase().includes(term) || sys.name.toLowerCase().includes(term))
                ).sort((a, b) => new Date(b.createdAt!).getTime() - new Date(a.createdAt!).getTime())
            })).filter(repo => repo.items.length > 0);

            return {
                ...sys,
                repos: filteredSysRepos
            };
        }).filter(sys => sys.repos.length > 0);
    }, [repos, reviews, searchTerm]);

    const getScoreColor = (score: number = 0) => {
        if (score >= 90) return '#10b981'; // Emerald
        if (score >= 70) return '#6366f1'; // Indigo
        return '#f43f5e'; // Rose
    };

    return (
        <div className="flex h-full bg-[#f8fafc] text-slate-600 font-sans selection:bg-indigo-100">
            {/* Sidebar: Repository-based Archive */}
            <aside className="w-80 flex-none border-r border-slate-200 bg-white flex flex-col shadow-[1px_0_10px_rgba(0,0,0,0.02)]">
                <div className="p-6">
                    <div className="flex items-center gap-3 mb-8">
                        <div className="w-10 h-10 rounded-xl bg-indigo-50 border border-indigo-100 flex items-center justify-center">
                            <Radar size={20} className="text-indigo-600" />
                        </div>
                        <div>
                            <h2 className="text-sm font-bold text-slate-800 tracking-tight uppercase">智查报告库</h2>
                            <p className="text-[10px] text-slate-400 font-mono tracking-widest uppercase">Diagnostic Center</p>
                        </div>
                    </div>

                    <div className="relative group">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-indigo-500 transition-colors" size={14} />
                        <input
                            placeholder="搜索仓库或报告..."
                            className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 pl-9 pr-4 text-xs outline-none focus:border-indigo-500/50 focus:bg-white focus:ring-4 focus:ring-indigo-500/5 transition-all"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>

                <div className="flex-1 overflow-y-auto px-4 pb-6 custom-scrollbar">
                    {loading ? (
                        <div className="flex flex-col items-center justify-center py-20 opacity-30 text-indigo-600">
                            <Loader className="animate-spin mb-2" size={20} />
                            <span className="text-[10px] font-bold tracking-widest uppercase">Initializing Content...</span>
                        </div>
                    ) : groupedData.length > 0 ? (groupedData as any[]).map(sys => (
                        <div key={`sys-${sys.id}`} className="mb-8">
                            {/* System Level Header */}
                            <div className="flex items-center gap-2 mb-3 px-2">
                                <div className="w-1.5 h-1.5 rounded-full bg-indigo-500 shadow-[0_0_8px_rgba(99,102,241,0.6)]" />
                                <span className="text-[10px] font-black uppercase text-slate-400 tracking-wider">Module: {sys.name}</span>
                            </div>

                            <div className="space-y-3">
                                {sys.repos.map((repo: any) => (
                                    <div key={`repo-${repo.id}`} className="bg-slate-50/50 rounded-2xl border border-slate-100/50 p-1">
                                        <button
                                            onClick={() => toggleRepo(repo.id!)}
                                            className="w-full flex items-center justify-between p-2.5 hover:bg-white hover:shadow-sm rounded-xl transition-all group"
                                        >
                                            <div className="flex items-center gap-2">
                                                <Package size={14} className="text-slate-400 group-hover:text-indigo-500 transition-colors" />
                                                <span className="text-xs font-bold text-slate-700 truncate max-w-[150px]">{repo.name}</span>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <span className="text-[9px] font-bold bg-white text-indigo-600 px-1.5 py-0.5 rounded-full shadow-sm border border-indigo-50 group-hover:bg-indigo-600 group-hover:text-white transition-colors">{repo.items.length}</span>
                                                <ChevronDown
                                                    size={12}
                                                    className={`text-slate-300 transition-transform duration-300 ${expandedRepos.has(repo.id!) ? 'rotate-180' : ''}`}
                                                />
                                            </div>
                                        </button>

                                        <AnimatePresence initial={false}>
                                            {expandedRepos.has(repo.id!) && (
                                                <motion.div
                                                    initial={{ height: 0, opacity: 0 }}
                                                    animate={{ height: 'auto', opacity: 1 }}
                                                    exit={{ height: 0, opacity: 0 }}
                                                    className="overflow-hidden"
                                                >
                                                    <div className="p-2 space-y-1">
                                                        {repo.items.map(r => (
                                                            <button
                                                                key={r.id}
                                                                onClick={() => setSelectedReview(r)}
                                                                className={`w-full text-left p-3 rounded-xl transition-all duration-300 relative group
                                                                    ${selectedReview?.id === r.id
                                                                        ? 'bg-white border-2 border-indigo-100 shadow-md ring-1 ring-indigo-500/5'
                                                                        : 'bg-transparent border-2 border-transparent hover:bg-white hover:border-slate-100 hover:shadow-sm'}`}
                                                            >
                                                                {selectedReview?.id === r.id && (
                                                                    <motion.div
                                                                        layoutId="active-dot"
                                                                        className="absolute -left-1 top-1/2 -translate-y-1/2 w-2 h-2 bg-indigo-600 rounded-full shadow-[0_0_8px_rgba(79,70,229,0.5)] z-10"
                                                                    />
                                                                )}
                                                                <div className="flex justify-between items-start mb-1.5">
                                                                    <span className="text-[8px] font-bold font-mono text-slate-400">{new Date(r.createdAt!).toLocaleDateString()}</span>
                                                                    <Badge count={`${r.score}%`} style={{ backgroundColor: getScoreColor(r.score), fontSize: '8px', height: '14px', lineHeight: '14px' }} />
                                                                </div>
                                                                <h3 className={`text-[11px] font-bold line-clamp-1 mb-1 ${selectedReview?.id === r.id ? 'text-indigo-600' : 'text-slate-700'}`}>
                                                                    {r.summary || 'Untethered Session'}
                                                                </h3>
                                                                <div className="flex items-center gap-1.5 text-[9px] text-slate-400 font-medium">
                                                                    <GitCommit size={10} className="text-slate-300" />
                                                                    <span className="truncate">{r.branch}</span>
                                                                </div>
                                                            </button>
                                                        ))}
                                                    </div>
                                                </motion.div>
                                            )}
                                        </AnimatePresence>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )) : (
                        <div className="py-20 flex flex-col items-center justify-center text-slate-300">
                            <Bot size={40} className="mb-4 opacity-10" />
                            <p className="text-[10px] font-black uppercase tracking-widest">No Intelligence Retained</p>
                        </div>
                    )}
                </div>
            </aside>

            {/* Main Content: The Report View */}
            <main className="flex-1 overflow-y-auto bg-white relative">
                {selectedReview ? (
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={selectedReview.id}
                            initial={{ opacity: 0, x: 20 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -20 }}
                            className="p-10 max-w-5xl mx-auto"
                        >
                            {/* Header Stats */}
                            <div className="flex flex-col md:flex-row gap-8 mb-12 items-end justify-between border-b border-slate-100 pb-12">
                                <div className="space-y-4">
                                    <div className="flex items-center gap-2">
                                        <div className="w-2 h-2 rounded-full bg-indigo-500 animate-pulse" />
                                        <span className="text-[10px] font-black uppercase text-indigo-600 tracking-[0.2em]">Diagnostic Report Finalized</span>
                                    </div>
                                    <h1 className="text-4xl font-black text-slate-900 tracking-tight leading-none uppercase italic">
                                        REPORT <span className="text-indigo-600">#{selectedReview.id}</span>
                                    </h1>
                                    <div className="flex items-center gap-4 text-xs text-slate-400 font-mono">
                                        <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-slate-50 text-slate-600"><FileCode size={12} /> {selectedReview.language}</div>
                                        <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-slate-50 text-slate-600"><User size={12} /> {selectedReview.developerEmail.split('@')[0]}</div>
                                        <div className="flex items-center gap-1.5 px-2 py-1 rounded bg-slate-50 text-slate-600"><Clock size={12} /> {new Date(selectedReview.createdAt).toLocaleDateString()}</div>
                                    </div>
                                </div>

                                <div className="flex gap-4">
                                    <div className="h-24 w-40 bg-white border border-slate-200 rounded-3xl p-4 flex flex-col justify-between group hover:border-indigo-500/30 transition-all shadow-sm">
                                        <span className="text-[9px] font-black uppercase text-slate-400 tracking-wider">Quality Score</span>
                                        <div className="flex items-baseline gap-1">
                                            <span className="text-4xl font-black" style={{ color: getScoreColor(selectedReview.score) }}>{selectedReview.score}</span>
                                            <span className="text-[10px] text-slate-400 font-mono">/100</span>
                                        </div>
                                    </div>
                                    <div className="h-24 w-40 bg-white border border-slate-200 rounded-3xl p-4 flex flex-col justify-between hover:border-rose-500/30 transition-all shadow-sm">
                                        <span className="text-[9px] font-black uppercase text-slate-400 tracking-wider">Critical Issues</span>
                                        <div className="flex items-baseline gap-1 text-slate-800">
                                            <span className="text-4xl font-black">{selectedReview.issues.filter(i => i.severity === 'critical').length}</span>
                                            <span className="text-rose-500"><AlertTriangle size={14} /></span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Score Breakdown */}
                            <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-12">
                                {Object.entries(selectedReview.scoreBreakdown).map(([key, val]) => (
                                    <div key={key} className="bg-white border border-slate-200 rounded-2xl p-5 relative overflow-hidden group hover:shadow-lg hover:border-indigo-100 transition-all shadow-sm">
                                        <div className="absolute top-0 right-0 p-3 opacity-[0.03] group-hover:scale-125 transition-transform group-hover:opacity-[0.08] text-indigo-600">
                                            {key === 'security' && <Shield size={32} />}
                                            {key === 'reliability' && <Activity size={32} />}
                                            {key === 'maintainability' && <Layers size={32} />}
                                            {key === 'performance' && <Zap size={32} />}
                                        </div>
                                        <h4 className="text-[10px] font-black uppercase text-slate-400 mb-3 tracking-widest">{key}</h4>
                                        <div className="flex items-end justify-between font-mono">
                                            <div className="text-2xl font-bold text-slate-800">{val}</div>
                                            <div className="w-16 h-1 bg-slate-100 rounded-full overflow-hidden">
                                                <motion.div
                                                    initial={{ width: 0 }}
                                                    animate={{ width: `${val}%` }}
                                                    className="h-full bg-indigo-500 shadow-[0_0_8px_rgba(99,102,241,0.4)]"
                                                />
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>

                            {/* Summary Content */}
                            <div className="mb-12 bg-white border border-slate-200 rounded-3xl p-8 shadow-sm">
                                <h3 className="text-xs font-black uppercase text-indigo-600 mb-6 tracking-widest flex items-center gap-2">
                                    <Fingerprint size={14} /> AI Analysis Summary
                                </h3>
                                <div className="prose prose-slate max-w-none text-slate-600">
                                    <ReactMarkdown>{selectedReview.content}</ReactMarkdown>
                                </div>
                            </div>

                            {/* Findings / Issues */}
                            <div className="space-y-4 pb-20">
                                <h3 className="text-xs font-black uppercase text-slate-400 mb-6 tracking-widest">Diagnostic Findings</h3>
                                {selectedReview.issues.length > 0 ? selectedReview.issues.map((issue, idx) => (
                                    <motion.div
                                        key={idx}
                                        whileHover={{ y: -2, x: 2 }}
                                        className="bg-white border border-slate-200 rounded-2xl p-6 hover:border-indigo-200 hover:shadow-xl hover:shadow-indigo-500/5 transition-all cursor-pointer group"
                                        onClick={() => setSelectedIssue(issue)}
                                    >
                                        <div className="flex items-start gap-4">
                                            <div className={`mt-1 h-3 w-3 rounded-full border-2 border-white shadow-sm ${issue.severity === 'critical' ? 'bg-rose-500' :
                                                issue.severity === 'major' ? 'bg-amber-500' : 'bg-blue-500'
                                                }`} />
                                            <div className="flex-1">
                                                <div className="flex items-center justify-between mb-2">
                                                    <h4 className="text-sm font-bold text-slate-800 group-hover:text-indigo-600 transition-colors">{issue.title}</h4>
                                                    <span className={`text-[9px] font-black uppercase italic tracking-widest px-2 py-0.5 rounded ${issue.severity === 'critical' ? 'text-rose-600 bg-rose-50' : 'text-slate-400 bg-slate-50'
                                                        }`}>{issue.severity}</span>
                                                </div>
                                                <p className="text-xs text-slate-500 line-clamp-2">{issue.description}</p>
                                            </div>
                                            <ChevronRight size={16} className="text-slate-300 self-center group-hover:text-indigo-400 group-hover:translate-x-1 transition-all" />
                                        </div>
                                    </motion.div>
                                )) : (
                                    <div className="py-20 flex flex-col items-center justify-center opacity-20">
                                        <CheckCircle size={40} className="text-emerald-500 mb-4" />
                                        <p className="text-sm font-bold uppercase tracking-widest italic">No Vulnerabilities Detected</p>
                                    </div>
                                )}
                            </div>
                        </motion.div>
                    </AnimatePresence>
                ) : (
                    <div className="h-full flex flex-col items-center justify-center text-slate-200">
                        <Bot size={48} className="mb-4 opacity-5" />
                        <p className="text-lg font-black tracking-widest uppercase opacity-20">Select a Report for Analysis</p>
                    </div>
                )}
            </main>

            {/* Issue Detail Modal (Tailored to light aesthetic) */}
            <Modal
                footer={null}
                open={!!selectedIssue}
                onCancel={() => setSelectedIssue(null)}
                width={700}
                centered
                styles={{ body: { backgroundColor: '#fff', padding: '0px' } }}
                closeIcon={<span className="text-slate-400 hover:text-slate-600">×</span>}
                className="light-diagnostic-modal"
            >
                {selectedIssue && (
                    <div className="p-8 text-slate-600 font-sans">
                        <div className="flex items-start justify-between mb-8 border-b border-slate-100 pb-8">
                            <div className="space-y-4">
                                <div className="flex items-center gap-2">
                                    <span className={`px-2 py-1 rounded-lg text-[9px] font-black uppercase tracking-widest ${selectedIssue.severity === 'critical' ? 'bg-rose-50 text-rose-600 border border-rose-100' :
                                        'bg-slate-50 text-slate-400 border border-slate-100'
                                        }`}>
                                        {selectedIssue.severity} Fault Identified
                                    </span>
                                </div>
                                <h2 className="text-2xl font-black text-slate-900 italic uppercase tracking-tight leading-tight">
                                    {selectedIssue.title}
                                </h2>
                                <div className="flex items-center gap-4 text-[10px] font-mono text-slate-400">
                                    <div className="flex items-center gap-1.5 px-2 py-0.5 rounded bg-slate-50 border border-slate-100"><FileCode size={12} /> Line {selectedIssue.line || 'Unknown'}</div>
                                    <div className="flex items-center gap-1.5"><Fingerprint size={12} /> Hash: {Math.random().toString(36).substring(7).toUpperCase()}</div>
                                </div>
                            </div>
                        </div>

                        <div className="space-y-8">
                            <div>
                                <h5 className="text-[10px] font-black uppercase text-indigo-500 mb-3 tracking-[0.2em]">Diagnostic Profile</h5>
                                <p className="text-sm text-slate-600 leading-relaxed font-medium bg-slate-50 p-6 border border-slate-100 rounded-3xl">
                                    {selectedIssue.description}
                                </p>
                            </div>

                            {selectedIssue.codeSnippet && (
                                <div>
                                    <h5 className="text-[10px] font-black uppercase text-slate-400 mb-3 tracking-[0.2em]">Source Context</h5>
                                    <div className="bg-slate-900 rounded-3xl overflow-hidden shadow-2xl">
                                        <div className="px-4 py-2 bg-slate-800/50 flex items-center justify-between border-b border-white/5">
                                            <div className="flex gap-1.5">
                                                <div className="w-2 h-2 rounded-full bg-slate-700" />
                                                <div className="w-2 h-2 rounded-full bg-slate-700" />
                                            </div>
                                            <span className="text-[8px] font-mono text-slate-500 uppercase">Buffer Inspector</span>
                                        </div>
                                        <pre className="p-6 overflow-x-auto text-[11px] leading-relaxed text-indigo-100 font-mono">
                                            <code>{selectedIssue.codeSnippet}</code>
                                        </pre>
                                    </div>
                                </div>
                            )}

                            <div>
                                <h5 className="text-[10px] font-black uppercase text-emerald-600 mb-3 tracking-[0.2em]">Resolution Protocol</h5>
                                <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-5 border-l-4 border-l-emerald-500">
                                    <div className="flex gap-3">
                                        <Zap size={18} className="text-emerald-600 flex-none" />
                                        <p className="text-sm text-emerald-900 font-semibold leading-relaxed">
                                            {selectedIssue.recommendation}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="mt-12 flex justify-end">
                            <button
                                onClick={() => setSelectedIssue(null)}
                                className="px-10 py-4 bg-slate-900 text-white text-[10px] font-black uppercase tracking-[0.2em] hover:bg-indigo-600 transition-all shadow-lg hover:shadow-indigo-500/20 italic"
                            >
                                Close Analysis
                            </button>
                        </div>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default AICodeReport;
