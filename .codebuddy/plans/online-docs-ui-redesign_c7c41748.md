---
name: online-docs-ui-redesign
overview: 将 OnlineDocsTool 组件从卡片网格布局重构为类似文件管理器的列表视图，包含快速访问区域、Tab 切换（最近/空间/收藏）、表格列表、行内操作等设计稿中的 UI 元素。
design:
  architecture:
    framework: react
  styleKeywords:
    - Enterprise File Manager
    - Clean Minimalism
    - Table-based Layout
    - Hover-reveal Actions
    - Flat Design with Subtle Shadows
  fontSystem:
    fontFamily: PingFang SC
    heading:
      size: 16px
      weight: 600
    subheading:
      size: 14px
      weight: 500
    body:
      size: 13px
      weight: 400
  colorSystem:
    primary:
      - "#1677FF"
      - "#4096FF"
    background:
      - "#FFFFFF"
      - "#FAFAFA"
      - "#F5F5F5"
    text:
      - "#1F1F1F"
      - "#595959"
      - "#8C8C8C"
    functional:
      - "#1677FF"
      - "#52C41A"
      - "#FA8C16"
      - "#722ED1"
      - "#FF4D4F"
todos:
  - id: refactor-layout
    content: 改造 OnlineDocsTool 整体布局结构：添加快速访问栏、Tab 导航栏、Table 列表容器，替换原有 Grid 卡片布局
    status: completed
  - id: implement-table-view
    content: 实现 Ant Design Table 列表视图：定义 columns（名称/所有者/位置/时间/大小/操作），配置行 hover 操作显示，文件类型彩色图标
    status: completed
    dependencies:
      - refactor-layout
  - id: add-quick-access-tabs
    content: 实现快速访问区域和 Tab 切换逻辑：快速访问取前4条文档，Tab 切换 activeTab 状态，空态占位处理
    status: completed
    dependencies:
      - refactor-layout
  - id: polish-toolbar-decoration
    content: 完善顶部工具栏（搜索/刷新/新建/上传/显示/筛选）和右下角装饰吉祥物，统一细节样式打磨
    status: completed
    dependencies:
      - implement-table-view
      - add-quick-access-tabs
---

## 产品概述

将在线文档管理页面（OnlineDocsTool）从当前卡片式网格布局改造为类似文件管理器的**列表视图布局**，参考用户提供的设计稿样式。

## 核心功能

- **快速访问区域**：页面顶部横向展示最近访问的文档快捷卡片（带图标+名称），点击可快速打开
- **Tab 切换栏**：「最近」（默认选中）、「空间」、「收藏」三个 Tab 标签，切换不同视图模式
- **列表表格视图**：使用 Ant Design Table 组件替代现有 grid 卡片，列包括：名称（含文件类型图标）、所有者、位置、最近查看时间（可排序）、文件大小
- **行内操作**：鼠标 hover 行时显示「链接复制」图标和「更多(...)」下拉菜单（包含编辑/下载/重命名/删除等操作）
- **顶部工具栏**：保留搜索框、刷新、新建、上传按钮，新增右侧「显示方式」和「筛选」控件
- **右下角装饰元素**：~~不需要~~（对标腾讯文档简洁风格）
- **保持不变的功能**：OnlyOffice 在线编辑弹窗、新建文档 Modal、重命名 Modal、上传/下载/删除等全部业务逻辑

## 技术栈

- 前端框架：React + TypeScript + Vite
- UI 组件库：Ant Design（Table, Dropdown, Tabs, Tooltip 等）
- 样式方案：TailwindCSS
- 图标库：lucide-react

## 实现方案

### 整体策略

采用 Ant Design Table 组件替换现有的 Grid 卡片布局，在单一组件 `OnlineDocsTool.tsx` 内完成 UI 改造。后端 API 和数据结构不做任何修改，「所有者」和「位置」字段使用前端模拟值填充（因为后端 Entity 暂无这些字段），Tab 中的「空间」「收藏」暂时显示空状态。

### 关键技术决策

1. **Table vs 自定义列表**：选用 Ant Design `Table` 组件而非自定义 div 列表，因为它原生支持排序（`sorter`）、行 hover 效果（`onRow`）、列定义（`columns`）、分页（`pagination`），与设计稿高度匹配
2. **快速访问数据来源**：取 `documents` 数组的前 4 个作为快速访问项，无需额外 API
3. **文件图标颜色区分**：根据 `fileName` 后缀返回不同颜色的图标（docx 蓝色、xlsx 绿色、pptx 橙色、pdf 红色）
4. **行内操作**：利用 Table 的 `onRow` 回调实现 hover 状态控制，操作列在 hover 时才显示链接和更多菜单
5. **「空间」和「收藏」Tab**：前端 mock 占位，切换时显示 Empty 提示"功能开发中"
6. **装饰吉祥物**：使用 CSS 绘制或 emoji 占位，固定定位于右下角

