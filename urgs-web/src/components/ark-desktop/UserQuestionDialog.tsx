import React, { useEffect, useState } from 'react';
import { Check, ChevronLeft, CircleHelp, LoaderCircle } from 'lucide-react';
import type { ArkDesktopUserQuestionRequest } from './types';

interface UserQuestionDialogProps {
    request: ArkDesktopUserQuestionRequest;
    onAnswer: (response: Record<string, unknown>) => Promise<void>;
}

const questionKey = (question: ArkDesktopUserQuestionRequest['questions'][number]) => question.id || question.question;
const hasCustomInput = (label: string) => /^(other|其他)/i.test(label.trim());
const otherOption = { label: 'Other', description: '手工输入你的想法或要求' };

const UserQuestionDialog: React.FC<UserQuestionDialogProps> = ({ request, onAnswer }) => {
    const [answers, setAnswers] = useState<Record<string, string[]>>({});
    const [notes, setNotes] = useState<Record<string, string>>({});
    const [submitting, setSubmitting] = useState(false);
    const [questionIndex, setQuestionIndex] = useState(0);
    const requestKey = `${request.sessionId}:${JSON.stringify(request.requestId)}`;

    useEffect(() => {
        setAnswers({});
        setNotes({});
        setSubmitting(false);
        setQuestionIndex(0);
    }, [requestKey]);

    const question = request.questions[questionIndex];
    const key = questionKey(question);
    const selected = answers[key] || [];
    const options = question.options.some((option) => hasCustomInput(option.label)) ? question.options : [...question.options, otherOption];
    const customSelected = selected.some(hasCustomInput);
    const canContinue = selected.length > 0 && (!customSelected || Boolean(notes[key]?.trim()));

    const updateAnswer = (question: ArkDesktopUserQuestionRequest['questions'][number], label: string) => {
        const key = questionKey(question);
        setAnswers((current) => {
            const selected = current[key] || [];
            const next = question.multiSelect
                ? selected.includes(label) ? selected.filter((item) => item !== label) : [...selected, label]
                : [label];
            return { ...current, [key]: next };
        });
        if (!question.multiSelect && !hasCustomInput(label)) {
            setNotes((current) => {
                const { [key]: _, ...next } = current;
                return next;
            });
        }
    };

    const submit = async (response: Record<string, unknown>) => {
        setSubmitting(true);
        try {
            await onAnswer(response);
        } finally {
            setSubmitting(false);
        }
    };

    const acceptedResponse = () => {
        const annotations = Object.fromEntries(request.questions
            .filter((item) => (answers[questionKey(item)] || []).some(hasCustomInput) && notes[questionKey(item)]?.trim())
            .map((item) => [questionKey(item), { notes: notes[questionKey(item)].trim() }]));
        return {
            outcome: 'accepted',
            answers,
            ...(Object.keys(annotations).length ? { annotations } : {}),
        };
    };

    const partialAnswers = Object.fromEntries(Object.entries(answers).filter(([, selected]) => selected.length).map(([key, selected]) => [key, selected.join(', ')]));

    return (
        <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-950/35 p-5 backdrop-blur-sm" role="dialog" aria-modal="true" aria-label="智能体需要你的选择">
            <div className="w-full max-w-2xl overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl">
                <div className="sticky top-0 z-10 flex items-start gap-3 border-b border-slate-100 bg-white px-6 py-4">
                    <span className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-slate-600"><CircleHelp size={19} /></span>
                    <div className="min-w-0 flex-1"><div className="flex items-center justify-between gap-3"><h2 className="text-lg font-semibold text-slate-900">智能体需要你的选择</h2><span className="shrink-0 text-xs font-medium text-slate-400">{questionIndex + 1} / {request.questions.length}</span></div><p className="mt-0.5 text-sm text-slate-500">逐题选择，最后统一提交给智能体。</p><div className="mt-3 h-1 overflow-hidden rounded-full bg-slate-100"><div className="h-full rounded-full bg-slate-900 transition-all" style={{ width: `${((questionIndex + 1) / request.questions.length) * 100}%` }} /></div></div>
                </div>
                <div className="px-6 py-5">
                    <section key={key}>
                        <div className="mb-4"><h3 className="text-[16px] font-semibold leading-7 text-slate-800">{question.question}</h3><p className="mt-1 text-xs text-slate-400">{question.multiSelect ? '可多选，也可以补充其他想法' : '请选择一项，或填写其他想法'}</p></div>
                        <div className="space-y-2">{options.map((option) => {
                            const active = selected.includes(option.label);
                            return <div key={option.label}>
                                <button type="button" onClick={() => updateAnswer(question, option.label)} className={`flex w-full items-start gap-3 rounded-xl border px-3.5 py-3 text-left transition ${active ? 'border-slate-900 bg-slate-50' : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'}`}>
                                    <span className={`mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center border ${question.multiSelect ? 'rounded-md' : 'rounded-full'} ${active ? 'border-slate-900 bg-slate-900 text-white' : 'border-slate-300 bg-white text-transparent'}`}><Check size={13} strokeWidth={2.5} /></span>
                                    <span className="min-w-0"><span className="block text-sm font-medium text-slate-800">{hasCustomInput(option.label) ? '其他' : option.label}</span>{option.description && <span className="mt-1 block text-xs leading-5 text-slate-500">{option.description}</span>}</span>
                                </button>
                                {active && hasCustomInput(option.label) && <textarea value={notes[key] || ''} onChange={(event) => setNotes((current) => ({ ...current, [key]: event.target.value }))} placeholder="请输入你的具体想法或要求" rows={3} className="mt-2 w-full resize-y rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-slate-400 focus:ring-2 focus:ring-slate-100" />}
                            </div>;
                        })}</div>
                    </section>
                </div>
                <div className="sticky bottom-0 flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 bg-white px-6 py-4">
                    <button type="button" disabled={submitting} onClick={() => void submit({ outcome: 'cancelled' })} className="rounded-lg px-3 py-2 text-sm text-slate-500 hover:bg-slate-100 disabled:opacity-50">取消</button>
                    <div className="flex flex-wrap justify-end gap-2">
                        {request.mode === 'plan' && <><button type="button" disabled={submitting} onClick={() => void submit({ outcome: 'chat_about_this', partial_answers: partialAnswers })} className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50">继续讨论</button><button type="button" disabled={submitting} onClick={() => void submit({ outcome: 'skip_interview', partial_answers: partialAnswers })} className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50">直接规划</button></>}
                        {questionIndex > 0 && <button type="button" disabled={submitting} onClick={() => setQuestionIndex((index) => index - 1)} className="flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-50"><ChevronLeft size={16} />上一步</button>}
                        {questionIndex === request.questions.length - 1 ? <button type="button" disabled={submitting || !canContinue} onClick={() => void submit(acceptedResponse())} className="flex items-center gap-1.5 rounded-lg bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-40">{submitting && <LoaderCircle size={15} className="animate-spin" />}提交选择</button> : <button type="button" disabled={submitting || !canContinue} onClick={() => setQuestionIndex((index) => index + 1)} className="rounded-lg bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-40">下一步</button>}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default UserQuestionDialog;
