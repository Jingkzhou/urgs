package com.example.urgs_api.quartz.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.extern.slf4j.Slf4j;
import com.example.urgs_api.issue.model.Issue;
import com.example.urgs_api.issue.service.IssueService;
import com.example.urgs_api.quartz.support.constant.ResponseCodeConst;
import com.example.urgs_api.quartz.support.domain.PageResultDTO;
import com.example.urgs_api.quartz.support.domain.ResponseDTO;
import com.example.urgs_api.quartz.constant.TaskExeStatusEnum;
import com.example.urgs_api.quartz.constant.TaskStatusEnum;
import com.example.urgs_api.quartz.dao.QuartzTaskDao;
import com.example.urgs_api.quartz.dao.QuartzTaskLogDao;
import com.example.urgs_api.quartz.dao.QuartzTaskStatusDao;
import com.example.urgs_api.quartz.domain.dto.*;
import com.example.urgs_api.quartz.domain.entity.QuartzTaskEntity;
import com.example.urgs_api.quartz.domain.entity.QuartzTaskStatusEntity;
import com.example.urgs_api.util.SmartBeanUtil;
import com.example.urgs_api.util.SmartPageUtil;
import org.quartz.CronExpression;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class QuartzTaskService {

    @Autowired
    private QuartzTaskDao quartzTaskDao;

    @Autowired
    private QuartzTaskStatusDao quartzTaskStatusDao;

    @Autowired
    private QuartzTaskLogDao quartzTaskLogDao;

    @Autowired
    private ExecutorClientService executorClientService;

    @Autowired
    private IssueService issueService;

    public ResponseDTO<PageResultDTO<QuartzTaskVO>> query(QuartzQueryDTO queryDTO) {
        Page<QuartzTaskVO> pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        List<QuartzTaskVO> taskList = quartzTaskDao.queryList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    public ResponseDTO<List<QuartzTaskVO>> queryDependencies(Long taskId) {
        if (taskId == null) {
            return ResponseDTO.succData(Collections.emptyList());
        }
        return ResponseDTO.succData(quartzTaskDao.getPreTaskListByTaskId(taskId));
    }

    public ResponseDTO<PageResultDTO<QuartzTaskLogVO>> queryLog(QuartzLogQueryDTO queryDTO) {
        Page<QuartzTaskLogVO> pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        List<QuartzTaskLogVO> taskList = quartzTaskLogDao.queryList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> saveOrUpdateTask(QuartzTaskDTO quartzTaskDTO) throws Exception {
        ResponseDTO<String> baseValid = baseValid(quartzTaskDTO);
        if (!baseValid.isSuccess()) {
            return baseValid;
        }
        if (quartzTaskDTO.getId() == null) {
            return saveTask(quartzTaskDTO);
        }
        return updateTask(quartzTaskDTO);
    }

    private ResponseDTO<String> baseValid(QuartzTaskDTO quartzTaskDTO) {
        if (!CronExpression.isValidExpression(quartzTaskDTO.getTaskCron())) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "请传入正确的cron表达式");
        }
        return ResponseDTO.succ();
    }

    private ResponseDTO<String> saveTask(QuartzTaskDTO quartzTaskDTO) {
        QuartzTaskEntity taskEntity = SmartBeanUtil.copy(quartzTaskDTO, QuartzTaskEntity.class);
        taskEntity.setTaskStatus(quartzTaskDTO.getTaskStatus() == null ? TaskStatusEnum.NORMAL.getStatus() : quartzTaskDTO.getTaskStatus());
        taskEntity.setDependId(null);
        taskEntity.setUpdateTime(new Date());
        taskEntity.setCreateTime(new Date());
        quartzTaskDao.insert(taskEntity);
        syncTaskDependencies(taskEntity.getId(), quartzTaskDTO.getDependId());
        return ResponseDTO.succ();
    }

    private ResponseDTO<String> updateTask(QuartzTaskDTO quartzTaskDTO) {
        QuartzTaskEntity oldEntity = quartzTaskDao.selectById(quartzTaskDTO.getId());
        if (oldEntity == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        QuartzTaskEntity taskEntity = SmartBeanUtil.copy(quartzTaskDTO, QuartzTaskEntity.class);
        taskEntity.setTaskStatus(oldEntity.getTaskStatus());
        taskEntity.setDependId(null);
        taskEntity.setUpdateTime(new Date());
        quartzTaskDao.updateById(taskEntity);
        syncTaskDependencies(taskEntity.getId(), quartzTaskDTO.getDependId());
        return ResponseDTO.succ();
    }

    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> pauseTask(Long taskId) {
        QuartzTaskEntity task = quartzTaskDao.selectById(taskId);
        if (task == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        task.setTaskStatus(TaskStatusEnum.PAUSE.getStatus());
        quartzTaskDao.updateById(task);
        return ResponseDTO.succ();
    }

    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> resumeTask(Long taskId) {
        QuartzTaskEntity task = quartzTaskDao.selectById(taskId);
        if (task == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        task.setTaskStatus(TaskStatusEnum.NORMAL.getStatus());
        quartzTaskDao.updateById(task);
        return ResponseDTO.succ();
    }

    public ResponseDTO<String> deleteTask(Long taskId) {
        QuartzTaskEntity task = quartzTaskDao.selectById(taskId);
        if (task == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        quartzTaskDao.deleteDependenciesByTaskId(taskId);
        quartzTaskDao.deleteById(taskId);
        return ResponseDTO.succ();
    }

    public ResponseDTO<PageResultDTO<QuartzTaskStatusVO>> queryTaskStatus(QuartzQueryDTO queryDTO) {
        Page<QuartzTaskStatusVO> pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        List<QuartzTaskStatusVO> taskList = quartzTaskStatusDao.queryList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> batchExecuteTaskStatus(QuartzBatchExecuteDTO batchExecuteDTO) {
        List<Long> statusIds = batchExecuteDTO.getStatusIds() == null
                ? Collections.emptyList()
                : batchExecuteDTO.getStatusIds().stream().filter(Objects::nonNull).distinct().collect(Collectors.toList());
        if (statusIds.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "请选择需要批量执行的实例");
        }

        List<QuartzTaskStatusEntity> statusList = quartzTaskStatusDao.selectByIds(statusIds);
        if (statusList.size() != statusIds.size()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "部分任务实例不存在或已被删除，请刷新后重试");
        }

        List<Long> invalidIds = statusList.stream()
                .filter(item -> item.getStatus() != 3 && item.getStatus() != 4)
                .map(QuartzTaskStatusEntity::getId)
                .collect(Collectors.toList());
        if (!invalidIds.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "批量执行仅支持失败或已完成实例，存在非法状态实例: " + invalidIds);
        }

        quartzTaskStatusDao.batchResetToWaiting(statusIds, "实例已批量重置为等待执行。");

        for (QuartzTaskStatusEntity statusEntity : statusList) {
            ResponseDTO<String> triggerResult = executorClientService.triggerNow(statusEntity.getPlanId(), statusEntity.getDataDate());
            if (!triggerResult.isSuccess()) {
                log.warn("triggerNow failed after batchExecute, planId={}, dataDate={}, msg={}", statusEntity.getPlanId(), statusEntity.getDataDate(), triggerResult.getMsg());
            }
        }
        return ResponseDTO.succ();
    }

    public ResponseDTO<String> triggerNow(QuartzTriggerNowDTO dto) {
        QuartzTaskEntity task = quartzTaskDao.selectById(dto.getPlanId());
        if (task == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "任务不存在");
        }
        if (TaskStatusEnum.PAUSE.getStatus().equals(task.getTaskStatus())) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "任务已暂停，请先恢复任务后再立即执行");
        }
        return executorClientService.triggerNow(dto.getPlanId(), dto.getDataDate());
    }

    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> transferProblemInstance(QuartzProblemTransferDTO dto) {
        if (dto.getPlanId() == null || dto.getDataDate() == null || dto.getDataDate().trim().isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "planId 和 dataDate 不能为空");
        }

        QuartzTaskStatusEntity status = quartzTaskStatusDao.selectByPlanIdAndDataDate(dto.getPlanId(), dto.getDataDate());
        if (status == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "任务实例不存在");
        }
        if (!isProblematicStatus(status.getStatus())) {
            return ResponseDTO.succData("当前实例不是失败或异常状态，无需转存");
        }

        QuartzTaskEntity task = quartzTaskDao.selectById(dto.getPlanId());
        String title = buildProblemTitle(status, task);
        long existingCount = issueService.lambdaQuery()
                .eq(Issue::getTitle, title)
                .count();
        if (existingCount > 0) {
            return ResponseDTO.succData("生产问题已存在，跳过重复转存");
        }

        String description = buildProblemDescription(status, task);
        Issue issue = new Issue();
        issue.setTitle(title);
        issue.setDescription(description);
        issue.setSystem(task != null && task.getTaskSystem() != null ? task.getTaskSystem() : "监管批量");
        issue.setSolution("");
        issue.setOccurTime(toLocalDateTime(firstNonNull(status.getEndTime(), status.getUpdateTime(), status.getBeginTime(), new Date())));
        issue.setReporter("系统自动登记");
        issue.setHandler("");
        issue.setIssueType("批量任务处理");
        issue.setStatus("新建");
        issue.setWorkHours(BigDecimal.ZERO);
        issue.setCreateTime(LocalDateTime.now());
        issue.setCreateBy("system");
        issue.setUpdateTime(LocalDateTime.now());
        issueService.save(issue);

        return ResponseDTO.succData("已转存生产问题");
    }

    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> batchForceStopTaskStatus(QuartzBatchForceStopDTO batchForceStopDTO) {
        List<Long> statusIds = batchForceStopDTO.getStatusIds() == null
                ? Collections.emptyList()
                : batchForceStopDTO.getStatusIds().stream().filter(Objects::nonNull).distinct().collect(Collectors.toList());
        if (statusIds.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "请选择需要强制停止的实例");
        }

        List<QuartzTaskStatusEntity> statusList = quartzTaskStatusDao.selectByIds(statusIds);
        if (statusList.size() != statusIds.size()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "部分任务实例不存在或已被删除，请刷新后重试");
        }

        List<Long> invalidIds = statusList.stream()
                .filter(item -> item.getStatus() != TaskExeStatusEnum.WAITING.getCode()
                        && item.getStatus() != TaskExeStatusEnum.RUNNING.getCode())
                .map(QuartzTaskStatusEntity::getId)
                .collect(Collectors.toList());
        if (!invalidIds.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "强制停止仅支持等待中或执行中实例，存在非法状态实例: " + invalidIds);
        }

        int cancelledCount = 0;
        int notRunningCount = 0;
        for (QuartzTaskStatusEntity statusEntity : statusList) {
            ResponseDTO<ExecutorClientService.ExecutorStopResultData> stopResult =
                    executorClientService.stopTask(statusEntity.getPlanId(), statusEntity.getDataDate());
            if (!stopResult.isSuccess()) {
                return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM,
                        stopResult.getMsg() == null ? "调用执行器停止任务失败" : stopResult.getMsg());
            }
            ExecutorClientService.ExecutorStopResultData stopData = stopResult.getData();
            if (stopData != null && stopData.isFoundRunningTask() && stopData.isCancelled()) {
                cancelledCount++;
            } else if (stopData != null && !stopData.isFoundRunningTask()) {
                notRunningCount++;
            }
        }

        quartzTaskStatusDao.batchForceStop(statusIds, "实例已被强制停止。");
        statusList.forEach(statusEntity -> transferFailedStatusSilently(statusEntity.getPlanId(), statusEntity.getDataDate()));
        String resultMsg = String.format(
                "批量强制停止完成：共 %d 条，执行器已取消 %d 条运行中任务，%d 条未检测到运行实例。",
                statusIds.size(), cancelledCount, notRunningCount
        );
        return ResponseDTO.succData(resultMsg);
    }

    private void transferFailedStatusSilently(Long planId, String dataDate) {
        try {
            QuartzProblemTransferDTO dto = new QuartzProblemTransferDTO();
            dto.setPlanId(planId);
            dto.setDataDate(dataDate);
            transferProblemInstance(dto);
        } catch (Exception e) {
            log.warn("自动转存生产问题失败, planId={}, dataDate={}, error={}", planId, dataDate, e.getMessage());
        }
    }

    private boolean isProblematicStatus(Integer status) {
        return status != null && (TaskExeStatusEnum.FAILED.getCode().equals(status) || !Arrays.asList(1, 2, 3, 4).contains(status));
    }

    private String buildProblemTitle(QuartzTaskStatusEntity status, QuartzTaskEntity task) {
        String taskName = task != null && task.getTaskName() != null ? task.getTaskName() : "任务 #" + status.getPlanId();
        return "[批量任务异常] " + taskName + " 实例 " + status.getId();
    }

    private String buildProblemDescription(QuartzTaskStatusEntity status, QuartzTaskEntity task) {
        String statusLabel = TaskExeStatusEnum.FAILED.getCode().equals(status.getStatus()) ? "失败" : "异常状态 " + status.getStatus();
        return String.join("\n",
                "任务实例在 t_quartz_task_status 中返回" + statusLabel + "，已自动转入生产问题追踪。",
                "",
                "实例ID：" + valueOrDash(status.getId()),
                "计划ID：" + valueOrDash(status.getPlanId()),
                "任务名称：" + valueOrDash(task == null ? null : task.getTaskName()),
                "涉及系统：" + valueOrDash(task == null ? null : task.getTaskSystem()),
                "主题：" + valueOrDash(task == null ? null : task.getTheme()),
                "数据日期：" + valueOrDash(status.getDataDate()),
                "开始时间：" + valueOrDash(status.getBeginTime()),
                "更新时间：" + valueOrDash(status.getUpdateTime()),
                "结束时间：" + valueOrDash(status.getEndTime()),
                "异常信息：" + valueOrDash(status.getMsg())
        );
    }

    private String valueOrDash(Object value) {
        return value == null ? "-" : String.valueOf(value);
    }

    @SafeVarargs
    private final <T> T firstNonNull(T... values) {
        for (T value : values) {
            if (value != null) {
                return value;
            }
        }
        return null;
    }

    private LocalDateTime toLocalDateTime(Date date) {
        return date.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
    }

    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> batchForcePassTaskStatus(QuartzBatchForcePassDTO batchForcePassDTO) {
        List<Long> statusIds = batchForcePassDTO.getStatusIds() == null
                ? Collections.emptyList()
                : batchForcePassDTO.getStatusIds().stream().filter(Objects::nonNull).distinct().collect(Collectors.toList());
        if (statusIds.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "请选择需要强制通过的实例");
        }

        List<QuartzTaskStatusEntity> statusList = quartzTaskStatusDao.selectByIds(statusIds);
        if (statusList.size() != statusIds.size()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "部分任务实例不存在或已被删除，请刷新后重试");
        }

        List<Long> invalidIds = statusList.stream()
                .filter(item -> item.getStatus() != TaskExeStatusEnum.FAILED.getCode())
                .map(QuartzTaskStatusEntity::getId)
                .collect(Collectors.toList());
        if (!invalidIds.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "强制通过仅支持失败实例，存在非法状态实例: " + invalidIds);
        }

        quartzTaskStatusDao.batchForcePass(statusIds, "实例已被强制通过。");
        return ResponseDTO.succ();
    }

    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryYl(QuartzQueryDTO queryDTO, String type) {
        Page<QuartzTaskVO> pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        QuartzTaskStatusEntity statusEntity = quartzTaskStatusDao.selectById(queryDTO.getStatusId());
        QuartzTaskEntity taskEntity = getByTaskId(statusEntity.getPlanId());

        Set<String> dependIdSet = new HashSet<>();
        if ("yl".equals(type)) {
            findYl(dependIdSet, taskEntity);
        } else if ("byl".equals(type)) {
            findByl(dependIdSet, taskEntity);
        }

        queryDTO.setDependId(String.join(", ", dependIdSet));
        String dependId = "".equals(queryDTO.getDependId())
                ? String.valueOf(taskEntity.getId())
                : taskEntity.getId() + "," + queryDTO.getDependId();
        queryDTO.setDependId(dependId);
        queryDTO.setDependIds(parseDependIds(dependId));
        queryDTO.setDataDate(statusEntity.getDataDate());

        List<QuartzTaskVO> taskList = quartzTaskStatusDao.queryYlList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryManyYl(QuartzQueryDTO queryDTO, String type) {
        Set<String> dependIdSet = new HashSet<>();
        Page<QuartzTaskVO> pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        String ids = String.join(",", queryDTO.getIds());

        for (String idStr : queryDTO.getIds()) {
            QuartzTaskEntity taskEntity = getByTaskId(Long.valueOf(idStr));
            if ("yl".equals(type)) {
                findYl(dependIdSet, taskEntity);
            } else if ("byl".equals(type)) {
                findByl(dependIdSet, taskEntity);
            }
        }

        String dependId = dependIdSet.isEmpty() ? ids : ids + "," + String.join(", ", dependIdSet);
        queryDTO.setDependId(dependId);
        queryDTO.setDependIds(parseDependIds(dependId));
        List<QuartzTaskVO> taskList = quartzTaskStatusDao.queryYlList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    public ResponseDTO<PageResultDTO<QuartzMissedTaskVO>> queryMissedTasks(QuartzMissedTaskQueryDTO queryDTO) {
        try {
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

            List<Long> taskIds = activeTasks.stream().map(QuartzTaskEntity::getId).collect(Collectors.toList());
            SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
            List<QuartzTaskStatusEntity> statusList =
                    quartzTaskStatusDao.getStatusBatch(taskIds, queryDTO.getStartDate(), queryDTO.getEndDate());

            Map<String, QuartzTaskStatusEntity> statusMap = new HashMap<>();
            for (QuartzTaskStatusEntity s : statusList) {
                statusMap.put(s.getPlanId() + "_" + s.getDataDate(), s);
            }

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
                        Calendar triggerCal = Calendar.getInstance();
                        triggerCal.setTime(currentDay);
                        int offset = task.getOffset() == null ? 0 : task.getOffset();
                        triggerCal.add(Calendar.DATE, -offset);
                        Date triggerDay = triggerCal.getTime();

                        Calendar dayStartCal = Calendar.getInstance();
                        dayStartCal.setTime(triggerDay);
                        dayStartCal.add(Calendar.SECOND, -1);

                        Calendar dayEnd = Calendar.getInstance();
                        dayEnd.setTime(triggerDay);
                        dayEnd.add(Calendar.DAY_OF_MONTH, 1);

                        Date nextFire = cron.getNextValidTimeAfter(dayStartCal.getTime());
                        if (nextFire == null || !nextFire.before(dayEnd.getTime()) || nextFire.after(now)) {
                            continue;
                        }

                        String key = task.getId() + "_" + dataDateStr;
                        if (!statusMap.containsKey(key)) {
                            missedList.add(buildMissedTaskVO(task, dataDateStr, "未下发", null));
                        }
                    } catch (Exception e) {
                        log.warn("解析任务[{}]的cron表达式[{}]失败: {}", task.getId(), task.getTaskCron(), e.getMessage());
                    }
                }
                cal.add(Calendar.DAY_OF_MONTH, 1);
            }

            for (QuartzMissedTaskVO vo : missedList) {
                QuartzTaskStatusEntity lastSuccess = quartzTaskStatusDao.getLastSuccess(vo.getTaskId());
                if (lastSuccess != null) {
                    vo.setLastSuccessDate(lastSuccess.getDataDate());
                    if (lastSuccess.getEndTime() != null) {
                        vo.setLastSuccessTime(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(lastSuccess.getEndTime()));
                    }
                }
            }

            int total = missedList.size();
            int pageNum = queryDTO.getPageNum();
            int pageSize = queryDTO.getPageSize();
            int fromIndex = (pageNum - 1) * pageSize;
            int toIndex = Math.min(fromIndex + pageSize, total);
            List<QuartzMissedTaskVO> pageList = fromIndex >= total ? Collections.emptyList() : missedList.subList(fromIndex, toIndex);

            PageResultDTO<QuartzMissedTaskVO> pageResult = new PageResultDTO<>();
            pageResult.setPageNum((long) pageNum);
            pageResult.setPageSize((long) pageSize);
            pageResult.setTotal((long) total);
            pageResult.setPages((long) ((total + pageSize - 1) / pageSize));
            pageResult.setList(pageList);
            return ResponseDTO.succData(pageResult);
        } catch (ParseException e) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "日期格式错误，请使用yyyyMMdd格式");
        }
    }

    private List<Long> parseDependIds(String dependIdStr) {
        List<Long> result = new ArrayList<>();
        if (dependIdStr == null || dependIdStr.trim().isEmpty()) {
            return result;
        }
        String[] parts = dependIdStr.split(",");
        for (String part : parts) {
            String trimmed = part.trim();
            if (!trimmed.isEmpty()) {
                result.add(Long.valueOf(trimmed));
            }
        }
        return result;
    }

    private QuartzTaskEntity getByTaskId(Long taskId) {
        return quartzTaskDao.selectById(taskId);
    }

    public Set<String> findYl(Set<String> set, QuartzTaskEntity task) {
        for (Long preTaskId : quartzTaskDao.getPreTaskIdsByTaskId(task.getId())) {
            set.add(String.valueOf(preTaskId));
        }
        return set;
    }

    public Set<String> findByl(Set<String> set, QuartzTaskEntity task) {
        List<QuartzTaskEntity> taskList = quartzTaskDao.getTaskListByDepId(task.getId());
        for (QuartzTaskEntity item : taskList) {
            set.add(String.valueOf(item.getId()));
        }
        return set;
    }

    private QuartzMissedTaskVO buildMissedTaskVO(QuartzTaskEntity task, String expectedDate, String missedStatus, Long waitingMinutes) {
        QuartzMissedTaskVO vo = new QuartzMissedTaskVO();
        vo.setTaskId(task.getId());
        vo.setTaskName(task.getTaskName());
        vo.setTaskSystem(task.getTaskSystem());
        vo.setTheme(task.getTheme());
        vo.setTaskCron(task.getTaskCron());
        vo.setDependId(task.getDependId());
        vo.setTaskType(task.getTaskType() == null ? 1 : task.getTaskType());
        vo.setExpectedDate(expectedDate);
        vo.setMissedStatus(missedStatus);
        vo.setWaitingMinutes(waitingMinutes);
        return vo;
    }

    private void syncTaskDependencies(Long taskId, String dependIdStr) {
        quartzTaskDao.deleteDependenciesByTaskId(taskId);
        for (Long preTaskId : parseDependIds(dependIdStr)) {
            if (!taskId.equals(preTaskId)) {
                quartzTaskDao.insertTaskDependency(taskId, preTaskId);
            }
        }
    }
}
