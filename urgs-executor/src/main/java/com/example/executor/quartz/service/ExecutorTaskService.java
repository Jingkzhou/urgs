package com.example.executor.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import com.example.executor.quartz.constant.TaskExeStatusEnum;
import com.example.executor.quartz.dao.QuartzTaskDao;
import com.example.executor.quartz.dao.QuartzTaskStatusDao;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskStatusEntity;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.CallableStatementCallback;
import org.springframework.jdbc.core.CallableStatementCreator;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.util.*;

@Slf4j
@Service
public class ExecutorTaskService {

    @Autowired
    private QuartzTaskDao quartzTaskDao;

    @Autowired
    private QuartzTaskStatusDao quartzTaskStatusDao;

    @Autowired
    private TaskExecutorPool taskExecutorPool;

    @Autowired
    private DataSourceCacheManager dataSourceCacheManager;

    public List<QuartzTaskEntity> queryAllActiveTasks() {
        return quartzTaskDao.queryActiveTasks();
    }

    public QuartzTaskEntity getByTaskId(Long taskId) {
        return quartzTaskDao.selectById(taskId);
    }

    public void submitTaskToPool(QuartzTaskEntity task, String dataDate) {
        String taskKey = task.getId() + "_" + dataDate;
        taskExecutorPool.submitTask(taskKey, () -> {
            try {
                DruidDataSource ds = task.getTaskType() == 2 ? dataSourceCacheManager.getOrCreate(task) : null;
                taskDispatch(task, dataDate, ds);
            } catch (Exception e) {
                log.error("{} task execute failed", taskTag(task, dataDate), e);
            }
        });
    }

    public boolean checkPredecessors(QuartzTaskEntity task, String dataDate) {
        List<Long> dependIds = quartzTaskDao.getPreTaskIdsByTaskId(task.getId());
        if (dependIds == null || dependIds.isEmpty()) {
            return true;
        }
        int finishCount = quartzTaskStatusDao.getFinishCount(dependIds, dataDate);
        return dependIds.size() == finishCount;
    }

    public void taskDispatch(QuartzTaskEntity task, String dataDate, DruidDataSource druidDataSource) throws Exception {
        Integer currentStatus = quartzTaskStatusDao.getStatusByPlanIdAndDate(task.getId(), dataDate);
        if (currentStatus != null
                && (TaskExeStatusEnum.RUNNING.getCode().equals(currentStatus) || TaskExeStatusEnum.SUCCESS.getCode().equals(currentStatus))) {
            log.info("{} already running/success, skip", taskTag(task, dataDate));
            return;
        }

        quartzTaskStatusDao.deleteByPlanIdAndDataDate(task.getId(), dataDate);

        QuartzTaskStatusEntity taskStatusEntity = new QuartzTaskStatusEntity();
        taskStatusEntity.setDataDate(dataDate);
        taskStatusEntity.setMsg("等待执行");
        taskStatusEntity.setPlanId(task.getId());
        taskStatusEntity.setStatus(TaskExeStatusEnum.WAITING.getCode());
        insertTaskExeStatus(taskStatusEntity);

        Map<String, String> result = new HashMap<>();
        try {
            if (!checkPredecessors(task, dataDate)) {
                taskStatusEntity.setStatus(TaskExeStatusEnum.WAITING.getCode());
                taskStatusEntity.setMsg("等待前置任务完成");
                updateTaskExeStatus(taskStatusEntity);
                return;
            }

            taskStatusEntity.setStatus(TaskExeStatusEnum.RUNNING.getCode());
            taskStatusEntity.setMsg("执行中");
            updateTaskExeStatus(taskStatusEntity);

            int maxRetries = 3;
            int retryCount = 0;
            result = exeTask(task, dataDate, druidDataSource);
            while (!"0".equals(result.get("code")) && task.getPeriod() != null && retryCount < maxRetries) {
                retryCount++;
                Thread.sleep(task.getPeriod());
                taskStatusEntity.setStatus(TaskExeStatusEnum.RUNNING.getCode());
                taskStatusEntity.setMsg(String.format("第%d/%d次重试, 错误: %s", retryCount, maxRetries, result.get("msg")));
                updateTaskExeStatus(taskStatusEntity);
                result = exeTask(task, dataDate, druidDataSource);
            }
        } catch (Exception e) {
            taskStatusEntity.setStatus(TaskExeStatusEnum.FAILED.getCode());
            taskStatusEntity.setMsg(trimTo500("执行异常: " + e.getMessage()));
            updateTaskExeStatus(taskStatusEntity);
            log.error("{} dispatch error", taskTag(task, dataDate), e);
            return;
        }

        if (result.get("code") == null) {
            taskStatusEntity.setStatus(TaskExeStatusEnum.FAILED.getCode());
            taskStatusEntity.setMsg("返回值不能为空");
            updateTaskExeStatus(taskStatusEntity);
            return;
        }
        if ("0".equals(result.get("code"))) {
            taskStatusEntity.setStatus(TaskExeStatusEnum.SUCCESS.getCode());
            taskStatusEntity.setMsg(result.get("msg"));
            updateTaskExeStatus(taskStatusEntity);
            return;
        }
        taskStatusEntity.setStatus(TaskExeStatusEnum.FAILED.getCode());
        taskStatusEntity.setMsg(trimTo500(result.get("msg")));
        updateTaskExeStatus(taskStatusEntity);
    }

