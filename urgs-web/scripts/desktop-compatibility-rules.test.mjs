import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import {
  inspectAntdStaticStyleContract,
  inspectSource,
  inspectTauriStyleCspContract,
} from './desktop-compatibility-rules.mjs';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));

test('阻止普通页面重复占用视口高度', () => {
  const violations = inspectSource('src/components/NewPage.tsx', '<div className="h-screen" />');
  assert.equal(violations[0]?.rule, 'nested-viewport-height');
});

test('阻止没有最大宽度保护的大固定面板', () => {
  const violations = inspectSource('src/components/NewPage.tsx', '<div className="w-[940px]" />');
  assert.equal(violations[0]?.rule, 'unsafe-fixed-width');
});

test('允许带最大宽度保护的固定理想宽度', () => {
  const violations = inspectSource('src/components/NewPage.tsx', '<div className="w-[940px] max-w-[95vw]" />');
  assert.deepEqual(violations, []);
});

test('要求浏览器专属能力经过双端适配', () => {
  const violations = inspectSource('src/components/NewPage.tsx', 'window.open(targetUrl);');
  assert.equal(violations[0]?.rule, 'browser-only-api');
});

test('允许有具体原因的受控例外', () => {
  const source = [
    '// desktop-compat-allow: 独立画布窗口由自身持有完整视口',
    '<div className="h-screen" />',
  ].join('\n');
  assert.deepEqual(inspectSource('src/components/Canvas.tsx', source), []);
});

test('拒绝没有具体原因的例外注释', () => {
  const source = [
    '// desktop-compat-allow: 特例',
    '<div className="h-screen" />',
  ].join('\n');
  assert.equal(inspectSource('src/components/Canvas.tsx', source)[0]?.rule, 'invalid-allowance');
});

test('禁止无评审标记更新存量基线', () => {
  const result = spawnSync(process.execPath, [path.join(scriptDirectory, 'check-desktop-compatibility.mjs'), '--write-baseline'], {
    cwd: path.resolve(scriptDirectory, '..'),
    encoding: 'utf8',
    env: { ...process.env, DESKTOP_COMPAT_UPDATE_BASELINE: '' },
  });
  assert.notEqual(result.status, 0);
  assert.match(`${result.stdout}${result.stderr}`, /DESKTOP_COMPAT_UPDATE_BASELINE=1/);
});

test('要求 Ant Design 使用静态组件样式和稳定主题变量', () => {
  const validSource = [
    "import 'antd/dist/antd.css';",
    "<ConfigProvider theme={{ zeroRuntime: true, cssVar: { key: 'urgs' } }} />",
  ].join('\n');
  assert.deepEqual(inspectAntdStaticStyleContract(validSource), []);

  const invalidSource = "<ConfigProvider theme={{ zeroRuntime: false }} />";
  assert.equal(inspectAntdStaticStyleContract(invalidSource).length, 3);
});

test('要求 Tauri 保留 Ant Design 主题变量所需的 style-src', () => {
  const validConfig = {
    app: {
      security: {
        csp: "default-src 'self'; style-src 'self' 'unsafe-inline'",
        dangerousDisableAssetCspModification: ['style-src'],
      },
    },
  };
  assert.deepEqual(inspectTauriStyleCspContract(validConfig), []);

  const invalidConfig = { app: { security: { csp: "style-src 'self'" } } };
  assert.equal(inspectTauriStyleCspContract(invalidConfig).length, 2);
});
