import { spawnSync } from 'node:child_process';
import { copyFile, mkdir, realpath, stat, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, extname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const desktopRoot = resolve(scriptDirectory, '..');
const repositoryRoot = resolve(desktopRoot, '..');
const binariesDirectory = resolve(desktopRoot, 'src-tauri/binaries');

const parseTarget = () => {
    const targetIndex = process.argv.indexOf('--target');
    if (targetIndex >= 0 && process.argv[targetIndex + 1]) {
        return process.argv[targetIndex + 1];
    }
    if (process.env.TAURI_ENV_TARGET_TRIPLE) {
        return process.env.TAURI_ENV_TARGET_TRIPLE;
    }

    const rustc = spawnSync('rustc', ['-vV'], { encoding: 'utf8' });
    const hostLine = rustc.stdout.split('\n').find((line) => line.startsWith('host:'));
    if (!hostLine) {
        throw new Error('无法确定 Rust 目标平台，请通过 --target 指定，例如 x86_64-pc-windows-msvc');
    }
    return hostLine.replace('host:', '').trim();
};

const candidateSources = () => {
    const executable = process.platform === 'win32' ? '.exe' : '';
    return [
        process.env.GROK_SIDECAR_SOURCE,
        resolve(repositoryRoot, `grok-build/target/release/xai-grok-pager${executable}`),
        resolve(homedir(), `.grok/bin/grok${executable}`),
    ].filter(Boolean);
};

const findSource = async () => {
    for (const candidate of candidateSources()) {
        try {
            const resolved = await realpath(candidate);
            if ((await stat(resolved)).isFile()) {
                return resolved;
            }
        } catch {
            // 尝试下一个来源。
        }
    }
    throw new Error(
        '未找到 Grok Build 可执行文件。请先构建 grok-build，或设置 GROK_SIDECAR_SOURCE 指向 grok(.exe)。',
    );
};

const readVersion = (source) => {
    const result = spawnSync(source, ['--no-auto-update', '--version'], { encoding: 'utf8' });
    if (result.status !== 0) {
        throw new Error(`无法读取 Grok Build 版本：${result.stderr || result.error?.message || 'unknown error'}`);
    }
    return result.stdout.trim();
};

const targetExtension = (target) => target.includes('windows') ? '.exe' : '';

const main = async () => {
    const target = parseTarget();
    const destination = resolve(binariesDirectory, `grok-${target}${targetExtension(target)}`);
    let source;
    try {
        source = await findSource();
    } catch (error) {
        try {
            if ((await stat(destination)).isFile()) {
                console.log(`复用已准备的 Grok Build Sidecar：${destination}`);
                return;
            }
        } catch {
            // 当前目标平台尚未准备 Sidecar，继续抛出原始错误。
        }
        throw error;
    }
    const version = readVersion(source);

    await mkdir(binariesDirectory, { recursive: true });
    await copyFile(source, destination);
    await writeFile(
        resolve(binariesDirectory, 'grok-sidecar-manifest.json'),
        `${JSON.stringify({ source, target, version, generatedAt: new Date().toISOString() }, null, 2)}\n`,
        'utf8',
    );

    console.log(`已准备 Grok Build Sidecar：${destination}`);
    console.log(`版本：${version}`);
};

main().catch((error) => {
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
});
