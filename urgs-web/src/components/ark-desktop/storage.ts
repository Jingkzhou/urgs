import {
    DEFAULT_ARK_DESKTOP_AGENTS,
    DEFAULT_ARK_DESKTOP_AUTOMATIONS,
    DEFAULT_ARK_DESKTOP_SKILLS,
} from './catalog';
import type { ArkDesktopSnapshot } from './types';

const STORAGE_KEY = 'urgs_ark_desktop_grok_snapshot_v3';
const LEGACY_STORAGE_KEY = 'urgs_ark_desktop_grok_snapshot_v2';
const MAX_TASK_HISTORY = 50;
const settledActivityPattern = /已完成|完成|成功|失败|取消|不可用|未生成|退出码|completed|success|failed|cancelled|canceled|unavailable|done/i;
const MAX_PERSISTED_TEXT = 4_000;
const MAX_PERSISTED_DIFF_HUNKS = 6;
const MAX_PERSISTED_DIFF_LINES = 32;

const clone = <T>(value: T): T => JSON.parse(JSON.stringify(value));

const refreshLegacyBuiltInAgent = (agent: ArkDesktopSnapshot['agents'][number]) => {
    const current = DEFAULT_ARK_DESKTOP_AGENTS.find((item) => item.id === agent.id);
    if (!current || !agent.builtIn || !/^grok\b/i.test(agent.name.trim())) return agent;
    return { ...clone(current), enabled: agent.enabled };
};

export const createDefaultArkDesktopSnapshot = (): ArkDesktopSnapshot => ({
    agents: clone(DEFAULT_ARK_DESKTOP_AGENTS),
    skills: clone(DEFAULT_ARK_DESKTOP_SKILLS),
    automations: clone(DEFAULT_ARK_DESKTOP_AUTOMATIONS),
    tasks: [],
    settings: {
        workspace: '',
        workspacePaths: [],
        grokModel: '',
        modelOptions: [],
        modelProviders: [],
        defaultAgentId: 'grok-general',
        defaultSkillIds: [],
        execution: {
            engine: 'acp',
            reasoningEffort: '',
            permissionMode: 'default',
            sandboxProfile: '',
            maxTurns: 0,
            noPlan: false,
            noSubagents: false,
            disableWebSearch: false,
            memoryMode: 'default',
            allowRules: '',
            denyRules: '',
            allowedTools: '',
            disallowedTools: '',
            additionalRules: '',
            systemPromptOverride: '',
            jsonSchema: '',
            agentName: '',
            inlineAgentsJson: '',
            outputFormat: 'json',
            verbatim: false,
            alwaysApprove: false,
            sessionMode: 'new',
            resumeSessionId: '',
            forkSession: false,
            restoreCode: false,
            newSessionId: '',
            promptMode: 'text',
            promptFile: '',
            promptJson: '',
            useWorktree: false,
            worktreeName: '',
            worktreeRef: '',
            oauth: false,
            debug: false,
            debugFile: '',
            leaderSocket: '',
            reauth: false,
            agentProfile: '',
            pluginDirs: '',
            leaderMode: 'default',
            grokWsOrigin: '',
            grokWsUrl: '',
            cliChatProxyUrl: '',
            xaiApiBaseUrl: '',
        },
    },
});

