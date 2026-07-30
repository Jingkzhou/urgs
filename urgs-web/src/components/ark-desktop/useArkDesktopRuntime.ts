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
    listGrokCliServices,
    listGrokModelProviders,
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
} from '@/services/grokDesktop';
import { loadArkDesktopSnapshot, resetArkDesktopSnapshot, saveArkDesktopSnapshot } from './storage';
import type {
    ArkDesktopAgent,
    ArkDesktopAutomation,
    ArkDesktopPermissionRequest,
    ArkDesktopPlanStep,
    ArkDesktopPlanApprovalRequest,
    ArkDesktopUserQuestionRequest,
    ArkDesktopSkill,
    ArkDesktopSnapshot,
    ArkDesktopSlashCommand,
    ArkDesktopTask,
    ArkDesktopTaskStatus,
    ArkDesktopToolActivity,
    ArkDesktopModelProvider,
    GrokExecutionSettings,
} from './types';
import { buildGrokHeadlessArguments, extractGrokHeadlessSessionId, extractGrokHeadlessText } from './execution';

interface StartTaskInput {
    prompt: string;
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

const redactRuntimeText = (value: string) => value
    .replace(/\bgrok(?:\s+build)?\b/gi, '内置智能引擎')
    .replace(/\bxai\b/gi, '服务');

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

const statusLabel = (status?: string) => {
    switch (status) {
        case 'pending': return '等待中';
        case 'in_progress': return '运行中';
        case 'completed': return '已完成';
        case 'failed': return '失败';
        default: return status || '运行中';
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

const isSettledActivity = (status: string) => /已完成|完成|成功|失败|取消|退出码|completed|success|failed|cancelled|canceled|done/i.test(status);

const settleForegroundActivities = (
    task: ArkDesktopTask,
    terminalStatus: ArkDesktopTaskStatus,
) => {
    const nextStatus = terminalStatus === 'failed' ? '失败' : terminalStatus === 'cancelled' ? '已取消' : '已完成';
    const tools = task.tools.map((tool) => {
        if (isSettledActivity(tool.status) || ['background_task', 'monitor', 'goal'].includes(tool.kind || '')) return tool;
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
    '多阶段任务必须使用计划工具维护 3 至 7 个可执行阶段；开始、完成或跳过每个阶段时立即更新状态，不要只在普通消息中口头描述进度。',
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
    const [userQuestions, setUserQuestions] = useState<ArkDesktopUserQuestionRequest[]>([]);
    const [planApprovals, setPlanApprovals] = useState<ArkDesktopPlanApprovalRequest[]>([]);
    const [runtimeError, setRuntimeError] = useState('');
    const cancelledTaskIdsRef = useRef(new Set<string>());
    const taskByProcessIdRef = useRef(new Map<string, string>());
    const taskBySessionIdRef = useRef(new Map<string, string>());
    const subagentBySessionIdRef = useRef(new Map<string, string>());
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

    const handleGrokEvent = useCallback((event: GrokBridgeEvent) => {
        const processId = eventProcessId(event);
        const sessionId = eventSessionId(event);
        const taskId = taskBySessionIdRef.current.get(sessionId)
            || taskByProcessIdRef.current.get(processId)
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
            if (updateType === 'agent_message_chunk' || updateType === 'message_delta') {
                const chunk = extractText(update);
                if (!chunk) return;
                const subagentId = updateType === 'message_delta'
                    ? subagentBySessionIdRef.current.get(sessionId)
                    : undefined;
                if (subagentId) {
                    updateTask(taskId, (task) => upsertTaskActivity(task, {
                        id: `subagent-${subagentId}`,
                        title: task.tools.find((tool) => tool.id === `subagent-${subagentId}`)?.title || '子智能体协作',
                        status: '运行中',
                        kind: 'subagent',
                        output: redactRuntimeText(chunk),
                    }, { appendOutput: true }));
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
                    const tools = task.tools.map((tool) => tool.kind === 'reasoning' && !isSettledActivity(tool.status)
                        ? { ...tool, status: '已完成', updatedAt: Date.now() }
                        : tool);
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
                const plan = parsePlanSteps(update.entries);
                updateTask(taskId, (task) => ({ ...task, plan, updatedAt: Date.now() }));
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
            if (updateType === 'tool_call_delta_chunk') {
                const id = String(update.tool_call_id || `tool-stream-${update.tool_index || 0}`);
                const chunk = typeof update.arguments_delta === 'string' ? update.arguments_delta : '';
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id,
                    title: redactRuntimeText(update.name || '正在准备工具调用'),
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
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id: `background-${backgroundTaskId}`,
                    title: redactRuntimeText(update.description || update.monitor_description || '后台任务'),
                    status: '后台运行中',
                    kind: update.monitor_description ? 'monitor' : 'background_task',
                    input: formatToolDetail(update.command),
                    output: update.output_file ? `输出日志：${update.output_file}` : undefined,
                }));
                return;
            }
            if (updateType === 'task_completed') {
                const completed = update.task_snapshot || {};
                const backgroundTaskId = String(completed.task_id || createId('background'));
                const exitCode = completed.exit_code;
                const failed = typeof exitCode === 'number' && exitCode !== 0;
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id: `background-${backgroundTaskId}`,
                    title: redactRuntimeText(completed.display_command || completed.command || '后台任务'),
                    status: failed ? `退出码 ${exitCode}` : '已完成',
                    kind: completed.kind || 'background_task',
                    input: formatToolDetail(completed.command),
                    output: formatToolDetail(completed.output || (completed.output_file ? `输出日志：${completed.output_file}` : '')),
                }));
                return;
            }
            if (updateType === 'subagent_spawned' || updateType === 'subagent_progress' || updateType === 'subagent_finished') {
                const subagentId = String(update.subagent_id || update.child_session_id || createId('subagent'));
                if (updateType === 'subagent_spawned' && typeof update.child_session_id === 'string' && update.child_session_id) {
                    taskBySessionIdRef.current.set(update.child_session_id, taskId);
                    subagentBySessionIdRef.current.set(update.child_session_id, subagentId);
                }
                const finished = updateType === 'subagent_finished';
                const progress = updateType === 'subagent_progress'
                    ? `已运行 ${Math.round(Number(update.duration_ms || 0) / 1000)} 秒 · ${Number(update.turn_count || 0)} 回合 · ${Number(update.tool_call_count || 0)} 次工具调用`
                    : undefined;
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id: `subagent-${subagentId}`,
                    title: redactRuntimeText(update.description || `${update.subagent_type || '子智能体'}协作`),
                    status: finished ? statusLabel(update.status) : progress || '运行中',
                    kind: 'subagent',
                    output: formatToolDetail(update.output || update.error),
                }));
                return;
            }
            if (updateType?.startsWith('auto_compact_')) {
                const failed = updateType === 'auto_compact_failed';
                const completed = updateType === 'auto_compact_completed';
                updateTask(taskId, (task) => upsertTaskActivity(task, {
                    id: 'context-compaction',
                    title: '整理会话上下文',
                    status: failed ? '失败' : completed ? '已完成' : updateType === 'auto_compact_cancelled' ? '已取消' : '运行中',
                    kind: 'context',
                    output: formatToolDetail(update.error || update.reason || update.summary_preview),
                }));
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
            setUserQuestions((current) => current.filter((item) => item.taskId !== taskId));
            setPlanApprovals((current) => current.filter((item) => item.taskId !== taskId));
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

    const startTask = useCallback(async ({
        prompt,
        agentId,
        skillIds = [],
        attachmentPaths = [],
        attachmentGrantIds = [],
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
                    await sendGrokPrompt(session.sessionId, effectivePrompt, attachmentPaths, attachmentGrantIds);
                }
                updateTask(taskId, (value) => cancelledTaskIdsRef.current.has(taskId)
                    ? value
                    : settleForegroundActivities(value, 'completed'));
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
        const agentId = selectAgentId(current, undefined, current.settings.defaultSkillIds);
        const agent = current.agents.find((item) => item.id === agentId && item.enabled)
            || current.agents.find((item) => item.enabled);
        if (!agent) return;
        const skillIds = Array.from(new Set([...agent.skillIds, ...current.settings.defaultSkillIds]));
        const skills = current.skills.filter((skill) => skill.enabled && skillIds.includes(skill.id));
        await prepareGrokRuntime(
            workspace,
            provider.id,
            buildAcpOptions(execution),
            buildSessionRules(agent, skills),
        );
    }, [runtimeStatus]);

    useEffect(() => {
        const timer = window.setTimeout(() => {
            void prepareEngine().catch(() => undefined);
        }, 250);
        return () => window.clearTimeout(timer);
    }, [prepareEngine, snapshot.settings.workspace, snapshot.settings.grokModel, snapshot.settings.defaultAgentId]);

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
                    alwaysApprove: false,
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
                : settleForegroundActivities(value, 'completed'));
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
                    attachmentGrantIds: task.attachmentGrantIds,
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
            ...settleForegroundActivities(value, 'cancelled'),
            error: undefined,
            modelKeyAuthorization: undefined,
        }));
        setPermissions((current) => current.filter((item) => item.taskId !== taskId));
        setUserQuestions((current) => current.filter((item) => item.taskId !== taskId));
        setPlanApprovals((current) => current.filter((item) => item.taskId !== taskId));
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
        selectWorkspace,
        selectAttachments,
        startTask,
        prepareEngine,
        sendFollowUp,
        authorizeTaskModel,
        cancelTask,
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
