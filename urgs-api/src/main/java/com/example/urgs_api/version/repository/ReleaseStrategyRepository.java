package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.ReleaseStrategy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ReleaseStrategyRepository extends JpaRepository<ReleaseStrategy, Long> {

    List<ReleaseStrategy> findByType(String type);

    List<ReleaseStrategy> findAllByOrderByIdAsc();
}
