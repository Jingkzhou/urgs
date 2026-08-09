import { readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  inspectAntdStaticStyleContract,
  inspectSource,
  inspectTauriStyleCspContract,
  summarizeViolations,
  violationKey,
} from './desktop-compatibility-rules.mjs';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDirectory, '..');
const sourceRoot = path.join(projectRoot, 'src');
const baselinePath = path.join(scriptDirectory, 'desktop-compatibility-baseline.json');
const supportedExtensions = new Set(['.css', '.scss', '.ts', '.tsx']);

const collectSourceFiles = async directory => {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(entries.map(async entry => {
    const absolutePath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      return collectSourceFiles(absolutePath);
    }
    return supportedExtensions.has(path.extname(entry.name)) ? [absolutePath] : [];
  }));
  return nested.flat();
};

const collectViolations = async () => {
  const files = await collectSourceFiles(sourceRoot);
  const violations = [];
  for (const absolutePath of files) {
    const relativePath = path.relative(projectRoot, absolutePath).split(path.sep).join('/');
    const content = await readFile(absolutePath, 'utf8');
    violations.push(...inspectSource(relativePath, content));
  }
  return summarizeViolations(violations);
};

const writeBaseline = async violations => {
  const records = violations.map(({ file, rule, source, count }) => ({ file, rule, source, count }));
  await writeFile(baselinePath, `${JSON.stringify({ version: 1, records }, null, 2)}\n`, 'utf8');
  console.log(`已更新 Desktop 兼容基线：${records.length} 条存量模式。`);
};

const loadBaseline = async () => {
  try {
    const value = JSON.parse(await readFile(baselinePath, 'utf8'));
    if (value.version !== 1 || !Array.isArray(value.records)) {
      throw new Error('基线格式无效');
    }
    return value.records;
  } catch (error) {
    throw new Error(`无法读取 ${path.relative(projectRoot, baselinePath)}：${error.message}`);
  }
};

const formatViolation = violation => {
  const lines = violation.lines.join(',');
  return `${violation.file}:${lines} [${violation.rule}] ${violation.message}\n  ${violation.source}`;
};

const main = async () => {
  const mainSource = await readFile(path.join(sourceRoot, 'main.tsx'), 'utf8');
  const staticStyleErrors = inspectAntdStaticStyleContract(mainSource);
  const tauriConfigPath = path.resolve(projectRoot, '../urgs-desktop/src-tauri/tauri.conf.json');
  const tauriConfig = JSON.parse(await readFile(tauriConfigPath, 'utf8'));
  const tauriStyleCspErrors = inspectTauriStyleCspContract(tauriConfig);
  const styleContractErrors = [...staticStyleErrors, ...tauriStyleCspErrors];
  if (styleContractErrors.length > 0) {
    console.error('Desktop Ant Design 样式契约失败：');
    console.error(styleContractErrors.map(error => `- ${error}`).join('\n'));
    process.exitCode = 1;
    return;
  }

  const violations = await collectViolations();
  const shouldWriteBaseline = process.argv.includes('--write-baseline');
  const shouldListAll = process.argv.includes('--list-all');

  if (shouldWriteBaseline) {
    if (process.env.DESKTOP_COMPAT_UPDATE_BASELINE !== '1') {
      throw new Error('更新兼容基线需要显式设置 DESKTOP_COMPAT_UPDATE_BASELINE=1，并完成存量风险评审。');
    }
    await writeBaseline(violations);
    return;
  }

  if (shouldListAll) {
    console.log(violations.map(formatViolation).join('\n'));
    console.log(`共发现 ${violations.length} 类存量兼容风险。`);
    return;
  }

  const baseline = await loadBaseline();
  const baselineCounts = new Map(baseline.map(record => [violationKey(record), record.count]));
  const regressions = violations.filter(violation => violation.count > (baselineCounts.get(violationKey(violation)) || 0));

  if (regressions.length > 0) {
    console.error('Desktop 双端兼容门禁失败。新增风险如下：');
    console.error(regressions.map(formatViolation).join('\n'));
    console.error('\n请改用 common/adaptive 组件；确属全屏画布或局部滚动时，添加 desktop-compat-allow: 具体原因。');
    process.exitCode = 1;
    return;
  }

  console.log(`Desktop 双端兼容门禁通过；当前 ${violations.length} 类存量风险未增加。`);
};

await main();
