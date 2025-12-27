---
description: 前端开发与验证工作流
---

# 前端开发与验证规范

为了确保前端 UI 的一致性和功能的稳健性，请遵循以下流程。

## 核心配置

1. **根目录**：`/Users/work/Documents/JLbankGit/URGS/urgs-web/`
2. **包管理**：使用 `npm` 进行管理。

## 开发流程

1. **本地预览**：
   // turbo
   ```bash
   npm run dev
   ```
2. **权限登记**：
   每次添加新按钮或菜单，必须在 `src/permissions/manifest.ts` 中登记权限标识。
3. **接口同步**：
   如果修改了 API 定义，确保 `src/api/` 下的 TypeScript 类型与后端 DTO 保持同步。
4. **验证构建**：
   // turbo
   提交前必须执行生产构建，确保没有类型错误或打包失败。
   ```bash
   npm run build
   ```

## 常见问题处理

- **权限失效**：检查 `manifest.ts` 是否登记，以及后端返回的权限列表是否包含该标识。
- **渲染异常**：检查 `console.error`，确保所有后端返回的字段都有兜底处理。
