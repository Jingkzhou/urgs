package net.lab1024.smartadmin.module.support.quartz.service;

import com.alibaba.druid.pool.DruidDataSource;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import net.lab1024.smartadmin.common.constant.ResponseCodeConst;
import net.lab1024.smartadmin.common.domain.PageResultDTO;
import net.lab1024.smartadmin.common.domain.ResponseDTO;

import net.lab1024.smartadmin.module.support.quartz.constant.TaskExeStatusEnum;
import net.lab1024.smartadmin.module.support.quartz.constant.TaskStatusEnum;
import net.lab1024.smartadmin.module.support.quartz.dao.QuartzTaskDao;
import net.lab1024.smartadmin.module.support.quartz.dao.QuartzTaskLogDao;
import net.lab1024.smartadmin.module.support.quartz.dao.QuartzTaskStatusDao;
import net.lab1024.smartadmin.module.support.quartz.domain.entity.QuartzTaskEntity;
import net.lab1024.smartadmin.module.support.quartz.domain.entity.QuartzTaskStatusEntity;
import net.lab1024.smartadmin.third.SmartApplicationContext;
import net.lab1024.smartadmin.util.SmartBeanUtil;
import net.lab1024.smartadmin.util.SmartPageUtil;
import lombok.extern.slf4j.Slf4j;
import net.lab1024.smartadmin.module.support.quartz.domain.dto.*;
import net.lab1024.smartadmin.util.SmartSendMessageUtil;
import org.quartz.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.CallableStatementCallback;
import org.springframework.jdbc.core.CallableStatementCreator;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import net.lab1024.smartadmin.module.support.quartz.domain.dto.QuartzMissedTaskQueryDTO;
import net.lab1024.smartadmin.module.support.quartz.domain.dto.QuartzMissedTaskVO;

import java.io.*;
import java.nio.charset.Charset;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.Calendar;
import java.util.stream.Collectors;

/**
 * [  ]
 *
 * @author yandanyang
 * @version 1.0
 * @company 1024lab.net
 * @copyright (c) 2018 1024lab.netInc. All rights reserved.
 * @date 2019/4/13 0013 下午 14:50
 * @since JDK1.8
 */
/**
 * @RequirementName: 监管调度平台对接ESB微信公众号短信平台需求
 * @Developer: 周敬坤
 * @ModifiedDate: 2025-03-19
 * @ModificationDescription: JLB_W2025020608_监管调度平台对接ESB微信公众号短信平台需求。
 */

@Slf4j
@Service
public class QuartzTaskService {
    long timeToSleep = 30000; //睡眠30秒
    @Autowired
    private QuartzTaskDao quartzTaskDao;
    @Autowired
    private QuartzTaskStatusDao quartzTaskStatusDao;

    @Autowired
    private QuartzTaskLogDao quartzTaskLogDao;

    @Autowired
    private Scheduler scheduler;

    @Autowired
    SmartSendMessageUtil smartSendMessageUtil;

    @Autowired
    private TaskExecutorPool taskExecutorPool;

    @Autowired
    private DataSourceCacheManager dataSourceCacheManager;

    /**
     * 构建统一日志标签，便于按 taskId/taskName/dataDate 搜索日志
     */
    private String taskTag(QuartzTaskEntity task, String dataDate) {
        return String.format("[taskId=%d][taskName=%s][dataDate=%s]", task.getId(), task.getTaskName(), dataDate);
    }

    private String taskTag(QuartzTaskEntity task) {
        return String.format("[taskId=%d][taskName=%s]", task.getId(), task.getTaskName());
    }

    /**
     * 查询列表
     *
     * @param queryDTO
     * @return
     */


