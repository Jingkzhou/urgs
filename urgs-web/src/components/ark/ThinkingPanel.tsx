import React, { useMemo, useState } from 'react';
import { Brain, Check, ChevronDown, Circle, Loader2, X } from 'lucide-react';
import { AnimatePresence, motion } from 'framer-motion';

export type ThinkingStep = {
    id: string;
    title: string;
    description?: string;
    status: 'pending' | 'running' | 'done' | 'error';
    timestamp?: string;
    kind?: 'progress' | 'tool' | 'stage';
};

export type ThinkingPanelProps = {
    title?: string;
    steps: ThinkingStep[];
    defaultExpanded?: boolean;
    currentStatus?: string;
};

const getStatusIcon = (status: ThinkingStep['status']) => {
    if (status === 'done') {
        return <Check size={13} strokeWidth={2.4} />;
    }
    if (status === 'running') {
        return <Loader2 size={13} className="animate-spin" strokeWidth={2.2} />;
    }
    if (status === 'error') {
        return <X size={13} strokeWidth={2.4} />;
    }
    return <Circle size={9} strokeWidth={2.2} />;
};

const getStatusClassName = (status: ThinkingStep['status']) => {
    switch (status) {
        case 'done':
            return 'border-slate-200 bg-white text-slate-400';
        case 'running':
            return 'border-slate-900 bg-slate-900 text-white shadow-sm';
        case 'error':
            return 'border-red-200 bg-red-50 text-red-500';
        default:
            return 'border-slate-200 bg-white text-slate-300';
    }
};

const getTextClassName = (status: ThinkingStep['status']) => {
    switch (status) {
        case 'running':
            return 'text-slate-900';
        case 'error':
            return 'text-red-600';
        case 'done':
            return 'text-slate-500';
        default:
            return 'text-slate-400';
    }
};

const ThinkingPanel: React.FC<ThinkingPanelProps> = ({
    title = '执行过程',
    steps,
    defaultExpanded = false,
    currentStatus
}) => {
    const [expanded, setExpanded] = useState(defaultExpanded);
    const latestRunning = useMemo(() => steps.find(step => step.status === 'running'), [steps]);
    const latestStep = steps[steps.length - 1];
    const displayStatus = currentStatus || latestRunning?.title || latestStep?.title || title;

    if (steps.length === 0 && !displayStatus) {
        return null;
    }

    return (
        <div className="mb-4 max-w-3xl">
            <button
                type="button"
                onClick={() => setExpanded(prev => !prev)}
                className="group flex max-w-full items-center gap-2 rounded-full px-1.5 py-1 text-left text-sm text-slate-500 transition-colors hover:text-slate-900"
            >
                <span className="flex h-5 w-5 shrink-0 items-center justify-center">
                    {latestRunning ? (
                        <Loader2 size={15} className="animate-spin text-slate-700" />
                    ) : (
                        <Brain size={15} className="text-slate-500" />
                    )}
                </span>
                <span className="min-w-0 truncate font-medium text-slate-600 group-hover:text-slate-900">
                    {displayStatus}
                </span>
                {steps.length > 0 && (
                    <span className="shrink-0 text-slate-400">
                        · {steps.length} 步
                    </span>
                )}
                {steps.length > 0 && (
                    <ChevronDown
                        size={14}
                        className={`shrink-0 text-slate-400 transition-transform ${expanded ? 'rotate-180' : ''}`}
                    />
                )}
            </button>

            <AnimatePresence initial={false}>
                {expanded && steps.length > 0 && (
                    <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: 'auto', opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.2, ease: 'easeOut' }}
                        className="overflow-hidden"
                    >
                        <div className="mt-2 space-y-0.5 pl-1">
                            {steps.map((step, index) => (
                                <div key={step.id} className={`relative flex gap-3 ${step.kind === 'progress' ? 'py-2.5' : 'py-1.5'}`}>
                                    {index < steps.length - 1 && (
                                        <span className="absolute left-[9px] top-7 h-[calc(100%-1rem)] w-px bg-slate-200" />
                                    )}
                                    <span className={`z-[1] mt-0.5 flex h-[18px] w-[18px] shrink-0 items-center justify-center rounded-full border ${getStatusClassName(step.status)}`}>
                                        {getStatusIcon(step.status)}
                                    </span>
                                    <span className="min-w-0 flex-1">
                                        <span className={`block font-medium ${step.kind === 'progress' ? 'text-[15px] leading-6' : 'text-sm leading-5'} ${getTextClassName(step.status)}`}>
                                            {step.title}
                                        </span>
                                        {step.description && (
                                            <span className={`mt-0.5 block whitespace-pre-wrap break-words ${step.kind === 'progress' ? 'text-sm leading-6 text-slate-600' : 'text-xs leading-5 text-slate-400'}`}>
                                                {step.description.length > 1000 ? `${step.description.slice(0, 1000)}...` : step.description}
                                            </span>
                                        )}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default ThinkingPanel;
