import React, { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkBreaks from 'remark-breaks';
import remarkGfm from 'remark-gfm';
import { Check, FileText, LoaderCircle } from 'lucide-react';
import type { ArkDesktopPlanApprovalRequest } from './types';

interface PlanApprovalDialogProps {
    request: ArkDesktopPlanApprovalRequest;
    onAnswer: (response: Record<string, unknown>) => Promise<void>;
}

const PlanMarkdown: React.FC<{ content: string }> = ({ content }) => <div className="min-w-0 text-sm leading-6 text-slate-700">
    <ReactMarkdown
        remarkPlugins={[remarkGfm, remarkBreaks]}
        components={{
            pre: ({ children }) => <pre className="my-3 overflow-x-auto rounded-lg bg-slate-900 px-4 py-3 font-mono text-[13px] leading-6 text-slate-100">{children}</pre>,
            code({ className, children, ...props }: any) {
                const isBlock = Boolean(className) || String(children).includes('\n');
                if (isBlock) return <code className="font-mono text-slate-100" {...props}>{children}</code>;
                return <code className="rounded-md bg-slate-100 px-1.5 py-0.5 font-mono text-[0.88em] font-medium text-slate-800" {...props}>{children}</code>;
            },
            h1: ({ children }) => <h1 className="mb-3 mt-5 text-xl font-semibold leading-8 text-slate-950 first:mt-0">{children}</h1>,
            h2: ({ children }) => <h2 className="mb-2.5 mt-5 text-lg font-semibold leading-7 text-slate-950 first:mt-0">{children}</h2>,
            h3: ({ children }) => <h3 className="mb-2 mt-4 text-base font-semibold leading-7 text-slate-900 first:mt-0">{children}</h3>,
            p: ({ children }) => <p className="my-2 first:mt-0 last:mb-0">{children}</p>,
            ul: ({ children, className }) => <ul className={`my-2 space-y-1 pl-6 marker:text-slate-400 ${className?.includes('contains-task-list') ? 'list-none pl-1' : 'list-disc'}`}>{children}</ul>,
            ol: ({ children }) => <ol className="my-2 list-decimal space-y-1 pl-6 marker:font-medium marker:text-slate-500">{children}</ol>,
            li: ({ children, className }) => <li className={`pl-1 ${className?.includes('task-list-item') ? 'flex items-start gap-2 pl-0 [&>input]:mt-[7px]' : ''}`}>{children}</li>,
            blockquote: ({ children }) => <blockquote className="my-3 rounded-r-lg border-l-[3px] border-slate-300 bg-slate-100 py-1 pl-4 pr-3 text-slate-600 [&>p]:my-2">{children}</blockquote>,
            table: ({ children }) => <div className="my-4 max-w-full overflow-x-auto rounded-lg border border-slate-200"><table className="min-w-full border-collapse text-left text-[13px] leading-6">{children}</table></div>,
            thead: ({ children }) => <thead className="bg-white text-slate-700">{children}</thead>,
            th: ({ children }) => <th className="whitespace-nowrap border-b border-slate-200 px-3 py-2 font-semibold">{children}</th>,
            td: ({ children }) => <td className="border-b border-slate-100 px-3 py-2 align-top text-slate-600 last:border-b-0">{children}</td>,
            a: ({ children, href }) => <a href={href} target="_blank" rel="noreferrer" className="font-medium text-blue-600 underline decoration-blue-200 underline-offset-2 transition hover:text-blue-700 hover:decoration-blue-500">{children}</a>,
            hr: () => <hr className="my-4 border-0 border-t border-slate-200" />,
            strong: ({ children }) => <strong className="font-semibold text-slate-900">{children}</strong>,
        }}
    >{content}</ReactMarkdown>
</div>;

const PlanApprovalDialog: React.FC<PlanApprovalDialogProps> = ({ request, onAnswer }) => {
    const [feedback, setFeedback] = useState('');
    const [submitting, setSubmitting] = useState(false);
    const requestKey = `${request.sessionId}:${JSON.stringify(request.requestId)}`;
    const planContent = request.planContent?.trim();
    const hasPlan = Boolean(planContent || request.planSteps?.length);

    useEffect(() => {
        setFeedback('');
        setSubmitting(false);
    }, [requestKey]);

    const submit = async (outcome: 'approved' | 'cancelled' | 'abandoned') => {
        setSubmitting(true);
        try {
            await onAnswer({
                outcome,
                ...(outcome !== 'abandoned' && feedback.trim() ? { feedback: feedback.trim() } : {}),
            });
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-950/35 p-5 backdrop-blur-sm" role="dialog" aria-modal="true" aria-label="审批执行计划">
            <div className="flex max-h-[88vh] w-full max-w-3xl flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl">
                <div className="flex items-start gap-3 border-b border-slate-100 px-6 py-4">
                    <span className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-slate-600"><FileText size={19} /></span>
                    <div><h2 className="text-lg font-semibold text-slate-900">审批执行计划</h2><p className="mt-0.5 text-sm text-slate-500">批准后，智能体会退出计划模式并开始修改工作区文件。</p></div>
                </div>
                <div className="min-h-0 flex-1 overflow-y-auto px-6 py-5">
                    {planContent ? <div className="rounded-xl border border-slate-200 bg-slate-50 p-4"><PlanMarkdown content={planContent} /></div> : request.planSteps?.length ? <ol className="space-y-2 rounded-xl border border-slate-200 bg-slate-50 p-4">{request.planSteps.map((step, index) => <li key={`${step.content}-${index}`} className="flex items-start gap-3 rounded-lg bg-white px-3 py-2.5"><span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-slate-100 text-xs font-semibold text-slate-500">{index + 1}</span><div className="min-w-0"><PlanMarkdown content={step.content} /><span className="text-xs text-slate-400">{step.status === 'in_progress' ? '进行中' : step.status === 'completed' ? '已完成' : step.status === 'cancelled' ? '已取消' : '待执行'}</span></div></li>)}</ol> : <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-6 text-center text-sm leading-6 text-amber-800">当前审批请求没有附带计划正文。你仍可以批准、放弃，或填写意见要求智能体补充计划。</div>}
                    <label className="mt-5 block"><span className="mb-1.5 block text-sm font-medium text-slate-700">修改意见（可选）</span><textarea value={feedback} onChange={(event) => setFeedback(event.target.value)} rows={3} placeholder="例如：先完成核心流程，再补充测试" className="w-full resize-y rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-slate-400 focus:ring-2 focus:ring-slate-100" /></label>
                </div>
                <div className="flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 bg-white px-6 py-4">
                    <button type="button" disabled={submitting} onClick={() => void submit('abandoned')} className="rounded-lg px-3 py-2 text-sm text-slate-500 hover:bg-slate-100 disabled:opacity-50">放弃计划</button>
                    <div className="flex flex-wrap items-center justify-end gap-2">{!hasPlan && <span className="text-xs text-amber-700">运行时未附带计划正文</span>}<button type="button" disabled={submitting} onClick={() => void submit('cancelled')} className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50">{hasPlan ? '返回修改' : '要求补充计划'}</button><button type="button" disabled={submitting} onClick={() => void submit('approved')} title="批准后开始执行计划" className="flex items-center gap-1.5 rounded-lg bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-50">{submitting ? <LoaderCircle size={15} className="animate-spin" /> : <Check size={15} />}{feedback.trim() ? '带意见批准' : '批准并开始实现'}</button></div>
                </div>
            </div>
        </div>
    );
};

export default PlanApprovalDialog;
