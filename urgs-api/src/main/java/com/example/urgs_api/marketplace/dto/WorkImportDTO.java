package com.example.urgs_api.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class WorkImportDTO {
    @NotBlank(message = "工作名称不能为空")
    @Size(max = 200, message = "工作名称不能超过200个字符")
    private String title;

    @NotBlank(message = "详细描述不能为空")
    private String description;

    @NotBlank(message = "优先级不能为空")
    @Pattern(regexp = "P[0-3]", message = "优先级只能是P0、P1、P2、P3")
    private String priority;

    private LocalDateTime deadline;

    @Size(max = 100, message = "需求编号不能超过100个字符")
    private String requirementNumber;

    @NotBlank(message = "申请部门不能为空")
    @Size(max = 100, message = "申请部门不能超过100个字符")
    private String applicationDepartment;

    @NotBlank(message = "申请人不能为空")
    @Size(max = 100, message = "申请人不能超过100个字符")
    private String applicantName;

    @NotBlank(message = "归属系统不能为空")
    @Size(max = 100, message = "归属系统不能超过100个字符")
    private String owningSystem;

    @NotNull(message = "是否主系统不能为空")
    private Boolean primarySystem;

    @Size(max = 100, message = "主系统名称不能超过100个字符")
    private String primarySystemName;

    @NotBlank(message = "项目类型不能为空")
    @Pattern(regexp = "变更类|仅配合", message = "项目类型只能是变更类或仅配合")
    private String projectType;
}
