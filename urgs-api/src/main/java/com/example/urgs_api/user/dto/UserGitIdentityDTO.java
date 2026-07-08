package com.example.urgs_api.user.dto;

import com.example.urgs_api.user.model.UserGitIdentity;
import lombok.Data;

@Data
public class UserGitIdentityDTO {
    private Long id;
    private Long userId;
    private String platform;
    private String gitUsername;
    private String gitEmail;
    private String gitUserId;
    private Boolean enabled;

    public static UserGitIdentityDTO fromEntity(UserGitIdentity identity) {
        if (identity == null) {
            return null;
        }
        UserGitIdentityDTO dto = new UserGitIdentityDTO();
        dto.setId(identity.getId());
        dto.setUserId(identity.getUserId());
        dto.setPlatform(identity.getPlatform());
        dto.setGitUsername(identity.getGitUsername());
        dto.setGitEmail(identity.getGitEmail());
        dto.setGitUserId(identity.getGitUserId());
        dto.setEnabled(identity.getEnabled());
        return dto;
    }
}
