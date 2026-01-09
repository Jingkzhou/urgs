import React, { useState, useEffect } from 'react';
import { Button, Tabs, Input, Avatar, Tag, Dropdown, Progress, Badge, Tooltip } from 'antd';
import { ArrowLeft, GitPullRequest, GitMerge, Check, X, Clock, MessageSquare, ChevronDown, MonitorCheck, ExternalLink, ShieldCheck, Bot, Loader2, AlertTriangle, Shield, Layers, Zap, FileCode, Terminal, User, CheckCircle, ArrowUpRight } from 'lucide-react';
import { message, Modal } from 'antd';
import PRStatusBadge, { PRStatus } from './components/PRStatusBadge';
import PRTimeline, { TimelineEvent } from './components/PRTimeline';
import PRDiffView from './components/PRDiffView';
import ReactMarkdown from 'react-markdown';
import {
    getPullRequest,
    getPullRequestCommits,
    getPullRequestFiles,
    mergePullRequest,
    closePullRequest,
    GitPullRequest as APIGitPullRequest,
    GitCommit,
    GitCommitDiff,
    getRepoCommits,
    triggerAICodeReview,
    AICodeReview,
    getAICodeReviewByCommit,
    getAICodeReviewDetail
} from '@/api/version';

// 扩展审查结果接口
interface AuditIssue {
    severity: 'critical' | 'major' | 'minor';
    title: string;
    line?: number;
    description?: string;
    recommendation?: string;
    codeSnippet?: string;
}

interface ExtendedReview extends AICodeReview {
    scoreBreakdown?: {
        security: number;
        reliability: number;
        maintainability: number;
        performance: number;
    };
    issues?: AuditIssue[];
    language?: string;
}

interface PullRequestDetailProps {
    repoId: number;
    prId: number;
    onBack: () => void;
}


