package com.example.urgs_api.version.service;

import com.example.urgs_api.ops.entity.InfrastructureAsset;
import com.example.urgs_api.ops.entity.InfrastructureUser;
import com.example.urgs_api.ops.repository.InfrastructureAssetRepository;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitCommitDiff;
import com.example.urgs_api.version.dto.GitTag;
import com.example.urgs_api.version.dto.ReleaseSpec;
import com.example.urgs_api.version.entity.VersionPackage;
import com.example.urgs_api.version.repository.VersionPackageRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StreamUtils;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class VersionPackageService {

    private final VersionPackageRepository packageRepository;
    private final GitPlatformService gitPlatformService;
    private final InfrastructureAssetRepository assetRepository;
    private final ObjectMapper objectMapper;

    @Value("${deploy.tool.workdir:classpath:db_deploy}")
    private String dbDeployPath;

    public List<VersionPackage> findBySsoId(Long ssoId) {
        return packageRepository.findBySsoIdOrderByCreatedAtDesc(ssoId);
    }

    public VersionPackage findById(Long id) {
        return packageRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Version package not found: " + id));
    }

    /**
     * 从 Git 引用创建版本包记录
     * 支持基于两个 tag 之间差异的打包
     */
    @Transactional
    public VersionPackage createPackage(Long repoId, Long ssoId, String gitRef, String previousGitRef,
                                         String description, Long createdBy, Long envId) {
        // 获取当前 tag 的提交信息
        GitCommit latestCommit = gitPlatformService.getLatestCommit(repoId, gitRef);

        // 如果未传 previousGitRef，自动确定基线 tag（按时间排序的前一个）
        if (previousGitRef == null || previousGitRef.isBlank()) {
            previousGitRef = resolvePreviousTag(repoId, gitRef);
        }

        // 获取基线 tag 的提交信息
        String previousCommitSha = null;
        if (previousGitRef != null) {
            GitCommit prevCommit = gitPlatformService.getLatestCommit(repoId, previousGitRef);
            if (prevCommit != null) {
                previousCommitSha = prevCommit.getFullSha();
            }
        }

        VersionPackage vp = new VersionPackage();
        vp.setRepoId(repoId);
        vp.setSsoId(ssoId);
        vp.setGitRef(gitRef);
        vp.setVersion(gitRef);
        if (latestCommit != null) {
            vp.setCommitSha(latestCommit.getFullSha());
        }
        vp.setPreviousGitRef(previousGitRef);
        vp.setPreviousCommitSha(previousCommitSha);
        vp.setDescription(description);
        vp.setStatus(VersionPackage.STATUS_READY);
        vp.setCreatedBy(createdBy);
        if (envId != null) {
            vp.setEnvId(envId);
        }

        return packageRepository.save(vp);
    }

    /**
     * 自动确定基线 tag：获取 tag 列表按时间排序，找到当前 tag 的前一个
     */
    private String resolvePreviousTag(Long repoId, String currentTag) {
        try {
            List<GitTag> tags = gitPlatformService.getTags(repoId);
            if (tags == null || tags.size() < 2) return null;

            // 按 taggerDate 降序排列（最新在前）
            tags.sort((a, b) -> {
                String dateA = a.getTaggerDate() != null ? a.getTaggerDate() : "";
                String dateB = b.getTaggerDate() != null ? b.getTaggerDate() : "";
                return dateB.compareTo(dateA);
            });

            for (int i = 0; i < tags.size(); i++) {
                if (currentTag.equals(tags.get(i).getName()) && i + 1 < tags.size()) {
                    return tags.get(i + 1).getName();
                }
            }
        } catch (Exception e) {
            log.warn("自动确定基线 tag 失败: {}", e.getMessage());
        }
        return null;
    }

    /**
     * 生成部署包 (.zip) - 基于两个 tag 之间的 diff
     * 包含: sql/, procedures/, prev_procedures/, rollback/, backup/, manifest.json, connections
     */
    public byte[] generateArchive(Long packageId) throws IOException {
        return generateArchive(packageId, null, List.of(), null);
    }

    public byte[] generateArchive(Long packageId, Set<String> allowedDbPaths) throws IOException {
        return generateArchive(packageId, allowedDbPaths, List.of(), null);
    }

    public byte[] generateArchive(Long packageId, Set<String> allowedDbPaths, List<String> backupTables) throws IOException {
        return generateArchive(packageId, allowedDbPaths, backupTables, null);
    }

    public byte[] generateArchive(Long packageId, Set<String> allowedDbPaths, List<String> backupTables,
                                  ReleaseSpec.DatabaseSpec databaseSpec) throws IOException {
        VersionPackage vp = findById(packageId);

        // 1. 获取两个 tag 之间的变更文件列表
        Set<String> changedDbPaths = new HashSet<>();
        if (vp.getPreviousGitRef() != null && !vp.getPreviousGitRef().isBlank()) {
            List<GitCommitDiff> diffs = gitPlatformService.compareRefs(
                    vp.getRepoId(), vp.getPreviousGitRef(), vp.getGitRef());
            for (GitCommitDiff diff : diffs) {
                String path = diff.getNewPath();
                if (path != null && path.startsWith("db/") && isAllowedDbPath(path, allowedDbPaths)) {
                    changedDbPaths.add(path);
                }
                // 也处理 oldPath（文件重命名或删除的情况）
                String oldPath = diff.getOldPath();
                if (oldPath != null && oldPath.startsWith("db/") && isAllowedDbPath(oldPath, allowedDbPaths)) {
                    changedDbPaths.add(oldPath);
                }
            }
        }

        // 收集变更的存储过程文件名（用于 manifest 中的 procedure_names）
        Set<String> changedProcedureFiles = changedDbPaths.stream()
                .filter(p -> p.startsWith("db/procedures/"))
                .map(p -> p.substring("db/procedures/".length()))
                .collect(Collectors.toSet());

        List<String> procedureNames = changedProcedureFiles.stream()
                .filter(f -> f.endsWith(".sql"))
                .map(f -> f.substring(0, f.length() - 4))  // 去掉 .sql 后缀
                .sorted()
                .collect(Collectors.toList());

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            StringBuilder checksumBuilder = new StringBuilder();

            // 2. 下载当前 tag 归档，提取变更文件
            boolean hasDiff = !changedDbPaths.isEmpty();
            try (InputStream gitArchive = gitPlatformService.downloadArchive(vp.getRepoId(), vp.getGitRef())) {
                extractFromArchive(zos, gitArchive, changedDbPaths, hasDiff, checksumBuilder);
            }

            // 3. 下载上一版本 tag 归档，提取变更的存储过程到 prev_procedures/
            if (vp.getPreviousGitRef() != null && !changedProcedureFiles.isEmpty()) {
                try (InputStream prevArchive = gitPlatformService.downloadArchive(
                        vp.getRepoId(), vp.getPreviousGitRef())) {
                    extractPrevProcedures(zos, prevArchive, changedProcedureFiles, checksumBuilder);
                }
            }

            // 4. 生成数据库连接配置并写入 manifest
            Map<String, Object> connections = buildConnectionsConfig(vp, databaseSpec);

            // 5. 生成 manifest.json
            String manifestJson = generateManifest(vp, procedureNames, connections, backupTables);
            addToZip(zos, "manifest.json", manifestJson.getBytes("UTF-8"), checksumBuilder);

            // 6. 打包 db_deploy 工具（按 dbType 选入对应驱动）
            String dbType = resolveDbType(vp, databaseSpec);
            addToolToZip(zos, checksumBuilder, dbType);

            // 7. 写入 checksum.sha256
            zos.putNextEntry(new ZipEntry("checksum.sha256"));
            zos.write(checksumBuilder.toString().getBytes());
            zos.closeEntry();
        }

        return baos.toByteArray();
    }

    private boolean isAllowedDbPath(String path, Set<String> allowedDbPaths) {
        return allowedDbPaths == null || allowedDbPaths.isEmpty() || allowedDbPaths.contains(path);
    }

    /**
     * 从 Git 归档中提取文件到 ZIP
     * 如果有 diff 信息，只提取变更的 db/ 文件；否则提取全部 db/ 文件
     */
    private void extractFromArchive(ZipOutputStream zos, InputStream gitArchive,
                                     Set<String> changedDbPaths, boolean hasDiff,
                                     StringBuilder checksumBuilder) throws IOException {
        ZipInputStream zis = new ZipInputStream(gitArchive);
        ZipEntry entry;
        while ((entry = zis.getNextEntry()) != null) {
            if (!entry.isDirectory()) {
                String name = entry.getName();
                // 移除顶级目录前缀 (归档通常带随机名前缀)
                String cleanName = name.contains("/") ? name.substring(name.indexOf("/") + 1) : name;

                if (cleanName.startsWith("db/")) {
                    // 如果有 diff，只提取变更文件；否则全量提取
                    if (!hasDiff || changedDbPaths.contains(cleanName)) {
                        // 路径映射: db/sql/xxx -> sql/xxx, db/procedures/xxx -> procedures/xxx
                        String targetPath = cleanName.substring("db/".length());
                        byte[] content = readStream(zis);
                        addToZip(zos, targetPath, content, checksumBuilder);
                    }
                }
            }
            zis.closeEntry();
        }
    }

    /**
     * 从上一版本归档中提取变更的存储过程到 prev_procedures/
     */
    private void extractPrevProcedures(ZipOutputStream zos, InputStream prevArchive,
                                        Set<String> changedProcedureFiles,
                                        StringBuilder checksumBuilder) throws IOException {
        ZipInputStream zis = new ZipInputStream(prevArchive);
        ZipEntry entry;
        while ((entry = zis.getNextEntry()) != null) {
            if (!entry.isDirectory()) {
                String name = entry.getName();
                String cleanName = name.contains("/") ? name.substring(name.indexOf("/") + 1) : name;

                if (cleanName.startsWith("db/procedures/")) {
                    String fileName = cleanName.substring("db/procedures/".length());
                    if (changedProcedureFiles.contains(fileName)) {
                        byte[] content = readStream(zis);
                        addToZip(zos, "prev_procedures/" + fileName, content, checksumBuilder);
                    }
                }
            }
            zis.closeEntry();
        }
    }

    /**
     * 优先根据发布规格构建数据库连接配置，兼容旧包的资产 ID + 执行用户模式
     */
    private Map<String, Object> buildConnectionsConfig(VersionPackage vp, ReleaseSpec.DatabaseSpec databaseSpec) {
        Map<String, Object> connections = new LinkedHashMap<>();

        if (hasDatabaseConnectionConfig(databaseSpec)) {
            String targetName = firstNonBlank(databaseSpec.getTargetName(), "prod_db");
            connections.put(targetName, buildConnectionFromSpec(databaseSpec));
            return connections;
        }

        if (vp.getAssetId() == null) {
            log.warn("版本包 {} 未指定目标数据库服务器，跳过连接配置生成", vp.getId());
            return connections;
        }

        InfrastructureAsset asset = assetRepository.findById(vp.getAssetId())
                .orElse(null);
        if (asset == null) {
            log.warn("未找到资产 ID: {}", vp.getAssetId());
            return connections;
        }

        // 查找 userType=db 且匹配 execUser 的用户
        InfrastructureUser dbUser = null;
        if (asset.getUsers() != null) {
            String execUser = vp.getExecUser();
            dbUser = asset.getUsers().stream()
                    .filter(u -> "db".equalsIgnoreCase(u.getUserType()))
                    .filter(u -> execUser == null || execUser.equals(u.getUsername()))
                    .findFirst()
                    .orElse(null);
        }

        if (dbUser == null) {
            log.warn("资产 {} 未找到匹配的数据库用户 (execUser={})", asset.getHostname(), vp.getExecUser());
            return connections;
        }

        Map<String, Object> connConfig = buildSingleConnection(asset, dbUser, databaseSpec);
        connections.put("prod_db", connConfig);

        return connections;
    }

    private boolean hasDatabaseConnectionConfig(ReleaseSpec.DatabaseSpec databaseSpec) {
        if (databaseSpec == null || isBlank(databaseSpec.getDbType())) {
            return false;
        }
        return !isBlank(databaseSpec.getUser())
                || !isBlank(databaseSpec.getPassword())
                || !isBlank(databaseSpec.getHost())
                || !isBlank(databaseSpec.getDsn())
                || !isBlank(databaseSpec.getJdbcUrl());
    }

    private Map<String, Object> buildConnectionFromSpec(ReleaseSpec.DatabaseSpec databaseSpec) {
        Map<String, Object> connConfig = new LinkedHashMap<>();
        String dbType = firstNonBlank(databaseSpec.getDbType(), "oracle").toLowerCase();
        connConfig.put("type", dbType);
        putIfPresent(connConfig, "user", databaseSpec.getUser());
        putIfPresent(connConfig, "password", databaseSpec.getPassword());
        appendDatabaseSpecOptions(connConfig, databaseSpec, dbType);

        boolean useJdbc = !isBlank(databaseSpec.getJdbcUrl())
                && !isBlank(databaseSpec.getDriverJar())
                && !isBlank(databaseSpec.getJdbcDriverClass());
        if (useJdbc) {
            return connConfig;
        }

        switch (dbType) {
            case "oracle":
                connConfig.put("dsn", resolveOracleDsn(databaseSpec));
                break;
            case "mysql":
            case "gbase":
                connConfig.put("host", firstNonBlank(databaseSpec.getHost(), hostFromJdbcUrl(databaseSpec.getJdbcUrl())));
                connConfig.put("port", firstNonNull(databaseSpec.getPort(), portFromJdbcUrl(databaseSpec.getJdbcUrl()), 3306));
                connConfig.put("database", firstNonBlank(databaseSpec.getDatabase(), databaseSpec.getSchema(),
                        databaseNameFromJdbcUrl(databaseSpec.getJdbcUrl())));
                break;
            default:
                putIfPresent(connConfig, "host", firstNonBlank(databaseSpec.getHost(), hostFromJdbcUrl(databaseSpec.getJdbcUrl())));
                if (databaseSpec.getPort() != null) {
                    connConfig.put("port", databaseSpec.getPort());
                }
                putIfPresent(connConfig, "database", firstNonBlank(databaseSpec.getDatabase(), databaseSpec.getSchema(),
                        databaseNameFromJdbcUrl(databaseSpec.getJdbcUrl())));
        }

        return connConfig;
    }

    /**
     * 构建单个数据库连接配置
     */
    private Map<String, Object> buildSingleConnection(InfrastructureAsset asset, InfrastructureUser dbUser,
                                                      ReleaseSpec.DatabaseSpec databaseSpec) {
        Map<String, Object> connConfig = new LinkedHashMap<>();

        String dbType = firstNonBlank(databaseSpec != null ? databaseSpec.getDbType() : null, asset.getDbType(), "oracle")
                .toLowerCase();
        connConfig.put("type", dbType);
        connConfig.put("user", dbUser.getUsername());
        connConfig.put("password", dbUser.getPassword());
        if (databaseSpec != null) {
            appendDatabaseSpecOptions(connConfig, databaseSpec, dbType);
        }

        switch (dbType) {
            case "oracle":
                String host = asset.getInternalIp();
                int port = asset.getDbPort() != null ? asset.getDbPort() : 1521;
                String serviceName = asset.getDbServiceName();
                String sid = asset.getDbName();
                if (serviceName != null && !serviceName.isBlank()) {
                    connConfig.put("dsn", String.format("%s:%d/%s", host, port, serviceName));
                } else if (sid != null && !sid.isBlank()) {
                    connConfig.put("dsn", String.format("%s:%d:%s", host, port, sid));
                } else {
                    connConfig.put("dsn", null);
                    connConfig.put("_warning", "服务器未配置 dbServiceName 或 dbName，dsn 无法生成，请在基础设施管理中补充后重新创建版本包");
                    log.error("资产 {} (id={}) 未配置 dbServiceName/dbName，manifest.json 中 dsn 将为空", asset.getHostname(), asset.getId());
                }
                break;
            case "mysql":
            case "gbase":
            case "xinghuan":
            case "transwarp":
                connConfig.put("host", asset.getInternalIp());
                connConfig.put("port", asset.getDbPort() != null ? asset.getDbPort() : 3306);
                connConfig.put("database", asset.getDbName());
                break;
            default:
                connConfig.put("host", asset.getInternalIp());
                connConfig.put("port", asset.getDbPort());
                connConfig.put("database", asset.getDbName());
        }

        return connConfig;
    }

    private void appendDatabaseSpecOptions(Map<String, Object> connConfig, ReleaseSpec.DatabaseSpec databaseSpec,
                                           String dbType) {
        if (!isBlank(databaseSpec.getJdbcUrl())) {
            connConfig.put("jdbc_url", databaseSpec.getJdbcUrl());
        }
        if (!isBlank(databaseSpec.getJdbcDriverClass())) {
            connConfig.put("driver_class", databaseSpec.getJdbcDriverClass());
        }
        if (!isBlank(databaseSpec.getDriverJar())) {
            connConfig.put("driver_jar", packageDriverJarPath(databaseSpec, dbType));
            connConfig.put("driver_jar_name", databaseSpec.getDriverJar());
        }
        if (!isBlank(databaseSpec.getDriverDir())) {
            connConfig.put("driver_dir", packageDriverDirPath(databaseSpec.getDriverDir(), dbType));
        }
        if (!isBlank(databaseSpec.getSchema())) {
            connConfig.put("schema", databaseSpec.getSchema());
        }
    }

    private String resolveOracleDsn(ReleaseSpec.DatabaseSpec databaseSpec) {
        if (!isBlank(databaseSpec.getDsn())) {
            return databaseSpec.getDsn();
        }
        String host = databaseSpec.getHost();
        Integer port = firstNonNull(databaseSpec.getPort(), 1521);
        String serviceName = databaseSpec.getServiceName();
        String sid = firstNonBlank(databaseSpec.getSid(), databaseSpec.getDatabase());
        if (!isBlank(host) && !isBlank(serviceName)) {
            return String.format("%s:%d/%s", host, port, serviceName);
        }
        if (!isBlank(host) && !isBlank(sid)) {
            return String.format("%s:%d:%s", host, port, sid);
        }
        return null;
    }

    private String hostFromJdbcUrl(String jdbcUrl) {
        String authority = jdbcAuthority(jdbcUrl);
        if (isBlank(authority)) {
            return null;
        }
        int at = authority.lastIndexOf('@');
        if (at >= 0 && at + 1 < authority.length()) {
            authority = authority.substring(at + 1);
        }
        int colon = authority.lastIndexOf(':');
        return colon > 0 ? authority.substring(0, colon) : authority;
    }

    private Integer portFromJdbcUrl(String jdbcUrl) {
        String authority = jdbcAuthority(jdbcUrl);
        if (isBlank(authority)) {
            return null;
        }
        int at = authority.lastIndexOf('@');
        if (at >= 0 && at + 1 < authority.length()) {
            authority = authority.substring(at + 1);
        }
        int colon = authority.lastIndexOf(':');
        if (colon < 0 || colon + 1 >= authority.length()) {
            return null;
        }
        try {
            return Integer.valueOf(authority.substring(colon + 1));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String databaseNameFromJdbcUrl(String jdbcUrl) {
        if (isBlank(jdbcUrl)) {
            return null;
        }
        String normalized = jdbcUrl;
        int queryIndex = normalized.indexOf('?');
        if (queryIndex >= 0) {
            normalized = normalized.substring(0, queryIndex);
        }
        int lastSlash = normalized.lastIndexOf('/');
        if (lastSlash < 0 || lastSlash + 1 >= normalized.length()) {
            return null;
        }
        String database = normalized.substring(lastSlash + 1);
        int semicolon = database.indexOf(';');
        if (semicolon >= 0) {
            database = database.substring(0, semicolon);
        }
        return isBlank(database) ? null : database;
    }

    private String jdbcAuthority(String jdbcUrl) {
        if (isBlank(jdbcUrl)) {
            return null;
        }
        int protocolIndex = jdbcUrl.indexOf("://");
        if (protocolIndex < 0 || protocolIndex + 3 >= jdbcUrl.length()) {
            return null;
        }
        String remainder = jdbcUrl.substring(protocolIndex + 3);
        int slash = remainder.indexOf('/');
        return slash >= 0 ? remainder.substring(0, slash) : remainder;
    }

    private void putIfPresent(Map<String, Object> target, String key, String value) {
        if (!isBlank(value)) {
            target.put(key, value);
        }
    }

    @SafeVarargs
    private <T> T firstNonNull(T... values) {
        for (T value : values) {
            if (value != null) {
                return value;
            }
        }
        return null;
    }

    /**
     * 生成 manifest.json，包含完整的 execution_plan 和 rollback_plan
     */
    private String generateManifest(VersionPackage vp, List<String> procedureNames,
                                     Map<String, Object> connections, List<String> backupTables) {
        try {
            ObjectNode root = objectMapper.createObjectNode();
            root.put("pkg_version", vp.getVersion());
            root.put("previous_version", vp.getPreviousGitRef() != null ? vp.getPreviousGitRef() : "");
            root.put("created_at", LocalDateTime.now().toString());
            root.put("git_commit", vp.getCommitSha() != null ? vp.getCommitSha() : "");
            root.put("previous_commit", vp.getPreviousCommitSha() != null ? vp.getPreviousCommitSha() : "");

            // connections
            root.set("connections", objectMapper.valueToTree(connections));

            // 确定 target 名称
            String targetName = connections.isEmpty() ? "prod_db" : connections.keySet().iterator().next();

            // execution_plan
            ArrayNode execPlan = objectMapper.createArrayNode();
            int step = 1;

            // Step 1: 存储过程一致性校验（如果有变更的存储过程）
            if (!procedureNames.isEmpty()) {
                ObjectNode preCheck = objectMapper.createObjectNode();
                preCheck.put("step", step++);
                preCheck.put("name", "生产存储过程一致性校验");
                preCheck.put("type", "export_and_compare_procedures");
                preCheck.set("targets", objectMapper.createArrayNode().add(targetName));
                ObjectNode preCheckParams = objectMapper.createObjectNode();
                preCheckParams.set("procedure_names", objectMapper.valueToTree(procedureNames));
                preCheckParams.put("expected_source_dir", "prev_procedures");
                preCheckParams.put("on_mismatch", "abort");
                preCheck.set("params", preCheckParams);
                execPlan.add(preCheck);
            }

            // Step 2: 执行备份
            if (backupTables != null && !backupTables.isEmpty()) {
                ObjectNode backupStep = objectMapper.createObjectNode();
                backupStep.put("step", step++);
                backupStep.put("name", "按表执行投产前备份");
                backupStep.put("type", "backup_table");
                backupStep.set("targets", objectMapper.createArrayNode().add(targetName));
                ObjectNode backupParams = objectMapper.createObjectNode();
                backupParams.set("tables", objectMapper.valueToTree(backupTables));
                backupStep.set("params", backupParams);
                execPlan.add(backupStep);
            } else {
                ObjectNode backupStep = objectMapper.createObjectNode();
                backupStep.put("step", step++);
                backupStep.put("name", "执行备份脚本");
                backupStep.put("type", "execute_sql_ordered");
                backupStep.set("targets", objectMapper.createArrayNode().add(targetName));
                ObjectNode backupParams = objectMapper.createObjectNode();
                backupParams.put("source_dir", "backup");
                backupParams.put("sort_by", "filename_asc");
                backupStep.set("params", backupParams);
                execPlan.add(backupStep);
            }

            // Step 3: 执行 DDL/DML
            ObjectNode sqlStep = objectMapper.createObjectNode();
            sqlStep.put("step", step++);
            sqlStep.put("name", "执行DDL/DML");
            sqlStep.put("type", "execute_sql_ordered");
            sqlStep.set("targets", objectMapper.createArrayNode().add(targetName));
            ObjectNode sqlParams = objectMapper.createObjectNode();
            sqlParams.put("source_dir", "sql");
            sqlParams.put("sort_by", "filename_asc");
            sqlStep.set("params", sqlParams);
            execPlan.add(sqlStep);

            // Step 4: 部署存储过程（如果有）
            if (!procedureNames.isEmpty()) {
                ObjectNode procStep = objectMapper.createObjectNode();
                procStep.put("step", step++);
                procStep.put("name", "部署存储过程");
                procStep.put("type", "deploy_procedures");
                procStep.set("targets", objectMapper.createArrayNode().add(targetName));
                ObjectNode procParams = objectMapper.createObjectNode();
                procParams.put("source_dir", "procedures");
                procStep.set("params", procParams);
                execPlan.add(procStep);
            }

            root.set("execution_plan", execPlan);

            // rollback_plan
            ArrayNode rollbackPlan = objectMapper.createArrayNode();
            int rStep = 1;

            // Rollback Step 1: 执行回滚脚本
            ObjectNode rollbackSql = objectMapper.createObjectNode();
            rollbackSql.put("step", rStep++);
            rollbackSql.put("name", "执行回滚脚本");
            rollbackSql.put("type", "execute_sql_ordered");
            rollbackSql.set("targets", objectMapper.createArrayNode().add(targetName));
            ObjectNode rollbackSqlParams = objectMapper.createObjectNode();
            rollbackSqlParams.put("source_dir", "rollback");
            rollbackSqlParams.put("sort_by", "filename_asc");
            rollbackSql.set("params", rollbackSqlParams);
            rollbackPlan.add(rollbackSql);

            // Rollback Step 2: 恢复上一版本存储过程
            if (!procedureNames.isEmpty()) {
                ObjectNode restoreProc = objectMapper.createObjectNode();
                restoreProc.put("step", rStep++);
                restoreProc.put("name", "恢复上一版本存储过程");
                restoreProc.put("type", "deploy_procedures");
                restoreProc.set("targets", objectMapper.createArrayNode().add(targetName));
                ObjectNode restoreProcParams = objectMapper.createObjectNode();
                restoreProcParams.put("source_dir", "prev_procedures");
                restoreProc.set("params", restoreProcParams);
                rollbackPlan.add(restoreProc);
            }

            root.set("rollback_plan", rollbackPlan);

            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(root);
        } catch (Exception e) {
            throw new RuntimeException("生成 manifest.json 失败: " + e.getMessage(), e);
        }
    }

    // ===================== 工具方法 =====================

    private void addToolToZip(ZipOutputStream zos, StringBuilder checksumBuilder, String dbType) throws IOException {
        if (!dbDeployPath.startsWith("classpath:")) {
            addFileToolToZip(zos, checksumBuilder, dbType);
            return;
        }

        ResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        String pattern = dbDeployPath.endsWith("/") ? dbDeployPath + "**/*" : dbDeployPath + "/**/*";
        Resource[] resources = resolver.getResources(pattern);

        String prefix = dbDeployPath.replace("classpath:", "");
        if (prefix.startsWith("/")) prefix = prefix.substring(1);
        if (!prefix.endsWith("/")) prefix = prefix + "/";

        // 确定要包含的驱动目录：默认 oracle
        String targetDriverDir = "/drivers/" + (dbType != null ? dbType : "oracle") + "/";

        for (Resource resource : resources) {
            if (!resource.isReadable()) continue;

            String uri = resource.getURI().toString();
            if (uri.contains("__pycache__") || uri.contains("/.")) continue;
            if (uri.endsWith(".pyc")) continue;

            String filename = resource.getURL().getPath();
            int index = filename.indexOf(prefix);
            if (index == -1) continue;

            String zipPath = "bin/" + filename.substring(index);

            // 驱动目录过滤：只打入匹配 dbType 的驱动子目录，跳过其他类型
            if (zipPath.contains("/drivers/") && !zipPath.contains(targetDriverDir)) {
                continue;
            }

            byte[] content = StreamUtils.copyToByteArray(resource.getInputStream());
            addToZip(zos, zipPath, content, checksumBuilder);
        }
    }

    private void addFileToolToZip(ZipOutputStream zos, StringBuilder checksumBuilder, String dbType) throws IOException {
        Path root = Path.of(dbDeployPath).toAbsolutePath().normalize();
        if (!Files.exists(root) || !Files.isDirectory(root)) {
            throw new IOException("部署工具目录不存在: " + root);
        }

        String targetDriverDir = "drivers/" + (dbType != null ? dbType : "oracle") + "/";
        List<Path> files;
        try (Stream<Path> stream = Files.walk(root)) {
            files = stream.filter(Files::isRegularFile).sorted().toList();
        }

        for (Path file : files) {
            String relative = root.relativize(file).toString().replace(File.separatorChar, '/');
            if (relative.contains("__pycache__") || relative.startsWith(".") || relative.contains("/.")) {
                continue;
            }
            if (relative.endsWith(".pyc")) {
                continue;
            }
            if (relative.startsWith("drivers/") && !relative.startsWith(targetDriverDir)) {
                continue;
            }
            addToZip(zos, "bin/db_deploy/" + relative, Files.readAllBytes(file), checksumBuilder);
        }
    }

    private void addToZip(ZipOutputStream zos, String path, byte[] content, StringBuilder checksumBuilder) throws IOException {
        ZipEntry entry = new ZipEntry(path);
        zos.putNextEntry(entry);
        zos.write(content);
        zos.closeEntry();

        String hash = calculateSha256(content);
        checksumBuilder.append(hash).append("  ").append(path).append("\n");
    }

    private String resolveDbType(VersionPackage vp, ReleaseSpec.DatabaseSpec databaseSpec) {
        if (databaseSpec != null && !isBlank(databaseSpec.getDbType())) {
            return databaseSpec.getDbType().toLowerCase();
        }
        if (vp.getAssetId() != null) {
            InfrastructureAsset asset = assetRepository.findById(vp.getAssetId()).orElse(null);
            if (asset != null && !isBlank(asset.getDbType())) {
                return asset.getDbType().toLowerCase();
            }
        }
        return "oracle";
    }

    private String packageDriverJarPath(ReleaseSpec.DatabaseSpec databaseSpec, String dbType) {
        return packageDriverDirPath(databaseSpec.getDriverDir(), dbType) + "/" + databaseSpec.getDriverJar();
    }

    private String packageDriverDirPath(String driverDir, String dbType) {
        String normalized = isBlank(driverDir) ? "db_deploy/drivers/" + dbType : driverDir.trim().replace("\\", "/");
        while (normalized.startsWith("/")) {
            normalized = normalized.substring(1);
        }
        while (normalized.endsWith("/")) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }
        if (normalized.startsWith("bin/")) {
            return normalized;
        }
        if (normalized.startsWith("db_deploy/")) {
            return "bin/" + normalized;
        }
        if (normalized.startsWith("drivers/")) {
            return "bin/db_deploy/" + normalized;
        }
        return "bin/db_deploy/drivers/" + normalized;
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (!isBlank(value)) {
                return value;
            }
        }
        return "";
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String calculateSha256(byte[] data) {
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(data);
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new RuntimeException("SHA-256 calculation failed", e);
        }
    }

    private byte[] readStream(InputStream is) throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[4096];
        while ((nRead = is.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }
        return buffer.toByteArray();
    }

    @Transactional
    public void deletePackage(Long id) {
        packageRepository.deleteById(id);
    }

    @Transactional
    public VersionPackage updateStatus(Long id, String status, Long operatorId) {
        VersionPackage vp = findById(id);
        vp.setStatus(status);
        if (VersionPackage.STATUS_DEPLOYED.equals(status)) {
            vp.setDeployedBy(operatorId);
            vp.setDeployedAt(LocalDateTime.now());
        }
        return packageRepository.save(vp);
    }
}
