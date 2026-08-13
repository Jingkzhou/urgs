import { createHash } from 'node:crypto';
import { readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { dirname, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const desktopRoot = resolve(scriptDirectory, '..');

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

export const verifyWindowsBundle = async ({
    bundleRoot = resolve(desktopRoot, 'src-tauri/target/release/bundle'),
    configPath = resolve(desktopRoot, 'src-tauri/tauri.conf.json'),
    environment = process.env,
} = {}) => {
    const config = await readJson(configPath, 'Tauri 配置');
    const version = config.version;
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

    const manifest = {
        productName: config.productName,
        version,
        commit: environment.GITHUB_SHA || null,
        workflowRunId: environment.GITHUB_RUN_ID || null,
        generatedAt: new Date().toISOString(),
        webviewInstallMode: config.bundle.windows.webviewInstallMode.type,
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
