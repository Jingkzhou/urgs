import React, { useState } from 'react';
import { CircleStop, LoaderCircle, Pause, Play } from 'lucide-react';
import type { ArkDesktopWorkflowRun } from './types';

export type WorkflowCommandAction = 'pause' | 'resume' | 'stop';

interface WorkflowRunControlsProps {
    run: ArkDesktopWorkflowRun;
    disabled?: boolean;
    compact?: boolean;
    onCommand: (action: WorkflowCommandAction) => Promise<void>;
    onError: (error: unknown) => void;
}

const isTerminalWorkflow = (status: string) => /complete|completed|failed|interrupted|cancelled|stopped|cleared/i.test(status);
const isPausedWorkflow = (status: string) => /paused/i.test(status);

const buttonClass = (compact: boolean, tone: 'neutral' | 'danger') => [
    'inline-flex items-center justify-center gap-1 rounded-md font-medium transition disabled:cursor-not-allowed disabled:opacity-40',
    compact ? 'px-1.5 py-1 text-[10px]' : 'px-2 py-1.5 text-[11px]',
    tone === 'danger'
        ? 'text-red-600 hover:bg-red-50'
        : 'text-slate-600 hover:bg-white',
].join(' ');

const WorkflowRunControls: React.FC<WorkflowRunControlsProps> = ({
    run,
    disabled = false,
    compact = false,
    onCommand,
    onError,
}) => {
    const [pending, setPending] = useState<WorkflowCommandAction | null>(null);
    if (isTerminalWorkflow(run.status)) return null;

    const command = async (action: WorkflowCommandAction) => {
        if (disabled || pending) return;
        if (action === 'stop' && !window.confirm(`确认停止工作流 ${run.name}？`)) return;
        setPending(action);
        try {
            await onCommand(action);
        } catch (error) {
            onError(error);
        } finally {
            setPending(null);
        }
    };

    const paused = isPausedWorkflow(run.status);
    const action = paused ? 'resume' : 'pause';
    const ActionIcon = paused ? Play : Pause;
    const actionLabel = paused ? '恢复' : '暂停';
    const actionPending = pending === action;
    const stopPending = pending === 'stop';

    return <div className="flex shrink-0 items-center gap-0.5">
        <button
            type="button"
            disabled={disabled || pending !== null}
            onClick={() => void command(action)}
            className={buttonClass(compact, 'neutral')}
            title={`${actionLabel}工作流`}
            aria-label={`${actionLabel}工作流 ${run.name}`}
        >
            {actionPending ? <LoaderCircle size={compact ? 11 : 13} className="animate-spin" /> : <ActionIcon size={compact ? 11 : 13} />}
            {!compact && actionLabel}
        </button>
        <button
            type="button"
            disabled={disabled || pending !== null}
            onClick={() => void command('stop')}
            className={buttonClass(compact, 'danger')}
            title="停止工作流"
            aria-label={`停止工作流 ${run.name}`}
        >
            {stopPending ? <LoaderCircle size={compact ? 11 : 13} className="animate-spin" /> : <CircleStop size={compact ? 11 : 13} />}
            {!compact && '停止'}
        </button>
    </div>;
};

export default WorkflowRunControls;
