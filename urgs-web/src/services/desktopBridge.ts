import { isDesktopRuntime } from '@/config';

export type DesktopLogLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';

export interface DesktopLogContext {
    requestId?: string | number | null;
    bridgeRequestId?: string | number | null;
}

let desktopInvokeSequence = 0;

const createDesktopRequestId = () => {
    desktopInvokeSequence += 1;
    if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
        return crypto.randomUUID();
    }
    return `desktop-${Date.now().toString(36)}-${desktopInvokeSequence.toString(36)}`;
};

const readLogContextValue = (value: unknown) => {
    if (typeof value !== 'string' && typeof value !== 'number') return undefined;
    const normalized = String(value).trim();
    return normalized ? normalized.slice(0, 160) : undefined;
};

const formatLogContext = (context: DesktopLogContext) => Object.entries({
    bridge_request_id: context.bridgeRequestId,
    request_id: context.requestId,
})
    .map(([key, value]) => [key, readLogContextValue(value)] as const)
    .filter((entry): entry is readonly [string, string] => Boolean(entry[1]))
    .map(([key, value]) => `${key}=${value}`)
    .join(' ');

const truncateFrontendLogText = (value: string, maxLength = 4_000) => value.length > maxLength
    ? `${value.slice(0, maxLength)}...`
    : value;

const redactFrontendLogText = (value: string) => value
    .replace(/\bBearer\s+[^\s,;]+/gi, 'Bearer [REDACTED]')
    .replace(/((?:api[_-]?key|access[_-]?token|authorization|x-api-key)\s*[:=]\s*["']?)[^,\s}"']+/gi, '$1[REDACTED]');

export const describeDesktopError = (error: unknown, includeStack = false) => {
    if (error instanceof Error) {
        const stack = includeStack && error.stack && error.stack !== error.message
            ? ` stack=${error.stack.split('\n').slice(0, 8).join(' | ')}`
            : '';
        return truncateFrontendLogText(`${error.name}: ${error.message}${stack}`);
    }
    if (typeof error === 'string') return truncateFrontendLogText(error);
    return truncateFrontendLogText(Object.prototype.toString.call(error));
};

export const writeDesktopLog = async (
    level: DesktopLogLevel,
    component: string,
    message: string,
    context: DesktopLogContext = {},
) => {
    if (!isDesktopRuntime()) return;
    const contextText = formatLogContext(context);
    const safeMessage = redactFrontendLogText(truncateFrontendLogText(
        contextText ? `${contextText} ${message}` : message,
    ));
    try {
        const { invoke } = await import('@tauri-apps/api/core');
        await invoke('desktop_log_write', { request: { level, component, message: safeMessage } });
    } catch {
        // 客户端日志写入不能反过来制造未处理异常。
    }
};

export const invokeDesktop = async <T>(
    command: string,
    args?: Record<string, unknown>,
    logContext: DesktopLogContext = {},
) => {
    const context: DesktopLogContext = {
        requestId: readLogContextValue(args?.requestId),
        ...logContext,
        bridgeRequestId: createDesktopRequestId(),
    };
    const startedAt = performance.now();
    try {
        if (!isDesktopRuntime()) throw new Error('该能力仅能在 URGS 桌面客户端中使用');
        const { invoke } = await import('@tauri-apps/api/core');
        return await invoke<T>(command, args);
    } catch (error) {
        await writeDesktopLog(
            'ERROR',
            'web.tauri.invoke',
            `command=${command} elapsed_ms=${Math.round(performance.now() - startedAt)} error=${describeDesktopError(error)}`,
            context,
        );
        throw error;
    }
};
