import { createHash } from 'node:crypto';
import { readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { dirname, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const desktopRoot = resolve(scriptDirectory, '..');
const defaultSidecarTarget = 'x86_64-pc-windows-msvc';

const toPortablePath = (value) => value.split(sep).join('/');

const listFiles = async (directory, predicate) => {
    try {
        const entries = await readdir(directory, { withFileTypes: true });
        return entries
            .filter((entry) => entry.isFile() && predicate(entry.name))
            .map((entry) => resolve(directory, entry.name))
            .sort();
    } catch (error) {
        if (error?.code === 'ENOENT') {
            return [];
        }
        throw error;
    }
};

const sha256 = async (filePath) => {
    const content = await readFile(filePath);
    return createHash('sha256').update(content).digest('hex');
};

const readJson = async (filePath, label) => {
    try {
        return JSON.parse(await readFile(filePath, 'utf8'));
    } catch (error) {
        throw new Error(`读取${label}失败：${error instanceof Error ? error.message : error}`);
    }
};

const verifySidecar = async ({
    sidecarPath,
    sidecarManifestPath,
    sidecarTarget,
    expectedVersion,
}) => {
    const manifest = await readJson(sidecarManifestPath, 'Grok sidecar 清单');
    const fileInfo = await stat(sidecarPath).catch((error) => {
        throw new Error(`未找到目标平台 Grok sidecar：${sidecarPath}：${error.message}`);
    });
    if (!fileInfo.isFile() || fileInfo.size === 0) {
        throw new Error(`Grok sidecar 不是有效的普通文件：${sidecarPath}`);
    }

    const digest = await sha256(sidecarPath);
    if (manifest.target !== sidecarTarget) {
        throw new Error(`Grok sidecar 目标不匹配：期望 ${sidecarTarget}，实际 ${manifest.target || '未声明'}`);
    }
    if (manifest.sha256 !== digest) {
        throw new Error(`Grok sidecar SHA-256 与清单不一致：期望 ${manifest.sha256 || '未声明'}，实际 ${digest}`);
    }
    if (manifest.sizeBytes !== fileInfo.size) {
        throw new Error(`Grok sidecar 大小与清单不一致：期望 ${manifest.sizeBytes || '未声明'}，实际 ${fileInfo.size}`);
    }
    if (expectedVersion && !String(manifest.version || '').includes(expectedVersion)) {
        throw new Error(`Grok sidecar 版本不匹配：期望 ${expectedVersion}，实际 ${manifest.version || '未声明'}`);
    }

    return {
        file: toPortablePath(relative(desktopRoot, sidecarPath)),
        target: manifest.target,
        version: manifest.version,
        sizeBytes: fileInfo.size,
        sha256: digest,
    };
};

export const verifyWindowsBundle = async ({
    bundleRoot = resolve(desktopRoot, 'src-tauri/target/release/bundle'),
    configPath = resolve(desktopRoot, 'src-tauri/tauri.conf.json'),
    environment = process.env,
    requireSidecar = true,
    sidecarTarget = environment.GROK_SIDECAR_TARGET || defaultSidecarTarget,
    sidecarPath = resolve(desktopRoot, `src-tauri/binaries/grok-${sidecarTarget}.exe`),
    sidecarManifestPath = resolve(desktopRoot, 'src-tauri/binaries/grok-sidecar-manifest.json'),
} = {}) => {
    const config = await readJson(configPath, 'Tauri 配置');
    const version = config.version;
    const externalBins = config.bundle?.externalBin || [];
    if (!externalBins.some((entry) => String(entry).endsWith('/grok') || String(entry) === 'grok')) {
        throw new Error('Tauri 配置未声明内置 Grok sidecar：bundle.externalBin 必须包含 binaries/grok');
    }
    if (config.bundle?.windows?.webviewInstallMode?.type !== 'offlineInstaller') {
        throw new Error('Windows 安装包未启用 WebView2 离线安装模式');
    }

    const msiFiles = await listFiles(resolve(bundleRoot, 'msi'), (name) => name.toLowerCase().endsWith('.msi'));
    const nsisFiles = await listFiles(resolve(bundleRoot, 'nsis'), (name) => name.toLowerCase().endsWith('-setup.exe'));

    if (msiFiles.length === 0) {
        throw new Error(`未在 ${resolve(bundleRoot, 'msi')} 找到 MSI 安装包`);
    }
    if (nsisFiles.length === 0) {
        throw new Error(`未在 ${resolve(bundleRoot, 'nsis')} 找到 NSIS setup.exe`);
    }

    const installers = [...msiFiles, ...nsisFiles];
    const artifacts = [];
    for (const filePath of installers) {
        const fileInfo = await stat(filePath);
        if (fileInfo.size === 0) {
            throw new Error(`安装包为空文件：${filePath}`);
        }
        if (!filePath.split(sep).pop().includes(version)) {
            throw new Error(`安装包文件名未包含配置版本 ${version}：${filePath}`);
        }

        artifacts.push({
            file: toPortablePath(relative(bundleRoot, filePath)),
            sizeBytes: fileInfo.size,
            sha256: await sha256(filePath),
        });
    }

    const grokSidecar = requireSidecar
        ? await verifySidecar({
            sidecarPath,
            sidecarManifestPath,
            sidecarTarget,
            expectedVersion: environment.GROK_BUILD_VERSION,
        })
        : null;

    const manifest = {
        productName: config.productName,
        version,
        commit: environment.GITHUB_SHA || null,
        workflowRunId: environment.GITHUB_RUN_ID || null,
        generatedAt: new Date().toISOString(),
        webviewInstallMode: config.bundle.windows.webviewInstallMode.type,
        grokSidecar,
        artifacts,
    };
    const manifestPath = resolve(bundleRoot, 'windows-build-manifest.json');
    const checksumsPath = resolve(bundleRoot, 'SHA256SUMS.txt');

    await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
    await writeFile(
        checksumsPath,
        `${artifacts.map((artifact) => `${artifact.sha256}  ${artifact.file}`).join('\n')}\n`,
        'utf8',
    );

    return { manifest, manifestPath, checksumsPath };
};

const isDirectExecution = process.argv[1]
    && resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isDirectExecution) {
    const bundleRoot = process.argv[2] ? resolve(process.argv[2]) : undefined;
    verifyWindowsBundle({ bundleRoot })
        .then(({ manifest, manifestPath, checksumsPath }) => {
            console.log(`Windows 安装包验收通过：${manifest.artifacts.length} 个文件，版本 ${manifest.version}`);
            console.log(`构建清单：${manifestPath}`);
            console.log(`校验文件：${checksumsPath}`);
        })
        .catch((error) => {
            console.error(error instanceof Error ? error.message : error);
            process.exitCode = 1;
        });
}
