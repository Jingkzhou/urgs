import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIRECTORY = fileURLToPath(new URL('.', import.meta.url));
const REPOSITORY_ROOT = resolve(SCRIPT_DIRECTORY, '..', '..');
const SUPPORTED_ENVIRONMENTS = new Set(['local', 'sit', 'prod']);

export const parseDeployEnv = (content) => Object.fromEntries(
    content
        .split(/\r?\n/)
        .map(line => line.trim())
        .filter(line => line && !line.startsWith('#') && line.includes('='))
        .map((line) => {
            const separator = line.indexOf('=');
            const key = line.slice(0, separator).trim();
            let value = line.slice(separator + 1).trim();
            if ((value.startsWith('"') && value.endsWith('"'))
                || (value.startsWith("'") && value.endsWith("'"))) {
                value = value.slice(1, -1);
            }
            return [key, value];
        }),
);

const normalizeHttpUrl = (value, name) => {
    const normalized = value?.trim().replace(/\/+$/, '') || '';
    let parsed;
    try {
        parsed = new URL(normalized);
    } catch {
        throw new Error(`${name} 不是有效地址`);
    }
    if (!['http:', 'https:'].includes(parsed.protocol)) {
        throw new Error(`${name} 仅支持 http/https`);
    }
    return normalized;
};

const normalizeWebSocketUrl = (value, name) => {
    const normalized = value?.trim().replace(/\/+$/, '') || '';
    let parsed;
    try {
        parsed = new URL(normalized);
    } catch {
        throw new Error(`${name} 不是有效地址`);
    }
    if (!['ws:', 'wss:'].includes(parsed.protocol)) {
        throw new Error(`${name} 仅支持 ws/wss`);
    }
    return normalized;
};

export const deriveWebSocketUrl = (apiBaseUrl) => {
    const url = new URL(apiBaseUrl);
    url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:';
    url.pathname = `${url.pathname.replace(/\/+$/, '')}/ws/im`;
    url.search = '';
    url.hash = '';
    return url.toString().replace(/\/+$/, '');
};

export const resolveDesktopRuntimeConfig = (content) => {
    const config = parseDeployEnv(content);
    const apiBaseUrl = normalizeHttpUrl(
        config.DESKTOP_API_BASE_URL || config.URGS_API_BASE_URL,
        'DESKTOP_API_BASE_URL',
    );
    const configuredWsUrl = config.DESKTOP_WS_URL || config.WEB_WS_URL;
    const wsUrl = configuredWsUrl
        ? normalizeWebSocketUrl(configuredWsUrl, 'DESKTOP_WS_URL')
        : deriveWebSocketUrl(apiBaseUrl);
    return { apiBaseUrl, wsUrl };
};

const buildWeb = () => {
    const environment = (process.env.DEPLOY_ENV || 'local').trim().toLowerCase();
    if (!SUPPORTED_ENVIRONMENTS.has(environment)) {
        throw new Error(`Desktop 构建环境仅支持 local/sit/prod，当前为 ${environment}`);
    }

    const deployEnvPath = resolve(REPOSITORY_ROOT, 'deploy', 'templates', `deploy.${environment}.env`);
    const runtimeConfig = resolveDesktopRuntimeConfig(readFileSync(deployEnvPath, 'utf8'));
    console.log(`Desktop ${environment} 默认 API: ${runtimeConfig.apiBaseUrl}`);
    console.log(`Desktop ${environment} 默认 WebSocket: ${runtimeConfig.wsUrl}`);

    const pnpmCommand = process.platform === 'win32' ? 'pnpm.cmd' : 'pnpm';
    const result = spawnSync(
        pnpmCommand,
        ['--dir', resolve(REPOSITORY_ROOT, 'urgs-web'), 'build', '--mode', 'desktop'],
        {
            stdio: 'inherit',
            env: {
                ...process.env,
                VITE_API_URL: runtimeConfig.apiBaseUrl,
                VITE_WS_URL: runtimeConfig.wsUrl,
            },
        },
    );

    if (result.error) {
        throw result.error;
    }
    if (result.status !== 0) {
        process.exitCode = result.status ?? 1;
    }
};

const isDirectExecution = process.argv[1]
    && resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isDirectExecution) {
    buildWeb();
}
