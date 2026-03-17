# Oracle 驱动目录

将 cx_Oracle 的 `.whl` 文件放入本目录，打包版本包时会自动打入 ZIP。

## 下载命令

```bash
# 下载适配 Linux x86_64 + Python 3.8 的 cx_Oracle
pip download cx_Oracle==8.3.0 \
  --platform linux_x86_64 \
  --python-version 38 \
  --only-binary=:all: \
  -d ./

# 下载 Python 3.9 版本
pip download cx_Oracle==8.3.0 \
  --platform linux_x86_64 \
  --python-version 39 \
  --only-binary=:all: \
  -d ./
```

## 注意

- `.whl` 文件已通过 `.gitignore` 排除，不入 Git 仓库
- 部署机还需单独安装 **Oracle Instant Client**（cx_Oracle 的 C 库依赖）
- 安装文档：https://cx-oracle.readthedocs.io/en/latest/user_guide/installation.html
