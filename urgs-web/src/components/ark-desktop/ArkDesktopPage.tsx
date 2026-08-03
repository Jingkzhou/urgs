import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkBreaks from 'remark-breaks';
import remarkGfm from 'remark-gfm';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneDark } from 'react-syntax-highlighter/dist/esm/styles/prism';
import {
    AlertCircle, Bot, BriefcaseBusiness, Check, CheckCircle2, CheckSquare,
    ChevronDown, ChevronUp, CircleStop, Code2, Copy, Cpu, FileText, Folder, FolderOpen,
    Hand, KeyRound, Lightbulb, LoaderCircle, Paperclip, Pencil, Plus,
    Puzzle, Search, Send, Settings, ShieldAlert, Trash2, WandSparkles, Wrench, X,
} from 'lucide-react';
import { copyToClipboard } from '@/utils/clipboard';
import { useArkDesktopRuntime } from './useArkDesktopRuntime';
import GrokCliCenter from './GrokCliCenter';
import GrokPluginManager from './GrokPluginManager';
import GrokConfigEditor from './GrokConfigEditor';
import GrokExecutionSettingsPanel from './GrokExecutionSettingsPanel';
import AutomationCenter from './AutomationCenter';
import { ArkDesktopSidebarToggle, ArkDesktopTitleContent } from './ArkDesktopTitleBar';
import { ConversationPromptInput } from './SlashCommandMenu';
import SessionCommandBar from './SessionCommandBar';
import TaskActivityTimeline from './TaskActivityTimeline';
import TaskChangeSummary from './TaskChangeSummary';
import TaskPlanPanel from './TaskPlanPanel';
import PlanApprovalDialog from './PlanApprovalDialog';
import UserQuestionDialog from './UserQuestionDialog';
import WorkspaceSessionSidebar from './WorkspaceSessionSidebar';
import type {
    ArkDesktopAgent, ArkDesktopAutomation, ArkDesktopSection, ArkDesktopSkill,
    ArkDesktopModelProvider, ArkDesktopTask, ArkDesktopTaskStatus, AutomationSchedule, GrokExecutionSettings,
} from './types';
import { nextAutomationRunAt } from './automationSchedule';

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
    { id: 'agents', label: '智能体', icon: Bot },
    { id: 'skills', label: '技能', icon: WandSparkles },
    { id: 'automations', label: '自动化', icon: BriefcaseBusiness },
];

type SettingsTab = 'general' | 'execution' | 'configuration' | 'plugins' | 'diagnostics';

const taskStatus: Record<ArkDesktopTaskStatus, { label: string; className: string }> = {
    running: { label: '执行中', className: 'bg-blue-50 text-blue-600' },
    waiting_authorization: { label: '等待解锁', className: 'bg-amber-50 text-amber-700' },
    completed: { label: '已完成', className: 'bg-emerald-50 text-emerald-600' },
    failed: { label: '失败', className: 'bg-red-50 text-red-600' },
    cancelled: { label: '已停止', className: 'bg-slate-100 text-slate-500' },
};

const categoryLabel: Record<ArkDesktopSkill['category'], string> = {
    office: '办公', data: '数据', code: '开发', research: '研究', workflow: '编排',
};

type PermissionMode = GrokExecutionSettings['permissionMode'];

const permissionModeOptions: Array<{
    value: PermissionMode;
    label: string;
    description: string;
    icon: React.ElementType;
    dangerous?: boolean;
}> = [
    { value: 'default', label: '请求批准', description: '编辑文件、运行命令和访问网络前询问', icon: Hand },
    { value: 'bypassPermissions', label: '完全访问权限', description: '不受限制地访问网络和本地工作区', icon: ShieldAlert, dangerous: true },
];

