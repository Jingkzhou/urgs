package com.example.urgs_api.version.repository;

import com.example.urgs_api.version.entity.DeployEnvironment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeployEnvironmentRepository extends JpaRepository<DeployEnvironment, Long> {

    List<DeployEnvironment> findBySsoIdOrderBySortOrderAsc(Long ssoId);

    Optional<DeployEnvironment> findBySsoIdAndCode(Long ssoId, String code);

    boolean existsBySsoIdAndCode(Long ssoId, String code);
}
