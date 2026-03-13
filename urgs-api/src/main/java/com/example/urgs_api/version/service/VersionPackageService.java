package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.entity.VersionPackage;
import com.example.urgs_api.version.repository.VersionPackageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class VersionPackageService {

    private final VersionPackageRepository packageRepository;
    private final GitPlatformService gitPlatformService;

    public List<VersionPackage> findBySsoId(Long ssoId) {
        return packageRepository.findBySsoIdOrderByCreatedAtDesc(ssoId);
    }

    public VersionPackage findById(Long id) {
        return packageRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Version package not found: " + id));
    }

    /**
     * 从 Git 引用创建版本包记录
     */
    @Transactional
    public VersionPackage createPackage(Long repoId, Long ssoId, String gitRef, String description, Long createdBy) {
        // 获取提交信息
        GitCommit latestCommit = gitPlatformService.getLatestCommit(repoId, gitRef);
        
        VersionPackage vp = new VersionPackage();
        vp.setRepoId(repoId);
        vp.setSsoId(ssoId);
        vp.setGitRef(gitRef);
        vp.setVersion(gitRef); // 默认使用 ref 作为版本号，如 v1.0.0
        if (latestCommit != null) {
            vp.setCommitSha(latestCommit.getFullSha());
        }
        vp.setDescription(description);
        vp.setStatus(VersionPackage.STATUS_READY);
        vp.setCreatedBy(createdBy);
        
        // 预设默认部署脚本模板
        vp.setDeployScript("#!/bin/bash\n" +
                "echo \"[1/4] 审核检查...\"\n" +
                "# 可以在这里增加权限检查、环境验证等\n" +
                "\n" +
                "echo \"[2/4] 备份当前版本...\"\n" +
                "BACKUP_DIR=\"./backups/$(date +%Y%m%d%H%M%S)\"\n" +
                "mkdir -p $BACKUP_DIR\n" +
                "mv server-*.jar $BACKUP_DIR/ 2>/dev/null\n" +
                "\n" +
                "echo \"[3/4] 更新到新版本...\"\n" +
                "cp ./source/*.jar ./ 2>/dev/null\n" +
                "\n" +
                "echo \"[4/4] 验证服务...\"\n" +
                "echo \"部署完成，可以执行启动命令。\"\n");
        
        vp.setRollbackScript("#!/bin/bash\n" +
                "echo \"一键回退...\"\n" +
                "LATEST_BACKUP=$(ls -td ./backups/* | head -1)\n" +
                "if [ -z \"$LATEST_BACKUP\" ]; then\n" +
                "  echo \"未找到备份文件，无法回退\"\n" +
                "  exit 1\n" +
                "fi\n" +
                "cp $LATEST_BACKUP/*.jar ./ \n" +
                "echo \"已从 $LATEST_BACKUP 恢复成功\"\n");

        return packageRepository.save(vp);
    }

    /**
     * 生成部署包 (.zip)
     * 包含: source/ (源码), deploy.sh, rollback.sh
     */
    public byte[] generateArchive(Long packageId) throws IOException {
        VersionPackage vp = findById(packageId);
        
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            // 1. 写入部署脚本
            zos.putNextEntry(new ZipEntry("deploy.sh"));
            zos.write(vp.getDeployScript().getBytes());
            zos.closeEntry();
            
            // 2. 写入回退脚本
            zos.putNextEntry(new ZipEntry("rollback.sh"));
            zos.write(vp.getRollbackScript().getBytes());
            zos.closeEntry();
            
            // 3. 写入源码归档 (作为 source/ 目录内容)
            try (InputStream gitArchive = gitPlatformService.downloadArchive(vp.getRepoId(), vp.getGitRef())) {
                ZipInputStream zis = new ZipInputStream(gitArchive);
                ZipEntry entry;
                while ((entry = zis.getNextEntry()) != null) {
                    if (!entry.isDirectory()) {
                        zos.putNextEntry(new ZipEntry("source/" + entry.getName()));
                        byte[] buffer = new byte[4096];
                        int len;
                        while ((len = zis.read(buffer)) > 0) {
                            zos.write(buffer, 0, len);
                        }
                        zos.closeEntry();
                    }
                    zis.closeEntry();
                }
            }
        }
        
        return baos.toByteArray();
    }

    @Transactional
    public void deletePackage(Long id) {
        packageRepository.deleteById(id);
    }

    @Transactional
    public VersionPackage updateStatus(Long id, String status, Long operatorId) {
        VersionPackage vp = findById(id);
        vp.setStatus(status);
        if (VersionPackage.STATUS_DEPLOYED.equals(status)) {
            vp.setDeployedBy(operatorId);
            vp.setDeployedAt(LocalDateTime.now());
        }
        return packageRepository.save(vp);
    }
}
