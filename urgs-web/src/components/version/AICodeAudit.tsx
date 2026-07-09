import React, { useEffect, useMemo, useState } from 'react';
import {
    askAICodeReview,
    getAICodeReviewByCommit,
    getAICodeReviews,
    getRepoCommits,
    GitCommit,
    triggerAICodeReview,
} from '../../api/version';
import {
    AlertTriangle,
    ArrowUpRight,
    Bot,
    CheckCircle,
    Clock,
    FileCode,
    GitCommit as GitCommitIcon,
    Loader2,
    MessageSquareText,
    RefreshCw,
    Search,
    Shield,
    Sparkles,
    Terminal,
    User,
    Zap,
} from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { Button, Input, message, Modal, Progress, Select, Tag } from 'antd';
import {
    AuditIssue,
    getScoreTone,
    getSeverityClassName,
    getSeverityLabel,
    getStatusClassName,
    getStatusLabel,
    parseAICodeReview,
    parseAICodeReviews,
    ParsedAICodeReview,
    summarizeReviews,
} from './aiCodeReviewModel';

interface Props {
    ssoId?: number;
    repoId?: number;
}

interface ReviewQuestion {
    question: string;
    answer: string;
    createdAt: string;
}

const STATUS_FILTERS = [
    { key: 'ALL', label: '全部' },
    { key: 'COMPLETED', label: '已完成' },
    { key: 'PENDING', label: '分析中' },
    { key: 'FAILED', label: '失败' },
];

const QUICK_QUESTIONS = [
    '哪些问题会阻断合并？',
    '按修复优先级给我一个顺序',
    '这次变更最可能影响哪个模块？',
];

const formatDateTime = (value?: string) => {
    if (!value) {
        return '-';
    }
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
        return value;
    }
    return date.toLocaleString();
};

const formatCommit = (sha?: string) => {
    if (!sha) {
        return '-';
    }
    return sha.length > 8 ? sha.substring(0, 8) : sha;
};

