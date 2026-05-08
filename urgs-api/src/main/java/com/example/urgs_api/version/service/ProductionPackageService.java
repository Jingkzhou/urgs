package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitCommitDiff;
import com.example.urgs_api.version.dto.ProductionPackageBuildResult;
import com.example.urgs_api.version.dto.ProductionPackageGateResult;
import com.example.urgs_api.version.dto.ProductionPackageRequest;
import com.example.urgs_api.version.dto.ReleaseSpec;
import com.example.urgs_api.version.entity.VersionPackage;
import com.example.urgs_api.version.repository.VersionPackageRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class ProductionPackageService {

    private static final String GATE_PASSED = "passed";
    private static final String GATE_FAILED = "failed";

    private final ReleaseSpecService releaseSpecService;
    private final GitPlatformService gitPlatformService;
    private final VersionPackageService versionPackageService;
    private final VersionPackageRepository packageRepository;
    private final ObjectMapper objectMapper;

    @Value("${deploy.tool.workdir:classpath:db_deploy}")
    private String dbDeployPath;

    public ProductionPackageGateResult gateCheck(ProductionPackageRequest request) {
        validateRequest(request);

        List<ProductionPackageGateResult.GateItem> gates = new ArrayList<>();
        ReleaseSpecService.LoadedReleaseSpec loadedSpec;
        try {
            loadedSpec = releaseSpecService.loadSpec(request.getRepoId(), request.getGitRef());
            gates.add(gate("spec", "发布规格文件", GATE_PASSED, "已读取 " + loadedSpec.path()));
        } catch (RuntimeException e) {
            gates.add(gate("spec", "发布规格文件", GATE_FAILED, e.getMessage()));
            return buildGateResult(request, null, null, gates, List.of(), emptySummary());
        }

        ReleaseSpec spec = loadedSpec.spec();
        List<String> includes = spec.getPackageSpec().getInclude();
        if (includes == null || includes.isEmpty()) {
            gates.add(gate("include", "差异文件范围", GATE_FAILED, ".urgs/release.yml 必须声明 package.include"));
        } else {
            gates.add(gate("include", "差异文件范围", GATE_PASSED, "已声明 " + includes.size() + " 条 include 规则"));
        }
        validateDatabaseSpec(spec, gates);

        List<GitCommitDiff> diffs = gitPlatformService.compareRefs(
                request.getRepoId(), request.getPreviousGitRef(), request.getGitRef());
        List<String> includedFiles = filterIncludedFiles(diffs, includes);
        ProductionPackageGateResult.ChangeSummary summary = summarize(includedFiles, spec);

        if (includedFiles.isEmpty()) {
            gates.add(gate("diff", "Tag 差异文件", GATE_FAILED, "当前 Tag 与基线 Tag 没有命中投产范围的差异文件"));
        } else {
            gates.add(gate("diff", "Tag 差异文件", GATE_PASSED, "命中 " + includedFiles.size() + " 个投产文件"));
        }

        boolean hasSql = !summary.getSqlFiles().isEmpty();
        boolean hasProcedures = !summary.getProcedureFiles().isEmpty();
        boolean hasDbChanges = hasSql || hasProcedures;

        if (hasProcedures) {
            validateProcedureGuard(request, spec, summary, gates);
        } else {
            gates.add(gate("procedureGuard", "存储过程生产一致性校验", GATE_PASSED, "本次无存储过程变更"));
        }

        validateBackup(spec, summary, hasDbChanges, gates);
        validateRollback(spec, summary, hasSql, hasProcedures, gates);

        String status = gates.stream().anyMatch(g -> GATE_FAILED.equals(g.getStatus())) ? GATE_FAILED : GATE_PASSED;
        ProductionPackageGateResult result = buildGateResult(request, loadedSpec.path(), spec, gates, includedFiles, summary);
        result.setStatus(status);
        result.setSummary(GATE_PASSED.equals(status) ? "生产投产包门禁通过" : "生产投产包门禁失败");
        return result;
    }

    @Transactional
    public ProductionPackageBuildResult buildProductionPackage(ProductionPackageRequest request) {
        ProductionPackageGateResult gateResult = gateCheck(request);
        if (!GATE_PASSED.equals(gateResult.getStatus())) {
            throw new IllegalStateException("生产投产包门禁未通过，禁止生成生产包");
        }

        GitCommit commit = gitPlatformService.getLatestCommit(request.getRepoId(), request.getGitRef());

        VersionPackage vp = new VersionPackage();
        vp.setRepoId(request.getRepoId());
        vp.setSsoId(request.getSsoId());
        vp.setVersion(request.getGitRef());
        vp.setGitRef(request.getGitRef());
        vp.setPreviousGitRef(request.getPreviousGitRef());
        vp.setDescription(request.getDescription());
        vp.setCreatedBy(request.getCreatedBy());
        vp.setEnvId(resolveEnvId(request));
        vp.setCommitSha(commit != null ? commit.getFullSha() : null);
        vp.setPackageType(gateResult.getPackageType());
        vp.setSpecPath(gateResult.getSpecPath());
        vp.setGateStatus(gateResult.getStatus());
        vp.setGateSummary(writeJson(gateResult));
        vp.setChangedFiles(writeJson(gateResult.getIncludedFiles()));
        vp.setBackupStatus(gateResult.getChangeSummary().getBackupFiles().isEmpty() ? "table_config" : "script");
        vp.setDeployCommand("bash deploy.sh --operator <姓名>");
        vp.setRollbackCommand("bash rollback.sh --operator <姓名>");
        vp.setStatus(VersionPackage.STATUS_READY);
        vp.setBuildLog("生产投产包门禁通过，等待下载执行。生成时间: " + LocalDateTime.now());

        VersionPackage saved = packageRepository.save(vp);
        byte[] archive;
        try {
            archive = generateProductionArchive(saved.getId());
        } catch (IOException e) {
            saved.setStatus(VersionPackage.STATUS_FAILED);
            saved.setBuildLog("生产投产包生成失败: " + e.getMessage());
            packageRepository.save(saved);
            throw new IllegalStateException("生产投产包生成失败: " + e.getMessage(), e);
        }

        String packageName = productionPackageName(saved);
        saved.setPackageName(packageName);
        saved.setPackageUrl("generated://production/" + saved.getId());
        saved.setPackageSize((long) archive.length);
        saved.setBuildLog("生产投产包生成成功，文件数: " + gateResult.getIncludedFiles().size());
        packageRepository.save(saved);

        return ProductionPackageBuildResult.builder()
                .packageId(saved.getId())
                .packageName(packageName)
                .packageSize((long) archive.length)
                .deployCommand(saved.getDeployCommand())
                .rollbackCommand(saved.getRollbackCommand())
                .gateResult(gateResult)
                .build();
    }

    public byte[] generateProductionArchive(Long packageId) throws IOException {
        VersionPackage vp = versionPackageService.findById(packageId);
        List<String> includedFiles = readChangedFiles(vp);
        Set<String> includedDbPaths = includedFiles.stream()
                .filter(p -> p.startsWith("db/"))
                .collect(Collectors.toCollection(LinkedHashSet::new));

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            StringBuilder checksumBuilder = new StringBuilder();

            ProductionPackageGateResult gateResult = readGateResult(vp);
            Map<String, Object> manifest = buildRootManifest(vp, includedFiles, gateResult);
            addToZip(zos, "manifest.json",
                    objectMapper.writerWithDefaultPrettyPrinter().writeValueAsBytes(manifest), checksumBuilder);

            if (!includedDbPaths.isEmpty()) {
                List<String> backupTables = gateResult.getBackupTables();
                ReleaseSpec.DatabaseSpec databaseSpec = loadDatabaseSpec(vp);
                byte[] dbArchive = versionPackageService.generateArchive(packageId, includedDbPaths, backupTables,
                        databaseSpec);
                addToZip(zos, "db/deploy-db.zip", dbArchive, checksumBuilder);
            }

            addChangedArtifacts(zos, checksumBuilder, vp, includedFiles);
            addToZip(zos, "deploy.sh", buildDeployScript(!includedDbPaths.isEmpty()).getBytes(StandardCharsets.UTF_8),
                    checksumBuilder);
            addToZip(zos, "rollback.sh",
                    buildRollbackScript(!includedDbPaths.isEmpty()).getBytes(StandardCharsets.UTF_8), checksumBuilder);
            addToZip(zos, "README.md", buildReadme(vp).getBytes(StandardCharsets.UTF_8), checksumBuilder);

            zos.putNextEntry(new ZipEntry("checksum.sha256"));
            zos.write(checksumBuilder.toString().getBytes(StandardCharsets.UTF_8));
            zos.closeEntry();
        }
        return baos.toByteArray();
    }

    public String productionPackageName(VersionPackage vp) {
        return String.format("release-%s-%s.zip", vp.getRepoId(), sanitize(vp.getGitRef()));
    }

    private void validateRequest(ProductionPackageRequest request) {
        if (request.getRepoId() == null) {
            throw new IllegalArgumentException("repoId 不能为空");
        }
        if (request.getSsoId() == null) {
            throw new IllegalArgumentException("ssoId 不能为空");
        }
        if (isBlank(request.getGitRef())) {
            throw new IllegalArgumentException("gitRef 不能为空");
        }
        if (isBlank(request.getPreviousGitRef())) {
            throw new IllegalArgumentException("previousGitRef 不能为空");
        }
    }

    private void validateDatabaseSpec(ReleaseSpec spec, List<ProductionPackageGateResult.GateItem> gates) {
        ReleaseSpec.DatabaseSpec database = spec.getDatabase();
        if (database == null || isBlank(database.getDbType())) {
            gates.add(gate("database", "数据库平台与连接", GATE_FAILED,
                    ".urgs/release.yml 必须声明 database.dbType 和生产库连接配置"));
            return;
        }

        String dbType = database.getDbType().toLowerCase();
        Set<String> supportedTypes = Set.of("mysql", "gbase", "oracle", "xinghuan", "transwarp", "dameng");
        if (!supportedTypes.contains(dbType)) {
            gates.add(gate("database", "数据库平台与连接", GATE_FAILED,
                    "database.dbType 仅支持 mysql/gbase/oracle/xinghuan/transwarp/dameng"));
            return;
        }

        List<String> missingConnection = missingConnectionFields(database, dbType);
        if (!missingConnection.isEmpty()) {
            gates.add(gate("database", "数据库平台与连接", GATE_FAILED,
                    ".urgs/release.yml 缺少生产库连接配置: " + String.join(", ", missingConnection)));
            return;
        }

        boolean jdbcRequired = "xinghuan".equals(dbType) || "transwarp".equals(dbType) || "dameng".equals(dbType);
        boolean jdbcConfigured = jdbcRequired
                || !isBlank(database.getDriverJar())
                || !isBlank(database.getJdbcDriverClass());
        if (jdbcRequired || jdbcConfigured) {
            List<String> missing = new ArrayList<>();
            if (isBlank(database.getJdbcUrl())) {
                missing.add("database.jdbcUrl");
            }
            if (isBlank(database.getDriverJar())) {
                missing.add("database.driverJar");
            }
            if (isBlank(database.getJdbcDriverClass())) {
                missing.add("database.jdbcDriverClass");
            }
            if (!missing.isEmpty()) {
                gates.add(gate("database", "数据库平台与连接", GATE_FAILED,
                        "JDBC 驱动方式缺少配置: " + String.join(", ", missing)));
                return;
            }
            String driverResource = normalizeDriverResourcePath(database, dbType);
            if (!driverResourceExists(driverResource)) {
                gates.add(gate("database", "数据库平台与连接", GATE_FAILED,
                        "驱动包不存在，请上传到 " + driverUploadPath(driverResource)));
                return;
            }
        }

        gates.add(gate("database", "数据库平台与连接", GATE_PASSED,
                "已从 .urgs/release.yml 读取生产库连接配置: " + dbType
                        + (isBlank(database.getDriverJar()) ? "" : "，驱动包 " + database.getDriverJar())));
    }

    private List<String> missingConnectionFields(ReleaseSpec.DatabaseSpec database, String dbType) {
        List<String> missing = new ArrayList<>();
        if (isBlank(database.getUser())) {
            missing.add("database.user");
        }
        if (isBlank(database.getPassword())) {
            missing.add("database.password");
        }
        if (hasCompleteJdbcConfig(database)) {
            return missing;
        }

        if ("oracle".equals(dbType)) {
            boolean hasDsn = !isBlank(database.getDsn());
            boolean hasHostDsn = !isBlank(database.getHost())
                    && (!isBlank(database.getServiceName()) || !isBlank(database.getSid()) || !isBlank(database.getDatabase()));
            if (!hasDsn && !hasHostDsn) {
                missing.add("database.dsn 或 database.host + database.serviceName/sid/database");
            }
            return missing;
        }

        if ("mysql".equals(dbType) || "gbase".equals(dbType)) {
            if (isBlank(database.getHost()) && isBlank(database.getJdbcUrl())) {
                missing.add("database.host 或 database.jdbcUrl");
            }
            if (isBlank(firstNonBlank(database.getDatabase(), database.getSchema(), databaseNameFromJdbcUrl(database.getJdbcUrl())))) {
                missing.add("database.database 或 database.schema");
            }
            return missing;
        }

        return missing;
    }

    private boolean hasCompleteJdbcConfig(ReleaseSpec.DatabaseSpec database) {
        return !isBlank(database.getJdbcUrl())
                && !isBlank(database.getDriverJar())
                && !isBlank(database.getJdbcDriverClass());
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

    private ReleaseSpec.DatabaseSpec loadDatabaseSpec(VersionPackage vp) {
        try {
            ReleaseSpecService.LoadedReleaseSpec loadedSpec = releaseSpecService.loadSpec(vp.getRepoId(), vp.getGitRef());
            return loadedSpec.spec().getDatabase();
        } catch (RuntimeException e) {
            throw new IllegalStateException("重新读取发布规格失败，无法生成生产库连接配置: " + e.getMessage(), e);
        }
    }

    private ReleaseSpec.DatabaseSpec sanitizeDatabaseSpec(ReleaseSpec.DatabaseSpec database) {
        if (database == null) {
            return null;
        }
        ReleaseSpec.DatabaseSpec sanitized = new ReleaseSpec.DatabaseSpec();
        sanitized.setDbType(database.getDbType());
        sanitized.setHost(database.getHost());
        sanitized.setPort(database.getPort());
        sanitized.setDatabase(database.getDatabase());
        sanitized.setDsn(database.getDsn());
        sanitized.setServiceName(database.getServiceName());
        sanitized.setSid(database.getSid());
        sanitized.setJdbcUrl(database.getJdbcUrl());
        sanitized.setSchema(database.getSchema());
        sanitized.setDriverDir(database.getDriverDir());
        sanitized.setDriverJar(database.getDriverJar());
        sanitized.setJdbcDriverClass(database.getJdbcDriverClass());
        sanitized.setTargetName(database.getTargetName());
        return sanitized;
    }

    private void validateProcedureGuard(ProductionPackageRequest request, ReleaseSpec spec,
                                        ProductionPackageGateResult.ChangeSummary summary,
                                        List<ProductionPackageGateResult.GateItem> gates) {
        ReleaseSpec.ProcedureGuardSpec guard = spec.getProcedureGuard();
        if (!Boolean.TRUE.equals(guard.getEnabled())) {
            gates.add(gate("procedureGuard", "存储过程生产一致性校验", GATE_FAILED,
                    "存储过程变更必须启用 procedureGuard"));
            return;
        }
        if (!"abort".equalsIgnoreCase(guard.getOnMismatch())) {
            gates.add(gate("procedureGuard", "存储过程生产一致性校验", GATE_FAILED,
                    "procedureGuard.onMismatch 必须为 abort"));
            return;
        }

        List<String> missingBaseline = new ArrayList<>();
        for (String path : summary.getProcedureFiles()) {
            try {
                gitPlatformService.getFileContent(request.getRepoId(), request.getPreviousGitRef(), path);
            } catch (RuntimeException e) {
                missingBaseline.add(path);
            }
        }
        if (!missingBaseline.isEmpty()) {
            gates.add(gate("procedureBaseline", "上一 Tag 存储过程基线", GATE_FAILED,
                    "上一 Tag 缺少基线文件: " + String.join(", ", missingBaseline)));
            return;
        }

        gates.add(gate("procedureGuard", "存储过程生产一致性校验", GATE_PASSED,
                "生产执行时将先比较生产版本与上一 Tag 基线，不一致立即终止投产"));
    }

    private void validateBackup(ReleaseSpec spec, ProductionPackageGateResult.ChangeSummary summary,
                                boolean hasDbChanges, List<ProductionPackageGateResult.GateItem> gates) {
        if (!hasDbChanges) {
            gates.add(gate("backup", "投产前备份", GATE_PASSED, "本次无数据库变更"));
            return;
        }
        boolean hasBackupScripts = !summary.getBackupFiles().isEmpty();
        boolean hasBackupTables = spec.getBackup().getTables() != null && !spec.getBackup().getTables().isEmpty();
        if (hasBackupScripts || hasBackupTables) {
            gates.add(gate("backup", "投产前备份", GATE_PASSED,
                    hasBackupScripts ? "已提供备份脚本" : "已声明 backup.tables"));
        } else {
            gates.add(gate("backup", "投产前备份", GATE_FAILED,
                    "SQL/存储过程投产必须提供 backup 脚本或 backup.tables"));
        }
    }

    private void validateRollback(ReleaseSpec spec, ProductionPackageGateResult.ChangeSummary summary,
                                  boolean hasSql, boolean hasProcedures,
                                  List<ProductionPackageGateResult.GateItem> gates) {
        if (!hasSql && !hasProcedures) {
            gates.add(gate("rollback", "回滚动作", GATE_PASSED, "本次无数据库变更"));
            return;
        }
        if (hasSql && summary.getRollbackFiles().isEmpty()) {
            gates.add(gate("rollback", "回滚动作", GATE_FAILED, "SQL 变更必须提供 rollback 脚本"));
            return;
        }
        if (Boolean.FALSE.equals(spec.getRollback().getRequired())) {
            gates.add(gate("rollback", "回滚动作", GATE_FAILED, "数据库投产必须启用 rollback.required"));
            return;
        }
        gates.add(gate("rollback", "回滚动作", GATE_PASSED,
                hasProcedures ? "SQL 回滚脚本已提供，存储过程将自动恢复上一 Tag 版本" : "SQL 回滚脚本已提供"));
    }

    private ProductionPackageGateResult buildGateResult(ProductionPackageRequest request, String specPath,
                                                        ReleaseSpec spec,
                                                        List<ProductionPackageGateResult.GateItem> gates,
                                                        List<String> includedFiles,
                                                        ProductionPackageGateResult.ChangeSummary summary) {
        String status = gates.stream().anyMatch(g -> GATE_FAILED.equals(g.getStatus())) ? GATE_FAILED : GATE_PASSED;
        return ProductionPackageGateResult.builder()
                .repoId(request.getRepoId())
                .gitRef(request.getGitRef())
                .previousGitRef(request.getPreviousGitRef())
                .packageType(spec != null ? spec.getType() : null)
                .specPath(specPath)
                .status(status)
                .summary(GATE_PASSED.equals(status) ? "生产投产包门禁通过" : "生产投产包门禁失败")
                .deployCommand("bash deploy.sh --operator <姓名>")
                .rollbackCommand("bash rollback.sh --operator <姓名>")
                .database(spec != null ? sanitizeDatabaseSpec(spec.getDatabase()) : null)
                .gates(gates)
                .includedFiles(includedFiles)
                .backupTables(spec != null && spec.getBackup() != null ? spec.getBackup().getTables() : List.of())
                .changeSummary(summary)
                .build();
    }

    private List<String> filterIncludedFiles(List<GitCommitDiff> diffs, List<String> includes) {
        if (diffs == null || includes == null || includes.isEmpty()) {
            return List.of();
        }
        List<Pattern> patterns = includes.stream().map(this::globToPattern).toList();
        Set<String> paths = new LinkedHashSet<>();
        for (GitCommitDiff diff : diffs) {
            String path = Boolean.TRUE.equals(diff.getDeletedFile()) ? diff.getOldPath() : diff.getNewPath();
            if (isBlank(path)) {
                path = diff.getNewPath() != null ? diff.getNewPath() : diff.getOldPath();
            }
            String candidatePath = path;
            if (!isBlank(candidatePath) && patterns.stream().anyMatch(p -> p.matcher(candidatePath).matches())) {
                paths.add(candidatePath);
            }
        }
        return paths.stream().sorted().toList();
    }

    private ProductionPackageGateResult.ChangeSummary summarize(List<String> files, ReleaseSpec spec) {
        String backupDir = normalizeDir(spec.getBackup().getSourceDir());
        String rollbackDir = normalizeDir(spec.getRollback().getSourceDir());
        ProductionPackageGateResult.ChangeSummary summary = ProductionPackageGateResult.ChangeSummary.builder()
                .sqlFiles(new ArrayList<>())
                .procedureFiles(new ArrayList<>())
                .backupFiles(new ArrayList<>())
                .rollbackFiles(new ArrayList<>())
                .otherFiles(new ArrayList<>())
                .build();

        for (String file : files) {
            if (file.startsWith("db/sql/") && file.endsWith(".sql")) {
                summary.getSqlFiles().add(file);
            } else if (file.startsWith("db/procedures/") && file.endsWith(".sql")) {
                summary.getProcedureFiles().add(file);
            } else if (file.startsWith(backupDir + "/") && file.endsWith(".sql")) {
                summary.getBackupFiles().add(file);
            } else if (file.startsWith(rollbackDir + "/") && file.endsWith(".sql")) {
                summary.getRollbackFiles().add(file);
            } else {
                summary.getOtherFiles().add(file);
            }
        }
        return summary;
    }

    private void addChangedArtifacts(ZipOutputStream zos, StringBuilder checksumBuilder,
                                     VersionPackage vp, List<String> includedFiles) throws IOException {
        Set<String> artifactFiles = includedFiles.stream()
                .filter(p -> !p.startsWith("db/"))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (artifactFiles.isEmpty()) {
            return;
        }

        try (InputStream archive = gitPlatformService.downloadArchive(vp.getRepoId(), vp.getGitRef());
             ZipInputStream zis = new ZipInputStream(archive)) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                if (!entry.isDirectory()) {
                    String cleanName = cleanArchiveEntryName(entry.getName());
                    if (artifactFiles.contains(cleanName)) {
                        addToZip(zos, "artifacts/changed/" + cleanName, readStream(zis), checksumBuilder);
                    }
                }
                zis.closeEntry();
            }
        }
    }

    private Map<String, Object> buildRootManifest(VersionPackage vp, List<String> includedFiles,
                                                  ProductionPackageGateResult gateResult) {
        Map<String, Object> manifest = new LinkedHashMap<>();
        manifest.put("package_id", vp.getId());
        manifest.put("repo_id", vp.getRepoId());
        manifest.put("sso_id", vp.getSsoId());
        manifest.put("version", vp.getVersion());
        manifest.put("git_ref", vp.getGitRef());
        manifest.put("previous_git_ref", vp.getPreviousGitRef());
        manifest.put("commit_sha", vp.getCommitSha());
        manifest.put("package_type", vp.getPackageType());
        manifest.put("spec_path", vp.getSpecPath());
        manifest.put("created_at", LocalDateTime.now().toString());
        manifest.put("deploy_command", vp.getDeployCommand());
        manifest.put("rollback_command", vp.getRollbackCommand());
        if (gateResult != null && gateResult.getDatabase() != null) {
            manifest.put("database", gateResult.getDatabase());
        }
        manifest.put("changed_files", includedFiles);
        return manifest;
    }

    private String buildDeployScript(boolean hasDbPackage) {
        return """
                #!/usr/bin/env bash
                set -euo pipefail

                OPERATOR="system"
                while [[ $# -gt 0 ]]; do
                  case "$1" in
                    --operator)
                      OPERATOR="${2:-system}"
                      shift 2
                      ;;
                    *)
                      shift
                      ;;
                  esac
                done

                ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                echo "[INFO] operator=${OPERATOR}"

                if command -v sha256sum >/dev/null 2>&1; then
                  (cd "$ROOT_DIR" && sha256sum -c checksum.sha256)
                elif command -v shasum >/dev/null 2>&1; then
                  (cd "$ROOT_DIR" && shasum -a 256 -c checksum.sha256)
                else
                  echo "[WARN] checksum tool not found, skip root checksum verification"
                fi

                """.stripIndent()
                + (hasDbPackage ? """

                rm -rf "$ROOT_DIR/.runtime/db"
                mkdir -p "$ROOT_DIR/.runtime/db"
                unzip -q "$ROOT_DIR/db/deploy-db.zip" -d "$ROOT_DIR/.runtime/db"
                (cd "$ROOT_DIR/.runtime/db" && python3 -m bin.db_deploy.cli.main check --pkg .)
                (cd "$ROOT_DIR/.runtime/db" && python3 -m bin.db_deploy.cli.main deploy --pkg . --operator "$OPERATOR")
                """ : """

                echo "[INFO] 本包未包含数据库投产动作"
                """)
                + "\necho \"[INFO] deploy finished\"\n";
    }

    private String buildRollbackScript(boolean hasDbPackage) {
        return """
                #!/usr/bin/env bash
                set -euo pipefail

                OPERATOR="system"
                while [[ $# -gt 0 ]]; do
                  case "$1" in
                    --operator)
                      OPERATOR="${2:-system}"
                      shift 2
                      ;;
                    *)
                      shift
                      ;;
                  esac
                done

                ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                echo "[INFO] rollback operator=${OPERATOR}"

                """.stripIndent()
                + (hasDbPackage ? """

                rm -rf "$ROOT_DIR/.runtime/db"
                mkdir -p "$ROOT_DIR/.runtime/db"
                unzip -q "$ROOT_DIR/db/deploy-db.zip" -d "$ROOT_DIR/.runtime/db"
                (cd "$ROOT_DIR/.runtime/db" && python3 -m bin.db_deploy.cli.main rollback --pkg . --operator "$OPERATOR")
                """ : """

                echo "[INFO] 本包未包含数据库回滚动作"
                """)
                + "\necho \"[INFO] rollback finished\"\n";
    }

    private String buildReadme(VersionPackage vp) {
        return """
                # Git 仓库生产投产包

                ## 部署

                ```bash
                bash deploy.sh --operator <姓名>
                ```

                ## 回滚

                ```bash
                bash rollback.sh --operator <姓名>
                ```

                ## 阻断规则

                如果存储过程生产版本与 GitLab 上一个投产 Tag 的基线版本不一致，部署脚本会在备份和正式部署前终止。

                """.stripIndent()
                + "\n版本: " + vp.getVersion() + "\n基线: " + vp.getPreviousGitRef() + "\n";
    }

    private List<String> readChangedFiles(VersionPackage vp) {
        if (vp.getChangedFiles() == null || vp.getChangedFiles().isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(vp.getChangedFiles(), new TypeReference<List<String>>() {
            });
        } catch (Exception e) {
            throw new IllegalStateException("解析投产文件清单失败: " + e.getMessage(), e);
        }
    }

    private ProductionPackageGateResult readGateResult(VersionPackage vp) {
        if (vp.getGateSummary() == null || vp.getGateSummary().isBlank()) {
            return ProductionPackageGateResult.builder().backupTables(List.of()).build();
        }
        try {
            return objectMapper.readValue(vp.getGateSummary(), ProductionPackageGateResult.class);
        } catch (Exception e) {
            throw new IllegalStateException("解析门禁结果失败: " + e.getMessage(), e);
        }
    }

    private Long resolveEnvId(ProductionPackageRequest request) {
        return request.getEnvId();
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            throw new IllegalStateException("JSON 序列化失败: " + e.getMessage(), e);
        }
    }

    private ProductionPackageGateResult.ChangeSummary emptySummary() {
        return ProductionPackageGateResult.ChangeSummary.builder()
                .sqlFiles(new ArrayList<>())
                .procedureFiles(new ArrayList<>())
                .backupFiles(new ArrayList<>())
                .rollbackFiles(new ArrayList<>())
                .otherFiles(new ArrayList<>())
                .build();
    }

    private ProductionPackageGateResult.GateItem gate(String key, String label, String status, String message) {
        return ProductionPackageGateResult.GateItem.builder()
                .key(key)
                .label(label)
                .status(status)
                .message(message)
                .build();
    }

    private Pattern globToPattern(String glob) {
        StringBuilder regex = new StringBuilder("^");
        for (int i = 0; i < glob.length(); i++) {
            char c = glob.charAt(i);
            if (c == '*') {
                if (i + 1 < glob.length() && glob.charAt(i + 1) == '*') {
                    regex.append(".*");
                    i++;
                } else {
                    regex.append("[^/]*");
                }
            } else if (c == '?') {
                regex.append('.');
            } else if ("\\.[]{}()+-^$|".indexOf(c) >= 0) {
                regex.append('\\').append(c);
            } else {
                regex.append(c);
            }
        }
        regex.append("$");
        return Pattern.compile(regex.toString());
    }

    private String normalizeDir(String dir) {
        String normalized = dir == null || dir.isBlank() ? "" : dir.trim();
        while (normalized.startsWith("/")) {
            normalized = normalized.substring(1);
        }
        while (normalized.endsWith("/")) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }
        return normalized;
    }

    private String normalizeDriverResourcePath(ReleaseSpec.DatabaseSpec database, String dbType) {
        String driverDir = isBlank(database.getDriverDir()) ? "db_deploy/drivers/" + dbType : database.getDriverDir();
        String normalized = normalizeDir(driverDir.replace("\\", "/"));
        if (normalized.startsWith("bin/")) {
            normalized = normalized.substring("bin/".length());
        }
        return normalized + "/" + database.getDriverJar();
    }

    private boolean driverResourceExists(String resourcePath) {
        if (dbDeployPath == null || dbDeployPath.startsWith("classpath:")) {
            return new ClassPathResource(resourcePath).exists();
        }
        return Files.exists(Path.of(dbDeployPath, relativeDriverPath(resourcePath)));
    }

    private String driverUploadPath(String resourcePath) {
        if (dbDeployPath == null || dbDeployPath.startsWith("classpath:")) {
            return "urgs-api/src/main/resources/" + resourcePath;
        }
        return Path.of(dbDeployPath, relativeDriverPath(resourcePath)).toString();
    }

    private String relativeDriverPath(String resourcePath) {
        return resourcePath.startsWith("db_deploy/")
                ? resourcePath.substring("db_deploy/".length())
                : resourcePath;
    }

    private String cleanArchiveEntryName(String name) {
        return name.contains("/") ? name.substring(name.indexOf("/") + 1) : name;
    }

    private void addToZip(ZipOutputStream zos, String path, byte[] content, StringBuilder checksumBuilder)
            throws IOException {
        zos.putNextEntry(new ZipEntry(path));
        zos.write(content);
        zos.closeEntry();
        checksumBuilder.append(calculateSha256(content)).append("  ").append(path).append("\n");
    }

    private String calculateSha256(byte[] data) {
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(data);
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 计算失败", e);
        }
    }

    private byte[] readStream(InputStream is) throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        byte[] data = new byte[4096];
        int nRead;
        while ((nRead = is.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }
        return buffer.toByteArray();
    }

    private String sanitize(String value) {
        return value == null ? "unknown" : value.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (!isBlank(value)) {
                return value;
            }
        }
        return null;
    }
}
