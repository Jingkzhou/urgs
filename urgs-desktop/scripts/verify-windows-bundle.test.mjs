import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import test from 'node:test';
import { verifyWindowsBundle } from './verify-windows-bundle.mjs';

const createFixture = async ({ withNsis = true } = {}) => {
    const root = await mkdtemp(resolve(tmpdir(), 'urgs-windows-bundle-'));
    const bundleRoot = resolve(root, 'bundle');
    const configPath = resolve(root, 'tauri.conf.json');
    await mkdir(resolve(bundleRoot, 'msi'), { recursive: true });
    await mkdir(resolve(bundleRoot, 'nsis'), { recursive: true });
    await writeFile(configPath, JSON.stringify({
        productName: 'URGS',
        version: '0.1.0',
        bundle: {
            externalBin: ['binaries/grok'],
            windows: { webviewInstallMode: { type: 'offlineInstaller' } },
        },
    }), 'utf8');
    await writeFile(resolve(bundleRoot, 'msi/URGS_0.1.0_x64_zh-CN.msi'), 'msi-content', 'utf8');
    if (withNsis) {
        await writeFile(resolve(bundleRoot, 'nsis/URGS_0.1.0_x64-setup.exe'), 'exe-content', 'utf8');
    }
    return { root, bundleRoot, configPath };
};

test('生成同时包含 MSI 和 NSIS 的校验清单', async (t) => {
    const fixture = await createFixture();
    t.after(() => rm(fixture.root, { recursive: true, force: true }));

    const result = await verifyWindowsBundle({
        bundleRoot: fixture.bundleRoot,
        configPath: fixture.configPath,
        environment: { GITHUB_SHA: 'abc123', GITHUB_RUN_ID: '456' },
        requireSidecar: false,
    });

    assert.equal(result.manifest.version, '0.1.0');
    assert.equal(result.manifest.commit, 'abc123');
    assert.equal(result.manifest.artifacts.length, 2);
    assert.match(await readFile(result.checksumsPath, 'utf8'), /msi\/URGS_0\.1\.0_x64_zh-CN\.msi/);
    assert.match(await readFile(result.checksumsPath, 'utf8'), /nsis\/URGS_0\.1\.0_x64-setup\.exe/);
});

test('缺少 NSIS 安装包时验收失败', async (t) => {
    const fixture = await createFixture({ withNsis: false });
    t.after(() => rm(fixture.root, { recursive: true, force: true }));

    await assert.rejects(
        verifyWindowsBundle({ bundleRoot: fixture.bundleRoot, configPath: fixture.configPath, requireSidecar: false }),
        /未在 .* 找到 NSIS setup\.exe/,
    );
});

test('验收内置 Grok sidecar 的目标、版本、大小和 SHA-256', async (t) => {
    const fixture = await createFixture();
    const sidecarPath = resolve(fixture.root, 'grok-x86_64-pc-windows-msvc.exe');
    const sidecarManifestPath = resolve(fixture.root, 'grok-sidecar-manifest.json');
    await writeFile(sidecarPath, 'grok-sidecar-content', 'utf8');
    const sidecarDigest = createHash('sha256').update('grok-sidecar-content').digest('hex');
    await writeFile(sidecarManifestPath, JSON.stringify({
        target: 'x86_64-pc-windows-msvc',
        version: 'grok 0.2.121 (test)',
        sha256: sidecarDigest,
        sizeBytes: 20,
    }), 'utf8');
    t.after(() => rm(fixture.root, { recursive: true, force: true }));

    const result = await verifyWindowsBundle({
        bundleRoot: fixture.bundleRoot,
        configPath: fixture.configPath,
        environment: { GROK_BUILD_VERSION: '0.2.121' },
        sidecarPath,
        sidecarManifestPath,
        sidecarTarget: 'x86_64-pc-windows-msvc',
    });

    assert.equal(result.manifest.grokSidecar.version, 'grok 0.2.121 (test)');
    assert.equal(result.manifest.grokSidecar.sha256, sidecarDigest);
});
