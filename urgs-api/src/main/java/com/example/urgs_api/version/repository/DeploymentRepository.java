package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.Deployment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface DeploymentRepository extends JpaRepository<Deployment, Long> {

    List<Deployment> findBySsoIdOrderByCreatedAtDesc(Long ssoId);

    List<Deployment> findByEnvIdOrderByCreatedAtDesc(Long envId);

    List<Deployment> findBySsoIdAndEnvIdOrderByCreatedAtDesc(Long ssoId, Long envId);

    List<Deployment> findByStatus(String status);

    List<Deployment> findByPipelineRunId(Long pipelineRunId);
}
