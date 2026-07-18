import React, { useEffect, useMemo, useRef, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import {
    AlertCircle, Bot, BriefcaseBusiness, Check, CheckCircle2, CheckSquare,
    ChevronDown, CircleStop, Clock3, Code2, FileText, Folder, History,
    Lightbulb, LoaderCircle, LogIn, Paperclip, Pencil, Play, Plus, RefreshCw,
    Search, Send, Settings, Sparkles, TerminalSquare, Trash2, WandSparkles, Wrench, X,
} from 'lucide-react';
import { useArkDesktopRuntime } from './useArkDesktopRuntime';
import GrokCliCenter from './GrokCliCenter';
import GrokConfigEditor from './GrokConfigEditor';
import GrokExecutionSettingsPanel from './GrokExecutionSettingsPanel';
import type {
    ArkDesktopAgent, ArkDesktopAutomation, ArkDesktopSection, ArkDesktopSkill,
    ArkDesktopTask, ArkDesktopTaskStatus, AutomationSchedule,
} from './types';

const taskTags = [
    { label: '文档处理', icon: FileText, skillId: 'document-processing', prompt: '请读取我选择的文档，整理关键信息并输出可以直接使用的成果。' },
    { label: '工作区检索', icon: Search, skillId: 'workspace-search', prompt: '请检索当前工作区，定位与以下目标最相关的代码、文件和上下文，并给出可追溯的结果：' },
    { label: '数据分析及可视化', icon: BriefcaseBusiness, skillId: 'data-analysis', prompt: '请分析我提供的数据，检查数据质量，并生成结论和可视化产物。' },
    { label: '代码开发', icon: Code2, skillId: 'code-development', prompt: '请分析当前代码仓库并完成以下开发任务，修改后运行必要验证：' },
    { label: '深度研究', icon: Lightbulb, skillId: 'deep-research', prompt: '请围绕以下主题开展深度研究，区分事实、推断和待验证内容：' },
    { label: '技能编排', icon: Wrench, skillId: 'workflow-orchestration', prompt: '请把以下目标拆成可执行步骤，并使用必要工具完成和验证：' },
];

const sectionItems: Array<{ id: ArkDesktopSection; label: string; icon: React.ElementType }> = [
    { id: 'new-task', label: '新建任务', icon: CheckSquare },
    { id: 'agents', label: 'Grok Agents', icon: Bot },
    { id: 'skills', label: 'Grok 技能', icon: WandSparkles },
    { id: 'automations', label: '自动化', icon: BriefcaseBusiness },
    { id: 'cli', label: 'Grok CLI', icon: TerminalSquare },
    { id: 'settings', label: '设置', icon: Settings },
];

const taskStatus: Record<ArkDesktopTaskStatus, { label: string; className: string }> = {
    running: { label: '执行中', className: 'bg-blue-50 text-blue-600' },
    completed: { label: '已完成', className: 'bg-emerald-50 text-emerald-600' },
    failed: { label: '失败', className: 'bg-red-50 text-red-600' },
    cancelled: { label: '已停止', className: 'bg-slate-100 text-slate-500' },
};

const categoryLabel: Record<ArkDesktopSkill['category'], string> = {
    office: '办公', data: '数据', code: '开发', research: '研究', workflow: '编排',
};

const createLocalId = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;

const formatDateTime = (value?: number) => value
    ? new Intl.DateTimeFormat('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }).format(value)
    : '尚未运行';

const nextRunAt = (schedule: AutomationSchedule, scheduleTime: string, weekday = 1, from = Date.now()) => {
    if (schedule === 'manual') return undefined;
    const [hour = 9, minute = 0] = scheduleTime.split(':').map(Number);
    const next = new Date(from);
    next.setHours(hour, minute, 0, 0);
    if (schedule === 'daily') {
        if (next.getTime() <= from) next.setDate(next.getDate() + 1);
        return next.getTime();
    }
    const distance = (weekday - next.getDay() + 7) % 7;
    next.setDate(next.getDate() + distance);
    if (next.getTime() <= from) next.setDate(next.getDate() + 7);
    return next.getTime();
};

const Toggle: React.FC<{ checked: boolean; onChange: () => void; label: string }> = ({ checked, onChange, label }) => (
    <button
        type="button"
        role="switch"
        aria-checked={checked}
        aria-label={label}
        onClick={onChange}
        className={`relative h-6 w-11 rounded-full transition-colors ${checked ? 'bg-slate-900' : 'bg-slate-300'}`}
    >
        <span className={`absolute top-1 h-4 w-4 rounded-full bg-white shadow-sm transition-transform ${checked ? 'translate-x-5' : 'translate-x-1'}`} />
    </button>
);

const Modal: React.FC<{ title: string; onClose: () => void; children: React.ReactNode }> = ({ title, onClose, children }) => (
    <div className="fixed inset-0 z-[1200] flex items-center justify-center bg-slate-950/35 p-5 backdrop-blur-sm">
        <div className="max-h-[88vh] w-full max-w-2xl overflow-y-auto rounded-2xl border border-slate-200 bg-white shadow-2xl">
            <div className="sticky top-0 z-10 flex items-center justify-between border-b border-slate-100 bg-white px-6 py-4">
                <h2 className="text-lg font-semibold text-slate-900">{title}</h2>
                <button type="button" onClick={onClose} className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-700"><X size={18} /></button>
            </div>
            <div className="p-6">{children}</div>
        </div>
    </div>
);

const Field: React.FC<{ label: string; children: React.ReactNode }> = ({ label, children }) => (
    <label className="block">
        <span className="mb-1.5 block text-sm font-medium text-slate-700">{label}</span>
        {children}
    </label>
);

const inputClass = 'w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none transition focus:border-slate-400 focus:ring-2 focus:ring-slate-100';

const ArkDesktopPage: React.FC = () => {
    const runtime = useArkDesktopRuntime();
    const [section, setSection] = useState<ArkDesktopSection>('new-task');
    const [draft, setDraft] = useState('');
    const [followUp, setFollowUp] = useState('');
    const [searchValue, setSearchValue] = useState('');
    const [selectedAgentId, setSelectedAgentId] = useState(runtime.snapshot.settings.defaultAgentId);
    const [selectedSkillIds, setSelectedSkillIds] = useState<string[]>(runtime.snapshot.settings.defaultSkillIds);
    const [attachments, setAttachments] = useState<string[]>([]);
    const [agentMenuOpen, setAgentMenuOpen] = useState(false);
    const [editor, setEditor] = useState<{ type: 'agent' | 'skill' | 'automation'; id?: string } | null>(null);
    const [actionPending, setActionPending] = useState(false);
    const schedulingRef = useRef(false);

    useEffect(() => {
        const initializeSchedules = () => {
            runtime.setSnapshot((current) => {
                const needsInitialization = current.automations.some((automation) => automation.enabled && automation.schedule !== 'manual' && !automation.nextRunAt);
                if (!needsInitialization) return current;
                return {
                    ...current,
                    automations: current.automations.map((automation) => automation.enabled && automation.schedule !== 'manual' && !automation.nextRunAt
                        ? { ...automation, nextRunAt: nextRunAt(automation.schedule, automation.scheduleTime, automation.scheduleWeekday) }
                        : automation),
                };
            });
        };
        initializeSchedules();
        const timer = window.setInterval(async () => {
            if (schedulingRef.current || runtime.snapshot.tasks.some((task) => task.status === 'running')) return;
            const due = runtime.snapshot.automations.find((automation) => automation.enabled && automation.nextRunAt && automation.nextRunAt <= Date.now());
            if (!due) return;
            schedulingRef.current = true;
            runtime.setSnapshot((current) => ({
                ...current,
                automations: current.automations.map((automation) => automation.id === due.id
                    ? { ...automation, nextRunAt: nextRunAt(automation.schedule, automation.scheduleTime, automation.scheduleWeekday) }
                    : automation),
            }));
            try {
                await runtime.startTask({ prompt: due.prompt, agentId: due.agentId, skillIds: due.skillIds, automationId: due.id });
            } catch (error) {
                runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
            } finally {
                schedulingRef.current = false;
            }
        }, 30_000);
        return () => window.clearInterval(timer);
    }, [runtime.setSnapshot, runtime.snapshot.automations, runtime.snapshot.tasks, runtime.startTask, runtime.setRuntimeError]);

    const selectedAgent = runtime.snapshot.agents.find((agent) => agent.id === selectedAgentId);
    const query = searchValue.trim().toLowerCase();
    const filteredAgents = runtime.snapshot.agents.filter((agent) => !query || `${agent.name} ${agent.description}`.toLowerCase().includes(query));
    const filteredTasks = runtime.snapshot.tasks.filter((task) => !query || `${task.title} ${task.prompt}`.toLowerCase().includes(query));

    const openNewTask = () => {
        runtime.setActiveTaskId(null);
        setSection('new-task');
        setDraft('');
        setAttachments([]);
    };

    const runTask = async () => {
        const execution = runtime.snapshot.settings.execution;
        if (execution.engine === 'headless' && (execution.alwaysApprove || execution.permissionMode === 'bypassPermissions')) {
            if (!window.confirm('当前 Headless 配置允许 Grok 无需逐次授权执行本地操作，确认发起任务？')) return;
        }
        setActionPending(true);
        try {
            await runtime.startTask({
                prompt: draft,
                agentId: selectedAgentId || undefined,
                skillIds: selectedSkillIds,
                attachmentPaths: attachments,
            });
            setDraft('');
            setAttachments([]);
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        } finally {
            setActionPending(false);
        }
    };

    const chooseAttachments = async () => {
        try {
            const selected = await runtime.selectAttachments();
            setAttachments((current) => Array.from(new Set([...current, ...selected])));
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        }
    };

    const chooseWorkspace = async () => {
        try {
            await runtime.selectWorkspace();
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        }
    };

    const renderRuntimeBadge = () => {
        if (!runtime.runtimeStatus) return <span className="text-slate-400">检测中…</span>;
        if (!runtime.runtimeStatus.available) return <span className="text-red-600">Grok 未安装</span>;
        if (!runtime.runtimeStatus.authenticated) return <span className="text-amber-600">等待登录</span>;
        return <span className="text-emerald-600">Grok {runtime.runtimeStatus.version || ''} 已就绪</span>;
    };

    return (
        <div className="flex h-screen min-h-[680px] overflow-hidden bg-white text-[#2f3034]">
            <aside className="hidden w-[286px] shrink-0 flex-col border-r border-[#e5e6e9] bg-[#fbfbfc] p-4 lg:flex">
                <div className="mb-6 flex items-center gap-2.5 px-1 pt-1">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#111827] text-white shadow-sm"><Sparkles size={19} /></div>
                    <div><div className="text-[17px] font-bold tracking-[-0.03em] text-[#17181c]">URGS 智能任务中心</div><div className="mt-0.5 text-[11px] font-medium text-slate-400">内置 Grok · 本地工作执行</div></div>
                </div>
                <label className="mb-3 flex h-11 items-center gap-2 rounded-xl border border-[#dedfe3] bg-[#f2f2f3] px-3 text-slate-400 focus-within:bg-white">
                    <Search size={18} /><input value={searchValue} onChange={(event) => setSearchValue(event.target.value)} placeholder="搜索 Grok Agent 或任务" className="min-w-0 flex-1 bg-transparent text-sm text-slate-700 outline-none" />
                </label>
                <div className="space-y-1">
                    {sectionItems.map((item) => {
                        const Icon = item.icon;
                        return <button key={item.id} type="button" onClick={() => item.id === 'new-task' ? openNewTask() : setSection(item.id)} className={`flex h-11 w-full items-center gap-3 rounded-xl px-4 text-left text-sm font-medium transition ${section === item.id && !runtime.activeTask ? 'bg-[#ececee] text-slate-900' : 'text-slate-600 hover:bg-[#f0f0f1]'}`}><Icon size={19} />{item.label}</button>;
                    })}
                </div>
                <div className="mt-6 min-h-0 flex-1 overflow-y-auto">
                    <div className="mb-2 flex items-center justify-between px-1 text-[11px] font-semibold tracking-[0.08em] text-slate-400"><span>最近任务</span><History size={14} /></div>
                    <div className="space-y-1">
                        {filteredTasks.slice(0, 8).map((task) => (
                            <button key={task.id} type="button" onClick={() => runtime.setActiveTaskId(task.id)} className={`w-full rounded-xl px-3 py-2.5 text-left transition hover:bg-slate-100 ${runtime.activeTaskId === task.id ? 'bg-white shadow-sm ring-1 ring-slate-200' : ''}`}>
                                <span className="block truncate text-sm font-medium text-slate-700">{task.title}</span>
                                <span className="mt-1 flex items-center justify-between text-[11px] text-slate-400"><span>{taskStatus[task.status].label}</span><span>{formatDateTime(task.updatedAt)}</span></span>
                            </button>
                        ))}
                        {filteredTasks.length === 0 && <div className="px-3 py-6 text-center text-xs text-slate-400">暂无本地任务</div>}
                    </div>
                </div>
                <div className="mt-3 rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-xs">{renderRuntimeBadge()}</div>
            </aside>

            <section className="relative flex min-w-0 flex-1 flex-col overflow-hidden">
                <header className="flex min-h-14 shrink-0 flex-wrap items-center justify-between gap-2 border-b border-[#eff0f2] px-4 lg:px-6">
                    <div className="flex min-w-0 items-center gap-2">
                        <button type="button" onClick={openNewTask} className="rounded-lg p-2 text-slate-500 hover:bg-slate-100" title="新建任务"><Plus size={18} /></button>
                        <div className="min-w-0"><div className="truncate text-sm font-semibold text-slate-800">{runtime.activeTask?.title || sectionItems.find((item) => item.id === section)?.label}</div><div className="truncate text-[11px] text-slate-400">{runtime.snapshot.settings.workspace || '尚未选择本地工作区'}</div></div>
                    </div>
                    <div className="flex items-center gap-2">
                        {!runtime.runtimeStatus?.authenticated && <button type="button" onClick={() => void runtime.startLogin().catch((error) => runtime.setRuntimeError(String(error)))} className="flex items-center gap-1.5 rounded-lg bg-slate-900 px-3 py-2 text-xs font-medium text-white"><LogIn size={15} />登录 Grok</button>}
                        <button type="button" onClick={() => void runtime.refreshRuntimeStatus()} className="rounded-lg p-2 text-slate-500 hover:bg-slate-100" title="刷新运行状态"><RefreshCw size={17} /></button>
                    </div>
                </header>

                {runtime.runtimeError && <div className="mx-5 mt-4 flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"><AlertCircle size={17} className="mt-0.5 shrink-0" /><span className="flex-1">{runtime.runtimeError}</span><button type="button" onClick={() => runtime.setRuntimeError('')}><X size={16} /></button></div>}

                <main className="custom-scrollbar min-h-0 flex-1 overflow-y-auto">
                    {runtime.activeTask ? <TaskView task={runtime.activeTask} runtime={runtime} followUp={followUp} setFollowUp={setFollowUp} /> : section === 'new-task' ? (
                        <NewTaskView
                            runtime={runtime}
                            draft={draft}
                            setDraft={setDraft}
                            selectedAgentId={selectedAgentId}
                            setSelectedAgentId={setSelectedAgentId}
                            selectedSkillIds={selectedSkillIds}
                            setSelectedSkillIds={setSelectedSkillIds}
                            selectedAgent={selectedAgent}
                            attachments={attachments}
                            setAttachments={setAttachments}
                            agentMenuOpen={agentMenuOpen}
                            setAgentMenuOpen={setAgentMenuOpen}
                            runTask={runTask}
                            chooseAttachments={chooseAttachments}
                            chooseWorkspace={chooseWorkspace}
                            openExecutionSettings={() => setSection('settings')}
                            actionPending={actionPending}
                        />
                    ) : section === 'agents' ? (
                        <AgentsView agents={filteredAgents} skills={runtime.snapshot.skills} runtime={runtime} onEdit={(id) => setEditor({ type: 'agent', id })} onCreate={() => setEditor({ type: 'agent' })} onUse={(id) => { setSelectedAgentId(id); openNewTask(); }} />
                    ) : section === 'skills' ? (
                        <SkillsView skills={runtime.snapshot.skills} runtime={runtime} onEdit={(id) => setEditor({ type: 'skill', id })} onCreate={() => setEditor({ type: 'skill' })} />
                    ) : section === 'automations' ? (
                        <AutomationsView automations={runtime.snapshot.automations} runtime={runtime} onEdit={(id) => setEditor({ type: 'automation', id })} onCreate={() => setEditor({ type: 'automation' })} />
                    ) : section === 'cli' ? (
                        <GrokCliCenter workspace={runtime.snapshot.settings.workspace} onError={runtime.setRuntimeError} onLogin={runtime.startLogin} onRuntimeRefresh={runtime.refreshRuntimeStatus} />
                    ) : <SettingsView runtime={runtime} chooseWorkspace={chooseWorkspace} />}
                </main>
            </section>

            {editor?.type === 'agent' && <AgentEditor id={editor.id} runtime={runtime} onClose={() => setEditor(null)} />}
            {editor?.type === 'skill' && <SkillEditor id={editor.id} runtime={runtime} onClose={() => setEditor(null)} />}
            {editor?.type === 'automation' && <AutomationEditor id={editor.id} runtime={runtime} onClose={() => setEditor(null)} />}
            {runtime.permission && <Modal title="允许 Grok 执行本地操作？" onClose={() => void runtime.answerPermission()}><p className="mb-5 text-sm leading-6 text-slate-600">{runtime.permission.title}</p><div className="flex flex-wrap justify-end gap-2"><button type="button" onClick={() => void runtime.answerPermission()} className="rounded-lg border border-slate-200 px-4 py-2 text-sm text-slate-600">拒绝</button>{runtime.permission.options.map((option) => <button key={option.optionId} type="button" onClick={() => void runtime.answerPermission(option.optionId)} className="rounded-lg bg-slate-900 px-4 py-2 text-sm text-white">{option.name}</button>)}</div></Modal>}
        </div>
    );
};

interface NewTaskViewProps {
    runtime: ReturnType<typeof useArkDesktopRuntime>;
    draft: string;
    setDraft: React.Dispatch<React.SetStateAction<string>>;
    selectedAgentId: string;
    setSelectedAgentId: (id: string) => void;
    selectedSkillIds: string[];
    setSelectedSkillIds: React.Dispatch<React.SetStateAction<string[]>>;
    selectedAgent?: ArkDesktopAgent;
    attachments: string[];
    setAttachments: React.Dispatch<React.SetStateAction<string[]>>;
    agentMenuOpen: boolean;
    setAgentMenuOpen: React.Dispatch<React.SetStateAction<boolean>>;
    runTask: () => Promise<void>;
    chooseAttachments: () => Promise<void>;
    chooseWorkspace: () => Promise<void>;
    openExecutionSettings: () => void;
    actionPending: boolean;
}

const NewTaskView: React.FC<NewTaskViewProps> = ({ runtime, draft, setDraft, selectedAgentId, setSelectedAgentId, selectedSkillIds, setSelectedSkillIds, selectedAgent, attachments, setAttachments, agentMenuOpen, setAgentMenuOpen, runTask, chooseAttachments, chooseWorkspace, openExecutionSettings, actionPending }) => (
    <div className="min-h-full px-5 py-8 md:px-10 lg:px-16">
        <div className="mx-auto w-full max-w-6xl">
            <div className="flex flex-col items-center text-center">
                <img src="/ark/ark-agents-robot-cropped.png" alt="URGS 智能任务中心" className="mb-2 h-20 w-20 object-contain mix-blend-multiply" />
                <h1 className="text-3xl font-semibold tracking-[-0.04em] text-[#303136] sm:text-[34px]">把本地工作交给 URGS 智能任务中心</h1>
                <p className="mt-2 text-base text-slate-500">内置 Grok 在你明确选择的工作区内执行，过程和产物都可追溯</p>
                <div className="mt-5 flex w-full flex-wrap justify-center gap-2.5">
                    {taskTags.map((tag) => { const Icon = tag.icon; const active = selectedSkillIds.includes(tag.skillId); return <button key={tag.label} type="button" onClick={() => { setDraft(tag.prompt); setSelectedSkillIds((current) => active ? current.filter((id) => id !== tag.skillId) : [...current, tag.skillId]); }} className={`flex items-center gap-2 rounded-full px-4 py-2.5 text-sm font-medium transition hover:-translate-y-0.5 ${active ? 'bg-slate-900 text-white' : 'bg-[#e9e9eb] text-[#494a4f] hover:bg-[#dedee1]'}`}><Icon size={17} />{tag.label}{active && <Check size={14} />}</button>; })}
                </div>
            </div>
            <div className="mt-7 grid gap-5 lg:grid-cols-[minmax(0,1fr)_300px]">
                <div>
            {attachments.length > 0 && <div className="mb-2 flex flex-wrap gap-2">{attachments.map((path) => <span key={path} title={path} className="flex max-w-72 items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs text-slate-600"><Paperclip size={13} /><span className="truncate">{path.split(/[\\/]/).pop()}</span><button type="button" onClick={() => setAttachments((current) => current.filter((item) => item !== path))}><X size={13} /></button></span>)}</div>}
            <div className="rounded-[26px] border border-slate-200 bg-[#f4f4f5] p-3 shadow-[0_10px_28px_rgba(15,23,42,0.06)] focus-within:border-slate-300">
                <textarea value={draft} onChange={(event) => setDraft(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter' && !event.shiftKey) { event.preventDefault(); void runTask(); } }} placeholder="描述你希望 Grok Agent 在本地完成的任务…" rows={3} className="w-full resize-none bg-transparent px-3 py-2 text-base leading-7 text-slate-700 outline-none placeholder:text-slate-400" />
                <div className="flex flex-wrap items-center justify-between gap-2 px-1 pt-1">
                    <div className="relative flex flex-wrap items-center gap-2">
                        <button type="button" onClick={() => setAgentMenuOpen((open) => !open)} className="flex items-center gap-2 rounded-lg bg-[#e3e3e5] px-3 py-2 text-sm font-medium text-slate-600 hover:bg-[#d8d8db]"><Bot size={16} /><span className="max-w-44 truncate">{selectedAgent?.name || '自动选择 Agent'}</span><ChevronDown size={15} /></button>
                        {agentMenuOpen && <div className="absolute bottom-11 left-0 z-20 max-h-64 w-72 overflow-y-auto rounded-xl border border-slate-200 bg-white p-1.5 shadow-xl"><button type="button" onClick={() => { setSelectedAgentId(''); setAgentMenuOpen(false); }} className="w-full rounded-lg px-3 py-2 text-left text-sm text-slate-600 hover:bg-slate-100">自动选择 Agent</button>{runtime.snapshot.agents.filter((agent) => agent.enabled).map((agent) => <button key={agent.id} type="button" onClick={() => { setSelectedAgentId(agent.id); setAgentMenuOpen(false); }} className="w-full truncate rounded-lg px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-100">{agent.name}</button>)}</div>}
                        <button type="button" onClick={() => void chooseAttachments()} className="rounded-lg p-2 text-slate-500 hover:bg-[#e3e3e5]" title="添加本地文件"><Paperclip size={18} /></button>
                        <button type="button" onClick={openExecutionSettings} className="flex items-center gap-1.5 rounded-lg px-2.5 py-2 text-xs font-medium text-slate-500 hover:bg-[#e3e3e5]" title="配置任务执行参数"><Settings size={16} />{runtime.snapshot.settings.execution.engine === 'acp' ? 'ACP' : 'CLI Headless'}</button>
                    </div>
                    <div className="flex items-center gap-2">
                        <button type="button" onClick={() => void chooseWorkspace()} className="flex max-w-64 items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-slate-500 hover:bg-[#e3e3e5]" title={runtime.snapshot.settings.workspace}><Folder size={17} /><span className="truncate">{runtime.snapshot.settings.workspace ? runtime.snapshot.settings.workspace.split(/[\\/]/).pop() : '选择工作区'}</span></button>
                        <button type="button" disabled={actionPending || (!draft.trim() && (runtime.snapshot.settings.execution.engine !== 'headless' || runtime.snapshot.settings.execution.promptMode === 'text'))} onClick={() => void runTask()} className="flex h-10 w-10 items-center justify-center rounded-full bg-[#202126] text-white shadow-sm transition hover:scale-105 disabled:cursor-not-allowed disabled:opacity-40">{actionPending ? <LoaderCircle size={17} className="animate-spin" /> : <Send size={17} />}</button>
                    </div>
                </div>
            </div>
                    <p className="mt-3 text-center text-xs text-slate-400">Grok 仅能访问你选择的工作区；执行命令和写文件前会请求授权。</p>
                </div>
                <aside className="grid gap-3 sm:grid-cols-3 lg:grid-cols-1">
                    <button type="button" onClick={() => void chooseWorkspace()} className="rounded-2xl border border-slate-200 bg-white p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-slate-300"><div className="flex items-center justify-between"><Folder size={18} className="text-slate-700" /><span className="text-xs font-medium text-slate-400">工作区</span></div><div className="mt-4 truncate text-sm font-semibold text-slate-800">{runtime.snapshot.settings.workspace ? runtime.snapshot.settings.workspace.split(/[\\/]/).pop() : '选择本地工作区'}</div><p className="mt-1 text-xs leading-5 text-slate-500">限定 Grok 可以读取和操作的范围</p></button>
                    <button type="button" onClick={openExecutionSettings} className="rounded-2xl border border-slate-200 bg-white p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-slate-300"><div className="flex items-center justify-between"><Settings size={18} className="text-slate-700" /><span className="text-xs font-medium text-slate-400">执行方式</span></div><div className="mt-4 text-sm font-semibold text-slate-800">{runtime.snapshot.settings.execution.engine === 'acp' ? 'ACP Agent' : 'CLI Headless'}</div><p className="mt-1 text-xs leading-5 text-slate-500">模型、授权和 CLI 参数均可配置</p></button>
                    <button type="button" onClick={() => setAgentMenuOpen(true)} className="rounded-2xl border border-slate-200 bg-white p-4 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-slate-300"><div className="flex items-center justify-between"><Bot size={18} className="text-slate-700" /><span className="text-xs font-medium text-slate-400">当前 Agent</span></div><div className="mt-4 truncate text-sm font-semibold text-slate-800">{selectedAgent?.name || '自动选择'}</div><p className="mt-1 text-xs leading-5 text-slate-500">已选 {selectedSkillIds.length} 项本地技能</p></button>
                </aside>
            </div>
        </div>
    </div>
);

const TaskView: React.FC<{ task: ArkDesktopTask; runtime: ReturnType<typeof useArkDesktopRuntime>; followUp: string; setFollowUp: (value: string) => void }> = ({ task, runtime, followUp, setFollowUp }) => {
    const [sending, setSending] = useState(false);
    const submit = async () => { if (!followUp.trim()) return; setSending(true); try { await runtime.sendFollowUp(task.id, followUp.trim()); setFollowUp(''); } catch (error) { runtime.setRuntimeError(error instanceof Error ? error.message : String(error)); } finally { setSending(false); } };
    return <div className="mx-auto flex min-h-full w-full max-w-5xl flex-col px-5 py-6 md:px-10">
        <div className="mb-5 flex flex-wrap items-center justify-between gap-3"><div><h1 className="text-xl font-semibold text-slate-900">{task.title}</h1><p className="mt-1 text-xs text-slate-400">{task.workspace} · {formatDateTime(task.createdAt)}</p></div><span className={`rounded-full px-3 py-1 text-xs font-medium ${taskStatus[task.status].className}`}>{task.status === 'running' && <LoaderCircle size={12} className="mr-1 inline animate-spin" />}{taskStatus[task.status].label}</span></div>
        <div className="flex-1 space-y-5">{task.messages.map((message) => <div key={message.id} className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}><div className={`max-w-[88%] rounded-2xl px-4 py-3 text-sm leading-7 ${message.role === 'user' ? 'bg-slate-900 text-white' : 'border border-slate-200 bg-white text-slate-700 shadow-sm'}`}>{message.role === 'assistant' ? <div className="prose prose-sm max-w-none"><ReactMarkdown>{message.content}</ReactMarkdown></div> : <span className="whitespace-pre-wrap">{message.content}</span>}</div></div>)}
            {task.tools.length > 0 && <div className="rounded-2xl border border-slate-200 bg-slate-50 p-4"><div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-700"><Wrench size={16} />本地执行步骤</div><div className="space-y-2">{task.tools.map((tool) => <div key={tool.id} className="flex items-center justify-between gap-3 rounded-xl bg-white px-3 py-2 text-sm"><span className="truncate text-slate-600">{tool.title}</span><span className="shrink-0 text-xs text-slate-400">{tool.status}</span></div>)}</div></div>}
            {task.error && <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{task.error}</div>}
            {task.status === 'running' && task.messages[task.messages.length - 1]?.role === 'user' && <div className="flex items-center gap-2 text-sm text-slate-400"><LoaderCircle size={16} className="animate-spin" />Grok 正在分析并执行任务…</div>}
        </div>
        <div className="sticky bottom-0 mt-6 bg-white/95 pt-3 backdrop-blur"><div className="flex items-end gap-2 rounded-2xl border border-slate-200 bg-slate-50 p-2"><textarea value={followUp} onChange={(event) => setFollowUp(event.target.value)} disabled={task.status === 'running'} placeholder={task.sessionId ? '继续给 Grok 补充要求…' : '历史会话已结束，请新建任务'} rows={2} className="min-w-0 flex-1 resize-none bg-transparent px-2 py-1.5 text-sm outline-none disabled:cursor-not-allowed" />{task.status === 'running' ? <button type="button" onClick={() => void runtime.cancelTask(task.id)} className="flex h-10 items-center gap-1.5 rounded-xl bg-red-600 px-3 text-sm text-white"><CircleStop size={16} />停止</button> : <button type="button" disabled={sending || !task.sessionId || !followUp.trim()} onClick={() => void submit()} className="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-900 text-white disabled:opacity-40">{sending ? <LoaderCircle size={16} className="animate-spin" /> : <Send size={16} />}</button>}</div></div>
    </div>;
};

const ViewHeader: React.FC<{ title: string; description: string; onCreate: () => void; button: string }> = ({ title, description, onCreate, button }) => <div className="mb-6 flex flex-wrap items-end justify-between gap-3"><div><h1 className="text-2xl font-semibold text-slate-900">{title}</h1><p className="mt-1 text-sm text-slate-500">{description}</p></div><button type="button" onClick={onCreate} className="flex items-center gap-2 rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-medium text-white"><Plus size={16} />{button}</button></div>;

const AgentsView: React.FC<{ agents: ArkDesktopAgent[]; skills: ArkDesktopSkill[]; runtime: ReturnType<typeof useArkDesktopRuntime>; onEdit: (id: string) => void; onCreate: () => void; onUse: (id: string) => void }> = ({ agents, skills, runtime, onEdit, onCreate, onUse }) => <div className="p-6 md:p-8"><ViewHeader title="Grok Agents" description="仅配置 Grok 本地任务角色，不读取或复用 ARK Chat Agent。" onCreate={onCreate} button="新建 Grok Agent" /><div className="grid gap-4 xl:grid-cols-2">{agents.map((agent) => <div key={agent.id} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><div className="flex items-start justify-between gap-3"><div className="flex min-w-0 gap-3"><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-slate-600"><Bot size={19} /></span><div><h3 className="font-semibold text-slate-900">{agent.name}</h3><p className="mt-1 text-sm leading-6 text-slate-500">{agent.description}</p></div></div><Toggle checked={agent.enabled} label={`启用 ${agent.name}`} onChange={() => runtime.setSnapshot((current) => ({ ...current, agents: current.agents.map((item) => item.id === agent.id ? { ...item, enabled: !item.enabled } : item) }))} /></div><div className="mt-4 flex flex-wrap gap-1.5">{agent.skillIds.map((id) => <span key={id} className="rounded-lg bg-slate-100 px-2 py-1 text-xs text-slate-500">{skills.find((skill) => skill.id === id)?.name || id}</span>)}</div><div className="mt-4 flex justify-end gap-2"><button type="button" onClick={() => onEdit(agent.id)} className="rounded-lg border border-slate-200 p-2 text-slate-500 hover:bg-slate-50"><Pencil size={16} /></button><button type="button" onClick={() => onUse(agent.id)} className="rounded-lg bg-slate-900 px-3 py-2 text-xs font-medium text-white">使用此 Agent</button></div></div>)}</div></div>;

const SkillsView: React.FC<{ skills: ArkDesktopSkill[]; runtime: ReturnType<typeof useArkDesktopRuntime>; onEdit: (id: string) => void; onCreate: () => void }> = ({ skills, runtime, onEdit, onCreate }) => <div className="p-6 md:p-8"><ViewHeader title="Grok 技能" description="仅注入 Grok 本地会话，不读取或复用原 ARK 技能。" onCreate={onCreate} button="新建 Grok 技能" /><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">{skills.map((skill) => <div key={skill.id} className="rounded-2xl border border-slate-200 p-5"><div className="flex items-start justify-between gap-3"><span className="rounded-lg bg-slate-100 px-2 py-1 text-xs text-slate-500">{categoryLabel[skill.category]}</span><Toggle checked={skill.enabled} label={`启用 ${skill.name}`} onChange={() => runtime.setSnapshot((current) => ({ ...current, skills: current.skills.map((item) => item.id === skill.id ? { ...item, enabled: !item.enabled } : item) }))} /></div><h3 className="mt-4 font-semibold text-slate-900">{skill.name}</h3><p className="mt-2 text-sm leading-6 text-slate-500">{skill.description}</p><button type="button" onClick={() => onEdit(skill.id)} className="mt-4 flex items-center gap-1.5 text-xs font-medium text-slate-600"><Pencil size={14} />编辑 Grok 指令</button></div>)}</div></div>;

const AutomationsView: React.FC<{ automations: ArkDesktopAutomation[]; runtime: ReturnType<typeof useArkDesktopRuntime>; onEdit: (id: string) => void; onCreate: () => void }> = ({ automations, runtime, onEdit, onCreate }) => {
    const run = async (automation: ArkDesktopAutomation) => { try { runtime.setActiveTaskId(await runtime.startTask({ prompt: automation.prompt, agentId: automation.agentId, skillIds: automation.skillIds, automationId: automation.id })); } catch (error) { runtime.setRuntimeError(error instanceof Error ? error.message : String(error)); } };
    return <div className="p-6 md:p-8"><ViewHeader title="自动化" description="保存可重复任务；每日/每周计划会在 URGS 桌面客户端运行期间自动触发。" onCreate={onCreate} button="新建自动化" /><div className="space-y-4">{automations.map((automation) => <div key={automation.id} className="rounded-2xl border border-slate-200 p-5"><div className="flex flex-wrap items-start justify-between gap-4"><div><div className="flex items-center gap-2"><h3 className="font-semibold text-slate-900">{automation.name}</h3>{automation.schedule !== 'manual' && <span className="rounded-full bg-blue-50 px-2 py-1 text-[11px] text-blue-600"><Clock3 size={11} className="mr-1 inline" />{automation.schedule === 'daily' ? '每日' : '每周'} {automation.scheduleTime}</span>}</div><p className="mt-1 text-sm text-slate-500">{automation.description}</p><p className="mt-3 line-clamp-2 text-sm leading-6 text-slate-600">{automation.prompt}</p><div className="mt-3 text-xs text-slate-400">上次：{formatDateTime(automation.lastRunAt)}{automation.nextRunAt ? ` · 下次：${formatDateTime(automation.nextRunAt)}` : ''}</div></div><div className="flex items-center gap-2"><Toggle checked={automation.enabled} label={`启用 ${automation.name}`} onChange={() => runtime.setSnapshot((current) => ({ ...current, automations: current.automations.map((item) => item.id === automation.id ? { ...item, enabled: !item.enabled, nextRunAt: !item.enabled ? nextRunAt(item.schedule, item.scheduleTime, item.scheduleWeekday) : undefined } : item) }))} /><button type="button" onClick={() => onEdit(automation.id)} className="rounded-lg border border-slate-200 p-2 text-slate-500"><Pencil size={16} /></button><button type="button" disabled={!automation.enabled} onClick={() => void run(automation)} className="flex items-center gap-1.5 rounded-lg bg-slate-900 px-3 py-2 text-xs font-medium text-white disabled:opacity-40"><Play size={14} />立即运行</button></div></div></div>)}</div></div>;
};

const SettingsView: React.FC<{ runtime: ReturnType<typeof useArkDesktopRuntime>; chooseWorkspace: () => Promise<void> }> = ({ runtime, chooseWorkspace }) => <div className="mx-auto max-w-4xl p-6 md:p-8">
    <div className="mb-6"><h1 className="text-2xl font-semibold text-slate-900">设置</h1><p className="mt-1 text-sm text-slate-500">配置 Grok 本地运行时和全部任务级 CLI 参数。</p></div>
    <div className="space-y-4">
        <div className="rounded-2xl border border-slate-200 p-5"><div className="flex items-start justify-between gap-3"><div><h3 className="font-semibold text-slate-900">Grok Build 运行时</h3><p className="mt-1 text-sm text-slate-500">{runtime.runtimeStatus?.message || (runtime.runtimeStatus?.available ? `版本 ${runtime.runtimeStatus.version || '未知'}` : '正在检测安装包内置组件')}</p><p className="mt-2 break-all text-xs text-slate-400">配置目录：{runtime.runtimeStatus?.grokHome || '-'}</p></div>{runtime.runtimeStatus?.authenticated ? <span className="flex items-center gap-1.5 text-sm text-emerald-600"><CheckCircle2 size={16} />已登录</span> : <button type="button" onClick={() => void runtime.startLogin().catch((error) => runtime.setRuntimeError(String(error)))} className="rounded-lg bg-slate-900 px-3 py-2 text-xs text-white">登录 Grok</button>}</div></div>
        <div className="rounded-2xl border border-slate-200 p-5"><h3 className="font-semibold text-slate-900">默认工作区</h3><p className="mt-2 break-all text-sm text-slate-500">{runtime.snapshot.settings.workspace || '尚未选择'}</p><button type="button" onClick={() => void chooseWorkspace()} className="mt-4 flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600"><Folder size={16} />选择目录</button></div>
        <GrokExecutionSettingsPanel
            model={runtime.snapshot.settings.grokModel}
            value={runtime.snapshot.settings.execution}
            onModelChange={(grokModel) => runtime.setSnapshot((current) => ({ ...current, settings: { ...current.settings, grokModel } }))}
            onChange={(execution) => runtime.setSnapshot((current) => ({ ...current, settings: { ...current.settings, execution } }))}
        />
        <GrokConfigEditor workspace={runtime.snapshot.settings.workspace} onError={runtime.setRuntimeError} />
        <div className="rounded-2xl border border-red-200 p-5"><h3 className="font-semibold text-slate-900">重置本地数据</h3><p className="mt-1 text-sm text-slate-500">清除自定义 Grok Agent、技能、CLI 配置、自动化和任务历史，不会删除工作区文件。</p><button type="button" onClick={() => { if (window.confirm('确认重置 ARK Desktop 的全部本地配置和历史？')) runtime.resetAll(); }} className="mt-4 flex items-center gap-2 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700"><Trash2 size={16} />重置数据</button></div>
    </div>
</div>;

const AgentEditor: React.FC<{ id?: string; runtime: ReturnType<typeof useArkDesktopRuntime>; onClose: () => void }> = ({ id, runtime, onClose }) => {
    const source = runtime.snapshot.agents.find((item) => item.id === id);
    const [value, setValue] = useState<ArkDesktopAgent>(source || { id: createLocalId('agent'), name: '', description: '', systemPrompt: '', skillIds: [], enabled: true, builtIn: false });
    const save = () => { if (!value.name.trim() || !value.systemPrompt.trim()) return; runtime.setSnapshot((current) => ({ ...current, agents: source ? current.agents.map((item) => item.id === source.id ? value : item) : [...current.agents, value] })); onClose(); };
    return <Modal title={source ? '编辑 Agent' : '新建 Agent'} onClose={onClose}><div className="space-y-4"><Field label="名称"><input className={inputClass} value={value.name} onChange={(event) => setValue({ ...value, name: event.target.value })} /></Field><Field label="说明"><input className={inputClass} value={value.description} onChange={(event) => setValue({ ...value, description: event.target.value })} /></Field><Field label="系统指令"><textarea className={inputClass} rows={6} value={value.systemPrompt} onChange={(event) => setValue({ ...value, systemPrompt: event.target.value })} /></Field><Field label="启用技能"><div className="grid gap-2 sm:grid-cols-2">{runtime.snapshot.skills.map((skill) => <label key={skill.id} className="flex items-center gap-2 rounded-lg border border-slate-200 p-2.5 text-sm"><input type="checkbox" checked={value.skillIds.includes(skill.id)} onChange={() => setValue({ ...value, skillIds: value.skillIds.includes(skill.id) ? value.skillIds.filter((item) => item !== skill.id) : [...value.skillIds, skill.id] })} />{skill.name}</label>)}</div></Field><EditorActions canDelete={Boolean(source && !source.builtIn)} onDelete={() => { runtime.setSnapshot((current) => ({ ...current, agents: current.agents.filter((item) => item.id !== source?.id) })); onClose(); }} onClose={onClose} onSave={save} /></div></Modal>;
};

const SkillEditor: React.FC<{ id?: string; runtime: ReturnType<typeof useArkDesktopRuntime>; onClose: () => void }> = ({ id, runtime, onClose }) => {
    const source = runtime.snapshot.skills.find((item) => item.id === id);
    const [value, setValue] = useState<ArkDesktopSkill>(source || { id: createLocalId('skill'), name: '', description: '', instruction: '', category: 'workflow', enabled: true, builtIn: false });
    const save = () => { if (!value.name.trim() || !value.instruction.trim()) return; runtime.setSnapshot((current) => ({ ...current, skills: source ? current.skills.map((item) => item.id === source.id ? value : item) : [...current.skills, value] })); onClose(); };
    return <Modal title={source ? '编辑技能' : '新建技能'} onClose={onClose}><div className="space-y-4"><Field label="名称"><input className={inputClass} value={value.name} onChange={(event) => setValue({ ...value, name: event.target.value })} /></Field><Field label="分类"><select className={inputClass} value={value.category} onChange={(event) => setValue({ ...value, category: event.target.value as ArkDesktopSkill['category'] })}>{Object.entries(categoryLabel).map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></Field><Field label="说明"><input className={inputClass} value={value.description} onChange={(event) => setValue({ ...value, description: event.target.value })} /></Field><Field label="执行指令"><textarea className={inputClass} rows={7} value={value.instruction} onChange={(event) => setValue({ ...value, instruction: event.target.value })} /></Field><EditorActions canDelete={Boolean(source && !source.builtIn)} onDelete={() => { runtime.setSnapshot((current) => ({ ...current, skills: current.skills.filter((item) => item.id !== source?.id) })); onClose(); }} onClose={onClose} onSave={save} /></div></Modal>;
};

const AutomationEditor: React.FC<{ id?: string; runtime: ReturnType<typeof useArkDesktopRuntime>; onClose: () => void }> = ({ id, runtime, onClose }) => {
    const source = runtime.snapshot.automations.find((item) => item.id === id);
    const [value, setValue] = useState<ArkDesktopAutomation>(source || { id: createLocalId('automation'), name: '', description: '', prompt: '', agentId: runtime.snapshot.settings.defaultAgentId, skillIds: [], schedule: 'manual', scheduleTime: '09:00', scheduleWeekday: 1, enabled: true });
    const save = () => { if (!value.name.trim() || !value.prompt.trim()) return; const saved = { ...value, nextRunAt: value.enabled ? nextRunAt(value.schedule, value.scheduleTime, value.scheduleWeekday) : undefined }; runtime.setSnapshot((current) => ({ ...current, automations: source ? current.automations.map((item) => item.id === source.id ? saved : item) : [...current.automations, saved] })); onClose(); };
    return <Modal title={source ? '编辑自动化' : '新建自动化'} onClose={onClose}><div className="space-y-4"><Field label="名称"><input className={inputClass} value={value.name} onChange={(event) => setValue({ ...value, name: event.target.value })} /></Field><Field label="说明"><input className={inputClass} value={value.description} onChange={(event) => setValue({ ...value, description: event.target.value })} /></Field><Field label="任务内容"><textarea className={inputClass} rows={6} value={value.prompt} onChange={(event) => setValue({ ...value, prompt: event.target.value })} /></Field><div className="grid gap-4 sm:grid-cols-2"><Field label="执行 Agent"><select className={inputClass} value={value.agentId} onChange={(event) => setValue({ ...value, agentId: event.target.value })}>{runtime.snapshot.agents.filter((agent) => agent.enabled).map((agent) => <option key={agent.id} value={agent.id}>{agent.name}</option>)}</select></Field><Field label="运行计划"><select className={inputClass} value={value.schedule} onChange={(event) => setValue({ ...value, schedule: event.target.value as AutomationSchedule })}><option value="manual">仅手动</option><option value="daily">每日</option><option value="weekly">每周</option></select></Field></div>{value.schedule !== 'manual' && <div className="grid gap-4 sm:grid-cols-2">{value.schedule === 'weekly' && <Field label="星期"><select className={inputClass} value={value.scheduleWeekday} onChange={(event) => setValue({ ...value, scheduleWeekday: Number(event.target.value) })}>{['周日', '周一', '周二', '周三', '周四', '周五', '周六'].map((label, index) => <option key={label} value={index}>{label}</option>)}</select></Field>}<Field label="时间"><input type="time" className={inputClass} value={value.scheduleTime} onChange={(event) => setValue({ ...value, scheduleTime: event.target.value })} /></Field></div>}<EditorActions canDelete={Boolean(source)} onDelete={() => { runtime.setSnapshot((current) => ({ ...current, automations: current.automations.filter((item) => item.id !== source?.id) })); onClose(); }} onClose={onClose} onSave={save} /></div></Modal>;
};

const EditorActions: React.FC<{ canDelete: boolean; onDelete: () => void; onClose: () => void; onSave: () => void }> = ({ canDelete, onDelete, onClose, onSave }) => <div className="flex items-center justify-between border-t border-slate-100 pt-4">{canDelete ? <button type="button" onClick={onDelete} className="flex items-center gap-1.5 text-sm text-red-600"><Trash2 size={15} />删除</button> : <span />}<div className="flex gap-2"><button type="button" onClick={onClose} className="rounded-lg border border-slate-200 px-4 py-2 text-sm text-slate-600">取消</button><button type="button" onClick={onSave} className="rounded-lg bg-slate-900 px-4 py-2 text-sm text-white">保存</button></div></div>;

export default ArkDesktopPage;
