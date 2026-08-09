# Web 与 Desktop 双端兼容开发规范

本规范适用于 `urgs-web` 中所有新增、修改、修复和删除的业务页面与功能。目标是让同一套 React 代码同时支持浏览器与 Tauri Desktop，禁止交付“Web 可用、Desktop 后补”的半成品。

## 一、运行环境基线

- Web：现代 Chromium 浏览器。
- macOS Desktop：Tauri WKWebView。
- Windows Desktop：Tauri WebView2。
- 必测实际内容宽度：约 `960px`、`1180px`、`1440px`。这里指扣除应用导航和内边距后的页面宽度，不是显示器分辨率。
- Desktop 最小窗口高度按 `700px` 验收，页面不得依赖浏览器地址栏之外的额外可用高度。
- Ant Design 固定使用静态组件样式模式：入口导入 `antd/dist/antd.css`，根 `ConfigProvider` 使用 `zeroRuntime: true` 和稳定的 `cssVar.key`。
- Ant Design 主题变量仍会生成内联 `<style>`。Tauri CSP 必须保留 `style-src 'unsafe-inline'`，并仅对 `style-src` 设置 `dangerousDisableAssetCspModification`；否则构建期 nonce 改写会让运行时主题变量被 WebView 拒绝，Portal 弹层退化成裸样式。

## 二、唯一视口所有者

只有 App Shell 可以拥有 `100dvh`。普通路由页面不得重新使用 `100vh`、`100dvh`、`h-screen`、`min-h-screen` 或 `100vw`。

应用层级固定为：

```text
html / body / #root
└── App Shell（唯一视口所有者）
    └── app-main（主滚动容器）
        └── PageViewport（容器查询上下文）
            └── AdaptivePage（业务页面）
```

新页面根节点默认写法：

```tsx
import { AdaptivePage } from '@/components/common/adaptive';

export default function ExamplePage() {
    return (
        <AdaptivePage className="space-y-4">
            {/* 页面内容 */}
        </AdaptivePage>
    );
}
```

需要页面自己滚动时使用 `scroll="page"`；画布等必须禁止外层滚动的页面使用 `scroll="none"`。不要在业务页面重新计算视口高度。

## 三、公共自适应组件

公共组件位于 `urgs-web/src/components/common/adaptive/`：

- `PageViewport`：由 App 统一装配，为所有现有和未来路由提供容器查询上下文。
- `AdaptivePage`：页面宽度、高度和滚动协议。
- `AdaptiveToolbar`：标题、筛选和操作区自动换行；禁止业务工具栏依赖单行固定宽度。
- `AdaptiveSplitLayout`：侧栏与主内容双栏，窄内容区自动切为单栏。
- `AdaptiveDataRegion`：表格、代码和宽画布的有意横向滚动区域，支持键盘聚焦。

响应式判断优先使用页面容器宽度，不要仅根据 `window.innerWidth` 或设备型号判断。页面 CSS 可使用：

```css
@container urgs-page-host (max-width: 960px) {
  .example-toolbar {
    flex-wrap: wrap;
  }
}
```

## 四、表格、弹窗与固定尺寸

- 数据表确需保留宽列时，必须放入 `AdaptiveDataRegion`，横向滚动只属于表格区域，不能把整页挤出窗口。
- 大弹窗使用 `.urgs-adaptive-overlay` 或同时提供理想宽度与视口保护，例如 `w-[960px] max-w-[95vw]`。
- 侧栏、抽屉和编辑器使用 `min()`、`max()`、`clamp()` 或 `max-width` 保护。
- Flex/Grid 中所有允许收缩的业务内容必须有 `min-width: 0`；Grid 内容列使用 `minmax(0, 1fr)`。
- 禁止用 `overflow-x-hidden` 掩盖裁切。先修收缩链路；确需宽内容时使用局部滚动。

## 五、浏览器与 Desktop 能力

以下能力不得在业务页面直接调用，必须使用已有双端适配器或补充适配器：

- 下载、Blob URL 和浏览器 `<a download>`。
- 文件选择、保存、剪贴板、全屏和打开新窗口。
- 依赖浏览器 Cookie、弹窗策略或地址栏行为的流程。

Desktop 判断统一使用 `isDesktopRuntime()`。Tauri API 只能在 Desktop 分支动态加载，不得让普通 Web 首屏静态执行原生命令。

## 六、静态门禁

每次前端功能改动都必须执行：

```bash
cd urgs-web
pnpm run test:desktop-compat
pnpm run check:desktop-compat
```

门禁会阻止新增：

- 内页完整视口高度或宽度。
- 无最大宽度保护的大固定面板。
- 未声明滚动意图的超宽最小宽度。
- 隐藏整页横向溢出。
- 未经过适配器的浏览器专属 API。
- Ant Design 静态 CSS、根主题模式或 Tauri `style-src` CSP 契约被破坏。

确属独立全屏画布、全屏弹窗或有意横向滚动时，在风险代码前增加具体原因：

```tsx
// desktop-compat-allow: 独立画布窗口由自身持有完整视口
```

禁止使用“特殊情况”“先放行”等无信息理由。`--write-baseline` 只用于首次建立基线或在评审确认后清理存量记录，且必须显式设置 `DESKTOP_COMPAT_UPDATE_BASELINE=1`；严禁用它吞掉新问题。

## 七、真实 Desktop 交付门禁

完成代码后必须：

1. 执行 Web 类型检查和构建。
2. 在 `urgs-desktop` 执行 `pnpm run prepare:grok && pnpm exec tauri build --debug`。
3. 完整覆盖 `/Applications/URGS.app`。
4. 校验构建产物与安装 App 可执行文件 SHA-256 一致。
5. 退出覆盖前的旧进程，再从 `/Applications/URGS.app` 启动。
6. 在约 `960px` 和正常宽度下验收主流程、工具栏、表格、弹窗、抽屉、下拉浮层、键盘焦点和滚动归属。
7. 打开 Desktop WebView 控制台，确认没有 CSP 拒绝运行时样式的错误。
8. 同一路由再做一次 Web 验收，确认 Desktop 适配没有回归浏览器。

构建成功不等于 Desktop 验收成功；旧进程仍在运行也不等于新 App 已生效。

## 八、新页面完成清单

- [ ] 页面继承 `PageViewport`，根节点使用 `AdaptivePage` 或同等契约。
- [ ] 工具栏在实际内容宽度 `960px` 下不裁切。
- [ ] 表格或画布的横向滚动被限制在自身区域。
- [ ] 弹窗、抽屉和浮层在最小窗口下完整可操作。
- [ ] 下载、文件、剪贴板、全屏和新窗口经过双端适配。
- [ ] `test:desktop-compat`、`check:desktop-compat`、TypeScript 和 Web 构建通过。
- [ ] 安装版 Desktop 已覆盖、哈希一致并完成真实业务验收。
