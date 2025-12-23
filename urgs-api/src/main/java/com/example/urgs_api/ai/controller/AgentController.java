package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.service.AgentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ai/agent")
public class AgentController {

    @Autowired
    private AgentService agentService;

    @GetMapping("/list")
    public List<Agent> listAgents() {
        return agentService.listAgents();
    }

    @PostMapping("/create")
    public ResponseEntity<?> createAgent(@RequestBody Agent agent) {
        Agent saved = agentService.saveAgent(agent);
        return ResponseEntity.ok(Map.of("status", "success", "id", saved.getId()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateAgent(@PathVariable Long id, @RequestBody Agent agent) {
        agent.setId(id);
        agentService.saveAgent(agent);
        return ResponseEntity.ok(Map.of("status", "success"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteAgent(@PathVariable Long id) {
        agentService.deleteAgent(id);
        return ResponseEntity.ok(Map.of("status", "success"));
    }

    @GetMapping("/role/{roleId}")
    public List<Long> getRoleAgents(@PathVariable Long roleId) {
        return agentService.getRoleAgents(roleId);
    }

    @PostMapping("/role/{roleId}")
    public ResponseEntity<?> updateRoleAgents(@PathVariable Long roleId, @RequestBody Map<String, List<Long>> payload) {
        List<Long> agentIds = payload.get("agentIds");
        agentService.updateRoleAgents(roleId, agentIds);
        return ResponseEntity.ok(Map.of("status", "success"));
    }
}
