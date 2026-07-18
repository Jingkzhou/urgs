export type ArkDesktopSection = 'new-task' | 'agents' | 'skills' | 'automations' | 'cli' | 'settings';

export interface ArkDesktopSkill {
    id: string;
    name: string;
    description: string;
    instruction: string;
    category: 'office' | 'data' | 'code' | 'research' | 'workflow';
    enabled: boolean;
    builtIn: boolean;
}

export interface ArkDesktopAgent {
    id: string;
    name: string;
    description: string;
    systemPrompt: string;
    skillIds: string[];
    enabled: boolean;
    builtIn: boolean;
}

export type AutomationSchedule = 'manual' | 'daily' | 'weekly';

export interface ArkDesktopAutomation {
    id: string;
    name: string;
    description: string;
    prompt: string;
    agentId: string;
    skillIds: string[];
    schedule: AutomationSchedule;
    scheduleTime: string;
    scheduleWeekday?: number;
    enabled: boolean;
    lastRunAt?: number;
    nextRunAt?: number;
}

export interface ArkDesktopToolActivity {
    id: string;
    title: string;
    status: string;
    kind?: string;
    updatedAt: number;
}

export interface ArkDesktopMessage {
    id: string;
    role: 'user' | 'assistant';
    content: string;
    createdAt: number;
}

export type ArkDesktopTaskStatus = 'running' | 'completed' | 'failed' | 'cancelled';

export interface ArkDesktopTask {
    id: string;
    title: string;
    prompt: string;
    agentId: string;
    skillIds: string[];
    workspace: string;
    attachmentPaths: string[];
    engine?: 'acp' | 'headless';
    sessionId?: string;
    cliServiceId?: string;
    status: ArkDesktopTaskStatus;
    messages: ArkDesktopMessage[];
    tools: ArkDesktopToolActivity[];
    error?: string;
    automationId?: string;
    createdAt: number;
    updatedAt: number;
}

export interface ArkDesktopSettings {
    workspace: string;
    grokModel: string;
    defaultAgentId: string;
    defaultSkillIds: string[];
    execution: GrokExecutionSettings;
}

export interface GrokExecutionSettings {
    engine: 'acp' | 'headless';
    reasoningEffort: string;
    permissionMode: 'default' | 'acceptEdits' | 'auto' | 'dontAsk' | 'bypassPermissions' | 'plan';
    sandboxProfile: string;
    maxTurns: number;
    bestOfN: number;
    check: boolean;
    noPlan: boolean;
    noSubagents: boolean;
    disableWebSearch: boolean;
    memoryMode: 'default' | 'disabled' | 'experimental';
    allowRules: string;
    denyRules: string;
    allowedTools: string;
    disallowedTools: string;
    additionalRules: string;
    systemPromptOverride: string;
    jsonSchema: string;
    agentName: string;
    inlineAgentsJson: string;
    outputFormat: 'plain' | 'json' | 'streaming-json';
    verbatim: boolean;
    alwaysApprove: boolean;
    sessionMode: 'new' | 'continue' | 'resume';
    resumeSessionId: string;
    forkSession: boolean;
    restoreCode: boolean;
    newSessionId: string;
    promptMode: 'text' | 'file' | 'json';
    promptFile: string;
    promptJson: string;
    useWorktree: boolean;
    worktreeName: string;
    worktreeRef: string;
    oauth: boolean;
    debug: boolean;
    debugFile: string;
    leaderSocket: string;
    reauth: boolean;
    agentProfile: string;
    pluginDirs: string;
    leaderMode: 'default' | 'leader' | 'standalone';
    grokWsOrigin: string;
    grokWsUrl: string;
    cliChatProxyUrl: string;
    xaiApiBaseUrl: string;
}

export interface ArkDesktopSnapshot {
    agents: ArkDesktopAgent[];
    skills: ArkDesktopSkill[];
    automations: ArkDesktopAutomation[];
    tasks: ArkDesktopTask[];
    settings: ArkDesktopSettings;
}

export interface ArkDesktopPermissionRequest {
    requestId: unknown;
    title: string;
    options: Array<{ optionId: string; name: string; kind?: string }>;
}