const PullRequestDetail: React.FC<PullRequestDetailProps> = ({ repoId, prId, onBack }) => {
    const [activeTab, setActiveTab] = useState('conversation');
    const [pr, setPr] = useState<APIGitPullRequest | null>(null);
    const [commits, setCommits] = useState<GitCommit[]>([]);
    const [files, setFiles] = useState<GitCommitDiff[]>([]);
    const [loading, setLoading] = useState(false);
    const [actionLoading, setActionLoading] = useState(false);

    // AI 智查状态
    const [auditStatus, setAuditStatus] = useState<'idle' | 'pending' | 'completed' | 'failed'>('idle');
    const [auditLoading, setAuditLoading] = useState(false);
    const [auditReview, setAuditReview] = useState<ExtendedReview | null>(null);
    const [selectedIssue, setSelectedIssue] = useState<AuditIssue | null>(null);
    const [isIssueModalOpen, setIsIssueModalOpen] = useState(false);

    // 扩展审查结果接口
    // 扩展审查结果接口
    const formatReviewData = (data: AICodeReview): ExtendedReview => {
        let extendedData: Partial<ExtendedReview> = {};
        try {
            if (data.content && (data.content.trim().startsWith('{') || data.content.trim().startsWith('```'))) {
                let jsonStr = data.content;
                // Clean up markdown code blocks if present
                if (jsonStr.includes('```json')) {
                    jsonStr = jsonStr.replace(/```json\n?|```/g, '');
                } else if (jsonStr.includes('```')) {
                    jsonStr = jsonStr.replace(/```\n?|```/g, '');
                }

                const parsed = JSON.parse(jsonStr);
                extendedData = {
                    scoreBreakdown: parsed.scoreBreakdown,
                    issues: parsed.issues,
                    // If the JSON has a summary/content field, prioritize it, otherwise keep original
                    content: parsed.content || parsed.summary || data.content
                };
            }
        } catch (e) {
            console.warn('Failed to parse AI review content JSON', e);
        }

        return {
            ...data,
            ...extendedData
        };
    };

    // 检查是否已有审查结果
    const checkExistingReview = async () => {
        if (!pr?.headSha) return;
        try {
            const res = await getAICodeReviewByCommit(pr.headSha);
            if (res && res.status === 'COMPLETED') {
                setAuditReview(formatReviewData(res));
                setAuditStatus('completed');
            } else if (res && res.status === 'PENDING') {
                setAuditStatus('pending');
                pollStatus(res.id);
            }
        } catch (e) {
            // Ignore
        }
    };

    // 轮询状态
    const pollStatus = (reviewId?: number, commitSha?: string) => {
        if (!reviewId && !commitSha) {
            return;
        }
        let resolvedReviewId = reviewId;
        const interval = setInterval(async () => {
            try {
                let res: AICodeReview | null = null;
                if (resolvedReviewId) {
                    res = await getAICodeReviewDetail(resolvedReviewId);
                } else if (commitSha) {
                    res = await getAICodeReviewByCommit(commitSha);
                    if (res?.id) {
                        resolvedReviewId = res.id;
                    }
                }

                if (res?.status === 'COMPLETED') {
                    setAuditReview(formatReviewData(res));
                    setAuditStatus('completed');
                    clearInterval(interval);
                    message.success('AI 代码智查完成');
                    setAuditLoading(false);
                } else if (res?.status === 'FAILED') {
                    setAuditStatus('failed');
                    clearInterval(interval);
                    message.error('AI 代码智查失败');
                    setAuditLoading(false);
                }
            } catch (error) {
                console.error('Poll failed', error);
            }
        }, 3000);

        // 60s 超时保护
        setTimeout(() => {
            setAuditLoading((loading) => {
                if (loading) {
                    message.warning('分析时间较长，请稍后刷新页面查看结果');
                    // Do not set status to failed, just stop spinner
                    return false;
                }
                return loading;
            });
        }, 60000);
    };

    // 触发 AI 智查
    // 触发 AI 智查
    const handleTriggerAudit = async () => {
        if (!pr) return;

        setAuditLoading(true);
        setAuditStatus('pending');
        setActiveTab('audit'); // 自动切换到智查报告 Tab

        try {
            const result = await triggerAICodeReview({
                repoId,
                commitSha: pr.headSha,
                branch: pr.headRef
            });

            pollStatus(result?.id, pr.headSha);
            message.loading('已触发 AI 分析，正在排队中...');
        } catch (error) {
            console.error('AI 智查触发失败:', error);
            setAuditStatus('failed');
            message.error('AI 智查触发失败');
            setAuditLoading(false);
        }
    };

    useEffect(() => {
        if (pr?.headSha) {
            checkExistingReview();
        }
    }, [pr?.headSha]);

    const fetchData = async () => {
        setLoading(true);
        try {
            // 1. Fetch PR details first to get info
            const prRes = await getPullRequest(repoId, prId);
            if (!prRes) return;

            setPr(prRes);

            // 2. Fetch Commits (using PR specific API to show only source branch commits) and Files in parallel
            const [commitsRes, filesRes] = await Promise.all([
                getPullRequestCommits(repoId, prId),
                getPullRequestFiles(repoId, prId)
            ]);

            if (commitsRes) setCommits(commitsRes);
            if (filesRes) setFiles(filesRes);

        } catch (error) {
            console.error(error);
            message.error('加载 Pull Request 详情失败');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, [repoId, prId]);

    const handleMerge = async () => {
        Modal.confirm({
            title: '确认合并',
            content: '确定要合并此 Pull Request 吗？',
            onOk: async () => {
                setActionLoading(true);
                try {
                    await mergePullRequest(repoId, prId);
                    message.success('合并成功');
                    fetchData(); // Refresh status
                } catch (error) {
                    message.error('合并失败');
                } finally {
                    setActionLoading(false);
                }
            }
        });
    };

    const handleClose = async () => {
        Modal.confirm({
            title: '确认关闭',
            content: '确定要关闭此 Pull Request 吗？',
            okType: 'danger',
            onOk: async () => {
                setActionLoading(true);
                try {
                    await closePullRequest(repoId, prId);
                    message.success('已关闭 PR');
                    fetchData(); // Refresh status
                } catch (error) {
                    message.error('关闭失败');
                } finally {
                    setActionLoading(false);
                }
            }
        });
    };

    if (loading) return <div className="p-10 text-center">Loading...</div>;
    if (!pr) return <div className="p-10 text-center">Pull Request not found</div>;

    // Map status
    let status: PRStatus = 'open';
    const state = pr.state === 'opened' ? 'open' : pr.state;
    if (state === 'closed') status = 'closed';
    if (state === 'merged') status = 'merged';

    return (
        <div className="bg-white min-h-screen">
            {/* Header */}
            <div className="border-b border-slate-200 bg-slate-50/50 z-10 backdrop-blur-sm">
                <div className="max-w-7xl mx-auto px-6 py-4">

                    <div className="flex justify-between items-start">
                        <div>
                            <div className="flex items-center gap-3 mb-2">
                                <h1 className="text-2xl font-semibold text-slate-900 m-0">{pr.title} <span className="text-slate-400 font-normal">#{pr.number}</span></h1>
                                <PRStatusBadge status={status} className="text-sm" />
                            </div>
                            <div className="flex items-center gap-2 text-slate-600 text-sm">
                                <span className="font-semibold text-slate-800">{pr.authorName}</span>
                                <span>想合并 commits 到 <span className="font-mono bg-slate-100 rounded px-1 text-slate-700">{pr.baseRef}</span></span>
                                <span>从 <span className="font-mono bg-slate-100 rounded px-1 text-slate-700">{pr.headRef}</span></span>
                            </div>
                        </div>
                        <div className="flex gap-2">
                            <Button>编辑</Button>
                            <Tooltip title="一键触发 AI 代码智查，分析当前 PR 的代码质量" placement="bottom">
                                <Button
                                    type="default"
                                    className="group relative overflow-hidden border-indigo-200 hover:border-indigo-400 hover:text-indigo-600 transition-all duration-300"
                                    icon={
                                        auditLoading ?
                                            <Loader2 size={16} className="animate-spin text-indigo-500" /> :
                                            <ShieldCheck size={16} className="text-indigo-500 group-hover:scale-110 transition-transform" />
                                    }
                                    onClick={handleTriggerAudit}
                                    loading={auditLoading}
                                    disabled={status !== 'open'}
                                >
                                    <span className="relative z-10">
                                        {auditLoading ? 'AI 分析中...' : 'AI 代码智查'}
                                    </span>
                                    <span className="absolute inset-0 bg-gradient-to-r from-indigo-50 via-purple-50 to-indigo-50 opacity-0 group-hover:opacity-100 transition-opacity" />
                                </Button>
                            </Tooltip>
                            <Button danger onClick={handleClose} loading={actionLoading} disabled={status !== 'open'}>
                                关闭 PR
                            </Button>
                            <Button
                                type="primary"
                                className="bg-[#1a7f37] hover:bg-[#156d2e]"
                                icon={<GitMerge size={16} />}
                                onClick={handleMerge}
                                loading={actionLoading}
                                disabled={status !== 'open'}
                            >
                                合并 Pull Request
                            </Button>
                        </div>
                    </div>
                </div>

                {/* Tabs */}
                <div className="max-w-7xl mx-auto px-6">
                    <Tabs
                        activeKey={activeTab}
                        onChange={setActiveTab}
                        className="custom-tabs"
                        items={[
                            { label: '对话', key: 'conversation' },
                            { label: `提交 (${commits.length})`, key: 'commits' },
                            { label: `文件变更 (${files.length})`, key: 'files' },
                            {
                                label: (
                                    <span className="flex items-center gap-1.5">
                                        <ShieldCheck size={14} className={auditStatus === 'pending' ? 'animate-pulse text-indigo-500' : auditStatus === 'completed' ? 'text-emerald-500' : 'text-slate-400'} />
                                        智查报告
                                        {auditStatus === 'pending' && (
                                            <span className="relative flex h-2 w-2">
                                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75"></span>
                                                <span className="relative inline-flex rounded-full h-2 w-2 bg-indigo-500"></span>
                                            </span>
                                        )}
                                        {auditStatus === 'completed' && auditReview?.score && (
                                            <Tag className="ml-1 bg-emerald-50 text-emerald-600 border-emerald-100 text-[10px] px-1.5 py-0 rounded-full font-bold">
                                                {auditReview.score}
                                            </Tag>
                                        )}
                                    </span>
                                ),
                                key: 'audit'
                            },
                        ]}
                    />
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-6 py-6 grid grid-cols-1 lg:grid-cols-4 gap-8">
                {/* Main Content */}
                <div className="lg:col-span-3">
                    {activeTab === 'conversation' && (
                        <div className="space-y-6">
                            {/* Description Box */}
                            <div className="border border-slate-200 rounded-lg bg-white overflow-hidden">
                                <div className="bg-slate-50 px-4 py-2 border-b border-slate-200 flex justify-between items-center">
                                    <div className="font-semibold text-slate-700 text-sm">描述</div>
                                    <Button type="text" size="small" className="text-slate-500">Edit</Button>
                                </div>
                                <div className="p-4 text-slate-800 prose prose-sm max-w-none">
                                    {/* Using description from PR */}
                                    <ReactMarkdown>{pr.body || 'No description provided.'}</ReactMarkdown>

                                </div>
                            </div>

                            {/* Timeline */}
                            {/* Timeline */}
                            <PRTimeline events={
                                commits.map(c => ({
                                    id: c.sha,
                                    type: 'commit',
                                    user: { name: c.authorName, avatar: c.authorAvatar },
                                    time: c.committedAt,
                                    sha: c.sha,
                                    content: c.message
                                } as TimelineEvent))
                            } />

                            {/* Comment Input */}
                            <div className="flex gap-4 mt-8 pt-6 border-t border-slate-200">
                                <Avatar size="large" className="mt-1">ME</Avatar>
                                <div className="flex-1">
                                    <div className="border border-slate-200 rounded-lg shadow-sm bg-white focus-within:ring-2 focus-within:ring-blue-100 focus-within:border-blue-400 transition-all overflow-hidden">
                                        <div className="bg-slate-50 border-b border-slate-200 px-2 py-1 flex gap-2 text-xs">
                                            <button className="px-2 py-1 font-medium text-slate-700 bg-white rounded shadow-sm">Write</button>
                                            <button className="px-2 py-1 text-slate-500 hover:bg-slate-100 rounded">Preview</button>
                                        </div>
                                        <Input.TextArea
                                            rows={4}
                                            placeholder="留下评论..."
                                            variant="borderless"
                                            className="p-3"
                                        />
                                        <div className="flex justify-end p-2 bg-slate-50 border-t border-slate-200">
                                            <Button type="primary" className="bg-[#1a7f37]">Comment</Button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}

                    {activeTab === 'files' && (
                        <PRDiffView files={files.map(f => ({
                            name: f.newPath || f.oldPath,
                            status: f.status as any, // 'added' | 'modified' | 'deleted'
                            additions: f.additions || 0,
                            deletions: f.deletions || 0,
                            diff: f.diff
                        }))} />
                    )}

                    {activeTab === 'audit' && (
                        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-2 duration-500">
                            {auditStatus === 'idle' && (
                                <div className="p-16 text-center border-2 border-dashed border-slate-200 rounded-2xl bg-slate-50/50">
                                    <div className="w-20 h-20 rounded-full bg-indigo-50 flex items-center justify-center mx-auto mb-6">
                                        <Bot size={40} className="text-indigo-400" />
                                    </div>
                                    <h3 className="text-xl font-bold text-slate-700 mb-2">AI 代码智查</h3>
                                    <p className="text-slate-500 max-w-md mx-auto mb-8">
                                        点击上方的"AI 代码智查"按钮，AI 将自动分析此 Pull Request 中的代码变更，发现潜在的 Bug、安全漏洞和性能问题。
                                    </p>
                                    <Button
                                        type="primary"
                                        size="large"
                                        className="bg-indigo-600 shadow-lg shadow-indigo-200 hover:scale-105 transition-transform"
                                        icon={<ShieldCheck size={18} />}
                                        onClick={handleTriggerAudit}
                                    >
                                        立即开始智能分析
                                    </Button>
                                </div>
                            )}

                            {auditStatus === 'pending' && (
                                <div className="p-20 text-center rounded-2xl bg-white border border-slate-100 shadow-sm relative overflow-hidden">
                                    <div className="absolute inset-0 bg-gradient-to-r from-transparent via-indigo-50/30 to-transparent w-full h-full animate-[shimmer_2s_infinite]"></div>
                                    <Loader2 size={48} className="animate-spin text-indigo-500 mx-auto mb-6 relative z-10" />
                                    <h3 className="text-xl font-bold text-slate-700 mb-2 relative z-10">正在进行智能分析...</h3>
                                    <p className="text-slate-500 relative z-10">AI 正在深度扫描代码变更，这可能需要几秒钟</p>
                                    <div className="mt-8 max-w-xs mx-auto space-y-3 relative z-10">
                                        <div className="flex items-center gap-3 text-sm text-slate-600">
                                            <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
                                            <span>分析代码结构</span>
                                        </div>
                                        <div className="flex items-center gap-3 text-sm text-slate-600 pl-4 border-l border-slate-100">
                                            <div className="w-2 h-2 rounded-full bg-amber-400 animate-pulse delay-300"></div>
                                            <span>检测安全漏洞</span>
                                        </div>
                                        <div className="flex items-center gap-3 text-sm text-slate-600 pl-4 border-l border-slate-100">
                                            <div className="w-2 h-2 rounded-full bg-indigo-400 animate-pulse delay-700"></div>
                                            <span>生成优化建议</span>
                                        </div>
                                    </div>
                                </div>
                            )}

                            {auditStatus === 'completed' && auditReview && (
                                <>
                                    {/* Score Card */}
                                    <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm flex flex-wrap gap-8 items-center justify-between">
                                        <div className="flex items-center gap-6">
                                            <div className="relative w-24 h-24 flex items-center justify-center">
                                                <svg className="transform -rotate-90 w-24 h-24">
                                                    <circle className="text-slate-100" strokeWidth="8" stroke="currentColor" fill="transparent" r="44" cx="48" cy="48" />
                                                    <circle
                                                        className={`${(auditReview.score || 0) >= 80 ? 'text-emerald-500' : (auditReview.score || 0) >= 60 ? 'text-amber-500' : 'text-rose-500'} transition-all duration-1000 ease-out`}
                                                        strokeWidth="8"
                                                        strokeDasharray={276}
                                                        strokeDashoffset={276 - (276 * (auditReview.score || 0)) / 100}
                                                        strokeLinecap="round"
                                                        stroke="currentColor"
                                                        fill="transparent"
                                                        r="44"
                                                        cx="48"
                                                        cy="48"
                                                    />
                                                </svg>
                                                <div className="absolute inset-0 flex flex-col items-center justify-center">
                                                    <span className="text-3xl font-bold text-slate-800">{auditReview.score}</span>
                                                    <span className="text-[10px] text-slate-400 uppercase tracking-wider font-bold">Total Score</span>
                                                </div>
                                            </div>
                                            <div>
                                                <h3 className="text-lg font-bold text-slate-800 mb-1">代码质量评估完成</h3>
                                                <p className="text-sm text-slate-500 mb-3 flex items-center gap-2">
                                                    <CheckCircle size={14} className="text-emerald-500" />
                                                    分析了 {files.length} 个文件的变更
                                                </p>
                                                <div className="flex gap-2">
                                                    {auditReview.score && auditReview.score >= 90 && (
                                                        <span className="px-2 py-0.5 bg-emerald-50 text-emerald-600 text-xs font-bold rounded border border-emerald-100">卓越质量</span>
                                                    )}
                                                    {auditReview.issues && auditReview.issues.length === 0 && (
                                                        <span className="px-2 py-0.5 bg-blue-50 text-blue-600 text-xs font-bold rounded border border-blue-100">无明显问题</span>
                                                    )}
                                                </div>
                                            </div>
                                        </div>

                                        <div className="flex gap-6 border-l border-slate-100 pl-8">
                                            {[
                                                { label: '安全性', score: auditReview.scoreBreakdown?.security, icon: Shield },
                                                { label: '可靠性', score: auditReview.scoreBreakdown?.reliability, icon: AlertTriangle },
                                                { label: '可维护', score: auditReview.scoreBreakdown?.maintainability, icon: Layers },
                                                { label: '高性能', score: auditReview.scoreBreakdown?.performance, icon: Zap },
                                            ].map(item => (
                                                <div key={item.label} className="flex flex-col items-center gap-2">
                                                    <div className="relative w-10 h-10">
                                                        <Progress
                                                            type="circle"
                                                            percent={item.score}
                                                            size={40}
                                                            strokeWidth={8}
                                                            showInfo={false}
                                                            strokeColor={item.score && item.score >= 80 ? '#10b981' : item.score && item.score >= 60 ? '#f59e0b' : '#ef4444'}
                                                            railColor="#f1f5f9"
                                                        />
                                                        <div className="absolute inset-0 flex items-center justify-center">
                                                            <item.icon size={12} className="text-slate-400" />
                                                        </div>
                                                    </div>
                                                    <div className="text-center">
                                                        <div className="text-[10px] font-bold text-slate-400 uppercase tracking-tight">{item.label}</div>
                                                        <div className="text-xs font-bold text-slate-700">{item.score}</div>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
                                        {/* Report Content */}
                                        <div className="xl:col-span-2 space-y-6">
                                            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
                                                <div className="bg-indigo-50/50 px-5 py-3 border-b border-indigo-100/50 flex items-center gap-2">
                                                    <Bot size={16} className="text-indigo-500" />
                                                    <span className="text-xs font-bold text-indigo-900 uppercase tracking-wide">AI 分析报告</span>
                                                </div>
                                                <div className="p-6 prose prose-sm prose-slate max-w-none prose-headings:font-bold prose-h3:text-indigo-600 prose-pre:bg-slate-900 prose-pre:text-slate-50 prose-a:text-indigo-500 hover:prose-a:text-indigo-600">
                                                    <ReactMarkdown>{auditReview.content || ''}</ReactMarkdown>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Issues List */}
                                        <div className="space-y-6">
                                            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
                                                <div className="bg-slate-50/50 px-5 py-3 border-b border-slate-100 flex items-center justify-between">
                                                    <span className="text-xs font-bold text-slate-700 uppercase flex items-center gap-2 tracking-wide">
                                                        <AlertTriangle size={14} className="text-amber-500" />
                                                        发现的问题
                                                    </span>
                                                    <span className="px-2 py-0.5 bg-slate-200 rounded-full text-[10px] font-bold text-slate-600">
                                                        {auditReview.issues?.length || 0}
                                                    </span>
                                                </div>
                                                <div className="divide-y divide-slate-50">
                                                    {auditReview.issues?.map((issue, idx) => (
                                                        <div
                                                            key={idx}
                                                            className="p-4 hover:bg-slate-50 cursor-pointer group transition-colors"
                                                            onClick={() => {
                                                                setSelectedIssue(issue);
                                                                setIsIssueModalOpen(true);
                                                            }}
                                                        >
                                                            <div className="flex items-start gap-2.5 mb-1">
                                                                <span className={`mt-0.5 px-1.5 py-0.5 rounded text-[9px] font-extrabold uppercase tracking-wide border 
                                                                    ${issue.severity === 'critical' ? 'bg-rose-50 text-rose-600 border-rose-100' :
                                                                        issue.severity === 'major' ? 'bg-amber-50 text-amber-600 border-amber-100' :
                                                                            'bg-blue-50 text-blue-600 border-blue-100'}`}>
                                                                    {issue.severity}
                                                                </span>
                                                                <span className="text-xs font-bold text-slate-700 leading-snug group-hover:text-indigo-600 transition-colors line-clamp-2">
                                                                    {issue.title}
                                                                </span>
                                                            </div>
                                                            {issue.line && (
                                                                <div className="flex items-center gap-1.5 ml-[54px] text-[10px] text-slate-400 font-mono">
                                                                    <Terminal size={10} /> Line {issue.line}
                                                                </div>
                                                            )}
                                                        </div>
                                                    ))}
                                                    {(!auditReview.issues || auditReview.issues.length === 0) && (
                                                        <div className="p-8 text-center">
                                                            <CheckCircle size={24} className="text-emerald-400 mx-auto mb-2 opacity-80" />
                                                            <p className="text-xs text-slate-400">未发现明显问题</p>
                                                        </div>
                                                    )}
                                                </div>
                                            </div>

                                            <div className="bg-gradient-to-br from-indigo-600 via-indigo-500 to-purple-600 rounded-xl p-5 text-white shadow-lg shadow-indigo-200 relative overflow-hidden group">
                                                <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity duration-500">
                                                    <Bot size={80} />
                                                </div>
                                                <h3 className="font-bold mb-2 relative z-10 flex items-center gap-2 text-sm">
                                                    <Zap size={14} className="text-yellow-300" />
                                                    AI 智能优化
                                                </h3>
                                                <p className="text-[11px] text-indigo-100 mb-4 relative z-10 opacity-90 leading-relaxed">
                                                    AI 可以自动为检测到的 {auditReview.issues?.length || 0} 个问题生成修复方案。
                                                </p>
                                                <button className="relative z-10 w-full bg-white/10 hover:bg-white/20 border border-white/30 text-white text-[11px] font-bold py-2 rounded-lg transition-all backdrop-blur-md flex items-center justify-center gap-2 shadow-inner">
                                                    <span>应用自动修复</span>
                                                    <ArrowUpRight size={12} />
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Issue Detail Modal */}
                                    <Modal
                                        title={null}
                                        open={isIssueModalOpen}
                                        onCancel={() => setIsIssueModalOpen(false)}
                                        footer={null}
                                        width={500}
                                        className="crystal-modal"
                                        centered
                                        destroyOnHidden
                                    >
                                        {selectedIssue && (
                                            <div className="pt-2">
                                                <div className="flex items-start gap-3 mb-5">
                                                    <div className={`mt-1 flex-none px-2.5 py-1 rounded-md text-[10px] font-extrabold uppercase tracking-wide border 
                                                        ${selectedIssue.severity === 'critical' ? 'bg-rose-50 text-rose-600 border-rose-100' :
                                                            selectedIssue.severity === 'major' ? 'bg-amber-50 text-amber-600 border-amber-100' :
                                                                'bg-blue-50 text-blue-600 border-blue-100'}`}>
                                                        {selectedIssue.severity}
                                                    </div>
                                                    <h3 className="text-lg font-bold text-slate-800 leading-snug">
                                                        {selectedIssue.title}
                                                    </h3>
                                                </div>

                                                <div className="space-y-6">
                                                    <div className="bg-slate-50 p-4 rounded-xl border border-slate-100/80">
                                                        <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                                            <AlertTriangle size={12} /> 问题描述
                                                        </h4>
                                                        <p className="text-sm text-slate-600 leading-relaxed">
                                                            {selectedIssue.description || '暂无详细描述。'}
                                                        </p>
                                                    </div>

                                                    {selectedIssue.line && (
                                                        <div>
                                                            <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                                                <FileCode size={12} /> 代码位置
                                                            </h4>
                                                            <div className="font-mono text-xs text-slate-600 bg-white border border-slate-200 px-3 py-2 rounded-lg flex items-center gap-2">
                                                                <Terminal size={12} className="text-slate-400" />
                                                                Line {selectedIssue.line}
                                                            </div>
                                                        </div>
                                                    )}

                                                    {selectedIssue.codeSnippet && (
                                                        <div>
                                                            <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                                                <FileCode size={12} /> 问题代码片段
                                                            </h4>
                                                            <div className="bg-slate-800 rounded-xl overflow-hidden border border-slate-700 shadow-inner">
                                                                <div className="flex items-center gap-1.5 px-3 py-2 bg-slate-900/50 border-b border-white/5">
                                                                    <div className="w-2.5 h-2.5 rounded-full bg-rose-500/20 border border-rose-500/50"></div>
                                                                    <div className="w-2.5 h-2.5 rounded-full bg-amber-500/20 border border-amber-500/50"></div>
                                                                    <div className="w-2.5 h-2.5 rounded-full bg-emerald-500/20 border border-emerald-500/50"></div>
                                                                </div>
                                                                <div className="p-4 overflow-x-auto">
                                                                    <pre className="font-mono text-[11px] leading-relaxed text-slate-300">
                                                                        <code>{selectedIssue.codeSnippet}</code>
                                                                    </pre>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    )}

                                                    <div>
                                                        <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                                            <Zap size={12} className="text-amber-500 fill-amber-500" /> AI 修复建议
                                                        </h4>
                                                        <div className="bg-amber-50/50 p-4 rounded-xl border border-amber-100/50">
                                                            <p className="text-sm text-slate-700 leading-relaxed">
                                                                {selectedIssue.recommendation || 'AI 正在分析最佳修复方案...'}
                                                            </p>
                                                        </div>
                                                    </div>
                                                </div>

                                                <div className="mt-8 flex justify-end gap-3">
                                                    <Button onClick={() => setIsIssueModalOpen(false)} className="rounded-xl border-slate-200 text-slate-500 text-xs font-bold hover:text-slate-700 hover:border-slate-300">
                                                        关闭
                                                    </Button>
                                                    <Button type="primary" className="bg-indigo-600 rounded-xl shadow-lg shadow-indigo-200 text-xs font-bold flex items-center gap-1.5">
                                                        <Zap size={12} />
                                                        自动修复
                                                    </Button>
                                                </div>
                                            </div>
                                        )}
                                    </Modal>
                                </>
                            )}
                        </div>
                    )}
                </div>

                {/* Sidebar */}
                <div className="space-y-6 text-sm">
                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            审核人 (Reviewers)
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">编辑</span>
                        </div>
                        {pr.reviewers && pr.reviewers.length > 0 ? (
                            pr.reviewers.map((reviewer, idx) => (
                                <div key={idx} className="flex items-center gap-2 mb-2">
                                    <span className={`w-2 h-2 rounded-full ${reviewer.status === 'approved' ? 'bg-green-500' : 'bg-orange-400'}`}></span>
                                    <span className="font-medium">{reviewer.name}</span>
                                    <span className="text-slate-400 ml-auto flex items-center gap-1">
                                        {reviewer.status === 'approved' ? <Check size={12} /> : <MonitorCheck size={12} />}
                                        {reviewer.status === 'approved' ? 'Approved' : 'Pending'}
                                    </span>
                                </div>
                            ))
                        ) : (
                            <div className="text-slate-400 italic text-xs">暂无审核人</div>
                        )}
                    </div>

                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            负责人 (Assignees)
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">编辑</span>
                        </div>
                        {pr.assignees && pr.assignees.length > 0 ? (
                            <div className="flex flex-wrap gap-2">
                                {pr.assignees.map((assignee, idx) => (
                                    <div key={idx} className="flex items-center gap-2">
                                        <Avatar size="small" src={assignee.avatar}>{assignee.name.substring(0, 2).toUpperCase()}</Avatar>
                                        <span>{assignee.name}</span>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <div className="text-slate-400 italic text-xs">暂无负责人</div>
                        )}
                    </div>

                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            标签 (Labels)
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">编辑</span>
                        </div>
                        <div className="flex flex-wrap gap-1">
                            {pr.labels && pr.labels.length > 0 ? (
                                pr.labels.map((label, idx) => (
                                    <Tag key={idx} color={label.color || 'blue'}>{label.name}</Tag>
                                ))
                            ) : (
                                <div className="text-slate-400 italic text-xs">暂无标签</div>
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default PullRequestDetail;
