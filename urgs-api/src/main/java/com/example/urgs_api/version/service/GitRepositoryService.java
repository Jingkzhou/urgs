package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.GitRepository;
import com.example.urgs_api.version.repository.GitRepositoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
/**
 * Git 仓库服务
 * 管理 Git 仓库配置及其同步状态
 */
public class GitRepositoryService {

    private final GitRepositoryRepository repository;

    /**
     * 获取所有 Git 仓库
     * 
     * @return 仓库列表
     */
    public List<GitRepository> findAll() {
        return repository.findAll();
    }

    /**
     * 根据 SSO ID 获取仓库列表
     * 
     * @param ssoId 系统 ID
     * @return 仓库列表
     */
    public List<GitRepository> findBySsoId(Long ssoId) {
        return repository.findBySsoId(ssoId);
    }

    /**
     * 根据 ID 获取仓库详情
     * 
     * @param id 仓库 ID
     * @return Optional 包装的仓库对象
     */
    public Optional<GitRepository> findById(Long id) {
        return repository.findById(id);
    }

    /**
     * 根据平台类型获取仓库列表
     * 
     * @param platform 平台类型 (gitee, github, gitlab)
     * @return 仓库列表
     */
    public List<GitRepository> findByPlatform(String platform) {
        return repository.findByPlatform(platform);
    }

    /**
     * 创建 Git 仓库配置
     * 
     * @param repo 仓库实体
     * @return 创建后的仓库实体
     * @throws IllegalArgumentException 如果仓库地址已存在
     */
    @Transactional
    public GitRepository create(GitRepository repo) {
        if (repository.existsByCloneUrl(repo.getCloneUrl())) {
            throw new IllegalArgumentException("仓库地址已存在: " + repo.getCloneUrl());
        }
        // 生成 webhook secret
        if (repo.getWebhookSecret() == null) {
            repo.setWebhookSecret(UUID.randomUUID().toString().replace("-", ""));
        }
        return repository.save(repo);
    }

    /**
     * 更新 Git 仓库配置
     * 
     * @param id   仓库 ID
     * @param repo 更新的仓库信息
     * @return 更新后的仓库实体
     * @throws IllegalArgumentException 如果仓库不存在
     */
    @Transactional
    public GitRepository update(Long id, GitRepository repo) {
        GitRepository existing = repository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("仓库不存在: " + id));

        existing.setName(repo.getName());
        existing.setFullName(repo.getFullName());
        existing.setCloneUrl(repo.getCloneUrl());
        existing.setSshUrl(repo.getSshUrl());
        existing.setDefaultBranch(repo.getDefaultBranch());
        existing.setAccessToken(repo.getAccessToken());
        existing.setEnabled(repo.getEnabled());

        return repository.save(existing);
    }

    /**
     * 删除 Git 仓库配置
     * 
     * @param id 仓库 ID
     */
    @Transactional
    public void delete(Long id) {
        repository.deleteById(id);
    }

    /**
     * 更新最后同步时间
     * 
     * @param id 仓库 ID
     */
    @Transactional
    public void updateLastSyncTime(Long id) {
        repository.findById(id).ifPresent(repo -> {
            repo.setLastSyncedAt(LocalDateTime.now());
            repository.save(repo);
        });
    }
}
