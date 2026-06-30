package com.example.urgs_api.quartz.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.datasource.repository.DataSourcePoolMapper;
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

    private static final String DATA_DEPENDENCY_TYPE = "DATA";
    private static final String CONTROL_DEPENDENCY_TYPE = "CONTROL";
    private static final int MAX_BLOCKING_GRAPH_NODES = 800;

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

    @Autowired
    private DataSourceConfigMapper dataSourceConfigMapper;

    @Autowired
    private DataSourcePoolMapper dataSourcePoolMapper;

    public ResponseDTO<PageResultDTO<QuartzTaskVO>> query(QuartzQueryDTO queryDTO) {
        Page<QuartzTaskVO> pageParam = SmartPageUtil.convert2QueryPage(queryDTO);
        List<QuartzTaskVO> taskList = quartzTaskDao.queryList(pageParam, queryDTO);
        pageParam.setRecords(taskList);
        return ResponseDTO.succData(SmartPageUtil.convert2PageResult(pageParam));
    }

    public ResponseDTO<List<QuartzTaskVO>> queryDependencies(Long taskId, String dependencyType) {
        if (taskId == null) {
            return ResponseDTO.succData(Collections.emptyList());
        }
        String normalizedType = normalizeDependencyType(dependencyType);
        if (normalizedType != null) {
            return ResponseDTO.succData(quartzTaskDao.getPreTaskListByTaskIdAndType(taskId, normalizedType));
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
        if (quartzTaskDTO.getDatasourcePoolId() == null && quartzTaskDTO.getDatasourceId() == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "请选择执行数据池或执行数据源");
        }
        if (quartzTaskDTO.getDatasourcePoolId() != null
                && dataSourcePoolMapper.selectById(quartzTaskDTO.getDatasourcePoolId()) == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "执行数据池不存在");
        }
        if (quartzTaskDTO.getDatasourceId() != null
                && dataSourceConfigMapper.selectById(quartzTaskDTO.getDatasourceId()) == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "执行数据源不存在");
        }
        return ResponseDTO.succ();
    }

    private ResponseDTO<String> saveTask(QuartzTaskDTO quartzTaskDTO) {
        QuartzTaskEntity taskEntity = SmartBeanUtil.copy(quartzTaskDTO, QuartzTaskEntity.class);
        taskEntity.setTaskStatus(quartzTaskDTO.getTaskStatus() == null ? TaskStatusEnum.NORMAL.getStatus() : quartzTaskDTO.getTaskStatus());
        taskEntity.setDependId(null);
        taskEntity.setDataDependId(null);
        taskEntity.setControlDependId(null);
        taskEntity.setUpdateTime(new Date());
        taskEntity.setCreateTime(new Date());
        quartzTaskDao.insert(taskEntity);
        syncTaskDependencies(taskEntity.getId(), DATA_DEPENDENCY_TYPE,
                firstNotBlank(quartzTaskDTO.getDataDependId(), quartzTaskDTO.getDependId()));
        syncTaskDependencies(taskEntity.getId(), CONTROL_DEPENDENCY_TYPE, quartzTaskDTO.getControlDependId());
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
        taskEntity.setDataDependId(null);
        taskEntity.setControlDependId(null);
        taskEntity.setUpdateTime(new Date());
        quartzTaskDao.updateById(taskEntity);
        syncTaskDependencies(taskEntity.getId(), DATA_DEPENDENCY_TYPE,
                firstNotBlank(quartzTaskDTO.getDataDependId(), quartzTaskDTO.getDependId()));
        syncTaskDependencies(taskEntity.getId(), CONTROL_DEPENDENCY_TYPE, quartzTaskDTO.getControlDependId());
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

    @Transactional(rollbackFor = Throwable.class)
    public ResponseDTO<String> deleteTask(Long taskId) {
        QuartzTaskEntity task = quartzTaskDao.selectById(taskId);
        if (task == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "task不存在");
        }
        List<QuartzTaskEntity> downstreamTasks = quartzTaskDao.getTaskListByDepId(taskId);
        if (downstreamTasks != null && !downstreamTasks.isEmpty()) {
            String downstreamNames = downstreamTasks.stream()
                    .limit(5)
                    .map(item -> item.getTaskName() == null ? String.valueOf(item.getId()) : item.getTaskName())
                    .collect(Collectors.joining("、"));
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM,
                    "当前任务仍被其他任务依赖，请先解除依赖后再删除: " + downstreamNames);
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

    public ResponseDTO<QuartzTaskStatusStatsVO> queryTaskStatusStats(QuartzQueryDTO queryDTO) {
        QuartzTaskStatusStatsVO stats = quartzTaskStatusDao.queryStats(queryDTO);
        if (stats == null) {
            stats = new QuartzTaskStatusStatsVO();
            stats.setTotalInstances(0L);
            stats.setWaitingInstances(0L);
            stats.setRunningInstances(0L);
            stats.setSuccessInstances(0L);
            stats.setFailedInstances(0L);
        }
        return ResponseDTO.succData(stats);
    }

    public ResponseDTO<QuartzDependencyImpactPageVO> queryDependencyImpact(QuartzDependencyImpactQueryDTO queryDTO) {
        Long planId = queryDTO.getPlanId();
        String dataDate = queryDTO.getDataDate();
        if ((planId == null || dataDate == null || dataDate.trim().isEmpty()) && queryDTO.getStatusId() != null) {
            QuartzTaskStatusEntity statusEntity = quartzTaskStatusDao.selectById(queryDTO.getStatusId());
            if (statusEntity != null) {
                planId = statusEntity.getPlanId();
                dataDate = statusEntity.getDataDate();
            }
        }
        if (planId == null || dataDate == null || dataDate.trim().isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "计划ID和数据日期不能为空");
        }

        List<QuartzTaskEntity> allTasks = quartzTaskDao.queryAllList();
        Map<Long, QuartzTaskEntity> taskMap = allTasks.stream()
                .filter(task -> task.getId() != null)
                .collect(Collectors.toMap(QuartzTaskEntity::getId, task -> task, (left, right) -> left, LinkedHashMap::new));
        Map<Long, List<Long>> dataDownstreamMap = buildDataDownstreamMap(allTasks);
        List<DependencyImpactNode> nodes = collectDependencyImpactNodes(planId, dataDownstreamMap);

        List<Long> planIds = nodes.stream()
                .map(DependencyImpactNode::getTaskId)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, QuartzTaskStatusEntity> statusMap = new HashMap<>();
        if (!planIds.isEmpty()) {
            List<QuartzTaskStatusEntity> statuses = quartzTaskStatusDao.getStatusBatch(planIds, dataDate, dataDate);
            for (QuartzTaskStatusEntity status : statuses) {
                statusMap.put(status.getPlanId(), status);
            }
        }

        List<QuartzDependencyImpactItemVO> allRows = nodes.stream()
                .map(node -> buildDependencyImpactItem(node, taskMap.get(node.getTaskId()), statusMap.get(node.getTaskId()), dataDownstreamMap))
                .collect(Collectors.toList());
        Map<Long, QuartzDependencyImpactItemVO> rowMap = allRows.stream()
                .collect(Collectors.toMap(QuartzDependencyImpactItemVO::getTaskId, row -> row, (left, right) -> left, LinkedHashMap::new));
        allRows.forEach(row -> {
            Set<Long> descendantIds = collectDescendantTaskIds(row.getTaskId(), dataDownstreamMap);
            row.setDescendantCount(descendantIds.size());
            row.setHasImpactedDescendant(descendantIds.stream()
                    .map(rowMap::get)
                    .filter(Objects::nonNull)
                    .anyMatch(item -> Boolean.TRUE.equals(item.getImpacted())));
        });

        QuartzDependencyImpactPageVO result = new QuartzDependencyImpactPageVO();
        result.setMaxLevel(allRows.stream().map(QuartzDependencyImpactItemVO::getLevel).filter(Objects::nonNull).max(Integer::compareTo).orElse(0));
        result.setWaitingCount((int) allRows.stream().filter(item -> Integer.valueOf(1).equals(item.getStatus())).count());
        result.setRunningCount((int) allRows.stream().filter(item -> Integer.valueOf(2).equals(item.getStatus())).count());
        result.setSuccessCount((int) allRows.stream().filter(item -> Integer.valueOf(3).equals(item.getStatus())).count());
        result.setFailedCount((int) allRows.stream().filter(item -> Integer.valueOf(4).equals(item.getStatus())).count());
        result.setMissingCount((int) allRows.stream().filter(item -> item.getStatusId() == null).count());
        result.setImpactedCount((int) allRows.stream().filter(item -> Boolean.TRUE.equals(item.getImpacted())).count());

        List<QuartzDependencyImpactItemVO> filteredRows = allRows.stream()
                .filter(item -> matchesDependencyImpactKeyword(item, queryDTO.getKeyword()))
                .filter(item -> matchesDependencyImpactStatus(item, queryDTO.getStatus()))
                .filter(item -> !Boolean.TRUE.equals(queryDTO.getImpactedOnly())
                        || Boolean.TRUE.equals(item.getImpacted())
                        || Boolean.TRUE.equals(item.getHasImpactedDescendant()))
                .collect(Collectors.toList());

        int pageNum = Math.max(1, Optional.ofNullable(queryDTO.getPageNum()).orElse(1));
        int pageSize = Math.min(200, Math.max(1, Optional.ofNullable(queryDTO.getPageSize()).orElse(50)));
        int total = filteredRows.size();
        int fromIndex = Math.min((pageNum - 1) * pageSize, total);
        int toIndex = Math.min(fromIndex + pageSize, total);

        result.setPageNum((long) pageNum);
        result.setPageSize((long) pageSize);
        result.setTotal((long) total);
        result.setPages((long) ((total + pageSize - 1) / pageSize));
        result.setList(filteredRows.subList(fromIndex, toIndex));
        return ResponseDTO.succData(result);
    }

    public ResponseDTO<QuartzBlockingRootPageVO> queryBlockingRoots(QuartzBlockingRootQueryDTO queryDTO) {
        BlockingQueryTarget target = resolveBlockingQueryTarget(
                queryDTO.getStatusId(),
                queryDTO.getPlanId(),
                queryDTO.getDataDate()
        );
        if (target == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "计划ID和数据日期不能为空");
        }

        BlockingAnalysis analysis = buildBlockingAnalysis(target);
        List<QuartzBlockingRootCauseVO> allRoots = analysis.getRootAggregates().values().stream()
                .map(aggregate -> buildBlockingRootCause(aggregate, analysis))
                .sorted(Comparator
                        .comparing((QuartzBlockingRootCauseVO item) -> blockingStatusRank(item.getRoot().getStatus()))
                        .thenComparing(QuartzBlockingRootCauseVO::getLevel)
                        .thenComparing(item -> item.getRoot().getTaskId()))
                .collect(Collectors.toList());

        int failedRootCount = (int) allRoots.stream()
                .filter(item -> Integer.valueOf(TaskExeStatusEnum.FAILED.getCode()).equals(item.getRoot().getStatus()))
                .count();
        List<QuartzBlockingRootCauseVO> filteredRoots = allRoots.stream()
                .filter(item -> matchesBlockingStatus(item.getRoot(), queryDTO.getStatus()))
                .collect(Collectors.toList());
        int pageNum = Math.max(1, Optional.ofNullable(queryDTO.getPageNum()).orElse(1));
        int pageSize = Math.min(200, Math.max(1, Optional.ofNullable(queryDTO.getPageSize()).orElse(50)));
        int total = filteredRoots.size();
        int fromIndex = Math.min((pageNum - 1) * pageSize, total);
        int toIndex = Math.min(fromIndex + pageSize, total);

        QuartzBlockingRootPageVO result = new QuartzBlockingRootPageVO();
        result.setPageNum((long) pageNum);
        result.setPageSize((long) pageSize);
        result.setTotal((long) total);
        result.setPages((long) ((total + pageSize - 1) / pageSize));
        result.setList(filteredRoots.subList(fromIndex, toIndex));
        result.setBlockingNodeCount(analysis.getBlockingNodeIds().size());
        result.setMaxLevel(allRoots.stream().map(QuartzBlockingRootCauseVO::getLevel).max(Integer::compareTo).orElse(0));
        result.setFailedRootCount(failedRootCount);
        result.setTruncated(analysis.isTruncated());
        return ResponseDTO.succData(result);
    }

    public ResponseDTO<QuartzBlockingPathPageVO> queryBlockingPaths(QuartzBlockingPathQueryDTO queryDTO) {
        if (queryDTO.getRootTaskId() == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "阻塞根因任务ID不能为空");
        }
        BlockingQueryTarget target = resolveBlockingQueryTarget(
                queryDTO.getStatusId(),
                queryDTO.getPlanId(),
                queryDTO.getDataDate()
        );
        if (target == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "计划ID和数据日期不能为空");
        }

        BlockingAnalysis analysis = buildBlockingAnalysis(target);
        BlockingRootAggregate rootAggregate = analysis.getRootAggregates().get(queryDTO.getRootTaskId());
        if (rootAggregate == null) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "指定任务不是当前实例的阻塞根因");
        }

        int pageNum = Math.max(1, Optional.ofNullable(queryDTO.getPageNum()).orElse(1));
        int pageSize = Math.min(100, Math.max(1, Optional.ofNullable(queryDTO.getPageSize()).orElse(20)));
        long offset = (long) (pageNum - 1) * pageSize;
        List<List<BlockingPathStep>> paths = new ArrayList<>();
        long[] skipped = {0L};
        for (UpstreamDependencyEdge edge : analysis.getUpstreamMap()
                .getOrDefault(target.getPlanId(), Collections.emptyList())) {
            collectBlockingPaths(
                    edge.getTaskId(),
                    edge.getDependencyTypes(),
                    queryDTO.getRootTaskId(),
                    analysis,
                    new ArrayList<>(),
                    new HashSet<>(Collections.singleton(target.getPlanId())),
                    offset,
                    pageSize,
                    skipped,
                    paths
            );
            if (paths.size() >= pageSize) {
                break;
            }
        }

        QuartzBlockingPathPageVO result = new QuartzBlockingPathPageVO();
        result.setPageNum((long) pageNum);
        result.setPageSize((long) pageSize);
        result.setTotal(rootAggregate.getPathCount());
        result.setPages(rootAggregate.getPathCount() / pageSize
                + (rootAggregate.getPathCount() % pageSize == 0 ? 0 : 1));
        result.setList(paths.stream()
                .map(path -> buildBlockingPathItems(path, analysis))
                .collect(Collectors.toList()));
        return ResponseDTO.succData(result);
    }

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

        List<QuartzTaskStatusEntity> executeStatusList = Boolean.TRUE.equals(batchExecuteDTO.getWithDataDownstream())
                ? collectDataRerunStatusList(statusList)
                : statusList;

        List<Long> invalidIds = executeStatusList.stream()
                .filter(item -> item.getStatus() != 3 && item.getStatus() != 4)
                .map(QuartzTaskStatusEntity::getId)
                .collect(Collectors.toList());
        if (!invalidIds.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "批量执行仅支持失败或已完成实例，存在非法状态实例: " + invalidIds);
        }

        List<Long> executeStatusIds = executeStatusList.stream()
                .map(QuartzTaskStatusEntity::getId)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
        if (executeStatusIds.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM, "未找到可重跑的任务实例");
        }

        Set<String> executeStatusKeys = executeStatusList.stream()
                .map(this::buildTaskDateKey)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        List<QuartzTaskStatusEntity> rootStatusList = filterBatchRerunRootStatuses(executeStatusList, executeStatusKeys);
        if (rootStatusList.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM,
                    "本次重跑集合内未找到可首批触发的根节点，请检查是否存在循环依赖");
        }

        quartzTaskStatusDao.batchResetToWaiting(executeStatusIds,
                Boolean.TRUE.equals(batchExecuteDTO.getWithDataDownstream())
                        ? "实例已按数据依赖链路重置为等待执行。"
                        : "实例已批量重置为等待执行。");

        List<String> triggerFailures = new ArrayList<>();
        for (QuartzTaskStatusEntity statusEntity : rootStatusList) {
            ResponseDTO<String> triggerResult = executorClientService.triggerNow(statusEntity.getPlanId(), statusEntity.getDataDate(), "rerun");
            if (!triggerResult.isSuccess()) {
                String failureMsg = trimTo500("触发执行器失败: " + firstNotBlank(triggerResult.getMsg(), "未知错误"));
                log.warn("triggerNow failed after batchExecute, planId={}, dataDate={}, msg={}", statusEntity.getPlanId(), statusEntity.getDataDate(), triggerResult.getMsg());
                markTriggerFailed(statusEntity, failureMsg);
                triggerFailures.add(statusEntity.getPlanId() + "_" + statusEntity.getDataDate() + "(" + failureMsg + ")");
            }
        }
        if (!triggerFailures.isEmpty()) {
            return ResponseDTO.wrap(ResponseCodeConst.ERROR_PARAM,
                    "部分实例未实际执行，已标记失败: " + String.join("; ", triggerFailures));
        }
        return ResponseDTO.succData(Boolean.TRUE.equals(batchExecuteDTO.getWithDataDownstream())
                ? "已按数据依赖链路重置 " + executeStatusIds.size() + " 条实例，首批触发 " + rootStatusList.size() + " 条，其余实例将等待本轮上游完成后继续执行"
                : "已重置 " + executeStatusIds.size() + " 条实例，首批触发 " + rootStatusList.size() + " 条，其余实例将等待本轮上游完成后继续执行");
    }

    private List<QuartzTaskStatusEntity> filterBatchRerunRootStatuses(List<QuartzTaskStatusEntity> executeStatusList,
                                                                      Set<String> executeStatusKeys) {
        return executeStatusList.stream()
                .filter(status -> !hasUpstreamInBatch(status, executeStatusKeys))
                .collect(Collectors.toList());
    }

    private boolean hasUpstreamInBatch(QuartzTaskStatusEntity status, Set<String> executeStatusKeys) {
        if (status.getDataDate() == null) {
            return false;
        }
        List<Long> upstreamTaskIds = quartzTaskDao.getPreTaskIdsByTaskId(status.getPlanId());
        if (upstreamTaskIds == null || upstreamTaskIds.isEmpty()) {
            return false;
        }
        return upstreamTaskIds.stream()
                .filter(Objects::nonNull)
                .map(upstreamTaskId -> buildTaskDateKey(upstreamTaskId, status.getDataDate()))
                .anyMatch(executeStatusKeys::contains);
    }

    private String buildTaskDateKey(QuartzTaskStatusEntity status) {
        return buildTaskDateKey(status.getPlanId(), status.getDataDate());
    }

    private String buildTaskDateKey(Long planId, String dataDate) {
        return planId + "_" + dataDate;
    }

    private void markTriggerFailed(QuartzTaskStatusEntity statusEntity, String msg) {
        Date now = new Date();
        QuartzTaskStatusEntity failedStatus = new QuartzTaskStatusEntity();
        failedStatus.setPlanId(statusEntity.getPlanId());
        failedStatus.setDataDate(statusEntity.getDataDate());
        failedStatus.setStatus(TaskExeStatusEnum.FAILED.getCode());
        failedStatus.setBeginTime(now);
        failedStatus.setEndTime(now);
        failedStatus.setUpdateTime(now);
        failedStatus.setMsg(msg);
        quartzTaskStatusDao.update(failedStatus);
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
        String resultMsg = String.format(
                "批量强制停止完成：共 %d 条，执行器已取消 %d 条运行中任务，%d 条未检测到运行实例。",
                statusIds.size(), cancelledCount, notRunningCount
        );
        return ResponseDTO.succData(resultMsg);
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

    private BlockingQueryTarget resolveBlockingQueryTarget(Long statusId, Long planId, String dataDate) {
        if ((planId == null || dataDate == null || dataDate.trim().isEmpty()) && statusId != null) {
            QuartzTaskStatusEntity statusEntity = quartzTaskStatusDao.selectById(statusId);
            if (statusEntity != null) {
                planId = statusEntity.getPlanId();
                dataDate = statusEntity.getDataDate();
            }
        }
        if (planId == null || dataDate == null || dataDate.trim().isEmpty()) {
            return null;
        }
        return new BlockingQueryTarget(planId, dataDate);
    }

    private BlockingAnalysis buildBlockingAnalysis(BlockingQueryTarget target) {
        List<QuartzTaskEntity> allTasks = quartzTaskDao.queryAllList();
        Map<Long, QuartzTaskEntity> taskMap = allTasks.stream()
                .filter(task -> task.getId() != null)
                .collect(Collectors.toMap(QuartzTaskEntity::getId, task -> task, (left, right) -> left, LinkedHashMap::new));
        Map<Long, List<UpstreamDependencyEdge>> upstreamMap = buildUpstreamDependencyMap(allTasks);
        Set<Long> reachableTaskIds = collectUpstreamTaskIds(target.getPlanId(), upstreamMap);
        List<Long> statusPlanIds = new ArrayList<>(reachableTaskIds);
        statusPlanIds.add(target.getPlanId());
        Map<Long, QuartzTaskStatusEntity> statusMap = new HashMap<>();
        if (!statusPlanIds.isEmpty()) {
            for (QuartzTaskStatusEntity status : quartzTaskStatusDao.getStatusBatch(
                    statusPlanIds.stream().distinct().collect(Collectors.toList()),
                    target.getDataDate(),
                    target.getDataDate()
            )) {
                statusMap.put(status.getPlanId(), status);
            }
        }

        BlockingAnalysis analysis = new BlockingAnalysis(taskMap, upstreamMap, statusMap);
        analysis.setTruncated(reachableTaskIds.size() >= MAX_BLOCKING_GRAPH_NODES);
        QuartzTaskStatusEntity selectedStatus = statusMap.get(target.getPlanId());
        if (selectedStatus == null || !Integer.valueOf(TaskExeStatusEnum.WAITING.getCode()).equals(selectedStatus.getStatus())) {
            return analysis;
        }

        Map<Long, BlockingRootAggregate> roots = new LinkedHashMap<>();
        for (UpstreamDependencyEdge edge : upstreamMap.getOrDefault(target.getPlanId(), Collections.emptyList())) {
            Map<Long, BlockingRootAggregate> childRoots = resolveBlockingRoots(
                    edge.getTaskId(),
                    analysis,
                    new HashSet<>(Collections.singleton(target.getPlanId()))
            );
            mergeRootAggregates(roots, childRoots, edge.getDependencyTypes(), false);
        }
        analysis.setRootAggregates(roots);
        return analysis;
    }

    private Map<Long, List<UpstreamDependencyEdge>> buildUpstreamDependencyMap(List<QuartzTaskEntity> taskList) {
        Map<Long, List<UpstreamDependencyEdge>> result = new HashMap<>();
        for (QuartzTaskEntity task : taskList) {
            if (task.getId() == null) {
                continue;
            }
            Map<Long, Set<String>> dependencyTypeMap = new LinkedHashMap<>();
            for (Long taskId : parseDependIds(firstNotBlank(task.getDataDependId(), task.getDependId()))) {
                dependencyTypeMap.computeIfAbsent(taskId, key -> new LinkedHashSet<>()).add(DATA_DEPENDENCY_TYPE);
            }
            for (Long taskId : parseDependIds(task.getControlDependId())) {
                dependencyTypeMap.computeIfAbsent(taskId, key -> new LinkedHashSet<>()).add(CONTROL_DEPENDENCY_TYPE);
            }
            List<UpstreamDependencyEdge> edges = dependencyTypeMap.entrySet().stream()
                    .map(entry -> new UpstreamDependencyEdge(entry.getKey(), new ArrayList<>(entry.getValue())))
                    .sorted(Comparator.comparing(UpstreamDependencyEdge::getTaskId))
                    .collect(Collectors.toList());
            result.put(task.getId(), edges);
        }
        return result;
    }

    private Set<Long> collectUpstreamTaskIds(Long rootTaskId, Map<Long, List<UpstreamDependencyEdge>> upstreamMap) {
        Set<Long> result = new LinkedHashSet<>();
        Deque<Long> queue = upstreamMap.getOrDefault(rootTaskId, Collections.emptyList()).stream()
                .map(UpstreamDependencyEdge::getTaskId)
                .collect(Collectors.toCollection(ArrayDeque::new));
        while (!queue.isEmpty() && result.size() < MAX_BLOCKING_GRAPH_NODES) {
            Long taskId = queue.poll();
            if (taskId == null || taskId.equals(rootTaskId) || !result.add(taskId)) {
                continue;
            }
            upstreamMap.getOrDefault(taskId, Collections.emptyList()).stream()
                    .map(UpstreamDependencyEdge::getTaskId)
                    .filter(id -> !result.contains(id))
                    .forEach(queue::add);
        }
        return result;
    }

    private Map<Long, BlockingRootAggregate> resolveBlockingRoots(
            Long taskId,
            BlockingAnalysis analysis,
            Set<Long> ancestors
    ) {
        Map<Long, BlockingRootAggregate> cached = analysis.getRootMemo().get(taskId);
        if (cached != null) {
            return cached;
        }
        if (taskId == null || ancestors.contains(taskId)) {
            return Collections.emptyMap();
        }
        QuartzTaskStatusEntity status = analysis.getStatusMap().get(taskId);
        if (status != null && Integer.valueOf(TaskExeStatusEnum.SUCCESS.getCode()).equals(status.getStatus())) {
            return Collections.emptyMap();
        }

        analysis.getBlockingNodeIds().add(taskId);
        List<UpstreamDependencyEdge> upstreamEdges = analysis.getUpstreamMap()
                .getOrDefault(taskId, Collections.emptyList());
        boolean waiting = status != null && Integer.valueOf(TaskExeStatusEnum.WAITING.getCode()).equals(status.getStatus());
        if (!waiting || upstreamEdges.isEmpty()) {
            Map<Long, BlockingRootAggregate> terminal = singletonBlockingRoot(taskId);
            analysis.getRootMemo().put(taskId, terminal);
            return terminal;
        }

        Set<Long> nextAncestors = new HashSet<>(ancestors);
        nextAncestors.add(taskId);
        Map<Long, BlockingRootAggregate> roots = new LinkedHashMap<>();
        for (UpstreamDependencyEdge edge : upstreamEdges) {
            Map<Long, BlockingRootAggregate> childRoots = resolveBlockingRoots(
                    edge.getTaskId(),
                    analysis,
                    nextAncestors
            );
            mergeRootAggregates(roots, childRoots, edge.getDependencyTypes(), true, taskId);
        }
        if (roots.isEmpty()) {
            roots = singletonBlockingRoot(taskId);
        }
        analysis.getRootMemo().put(taskId, roots);
        return roots;
    }

    private Map<Long, BlockingRootAggregate> singletonBlockingRoot(Long taskId) {
        BlockingRootAggregate aggregate = new BlockingRootAggregate();
        aggregate.setRootTaskId(taskId);
        aggregate.setPathCount(1L);
        aggregate.setRepresentativePath(Collections.singletonList(
                new BlockingPathStep(taskId, Collections.emptyList())
        ));
        Map<Long, BlockingRootAggregate> result = new LinkedHashMap<>();
        result.put(taskId, aggregate);
        return result;
    }

    private void mergeRootAggregates(
            Map<Long, BlockingRootAggregate> target,
            Map<Long, BlockingRootAggregate> source,
            List<String> dependencyTypes,
            boolean prependCurrent
    ) {
        mergeRootAggregates(target, source, dependencyTypes, prependCurrent, null);
    }

    private void mergeRootAggregates(
            Map<Long, BlockingRootAggregate> target,
            Map<Long, BlockingRootAggregate> source,
            List<String> dependencyTypes,
            boolean prependCurrent,
            Long currentTaskId
    ) {
        source.forEach((rootTaskId, incoming) -> {
            List<BlockingPathStep> representativePath = incoming.getRepresentativePath().stream()
                    .map(step -> new BlockingPathStep(step.getTaskId(), step.getDependencyTypes()))
                    .collect(Collectors.toList());
            if (!representativePath.isEmpty()) {
                BlockingPathStep first = representativePath.get(0);
                representativePath.set(0, new BlockingPathStep(first.getTaskId(), dependencyTypes));
            }
            if (prependCurrent && currentTaskId != null) {
                representativePath.add(0, new BlockingPathStep(currentTaskId, Collections.emptyList()));
            }

            BlockingRootAggregate existing = target.get(rootTaskId);
            if (existing == null) {
                existing = new BlockingRootAggregate();
                existing.setRootTaskId(rootTaskId);
                existing.setPathCount(0L);
                existing.setRepresentativePath(representativePath);
                target.put(rootTaskId, existing);
            } else if (representativePath.size() < existing.getRepresentativePath().size()) {
                existing.setRepresentativePath(representativePath);
            }
            existing.setPathCount(saturatedAdd(existing.getPathCount(), incoming.getPathCount()));
        });
    }

    private long saturatedAdd(long left, long right) {
        if (Long.MAX_VALUE - left < right) {
            return Long.MAX_VALUE;
        }
        return left + right;
    }

    private QuartzBlockingRootCauseVO buildBlockingRootCause(
            BlockingRootAggregate aggregate,
            BlockingAnalysis analysis
    ) {
        QuartzBlockingRootCauseVO result = new QuartzBlockingRootCauseVO();
        List<QuartzDependencyImpactItemVO> path = buildBlockingPathItems(
                aggregate.getRepresentativePath(),
                analysis
        );
        result.setRoot(path.get(path.size() - 1));
        result.setPathCount(aggregate.getPathCount());
        result.setLevel(path.size());
        result.setRepresentativePath(path);
        return result;
    }

    private List<QuartzDependencyImpactItemVO> buildBlockingPathItems(
            List<BlockingPathStep> path,
            BlockingAnalysis analysis
    ) {
        List<QuartzDependencyImpactItemVO> result = new ArrayList<>();
        for (int index = 0; index < path.size(); index++) {
            BlockingPathStep step = path.get(index);
            DependencyImpactNode node = new DependencyImpactNode(step.getTaskId(), index + 1);
            QuartzDependencyImpactItemVO item = buildDependencyImpactItem(
                    node,
                    analysis.getTaskMap().get(step.getTaskId()),
                    analysis.getStatusMap().get(step.getTaskId()),
                    Collections.emptyMap()
            );
            item.setDependencyTypes(step.getDependencyTypes());
            result.add(item);
        }
        return result;
    }

    private boolean matchesBlockingStatus(QuartzDependencyImpactItemVO item, String status) {
        if (status == null || status.trim().isEmpty() || "all".equalsIgnoreCase(status)) {
            return true;
        }
        if ("missing".equalsIgnoreCase(status)) {
            return item.getStatusId() == null;
        }
        return status.equals(String.valueOf(item.getStatus()));
    }

    private int blockingStatusRank(Integer status) {
        if (Integer.valueOf(TaskExeStatusEnum.FAILED.getCode()).equals(status)) {
            return 0;
        }
        if (Integer.valueOf(TaskExeStatusEnum.RUNNING.getCode()).equals(status)) {
            return 1;
        }
        if (Integer.valueOf(TaskExeStatusEnum.WAITING.getCode()).equals(status)) {
            return 2;
        }
        return 3;
    }

    private void collectBlockingPaths(
            Long taskId,
            List<String> dependencyTypes,
            Long rootTaskId,
            BlockingAnalysis analysis,
            List<BlockingPathStep> path,
            Set<Long> ancestors,
            long offset,
            int limit,
            long[] skipped,
            List<List<BlockingPathStep>> result
    ) {
        if (result.size() >= limit || taskId == null || ancestors.contains(taskId)) {
            return;
        }
        QuartzTaskStatusEntity status = analysis.getStatusMap().get(taskId);
        if (status != null && Integer.valueOf(TaskExeStatusEnum.SUCCESS.getCode()).equals(status.getStatus())) {
            return;
        }
        List<BlockingPathStep> nextPath = new ArrayList<>(path);
        nextPath.add(new BlockingPathStep(taskId, dependencyTypes));
        if (taskId.equals(rootTaskId)) {
            if (skipped[0] < offset) {
                skipped[0]++;
            } else {
                result.add(nextPath);
            }
            return;
        }
        boolean waiting = status != null && Integer.valueOf(TaskExeStatusEnum.WAITING.getCode()).equals(status.getStatus());
        if (!waiting) {
            return;
        }
        Set<Long> nextAncestors = new HashSet<>(ancestors);
        nextAncestors.add(taskId);
        for (UpstreamDependencyEdge edge : analysis.getUpstreamMap().getOrDefault(taskId, Collections.emptyList())) {
            collectBlockingPaths(
                    edge.getTaskId(),
                    edge.getDependencyTypes(),
                    rootTaskId,
                    analysis,
                    nextPath,
                    nextAncestors,
                    offset,
                    limit,
                    skipped,
                    result
            );
            if (result.size() >= limit) {
                return;
            }
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

    private List<QuartzTaskStatusEntity> collectDataRerunStatusList(List<QuartzTaskStatusEntity> rootStatusList) {
        Map<String, QuartzTaskStatusEntity> statusMap = new LinkedHashMap<>();
        for (QuartzTaskStatusEntity rootStatus : rootStatusList) {
            collectDataRerunStatus(rootStatus.getPlanId(), rootStatus.getDataDate(), statusMap, new HashSet<>());
        }
        return new ArrayList<>(statusMap.values());
    }

    private Map<Long, List<Long>> buildDataDownstreamMap(List<QuartzTaskEntity> taskList) {
        Map<Long, List<Long>> downstreamMap = new HashMap<>();
        for (QuartzTaskEntity task : taskList) {
            if (task.getId() == null) {
                continue;
            }
            for (Long upstreamTaskId : parseDependIds(firstNotBlank(task.getDataDependId(), task.getDependId()))) {
                downstreamMap.computeIfAbsent(upstreamTaskId, key -> new ArrayList<>()).add(task.getId());
            }
        }
        downstreamMap.values().forEach(ids -> ids.sort(Long::compareTo));
        return downstreamMap;
    }

    private List<DependencyImpactNode> collectDependencyImpactNodes(Long rootTaskId, Map<Long, List<Long>> downstreamMap) {
        Map<Long, DependencyImpactNode> nodeMap = new LinkedHashMap<>();
        Deque<DependencyImpactNode> queue = new ArrayDeque<>();
        for (Long childTaskId : downstreamMap.getOrDefault(rootTaskId, Collections.emptyList())) {
            queue.add(new DependencyImpactNode(childTaskId, 1));
        }

        Set<Long> visited = new HashSet<>();
        while (!queue.isEmpty()) {
            DependencyImpactNode current = queue.poll();
            if (current.getTaskId() == null || current.getTaskId().equals(rootTaskId)) {
                continue;
            }

            DependencyImpactNode existing = nodeMap.get(current.getTaskId());
            if (existing == null || current.getLevel() < existing.getLevel()) {
                nodeMap.put(current.getTaskId(), current);
            }
            if (!visited.add(current.getTaskId())) {
                continue;
            }

            for (Long childTaskId : downstreamMap.getOrDefault(current.getTaskId(), Collections.emptyList())) {
                if (!visited.contains(childTaskId)) {
                    queue.add(new DependencyImpactNode(childTaskId, current.getLevel() + 1));
                }
            }
        }
        return new ArrayList<>(nodeMap.values()).stream()
                .sorted(Comparator.comparing(DependencyImpactNode::getLevel).thenComparing(DependencyImpactNode::getTaskId))
                .collect(Collectors.toList());
    }

    private QuartzDependencyImpactItemVO buildDependencyImpactItem(DependencyImpactNode node,
                                                                  QuartzTaskEntity task,
                                                                  QuartzTaskStatusEntity status,
                                                                  Map<Long, List<Long>> downstreamMap) {
        QuartzDependencyImpactItemVO item = new QuartzDependencyImpactItemVO();
        item.setTaskId(node.getTaskId());
        item.setTaskName(task == null || task.getTaskName() == null ? "任务 #" + node.getTaskId() : task.getTaskName());
        item.setTaskSystem(task == null || task.getTaskSystem() == null ? "-" : task.getTaskSystem());
        item.setTheme(task == null || task.getTheme() == null ? "-" : task.getTheme());
        item.setMissingTask(task == null);
        item.setLevel(node.getLevel());
        item.setDependencyTypes(Collections.singletonList(DATA_DEPENDENCY_TYPE));
        item.setDirectChildCount(downstreamMap.getOrDefault(node.getTaskId(), Collections.emptyList()).size());
        item.setDescendantCount(0);
        item.setHasImpactedDescendant(false);

        if (status != null) {
            item.setStatusId(status.getId());
            item.setDataDate(status.getDataDate());
            item.setStatus(status.getStatus());
            item.setBeginTime(status.getBeginTime());
            item.setUpdateTime(status.getUpdateTime());
            item.setEndTime(status.getEndTime());
            item.setCreateTime(status.getCreateTime());
            item.setMsg(status.getMsg());
        }
        item.setImpacted(status == null || !Integer.valueOf(TaskExeStatusEnum.SUCCESS.getCode()).equals(status.getStatus()));
        return item;
    }

    private Set<Long> collectDescendantTaskIds(Long taskId, Map<Long, List<Long>> downstreamMap) {
        Set<Long> descendantIds = new LinkedHashSet<>();
        Deque<Long> queue = new ArrayDeque<>(downstreamMap.getOrDefault(taskId, Collections.emptyList()));
        while (!queue.isEmpty()) {
            Long currentTaskId = queue.poll();
            if (currentTaskId == null || !descendantIds.add(currentTaskId)) {
                continue;
            }
            queue.addAll(downstreamMap.getOrDefault(currentTaskId, Collections.emptyList()));
        }
        return descendantIds;
    }

    private boolean matchesDependencyImpactKeyword(QuartzDependencyImpactItemVO item, String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return true;
        }
        String normalizedKeyword = keyword.trim().toLowerCase(Locale.ROOT);
        return String.valueOf(item.getTaskId()).contains(normalizedKeyword)
                || containsIgnoreCase(item.getTaskName(), normalizedKeyword)
                || containsIgnoreCase(item.getTaskSystem(), normalizedKeyword)
                || containsIgnoreCase(item.getTheme(), normalizedKeyword)
                || containsIgnoreCase(item.getMsg(), normalizedKeyword);
    }

    private boolean containsIgnoreCase(String value, String normalizedKeyword) {
        return value != null && value.toLowerCase(Locale.ROOT).contains(normalizedKeyword);
    }

    private boolean matchesDependencyImpactStatus(QuartzDependencyImpactItemVO item, String status) {
        if (status == null || status.trim().isEmpty() || "all".equalsIgnoreCase(status.trim())) {
            return true;
        }
        String normalizedStatus = status.trim();
        if ("missing".equalsIgnoreCase(normalizedStatus)) {
            return item.getStatusId() == null;
        }
        return item.getStatus() != null && normalizedStatus.equals(String.valueOf(item.getStatus()));
    }

    private static class BlockingQueryTarget {
        private final Long planId;
        private final String dataDate;

        private BlockingQueryTarget(Long planId, String dataDate) {
            this.planId = planId;
            this.dataDate = dataDate;
        }

        private Long getPlanId() {
            return planId;
        }

        private String getDataDate() {
            return dataDate;
        }
    }

    private static class UpstreamDependencyEdge {
        private final Long taskId;
        private final List<String> dependencyTypes;

        private UpstreamDependencyEdge(Long taskId, List<String> dependencyTypes) {
            this.taskId = taskId;
            this.dependencyTypes = dependencyTypes;
        }

        private Long getTaskId() {
            return taskId;
        }

        private List<String> getDependencyTypes() {
            return dependencyTypes;
        }
    }

    private static class BlockingPathStep {
        private final Long taskId;
        private final List<String> dependencyTypes;

        private BlockingPathStep(Long taskId, List<String> dependencyTypes) {
            this.taskId = taskId;
            this.dependencyTypes = dependencyTypes == null
                    ? Collections.emptyList()
                    : new ArrayList<>(dependencyTypes);
        }

        private Long getTaskId() {
            return taskId;
        }

        private List<String> getDependencyTypes() {
            return dependencyTypes;
        }
    }

    private static class BlockingRootAggregate {
        private Long rootTaskId;
        private Long pathCount;
        private List<BlockingPathStep> representativePath;

        private Long getRootTaskId() {
            return rootTaskId;
        }

        private void setRootTaskId(Long rootTaskId) {
            this.rootTaskId = rootTaskId;
        }

        private Long getPathCount() {
            return pathCount;
        }

        private void setPathCount(Long pathCount) {
            this.pathCount = pathCount;
        }

        private List<BlockingPathStep> getRepresentativePath() {
            return representativePath;
        }

        private void setRepresentativePath(List<BlockingPathStep> representativePath) {
            this.representativePath = representativePath;
        }
    }

    private static class BlockingAnalysis {
        private final Map<Long, QuartzTaskEntity> taskMap;
        private final Map<Long, List<UpstreamDependencyEdge>> upstreamMap;
        private final Map<Long, QuartzTaskStatusEntity> statusMap;
        private final Map<Long, Map<Long, BlockingRootAggregate>> rootMemo = new HashMap<>();
        private final Set<Long> blockingNodeIds = new LinkedHashSet<>();
        private Map<Long, BlockingRootAggregate> rootAggregates = new LinkedHashMap<>();
        private boolean truncated;

        private BlockingAnalysis(
                Map<Long, QuartzTaskEntity> taskMap,
                Map<Long, List<UpstreamDependencyEdge>> upstreamMap,
                Map<Long, QuartzTaskStatusEntity> statusMap
        ) {
            this.taskMap = taskMap;
            this.upstreamMap = upstreamMap;
            this.statusMap = statusMap;
        }

        private Map<Long, QuartzTaskEntity> getTaskMap() {
            return taskMap;
        }

        private Map<Long, List<UpstreamDependencyEdge>> getUpstreamMap() {
            return upstreamMap;
        }

        private Map<Long, QuartzTaskStatusEntity> getStatusMap() {
            return statusMap;
        }

        private Map<Long, Map<Long, BlockingRootAggregate>> getRootMemo() {
            return rootMemo;
        }

        private Set<Long> getBlockingNodeIds() {
            return blockingNodeIds;
        }

        private Map<Long, BlockingRootAggregate> getRootAggregates() {
            return rootAggregates;
        }

        private void setRootAggregates(Map<Long, BlockingRootAggregate> rootAggregates) {
            this.rootAggregates = rootAggregates;
        }

        private boolean isTruncated() {
            return truncated;
        }

        private void setTruncated(boolean truncated) {
            this.truncated = truncated;
        }
    }

    private static class DependencyImpactNode {
        private final Long taskId;
        private final Integer level;

        private DependencyImpactNode(Long taskId, Integer level) {
            this.taskId = taskId;
            this.level = level;
        }

        private Long getTaskId() {
            return taskId;
        }

        private Integer getLevel() {
            return level;
        }
    }

    private void collectDataRerunStatus(Long taskId, String dataDate, Map<String, QuartzTaskStatusEntity> statusMap, Set<Long> visitedTaskIds) {
        if (taskId == null || dataDate == null || !visitedTaskIds.add(taskId)) {
            return;
        }

        QuartzTaskStatusEntity currentStatus = quartzTaskStatusDao.selectOne(new QueryWrapper<QuartzTaskStatusEntity>()
                .eq("plan_id", taskId)
                .eq("data_date", dataDate)
                .last("LIMIT 1"));
        if (currentStatus != null) {
            statusMap.put(taskId + "_" + dataDate, currentStatus);
        }

        for (Long downstreamTaskId : quartzTaskDao.getDownstreamTaskIdsByPreTaskIdAndType(taskId, DATA_DEPENDENCY_TYPE)) {
            collectDataRerunStatus(downstreamTaskId, dataDate, statusMap, visitedTaskIds);
        }
    }

    private String normalizeDependencyType(String dependencyType) {
        if (dependencyType == null || dependencyType.trim().isEmpty()) {
            return null;
        }
        String normalized = dependencyType.trim().toUpperCase(Locale.ROOT);
        if (DATA_DEPENDENCY_TYPE.equals(normalized) || CONTROL_DEPENDENCY_TYPE.equals(normalized)) {
            return normalized;
        }
        return null;
    }

    private String firstNotBlank(String primary, String fallback) {
        if (primary != null && !primary.trim().isEmpty()) {
            return primary;
        }
        return fallback;
    }

    private String trimTo500(String value) {
        if (value == null) {
            return null;
        }
        return value.length() > 500 ? value.substring(0, 500) : value;
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

    private void syncTaskDependencies(Long taskId, String dependencyType, String dependIdStr) {
        quartzTaskDao.deleteDependenciesByTaskIdAndType(taskId, dependencyType);
        for (Long preTaskId : parseDependIds(dependIdStr)) {
            if (!taskId.equals(preTaskId)) {
                quartzTaskDao.insertTaskDependencyWithType(taskId, preTaskId, dependencyType);
            }
        }
    }
}
