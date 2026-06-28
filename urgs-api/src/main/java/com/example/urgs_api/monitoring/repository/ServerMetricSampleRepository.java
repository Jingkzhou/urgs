package com.example.urgs_api.monitoring.repository;

import com.example.urgs_api.monitoring.entity.ServerMetricSample;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface ServerMetricSampleRepository extends JpaRepository<ServerMetricSample, Long> {
    Optional<ServerMetricSample> findTopByAssetIdOrderByCollectedAtDesc(Long assetId);
    List<ServerMetricSample> findByAssetIdAndCollectedAtGreaterThanEqualOrderByCollectedAtAsc(Long assetId, LocalDateTime from);
    @Modifying
    @Query("delete from ServerMetricSample sample where sample.collectedAt < :before")
    int deleteByCollectedAtBefore(@Param("before") LocalDateTime before);
}
