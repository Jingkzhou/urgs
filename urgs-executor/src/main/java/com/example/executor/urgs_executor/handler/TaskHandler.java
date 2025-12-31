package com.example.executor.urgs_executor.handler;

import com.example.executor.urgs_executor.entity.ExecutorTaskInstance;

public interface TaskHandler {
    String execute(ExecutorTaskInstance taskInstance) throws Exception;
}
