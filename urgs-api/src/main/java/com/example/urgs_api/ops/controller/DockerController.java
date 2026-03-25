package com.example.urgs_api.ops.controller;

import com.example.urgs_api.ops.entity.DockerContainerDTO;
import com.example.urgs_api.ops.entity.DockerContainerStatsDTO;
import com.example.urgs_api.ops.entity.DockerLogDTO;
import com.example.urgs_api.ops.entity.DockerOperationResultDTO;
import com.example.urgs_api.ops.service.DockerService;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/ops/docker")
@RequiredArgsConstructor
@Slf4j
public class DockerController {

    private final DockerService dockerService;

    @GetMapping("/containers")
    public List<DockerContainerDTO> listContainers() {
        return dockerService.listContainers();
    }

    @GetMapping("/containers/{containerId}/logs")
    public List<DockerLogDTO> getContainerLogs(
            @PathVariable String containerId,
            @RequestParam(defaultValue = "100") int lines) {
        return dockerService.getContainerLogs(containerId, lines);
    }

    @GetMapping("/containers/{containerId}/logs/download")
    public void downloadLogs(@PathVariable String containerId, HttpServletResponse response) throws IOException {
        byte[] content = dockerService.downloadContainerLogs(containerId);

        response.setContentType(MediaType.TEXT_PLAIN_VALUE);
        response.setHeader(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"docker-" + containerId + ".log\"");
        response.setContentLength(content.length);

        response.getOutputStream().write(content);
        response.flushBuffer();
    }

    @GetMapping("/containers/{containerId}/stats")
    public DockerContainerStatsDTO getContainerStats(@PathVariable String containerId) {
        return dockerService.getContainerStats(containerId);
    }

    @GetMapping("/containers/stats")
    public List<DockerContainerStatsDTO> getAllContainerStats() {
        return dockerService.getAllContainerStats();
    }

    @PostMapping("/containers/{containerId}/start")
    public DockerOperationResultDTO startContainer(@PathVariable String containerId) {
        return dockerService.startContainer(containerId);
    }

    @PostMapping("/containers/{containerId}/stop")
    public DockerOperationResultDTO stopContainer(@PathVariable String containerId) {
        return dockerService.stopContainer(containerId);
    }

    @PostMapping("/containers/{containerId}/restart")
    public DockerOperationResultDTO restartContainer(@PathVariable String containerId) {
        return dockerService.restartContainer(containerId);
    }
}
