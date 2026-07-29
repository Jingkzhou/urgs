export type ArkDesktopSection = 'new-task' | 'agents' | 'skills' | 'automations' | 'settings';

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
    input?: string;
    output?: string;
    startedAt?: number;
    updatedAt: number;
}

export interface ArkDesktopPlanStep {
    content: string;
    status: 'pending' | 'in_progress' | 'completed' | 'cancelled';
    priority?: 'high' | 'medium' | 'low';
}

export interface ArkDesktopMessage {
    id: string;
    role: 'user' | 'assistant';
    content: string;
    createdAt: number;
}

export interface ArkDesktopSlashCommand {
    name: string;
    description: string;
    inputHint?: string | null;
}

export type ArkDesktopTaskStatus = 'running' | 'waiting_authorization' | 'completed' | 'failed' | 'cancelled';

export interface ArkDesktopModelKeyAuthorization {
    providerId: string;
    action: 'start' | 'follow_up';
    prompt?: string;
}

export interface ArkDesktopTask {
    id: string;
    title: string;
    prompt: string;
    agentId: string;
    skillIds: string[];
    workspace: string;
    attachmentPaths: string[];
    engine?: 'acp' | 'headless';
    model?: string;
    permissionMode?: GrokExecutionSettings['permissionMode'];
    alwaysApprove?: boolean;
    sessionId?: string;
    runtimeProcessId?: string;
    cliServiceId?: string;
    status: ArkDesktopTaskStatus;
    messages: ArkDesktopMessage[];
    tools: ArkDesktopToolActivity[];
    plan?: ArkDesktopPlanStep[];
    availableCommands?: ArkDesktopSlashCommand[];
    error?: string;
    modelKeyAuthorization?: ArkDesktopModelKeyAuthorization;
    automationId?: string;
    createdAt: number;
    updatedAt: number;
}

export interface ArkDesktopSettings {
    workspace: string;
    grokModel: string;
    modelOptions: string[];
    modelProviders: ArkDesktopModelProvider[];
    defaultAgentId: string;
    defaultSkillIds: string[];
    execution: GrokExecutionSettings;
}

export interface ArkDesktopModelProvider {
    id: string;
    name: string;
    model: string;
    baseUrl: string;
    apiBackend: 'chat_completions' | 'responses' | 'messages';
    authScheme: 'bearer' | 'x_api_key';
    contextWindow: number;
    enabled: boolean;
    hasApiKey: boolean;
}

export interface GrokExecutionSettings {
    engine: 'acp' | 'headless';
    reasoningEffort: string;
    permissionMode: 'default' | 'bypassPermissions';
    sandboxProfile: string;
    maxTurns: number;
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
    taskId: string;
    sessionId: string;
    taskTitle: string;
    requestId: unknown;
    title: string;
    options: Array<{ optionId: string; name: string; kind?: string }>;
}

export interface ArkDesktopUserQuestionRequest {
    taskId: string;
    sessionId: string;
    requestId: unknown;
    toolCallId?: string;
    mode: 'default' | 'plan';
    questions: Array<{
        id?: string;
        question: string;
        multiSelect?: boolean;
        options: Array<{
            id?: string;
            label: string;
            description?: string;
            preview?: string;
        }>;
    }>;
}

export interface ArkDesktopPlanApprovalRequest {
    taskId: string;
    sessionId: string;
    requestId: unknown;
    toolCallId?: string;
    planContent?: string;
}
