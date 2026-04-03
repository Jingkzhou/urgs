package net.lab1024.smartadmin.module.support.quartz.controller;

import net.lab1024.smartadmin.common.anno.NoValidPrivilege;
import net.lab1024.smartadmin.common.anno.OperateLog;
import net.lab1024.smartadmin.common.domain.PageResultDTO;
import net.lab1024.smartadmin.constant.SwaggerTagConst;
import net.lab1024.smartadmin.common.domain.ResponseDTO;
import net.lab1024.smartadmin.module.support.quartz.service.QuartzTaskService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import net.lab1024.smartadmin.module.support.quartz.domain.dto.*;
import org.springframework.beans.factory.annotation.Autowired;
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
@OperateLog
@RestController
@Api(tags = {SwaggerTagConst.Admin.MANAGER_TASK_SCHEDULER})
public class QuartzController {

    @Autowired
    private QuartzTaskService quartzTaskService;


    @PostMapping("/quartz/task/query")
    @ApiOperation(value = "查询任务")
    @NoValidPrivilege
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> query(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.query(queryDTO);
    }
    @PostMapping("/quartz/task/status/queryYl")
    @ApiOperation(value = "查询依赖任务")
    @NoValidPrivilege
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryYl(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryYl(queryDTO,"yl");

    }
    @PostMapping("/quartz/task/status/queryByl")
    @ApiOperation(value = "查询被依赖任务")
    @NoValidPrivilege
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryByl(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryYl(queryDTO,"byl");
    }
    @PostMapping("/quartz/task/status/queryManyYl")
    @ApiOperation(value = "查询多个依赖任务")
    @NoValidPrivilege
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryManyYl(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryManyYl(queryDTO,"yl");
    }
    @PostMapping("/quartz/task/status/queryManyByl")
    @ApiOperation(value = "查询多个被依赖任务")
    @NoValidPrivilege
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> queryManyByl(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryManyYl(queryDTO,"byl");
    }
    @PostMapping("/quartz/task/status/query")

    @ApiOperation(value = "查询任务执行状态")
    @NoValidPrivilege
    public ResponseDTO<PageResultDTO<QuartzTaskStatusVO>> queryStatus(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.queryTaskStatus(queryDTO);
    }


    @PostMapping("/quartz/task/queryLog")
    @ApiOperation(value = "查询任务运行日志")
    @NoValidPrivilege
    public ResponseDTO<PageResultDTO<QuartzTaskLogVO>> queryLog(@RequestBody @Valid QuartzLogQueryDTO queryDTO){
        return quartzTaskService.queryLog(queryDTO);
    }

    @PostMapping("/quartz/task/saveOrUpdate")
    @ApiOperation(value = "新建更新任务")
    public ResponseDTO<String> saveOrUpdateTask(@RequestBody @Valid QuartzTaskDTO quartzTaskDTO)throws Exception{
        return quartzTaskService.saveOrUpdateTask(quartzTaskDTO);
    }

    @PostMapping("/quartz/task/run")
    @ApiOperation(value = "立即运行某个任务")
    @NoValidPrivilege
    public ResponseDTO<String> runTask(@RequestBody @Valid QuartzQueryDTO queryDTO)throws Exception{
        return quartzTaskService.runTask(queryDTO);
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
    @PostMapping("/quartz/task/stopTask")
    @ApiOperation(value = "停止某个任务")
    public ResponseDTO<String> stopTask(@RequestBody @Valid QuartzQueryDTO queryDTO)throws Exception{
        return quartzTaskService.stopTask(queryDTO);
    }
    @PostMapping("/quartz/task/passTask")
    @ApiOperation(value = "强制通过某个任务")
    public ResponseDTO<String> passTask(@RequestBody @Valid QuartzQueryDTO queryDTO)throws Exception{
        return quartzTaskService.passTask(queryDTO);
    }
    @PostMapping("/quartz/task/taskRun")
    @ApiOperation(value = "批量执行任务")
    public ResponseDTO<String> taskRun(@RequestBody @Valid QuartzQueryDTO queryDTO)throws Exception{
        return quartzTaskService.taskRun(queryDTO);
    }


    @PostMapping("/quartz/task/resetTask")
    @ApiOperation(value = "重置任务")
    public ResponseDTO<String> resetTask()throws Exception{
         quartzTaskService.resetTask();
        return ResponseDTO.succ();
    }

    @PostMapping("/quartz/task/missed/query")
    @ApiOperation(value = "查询未下发任务")
    @NoValidPrivilege
    public ResponseDTO<PageResultDTO<QuartzMissedTaskVO>> queryMissedTasks(@RequestBody @Valid QuartzMissedTaskQueryDTO queryDTO){
        return quartzTaskService.queryMissedTasks(queryDTO);
    }
}
