package com.example.urgs_api.marketplace.support;

import com.example.urgs_api.marketplace.enums.TaskStatus;
import com.example.urgs_api.marketplace.model.WorkTask;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;

/**
 * 与需求统计「重点关注」一致的任务预警判定：逾期、提测时限、质量验收时限。
 */
public final class TaskAttentionSupport {

    public static final String ATTENTION_OVERDUE = "OVERDUE";
    public static final String ATTENTION_TEST_SUBMISSION = "TEST_SUBMISSION";
    public static final String ATTENTION_QUALITY_ACCEPTANCE = "QUALITY_ACCEPTANCE";

    private static final Set<String> CLOSED_TASK_STATUSES = Set.of(
            TaskStatus.COMPLETED.name(),
            TaskStatus.CANCELLED.name());
    private static final String STAGE_TEST_SUBMISSION_COMPLETED = "TEST_SUBMISSION_COMPLETED";
    private static final String STAGE_QUALITY_ACCEPTANCE_COMPLETED = "QUALITY_ACCEPTANCE_COMPLETED";
    private static final int TEST_SUBMISSION_WARNING_WORKDAYS = 9;
    private static final int QUALITY_ACCEPTANCE_WARNING_WORKDAYS = 3;

    private TaskAttentionSupport() {
    }

    public static boolean needsAttention(WorkTask task, LocalDateTime now) {
        return isOverdueTask(task, now) || getStageDeadlineAlert(task, now) != null;
    }

    public static boolean isOverdueTask(WorkTask task, LocalDateTime now) {
        return task.getDeadline() != null
                && task.getDeadline().isBefore(now)
                && !CLOSED_TASK_STATUSES.contains(normalizeStatus(task.getStatus()))
                && !TaskStatus.PAUSED.name().equals(normalizeStatus(task.getStatus()));
    }

    /**
     * @return OVERDUE / TEST_SUBMISSION / QUALITY_ACCEPTANCE，无需关注时返回 null
     */
    public static String resolveAttentionType(WorkTask task, LocalDateTime now) {
        if (isOverdueTask(task, now)) {
            return ATTENTION_OVERDUE;
        }
        StageDeadlineAlert alert = getStageDeadlineAlert(task, now);
        return alert == null ? null : alert.type();
    }

    public static StageDeadlineAlert getStageDeadlineAlert(WorkTask task, LocalDateTime now) {
        if (task.getDeadline() == null
                || CLOSED_TASK_STATUSES.contains(normalizeStatus(task.getStatus()))
                || TaskStatus.PAUSED.name().equals(normalizeStatus(task.getStatus()))) {
            return null;
        }
        int remainingWorkdays = countRemainingWorkdays(now.toLocalDate(), task.getDeadline().toLocalDate());
        if (remainingWorkdays < 0) {
            return null;
        }
        if (STAGE_TEST_SUBMISSION_COMPLETED.equals(task.getCurrentStage())
                && remainingWorkdays <= TEST_SUBMISSION_WARNING_WORKDAYS) {
            return new StageDeadlineAlert(ATTENTION_TEST_SUBMISSION, remainingWorkdays);
        }
        if (STAGE_QUALITY_ACCEPTANCE_COMPLETED.equals(task.getCurrentStage())
                && remainingWorkdays <= QUALITY_ACCEPTANCE_WARNING_WORKDAYS) {
            return new StageDeadlineAlert(ATTENTION_QUALITY_ACCEPTANCE, remainingWorkdays);
        }
        return null;
    }

    private static int countRemainingWorkdays(LocalDate currentDate, LocalDate deadlineDate) {
        if (deadlineDate.isBefore(currentDate)) {
            return -1;
        }
        int workdays = 0;
        for (LocalDate date = currentDate.plusDays(1); !date.isAfter(deadlineDate); date = date.plusDays(1)) {
            if (date.getDayOfWeek() != DayOfWeek.SATURDAY && date.getDayOfWeek() != DayOfWeek.SUNDAY) {
                workdays++;
            }
        }
        return workdays;
    }

    private static String normalizeStatus(String status) {
        return status == null ? "UNKNOWN" : status.trim().toUpperCase();
    }

    public record StageDeadlineAlert(String type, int remainingWorkdays) {
    }
}
