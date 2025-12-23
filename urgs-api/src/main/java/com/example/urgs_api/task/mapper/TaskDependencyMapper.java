package com.example.urgs_api.task.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.task.entity.TaskDependency;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface TaskDependencyMapper extends BaseMapper<TaskDependency> {
}
