package com.example.executor.urgs_executor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.executor.urgs_executor.entity.Task;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface TaskMapper extends BaseMapper<Task> {
}
