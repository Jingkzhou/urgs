import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { isDesktopRuntime } from '@/config';
import {
    cancelGrokPrompt,
    chooseGrokAttachments,
    chooseGrokWorkspace,
    createGrokSession,
    getGrokRuntimeStatus,
    respondGrokPermission,
    sendGrokPrompt,
    startGrokLogin,
    subscribeGrokEvents,
    type GrokBridgeEvent,
    type GrokRuntimeStatus,
} from '@/services/grokDesktop';
import { loadArkDesktopSnapshot, resetArkDesktopSnapshot, saveArkDesktopSnapshot } from './storage';
import type {
    ArkDesktopAgent,
    ArkDesktopAutomation,
    ArkDesktopPermissionRequest,
    ArkDesktopSkill,
    ArkDesktopSnapshot,
    ArkDesktopTask,
} from './types';

interface StartTaskInput {
    prompt: string;
    agentId?: string;
    skillIds?: string[];
    attachmentPaths?: string[];
    automationId?: string;
}

const createId = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;

const extractText = (update: Record<string, any>) =>
    update?.content?.text || update?.content?.content?.text || update?.text || '';

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
    if (skillIds.includes('data-analysis') || skillIds.includes('regulatory-query')) return 'grok-data';
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

export const useArkDesktopRuntime = () => {
    const [snapshot, setSnapshot] = useState<ArkDesktopSnapshot>(loadArkDesktopSnapshot);
    const [runtimeStatus, setRuntimeStatus] = useState<GrokRuntimeStatus | null>(null);
    const [activeTaskId, setActiveTaskId] = useState<string | null>(null);
    const [permission, setPermission] = useState<ArkDesktopPermissionRequest | null>(null);
    const [runtimeError, setRuntimeError] = useState('');
    const activeTaskIdRef = useRef<string | null>(null);
    const cancelledTaskIdsRef = useRef(new Set<string>());
    const snapshotRef = useRef(snapshot);

    useEffect(() => {
        snapshotRef.current = snapshot;
        saveArkDesktopSnapshot(snapshot);
    }, [snapshot]);

    useEffect(() => {
        activeTaskIdRef.current = activeTaskId;
    }, [activeTaskId]);

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
            setRuntimeError(error instanceof Error ? error.message : '无法检测 Grok Build');
        }
    }, []);

    const handleGrokEvent = useCallback((event: GrokBridgeEvent) => {
        const taskId = activeTaskIdRef.current;
        if (event.eventType === 'session_update' && taskId) {
            const params = event.payload?.params || event.payload;
            const update = params?.update || params?.sessionUpdate || {};
            const updateType = update?.sessionUpdate;
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
                    const nextTool = {
                        id,
                        title: update.title || update.toolCall?.title || '本地工具调用',
                        status: statusLabel(update.status),
                        kind: update.kind || update.toolCall?.kind,
                        updatedAt: Date.now(),
                    };
                    if (existingIndex >= 0) tools[existingIndex] = { ...tools[existingIndex], ...nextTool };
                    else tools.push(nextTool);
                    return { ...task, tools, updatedAt: Date.now() };
                });
            }
            return;
        }

        if (event.eventType === 'permission_request') {
            const params = event.payload?.params || {};
            setPermission({
                requestId: event.payload?.id,
                title: params?.toolCall?.title || params?.toolCall?.rawInput || 'Grok 请求执行本地操作',
                options: (params?.options || []).map((option: any) => ({
                    optionId: option.optionId,
                    name: option.name || option.optionId,
                    kind: option.kind,
                })),
            });
            return;
        }

        if (event.eventType === 'runtime_error') {
            const message = event.payload?.message || 'Grok 本地运行时发生错误';
            setRuntimeError(message);
            if (taskId) {
                updateTask(taskId, (task) => ({ ...task, status: 'failed', error: message, updatedAt: Date.now() }));
            }
            return;
        }

        if (event.eventType === 'terminated' && taskId) {
            updateTask(taskId, (task) => task.status === 'running'
                ? { ...task, status: 'failed', error: 'Grok 本地进程已退出', updatedAt: Date.now() }
                : task);
        }

        if (event.eventType === 'login_completed') {
            void refreshRuntimeStatus();
        }
    }, [refreshRuntimeStatus, updateTask]);

    useEffect(() => {
        if (!isDesktopRuntime()) return;
        void refreshRuntimeStatus();
        let unlisten: (() => void) | undefined;
        void subscribeGrokEvents(handleGrokEvent).then((dispose) => {
            unlisten = dispose;
        }).catch((error) => {
            setRuntimeError(error instanceof Error ? error.message : '无法订阅 Grok 事件');
        });
        return () => unlisten?.();
    }, [handleGrokEvent, refreshRuntimeStatus]);

    const selectWorkspace = useCallback(async () => {
        const selected = await chooseGrokWorkspace();
        if (!selected) return '';
        setSnapshot((current) => ({ ...current, settings: { ...current.settings, workspace: selected } }));
        return selected;
    }, []);

    const selectAttachments = useCallback(async () => chooseGrokAttachments(), []);

    const startLogin = useCallback(async () => {
        setRuntimeError('');
        await startGrokLogin();
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
        if (!runtimeStatus?.available) throw new Error('未检测到内置 Grok Build，请先检查桌面安装包');
        if (!runtimeStatus.authenticated) throw new Error('请先登录 Grok');
        if (!workspace) throw new Error('请先选择本地工作区');
        if (!prompt.trim()) throw new Error('请输入要完成的任务');
        if (current.tasks.some((task) => task.status === 'running')) throw new Error('已有本地任务正在执行，请等待完成或先停止任务');

        const resolvedAgentId = selectAgentId(current, agentId, skillIds);
        const agent = current.agents.find((item) => item.id === resolvedAgentId && item.enabled)
            || current.agents.find((item) => item.enabled);
        if (!agent) throw new Error('没有可用的本地 Agent');
        const resolvedSkillIds = Array.from(new Set([...agent.skillIds, ...skillIds]))
            .filter((id) => current.skills.some((skill) => skill.id === id && skill.enabled));
        const skills = current.skills.filter((skill) => resolvedSkillIds.includes(skill.id));
        const now = Date.now();
        const taskId = createId('task');
        const task: ArkDesktopTask = {
            id: taskId,
            title: prompt.trim().slice(0, 36),
            prompt: prompt.trim(),
            agentId: agent.id,
            skillIds: resolvedSkillIds,
            workspace,
            attachmentPaths,
            status: 'running',
            messages: [{ id: createId('message'), role: 'user', content: prompt.trim(), createdAt: now }],
            tools: [],
            automationId,
            createdAt: now,
            updatedAt: now,
        };
        setSnapshot((value) => ({ ...value, tasks: [task, ...value.tasks].slice(0, 50) }));
        setActiveTaskId(taskId);
        activeTaskIdRef.current = taskId;
        setRuntimeError('');

        try {
            const session = await createGrokSession(workspace, buildSessionRules(agent, skills), current.settings.grokModel);
            updateTask(taskId, (value) => ({ ...value, sessionId: session.sessionId, updatedAt: Date.now() }));
            await sendGrokPrompt(session.sessionId, buildTaskPrompt(prompt.trim(), attachmentPaths));
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
            const message = error instanceof Error ? error.message : String(error);
            if (!cancelledTaskIdsRef.current.has(taskId)) {
                updateTask(taskId, (value) => ({ ...value, status: 'failed', error: message, updatedAt: Date.now() }));
                setRuntimeError(message);
            }
        }
        return taskId;
    }, [runtimeStatus, updateTask]);

    const sendFollowUp = useCallback(async (taskId: string, prompt: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) throw new Error('该历史任务的本地会话已经结束，请新建任务');
        updateTask(taskId, (value) => ({
            ...value,
            status: 'running',
            messages: [...value.messages, { id: createId('message'), role: 'user', content: prompt, createdAt: Date.now() }],
            updatedAt: Date.now(),
        }));
        await sendGrokPrompt(task.sessionId, prompt);
        updateTask(taskId, (value) => cancelledTaskIdsRef.current.has(taskId)
            ? value
            : { ...value, status: 'completed', updatedAt: Date.now() });
    }, [updateTask]);

    const cancelTask = useCallback(async (taskId: string) => {
        const task = snapshotRef.current.tasks.find((item) => item.id === taskId);
        if (!task?.sessionId) return;
        cancelledTaskIdsRef.current.add(taskId);
        await cancelGrokPrompt(task.sessionId);
        updateTask(taskId, (value) => ({ ...value, status: 'cancelled', updatedAt: Date.now() }));
        setPermission(null);
    }, [updateTask]);

    const answerPermission = useCallback(async (optionId?: string) => {
        if (!permission) return;
        await respondGrokPermission(permission.requestId, optionId);
        setPermission(null);
    }, [permission]);

    const activeTask = useMemo(
        () => snapshot.tasks.find((task) => task.id === activeTaskId) || null,
        [activeTaskId, snapshot.tasks],
    );

    const resetAll = useCallback(() => {
        const defaults = resetArkDesktopSnapshot();
        setSnapshot(defaults);
        setActiveTaskId(null);
        setRuntimeError('');
    }, []);

    return {
        snapshot,
        setSnapshot,
        runtimeStatus,
        runtimeError,
        setRuntimeError,
        refreshRuntimeStatus,
        startLogin,
        selectWorkspace,
        selectAttachments,
        startTask,
        sendFollowUp,
        cancelTask,
        permission,
        answerPermission,
        activeTask,
        activeTaskId,
        setActiveTaskId,
        resetAll,
    };
};

export type ArkDesktopRuntime = ReturnType<typeof useArkDesktopRuntime>;
export type { StartTaskInput };
