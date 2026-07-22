import { cp, mkdir, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import { basename, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const usage = () => {
    console.error('用法: node deploy/prepare-desktop-updater.mjs --source <签名工件目录> --output <输出目录> --base-url <内网更新根地址> --version <客户端版本>');
};

const parseArgs = (args) => {
    const values = {};
    for (let index = 0; index < args.length; index += 2) {
        const key = args[index];
        const value = args[index + 1];
        if (!key?.startsWith('--') || !value) {
            usage();
            throw new Error('参数不完整');
        }
        values[key.slice(2)] = value;
    }
    return values;
};

const listFiles = async (directory) => {
    const entries = await readdir(directory, { withFileTypes: true });
    const files = [];
    for (const entry of entries) {
        const path = resolve(directory, entry.name);
        if (entry.isDirectory()) {
            files.push(...await listFiles(path));
        } else if (entry.isFile()) {
            files.push(path);
        }
    }
    return files;
};

const requireSingleFile = (files, label) => {
    if (files.length !== 1) {
        throw new Error(`${label}必须且只能有一个，实际找到 ${files.length} 个`);
    }
    return files[0];
};

const readSignature = async (installerPath) => {
    const signaturePath = `${installerPath}.sig`;
    try {
        const signature = (await readFile(signaturePath, 'utf8')).trim();
        if (!signature) {
            throw new Error('签名内容为空');
        }
        return { signaturePath, signature };
    } catch (error) {
        if (error?.code === 'ENOENT') {
            throw new Error(`缺少更新签名文件：${signaturePath}`);
        }
        throw error;
    }
};

const normalizeBaseUrl = (value) => {
    const url = new URL(value);
    if (!['http:', 'https:'].includes(url.protocol)) {
        throw new Error('DESKTOP_UPDATER_BASE_URL 只支持 http 或 https 地址');
    }
    if (['github.com', 'api.github.com'].includes(url.hostname)) {
        throw new Error('DESKTOP_UPDATER_BASE_URL 不能指向 GitHub；SIT/生产更新必须使用内网地址');
    }
    return value.replace(/\/+$/, '');
};

const artifactUrl = (baseUrl, filePath) => `${baseUrl}/${encodeURIComponent(basename(filePath))}`;

export const prepareDesktopUpdater = async ({ sourceDir, outputDir, baseUrl, version }) => {
    if (!version) {
        throw new Error('缺少客户端版本号');
    }
    const source = resolve(sourceDir);
    const sourceInfo = await stat(source);
    if (!sourceInfo.isDirectory()) {
        throw new Error(`签名工件目录不存在：${source}`);
    }

    const files = await listFiles(source);
    const nsisInstaller = requireSingleFile(
        files.filter((file) => /-setup\.exe$/i.test(file)),
        'NSIS setup.exe',
    );
    const msiInstaller = requireSingleFile(
        files.filter((file) => /\.msi$/i.test(file)),
        'MSI 安装包',
    );
    const nsis = await readSignature(nsisInstaller);
    const msi = await readSignature(msiInstaller);
    const updaterBaseUrl = normalizeBaseUrl(baseUrl);

    await mkdir(outputDir, { recursive: true });
    await Promise.all([
        cp(nsisInstaller, resolve(outputDir, basename(nsisInstaller))),
        cp(nsis.signaturePath, resolve(outputDir, basename(nsis.signaturePath))),
        cp(msiInstaller, resolve(outputDir, basename(msiInstaller))),
        cp(msi.signaturePath, resolve(outputDir, basename(msi.signaturePath))),
    ]);

    const manifest = {
        version,
        notes: 'URGS Windows 客户端自动更新版本。',
        pub_date: new Date().toISOString(),
        platforms: {
            'windows-x86_64': {
                signature: nsis.signature,
                url: artifactUrl(updaterBaseUrl, nsisInstaller),
            },
            'windows-x86_64-nsis': {
                signature: nsis.signature,
                url: artifactUrl(updaterBaseUrl, nsisInstaller),
            },
            'windows-x86_64-msi': {
                signature: msi.signature,
                url: artifactUrl(updaterBaseUrl, msiInstaller),
            },
        },
    };
    await writeFile(resolve(outputDir, 'latest.json'), `${JSON.stringify(manifest, null, 2)}\n`, 'utf8');
    return manifest;
};

const isDirectExecution = process.argv[1]
    && resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isDirectExecution) {
    const args = parseArgs(process.argv.slice(2));
    prepareDesktopUpdater({
        sourceDir: args.source,
        outputDir: args.output,
        baseUrl: args['base-url'],
        version: args.version,
    }).then((manifest) => {
        console.log(`Windows 自动更新工件已准备完成：${manifest.version}`);
    }).catch((error) => {
        console.error(error instanceof Error ? error.message : error);
        process.exitCode = 1;
    });
}