    public ResponseDTO<PageResultDTO<QuartzTaskVO>> query(QuartzQueryDTO queryDTO) {
        Page pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        List<QuartzTaskVO> taskList = quartzTaskDao.queryList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    /**
     * 查询运行日志
     *
     * @param queryDTO
     * @return
     */
    public ResponseDTO<PageResultDTO<QuartzTaskLogVO>> queryLog(QuartzLogQueryDTO queryDTO) {
        Page pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        List<QuartzTaskLogVO> taskList = quartzTaskLogDao.queryList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    /**
     * 保存或更新
     *
     * @param quartzTaskDTO
     * @return
     * @throws Exception
     */
    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> saveOrUpdateTask(QuartzTaskDTO quartzTaskDTO) throws Exception {
        ResponseDTO baseValid = this.baseValid(quartzTaskDTO);
        if (!baseValid.isSuccess()) {
            return baseValid;
        }
        Long taskId = quartzTaskDTO.getId();
        if (taskId == null) {
            return this.saveTask(quartzTaskDTO);
        } else {
            return this.updateTask(quartzTaskDTO);
        }
    }

    private ResponseDTO<String> baseValid(QuartzTaskDTO quartzTaskDTO) {
        Object taskBean = null;
        try {
            taskBean = SmartApplicationContext.getBean(quartzTaskDTO.getTaskBean());
        } catch (Exception e) {
            log.error("taskBean [{}] 不存在", quartzTaskDTO.getTaskBean(), e);
        }
        if (taskBean == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "taskBean 不存在");
        }
        if (!CronExpression.isValidExpression(quartzTaskDTO.getTaskCron())) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "请传入正确的正则表达式");
        }
        return ResponseDTO.succ();
    }

    private ResponseDTO<String> saveTask(QuartzTaskDTO quartzTaskDTO) throws Exception {
        QuartzTaskEntity taskEntity = SmartBeanUtil.copy(quartzTaskDTO, QuartzTaskEntity.class);
        taskEntity.setTaskStatus(TaskStatusEnum.NORMAL.getStatus());
        taskEntity.setUpdateTime(new Date());
        taskEntity.setCreateTime(new Date());
        quartzTaskDao.insert(taskEntity);
        return ResponseDTO.succ();
    }

    private ResponseDTO<String> updateTask(QuartzTaskDTO quartzTaskDTO) throws Exception {
        QuartzTaskEntity updateEntity = quartzTaskDao.selectById(quartzTaskDTO.getId());
        if (updateEntity == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        QuartzTaskEntity taskEntity = SmartBeanUtil.copy(quartzTaskDTO, QuartzTaskEntity.class);
        //任务状态不能更新
        taskEntity.setTaskStatus(updateEntity.getTaskStatus());
        taskEntity.setUpdateTime(new Date());
        quartzTaskDao.updateById(taskEntity);
        return ResponseDTO.succ();
    }

    /**
     * 立即运行
     *
     * @param
     * @return
     * @throws Exception
     */
    public ResponseDTO<String> runTask(QuartzQueryDTO queryDTO) throws Exception {
        QuartzTaskEntity quartzTaskEntity = quartzTaskDao.selectById(queryDTO.getId());
        if (quartzTaskEntity == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        String dataDate = queryDTO.getDataDate();
        String taskKey = quartzTaskEntity.getId() + "_" + dataDate;
        taskExecutorPool.submitTask(taskKey, () -> {
            try {
                DruidDataSource ds = quartzTaskEntity.getTaskType() == 2 ? dataSourceCacheManager.getOrCreate(quartzTaskEntity) : null;
                taskDispatch(quartzTaskEntity, dataDate, ds);
            } catch (Exception e) {
                log.error("{} 手动执行任务异常", taskTag(quartzTaskEntity, dataDate), e);
            }
        });
        return ResponseDTO.succ();
    }

    /**
     * 停止任务
     *
     * @param
     * @return
     * @throws Exception
     */
    public ResponseDTO<String> stopTask(QuartzQueryDTO queryDTO) throws Exception {
        for (int i=0;i<queryDTO.getIds().size();i++)
        {
            String id = queryDTO.getIds().get(i);
            String dataDate = queryDTO.getDataDates().get(i);
            QuartzTaskEntity quartzTaskEntity = quartzTaskDao.selectById(id);
            if (quartzTaskEntity == null) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
            }
            String taskKey = quartzTaskEntity.getId() + "_" + dataDate;
            try {
                log.info("{} 开始停止任务", taskTag(quartzTaskEntity, dataDate));

                // 存储过程任务：kill Oracle session
                if(quartzTaskEntity.getTaskType() == 2){
                    DruidDataSource druidDataSource = dataSourceCacheManager.getOrCreate(quartzTaskEntity);
                    try{
                        JdbcTemplate jdbcTemplate = new JdbcTemplate();
                        jdbcTemplate.setDataSource(druidDataSource);
                        String procName = quartzTaskEntity.getExePath().substring(quartzTaskEntity.getExePath().indexOf(".")+1,quartzTaskEntity.getExePath().indexOf("(")).toUpperCase();

                        String sql  = " select b.sid, b.SERIAL# from SYS.V_$ACCESS a, SYS.V_$session b where a.type = 'PROCEDURE' and (a.OBJECT like upper(?) or a.OBJECT like lower(?)) and a.sid = b.sid and b.USERNAME = ? and b.status = 'ACTIVE'";
                        String procPattern = "%" + procName + "%";
                        String username = quartzTaskEntity.getUsername().toUpperCase();
                        List<Map<String, Object>> resultMapList = jdbcTemplate.queryForList(sql, procPattern, procPattern, username);
                        if(resultMapList.size()>0) {
                            Map<String, Object> resultMap = resultMapList.get(0);
                            String killSQl = "alter system kill session '" + resultMap.get("SID") + "," + resultMap.get("SERIAL#") + "'";
                            log.info("{} 停止任务-杀进程: SID={}, SERIAL#={}", taskTag(quartzTaskEntity, dataDate), resultMap.get("SID"), resultMap.get("SERIAL#"));
                            jdbcTemplate.execute(killSQl);
                        }
                    }catch (Exception e){
                        log.error("{} 停止任务-杀进程异常, procName={}", taskTag(quartzTaskEntity, dataDate), quartzTaskEntity.getExePath(), e);
                    }
                }
                // 取消线程池中的任务
                taskExecutorPool.cancelTask(taskKey);
                log.info("{} 任务已中断", taskTag(quartzTaskEntity, dataDate));
            }catch (Exception e){
                log.error("{} 停止任务异常", taskTag(quartzTaskEntity, dataDate), e);
            }finally {
                QuartzTaskStatusEntity taskStatusEntity = new QuartzTaskStatusEntity();
                taskStatusEntity.setStatus(TaskExeStatusEnum.FAILED.getCode());
                taskStatusEntity.setMsg("停止任务");
                taskStatusEntity.setDataDate(dataDate);
                taskStatusEntity.setPlanId(quartzTaskEntity.getId());
                updateTaskExeStatus(taskStatusEntity);
                log.info("{} 状态变更为 [{}]", taskTag(quartzTaskEntity, dataDate), TaskExeStatusEnum.FAILED.getDesc());
            }
        }
        return ResponseDTO.succ();
    }

    /**
     * 暂停运行
     *
     * @param taskId
     * @return
     * @throws Exception
     */
    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> pauseTask(Long taskId) throws Exception {
        QuartzTaskEntity quartzTaskEntity = quartzTaskDao.selectById(taskId);
        if (quartzTaskEntity == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        quartzTaskEntity.setTaskStatus(TaskStatusEnum.PAUSE.getStatus());
        quartzTaskDao.updateById(quartzTaskEntity);
        return ResponseDTO.succ();
    }

    /**
     * 恢复任务
     *
     * @param taskId
     * @return
     * @throws Exception
     */
    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> resumeTask(Long taskId) throws Exception {
        QuartzTaskEntity quartzTaskEntity = quartzTaskDao.selectById(taskId);
        if (quartzTaskEntity == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        quartzTaskEntity.setTaskStatus(TaskStatusEnum.NORMAL.getStatus());
        quartzTaskDao.updateById(quartzTaskEntity);
        return ResponseDTO.succ();
    }

    /**
     * 删除任务
     *
     * @param taskId
     * @return
     * @throws Exception
     */
    public ResponseDTO<String> deleteTask(Long taskId) throws Exception {
        QuartzTaskEntity quartzTaskEntity = quartzTaskDao.selectById(taskId);
        if (quartzTaskEntity == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        quartzTaskDao.deleteById(taskId);
        return ResponseDTO.succ();
    }

    /**
     * 通过任务Id 获取任务实体
     *
     * @param taskId
     * @return
     */
    public QuartzTaskEntity getByTaskId(Long taskId) {
        return quartzTaskDao.selectById(taskId);
    }

    /**
     * 查询所有活跃任务 (task_status=0)
     * 供 TaskDispatcherJob 调用
     */
    public List<QuartzTaskEntity> queryAllActiveTasks() {
        return quartzTaskDao.queryActiveTasks();
    }

    /**
     * 重置任务调度器
     * 清理 Quartz QRTZ_ 表中的旧数据（旧架构遗留的2500个Job）。
     * 新架构使用 Spring @Scheduled 驱动 TaskDispatcherJob，不再需要 Quartz 调度。
     */
    public void resetTask() throws Exception {
        scheduler.clear();
        log.info("任务调度器已重置: 已清理 QRTZ 表旧数据, 调度由 Spring @Scheduled 驱动");
    }

    /**
     * 将任务提交到线程池执行（供 DependencyCheckTask 和内部调用使用）
     */
    public void submitTaskToPool(QuartzTaskEntity task, String dataDate) {
        String taskKey = task.getId() + "_" + dataDate;
        taskExecutorPool.submitTask(taskKey, () -> {
            try {
                DruidDataSource ds = task.getTaskType() == 2 ? dataSourceCacheManager.getOrCreate(task) : null;
                taskDispatch(task, dataDate, ds);
            } catch (Exception e) {
                log.error("{} 任务执行异常", taskTag(task, dataDate), e);
            }
        });
    }

    /**
     * 将逗号分隔的ID字符串转为 List<Long>
     */
    private List<Long> parseDependIds(String dependIdStr) {
        List<Long> result = new ArrayList<>();
        if (dependIdStr == null || "".equals(dependIdStr.trim())) {
            return result;
        }
        String[] parts = dependIdStr.split(",");
        for (String part : parts) {
            String trimmed = part.trim();
            if (!"".equals(trimmed)) {
                result.add(Long.valueOf(trimmed));
            }
        }
        return result;
    }

    void deleteTaskExeStatus(Long taskId, String dataDate) {
        quartzTaskStatusDao.delete(taskId, dataDate);
    }

    void insertTaskExeStatus(QuartzTaskStatusEntity taskStatusEntity) {
      //  taskStatusEntity.setBeginTime(new Date());
        taskStatusEntity.setCreateTime(new Date());
        taskStatusEntity.setUpdateTime(new Date());
        quartzTaskStatusDao.insert(taskStatusEntity);
    }

    /**
     * 检查前置任务是否全部完成（非阻塞，一次性检查）
     *
     * @param task
     * @param dataDate
     * @return true=全部完成可执行, false=还有未完成的
     */
    public boolean checkPredecessors(QuartzTaskEntity task, String dataDate) {
        if (task.getDependId() == null || "".equals(task.getDependId()) || "null".equals(task.getDependId())) {
            return true;
        }
        String[] idStrs = task.getDependId().split(",");
        List<Long> dependIds = new ArrayList<>();
        for (String idStr : idStrs) {
            dependIds.add(Long.valueOf(idStr.trim()));
        }
        int finishCount = quartzTaskStatusDao.getFinishCount(dependIds, dataDate);
        if (dependIds.size() != finishCount) {
            log.info("{} 前置任务检查: 总数={}, 已完成={}, 未完成={}", taskTag(task, dataDate), dependIds.size(), finishCount, dependIds.size() - finishCount);
            return false;
        }
        log.info("{} 前置任务检查: 全部完成, 总数={}", taskTag(task, dataDate), dependIds.size());
        return true;
    }

    /**
     * 删除任务
     *
     * @param
     * @return
     * @throws Exception
     */
    public ResponseDTO<String> updateTaskExeStatus(QuartzTaskStatusEntity taskStatusEntity) throws Exception {
        taskStatusEntity.setUpdateTime(new Date());
        if (TaskExeStatusEnum.FAILED.getCode().equals(taskStatusEntity.getStatus())
                || TaskExeStatusEnum.SUCCESS.getCode().equals(taskStatusEntity.getStatus())) {
            taskStatusEntity.setEndTime(new Date());
        }
        if (TaskExeStatusEnum.RUNNING.getCode().equals(taskStatusEntity.getStatus())) {
            taskStatusEntity.setBeginTime(new Date());
        }
        quartzTaskStatusDao.update(taskStatusEntity);
        return ResponseDTO.succ();
    }

    public Map<String, String> exeTask(QuartzTaskEntity task, String dataDate,DruidDataSource druidDataSource,QuartzTaskStatusEntity taskStatusEntity) throws Exception {
        Map<String, String> result = new HashMap<>();
        if (task.getTaskType() == 1) {
            log.info("{} 执行类型: 脚本任务, 路径={}", taskTag(task, dataDate), task.getExePath());
            result = sshCommand(task, dataDate,taskStatusEntity);
        } else if (task.getTaskType() == 2) {
            log.info("{} 执行类型: 存储过程, 路径={}", taskTag(task, dataDate), task.getExePath());
            result = exeProc(task, dataDate,druidDataSource);
        }
        return result;
    }


    public Map<String, String> exeProc(QuartzTaskEntity task, String dataDate,DruidDataSource druidDataSource) {
        JdbcTemplate jdbcTemplate = new JdbcTemplate();
        jdbcTemplate.setDataSource(druidDataSource);
        Map<String, String> procRetrun = new HashMap<>();
        String taskKey = task.getId() + "_" + dataDate;
        try {
            procRetrun = (Map<String, String>) jdbcTemplate.execute(
                    new CallableStatementCreator() {
                        public CallableStatement createCallableStatement(Connection con) throws SQLException {
                            String storedProc = "{call " + task.getExePath() + "}";
                            CallableStatement cs = con.prepareCall(storedProc);
                            cs.setString(1, dataDate);// 设置输入参数的值
                            cs.registerOutParameter(2, Types.VARCHAR);// 注册输出参数的类型
                            cs.registerOutParameter(3, Types.VARCHAR);// 注册输出参数的类型
                            // 注册Statement到线程池，强制停止时调用cs.cancel()中断execute()
                            taskExecutorPool.registerResource(taskKey, () -> {
                                try { cs.cancel(); } catch (Exception ignored) {}
                            });
                            return cs;
                        }
                    }, new CallableStatementCallback() {
                        public Object doInCallableStatement(CallableStatement cs) throws SQLException, DataAccessException {
                            cs.execute();
                            String code = "";
                            String returnCode = cs.getString(2);

                            Map<String, String> rMap = new HashMap<>();
                            rMap.put("code", returnCode);
                            rMap.put("msg", cs.getString(3));

                            return rMap;// 获取输出参数的值
                        }
                    });
        }catch (Exception e){
            procRetrun.put("code","-1");
            procRetrun.put("msg",e.getMessage());
            log.error("{} 存储过程执行异常, 路径={}", taskTag(task, dataDate), task.getExePath(), e);
        }
        log.info("{} 存储过程执行完毕, code={}, msg={}", taskTag(task, dataDate), procRetrun.get("code"), procRetrun.get("msg"));
        return procRetrun;
    }

    public Map<String, String> sshCommand(QuartzTaskEntity task, String dataDate,QuartzTaskStatusEntity taskStatusEntity) throws Exception {
        JSch jsch = new JSch();
        String lastLine = "";
        String currentLine = "";
        Session session = null;
        InputStream in = null;
        ChannelExec execChannel = null;
        Map<String, String> returnMap = new HashMap<>();
        long startTime = System.currentTimeMillis();

        try {
            log.info("{} SSH连接 {}@{}:22", taskTag(task, dataDate), task.getUsername(), task.getUrl());
            session = jsch.getSession(task.getUsername(), task.getUrl(), 22);
            session.setPassword(task.getPassword());
            session.setTimeout(6000000);
            Properties config = new Properties();
            //严格的主机key检查
            config.put("StrictHostKeyChecking", "no");
            session.setConfig(config);
            session.connect();
            execChannel = (ChannelExec) session.openChannel("exec");
            String command = task.getExePath().replace("$datadate", dataDate);
            execChannel.setCommand(command);
            log.info("{} SSH执行命令: {}", taskTag(task, dataDate), command);
            execChannel.connect();

            // 注册SSH资源到线程池，强制停止时直接断开连接使readLine()抛异常退出
            String taskKey = task.getId() + "_" + dataDate;
            final Session sshSession = session;
            final ChannelExec sshChannel = execChannel;
            taskExecutorPool.registerResource(taskKey, () -> {
                try { sshChannel.disconnect(); } catch (Exception ignored) {}
                try { sshSession.disconnect(); } catch (Exception ignored) {}
            });

            in = execChannel.getInputStream();
            BufferedReader br1 = new BufferedReader(new InputStreamReader(in, Charset.forName("utf-8")));
            while ((currentLine = br1.readLine()) != null) {
                lastLine = currentLine;
            }
            long elapsed = System.currentTimeMillis() - startTime;
            log.info("{} SSH执行完毕, 返回值={}, 耗时={}ms, command={}", taskTag(task, dataDate), lastLine, elapsed, task.getExePath());
            if("0".equals(lastLine)){
                returnMap.put("code", "0");
            }else{
                returnMap.put("code", "-1");
                returnMap.put("msg", lastLine);
            }
        } catch (Exception e) {
            log.error("{} SSH执行异常, 路径={}", taskTag(task, dataDate), task.getExePath(), e);
            taskStatusEntity.setStatus(TaskExeStatusEnum.FAILED.getCode());
            String errorDetail = String.format("执行路径: %s, 错误: %s", task.getExePath(), e.getMessage());
            taskStatusEntity.setMsg(errorDetail.length() > 500 ? errorDetail.substring(0, 500) : errorDetail);
            updateTaskExeStatus(taskStatusEntity);
            QuartzQueryDTO queryDTO = new QuartzQueryDTO();
            List<String> ids = new ArrayList<>();
            ids.add(String.valueOf(task.getId()));
            queryDTO.setIds(ids);
            queryDTO.setDataDate(dataDate);
            stopTask(queryDTO);
        } finally {
            if (in != null) {
                try {
                    in.close();
                } catch (IOException e) {
                    log.error("{} SSH输入流关闭异常", taskTag(task, dataDate), e);
                }
            }
            if (execChannel != null) {
                execChannel.disconnect();
            }
            if (session != null) {
                session.disconnect();
            }
        }
        return returnMap;
    }

    public void taskDispatch(QuartzTaskEntity task, String dataDate,DruidDataSource druidDataSource) throws Exception {
        long dispatchStartTime = System.currentTimeMillis();
        log.info("{} 开始执行", taskTag(task, dataDate));

        // 防重入：如果当前 dataDate 已有执行中或已完成的记录，直接返回
        Integer currentStatus = quartzTaskStatusDao.getStatusByPlanIdAndDate(task.getId(), dataDate);
        if (currentStatus != null && (TaskExeStatusEnum.RUNNING.getCode().equals(currentStatus) || TaskExeStatusEnum.SUCCESS.getCode().equals(currentStatus))) {
            log.info("{} 已在执行中或已完成(status={}), 跳过", taskTag(task, dataDate), currentStatus);
            return;
        }

        //插入新增任务执行计划 状态为等待执行
        log.info("{} 清理历史日志记录", taskTag(task, dataDate));
        deleteTaskExeStatus(task.getId(), dataDate);

        QuartzTaskStatusEntity taskStatusEntity = new QuartzTaskStatusEntity();
        taskStatusEntity.setDataDate(dataDate);
        taskStatusEntity.setMsg("等待执行");
        taskStatusEntity.setPlanId(task.getId());
        taskStatusEntity.setStatus(TaskExeStatusEnum.WAITING.getCode());
        insertTaskExeStatus(taskStatusEntity);
        log.info("{} 状态变更为 [{}]", taskTag(task, dataDate), TaskExeStatusEnum.WAITING.getDesc());

        Map<String, String> result = new HashMap<>();
        try {
            //检核依赖任务是否完成，如完成继续执行，未完成则释放线程等待依赖检查器触发
            if (!checkPredecessors(task, dataDate)) {
                taskStatusEntity.setStatus(TaskExeStatusEnum.WAITING.getCode());
                taskStatusEntity.setMsg("等待前置任务完成");
                updateTaskExeStatus(taskStatusEntity);
                log.info("{} 等待前置任务完成, 释放线程", taskTag(task, dataDate));
                return; // 释放线程，由依赖检查器后续触发
            }
            //检核依赖完成后执行状态修改为执行中
            taskStatusEntity.setStatus(TaskExeStatusEnum.RUNNING.getCode());
            taskStatusEntity.setMsg("执行中");
            updateTaskExeStatus(taskStatusEntity);
            log.info("{} 状态变更为 [{}]", taskTag(task, dataDate), TaskExeStatusEnum.RUNNING.getDesc());

            //调用存储过程或者脚本执行任务
            int maxRetries = 3;
            int retryCount = 0;
            result = exeTask(task, dataDate, druidDataSource, taskStatusEntity);
            log.info("{} 执行结果 code={}, msg={}", taskTag(task, dataDate), result.get("code"), result.get("msg"));

            while (!"0".equals(result.get("code")) && task.getPeriod() != null && retryCount < maxRetries) {
                retryCount++;
                log.warn("{} 第{}/{}次重试, {}毫秒后执行, 上次错误: {}", taskTag(task, dataDate), retryCount, maxRetries, task.getPeriod(), result.get("msg"));
                Thread.sleep(task.getPeriod());
                taskStatusEntity.setStatus(TaskExeStatusEnum.RUNNING.getCode());
                taskStatusEntity.setMsg(String.format("第%d/%d次重试, 错误: %s", retryCount, maxRetries, result.get("msg")));
                updateTaskExeStatus(taskStatusEntity);
                result = exeTask(task, dataDate, druidDataSource, taskStatusEntity);
                log.info("{} 重试执行结果 code={}, msg={}", taskTag(task, dataDate), result.get("code"), result.get("msg"));
            }
        } catch (Exception e) {
            //执行异常则修改执行状态为异常
            log.error("{} 任务调度异常", taskTag(task, dataDate), e);
            taskStatusEntity.setStatus(TaskExeStatusEnum.FAILED.getCode());
            String errorDetail = String.format("执行路径: %s, 错误: %s", task.getExePath(), e.getMessage());
            taskStatusEntity.setMsg(errorDetail.length() > 500 ? errorDetail.substring(0, 500) : errorDetail);
            updateTaskExeStatus(taskStatusEntity);
        }
        log.info("{} planId={}, result_code={}", taskTag(task, dataDate), taskStatusEntity.getPlanId(), result.get("code"));
        switch (String.valueOf(result.get("code"))) {
            //如果返回值为空 则提示异常
            case "null":
                taskStatusEntity.setStatus(TaskExeStatusEnum.FAILED.getCode());
                taskStatusEntity.setMsg("返回值不能为空");
                updateTaskExeStatus(taskStatusEntity);
                log.warn("{} 执行完成, 最终状态=[{}], 原因=返回值为空", taskTag(task, dataDate), TaskExeStatusEnum.FAILED.getDesc());
                break;
            //如果返回值为0 则提示成功
            case "0":
                taskStatusEntity.setStatus(TaskExeStatusEnum.SUCCESS.getCode());
                taskStatusEntity.setMsg(result.get("msg"));
                updateTaskExeStatus(taskStatusEntity);
                long elapsed = System.currentTimeMillis() - dispatchStartTime;
                log.info("{} 执行完成, 最终状态=[{}], 耗时={}ms", taskTag(task, dataDate), TaskExeStatusEnum.SUCCESS.getDesc(), elapsed);
                break;
            default:
                taskStatusEntity.setStatus(TaskExeStatusEnum.FAILED.getCode());
                String failMsg = result.get("msg");
                taskStatusEntity.setMsg(failMsg);
                updateTaskExeStatus(taskStatusEntity);
                log.error("{} 执行完成, 最终状态=[{}], msg={}", taskTag(task, dataDate), TaskExeStatusEnum.FAILED.getDesc(), failMsg);
                break;
        }
        smartSendMessageUtil.sendMessage(task,taskStatusEntity);

    }

    public DruidDataSource getDataSource(QuartzTaskEntity task) {
        return dataSourceCacheManager.getOrCreate(task);
    }

    public ResponseDTO<PageResultDTO<QuartzTaskStatusVO>> queryTaskStatus(QuartzQueryDTO queryDTO) {
        Page pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        List<QuartzTaskStatusVO> taskList = quartzTaskStatusDao.queryList(pageParam, queryDTO);

        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryYl(QuartzQueryDTO queryDTO, String type) {
        Page pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        //获取status
        QuartzTaskStatusEntity quartzTaskStatusEntity = quartzTaskStatusDao.selectById(queryDTO.getStatusId());
        //获取task信息
        QuartzTaskEntity quartzTaskEntity = getByTaskId(quartzTaskStatusEntity.getPlanId());
        Set<String> dependIdSet = new HashSet<>();
        //找到所有依赖返回set
        if ("yl".equals(type)) {
            findYl(dependIdSet, quartzTaskEntity);
        } else if ("byl".equals(type)) {
            //被依赖
            findByl(dependIdSet, quartzTaskEntity);
        }
        queryDTO.setDependId(String.join(", ", dependIdSet));
        //补充自己任务ID;
        String dependId = "".equals(queryDTO.getDependId()) ? quartzTaskEntity.getId() + "" : quartzTaskEntity.getId() + "," + queryDTO.getDependId();
        queryDTO.setDependId(dependId);
        // 将逗号分隔的字符串转为 List<Long> 用于参数化查询
        queryDTO.setDependIds(parseDependIds(dependId));
        queryDTO.setDataDate(quartzTaskStatusEntity.getDataDate());
        List<QuartzTaskVO> taskList = quartzTaskStatusDao.queryYlList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    /**
     * 查找所有依赖任务
     *
     * @param set
     * @param task
     * @return
     */
    public Set<String> findYl(Set<String> set, QuartzTaskEntity task) {
        if (!"".equals(task.getDependId()) && task.getDependId() != null) {
            String[] dependIdStrArray = task.getDependId().split(",");

            for (String depId : dependIdStrArray
            ) {
                QuartzTaskEntity quartzTaskEntity = getByTaskId(Long.valueOf(depId));
                set.add(depId);
              //  findYl(set, quartzTaskEntity);
            }
        }
        return set;
    }


    /**
     * 查找所有被依赖任务
     *
     * @param set
     * @param task
     * @return
     */
    public Set<String> findByl(Set<String> set, QuartzTaskEntity task) {
        String[] dependIdStrArray = task.getDependId().split(",");
        List<QuartzTaskEntity> quartzTaskEntityList = quartzTaskDao.getTaskListByDepId(task.getId());
        for (QuartzTaskEntity quartzTaskEntity : quartzTaskEntityList
        ) {
            set.add(String.valueOf(quartzTaskEntity.getId()));
          //  findByl(set, quartzTaskEntity);
        }
        return set;
    }

    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryManyYl(QuartzQueryDTO queryDTO, String type) {
        Set<String> dependIdSet = new HashSet<>();
        Page pageParam = SmartPageUtil.convert2QueryPage(queryDTO);


        String ids = String.join(",", queryDTO.getIds());
        //找到所有依赖返回set
        for (String idStr : queryDTO.getIds()
        ) {
            QuartzTaskEntity quartzTaskEntity = getByTaskId(Long.valueOf(idStr));

            //依赖
            if ("yl".equals(type)) {
                findYl(dependIdSet, quartzTaskEntity);
            } else if ("byl".equals(type)) {
                //被依赖
                findByl(dependIdSet, quartzTaskEntity);
            }
        }
        //补充自己任务ID;
        String dependId = dependIdSet.size() == 0 ? ids + "" : ids + "," + String.join(", ", dependIdSet);
        queryDTO.setDependId(dependId);
        // 将逗号分隔的字符串转为 List<Long> 用于参数化查询
        queryDTO.setDependIds(parseDependIds(dependId));
        List<QuartzTaskVO> taskList = quartzTaskStatusDao.queryYlList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));

    }

    public ResponseDTO<String> taskRun(QuartzQueryDTO queryDTO) throws Exception {

        List<QuartzTaskStatusEntity> quartzTaskStatusEntityList = new ArrayList<>();
        //删除之前任务执行状态
        for (String statusId : queryDTO.getStatusIds()
        ) {
            QuartzTaskStatusEntity quartzTaskStatusEntity = quartzTaskStatusDao.selectById(statusId);
            quartzTaskStatusEntityList.add(quartzTaskStatusEntity);
            quartzTaskStatusDao.deleteById(statusId);
        }

        for (QuartzTaskStatusEntity quartzTaskStatusEntity : quartzTaskStatusEntityList
        ) {
            //获取执行状态信息  获得任务id 及数据日期

            QuartzTaskEntity quartzTaskEntity = quartzTaskDao.selectById(quartzTaskStatusEntity.getPlanId());
            if (quartzTaskEntity == null) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
            }
            submitTaskToPool(quartzTaskEntity, quartzTaskStatusEntity.getDataDate());
        }
        return ResponseDTO.succ();
    }

    public ResponseDTO<String> passTask(QuartzQueryDTO queryDTO) throws Exception {
        for (int i=0;i<queryDTO.getIds().size();i++) {
            String id = queryDTO.getIds().get(i);
            String dataDate = queryDTO.getDataDates().get(i);
            QuartzTaskEntity quartzTaskEntity = quartzTaskDao.selectById(id);
            if (quartzTaskEntity == null) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
            }
            QuartzTaskStatusEntity taskStatusEntity = new QuartzTaskStatusEntity();
            taskStatusEntity.setStatus(TaskExeStatusEnum.SUCCESS.getCode());
            taskStatusEntity.setMsg("强制通过");
            taskStatusEntity.setDataDate(dataDate);
            taskStatusEntity.setPlanId(quartzTaskEntity.getId());
            updateTaskExeStatus(taskStatusEntity);
            log.info("{} 强制通过, 状态变更为 [{}]", taskTag(quartzTaskEntity, dataDate), TaskExeStatusEnum.SUCCESS.getDesc());
        }
        return ResponseDTO.succ();
    }

    /**
     * 查询未下发/等待超时的任务
     */
    public ResponseDTO<PageResultDTO<QuartzMissedTaskVO>> queryMissedTasks(QuartzMissedTaskQueryDTO queryDTO) {
        try {
            // 1. 加载所有活跃任务
            List<QuartzTaskEntity> activeTasks = quartzTaskDao.queryActiveTasksFiltered(queryDTO);
            if (activeTasks.isEmpty()) {
                PageResultDTO<QuartzMissedTaskVO> emptyPage = new PageResultDTO<>();
                emptyPage.setPageNum((long) queryDTO.getPageNum());
                emptyPage.setPageSize((long) queryDTO.getPageSize());
                emptyPage.setTotal(0L);
                emptyPage.setPages(0L);
                emptyPage.setList(Collections.emptyList());
                return ResponseDTO.succData(emptyPage);
            }

            // 2. 搜索条件的日期范围为数据日期(dataDate)，直接按dataDate批量加载status记录
            List<Long> taskIds = activeTasks.stream().map(QuartzTaskEntity::getId).collect(Collectors.toList());
            SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");

            List<QuartzTaskStatusEntity> statusList = quartzTaskStatusDao.getStatusBatch(taskIds, queryDTO.getStartDate(), queryDTO.getEndDate());

            // 构建 Map: "planId_dataDate" -> QuartzTaskStatusEntity
            Map<String, QuartzTaskStatusEntity> statusMap = new HashMap<>();
            for (QuartzTaskStatusEntity s : statusList) {
                statusMap.put(s.getPlanId() + "_" + s.getDataDate(), s);
            }

            // 3. 遍历任务 x 数据日期，检测未下发
            //    搜索日期 = dataDate范围，反推cron触发日期 = dataDate - offset
            Date startDate = sdf.parse(queryDTO.getStartDate());
            Date endDate = sdf.parse(queryDTO.getEndDate());
            Date now = new Date();

            List<QuartzMissedTaskVO> missedList = new ArrayList<>();

            Calendar cal = Calendar.getInstance();
            cal.setTime(startDate);

            while (!cal.getTime().after(endDate)) {
                Date currentDay = cal.getTime();
                String dataDateStr = sdf.format(currentDay);

                for (QuartzTaskEntity task : activeTasks) {
                    try {
                        CronExpression cron = new CronExpression(task.getTaskCron());

                        // 根据offset反推cron实际触发日期: triggerDate = dataDate - offset
                        Calendar triggerCal = Calendar.getInstance();
                        triggerCal.setTime(currentDay);
                        triggerCal.add(Calendar.DATE, -task.getOffset());
                        Date triggerDay = triggerCal.getTime();

                        // 判断该 cron 在触发日期当天是否应触发
                        Calendar dayStartCal = Calendar.getInstance();
                        dayStartCal.setTime(triggerDay);
                        dayStartCal.add(Calendar.SECOND, -1);

                        Calendar dayEnd = Calendar.getInstance();
                        dayEnd.setTime(triggerDay);
                        dayEnd.add(Calendar.DAY_OF_MONTH, 1);

                        Date nextFire = cron.getNextValidTimeAfter(dayStartCal.getTime());

                        if (nextFire == null || !nextFire.before(dayEnd.getTime())) {
                            // cron在该触发日不触发，跳过
                            continue;
                        }

                        // 如果触发时间还没到（即当前时间 < cron触发时间），跳过
                        if (nextFire.after(now)) {
                            continue;
                        }

                        // 按 taskId + dataDate 查找状态记录
                        String key = task.getId() + "_" + dataDateStr;
                        QuartzTaskStatusEntity statusEntity = statusMap.get(key);

                        if (statusEntity == null) {
                            // 无记录 -> 未下发
                            QuartzMissedTaskVO vo = buildMissedTaskVO(task, dataDateStr, "未下发", null);
                            missedList.add(vo);
                        }
                        // 有记录（任何状态：等待/执行中/成功/失败）-> 已下发，跳过
                    } catch (Exception e) {
                        log.warn("解析任务[{}]的cron表达式[{}]失败: {}", task.getId(), task.getTaskCron(), e.getMessage());
                    }
                }

                cal.add(Calendar.DAY_OF_MONTH, 1);
            }

            // 4. 查询每个异常任务的最近成功记录
            for (QuartzMissedTaskVO vo : missedList) {
                QuartzTaskStatusEntity lastSuccess = quartzTaskStatusDao.getLastSuccess(vo.getTaskId());
                if (lastSuccess != null) {
                    vo.setLastSuccessDate(lastSuccess.getDataDate());
                    if (lastSuccess.getEndTime() != null) {
                        vo.setLastSuccessTime(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(lastSuccess.getEndTime()));
                    }
                }
            }

            // 5. 内存分页
            int total = missedList.size();
            int pageNum = queryDTO.getPageNum();
            int pageSize = queryDTO.getPageSize();
            int fromIndex = (pageNum - 1) * pageSize;
            int toIndex = Math.min(fromIndex + pageSize, total);

            List<QuartzMissedTaskVO> pageList;
            if (fromIndex >= total) {
                pageList = Collections.emptyList();
            } else {
                pageList = missedList.subList(fromIndex, toIndex);
            }

            PageResultDTO<QuartzMissedTaskVO> pageResult = new PageResultDTO<>();
            pageResult.setPageNum((long) pageNum);
            pageResult.setPageSize((long) pageSize);
            pageResult.setTotal((long) total);
            pageResult.setPages((long) ((total + pageSize - 1) / pageSize));
            pageResult.setList(pageList);

            return ResponseDTO.succData(pageResult);
        } catch (ParseException e) {
            log.error("日期解析失败", e);
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "日期格式错误，请使用yyyyMMdd格式");
        }
    }

    private QuartzMissedTaskVO buildMissedTaskVO(QuartzTaskEntity task, String expectedDate, String missedStatus, Long waitingMinutes) {
        QuartzMissedTaskVO vo = new QuartzMissedTaskVO();
        vo.setTaskId(task.getId());
        vo.setTaskName(task.getTaskName());
        vo.setTaskSystem(task.getTaskSystem());
        vo.setTheme(task.getTheme());
        vo.setTaskCron(task.getTaskCron());
        vo.setDependId(task.getDependId());
        vo.setTaskType(task.getTaskType());
        vo.setExpectedDate(expectedDate);
        vo.setMissedStatus(missedStatus);
        vo.setWaitingMinutes(waitingMinutes);
        return vo;
    }
}
