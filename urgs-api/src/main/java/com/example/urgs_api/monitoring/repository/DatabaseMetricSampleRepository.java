package com.example.urgs_api.monitoring.repository;

import com.example.urgs_api.monitoring.entity.DatabaseMetricSample;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface DatabaseMetricSampleRepository extends JpaRepository<DatabaseMetricSample, Long> {
    Optional<DatabaseMetricSample> findTopByDatasourceIdOrderByCollectedAtDesc(Long datasourceId);
    List<DatabaseMetricSample> findByDatasourceIdAndCollectedAtGreaterThanEqualOrderByCollectedAtAsc(Long datasourceId, LocalDateTime from);
    @Modifying
    @Query("delete from DatabaseMetricSample sample where sample.collectedAt < :before")
    int deleteByCollectedAtBefore(@Param("before") LocalDateTime before);
}
