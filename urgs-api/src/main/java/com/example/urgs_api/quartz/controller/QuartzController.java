package com.example.urgs_api.quartz.controller;

import com.example.urgs_api.quartz.support.domain.PageResultDTO;
import com.example.urgs_api.quartz.support.domain.ResponseDTO;
import com.example.urgs_api.quartz.domain.dto.ExecutorPoolStatsVO;
import com.example.urgs_api.quartz.service.ExecutorClientService;
import com.example.urgs_api.quartz.service.QuartzTaskService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import com.example.urgs_api.quartz.domain.dto.*;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

/**
 * 
 * [  ]
 * 
 * @version 1.0
 * @since JDK1.8
 * @author yandanyang
 * @company 1024lab.net
 * @copyright (c) 2019 1024lab.netInc. All rights reserved.
 * @date  
 */
@RestController
@RequestMapping("/api")
@Api(tags = {"Task Scheduler"})
public class QuartzController {

    private final QuartzTaskService quartzTaskService;
    private final ExecutorClientService executorClientService;

    public QuartzController(QuartzTaskService quartzTaskService, ExecutorClientService executorClientService) {
        this.quartzTaskService = quartzTaskService;
        this.executorClientService = executorClientService;
    }


    @PostMapping("/quartz/task/query")
    @ApiOperation(value = "查询任务")
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> query(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.query(queryDTO);
    }

    @GetMapping("/quartz/task/dependencies/{taskId}")
    @ApiOperation(value = "查询任务当前依赖明细")
    public ResponseDTO<java.util.List<QuartzTaskVO>> queryDependencies(
            @PathVariable("taskId") Long taskId,
            @RequestParam(value = "dependencyType", required = false) String dependencyType) {
        return quartzTaskService.queryDependencies(taskId, dependencyType);
    }
    @PostMapping("/quartz/task/status/queryYl")
    @ApiOperation(value = "查询依赖任务")
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryYl(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryYl(queryDTO,"yl");

    }
    @PostMapping("/quartz/task/status/queryByl")
    @ApiOperation(value = "查询被依赖任务")
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryByl(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryYl(queryDTO,"byl");
    }
    @PostMapping("/quartz/task/status/queryManyYl")
    @ApiOperation(value = "查询多个依赖任务")
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryManyYl(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryManyYl(queryDTO,"yl");
    }
    @PostMapping("/quartz/task/status/queryManyByl")
    @ApiOperation(value = "查询多个被依赖任务")
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryManyByl(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryManyYl(queryDTO,"byl");
    }
    @PostMapping("/quartz/task/status/query")

    @ApiOperation(value = "查询任务执行状态")
    public ResponseDTO<PageResultDTO<QuartzTaskStatusVO>> queryStatus(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryTaskStatus(queryDTO);
    }

    @PostMapping("/quartz/task/status/stats")
    @ApiOperation(value = "统计任务执行状态")
    public ResponseDTO<QuartzTaskStatusStatsVO> queryStatusStats(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryTaskStatusStats(queryDTO);
    }

    @PostMapping("/quartz/task/status/dependencyImpact")
    @ApiOperation(value = "分页查询任务实例依赖影响范围")
    public ResponseDTO<QuartzDependencyImpactPageVO> queryDependencyImpact(@RequestBody @Valid QuartzDependencyImpactQueryDTO queryDTO){
        return quartzTaskService.queryDependencyImpact(queryDTO);
    }

    @PostMapping("/quartz/task/status/blockingRoots")
    @ApiOperation(value = "分页查询任务实例调度阻塞根因")
    public ResponseDTO<QuartzBlockingRootPageVO> queryBlockingRoots(@RequestBody @Valid QuartzBlockingRootQueryDTO queryDTO) {
        return quartzTaskService.queryBlockingRoots(queryDTO);
    }

    @PostMapping("/quartz/task/status/blockingPaths")
    @ApiOperation(value = "分页查询任务实例指定阻塞根因的完整路径")
    public ResponseDTO<QuartzBlockingPathPageVO> queryBlockingPaths(@RequestBody @Valid QuartzBlockingPathQueryDTO queryDTO) {
        return quartzTaskService.queryBlockingPaths(queryDTO);
    }