const createLocalId = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;

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
    const [followUpDrafts, setFollowUpDrafts] = useState<Record<string, string>>({});
    const [searchValue, setSearchValue] = useState('');
    const [selectedAgentId, setSelectedAgentId] = useState('');
    const [selectedSkillIds, setSelectedSkillIds] = useState<string[]>(runtime.snapshot.settings.defaultSkillIds);
    const [attachments, setAttachments] = useState<string[]>([]);
    const [attachmentGrantIds, setAttachmentGrantIds] = useState<string[]>([]);
    const [draftWorkspace, setDraftWorkspace] = useState(runtime.snapshot.settings.workspace);
    const [latestMessageTaskId, setLatestMessageTaskId] = useState<string | null>(null);
    const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
    const [settingsTab, setSettingsTab] = useState<SettingsTab>('general');

    const [editor, setEditor] = useState<{ type: 'agent' | 'skill' | 'automation'; id?: string } | null>(null);
    const [actionPending, setActionPending] = useState(false);
    const schedulingRef = useRef(false);
    const draftWorkspaceFollowsDefaultRef = useRef(true);
    const conversationScrollRef = useRef<HTMLDivElement>(null);
    const clearLatestMessageLocation = useCallback(() => setLatestMessageTaskId(null), []);

    useEffect(() => {
        const initializeSchedules = () => {
            runtime.setSnapshot((current) => {
                const needsInitialization = current.automations.some((automation) => automation.enabled && automation.schedule !== 'manual' && !automation.nextRunAt);
                if (!needsInitialization) return current;
                return {
                    ...current,
                    automations: current.automations.map((automation) => automation.enabled && automation.schedule !== 'manual' && !automation.nextRunAt
                        ? { ...automation, nextRunAt: nextAutomationRunAt(automation.schedule, automation.scheduleTime, automation.scheduleWeekday) }
                        : automation),
                };
            });
        };
        initializeSchedules();
        const timer = window.setInterval(async () => {
            if (schedulingRef.current) return;
            const due = runtime.snapshot.automations.find((automation) => (
                automation.enabled
                && automation.nextRunAt
                && automation.nextRunAt <= Date.now()
                && !runtime.snapshot.tasks.some((task) => task.automationId === automation.id && task.status === 'running')
            ));
            if (!due) return;
            schedulingRef.current = true;
            try {
                await runtime.startTask({
                    prompt: due.prompt,
                    workspace: due.workspace,
                    agentId: due.agentId,
                    skillIds: due.skillIds,
                    automationId: due.id,
                });
                runtime.setSnapshot((current) => ({
                    ...current,
                    automations: current.automations.map((automation) => automation.id === due.id
                        ? { ...automation, nextRunAt: nextAutomationRunAt(automation.schedule, automation.scheduleTime, automation.scheduleWeekday) }
                        : automation),
                }));
            } catch (error) {
                runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
            } finally {
                schedulingRef.current = false;
            }
        }, 30_000);
        return () => window.clearInterval(timer);
    }, [runtime.setSnapshot, runtime.snapshot.automations, runtime.snapshot.tasks, runtime.startTask, runtime.setRuntimeError]);

    useEffect(() => {
        if (draftWorkspace) void runtime.prepareEngine(draftWorkspace).catch(() => undefined);
    }, [draftWorkspace, runtime.prepareEngine]);

    useEffect(() => {
        if (draftWorkspaceFollowsDefaultRef.current) {
            setDraftWorkspace(runtime.snapshot.settings.workspace);
        }
    }, [runtime.snapshot.settings.workspace]);

    const query = searchValue.trim().toLowerCase();
    const filteredAgents = runtime.snapshot.agents.filter((agent) => !query || `${agent.name} ${agent.description}`.toLowerCase().includes(query));

    const openNewTask = (workspace?: string) => {
        const nextWorkspace = workspace || runtime.snapshot.settings.workspace;
        draftWorkspaceFollowsDefaultRef.current = !workspace;
        runtime.setActiveTaskId(null);
        setSection('new-task');
        setDraft('');
        setDraftWorkspace(nextWorkspace);
        setAttachments([]);
        setAttachmentGrantIds([]);
    };

    const openSettings = (tab: SettingsTab = 'general') => {
        setSettingsTab(tab);
        runtime.setActiveTaskId(null);
        setSection('settings');
    };

    const openSection = (nextSection: ArkDesktopSection) => {
        if (nextSection === 'new-task') {
            openNewTask();
            return;
        }
        runtime.setActiveTaskId(null);
        setSection(nextSection);
    };

    const runTask = async () => {
        const execution = runtime.snapshot.settings.execution;
        if (execution.permissionMode === 'bypassPermissions') {
            if (!window.confirm('当前任务已启用完全访问权限，将无需逐次授权执行本地操作。确认发起任务？')) return;
        }
        setActionPending(true);
        try {
            await runtime.startTask({
                prompt: draft,
                workspace: draftWorkspace,
                agentId: selectedAgentId || undefined,
                skillIds: selectedSkillIds,
                attachmentPaths: attachments,
                attachmentGrantIds,
            });
            setDraft('');
            setAttachments([]);
            setAttachmentGrantIds([]);
            setSelectedAgentId('');
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        } finally {
            setActionPending(false);
        }
    };

    const chooseAttachments = async () => {
        try {
            const selected = await runtime.selectAttachments();
            setAttachments((current) => Array.from(new Set([...current, ...selected.paths])));
            if (selected.grantId) {
                const grantId = selected.grantId;
                setAttachmentGrantIds((current) => Array.from(new Set([...current, grantId])));
            }
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        }
    };

    const chooseWorkspace = async () => {
        try {
            const selected = await runtime.pickWorkspace();
            if (selected) {
                draftWorkspaceFollowsDefaultRef.current = false;
                setDraftWorkspace(selected);
            }
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        }
    };

    const chooseDefaultWorkspace = async () => {
        try {
            await runtime.selectWorkspace();
        } catch (error) {
            runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        }
    };

    const addWorkspace = async () => {
        const selected = await runtime.pickWorkspace();
        if (selected) {
            runtime.addWorkspace(selected);
            openNewTask(selected);
        }
    };

    const archiveSidebarTask = (taskId: string) => {
        const wasActive = runtime.activeTaskId === taskId;
        runtime.archiveTask(taskId);
        if (wasActive) openNewTask();
    };

    const deleteSidebarTask = async (taskId: string) => {
        const wasActive = runtime.activeTaskId === taskId;
        await runtime.deleteTask(taskId);
        if (wasActive) openNewTask();
    };

    const renderRuntimeBadge = () => {
        if (!runtime.runtimeStatus) return <span className="text-slate-400">检测中…</span>;
        if (!runtime.runtimeStatus.available) return <span className="text-red-600">内置智能引擎未就绪</span>;
        const provider = runtime.snapshot.settings.modelProviders.find((item) => item.id === runtime.snapshot.settings.grokModel);
        if (!provider?.enabled || !provider.hasApiKey) return <span className="text-amber-600">请配置模型连接</span>;
        return <span className="text-emerald-600">内置智能引擎已就绪</span>;
    };
    const headerTitle = runtime.activeTask?.title || (section === 'settings' ? '设置' : sectionItems.find((item) => item.id === section)?.label || '新建任务');
    const headerStatus = runtime.activeTask ? taskStatus[runtime.activeTask.status] : undefined;
    const headerMeta = runtime.activeTask
        ? [
            runtime.activeTask.workspace.split(/[\\/]/).filter(Boolean).pop(),
            runtime.snapshot.settings.modelProviders.find((provider) => provider.id === runtime.activeTask?.model)?.name || runtime.activeTask.model,
            runtime.activeTask.engine === 'headless' ? '后台模式' : '实时会话',
        ].filter(Boolean).join(' · ')
        : undefined;
    const workspaceOptions = useMemo(() => {
        const latestByWorkspace = new Map<string, number>();
        runtime.snapshot.settings.workspacePaths.forEach((workspace) => latestByWorkspace.set(workspace, 0));
        runtime.snapshot.tasks.forEach((task) => {
            if (!latestByWorkspace.has(task.workspace)) return;
            latestByWorkspace.set(task.workspace, Math.max(latestByWorkspace.get(task.workspace) || 0, task.updatedAt));
        });
        [draftWorkspace].filter(Boolean).forEach((workspace) => {
            if (!latestByWorkspace.has(workspace)) latestByWorkspace.set(workspace, 0);
        });
        return Array.from(latestByWorkspace)
            .sort((left, right) => right[1] - left[1])
            .map(([workspace]) => workspace);
    }, [draftWorkspace, runtime.snapshot.settings.workspacePaths, runtime.snapshot.tasks]);

    useEffect(() => { document.title = headerTitle; }, [headerTitle]);

    return (
        <div className="relative flex h-screen min-h-[680px] overflow-hidden bg-white pt-[52px] text-[#292a2e]">
            <header className="absolute inset-x-0 top-0 z-10 flex h-[52px] items-center border-b border-[#e9e9ea] bg-white/95">
                <div data-tauri-drag-region className={`${isSidebarCollapsed ? 'w-[126px]' : 'w-[270px]'} h-full shrink-0 transition-[width] duration-200`} />
                <ArkDesktopSidebarToggle collapsed={isSidebarCollapsed} onToggle={() => setIsSidebarCollapsed((current) => !current)} />
                <ArkDesktopTitleContent
                    title={headerTitle}
                    meta={headerMeta}
                    settingsActive={section === 'settings' && !runtime.activeTask}
                    onOpenSettings={openSettings}
                    icon={runtime.activeTask ? <Cpu size={16} strokeWidth={1.8} /> : section === 'settings' ? <Settings size={16} strokeWidth={1.8} /> : <CheckSquare size={16} strokeWidth={1.8} />}
                    status={headerStatus ? <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-medium ${headerStatus.className}`}>{headerStatus.label}</span> : undefined}
                    planControl={runtime.activeTask?.plan?.length
                        ? <TaskPlanPanel plan={runtime.activeTask.plan} taskStatus={runtime.activeTask.status} />
                        : undefined}
                />
            </header>
            <aside className={`${isSidebarCollapsed ? 'hidden' : 'hidden w-[270px] shrink-0 flex-col border-r border-[#e5e5e7] bg-[#f8f8f9] px-3 py-4 lg:flex'}`}>
                <div className="mb-3 flex h-10 items-center gap-2 px-2">
                    <span className="text-[18px] font-semibold tracking-[-0.03em] text-[#303136]">URGS</span>
                    <span className="truncate text-[11px] font-medium text-slate-400">智能任务中心</span>
                </div>
                <label className="mb-3 flex h-9 w-full cursor-text items-center gap-2 rounded-lg border border-transparent bg-[#eeeeef] px-3 text-slate-400 transition focus-within:border-slate-200 focus-within:bg-white focus-within:ring-2 focus-within:ring-slate-100">
                    <Search size={16} className="shrink-0" />
                    <span className="sr-only">搜索会话与智能体</span>
                    <input value={searchValue} onChange={(event) => setSearchValue(event.target.value)} placeholder="搜索会话与智能体" className="min-w-0 flex-1 bg-transparent text-[13px] text-slate-700 outline-none placeholder:text-slate-400" />
                    {searchValue && <button type="button" onClick={() => setSearchValue('')} className="rounded p-0.5 text-slate-400 hover:bg-slate-200 hover:text-slate-600" title="清除搜索" aria-label="清除搜索"><X size={13} /></button>}
                </label>
                <nav className="space-y-0.5">
                    {sectionItems.map((item) => {
                        const Icon = item.icon;
                        return <button key={item.id} type="button" onClick={() => openSection(item.id)} className={`flex h-10 w-full items-center gap-3 rounded-lg px-3 text-left text-[14px] font-medium transition ${section === item.id && !runtime.activeTask ? 'bg-[#e9e9eb] text-[#25262b]' : 'text-[#55565c] hover:bg-[#eeeeef] hover:text-[#303136]'}`}><Icon size={18} strokeWidth={1.8} />{item.label}</button>;
                    })}
                </nav>
                <WorkspaceSessionSidebar
                    tasks={runtime.snapshot.tasks}
                    workspaces={runtime.snapshot.settings.workspacePaths}
                    defaultWorkspace={runtime.snapshot.settings.workspace}
                    searchValue={searchValue}
                    activeTaskId={runtime.activeTaskId}
                    onOpenTask={(taskId) => { setLatestMessageTaskId(taskId); setSection('new-task'); runtime.setActiveTaskId(taskId); }}
                    onAddWorkspace={addWorkspace}
                    onCreateInWorkspace={openNewTask}
                    onSetDefaultWorkspace={runtime.setDefaultWorkspace}
                    onRemoveWorkspace={runtime.removeWorkspace}
                    onRevealWorkspace={runtime.revealWorkspace}
                    onRenameTask={runtime.renameTask}
                    onToggleTaskPin={runtime.toggleTaskPin}
                    onArchiveTask={archiveSidebarTask}
                    onRestoreTask={runtime.restoreTask}
                    onDeleteTask={deleteSidebarTask}
                    onError={runtime.setRuntimeError}
                />
                <div className="mt-3 flex items-center justify-between border-t border-[#e5e5e7] px-2 pt-3 text-xs" title={runtime.runtimeStatus?.version || runtime.runtimeStatus?.message || '正在检测内置智能引擎'}><span className="flex items-center gap-2"><span className="flex h-7 w-7 items-center justify-center rounded-full bg-[#313238] text-[10px] font-medium text-white">U</span><span className="font-medium text-[#494a4f]">本地任务</span></span><span>{renderRuntimeBadge()}</span></div>
            </aside>
            <section className="relative flex min-w-0 flex-1 flex-col overflow-hidden">
                {runtime.runtimeError && <div className="mx-5 mt-4 flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"><AlertCircle size={17} className="mt-0.5 shrink-0" /><span className="flex-1">{runtime.runtimeError}</span><button type="button" onClick={() => runtime.setRuntimeError('')}><X size={16} /></button></div>}

                <main ref={conversationScrollRef} className="custom-scrollbar min-h-0 flex-1 overflow-y-auto">
                    {runtime.activeTask || section === 'new-task' ? <TaskView
                        task={runtime.activeTask}
                        runtime={runtime}
                        scrollContainerRef={conversationScrollRef}
                        followUp={runtime.activeTask ? followUpDrafts[runtime.activeTask.id] || '' : draft}
                        setFollowUp={runtime.activeTask ? (value) => setFollowUpDrafts((current) => ({ ...current, [runtime.activeTask!.id]: value })) : setDraft}
                        locateLatestMessage={latestMessageTaskId === runtime.activeTask?.id}
                        onLatestMessageLocated={clearLatestMessageLocation}
                        newTask={!runtime.activeTask ? {
                            selectedSkillIds,
                            setSelectedSkillIds,
                            workspace: draftWorkspace,
                            attachments,
                            setAttachments,
                            runTask,
                            chooseAttachments,
                            chooseWorkspace,
                            workspaceOptions,
                            selectWorkspace: (workspace) => {
                                draftWorkspaceFollowsDefaultRef.current = false;
                                setDraftWorkspace(workspace);
                            },
                            actionPending,
                            managePlugins: () => openSettings('plugins'),
                        } : undefined}
                    /> : section === 'agents' ? (
                        <AgentsView agents={filteredAgents} skills={runtime.snapshot.skills} runtime={runtime} onEdit={(id) => setEditor({ type: 'agent', id })} onCreate={() => setEditor({ type: 'agent' })} onUse={(id) => { setSelectedAgentId(id); openNewTask(); }} />
                    ) : section === 'skills' ? (
                        <SkillsView skills={runtime.snapshot.skills} runtime={runtime} onEdit={(id) => setEditor({ type: 'skill', id })} onCreate={() => setEditor({ type: 'skill' })} />
                    ) : section === 'automations' ? (
                        <AutomationCenter runtime={runtime} onEdit={(id) => setEditor({ type: 'automation', id })} />
                    ) : <SettingsView runtime={runtime} chooseWorkspace={chooseDefaultWorkspace} initialTab={settingsTab} />}
                </main>
            </section>

            {editor?.type === 'agent' && <AgentEditor id={editor.id} runtime={runtime} onClose={() => setEditor(null)} />}
            {editor?.type === 'skill' && <SkillEditor id={editor.id} runtime={runtime} onClose={() => setEditor(null)} />}
            {editor?.type === 'automation' && <AutomationEditor id={editor.id} runtime={runtime} onClose={() => setEditor(null)} />}
            {runtime.permission && <Modal title={`允许“${runtime.permission.taskTitle}”执行本地操作？`} onClose={() => void runtime.answerPermission()}><p className="mb-5 text-sm leading-6 text-slate-600">{runtime.permission.title}</p><div className="flex flex-wrap justify-end gap-2"><button type="button" onClick={() => void runtime.answerPermission()} className="rounded-lg border border-slate-200 px-4 py-2 text-sm text-slate-600">拒绝</button>{runtime.permission.options.map((option) => <button key={option.optionId} type="button" onClick={() => void runtime.answerPermission(option.optionId)} className="rounded-lg bg-slate-900 px-4 py-2 text-sm text-white">{option.name}</button>)}</div></Modal>}
            {runtime.userQuestion && <UserQuestionDialog request={runtime.userQuestion} onAnswer={runtime.answerUserQuestion} />}
            {runtime.planApproval && <PlanApprovalDialog request={runtime.planApproval} onAnswer={runtime.answerPlanApproval} />}
        </div>
    );
};

interface NewTaskConfig {
    selectedSkillIds: string[];
    setSelectedSkillIds: React.Dispatch<React.SetStateAction<string[]>>;
    workspace: string;
    attachments: string[];
    setAttachments: React.Dispatch<React.SetStateAction<string[]>>;
    runTask: () => Promise<void>;
    chooseAttachments: () => Promise<void>;
    chooseWorkspace: () => Promise<void>;
    workspaceOptions: string[];
    selectWorkspace: (workspace: string) => void;
    actionPending: boolean;
    managePlugins: () => void;
}

const ToolCopyButton: React.FC<{ value: string; label?: string }> = ({ value, label = '复制' }) => {
    const [copied, setCopied] = useState(false);
    const copy = async () => {
        if (!await copyToClipboard(value)) return;
        setCopied(true);
        window.setTimeout(() => setCopied(false), 1600);
    };
    return <button type="button" onClick={() => void copy()} className="inline-flex items-center gap-1 rounded-md px-1.5 py-1 text-[11px] font-medium text-slate-400 transition hover:bg-white hover:text-slate-700" title={label}>{copied ? <Check size={12} className="text-emerald-600" /> : <Copy size={12} />}{copied ? '已复制' : label}</button>;
};

const MarkdownCodeBlock: React.FC<{ language: string; value: string }> = ({ language, value }) => {
    const displayLanguage = language === 'text' ? 'TEXT' : language.toUpperCase();
    return <div className="my-4 overflow-hidden rounded-xl border border-slate-800 bg-[#17191f] shadow-sm">
        <div className="flex h-10 items-center justify-between border-b border-white/10 px-3.5">
            <span className="font-mono text-[10px] font-semibold tracking-[0.12em] text-slate-400">{displayLanguage}</span>
            <ToolCopyButton value={value} label="复制代码" />
        </div>
        <div className="overflow-x-auto">
            <SyntaxHighlighter language={language} style={oneDark} PreTag="div" customStyle={{ margin: 0, minWidth: '100%', padding: '14px 16px 16px', background: '#17191f', fontSize: '13px', lineHeight: '1.65' }} codeTagProps={{ style: { fontFamily: 'var(--font-mono)' } }} wrapLongLines={false}>{value}</SyntaxHighlighter>
        </div>
    </div>;
};

const MarkdownContent: React.FC<{ content: string }> = ({ content }) => <div className="min-w-0 text-[15px] leading-7 text-slate-700">
    <ReactMarkdown
        remarkPlugins={[remarkGfm, remarkBreaks]}
        components={{
            pre: ({ children }) => <>{children}</>,
            code({ className, children, ...props }: any) {
                const match = /language-([\w-]+)/.exec(className || '');
                const value = String(children).replace(/\n$/, '');
                if (match || value.includes('\n')) return <MarkdownCodeBlock language={match?.[1] || 'text'} value={value} />;
                return <code className="rounded-md bg-slate-100 px-1.5 py-0.5 font-mono text-[0.88em] font-medium text-slate-800" {...props}>{children}</code>;
            },
            h1: ({ children }) => <h1 className="mb-3 mt-7 text-[22px] font-semibold leading-8 tracking-[-0.02em] text-slate-950 first:mt-0">{children}</h1>,
            h2: ({ children }) => <h2 className="mb-2.5 mt-6 text-[19px] font-semibold leading-7 tracking-[-0.015em] text-slate-950 first:mt-0">{children}</h2>,
            h3: ({ children }) => <h3 className="mb-2 mt-5 text-[16px] font-semibold leading-7 text-slate-900 first:mt-0">{children}</h3>,
            p: ({ children }) => <p className="my-3 first:mt-0 last:mb-0">{children}</p>,
            ul: ({ children, className }) => <ul className={`my-3 space-y-1 pl-6 marker:text-slate-400 ${className?.includes('contains-task-list') ? 'list-none pl-1' : 'list-disc'}`}>{children}</ul>,
            ol: ({ children }) => <ol className="my-3 list-decimal space-y-1 pl-6 marker:font-medium marker:text-slate-500">{children}</ol>,
            li: ({ children, className }) => <li className={`pl-1 ${className?.includes('task-list-item') ? 'flex items-start gap-2 pl-0 [&>input]:mt-[7px]' : ''}`}>{children}</li>,
            blockquote: ({ children }) => <blockquote className="my-4 rounded-r-lg border-l-[3px] border-slate-300 bg-slate-50 py-1 pl-4 pr-3 text-slate-600 [&>p]:my-2">{children}</blockquote>,
            table: ({ children }) => <div className="my-5 max-w-full overflow-x-auto rounded-xl border border-slate-200"><table className="min-w-full border-collapse text-left text-[13px] leading-6">{children}</table></div>,
            thead: ({ children }) => <thead className="bg-slate-50 text-slate-700">{children}</thead>,
            th: ({ children }) => <th className="whitespace-nowrap border-b border-slate-200 px-3.5 py-2.5 font-semibold">{children}</th>,
            td: ({ children }) => <td className="border-b border-slate-100 px-3.5 py-2.5 align-top text-slate-600 last:border-b-0">{children}</td>,
            a: ({ children, href }) => <a href={href} target="_blank" rel="noreferrer" className="font-medium text-blue-600 underline decoration-blue-200 underline-offset-2 transition hover:text-blue-700 hover:decoration-blue-500">{children}</a>,
            hr: () => <hr className="my-6 border-0 border-t border-slate-200" />,
            strong: ({ children }) => <strong className="font-semibold text-slate-900">{children}</strong>,
        }}
    >{content}</ReactMarkdown>
</div>;

const PermissionModePicker: React.FC<{
    value: PermissionMode;
    disabled?: boolean;
    onChange: (value: PermissionMode) => void;
}> = ({ value, disabled = false, onChange }) => {
    const [open, setOpen] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);
    const selected = permissionModeOptions.find((option) => option.value === value) || permissionModeOptions[0];
    const SelectedIcon = selected.icon;

    useEffect(() => {
        if (!open) return undefined;
        const close = (event: MouseEvent) => {
            if (!menuRef.current?.contains(event.target as Node)) setOpen(false);
        };
        window.addEventListener('mousedown', close);
        return () => window.removeEventListener('mousedown', close);
    }, [open]);

    const selectMode = (option: typeof permissionModeOptions[number]) => {
        if (option.value === value) {
            setOpen(false);
            return;
        }
            if (option.dangerous && !window.confirm('完全访问权限将允许智能体不经逐次批准执行本地操作并访问网络。确认启用？')) return;
        onChange(option.value);
        setOpen(false);
    };

    return <div ref={menuRef} className="relative">
        <button type="button" disabled={disabled} onClick={() => setOpen((current) => !current)} title={disabled ? '任务运行中不可修改权限' : '设置 Grok 工具权限'} className={`flex max-w-48 items-center gap-1.5 rounded-lg px-2.5 py-2 text-xs font-medium transition disabled:cursor-default disabled:opacity-50 ${selected.dangerous ? 'bg-orange-50 text-orange-600 hover:bg-orange-100' : 'text-slate-500 hover:bg-slate-100 hover:text-slate-700'}`}>
            <SelectedIcon size={15} className="shrink-0" />
            <span className="truncate">{selected.label}</span>
            <ChevronDown size={13} className={`shrink-0 text-slate-400 transition-transform ${open ? 'rotate-180' : ''}`} />
        </button>
        {open && <div className="absolute bottom-[calc(100%+8px)] left-0 z-40 w-[min(420px,calc(100vw-40px))] overflow-hidden rounded-2xl border border-slate-200 bg-white p-2 shadow-[0_20px_55px_rgba(15,23,42,0.18)]">
            <div className="flex items-center justify-between px-2.5 pb-2 pt-1"><span className="text-xs font-semibold text-slate-500">智能体工具权限</span><span className="text-[11px] text-slate-400">应用于下一次发送</span></div>
            {permissionModeOptions.map((option) => { const Icon = option.icon; const active = option.value === value; return <button key={option.value} type="button" onClick={() => selectMode(option)} className={`flex w-full items-center gap-3 rounded-xl px-2.5 py-2.5 text-left transition ${active ? option.dangerous ? 'bg-orange-50' : 'bg-slate-100' : 'hover:bg-slate-50'}`}><span className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${option.dangerous ? 'text-orange-600' : 'text-slate-500'}`}><Icon size={18} /></span><span className="min-w-0 flex-1"><span className={`block text-sm font-medium ${option.dangerous ? 'text-orange-600' : 'text-slate-800'}`}>{option.label}</span><span className={`mt-0.5 block text-xs leading-5 ${option.dangerous ? 'text-orange-500' : 'text-slate-400'}`}>{option.description}</span></span>{active && <Check size={17} className={option.dangerous ? 'text-orange-600' : 'text-slate-700'} />}</button>; })}
        </div>}
    </div>;
};

