package com.example.urgs_api.ops.service;

import com.example.urgs_api.ops.entity.DockerContainerDTO;
import com.example.urgs_api.ops.entity.DockerContainerStatsDTO;
import com.example.urgs_api.ops.entity.DockerLogDTO;
import com.example.urgs_api.ops.entity.DockerOperationResultDTO;

import java.util.List;

public interface DockerService {
    List<DockerContainerDTO> listContainers();

    List<DockerLogDTO> getContainerLogs(String containerId, int lines);

    byte[] downloadContainerLogs(String containerId);

    DockerContainerStatsDTO getContainerStats(String containerId);

    List<DockerContainerStatsDTO> getAllContainerStats();

    DockerOperationResultDTO startContainer(String containerId);

    DockerOperationResultDTO stopContainer(String containerId);

    DockerOperationResultDTO restartContainer(String containerId);
}
