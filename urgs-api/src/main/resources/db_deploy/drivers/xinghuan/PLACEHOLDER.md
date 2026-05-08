# 星环驱动目录

将星环/Transwarp 对应的 JDBC 驱动 `.jar` 文件放入本目录。

生产投产包生成时，如果 `.urgs/release.yml` 中声明：

```yaml
database:
  dbType: xinghuan
  driverJar: transwarp-jdbc.jar
```

系统会把本目录下的 `transwarp-jdbc.jar` 打入生产投产包：

```text
bin/db_deploy/drivers/xinghuan/transwarp-jdbc.jar
```

## 注意

- `.jar` 文件已通过上级 `.gitignore` 排除，避免误提交专有驱动。
- JDBC 方式需要执行机已安装或包内已带 `JayDeBeApi`、`JPype1` 的 `.whl` 离线依赖。
