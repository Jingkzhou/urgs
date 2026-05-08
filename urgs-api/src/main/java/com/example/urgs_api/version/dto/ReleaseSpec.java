package com.example.urgs_api.version.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class ReleaseSpec {

    private String type = "db";

    @JsonProperty("package")
    private PackageSpec packageSpec = new PackageSpec();

    private DatabaseSpec database = new DatabaseSpec();

    private BackupSpec backup = new BackupSpec();

    private RollbackSpec rollback = new RollbackSpec();

    private ProcedureGuardSpec procedureGuard = new ProcedureGuardSpec();

    private DeploySpec deploy = new DeploySpec();

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class PackageSpec {
        private List<String> include = new ArrayList<>();
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class DatabaseSpec {
        private String dbType;
        private String jdbcUrl;
        private String schema;
        private String driverDir;
        private String driverJar;
        private String jdbcDriverClass;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class BackupSpec {
        private Boolean required = true;
        private String sourceDir = "db/backup";
        private List<String> tables = new ArrayList<>();
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RollbackSpec {
        private Boolean required = true;
        private String sourceDir = "db/rollback";
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ProcedureGuardSpec {
        private Boolean enabled = true;
        private String onMismatch = "abort";
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class DeploySpec {
        private String command = "bash deploy.sh --operator ${operator}";
    }
}
