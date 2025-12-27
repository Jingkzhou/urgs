---
description: Java 后端开发与编译工作流
---

# Java 后端开发与编译规范

为了确保后端代码的质量和环境兼容性，请遵循以下流程。

## 核心配置

1. **JDK 版本强制要求**：本项目必须使用 **JDK 17**。
2. **JAVA_HOME 设置**：
   在执行任何 `mvn` 命令前，必须确保环境变量正确。
   ```bash
   export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
   ```

## 开发流程

1. **代码修改**：遵循 `coding_standards.md` 中的命名和架构规范。
2. **数据库变更**：如涉及 Schema 变更，参照 `/db-migration` 工作流先创建 SQL 脚本。
3. **本地验证**：
   // turbo
   使用以下命令进行增量编译验证：
   ```bash
   export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home && mvn clean compile -DskipTests
   ```
4. **单元测试**：
   如果修改了核心逻辑，运行相关测试类。
   ```bash
   mvn test -Dtest=ClassName
   ```

## 常见问题处理

- **Lombok 报错**：通常是由于使用了 JDK 21+ 导致，请检查 `JAVA_HOME` 是否指向 JDK 17。
- **依赖冲突**：检查 `pom.xml` 中的版本定义。