const AICodeAudit: React.FC<Props> = ({ repoId }) => {
    const [reviews, setReviews] = useState<ParsedAICodeReview[]>([]);
    const [commits, setCommits] = useState<GitCommit[]>([]);
    const [selectedReview, setSelectedReview] = useState<ParsedAICodeReview | null>(null);
    const [selectedIssue, setSelectedIssue] = useState<AuditIssue | null>(null);
    const [loading, setLoading] = useState(false);
    const [commitLoading, setCommitLoading] = useState(false);
    const [triggering, setTriggering] = useState(false);
    const [isRunModalOpen, setIsRunModalOpen] = useState(false);
    const [isIssueModalOpen, setIsIssueModalOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('ALL');
    const [severityFilter, setSeverityFilter] = useState<'ALL' | AuditIssue['severity']>('ALL');
    const [question, setQuestion] = useState('');
    const [questionLoading, setQuestionLoading] = useState(false);
    const [questionHistory, setQuestionHistory] = useState<Record<number, ReviewQuestion[]>>({});
    const [runTarget, setRunTarget] = useState({
        commitSha: '',
        branch: '',
        email: '',
    });

    const fetchReviews = async () => {
        setLoading(true);
        try {
            const data = await getAICodeReviews(repoId ? { repoId } : {});
            const parsed = parseAICodeReviews(data || []).sort((a, b) => {
                const aTime = a.createdAt ? new Date(a.createdAt).getTime() : 0;
                const bTime = b.createdAt ? new Date(b.createdAt).getTime() : 0;
                return bTime - aTime;
            });
            setReviews(parsed);
            setSelectedReview((current) => parsed.find((item) => item.id === current?.id) || parsed[0] || null);
        } catch (error: any) {
            message.error(error?.message || '加载智查报告失败');
        } finally {
            setLoading(false);
        }
    };

    const fetchCommits = async () => {
        if (!repoId) {
            return;
        }
        setCommitLoading(true);
        try {
            const data = await getRepoCommits(repoId, { page: 1, perPage: 20 });
            setCommits(data || []);
        } catch (error) {
            console.warn('Failed to load recent commits', error);
        } finally {
            setCommitLoading(false);
        }
    };

    useEffect(() => {
        fetchReviews();
        fetchCommits();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [repoId]);

    useEffect(() => {
        if (!reviews.some((review) => review.status === 'PENDING')) {
            return;
        }
        const timer = window.setInterval(fetchReviews, 5000);
        return () => window.clearInterval(timer);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [reviews]);

    const filteredReviews = useMemo(() => {
        const keyword = searchTerm.trim().toLowerCase();
        return reviews.filter((review) => {
            const matchesStatus = statusFilter === 'ALL' || review.status === statusFilter;
            const matchesSeverity =
                severityFilter === 'ALL' || review.issues.some((issue) => issue.severity === severityFilter);
            const matchesKeyword =
                !keyword ||
                review.commitSha?.toLowerCase().includes(keyword) ||
                review.branch?.toLowerCase().includes(keyword) ||
                review.developerEmail?.toLowerCase().includes(keyword) ||
                review.displaySummary.toLowerCase().includes(keyword);
            return matchesStatus && matchesSeverity && matchesKeyword;
        });
    }, [reviews, searchTerm, statusFilter, severityFilter]);

    const stats = useMemo(() => summarizeReviews(reviews), [reviews]);
    const selectedTone = getScoreTone(selectedReview?.score);
    const selectedQuestions = selectedReview ? questionHistory[selectedReview.id] || [] : [];
    const selectedIssues = selectedReview
        ? selectedReview.issues.filter((issue) => severityFilter === 'ALL' || issue.severity === severityFilter)
        : [];

    const pollTriggeredReview = (commitSha: string) => {
        let attempts = 0;
        const timer = window.setInterval(async () => {
            attempts += 1;
            try {
                const review = await getAICodeReviewByCommit(commitSha);
                if (review) {
                    const parsed = parseAICodeReview(review);
                    setSelectedReview(parsed);
                    await fetchReviews();
                    if (review.status !== 'PENDING') {
                        window.clearInterval(timer);
                    }
                }
            } catch (error) {
                if (attempts >= 20) {
                    window.clearInterval(timer);
                }
            }
        }, 3000);
    };

    const handleTriggerReview = async () => {
        if (!repoId) {
            message.warning('请先选择仓库');
            return;
        }
        const commitSha = runTarget.commitSha.trim();
        if (!commitSha) {
            message.warning('请选择或输入 Commit SHA');
            return;
        }
        setTriggering(true);
        try {
            await triggerAICodeReview({
                repoId,
                commitSha,
                branch: runTarget.branch.trim() || undefined,
                email: runTarget.email.trim() || undefined,
            });
            message.success('已提交 AI 智查任务');
            setIsRunModalOpen(false);
            pollTriggeredReview(commitSha);
            window.setTimeout(fetchReviews, 1200);
        } catch (error: any) {
            message.error(error?.message || '提交智查任务失败');
        } finally {
            setTriggering(false);
        }
    };

    const handleAskReview = async (nextQuestion?: string, issue?: AuditIssue) => {
        const review = selectedReview;
        const finalQuestion = (nextQuestion || question).trim();
        if (!review || !finalQuestion) {
            return;
        }
        if (review.status !== 'COMPLETED') {
            message.warning('报告完成后才能追问');
            return;
        }
        setQuestionLoading(true);
        try {
            const response = await askAICodeReview(review.id, {
                question: finalQuestion,
                issueTitle: issue?.title,
                issueSeverity: issue?.severity,
            });
            setQuestionHistory((current) => ({
                ...current,
                [review.id]: [
                    ...(current[review.id] || []),
                    {
                        question: finalQuestion,
                        answer: response.answer,
                        createdAt: response.generatedAt || new Date().toISOString(),
                    },
                ],
            }));
            setQuestion('');
        } catch (error: any) {
            message.error(error?.message || '报告追问失败');
        } finally {
            setQuestionLoading(false);
        }
    };

    return (
        <div className="flex h-[calc(100vh-140px)] flex-col gap-4 overflow-hidden rounded-2xl border border-slate-200 bg-slate-50 p-4">
            <div className="grid flex-none grid-cols-1 gap-3 md:grid-cols-4">
                {[
                    { label: '平均分', value: stats.averageScore || '-', icon: Shield, tone: 'text-emerald-700 bg-emerald-50 border-emerald-200' },
                    { label: '审查记录', value: stats.total, icon: FileCode, tone: 'text-sky-700 bg-sky-50 border-sky-200' },
                    { label: '高危问题', value: stats.criticalIssues, icon: AlertTriangle, tone: 'text-rose-700 bg-rose-50 border-rose-200' },
                    { label: '分析中', value: stats.pending, icon: Clock, tone: 'text-amber-700 bg-amber-50 border-amber-200' },
                ].map((item) => (
                    <div key={item.label} className="flex items-center justify-between rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-sm">
                        <div>
                            <div className="text-[11px] font-semibold text-slate-500">{item.label}</div>
                            <div className="mt-1 text-2xl font-bold text-slate-900">{item.value}</div>
                        </div>
                        <div className={`flex h-10 w-10 items-center justify-center rounded-lg border ${item.tone}`}>
                            <item.icon size={18} />
                        </div>
                    </div>
                ))}
            </div>

            <div className="flex min-h-0 flex-1 gap-4 overflow-hidden">
                <aside className="flex w-[360px] flex-none flex-col overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
                    <div className="border-b border-slate-100 p-3">
                        <div className="mb-3 flex items-center justify-between gap-2">
                            <div>
                                <div className="text-sm font-bold text-slate-900">代码智查</div>
                                <div className="text-[11px] text-slate-500">PR / Commit 审查记录</div>
                            </div>
                            <Button
                                type="primary"
                                size="small"
                                className="bg-slate-900"
                                icon={<Sparkles size={14} />}
                                onClick={() => setIsRunModalOpen(true)}
                            >
                                新智查
                            </Button>
                        </div>
                        <div className="flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2">
                            <Search size={14} className="text-slate-400" />
                            <input
                                value={searchTerm}
                                onChange={(event) => setSearchTerm(event.target.value)}
                                placeholder="搜索分支、提交、开发者"
                                className="w-full border-none bg-transparent text-xs text-slate-700 outline-none placeholder:text-slate-400"
                            />
                        </div>
                        <div className="mt-3 flex flex-wrap gap-2">
                            {STATUS_FILTERS.map((item) => (
                                <button
                                    key={item.key}
                                    onClick={() => setStatusFilter(item.key)}
                                    className={`rounded-full border px-2.5 py-1 text-[11px] font-semibold transition-colors ${
                                        statusFilter === item.key
                                            ? 'border-slate-900 bg-slate-900 text-white'
                                            : 'border-slate-200 bg-white text-slate-500 hover:border-slate-300'
                                    }`}
                                >
                                    {item.label}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div className="min-h-0 flex-1 overflow-y-auto p-3">
                        {loading && reviews.length === 0 ? (
                            <div className="flex h-full items-center justify-center text-sm text-slate-400">
                                <Loader2 size={18} className="mr-2 animate-spin" />
                                加载中
                            </div>
                        ) : filteredReviews.length === 0 ? (
                            <div className="flex h-full flex-col items-center justify-center px-8 text-center text-slate-400">
                                <Bot size={36} className="mb-3 text-slate-300" />
                                <div className="text-sm font-semibold text-slate-600">暂无匹配记录</div>
                                <div className="mt-1 text-xs">可以发起一次新的 Commit 智查</div>
                            </div>
                        ) : (
                            <div className="space-y-2">
                                {filteredReviews.map((review) => {
                                    const tone = getScoreTone(review.score);
                                    return (
                                        <button
                                            type="button"
                                            key={review.id}
                                            onClick={() => setSelectedReview(review)}
                                            className={`w-full rounded-xl border p-3 text-left transition-all ${
                                                selectedReview?.id === review.id
                                                    ? 'border-slate-900 bg-slate-50 shadow-sm'
                                                    : 'border-slate-100 bg-white hover:border-slate-300'
                                            }`}
                                        >
                                            <div className="mb-2 flex items-start justify-between gap-2">
                                                <div className="min-w-0">
                                                    <div className="flex items-center gap-2">
                                                        <span className="rounded bg-slate-100 px-1.5 py-0.5 font-mono text-[10px] font-bold text-slate-700">
                                                            {formatCommit(review.commitSha)}
                                                        </span>
                                                        <span className={`rounded-full border px-2 py-0.5 text-[10px] font-semibold ${getStatusClassName(review.status)}`}>
                                                            {getStatusLabel(review.status)}
                                                        </span>
                                                    </div>
                                                    <div className="mt-2 line-clamp-2 text-xs font-semibold leading-5 text-slate-800">
                                                        {review.displaySummary}
                                                    </div>
                                                </div>
                                                <div className={`flex h-11 w-11 flex-none items-center justify-center rounded-lg border text-base font-bold ${tone.bg} ${tone.text} ${tone.border}`}>
                                                    {review.score || '-'}
                                                </div>
                                            </div>
                                            <div className="flex items-center justify-between border-t border-slate-100 pt-2 text-[11px] text-slate-500">
                                                <span className="flex min-w-0 items-center gap-1">
                                                    <GitCommitIcon size={11} />
                                                    <span className="truncate">{review.branch || '未记录分支'}</span>
                                                </span>
                                                <span>{review.issues.length} 个问题</span>
                                            </div>
                                        </button>
                                    );
                                })}
                            </div>
                        )}
                    </div>
                </aside>

                <main className="min-w-0 flex-1 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
                    {selectedReview ? (
                        <div className="flex h-full flex-col overflow-hidden">
                            <div className="flex flex-none items-start justify-between gap-4 border-b border-slate-100 bg-white px-5 py-4">
                                <div className="flex min-w-0 items-start gap-4">
                                    <div className="relative h-20 w-20 flex-none">
                                        <Progress
                                            type="circle"
                                            percent={selectedReview.score || 0}
                                            size={80}
                                            strokeWidth={8}
                                            strokeColor={selectedTone.stroke}
                                            trailColor="#e2e8f0"
                                            format={() => (
                                                <span className={`text-xl font-bold ${selectedTone.text}`}>
                                                    {selectedReview.score || '-'}
                                                </span>
                                            )}
                                        />
                                    </div>
                                    <div className="min-w-0">
                                        <div className="flex flex-wrap items-center gap-2">
                                            <h2 className="m-0 text-lg font-bold text-slate-900">智查报告</h2>
                                            <Tag className={`m-0 border ${selectedTone.bg} ${selectedTone.text} ${selectedTone.border}`}>
                                                {selectedTone.label}
                                            </Tag>
                                            <Tag className={`m-0 border ${getStatusClassName(selectedReview.status)}`}>
                                                {getStatusLabel(selectedReview.status)}
                                            </Tag>
                                        </div>
                                        <p className="mt-2 line-clamp-2 max-w-3xl text-sm leading-6 text-slate-600">
                                            {selectedReview.displaySummary}
                                        </p>
                                        <div className="mt-2 flex flex-wrap gap-2 text-[11px] text-slate-500">
                                            <span className="flex items-center gap-1 rounded-md border border-slate-200 bg-slate-50 px-2 py-1 font-mono">
                                                <GitCommitIcon size={11} /> {formatCommit(selectedReview.commitSha)}
                                            </span>
                                            <span className="flex items-center gap-1 rounded-md border border-slate-200 bg-slate-50 px-2 py-1">
                                                <User size={11} /> {selectedReview.developerEmail || '未记录开发者'}
                                            </span>
                                            <span className="flex items-center gap-1 rounded-md border border-slate-200 bg-slate-50 px-2 py-1">
                                                <Clock size={11} /> {formatDateTime(selectedReview.createdAt)}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                                <Button icon={<RefreshCw size={14} />} onClick={fetchReviews} loading={loading}>
                                    刷新
                                </Button>
                            </div>

                            <div className="grid min-h-0 flex-1 grid-cols-1 gap-4 overflow-y-auto bg-slate-50 p-4 xl:grid-cols-[minmax(0,1fr)_380px]">
                                <section className="space-y-4">
                                    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
                                        {[
                                            { label: '安全性', value: selectedReview.scoreBreakdown.security, icon: Shield },
                                            { label: '可靠性', value: selectedReview.scoreBreakdown.reliability, icon: AlertTriangle },
                                            { label: '可维护', value: selectedReview.scoreBreakdown.maintainability, icon: FileCode },
                                            { label: '性能', value: selectedReview.scoreBreakdown.performance, icon: Zap },
                                        ].map((item) => {
                                            const tone = getScoreTone(item.value);
                                            return (
                                                <div key={item.label} className="rounded-xl border border-slate-200 bg-white p-3">
                                                    <div className="mb-3 flex items-center justify-between text-xs font-semibold text-slate-500">
                                                        <span>{item.label}</span>
                                                        <item.icon size={14} />
                                                    </div>
                                                    <div className={`text-2xl font-bold ${tone.text}`}>{item.value || '-'}</div>
                                                </div>
                                            );
                                        })}
                                    </div>

                                    <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
                                        <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
                                            <div className="flex items-center gap-2 text-sm font-bold text-slate-900">
                                                <Bot size={16} className="text-slate-500" />
                                                AI 分析报告
                                            </div>
                                            <div className="flex gap-2">
                                                {(['ALL', 'critical', 'major', 'minor'] as const).map((item) => (
                                                    <button
                                                        key={item}
                                                        onClick={() => setSeverityFilter(item)}
                                                        className={`rounded-full border px-2.5 py-1 text-[11px] font-semibold ${
                                                            severityFilter === item
                                                                ? 'border-slate-900 bg-slate-900 text-white'
                                                                : 'border-slate-200 bg-white text-slate-500'
                                                        }`}
                                                    >
                                                        {item === 'ALL' ? '全部问题' : getSeverityLabel(item)}
                                                    </button>
                                                ))}
                                            </div>
                                        </div>
                                        <div className="prose prose-sm max-w-none p-5 prose-headings:text-slate-900 prose-p:text-slate-700 prose-pre:bg-slate-950 prose-pre:text-slate-100">
                                            {selectedReview.reportContent ? (
                                                <ReactMarkdown>{selectedReview.reportContent}</ReactMarkdown>
                                            ) : (
                                                <div className="flex items-center justify-center py-16 text-sm text-slate-400">
                                                    {selectedReview.status === 'PENDING' ? (
                                                        <>
                                                            <Loader2 size={18} className="mr-2 animate-spin" />
                                                            报告生成中
                                                        </>
                                                    ) : (
                                                        '暂无报告内容'
                                                    )}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </section>

                                <aside className="space-y-4">
                                    <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
                                        <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
                                            <div className="flex items-center gap-2 text-sm font-bold text-slate-900">
                                                <AlertTriangle size={16} className="text-amber-600" />
                                                问题清单
                                            </div>
                                            <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11px] font-bold text-slate-600">
                                                {selectedIssues.length}
                                            </span>
                                        </div>
                                        <div className="max-h-[360px] overflow-y-auto">
                                            {selectedIssues.length > 0 ? (
                                                selectedIssues.map((issue, index) => (
                                                    <button
                                                        type="button"
                                                        key={`${issue.title}-${index}`}
                                                        onClick={() => {
                                                            setSelectedIssue(issue);
                                                            setIsIssueModalOpen(true);
                                                        }}
                                                        className="w-full border-b border-slate-50 p-4 text-left transition-colors hover:bg-slate-50"
                                                    >
                                                        <div className="mb-2 flex items-start gap-2">
                                                            <span className={`flex-none rounded border px-2 py-0.5 text-[10px] font-bold ${getSeverityClassName(issue.severity)}`}>
                                                                {getSeverityLabel(issue.severity)}
                                                            </span>
                                                            <span className="text-xs font-semibold leading-5 text-slate-800">
                                                                {issue.title}
                                                            </span>
                                                        </div>
                                                        {issue.line && (
                                                            <div className="flex items-center gap-1 text-[11px] text-slate-500">
                                                                <Terminal size={11} />
                                                                Line {issue.line}
                                                            </div>
                                                        )}
                                                    </button>
                                                ))
                                            ) : (
                                                <div className="px-6 py-10 text-center text-xs text-slate-400">
                                                    <CheckCircle size={28} className="mx-auto mb-2 text-emerald-500" />
                                                    当前筛选下没有问题
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    <div className="rounded-xl border border-slate-200 bg-white p-4">
                                        <div className="mb-3 flex items-center gap-2 text-sm font-bold text-slate-900">
                                            <MessageSquareText size={16} className="text-slate-500" />
                                            报告追问
                                        </div>
                                        <div className="mb-3 flex flex-wrap gap-2">
                                            {QUICK_QUESTIONS.map((item) => (
                                                <button
                                                    type="button"
                                                    key={item}
                                                    disabled={questionLoading || selectedReview.status !== 'COMPLETED'}
                                                    onClick={() => handleAskReview(item)}
                                                    className="rounded-full border border-slate-200 bg-slate-50 px-2.5 py-1 text-[11px] font-semibold text-slate-600 hover:border-slate-300 disabled:cursor-not-allowed disabled:opacity-50"
                                                >
                                                    {item}
                                                </button>
                                            ))}
                                        </div>
                                        <Input.TextArea
                                            value={question}
                                            onChange={(event) => setQuestion(event.target.value)}
                                            rows={3}
                                            placeholder="针对当前报告追问..."
                                            disabled={selectedReview.status !== 'COMPLETED'}
                                        />
                                        <Button
                                            type="primary"
                                            className="mt-3 w-full bg-slate-900"
                                            icon={questionLoading ? <Loader2 size={14} className="animate-spin" /> : <ArrowUpRight size={14} />}
                                            loading={questionLoading}
                                            onClick={() => handleAskReview()}
                                            disabled={!question.trim() || selectedReview.status !== 'COMPLETED'}
                                        >
                                            提交追问
                                        </Button>

                                        <div className="mt-4 space-y-3">
                                            {selectedQuestions.map((item, index) => (
                                                <div key={`${item.createdAt}-${index}`} className="rounded-lg border border-slate-200 bg-slate-50 p-3">
                                                    <div className="mb-2 text-xs font-bold text-slate-800">{item.question}</div>
                                                    <div className="prose prose-xs max-w-none text-xs text-slate-600">
                                                        <ReactMarkdown>{item.answer}</ReactMarkdown>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                </aside>
                            </div>
                        </div>
                    ) : (
                        <div className="flex h-full flex-col items-center justify-center text-center text-slate-400">
                            <Bot size={44} className="mb-3 text-slate-300" />
                            <div className="text-base font-bold text-slate-700">还没有智查报告</div>
                            <Button className="mt-4" type="primary" icon={<Sparkles size={14} />} onClick={() => setIsRunModalOpen(true)}>
                                发起代码智查
                            </Button>
                        </div>
                    )}
                </main>
            </div>

            <Modal
                title="发起代码智查"
                open={isRunModalOpen}
                onCancel={() => setIsRunModalOpen(false)}
                onOk={handleTriggerReview}
                okText="提交智查"
                confirmLoading={triggering}
                destroyOnClose
            >
                <div className="space-y-4 pt-2">
                    <div>
                        <label className="mb-1 block text-xs font-semibold text-slate-500">最近提交</label>
                        <Select
                            className="w-full"
                            loading={commitLoading}
                            placeholder="选择最近提交或手动输入 SHA"
                            value={runTarget.commitSha || undefined}
                            onChange={(value) => {
                                const commit = commits.find((item) => item.sha === value);
                                setRunTarget({
                                    ...runTarget,
                                    commitSha: value,
                                    email: commit?.authorEmail || runTarget.email,
                                });
                            }}
                            showSearch
                            optionFilterProp="label"
                        >
                            {commits.map((commit) => (
                                <Select.Option
                                    key={commit.sha}
                                    value={commit.sha}
                                    label={`${formatCommit(commit.sha)} ${commit.message}`}
                                >
                                    <div className="flex flex-col">
                                        <span className="font-mono text-xs font-bold text-slate-700">{formatCommit(commit.sha)}</span>
                                        <span className="line-clamp-1 text-xs text-slate-500">{commit.message}</span>
                                    </div>
                                </Select.Option>
                            ))}
                        </Select>
                    </div>
                    <div>
                        <label className="mb-1 block text-xs font-semibold text-slate-500">Commit SHA</label>
                        <Input
                            value={runTarget.commitSha}
                            onChange={(event) => setRunTarget({ ...runTarget, commitSha: event.target.value })}
                            placeholder="例如 8f3a2b1..."
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-3">
                        <div>
                            <label className="mb-1 block text-xs font-semibold text-slate-500">分支</label>
                            <Input
                                value={runTarget.branch}
                                onChange={(event) => setRunTarget({ ...runTarget, branch: event.target.value })}
                                placeholder="main / feature..."
                            />
                        </div>
                        <div>
                            <label className="mb-1 block text-xs font-semibold text-slate-500">开发者邮箱</label>
                            <Input
                                value={runTarget.email}
                                onChange={(event) => setRunTarget({ ...runTarget, email: event.target.value })}
                                placeholder="可选"
                            />
                        </div>
                    </div>
                </div>
            </Modal>

            <Modal
                title={null}
                open={isIssueModalOpen}
                onCancel={() => setIsIssueModalOpen(false)}
                footer={null}
                width={620}
                destroyOnClose
            >
                {selectedIssue && (
                    <div className="space-y-5 pt-2">
                        <div className="flex items-start gap-3">
                            <span className={`mt-1 rounded border px-2.5 py-1 text-[11px] font-bold ${getSeverityClassName(selectedIssue.severity)}`}>
                                {getSeverityLabel(selectedIssue.severity)}
                            </span>
                            <div>
                                <h3 className="m-0 text-lg font-bold text-slate-900">{selectedIssue.title}</h3>
                                {selectedIssue.line && (
                                    <div className="mt-1 flex items-center gap-1 text-xs text-slate-500">
                                        <Terminal size={12} />
                                        Line {selectedIssue.line}
                                    </div>
                                )}
                            </div>
                        </div>

                        <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                            <div className="mb-2 text-xs font-bold text-slate-500">问题描述</div>
                            <p className="m-0 text-sm leading-6 text-slate-700">{selectedIssue.description || '暂无详细描述。'}</p>
                        </div>

                        {selectedIssue.codeSnippet && (
                            <div className="overflow-hidden rounded-xl border border-slate-800 bg-slate-950">
                                <div className="border-b border-white/10 px-3 py-2 font-mono text-[11px] text-slate-400">source</div>
                                <pre className="m-0 overflow-x-auto p-4 text-xs leading-6 text-slate-200">
                                    <code>{selectedIssue.codeSnippet}</code>
                                </pre>
                            </div>
                        )}

                        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
                            <div className="mb-2 flex items-center gap-1.5 text-xs font-bold text-amber-700">
                                <Zap size={13} />
                                修复建议
                            </div>
                            <p className="m-0 text-sm leading-6 text-slate-700">{selectedIssue.recommendation || '暂无修复建议。'}</p>
                        </div>

                        <Button
                            type="primary"
                            className="w-full bg-slate-900"
                            icon={<MessageSquareText size={14} />}
                            loading={questionLoading}
                            onClick={() => {
                                setIsIssueModalOpen(false);
                                handleAskReview(`围绕这个问题给出更具体的修复方案：${selectedIssue.title}`, selectedIssue);
                            }}
                        >
                            追问这个问题
                        </Button>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default AICodeAudit;
