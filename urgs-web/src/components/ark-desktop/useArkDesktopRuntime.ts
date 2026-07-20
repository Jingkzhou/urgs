import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { isDesktopRuntime } from '@/config';
import {
    applyGrokModel,
    authorizeGrokModelProvider,
    cancelGrokPrompt,
    chooseGrokAttachments,
    chooseGrokWorkspace,
    createGrokSession,
    deleteGrokModelProvider,
    getGrokRuntimeStatus,
    loadGrokSession,
    listGrokAvailableCommands,
    listGrokCliServices,
    listGrokModelProviders,
    runGrokCli,
    respondGrokPermission,
    prepareGrokRuntime,
    startGrokCliService,
    stopGrokCliService,
    sendGrokPrompt,
    setGrokSessionModel,
    saveGrokModelProvider,
    startGrokLogin,
    subscribeGrokEvents,
    type GrokBridgeEvent,
    type GrokAcpOptions,
    type GrokRuntimeStatus,
    type GrokModelProvider,
    type GrokModelProviderInput,
} from '@/services/grokDesktop';
import { loadArkDesktopSnapshot, resetArkDesktopSnapshot, saveArkDesktopSnapshot } from './storage';
import type {
    ArkDesktopAgent,
    ArkDesktopAutomation,
    ArkDesktopPermissionRequest,
    ArkDesktopSkill,
    ArkDesktopSnapshot,
    ArkDesktopSlashCommand,
    ArkDesktopTask,
    ArkDesktopModelProvider,
    GrokExecutionSettings,
} from './types';
import { buildGrokHeadlessArguments, extractGrokHeadlessSessionId, extractGrokHeadlessText } from './execution';

