import React, { useEffect, useMemo, useState } from 'react';
import {
    AlertCircle, CheckCircle2, ChevronDown, ChevronRight, Circle, FileText, LoaderCircle, Search, ShieldAlert, SquareTerminal, Wrench,
} from 'lucide-react';
import type { ArkDesktopExecutionState, ArkDesktopTask, ArkDesktopToolActivity } from './types';

type Tool = ArkDesktopToolActivity;

const hiddenKinds = new Set(['diagnostic', 'context', 'memory', 'recovery', 'inference']);

const isHidden = (tool: Tool) => tool.visibility === 'diagnostic' || hiddenKinds.has(String(tool.kind || '').toLowerCase());
const isReasoning = (tool: Tool) => tool.kind === 'reasoning';

const getToolState = (status: string) => {
    if (/失败|错误|退出码|failed|error/i.test(status)) return 'failed';
    if (/已完成|已记录|完成|成功|取消|不可用|未生成|completed|recorded|success|cancelled|canceled|unavailable|done/i.test(status)) return 'completed';
    if (/等待|pending/i.test(status)) return 'pending';
    return 'running';
};

const getFallbackStage = (tool: Tool) => {
    const hint = `${tool.kind || ''} ${tool.title}`.toLowerCase();
    if (/write|edit|patch|写入|编辑|修改/.test(hint)) return '正在修改代码';
    if (/read|file|读取|文件/.test(hint)) return '正在检查项目文件';
    if (/search|find|grep|检索|搜索/.test(hint)) return '正在搜索相关代码';
    if (/shell|terminal|command|命令|运行|compile|test|lint|build|编译|测试|验证/.test(hint)) return '正在运行验证';
    if (/git|diff|branch|变更/.test(hint)) return '正在检查代码变更';
    if (/browser|网页|页面/.test(hint)) return '正在检查页面表现';
    return isReasoning(tool) ? '正在分析需求' : '正在执行任务';
};

const getStage = (tool: Tool) => {
    const value = tool.semanticStage || getFallbackStage(tool);
    if (/^(正在|等待|已|执行)/.test(value)) return value;
    return `正在${value}`;
};

const formatDuration = (milliseconds: number) => {
    const seconds = Math.max(0, Math.round(milliseconds / 1000));
    if (seconds < 60) return `${seconds} 秒`;
    const minutes = Math.floor(seconds / 60);
    return `${minutes} 分 ${seconds % 60} 秒`;
};

const formatCompactDuration = (milliseconds: number) => {
    const seconds = Math.max(0, Math.round(milliseconds / 1000));
    if (seconds < 60) return `${seconds}s`;
    return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
};

const formatActivityAge = (milliseconds: number) => {
    const seconds = Math.max(0, Math.floor(milliseconds / 1000));
    if (seconds <= 3) return '刚刚仍有活动';
    if (seconds < 60) return `${seconds} 秒前仍有活动`;
    return `${Math.floor(seconds / 60)} 分钟前有活动`;
};

const ToolDetail: React.FC<{ label: string; value: string }> = ({ label, value }) => (
    <div className="mt-1.5 overflow-hidden rounded-lg border border-slate-200 bg-[#fafafa]">
        <div className="border-b border-slate-100 px-3 py-1.5 text-[10px] font-medium tracking-[0.08em] text-slate-400">{label}</div>
        <pre className="max-h-48 overflow-auto whitespace-pre-wrap break-words px-3 py-2 font-mono text-[11px] leading-5 text-slate-600">{value}</pre>
    </div>
);

const ActivityDetail: React.FC<{ tool: Tool }> = ({ tool }) => {
    const [open, setOpen] = useState(false);
    const hasDetails = Boolean(tool.input || tool.output || tool.fileChanges?.length);
    if (!hasDetails) return null;
    return (
        <div className="mt-1.5 ml-7">
            <button type="button" onClick={() => setOpen((value) => !value)} className="flex items-center gap-1 text-[11px] text-slate-400 hover:text-slate-600" aria-expanded={open}>
                <ChevronRight size={13} className={open ? 'rotate-90' : ''} />
                查看执行数据
            </button>
            {open && <div className="mt-1.5">
                {tool.input && <ToolDetail label="调用参数" value={tool.input} />}
                {tool.output && <ToolDetail label="返回结果" value={tool.output} />}
                {tool.fileChanges?.length ? <ToolDetail label="文件变更" value={tool.fileChanges.map((change) => `${change.path} (+${change.additions}/-${change.deletions})`).join('\n')} /> : null}
            </div>}
        </div>
    );
};

