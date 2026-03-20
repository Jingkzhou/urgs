package com.example.executor.urgs_executor.handler.impl;

import com.example.executor.urgs_executor.entity.ExecutorTaskInstance;
import com.example.executor.urgs_executor.handler.TaskHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DependentTaskHandler implements TaskHandler {

    @Override
    public String execute(ExecutorTaskInstance instance) throws Exception {
        log.info("Starting Dependent task: {}. This is a logic gate, marking as success immediately.",
                instance.getId());
        // Logic gate: if it reached here, it means all dependencies are met (handled by
        // Executor logic).
        // So we just finish successfully.
        String ts = java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        return "[" + ts + "] Dependent Task (Logic Gate) Passed.\n[" + ts + "] All upstream dependencies met.";
    }
}
