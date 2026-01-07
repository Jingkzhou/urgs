package com.example.urgs_api.system.controller;

import com.example.urgs_api.system.dto.SystemDTO;
import com.example.urgs_api.system.dto.SystemRequest;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("/api/system")
public class SystemController {

    private final SysSystemService sysSystemService;
    private final com.example.urgs_api.auth.service.OAuthService oAuthService;
    private final Random random = new Random();

    public SystemController(SysSystemService sysSystemService,
            com.example.urgs_api.auth.service.OAuthService oAuthService) {
        this.sysSystemService = sysSystemService;
        this.oAuthService = oAuthService;
    }

    @GetMapping
    public List<SystemDTO> list(jakarta.servlet.http.HttpServletRequest request,
            @RequestParam(required = false, defaultValue = "false") boolean showAll) {
        Long userId = (Long) request.getAttribute("userId");
        return sysSystemService.getSystems(userId != null ? userId : 1L, showAll).stream()
                .map(SystemDTO::fromEntity)
                .collect(Collectors.toList());
    }

    @PostMapping
    public SystemDTO create(@RequestBody SystemRequest req) {
        SysSystem cfg = toEntity(req, null);
        sysSystemService.save(cfg);
        return SystemDTO.fromEntity(cfg);
    }

    @PutMapping("/{id}")
    public ResponseEntity<SystemDTO> update(@PathVariable("id") Long id, @RequestBody SystemRequest req) {
        if (sysSystemService.getById(id) == null) {
            return ResponseEntity.notFound().build();
        }
        SysSystem cfg = toEntity(req, id);
        sysSystemService.updateById(cfg);
        return ResponseEntity.ok(SystemDTO.fromEntity(sysSystemService.getById(id)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable("id") Long id) {
        boolean removed = sysSystemService.removeById(id);
        return removed ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }

    @GetMapping("/{id}/ping")
    public ResponseEntity<SystemDTO> ping(@PathVariable("id") Long id) {
        SysSystem cfg = sysSystemService.getById(id);
        if (cfg == null)
            return ResponseEntity.notFound().build();
        // Mock heartbeat: random latency and status flip to simulate connectivity
        cfg.setStatus(random.nextBoolean() ? "active" : "maintenance");
        sysSystemService.updateById(cfg);
        return ResponseEntity.ok(SystemDTO.fromEntity(cfg));
    }

    @PostMapping("/{id}/jump")
    public ResponseEntity<java.util.Map<String, String>> jump(@PathVariable("id") Long id, HttpServletRequest request) {
        SysSystem cfg = sysSystemService.getById(id);
        if (cfg == null) {
            return ResponseEntity.notFound().build();
        }

        // Get current user ID (from interceptor)
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Generate real OAuth code
        String code = oAuthService.createCode(userId);

        // Append code to callback URL
        String targetUrl = cfg.getCallbackUrl();
        if (targetUrl.contains("?")) {
            targetUrl += "&code=" + code;
        } else {
            targetUrl += "?code=" + code;
        }

        return ResponseEntity.ok(java.util.Collections.singletonMap("targetUrl", targetUrl));
    }

    private SysSystem toEntity(SystemRequest req, Long id) {
        SysSystem cfg = new SysSystem();
        cfg.setId(id);
        cfg.setName(req.getName());
        cfg.setProtocol(req.getProtocol());
        cfg.setClientId(req.getClientId());
        cfg.setCallbackUrl(req.getCallbackUrl());
        cfg.setAlgorithm(req.getAlgorithm());
        cfg.setNetwork(req.getNetwork());
        cfg.setStatus(req.getStatus());
        cfg.setIcon(req.getIcon());
        return cfg;
    }
}
