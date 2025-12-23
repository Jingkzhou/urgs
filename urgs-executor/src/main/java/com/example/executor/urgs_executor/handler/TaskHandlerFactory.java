package com.example.executor.urgs_executor.handler;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class TaskHandlerFactory {

    @Autowired
    private Map<String, TaskHandler> handlers;

    public TaskHandler getHandler(String taskType) {
        if (taskType == null)
            return null;

        // Try exact match
        TaskHandler handler = handlers.get(taskType);
        if (handler != null)
            return handler;

        // Try case-insensitive match (Spring bean names might be default camelCase if
        // not specified,
        // or we specified uppercase in @Component)
        for (Map.Entry<String, TaskHandler> entry : handlers.entrySet()) {
            if (entry.getKey().equalsIgnoreCase(taskType)) {
                return entry.getValue();
            }
        }
        return null;
    }
}
