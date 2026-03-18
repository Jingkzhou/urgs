# MySQL 驱动目录

将 PyMySQL 的 `.whl` 文件放入本目录，打包版本包时会自动打入 ZIP。

## 下载命令

```bash
# PyMySQL 是纯 Python 包，无需指定平台
pip download PyMySQL==1.1.1 --no-deps -d ./
```

## 注意

- `.whl` 文件已通过 `.gitignore` 排除，不入 Git 仓库
- PyMySQL 无 C 扩展，`.whl` 文件适用于所有平台和 Python 版本
