import React, { useState } from 'react';
import {
    AlertCircle, ChevronDown, ChevronRight, Circle, Eye, FileText, LoaderCircle, Search, SquareTerminal, Wrench,
} from 'lucide-react';
import type { ArkDesktopTask } from './types';

type Tool = ArkDesktopTask['tools'][number];

const getToolState = (status: string) => {
    if (status === '已完成') return 'completed';
    if (status === '失败') return 'failed';
    if (status === '等待中') return 'pending';
    return 'running';
};

const getToolIcon = (tool: Tool) => {
    const hint = `${tool.kind || ''} ${tool.title}`.toLowerCase();
    if (/search|find|grep|检索|搜索/.test(hint)) return Search;
    if (/read|读取/.test(hint)) return Eye;
    if (/write|edit|patch|file|文件|写入|编辑|修改/.test(hint)) return FileText;
    if (/code|shell|terminal|command|命令|运行/.test(hint)) return SquareTerminal;
    return Wrench;
};

const getToolVerb = (tool: Tool, state: ReturnType<typeof getToolState>) => {
    const hint = `${tool.kind || ''} ${tool.title}`.toLowerCase();
    const running = state === 'running' || state === 'pending';
    if (/write|edit|patch|写入|编辑|修改/.test(hint)) return running ? '正在编辑' : '已编辑';
    if (/read|file|读取|文件/.test(hint)) return running ? '正在读取' : '已读取';
    if (/search|find|grep|检索|搜索/.test(hint)) return running ? '正在搜索' : '已搜索';
    if (/code|shell|terminal|command|命令|运行/.test(hint)) return running ? '正在运行' : '已运行';
    return running ? '正在使用' : '已使用';
};

const getStatusIcon = (state: ReturnType<typeof getToolState>) => {
    if (state === 'failed') return AlertCircle;
    if (state === 'running') return LoaderCircle;
    if (state === 'pending') return Circle;
    return null;
};

const ToolDetail: React.FC<{ label: string; value: string }> = ({ label, value }) => (
    <div className="mt-1.5 overflow-hidden rounded-lg border border-slate-200 bg-[#fafafa]">
        <div className="border-b border-slate-100 px-3 py-1.5 text-[10px] font-medium tracking-[0.08em] text-slate-400">{label}</div>
        <pre className="max-h-48 overflow-auto whitespace-pre-wrap break-words px-3 py-2 font-mono text-[11px] leading-5 text-slate-600">{value}</pre>
    </div>
);

const ToolActivityItem: React.FC<{ tool: Tool }> = ({ tool }) => {
    const [detailsOpen, setDetailsOpen] = useState(false);
    const hasDetails = Boolean(tool.input || tool.output);
    const state = getToolState(tool.status);
    const ToolIcon = getToolIcon(tool);
    const StatusIcon = getStatusIcon(state);
    const statusColor = state === 'failed' ? 'text-red-500' : state === 'running' ? 'text-blue-500' : state === 'pending' ? 'text-amber-500' : 'text-slate-400';

    return (
        <div className="py-1">
            <button
                type="button"
                disabled={!hasDetails}
                onClick={() => setDetailsOpen((open) => !open)}
                className={`group flex w-full min-w-0 items-center gap-2 rounded-md px-1.5 py-1.5 text-left transition ${hasDetails ? 'hover:bg-slate-50' : 'cursor-default'}`}
                aria-expanded={hasDetails ? detailsOpen : undefined}
            >
                <span className={`flex h-5 w-5 shrink-0 items-center justify-center ${statusColor}`}>
                    {StatusIcon ? <StatusIcon size={16} className={state === 'running' ? 'animate-spin' : ''} /> : <ToolIcon size={17} strokeWidth={1.8} />}
                </span>
                <span className={`shrink-0 text-[14px] font-medium ${state === 'failed' ? 'text-red-600' : 'text-slate-700'}`}>{getToolVerb(tool, state)}</span>
                <span className="min-w-0 flex-1 truncate text-[14px] text-slate-500" title={tool.title}>{tool.title}</span>
                {hasDetails && <ChevronRight size={15} className={`shrink-0 text-slate-300 transition-transform group-hover:text-slate-500 ${detailsOpen ? 'rotate-90' : ''}`} />}
            </button>
            {detailsOpen && hasDetails && <div className="ml-7 mr-1">{tool.input && <ToolDetail label="调用参数" value={tool.input} />}{tool.output && <ToolDetail label="返回结果" value={tool.output} />}</div>}
        </div>
    );
};

const TaskActivityTimeline: React.FC<{ tools: ArkDesktopTask['tools'] }> = ({ tools }) => {
    const [expanded, setExpanded] = useState(false);
    const latestTool = tools[tools.length - 1];
    const hasFailure = tools.some((tool) => getToolState(tool.status) === 'failed');
    const isRunning = tools.some((tool) => ['running', 'pending'].includes(getToolState(tool.status)));
    const summary = hasFailure ? '工具调用存在失败' : isRunning ? '正在调用工具' : `已调用 ${tools.length} 个工具`;

    return (
        <section className="my-1.5" aria-label="工具调用记录">
            <button type="button" onClick={() => setExpanded((value) => !value)} className={`group flex w-full min-w-0 items-center gap-2 rounded-md px-1.5 py-1.5 text-left transition hover:bg-slate-50 ${hasFailure ? 'text-red-600' : 'text-slate-600'}`} aria-expanded={expanded}>
                {hasFailure ? <AlertCircle size={17} /> : isRunning ? <LoaderCircle size={17} className="animate-spin text-blue-500" /> : <Wrench size={17} className="text-slate-400" />}
                <span className="shrink-0 text-[14px] font-medium">{summary}</span>
                {latestTool && <span className="min-w-0 flex-1 truncate text-[13px] text-slate-400">{latestTool.title}</span>}
                <ChevronDown size={15} className={`shrink-0 text-slate-300 transition-transform group-hover:text-slate-500 ${expanded ? '' : '-rotate-90'}`} />
            </button>
            {expanded && <div className="mt-1.5 space-y-0.5 border-l border-slate-200 pl-3">{tools.map((tool) => <ToolActivityItem key={tool.id} tool={tool} />)}</div>}
        </section>
    );
};

export default TaskActivityTimeline;
