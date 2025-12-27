package com.example.urgs_api.task.controller;

import com.example.urgs_api.task.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/task")
public class TaskController {

    @Autowired
    private TaskService taskService;

    @PostMapping("/save")
    public String saveTask(@RequestBody TaskDto dto) {
        return taskService.saveTask(dto.getId(), dto.getName(), dto.getType(), dto.getContent(),
                dto.getCronExpression(), dto.getStatus(), dto.getPriority(), dto.getPreTaskIds(), dto.getSystemId());
    }

    @GetMapping("/list")
    public com.baomidou.mybatisplus.core.metadata.IPage<com.example.urgs_api.task.entity.Task> listTasks(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String workflowIds,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        System.out.println("DEBUG: listTasks called with keyword='" + keyword + "', workflowIds='" + workflowIds
                + "', page=" + page + ", size=" + size);
        return taskService.listTasks(keyword, workflowIds, page, size);
    }

    @DeleteMapping("/{id}")
    public String deleteTask(@PathVariable String id) {
        taskService.deleteTask(id);
        return "Success";
    }

    public static class TaskDto {
        private String id;
        private String name;
        private String type;
        private String content;
        private String cronExpression;
        private Integer status;
        private Integer priority;
        private java.util.List<String> preTaskIds;
        private Long systemId;

        public String getId() {
            return id;
        }

        public void setId(String id) {
            this.id = id;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getType() {
            return type;
        }

        public void setType(String type) {
            this.type = type;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }

        public String getCronExpression() {
            return cronExpression;
        }

        public void setCronExpression(String cronExpression) {
            this.cronExpression = cronExpression;
        }

        public Integer getStatus() {
            return status;
        }

        public void setStatus(Integer status) {
            this.status = status;
        }

        public Integer getPriority() {
            return priority;
        }

        public void setPriority(Integer priority) {
            this.priority = priority;
        }

        public java.util.List<String> getPreTaskIds() {
            return preTaskIds;
        }

        public void setPreTaskIds(java.util.List<String> preTaskIds) {
            this.preTaskIds = preTaskIds;
        }

        public Long getSystemId() {
            return systemId;
        }

        public void setSystemId(Long systemId) {
            this.systemId = systemId;
        }
    }
}
