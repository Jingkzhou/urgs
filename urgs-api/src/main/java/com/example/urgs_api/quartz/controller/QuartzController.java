package com.example.urgs_api.quartz.controller;

import com.example.urgs_api.quartz.support.domain.PageResultDTO;
import com.example.urgs_api.quartz.support.domain.ResponseDTO;
import com.example.urgs_api.quartz.service.QuartzTaskService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import com.example.urgs_api.quartz.domain.dto.*;
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
@RestController
@Api(tags = {"Task Scheduler"})
public class QuartzController {

    @Autowired
    private QuartzTaskService quartzTaskService;


    @PostMapping("/quartz/task/query")
    @ApiOperation(value = "查询任务")
    public ResponseDTO<PageResultDTO<QuartzTaskVO>> query(@RequestBody @Valid QuartzQueryDTO queryDTO){
        return quartzTaskService.query(queryDTO);
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
}
