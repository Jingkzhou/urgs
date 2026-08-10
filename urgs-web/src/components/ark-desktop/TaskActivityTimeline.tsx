import React, { useEffect, useMemo, useState } from 'react';
import {
    AlertCircle, CheckCircle2, ChevronDown, ChevronRight, Circle, FileText, FolderOpen, LoaderCircle, Pencil, Search, ShieldAlert, SquareTerminal, Wrench,
} from 'lucide-react';
import type { ArkDesktopExecutionState, ArkDesktopTask, ArkDesktopToolActivity } from './types';
import { classifyActivityStatus } from './activityStatus';

type Tool = ArkDesktopToolActivity;
type ToolState = 'failed' | 'completed' | 'pending' | 'running';
type ActivityKind = 'edit' | 'list' | 'read' | 'search' | 'command' | 'git' | 'browser' | 'agent' | 'workflow' | 'plan' | 'interaction' | 'other';

const hiddenKinds = new Set(['diagnostic', 'context', 'memory', 'recovery']);

const isHidden = (tool: Tool) => tool.visibility === 'diagnostic' || hiddenKinds.has(String(tool.kind || '').toLowerCase());
const isReasoning = (tool: Tool) => tool.kind === 'reasoning';

const getToolState = (status: string): ToolState => {
    const kind = classifyActivityStatus(status);
    if (kind === 'failed') return 'failed';
    if (kind === 'pending') return 'pending';
    if (kind === 'running') return 'running';
    return 'completed';
};

const compactText = (value: string, maxLength = 72) => {
    const compact = value.replace(/\s+/g, ' ').trim();
    return compact.length > maxLength ? `${compact.slice(0, maxLength - 1)}…` : compact;
};

const parseToolInput = (input?: string): Record<string, unknown> | undefined => {
    if (!input) return undefined;
    try {
        const parsed = JSON.parse(input);
        return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : undefined;
    } catch {
        return undefined;
    }
};

const inputString = (tool: Tool, keys: string[]) => {
    const parsed = parseToolInput(tool.input);
    for (const key of keys) {
        const value = parsed?.[key];
        if (typeof value === 'string' && value.trim()) return value.trim();
        if (Array.isArray(value) && value.length > 0) return value.map(String).join(' ');
    }
    return undefined;
};

const toolDescription = (tool: Tool) => inputString(tool, ['description', 'display_name', 'displayName', 'label']);
const toolVariant = (tool: Tool) => inputString(tool, ['variant', 'type', 'tool_type', 'toolType']);
const localizedToolDescription = (tool: Tool) => {
    const description = toolDescription(tool);
    return description && /[\u3400-\u9fff]/.test(description) ? description : undefined;
};

const toolPath = (tool: Tool) => {
    const changedPaths = Array.from(new Set((tool.fileChanges || []).map((change) => change.path).filter(Boolean)));
    if (changedPaths.length === 1) return changedPaths[0];
    return inputString(tool, ['path', 'file_path', 'filePath', 'filename', 'target_file', 'targetFile', 'target_directory', 'targetDirectory', 'target_path', 'targetPath', 'target']);
};

