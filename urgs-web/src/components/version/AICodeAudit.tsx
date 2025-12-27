import React, { useState, useEffect } from 'react';
import { getAICodeReviews, AICodeReview, triggerAICodeReview } from '../../api/version';
import { Bot, CheckCircle, XCircle, Clock, GitCommit, Search, RefreshCw, FileCode } from 'lucide-react';
import ReactMarkdown from 'react-markdown';

interface Props {
    ssoId?: number;
    repoId?: number;
}

const AICodeAudit: React.FC<Props> = ({ ssoId, repoId }) => {
    const [reviews, setReviews] = useState<AICodeReview[]>([]);
    const [loading, setLoading] = useState(false);
    const [selectedReview, setSelectedReview] = useState<AICodeReview | null>(null);

    const fetchReviews = async () => {
        setLoading(true);
        try {
            const data = await getAICodeReviews({ repoId });
            setReviews(data || []);
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchReviews();
        // Poll every 30s to check for new reviews/status updates
        const interval = setInterval(fetchReviews, 30000);
        return () => clearInterval(interval);
    }, []);

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'COMPLETED': return 'bg-green-100 text-green-700';
            case 'FAILED': return 'bg-red-100 text-red-700';
            default: return 'bg-amber-100 text-amber-700';
        }
    };

    const getScoreColor = (score?: number) => {
        if (!score) return 'text-gray-400';
        if (score >= 90) return 'text-green-600';
        if (score >= 70) return 'text-amber-600';
        return 'text-red-600';
    };

    return (
        <div className="h-[calc(100vh-200px)] flex gap-4">
            {/* List Side */}
            <div className="w-1/3 flex flex-col border-r border-slate-100 pr-4">
                <div className="flex justify-between items-center mb-4">
                    <h3 className="font-semibold text-slate-800 flex items-center gap-2">
                        <Bot size={18} className="text-indigo-600" />
                        AI 审查记录
                    </h3>
                    <button onClick={fetchReviews} className="p-1.5 rounded-md hover:bg-slate-100 text-slate-500">
                        <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
                    </button>
                </div>

                <div className="flex-1 overflow-y-auto space-y-2 pr-1">
                    {reviews.map(review => (
                        <div
                            key={review.id}
                            onClick={() => setSelectedReview(review)}
                            className={`p-3 rounded-lg border cursor-pointer transition-all hover:shadow-md ${selectedReview?.id === review.id ? 'border-indigo-500 bg-indigo-50' : 'border-slate-200 bg-white'
                                }`}
                        >
                            <div className="flex justify-between items-start mb-2">
                                <div className="flex items-center gap-2">
                                    <span className={`text-[10px] uppercase font-bold px-1.5 py-0.5 rounded ${getStatusColor(review.status)}`}>
                                        {review.status}
                                    </span>
                                    <span className="text-xs text-slate-500 font-mono">
                                        {review.commitSha.substring(0, 7)}
                                    </span>
                                </div>
                                {review.score !== undefined && (
                                    <span className={`text-lg font-bold ${getScoreColor(review.score)}`}>
                                        {review.score}
                                    </span>
                                )}
                            </div>
                            <p className="text-sm text-slate-700 line-clamp-2 mb-2">{review.summary || 'Waiting for analysis...'}</p>
                            <div className="flex items-center justify-between text-xs text-slate-400">
                                <span>{review.developerEmail || 'Unknown Dev'}</span>
                                <span className="flex items-center gap-1">
                                    <Clock size={10} />
                                    {review.createdAt ? new Date(review.createdAt).toLocaleString() : '-'}
                                </span>
                            </div>
                        </div>
                    ))}
                    {reviews.length === 0 && !loading && (
                        <div className="text-center py-10 text-slate-400">
                            暂无审查记录
                        </div>
                    )}
                </div>
            </div>

            {/* Detail Side */}
            <div className="w-2/3 flex flex-col h-full overflow-hidden bg-slate-50 rounded-lg p-6">
                {selectedReview ? (
                    <div className="h-full flex flex-col">
                        <div className="mb-6 flex items-start gap-4">
                            <div className="flex-1">
                                <h2 className="text-lg font-bold text-slate-800 mb-1">代码审查详情</h2>
                                <div className="flex gap-4 text-sm text-slate-600">
                                    <div className="flex items-center gap-1">
                                        <GitCommit size={14} />
                                        <span className="font-mono">{selectedReview.commitSha}</span>
                                    </div>
                                    <div className="flex items-center gap-1">
                                        <FileCode size={14} />
                                        <span>{selectedReview.branch}</span>
                                    </div>
                                </div>
                            </div>
                            <div className="text-right">
                                <div className="text-3xl font-bold text-indigo-600">{selectedReview.score || '-'}</div>
                                <div className="text-xs text-slate-400">AI SAFETY SCORE</div>
                            </div>
                        </div>

                        <div className="flex-1 overflow-y-auto bg-white rounded-lg border border-slate-200 p-6 shadow-sm prose prose-sm max-w-none">
                            {selectedReview.content ? (
                                <ReactMarkdown>{selectedReview.content}</ReactMarkdown>
                            ) : (
                                <div className="flex flex-col items-center justify-center h-full text-slate-400">
                                    <Bot size={48} className="mb-2 opacity-20" />
                                    <p>AI 正在分析中...</p>
                                </div>
                            )}
                        </div>
                    </div>
                ) : (
                    <div className="flex flex-col items-center justify-center h-full text-slate-400">
                        <Search size={48} className="mb-4 opacity-20" />
                        <p>请选择一条记录查看详情</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AICodeAudit;