export const loadArkDesktopSnapshot = (): ArkDesktopSnapshot => {
    const defaults = createDefaultArkDesktopSnapshot();
    if (typeof window === 'undefined') return defaults;
    try {
        const currentRaw = localStorage.getItem(STORAGE_KEY);
        const raw = currentRaw || localStorage.getItem(LEGACY_STORAGE_KEY);
        if (!raw) return defaults;
        const stored = JSON.parse(raw) as Partial<ArkDesktopSnapshot>;
        const isLegacy = !currentRaw;
        const skills = isLegacy
            ? [...defaults.skills, ...(stored.skills || []).filter((skill) => !skill.builtIn)]
            : Array.isArray(stored.skills) && stored.skills.length > 0 ? stored.skills : defaults.skills;
        const validSkillIds = new Set(skills.map((skill) => skill.id));
        const agents = (isLegacy
            ? [...defaults.agents, ...(stored.agents || []).filter((agent) => !agent.builtIn)]
            : Array.isArray(stored.agents) && stored.agents.length > 0 ? stored.agents : defaults.agents)
            .map(refreshLegacyBuiltInAgent)
            .map((agent) => ({ ...agent, skillIds: agent.skillIds.filter((id) => validSkillIds.has(id)) }));
        const validAgentIds = new Set(agents.map((agent) => agent.id));
        const automations = (Array.isArray(stored.automations) ? stored.automations : defaults.automations)
            .map((automation) => ({
                ...automation,
                agentId: validAgentIds.has(automation.agentId) ? automation.agentId : defaults.settings.defaultAgentId,
                skillIds: automation.skillIds.filter((id) => validSkillIds.has(id)),
            }));
        const tasks = Array.isArray(stored.tasks) ? stored.tasks.slice(0, MAX_TASK_HISTORY).map((task) => {
            const interrupted = task.status === 'running';
            const taskStatus = interrupted ? 'failed' as const : task.status;
            const taskIsTerminal = ['completed', 'failed', 'cancelled'].includes(taskStatus);
            const bypassPermissions = task.alwaysApprove || task.permissionMode === 'bypassPermissions';
            const terminalToolStatus = taskStatus === 'failed' ? '失败' : taskStatus === 'cancelled' ? '已取消' : '已完成';
            return {
                ...task,
                ...(interrupted ? { status: 'failed' as const, error: '桌面客户端已重新启动，本次执行已中断', updatedAt: Date.now() } : {}),
                tools: (task.tools || []).map((tool) => taskIsTerminal
                    && !settledActivityPattern.test(tool.status)
                    && !['background_task', 'monitor', 'goal'].includes(tool.kind || '')
                    ? { ...tool, status: terminalToolStatus, updatedAt: Date.now() }
                    : tool),
                permissionMode: bypassPermissions
                    ? 'bypassPermissions' as const
                    : 'default' as const,
                alwaysApprove: false,
                runtimeProcessId: undefined,
            };
        }) : [];
        const modelProviders = Array.isArray(stored.settings?.modelProviders)
            ? stored.settings.modelProviders
            : [];
        const enabledModelIds = modelProviders
            .filter((provider) => provider.enabled)
            .map((provider) => provider.id.trim())
            .filter(Boolean);
        const storedModel = stored.settings?.grokModel?.trim() || '';
        const configuredModel = enabledModelIds.includes(storedModel) ? storedModel : enabledModelIds[0] || '';
        const modelOptions = Array.from(new Set(enabledModelIds));
        const workspacePaths = Array.from(new Set(
            (Array.isArray(stored.settings?.workspacePaths)
                ? stored.settings.workspacePaths
                : [stored.settings?.workspace, ...tasks.map((task) => task.workspace)])
                .map((workspace) => workspace?.trim())
                .filter((workspace): workspace is string => Boolean(workspace)),
        ));
        const snapshot: ArkDesktopSnapshot = {
            agents,
            skills,
            automations,
            tasks,
            settings: {
                ...defaults.settings,
                ...(stored.settings || {}),
                workspacePaths,
                grokModel: configuredModel,
                modelOptions,
                modelProviders,
                defaultAgentId: validAgentIds.has(stored.settings?.defaultAgentId || '') ? stored.settings!.defaultAgentId : defaults.settings.defaultAgentId,
                defaultSkillIds: (stored.settings?.defaultSkillIds || []).filter((id) => validSkillIds.has(id)),
                execution: {
                    ...defaults.settings.execution,
                    ...(stored.settings?.execution || {}),
                    permissionMode: stored.settings?.execution?.alwaysApprove || stored.settings?.execution?.permissionMode === 'bypassPermissions'
                        ? 'bypassPermissions'
                        : defaults.settings.execution.permissionMode,
                    alwaysApprove: false,
                },
            },
        };
        if (isLegacy) localStorage.setItem(STORAGE_KEY, JSON.stringify(snapshot));
        return snapshot;
    } catch (error) {
        console.error('读取 ARK Desktop 本地配置失败', error);
        return defaults;
    }
};

export const saveArkDesktopSnapshot = (snapshot: ArkDesktopSnapshot) => {
    if (typeof window === 'undefined') return;
    const compact = (value: string | undefined) => value?.slice(-MAX_PERSISTED_TEXT);
    const compactTasks = snapshot.tasks.slice(0, MAX_TASK_HISTORY).map((task) => ({
        ...task,
        prompt: task.prompt.slice(0, MAX_PERSISTED_TEXT),
        messages: task.messages.map((message) => ({ ...message, content: message.content.slice(0, MAX_PERSISTED_TEXT) })),
        tools: task.tools.map((tool) => ({
            ...tool,
            ...(tool.input ? { input: compact(tool.input) } : {}),
            ...(tool.output ? { output: compact(tool.output) } : {}),
            ...(tool.fileChanges ? {
                fileChanges: tool.fileChanges.map((change) => ({
                    ...change,
                    hunks: change.hunks.slice(0, MAX_PERSISTED_DIFF_HUNKS).map((hunk) => ({
                        ...hunk,
                        oldLines: hunk.oldLines.slice(0, MAX_PERSISTED_DIFF_LINES),
                        newLines: hunk.newLines.slice(0, MAX_PERSISTED_DIFF_LINES),
                    })),
                    previewTruncated: true,
                })),
            } : {}),
        })),
    }));
    const payload = JSON.stringify({ ...snapshot, tasks: compactTasks });
    try {
        localStorage.setItem(STORAGE_KEY, payload);
    } catch (error) {
        // A large tool output or diff must never prevent the desktop UI from mounting.
        if (!(error instanceof DOMException) || error.name !== 'QuotaExceededError') throw error;
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify({
                ...snapshot,
                tasks: compactTasks.map((task) => ({
                    ...task,
                    tools: task.tools.map(({ fileChanges: _fileChanges, input: _input, output: _output, ...tool }) => tool),
                })),
            }));
        } catch (fallbackError) {
            console.warn('ARK Desktop 本地快照空间不足，已跳过本轮持久化', fallbackError);
        }
    }
};

export const resetArkDesktopSnapshot = () => {
    if (typeof window !== 'undefined') {
        localStorage.removeItem(STORAGE_KEY);
        localStorage.removeItem(LEGACY_STORAGE_KEY);
    }
    return createDefaultArkDesktopSnapshot();
};
