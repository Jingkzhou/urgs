package com.example.urgs_api.version.service;

import com.example.urgs_api.ops.entity.InfrastructureAsset;
import com.example.urgs_api.ops.entity.InfrastructureUser;
import com.example.urgs_api.ops.repository.InfrastructureAssetRepository;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitCommitDiff;
import com.example.urgs_api.version.dto.GitTag;
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
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
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
                                         Long assetId, String execUser, String description, Long createdBy, Long envId) {
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
        vp.setAssetId(assetId);
        vp.setExecUser(execUser);
        vp.setDescription(description);
        vp.setStatus(VersionPackage.STATUS_READY);
        vp.setCreatedBy(createdBy);
        vp.setEnvId(envId);

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
        VersionPackage vp = findById(packageId);

        // 1. 获取两个 tag 之间的变更文件列表
        Set<String> changedDbPaths = new HashSet<>();
        if (vp.getPreviousGitRef() != null && !vp.getPreviousGitRef().isBlank()) {
            List<GitCommitDiff> diffs = gitPlatformService.compareRefs(
                    vp.getRepoId(), vp.getPreviousGitRef(), vp.getGitRef());
            for (GitCommitDiff diff : diffs) {
                String path = diff.getNewPath();
                if (path != null && path.startsWith("db/")) {
                    changedDbPaths.add(path);
                }
                // 也处理 oldPath（文件重命名或删除的情况）
                String oldPath = diff.getOldPath();
                if (oldPath != null && oldPath.startsWith("db/")) {
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
            Map<String, Object> connections = buildConnectionsConfig(vp);

            // 5. 生成 manifest.json
            String manifestJson = generateManifest(vp, procedureNames, connections);
            addToZip(zos, "manifest.json", manifestJson.getBytes("UTF-8"), checksumBuilder);

            // 6. 打包 db_deploy 工具
            addToolToZip(zos, checksumBuilder);

            // 7. 写入 checksum.sha256
            zos.putNextEntry(new ZipEntry("checksum.sha256"));
            zos.write(checksumBuilder.toString().getBytes());
            zos.closeEntry();
        }

        return baos.toByteArray();
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
     * 根据单台资产 ID + 执行用户构建数据库连接配置
     * 从 InfrastructureAsset + InfrastructureUser (userType=db) 自动生成
     */
    private Map<String, Object> buildConnectionsConfig(VersionPackage vp) {
        Map<String, Object> connections = new LinkedHashMap<>();

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

        Map<String, Object> connConfig = buildSingleConnection(asset, dbUser);
        connections.put("prod_db", connConfig);

        return connections;
    }

    /**
     * 构建单个数据库连接配置
     */
    private Map<String, Object> buildSingleConnection(InfrastructureAsset asset, InfrastructureUser dbUser) {
        Map<String, Object> connConfig = new LinkedHashMap<>();

        String dbType = asset.getDbType() != null ? asset.getDbType().toLowerCase() : "oracle";
        connConfig.put("type", dbType);
        connConfig.put("user", dbUser.getUsername());
        connConfig.put("password", dbUser.getPassword());

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

    /**
     * 生成 manifest.json，包含完整的 execution_plan 和 rollback_plan
     */
    private String generateManifest(VersionPackage vp, List<String> procedureNames,
                                     Map<String, Object> connections) {
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

            // Step 2: 执行备份脚本
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

    private void addToolToZip(ZipOutputStream zos, StringBuilder checksumBuilder) throws IOException {
        ResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        String pattern = dbDeployPath.endsWith("/") ? dbDeployPath + "**/*" : dbDeployPath + "/**/*";
        Resource[] resources = resolver.getResources(pattern);

        String prefix = dbDeployPath.replace("classpath:", "");
        if (prefix.startsWith("/")) prefix = prefix.substring(1);
        if (!prefix.endsWith("/")) prefix = prefix + "/";

        for (Resource resource : resources) {
            if (!resource.isReadable()) continue;

            String uri = resource.getURI().toString();
            if (uri.contains("__pycache__") || uri.contains("/.")) continue;
            if (uri.endsWith(".pyc")) continue;

            String filename = resource.getURL().getPath();
            int index = filename.indexOf(prefix);
            if (index == -1) continue;

            String zipPath = "bin/" + filename.substring(index);
            byte[] content = StreamUtils.copyToByteArray(resource.getInputStream());
            addToZip(zos, zipPath, content, checksumBuilder);
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
