package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.ReleaseRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ReleaseRecordRepository extends JpaRepository<ReleaseRecord, Long> {

    List<ReleaseRecord> findBySsoIdOrderByCreatedAtDesc(Long ssoId);

    List<ReleaseRecord> findByStatusOrderByCreatedAtDesc(String status);

    List<ReleaseRecord> findBySsoIdAndStatusOrderByCreatedAtDesc(Long ssoId, String status);

    List<ReleaseRecord> findByCreatedByOrderByCreatedAtDesc(Long createdBy);
}
