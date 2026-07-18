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
    sessionId?: string;
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
