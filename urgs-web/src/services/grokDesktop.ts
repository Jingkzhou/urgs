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

export interface GrokBridgeEvent {
    eventType: string;
    payload: Record<string, any>;
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

export const createGrokSession = (workspace: string, rules?: string, model?: string) =>
    invokeGrok<GrokSession>('grok_create_session', { workspace, rules: rules || null, model: model || null });

export const sendGrokPrompt = (sessionId: string, prompt: string) =>
    invokeGrok<void>('grok_send_prompt', { sessionId, prompt });

export const cancelGrokPrompt = (sessionId: string) => invokeGrok<void>('grok_cancel', { sessionId });

export const respondGrokPermission = (requestId: unknown, optionId?: string) =>
    invokeGrok<void>('grok_respond_permission', { requestId, optionId: optionId || null });

export const startGrokLogin = () => invokeGrok<void>('grok_start_login');

export const shutdownGrok = () => invokeGrok<void>('grok_shutdown');

export const chooseGrokWorkspace = async () => {
    assertDesktopRuntime();
    const { open } = await import('@tauri-apps/plugin-dialog');
    const selected = await open({
        directory: true,
        multiple: false,
        title: '选择 Grok Build 工作区',
    });
    return typeof selected === 'string' ? selected : null;
};

export const chooseGrokAttachments = async () => {
    assertDesktopRuntime();
    const { open } = await import('@tauri-apps/plugin-dialog');
    const selected = await open({
        directory: false,
        multiple: true,
        title: '选择提供给 Grok Build 的本地文件',
    });
    if (!selected) return [];
    return Array.isArray(selected) ? selected : [selected];
};

export const subscribeGrokEvents = async (listener: (event: GrokBridgeEvent) => void) => {
    assertDesktopRuntime();
    const { listen } = await import('@tauri-apps/api/event');
    return listen<GrokBridgeEvent>('grok-event', (event) => listener(event.payload));
};
