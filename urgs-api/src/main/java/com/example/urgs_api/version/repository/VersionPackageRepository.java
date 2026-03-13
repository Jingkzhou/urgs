package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.VersionPackage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VersionPackageRepository extends JpaRepository<VersionPackage, Long> {
    List<VersionPackage> findBySsoIdOrderByCreatedAtDesc(Long ssoId);
    List<VersionPackage> findByRepoIdOrderByCreatedAtDesc(Long repoId);
}
