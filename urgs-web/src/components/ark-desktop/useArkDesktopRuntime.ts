import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { isDesktopRuntime } from '@/config';
import {
    applyGrokModel,
    applyGrokQueueAction,
    authorizeGrokModelProvider,
    cancelGrokPrompt,
    chooseGrokAttachments,
    chooseGrokWorkspace,
    createGrokSession,
    deleteGrokModelProvider,
    deleteGrokScheduledTask,
    getGrokRuntimeStatus,
    getGrokModelCatalog,
    getGrokRuntimeDiagnostics,
    getGrokSessionInfo,
    listGrokBackgroundTasks,
    getGrokSubagent,
    listGrokMcpServers,
    listGrokSessions,
    searchGrokSessions,
    compactGrokSession,
    recapGrokSession,
    flushGrokMemory,
    killGrokBackgroundTask,
    cancelGrokSubagent,
    renameGrokSession,
    deleteGrokSession,
    reloadGrokMcpServers,
    setGrokMcpEnabled,
    invalidatePreparedGrokRuntime,
    inspectGrokPlugins,
    loadGrokSession,
    listGrokAvailableCommands,
    listGrokWorkflows,
    readGrokWorkflow,
    listGrokCliServices,
    listGrokModelProviders,
    openGrokWorkspace,
    releaseGrokSession,
    rewindGrokFiles,
    runGrokCli,
    respondGrokPlanApproval,
    respondGrokUserQuestion,
    respondGrokPermission,
    prepareGrokRuntime,
    startGrokCliService,
    stopGrokCliService,
    sendGrokPrompt,
    setGrokSessionModel,
    saveGrokModelProvider,
    subscribeGrokEvents,
    type GrokBridgeEvent,
    type GrokAcpOptions,
    type GrokRuntimeStatus,
    type GrokModelProvider,
    type GrokModelProviderInput,
    type GrokDiscoveredPlugin,
    type GrokModelCatalog,
    type GrokSessionSummary,
    type GrokRuntimeDiagnostics,
    type GrokMcpServerState,
    type GrokWorkflowFile,
    type GrokWorkflowListing,
} from '@/services/grokDesktop';
import { loadArkDesktopSnapshot, resetArkDesktopSnapshot, saveArkDesktopSnapshot } from './storage';
import { extractFileChanges } from './fileChanges';
import type {
    ArkDesktopAgent,
    ArkDesktopQueueEntry,
    ArkDesktopAutomation,
    ArkDesktopPermissionRequest,
    ArkDesktopPlanStep,
    ArkDesktopPlanApprovalRequest,
    ArkDesktopUserQuestionRequest,
    ArkDesktopSkill,
    ArkDesktopSnapshot,
    ArkDesktopScheduledTask,
    ArkDesktopSlashCommand,
    ArkDesktopTask,
    ArkDesktopTaskStatus,
    ArkDesktopToolActivity,
    ArkDesktopWorkflowRun,
    ArkDesktopModelProvider,
    GrokExecutionSettings,
} from './types';
import { buildGrokHeadlessArguments, extractGrokHeadlessSessionId, extractGrokHeadlessText } from './execution';

interface StartTaskInput {
    prompt: string;
    workspace?: string;
    agentId?: string;
    skillIds?: string[];
    attachmentPaths?: string[];
    attachmentGrantIds?: string[];
    automationId?: string;
}

const MODEL_KEY_AUTHORIZATION_REQUIRED = 'MODEL_KEY_AUTHORIZATION_REQUIRED:';

const runtimeErrorText = (error: unknown) => error instanceof Error ? error.message : String(error);

const modelKeyAuthorizationProviderId = (error: unknown) => {
    const message = runtimeErrorText(error);
    const markerIndex = message.indexOf(MODEL_KEY_AUTHORIZATION_REQUIRED);
    if (markerIndex < 0) return undefined;
    return message
        .slice(markerIndex + MODEL_KEY_AUTHORIZATION_REQUIRED.length)
        .match(/^[A-Za-z0-9_-]+/)?.[0];
};

const createId = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;

const resolveModelProvider = (snapshot: ArkDesktopSnapshot, modelValue?: string) => {
    const value = modelValue?.trim();
    if (!value) return undefined;
    return snapshot.settings.modelProviders.find((provider) => provider.id === value)
        || snapshot.settings.modelProviders.find((provider) => provider.model === value);
};

