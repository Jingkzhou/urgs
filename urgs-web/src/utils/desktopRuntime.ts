import {
    applyRuntimeConfig,
    isDesktopRuntime,
    type RuntimeConfig,
} from '@/config';
import { invokeDesktop } from '@/services/grokDesktop';

export const initializeDesktopRuntimeConfig = async () => {
    if (!isDesktopRuntime()) {
        return;
    }

    try {
        const config = await invokeDesktop<RuntimeConfig | null>('load_desktop_runtime_config');
        if (config) {
            applyRuntimeConfig(config);
        }
    } catch (error) {
        console.error('加载桌面客户端配置失败', error);
    }
};

export const saveDesktopRuntimeConfig = async (config: Required<RuntimeConfig>) => {
    if (!isDesktopRuntime()) {
        throw new Error('当前不是桌面客户端环境');
    }

    const savedConfig = await invokeDesktop<Required<RuntimeConfig>>('save_desktop_runtime_config', { config });
    applyRuntimeConfig(savedConfig);
    return savedConfig;
};

export const openExternalUrl = async (url: string) => {
    if (!url) {
        return;
    }

    if (isDesktopRuntime()) {
        const { openUrl } = await import('@tauri-apps/plugin-opener');
        await openUrl(url);
        return;
    }

    window.open(url, '_blank', 'noopener,noreferrer');
};