    @GetMapping("/quartz/executor/pool/stats")
    @ApiOperation(value = "查询执行器线程池实时统计")
    public ResponseDTO<ExecutorPoolStatsVO> getExecutorPoolStats() {
        return executorClientService.getPoolStats();
    }

    @PostMapping("/quartz/task/status/batchExecute")
    @ApiOperation(value = "批量执行任务实例")
    public ResponseDTO<String> batchExecuteStatus(@RequestBody @Valid QuartzBatchExecuteDTO batchExecuteDTO){
        return quartzTaskService.batchExecuteTaskStatus(batchExecuteDTO);
    }

    @PostMapping("/quartz/task/status/batchForceStop")
    @ApiOperation(value = "批量强制停止任务实例")
    public ResponseDTO<String> batchForceStopStatus(@RequestBody @Valid QuartzBatchForceStopDTO batchForceStopDTO){
        return quartzTaskService.batchForceStopTaskStatus(batchForceStopDTO);
    }

    @PostMapping("/quartz/task/status/batchForcePass")
    @ApiOperation(value = "批量强制通过任务实例")
    public ResponseDTO<String> batchForcePassStatus(@RequestBody @Valid QuartzBatchForcePassDTO batchForcePassDTO){
        return quartzTaskService.batchForcePassTaskStatus(batchForcePassDTO);
    }


    @PostMapping("/quartz/task/queryLog")
    @ApiOperation(value = "查询任务运行日志")
    public ResponseDTO<PageResultDTO<QuartzTaskLogVO>> queryLog(@RequestBody @Valid QuartzLogQueryDTO queryDTO){
        return quartzTaskService.queryLog(queryDTO);
    }

    @PostMapping("/quartz/task/saveOrUpdate")
    @ApiOperation(value = "新建更新任务")
    public ResponseDTO<String> saveOrUpdateTask(@RequestBody @Valid QuartzTaskDTO quartzTaskDTO)throws Exception{
        return quartzTaskService.saveOrUpdateTask(quartzTaskDTO);
    }

    @GetMapping("/quartz/task/pause/{taskId}")
    @ApiOperation(value = "暂停某个任务")
    public ResponseDTO<String> pauseTask(@PathVariable("taskId")Long taskId)throws Exception{
        return quartzTaskService.pauseTask(taskId);
    }

    @GetMapping("/quartz/task/resume/{taskId}")
    @ApiOperation(value = "恢复某个任务")
    public ResponseDTO<String> resumeTask(@PathVariable("taskId")Long taskId)throws Exception{
        return quartzTaskService.resumeTask(taskId);
    }

    @GetMapping("/quartz/task/delete/{taskId}")
    @ApiOperation(value = "删除某个任务")
    public ResponseDTO<String> deleteTask(@PathVariable("taskId")Long taskId)throws Exception{
        return quartzTaskService.deleteTask(taskId);
    }
    @PostMapping("/quartz/task/missed/query")
    @ApiOperation(value = "查询未下发任务")
    public ResponseDTO<PageResultDTO<QuartzMissedTaskVO>> queryMissedTasks(@RequestBody @Valid QuartzMissedTaskQueryDTO queryDTO){
        return quartzTaskService.queryMissedTasks(queryDTO);
    }

    @PostMapping("/quartz/task/status/triggerNow")
    @ApiOperation(value = "立即触发任务")
    public ResponseDTO<String> triggerNow(@RequestBody @Valid QuartzTriggerNowDTO triggerNowDTO) {
        return quartzTaskService.triggerNow(triggerNowDTO);
    }

    @PostMapping("/internal/quartz/task/status/transfer-problem")
    @ApiOperation(value = "内部接口：失败任务实例转存生产问题")
    public ResponseDTO<String> transferProblemInstance(@RequestBody QuartzProblemTransferDTO transferDTO) {
        return quartzTaskService.transferProblemInstance(transferDTO);
    }
}
