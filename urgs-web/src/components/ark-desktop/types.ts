export type ArkDesktopSection = 'new-task' | 'workflows' | 'automations' | 'settings';

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
    workspace?: string;
    agentId: string;
    skillIds: string[];
    schedule: AutomationSchedule;
    scheduleTime: string;
    scheduleWeekday?: number;
    enabled: boolean;
    lastRunAt?: number;
    nextRunAt?: number;
}

export interface ArkDesktopScheduledTask {
    id: string;
    prompt: string;
    humanSchedule: string;
    nextFireAt?: string;
    createdAt: number;
    lastFiredAt?: number;
    firedCount: number;
}

export interface ArkDesktopToolActivity {
    id: string;
    title: string;
    status: string;
    kind?: string;
    visibility?: 'summary' | 'diagnostic' | 'action';
    semanticStage?: string;
    severity?: 'info' | 'warning' | 'error';
    blocking?: boolean;
    recovered?: boolean;
    attempt?: number;
    readOnly?: boolean;
    input?: string;
    output?: string;
    fileChanges?: ArkDesktopFileChange[];
    changesRevertedAt?: number;
    startedAt?: number;
    updatedAt: number;
}

export interface ArkDesktopExecutionState {
    status: 'running' | 'waiting_user' | 'recovering' | 'completed' | 'completed_limited' | 'failed' | 'stopped';
    currentStage?: string;
    lastActivityAt?: number;
    startedAt?: number;
    completedAt?: number;
    resultLimitations?: string[];
}

export interface ArkDesktopDiffHunk {
    oldLine: number;
    newLine: number;
    oldLines: string[];
    newLines: string[];
}

export interface ArkDesktopFileChange {
    path: string;
    additions: number;
    deletions: number;
    hunks: ArkDesktopDiffHunk[];
    previewTruncated?: boolean;
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
    queueEntryId?: string;
}

export interface ArkDesktopSlashCommand {
    name: string;
    description: string;
    inputHint?: string | null;
}

export interface ArkDesktopQueueEntry {
    id: string;
    version: number;
    owner?: string | null;
    lastEditor?: string | null;
    kind: string;
    text: string;
    position: number;
}

export interface ArkDesktopContextInfo {
    used: number;
    total: number;
    systemPromptTokens: number;
    toolDefinitionsCount: number;
    toolDefinitionsTokens: number;
    compactionCount: number;
    turnCount: number;
    toolCallCount: number;
    messageCount: number;
    messageTokens: number;
    freeTokens: number;
    usagePct: number;
    autoCompactThresholdPercent: number;
    usageCategories?: Array<Record<string, any>>;
}

export interface ArkDesktopBackgroundTask {
    taskId: string;
    title: string;
    status: string;
    command?: string;
    output?: string;
    outputFile?: string;
    kind?: string;
    updatedAt: number;
}

export interface ArkDesktopSubagentActivity {
    subagentId: string;
    title: string;
    status: string;
    output?: string;
    updatedAt: number;
}

export interface ArkDesktopWorkflowPhase {
    title: string;
    state: string;
}

export interface ArkDesktopWorkflowAgent {
    agentId: string;
    label: string;
    phase?: string;
    model?: string;
    state: string;
    tokensUsed: number;
    durationMs: number;
}

export interface ArkDesktopWorkflowRun {
    runId: string;
    name: string;
    objective: string;
    status: string;
    foreground: boolean;
    revision: number;
    phases: ArkDesktopWorkflowPhase[];
    currentPhase?: string;
    agentBudget?: number;
    agentsUsed: number;
    agentsReserved: number;
    agentsRemaining?: number;
    agentUsageIncomplete: boolean;
    elapsedMs: number;
    activeAgents: number;
    currentAgentLabel?: string;
    agents: ArkDesktopWorkflowAgent[];
    lastEvent?: string;
    lastEventDetail?: string;
    lastEventTimestamp?: string;
    pauseMessage?: string;
    resultSummary?: string;
    updatedAt: number;
}

export type ArkDesktopTaskStatus = 'running' | 'waiting_authorization' | 'completed' | 'failed' | 'cancelled';

