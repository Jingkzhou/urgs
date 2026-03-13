package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.entity.VersionPackage;
import com.example.urgs_api.version.repository.VersionPackageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StreamUtils;

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

    // 默认从类路径读取，也可通过配置覆盖
    @Value("${deploy.tool.workdir:classpath:db_deploy}")
    private String dbDeployPath;

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
     * 符合 db_deploy 规格：manifest.json, checksum.sha256, sql/, procedures/, rollback/
     */
    public byte[] generateArchive(Long packageId) throws IOException {
        VersionPackage vp = findById(packageId);
        
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            StringBuilder checksumBuilder = new StringBuilder();
            
            // 1. 生成并写入 manifest.json
            String manifestJson = generateManifest(vp);
            addToZip(zos, "manifest.json", manifestJson.getBytes(), checksumBuilder);
            
            // 2. 处理 Git 归档内容并映射到结构中
            try (InputStream gitArchive = gitPlatformService.downloadArchive(vp.getRepoId(), vp.getGitRef())) {
                ZipInputStream zis = new ZipInputStream(gitArchive);
                ZipEntry entry;
                while ((entry = zis.getNextEntry()) != null) {
                    if (!entry.isDirectory()) {
                        String name = entry.getName();
                        // 移除顶级目录前缀 (GitHub/GitLab 归档通常带有一个随机名前缀)
                        String cleanName = name.contains("/") ? name.substring(name.indexOf("/") + 1) : name;
                        
                        // 逻辑映射：根据目录名决定在部署包中的位置
                        if (cleanName.startsWith("sql/") || cleanName.startsWith("procedures/") || cleanName.startsWith("rollback/")) {
                            byte[] content = readStream(zis);
                            addToZip(zos, cleanName, content, checksumBuilder);
                        }
                    }
                    zis.closeEntry();
                }
            }
            
            // 3. 写入部署工具包 (db_deploy) 源代码到 bin/ 目录
            addToolToZip(zos, checksumBuilder);
            
            // 4. 写入校验和文件 checksum.sha256
            zos.putNextEntry(new ZipEntry("checksum.sha256"));
            zos.write(checksumBuilder.toString().getBytes());
            zos.closeEntry();
        }
        
        return baos.toByteArray();
    }

    private void addToolToZip(ZipOutputStream zos, StringBuilder checksumBuilder) throws IOException {
        ResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        // 递归匹配所有文件，排除 pycache 和隐藏文件
        String pattern = dbDeployPath.endsWith("/") ? dbDeployPath + "**/*" : dbDeployPath + "/**/*";
        Resource[] resources = resolver.getResources(pattern);
        
        String prefix = dbDeployPath.replace("classpath:", "");
        if (prefix.startsWith("/")) prefix = prefix.substring(1);
        if (!prefix.endsWith("/")) prefix = prefix + "/";

        for (Resource resource : resources) {
            if (!resource.isReadable()) continue;
            
            String uri = resource.getURI().toString();
            // 过滤 __pycache__ 或 .git 等
            if (uri.contains("__pycache__") || uri.contains("/.")) continue;
            if (uri.endsWith(".pyc")) continue;

            // 计算在 ZIP 中的路径: bin/db_deploy/...
            String filename = resource.getURL().getPath();
            int index = filename.indexOf(prefix);
            if (index == -1) continue;
            
            String zipPath = "bin/" + filename.substring(index);
            byte[] content = StreamUtils.copyToByteArray(resource.getInputStream());
            addToZip(zos, zipPath, content, checksumBuilder);
        }
    }

    private void addToZip(ZipOutputStream zos, String path, byte[] content, StringBuilder checksumBuilder) throws IOException {
        ZipEntry entry = new ZipEntry(path);
        zos.putNextEntry(entry);
        zos.write(content);
        zos.closeEntry();

        // 计算校验和并记录到 checksumBuilder (格式: hash  path)
        String hash = calculateSha256(content);
        checksumBuilder.append(hash).append("  ").append(path).append("\n");
    }

    private String generateManifest(VersionPackage vp) {
        // 构建一个简单的基础 manifest，后续可根据需求扩展
        return String.format("{\n" +
                "  \"pkg_version\": \"%s\",\n" +
                "  \"created_at\": \"%s\",\n" +
                "  \"git_commit\": \"%s\",\n" +
                "  \"execution_plan\": [],\n" +
                "  \"rollback_plan\": []\n" +
                "}", 
                vp.getVersion(), 
                vp.getCreatedAt(), 
                vp.getCommitSha());
    }

    private String calculateSha256(byte[] data) {
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(data);
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            throw new RuntimeException("SHA-256 calculation failed", e);
        }
    }

    private byte[] readStream(InputStream is) throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[4096];
        while ((nRead = is.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }
        return buffer.toByteArray();
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
