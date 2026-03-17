# GBase 驱动目录

GBase 8a 兼容 MySQL 协议，使用 PyMySQL 作为驱动。
将 PyMySQL 的 `.whl` 文件放入本目录，打包版本包时会自动打入 ZIP。

## 下载命令

```bash
# 与 mysql 目录相同
pip download PyMySQL==1.1.1 --no-deps -d ./
```

## 注意

- `.whl` 文件已通过 `.gitignore` 排除，不入 Git 仓库
