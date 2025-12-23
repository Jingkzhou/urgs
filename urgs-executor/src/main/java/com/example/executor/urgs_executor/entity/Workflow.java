package com.example.executor.urgs_executor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("sys_workflow")
public class Workflow {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String name;
    private String owner;
    private String description;
    private String content; // JSON content for graph
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
