# Batch Process Monitoring Implementation

I have implemented the **Batch Process Monitoring** component as requested, matching the provided design mockups.

# 配置重构完成：Docker 动态环境支持 (SIT/UAT/PROD)

我已经将系统升级为“一次构建，到处运行”的架构。现在，你可以在不重新构建镜像的情况下，通过 Docker 环境变量动态配置所有 IP 和 URL 信息。

## 核心变更

### 1. Docker 运行时注入
- **新增 [entrypoint.sh](file:///Users/work/Documents/JLbankGit/URGS/urgs-web/entrypoint.sh)**：容器启动时自动将环境变量写入 `config.js` 并更新 Nginx 配置。
- **Dockerfile 升级**：集成了自动配置流程，使用 `ENTRYPOINT` 模式。

### 2. Nginx 配置动态化
- **新增 [nginx.conf.template](file:///Users/work/Documents/JLbankGit/URGS/urgs-web/nginx.conf.template)**：后端代理地址（API, RAG）现在支持通过环境变量动态替换。

### 3. 前端载入逻辑
- **[index.html](file:///Users/work/Documents/JLbankGit/URGS/urgs-web/index.html)**：自动加载容器生成的 `config.js`。
- **[src/config.ts](file:///Users/work/Documents/JLbankGit/URGS/urgs-web/src/config.ts)**：优先使用容器注入的运行时配置，无缝对接不同环境。

## SIT / UAT / PROD 部署说明

你可以使用同一个 Docker 镜像，通过 `-e` 参数运行在不同环境：

### SIT 环境
```bash
docker run -d -p 80:80 \
  -e VITE_WS_URL=ws://sit-server:8080/ws/im \
  -e VITE_API_URL=http://sit-server:8080 \
  -e VITE_RAG_URL=http://sit-rag:8001 \
  urgs-web:latest
```

### PROD 环境
```bash
docker run -d -p 80:80 \
  -e VITE_WS_URL=ws://prod-server.company.com/ws/im \
  -e VITE_API_URL=http://prod-api.company.com \
  -e VITE_RAG_URL=http://prod-rag.company.com \
  urgs-web:latest
```

## 环境变量说明
- `VITE_WS_URL`: 前端 WebSocket 连接地址。
- `VITE_API_URL`: Nginx 代理后端 API 的目标地址。
- `VITE_RAG_URL`: Nginx 代理 RAG 服务的目标地址。

## Features

### 1. Metrics Dashboard
- **Total Throughput**: Displays daily task count and growth trend.
- **Active Processing**: Shows concurrent job count.
- **Success Rate**: Visualizes success percentage with threshold warnings.
- **System Health**: Health score with error detection count.

### 2. Visual Analytics
- **Processing Volume Trend**: Line chart showing task volume over time (Current vs Previous).
- **Task Status Distribution**: Donut chart breaking down tasks by status (Completed, Failed, Processing, Pending).

### 3. Real-time Task Stream
- A detailed table listing current batch tasks.
- **Columns**: Batch ID, Task Name (with owner/priority), Progress Bar, Status Badge, Action Button.
- **Interactive Elements**: "AI Analyze" button for failed tasks (currently a placeholder action).

## Integration
- The component is integrated into the main `Dashboard.tsx`.
- It is protected by the permission code `dash:Batch-monitoring`.
- It appears below the existing Stats and Notices sections.

## Style Optimizations (Light Theme & AI Aesthetics)
- **Light Theme**: Switched to a clean, white/slate palette (`bg-white/80`, `text-slate-800`) for better readability and a modern feel.
- **AI Aesthetics**:
    - **Glassmorphism**: `backdrop-blur-xl` and semi-transparent backgrounds.
    - **Gradients**: Subtle blue/indigo/purple gradients on icons and buttons to evoke "intelligence".
    - **Soft Shadows**: `shadow-[0_8px_30px_...]` for a floating, high-tech effect.
- **Interactivity**: Enhanced hover states with lift effects and glow animations.
- **Localization**: Fully translated UI text and data into Chinese (Simplified).
- **Layout**: Optimized spacing with reduced top margin (`-mt-2`) and tighter vertical rhythm (`space-y-4`).

## Screenshots
The implementation uses a light theme with Tailwind CSS to match the requested "AI Intelligence" aesthetic, with all content in Chinese.

# Metadata Management Implementation

## Features
- **Regulatory Mart (LDM)**:
    - **Tree View**: Hierarchical display of regulatory themes (e.g., EAST 5.0).
    - **Standard Table**: List of standard interfaces with version tracking.
    - **Field Drawer**: Detailed view of field standards and validation rules.
- **Metadata Model (PDM)**:
    - **Datasource Selection**: Filter by Hive-ODS, Hive-DWD, or Oracle.
    - **Physical Table List**: View table details including storage, row count, and owner.
    - **Sync Function**: Mock "Sync Metadata" button with loading state.

## Verification
1.  **Navigation**: Click "元数据管理" in the main sidebar.
2.  **LDM**:
    - Verify the tree structure on the left.
    - Click a table row to open the Field Standard drawer.
3.  **PDM**:
    - Switch to "元数据模型" tab.
    - Try changing the datasource dropdown.
    - Click "同步元数据" to see the loading animation.

## Verification
1.  **Permission**: Ensure your user role has the `dash:Batch-monitoring` permission.
2.  **View**: Navigate to the Dashboard; the new section should appear at the bottom.
3.  **Responsiveness**: The layout adapts from single column (mobile) to multi-column (desktop).
