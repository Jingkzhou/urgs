package com.example.urgs_api.ops.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DockerContainerDTO {
    private String id;
    private String name;
    private String image;
    private String status; // running, stopped, restarting
    private String ip;
    private String cpu;
    private String memory;
    private String uptime;
}
