package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.entity.AgentAppSkill;
import com.example.urgs_api.ai.service.AgentAppSkillService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ai/agent-app-skills")
public class AgentAppSkillController {

    @Autowired
    private AgentAppSkillService skillService;

    @GetMapping("/list")
    public List<AgentAppSkill> listSkills() {
        return skillService.listSkills();
    }

    @GetMapping("/enabled")
    public List<AgentAppSkill> listEnabledSkills(@RequestParam(required = false) String appCodes) {
        return skillService.listEnabledSkills(appCodes);
    }

    @PostMapping("/sync-defaults")
    public List<AgentAppSkill> syncDefaultSkills(@RequestParam String appCode) {
        return skillService.syncDefaultSkills(appCode);
    }

    @PostMapping("/create")
    public ResponseEntity<?> createSkill(@RequestBody AgentAppSkill skill) {
        AgentAppSkill saved = skillService.saveSkill(skill);
        return ResponseEntity.ok(Map.of("status", "success", "id", saved.getId()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateSkill(@PathVariable Long id, @RequestBody AgentAppSkill skill) {
        skill.setId(id);
        skillService.saveSkill(skill);
        return ResponseEntity.ok(Map.of("status", "success"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteSkill(@PathVariable Long id) {
        skillService.deleteSkill(id);
        return ResponseEntity.ok(Map.of("status", "success"));
    }
}
