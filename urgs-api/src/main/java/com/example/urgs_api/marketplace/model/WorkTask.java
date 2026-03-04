package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_work_task")
public class WorkTask {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String workId;
    private String title;
    private String description;
    private String requiredSkills;
    private Integer points;
    private String assignMode;
    private String status;
    private String assigneeId;
    private Integer maxApplicants;
    private LocalDateTime deadline;
    private Integer sortOrder;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
