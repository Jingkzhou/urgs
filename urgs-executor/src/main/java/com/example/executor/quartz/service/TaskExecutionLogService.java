package com.example.executor.quartz.service;

import com.example.executor.quartz.dao.QuartzTaskLogDao;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskLogEntity;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Date;

@Slf4j
@Service
public class TaskExecutionLogService {

    @Autowired
    private QuartzTaskLogDao quartzTaskLogDao;

    public ExecutionLogContext start(QuartzTaskEntity task, String dataDate) {
        QuartzTaskLogEntity entity = new QuartzTaskLogEntity();
        entity.setTaskId(task.getId());
        entity.setTaskName(task.getTaskName());
        entity.setTaskParams("dataDate=" + dataDate);
        entity.setProcessStatus(null);
        entity.setProcessDuration(null);
        entity.setProcessLog("");
        entity.setIpAddress(resolveLocalIp());
        Date now = new Date();
        entity.setCreateTime(now);
        entity.setUpdateTime(now);
        quartzTaskLogDao.insertLog(entity);

        ExecutionLogContext ctx = new ExecutionLogContext(entity.getId(), System.currentTimeMillis());
        append(ctx, String.format("[START] taskId=%s, taskName=%s, dataDate=%s", task.getId(), task.getTaskName(), dataDate));
        return ctx;
    }

    public void append(ExecutionLogContext ctx, String line) {
        if (ctx == null || ctx.getId() == null || line == null) {
            return;
        }
        String trimmed = line.trim();
        if (trimmed.isEmpty()) {
            return;
        }
        try {
            quartzTaskLogDao.appendLog(ctx.getId(), trimmed);
        } catch (Exception e) {
            log.warn("append task log failed, logId={}, msg={}", ctx.getId(), e.getMessage());
        }
    }

    public void finish(ExecutionLogContext ctx, boolean success, String summary) {
        if (ctx == null || ctx.getId() == null) {
            return;
        }
        if (summary != null && !summary.trim().isEmpty()) {
            append(ctx, "[END] " + summary.trim());
        }
        long duration = Math.max(0, System.currentTimeMillis() - ctx.getStartTs());
        try {
            quartzTaskLogDao.finishLog(ctx.getId(), success ? 0 : 1, duration);
        } catch (Exception e) {
            log.warn("finish task log failed, logId={}, msg={}", ctx.getId(), e.getMessage());
        }
    }

    private String resolveLocalIp() {
        try {
            return InetAddress.getLocalHost().getHostAddress();
        } catch (UnknownHostException e) {
            return "unknown";
        }
    }

    @Getter
    public static class ExecutionLogContext {
        private final Long id;
        private final long startTs;

        public ExecutionLogContext(Long id, long startTs) {
            this.id = id;
            this.startTs = startTs;
        }
    }
}

