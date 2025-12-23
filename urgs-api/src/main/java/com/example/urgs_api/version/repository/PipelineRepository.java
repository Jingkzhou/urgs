package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.Pipeline;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface PipelineRepository extends JpaRepository<Pipeline, Long> {

    List<Pipeline> findBySsoId(Long ssoId);

    List<Pipeline> findByRepoId(Long repoId);

    List<Pipeline> findByEnabled(Boolean enabled);
}
