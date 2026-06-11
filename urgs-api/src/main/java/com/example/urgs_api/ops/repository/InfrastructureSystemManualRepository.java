package com.example.urgs_api.ops.repository;

import com.example.urgs_api.ops.entity.InfrastructureSystemManual;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface InfrastructureSystemManualRepository extends JpaRepository<InfrastructureSystemManual, Long> {

    List<InfrastructureSystemManual> findByAppSystemIdOrderByCreatedAtDesc(Long appSystemId);
}
