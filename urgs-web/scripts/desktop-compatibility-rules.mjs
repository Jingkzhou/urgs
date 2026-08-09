const MIN_FIXED_WIDTH = 640;
const MIN_UNBOUNDED_CONTENT_WIDTH = 900;

const normalizeSource = source => source.trim().replace(/\s+/g, ' ');

const parsePixelValues = (source, pattern) => {
  const values = [];
  for (const match of source.matchAll(pattern)) {
    values.push(Number(match[1]));
  }
  return values;
};

const RULES = [
  {
    id: 'nested-viewport-height',
    message: '普通页面不得重新占用完整视口高度，请使用 h-full/min-h-0 或 AdaptivePage。',
    match: source => /\b(?:h-screen|min-h-screen)\b|100d?vh/.test(source),
  },
  {
    id: 'unbounded-viewport-width',
    message: '普通页面不得直接使用完整视口宽度，请使用容器宽度或有边距的自适应浮层。',
    match: source => /\bw-screen\b|w-\[100vw\]|(?:^|[\s;{])width\s*:\s*[^;]*100vw|\bwidth\s*=\s*["'{][^"'}]*100vw/.test(source),
  },
  {
    id: 'unsafe-fixed-width',
    message: `大于等于 ${MIN_FIXED_WIDTH}px 的固定宽度必须同时提供 max-width 保护或改用自适应布局。`,
    match: source => {
      const hasMaxWidthGuard = /\bmax-w-(?:full|\[[^\]]+\])|max-width\s*:/.test(source);
      const tailwindWidths = parsePixelValues(source, /(?<!min-)(?<!max-)\bw-\[(\d+)px\]/g);
      const cssWidths = parsePixelValues(source, /(?:^|[\s;{])width\s*:\s*(\d+)px/g);
      const componentWidths = parsePixelValues(source, /\bwidth\s*=\s*\{(\d+)\}/g);
      return !hasMaxWidthGuard && [...tailwindWidths, ...cssWidths, ...componentWidths].some(value => value >= MIN_FIXED_WIDTH);
    },
  },
  {
    id: 'unsafe-min-width',
    message: `大于等于 ${MIN_UNBOUNDED_CONTENT_WIDTH}px 的最小宽度必须放入 AdaptiveDataRegion，并显式说明横向滚动意图。`,
    match: source => {
      const tailwindWidths = parsePixelValues(source, /\bmin-w-\[(\d+)px\]/g);
      const cssWidths = parsePixelValues(source, /(?:^|[\s;{])min-width\s*:\s*(\d+)px/g);
      return [...tailwindWidths, ...cssWidths].some(value => value >= MIN_UNBOUNDED_CONTENT_WIDTH);
    },
  },
  {
    id: 'hidden-horizontal-overflow',
    message: '新增 overflow-x-hidden 会掩盖 Desktop 裁切，请改为可收缩布局或局部滚动区域。',
    match: source => /\boverflow-x-hidden\b|overflow-x\s*:\s*hidden/.test(source),
  },
  {
    id: 'browser-only-api',
    message: '浏览器专属能力必须通过双端适配器调用，或用 desktop-compat-allow 注释说明已验证的保护条件。',
    match: source => /\bwindow\.open\s*\(|\bnavigator\.clipboard\b|\bURL\.createObjectURL\b|\bshowSaveFilePicker\b|\brequestFullscreen\s*\(|\bdocument\.execCommand\b|\bdownload\s*=/.test(source),
  },
];

const allowancePattern = /desktop-compat-allow:\s*(.+?)(?:\s*\*\/|\s*-->\s*|\s*\*\}|$)/;

const isValidAllowance = reason => reason && reason.trim().length >= 8;

export const inspectSource = (file, content) => {
  const violations = [];
  const lines = content.split(/\r?\n/);
  let pendingAllowance = null;

  lines.forEach((source, index) => {
    const allowanceMatch = source.match(allowancePattern);
    const inlineAllowance = allowanceMatch?.[1]?.trim();

    if (allowanceMatch && !isValidAllowance(inlineAllowance)) {
      violations.push({
        file,
        line: index + 1,
        rule: 'invalid-allowance',
        message: 'desktop-compat-allow 必须填写不少于 8 个字符的具体原因。',
        source: normalizeSource(source),
      });
      pendingAllowance = null;
      return;
    }

    if (allowanceMatch && normalizeSource(source).replace(allowancePattern, '').replace(/[{}/*<!>-]/g, '').trim() === '') {
      pendingAllowance = inlineAllowance;
      return;
    }

    const allowance = inlineAllowance || pendingAllowance;
    const matchedRules = RULES.filter(rule => rule.match(source));

    if (matchedRules.length > 0 && !isValidAllowance(allowance)) {
      matchedRules.forEach(rule => violations.push({
        file,
        line: index + 1,
        rule: rule.id,
        message: rule.message,
        source: normalizeSource(source),
      }));
    }

    if (source.trim() && pendingAllowance) {
      pendingAllowance = null;
    }
  });

  return violations;
};

export const violationKey = violation => `${violation.file}\u0000${violation.rule}\u0000${violation.source}`;

export const summarizeViolations = violations => {
  const summary = new Map();
  violations.forEach(violation => {
    const key = violationKey(violation);
    const existing = summary.get(key);
    if (existing) {
      existing.count += 1;
      existing.lines.push(violation.line);
    } else {
      summary.set(key, { ...violation, count: 1, lines: [violation.line] });
    }
  });
  return [...summary.values()].sort((left, right) => (
    left.file.localeCompare(right.file)
    || left.rule.localeCompare(right.rule)
    || left.source.localeCompare(right.source)
  ));
};

export const inspectAntdStaticStyleContract = mainSource => {
  const errors = [];
  if (!/import\s+['"]antd\/dist\/antd\.css['"]/.test(mainSource)) {
    errors.push('根入口必须导入 antd/dist/antd.css，避免 Desktop 依赖运行时组件样式注入。');
  }
  if (!/zeroRuntime\s*:\s*true/.test(mainSource)) {
    errors.push('根 ConfigProvider 必须启用 zeroRuntime: true，与 Ant Design 静态 CSS 模式保持一致。');
  }
  if (!/cssVar\s*:\s*\{\s*key\s*:\s*['"][^'"]+['"]\s*\}/.test(mainSource)) {
    errors.push('根 ConfigProvider 必须设置稳定的 cssVar.key，保证 Portal 弹层获得同一套主题变量。');
  }
  return errors;
};

export const inspectTauriStyleCspContract = tauriConfig => {
  const security = tauriConfig?.app?.security;
  const csp = typeof security?.csp === 'string' ? security.csp : '';
  const disabledModifications = security?.dangerousDisableAssetCspModification;
  const preservesRuntimeStyles = Array.isArray(disabledModifications)
    && disabledModifications.includes('style-src');
  const errors = [];

  if (!/style-src[^;]*'unsafe-inline'/.test(csp)) {
    errors.push("Tauri CSP 的 style-src 必须允许 'unsafe-inline'，供 Ant Design 主题变量运行时生成。");
  }
  if (!preservesRuntimeStyles) {
    errors.push('Tauri 必须仅对 style-src 禁用构建期 CSP 改写，防止 unsafe-inline 被 nonce 替换。');
  }
  return errors;
};