    private void insertTaskExeStatus(QuartzTaskStatusEntity entity) {
        Date now = new Date();
        entity.setCreateTime(now);
        entity.setUpdateTime(now);
        quartzTaskStatusDao.insertStatus(entity);
    }

    private void updateTaskExeStatus(QuartzTaskStatusEntity entity) {
        entity.setUpdateTime(new Date());
        if (TaskExeStatusEnum.FAILED.getCode().equals(entity.getStatus())
                || TaskExeStatusEnum.SUCCESS.getCode().equals(entity.getStatus())) {
            entity.setEndTime(new Date());
        }
        if (TaskExeStatusEnum.RUNNING.getCode().equals(entity.getStatus())) {
            entity.setBeginTime(new Date());
        }
        quartzTaskStatusDao.updateStatus(entity);
    }

    private Map<String, String> exeTask(QuartzTaskEntity task, String dataDate, DruidDataSource ds) throws Exception {
        if (task.getTaskType() != null && task.getTaskType() == 2) {
            return exeProc(task, dataDate, ds);
        }
        return sshCommand(task, dataDate);
    }

    private Map<String, String> exeProc(QuartzTaskEntity task, String dataDate, DruidDataSource druidDataSource) {
        Map<String, String> procReturn = new HashMap<>();
        JdbcTemplate jdbcTemplate = new JdbcTemplate();
        jdbcTemplate.setDataSource(druidDataSource);
        String taskKey = task.getId() + "_" + dataDate;
        try {
            procReturn = jdbcTemplate.execute(
                    new CallableStatementCreator() {
                        @Override
                        public CallableStatement createCallableStatement(Connection con) throws SQLException {
                            String storedProc = "{call " + task.getExePath() + "}";
                            CallableStatement cs = con.prepareCall(storedProc);
                            cs.setString(1, dataDate);
                            cs.registerOutParameter(2, Types.VARCHAR);
                            cs.registerOutParameter(3, Types.VARCHAR);
                            taskExecutorPool.registerResource(taskKey, () -> {
                                try {
                                    cs.cancel();
                                } catch (Exception ignore) {
                                }
                            });
                            return cs;
                        }
                    },
                    new CallableStatementCallback<Map<String, String>>() {
                        @Override
                        public Map<String, String> doInCallableStatement(CallableStatement cs) throws SQLException, DataAccessException {
                            cs.execute();
                            Map<String, String> result = new HashMap<>();
                            result.put("code", cs.getString(2));
                            result.put("msg", cs.getString(3));
                            return result;
                        }
                    }
            );
        } catch (Exception e) {
            procReturn.put("code", "-1");
            procReturn.put("msg", trimTo500(e.getMessage()));
            log.error("{} proc execute failed", taskTag(task, dataDate), e);
        }
        return procReturn;
    }

    private Map<String, String> sshCommand(QuartzTaskEntity task, String dataDate) {
        Map<String, String> returnMap = new HashMap<>();
        Session session = null;
        ChannelExec execChannel = null;
        InputStream in = null;
        String lastLine = null;
        String taskKey = task.getId() + "_" + dataDate;

        try {
            JSch jsch = new JSch();
            session = jsch.getSession(task.getUsername(), task.getUrl(), 22);
            session.setPassword(task.getPassword());
            session.setTimeout(6000000);
            Properties config = new Properties();
            config.put("StrictHostKeyChecking", "no");
            session.setConfig(config);
            session.connect();

            execChannel = (ChannelExec) session.openChannel("exec");
            String command = task.getExePath().replace("$datadate", dataDate);
            execChannel.setCommand(command);
            execChannel.connect();

            Session finalSession = session;
            ChannelExec finalExecChannel = execChannel;
            taskExecutorPool.registerResource(taskKey, () -> {
                try {
                    finalExecChannel.disconnect();
                } catch (Exception ignore) {
                }
                try {
                    finalSession.disconnect();
                } catch (Exception ignore) {
                }
            });

            in = execChannel.getInputStream();
            BufferedReader reader = new BufferedReader(new InputStreamReader(in, Charset.forName("utf-8")));
            String currentLine;
            while ((currentLine = reader.readLine()) != null) {
                lastLine = currentLine;
            }
            if ("0".equals(lastLine)) {
                returnMap.put("code", "0");
                returnMap.put("msg", "success");
            } else {
                returnMap.put("code", "-1");
                returnMap.put("msg", trimTo500(lastLine));
            }
        } catch (Exception e) {
            returnMap.put("code", "-1");
            returnMap.put("msg", trimTo500(e.getMessage()));
            log.error("{} ssh execute failed", taskTag(task, dataDate), e);
        } finally {
            try {
                if (in != null) {
                    in.close();
                }
            } catch (Exception ignore) {
            }
            try {
                if (execChannel != null) {
                    execChannel.disconnect();
                }
            } catch (Exception ignore) {
            }
            try {
                if (session != null) {
                    session.disconnect();
                }
            } catch (Exception ignore) {
            }
        }
        return returnMap;
    }

    private String taskTag(QuartzTaskEntity task, String dataDate) {
        return "[taskId=" + task.getId() + "][taskName=" + task.getTaskName() + "][dataDate=" + dataDate + "]";
    }

    private String trimTo500(String value) {
        if (value == null) {
            return null;
        }
        return value.length() > 500 ? value.substring(0, 500) : value;
    }
}
