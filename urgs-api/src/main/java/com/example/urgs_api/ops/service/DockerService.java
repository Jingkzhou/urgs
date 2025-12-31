package com.example.urgs_api.ops.service;

import com.example.urgs_api.ops.entity.DockerContainerDTO;
import com.example.urgs_api.ops.entity.DockerLogDTO;

import java.util.List;

public interface DockerService {
    List<DockerContainerDTO> listContainers();

    List<DockerLogDTO> getContainerLogs(String containerId, int lines);

    byte[] downloadContainerLogs(String containerId);
}