interface StartTaskInput {
    prompt: string;
    agentId?: string;
    skillIds?: string[];
    attachmentPaths?: string[];
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

const redactRuntimeText = (value: string) => value
    .replace(/\bgrok(?:\s+build)?\b/gi, '内置智能引擎')
    .replace(/\bxai\b/gi, '服务');

const extractText = (update: Record<string, any>) =>
    update?.content?.text || update?.content?.content?.text || update?.text || '';

const formatToolDetail = (value: unknown) => {
    if (value === undefined || value === null || value === '') return undefined;
    const text = typeof value === 'string'
        ? value
        : Array.isArray(value)
            ? value.map((item) => item?.text || item?.content?.text || JSON.stringify(item)).join('\n')
            : JSON.stringify(value, null, 2);
    return redactRuntimeText(text).slice(0, 12_000);
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
    alwaysApprove: execution.alwaysApprove,
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

const findUniqueHistoricalSessionId = async (workspace: string, firstPrompt: string) => {
    const query = firstPrompt.trim();
    if (!query) return undefined;
    const result = await runGrokCli(['sessions', 'search', '--limit', '5', query], workspace, 30);
    if (!result.success) return undefined;
    const sessionIds = Array.from(new Set(
        result.stdout.match(/\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b/gi) || [],
    ));
    return sessionIds.length === 1 ? sessionIds[0] : undefined;
};

export const useArkDesktopRuntime = () => {
    const [snapshot, setSnapshot] = useState<ArkDesktopSnapshot>(loadArkDesktopSnapshot);
    const [runtimeStatus, setRuntimeStatus] = useState<GrokRuntimeStatus | null>(null);
    const [discoveredCommands, setDiscoveredCommands] = useState<ArkDesktopSlashCommand[]>([]);
    const [activeTaskId, setActiveTaskId] = useState<string | null>(null);
    const [permissions, setPermissions] = useState<ArkDesktopPermissionRequest[]>([]);
    const [runtimeError, setRuntimeError] = useState('');
    const cancelledTaskIdsRef = useRef(new Set<string>());
    const taskByProcessIdRef = useRef(new Map<string, string>());
    const taskBySessionIdRef = useRef(new Map<string, string>());
    const snapshotRef = useRef(snapshot);

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

    const refreshRuntimeStatus = useCallback(async () => {
        if (!isDesktopRuntime()) return;
        try {
            setRuntimeError('');
            setRuntimeStatus(await getGrokRuntimeStatus());
        } catch (error) {
            setRuntimeError(redactRuntimeText(error instanceof Error ? error.message : '无法检测内置智能引擎'));
        }
    }, []);

    const refreshModelProviders = useCallback(async () => {
        if (!isDesktopRuntime()) return;
        const modelProviders = await listGrokModelProviders();
        setSnapshot((current) => ({
            ...current,
            settings: {
                ...current.settings,
                modelProviders,
                modelOptions: Array.from(new Set([
                    ...current.settings.modelOptions,
                    ...modelProviders.map((provider) => provider.id),
                ])),
            },
        }));
    }, []);

    useEffect(() => {
        const workspace = snapshot.settings.workspace;
        if (!isDesktopRuntime() || !runtimeStatus?.available || !workspace) {
            setDiscoveredCommands([]);
            return undefined;
        }
        let cancelled = false;
        void listGrokAvailableCommands(workspace)
            .then((commands) => {
                if (!cancelled) setDiscoveredCommands(commands);
            })
            .catch((error) => {
                if (!cancelled) {
                    setDiscoveredCommands([]);
                    setRuntimeError(redactRuntimeText(`加载会话命令失败：${runtimeErrorText(error)}`));
                }
            });
        return () => {
            cancelled = true;
        };
    }, [runtimeStatus?.available, snapshot.settings.workspace]);

    const handleGrokEvent = useCallback((event: GrokBridgeEvent) => {
        const processId = eventProcessId(event);
        const sessionId = eventSessionId(event);
        const taskId = taskByProcessIdRef.current.get(processId)
            || taskBySessionIdRef.current.get(sessionId)
            || snapshotRef.current.tasks.find((task) => (
                (processId && task.runtimeProcessId === processId)
                || (sessionId && task.sessionId === sessionId)
            ))?.id;
        if (event.eventType === 'session_update' && taskId) {
            const params = event.payload?.params || event.payload;
            const update = params?.update || params?.sessionUpdate || {};
            const updateType = update?.sessionUpdate;
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
            if (updateType === 'agent_message_chunk') {
                const chunk = extractText(update);
                if (!chunk) return;
                updateTask(taskId, (task) => {
                    const messages = task.messages.slice();
                    const last = messages[messages.length - 1];
                    if (last?.role === 'assistant') {
                        messages[messages.length - 1] = { ...last, content: `${last.content}${chunk}` };
                    } else {
                        messages.push({ id: createId('message'), role: 'assistant', content: chunk, createdAt: Date.now() });
                    }
                    return { ...task, messages, updatedAt: Date.now() };
                });
                return;
            }
            if (updateType === 'tool_call' || updateType === 'tool_call_update') {
                const id = String(update.toolCallId || update.toolCall?.toolCallId || createId('tool'));
                updateTask(taskId, (task) => {
                    const tools = task.tools.slice();
                    const existingIndex = tools.findIndex((tool) => tool.id === id);
                    const input = formatToolDetail(update.rawInput ?? update.toolCall?.rawInput);
                    const output = formatToolDetail(update.rawOutput ?? update.content ?? update.toolCall?.content);
                    const nextTool = {
                        id,
                        title: redactRuntimeText(update.title || update.toolCall?.title || '本地工具调用'),
                        status: statusLabel(update.status),
                        kind: update.kind || update.toolCall?.kind,
                        ...(input ? { input } : {}),
                        ...(output ? { output } : {}),
                        startedAt: existingIndex >= 0 ? tools[existingIndex].startedAt || tools[existingIndex].updatedAt : Date.now(),
                        updatedAt: Date.now(),
                    };
                    if (existingIndex >= 0) tools[existingIndex] = { ...tools[existingIndex], ...nextTool };
                    else tools.push(nextTool);
                    return { ...task, tools, updatedAt: Date.now() };
                });
                return;
            }
            if (updateType === 'retry_state') {
                const attempt = Number(update.attempt || 0);
                const maxRetries = Number(update.max_retries || 0);
                const reason = redactRuntimeText(String(update.reason || '模型服务暂时不可用'));
                updateTask(taskId, (task) => {
                    const tools = task.tools.filter((tool) => tool.id !== 'inference-retry');
                    tools.push({
                        id: 'inference-retry',
                        title: `模型请求重试 ${attempt}${maxRetries ? `/${maxRetries}` : ''}`,
                        status: reason,
                        kind: 'inference',
                        startedAt: Date.now(),
                        updatedAt: Date.now(),
                    });
                    return { ...task, tools, updatedAt: Date.now() };
                });
            }
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
            setPermissions((current) => current.filter((item) => item.taskId !== taskId));
            updateTask(taskId, (task) => task.runtimeProcessId === processId && task.status === 'running'
                ? { ...task, status: 'failed', error: '本地任务进程已退出', updatedAt: Date.now() }
                : task);
        }

        if (event.eventType === 'login_completed') {
            void refreshRuntimeStatus();
        }
    }, [refreshRuntimeStatus, updateTask]);

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

    const selectWorkspace = useCallback(async () => {
        const selected = await chooseGrokWorkspace();
        if (!selected) return '';
        setSnapshot((current) => ({ ...current, settings: { ...current.settings, workspace: selected } }));
        return selected;
    }, []);

    const selectAttachments = useCallback(async () => chooseGrokAttachments(), []);

    const startLogin = useCallback(async (method: 'browser' | 'oauth' | 'device' = 'browser') => {
        setRuntimeError('');
        await startGrokLogin(method);
    }, []);

    const startTask = useCallback(async ({
        prompt,
        agentId,
        skillIds = [],
        attachmentPaths = [],
        automationId,
    }: StartTaskInput) => {
        const current = snapshotRef.current;
        const workspace = current.settings.workspace;
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
            engine: current.settings.execution.engine,
            model: current.settings.grokModel || undefined,
            permissionMode: current.settings.execution.permissionMode,
            alwaysApprove: current.settings.execution.alwaysApprove,
            status: 'running',
            messages: [{ id: createId('message'), role: 'user', content: effectivePrompt, createdAt: now }],
            tools: [],
            automationId,
            createdAt: now,
            updatedAt: now,
        };
        setSnapshot((value) => ({ ...value, tasks: [task, ...value.tasks].slice(0, 50) }));
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
                    await sendGrokPrompt(session.sessionId, buildTaskPrompt(effectivePrompt, attachmentPaths));
                }
                updateTask(taskId, (value) => cancelledTaskIdsRef.current.has(taskId)
                    ? value
                    : { ...value, status: 'completed', updatedAt: Date.now() });
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
                        updateTask(taskId, (value) => ({
                            ...value,
                            status: 'waiting_authorization',
                            error: undefined,
                            modelKeyAuthorization: { providerId, action: 'start' },
                            updatedAt: Date.now(),
                        }));
                    } else {
                        const message = redactRuntimeText(runtimeErrorText(error));
                        updateTask(taskId, (value) => ({ ...value, status: 'failed', error: message, updatedAt: Date.now() }));
                    }
                }
            }
        })();
        return taskId;
    }, [refreshModelProviders, runtimeStatus, updateTask]);

    const prepareEngine = useCallback(async () => {
        const current = snapshotRef.current;
        const workspace = current.settings.workspace;
        const provider = current.settings.modelProviders.find((item) => item.id === current.settings.grokModel);
        if (!isDesktopRuntime() || !runtimeStatus?.available || !workspace || !provider?.enabled || !provider.hasApiKey) return;
        setRuntimeError('');
        const execution = current.settings.execution;
        await prepareGrokRuntime(workspace, provider.id, buildAcpOptions(execution));
    }, [runtimeStatus]);

    const sendFollowUp = useCallback(async (taskId: string, prompt: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task) throw new Error('历史任务不存在');
        try {
            const current = snapshotRef.current;
            const sessionId = task.sessionId
                || await findUniqueHistoricalSessionId(task.workspace, task.prompt);
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
                const skills = current.skills.filter((skill) => task.skillIds.includes(skill.id) && skill.enabled);
                const execution = {
                    ...current.settings.execution,
                    permissionMode: task.permissionMode || current.settings.execution.permissionMode,
                    alwaysApprove: task.alwaysApprove ?? current.settings.execution.alwaysApprove,
                };
                const session = await loadGrokSession(
                    sessionId,
                    task.workspace,
                    buildSessionRules(agent, skills),
                    task.model || current.settings.grokModel,
                    buildAcpOptions(execution),
                );
                taskByProcessIdRef.current.set(session.processId, taskId);
                taskBySessionIdRef.current.set(session.sessionId, taskId);
                updateTask(taskId, (value) => ({
                    ...value,
                    runtimeProcessId: session.processId,
                    availableCommands: session.availableCommands,
                    updatedAt: Date.now(),
                }));
            }
            cancelledTaskIdsRef.current.delete(taskId);
            updateTask(taskId, (value) => ({
                ...value,
                status: 'running',
                error: undefined,
                modelKeyAuthorization: undefined,
                messages: [...value.messages, { id: createId('message'), role: 'user', content: prompt, createdAt: Date.now() }],
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
                await sendGrokPrompt(sessionId, prompt);
            }
            updateTask(taskId, (value) => cancelledTaskIdsRef.current.has(taskId)
                ? value
                : { ...value, status: 'completed', updatedAt: Date.now() });
        } catch (error) {
            if (!cancelledTaskIdsRef.current.has(taskId)) {
                const providerId = modelKeyAuthorizationProviderId(error);
                if (providerId) {
                    updateTask(taskId, (value) => {
                        const lastMessage = value.messages[value.messages.length - 1];
                        const messages = task.engine === 'headless' && lastMessage?.role === 'user' && lastMessage.content === prompt
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
                    updateTask(taskId, (value) => ({ ...value, status: 'failed', error: message, updatedAt: Date.now() }));
                }
            }
            throw error;
        }
    }, [updateTask]);

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
                    agentId: task.agentId,
                    skillIds: task.skillIds,
                    attachmentPaths: task.attachmentPaths,
                    automationId: task.automationId,
                });
                setSnapshot((current) => ({
                    ...current,
                    tasks: current.tasks.filter((item) => item.id !== taskId),
                }));
                return nextTaskId;
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
    }, [sendFollowUp, startTask, updateTask]);

    const cancelTask = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task) return;
        cancelledTaskIdsRef.current.add(taskId);
        if (task.engine === 'headless' && task.cliServiceId) {
            await stopGrokCliService(task.cliServiceId);
        } else if (task.sessionId) {
            await cancelGrokPrompt(task.sessionId);
        }
        updateTask(taskId, (value) => ({
            ...value,
            status: 'cancelled',
            error: undefined,
            modelKeyAuthorization: undefined,
            updatedAt: Date.now(),
        }));
        setPermissions((current) => current.filter((item) => item.taskId !== taskId));
    }, [updateTask]);

    const permission = useMemo(
        () => permissions.find((item) => item.taskId === activeTaskId) || permissions[0] || null,
        [activeTaskId, permissions],
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
                alwaysApprove: task.alwaysApprove ?? current.settings.execution.alwaysApprove,
            };
            const session = await loadGrokSession(
                task.sessionId,
                task.workspace,
                buildSessionRules(agent, skills),
                task.model || current.settings.grokModel,
                buildAcpOptions(execution),
            );
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
        startLogin,
        selectWorkspace,
        selectAttachments,
        startTask,
        prepareEngine,
        sendFollowUp,
        authorizeTaskModel,
        cancelTask,
        permission,
        answerPermission,
        addModel,
        selectModel,
        saveModelProvider,
        removeModelProvider,
        refreshModelProviders,
        switchTaskModel,
        setTaskPermissionMode,
        availableCommands,
        activeTask,
        activeTaskId,
        setActiveTaskId,
        dismissTaskError,
        resetAll,
    };
};

export type ArkDesktopRuntime = ReturnType<typeof useArkDesktopRuntime>;
export type { StartTaskInput };
