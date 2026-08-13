import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

test('独立 App 持有唯一桌面视口', () => {
  const source = readFileSync(new URL('../src/components/task-center/ArkDesktopPage.tsx', import.meta.url), 'utf8');
  assert.match(source, /h-screen/);
});

test('独立 App 未引入 Unicode 弯引号', () => {
  const source = readFileSync(new URL('../src/main.tsx', import.meta.url), 'utf8');
  assert.doesNotMatch(source, /[\u2018\u2019\u201c\u201d]/);
});

test('主窗口以非全屏模式在屏幕中央启动', () => {
  const config = JSON.parse(readFileSync(new URL('../src-tauri/tauri.conf.json', import.meta.url), 'utf8'));
  const [mainWindow] = config.app.windows;
  assert.equal(mainWindow.width, 1180);
  assert.equal(mainWindow.height, 720);
  assert.equal(mainWindow.center, true);
  assert.equal(mainWindow.maximized, false);
  assert.equal(mainWindow.fullscreen, false);
});
