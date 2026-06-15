package com.example.urgs_api.online.dto;

import com.example.urgs_api.user.dto.UserDTO;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class OnlineDocumentPermissionGroupDTO {
    private Long id;
    private String name;
    private String description;
    private Integer memberCount;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    private List<UserDTO> members;
}