const shortPath = (value: string) => {
    const normalized = value.replace(/\\/g, '/').replace(/^['"]|['"]$/g, '');
    const parts = normalized.split('/').filter(Boolean);
    return compactText(parts.slice(-3).join('/') || normalized, 64);
};

const toolCommand = (tool: Tool) => {
    const command = inputString(tool, ['cmd', 'command', 'script', 'shell_command', 'shellCommand']);
    if (command) return compactText(command);
    const kindHint = `${tool.kind || ''} ${tool.title}`.toLowerCase();
    if (/shell|terminal|command|exec|bash|powershell|命令/.test(kindHint) && tool.input && !parseToolInput(tool.input)) {
        return compactText(tool.input);
    }
    return undefined;
};

const toolQuery = (tool: Tool) => inputString(tool, ['query', 'pattern', 'search', 'needle', 'keyword']);

const toolQuestion = (tool: Tool) => {
    const parsed = parseToolInput(tool.input);
    const questions = parsed?.questions;
    if (!Array.isArray(questions)) return undefined;
    const question = questions.find((item) => item && typeof item === 'object' && typeof item.question === 'string');
    return question && typeof question.question === 'string' ? question.question.trim() : undefined;
};

const activityKind = (tool: Tool): ActivityKind => {
    const variant = toolVariant(tool)?.toLowerCase() || '';
    const hint = `${tool.kind || ''} ${tool.title} ${toolDescription(tool) || ''} ${variant}`.toLowerCase();
    if (/writefile|editfile|applypatch|apply_patch|replacefile/.test(variant)) return 'edit';
    if (/listdir/.test(variant)) return 'list';
    if (/readfile|viewfile/.test(variant)) return 'read';
    if (/bash|powershell|shell|command|monitor/.test(variant)) return 'command';
    if (/todowrite|updateplan|planwrite/.test(variant)) return 'plan';
    if (/askuserquestion|requestuserinput/.test(variant)) return 'interaction';
    if (tool.fileChanges?.length || /apply_patch|write|edit|patch|replace|写入|编辑|修改/.test(hint)) return 'edit';
    if (/git|diff|branch|commit|status|变更|分支|提交/.test(hint)) return 'git';
    if (/search|find|grep|glob|rg\b|检索|搜索/.test(hint)) return 'search';
    if (/read|open_file|view_file|读取|查看文件/.test(hint) || (tool.readOnly === true && Boolean(toolPath(tool)))) return 'read';
    if (/shell|terminal|command|exec|bash|powershell|compile|test|lint|build|命令|运行|编译|测试|验证/.test(hint) || Boolean(toolCommand(tool))) return 'command';
    if (/browser|screenshot|网页|页面|浏览器/.test(hint)) return 'browser';
    if (/subagent|agent|智能体/.test(hint)) return 'agent';
    if (/workflow|工作流/.test(hint)) return 'workflow';
    return 'other';
};

const activityState = (tools: Tool[]): ToolState => {
    if (tools.some((tool) => ['running', 'pending'].includes(getToolState(tool.status)))) return 'running';
    if (tools.some((tool) => getToolState(tool.status) === 'failed' && !tool.recovered)) return 'failed';
    return 'completed';
};

const activityClause = (kind: ActivityKind, state: ToolState) => {
    const labels: Record<ActivityKind, Record<'running' | 'completed' | 'failed', string>> = {
        edit: { running: '正在编辑文件', completed: '编辑了文件', failed: '编辑文件未完成' },
        list: { running: '正在查看目录', completed: '查看了目录', failed: '查看目录未完成' },
        read: { running: '正在读取文件', completed: '读取了文件', failed: '读取文件未完成' },
        search: { running: '正在搜索代码', completed: '搜索了代码', failed: '搜索代码未完成' },
        command: { running: '正在运行命令', completed: '运行了命令', failed: '运行命令未完成' },
        git: { running: '正在检查 Git', completed: '检查了 Git', failed: 'Git 检查未完成' },
        browser: { running: '正在检查页面', completed: '检查了页面', failed: '页面检查未完成' },
        agent: { running: '正在调用智能体', completed: '调用了智能体', failed: '智能体调用未完成' },
        workflow: { running: '正在执行工作流', completed: '执行了工作流', failed: '工作流未完成' },
        plan: { running: '正在更新执行计划', completed: '更新了执行计划', failed: '执行计划更新未完成' },
        interaction: { running: '正在等待补充信息', completed: '询问了补充信息', failed: '补充信息请求未完成' },
        other: { running: '正在执行本地操作', completed: '完成了本地操作', failed: '本地操作未完成' },
    };
    return labels[kind][state === 'pending' ? 'running' : state];
};

const joinSummaryParts = (parts: string[]) => {
    if (parts.length <= 1) return parts[0] || '完成了本地操作';
    return `${parts.slice(0, -1).join('、')}并${parts[parts.length - 1]}`;
};

const genericTitlePattern = /^(本地工具调用|工具调用|已执行任务|执行任务|任务|tool call|task|use tool|execute task)$/i;

const commandGroupSummary = (tools: Tool[]) => {
    if (!tools.length || tools.some((tool) => activityKind(tool) !== 'command')) return undefined;
    const descriptions = Array.from(new Set(tools
        .map(localizedToolDescription)
        .filter((description): description is string => Boolean(description))
        .map((description) => compactText(description, 64))));
    if (descriptions.length === 0) return undefined;
    if (tools.length === 1) return descriptions[0];
    return `${descriptions.slice(0, 2).join('、')}等操作`;
};

const activityGroupSummary = (tools: Tool[]) => {
    if (tools.length === 1 && tools[0].kind === 'inference') return activityDetailSummary(tools[0]);
    const commandSummary = commandGroupSummary(tools);
    if (commandSummary) return commandSummary;
    const kinds = Array.from(new Set(tools.map(activityKind)));
    const concreteKinds = kinds.filter((kind) => kind !== 'other');
    const displayedKinds = concreteKinds.length > 0 ? concreteKinds : kinds;
    if (displayedKinds.length === 1 && displayedKinds[0] === 'other' && tools.length > 1) {
        const state = activityState(tools);
        if (state === 'running') return `正在执行 ${tools.length} 项本地操作`;
        if (state === 'failed') return `${tools.length} 项本地操作未完成`;
        return `完成了 ${tools.length} 项本地操作`;
    }
    return joinSummaryParts(displayedKinds.map((kind) => activityClause(kind, activityState(tools.filter((tool) => activityKind(tool) === kind)))));
};

const isEmptySettledPlaceholder = (tool: Tool) => genericTitlePattern.test(tool.title.trim())
    && !tool.kind
    && !tool.input
    && !tool.output
    && !tool.fileChanges?.length
    && getToolState(tool.status) === 'completed';

const isSummaryTool = (tool: Tool) => !isHidden(tool) && !isReasoning(tool) && !isEmptySettledPlaceholder(tool);

const activityDetailSummary = (tool: Tool) => {
    const kind = activityKind(tool);
    const state = getToolState(tool.status);
    const path = toolPath(tool);
    const command = toolCommand(tool);
    const query = toolQuery(tool);
    const description = localizedToolDescription(tool);
    const question = toolQuestion(tool);
    const changedPathCount = new Set((tool.fileChanges || []).map((change) => change.path).filter(Boolean)).size;
    if (kind === 'edit' && changedPathCount > 1) return `${state === 'running' ? '正在编辑' : state === 'failed' ? '编辑未完成：' : '编辑了'} ${changedPathCount} 个文件`;
    if (kind === 'edit' && path) return `${state === 'running' ? '正在编辑' : state === 'failed' ? '编辑未完成：' : '编辑'} ${shortPath(path)}`;
    if (kind === 'list' && path) return `${state === 'running' ? '正在查看' : state === 'failed' ? '查看未完成：' : '查看'} ${shortPath(path)} 目录`;
    if (kind === 'read' && path) return `${state === 'running' ? '正在读取' : state === 'failed' ? '读取未完成：' : '读取'} ${shortPath(path)}`;
    if (kind === 'search' && query) return `${state === 'running' ? '正在搜索' : state === 'failed' ? '搜索未完成：' : '搜索'} “${compactText(query, 54)}”`;
    if (kind === 'plan') return activityClause(kind, state);
    if (kind === 'interaction' && question) return `${state === 'running' ? '正在询问' : state === 'failed' ? '询问未完成：' : '询问'} “${compactText(question, 54)}”`;
    if (description) return compactText(description);
    if ((kind === 'command' || kind === 'git') && command) return `${state === 'running' ? '正在运行' : state === 'failed' ? '运行未完成：' : '运行'} ${command}`;
    const title = compactText(tool.title);
    if (title && /[\u3400-\u9fff]/.test(title) && !genericTitlePattern.test(title)) return title;
    return activityClause(kind, state);
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
    const summary = activityDetailSummary(tool);
    const state = getToolState(tool.status);
    return (
        <div>
            <button type="button" disabled={!hasDetails} onClick={() => setOpen((value) => !value)} className="flex w-full min-w-0 items-center gap-1.5 rounded-md px-1.5 py-1 text-left text-[12px] leading-5 text-slate-500 transition enabled:hover:bg-slate-50 enabled:hover:text-slate-700 disabled:cursor-default" aria-expanded={hasDetails ? open : undefined}>
                {hasDetails ? <ChevronRight size={13} className={`shrink-0 transition-transform ${open ? 'rotate-90' : ''}`} /> : <span className="w-[13px] shrink-0" />}
                <span className="min-w-0 flex-1 truncate">{summary}</span>
                {state === 'failed' && <span className="shrink-0 text-[10px] text-amber-600">未完成</span>}
            </button>
            {hasDetails && open && <div className="ml-5 mt-1.5">
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
    return <CheckCircle2 size={15} strokeWidth={1.7} className="text-[#8b8b8b]" />;
};

const activityIcon = (tools: Tool[]) => {
    const kinds = new Set(tools.map(activityKind));
    if (kinds.has('edit')) return Pencil;
    if (kinds.has('command') || kinds.has('git')) return SquareTerminal;
    if (kinds.has('search') || kinds.has('browser')) return Search;
    if (kinds.has('list')) return FolderOpen;
    if (kinds.has('read')) return FileText;
    return Wrench;
};

export const TaskActivityDetails: React.FC<{ tools: Tool[] }> = ({ tools }) => {
    const [open, setOpen] = useState(false);
    const visibleTools = tools.filter(isSummaryTool);
    if (visibleTools.length === 0) return null;

    const state = activityState(visibleTools);
    const active = state === 'running';
    const ActionIcon = activityIcon(visibleTools);
    const summary = activityGroupSummary(visibleTools);
    return <div>
        <button type="button" onClick={() => setOpen((value) => !value)} className="flex min-h-7 w-full min-w-0 items-center gap-2 rounded-md px-1 text-left text-[13px] leading-5 text-[#77787c] transition hover:bg-slate-50 hover:text-[#55565a]" aria-expanded={open}>
            {active || state === 'failed'
                ? <StageIcon state={state} active={active} />
                : <ActionIcon size={15} strokeWidth={1.7} className="shrink-0 text-[#8b8b8b]" />}
            <span className="group/detail inline-flex min-w-0 max-w-full items-center gap-1.5">
                <span className="min-w-0 truncate">{summary}</span>
                <ChevronRight size={14} className={`shrink-0 text-slate-400 opacity-0 transition-[transform,opacity] group-hover/detail:opacity-100 ${open ? 'rotate-90' : ''}`} />
            </span>
        </button>
        {open && <div className="ml-5 mt-1 space-y-0.5 border-l border-slate-200 pl-2">
            {visibleTools.map((tool) => <ActivityDetail key={tool.id} tool={tool} />)}
        </div>}
    </div>;
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
    const [diagnosticsOpen, setDiagnosticsOpen] = useState(false);
    const [now, setNow] = useState(() => Date.now());
    const summaryTools = useMemo(() => tools.filter(isSummaryTool), [tools]);
    const diagnosticTools = useMemo(() => tools.filter((tool) => isHidden(tool) && !isReasoning(tool)), [tools]);
    const allWorkTools = useMemo(() => tools.filter((tool) => !isReasoning(tool) && !isEmptySettledPlaceholder(tool)), [tools]);
    const latestActivityAt = Math.max(
        execution?.lastActivityAt || 0,
        ...tools.map((tool) => tool.updatedAt || tool.startedAt || 0),
    );
    const activeTool = [...summaryTools].reverse().find((tool) => ['running', 'pending'].includes(getToolState(tool.status)));
    const failedTool = summaryTools.some((tool) => getToolState(tool.status) === 'failed' && !tool.recovered);
    const terminalTask = taskStatus === 'completed'
        || taskStatus === 'failed'
        || taskStatus === 'cancelled'
        || ['completed', 'completed_limited', 'failed', 'stopped'].includes(execution?.status || '');
    const active = !terminalTask && (isActive ?? Boolean(activeTool));
    const [expanded, setExpanded] = useState(active);
    const isWaiting = active && (taskStatus === 'waiting_authorization' || execution?.status === 'waiting_user');
    const isRunning = active && !isWaiting && (taskStatus === 'running' || execution?.status === 'running' || execution?.status === 'recovering' || Boolean(activeTool));
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

    useEffect(() => {
        setExpanded(active);
    }, [active]);

    if (!summaryOnly && tools.length === 0 && !execution?.currentStage) return null;

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
    const expandedDetails = expanded && <div className="mt-1.5 border-l border-slate-200 pl-4">
        {children}
        {!children && <TaskActivityDetails tools={summaryTools} />}
        {!children && summaryTools.length === 0 && <div className="py-1 text-[12px] text-slate-400">{active ? '当前阶段正在准备中' : '已完成执行步骤'}</div>}
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
        <button type="button" onClick={() => setExpanded((value) => !value)} className="group flex w-full items-center border-b border-slate-200 py-3 text-left text-[15px] font-medium text-slate-500 transition hover:text-slate-700" aria-expanded={expanded} aria-label={compactSummary}>
            <span className="group/summary inline-flex min-w-0 max-w-full items-center gap-1.5">
                <span className="min-w-0 truncate">{compactSummary}</span>
                <ChevronRight size={16} strokeWidth={1.8} className={`shrink-0 text-slate-400 opacity-0 transition-[transform,opacity] group-hover/summary:opacity-100 ${expanded ? 'rotate-90' : ''}`} />
            </span>
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