### 架构设计

```
OnlineDocsTool (重构)
├── QuickAccessBar      — 快速访问横向标签栏（取 documents 前 N 个）
├── TabBar              — 最近 | 空间 | 收藏 Tab 切换
├── Toolbar             — 搜索 + 刷新 + 新建 + 上传 + 显示/筛选
├── DocumentTable       — Ant Design Table 主列表
│   ├── NameColumn      — 文件图标(彩色) + 文件名(可点击打开)
│   ├── OwnerColumn     — 所有者(固定显示"我")
│   ├── LocationColumn  — 位置路径(固定显示文档名)
│   ├── TimeColumn      — 最近查看时间(可排序)
│   ├── SizeColumn      — 文件大小
│   └── ActionColumn    — hover 显示: 链接图标 + 更多下拉菜单
├── Pagination          — 分页器（可用 Table 自带的 pagination 属性）
├── Modals              — 新建/重命名 Modal (保持不变)
└── OnlyOfficeEditor    — 在线编辑器 Modal (保持不变)
```

## 目录结构

```
urgs-web/src/components/tools/
├── OnlineDocsTool.tsx        # [MODIFY] 主要改造目标：从 Grid 卡片改为 Table 列表视图
├── OnlyOfficeEditorModal.tsx # [不修改] 保持不变
└── ToolsPage.tsx             # [不修改] 外层容器不变
```

## 实现注意事项

- **性能**：Table 使用 `rowKey="id"` 保证渲染效率；快速访问仅取前 4 条数据无需分页
- **向后兼容**：所有原有 API 调用（list/create/delete/upload/rename/edit）完全不变
- **状态管理**：新增 `activeTab` state（'recent'|'space'|'favorite'），仅 'recent' tab 加载数据
- **文件图标工具函数**：内部实现 `getFileIconColor(fileName)` 根据 extension 返回对应颜色和 lucide 图标
- **表格排序**：时间列使用 `updateTime` 做 sorter 排序
- **Dropdown 更多菜单**：包含「在线打开」「下载」「重命名」「删除」四项

## 设计概述

参考设计稿，将在线文档页面改造成专业的文件管理器风格界面。整体为白底简洁布局，层次清晰。

## 设计风格

采用现代企业级文件管理器设计风格，类似飞书文档/钉盘的视觉语言。白色主背景配合浅灰分割线，信息密度适中，操作直觉化。

## 页面结构设计

### 页面 1: 在线文档管理器主页（唯一页面）

#### 区块 1 - 快速访问区（Quick Access Bar）

- **位置**: 页面最顶部，白色背景，下方细线分割
- **布局**: 横向排列的文档快捷入口卡片
- **内容**: 每个卡片左侧显示文件类型小图标（带背景色块），右侧显示文档名称（截断省略），最多展示 4 个最近访问文档
- **交互**: 卡片 hover 时出现微阴影上浮效果，点击直接用 OnlyOffice 打开文档
- **样式**: 圆角标签样式，浅色边框包裹，紧凑间距

#### 区块 2 - Tab 导航栏

- **位置**: 快速访问区下方
- **布局**: 左侧三个 Tab 标签（最近 / 空间 / 收藏），右侧放置「显示」图标按钮和「筛选」下拉按钮
- **样式**: 「最近」选中态为粗体文字+底部蓝色下划线；未选中态为常规灰色文字；hover 有过渡动画
- **交互**: 点击 Tab 切换内容区域（仅「最近」有实际数据）

#### 区块 3 - 文档列表表格

- **位置**: 页面主体区域
- **组件**: Ant Design Table，无边框简洁风格
- **表头**: 名称 | 所有者 | 位置 | 最近查看▼ | 文件大小
- **表体每行**:
- **名称列**: 彩色文件图标(16px) + 文档标题(可点击打开)，根据文件类型着色（Word蓝/Excel绿/PPT橙/PDF紫）
- **所有者列**: 固定显示"我"
- **位置列**: 显示所属目录路径（暂用文档名代替）
- **时间列**: 格式 MM-dd HH:mm，支持点击表头排序
- **文件大小列**: 格式化为 KB/MB，无数据显示 "-"
- **操作列(隐藏→hover显示)**: 链接图标(复制链接) + 三点更多菜单(编辑/下载/重命名/删除)
- **交互**: 行 hover 时背景变浅灰，同时浮现操作按钮；行间隔使用极细分割线

#### 区块 4 - 弹窗层（保持不变）

- 新建文档 Modal、重命名 Modal、OnlyOffice 编辑器 Modal 全部保持原有逻辑和样式