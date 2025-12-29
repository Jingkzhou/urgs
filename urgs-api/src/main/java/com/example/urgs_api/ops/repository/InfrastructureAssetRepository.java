package com.example.urgs_api.ops.repository;

import com.example.urgs_api.ops.entity.InfrastructureAsset;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface InfrastructureAssetRepository extends JpaRepository<InfrastructureAsset, Long> {

    List<InfrastructureAsset> findByAppSystemId(Long appSystemId);

    List<InfrastructureAsset> findByEnvId(Long envId);

    List<InfrastructureAsset> findByAppSystemIdAndEnvId(Long appSystemId, Long envId);

    List<InfrastructureAsset> findByEnvType(String envType);
}
