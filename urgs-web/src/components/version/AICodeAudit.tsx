import React, { useState, useEffect, useMemo } from 'react';
import { getAICodeReviews, AICodeReview } from '../../api/version';
import {
    Bot, CheckCircle, Clock, GitCommit, Search, RefreshCw, FileCode,
    Shield, Activity, Zap, Layers, AlertTriangle, Terminal, User,
    ArrowUpRight, Loader, Check
} from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { Progress, Badge } from 'antd';

interface Props {
    ssoId?: number;
    repoId?: number;
}

// 扩展的 Review 接口
interface ExtendedReview extends AICodeReview {
    scoreBreakdown: {
        security: number;
        reliability: number;
        maintainability: number;
        performance: number;
    };
    issues: {
        severity: 'critical' | 'major' | 'minor';
        title: string;
        line?: number;
    }[];
    language?: string;
}

const AICodeAudit: React.FC<Props> = ({ ssoId, repoId }) => {
    const [reviews, setReviews] = useState<ExtendedReview[]>([]);
    const [loading, setLoading] = useState(false);
    const [selectedReview, setSelectedReview] = useState<ExtendedReview | null>(null);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState<string>('ALL');

    // 模拟数据适配器
    const adaptReviewData = (data: AICodeReview[]): ExtendedReview[] => {
        return data.map(r => ({
            ...r,
            language: 'TypeScript',
            scoreBreakdown: {
                security: r.score ? Math.min(100, r.score + 5) : 85,
                reliability: r.score || 80,
                maintainability: r.score ? Math.max(60, r.score - 5) : 75,
                performance: r.score || 90,
            },
            issues: r.score && r.score > 80 ? [] : [
                { severity: 'critical', title: 'Potential SQL Injection in query builder', line: 42 },
                { severity: 'major', title: 'Unused variable "tempData"', line: 12 },
                { severity: 'minor', title: 'Missing return type annotation', line: 85 },
            ]
        }));
    };

    const fetchReviews = async () => {
        setLoading(true);
        try {
            const data = await getAICodeReviews({ repoId });
            setReviews(adaptReviewData(data || []));
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchReviews();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [repoId]);

    const filteredReviews = useMemo(() => {
        return reviews.filter(r => {
            const matchesSearch =
                r.commitSha.includes(searchTerm) ||
                r.branch?.includes(searchTerm) ||
                r.developerEmail?.includes(searchTerm);
            const matchesStatus = filterStatus === 'ALL' || r.status === filterStatus;
            return matchesSearch && matchesStatus;
        });
    }, [reviews, searchTerm, filterStatus]);

    const stats = useMemo(() => {
        const total = reviews.length;
        const avgScore = total > 0 ? Math.round(reviews.reduce((acc, r) => acc + (r.score || 0), 0) / total) : 0;
        const criticalIssues = reviews.reduce((acc, r) => acc + (r.status === 'FAILED' ? 1 : 0), 0);
        return { total, avgScore, criticalIssues };
    }, [reviews]);

    const getScoreColor = (score?: number) => {
        if (!score) return 'text-slate-400';
        if (score >= 90) return 'text-emerald-500';
        if (score >= 75) return 'text-indigo-500';
        if (score >= 60) return 'text-amber-500';
        return 'text-rose-500';
    };

    const getScoreBg = (score?: number) => {
        if (!score) return 'bg-slate-100';
        if (score >= 90) return 'bg-emerald-50';
        if (score >= 75) return 'bg-indigo-50';
        if (score >= 60) return 'bg-amber-50';
        return 'bg-rose-50';
    };

    const getSeverityColor = (severity: string) => {
        switch (severity) {
            case 'critical': return 'text-rose-600 bg-rose-50 border-rose-100';
            case 'major': return 'text-amber-600 bg-amber-50 border-amber-100';
            case 'minor': return 'text-blue-600 bg-blue-50 border-blue-100';
            default: return 'text-slate-600 bg-slate-50 border-slate-100';
        }
    };

    return (
        <div className="h-[calc(100vh-140px)] flex flex-col gap-5 bg-slate-50/50 p-6 rounded-3xl overflow-hidden border border-slate-100">
            {/* Dashboard Header */}
            <div className="flex-none grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-white p-4 rounded-2xl border border-slate-200/60 shadow-sm flex items-center justify-between group hover:shadow-md transition-all duration-300">
                    <div>
                        <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">代码平均质量</div>
                        <div className="text-2xl font-bold text-slate-800 flex items-center gap-2">
                            {stats.avgScore}
                            <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-md bg-emerald-50 text-emerald-600 flex items-center border border-emerald-100">
                                <ArrowUpRight size={10} className="mr-0.5" /> +2.4%
                            </span>
                        </div>
                    </div>
                    <div className="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center group-hover:scale-110 transition-transform">
                        <Activity size={20} className="text-indigo-600" />
                    </div>
                </div>
                <div className="bg-white p-4 rounded-2xl border border-slate-200/60 shadow-sm flex items-center justify-between group hover:shadow-md transition-all duration-300">
                    <div>
                        <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">总审查次数</div>
                        <div className="text-2xl font-bold text-slate-800">{stats.total}</div>
                    </div>
                    <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center group-hover:scale-110 transition-transform">
                        <Layers size={20} className="text-blue-600" />
                    </div>
                </div>
                <div className="bg-white p-4 rounded-2xl border border-slate-200/60 shadow-sm flex items-center justify-between group hover:shadow-md transition-all duration-300">
                    <div>
                        <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">拦截高危风险</div>
                        <div className="text-2xl font-bold text-slate-800 flex items-center gap-2">
                            {stats.criticalIssues}
                            {stats.criticalIssues > 0 && (
                                <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-md bg-rose-50 text-rose-600 border border-rose-100">ATTENTION</span>
                            )}
                        </div>
                    </div>
                    <div className="w-10 h-10 rounded-xl bg-rose-50 flex items-center justify-center group-hover:scale-110 transition-transform">
                        <Shield size={20} className="text-rose-600" />
                    </div>
                </div>
                <div className="bg-gradient-to-br from-indigo-600 to-purple-600 p-4 rounded-2xl shadow-lg shadow-indigo-200 text-white flex flex-col justify-center items-start cursor-pointer hover:shadow-xl hover:translate-y-[-2px] transition-all duration-300" onClick={fetchReviews}>
                    <div className="flex items-center gap-2 mb-2">
                        <Bot size={18} className="text-indigo-100" />
                        <span className="font-bold text-sm">开始新审查</span>
                    </div>
                    <div className="text-[10px] text-indigo-100 opacity-80 uppercase tracking-wider font-semibold">AI Engine Ready</div>
                </div>
            </div>

            <div className="flex-1 flex gap-5 overflow-hidden">
                {/* Left Listing */}
                <div className="w-[340px] flex-none flex flex-col bg-white rounded-2xl border border-slate-200/60 shadow-sm overflow-hidden">
                    <div className="p-4 border-b border-slate-100 space-y-3 bg-slate-50/30">
                        <div className="flex items-center gap-2 bg-white px-3 py-2.5 rounded-xl border border-slate-200 focus-within:border-indigo-300 focus-within:ring-2 focus-within:ring-indigo-100 transition-all shadow-sm">
                            <Search size={14} className="text-slate-400" />
                            <input
                                type="text"
                                placeholder="搜索 Commit, Branch..."
                                className="bg-transparent border-none outline-none text-xs w-full placeholder:text-slate-400 text-slate-700 font-medium"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
                            {['ALL', 'COMPLETED', 'FAILED', 'PENDING'].map(status => (
                                <button
                                    key={status}
                                    onClick={() => setFilterStatus(status)}
                                    className={`px-3 py-1 text-[10px] font-bold rounded-full border whitespace-nowrap transition-all duration-200
                                        ${filterStatus === status
                                            ? 'bg-indigo-50 border-indigo-200 text-indigo-600 shadow-sm'
                                            : 'bg-white border-slate-200 text-slate-400 hover:border-slate-300 hover:text-slate-500'}`}
                                >
                                    {status}
                                </button>
                            ))}
                        </div>
                    </div>
                    <div className="flex-1 overflow-y-auto p-3 space-y-2.5">
                        {loading && reviews.length === 0 ? (
                            <div className="flex flex-col items-center justify-center p-10 text-slate-300 gap-2">
                                <Loader className="animate-spin" size={20} />
                                <span className="text-xs font-medium">Loading data...</span>
                            </div>
                        ) : filteredReviews.map(review => (
                            <div
                                key={review.id}
                                onClick={() => setSelectedReview(review)}
                                className={`group p-3.5 rounded-xl border cursor-pointer transition-all duration-200 relative overflow-hidden
                                    ${selectedReview?.id === review.id
                                        ? 'border-indigo-500 bg-indigo-50/20 ring-1 ring-indigo-500/20 shadow-sm'
                                        : 'border-slate-100 bg-white hover:border-indigo-200 hover:shadow-md hover:-translate-y-0.5'}`}
                            >
                                {selectedReview?.id === review.id && (
                                    <div className="absolute left-0 top-3 bottom-3 w-1 bg-indigo-500 rounded-r-full" />
                                )}
                                <div className="flex justify-between items-start mb-2 pl-2">
                                    <div className="flex items-center gap-2">
                                        <div className={`w-2 h-2 rounded-full ring-2 ring-white shadow-sm ${review.status === 'COMPLETED' ? 'bg-emerald-400' : 'bg-amber-400'}`} />
                                        <span className="text-xs font-mono font-bold text-slate-700 bg-slate-100 px-1.5 py-0.5 rounded text-[10px]">
                                            {review.commitSha.substring(0, 7)}
                                        </span>
                                    </div>
                                    <div className={`text-sm font-bold ${getScoreColor(review.score)}`}>
                                        {review.score ?? '-'}
                                    </div>
                                </div>
                                <div className="pl-2 mb-2">
                                    <h4 className="text-xs text-slate-700 line-clamp-1 font-semibold">{review.summary || 'Waiting for analysis...'}</h4>
                                    <div className="flex items-center gap-1.5 mt-1.5">
                                        <GitCommit size={10} className="text-slate-400" />
                                        <span className="text-[10px] font-medium text-slate-400 truncate max-w-[140px] bg-slate-50 px-1.5 py-0.5 rounded border border-slate-100">
                                            {review.branch}
                                        </span>
                                    </div>
                                </div>
                                <div className="pl-2 flex items-center justify-between text-[10px] text-slate-400 pt-2 border-t border-slate-50 mt-2">
                                    <div className="flex items-center gap-1.5">
                                        <User size={10} />
                                        <span className="font-medium">{review.developerEmail?.split('@')[0] || 'Unknown'}</span>
                                    </div>
                                    <span className="font-mono opacity-80">{review.createdAt ? new Date(review.createdAt).toLocaleDateString() : ''}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Right Detail Pane */}
                <div className="flex-1 bg-white rounded-2xl border border-slate-200/60 shadow-sm flex flex-col overflow-hidden relative">
                    {selectedReview ? (
                        <>
                            {/* Detail Header */}
                            <div className="p-6 border-b border-slate-100 bg-slate-50/20 backdrop-blur-sm">
                                <div className="flex flex-wrap gap-6 items-start justify-between">
                                    <div className="flex items-center gap-5">
                                        <div className={`relative w-20 h-20 rounded-2xl flex items-center justify-center text-3xl font-bold shadow-lg shadow-slate-200/50 ${getScoreBg(selectedReview.score)} ${getScoreColor(selectedReview.score)}`}>
                                            <svg className="absolute inset-0 w-full h-full -rotate-90 pointer-events-none p-1" viewBox="0 0 100 100">
                                                <circle className="text-slate-200 opacity-20" strokeWidth="6" stroke="currentColor" fill="transparent" r="42" cx="50" cy="50" />
                                                <circle
                                                    className={`transition-all duration-1000 ease-out ${selectedReview.score && selectedReview.score >= 90 ? 'text-emerald-500' : 'text-indigo-500'}`}
                                                    strokeWidth="6"
                                                    strokeDasharray={264}
                                                    strokeDashoffset={264 - (264 * (selectedReview.score || 0)) / 100}
                                                    strokeLinecap="round"
                                                    stroke="currentColor"
                                                    fill="transparent"
                                                    r="42"
                                                    cx="50"
                                                    cy="50"
                                                />
                                            </svg>
                                            {selectedReview.score || '?'}
                                        </div>
                                        <div>
                                            <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-2">
                                                代码质量评估报告
                                                {selectedReview.score && selectedReview.score >= 90 && (
                                                    <Badge status="success" text={<span className="text-emerald-600 text-xs font-bold uppercase tracking-wider bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-100">Excellent</span>} />
                                                )}
                                            </h2>
                                            <div className="flex items-center gap-3 text-xs text-slate-500">
                                                <div className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-white border border-slate-200 shadow-sm">
                                                    <FileCode size={12} className="text-slate-400" />
                                                    <span className="font-mono text-slate-700 font-semibold">{selectedReview.language || 'TypeScript'}</span>
                                                </div>
                                                <div className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-white border border-slate-200 shadow-sm">
                                                    <GitCommit size={12} className="text-slate-400" />
                                                    <span className="font-mono text-slate-700 font-semibold">{selectedReview.commitSha.substring(0, 7)}</span>
                                                </div>
                                                <div className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-white border border-slate-200 shadow-sm">
                                                    <Clock size={12} className="text-slate-400" />
                                                    <span className="font-mono text-slate-700 font-semibold">{new Date(selectedReview.createdAt || '').toLocaleString()}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Multi-dim Score */}
                                    <div className="flex items-center gap-4 bg-white p-2 rounded-xl border border-slate-100 shadow-sm">
                                        {[
                                            { label: 'Security', score: selectedReview.scoreBreakdown?.security, icon: Shield },
                                            { label: 'Reliability', score: selectedReview.scoreBreakdown?.reliability, icon: AlertTriangle },
                                            { label: 'Maint.', score: selectedReview.scoreBreakdown?.maintainability, icon: Layers },
                                            { label: 'Perf.', score: selectedReview.scoreBreakdown?.performance, icon: Zap },
                                        ].map(item => (
                                            <div key={item.label} className="flex flex-col items-center gap-1 px-2 border-r last:border-0 border-slate-100">
                                                <div className="relative w-8 h-8">
                                                    <Progress
                                                        type="circle"
                                                        percent={item.score}
                                                        width={32}
                                                        strokeWidth={10}
                                                        showInfo={false}
                                                        strokeColor={item.score && item.score >= 80 ? '#10b981' : item.score && item.score >= 60 ? '#f59e0b' : '#ef4444'}
                                                        trailColor="#f1f5f9"
                                                    />
                                                    <div className="absolute inset-0 flex items-center justify-center">
                                                        <item.icon size={10} className="text-slate-400" />
                                                    </div>
                                                </div>
                                                <span className="text-[9px] font-bold text-slate-400 uppercase tracking-tight mt-1">{item.label}</span>
                                                <span className="text-[10px] font-bold text-slate-700">{item.score}</span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            </div>

                            {/* Detail Content */}
                            <div className="flex-1 overflow-y-auto p-6 grid grid-cols-1 xl:grid-cols-3 gap-6 bg-slate-50/20">
                                {/* Main Content - MD Render */}
                                <div className="xl:col-span-2 space-y-6">
                                    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                                        <div className="bg-slate-50/50 px-5 py-3 border-b border-slate-100 flex items-center gap-2">
                                            <Bot size={16} className="text-indigo-500" />
                                            <span className="text-xs font-bold text-indigo-900 uppercase tracking-wide">AI Analysis Report</span>
                                        </div>
                                        <div className="p-6 prose prose-sm prose-slate max-w-none prose-headings:font-bold prose-h3:text-indigo-600 prose-pre:bg-slate-900 prose-pre:text-slate-50 prose-a:text-indigo-500 hover:prose-a:text-indigo-600">
                                            {selectedReview.content ? (
                                                <ReactMarkdown>{selectedReview.content}</ReactMarkdown>
                                            ) : (
                                                <div className="flex flex-col items-center justify-center py-16 opacity-50">
                                                    <Loader size={32} className="animate-spin text-indigo-500 mb-3" />
                                                    <span className="font-medium text-slate-500">Analyzing code structure...</span>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>

                                {/* Sidebar - Issues & Stats */}
                                <div className="space-y-6">
                                    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                                        <div className="bg-slate-50/50 px-5 py-3 border-b border-slate-100 flex items-center justify-between">
                                            <span className="text-xs font-bold text-slate-700 uppercase flex items-center gap-2 tracking-wide">
                                                <AlertTriangle size={14} className="text-amber-500" />
                                                Detected Issues
                                            </span>
                                            <div className="px-2 py-0.5 bg-slate-100 rounded-full text-[10px] font-bold text-slate-500">
                                                {selectedReview.issues?.length || 0}
                                            </div>
                                        </div>
                                        <div className="divide-y divide-slate-50 max-h-[400px] overflow-y-auto">
                                            {selectedReview.issues?.map((issue, idx) => (
                                                <div key={idx} className="p-4 hover:bg-slate-50 transition-colors group border-l-2 border-transparent hover:border-indigo-500">
                                                    <div className="flex items-start gap-2.5">
                                                        <span className={`mt-0.5 px-2 py-0.5 rounded text-[9px] font-extrabold uppercase tracking-wide border ${getSeverityColor(issue.severity)}`}>
                                                            {issue.severity}
                                                        </span>
                                                        <span className="text-xs text-slate-700 font-semibold leading-relaxed group-hover:text-indigo-700 transition-colors">
                                                            {issue.title}
                                                        </span>
                                                    </div>
                                                    {issue.line && (
                                                        <div className="mt-2 ml-1 pl-3 border-l-2 border-slate-200 text-[10px] font-mono text-slate-500 flex items-center gap-1">
                                                            <Terminal size={10} />
                                                            Line {issue.line}
                                                        </div>
                                                    )}
                                                </div>
                                            ))}
                                            {(!selectedReview.issues || selectedReview.issues.length === 0) && (
                                                <div className="p-10 text-center text-xs text-slate-400 bg-slate-50/30">
                                                    <CheckCircle size={32} className="mx-auto mb-3 text-emerald-400 opacity-80" />
                                                    <div className="font-semibold text-slate-500">Clean Codebase</div>
                                                    <div className="mt-1 opacity-70">No major issues detected in this review</div>
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    <div className="bg-gradient-to-br from-indigo-600 via-indigo-500 to-purple-600 rounded-2xl p-6 text-white shadow-lg shadow-indigo-200 relative overflow-hidden group">
                                        <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity duration-500">
                                            <Bot size={100} />
                                        </div>
                                        <h3 className="font-bold mb-2 relative z-10 flex items-center gap-2">
                                            <Zap size={16} className="text-yellow-300" />
                                            AI Optimization
                                        </h3>
                                        <p className="text-xs text-indigo-100 mb-5 relative z-10 opacity-90 leading-relaxed">
                                            AI can automatically generate fixes for the detected {selectedReview.issues?.length || 0} issues.
                                        </p>
                                        <button className="relative z-10 w-full bg-white/10 hover:bg-white/20 border border-white/30 text-white text-xs font-bold py-2.5 rounded-xl transition-all backdrop-blur-md flex items-center justify-center gap-2 shadow-inner">
                                            <span>Apply Auto-Fix</span>
                                            <ArrowUpRight size={12} />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </>
                    ) : (
                        <div className="absolute inset-0 flex flex-col items-center justify-center text-slate-300 bg-slate-50/30">
                            <div className="w-24 h-24 bg-white rounded-full flex items-center justify-center mb-6 shadow-sm border border-slate-100">
                                <Search size={40} className="text-slate-200" />
                            </div>
                            <h3 className="text-lg font-bold text-slate-700 mb-2">Ready to Analyze</h3>
                            <p className="text-sm font-medium text-slate-400 max-w-xs text-center leading-relaxed">Select a review from the sidebar to view detailed AI analysis and quality metrics.</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default AICodeAudit;
