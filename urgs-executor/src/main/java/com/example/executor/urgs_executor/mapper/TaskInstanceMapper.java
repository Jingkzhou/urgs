package com.example.executor.urgs_executor.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.executor.urgs_executor.entity.TaskInstance;
import org.apache.ibatis.annotations.Mapper;

import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface TaskInstanceMapper extends BaseMapper<TaskInstance> {

    @Update("UPDATE sys_task_instance SET status = 'RUNNING', start_time = NOW() WHERE id = #{id} AND status = 'WAITING'")
    int tryLockTask(@Param("id") Long id);
}
