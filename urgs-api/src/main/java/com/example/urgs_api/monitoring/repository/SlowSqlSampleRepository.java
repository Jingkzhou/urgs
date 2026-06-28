package com.example.urgs_api.monitoring.repository;

import com.example.urgs_api.monitoring.entity.SlowSqlSample;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface SlowSqlSampleRepository extends JpaRepository<SlowSqlSample, Long> {
    List<SlowSqlSample> findByDatasourceIdAndCollectedAtGreaterThanEqualOrderByTotalLatencyMsDesc(
            Long datasourceId, LocalDateTime from);
    @Modifying
    @Query("delete from SlowSqlSample sample where sample.collectedAt < :before")
    int deleteByCollectedAtBefore(@Param("before") LocalDateTime before);
}
