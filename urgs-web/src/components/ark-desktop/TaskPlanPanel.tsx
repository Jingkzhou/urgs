import React, { useEffect, useRef, useState } from 'react';
import { CheckCircle2, Circle, ListTodo, LoaderCircle, LocateFixed, XCircle } from 'lucide-react';
import type { ArkDesktopPlanStep, ArkDesktopTaskStatus } from './types';

interface TaskPlanPanelProps {
    plan: ArkDesktopPlanStep[];
    taskStatus: ArkDesktopTaskStatus;
}

const stepIcon = (status: ArkDesktopPlanStep['status']) => {
    if (status === 'completed') return <CheckCircle2 size={16} className="text-emerald-500" />;
    if (status === 'in_progress') return <LoaderCircle size={16} className="animate-spin text-blue-500" />;
    if (status === 'cancelled') return <XCircle size={16} className="text-slate-300" />;
    return <Circle size={16} className="text-slate-300" />;
};

const stepLabel: Record<ArkDesktopPlanStep['status'], string> = {
    pending: '待开始',
    in_progress: '进行中',
    completed: '已完成',
    cancelled: '已跳过',
};

const TaskPlanPanel: React.FC<TaskPlanPanelProps> = ({ plan, taskStatus }) => {
    const [open, setOpen] = useState(false);
    const [followCurrentStep, setFollowCurrentStep] = useState(true);
    const activeStepRef = useRef<HTMLDivElement>(null);
    const autoScrollingRef = useRef(false);
    const completedCount = plan.filter((step) => step.status === 'completed' || step.status === 'cancelled').length;
    const progress = plan.length ? Math.round((completedCount / plan.length) * 100) : 0;
    const statusText = plan.length ? `${completedCount} / ${plan.length} 已完成` : taskStatus === 'running' ? '正在制定计划' : '暂无执行计划';
    const activeStepIndex = plan.findIndex((step) => step.status === 'in_progress');

    useEffect(() => {
        if (!open || !followCurrentStep || activeStepIndex < 0) return;

        const frame = window.requestAnimationFrame(() => {
            autoScrollingRef.current = true;
            activeStepRef.current?.scrollIntoView({ block: 'center' });
            window.requestAnimationFrame(() => {
                autoScrollingRef.current = false;
            });
        });

        return () => window.cancelAnimationFrame(frame);
    }, [activeStepIndex, followCurrentStep, open, plan]);

    const toggleOpen = () => {
        setOpen((current) => {
            const next = !current;
            if (next) setFollowCurrentStep(true);
            return next;
        });
    };

    return (
        <div className="relative">
            <button type="button" onClick={toggleOpen} className={`flex h-7 w-7 items-center justify-center rounded-md transition ${open ? 'bg-slate-200 text-slate-800' : 'text-slate-500 hover:bg-slate-100 hover:text-slate-700'}`} title="查看执行计划" aria-label="查看执行计划" aria-expanded={open}><ListTodo size={17} strokeWidth={1.8} /></button>
            {open && <div className="absolute right-0 top-[calc(100%+10px)] z-50 w-[min(380px,calc(100vw-40px))] overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-[0_18px_45px_rgba(15,23,42,0.16)]">
                <div className="border-b border-slate-100 px-4 py-3"><div className="flex items-center justify-between gap-3"><span className="flex items-center gap-2 text-sm font-semibold text-slate-800"><ListTodo size={17} className="text-slate-500" />执行计划</span><span className="text-xs text-slate-400">{statusText}</span></div><div className="mt-2 h-1.5 overflow-hidden rounded-full bg-slate-100"><div className="h-full rounded-full bg-slate-800 transition-all duration-300" style={{ width: `${progress}%` }} /></div></div>
                <div className="flex items-center justify-between border-b border-slate-100 px-4 py-2 text-xs"><span className={followCurrentStep ? 'text-blue-600' : 'text-slate-400'}>{activeStepIndex >= 0 ? followCurrentStep ? '已锁定当前执行阶段' : '已解除阶段锁定' : '等待执行阶段更新'}</span>{activeStepIndex >= 0 && !followCurrentStep && <button type="button" onClick={() => setFollowCurrentStep(true)} className="flex items-center gap-1 rounded-md px-1.5 py-1 font-medium text-slate-600 hover:bg-slate-100 hover:text-slate-900"><LocateFixed size={13} />定位当前阶段</button>}</div>
                <div className="max-h-[340px] overflow-y-auto px-2 py-2" onScroll={() => { if (!autoScrollingRef.current) setFollowCurrentStep(false); }}>{plan.length ? plan.map((step, index) => <div key={`${step.content}-${index}`} ref={index === activeStepIndex ? activeStepRef : undefined} className={`flex gap-2.5 rounded-xl px-2.5 py-2.5 ${index === activeStepIndex ? 'bg-blue-50/80' : ''}`}><span className="mt-0.5 shrink-0">{stepIcon(step.status)}</span><div className="min-w-0 flex-1"><div className={`text-sm leading-5 ${step.status === 'completed' || step.status === 'cancelled' ? 'text-slate-400 line-through' : 'text-slate-700'}`}>{step.content}</div><div className="mt-0.5 text-[11px] text-slate-400">{stepLabel[step.status]}{step.priority ? ` · ${step.priority === 'high' ? '高优先级' : step.priority === 'low' ? '低优先级' : '中优先级'}` : ''}</div></div></div>) : <div className="px-3 py-8 text-center text-sm text-slate-400">{taskStatus === 'running' ? '智能体正在梳理任务，计划生成后会实时显示在这里。' : '本次任务没有生成执行计划。'}</div>}</div>
            </div>}
        </div>
    );
};

export default TaskPlanPanel;
