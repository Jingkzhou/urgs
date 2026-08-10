import { isDesktopRuntime } from '@/config';
import { describeDesktopError, writeDesktopLog } from '@/services/grokDesktop';

let installed = false;

const currentRoute = () => {
    if (typeof window === 'undefined') return 'unknown';
    const hash = window.location.hash.split('?')[0];
    return `${window.location.pathname}${hash}`.slice(0, 240);
};

const sourcePath = (filename: string) => {
    if (!filename) return '';
    try {
        return new URL(filename, window.location.href).pathname.slice(0, 240);
    } catch {
        return filename.slice(0, 240);
    }
};

export const installDesktopErrorLogging = () => {
    if (installed || typeof window === 'undefined' || !isDesktopRuntime()) return;
    installed = true;

    window.addEventListener('error', (event) => {
        const details = event.error
            ? describeDesktopError(event.error, true)
            : event.message || '未知脚本错误';
        void writeDesktopLog(
            'ERROR',
            'web.runtime',
            `route=${currentRoute()} message=${details} source=${sourcePath(event.filename)} line=${event.lineno || 0} col=${event.colno || 0}`,
        );
    });

    window.addEventListener('unhandledrejection', (event) => {
        void writeDesktopLog(
            'ERROR',
            'web.promise',
            `route=${currentRoute()} reason=${describeDesktopError(event.reason, true)}`,
        );
    });
};
