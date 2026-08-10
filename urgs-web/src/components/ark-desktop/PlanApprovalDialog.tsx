import React, { useEffect, useState } from 'react';
import { Check, FileText, LoaderCircle } from 'lucide-react';
import type { ArkDesktopPlanApprovalRequest } from './types';

interface PlanApprovalDialogProps {
    request: ArkDesktopPlanApprovalRequest;
    onAnswer: (response: Record<string, unknown>) => Promise<void>;
}

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
                    {planContent ? <pre className="whitespace-pre-wrap break-words rounded-xl border border-slate-200 bg-slate-50 p-4 font-mono text-[13px] leading-6 text-slate-700">{planContent}</pre> : request.planSteps?.length ? <ol className="space-y-2 rounded-xl border border-slate-200 bg-slate-50 p-4">{request.planSteps.map((step, index) => <li key={`${step.content}-${index}`} className="flex items-start gap-3 rounded-lg bg-white px-3 py-2.5"><span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-slate-100 text-xs font-semibold text-slate-500">{index + 1}</span><div className="min-w-0"><p className="text-sm leading-6 text-slate-700">{step.content}</p><span className="text-xs text-slate-400">{step.status === 'in_progress' ? '进行中' : step.status === 'completed' ? '已完成' : step.status === 'cancelled' ? '已取消' : '待执行'}</span></div></li>)}</ol> : <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-6 text-center text-sm leading-6 text-amber-800">当前审批请求没有附带计划正文。你仍可以批准、放弃，或填写意见要求智能体补充计划。</div>}
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
