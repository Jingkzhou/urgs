package com.example.urgs_api.monitoring.repository;

import com.example.urgs_api.monitoring.entity.MonitorTargetConfig;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MonitorTargetConfigRepository extends JpaRepository<MonitorTargetConfig, Long> {
    Optional<MonitorTargetConfig> findByTargetTypeAndTargetId(String targetType, Long targetId);
}
