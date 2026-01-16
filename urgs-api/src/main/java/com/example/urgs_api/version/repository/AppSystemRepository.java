package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.AppSystem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface AppSystemRepository extends JpaRepository<AppSystem, Long> {

    Optional<AppSystem> findByCode(String code);

    List<AppSystem> findByStatus(String status);

    List<AppSystem> findByNameContaining(String name);

    boolean existsByCode(String code);

    java.util.List<AppSystem> findByNameIn(java.util.Collection<String> names);

    java.util.List<AppSystem> findByCodeIn(java.util.Collection<String> codes);
}
