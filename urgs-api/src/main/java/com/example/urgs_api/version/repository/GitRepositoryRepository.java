package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.GitRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface GitRepositoryRepository extends JpaRepository<GitRepository, Long> {

    List<GitRepository> findBySsoId(Long ssoId);

    List<GitRepository> findByPlatform(String platform);

    Optional<GitRepository> findByCloneUrl(String cloneUrl);

    List<GitRepository> findByEnabled(Boolean enabled);

    boolean existsByCloneUrl(String cloneUrl);
}
