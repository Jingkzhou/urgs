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
        return "Dependent Task (Logic Gate) Passed.\nAll upstream dependencies met.";
    }
}
