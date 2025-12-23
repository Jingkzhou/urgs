package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.DeployEnvironment;
import com.example.urgs_api.version.entity.Deployment;
import com.example.urgs_api.version.service.DeploymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/version/deploy")
@RequiredArgsConstructor
public class DeploymentController {

    private final DeploymentService deploymentService;

    // ========== 环境管理 ==========

    @GetMapping("/environments")
    public List<DeployEnvironment> listEnvironments(@RequestParam(required = false) Long ssoId) {
        if (ssoId != null) {
            return deploymentService.findEnvironmentsBySsoId(ssoId);
        }
        return deploymentService.findAllEnvironments();
    }

    @GetMapping("/environments/{id}")
    public ResponseEntity<DeployEnvironment> getEnvironment(@PathVariable Long id) {
        return deploymentService.findEnvironmentById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/environments")
    public DeployEnvironment createEnvironment(@RequestBody DeployEnvironment env) {
        return deploymentService.createEnvironment(env);
    }

    @PutMapping("/environments/{id}")
    public DeployEnvironment updateEnvironment(@PathVariable Long id, @RequestBody DeployEnvironment env) {
        return deploymentService.updateEnvironment(id, env);
    }

    @DeleteMapping("/environments/{id}")
    public ResponseEntity<Void> deleteEnvironment(@PathVariable Long id) {
        deploymentService.deleteEnvironment(id);
        return ResponseEntity.noContent().build();
    }

    // ========== 部署管理 ==========

    @GetMapping("/deployments")
    public List<Deployment> listDeployments(@RequestParam(required = false) Long ssoId,
            @RequestParam(required = false) Long envId) {
        if (envId != null) {
            return deploymentService.findDeploymentsByEnvId(envId);
        }
        if (ssoId != null) {
            return deploymentService.findDeploymentsBySsoId(ssoId);
        }
        return deploymentService.findAllDeployments();
    }

    @GetMapping("/deployments/{id}")
    public ResponseEntity<Deployment> getDeployment(@PathVariable Long id) {
        return deploymentService.findDeploymentById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 执行部署
     */
    @PostMapping("/execute")
    public Deployment deploy(@RequestBody Map<String, Object> params) {
        Long ssoId = Long.valueOf(params.get("ssoId").toString());
        Long envId = Long.valueOf(params.get("envId").toString());
        String version = (String) params.get("version");
        String artifactUrl = (String) params.get("artifactUrl");
        Long deployedBy = params.get("deployedBy") != null
                ? Long.valueOf(params.get("deployedBy").toString())
                : null;

        return deploymentService.deploy(ssoId, envId, version, artifactUrl, deployedBy);
    }

    /**
     * 回滚部署
     */
    @PostMapping("/deployments/{id}/rollback")
    public Deployment rollback(@PathVariable Long id, @RequestBody(required = false) Map<String, Object> params) {
        Long deployedBy = params != null && params.get("deployedBy") != null
                ? Long.valueOf(params.get("deployedBy").toString())
                : null;
        return deploymentService.rollback(id, deployedBy);
    }
}
