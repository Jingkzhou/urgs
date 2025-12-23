package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.PipelineRun;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface PipelineRunRepository extends JpaRepository<PipelineRun, Long> {

    List<PipelineRun> findByPipelineIdOrderByRunNumberDesc(Long pipelineId);

    Optional<PipelineRun> findTopByPipelineIdOrderByRunNumberDesc(Long pipelineId);

    List<PipelineRun> findByStatus(String status);

    @Query("SELECT COUNT(r) FROM PipelineRun r WHERE r.pipelineId = :pipelineId")
    long countByPipelineId(Long pipelineId);
}
