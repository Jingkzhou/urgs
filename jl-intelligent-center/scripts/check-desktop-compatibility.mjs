import { readFileSync, readdirSync, statSync } from 'node:fs';
import { resolve } from 'node:path';

const sourceRoot = resolve('src');
const violations = [];

const scan = (directory) => {
  for (const name of readdirSync(directory)) {
    const path = resolve(directory, name);
    if (statSync(path).isDirectory()) {
      scan(path);
      continue;
    }
    if (!/\.(?:ts|tsx|css)$/.test(name)) continue;
    const content = readFileSync(path, 'utf8');
    if (/[\u2018\u2019\u201c\u201d]/.test(content)) violations.push(`${path}: 包含 Unicode 弯引号`);
  }
};

scan(sourceRoot);
if (violations.length) {
  console.error(violations.join('\n'));
  process.exit(1);
}
console.log('JLIntelligentCenter Desktop 兼容静态检查通过');

