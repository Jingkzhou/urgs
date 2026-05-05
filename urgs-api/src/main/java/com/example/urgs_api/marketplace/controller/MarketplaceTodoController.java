package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.marketplace.dto.MarketplaceTodoDTO;
import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.model.TaskApplication;
import com.example.urgs_api.marketplace.model.TaskAppeal;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.TaskAppealService;
import com.example.urgs_api.marketplace.service.TaskApplicationService;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/marketplace/todos")
public class MarketplaceTodoController {

    @Autowired
    private WorkService workService;

    @Autowired
    private WorkTaskService workTaskService;

    @Autowired
    private TaskApplicationService taskApplicationService;

    @Autowired
    private TaskAppealService taskAppealService;

    @GetMapping
    public List<MarketplaceTodoDTO> listTodos(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        List<MarketplaceTodoDTO> todos = new ArrayList<>();

        long assignedCount = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .eq(WorkTask::getStatus, TaskStatus.ASSIGNED.name())
                .count();
        addTodo(todos, "ASSIGNED", "待开始任务", "已承接但尚未进入进行中", assignedCount, "mine", "info");

        long rejectedCount = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .eq(WorkTask::getStatus, TaskStatus.REJECTED.name())
                .count();
        addTodo(todos, "REJECTED", "退回修改", "验收退回后需要补充交付", rejectedCount, "mine", "warning");

        long overdueCount = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .in(WorkTask::getStatus, TaskStatus.ASSIGNED.name(), TaskStatus.IN_PROGRESS.name())
                .lt(WorkTask::getDeadline, LocalDateTime.now())
                .count();
        addTodo(todos, "OVERDUE", "我的逾期任务", "已超过截止时间的承接任务", overdueCount, "mine", "danger");

        List<String> myWorkIds = workService.lambdaQuery()
                .eq(Work::getPublisherId, userId)
                .list()
                .stream()
                .map(Work::getId)
                .toList();

        if (!myWorkIds.isEmpty()) {
            long reviewCount = workTaskService.lambdaQuery()
                    .in(WorkTask::getWorkId, myWorkIds)
                    .eq(WorkTask::getStatus, TaskStatus.REVIEW.name())
                    .count();
            addTodo(todos, "REVIEW", "待验收任务", "成员已提交，等待项目经理验收评分", reviewCount, "review", "warning");

            List<String> myTaskIds = workTaskService.lambdaQuery()
                    .in(WorkTask::getWorkId, myWorkIds)
                    .list()
                    .stream()
                    .map(WorkTask::getId)
                    .toList();
            if (!myTaskIds.isEmpty()) {
                long applicationCount = taskApplicationService.lambdaQuery()
                        .in(TaskApplication::getTaskId, myTaskIds)
                        .eq(TaskApplication::getStatus, "PENDING")
                        .count();
                addTodo(todos, "APPLICATION", "竞标待审批", "公开竞标任务有成员申请承接", applicationCount, "publish", "info");

                long appealCount = taskAppealService.lambdaQuery()
                        .in(TaskAppeal::getTaskId, myTaskIds)
                        .eq(TaskAppeal::getStatus, "PENDING")
                        .count();
                addTodo(todos, "APPEAL", "积分申诉待处理", "成员对验收或积分提出复核", appealCount, "review", "danger");
            }
        }

        return todos;
    }

    private void addTodo(List<MarketplaceTodoDTO> todos, String type, String title, String description,
                         long count, String targetTab, String severity) {
        if (count <= 0) {
            return;
        }
        MarketplaceTodoDTO dto = new MarketplaceTodoDTO();
        dto.setType(type);
        dto.setTitle(title);
        dto.setDescription(description);
        dto.setCount(Math.toIntExact(count));
        dto.setTargetTab(targetTab);
        dto.setSeverity(severity);
        todos.add(dto);
    }

    private String getEffectiveUserId(String headerUserId, Long attrUserId) {
        if (headerUserId != null && !headerUserId.isEmpty()) {
            return headerUserId;
        }
        if (attrUserId != null) {
            return String.valueOf(attrUserId);
        }
        throw new IllegalArgumentException("Missing user identifier");
    }
}
