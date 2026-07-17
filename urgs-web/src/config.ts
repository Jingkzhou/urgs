/// <reference types="vite/client" />

export interface RuntimeConfig {
    VITE_API_URL?: string;
    VITE_WS_URL?: string;
}

declare global {
    interface Window {
        __RUNTIME_CONFIG__?: RuntimeConfig;
        __TAURI_INTERNALS__?: unknown;
    }
}

const normalizeBaseUrl = (value?: string) => value?.trim().replace(/\/+$/, '') || '';

const readRuntimeValue = (key: keyof RuntimeConfig) => {
    const runtimeValue = window.__RUNTIME_CONFIG__?.[key];
    if (runtimeValue?.trim()) {
        return normalizeBaseUrl(runtimeValue);
    }

    const buildTimeValue = import.meta.env[key];
    return typeof buildTimeValue === 'string' ? normalizeBaseUrl(buildTimeValue) : '';
};

export const isDesktopRuntime = () => typeof window !== 'undefined' && Boolean(window.__TAURI_INTERNALS__);

export const getApiBaseUrl = () => readRuntimeValue('VITE_API_URL');

export const deriveWebSocketUrl = (apiBaseUrl: string) => {
    const url = new URL(apiBaseUrl);
    url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:';
    url.pathname = `${url.pathname.replace(/\/+$/, '')}/ws/im`;
    url.search = '';
    url.hash = '';
    return normalizeBaseUrl(url.toString());
};

const getWebSocketUrl = () => {
    const configuredUrl = readRuntimeValue('VITE_WS_URL');
    if (configuredUrl) {
        return configuredUrl;
    }

    const apiBaseUrl = getApiBaseUrl();
    return apiBaseUrl ? deriveWebSocketUrl(apiBaseUrl) : 'ws://localhost:8080/ws/im';
};

export let WS_URL = getWebSocketUrl();

export const applyRuntimeConfig = (config: RuntimeConfig) => {
    window.__RUNTIME_CONFIG__ = {
        ...window.__RUNTIME_CONFIG__,
        ...config,
    };
    WS_URL = getWebSocketUrl();
};

const joinBaseUrl = (baseUrl: string, path: string) => {
    if (!baseUrl) {
        return path;
    }
    return `${baseUrl}${path.startsWith('/') ? path : `/${path}`}`;
};

const ABSOLUTE_URL_PATTERN = /^(?:[a-z][a-z\d+.-]*:|\/\/)/i;

export const resolveServiceUrl = (url: string) => {
    if (!url || !isDesktopRuntime() || ABSOLUTE_URL_PATTERN.test(url)) {
        return url;
    }

    if (url.startsWith('/api') || url.startsWith('/uploads') || url.startsWith('/profile')) {
        return joinBaseUrl(getApiBaseUrl(), url);
    }

    return url;
};

let serviceRequestAdaptersInstalled = false;

export const installServiceRequestAdapters = () => {
    if (serviceRequestAdaptersInstalled || !isDesktopRuntime()) {
        return;
    }

    const browserFetch = window.fetch.bind(window);
    window.fetch = (input: RequestInfo | URL, init?: RequestInit) => {
        if (typeof input === 'string') {
            return browserFetch(resolveServiceUrl(input), init);
        }
        return browserFetch(input, init);
    };

    const browserXhrOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (
        method: string,
        url: string | URL,
        async = true,
        username?: string | null,
        password?: string | null,
    ) {
        browserXhrOpen.call(this, method, resolveServiceUrl(String(url)), async, username, password);
    };

    serviceRequestAdaptersInstalled = true;
};
