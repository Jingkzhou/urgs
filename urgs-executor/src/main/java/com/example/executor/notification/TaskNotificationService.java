package com.example.executor.notification;

import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskStatusEntity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.function.Consumer;

@Slf4j
@Service
public class TaskNotificationService {

    private final SmartSendMessageService smartSendMessageService;

    public TaskNotificationService(SmartSendMessageService smartSendMessageService) {
        this.smartSendMessageService = smartSendMessageService;
    }

    public void notifyTaskResult(QuartzTaskEntity task, QuartzTaskStatusEntity status, Consumer<String> logConsumer) {
        if (task == null || status == null || status.getStatus() == null) {
            return;
        }
        if (status.getStatus() != 3 && status.getStatus() != 4) {
            return;
        }
        try {
            List<SmartSendMessageService.NotificationSendResult> results = smartSendMessageService.sendMessage(task, status);
            for (SmartSendMessageService.NotificationSendResult result : results) {
                appendAuditLog(result, logConsumer);
            }
        } catch (Exception e) {
            log.error("Notify task result failed, taskId={}, status={}", task.getId(), status.getStatus(), e);
            if (logConsumer != null) {
                logConsumer.accept("[NOTIFY] status=FAILED, notifyType=SYSTEM, taskId=" + task.getId()
                        + ", error=" + safe(e.getMessage()));
            }
        }
    }

    private void appendAuditLog(SmartSendMessageService.NotificationSendResult result, Consumer<String> logConsumer) {
        if (result == null || logConsumer == null) {
            return;
        }
        StringBuilder sb = new StringBuilder("[NOTIFY] ");
        sb.append("status=").append(result.success() ? "SUCCESS" : "FAILED");
        sb.append(", notifyType=").append(safe(result.notifyType()));
        sb.append(", taskId=").append(safe(result.taskId()));
        sb.append(", dataDate=").append(safe(result.dataDate()));
        sb.append(", custid=").append(safe(result.custId()));
        sb.append(", seqNo=").append(safe(result.seqNo()));
        sb.append(", subSeqNo=").append(safe(result.subSeqNo()));
        sb.append(", tranDate=").append(safe(result.tranDate()));
        sb.append(", tranTimestamp=").append(safe(result.tranTimestamp()));
        sb.append(", msgUrl=").append(safe(result.msgUrl()));
        sb.append(", response=").append(safe(result.response()));
        sb.append(", error=").append(safe(result.errorMessage()));
        logConsumer.accept(sb.toString());
    }

    private String safe(Object value) {
        return value == null ? "" : String.valueOf(value);
    }
}