export interface ArkDesktopModelKeyAuthorization {
    providerId: string;
    action: 'start' | 'follow_up' | 'context';
    contextAction?: 'compact' | 'memory' | 'workflow';
    prompt?: string;
}

export type ArkDesktopGitMode = 'worktree' | 'workspace' | 'readonly';

export interface ArkDesktopGitFile {
    path: string;
    indexStatus: string;
    worktreeStatus: string;
    additions: number;
    deletions: number;
    staged: boolean;
    modified: boolean;
    untracked: boolean;
    conflicted: boolean;
}

export interface ArkDesktopGitStatus {
    repoRoot: string;
    workspacePath: string;
    isRepository?: boolean;
    branch?: string | null;
    upstream?: string | null;
    ahead: number;
    behind: number;
    headCommit?: string | null;
    isDirty: boolean;
    isDetached: boolean;
    stagedCount: number;
    modifiedCount: number;
    untrackedCount: number;
    conflictCount: number;
    additions: number;
    deletions: number;
    files: ArkDesktopGitFile[];
}

export interface ArkDesktopGitContext {
    taskId: string;
    mode: ArkDesktopGitMode;
    repoRoot: string;
    sourceWorkspace: string;
    workspacePath: string;
    worktreeId?: string | null;
    branch?: string | null;
    baseRef?: string | null;
    baseCommit?: string | null;
    headCommit?: string | null;
    status?: ArkDesktopGitStatus;
    updatedAt: number;
}

export type ArkDesktopInteractionMode = 'default' | 'plan' | 'ask';

export interface ArkDesktopReasoningEffortOption {
    id: string;
    value: string;
    label: string;
    description: string;
    default: boolean;
}

export interface ArkDesktopTask {
    id: string;
    title: string;
    prompt: string;
    agentId: string;
    skillIds: string[];
    workspace: string;
    runtimeWorkspace?: string;
    sourceWorkspace?: string;
    gitContext?: ArkDesktopGitContext;
    attachmentPaths: string[];
    attachmentGrantIds?: string[];
    engine?: 'acp' | 'headless';
    model?: string;
    reasoningEffort?: string;
    supportsReasoningEffort?: boolean;
    reasoningEfforts?: ArkDesktopReasoningEffortOption[];
    permissionMode?: GrokExecutionSettings['permissionMode'];
    interactionMode?: ArkDesktopInteractionMode;
    alwaysApprove?: boolean;
    sessionId?: string;
    runtimeProcessId?: string;
    runtimeMode?: string;
    cliServiceId?: string;
    status: ArkDesktopTaskStatus;
    execution?: ArkDesktopExecutionState;
    messages: ArkDesktopMessage[];
    tools: ArkDesktopToolActivity[];
    queueEntries?: ArkDesktopQueueEntry[];
    queueRunningPromptId?: string | null;
    plan?: ArkDesktopPlanStep[];
    planDocument?: string;
    availableCommands?: ArkDesktopSlashCommand[];
    contextInfo?: ArkDesktopContextInfo;
    recap?: string;
    backgroundTasks?: ArkDesktopBackgroundTask[];
    subagents?: ArkDesktopSubagentActivity[];
    workflowRuns?: ArkDesktopWorkflowRun[];
    mcpServers?: Array<{ name: string; transport: string; health: string; tools: string[] }>;
    diagnostics?: string[];
    error?: string;
    modelKeyAuthorization?: ArkDesktopModelKeyAuthorization;
    automationId?: string;
    scheduledTasks?: ArkDesktopScheduledTask[];
    pinnedAt?: number;
    archivedAt?: number;
    createdAt: number;
    updatedAt: number;
}

export interface ArkDesktopSettings {
    workspace: string;
    workspacePaths: string[];
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
    supportsReasoningEffort: boolean;
    hasApiKey: boolean;
}

export interface GrokExecutionSettings {
    engine: 'acp' | 'headless';
    gitMode: ArkDesktopGitMode;
    reasoningEffort: string;
    permissionMode: 'default' | 'bypassPermissions';
    interactionMode: ArkDesktopInteractionMode;
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
    planSteps?: ArkDesktopPlanStep[];
}
