package com.example.urgs_api.config;

import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Flyway Configuration for Auto-Repair
 * Useful in development when schema history might get corrupted or out of sync.
 */
@Configuration
public class FlywayConfig {

    @Bean
    public FlywayMigrationStrategy flywayMigrationStrategy() {
        return flyway -> {
            // Repair: Fixes checksum mismatches and removes failed migration entries
            flyway.repair();
            // Migrate: Applies pending migrations
            flyway.migrate();
        };
    }
}
