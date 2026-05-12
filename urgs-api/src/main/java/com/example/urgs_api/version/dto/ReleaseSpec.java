package com.example.urgs_api.version.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonAlias;
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

    private EnvironmentSpec environment = new EnvironmentSpec();

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
        @JsonAlias({"username", "execUser"})
        private String user;
        private String password;
        @JsonAlias({"server", "hostname", "ip"})
        private String host;
        private Integer port;
        @JsonAlias({"dbName", "databaseName"})
        private String database;
        private String dsn;
        private String serviceName;
        private String sid;
        private String jdbcUrl;
        private String schema;
        private String driverDir;
        private String driverJar;
        private String jdbcDriverClass;
        private String targetName = "prod_db";
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class EnvironmentSpec {
        private String code = "prod";
        private String name = "生产环境";
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
