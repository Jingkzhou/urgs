package com.example.urgs_api.task.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.task.entity.TaskInstance;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface TaskInstanceMapper extends BaseMapper<TaskInstance> {
}
