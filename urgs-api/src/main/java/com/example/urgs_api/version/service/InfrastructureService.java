package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.InfrastructureAsset;
import com.example.urgs_api.version.repository.InfrastructureAssetRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
/**
 * 基础设施资产服务
 * 管理服务器、虚拟机等基础设施资产
 */
public class InfrastructureService {

    private final InfrastructureAssetRepository repository;

    public List<InfrastructureAsset> findAll() {
        return repository.findAll();
    }

    /**
     * 根据条件筛选资产
     * 
     * @param appSystemId 应用系统 ID
     * @param envId       环境 ID
     * @param envType     环境类型
     * @return 匹配的资产列表
     */
    public List<InfrastructureAsset> findByFilter(Long appSystemId, Long envId, String envType) {
        // 当前使用简单的手动过滤
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

    public void exportData(jakarta.servlet.http.HttpServletResponse response) throws java.io.IOException {
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");
        // 这里URLEncoder.encode可以防止中文乱码
        String fileName = java.net.URLEncoder.encode("infrastructure_assets", "UTF-8").replaceAll("\\+", "%20");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

        com.alibaba.excel.EasyExcel.write(response.getOutputStream(), InfrastructureAsset.class)
                .sheet("资产列表")
                .doWrite(this::findAll);
    }

    public void importData(org.springframework.web.multipart.MultipartFile file) throws java.io.IOException {
        com.alibaba.excel.EasyExcel.read(file.getInputStream(), InfrastructureAsset.class,
                new com.alibaba.excel.read.listener.ReadListener<InfrastructureAsset>() {
                    public static final int BATCH_COUNT = 100;
                    private java.util.List<InfrastructureAsset> cachedData = com.alibaba.excel.util.ListUtils
                            .newArrayListWithExpectedSize(BATCH_COUNT);

                    @Override
                    public void invoke(InfrastructureAsset data, com.alibaba.excel.context.AnalysisContext context) {
                        // 如果 ID 存在（大于0），检查是否更新；否则新建
                        // 这里简化逻辑：如果是导入，通常我们可能希望根据主机名或IP去重，或者直接覆盖
                        // 目前逻辑：有ID则尝试更新（但Excel通常不填ID则为null），无ID则新增
                        // 注意：Excel导入的ID可能跟数据库不一致，通常建议忽略ID或用于更新指定记录
                        // 如果用户修改了ID列，可能会导致主键冲突或更新错误记录。
                        // 建议策略：导入数据如果ID为空，则新增。如果ID有值，则更新。
                        cachedData.add(data);
                        if (cachedData.size() >= BATCH_COUNT) {
                            saveData();
                        }
                    }

                    @Override
                    public void doAfterAllAnalysed(com.alibaba.excel.context.AnalysisContext context) {
                        saveData();
                    }

                    private void saveData() {
                        if (org.springframework.util.CollectionUtils.isEmpty(cachedData)) {
                            return;
                        }
                        repository.saveAll(cachedData);
                        cachedData.clear();
                    }
                }).sheet().doRead();
    }
}