const StageIcon: React.FC<{ state: ReturnType<typeof getToolState>; active: boolean }> = ({ state, active }) => {
    if (state === 'failed') return <AlertCircle size={15} className="text-amber-500" />;
    if (active) return <LoaderCircle size={15} className="animate-spin text-blue-500" />;
    if (state === 'pending') return <Circle size={14} className="text-slate-300" />;
    return <CheckCircle2 size={15} className="text-emerald-500" />;
};

const getSummaryIcon = (stage: string, active: boolean, failed: boolean) => {
    if (failed) return ShieldAlert;
    if (active) return LoaderCircle;
    if (/检查|搜索/.test(stage)) return Search;
    if (/修改/.test(stage)) return FileText;
    if (/验证|运行/.test(stage)) return SquareTerminal;
    return Wrench;
};

interface TaskActivityTimelineProps {
    tools: ArkDesktopTask['tools'];
    taskStatus?: ArkDesktopTask['status'];
    execution?: ArkDesktopExecutionState;
    runStartedAt?: number;
    runCompletedAt?: number;
    isActive?: boolean;
    summaryOnly?: boolean;
    children?: React.ReactNode;
}

const TaskActivityTimeline: React.FC<TaskActivityTimelineProps> = ({ tools, taskStatus, execution, runStartedAt, runCompletedAt, isActive, summaryOnly = false, children }) => {
    const [expanded, setExpanded] = useState(false);
    const [diagnosticsOpen, setDiagnosticsOpen] = useState(false);
    const [now, setNow] = useState(() => Date.now());
    const summaryTools = useMemo(() => tools.filter((tool) => !isHidden(tool) && !isReasoning(tool)), [tools]);
    const diagnosticTools = useMemo(() => tools.filter((tool) => isHidden(tool) && !isReasoning(tool)), [tools]);
    const allWorkTools = useMemo(() => tools.filter((tool) => !isReasoning(tool)), [tools]);
    const latestActivityAt = Math.max(
        execution?.lastActivityAt || 0,
        ...tools.map((tool) => tool.updatedAt || tool.startedAt || 0),
    );
    const activeTool = [...summaryTools].reverse().find((tool) => ['running', 'pending'].includes(getToolState(tool.status)));
    const failedTool = summaryTools.some((tool) => getToolState(tool.status) === 'failed' && !tool.recovered);
    const active = isActive ?? Boolean(activeTool);
    const isRunning = active && (taskStatus === 'running' || execution?.status === 'running' || execution?.status === 'recovering' || Boolean(activeTool));
    const isWaiting = active && (taskStatus === 'waiting_authorization' || execution?.status === 'waiting_user');
    const currentStage = isWaiting && active
        ? execution?.currentStage || '等待你的确认'
        : active && activeTool
            ? getStage(activeTool)
            : active
                ? execution?.currentStage || (summaryTools.length > 0 ? getStage(summaryTools[summaryTools.length - 1]) : '正在分析需求')
                : summaryTools.length > 0 ? getStage(summaryTools[summaryTools.length - 1]) : '已完成执行步骤';
    const SummaryIcon = getSummaryIcon(currentStage, isRunning, failedTool || taskStatus === 'failed');
    const completedCount = allWorkTools.filter((tool) => getToolState(tool.status) === 'completed').length;
    const totalCount = allWorkTools.length;
    const elapsedStartAt = runStartedAt || execution?.startedAt;
    const elapsed = elapsedStartAt ? Math.max(0, (runCompletedAt || execution?.completedAt || now) - elapsedStartAt) : 0;

    useEffect(() => {
        if (!isRunning && !isWaiting) return undefined;
        const timer = window.setInterval(() => setNow(Date.now()), 1000);
        return () => window.clearInterval(timer);
    }, [isRunning, isWaiting]);

    if (!summaryOnly && tools.length === 0 && !execution?.currentStage) return null;

    const detailTools = summaryOnly ? tools.filter((tool) => !isHidden(tool)) : summaryTools;
    const groupedStages = detailTools.reduce<Array<{ label: string; tools: Tool[] }>>((groups, tool) => {
        const label = getStage(tool);
        const last = groups[groups.length - 1];
        if (last?.label === label) last.tools.push(tool);
        else groups.push({ label, tools: [tool] });
        return groups;
    }, []);

    const statusText = isWaiting
        ? '等待你的操作'
        : isRunning
            ? `${elapsed > 0 ? `已运行 ${formatDuration(elapsed)} · ` : ''}${formatActivityAge(now - latestActivityAt)}`
            : taskStatus === 'failed' || execution?.status === 'failed'
                ? '执行未完成'
                : totalCount > 0
                    ? `已完成 ${completedCount}/${totalCount} 项`
                    : '已记录执行结果';
    const compactSummary = taskStatus === 'failed' || execution?.status === 'failed'
        ? '处理未完成'
        : taskStatus === 'cancelled'
            ? `已取消 ${formatCompactDuration(elapsed)}`
            : isWaiting
                ? `等待操作 ${formatCompactDuration(elapsed)}`
                : isRunning
                    ? `处理中 ${formatCompactDuration(elapsed)}`
                    : `已处理 ${formatCompactDuration(elapsed)}`;
    const expandedDetails = expanded && <div className="mt-1.5 space-y-2 border-l border-slate-200 pl-4">
        {children}
        {groupedStages.length > 0 ? groupedStages.map((group) => {
            const active = group.tools.some((tool) => ['running', 'pending'].includes(getToolState(tool.status)));
            const state = group.tools.some((tool) => getToolState(tool.status) === 'failed') ? 'failed' : active ? 'running' : 'completed';
            return <div key={`${group.label}-${group.tools[0]?.id}`} className="py-0.5">
                <div className="flex items-center gap-2 text-[12px] text-slate-600">
                    <StageIcon state={state} active={active} />
                    <span className="min-w-0 flex-1 truncate">{group.label}</span>
                    <span className="shrink-0 text-[10px] text-slate-400">{group.tools.length} 项</span>
                </div>
                {group.tools.map((tool) => <ActivityDetail key={tool.id} tool={tool} />)}
            </div>;
        }) : <div className="py-1 text-[12px] text-slate-400">{active ? '当前阶段正在准备中' : '已完成执行步骤'}</div>}
        {diagnosticTools.length > 0 && <div className="pt-1">
            <button type="button" onClick={() => setDiagnosticsOpen((value) => !value)} className="flex items-center gap-1.5 text-[11px] text-slate-400 hover:text-slate-600" aria-expanded={diagnosticsOpen}>
                <ChevronRight size={13} className={diagnosticsOpen ? 'rotate-90' : ''} />
                {diagnosticsOpen ? '隐藏技术诊断' : `查看技术诊断（${diagnosticTools.length} 条）`}
            </button>
            {diagnosticsOpen && <div className="mt-1.5 space-y-2">
                {diagnosticTools.map((tool) => <div key={tool.id} className="rounded-lg bg-slate-50 px-2.5 py-2">
                    <div className="flex items-center gap-2 text-[11px] text-slate-500"><AlertCircle size={13} className={tool.recovered ? 'text-emerald-500' : 'text-slate-400'} /><span className="min-w-0 flex-1 truncate">{tool.recovered ? '内部异常已自动恢复' : tool.title}</span><span className="shrink-0 text-[10px] text-slate-400">{tool.status}</span></div>
                    {tool.input && <ToolDetail label="调用参数" value={tool.input} />}
                    {tool.output && <ToolDetail label="返回结果" value={tool.output} />}
                </div>)}
            </div>}
        </div>}
    </div>;

    if (summaryOnly) return <section className="my-2" aria-label="执行记录">
        <button type="button" onClick={() => setExpanded((value) => !value)} className="flex w-full items-center gap-1.5 border-b border-slate-200 py-3 text-left text-[15px] font-medium text-slate-500 transition hover:text-slate-700" aria-expanded={expanded} aria-label={compactSummary}>
            <span className="truncate">{compactSummary}</span>
            <ChevronRight size={16} strokeWidth={1.8} className={`shrink-0 text-slate-400 transition-transform ${expanded ? 'rotate-90' : ''}`} />
        </button>
        {expandedDetails}
    </section>;

    return (
        <section className="my-1.5" aria-label="执行过程">
            <button type="button" onClick={() => setExpanded((value) => !value)} className={`group flex w-full min-w-0 items-center gap-2 rounded-lg px-2 py-2 text-left transition hover:bg-slate-50 ${failedTool || taskStatus === 'failed' ? 'text-amber-700' : 'text-slate-600'}`} aria-expanded={expanded}>
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-slate-50">
                    <SummaryIcon size={16} className={isRunning ? 'animate-spin text-blue-500' : failedTool || taskStatus === 'failed' ? 'text-amber-500' : 'text-slate-400'} />
                </span>
                <span className="min-w-0 flex-1">
                    <span className="block truncate text-[14px] font-medium">{currentStage}</span>
                    <span className="mt-0.5 block truncate text-[11px] text-slate-400">{statusText}</span>
                </span>
                <span className="flex shrink-0 items-center gap-1 text-[11px] text-slate-400">
                    <ChevronDown size={15} className={`transition-transform ${expanded ? '' : '-rotate-90'}`} />
                </span>
            </button>
            {expandedDetails}
        </section>
    );
};

export default TaskActivityTimeline;
