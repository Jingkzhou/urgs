package com.example.urgs_api.marketplace.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.marketplace.dto.TaskAppealDTO;
import com.example.urgs_api.marketplace.mapper.TaskAppealMapper;
import com.example.urgs_api.marketplace.model.TaskAppeal;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.TaskAppealService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class TaskAppealServiceImpl extends ServiceImpl<TaskAppealMapper, TaskAppeal> implements TaskAppealService {

    @Autowired
    private WorkTaskService workTaskService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public TaskAppeal createAppeal(String taskId, String applicantId, TaskAppealDTO dto) {
        WorkTask task = workTaskService.getById(taskId);
        if (task == null) {
            throw new IllegalArgumentException("任务不存在");
        }
        if (!applicantId.equals(task.getAssigneeId())) {
            throw new IllegalStateException("只能对自己的任务发起申诉");
        }
        TaskAppeal appeal = new TaskAppeal();
        appeal.setTaskId(taskId);
        appeal.setApplicantId(applicantId);
        appeal.setReason(dto.getReason());
        appeal.setExpectedResult(dto.getExpectedResult());
        appeal.setStatus("PENDING");
        this.save(appeal);
        workTaskService.logTaskAction(taskId, applicantId, "APPEAL_CREATE", dto.getReason());
        return appeal;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean resolveAppeal(String appealId, String resolverId, TaskAppealDTO dto) {
        TaskAppeal appeal = this.getById(appealId);
        if (appeal == null || !"PENDING".equals(appeal.getStatus())) {
            throw new IllegalArgumentException("申诉不存在或已处理");
        }
        appeal.setStatus("RESOLVED");
        appeal.setResolverId(resolverId);
        appeal.setResolution(dto.getResolution());
        appeal.setResolvedAt(LocalDateTime.now());
        boolean success = this.updateById(appeal);
        if (success) {
            workTaskService.logTaskAction(appeal.getTaskId(), resolverId, "APPEAL_RESOLVE", dto.getResolution());
        }
        return success;
    }
}
