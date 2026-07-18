import { isDesktopRuntime } from '@/config';

export interface GrokRuntimeStatus {
    available: boolean;
    authenticated: boolean;
    version?: string | null;
    grokHome: string;
    message?: string | null;
}

export interface GrokSession {
    sessionId: string;
    workspace: string;
}

export interface GrokAcpOptions {
    reasoningEffort?: string;
    alwaysApprove?: boolean;
    reauth?: boolean;
    agentProfile?: string;
    pluginDirs?: string[];
    leaderMode?: 'default' | 'leader' | 'standalone';
    grokWsOrigin?: string;
    grokWsUrl?: string;
    cliChatProxyUrl?: string;
    xaiApiBaseUrl?: string;
    debug?: boolean;
    debugFile?: string;
    leaderSocket?: string;
}

export interface GrokBridgeEvent {
    eventType: string;
    payload: Record<string, any>;
}

export interface GrokCliResult {
    arguments: string[];
    success: boolean;
    exitCode?: number | null;
    stdout: string;
    stderr: string;
}

export interface GrokCliServiceInfo {
    id: string;
    arguments: string[];
    pid: number;
    alive: boolean;
    startedAt: number;
    exitCode?: number | null;
    stdout: string;
    stderr: string;
}

export interface GrokConfigFile {
    scope: 'user' | 'project';
    kind: 'config' | 'appearance';
    path: string;
    exists: boolean;
    content: string;
}

const assertDesktopRuntime = () => {
    if (!isDesktopRuntime()) {
        throw new Error('ARK Desktop 仅能在 URGS 桌面客户端中使用');
    }
};

const invokeGrok = async <T>(command: string, args?: Record<string, unknown>) => {
    assertDesktopRuntime();
    const { invoke } = await import('@tauri-apps/api/core');
    return invoke<T>(command, args);
};

export const getGrokRuntimeStatus = () => invokeGrok<GrokRuntimeStatus>('grok_runtime_status');

export const runGrokCli = (arguments_: string[], workspace?: string, timeoutSeconds = 120) =>
    invokeGrok<GrokCliResult>('grok_cli_run', {
        arguments: arguments_,
        workspace: workspace || null,
        timeoutSeconds,
    });

export const startGrokCliService = (arguments_: string[], workspace?: string) =>
    invokeGrok<GrokCliServiceInfo>('grok_cli_service_start', { arguments: arguments_, workspace: workspace || null });

export const listGrokCliServices = () => invokeGrok<GrokCliServiceInfo[]>('grok_cli_service_list');

export const stopGrokCliService = (serviceId: string) => invokeGrok<void>('grok_cli_service_stop', { serviceId });

export const readGrokConfig = (scope: 'user' | 'project', workspace?: string, kind: 'config' | 'appearance' = 'config') =>
    invokeGrok<GrokConfigFile>('grok_config_read', { scope, kind, workspace: workspace || null });

export const saveGrokConfig = (scope: 'user' | 'project', content: string, workspace?: string, kind: 'config' | 'appearance' = 'config') =>
    invokeGrok<GrokConfigFile>('grok_config_save', { scope, kind, content, workspace: workspace || null });

export const applyGrokModel = (model: string) => invokeGrok<void>('grok_model_apply', { model });

export const createGrokSession = (workspace: string, rules?: string, model?: string, options?: GrokAcpOptions) =>
    invokeGrok<GrokSession>('grok_create_session', { workspace, rules: rules || null, model: model || null, options: options || null });

export const sendGrokPrompt = (sessionId: string, prompt: string) =>
    invokeGrok<void>('grok_send_prompt', { sessionId, prompt });

export const setGrokSessionModel = (sessionId: string, model: string) =>
    invokeGrok<void>('grok_session_set_model', { sessionId, model });

export const cancelGrokPrompt = (sessionId: string) => invokeGrok<void>('grok_cancel', { sessionId });

export const respondGrokPermission = (requestId: unknown, optionId?: string) =>
    invokeGrok<void>('grok_respond_permission', { requestId, optionId: optionId || null });

export const startGrokLogin = (method: 'browser' | 'oauth' | 'device' = 'browser') =>
    invokeGrok<void>('grok_start_login', { method });

export const shutdownGrok = () => invokeGrok<void>('grok_shutdown');

export const chooseGrokWorkspace = async () => {
    assertDesktopRuntime();
    const { open } = await import('@tauri-apps/plugin-dialog');
    const selected = await open({
        directory: true,
        multiple: false,
        title: '选择本地工作区',
    });
    return typeof selected === 'string' ? selected : null;
};

export const chooseGrokAttachments = async () => {
    assertDesktopRuntime();
    const { open } = await import('@tauri-apps/plugin-dialog');
    const selected = await open({
        directory: false,
        multiple: true,
        title: '选择任务附件',
    });
    if (!selected) return [];
    return Array.isArray(selected) ? selected : [selected];
};

export const subscribeGrokEvents = async (listener: (event: GrokBridgeEvent) => void) => {
    assertDesktopRuntime();
    const { listen } = await import('@tauri-apps/api/event');
    return listen<GrokBridgeEvent>('grok-event', (event) => listener(event.payload));
};
