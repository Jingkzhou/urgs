import React, { useEffect, useId, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { CheckCircle2, Circle, ListTodo, LoaderCircle, LocateFixed, X, XCircle } from 'lucide-react';
import type { ArkDesktopPlanStep, ArkDesktopTaskStatus } from './types';

interface TaskPlanPanelProps {
    plan: ArkDesktopPlanStep[];
    taskStatus: ArkDesktopTaskStatus;
    trigger: React.ReactNode;
}

interface PanelPosition {
    top: number;
    left: number;
    width: number;
    maxHeight: number;
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

const getDisplayStepStatus = (status: ArkDesktopPlanStep['status'], taskStatus: ArkDesktopTaskStatus) => {
    if (taskStatus !== 'running' && taskStatus !== 'waiting_authorization' && status !== 'completed') return 'cancelled' as const;
    return status;
};

const getDisplayStepLabel = (status: ArkDesktopPlanStep['status'], taskStatus: ArkDesktopTaskStatus) => {
    if (taskStatus === 'cancelled' && status !== 'completed') return '已停止';
    if (taskStatus === 'failed' && status !== 'completed') return '未完成';
    if (taskStatus === 'completed' && status !== 'completed') return '未完成';
    return stepLabel[status];
};

const TaskPlanPanel: React.FC<TaskPlanPanelProps> = ({ plan, taskStatus, trigger }) => {
    const [open, setOpen] = useState(false);
    const [followCurrentStep, setFollowCurrentStep] = useState(true);
    const [panelPosition, setPanelPosition] = useState<PanelPosition>({ top: 16, left: 16, width: 400, maxHeight: 560 });
    const triggerRef = useRef<HTMLButtonElement>(null);
    const panelRef = useRef<HTMLDivElement>(null);
    const planListRef = useRef<HTMLDivElement>(null);
    const activeStepRef = useRef<HTMLDivElement>(null);
    const autoScrollingRef = useRef(false);
    const panelId = `task-plan-panel-${useId().replace(/:/g, '')}`;
    const completedCount = plan.filter((step) => step.status === 'completed').length;
    const progress = plan.length ? Math.round((completedCount / plan.length) * 100) : 0;
    const statusText = plan.length
        ? taskStatus === 'cancelled'
            ? `已停止 · ${completedCount} / ${plan.length} 已完成`
            : taskStatus === 'failed'
                ? `执行未完成 · ${completedCount} / ${plan.length} 已完成`
                : `${completedCount} / ${plan.length} 已完成`
        : taskStatus === 'running' ? '正在制定计划' : '暂无执行计划';
    const activeStepIndex = taskStatus === 'running' || taskStatus === 'waiting_authorization'
        ? plan.findIndex((step) => step.status === 'in_progress')
        : -1;
    const stageStatusText = activeStepIndex >= 0
        ? followCurrentStep ? '已锁定当前执行阶段' : '已解除阶段锁定'
        : taskStatus === 'completed'
            ? '执行已完成'
            : taskStatus === 'failed'
                ? '执行未完成'
                : taskStatus === 'cancelled'
                    ? '执行已停止'
                    : '等待执行阶段更新';

    useLayoutEffect(() => {
        if (!open) return undefined;

        const updatePanelPosition = () => {
            const triggerElement = triggerRef.current;
            if (!triggerElement) return;

            const viewportPadding = 16;
            const viewportWidth = window.innerWidth;
            const viewportHeight = window.innerHeight;
            const width = Math.min(400, Math.max(240, viewportWidth - viewportPadding * 2));
            const maxHeight = Math.max(220, viewportHeight - viewportPadding * 2);
            const panelHeight = Math.min(panelRef.current?.getBoundingClientRect().height || 480, maxHeight);
            const triggerRect = triggerElement.getBoundingClientRect();
            const belowTop = triggerRect.bottom + 10;
            const aboveTop = triggerRect.top - panelHeight - 10;
            const top = belowTop + panelHeight <= viewportHeight - viewportPadding || aboveTop < viewportPadding
                ? Math.min(belowTop, viewportHeight - panelHeight - viewportPadding)
                : aboveTop;
            const left = Math.min(Math.max(viewportPadding, triggerRect.right - width), viewportWidth - width - viewportPadding);

            setPanelPosition({
                top: Math.max(viewportPadding, top),
                left,
                width,
                maxHeight,
            });
        };

        updatePanelPosition();
        const frame = window.requestAnimationFrame(updatePanelPosition);
        window.addEventListener('resize', updatePanelPosition);
        window.addEventListener('scroll', updatePanelPosition, true);
        return () => {
            window.cancelAnimationFrame(frame);
            window.removeEventListener('resize', updatePanelPosition);
            window.removeEventListener('scroll', updatePanelPosition, true);
        };
    }, [activeStepIndex, open, plan.length]);

    useEffect(() => {
        if (!open) return undefined;
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.key === 'Escape') setOpen(false);
        };
        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [open]);

    useEffect(() => {
        if (!open || !followCurrentStep || activeStepIndex < 0) return;

        const frame = window.requestAnimationFrame(() => {
            const list = planListRef.current;
            const activeStep = activeStepRef.current;
            if (!list || !activeStep) return;

            autoScrollingRef.current = true;
            const listRect = list.getBoundingClientRect();
            const activeStepRect = activeStep.getBoundingClientRect();
            if (activeStepRect.top < listRect.top) list.scrollTop -= listRect.top - activeStepRect.top;
            if (activeStepRect.bottom > listRect.bottom) list.scrollTop += activeStepRect.bottom - listRect.bottom;
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

    const planContent = open && typeof document !== 'undefined' ? createPortal(<>
        <div className="fixed inset-0 z-[1290]" aria-hidden="true" onMouseDown={() => setOpen(false)} />
        <div
            ref={panelRef}
            id={panelId}
            role="dialog"
            aria-label="执行计划"
            className="fixed z-[1291] flex min-h-0 max-w-[calc(100vw-32px)] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-[0_18px_45px_rgba(15,23,42,0.16)]"
            style={{ top: panelPosition.top, left: panelPosition.left, width: panelPosition.width, maxHeight: panelPosition.maxHeight }}
            onMouseDown={(event) => event.stopPropagation()}
        >
            <div className="flex shrink-0 items-center justify-between gap-3 border-b border-slate-100 px-4 py-3">
                <div className="flex min-w-0 items-center gap-2"><ListTodo size={17} className="shrink-0 text-slate-500" /><span className="text-sm font-semibold text-slate-800">执行计划</span></div>
                <div className="flex shrink-0 items-center gap-2"><span className="text-xs text-slate-400">{statusText}</span><button type="button" onClick={() => setOpen(false)} className="rounded-md p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-700" aria-label="关闭执行计划"><X size={15} /></button></div>
            </div>
            <div className="shrink-0 border-b border-slate-100 px-4 py-3"><div className="h-1.5 overflow-hidden rounded-full bg-slate-100"><div className="h-full rounded-full bg-slate-800 transition-all duration-300" style={{ width: `${progress}%` }} /></div></div>
            <div className="flex shrink-0 items-center justify-between gap-3 border-b border-slate-100 px-4 py-2 text-xs"><span className={activeStepIndex >= 0 && followCurrentStep ? 'text-blue-600' : 'text-slate-400'}>{stageStatusText}</span>{activeStepIndex >= 0 && !followCurrentStep && <button type="button" onClick={() => setFollowCurrentStep(true)} className="flex shrink-0 items-center gap-1 rounded-md px-1.5 py-1 font-medium text-slate-600 hover:bg-slate-100 hover:text-slate-900"><LocateFixed size={13} />定位当前阶段</button>}</div>
            <div ref={planListRef} className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-2 py-2" aria-label="执行计划步骤" onScroll={() => { if (!autoScrollingRef.current) setFollowCurrentStep(false); }}>{plan.length ? plan.map((step, index) => { const displayStatus = getDisplayStepStatus(step.status, taskStatus); return <div key={`${step.content}-${index}`} ref={index === activeStepIndex ? activeStepRef : undefined} className={`flex gap-2.5 rounded-xl px-2.5 py-2.5 ${index === activeStepIndex ? 'bg-blue-50/80' : ''}`}><span className="mt-0.5 shrink-0">{stepIcon(displayStatus)}</span><div className="min-w-0 flex-1"><div className={`text-sm leading-5 ${displayStatus === 'completed' || displayStatus === 'cancelled' ? 'text-slate-400 line-through' : 'text-slate-700'}`}>{step.content}</div><div className="mt-0.5 text-[11px] text-slate-400">{getDisplayStepLabel(step.status, taskStatus)}{step.priority ? ` · ${step.priority === 'high' ? '高优先级' : step.priority === 'low' ? '低优先级' : '中优先级'}` : ''}</div></div></div>; }) : <div className="px-3 py-8 text-center text-sm text-slate-400">{taskStatus === 'running' ? '智能体正在梳理任务，计划生成后会实时显示在这里。' : '本次任务没有生成执行计划。'}</div>}</div>
        </div>
    </>, document.body) : null;

    return (
        <>
            <div className="relative shrink-0"><button ref={triggerRef} type="button" onClick={toggleOpen} className={`inline-flex max-w-full items-center gap-2 rounded-full border bg-white px-4 py-2.5 text-sm text-slate-600 shadow-[0_1px_3px_rgba(15,23,42,0.05)] transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-300 ${open ? 'border-blue-500' : 'border-slate-200 hover:border-blue-300'}`} title="查看执行计划" aria-label="查看执行计划" aria-haspopup="dialog" aria-controls={panelId} aria-expanded={open}>{trigger}</button></div>
            {planContent}
        </>
    );
};

export default TaskPlanPanel;
