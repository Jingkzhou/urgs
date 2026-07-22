import { isDesktopRuntime } from '@/config';

const getAutostartApi = async () => import('@tauri-apps/plugin-autostart');

const getInvoke = async () => {
    const { invoke } = await import('@tauri-apps/api/core');
    return invoke;
};

export const initializeDesktopAutostart = async () => {
    if (!isDesktopRuntime()) {
        return false;
    }

    try {
        const [autostart, invoke] = await Promise.all([getAutostartApi(), getInvoke()]);
        const preference = await invoke<boolean | null>('load_desktop_auto_start_enabled');
        const enabled = preference ?? true;
        const registered = await autostart.isEnabled();

        if (enabled && !registered) {
            await autostart.enable();
        }
        if (!enabled && registered) {
            await autostart.disable();
        }
        if (preference === null) {
            await invoke('save_desktop_auto_start_enabled', { enabled });
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

    const [autostart, invoke] = await Promise.all([getAutostartApi(), getInvoke()]);
    if (enabled) {
        await autostart.enable();
    } else {
        await autostart.disable();
    }
    await invoke('save_desktop_auto_start_enabled', { enabled });
    return autostart.isEnabled();
};
