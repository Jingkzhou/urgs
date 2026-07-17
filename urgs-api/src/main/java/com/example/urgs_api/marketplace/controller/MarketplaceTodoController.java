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
import com.example.urgs_api.marketplace.support.TaskAttentionSupport;
import com.example.urgs_api.role.model.Role;
import com.example.urgs_api.role.service.RoleService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

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

    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @GetMapping
    public List<MarketplaceTodoDTO> listTodos(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        List<MarketplaceTodoDTO> todos = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        long assignedCount = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .eq(WorkTask::getStatus, TaskStatus.READY.name())
                .count();
        WorkTask assignedTask = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .eq(WorkTask::getStatus, TaskStatus.READY.name())
                .orderByAsc(WorkTask::getDeadline)
                .orderByDesc(WorkTask::getCreateTime)
                .last("LIMIT 1")
                .one();
        addTodo(todos, "READY", "待开始任务", "已确定负责人但尚未开始", assignedCount, "mine", "info", assignedTask);

        long rejectedCount = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .eq(WorkTask::getStatus, TaskStatus.REWORK.name())
                .count();
        WorkTask rejectedTask = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .eq(WorkTask::getStatus, TaskStatus.REWORK.name())
                .orderByAsc(WorkTask::getDeadline)
                .orderByDesc(WorkTask::getCreateTime)
                .last("LIMIT 1")
                .one();
        addTodo(todos, "REWORK", "退回修改", "审核退回后需要补充交付", rejectedCount, "mine", "warning", rejectedTask);

        long overdueCount = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .in(WorkTask::getStatus, TaskStatus.READY.name(), TaskStatus.IN_PROGRESS.name(),
                        TaskStatus.WAITING_REVIEW.name(), TaskStatus.REWORK.name(), TaskStatus.PAUSED.name())
                .lt(WorkTask::getDeadline, now)
                .count();
        WorkTask overdueTask = workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .in(WorkTask::getStatus, TaskStatus.READY.name(), TaskStatus.IN_PROGRESS.name(),
                        TaskStatus.WAITING_REVIEW.name(), TaskStatus.REWORK.name(), TaskStatus.PAUSED.name())
                .lt(WorkTask::getDeadline, now)
                .orderByAsc(WorkTask::getDeadline)
                .orderByDesc(WorkTask::getCreateTime)
                .last("LIMIT 1")
                .one();
        addTodo(todos, "OVERDUE", "我的逾期任务", "已超过截止时间的承接任务", overdueCount, "mine", "danger", overdueTask);

        List<String> myWorkIds = workService.lambdaQuery()
                .eq(Work::getPublisherId, userId)
                .list()
                .stream()
                .map(Work::getId)
                .toList();

        if (!myWorkIds.isEmpty()) {
            long reviewCount = workTaskService.lambdaQuery()
                    .in(WorkTask::getWorkId, myWorkIds)
                    .eq(WorkTask::getStatus, TaskStatus.WAITING_REVIEW.name())
                    .count();
            WorkTask reviewTask = workTaskService.lambdaQuery()
                    .in(WorkTask::getWorkId, myWorkIds)
                    .eq(WorkTask::getStatus, TaskStatus.WAITING_REVIEW.name())
                    .orderByAsc(WorkTask::getDeadline)
                    .orderByDesc(WorkTask::getSubmittedAt)
                    .last("LIMIT 1")
                    .one();
            addTodo(todos, "WAITING_REVIEW", "待审核任务", "成员已提交，等待项目经理审核处理", reviewCount, "review", "warning", reviewTask);

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
                TaskApplication application = taskApplicationService.lambdaQuery()
                        .in(TaskApplication::getTaskId, myTaskIds)
                        .eq(TaskApplication::getStatus, "PENDING")
                        .orderByDesc(TaskApplication::getCreateTime)
                        .last("LIMIT 1")
                        .one();
                WorkTask applicationTask = application == null ? null : workTaskService.getById(application.getTaskId());
                addTodo(todos, "APPLICATION", "竞标待审批", "公开竞标任务有成员申请承接", applicationCount, "publish", "info", applicationTask);

                long appealCount = taskAppealService.lambdaQuery()
                        .in(TaskAppeal::getTaskId, myTaskIds)
                        .eq(TaskAppeal::getStatus, "PENDING")
                        .count();
                TaskAppeal appeal = taskAppealService.lambdaQuery()
                        .in(TaskAppeal::getTaskId, myTaskIds)
                        .eq(TaskAppeal::getStatus, "PENDING")
                        .orderByDesc(TaskAppeal::getCreateTime)
                        .last("LIMIT 1")
                        .one();
                WorkTask appealTask = appeal == null ? null : workTaskService.getById(appeal.getTaskId());
                addTodo(todos, "APPEAL", "积分申诉待处理", "成员对验收或积分提出复核", appealCount, "review", "danger", appealTask);
            }
        }

        addAttentionTodos(todos, userId, myWorkIds, now);

        return todos;
    }

    /**
     * 与需求统计「重点关注」一致：逾期、提测预警、质量验收预警。
     * 范围：本人承接任务 + 本人发布需求下的任务（监管科技管理员看全部）。
     * 阶段预警单独入待办；发布侧团队逾期单独入待办，避免与「我的逾期任务」重复计数。
     */
    private void addAttentionTodos(
            List<MarketplaceTodoDTO> todos,
            String userId,
            List<String> myWorkIds,
            LocalDateTime now) {
        Map<String, WorkTask> candidateById = new LinkedHashMap<>();

        workTaskService.lambdaQuery()
                .eq(WorkTask::getAssigneeId, userId)
                .list()
                .forEach(task -> candidateById.put(task.getId(), task));

        if (!myWorkIds.isEmpty()) {
            workTaskService.lambdaQuery()
                    .in(WorkTask::getWorkId, myWorkIds)
                    .list()
                    .forEach(task -> candidateById.putIfAbsent(task.getId(), task));
        }

        if (isRegTechAdmin(userId)) {
            workTaskService.lambdaQuery()
                    .notIn(WorkTask::getStatus, TaskStatus.COMPLETED.name(), TaskStatus.CANCELLED.name())
                    .list()
                    .forEach(task -> candidateById.putIfAbsent(task.getId(), task));
        }

        List<WorkTask> attentionTasks = candidateById.values().stream()
                .filter(task -> TaskAttentionSupport.needsAttention(task, now))
                .sorted(Comparator
                        .comparing((WorkTask task) -> !TaskAttentionSupport.isOverdueTask(task, now))
                        .thenComparing(task -> TaskAttentionSupport.getStageDeadlineAlert(task, now) == null)
                        .thenComparing(WorkTask::getDeadline, Comparator.nullsLast(Comparator.naturalOrder())))
                .collect(Collectors.toList());

        if (attentionTasks.isEmpty()) {
            return;
        }

        List<WorkTask> myStageAlerts = attentionTasks.stream()
                .filter(task -> userId.equals(task.getAssigneeId()))
                .filter(task -> !TaskAttentionSupport.isOverdueTask(task, now))
                .filter(task -> TaskAttentionSupport.getStageDeadlineAlert(task, now) != null)
                .toList();

        List<WorkTask> testSubmissionMine = myStageAlerts.stream()
                .filter(task -> TaskAttentionSupport.ATTENTION_TEST_SUBMISSION
                        .equals(TaskAttentionSupport.resolveAttentionType(task, now)))
                .toList();
        List<WorkTask> qualityMine = myStageAlerts.stream()
                .filter(task -> TaskAttentionSupport.ATTENTION_QUALITY_ACCEPTANCE
                        .equals(TaskAttentionSupport.resolveAttentionType(task, now)))
                .toList();

        addTodo(todos, "TEST_SUBMISSION", "提测时限预警", "距截止日期不足，需尽快完成提测",
                testSubmissionMine.size(), "mine", "warning", firstOrNull(testSubmissionMine));
        addTodo(todos, "QUALITY_ACCEPTANCE", "质量验收时限预警", "距截止日期不足，需尽快完成质量验收",
                qualityMine.size(), "mine", "warning", firstOrNull(qualityMine));

        List<WorkTask> publishScope = attentionTasks.stream()
                .filter(task -> !userId.equals(task.getAssigneeId()))
                .toList();

        List<WorkTask> publishOverdue = publishScope.stream()
                .filter(task -> TaskAttentionSupport.isOverdueTask(task, now))
                .toList();
        List<WorkTask> publishTest = publishScope.stream()
                .filter(task -> TaskAttentionSupport.ATTENTION_TEST_SUBMISSION
                        .equals(TaskAttentionSupport.resolveAttentionType(task, now)))
                .toList();
        List<WorkTask> publishQuality = publishScope.stream()
                .filter(task -> TaskAttentionSupport.ATTENTION_QUALITY_ACCEPTANCE
                        .equals(TaskAttentionSupport.resolveAttentionType(task, now)))
                .toList();

        String publishTab = "publish";
        addTodo(todos, "PUBLISH_OVERDUE", "重点关注·逾期", "需求统计中的逾期任务，需督促跟进",
                publishOverdue.size(), publishTab, "danger", firstOrNull(publishOverdue));
        addTodo(todos, "PUBLISH_TEST_SUBMISSION", "重点关注·提测预警", "需求统计中的提测时限预警",
                publishTest.size(), publishTab, "warning", firstOrNull(publishTest));
        addTodo(todos, "PUBLISH_QUALITY_ACCEPTANCE", "重点关注·质量验收预警", "需求统计中的质量验收时限预警",
                publishQuality.size(), publishTab, "warning", firstOrNull(publishQuality));
    }

    private WorkTask firstOrNull(List<WorkTask> tasks) {
        return tasks == null || tasks.isEmpty() ? null : tasks.get(0);
    }

    private void addTodo(List<MarketplaceTodoDTO> todos, String type, String title, String description,
                         long count, String targetTab, String severity, WorkTask targetTask) {
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
        if (targetTask != null) {
            dto.setTargetTaskId(targetTask.getId());
            dto.setTargetWorkId(targetTask.getWorkId());
        }
        todos.add(dto);
    }

    private boolean isRegTechAdmin(String userId) {
        try {
            User user = userService.getById(Long.valueOf(userId));
            if (user == null) {
                return false;
            }
            if ("监管科技管理员".equals(user.getRoleName())) {
                return true;
            }
            if (user.getRoleId() == null) {
                return false;
            }
            Role role = roleService.getById(user.getRoleId());
            return role != null && "监管科技管理员".equals(role.getName());
        } catch (NumberFormatException | NullPointerException ignored) {
            return false;
        }
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
