package com.example.executor.urgs_executor.handler;

import com.example.executor.urgs_executor.entity.TaskInstance;

public interface TaskHandler {
    String execute(TaskInstance instance) throws Exception;
}
