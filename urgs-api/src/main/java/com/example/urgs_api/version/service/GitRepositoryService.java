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
public class GitRepositoryService {

    private final GitRepositoryRepository repository;

    public List<GitRepository> findAll() {
        return repository.findAll();
    }

    public List<GitRepository> findBySsoId(Long ssoId) {
        return repository.findBySsoId(ssoId);
    }

    public Optional<GitRepository> findById(Long id) {
        return repository.findById(id);
    }

    public List<GitRepository> findByPlatform(String platform) {
        return repository.findByPlatform(platform);
    }

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

    @Transactional
    public void delete(Long id) {
        repository.deleteById(id);
    }

    @Transactional
    public void updateLastSyncTime(Long id) {
        repository.findById(id).ifPresent(repo -> {
            repo.setLastSyncedAt(LocalDateTime.now());
            repository.save(repo);
        });
    }
}