const redactRuntimeText = (value: string) => {
    const redacted = value
        .replace(/\bgrok(?:\s+build)?\b/gi, '内置智能引擎')
        .replace(/\bxai\b/gi, '服务')
        .replace(/MODEL_KEY_AUTHORIZATION_REQUIRED:[A-Za-z0-9_-]+/g, '当前模型连接需要先解锁本机密钥');
    if (/unknown variant[\s`'\"]*image_url[\s`'\"]*[\s\S]*expected[\s`'\"]*text/i.test(redacted)) {
        return '当前模型连接不支持图像输入；已生成的文件仍然保留，请切换支持图片的模型后重新进行视觉验证。';
    }
    return redacted;
};

const extractText = (update: Record<string, any>) =>
    (typeof update?.content === 'string' ? update.content : undefined)
    || update?.content?.text
    || update?.content?.content?.text
    || update?.text
    || update?.delta
    || '';

const formatToolDetail = (value: unknown) => {
    if (value === undefined || value === null || value === '') return undefined;
    const text = typeof value === 'string'
        ? value
        : Array.isArray(value)
            ? value.map((item) => item?.text || item?.content?.text || JSON.stringify(item)).join('\n')
            : JSON.stringify(value, null, 2);
    return redactRuntimeText(text).slice(0, 12_000);
};

const formatDisplayToolTitle = (value: unknown, fallback = '本地工具调用') => {
    const title = redactRuntimeText(String(value || '').trim()) || fallback;
    return /^(get task output|get_task_output|get command or subagent output|get_command_or_subagent_output)(:|\s|$)/i.test(title)
        ? '等待后台任务完成'
        : title;
};

const statusLabel = (status?: string) => {
    switch (status) {
        case 'pending': return '等待中';
        case 'in_progress': return '运行中';
        case 'completed': return '已完成';
        case 'failed': return '失败';
        default: return status || '运行中';
    }
};

const workflowText = (value: unknown) => {
    const text = typeof value === 'string' ? value.trim() : '';
    return text ? redactRuntimeText(text) : undefined;
};

const workflowNumber = (value: unknown, fallback = 0) => {
    const number = Number(value);
    return Number.isFinite(number) ? number : fallback;
};

const normalizeWorkflowRun = (update: Record<string, any>): ArkDesktopWorkflowRun => {
    const agents = Array.isArray(update.agents)
        ? update.agents.map((agent: any) => ({
            agentId: String(agent?.agent_id || agent?.agentId || '').trim(),
            label: workflowText(agent?.label) || '工作流智能体',
            phase: workflowText(agent?.phase),
            model: workflowText(agent?.model),
            state: String(agent?.state || 'unknown'),
            tokensUsed: workflowNumber(agent?.tokens_used ?? agent?.tokensUsed),
            durationMs: workflowNumber(agent?.duration_ms ?? agent?.durationMs),
        })).filter((agent: ArkDesktopWorkflowRun['agents'][number]) => agent.agentId || agent.label)
        : [];
    const phases = Array.isArray(update.phases)
        ? update.phases.map((phase: any) => ({
            title: workflowText(phase?.title) || '未命名阶段',
            state: String(phase?.state || 'pending'),
        }))
        : [];
    const budget = update.agent_budget ?? update.agentBudget;
    const remaining = update.agents_remaining ?? update.agentsRemaining;
    return {
        runId: String(update.run_id || update.runId || '').trim(),
        name: workflowText(update.name) || '工作流',
        objective: workflowText(update.objective) || '',
        status: String(update.status || 'active'),
        foreground: update.foreground === true,
        revision: workflowNumber(update.revision),
        phases,
        currentPhase: workflowText(update.current_phase ?? update.currentPhase),
        agentBudget: budget == null ? undefined : workflowNumber(budget),
        agentsUsed: workflowNumber(update.agents_used ?? update.agentsUsed),
        agentsReserved: workflowNumber(update.agents_reserved ?? update.agentsReserved),
        agentsRemaining: remaining == null ? undefined : workflowNumber(remaining),
        agentUsageIncomplete: update.agent_usage_incomplete === true || update.agentUsageIncomplete === true,
        elapsedMs: workflowNumber(update.elapsed_ms ?? update.elapsedMs),
        activeAgents: workflowNumber(update.active_agents ?? update.activeAgents ?? agents.filter((agent: ArkDesktopWorkflowRun['agents'][number]) => agent.state === 'running').length),
        currentAgentLabel: workflowText(update.current_agent_label ?? update.currentAgentLabel),
        agents,
        lastEvent: workflowText(update.last_event ?? update.lastEvent),
        lastEventDetail: workflowText(update.last_event_detail ?? update.lastEventDetail),
        lastEventTimestamp: workflowText(update.last_event_timestamp ?? update.lastEventTimestamp),
        pauseMessage: workflowText(update.pause_message ?? update.pauseMessage),
        resultSummary: workflowText(update.result_summary ?? update.resultSummary),
        updatedAt: Date.now(),
    };
};

const workflowStatusLabel = (status: string) => {
    switch (status.toLowerCase()) {
        case 'complete':
        case 'completed': return '已完成';
        case 'failed': return '失败';
        case 'interrupted':
        case 'cancelled': return '已取消';
        case 'stopped': return '已停止';
        case 'cleared': return '已清理';
        case 'paused':
        case 'user_paused': return '已暂停';
        default: return '运行中';
    }
};

const upsertTaskActivity = (
    task: ArkDesktopTask,
    activity: Omit<ArkDesktopToolActivity, 'startedAt' | 'updatedAt'>,
    options: { appendOutput?: boolean } = {},
) => {
    const tools = task.tools.slice();
    const existingIndex = tools.findIndex((tool) => tool.id === activity.id);
    const existing = existingIndex >= 0 ? tools[existingIndex] : undefined;
    const output = options.appendOutput && existing?.output && activity.output
        ? `${existing.output}${activity.output}`.slice(-12_000)
        : activity.output ?? existing?.output;
    const next: ArkDesktopToolActivity = {
        ...existing,
        ...activity,
        ...(output ? { output } : {}),
        startedAt: existing?.startedAt || existing?.updatedAt || Date.now(),
        updatedAt: Date.now(),
    };
    if (existingIndex >= 0) tools[existingIndex] = next;
    else tools.push(next);
    return { ...task, tools: tools.slice(-200), updatedAt: Date.now() };
};

const applyCompactedContextInfo = (
    contextInfo: ArkDesktopTask['contextInfo'],
    tokensAfter: unknown,
) => {
    if (!contextInfo) return contextInfo;
    const used = Number(tokensAfter);
    if (!Number.isFinite(used) || used < 0) return contextInfo;
    const total = Number(contextInfo.total);
    return {
        ...contextInfo,
        used,
        freeTokens: total > 0 ? Math.max(0, total - used) : contextInfo.freeTokens,
        usagePct: total > 0 ? Math.min(100, Math.floor((used * 100) / total)) : contextInfo.usagePct,
        compactionCount: contextInfo.compactionCount + 1,
    };
};

const isSettledActivity = (status: string) => /已完成|已记录|完成|成功|失败|取消|不可用|未生成|退出码|completed|recorded|success|failed|cancelled|canceled|unavailable|done/i.test(status);

const settleForegroundActivities = (
    task: ArkDesktopTask,
    terminalStatus: ArkDesktopTaskStatus,
) => {
    const nextStatus = terminalStatus === 'failed' ? '失败' : terminalStatus === 'cancelled' ? '已取消' : '已完成';
    const tools = task.tools.map((tool) => {
        // Recap is queued asynchronously by the sidecar. A foreground turn can
        // finish before its session_recap/session_recap_unavailable event arrives.
        if (tool.id === 'session-recap' || isSettledActivity(tool.status) || ['background_task', 'monitor', 'goal', 'workflow'].includes(tool.kind || '')) return tool;
        return { ...tool, status: nextStatus, updatedAt: Date.now() };
    });
    return { ...task, status: terminalStatus, tools, updatedAt: Date.now() };
};

const parsePlanSteps = (entries: unknown): ArkDesktopPlanStep[] => Array.isArray(entries)
    ? entries.map((entry: any) => {
        const rawStatus = String(entry?.status || 'pending').toLowerCase();
        const status: ArkDesktopPlanStep['status'] = rawStatus === 'in_progress' || rawStatus === 'completed' || rawStatus === 'cancelled'
            ? rawStatus
            : 'pending';
        const rawPriority = String(entry?.priority || '').toLowerCase();
        const priority: ArkDesktopPlanStep['priority'] = rawPriority === 'high' || rawPriority === 'medium' || rawPriority === 'low'
            ? rawPriority
            : undefined;
        return {
            content: String(entry?.content || '').trim(),
            status: entry?.meta?.cancelled ? 'cancelled' : status,
            ...(priority ? { priority } : {}),
        };
    }).filter((step: ArkDesktopPlanStep) => step.content)
    : [];

const findTodoCollection = (value: unknown, visited = new Set<object>()): unknown => {
    if (typeof value === 'string') {
        try {
            return findTodoCollection(JSON.parse(value), visited);
        } catch {
            return undefined;
        }
    }
    if (!value || typeof value !== 'object') return undefined;
    if (visited.has(value)) return undefined;
    visited.add(value);

    if (Array.isArray(value)) {
        for (const item of value) {
            const todos = findTodoCollection(item, visited);
            if (todos !== undefined) return todos;
        }
        return undefined;
    }

    const object = value as Record<string, unknown>;
    if (object.TodosUpdated !== undefined) {
        return findTodoCollection(object.TodosUpdated, visited);
    }
    const state = object.state;
    if (state && typeof state === 'object' && 'todos' in state) {
        return (state as Record<string, unknown>).todos;
    }
    if (object.todos !== undefined) return object.todos;

    for (const key of ['content', 'text', 'output', 'rawOutput', 'structuredContent', 'data', 'result']) {
        const todos = findTodoCollection(object[key], visited);
        if (todos !== undefined) return todos;
    }
    return undefined;
};

const parseTodoPlan = (value: unknown): ArkDesktopPlanStep[] | null => {
    const todos = findTodoCollection(value);
    if (!todos || typeof todos !== 'object') return null;

    const entries = Array.isArray(todos)
        ? todos
        : Object.entries(todos)
            .sort(([left], [right]) => {
                const leftNumber = Number(left);
                const rightNumber = Number(right);
                return Number.isNaN(leftNumber) || Number.isNaN(rightNumber)
                    ? left.localeCompare(right)
                    : leftNumber - rightNumber;
            })
            .map(([, item]) => item);
    const plan = parsePlanSteps(entries);
    return plan.length ? plan : null;
};

const selectAgentId = (snapshot: ArkDesktopSnapshot, requestedAgentId?: string, skillIds: string[] = []) => {
    if (requestedAgentId && snapshot.agents.some((agent) => agent.id === requestedAgentId && agent.enabled)) {
        return requestedAgentId;
    }
    if (skillIds.includes('code-development')) return 'grok-code';
    if (skillIds.includes('data-analysis') || skillIds.includes('workspace-search')) return 'grok-data';
    if (skillIds.includes('document-processing') || skillIds.includes('deep-research')) return 'grok-office';
    return snapshot.settings.defaultAgentId || 'grok-general';
};

const buildSessionRules = (agent: ArkDesktopAgent, skills: ArkDesktopSkill[]) => [
    '你运行在 URGS ARK Desktop 智能任务中心中。你可以操作用户明确选择的本地工作区。',
    agent.systemPrompt,
    ...skills.map((skill) => `技能【${skill.name}】：${skill.instruction}`),
    '当需要用户在预设方向、方案或偏好中选择时，必须调用 AskUserQuestion 工具并提供结构化选项。不要在普通消息里列出题目、选项或要求用户用文字回答；调用前最多用一句话说明需要确认方向，随后等待用户在界面卡片中选择。',
    '多阶段任务必须使用计划工具维护 3 至 7 个可执行阶段；开始执行前先创建完整计划，并且只允许一个阶段处于 in_progress。阶段必须严格串行：完成当前阶段的全部工具工作后，立即调用计划工具将当前阶段标记为 completed、将下一个阶段标记为 in_progress，等待该调用成功后才能开始下一阶段。不要把多个阶段的状态留到最后一次调用，也不要只在普通消息中口头描述进度；如果阶段包含多个工具调用，在该阶段全部完成前保持它为 in_progress。',
    '执行要求：先理解目标，再使用必要工具完成实际工作；涉及修改或命令时等待 ARK Desktop 的用户授权；结束时总结产物、修改文件和验证结果。',
].filter(Boolean).join('\n\n');

const buildTaskPrompt = (prompt: string, attachmentPaths: string[]) => {
    if (attachmentPaths.length === 0) return prompt;
    return `${prompt}\n\n用户为本任务选择了以下本地文件，请按需读取并处理：\n${attachmentPaths.map((path) => `- ${path}`).join('\n')}`;
};

const buildAcpOptions = (execution: GrokExecutionSettings): GrokAcpOptions => ({
    reasoningEffort: execution.reasoningEffort,
    permissionMode: execution.permissionMode,
    sandboxProfile: execution.sandboxProfile,
    alwaysApprove: execution.permissionMode === 'bypassPermissions',
    reauth: execution.reauth,
    agentProfile: execution.agentProfile,
    pluginDirs: execution.pluginDirs.split('\n').map((item) => item.trim()).filter(Boolean),
    leaderMode: execution.leaderMode,
    grokWsOrigin: execution.grokWsOrigin,
    grokWsUrl: execution.grokWsUrl,
    cliChatProxyUrl: execution.cliChatProxyUrl,
    xaiApiBaseUrl: execution.xaiApiBaseUrl,
    debug: execution.debug,
    debugFile: execution.debugFile,
    leaderSocket: execution.leaderSocket,
});

const eventProcessId = (event: GrokBridgeEvent) => String(event.payload?.processId || '');

const eventSessionId = (event: GrokBridgeEvent) => {
    const params = event.payload?.params || event.payload;
    return String(params?.sessionId || params?.session_id || '');
};

const waitForCliService = async (serviceId: string) => {
    const deadline = Date.now() + 60 * 60 * 1000;
    while (Date.now() < deadline) {
        const service = (await listGrokCliServices()).find((item) => item.id === serviceId);
        if (!service) throw new Error('后台任务进程不存在');
        if (!service.alive) return service;
        await new Promise((resolve) => window.setTimeout(resolve, 800));
    }
    await stopGrokCliService(serviceId).catch(() => undefined);
    throw new Error('后台任务执行超过 1 小时');
};

const findLatestGrokSessionId = async (workspace: string) => {
    const result = await runGrokCli(['sessions', 'list', '--limit', '1'], workspace, 30);
    if (!result.success) return undefined;
    return result.stdout.match(/\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b/i)?.[0];
};

const findHistoricalSessionId = async (workspace: string, firstPrompt: string) => {
    const query = firstPrompt.trim();
    if (!query) return undefined;
    try {
        const response = await searchGrokSessions(workspace, query, 10);
        const best = response.results
            .filter((item) => item.sessionId)
            .sort((left, right) => Number(right.score || 0) - Number(left.score || 0))[0];
        if (best?.sessionId) return best.sessionId;
    } catch {
        // Keep the CLI fallback for snapshots created before native history was available.
    }
    const result = await runGrokCli(['sessions', 'search', '--limit', '5', query], workspace, 30);
    if (!result.success) return undefined;
    const sessionIds = Array.from(new Set(
        result.stdout.match(/\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b/gi) || [],
    ));
    return sessionIds[0];
};

export const useArkDesktopRuntime = () => {
    const [snapshot, setSnapshot] = useState<ArkDesktopSnapshot>(loadArkDesktopSnapshot);
    const [runtimeStatus, setRuntimeStatus] = useState<GrokRuntimeStatus | null>(null);
    const [modelCatalog, setModelCatalog] = useState<GrokModelCatalog | null>(null);
    const [remoteSessions, setRemoteSessions] = useState<GrokSessionSummary[]>([]);
    const [remoteSessionsLoading, setRemoteSessionsLoading] = useState(false);
    const [remoteSessionsError, setRemoteSessionsError] = useState('');
    const [runtimeDiagnostics, setRuntimeDiagnostics] = useState<GrokRuntimeDiagnostics[]>([]);
    const [mcpServers, setMcpServers] = useState<GrokMcpServerState[]>([]);
    const [discoveredCommands, setDiscoveredCommands] = useState<ArkDesktopSlashCommand[]>([]);
    const [discoveredPlugins, setDiscoveredPlugins] = useState<GrokDiscoveredPlugin[]>([]);
    const [capabilitiesLoading, setCapabilitiesLoading] = useState(false);
    const [capabilitiesError, setCapabilitiesError] = useState('');
    const [activeTaskId, setActiveTaskId] = useState<string | null>(null);
    const [permissions, setPermissions] = useState<ArkDesktopPermissionRequest[]>([]);
    const [userQuestions, setUserQuestions] = useState<ArkDesktopUserQuestionRequest[]>([]);
    const [planApprovals, setPlanApprovals] = useState<ArkDesktopPlanApprovalRequest[]>([]);
    const [runtimeError, setRuntimeError] = useState('');
    const cancelledTaskIdsRef = useRef(new Set<string>());
    const taskByProcessIdRef = useRef(new Map<string, string>());
    const taskBySessionIdRef = useRef(new Map<string, string>());
    const mountedSessionIdsRef = useRef(new Set<string>());
    const subagentBySessionIdRef = useRef(new Map<string, string>());
    const activePromptCountsRef = useRef(new Map<string, number>());
    const snapshotRef = useRef(snapshot);
    const capabilityRequestIdRef = useRef(0);
    const remoteSessionRequestIdRef = useRef(0);

    useEffect(() => {
        snapshotRef.current = snapshot;
        saveArkDesktopSnapshot(snapshot);
        snapshot.tasks.forEach((task) => {
            if (task.runtimeProcessId) taskByProcessIdRef.current.set(task.runtimeProcessId, task.id);
            if (task.sessionId) taskBySessionIdRef.current.set(task.sessionId, task.id);
        });
    }, [snapshot]);

    const updateTask = useCallback((taskId: string, updater: (task: ArkDesktopTask) => ArkDesktopTask) => {
        setSnapshot((current) => ({
            ...current,
            tasks: current.tasks.map((task) => task.id === taskId ? updater(task) : task),
        }));
    }, []);

    const finishForegroundPrompt = useCallback((
        taskId: string,
        terminalStatus: Extract<ArkDesktopTaskStatus, 'completed' | 'failed'>,
        error?: string,
    ) => {
        const remaining = Math.max(0, (activePromptCountsRef.current.get(taskId) || 1) - 1);
        if (remaining > 0) activePromptCountsRef.current.set(taskId, remaining);
        else activePromptCountsRef.current.delete(taskId);
        updateTask(taskId, (task) => {
            if (cancelledTaskIdsRef.current.has(taskId)) return task;
            if (remaining > 0) {
                return {
                    ...task,
                    status: 'running',
                    ...(error ? { error } : {}),
                    updatedAt: Date.now(),
                };
            }
            const settled = settleForegroundActivities(task, terminalStatus);
            return error ? { ...settled, error } : settled;
        });
    }, [updateTask]);

    const refreshRuntimeStatus = useCallback(async () => {
        if (!isDesktopRuntime()) return;
        try {
            setRuntimeError('');
            setRuntimeStatus(await getGrokRuntimeStatus());
        } catch (error) {
            setRuntimeError(redactRuntimeText(error instanceof Error ? error.message : '无法检测内置智能引擎'));
        }
    }, []);

    const refreshCapabilities = useCallback(async (workspaceOverride?: string) => {
        if (!isDesktopRuntime()) return;
        const requestId = ++capabilityRequestIdRef.current;
        setCapabilitiesLoading(true);
        setCapabilitiesError('');
        const workspace = workspaceOverride?.trim() || snapshotRef.current.settings.workspace;
        const results = await Promise.allSettled([
            workspace ? listGrokAvailableCommands(workspace) : Promise.resolve([]),
            inspectGrokPlugins(workspace || undefined),
        ]);
        if (requestId !== capabilityRequestIdRef.current) return;
        const [commandsResult, pluginsResult] = results;
        if (commandsResult.status === 'fulfilled') {
            setDiscoveredCommands(commandsResult.value.map((command) => ({
                name: command.name,
                description: command.description,
                inputHint: command.inputHint,
            })));
        } else setDiscoveredCommands([]);
        if (pluginsResult.status === 'fulfilled') setDiscoveredPlugins(pluginsResult.value);
        const capabilityErrors = [commandsResult, pluginsResult]
            .filter((result): result is PromiseRejectedResult => result.status === 'rejected')
            .map((result) => redactRuntimeText(result.reason instanceof Error ? result.reason.message : String(result.reason)));
        setCapabilitiesError(capabilityErrors.join('；'));
        setCapabilitiesLoading(false);
    }, []);

    const refreshModelProviders = useCallback(async () => {
        if (!isDesktopRuntime()) return;
        const modelProviders = await listGrokModelProviders();
        const enabledModelIds = modelProviders.filter((provider) => provider.enabled).map((provider) => provider.id);
        setSnapshot((current) => ({
            ...current,
            settings: {
                ...current.settings,
                modelProviders,
                grokModel: enabledModelIds.includes(current.settings.grokModel)
                    ? current.settings.grokModel
                    : enabledModelIds[0] || '',
                modelOptions: enabledModelIds,
            },
        }));
    }, []);

    const refreshModelCatalog = useCallback(async (workspaceOverride?: string) => {
        if (!isDesktopRuntime()) return null;
        const workspace = workspaceOverride?.trim() || snapshotRef.current.settings.workspace;
        if (!workspace) return null;
        try {
            const catalog = await getGrokModelCatalog(workspace);
            setModelCatalog(catalog || null);
            return catalog || null;
        } catch (error) {
            setModelCatalog(null);
            return null;
        }
    }, []);

    const refreshRemoteSessions = useCallback(async (workspaceOverride?: string, query = '') => {
        if (!isDesktopRuntime()) return [];
        const requestId = ++remoteSessionRequestIdRef.current;
        const workspace = workspaceOverride?.trim() || snapshotRef.current.settings.workspace;
        if (!workspace) {
            setRemoteSessions([]);
            return [];
        }
        setRemoteSessionsLoading(true);
        setRemoteSessionsError('');
        try {
            const sessions = query.trim()
                ? (await searchGrokSessions(workspace, query.trim(), 30)).results
                : (await listGrokSessions(workspace, undefined, 200)).sessions;
            if (requestId === remoteSessionRequestIdRef.current) setRemoteSessions(sessions);
            return sessions;
        } catch (error) {
            const message = redactRuntimeText(error instanceof Error ? error.message : String(error));
            if (requestId === remoteSessionRequestIdRef.current) setRemoteSessionsError(message);
            return [];
        } finally {
            if (requestId === remoteSessionRequestIdRef.current) setRemoteSessionsLoading(false);
        }
    }, []);

    const refreshMcpServers = useCallback(async (workspaceOverride?: string) => {
        if (!isDesktopRuntime()) return [];
        const workspace = workspaceOverride?.trim() || snapshotRef.current.settings.workspace;
        if (!workspace) return [];
        try {
            const servers = await listGrokMcpServers(workspace);
            setMcpServers(servers);
            return servers;
        } catch {
            setMcpServers([]);
            return [];
        }
    }, []);

    const refreshRuntimeDiagnostics = useCallback(async () => {
        if (!isDesktopRuntime()) return [];
        try {
            const diagnostics = await getGrokRuntimeDiagnostics();
            setRuntimeDiagnostics(diagnostics);
            return diagnostics;
        } catch {
            setRuntimeDiagnostics([]);
            return [];
        }
    }, []);

    const handleGrokEvent = useCallback((event: GrokBridgeEvent) => {
        const processId = eventProcessId(event);
        const sessionId = eventSessionId(event);
        const taskId = taskBySessionIdRef.current.get(sessionId)
            || taskByProcessIdRef.current.get(processId)
            || snapshotRef.current.tasks.find((task) => (
                (processId && task.runtimeProcessId === processId)
                || (sessionId && task.sessionId === sessionId)
            ))?.id;
        const taskSessionId = taskId
            ? snapshotRef.current.tasks.find((task) => task.id === taskId)?.sessionId
            : undefined;
        const isChildSession = Boolean(sessionId && taskSessionId && sessionId !== taskSessionId);
        if (taskId && isChildSession && ['queue_changed', 'interjection', 'scheduled_prompt'].includes(event.eventType)) {
            return;
        }
        if (event.eventType === 'queued_prompt' && taskId) {
            const phase = String(event.payload?.phase || '');
            if (phase === 'accepted') {
                return;
            }
            if (phase === 'completed') {
                finishForegroundPrompt(taskId, 'completed');
            } else if (phase === 'failed') {
                finishForegroundPrompt(
                    taskId,
                    'failed',
                    redactRuntimeText(String(event.payload?.message || '补充消息执行失败')),
                );
            }
            return;
        }
        if (event.eventType === 'scheduled_prompt' && taskId) {
            const phase = String(event.payload?.phase || '');
            if (phase === 'started') {
                const prompt = redactRuntimeText(String(event.payload?.prompt || '').trim());
                updateTask(taskId, (task) => ({
                    ...task,
                    status: 'running',
                    error: undefined,
                    messages: prompt
                        ? [...task.messages, { id: createId('message'), role: 'user' as const, content: prompt, createdAt: Date.now() }]
                        : task.messages,
                    updatedAt: Date.now(),
                }));
            } else if (phase === 'failed') {
                const message = redactRuntimeText(String(event.payload?.message || 'Grok 会话循环执行失败'));
                updateTask(taskId, (task) => ({
                    ...settleForegroundActivities(task, 'failed'),
                    error: message,
                }));
            } else if (phase === 'completed') {
                updateTask(taskId, (task) => settleForegroundActivities(task, 'completed'));
            }
            return;
        }
        if (event.eventType === 'queue_changed' && taskId) {
            const queue = event.payload?.params || event.payload || {};
            const entries: ArkDesktopQueueEntry[] = Array.isArray(queue.entries)
                ? queue.entries
                    .filter((entry: any) => typeof entry?.id === 'string' && typeof entry?.text === 'string')
                    .map((entry: any, index: number) => ({
                        id: entry.id,
                        version: Number.isFinite(Number(entry.version)) ? Number(entry.version) : 0,
                        owner: typeof entry.owner === 'string' ? entry.owner : null,
                        lastEditor: typeof entry.lastEditor === 'string' ? entry.lastEditor : null,
                        kind: typeof entry.kind === 'string' ? entry.kind : 'prompt',
                        text: entry.text,
                        position: Number.isFinite(Number(entry.position)) ? Number(entry.position) : index,
                    }))
                : [];
            const runningPromptId = typeof queue.runningPromptId === 'string' ? queue.runningPromptId : null;
            updateTask(taskId, (task) => {
                const previousEntries = task.queueEntries || [];
                const startedEntry = runningPromptId
                    ? previousEntries.find((entry) => entry.id === runningPromptId && !entries.some((next) => next.id === entry.id))
                    : undefined;
                const latestMessage = task.messages[task.messages.length - 1];
                const alreadyRendered = startedEntry && latestMessage?.role === 'user'
                    && latestMessage.content.trim() === startedEntry.text.trim();
                const messages = startedEntry
                    && !alreadyRendered
                    && !task.messages.some((message) => message.queueEntryId === startedEntry.id)
                    ? [...task.messages, {
                        id: createId('message'),
                        role: 'user' as const,
                        content: startedEntry.text,
                        queueEntryId: startedEntry.id,
                        createdAt: Date.now(),
                    }]
                    : task.messages;
                return {
                    ...task,
                    queueEntries: entries,
                    queueRunningPromptId: runningPromptId,
                    messages,
                    updatedAt: Date.now(),
                };
            });
            return;
        }
        if (event.eventType === 'interjection' && taskId) {
            const text = redactRuntimeText(String(event.payload?.text || '').trim());
            const interjectionId = String(event.payload?.interjectionId || '').trim();
            if (!text) return;
            const messageId = interjectionId ? `interjection-${interjectionId}` : createId('interjection');
            updateTask(taskId, (task) => {
                const latestMessage = task.messages[task.messages.length - 1];
                const alreadyRendered = latestMessage?.role === 'user'
                    && latestMessage.content.trim() === text;
                return {
                    ...task,
                    messages: alreadyRendered || task.messages.some((message) => message.id === messageId)
                        ? task.messages
                        : [...task.messages, {
                        id: messageId,
                        role: 'user' as const,
                        content: text,
                        createdAt: Date.now(),
                    }],
                    updatedAt: Date.now(),
                };
            });
            return;
        }
        if (event.eventType === 'mcp_servers_updated') {
            const servers = Array.isArray(event.payload?.mcpServers)
                ? event.payload.mcpServers as GrokMcpServerState[]
                : [];
            setMcpServers(servers);
            if (taskId) {
                updateTask(taskId, (task) => ({
                    ...task,
                    mcpServers: servers.map((server) => ({
                        name: server.name,
                        transport: server.transport,
                        health: server.health,
                        tools: server.tools || [],
                    })),
                    updatedAt: Date.now(),
                }));
            }
            return;
        }
        if (event.eventType === 'session_update' && taskId) {
            const params = event.payload?.params || event.payload;
            const update = params?.update || params?.sessionUpdate || {};
            const updateType = update?.sessionUpdate;
            // Grok emits a non-persisted turn-end Plan without `_meta.eventId`.
            // It maps stale in_progress items to completed only to clear its
            // native spinner, so it must not overwrite the authoritative TodoWrite state.
            const isTransientPlanCleanup = updateType === 'plan'
                && !String(params?._meta?.eventId || '').trim();
            const todoPlan = isTransientPlanCleanup ? null : parseTodoPlan(update);
            if (todoPlan) {
                updateTask(taskId, (task) => ({ ...task, plan: todoPlan, updatedAt: Date.now() }));
            }
            if (updateType === 'available_commands_update') {
                const availableCommands = Array.isArray(update.availableCommands)
                    ? update.availableCommands
                        .filter((command: any) => typeof command?.name === 'string' && command.name.trim())
                        .map((command: any) => ({
                            name: command.name.trim(),
                            description: typeof command.description === 'string' ? command.description.trim() : '',
                            inputHint: typeof command.input?.hint === 'string'
                                ? command.input.hint.trim()
                                : typeof command.argumentHint === 'string'
                                    ? command.argumentHint.trim()
                                    : undefined,
                        }))
                    : [];
                updateTask(taskId, (task) => ({ ...task, availableCommands, updatedAt: Date.now() }));
                return;
            }
            if (updateType === 'session_recap') {
                const recap = redactRuntimeText(String(update.content || update.summary || update.recap || '').trim());
                updateTask(taskId, (task) => {
                    const next = upsertTaskActivity(task, {
                        id: 'session-recap',
                        title: '生成会话 Recap',
                        status: recap ? '已完成' : '不可用',
                        kind: 'context',
                        output: recap ? '会话 Recap 已生成' : 'Recap 返回为空，当前未生成摘要',
                    });
                    return recap ? { ...next, recap } : next;
                });
                return;
            }
            if (updateType === 'session_recap_unavailable') {
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id: 'session-recap',
                    title: '生成会话 Recap',
                    status: '不可用',
                    kind: 'context',
                    output: formatToolDetail(update.reason || update.message || '当前会话暂时无法生成 Recap') || '当前会话暂时无法生成 Recap',
                }));
                return;
            }
            if (updateType === 'agent_message_chunk' || updateType === 'message_delta') {
                const chunk = extractText(update);
                if (!chunk) return;
                const subagentId = subagentBySessionIdRef.current.get(sessionId);
                if (subagentId || isChildSession) {
                    const activityId = subagentId || sessionId;
                    updateTask(taskId, (task) => {
                        const existing = task.tools.find((tool) => tool.id === `subagent-${activityId}`);
                        return upsertTaskActivity(task, {
                            id: `subagent-${activityId}`,
                            title: existing?.title || '子智能体协作',
                            status: existing && isSettledActivity(existing.status) ? existing.status : '运行中',
                            kind: 'subagent',
                            output: redactRuntimeText(chunk),
                        }, { appendOutput: true });
                    });
                    return;
                }
                updateTask(taskId, (task) => {
                    const messages = task.messages.slice();
                    const last = messages[messages.length - 1];
                    const latestToolStartedAt = task.tools.reduce((latest, tool) => Math.max(latest, tool.startedAt || tool.updatedAt), 0);
                    if (last?.role === 'assistant' && latestToolStartedAt < last.createdAt) {
                        messages[messages.length - 1] = { ...last, content: `${last.content}${chunk}` };
                    } else {
                        messages.push({ id: createId('message'), role: 'assistant', content: chunk, createdAt: Date.now() });
                    }
                    const isWorkflowCompletionMessage = String(params?._meta?.promptId || '').startsWith('workflow-completed-');
                    const tools = task.tools.map((tool) => (
                        (tool.kind === 'reasoning' || (tool.kind === 'subagent' && isWorkflowCompletionMessage))
                        && !isSettledActivity(tool.status)
                    ) ? { ...tool, status: '已完成', updatedAt: Date.now() } : tool);
                    return { ...task, messages, tools, updatedAt: Date.now() };
                });
                return;
            }
            if (updateType === 'agent_thought_chunk') {
                const chunk = extractText(update);
                if (!chunk) return;
                const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
                const latestUserMessage = [...(task?.messages || [])].reverse().find((message) => message.role === 'user');
                updateTask(taskId, (value) => upsertTaskActivity(value, {
                    id: `reasoning-${latestUserMessage?.id || 'current'}`,
                    title: '分析过程',
                    status: '分析中',
                    kind: 'reasoning',
                    output: redactRuntimeText(chunk),
                }, { appendOutput: true }));
                return;
            }
            if (updateType === 'plan') {
                if (isTransientPlanCleanup) return;
                const plan = parsePlanSteps(update.entries);
                updateTask(taskId, (task) => ({ ...task, plan, updatedAt: Date.now() }));
                return;
            }
            if (updateType === 'tool_call' || updateType === 'tool_call_update') {
                const id = String(update.toolCallId || update.tool_call_id || update.toolCall?.toolCallId || update.toolCall?.tool_call_id || createId('tool'));
                updateTask(taskId, (task) => {
                    const tools = task.tools.slice();
                    const existingIndex = tools.findIndex((tool) => tool.id === id);
                    const input = formatToolDetail(update.rawInput ?? update.raw_input ?? update.toolCall?.rawInput ?? update.toolCall?.raw_input);
                    const structuredContent = update.content ?? update.toolCall?.content;
                    const fileChanges = extractFileChanges(structuredContent);
                    const output = formatToolDetail(
                        update.rawOutput ?? update.raw_output ?? (fileChanges.length > 0 ? undefined : structuredContent),
                    );
                    const nextTool = {
                        id,
                        title: formatDisplayToolTitle(update.title || update.toolCall?.title),
                        status: statusLabel(update.status),
                        kind: update.kind || update.toolCall?.kind,
                        ...(input ? { input } : {}),
                        ...(output ? { output } : {}),
                        ...(fileChanges.length > 0 ? { fileChanges } : {}),
                        startedAt: existingIndex >= 0 ? tools[existingIndex].startedAt || tools[existingIndex].updatedAt : Date.now(),
                        updatedAt: Date.now(),
                    };
                    if (existingIndex >= 0) tools[existingIndex] = { ...tools[existingIndex], ...nextTool };
                    else tools.push(nextTool);
                    return { ...task, tools, updatedAt: Date.now() };
                });
                return;
            }
            if (updateType === 'tool_call_delta_chunk') {
                const id = String(update.tool_call_id || update.toolCallId || `tool-stream-${update.tool_index || 0}`);
                const chunk = typeof update.arguments_delta === 'string' ? update.arguments_delta : '';
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id,
                    title: formatDisplayToolTitle(update.name, '正在准备工具调用'),
                    status: '运行中',
                    kind: update.name || 'tool',
                    ...(chunk ? { input: `${task.tools.find((tool) => tool.id === id)?.input || ''}${chunk}`.slice(-12_000) } : {}),
                }));
                return;
            }
            if (updateType === 'retry_state') {
                const attempt = Number(update.attempt || update.attempts || 0);
                const maxRetries = Number(update.maxRetries || update.max_retries || 0);
                const reason = redactRuntimeText(String(update.reason || update.message || '模型服务暂时不可用'));
                const failed = update.type === 'failed' || update.type === 'exhausted';
                updateTask(taskId, (task) => ({
                    ...upsertTaskActivity(task, {
                        id: 'inference-retry',
                        title: failed ? '模型请求未能恢复' : `模型请求重试 ${attempt}${maxRetries ? `/${maxRetries}` : ''}`,
                        status: failed ? '失败' : reason,
                        kind: 'inference',
                        output: reason,
                    }),
                    ...(failed ? { status: 'failed' as const, error: reason } : {}),
                }));
                return;
            }
            if (updateType === 'session_summary_generated') {
                const title = String(update.session_summary || '').trim();
                if (title) updateTask(taskId, (task) => ({ ...task, title: title.slice(0, 60), updatedAt: Date.now() }));
                return;
            }
            if (updateType === 'model_changed' || updateType === 'model_auto_switched') {
                const model = String(update.model_id || update.new_model_id || '').trim();
                if (model) updateTask(taskId, (task) => ({ ...task, model, updatedAt: Date.now() }));
                return;
            }
            if (updateType === 'task_backgrounded') {
                const backgroundTaskId = String(update.task_id || update.tool_call_id || createId('background'));
                updateTask(taskId, (task) => {
                    const title = redactRuntimeText(update.description || update.monitor_description || '后台任务');
                    const next = upsertTaskActivity(task, {
                        id: `background-${backgroundTaskId}`,
                        title,
                        status: '后台运行中',
                        kind: update.monitor_description ? 'monitor' : 'background_task',
                        input: formatToolDetail(update.command),
                        output: update.output_file ? `输出日志：${update.output_file}` : undefined,
                    });
                    const backgroundTasks = (task.backgroundTasks || []).filter((item) => item.taskId !== backgroundTaskId);
                    return {
                        ...next,
                        backgroundTasks: [...backgroundTasks, {
                            taskId: backgroundTaskId,
                            title,
                            status: '后台运行中',
                            command: typeof update.command === 'string' ? update.command : undefined,
                            outputFile: typeof update.output_file === 'string' ? update.output_file : undefined,
                            kind: update.monitor_description ? 'monitor' : 'background_task',
                            updatedAt: Date.now(),
                        }],
                    };
                });
                return;
            }
            if (updateType === 'task_completed') {
                const completed = update.task_snapshot || {};
                const backgroundTaskId = String(completed.task_id || createId('background'));
                const exitCode = completed.exit_code;
                const failed = typeof exitCode === 'number' && exitCode !== 0;
                updateTask(taskId, (task) => {
                    const title = redactRuntimeText(completed.display_command || completed.command || '后台任务');
                    const status = failed ? `退出码 ${exitCode}` : '已完成';
                    const next = upsertTaskActivity(task, {
                        id: `background-${backgroundTaskId}`,
                        title,
                        status,
                        kind: completed.kind || 'background_task',
                        input: formatToolDetail(completed.command),
                        output: formatToolDetail(completed.output || (completed.output_file ? `输出日志：${completed.output_file}` : '')),
                    });
                    const backgroundTasks = (task.backgroundTasks || []).filter((item) => item.taskId !== backgroundTaskId);
                    return {
                        ...next,
                        backgroundTasks: [...backgroundTasks, {
                            taskId: backgroundTaskId,
                            title,
                            status,
                            command: typeof completed.command === 'string' ? completed.command : undefined,
                            output: typeof completed.output === 'string' ? redactRuntimeText(completed.output) : undefined,
                            outputFile: typeof completed.output_file === 'string' ? completed.output_file : undefined,
                            kind: completed.kind || 'background_task',
                            updatedAt: Date.now(),
                        }],
                    };
                });
                return;
            }
            if (updateType === 'subagent_spawned' || updateType === 'subagent_progress' || updateType === 'subagent_finished') {
                const subagentId = String(update.child_session_id || update.subagent_id || createId('subagent'));
                if (updateType === 'subagent_spawned' && typeof update.child_session_id === 'string' && update.child_session_id) {
                    taskBySessionIdRef.current.set(update.child_session_id, taskId);
                    subagentBySessionIdRef.current.set(update.child_session_id, subagentId);
                }
                const finished = updateType === 'subagent_finished';
                const progress = updateType === 'subagent_progress'
                    ? `已运行 ${Math.round(Number(update.duration_ms || 0) / 1000)} 秒 · ${Number(update.turn_count || 0)} 回合 · ${Number(update.tool_call_count || 0)} 次工具调用`
                    : undefined;
                updateTask(taskId, (task) => {
                    const title = redactRuntimeText(update.description || `${update.subagent_type || '子智能体'}协作`);
                    const status = finished ? statusLabel(update.status) : progress || '运行中';
                    const next = upsertTaskActivity(task, {
                        id: `subagent-${subagentId}`,
                        title,
                        status,
                        kind: 'subagent',
                        output: formatToolDetail(update.output || update.error),
                    });
                    const subagents = (task.subagents || []).filter((item) => item.subagentId !== subagentId);
                    return {
                        ...next,
                        subagents: [...subagents, {
                            subagentId,
                            title,
                            status,
                            output: formatToolDetail(update.output || update.error),
                            updatedAt: Date.now(),
                        }],
                    };
                });
                return;
            }
            if (updateType?.startsWith('auto_compact_')) {
                const failed = updateType === 'auto_compact_failed';
                const completed = updateType === 'auto_compact_completed';
                updateTask(taskId, (task) => {
                    const activityId = task.tools.some((tool) => tool.id === 'context-compaction-manual')
                        ? 'context-compaction-manual'
                        : 'context-compaction';
                    const next = upsertTaskActivity(task, {
                        id: activityId,
                        title: '整理会话上下文',
                        status: failed ? '失败' : completed ? '已完成' : updateType === 'auto_compact_cancelled' ? '已取消' : '运行中',
                        kind: 'context',
                        output: formatToolDetail(update.error || update.reason || update.summary_preview),
                    });
                    return completed
                        ? { ...next, contextInfo: applyCompactedContextInfo(next.contextInfo, update.tokens_after) }
                        : next;
                });
                return;
            }
            if (updateType?.startsWith('auto_recovery_')) {
                const exhausted = updateType === 'auto_recovery_exhausted';
                const detail = redactRuntimeText(String(update.error || '正在恢复会话'));
                updateTask(taskId, (task) => ({
                    ...upsertTaskActivity(task, {
                        id: 'auto-recovery',
                        title: exhausted ? '会话自动恢复失败' : `正在自动恢复 ${Number(update.attempt || 1)}/${Number(update.max_retries || 1)}`,
                        status: exhausted ? '失败' : '运行中',
                        kind: 'recovery',
                        output: detail,
                    }),
                    ...(exhausted ? { status: 'failed' as const, error: detail } : {}),
                }));
                return;
            }
            if (updateType?.startsWith('memory_')) {
                const finished = updateType.endsWith('_completed') || updateType === 'memory_session_saved';
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id: `memory-${updateType.replace(/_(started|completed)$/, '')}`,
                    title: updateType.includes('dream') ? '整理长期记忆' : updateType.includes('session_saved') ? '保存会话记忆' : '刷新会话记忆',
                    status: finished ? '已完成' : '运行中',
                    kind: 'memory',
                    output: formatToolDetail(update.result || update.path),
                }));
                return;
            }
            if (updateType === 'goal_updated') {
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id: `goal-${String(update.goal_id || 'current')}`,
                    title: redactRuntimeText(update.objective || '持续任务'),
                    status: `${update.status || 'active'} · ${update.phase || 'executing'}`,
                    kind: 'goal',
                    output: formatToolDetail(update.pause_message || update.last_event_detail),
                }));
                return;
            }
            if (updateType === 'workflow_updated') {
                const workflow = normalizeWorkflowRun(update);
                if (!workflow.runId) return;
                updateTask(taskId, (task) => {
                    const existing = (task.workflowRuns || []).find((item) => item.runId === workflow.runId);
                    const isCleared = workflow.status.toLowerCase() === 'cleared';
                    if (!isCleared && existing && ((workflow.revision === 0 && existing.revision > 0)
                        || (workflow.revision > 0 && workflow.revision <= existing.revision))) {
                        return task;
                    }
                    const detail = [
                        workflow.currentPhase ? `阶段：${workflow.currentPhase}` : '',
                        workflow.activeAgents > 0 ? `活跃智能体：${workflow.activeAgents}` : '',
                        workflow.currentAgentLabel ? `当前智能体：${workflow.currentAgentLabel}` : '',
                        workflow.pauseMessage,
                        workflow.lastEventDetail,
                        workflow.resultSummary,
                    ].filter(Boolean).join('\n');
                    const next = upsertTaskActivity(task, {
                        id: `workflow-${workflow.runId}`,
                        title: workflow.name,
                        status: workflowStatusLabel(workflow.status),
                        kind: 'workflow',
                        output: detail || undefined,
                    });
                    const workflowRuns = isCleared
                        ? (task.workflowRuns || []).filter((item) => item.runId !== workflow.runId)
                        : [...(task.workflowRuns || []).filter((item) => item.runId !== workflow.runId), workflow];
                    return { ...next, workflowRuns, updatedAt: Date.now() };
                });
                return;
            }
            if (updateType === 'scheduled_task_created' || updateType === 'scheduled_task_fired') {
                const scheduledTaskId = String(update.task_id || '').trim();
                if (!scheduledTaskId) return;
                const fired = updateType === 'scheduled_task_fired';
                updateTask(taskId, (task) => {
                    const scheduledTasks = task.scheduledTasks?.slice() || [];
                    const existingIndex = scheduledTasks.findIndex((item) => item.id === scheduledTaskId);
                    const existing = existingIndex >= 0 ? scheduledTasks[existingIndex] : undefined;
                    const scheduledTask: ArkDesktopScheduledTask = {
                        id: scheduledTaskId,
                        prompt: String(update.prompt || existing?.prompt || '').trim(),
                        humanSchedule: String(update.human_schedule || existing?.humanSchedule || '计划执行'),
                        nextFireAt: typeof update.next_fire_at === 'string' ? update.next_fire_at : existing?.nextFireAt,
                        createdAt: existing?.createdAt || Date.now(),
                        lastFiredAt: fired ? Date.now() : existing?.lastFiredAt,
                        firedCount: (existing?.firedCount || 0) + (fired ? 1 : 0),
                    };
                    if (existingIndex >= 0) scheduledTasks[existingIndex] = scheduledTask;
                    else scheduledTasks.push(scheduledTask);
                    return { ...task, scheduledTasks, updatedAt: Date.now() };
                });
                return;
            }
            if (updateType === 'scheduled_task_deleted') {
                const scheduledTaskId = String(update.task_id || '').trim();
                if (!scheduledTaskId) return;
                updateTask(taskId, (task) => ({
                    ...task,
                    scheduledTasks: (task.scheduledTasks || []).filter((item) => item.id !== scheduledTaskId),
                    updatedAt: Date.now(),
                }));
                return;
            }
            if (updateType === 'turn_completed') {
                const stopReason = String(update.stopReason || update.stop_reason || '').toLowerCase();
                const status: ArkDesktopTask['status'] = stopReason.includes('cancel')
                    ? 'cancelled'
                    : stopReason.includes('error') || stopReason.includes('fail')
                        ? 'failed'
                        : 'completed';
                updateTask(taskId, (task) => settleForegroundActivities(task, status));
                return;
            }
            if (updateType === 'user_message_chunk' || updateType === 'interaction_resolved' || updateType === 'current_mode_update') {
                return;
            }
            const diagnosticType = typeof updateType === 'string' && updateType ? updateType : 'unknown';
            updateTask(taskId, (task) => upsertTaskActivity(task, {
                id: `runtime-event-${diagnosticType}`,
                title: '运行时兼容事件',
                status: `已记录：${diagnosticType}`,
                kind: 'diagnostic',
            }));
            return;
        }

        if (event.eventType === 'permission_request' && taskId && sessionId) {
            const params = event.payload?.params || {};
            const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
            const request: ArkDesktopPermissionRequest = {
                taskId,
                sessionId,
                taskTitle: task?.title || '后台任务',
                requestId: event.payload?.id,
                title: redactRuntimeText(params?.toolCall?.title || params?.toolCall?.rawInput || '智能体请求执行本地操作'),
                options: (params?.options || []).map((option: any) => ({
                    optionId: option.optionId,
                    name: option.name || option.optionId,
                    kind: option.kind,
                })),
            };
            const requestKey = JSON.stringify(request.requestId);
            setPermissions((current) => [
                ...current.filter((item) => item.sessionId !== sessionId || JSON.stringify(item.requestId) !== requestKey),
                request,
            ]);
            return;
        }

        if (event.eventType === 'user_question_request' && taskId && sessionId) {
            const request: ArkDesktopUserQuestionRequest = {
                taskId,
                sessionId,
                requestId: event.payload?.requestId,
                toolCallId: event.payload?.toolCallId,
                mode: event.payload?.mode === 'plan' ? 'plan' : 'default',
                questions: Array.isArray(event.payload?.questions) ? event.payload.questions.map((question: any) => ({
                    ...(typeof question?.id === 'string' ? { id: question.id } : {}),
                    question: String(question?.question || '请完成以下选择'),
                    multiSelect: Boolean(question?.multiSelect ?? question?.multi_select),
                    options: Array.isArray(question?.options) ? question.options.map((option: any) => ({
                        ...(typeof option?.id === 'string' ? { id: option.id } : {}),
                        label: String(option?.label || ''),
                        ...(typeof option?.description === 'string' ? { description: option.description } : {}),
                        ...(typeof option?.preview === 'string' ? { preview: option.preview } : {}),
                    })).filter((option: ArkDesktopUserQuestionRequest['questions'][number]['options'][number]) => option.label) : [],
                })).filter((question: ArkDesktopUserQuestionRequest['questions'][number]) => question.question && question.options.length > 0) : [],
            };
            if (request.requestId === undefined || request.requestId === null || request.questions.length === 0) {
                updateTask(taskId, (task) => ({ ...task, error: '收到的用户问卷格式无效', updatedAt: Date.now() }));
                return;
            }
            const requestKey = JSON.stringify(request.requestId);
            setUserQuestions((current) => [
                ...current.filter((item) => item.sessionId !== sessionId || JSON.stringify(item.requestId) !== requestKey),
                request,
            ]);
            return;
        }

        if (event.eventType === 'plan_approval_request' && taskId && sessionId) {
            const request: ArkDesktopPlanApprovalRequest = {
                taskId,
                sessionId,
                requestId: event.payload?.requestId,
                toolCallId: typeof event.payload?.toolCallId === 'string' ? event.payload.toolCallId : undefined,
                planContent: typeof event.payload?.planContent === 'string' ? event.payload.planContent : undefined,
            };
            if (request.requestId === undefined || request.requestId === null) {
                updateTask(taskId, (task) => ({ ...task, error: '收到的计划审批格式无效', updatedAt: Date.now() }));
                return;
            }
            const requestKey = JSON.stringify(request.requestId);
            setPlanApprovals((current) => [
                ...current.filter((item) => item.sessionId !== sessionId || JSON.stringify(item.requestId) !== requestKey),
                request,
            ]);
            return;
        }

        if (event.eventType === 'agent_event' || event.eventType === 'stderr') {
            const method = String(event.payload?.method || event.payload?.event || event.eventType);
            const detail = formatToolDetail(event.payload?.params || event.payload?.message || event.payload);
            if (taskId) {
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id: `diagnostic-${method}`,
                    title: method === 'hooks_changed' || method.includes('hook') ? 'Hooks 状态变化' : '运行时诊断事件',
                    status: '已记录',
                    kind: 'diagnostic',
                    output: detail,
                }));
            }
            return;
        }

        if (event.eventType === 'runtime_error') {
            const message = redactRuntimeText(event.payload?.message || '本地智能运行时发生错误');
            if (taskId) {
                updateTask(taskId, (task) => ({ ...task, status: 'failed', error: message, updatedAt: Date.now() }));
            } else {
                setRuntimeError(message);
            }
            return;
        }

        if (event.eventType === 'terminated' && taskId) {
            if (!processId) return;
            taskByProcessIdRef.current.delete(processId);
            const taskSessionId = snapshotRef.current.tasks.find((task) => task.id === taskId)?.sessionId;
            if (taskSessionId) mountedSessionIdsRef.current.delete(taskSessionId);
            setPermissions((current) => current.filter((item) => item.taskId !== taskId));
            setUserQuestions((current) => current.filter((item) => item.taskId !== taskId));
            setPlanApprovals((current) => current.filter((item) => item.taskId !== taskId));
            updateTask(taskId, (task) => task.runtimeProcessId === processId && task.status === 'running'
                ? { ...task, status: 'failed', error: '本地任务进程已退出', updatedAt: Date.now() }
                : task);
        }

        if (event.eventType === 'login_completed') {
            void refreshRuntimeStatus();
        }
    }, [finishForegroundPrompt, refreshRuntimeStatus, updateTask]);

    useEffect(() => {
        if (!isDesktopRuntime()) return;
        void refreshRuntimeStatus();
        void refreshModelProviders().catch((error) => {
            setRuntimeError(redactRuntimeText(error instanceof Error ? error.message : '无法读取模型连接'));
        });
        let unlisten: (() => void) | undefined;
        let disposed = false;
        void subscribeGrokEvents(handleGrokEvent).then((dispose) => {
            if (disposed) {
                dispose();
            } else {
                unlisten = dispose;
            }
        }).catch((error) => {
            if (!disposed) {
                setRuntimeError(redactRuntimeText(error instanceof Error ? error.message : '无法订阅本地任务事件'));
            }
        });
        return () => {
            disposed = true;
            unlisten?.();
        };
    }, [handleGrokEvent, refreshModelProviders, refreshRuntimeStatus]);

    useEffect(() => {
        void refreshCapabilities();
    }, [refreshCapabilities, snapshot.settings.grokModel, snapshot.settings.workspace]);

    const selectWorkspace = useCallback(async () => {
        const selected = await chooseGrokWorkspace();
        if (!selected) return '';
        setSnapshot((current) => ({
            ...current,
            settings: {
                ...current.settings,
                workspace: selected,
                workspacePaths: Array.from(new Set([...current.settings.workspacePaths, selected])),
            },
        }));
        return selected;
    }, []);

    const pickWorkspace = useCallback(async () => chooseGrokWorkspace(), []);

    const addWorkspace = useCallback((workspace: string) => {
        const normalized = workspace.trim();
        if (!normalized) return;
        setSnapshot((current) => ({
            ...current,
            settings: {
                ...current.settings,
                workspacePaths: Array.from(new Set([...current.settings.workspacePaths, normalized])),
            },
        }));
    }, []);

    const setDefaultWorkspace = useCallback((workspace: string) => {
        const normalized = workspace.trim();
        if (!normalized) return;
        setSnapshot((current) => ({
            ...current,
            settings: {
                ...current.settings,
                workspace: normalized,
                workspacePaths: Array.from(new Set([...current.settings.workspacePaths, normalized])),
            },
        }));
    }, []);

    const removeWorkspace = useCallback((workspace: string) => {
        const normalized = workspace.trim();
        if (!normalized) return;
        setSnapshot((current) => {
            const workspacePaths = current.settings.workspacePaths.filter((item) => item !== normalized);
            return {
                ...current,
                settings: {
                    ...current.settings,
                    workspacePaths,
                    workspace: current.settings.workspace === normalized
                        ? workspacePaths[0] || ''
                        : current.settings.workspace,
                },
            };
        });
    }, []);

    const selectAttachments = useCallback(async () => chooseGrokAttachments(), []);

    const startTask = useCallback(async ({
        prompt,
        workspace: requestedWorkspace,
        agentId,
        skillIds = [],
        attachmentPaths = [],
        attachmentGrantIds = [],
        automationId,
    }: StartTaskInput) => {
        const current = snapshotRef.current;
        const workspace = requestedWorkspace?.trim() || current.settings.workspace;
        if (!isDesktopRuntime()) throw new Error('请在 URGS 桌面客户端中运行 ARK Desktop');
        if (!runtimeStatus?.available) throw new Error('未检测到内置智能引擎，请先检查桌面安装包');
        if (!workspace) throw new Error('请先选择本地工作区');
        const selectedProvider = current.settings.modelProviders.find((provider) => provider.id === current.settings.grokModel);
        if (!current.settings.grokModel || !selectedProvider) throw new Error('请先在设置中添加并选择模型连接');
        if (!selectedProvider.enabled) throw new Error(`模型连接“${selectedProvider.name}”已停用`);
        const promptRequired = current.settings.execution.engine !== 'headless' || current.settings.execution.promptMode === 'text';
        if (promptRequired && !prompt.trim()) throw new Error('请输入要完成的任务');
        const resolvedAgentId = selectAgentId(current, agentId, skillIds);
        const agent = current.agents.find((item) => item.id === resolvedAgentId && item.enabled)
            || current.agents.find((item) => item.enabled);
        if (!agent) throw new Error('没有可用的本地 Agent');
        const resolvedSkillIds = Array.from(new Set([...agent.skillIds, ...skillIds]))
            .filter((id) => current.skills.some((skill) => skill.id === id && skill.enabled));
        const skills = current.skills.filter((skill) => resolvedSkillIds.includes(skill.id));
        const effectivePrompt = prompt.trim()
            || current.settings.execution.promptFile.trim()
            || '本地 JSON 内容块任务';
        const now = Date.now();
        const taskId = createId('task');
        const task: ArkDesktopTask = {
            id: taskId,
            title: effectivePrompt.slice(0, 36),
            prompt: effectivePrompt,
            agentId: agent.id,
            skillIds: resolvedSkillIds,
            workspace,
            attachmentPaths,
            attachmentGrantIds,
            engine: current.settings.execution.engine,
            model: current.settings.grokModel || undefined,
            permissionMode: current.settings.execution.permissionMode,
            alwaysApprove: false,
            status: 'running',
            messages: [{ id: createId('message'), role: 'user', content: effectivePrompt, createdAt: now }],
            tools: [],
            automationId,
            createdAt: now,
            updatedAt: now,
        };
        setSnapshot((value) => ({
            ...value,
            tasks: [task, ...value.tasks].slice(0, 50),
            settings: {
                ...value.settings,
                workspacePaths: Array.from(new Set([...value.settings.workspacePaths, workspace])),
            },
        }));
        activePromptCountsRef.current.set(taskId, 1);
        setActiveTaskId(taskId);
        setRuntimeError('');

        void (async () => {
            try {
                const sessionRules = buildSessionRules(agent, skills);
                if (current.settings.execution.engine === 'headless') {
                    const execution = current.settings.execution;
                    const headlessExecution = execution.sessionMode === 'new' && !execution.newSessionId.trim()
                        ? { ...execution, newSessionId: crypto.randomUUID() }
                        : execution;
                    const headlessRules = headlessExecution.promptMode === 'text' || attachmentPaths.length === 0
                        ? sessionRules
                        : `${sessionRules}\n\n用户为本任务选择了以下本地文件，请按需读取并处理：\n${attachmentPaths.map((path) => `- ${path}`).join('\n')}`;
                    const service = await startGrokCliService(
                        buildGrokHeadlessArguments(
                            headlessExecution,
                            current.settings.grokModel,
                            buildTaskPrompt(effectivePrompt, attachmentPaths),
                            headlessRules,
                        ),
                        workspace,
                    );
                    void refreshModelProviders().catch(() => undefined);
                    if (cancelledTaskIdsRef.current.has(taskId)) {
                        await stopGrokCliService(service.id).catch(() => undefined);
                        return;
                    }
                    updateTask(taskId, (value) => ({ ...value, cliServiceId: service.id, updatedAt: Date.now() }));
                    const result = await waitForCliService(service.id);
                    if (result.exitCode !== 0 && !cancelledTaskIdsRef.current.has(taskId)) throw new Error(result.stderr || '后台任务执行失败');
                    const knownSessionId = headlessExecution.sessionMode === 'new'
                        ? headlessExecution.newSessionId
                        : headlessExecution.sessionMode === 'resume' && !headlessExecution.forkSession
                            ? headlessExecution.resumeSessionId
                            : '';
                    const sessionId = extractGrokHeadlessSessionId(result.stdout, headlessExecution.outputFormat)
                        || knownSessionId
                        || await findLatestGrokSessionId(workspace).catch(() => undefined);
                    const response = redactRuntimeText(extractGrokHeadlessText(result.stdout, headlessExecution.outputFormat));
                    updateTask(taskId, (value) => ({
                        ...value,
                        sessionId,
                        messages: [...value.messages, { id: createId('message'), role: 'assistant', content: response || '任务已完成。', createdAt: Date.now() }],
                        updatedAt: Date.now(),
                    }));
                } else {
                    const execution = current.settings.execution;
                    const session = await createGrokSession(
                        workspace,
                        sessionRules,
                        current.settings.grokModel,
                        buildAcpOptions(execution),
                    );
                    void refreshModelProviders().catch(() => undefined);
                    taskByProcessIdRef.current.set(session.processId, taskId);
                    taskBySessionIdRef.current.set(session.sessionId, taskId);
                    mountedSessionIdsRef.current.add(session.sessionId);
                    updateTask(taskId, (value) => ({
                        ...value,
                        sessionId: session.sessionId,
                        runtimeProcessId: session.processId,
                        availableCommands: session.availableCommands,
                        updatedAt: Date.now(),
                    }));
                    if (cancelledTaskIdsRef.current.has(taskId)) {
                        await cancelGrokPrompt(session.sessionId).catch(() => undefined);
                        return;
                    }
                    await sendGrokPrompt(session.sessionId, effectivePrompt, attachmentPaths, attachmentGrantIds);
                    const info = await getGrokSessionInfo(session.sessionId).catch(() => null);
                    if (info) updateTask(taskId, (value) => ({
                        ...value,
                        model: info.model || value.model,
                        contextInfo: info.context,
                        updatedAt: Date.now(),
                    }));
                }
                finishForegroundPrompt(taskId, 'completed');
                if (automationId) {
                    setSnapshot((value) => ({
                        ...value,
                        automations: value.automations.map((automation) => automation.id === automationId
                            ? { ...automation, lastRunAt: Date.now() }
                            : automation),
                    }));
                }
            } catch (error) {
                if (!cancelledTaskIdsRef.current.has(taskId)) {
                    const providerId = modelKeyAuthorizationProviderId(error);
                    if (providerId) {
                        activePromptCountsRef.current.delete(taskId);
                        updateTask(taskId, (value) => ({
                            ...value,
                            status: 'waiting_authorization',
                            error: undefined,
                            modelKeyAuthorization: { providerId, action: 'start' },
                            updatedAt: Date.now(),
                        }));
                    } else {
                        const message = redactRuntimeText(runtimeErrorText(error));
                        finishForegroundPrompt(taskId, 'failed', message);
                    }
                }
            }
        })();
        return taskId;
    }, [finishForegroundPrompt, refreshModelProviders, runtimeStatus, updateTask]);

    const prepareEngine = useCallback(async (workspaceOverride?: string) => {
        const current = snapshotRef.current;
        const workspace = workspaceOverride?.trim() || current.settings.workspace;
        const provider = current.settings.modelProviders.find((item) => item.id === current.settings.grokModel);
        if (!isDesktopRuntime() || !runtimeStatus?.available || !workspace || !provider?.enabled || !provider.hasApiKey) return false;
        setRuntimeError('');
        const execution = current.settings.execution;
        const agentId = selectAgentId(current, undefined, current.settings.defaultSkillIds);
        const agent = current.agents.find((item) => item.id === agentId && item.enabled)
            || current.agents.find((item) => item.enabled);
        if (!agent) return false;
        const skillIds = Array.from(new Set([...agent.skillIds, ...current.settings.defaultSkillIds]));
        const skills = current.skills.filter((skill) => skill.enabled && skillIds.includes(skill.id));
        await prepareGrokRuntime(
            workspace,
            provider.id,
            buildAcpOptions(execution),
            buildSessionRules(agent, skills),
        );
        await Promise.allSettled([
            refreshCapabilities(workspace),
            refreshModelCatalog(workspace),
            refreshRemoteSessions(workspace),
            refreshMcpServers(workspace),
            refreshRuntimeDiagnostics(),
        ]);
        return true;
    }, [refreshCapabilities, refreshMcpServers, refreshModelCatalog, refreshRemoteSessions, refreshRuntimeDiagnostics, runtimeStatus]);

    const reloadPluginCapabilities = useCallback(async () => {
        await invalidatePreparedGrokRuntime();
        if (!await prepareEngine()) await refreshCapabilities();
    }, [prepareEngine, refreshCapabilities]);

    useEffect(() => {
        const timer = window.setTimeout(() => {
            void prepareEngine().catch(() => undefined);
        }, 250);
        return () => window.clearTimeout(timer);
    }, [prepareEngine, snapshot.settings.workspace, snapshot.settings.grokModel, snapshot.settings.defaultAgentId]);

    const ensureTaskSessionMounted = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId || task.engine === 'headless' || mountedSessionIdsRef.current.has(task.sessionId)) return;
        const current = snapshotRef.current;
        const agent = current.agents.find((item) => item.id === task.agentId && item.enabled)
            || current.agents.find((item) => item.enabled);
        if (!agent) throw new Error('该历史任务使用的 Agent 已不存在');
        const skills = current.skills.filter((skill) => task.skillIds.includes(skill.id) && skill.enabled);
        const execution = {
            ...current.settings.execution,
            permissionMode: task.permissionMode || current.settings.execution.permissionMode,
            alwaysApprove: false,
        };
        const modelProvider = resolveModelProvider(current, task.model || current.settings.grokModel);
        if (!modelProvider) throw new Error(`历史会话使用的模型连接“${task.model || current.settings.grokModel}”不存在，请在设置中配置对应连接`);
        if (!modelProvider.enabled) throw new Error(`模型连接“${modelProvider.name}”已停用`);
        const session = await loadGrokSession(
            task.sessionId,
            task.workspace,
            buildSessionRules(agent, skills),
            modelProvider.id,
            buildAcpOptions(execution),
        );
        mountedSessionIdsRef.current.add(session.sessionId);
        taskByProcessIdRef.current.set(session.processId, taskId);
        taskBySessionIdRef.current.set(session.sessionId, taskId);
        updateTask(taskId, (value) => ({
            ...value,
            runtimeProcessId: session.processId,
            availableCommands: session.availableCommands,
            mcpServers: session.mcpServers.map((server) => ({
                name: server.name,
                transport: server.transport,
                health: server.health,
                tools: server.tools,
            })),
            updatedAt: Date.now(),
        }));
        session.replayedEvents.forEach((replayed) => handleGrokEvent({
            eventType: 'session_update',
            payload: { ...replayed, processId: session.processId },
        }));
    }, [handleGrokEvent, loadGrokSession, updateTask]);

    const openRemoteSession = useCallback(async (summary: GrokSessionSummary) => {
        const current = snapshotRef.current;
        const existing = current.tasks.find((task) => task.sessionId === summary.sessionId);
        if (existing) {
            setActiveTaskId(existing.id);
            return existing.id;
        }
        const workspace = summary.cwd || current.settings.workspace;
        const agent = current.agents.find((item) => item.id === current.settings.defaultAgentId && item.enabled)
            || current.agents.find((item) => item.enabled);
        if (!agent) throw new Error('没有可用的本地 Agent');
        const prompt = String(summary.firstPrompt || summary.summary || summary.title || '历史会话').trim();
        const now = Date.now();
        const taskId = createId('grok-session');
        const task: ArkDesktopTask = {
            id: taskId,
            title: String(summary.title || summary.summary || '历史会话').slice(0, 80),
            prompt,
            agentId: agent.id,
            skillIds: agent.skillIds.filter((id) => current.skills.some((skill) => skill.id === id && skill.enabled)),
            workspace,
            attachmentPaths: [],
            engine: 'acp',
            model: current.settings.grokModel || summary.modelId || undefined,
            permissionMode: current.settings.execution.permissionMode,
            status: 'completed',
            messages: [],
            tools: [],
            remoteOnly: true,
            createdAt: summary.createdAt ? Date.parse(summary.createdAt) || now : now,
            updatedAt: summary.updatedAt ? Date.parse(summary.updatedAt) || now : now,
        };
        setSnapshot((value) => ({ ...value, tasks: [task, ...value.tasks].slice(0, 50) }));
        setActiveTaskId(taskId);
        try {
            if (!task.model) throw new Error('请先配置一个可用的模型连接，再打开历史会话');
            const session = await loadGrokSession(
                summary.sessionId,
                workspace,
                undefined,
                task.model,
                buildAcpOptions(current.settings.execution),
            );
            mountedSessionIdsRef.current.add(session.sessionId);
            taskByProcessIdRef.current.set(session.processId, taskId);
            taskBySessionIdRef.current.set(session.sessionId, taskId);
            updateTask(taskId, (value) => ({
                ...value,
                sessionId: session.sessionId,
                runtimeProcessId: session.processId,
                availableCommands: session.availableCommands,
                mcpServers: session.mcpServers.map((server) => ({
                    name: server.name,
                    transport: server.transport,
                    health: server.health,
                    tools: server.tools,
                })),
                updatedAt: Date.now(),
            }));
            session.replayedEvents.forEach((replayed) => handleGrokEvent({
                eventType: 'session_update',
                payload: { ...replayed, processId: session.processId },
            }));
            const info = await getGrokSessionInfo(session.sessionId).catch(() => null);
            if (info) updateTask(taskId, (value) => ({
                ...value,
                model: info.model || value.model,
                contextInfo: info.context,
                updatedAt: Date.now(),
            }));
            return taskId;
        } catch (error) {
            const message = redactRuntimeText(runtimeErrorText(error));
            updateTask(taskId, (value) => ({ ...value, status: 'failed', error: message, updatedAt: Date.now() }));
            throw error;
        }
    }, [handleGrokEvent, updateTask]);

    const sendFollowUp = useCallback(async (taskId: string, prompt: string, displayPrompt = prompt) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task) throw new Error('历史任务不存在');
        const activePromptCount = activePromptCountsRef.current.get(taskId) || 0;
        activePromptCountsRef.current.set(taskId, activePromptCount + 1);
        try {
            const current = snapshotRef.current;
            const sessionId = task.sessionId
                || await findHistoricalSessionId(task.workspace, task.title || task.prompt);
            if (!sessionId) {
                throw new Error('无法唯一匹配该任务的原历史会话，请新建任务');
            }
            if (!task.sessionId) {
                taskBySessionIdRef.current.set(sessionId, taskId);
                updateTask(taskId, (value) => ({ ...value, sessionId, updatedAt: Date.now() }));
            }
            if (task.engine !== 'headless') {
                const agent = current.agents.find((item) => item.id === task.agentId)
                    || current.agents.find((item) => item.enabled);
                if (!agent) throw new Error('该历史任务使用的 Agent 已不存在');
                const modelProvider = resolveModelProvider(current, task.model || current.settings.grokModel);
                if (!modelProvider) {
                    throw new Error(`历史会话使用的模型连接“${task.model || current.settings.grokModel}”不存在，请在设置中配置对应连接`);
                }
                if (!modelProvider.enabled) {
                    throw new Error(`模型连接“${modelProvider.name}”已停用`);
                }
                const skills = current.skills.filter((skill) => task.skillIds.includes(skill.id) && skill.enabled);
                const execution = {
                    ...current.settings.execution,
                    permissionMode: task.permissionMode || current.settings.execution.permissionMode,
                    alwaysApprove: false,
                };
                if (!mountedSessionIdsRef.current.has(sessionId)) {
                    const session = await loadGrokSession(
                        sessionId,
                        task.workspace,
                        buildSessionRules(agent, skills),
                        modelProvider.id,
                        buildAcpOptions(execution),
                    );
                    mountedSessionIdsRef.current.add(session.sessionId);
                    taskByProcessIdRef.current.set(session.processId, taskId);
                    taskBySessionIdRef.current.set(session.sessionId, taskId);
                    updateTask(taskId, (value) => ({
                        ...value,
                        runtimeProcessId: session.processId,
                        availableCommands: session.availableCommands,
                        updatedAt: Date.now(),
                    }));
                }
            }
            cancelledTaskIdsRef.current.delete(taskId);
            const shouldQueue = task.engine !== 'headless' && task.status === 'running';
            updateTask(taskId, (value) => ({
                ...value,
                status: 'running',
                error: undefined,
                modelKeyAuthorization: undefined,
                messages: shouldQueue
                    ? value.messages
                    : [...value.messages, { id: createId('message'), role: 'user', content: displayPrompt, createdAt: Date.now() }],
                updatedAt: Date.now(),
            }));
            if (task.engine === 'headless') {
                const model = task.model || current.settings.grokModel;
                const service = await startGrokCliService([
                    ...(model.trim() ? ['--model', model.trim()] : []),
                    '--resume', sessionId,
                    '--output-format', current.settings.execution.outputFormat,
                    '--single', prompt,
                ], task.workspace);
                updateTask(taskId, (value) => ({ ...value, cliServiceId: service.id, updatedAt: Date.now() }));
                const result = await waitForCliService(service.id);
                if (result.exitCode !== 0 && !cancelledTaskIdsRef.current.has(taskId)) throw new Error(result.stderr || '后台任务追问失败');
                const response = redactRuntimeText(extractGrokHeadlessText(result.stdout, current.settings.execution.outputFormat));
                updateTask(taskId, (value) => ({
                    ...value,
                    messages: [...value.messages, { id: createId('message'), role: 'assistant', content: response || '补充任务已完成。', createdAt: Date.now() }],
                    updatedAt: Date.now(),
                }));
            } else {
                await sendGrokPrompt(sessionId, prompt, [], [], shouldQueue);
                if (!shouldQueue) {
                    const info = await getGrokSessionInfo(sessionId).catch(() => null);
                    if (info) updateTask(taskId, (value) => ({
                        ...value,
                        model: info.model || value.model,
                        contextInfo: info.context,
                        updatedAt: Date.now(),
                    }));
                }
            }
            if (task.engine === 'headless' || !shouldQueue) {
                finishForegroundPrompt(taskId, 'completed');
            }
        } catch (error) {
            if (!cancelledTaskIdsRef.current.has(taskId)) {
                const providerId = modelKeyAuthorizationProviderId(error);
                if (providerId) {
                    activePromptCountsRef.current.delete(taskId);
                    updateTask(taskId, (value) => {
                        const lastMessage = value.messages[value.messages.length - 1];
                        const messages = task.engine === 'headless' && lastMessage?.role === 'user' && lastMessage.content === displayPrompt
                            ? value.messages.slice(0, -1)
                            : value.messages;
                        return {
                            ...value,
                            status: 'waiting_authorization',
                            error: undefined,
                            modelKeyAuthorization: { providerId, action: 'follow_up', prompt },
                            messages,
                            updatedAt: Date.now(),
                        };
                    });
                } else {
                    const message = redactRuntimeText(runtimeErrorText(error));
                    finishForegroundPrompt(taskId, 'failed', message);
                }
            }
            throw error;
        }
    }, [finishForegroundPrompt, updateTask]);

    const sendWorkflowCommand = useCallback(async (
        taskId: string,
        action: 'pause' | 'resume' | 'stop' | 'save',
        workflowName: string,
    ) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有可操作的 Grok 会话');
        const command = `/workflow ${action} ${workflowName}`;
        const actionLabel = action === 'pause'
            ? '暂停'
            : action === 'resume'
                ? '恢复'
                : action === 'stop'
                    ? '停止'
                    : '保存';
        await sendFollowUp(taskId, command, `工作流控制：${actionLabel}“${workflowName}”`);
    }, [sendFollowUp]);

    const listTaskWorkflows = useCallback(async (taskId: string): Promise<GrokWorkflowListing[]> => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有可读取 Workflow 的 Grok 会话');
        try {
            await ensureTaskSessionMounted(taskId);
            return await listGrokWorkflows(task.sessionId);
        } catch (error) {
            const providerId = modelKeyAuthorizationProviderId(error);
            if (providerId) {
                updateTask(taskId, (value) => ({
                    ...value,
                    error: undefined,
                    modelKeyAuthorization: { providerId, action: 'context', contextAction: 'workflow' },
                    updatedAt: Date.now(),
                }));
                throw new Error('当前会话需要先解锁本地模型密钥，请点击下方“解锁密钥”后刷新目录');
            }
            throw error;
        }
    }, [ensureTaskSessionMounted, updateTask]);

    const readTaskWorkflow = useCallback(async (taskId: string, workflowName: string): Promise<GrokWorkflowFile> => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有可读取 Workflow 的 Grok 会话');
        await ensureTaskSessionMounted(taskId);
        return readGrokWorkflow(task.sessionId, workflowName);
    }, [ensureTaskSessionMounted]);

    const launchWorkflow = useCallback(async (taskId: string, workflowName: string, args: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有可启动 Workflow 的 Grok 会话');
        const name = workflowName.trim();
        if (!name) throw new Error('请选择要启动的 Workflow');
        const normalizedArgs = args.trim();
        const command = `/workflow ${name}${normalizedArgs ? ` ${normalizedArgs}` : ''}`;
        await sendFollowUp(taskId, command, `启动工作流：“${name}”${normalizedArgs ? '（已附加参数）' : ''}`);
    }, [sendFollowUp]);

    const validateWorkflow = useCallback(async (taskId: string, workflowName: string, args: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有可校验 Workflow 的 Grok 会话');
        const normalizedArgs = args.trim();
        let parsedArgs: unknown = null;
        if (normalizedArgs) {
            try {
                parsedArgs = JSON.parse(normalizedArgs);
            } catch {
                throw new Error('只校验不启动时，运行参数必须是合法 JSON');
            }
        }
        const input = JSON.stringify({
            name: workflowName.trim(),
            args: parsedArgs,
            validate_only: true,
        });
        const prompt = `请只调用 Workflow 工具执行一次运行前校验，不要启动实际运行。必须使用 validate_only=true，参数如下：${input}。完成后只返回校验结果。`;
        await sendFollowUp(taskId, prompt, `只校验 Workflow：“${workflowName.trim()}”`);
    }, [sendFollowUp]);

    const queueAction = useCallback(async (
        taskId: string,
        action: 'remove' | 'edit' | 'reorder' | 'clear' | 'send_now' | 'interject',
        options: { id?: string; expectedVersion?: number; newText?: string; orderedIds?: string[] } = {},
    ) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务没有可操作的 Grok 会话');
        try {
            await applyGrokQueueAction(task.sessionId, action, options);
        } catch (error) {
            const message = redactRuntimeText(runtimeErrorText(error));
            updateTask(taskId, (value) => ({ ...value, error: message, updatedAt: Date.now() }));
            throw error;
        }
    }, [updateTask]);

    const refreshTaskSessionInfo = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有本地会话');
        let info;
        try {
            info = await getGrokSessionInfo(task.sessionId);
        } catch (error) {
            try {
                await ensureTaskSessionMounted(taskId);
                info = await getGrokSessionInfo(task.sessionId);
            } catch (mountError) {
                const providerId = modelKeyAuthorizationProviderId(mountError);
                if (providerId) {
                    updateTask(taskId, (value) => ({
                        ...value,
                        error: undefined,
                        modelKeyAuthorization: { providerId, action: 'context' },
                        updatedAt: Date.now(),
                    }));
                }
                throw mountError;
            }
        }
        updateTask(taskId, (value) => ({
            ...value,
            model: info.model || value.model,
            contextInfo: info.context,
            updatedAt: Date.now(),
        }));
        return info;
    }, [ensureTaskSessionMounted, updateTask]);

    const ensureContextSession = useCallback(async (
        taskId: string,
        contextAction: 'compact' | 'recap' | 'memory',
    ) => {
        try {
            await ensureTaskSessionMounted(taskId);
        } catch (error) {
            const providerId = modelKeyAuthorizationProviderId(error);
            if (providerId) {
                updateTask(taskId, (value) => ({
                    ...value,
                    error: undefined,
                    modelKeyAuthorization: { providerId, action: 'context', contextAction },
                    updatedAt: Date.now(),
                }));
            }
            throw error;
        }
    }, [ensureTaskSessionMounted, updateTask]);

    const compactTask = useCallback(async (taskId: string, userContext?: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有本地会话');
        updateTask(taskId, (value) => upsertTaskActivity(value, {
            id: 'context-compaction-manual',
            title: '整理会话上下文',
            status: '运行中',
            kind: 'context',
        }));
        try {
            await ensureContextSession(taskId, 'compact');
            await compactGrokSession(task.sessionId, userContext);
            updateTask(taskId, (value) => upsertTaskActivity(value, {
                id: 'context-compaction-manual',
                title: '整理会话上下文',
                status: '已完成',
                kind: 'context',
            }));
        } catch (error) {
            updateTask(taskId, (value) => upsertTaskActivity(value, {
                id: 'context-compaction-manual',
                title: '整理会话上下文',
                status: '失败',
                kind: 'context',
                output: redactRuntimeText(runtimeErrorText(error)),
            }));
            throw error;
        }
    }, [ensureContextSession, updateTask]);

    const recapTask = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有本地会话');
        updateTask(taskId, (value) => upsertTaskActivity(value, {
            id: 'session-recap',
            title: '生成会话 Recap',
            status: '运行中',
            kind: 'context',
        }));
        try {
            await ensureContextSession(taskId, 'recap');
            await recapGrokSession(task.sessionId);
        } catch (error) {
            const detail = redactRuntimeText(runtimeErrorText(error));
            const recapUnavailable = /method not found/i.test(detail);
            const unavailable = detail.includes('当前模型连接不支持图像输入') || recapUnavailable;
            updateTask(taskId, (value) => upsertTaskActivity(value, {
                id: 'session-recap',
                title: '生成会话 Recap',
                status: unavailable ? '不可用' : '失败',
                kind: 'context',
                output: recapUnavailable
                    ? '当前安装的内置智能引擎暂未提供 Recap 接口，请更新内置引擎后重启客户端。'
                    : detail,
            }));
            if (!unavailable) throw error;
        }
    }, [ensureContextSession, updateTask]);

    const flushTaskMemory = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有本地会话');
        updateTask(taskId, (value) => upsertTaskActivity(value, {
            id: 'memory-flush',
            title: '刷新会话记忆',
            status: '运行中',
            kind: 'memory',
        }));
        try {
            await ensureContextSession(taskId, 'memory');
            await flushGrokMemory(task.sessionId);
        } catch (error) {
            updateTask(taskId, (value) => upsertTaskActivity(value, {
                id: 'memory-flush',
                title: '刷新会话记忆',
                status: '失败',
                kind: 'memory',
                output: redactRuntimeText(runtimeErrorText(error)),
            }));
            throw error;
        }
    }, [ensureContextSession, updateTask]);

    const refreshTaskBackgroundTasks = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有本地会话');
        const next = await listGrokBackgroundTasks(task.sessionId);
        updateTask(taskId, (value) => ({
            ...value,
            backgroundTasks: next.map((item) => ({
                taskId: item.taskId,
                title: item.displayCommand || item.command || '后台任务',
                status: item.completed ? (item.exitCode && item.exitCode !== 0 ? `退出码 ${item.exitCode}` : '已完成') : '后台运行中',
                command: item.command,
                output: item.output,
                outputFile: item.outputFile,
                kind: item.kind,
                updatedAt: Date.now(),
            })),
            updatedAt: Date.now(),
        }));
        return next;
    }, [updateTask]);

    const killTaskBackgroundTask = useCallback(async (taskId: string, backgroundTaskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有本地会话');
        await killGrokBackgroundTask(task.sessionId, backgroundTaskId);
        await refreshTaskBackgroundTasks(taskId);
    }, [refreshTaskBackgroundTasks]);

    const waitTaskBackgroundTask = useCallback(async (taskId: string, backgroundTaskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有本地会话');
        const deadline = Date.now() + 10 * 60 * 1000;
        while (Date.now() < deadline) {
            const current = await listGrokBackgroundTasks(task.sessionId);
            const item = current.find((value) => value.taskId === backgroundTaskId);
            await refreshTaskBackgroundTasks(taskId);
            if (!item || item.completed) return item;
            await new Promise((resolve) => window.setTimeout(resolve, 800));
        }
        throw new Error('等待后台任务超过 10 分钟');
    }, [refreshTaskBackgroundTasks]);

    const cancelTaskSubagent = useCallback(async (taskId: string, subagentId: string) => {
        await cancelGrokSubagent(subagentId);
        updateTask(taskId, (value) => ({
            ...value,
            subagents: (value.subagents || []).map((item) => item.subagentId === subagentId
                ? { ...item, status: '已取消', updatedAt: Date.now() }
                : item),
            updatedAt: Date.now(),
        }));
    }, [updateTask]);

    const waitTaskSubagent = useCallback(async (taskId: string, subagentId: string) => {
        const deadline = Date.now() + 10 * 60 * 1000;
        while (Date.now() < deadline) {
            const value = await getGrokSubagent(subagentId);
            const status = String(value?.status || value?.state || '').toLowerCase();
            const completed = value?.completed === true || /complete|success|failed|cancel|stop|error|done/.test(status);
            updateTask(taskId, (task) => ({
                ...task,
                subagents: (task.subagents || []).map((item) => item.subagentId === subagentId
                    ? { ...item, status: completed ? (status || '已完成') : '运行中', output: formatToolDetail(value?.output || value?.result || item.output), updatedAt: Date.now() }
                    : item),
                updatedAt: Date.now(),
            }));
            if (completed) return value;
            await new Promise((resolve) => window.setTimeout(resolve, 800));
        }
        throw new Error('等待子智能体超过 10 分钟');
    }, [updateTask]);

    const toggleMcpServer = useCallback(async (name: string, enabled: boolean) => {
        const workspace = snapshotRef.current.settings.workspace;
        await setGrokMcpEnabled(name, enabled, workspace);
        if (workspace) await reloadGrokMcpServers(workspace).catch(() => undefined);
        await refreshMcpServers(workspace);
    }, [refreshMcpServers]);

    const reloadTaskMcp = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前任务还没有本地会话');
        await reloadGrokMcpServers(task.workspace);
        const servers = await refreshMcpServers(task.workspace);
        updateTask(taskId, (value) => ({
            ...value,
            mcpServers: servers.map((server) => ({ name: server.name, transport: server.transport, health: server.health, tools: server.tools })),
            updatedAt: Date.now(),
        }));
    }, [refreshMcpServers, updateTask]);

    const reloadMcpServers = useCallback(async (workspaceOverride?: string) => {
        const workspace = workspaceOverride?.trim() || snapshotRef.current.settings.workspace;
        if (!workspace) throw new Error('请先选择工作区');
        await reloadGrokMcpServers(workspace);
        await refreshMcpServers(workspace);
    }, [refreshMcpServers]);

    const authorizeTaskModel = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        const authorization = task?.modelKeyAuthorization;
        if (!task || !authorization) throw new Error('当前任务不需要模型密钥授权');
        try {
            const provider = await authorizeGrokModelProvider(authorization.providerId);
            const updateProvider = (current: ArkDesktopSnapshot): ArkDesktopSnapshot => ({
                ...current,
                settings: {
                    ...current.settings,
                    modelProviders: current.settings.modelProviders.map((item) => item.id === provider.id
                        ? provider as ArkDesktopModelProvider
                        : item),
                },
            });
            if (authorization.action === 'start') {
                setSnapshot(updateProvider);
                const nextTaskId = await startTask({
                    prompt: task.prompt,
                    workspace: task.workspace,
                    agentId: task.agentId,
                    skillIds: task.skillIds,
                    attachmentPaths: task.attachmentPaths,
                    attachmentGrantIds: task.attachmentGrantIds,
                    automationId: task.automationId,
                });
                setSnapshot((current) => ({
                    ...current,
                    tasks: current.tasks.filter((item) => item.id !== taskId),
                }));
                return nextTaskId;
            }
            if (authorization.action === 'context') {
                setSnapshot((current) => {
                    const next = updateProvider(current);
                    return {
                        ...next,
                        tasks: next.tasks.map((item) => item.id === taskId
                            ? { ...item, modelKeyAuthorization: undefined, error: undefined, updatedAt: Date.now() }
                        : item),
                    };
                });
                if (authorization.contextAction === 'compact') {
                    await compactTask(taskId);
                    return taskId;
                }
                if (authorization.contextAction === 'recap') {
                    await recapTask(taskId);
                    return taskId;
                }
                if (authorization.contextAction === 'memory') {
                    await flushTaskMemory(taskId);
                    return taskId;
                }
                if (authorization.contextAction === 'workflow') {
                    await ensureTaskSessionMounted(taskId);
                    return taskId;
                }
                await refreshTaskSessionInfo(taskId);
                return taskId;
            }
            setSnapshot((current) => {
                const next = updateProvider(current);
                return {
                    ...next,
                    tasks: next.tasks.map((item) => item.id === taskId
                        ? { ...item, modelKeyAuthorization: undefined, error: undefined, updatedAt: Date.now() }
                        : item),
                };
            });
            await sendFollowUp(taskId, authorization.prompt || '');
            return taskId;
        } catch (error) {
            const message = redactRuntimeText(runtimeErrorText(error));
            updateTask(taskId, (value) => ({ ...value, error: message, updatedAt: Date.now() }));
            throw error;
        }
    }, [compactTask, ensureTaskSessionMounted, flushTaskMemory, recapTask, refreshTaskSessionInfo, sendFollowUp, startTask, updateTask]);

    const cancelTask = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task) return;
        cancelledTaskIdsRef.current.add(taskId);
        activePromptCountsRef.current.delete(taskId);
        if (task.engine === 'headless' && task.cliServiceId) {
            await stopGrokCliService(task.cliServiceId);
        } else if (task.sessionId) {
            await cancelGrokPrompt(task.sessionId);
        }
        updateTask(taskId, (value) => ({
            ...settleForegroundActivities(value, 'cancelled'),
            error: undefined,
            modelKeyAuthorization: undefined,
        }));
        setPermissions((current) => current.filter((item) => item.taskId !== taskId));
        setUserQuestions((current) => current.filter((item) => item.taskId !== taskId));
        setPlanApprovals((current) => current.filter((item) => item.taskId !== taskId));
    }, [updateTask]);

    const rewindTaskFiles = useCallback(async (taskId: string, promptIndex: number, force = false) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前会话尚未建立，无法撤销文件修改');
        if (task.engine === 'headless') throw new Error('后台模式暂不支持按会话检查点撤销');
        if (task.status === 'running' || task.status === 'waiting_authorization') {
            throw new Error('请等待当前任务结束或先停止任务，再撤销文件修改');
        }
        const current = snapshotRef.current;
        const agent = current.agents.find((item) => item.id === task.agentId)
            || current.agents.find((item) => item.enabled);
        if (!agent) throw new Error('该历史任务使用的 Agent 已不存在');
        const skills = current.skills.filter((skill) => task.skillIds.includes(skill.id) && skill.enabled);
        const execution = {
            ...current.settings.execution,
            permissionMode: task.permissionMode || current.settings.execution.permissionMode,
            alwaysApprove: false,
        };
        const model = task.model || current.settings.grokModel;
        if (!model) throw new Error('该历史任务没有可用的模型连接元数据');
        const requestRewind = (shouldForce: boolean) => rewindGrokFiles(
            task.sessionId,
            promptIndex,
            task.workspace,
            model,
            buildSessionRules(agent, skills),
            buildAcpOptions(execution),
            shouldForce,
        );
        let result = await requestRewind(force);
        const conflicts = result.conflicts || [];
        if (!force) {
            if (conflicts.length > 0) {
                return { requiresConfirmation: true, conflicts };
            }
            result = await requestRewind(true);
        }
        if (!result.success) {
            throw new Error(result.error || '撤销文件修改失败');
        }
        const userMessages = task.messages.filter((message) => message.role === 'user');
        const rewindStartedAt = userMessages[promptIndex]?.createdAt || 0;
        const rewoundAt = Date.now();
        updateTask(taskId, (value) => ({
            ...value,
            tools: value.tools.map((tool) => (
                tool.fileChanges?.length && (tool.startedAt || tool.updatedAt) >= rewindStartedAt
                    ? { ...tool, changesRevertedAt: rewoundAt, updatedAt: rewoundAt }
                    : tool
            )),
            error: undefined,
            updatedAt: rewoundAt,
        }));
        return { requiresConfirmation: false, conflicts: [] };
    }, [updateTask]);

    const permission = useMemo(
        () => permissions.find((item) => item.taskId === activeTaskId) || permissions[0] || null,
        [activeTaskId, permissions],
    );

    const userQuestion = useMemo(
        () => userQuestions.find((item) => item.taskId === activeTaskId) || userQuestions[0] || null,
        [activeTaskId, userQuestions],
    );

    const planApproval = useMemo(
        () => planApprovals.find((item) => item.taskId === activeTaskId) || planApprovals[0] || null,
        [activeTaskId, planApprovals],
    );

    const answerPermission = useCallback(async (optionId?: string) => {
        if (!permission) return;
        try {
            await respondGrokPermission(permission.sessionId, permission.requestId, optionId);
            const requestKey = JSON.stringify(permission.requestId);
            setPermissions((current) => current.filter((item) => (
                item.sessionId !== permission.sessionId || JSON.stringify(item.requestId) !== requestKey
            )));
        } catch (error) {
            const message = redactRuntimeText(error instanceof Error ? error.message : String(error));
            updateTask(permission.taskId, (task) => ({ ...task, error: message, updatedAt: Date.now() }));
        }
    }, [permission, updateTask]);

    const answerUserQuestion = useCallback(async (response: Record<string, unknown>) => {
        if (!userQuestion) return;
        try {
            await respondGrokUserQuestion(userQuestion.sessionId, userQuestion.requestId, response);
            const requestKey = JSON.stringify(userQuestion.requestId);
            setUserQuestions((current) => current.filter((item) => (
                item.sessionId !== userQuestion.sessionId || JSON.stringify(item.requestId) !== requestKey
            )));
        } catch (error) {
            const message = redactRuntimeText(error instanceof Error ? error.message : String(error));
            updateTask(userQuestion.taskId, (task) => ({ ...task, error: message, updatedAt: Date.now() }));
        }
    }, [updateTask, userQuestion]);

    const answerPlanApproval = useCallback(async (response: Record<string, unknown>) => {
        if (!planApproval) return;
        try {
            await respondGrokPlanApproval(planApproval.sessionId, planApproval.requestId, response);
            const requestKey = JSON.stringify(planApproval.requestId);
            setPlanApprovals((current) => current.filter((item) => (
                item.sessionId !== planApproval.sessionId || JSON.stringify(item.requestId) !== requestKey
            )));
        } catch (error) {
            const message = redactRuntimeText(error instanceof Error ? error.message : String(error));
            updateTask(planApproval.taskId, (task) => ({ ...task, error: message, updatedAt: Date.now() }));
        }
    }, [planApproval, updateTask]);

    const addModel = useCallback(async (model: string) => {
        const modelId = model.trim();
        await applyGrokModel(modelId);
        setSnapshot((current) => ({
            ...current,
            settings: {
                ...current.settings,
                grokModel: modelId,
                modelOptions: Array.from(new Set([...current.settings.modelOptions, modelId])),
            },
        }));
    }, []);

    const selectModel = useCallback(async (model: string) => {
        const modelId = model.trim();
        const provider = snapshotRef.current.settings.modelProviders.find((item) => item.id === modelId && item.enabled);
        if (!provider) throw new Error('该内网模型连接已不存在或已停用');
        await applyGrokModel(modelId);
        setSnapshot((current) => ({
            ...current,
            settings: {
                ...current.settings,
                grokModel: modelId,
                modelOptions: current.settings.modelProviders.filter((item) => item.enabled).map((item) => item.id),
            },
        }));
    }, []);

    const saveModelProvider = useCallback(async (input: GrokModelProviderInput): Promise<GrokModelProvider> => {
        const provider = await saveGrokModelProvider(input);
        setSnapshot((current) => ({
            ...current,
            settings: {
                ...current.settings,
                grokModel: provider.id,
                modelOptions: Array.from(new Set([...current.settings.modelOptions, provider.id])),
                modelProviders: [
                    ...current.settings.modelProviders.filter((item) => item.id !== provider.id),
                    provider as ArkDesktopModelProvider,
                ],
            },
        }));
        return provider;
    }, []);

    const removeModelProvider = useCallback(async (providerId: string) => {
        await deleteGrokModelProvider(providerId);
        setSnapshot((current) => {
            const modelProviders = current.settings.modelProviders.filter((provider) => provider.id !== providerId);
            const fallbackModel = current.settings.grokModel === providerId ? modelProviders[0]?.id || '' : current.settings.grokModel;
            return {
                ...current,
                settings: {
                    ...current.settings,
                    grokModel: fallbackModel,
                    modelOptions: current.settings.modelOptions.filter((model) => model !== providerId),
                    modelProviders,
                },
            };
        });
    }, []);

    const switchTaskModel = useCallback(async (taskId: string, model: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('当前会话尚未建立，无法切换模型');
        if (task.engine === 'headless') throw new Error('后台模式会话仅支持在发起新任务时切换模型');
        const modelId = model.trim();
        if (!modelId) throw new Error('请选择模型');
        try {
            const current = snapshotRef.current;
            const agent = current.agents.find((item) => item.id === task.agentId)
                || current.agents.find((item) => item.enabled);
            if (!agent) throw new Error('该历史任务使用的 Agent 已不存在');
            const skills = current.skills.filter((skill) => task.skillIds.includes(skill.id) && skill.enabled);
            const execution = {
                ...current.settings.execution,
                permissionMode: task.permissionMode || current.settings.execution.permissionMode,
                alwaysApprove: false,
            };
            const modelProvider = resolveModelProvider(current, task.model || current.settings.grokModel);
            if (!modelProvider) throw new Error(`历史会话使用的模型连接“${task.model || current.settings.grokModel}”不存在，请在设置中配置对应连接`);
            if (!modelProvider.enabled) throw new Error(`模型连接“${modelProvider.name}”已停用`);
            const session = await loadGrokSession(
                task.sessionId,
                task.workspace,
                buildSessionRules(agent, skills),
                modelProvider.id,
                buildAcpOptions(execution),
            );
            mountedSessionIdsRef.current.add(session.sessionId);
            taskByProcessIdRef.current.set(session.processId, taskId);
            taskBySessionIdRef.current.set(session.sessionId, taskId);
            await setGrokSessionModel(task.sessionId, modelId);
            updateTask(taskId, (value) => ({
                ...value,
                model: modelId,
                runtimeProcessId: session.processId,
                availableCommands: session.availableCommands,
                error: undefined,
                updatedAt: Date.now(),
            }));
        } catch (error) {
            const message = redactRuntimeText(error instanceof Error ? error.message : String(error));
            updateTask(taskId, (value) => ({ ...value, error: message, updatedAt: Date.now() }));
            throw error;
        }
    }, [updateTask]);

    const setTaskPermissionMode = useCallback((taskId: string, permissionMode: GrokExecutionSettings['permissionMode']) => {
        updateTask(taskId, (task) => ({
            ...task,
            permissionMode,
            alwaysApprove: false,
            updatedAt: Date.now(),
        }));
    }, [updateTask]);

    const renameTask = useCallback(async (taskId: string, title: string) => {
        const normalized = title.trim().slice(0, 80);
        if (!normalized) throw new Error('会话名称不能为空');
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task) throw new Error('会话不存在');
        if (task.sessionId) {
            await renameGrokSession(task.sessionId, normalized, task.workspace);
            await refreshRemoteSessions(task.workspace).catch(() => undefined);
        }
        updateTask(taskId, (task) => ({ ...task, title: normalized }));
    }, [refreshRemoteSessions, updateTask]);

    const toggleTaskPin = useCallback((taskId: string) => {
        updateTask(taskId, (task) => ({
            ...task,
            pinnedAt: task.pinnedAt ? undefined : Date.now(),
        }));
    }, [updateTask]);

    const archiveTask = useCallback((taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task) throw new Error('会话不存在');
        if (task.status === 'running' || task.status === 'waiting_authorization') {
            throw new Error('请先停止正在执行的会话');
        }
        updateTask(taskId, (value) => ({ ...value, archivedAt: Date.now() }));
        setActiveTaskId((current) => current === taskId ? null : current);
    }, [updateTask]);

    const restoreTask = useCallback((taskId: string) => {
        updateTask(taskId, (task) => ({ ...task, archivedAt: undefined }));
    }, [updateTask]);

    const deleteTask = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task) return;
        if (task.status === 'running' || task.status === 'waiting_authorization') {
            throw new Error('请先停止正在执行的会话');
        }
        if (task.sessionId) {
            await releaseGrokSession(task.sessionId);
            try {
                await deleteGrokSession(task.sessionId, task.workspace);
            } catch (error) {
                // Keep the CLI fallback for older bundled binaries that do not
                // expose x.ai/session/delete yet.
                const result = await runGrokCli(['sessions', 'delete', task.sessionId], undefined, 30);
                const missing = /not found|no session|不存在|未找到/i.test(`${result.stderr}\n${result.stdout}`);
                if (!result.success && !missing) {
                    throw error instanceof Error ? error : new Error(redactRuntimeText(result.stderr || result.stdout || '删除本地会话失败'));
                }
            }
            await refreshRemoteSessions(task.workspace).catch(() => undefined);
        }
        setSnapshot((current) => ({
            ...current,
            tasks: current.tasks.filter((item) => item.id !== taskId),
        }));
        setActiveTaskId((current) => current === taskId ? null : current);
        setPermissions((current) => current.filter((item) => item.taskId !== taskId));
        setUserQuestions((current) => current.filter((item) => item.taskId !== taskId));
        setPlanApprovals((current) => current.filter((item) => item.taskId !== taskId));
        if (task.runtimeProcessId) taskByProcessIdRef.current.delete(task.runtimeProcessId);
        if (task.sessionId) {
            mountedSessionIdsRef.current.delete(task.sessionId);
            taskBySessionIdRef.current.delete(task.sessionId);
        }
    }, [refreshRemoteSessions]);

    const deleteScheduledTask = useCallback(async (ownerTaskId: string, scheduledTaskId: string) => {
        const ownerTask = snapshotRef.current.tasks.find((item) => item.id === ownerTaskId);
        if (!ownerTask?.sessionId) throw new Error('关联会话尚未建立，无法停止循环');
        if (!ownerTask.runtimeProcessId) throw new Error('关联会话未连接，请先打开会话并发送一条消息后再停止循环');
        const deleted = await deleteGrokScheduledTask(ownerTask.sessionId, scheduledTaskId);
        if (!deleted) throw new Error('该会话循环已经停止或不存在');
        updateTask(ownerTaskId, (task) => ({
            ...task,
            scheduledTasks: (task.scheduledTasks || []).filter((item) => item.id !== scheduledTaskId),
            updatedAt: Date.now(),
        }));
    }, [updateTask]);

    const revealWorkspace = useCallback(async (workspace: string) => {
        await openGrokWorkspace(workspace);
    }, []);

    const availableCommands = useMemo(() => {
        const commands = new Map<string, ArkDesktopSlashCommand>();
        discoveredCommands.forEach((command) => commands.set(command.name, command));
        snapshot.tasks.forEach((task) => {
            task.availableCommands?.forEach((command) => commands.set(command.name, command));
        });
        return Array.from(commands.values());
    }, [discoveredCommands, snapshot.tasks]);

    const activeTask = useMemo(
        () => snapshot.tasks.find((task) => task.id === activeTaskId) || null,
        [activeTaskId, snapshot.tasks],
    );

    const resetAll = useCallback(() => {
        const defaults = resetArkDesktopSnapshot();
        setSnapshot(defaults);
        setActiveTaskId(null);
        setPermissions([]);
        setUserQuestions([]);
        setPlanApprovals([]);
        taskByProcessIdRef.current.clear();
        taskBySessionIdRef.current.clear();
        setRuntimeError('');
    }, []);

    const dismissTaskError = useCallback((taskId: string) => {
        updateTask(taskId, (task) => ({ ...task, error: undefined, updatedAt: Date.now() }));
    }, [updateTask]);

    return {
        snapshot,
        setSnapshot,
        runtimeStatus,
        runtimeError,
        setRuntimeError: (message: string) => setRuntimeError(redactRuntimeText(message)),
        refreshRuntimeStatus,
        modelCatalog,
        refreshModelCatalog,
        remoteSessions,
        remoteSessionsLoading,
        remoteSessionsError,
        refreshRemoteSessions,
        openRemoteSession,
        runtimeDiagnostics,
        refreshRuntimeDiagnostics,
        mcpServers,
        refreshMcpServers,
        selectWorkspace,
        pickWorkspace,
        addWorkspace,
        setDefaultWorkspace,
        removeWorkspace,
        revealWorkspace,
        selectAttachments,
        startTask,
        prepareEngine,
        sendFollowUp,
        sendWorkflowCommand,
        listTaskWorkflows,
        readTaskWorkflow,
        launchWorkflow,
        validateWorkflow,
        refreshTaskSessionInfo,
        compactTask,
        recapTask,
        flushTaskMemory,
        refreshTaskBackgroundTasks,
        killTaskBackgroundTask,
        waitTaskBackgroundTask,
        cancelTaskSubagent,
        waitTaskSubagent,
        reloadTaskMcp,
        reloadMcpServers,
        toggleMcpServer,
        queueAction,
        authorizeTaskModel,
        cancelTask,
        rewindTaskFiles,
        permission,
        answerPermission,
        userQuestion,
        answerUserQuestion,
        planApproval,
        answerPlanApproval,
        addModel,
        selectModel,
        saveModelProvider,
        removeModelProvider,
        refreshModelProviders,
        switchTaskModel,
        setTaskPermissionMode,
        renameTask,
        toggleTaskPin,
        archiveTask,
        restoreTask,
        deleteTask,
        deleteScheduledTask,
        availableCommands,
        discoveredPlugins,
        capabilitiesLoading,
        capabilitiesError,
        refreshCapabilities,
        reloadPluginCapabilities,
        activeTask,
        activeTaskId,
        setActiveTaskId,
        dismissTaskError,
        resetAll,
    };
};

export type ArkDesktopRuntime = ReturnType<typeof useArkDesktopRuntime>;
export type { StartTaskInput };
