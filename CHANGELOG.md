# CHANGELOG

本文件记录项目的所有重要变更。

## [未发布]
### Added
- 实施变更记录标准化流程：PR 模板、Commit 模板、自动生成脚本。
- SQL 控制台权限修复：对齐前后端权限编码 `metadata:query`。
- SQL 控制台 UI 优化：消除 Monaco Editor worker 跨域警告。

### Fixed
- 非 admin 用户执行 SQL 返回 403 的错误。
- 处理 SQL Lineage Engine 在生产环境 Docker 中的 numpy 线程冲突问题。
