package com.example.urgs_api.task.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;
import java.time.LocalDate;

@Data
@TableName("t_task_realtime_monitor")
public class TaskRealtimeMonitor {
    @TableId(type = IdType.AUTO)
    private Long id;
    
    /**
     * 对应系统表的 AppID (client_id)
     */
    private String systemCode;
    
    /**
     * 任务名称
     */
    private String taskName;
    
    /**
     * 状态: RUNNING, SUCCESS, FAILED
     */
    private String taskStatus;
    
    /**
     * 任务开始时间
     */
    private LocalDateTime startTime;
    
    /**
     * 任务完成时间
     */
    private LocalDateTime endTime;
    
    /**
     * 数据日期 (业务日期)
     */
    private LocalDate dataDate;
}
