package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.marketplace.dto.TaskAppealDTO;
import com.example.urgs_api.marketplace.model.TaskAppeal;

public interface TaskAppealService extends IService<TaskAppeal> {
    TaskAppeal createAppeal(String taskId, String applicantId, TaskAppealDTO dto);

    boolean resolveAppeal(String appealId, String resolverId, TaskAppealDTO dto);
}
