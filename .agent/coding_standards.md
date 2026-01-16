# 团队开发规范 (Coding Standards)

> [!IMPORTANT]
> 本规范是 Agent 协作的核心依据，任何代码变更必须遵循以下规则。

## 通用原则
1. **语言规范**：所有计划 (Implementation Plan)、任务 (task.md) 和 Walkthrough 必须使用 **中文**。
2. **职责边界**：每个项目只负责其核心职责，严禁跨项目乱建或混用功能。
3. **路径规范**：所有数据库文件、新创建的文件必须存放在统一的任务路径或指定的项目目录下，严禁随处扩散。
4. **编译验证**：所有代码变更后，Agent 必须通过相应的编译命令（如 `mvn compile` 或 `npm run build`）进行验证，确保不引入破坏性变更。

## Java & 后端规范

### 1. 命名规范
- **包名**：全小写，使用反向域名格式，如 `com.example.urgs_api.task`。
- **类名**：使用 `PascalCase`（大驼峰），如 `TaskController`, `ReleaseRecordService`。
- **方法与变量**：使用 `camelCase`（小驼峰），如 `getTaskGlobalStats`, `releaseRepository`。
- **常量**：使用 `UPPER_SNAKE_CASE`（大写下划线），如 `STATUS_DRAFT`。

### 2. 架构规范
- **分层模式**：遵循 Controller -> Service -> Mapper/Repository 层次。
- **DTO/VO**：严禁将 Entity 直接暴露给前端。接口返回固定使用 `VO` (Value Object)，请求入参使用 `DTO` (Data Transfer Object)。
- **注解使用**：
    - 优先使用 Lombok 的 `@Data`, `@Slf4j`, `@RequiredArgsConstructor`。
    - 接口统一使用 `Spring MVC` 注解（`@RestController`, `@GetMapping` 等）。

### 3. 环境与编译
- **JDK 版本**：本项目基准 JDK 为 **17**。在编译时务必确保 `JAVA_HOME` 指向 JDK 17，避免因高版本 JDK (如 JDK 24) 导致的 Lombok 兼容性报错。
- **Maven 命令**：推荐使用 `mvn clean compile -DskipTests` 进行快速验证。

### 4. 异常处理
- **自定义异常**：业务逻辑冲突建议抛出具体的业务异常。
- **日志规范**：Service 层必须记录关键业务路径的日志。

---

## TypeScript & 前端规范

### 1. 命名规范
- **变量与函数**：使用 `camelCase`（小驼峰），如 `activeAgent`, `handleNewChat`。
- **组件、类、接口与类型**：使用 `PascalCase`（大驼峰），如 `ArkPage`, `SessionProps`, `AiAgent`。
- **常量**：使用 `UPPER_SNAKE_CASE`（大写下划线），如 `API_BASE_URL`。
- **Boolean 变量**：建议使用 `is`, `has`, `should` 前缀，如 `isGenerating`, `hasError`。

### 2. 错误处理
- **API 请求**：统一使用 `try...catch` 块包裹异步请求，并根据业务需求进行友好提示（如 AntD 的 `message.error`）。
- **兜底方案**：对可能为 `null` 或 `undefined` 的后端返回数据，必须提供初始值或默认值，避免页面崩溃。
- **日志记录**：关键业务逻辑报错时，需保留 `console.error` 并附带上下文信息，方便线上调试。

### 3. React 组件规范
- **函数式组件**：统一使用函数式组件与 Hooks。
- **Props 定义**：所有组件必须明确定义 Props 接口，严禁使用 `any`。
- **逻辑复用**：复杂的业务逻辑应提取到自定义 Hooks 或外部 Service 中，保持 UI 组件简洁。
- **组件提炼**：凡是超过 **2 个页面** 使用，或适合封装为独立单元的功能模块（如分页、搜索栏、状态标签），必须提炼为公共组件存放在 `src/components/common/`。
- **样式冲突**：优先使用 CSS Modules 或 TailwindCSS 类名，避免全局样式污染。

### 4. 协作与路径
- **代码注释**：公共函数、复杂算法必须通过 JSDoc 格式注释说明入参和返回值。
- **路径约束**：
    - **前端业务代码**：存放于 `src/components/` 的对应子目录下。
    - **API 定义**：存放于 `src/api/`。
    - **配置文件**：存放于 `src/config/`。
- **Git Commit**：遵循 `feat:`, `fix:`, `refactor:`, `docs:` 等语义化前缀。
- **权限登记（重要）**：
    - 每次添加**新按钮**、**新功能菜单**或**操作项**时，必须在 [manifest.ts](file:///Users/work/Documents/JLbankGit/URGS/urgs-web/src/permissions/manifest.ts) 中进行登记。
    - 确保登记的权限标识符与后端保持一致，以便权限控制逻辑生效。

### 5. 性能与优化
- **避免过度渲染**：对于大型列表或复杂计算，合理使用 `React.memo`, `useMemo` 和 `useCallback`。
- **按需加载**：大型组件或非首屏模块建议使用 `React.lazy` 进行代码分割。

### 6. 组件库使用 (Ant Design)
- **统一性**：优先使用 Ant Design 的官方组件，保持全局 UI 风格一致。
- **自定义主题**：如需修改样式，应通过 ConfigProvider 或全局 CSS 变量，严禁在多处硬编码颜色值。

---

## 项目结构约束

- **后端根目录**：`/Users/work/Documents/JLbankGit/URGS/urgs-api/`
- **前端根目录**：`/Users/work/Documents/JLbankGit/URGS/urgs-web/`
- **迁移动作**：数据库 SQL 迁移文件存放于 `urgs-api/src/main/resources/db/migration`。
- **文档维护**：发布说明存放于 `docs/release-notes/`。
