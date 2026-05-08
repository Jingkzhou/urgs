package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.GitFileContent;
import com.example.urgs_api.version.dto.ReleaseSpec;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;

@Service
@RequiredArgsConstructor
public class ReleaseSpecService {

    public static final String SPEC_PATH_YML = ".urgs/release.yml";
    public static final String SPEC_PATH_YAML = ".urgs/release.yaml";

    private final GitPlatformService gitPlatformService;
    private final ObjectMapper yamlMapper = new ObjectMapper(new YAMLFactory());

    public LoadedReleaseSpec loadSpec(Long repoId, String ref) {
        RuntimeException firstError = null;
        for (String path : new String[] { SPEC_PATH_YML, SPEC_PATH_YAML }) {
            try {
                GitFileContent content = gitPlatformService.getFileContent(repoId, ref, path);
                ReleaseSpec spec = parse(content.getContent());
                return new LoadedReleaseSpec(path, spec);
            } catch (RuntimeException e) {
                if (firstError == null) {
                    firstError = e;
                }
            } catch (Exception e) {
                throw new IllegalArgumentException("发布规格文件解析失败: " + path + " - " + e.getMessage(), e);
            }
        }
        throw new IllegalArgumentException("目标 Tag 缺少发布规格文件 .urgs/release.yml", firstError);
    }

    private ReleaseSpec parse(String yaml) throws Exception {
        if (yaml == null || yaml.isBlank()) {
            throw new IllegalArgumentException("发布规格文件为空");
        }
        ReleaseSpec spec = yamlMapper.readValue(yaml, ReleaseSpec.class);
        applyDefaults(spec);
        return spec;
    }

    private void applyDefaults(ReleaseSpec spec) {
        if (spec.getType() == null || spec.getType().isBlank()) {
            spec.setType("db");
        }
        if (spec.getPackageSpec() == null) {
            spec.setPackageSpec(new ReleaseSpec.PackageSpec());
        }
        if (spec.getPackageSpec().getInclude() == null) {
            spec.getPackageSpec().setInclude(new ArrayList<>());
        }
        if (spec.getDatabase() == null) {
            spec.setDatabase(new ReleaseSpec.DatabaseSpec());
        }
        if (spec.getDatabase().getDbType() != null) {
            spec.getDatabase().setDbType(spec.getDatabase().getDbType().trim().toLowerCase());
        }
        if ((spec.getDatabase().getDriverDir() == null || spec.getDatabase().getDriverDir().isBlank())
                && spec.getDatabase().getDbType() != null && !spec.getDatabase().getDbType().isBlank()) {
            spec.getDatabase().setDriverDir("db_deploy/drivers/" + spec.getDatabase().getDbType());
        }
        if (spec.getBackup() == null) {
            spec.setBackup(new ReleaseSpec.BackupSpec());
        }
        if (spec.getBackup().getRequired() == null) {
            spec.getBackup().setRequired(true);
        }
        if (spec.getBackup().getSourceDir() == null || spec.getBackup().getSourceDir().isBlank()) {
            spec.getBackup().setSourceDir("db/backup");
        }
        if (spec.getBackup().getTables() == null) {
            spec.getBackup().setTables(new ArrayList<>());
        }
        if (spec.getRollback() == null) {
            spec.setRollback(new ReleaseSpec.RollbackSpec());
        }
        if (spec.getRollback().getRequired() == null) {
            spec.getRollback().setRequired(true);
        }
        if (spec.getRollback().getSourceDir() == null || spec.getRollback().getSourceDir().isBlank()) {
            spec.getRollback().setSourceDir("db/rollback");
        }
        if (spec.getProcedureGuard() == null) {
            spec.setProcedureGuard(new ReleaseSpec.ProcedureGuardSpec());
        }
        if (spec.getProcedureGuard().getEnabled() == null) {
            spec.getProcedureGuard().setEnabled(true);
        }
        if (spec.getProcedureGuard().getOnMismatch() == null || spec.getProcedureGuard().getOnMismatch().isBlank()) {
            spec.getProcedureGuard().setOnMismatch("abort");
        }
        if (spec.getDeploy() == null) {
            spec.setDeploy(new ReleaseSpec.DeploySpec());
        }
        if (spec.getDeploy().getCommand() == null || spec.getDeploy().getCommand().isBlank()) {
            spec.getDeploy().setCommand("bash deploy.sh --operator ${operator}");
        }
    }

    public record LoadedReleaseSpec(String path, ReleaseSpec spec) {
    }
}
