import { isDesktopRuntime } from '@/config';
import { invokeDesktop } from '@/services/desktopBridge';

const getAutostartApi = async () => import('@tauri-apps/plugin-autostart');

export const initializeDesktopAutostart = async () => {
    if (!isDesktopRuntime()) {
        return false;
    }

    try {
        const autostart = await getAutostartApi();
        const preference = await invokeDesktop<boolean | null>('load_desktop_auto_start_enabled');
        const enabled = preference ?? true;
        const registered = await autostart.isEnabled();

        if (enabled && !registered) {
            await autostart.enable();
        }
        if (!enabled && registered) {
            await autostart.disable();
        }
        if (preference === null) {
            await invokeDesktop('save_desktop_auto_start_enabled', { enabled });
        }

        return enabled;
    } catch (error) {
        console.error('初始化开机自启动失败', error);
        return false;
    }
};

export const getDesktopAutostartEnabled = async () => {
    if (!isDesktopRuntime()) {
        return false;
    }

    const autostart = await getAutostartApi();
    return autostart.isEnabled();
};

export const setDesktopAutostartEnabled = async (enabled: boolean) => {
    if (!isDesktopRuntime()) {
        throw new Error('当前不是桌面客户端环境');
    }

    const autostart = await getAutostartApi();
    if (enabled) {
        await autostart.enable();
    } else {
        await autostart.disable();
    }
    await invokeDesktop('save_desktop_auto_start_enabled', { enabled });
    return autostart.isEnabled();
};
