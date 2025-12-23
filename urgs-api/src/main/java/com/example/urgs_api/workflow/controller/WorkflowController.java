package com.example.urgs_api.workflow.controller;

import com.example.urgs_api.workflow.service.WorkflowService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/workflow")
public class WorkflowController {

    @Autowired
    private WorkflowService workflowService;

    @PostMapping("/save")
    public String saveWorkflow(@RequestBody WorkflowDto dto) {
        try {
            workflowService.saveWorkflow(dto.getWorkflowId(), dto.getName(), dto.getOwner(), dto.getDescription(),
                    dto.getContent(), dto.getCron(), dto.getNodes(), dto.getEdges());
            return "Success";
        } catch (IllegalArgumentException e) {
            return "Failed: " + e.getMessage();
        }
    }

    @GetMapping("/list")
    public List<com.example.urgs_api.workflow.entity.Workflow> listWorkflows() {
        return workflowService.listWorkflows();
    }

    @GetMapping("/{id}")
    public com.example.urgs_api.workflow.entity.Workflow getWorkflow(@PathVariable Long id) {
        return workflowService.getWorkflow(id);
    }

    @DeleteMapping("/{id}")
    public String deleteWorkflow(@PathVariable Long id) {
        workflowService.deleteWorkflow(id);
        return "Success";
    }

    public static class WorkflowDto {
        private Long workflowId;
        private String name;
        private String owner;
        private String description;
        private String content;
        private String cron;
        private List<String> nodes;
        private List<Map<String, String>> edges;

        public Long getWorkflowId() {
            return workflowId;
        }

        public void setWorkflowId(Long workflowId) {
            this.workflowId = workflowId;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getOwner() {
            return owner;
        }

        public void setOwner(String owner) {
            this.owner = owner;
        }

        public String getDescription() {
            return description;
        }

        public void setDescription(String description) {
            this.description = description;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }

        public String getCron() {
            return cron;
        }

        public void setCron(String cron) {
            this.cron = cron;
        }

        public List<String> getNodes() {
            return nodes;
        }

        public void setNodes(List<String> nodes) {
            this.nodes = nodes;
        }

        public List<Map<String, String>> getEdges() {
            return edges;
        }

        public void setEdges(List<Map<String, String>> edges) {
            this.edges = edges;
        }
    }
}
