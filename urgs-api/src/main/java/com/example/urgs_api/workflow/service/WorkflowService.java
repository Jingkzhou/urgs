package com.example.urgs_api.workflow.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.workflow.entity.JobDependency;
import com.example.urgs_api.workflow.repository.JobDependencyMapper;
import com.example.urgs_api.task.mapper.TaskMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class WorkflowService {

    @Autowired
    private JobDependencyMapper jobDependencyMapper;

    @Autowired
    private com.example.urgs_api.workflow.repository.WorkflowMapper workflowMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private com.example.urgs_api.task.service.TaskService taskService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Transactional(rollbackFor = Exception.class)
    public void saveWorkflow(Long workflowId, String name, String owner, String description, String content,
            String cron,
            List<String> nodes, List<Map<String, String>> edges, Long systemId) {
        // 1. Cycle Detection
        if (hasCycle(nodes, edges)) {
            throw new IllegalArgumentException("Cycle detected in workflow DAG");
        }

        // 2. Extract Tasks and Strip Content
        try {
            JsonNode rootNode = objectMapper.readTree(content);
            JsonNode nodesNode = rootNode.get("nodes");

            // Build Pre-Task Map for dependencies
            Map<String, List<String>> preTaskMap = new HashMap<>();
            if (edges != null) {
                for (Map<String, String> edge : edges) {
                    String target = edge.get("target");
                    String source = edge.get("source");
                    preTaskMap.computeIfAbsent(target, k -> new ArrayList<>()).add(source);
                }
            }

            if (nodesNode != null && nodesNode.isArray()) {
                for (JsonNode node : nodesNode) {
                    if (node.has("id") && node.has("data")) {
                        String taskId = node.get("id").asText();
                        JsonNode data = node.get("data");

                        // Extract basic info
                        String label = data.has("label") ? data.get("label").asText() : "New Task";
                        String type = data.has("taskType") ? data.get("taskType").asText()
                                : (data.has("type") ? data.get("type").asText() : "SHELL");

                        // Use the whole data object as content for the Task entity
                        // This preserves all config like script, connectionId, etc.
                        String taskContent = data.toString();

                        // Get dependencies
                        List<String> preTasks = preTaskMap.getOrDefault(taskId, new ArrayList<>());

                        // Save Task (sys_task)
                        // Note: We don't pass cron here as it's managed by workflow or not set for
                        // dependent tasks
                        // Extract cronExpression
                        String cronExpression = data.has("cronExpression") ? data.get("cronExpression").asText() : null;
                        System.out.println(
                                "DEBUG: Saving task " + taskId + ", label=" + label + ", cron=" + cronExpression);
                        System.out.println("DEBUG: Task Data: " + data.toString());

                        // Save Task (sys_task)
                        taskService.saveTask(taskId, label, type, taskContent, cronExpression, 1, 0, preTasks,
                                systemId);

                        // Strip heavy config from Workflow JSON
                        // We only keep UI-related fields in sys_workflow
                        if (data instanceof com.fasterxml.jackson.databind.node.ObjectNode) {
                            com.fasterxml.jackson.databind.node.ObjectNode newData = objectMapper.createObjectNode();
                            // Keep UI fields
                            if (data.has("label"))
                                newData.set("label", data.get("label"));
                            if (data.has("type"))
                                newData.set("type", data.get("type"));
                            // Replace data in the node
                            ((com.fasterxml.jackson.databind.node.ObjectNode) node).set("data", newData);
                        }
                    }
                }
                // Update content to be the stripped version
                content = rootNode.toString();
            }
        } catch (Exception e) {
            throw new IllegalArgumentException("Failed to parse or process workflow content", e);
        }

        // 2. Save/Update Workflow Metadata
        com.example.urgs_api.workflow.entity.Workflow workflow = new com.example.urgs_api.workflow.entity.Workflow();
        if (workflowId != null) {
            workflow = workflowMapper.selectById(workflowId);
            if (workflow == null)
                workflow = new com.example.urgs_api.workflow.entity.Workflow();
        }
        workflow.setName(name);
        workflow.setOwner(owner);
        workflow.setDescription(description);
        workflow.setSystemId(systemId);
        workflow.setContent(content);
        if (workflow.getId() == null) {
            workflow.setCreateTime(java.time.LocalDateTime.now());
            workflowMapper.insert(workflow);
            workflowId = workflow.getId(); // Get generated ID
        } else {
            workflow.setUpdateTime(java.time.LocalDateTime.now());
            workflowMapper.updateById(workflow);
        }

        // 3. Clear existing dependencies for this workflow
        jobDependencyMapper.delete(new QueryWrapper<JobDependency>().eq("workflow_id", workflowId));

        // 4. Build Graph & Calculate In-Degree
        Map<String, Integer> inDegree = new HashMap<>();
        for (String node : nodes) {
            inDegree.put(node, 0);
        }
        if (edges != null) {
            for (Map<String, String> edge : edges) {
                String source = edge.get("source");
                String target = edge.get("target");

                // Save dependency
                JobDependency dep = new JobDependency();
                dep.setWorkflowId(workflowId);
                dep.setParentJobName(source);
                dep.setChildJobName(target);
                jobDependencyMapper.insert(dep);

                inDegree.put(target, inDegree.getOrDefault(target, 0) + 1);
            }
        }
    }

    public List<com.example.urgs_api.workflow.entity.Workflow> listWorkflows() {
        return workflowMapper.selectList(null);
    }

    public com.example.urgs_api.workflow.entity.Workflow getWorkflow(Long id) {
        com.example.urgs_api.workflow.entity.Workflow workflow = workflowMapper.selectById(id);
        if (workflow != null && workflow.getContent() != null) {
            try {
                // Hydrate content from sys_task
                JsonNode rootNode = objectMapper.readTree(workflow.getContent());
                JsonNode nodesNode = rootNode.get("nodes");

                if (nodesNode != null && nodesNode.isArray()) {
                    List<String> taskIds = new ArrayList<>();
                    for (JsonNode node : nodesNode) {
                        if (node.has("id")) {
                            taskIds.add(node.get("id").asText());
                        }
                    }

                    if (!taskIds.isEmpty()) {
                        // Batch fetch tasks
                        List<com.example.urgs_api.task.entity.Task> tasks = taskMapper.selectBatchIds(taskIds);
                        Map<String, com.example.urgs_api.task.entity.Task> taskMap = tasks.stream()
                                .collect(Collectors.toMap(com.example.urgs_api.task.entity.Task::getId, t -> t));

                        for (JsonNode node : nodesNode) {
                            if (node.has("id")) {
                                String taskId = node.get("id").asText();
                                com.example.urgs_api.task.entity.Task task = taskMap.get(taskId);
                                if (task != null && task.getContent() != null) {
                                    // Merge task content back into node data
                                    JsonNode taskContentNode = objectMapper.readTree(task.getContent());
                                    if (node.has("data") && node
                                            .get("data") instanceof com.fasterxml.jackson.databind.node.ObjectNode) {
                                        com.fasterxml.jackson.databind.node.ObjectNode dataNode = (com.fasterxml.jackson.databind.node.ObjectNode) node
                                                .get("data");
                                        // We overwrite/merge fields from task content
                                        // Assuming task content is the full data object
                                        if (taskContentNode.isObject()) {
                                            dataNode.setAll(
                                                    (com.fasterxml.jackson.databind.node.ObjectNode) taskContentNode);
                                        }
                                        // FORCE inject taskType from DB column to ensure it's correct
                                        dataNode.put("taskType", task.getType());
                                    } else {
                                        // If data is missing or not object, just set it
                                        ((com.fasterxml.jackson.databind.node.ObjectNode) node).set("data",
                                                taskContentNode);
                                        // FORCE inject taskType from DB column
                                        if (node.get(
                                                "data") instanceof com.fasterxml.jackson.databind.node.ObjectNode) {
                                            ((com.fasterxml.jackson.databind.node.ObjectNode) node.get("data"))
                                                    .put("taskType", task.getType());
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                workflow.setContent(rootNode.toString());
            } catch (Exception e) {
                e.printStackTrace(); // Log error but return workflow as is
            }
        }
        return workflow;
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteWorkflow(Long workflowId) {
        // 1. Delete dependencies
        jobDependencyMapper.delete(new QueryWrapper<JobDependency>().eq("workflow_id", workflowId));

        // 4. Delete associated tasks
        com.example.urgs_api.workflow.entity.Workflow workflow = workflowMapper.selectById(workflowId);
        if (workflow != null && workflow.getContent() != null) {
            try {
                JsonNode root = objectMapper.readTree(workflow.getContent());
                if (root.has("nodes")) {
                    List<String> taskIds = new ArrayList<>();
                    for (JsonNode node : root.get("nodes")) {
                        if (node.has("id")) {
                            taskIds.add(node.get("id").asText());
                        }
                    }
                    if (!taskIds.isEmpty()) {
                        taskMapper.deleteBatchIds(taskIds);
                    }
                }
            } catch (Exception e) {
                // Log error but continue deletion of workflow
                e.printStackTrace();
            }
        }

        // 5. Delete workflow
        workflowMapper.deleteById(workflowId);
    }

    private boolean hasCycle(List<String> nodes, List<Map<String, String>> edges) {
        Map<String, List<String>> adj = new HashMap<>();
        Map<String, Integer> inDegree = new HashMap<>();

        for (String node : nodes) {
            adj.put(node, new ArrayList<>());
            inDegree.put(node, 0);
        }

        for (String node : nodes) {
            adj.put(node, new ArrayList<>());
            inDegree.put(node, 0);
        }

        if (edges != null) {
            for (Map<String, String> edge : edges) {
                String u = edge.get("source");
                String v = edge.get("target");

                // Ensure nodes exist in the graph
                if (!adj.containsKey(u) || !adj.containsKey(v)) {
                    // Skip edges that reference unknown nodes, or throw error
                    // For robustness, let's skip but log/warn if possible.
                    // Here we just continue to avoid NPE.
                    continue;
                }

                adj.get(u).add(v);
                inDegree.put(v, inDegree.get(v) + 1);
            }
        }

        Queue<String> queue = new LinkedList<>();
        for (String node : nodes) {
            if (inDegree.get(node) == 0) {
                queue.offer(node);
            }
        }

        int visited = 0;
        while (!queue.isEmpty()) {
            String u = queue.poll();
            visited++;

            for (String v : adj.get(u)) {
                inDegree.put(v, inDegree.get(v) - 1);
                if (inDegree.get(v) == 0) {
                    queue.offer(v);
                }
            }
        }

        return visited != nodes.size();
    }
}