const ModelPickerControl: React.FC<{
    runtime: ReturnType<typeof useArkDesktopRuntime>;
    selectedModel: string;
    disabled?: boolean;
    disabledReason?: string;
    onSelect: (model: string) => Promise<void>;
    onError?: (error: unknown) => void;
}> = ({ runtime, selectedModel, disabled = false, disabledReason = '当前不可切换模型', onSelect, onError }) => {
    const [switching, setSwitching] = useState(false);
    const [open, setOpen] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);
    const modelOptions = runtime.snapshot.settings.modelOptions;
    const providers = new Map(runtime.snapshot.settings.modelProviders.map((provider) => [provider.id, provider]));
    const selectedProvider = providers.get(selectedModel);
    const hasModelOptions = modelOptions.length > 0;

    useEffect(() => {
        if (!open) return undefined;
        const close = (event: MouseEvent) => {
            if (!menuRef.current?.contains(event.target as Node)) setOpen(false);
        };
        window.addEventListener('mousedown', close);
        return () => window.removeEventListener('mousedown', close);
    }, [open]);

    const switchModel = async (model: string) => {
        if (disabled || switching || model === selectedModel) return;
        setSwitching(true);
        try {
            await onSelect(model);
            setOpen(false);
        } catch (error) {
            if (onError) onError(error);
            else runtime.setRuntimeError(error instanceof Error ? error.message : String(error));
        } finally {
            setSwitching(false);
        }
    };

    return <div ref={menuRef} className="relative">
        <button type="button" disabled={disabled || switching || !hasModelOptions} onClick={() => setOpen((current) => !current)} title={!hasModelOptions ? '请先在设置中配置模型' : disabled ? disabledReason : '选择模型'} className="flex max-w-56 items-center gap-1.5 rounded-lg px-2.5 py-2 text-xs font-medium text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 disabled:cursor-default disabled:opacity-50">
            {switching ? <LoaderCircle size={15} className="shrink-0 animate-spin" /> : <Cpu size={15} className="shrink-0" />}
            <span className="truncate">{selectedProvider?.name || selectedModel || '默认模型'}</span>
            <ChevronDown size={13} className={`shrink-0 text-slate-400 transition-transform ${open ? 'rotate-180' : ''}`} />
        </button>
        {open && hasModelOptions && <div className="absolute bottom-[calc(100%+8px)] left-0 z-40 w-80 overflow-hidden rounded-2xl border border-slate-200 bg-white p-2 shadow-[0_20px_55px_rgba(15,23,42,0.18)]">
            <div className="px-2.5 pb-2 pt-1 text-xs font-semibold text-slate-500">选择推理模型</div>
            {modelOptions.map((model) => { const provider = providers.get(model); const active = model === selectedModel; return <button key={model} type="button" disabled={switching || active} onClick={() => void switchModel(model)} className={`flex w-full items-center gap-3 rounded-xl px-2.5 py-2.5 text-left transition ${active ? 'bg-slate-100' : 'hover:bg-slate-50 disabled:opacity-100'}`}><span className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${active ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-500'}`}>{active ? <Check size={15} /> : <Cpu size={15} />}</span><span className="min-w-0 flex-1"><span className="block truncate text-sm font-medium text-slate-700">{provider?.name || model}</span><span className="mt-0.5 block truncate text-xs text-slate-400">{provider?.model || model}</span></span></button>; })}
        </div>}
    </div>;
};

const DefaultModelPicker: React.FC<{ runtime: ReturnType<typeof useArkDesktopRuntime> }> = ({ runtime }) => <ModelPickerControl runtime={runtime} selectedModel={runtime.snapshot.settings.grokModel} onSelect={runtime.selectModel} />;

const TaskModelPicker: React.FC<{ task: ArkDesktopTask; runtime: ReturnType<typeof useArkDesktopRuntime> }> = ({ task, runtime }) => {
    const disabled = task.status === 'running' || task.status === 'waiting_authorization' || !task.sessionId || task.engine === 'headless';
    return <ModelPickerControl
        runtime={runtime}
        selectedModel={task.model || runtime.snapshot.settings.grokModel}
        disabled={disabled}
        disabledReason={task.engine === 'headless' ? '后台模式会话不可切换模型' : task.status === 'running' ? '任务运行中不可切换模型' : '会话恢复后可切换模型'}
        onSelect={(model) => runtime.switchTaskModel(task.id, model)}
        onError={() => undefined}
    />;
};

const TaskMessage: React.FC<{ message: ArkDesktopTask['messages'][number]; attachments?: string[]; scrollTarget?: React.RefObject<HTMLDivElement> }> = ({ message, attachments = [], scrollTarget }) => {
    if (message.role === 'user') return <div ref={scrollTarget} className="flex scroll-mt-6 justify-end py-2.5"><div className="max-w-[min(86%,680px)] rounded-[20px] rounded-br-md bg-[#f0f1f3] px-4 py-2.5 text-[14px] leading-7 text-slate-800"><span className="whitespace-pre-wrap">{message.content}</span>{attachments.length > 0 && <div className="mt-2 flex flex-wrap justify-end gap-1.5">{attachments.map((path) => <span key={path} title={path} className="flex max-w-56 items-center gap-1 rounded-md bg-white/80 px-2 py-1 text-[11px] leading-4 text-slate-500"><Paperclip size={11} /><span className="truncate">{path.split(/[\\/]/).pop()}</span></span>)}</div>}</div></div>;
    return <div ref={scrollTarget} className="scroll-mt-6 py-2"><MarkdownContent content={message.content} /></div>;
};

const isInternalGoalHarnessPrompt = (content: string) => [
    '<system-reminder>\nA goal has been set:',
    'You are the Goal Plan Writer for the xAI Grok Build harness.',
    'You are the Goal Strategist for the xAI Grok Build harness.',
    'You are the Goal Summarizer for the xAI Grok Build harness.',
    'You are an **adversarial verifier** for the xAI Grok Build harness.',
].some((prefix) => content.trimStart().startsWith(prefix));

const workspaceName = (workspace: string) => workspace.split(/[\\/]/).filter(Boolean).pop() || workspace;

const WorkspacePicker: React.FC<{
    workspace: string;
    workspaces: string[];
    disabled?: boolean;
    onSelect: (workspace: string) => void;
    onBrowse: () => Promise<void>;
}> = ({ workspace, workspaces, disabled = false, onSelect, onBrowse }) => {
    const [open, setOpen] = useState(false);
    const [query, setQuery] = useState('');
    const [activeIndex, setActiveIndex] = useState(0);
    const menuRef = useRef<HTMLDivElement>(null);
    const searchRef = useRef<HTMLInputElement>(null);
    const label = workspaceName(workspace) || '选择工作空间';
    const normalizedQuery = query.trim().toLowerCase();
    const filteredWorkspaces = workspaces.filter((item) => !normalizedQuery
        || `${workspaceName(item)} ${item}`.toLowerCase().includes(normalizedQuery));

    useEffect(() => {
        if (!open) return undefined;
        const close = (event: MouseEvent) => {
            if (!menuRef.current?.contains(event.target as Node)) setOpen(false);
        };
        const closeOnEscape = (event: KeyboardEvent) => {
            if (event.key === 'Escape') setOpen(false);
        };
        const focusFrame = window.requestAnimationFrame(() => searchRef.current?.focus());
        window.addEventListener('mousedown', close);
        window.addEventListener('keydown', closeOnEscape);
        return () => {
            window.cancelAnimationFrame(focusFrame);
            window.removeEventListener('mousedown', close);
            window.removeEventListener('keydown', closeOnEscape);
        };
    }, [open]);

    const select = (nextWorkspace: string) => {
        onSelect(nextWorkspace);
        setOpen(false);
        setQuery('');
    };

    const openMenu = () => {
        setQuery('');
        setActiveIndex(0);
        setOpen((current) => !current);
    };

    const handleSearchKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
        if (event.key === 'ArrowDown') {
            event.preventDefault();
            setActiveIndex((current) => Math.max(0, Math.min(current + 1, filteredWorkspaces.length - 1)));
        } else if (event.key === 'ArrowUp') {
            event.preventDefault();
            setActiveIndex((current) => Math.max(current - 1, 0));
        } else if (event.key === 'Enter' && filteredWorkspaces[activeIndex]) {
            event.preventDefault();
            select(filteredWorkspaces[activeIndex]);
        }
    };

    return <div ref={menuRef} className="relative">
        {open && <div className="absolute bottom-[calc(100%+10px)] left-0 z-50 w-[min(430px,calc(100vw-48px))] overflow-hidden rounded-[18px] border border-[#d8d8db] bg-white p-2 shadow-[0_20px_55px_rgba(15,23,42,0.16)]">
            <label className="flex h-14 items-center gap-3 px-3 text-slate-400">
                <Search size={18} strokeWidth={1.8} className="shrink-0" />
                <span className="sr-only">搜索项目</span>
                <input
                    ref={searchRef}
                    value={query}
                    onChange={(event) => {
                        setQuery(event.target.value);
                        setActiveIndex(0);
                    }}
                    onKeyDown={handleSearchKeyDown}
                    placeholder="搜索项目"
                    className="min-w-0 flex-1 bg-transparent text-[15px] text-[#303136] outline-none placeholder:text-[#8d8e93]"
                />
                {query && <button type="button" onClick={() => setQuery('')} className="rounded-md p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600" title="清除搜索" aria-label="清除搜索"><X size={14} /></button>}
            </label>
            <div role="listbox" aria-label="工作区项目" className="custom-scrollbar max-h-[280px] overflow-y-auto">
                {filteredWorkspaces.length ? filteredWorkspaces.map((item, index) => {
                    const selected = item === workspace;
                    return <button
                        key={item}
                        type="button"
                        role="option"
                        aria-selected={selected}
                        title={item}
                        onMouseEnter={() => setActiveIndex(index)}
                        onClick={() => select(item)}
                        className={`flex h-14 w-full items-center gap-3 rounded-[13px] px-3 text-left text-[#303136] transition ${activeIndex === index ? 'bg-[#f0f0f1]' : 'hover:bg-[#f4f4f5]'}`}
                    >
                        <Folder size={19} strokeWidth={1.8} className="shrink-0 text-[#55565b]" />
                        <span className="min-w-0 flex-1 truncate text-[15px] font-medium">{workspaceName(item)}</span>
                        {selected && <Check size={18} strokeWidth={1.8} className="shrink-0 text-[#55565b]" />}
                    </button>;
                }) : <div className="flex h-20 items-center justify-center text-sm text-slate-400">没有匹配的项目</div>}
            </div>
            <div className="mt-1 border-t border-[#ececee] pt-1">
                <button
                    type="button"
                    onClick={() => {
                        setOpen(false);
                        setQuery('');
                        void onBrowse();
                    }}
                    className="flex h-12 w-full items-center gap-3 rounded-[13px] px-3 text-left text-[14px] font-medium text-[#55565b] transition hover:bg-[#f4f4f5] hover:text-[#303136]"
                >
                    <FolderOpen size={18} strokeWidth={1.8} />
                    选择其他文件夹…
                </button>
            </div>
        </div>}
        <button
            type="button"
            disabled={disabled}
            onClick={openMenu}
            aria-haspopup="listbox"
            aria-expanded={open}
            aria-label={`选择工作区，当前为 ${label}`}
            className={`flex h-8 max-w-48 items-center gap-1.5 rounded-lg px-2 text-[#5b5c61] transition hover:bg-[#f1f1f2] hover:text-[#303136] disabled:cursor-not-allowed disabled:opacity-50 ${open ? 'bg-[#eeeeef] text-[#303136]' : ''}`}
            title={workspace || '选择任务工作空间'}
        >
            <Folder size={15} strokeWidth={1.8} className="shrink-0 text-[#6b6c71]" />
            <span className="min-w-0 flex-1 truncate text-[12px] font-medium">{label}</span>
            <ChevronDown size={11} strokeWidth={1.8} className={`shrink-0 text-[#9a9ba0] transition-transform ${open ? 'rotate-180' : ''}`} />
        </button>
    </div>;
};

const QueuePanel: React.FC<{ task: ArkDesktopTask; runtime: ReturnType<typeof useArkDesktopRuntime> }> = ({ task, runtime }) => {
    const entries = [...(task.queueEntries || [])].sort((left, right) => left.position - right.position);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [draft, setDraft] = useState('');
    const [busyId, setBusyId] = useState<string | null>(null);
    if (entries.length === 0) return null;

    const runAction = async (id: string, action: Parameters<typeof runtime.queueAction>[1], options: Parameters<typeof runtime.queueAction>[2] = {}) => {
        setBusyId(id);
        try {
            await runtime.queueAction(task.id, action, options);
        } catch {
            // queueAction 已将可读错误写回当前任务，避免按钮事件产生未处理的 Promise。
        } finally {
            setBusyId(null);
        }
    };
    const saveEdit = async (entry: typeof entries[number]) => {
        const text = draft.trim();
        if (!text || text === entry.text) {
            setEditingId(null);
            return;
        }
        await runAction(entry.id, 'edit', { id: entry.id, newText: text });
        setEditingId(null);
    };
    const reorder = async (index: number, offset: number) => {
        const target = index + offset;
        if (target < 0 || target >= entries.length) return;
        const orderedIds = entries.map((entry) => entry.id);
        [orderedIds[index], orderedIds[target]] = [orderedIds[target], orderedIds[index]];
        await runAction(entries[index].id, 'reorder', { orderedIds });
    };

    return <section className="mb-3 rounded-2xl border border-slate-200 bg-slate-50/85 px-3 py-2.5" aria-label="排队中的消息">
        <div className="flex items-center justify-between gap-3 px-1 pb-2">
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-700"><span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-slate-900 px-1.5 text-[10px] text-white">{entries.length}</span>排队中</div>
            <button type="button" disabled={busyId === 'clear'} onClick={() => void runAction('clear', 'clear')} className="text-[11px] font-medium text-slate-400 transition hover:text-red-600 disabled:opacity-40">清空队列</button>
        </div>
        <div className="space-y-1.5">
            {entries.map((entry, index) => {
                const busy = busyId === entry.id;
                const editing = editingId === entry.id;
                return <div key={entry.id} className="rounded-xl border border-slate-200/80 bg-white px-3 py-2 shadow-sm">
                    {editing ? <div className="space-y-2">
                        <textarea value={draft} onChange={(event) => setDraft(event.target.value)} rows={2} autoFocus className="w-full resize-none rounded-lg border border-slate-200 px-2.5 py-2 text-sm text-slate-700 outline-none focus:border-slate-400 focus:ring-2 focus:ring-slate-100" />
                        <div className="flex justify-end gap-2"><button type="button" onClick={() => setEditingId(null)} className="rounded-lg px-2.5 py-1 text-xs text-slate-500 hover:bg-slate-100">取消</button><button type="button" disabled={!draft.trim() || busy} onClick={() => void saveEdit(entry)} className="rounded-lg bg-slate-900 px-2.5 py-1 text-xs font-medium text-white disabled:opacity-40">保存</button></div>
                    </div> : <div className="flex items-start gap-2">
                        <span className="mt-0.5 shrink-0 text-xs font-medium text-slate-400">{index + 1}</span>
                        <p className="min-w-0 flex-1 whitespace-pre-wrap break-words text-sm leading-5 text-slate-700">{entry.text}</p>
                        <div className="flex shrink-0 items-center gap-0.5">
                            <button type="button" disabled={busy || index === 0} onClick={() => void reorder(index, -1)} title="上移" aria-label="上移队列项" className="rounded-md p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-700 disabled:opacity-25"><ChevronUp size={14} /></button>
                            <button type="button" disabled={busy || index === entries.length - 1} onClick={() => void reorder(index, 1)} title="下移" aria-label="下移队列项" className="rounded-md p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-700 disabled:opacity-25"><ChevronDown size={14} /></button>
                            <button type="button" disabled={busy} onClick={() => { setEditingId(entry.id); setDraft(entry.text); }} title="编辑" aria-label="编辑队列项" className="rounded-md p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-700 disabled:opacity-25"><Pencil size={14} /></button>
                            <button type="button" disabled={busy} onClick={() => void runAction(entry.id, 'interject', { id: entry.id, expectedVersion: entry.version, newText: entry.text })} title="立即补充到当前执行，不中断任务" aria-label="立即补充到当前执行" className="rounded-md p-1 text-slate-400 hover:bg-blue-50 hover:text-blue-600 disabled:opacity-25">{busy ? <LoaderCircle size={14} className="animate-spin" /> : <Send size={14} />}</button>
                            <button type="button" disabled={busy} onClick={() => void runAction(entry.id, 'remove', { id: entry.id, expectedVersion: entry.version })} title="移除" aria-label="移除队列项" className="rounded-md p-1 text-slate-400 hover:bg-red-50 hover:text-red-600 disabled:opacity-25"><Trash2 size={14} /></button>
                        </div>
                    </div>}
                </div>;
            })}
        </div>
    </section>;
};

const TaskComposer: React.FC<{ task?: ArkDesktopTask; runtime: ReturnType<typeof useArkDesktopRuntime>; value: string; onChange: (value: string) => void; onSubmit: () => Promise<void>; onCancel?: () => Promise<void>; sending: boolean; newTask?: NewTaskConfig }> = ({ task, runtime, value, onChange, onSubmit, onCancel, sending, newTask }) => {
    const isNewTask = !task;
    const isRunning = task?.status === 'running';
    const isWaitingAuthorization = task?.status === 'waiting_authorization';
    const canQueuePrompt = Boolean(isRunning && task?.engine !== 'headless' && task.sessionId);
    const execution = runtime.snapshot.settings.execution;
    const workspace = isNewTask ? newTask?.workspace || '' : task?.workspace || runtime.snapshot.settings.workspace;
    const canSubmit = isNewTask
        ? Boolean(workspace) && !sending && (!!value.trim() || (execution.engine === 'headless' && execution.promptMode !== 'text'))
        : !isWaitingAuthorization && !sending && !!value.trim();
    return <div className="sticky bottom-0 mt-7 bg-gradient-to-t from-white via-white to-white/85 pt-5">
        {isNewTask && newTask?.attachments.length ? <div className="mb-2 flex flex-wrap gap-2">{newTask.attachments.map((path) => <span key={path} title={path} className="flex max-w-72 items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-2.5 py-1.5 text-xs text-slate-600"><Paperclip size={13} /><span className="truncate">{path.split(/[\\/]/).pop()}</span><button type="button" onClick={() => newTask.setAttachments((current) => current.filter((item) => item !== path))} aria-label="移除附件"><X size={13} /></button></span>)}</div> : null}
        <div className="rounded-[22px] border border-slate-200 bg-white p-2 shadow-[0_10px_28px_rgba(15,23,42,0.09)] transition focus-within:border-slate-300 focus-within:shadow-[0_12px_34px_rgba(15,23,42,0.12)]">
            <ConversationPromptInput value={value} commands={task?.availableCommands?.length ? task.availableCommands : runtime.availableCommands} onChange={onChange} onSubmit={onSubmit} disabled={(isRunning && !canQueuePrompt) || isWaitingAuthorization || sending} slashDisabled={task?.engine === 'headless' || (isNewTask && execution.engine === 'headless')} placeholder={isNewTask ? '描述希望智能体在本地完成的任务，输入 / 查看会话命令…' : isWaitingAuthorization ? '请先解锁本地模型密钥…' : canQueuePrompt ? '继续补充消息，将按发送顺序执行…' : task?.sessionId ? '继续补充任务要求，输入 / 查看会话命令…' : '输入指令，将尝试恢复原历史会话…'} rows={2} />
            <div className={`flex flex-wrap items-center justify-between gap-2 px-1 ${isNewTask ? 'pt-1' : 'pb-1'}`}>
                <div className="relative flex min-w-0 flex-wrap items-center gap-1">
                    {isNewTask && newTask ? <>
                        <SessionCommandBar
                            commands={runtime.availableCommands}
                            disabled={sending}
                            onSelect={onChange}
                            onChooseAttachments={newTask.chooseAttachments}
                            skills={runtime.snapshot.skills}
                            selectedSkillIds={newTask.selectedSkillIds}
                            onToggleSkill={(skillId) => newTask.setSelectedSkillIds((current) => current.includes(skillId)
                                ? current.filter((id) => id !== skillId)
                                : [...current, skillId])}
                            plugins={runtime.discoveredPlugins}
                            sessionPluginDirs={execution.pluginDirs.split('\n').map((item) => item.trim()).filter(Boolean)}
                            capabilitiesLoading={runtime.capabilitiesLoading}
                            capabilitiesError={runtime.capabilitiesError}
                            onRefreshCapabilities={async () => { await runtime.prepareEngine(workspace); }}
                            onManagePlugins={newTask.managePlugins}
                        />
                        <WorkspacePicker
                            workspace={workspace}
                            workspaces={newTask.workspaceOptions}
                            disabled={sending}
                            onSelect={newTask.selectWorkspace}
                            onBrowse={newTask.chooseWorkspace}
                        />
                        <PermissionModePicker value={execution.permissionMode} onChange={(permissionMode) => runtime.setSnapshot((current) => ({ ...current, settings: { ...current.settings, execution: { ...current.settings.execution, permissionMode, alwaysApprove: false } } }))} />
                        <DefaultModelPicker runtime={runtime} />
                    </> : task ? <>
                        {task.engine !== 'headless' && <SessionCommandBar commands={task.availableCommands || []} disabled={isRunning || isWaitingAuthorization || sending} onSelect={onChange} />}
                        <PermissionModePicker value={task.permissionMode || execution.permissionMode} disabled={isRunning || isWaitingAuthorization} onChange={(permissionMode) => runtime.setTaskPermissionMode(task.id, permissionMode)} />
                        <TaskModelPicker task={task} runtime={runtime} />
                    </> : null}
                </div>
                <div className="flex items-center gap-2"><span className="hidden text-[11px] text-slate-400 sm:inline">{canQueuePrompt ? '执行中，可继续追加消息' : isRunning ? '任务正在执行' : isWaitingAuthorization ? '等待本地密钥解锁' : isNewTask ? 'Enter 发送' : task?.sessionId ? 'Enter 发送' : '发送时恢复历史会话'}</span>{isRunning ? <><button type="button" onClick={() => void onCancel?.()} className="flex h-8 items-center gap-1.5 rounded-lg px-2.5 text-xs font-medium text-red-600 hover:bg-red-50"><CircleStop size={15} />停止任务</button>{canQueuePrompt ? <button type="button" disabled={!canSubmit} onClick={() => void onSubmit()} aria-label="追加消息" title="追加消息" className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-900 text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-35">{sending ? <LoaderCircle size={15} className="animate-spin" /> : <Send size={15} />}</button> : null}</> : <button type="button" disabled={!canSubmit} onClick={() => void onSubmit()} className="flex h-8 w-8 items-center justify-center rounded-full bg-slate-900 text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-35">{sending ? <LoaderCircle size={15} className="animate-spin" /> : <Send size={15} />}</button>}</div>
            </div>
        </div>
        <p className="mt-2 text-center text-[11px] text-slate-400">智能体可能会出错，请核实重要信息与工具操作。</p>
    </div>;
};

const TaskView: React.FC<{ task?: ArkDesktopTask; runtime: ReturnType<typeof useArkDesktopRuntime>; scrollContainerRef: React.RefObject<HTMLDivElement | null>; followUp: string; setFollowUp: (value: string) => void; locateLatestMessage: boolean; onLatestMessageLocated: () => void; newTask?: NewTaskConfig }> = ({ task, runtime, scrollContainerRef, followUp, setFollowUp, locateLatestMessage, onLatestMessageLocated, newTask }) => {
    const [sending, setSending] = useState(false);
    const [authorizing, setAuthorizing] = useState(false);
    const lastMessageRef = useRef<HTMLDivElement>(null);
    const isNewTask = !task;
    useEffect(() => {
        if (task?.status === 'running') setSending(false);
    }, [task?.status]);
    const submit = async () => {
        if (isNewTask) {
            await newTask?.runTask();
            return;
        }
        const prompt = followUp.trim();
        if (!prompt) return;
        setFollowUp('');
        setSending(true);
        try {
            await runtime.sendFollowUp(task!.id, prompt);
        } catch {
            // 会话级错误由运行时写入当前任务，避免影响其他并发任务。
        } finally {
            setSending(false);
        }
    };
    const authorizeModelKey = async () => {
        if (!task) return;
        setAuthorizing(true);
        try {
            const action = task.modelKeyAuthorization?.action;
            await runtime.authorizeTaskModel(task.id);
            if (action === 'follow_up') setFollowUp('');
        } catch {
            // 授权错误保留在当前任务中，用户可继续重试。
        } finally {
            setAuthorizing(false);
        }
    };
    const hasActiveTool = Boolean(task?.tools.some((tool) => !/已完成|完成|成功|取消|completed|success|cancelled|canceled|done|失败|错误|退出码|failed|error/i.test(tool.status)));
    const waitingForReply = task?.status === 'running' && task.messages[task.messages.length - 1]?.role === 'user' && !hasActiveTool;
    const followOutputRef = useRef(true);
    const pendingFollowFrameRef = useRef<number | null>(null);
    const turns = useMemo(() => {
        const result: Array<{ user?: ArkDesktopTask['messages'][number]; stages: Array<{ message?: ArkDesktopTask['messages'][number]; tools: ArkDesktopTask['tools'] }> }> = [];
        if (!task) return result;
        const visibleMessages = task.messages.filter((message, index, messages) => {
            if (message.role === 'user' && isInternalGoalHarnessPrompt(message.content)) return false;
            const previous = messages[index - 1];
            if (message.role !== 'user' || previous?.role !== 'user' || message.content.trim() !== previous.content.trim()) return true;
            return !(
                message.id.startsWith('interjection-')
                || previous.id.startsWith('interjection-')
                || message.queueEntryId
                || previous.queueEntryId
            );
        });
        visibleMessages.forEach((message) => {
            if (message.role === 'user' || result.length === 0) result.push({ ...(message.role === 'user' ? { user: message } : {}), stages: message.role === 'assistant' ? [{ message, tools: [] }] : [] });
            else result[result.length - 1].stages.push({ message, tools: [] });
        });
        task.tools.forEach((tool) => {
            const toolTime = tool.startedAt || tool.updatedAt;
            let turnIndex = result.length - 1;
            for (let index = 0; index < result.length; index += 1) {
                const nextUserTime = result[index + 1]?.user?.createdAt ?? Number.POSITIVE_INFINITY;
                if (toolTime < nextUserTime) {
                    turnIndex = index;
                    break;
                }
            }
            if (turnIndex < 0) {
                result.push({ stages: [{ tools: [tool] }] });
                return;
            }
            const stages = result[turnIndex].stages;
            let stage = stages[0];
            for (const candidate of stages) {
                if (candidate.message && candidate.message.createdAt <= toolTime) stage = candidate;
                else if (candidate.message && candidate.message.createdAt > toolTime) break;
            }
            if (!stage || (stage.message && stage.message.createdAt > toolTime)) {
                stage = { tools: [] };
                stages.unshift(stage);
            }
            stage.tools.push(tool);
        });
        return result;
    }, [task]);

    const latestMessage = task?.messages[task.messages.length - 1];
    const latestTool = task?.tools[task.tools.length - 1];

    useEffect(() => {
        const container = scrollContainerRef.current;
        if (!container) return undefined;
        const pauseFollowing = () => {
            followOutputRef.current = false;
            if (pendingFollowFrameRef.current !== null) {
                window.cancelAnimationFrame(pendingFollowFrameRef.current);
                pendingFollowFrameRef.current = null;
            }
        };
        const updateFollowState = () => {
            const nearBottom = container.scrollHeight - container.scrollTop - container.clientHeight < 48;
            if (!nearBottom) pauseFollowing();
            else followOutputRef.current = true;
        };
        const handleWheel = (event: WheelEvent) => {
            if (event.deltaY < 0 || container.scrollTop + container.clientHeight < container.scrollHeight - 48) pauseFollowing();
        };
        const handleTouchStart = () => pauseFollowing();
        container.addEventListener('scroll', updateFollowState, { passive: true });
        container.addEventListener('wheel', handleWheel, { passive: true });
        container.addEventListener('touchstart', handleTouchStart, { passive: true });
        updateFollowState();
        return () => {
            container.removeEventListener('scroll', updateFollowState);
            container.removeEventListener('wheel', handleWheel);
            container.removeEventListener('touchstart', handleTouchStart);
        };
    }, [scrollContainerRef, task?.id]);

    useEffect(() => {
        if (!task || (!locateLatestMessage && !followOutputRef.current)) return undefined;
        const container = scrollContainerRef.current;
        const frame = window.requestAnimationFrame(() => {
            pendingFollowFrameRef.current = null;
            if (!locateLatestMessage && !followOutputRef.current) return;
            if (container) {
                container.scrollTop = container.scrollHeight;
                followOutputRef.current = true;
            } else {
                lastMessageRef.current?.scrollIntoView({ block: 'end' });
            }
            if (locateLatestMessage) onLatestMessageLocated();
        });
        pendingFollowFrameRef.current = frame;
        return () => {
            window.cancelAnimationFrame(frame);
            if (pendingFollowFrameRef.current === frame) pendingFollowFrameRef.current = null;
        };
    }, [locateLatestMessage, onLatestMessageLocated, scrollContainerRef, task?.id, latestMessage?.content, latestMessage?.createdAt, latestTool?.id, latestTool?.updatedAt]);

    return <div className="mx-auto flex min-h-full w-full max-w-[960px] flex-col px-4 py-5 font-sans sm:px-5 lg:px-0">
        <div className="flex-1">{isNewTask ? <div className="flex min-h-[300px] flex-col items-center justify-center py-8 text-center"><img src="/ark/ark-agents-robot-cropped.png" alt="URGS 智能任务中心" className="mb-3 h-20 w-20 object-contain mix-blend-multiply" /><h2 className="text-2xl font-semibold tracking-[-0.035em] text-[#303136]">让智能体把想法变成现实</h2><p className="mt-2 text-sm text-slate-500">输入第一条消息，即可在当前会话中开始执行</p><div className="mt-5 flex w-full flex-wrap justify-center gap-2">{taskTags.map((tag) => { const Icon = tag.icon; const active = newTask?.selectedSkillIds.includes(tag.skillId); return <button key={tag.label} type="button" onClick={() => { setFollowUp(tag.prompt); newTask?.setSelectedSkillIds((current) => active ? current.filter((id) => id !== tag.skillId) : [...current, tag.skillId]); }} className={`flex items-center gap-2 rounded-full px-4 py-2.5 text-sm font-medium transition hover:-translate-y-0.5 ${active ? 'bg-slate-900 text-white' : 'bg-[#e9e9eb] text-[#494a4f] hover:bg-[#dedee1]'}`}><Icon size={17} />{tag.label}{active && <Check size={14} />}</button>; })}</div></div> : <>{turns.map((turn, index) => <div key={`${task!.id}-${turn.user?.id || `turn-${index}`}`} className="border-b border-slate-100 py-2 last:border-b-0">{turn.user && <TaskMessage message={turn.user} attachments={index === 0 ? task!.attachmentPaths : undefined} scrollTarget={turn.user.id === task!.messages[task!.messages.length - 1]?.id ? lastMessageRef : undefined} />}{turn.stages.map((stage, stageIndex) => <React.Fragment key={stage.message?.id || `${task!.id}-stage-${index}-${stageIndex}`} >{stage.message && <TaskMessage message={stage.message} scrollTarget={stage.message.id === task!.messages[task!.messages.length - 1]?.id ? lastMessageRef : undefined} />}{stage.tools.length > 0 && <TaskActivityTimeline tools={stage.tools} />}</React.Fragment>)}<TaskChangeSummary taskId={task!.id} workspace={task!.workspace} promptIndex={index} tools={turn.stages.flatMap((stage) => stage.tools)} onRewind={runtime.rewindTaskFiles} /></div>)}{task?.modelKeyAuthorization && <div className="my-5 flex flex-wrap items-center gap-3 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900"><span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-white text-amber-700 shadow-sm"><KeyRound size={16} /></span><div className="min-w-0 flex-1"><div className="font-medium">解锁本地模型密钥</div><div className="mt-0.5 text-xs leading-5 text-amber-700">仅从本机 macOS 钥匙串读取，不连接 xAI。解锁后将继续当前任务。</div></div><div className="flex items-center gap-2"><button type="button" disabled={authorizing} onClick={() => void runtime.cancelTask(task.id)} className="h-8 rounded-lg px-2.5 text-xs font-medium text-amber-800 hover:bg-amber-100 disabled:opacity-60">取消任务</button><button type="button" disabled={authorizing} onClick={() => void authorizeModelKey()} className="flex h-8 items-center gap-1.5 rounded-lg bg-amber-700 px-3 text-xs font-medium text-white hover:bg-amber-800 disabled:opacity-60">{authorizing ? <LoaderCircle size={14} className="animate-spin" /> : <KeyRound size={14} />}解锁密钥</button></div></div>}{task?.error && <div className="my-5 flex gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm leading-6 text-red-700"><AlertCircle size={16} className="mt-0.5 shrink-0" /><span className="flex-1">{task.error}</span><button type="button" onClick={() => runtime.dismissTaskError(task.id)} className="shrink-0 text-red-500 hover:text-red-700" title="关闭提示" aria-label="关闭提示"><X size={16} /></button></div>}{waitingForReply && <div className="flex items-center gap-2 py-4 text-sm text-slate-400"><LoaderCircle size={16} className="animate-spin" />智能体正在分析并调用必要工具…</div>}</>}</div>
        {task && <QueuePanel task={task} runtime={runtime} />}
        <TaskComposer task={task} runtime={runtime} value={followUp} onChange={setFollowUp} onSubmit={submit} onCancel={task ? () => runtime.cancelTask(task.id) : undefined} sending={isNewTask ? newTask?.actionPending || false : sending} newTask={newTask} />
    </div>;
};

const ViewHeader: React.FC<{ title: string; description: string; onCreate: () => void; button: string }> = ({ title, description, onCreate, button }) => <div className="mb-6 flex flex-wrap items-end justify-between gap-3"><div><h1 className="text-2xl font-semibold text-slate-900">{title}</h1><p className="mt-1 text-sm text-slate-500">{description}</p></div><button type="button" onClick={onCreate} className="flex items-center gap-2 rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-medium text-white"><Plus size={16} />{button}</button></div>;

const AgentsView: React.FC<{ agents: ArkDesktopAgent[]; skills: ArkDesktopSkill[]; runtime: ReturnType<typeof useArkDesktopRuntime>; onEdit: (id: string) => void; onCreate: () => void; onUse: (id: string) => void }> = ({ agents, skills, runtime, onEdit, onCreate, onUse }) => <div className="p-6 md:p-8"><ViewHeader title="智能体" description="独立配置本地任务角色，不读取或复用 ARK Chat Agent。" onCreate={onCreate} button="新建智能体" /><div className="grid gap-4 xl:grid-cols-2">{agents.map((agent) => <div key={agent.id} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"><div className="flex items-start justify-between gap-3"><div className="flex min-w-0 gap-3"><span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-slate-600"><Bot size={19} /></span><div><h3 className="font-semibold text-slate-900">{agent.name}</h3><p className="mt-1 text-sm leading-6 text-slate-500">{agent.description}</p></div></div><Toggle checked={agent.enabled} label={`启用 ${agent.name}`} onChange={() => runtime.setSnapshot((current) => ({ ...current, agents: current.agents.map((item) => item.id === agent.id ? { ...item, enabled: !item.enabled } : item) }))} /></div><div className="mt-4 flex flex-wrap gap-1.5">{agent.skillIds.map((id) => <span key={id} className="rounded-lg bg-slate-100 px-2 py-1 text-xs text-slate-500">{skills.find((skill) => skill.id === id)?.name || id}</span>)}</div><div className="mt-4 flex justify-end gap-2"><button type="button" onClick={() => onEdit(agent.id)} className="rounded-lg border border-slate-200 p-2 text-slate-500 hover:bg-slate-50"><Pencil size={16} /></button><button type="button" onClick={() => onUse(agent.id)} className="rounded-lg bg-slate-900 px-3 py-2 text-xs font-medium text-white">使用此智能体</button></div></div>)}</div></div>;

const SkillsView: React.FC<{ skills: ArkDesktopSkill[]; runtime: ReturnType<typeof useArkDesktopRuntime>; onEdit: (id: string) => void; onCreate: () => void }> = ({ skills, runtime, onEdit, onCreate }) => <div className="p-6 md:p-8"><ViewHeader title="技能" description="仅注入本地任务会话，不读取或复用原 ARK 技能。" onCreate={onCreate} button="新建技能" /><div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">{skills.map((skill) => <div key={skill.id} className="rounded-2xl border border-slate-200 p-5"><div className="flex items-start justify-between gap-3"><span className="rounded-lg bg-slate-100 px-2 py-1 text-xs text-slate-500">{categoryLabel[skill.category]}</span><Toggle checked={skill.enabled} label={`启用 ${skill.name}`} onChange={() => runtime.setSnapshot((current) => ({ ...current, skills: current.skills.map((item) => item.id === skill.id ? { ...item, enabled: !item.enabled } : item) }))} /></div><h3 className="mt-4 font-semibold text-slate-900">{skill.name}</h3><p className="mt-2 text-sm leading-6 text-slate-500">{skill.description}</p><button type="button" onClick={() => onEdit(skill.id)} className="mt-4 flex items-center gap-1.5 text-xs font-medium text-slate-600"><Pencil size={14} />编辑任务指令</button></div>)}</div></div>;

const ModelProviderPanel: React.FC<{ providers: ArkDesktopModelProvider[]; currentModel: string; onSave: ReturnType<typeof useArkDesktopRuntime>['saveModelProvider']; onSelect: (model: string) => Promise<void>; onDelete: ReturnType<typeof useArkDesktopRuntime>['removeModelProvider']; onError: (message: string) => void }> = ({ providers, currentModel, onSave, onSelect, onDelete, onError }) => {
    const [name, setName] = useState('');
    const [model, setModel] = useState('');
    const [baseUrl, setBaseUrl] = useState('');
    const [apiKey, setApiKey] = useState('');
    const [apiBackend, setApiBackend] = useState<ArkDesktopModelProvider['apiBackend']>('chat_completions');
    const [authScheme, setAuthScheme] = useState<ArkDesktopModelProvider['authScheme']>('bearer');
    const [contextWindow, setContextWindow] = useState('128000');
    const [editingProviderId, setEditingProviderId] = useState<string>();
    const [saving, setSaving] = useState(false);
    const apply = async (action: () => Promise<void>) => {
        setSaving(true);
        try {
            await action();
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        } finally {
            setSaving(false);
        }
    };
    const add = async () => {
        if (!name.trim() || !model.trim() || !baseUrl.trim()) return;
        await apply(async () => {
            await onSave({
                id: editingProviderId || `model-${Date.now().toString(36)}`,
                name: name.trim(),
                model: model.trim(),
                baseUrl: baseUrl.trim(),
                apiBackend,
                authScheme,
                contextWindow: Number(contextWindow) || 128000,
                enabled: true,
                apiKey: apiKey.trim() || undefined,
            });
            setName('');
            setModel('');
            setBaseUrl('');
            setApiKey('');
            setEditingProviderId(undefined);
        });
    };
    const edit = (provider: ArkDesktopModelProvider) => {
        setEditingProviderId(provider.id);
        setName(provider.name);
        setModel(provider.model);
        setBaseUrl(provider.baseUrl);
        setApiBackend(provider.apiBackend);
        setAuthScheme(provider.authScheme);
        setContextWindow(String(provider.contextWindow));
        setApiKey('');
    };
    const remove = async (provider: ArkDesktopModelProvider) => {
        if (!window.confirm(`确认删除模型连接“${provider.name}”吗？系统凭据库中的密钥也会一并删除。`)) return;
        await apply(() => onDelete(provider.id));
    };
    return <div className="rounded-2xl border border-slate-200 p-5"><div><h3 className="font-semibold text-slate-900">模型连接</h3><p className="mt-1 text-sm leading-6 text-slate-500">添加 OpenAI 兼容、Responses 或 Messages 协议的模型。任务仍由内置智能引擎执行工具和工作区操作，仅推理由这里配置的模型完成。</p></div><div className="mt-5 grid gap-3 md:grid-cols-2"><Field label="连接名称"><input value={name} onChange={(event) => setName(event.target.value)} placeholder="例如：通义千问" className={inputClass} /></Field><Field label="模型标识"><input value={model} onChange={(event) => setModel(event.target.value)} placeholder="例如：qwen-plus" className={inputClass} /></Field><Field label="API Base URL"><input value={baseUrl} onChange={(event) => setBaseUrl(event.target.value)} placeholder="例如：http://127.0.0.1:1234/v1" className={inputClass} /></Field><Field label="API Key"><input type="password" value={apiKey} onChange={(event) => setApiKey(event.target.value)} placeholder={editingProviderId ? '留空则保留已有密钥' : '仅保存到系统凭据库'} className={inputClass} /></Field><Field label="API 协议"><select value={apiBackend} onChange={(event) => setApiBackend(event.target.value as ArkDesktopModelProvider['apiBackend'])} className={inputClass}><option value="chat_completions">Chat Completions（Kimi / Qwen / OpenAI）</option><option value="responses">Responses</option><option value="messages">Messages</option></select></Field><Field label="认证方式"><select value={authScheme} onChange={(event) => setAuthScheme(event.target.value as ArkDesktopModelProvider['authScheme'])} className={inputClass}><option value="bearer">Bearer Token</option><option value="x_api_key">x-api-key</option></select></Field><Field label="上下文窗口"><input type="number" min="4096" max="2000000" value={contextWindow} onChange={(event) => setContextWindow(event.target.value)} className={inputClass} /></Field></div><div className="mt-4 flex justify-end gap-2">{editingProviderId && <button type="button" disabled={saving} onClick={() => { setEditingProviderId(undefined); setName(''); setModel(''); setBaseUrl(''); setApiKey(''); }} className="rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm text-slate-600">取消编辑</button>}<button type="button" disabled={saving || !name.trim() || !model.trim() || !baseUrl.trim()} onClick={() => void add()} className="flex items-center gap-1.5 rounded-xl bg-slate-900 px-3.5 py-2.5 text-sm text-white disabled:opacity-40">{saving ? <LoaderCircle size={15} className="animate-spin" /> : <Plus size={15} />}{editingProviderId ? '保存连接' : '添加并设为默认'}</button></div><div className="mt-5 space-y-2">{providers.length === 0 ? <div className="rounded-xl bg-slate-50 px-3 py-3 text-sm text-slate-400">暂未添加模型连接。添加后即可在新任务和会话中选择。</div> : providers.map((provider) => <div key={provider.id} className={`flex flex-wrap items-center justify-between gap-3 rounded-xl border px-3.5 py-3 ${provider.id === currentModel ? 'border-slate-800 bg-slate-50' : 'border-slate-200'}`}><div className="min-w-0"><div className="flex items-center gap-2"><span className="font-medium text-slate-800">{provider.name}</span>{provider.id === currentModel && <span className="rounded bg-slate-900 px-1.5 py-0.5 text-[10px] text-white">默认</span>}{provider.hasApiKey ? <span className="text-xs text-emerald-600">密钥已保存</span> : <span className="text-xs text-amber-600">未配置密钥</span>}</div><p className="mt-1 truncate text-xs text-slate-500">{provider.model} · {provider.baseUrl}</p></div><div className="flex items-center gap-2"><button type="button" disabled={saving} onClick={() => edit(provider)} className="rounded-lg border border-slate-200 px-2.5 py-1.5 text-xs text-slate-600 disabled:opacity-40">编辑</button><button type="button" disabled={saving || provider.id === currentModel} onClick={() => void apply(() => onSelect(provider.id))} className="rounded-lg border border-slate-200 px-2.5 py-1.5 text-xs text-slate-600 disabled:opacity-40">设为默认</button><button type="button" disabled={saving} onClick={() => void remove(provider)} className="rounded-lg p-1.5 text-slate-400 hover:bg-red-50 hover:text-red-600 disabled:opacity-40" title="删除模型连接"><Trash2 size={16} /></button></div></div>)}</div></div>;
};

const SettingsView: React.FC<{ runtime: ReturnType<typeof useArkDesktopRuntime>; chooseWorkspace: () => Promise<void>; initialTab?: SettingsTab }> = ({ runtime, chooseWorkspace, initialTab = 'general' }) => {
    const [activeTab, setActiveTab] = useState<SettingsTab>(initialTab);
    const rootRef = useRef<HTMLDivElement>(null);
    useEffect(() => setActiveTab(initialTab), [initialTab]);
    const selectedProvider = runtime.snapshot.settings.modelProviders.find((provider) => provider.id === runtime.snapshot.settings.grokModel);
    const runtimeReady = Boolean(runtime.runtimeStatus?.available);
    const modelReady = Boolean(selectedProvider?.enabled && selectedProvider.hasApiKey);
    const ready = runtimeReady && modelReady;
    const healthLabel = ready ? '可以开始任务' : !runtime.runtimeStatus ? '等待桌面运行时' : !runtimeReady ? '内置引擎不可用' : '需要配置当前模型';
    const healthClass = ready ? 'bg-emerald-50 text-emerald-700' : runtime.runtimeStatus && !runtimeReady ? 'bg-red-50 text-red-700' : 'bg-amber-50 text-amber-700';
    const tabs: Array<{ id: SettingsTab; label: string; description: string; icon: React.ElementType }> = [
        { id: 'general', label: '常规', description: '运行状态、工作区与模型', icon: Cpu },
        { id: 'execution', label: '任务执行', description: '权限、工具与会话参数', icon: CheckSquare },
        { id: 'configuration', label: '运行配置', description: '用户与项目 TOML', icon: Code2 },
        { id: 'plugins', label: '插件', description: '本地安装与会话加载', icon: Puzzle },
        { id: 'diagnostics', label: 'CLI 与诊断', description: '长尾能力和本地维护', icon: Wrench },
    ];
    const selectTab = (tab: SettingsTab) => {
        setActiveTab(tab);
        rootRef.current?.closest('main')?.scrollTo({ top: 0, behavior: 'smooth' });
    };

    return <div ref={rootRef} className="mx-auto w-full max-w-5xl p-6 md:p-8">
        <div className="mb-5"><h1 className="text-2xl font-semibold tracking-[-0.03em] text-slate-900">设置</h1><p className="mt-1 text-sm text-slate-500">先确认运行条件，再按需调整高级能力。</p></div>
        <div className="mb-6 grid gap-2 rounded-2xl bg-slate-100 p-1.5 md:grid-cols-5" role="tablist" aria-label="智能任务中心设置">
            {tabs.map((tab) => {
                const Icon = tab.icon;
                const active = activeTab === tab.id;
                return <button key={tab.id} type="button" role="tab" aria-selected={active} onClick={() => selectTab(tab.id)} className={`flex min-w-0 items-center gap-2.5 rounded-xl px-3 py-2.5 text-left transition ${active ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:bg-white/60 hover:text-slate-800'}`}><Icon size={16} className="shrink-0" /><span className="min-w-0"><span className="block text-sm font-medium">{tab.label}</span><span className="hidden truncate text-[10px] text-slate-400 lg:block">{tab.description}</span></span></button>;
            })}
        </div>

        {activeTab === 'general' && <div className="space-y-4" role="tabpanel">
            <div className="rounded-2xl border border-slate-200 p-5">
                <div className="flex flex-wrap items-start justify-between gap-3"><div><h3 className="font-semibold text-slate-900">运行状态</h3><p className="mt-1 text-sm text-slate-500">{runtime.runtimeStatus?.available ? '安装包内置智能引擎已加载' : runtime.runtimeStatus?.message || '正在等待桌面客户端返回运行时状态'}</p>{runtime.runtimeStatus?.version && <p className="mt-2 font-mono text-xs text-slate-400">{runtime.runtimeStatus.version}</p>}</div><span className={`flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium ${healthClass}`}>{ready ? <CheckCircle2 size={14} /> : <AlertCircle size={14} />}{healthLabel}</span></div>
                <div className="mt-4 grid gap-2 sm:grid-cols-3"><div className={`rounded-xl px-3 py-2.5 text-sm ${runtimeReady ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-50 text-slate-500'}`}>本地工具引擎 · {runtimeReady ? '已就绪' : '未就绪'}</div><div className={`rounded-xl px-3 py-2.5 text-sm ${modelReady ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'}`}>当前模型 · {modelReady ? selectedProvider?.name : '需要连接并保存密钥'}</div><div className="rounded-xl bg-blue-50 px-3 py-2.5 text-sm text-blue-700">网络策略 · 内网隔离已开启</div></div>
            </div>
            <div className="rounded-2xl border border-slate-200 p-5"><h3 className="font-semibold text-slate-900">默认工作区</h3><p className="mt-2 break-all text-sm text-slate-500">{runtime.snapshot.settings.workspace || '尚未选择'}</p><button type="button" onClick={() => void chooseWorkspace()} className="mt-4 flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 transition hover:bg-slate-50"><Folder size={16} />选择目录</button></div>
            <ModelProviderPanel providers={runtime.snapshot.settings.modelProviders} currentModel={runtime.snapshot.settings.grokModel} onSave={runtime.saveModelProvider} onSelect={runtime.selectModel} onDelete={runtime.removeModelProvider} onError={runtime.setRuntimeError} />
        </div>}

        {activeTab === 'execution' && <div role="tabpanel"><GrokExecutionSettingsPanel value={runtime.snapshot.settings.execution} onChange={(execution) => runtime.setSnapshot((current) => ({ ...current, settings: { ...current.settings, execution } }))} /></div>}
        {activeTab === 'configuration' && <div role="tabpanel"><GrokConfigEditor workspace={runtime.snapshot.settings.workspace} onError={runtime.setRuntimeError} /></div>}
        {activeTab === 'plugins' && <GrokPluginManager workspace={runtime.snapshot.settings.workspace} onChanged={runtime.reloadPluginCapabilities} onError={runtime.setRuntimeError} />}
        {activeTab === 'diagnostics' && <div className="space-y-6" role="tabpanel"><GrokCliCenter workspace={runtime.snapshot.settings.workspace} onError={runtime.setRuntimeError} /><div className="rounded-2xl border border-red-200 p-5"><h3 className="font-semibold text-slate-900">重置本地数据</h3><p className="mt-1 text-sm text-slate-500">清除自定义智能体、技能、运行配置、自动化和任务历史，不会删除工作区文件。</p><button type="button" onClick={() => { if (window.confirm('确认重置智能任务中心的全部本地配置和历史？')) runtime.resetAll(); }} className="mt-4 flex items-center gap-2 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700"><Trash2 size={16} />重置数据</button></div></div>}
    </div>;
};

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
    const save = () => { if (!value.name.trim() || !value.prompt.trim()) return; const saved = { ...value, nextRunAt: value.enabled ? nextAutomationRunAt(value.schedule, value.scheduleTime, value.scheduleWeekday) : undefined }; runtime.setSnapshot((current) => ({ ...current, automations: source ? current.automations.map((item) => item.id === source.id ? saved : item) : [...current.automations, saved] })); onClose(); };
    return <Modal title={source ? '编辑独立计划' : '新建独立计划'} onClose={onClose}><div className="space-y-4"><Field label="名称"><input className={inputClass} value={value.name} onChange={(event) => setValue({ ...value, name: event.target.value })} /></Field><Field label="说明"><input className={inputClass} value={value.description} onChange={(event) => setValue({ ...value, description: event.target.value })} /></Field><Field label="任务内容"><textarea className={inputClass} rows={6} value={value.prompt} onChange={(event) => setValue({ ...value, prompt: event.target.value })} /></Field><div className="grid gap-4 sm:grid-cols-2"><Field label="执行 Agent"><select className={inputClass} value={value.agentId} onChange={(event) => setValue({ ...value, agentId: event.target.value })}>{runtime.snapshot.agents.filter((agent) => agent.enabled).map((agent) => <option key={agent.id} value={agent.id}>{agent.name}</option>)}</select></Field><Field label="运行计划"><select className={inputClass} value={value.schedule} onChange={(event) => setValue({ ...value, schedule: event.target.value as AutomationSchedule })}><option value="manual">仅手动</option><option value="daily">每日</option><option value="weekly">每周</option></select></Field></div>{value.schedule !== 'manual' && <div className="grid gap-4 sm:grid-cols-2">{value.schedule === 'weekly' && <Field label="星期"><select className={inputClass} value={value.scheduleWeekday} onChange={(event) => setValue({ ...value, scheduleWeekday: Number(event.target.value) })}>{['周日', '周一', '周二', '周三', '周四', '周五', '周六'].map((label, index) => <option key={label} value={index}>{label}</option>)}</select></Field>}<Field label="时间"><input type="time" className={inputClass} value={value.scheduleTime} onChange={(event) => setValue({ ...value, scheduleTime: event.target.value })} /></Field></div>}<EditorActions canDelete={Boolean(source)} onDelete={() => { runtime.setSnapshot((current) => ({ ...current, automations: current.automations.filter((item) => item.id !== source?.id) })); onClose(); }} onClose={onClose} onSave={save} /></div></Modal>;
};

const EditorActions: React.FC<{ canDelete: boolean; onDelete: () => void; onClose: () => void; onSave: () => void }> = ({ canDelete, onDelete, onClose, onSave }) => <div className="flex items-center justify-between border-t border-slate-100 pt-4">{canDelete ? <button type="button" onClick={onDelete} className="flex items-center gap-1.5 text-sm text-red-600"><Trash2 size={15} />删除</button> : <span />}<div className="flex gap-2"><button type="button" onClick={onClose} className="rounded-lg border border-slate-200 px-4 py-2 text-sm text-slate-600">取消</button><button type="button" onClick={onSave} className="rounded-lg bg-slate-900 px-4 py-2 text-sm text-white">保存</button></div></div>;

export default ArkDesktopPage;
