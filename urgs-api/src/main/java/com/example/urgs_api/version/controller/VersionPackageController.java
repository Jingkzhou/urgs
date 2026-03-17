package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.VersionPackage;
import com.example.urgs_api.version.service.VersionPackageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/version/deploy/packages")
@RequiredArgsConstructor
public class VersionPackageController {

    private final VersionPackageService packageService;

    @GetMapping
    public List<VersionPackage> list(@RequestParam Long ssoId) {
        return packageService.findBySsoId(ssoId);
    }

    @PostMapping
    public VersionPackage create(@RequestBody Map<String, Object> params) {
        Long repoId = Long.valueOf(params.get("repoId").toString());
        Long ssoId = Long.valueOf(params.get("ssoId").toString());
        String gitRef = (String) params.get("gitRef");
        String description = (String) params.get("description");
        String previousGitRef = (String) params.get("previousGitRef");
        Long assetId = params.get("assetId") != null ? Long.valueOf(params.get("assetId").toString()) : null;
        String execUser = (String) params.get("execUser");
        Long createdBy = params.get("createdBy") != null ? Long.valueOf(params.get("createdBy").toString()) : null;
        Long envId = params.get("envId") != null ? Long.valueOf(params.get("envId").toString()) : null;

        return packageService.createPackage(repoId, ssoId, gitRef, previousGitRef, assetId, execUser, description, createdBy, envId);
    }

    /**
     * 下载部署安装包 (ZIP)
     */
    @GetMapping("/{id}/download")
    public ResponseEntity<byte[]> download(@PathVariable Long id) throws IOException {
        VersionPackage vp = packageService.findById(id);
        byte[] archive = packageService.generateArchive(id);
        
        String filename = String.format("deploy-%s-%s.zip", vp.getVersion(), vp.getGitRef());
        
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(archive);
    }

    @PutMapping("/{id}/status")
    public VersionPackage updateStatus(@PathVariable Long id, @RequestBody Map<String, Object> params) {
        String status = (String) params.get("status");
        Long operatorId = params.get("operatorId") != null ? Long.valueOf(params.get("operatorId").toString()) : null;
        return packageService.updateStatus(id, status, operatorId);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        packageService.deletePackage(id);
        return ResponseEntity.noContent().build();
    }
}
