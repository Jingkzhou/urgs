package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.InfrastructureAsset;
import com.example.urgs_api.version.repository.InfrastructureAssetRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class InfrastructureService {

    private final InfrastructureAssetRepository repository;

    public List<InfrastructureAsset> findAll() {
        return repository.findAll();
    }

    public List<InfrastructureAsset> findByFilter(Long appSystemId, Long envId, String envType) {
        // Simple manual filtering for now
        return repository.findAll().stream()
                .filter(a -> appSystemId == null || appSystemId.equals(a.getAppSystemId()))
                .filter(a -> envId == null || envId.equals(a.getEnvId()))
                .filter(a -> envType == null || envType.isEmpty() || envType.equals(a.getEnvType()))
                .collect(java.util.stream.Collectors.toList());
    }

    public Optional<InfrastructureAsset> findById(Long id) {
        return repository.findById(id);
    }

    public InfrastructureAsset save(InfrastructureAsset asset) {
        return repository.save(asset);
    }

    public InfrastructureAsset update(Long id, InfrastructureAsset assetDetails) {
        InfrastructureAsset asset = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Asset not found: " + id));

        asset.setHostname(assetDetails.getHostname());
        asset.setInternalIp(assetDetails.getInternalIp());
        asset.setExternalIp(assetDetails.getExternalIp());
        asset.setOsType(assetDetails.getOsType());
        asset.setOsVersion(assetDetails.getOsVersion());
        asset.setCpu(assetDetails.getCpu());
        asset.setMemory(assetDetails.getMemory());
        asset.setDisk(assetDetails.getDisk());
        asset.setRole(assetDetails.getRole());
        asset.setAppSystemId(assetDetails.getAppSystemId());
        asset.setEnvId(assetDetails.getEnvId());
        asset.setEnvType(assetDetails.getEnvType());
        asset.setStatus(assetDetails.getStatus());
        asset.setDescription(assetDetails.getDescription());

        return repository.save(asset);
    }

    public void delete(Long id) {
        repository.deleteById(id);
    }
}
