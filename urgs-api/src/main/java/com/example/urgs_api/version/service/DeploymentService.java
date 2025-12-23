package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.DeployEnvironment;
import com.example.urgs_api.version.entity.Deployment;
import com.example.urgs_api.version.repository.DeployEnvironmentRepository;
import com.example.urgs_api.version.repository.DeploymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class DeploymentService {

    private final DeployEnvironmentRepository envRepository;
    private final DeploymentRepository deploymentRepository;

    // ========== 环境管理 ==========

    public List<DeployEnvironment> findAllEnvironments() {
        return envRepository.findAll();
    }

    public List<DeployEnvironment> findEnvironmentsBySsoId(Long ssoId) {
        return envRepository.findBySsoIdOrderBySortOrderAsc(ssoId);
    }

    public Optional<DeployEnvironment> findEnvironmentById(Long id) {
        return envRepository.findById(id);
    }

    @Transactional
    public DeployEnvironment createEnvironment(DeployEnvironment env) {
        if (envRepository.existsBySsoIdAndCode(env.getSsoId(), env.getCode())) {
            throw new IllegalArgumentException("环境编码已存在: " + env.getCode());
        }
        return envRepository.save(env);
    }

    @Transactional
    public DeployEnvironment updateEnvironment(Long id, DeployEnvironment env) {
        DeployEnvironment existing = envRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("环境不存在: " + id));

        existing.setName(env.getName());
        existing.setDeployUrl(env.getDeployUrl());
        existing.setDeployType(env.getDeployType());
        existing.setConfig(env.getConfig());
        existing.setSortOrder(env.getSortOrder());

        return envRepository.save(existing);
    }

    @Transactional
    public void deleteEnvironment(Long id) {
        envRepository.deleteById(id);
    }

    // ========== 部署管理 ==========

    public List<Deployment> findAllDeployments() {
        return deploymentRepository.findAll();
    }

    public List<Deployment> findDeploymentsBySsoId(Long ssoId) {
        return deploymentRepository.findBySsoIdOrderByCreatedAtDesc(ssoId);
    }

    public List<Deployment> findDeploymentsByEnvId(Long envId) {
        return deploymentRepository.findByEnvIdOrderByCreatedAtDesc(envId);
    }

    public Optional<Deployment> findDeploymentById(Long id) {
        return deploymentRepository.findById(id);
    }

    /**
     * 创建部署
     */
    @Transactional
    public Deployment deploy(Long ssoId, Long envId, String version, String artifactUrl, Long deployedBy) {
        DeployEnvironment env = envRepository.findById(envId)
                .orElseThrow(() -> new IllegalArgumentException("环境不存在: " + envId));

        Deployment deployment = new Deployment();
        deployment.setSsoId(ssoId);
        deployment.setEnvId(envId);
        deployment.setVersion(version);
        deployment.setArtifactUrl(artifactUrl);
        deployment.setDeployedBy(deployedBy);
        deployment.setStatus(Deployment.STATUS_PENDING);

        Deployment saved = deploymentRepository.save(deployment);

        // 异步执行部署
        executeDeployAsync(saved.getId(), env);

        return saved;
    }

    /**
     * 回滚到指定版本
     */
    @Transactional
    public Deployment rollback(Long deploymentId, Long deployedBy) {
        Deployment original = deploymentRepository.findById(deploymentId)
                .orElseThrow(() -> new IllegalArgumentException("部署记录不存在: " + deploymentId));

        // 创建新的部署记录，标记为回滚
        Deployment rollbackDeployment = new Deployment();
        rollbackDeployment.setSsoId(original.getSsoId());
        rollbackDeployment.setEnvId(original.getEnvId());
        rollbackDeployment.setVersion(original.getVersion());
        rollbackDeployment.setArtifactUrl(original.getArtifactUrl());
        rollbackDeployment.setDeployedBy(deployedBy);
        rollbackDeployment.setRollbackTo(deploymentId);
        rollbackDeployment.setStatus(Deployment.STATUS_PENDING);
        rollbackDeployment.setRemark("回滚至版本: " + original.getVersion());

        Deployment saved = deploymentRepository.save(rollbackDeployment);

        // 异步执行回滚部署
        DeployEnvironment env = envRepository.findById(original.getEnvId()).orElse(null);
        if (env != null) {
            executeDeployAsync(saved.getId(), env);
        }

        return saved;
    }

    /**
     * 异步执行部署
     */
    @Async
    public void executeDeployAsync(Long deploymentId, DeployEnvironment env) {
        try {
            Deployment deployment = deploymentRepository.findById(deploymentId).orElse(null);
            if (deployment == null)
                return;

            // 更新状态为部署中
            deployment.setStatus(Deployment.STATUS_DEPLOYING);
            deployment.setDeployedAt(LocalDateTime.now());
            deploymentRepository.save(deployment);

            StringBuilder logs = new StringBuilder();
            logs.append("[").append(LocalDateTime.now()).append("] 开始部署\n");
            logs.append("[").append(LocalDateTime.now()).append("] 环境: ").append(env.getName()).append("\n");
            logs.append("[").append(LocalDateTime.now()).append("] 版本: ").append(deployment.getVersion()).append("\n");
            logs.append("[").append(LocalDateTime.now()).append("] 目标: ").append(env.getDeployUrl()).append("\n");

            // TODO: 实际执行部署逻辑
            // 可以根据 env.getDeployType() 执行不同的部署方式
            Thread.sleep(3000); // 模拟部署

            logs.append("[").append(LocalDateTime.now()).append("] 部署完成\n");

            // 更新状态为成功
            deployment.setStatus(Deployment.STATUS_SUCCESS);
            deployment.setLogs(logs.toString());
            deploymentRepository.save(deployment);

            log.info("Deployment {} completed successfully", deploymentId);

        } catch (Exception e) {
            log.error("Deployment {} failed", deploymentId, e);
            deploymentRepository.findById(deploymentId).ifPresent(d -> {
                d.setStatus(Deployment.STATUS_FAILED);
                d.setLogs(d.getLogs() + "\n[ERROR] " + e.getMessage());
                deploymentRepository.save(d);
            });
        }
    }
}
