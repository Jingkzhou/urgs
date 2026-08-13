import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const desktopRoot = resolve(scriptDirectory, '..');
const tauriCliPath = resolve(desktopRoot, 'node_modules/@tauri-apps/cli/tauri.js');

const endpoint = process.env.JL_INTELLIGENT_CENTER_UPDATER_ENDPOINT;
if (!endpoint) {
    throw new Error('缺少 JL_INTELLIGENT_CENTER_UPDATER_ENDPOINT，例如 http://25.18.17.210:18080/jl-intelligent-center/latest.json');
}

const url = new URL(endpoint);
if (!['http:', 'https:'].includes(url.protocol) || ['github.com', 'api.github.com'].includes(url.hostname)) {
    throw new Error('JL_INTELLIGENT_CENTER_UPDATER_ENDPOINT 必须是 SIT 或生产内网的 http(s) 更新地址，不能使用 GitHub');
}

const configDir = await mkdtemp(resolve(tmpdir(), 'jl-intelligent-center-updater-'));
const configPath = resolve(configDir, 'tauri.updater.override.json');
await writeFile(configPath, `${JSON.stringify({
    plugins: {
        updater: {
            endpoints: [endpoint],
            dangerousInsecureTransportProtocol: url.protocol === 'http:',
        },
    },
}, null, 2)}\n`, 'utf8');

try {
    const result = spawnSync(process.execPath, [tauriCliPath, 'build', '--config', configPath, '--verbose'], {
        cwd: desktopRoot,
        env: process.env,
        stdio: 'inherit',
    });
    if (result.error) {
        throw result.error;
    }
    if (result.status !== 0) {
        process.exitCode = result.status ?? 1;
    }
} finally {
    await rm(configDir, { recursive: true, force: true });
}
