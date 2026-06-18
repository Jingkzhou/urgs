package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.entity.AgentRole;
import com.example.urgs_api.ai.repository.AgentRepository;
import com.example.urgs_api.ai.repository.AgentRoleRepository;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class AgentService {

    @Autowired
    private AgentRepository agentRepository;

    @Autowired
    private AgentRoleRepository agentRoleRepository;

    public List<Agent> listAgents() {
        return agentRepository.selectList(new QueryWrapper<Agent>().orderByAsc("sort_order").orderByDesc("id"));
    }

    public List<Long> getRoleAgents(Long roleId) {
        return agentRoleRepository.selectList(new QueryWrapper<AgentRole>().eq("role_id", roleId))
                .stream().map(AgentRole::getAgentId).collect(java.util.stream.Collectors.toList());
    }

    public void updateRoleAgents(Long roleId, List<Long> agentIds) {
        // Delete existing
        agentRoleRepository.delete(new QueryWrapper<AgentRole>().eq("role_id", roleId));

        // Add new
        if (agentIds != null && !agentIds.isEmpty()) {
            for (Long agentId : agentIds) {
                AgentRole ar = new AgentRole();
                ar.setRoleId(roleId);
                ar.setAgentId(agentId);
                agentRoleRepository.insert(ar);
            }
        }
    }

    public Agent getAgent(Long id) {
        return agentRepository.selectById(id);
    }

    public Agent saveAgent(Agent agent) {
        normalizeBuildMode(agent);
        agent.setUpdatedAt(new Date());
        if (agent.getId() == null) {
            agentRepository.insert(agent);
        } else {
            agentRepository.updateById(agent);
        }
        return agent;
    }

    public void deleteAgent(Long id) {
        agentRepository.deleteById(id);
    }

    private void normalizeBuildMode(Agent agent) {
        String buildMode = agent.getBuildMode();
        if (isBlank(buildMode)) {
            if (!isBlank(agent.getDifyApiKey())) {
                buildMode = "DIFY";
            } else if (!isBlank(agent.getAgentAppTools())) {
                buildMode = "AGENT_APP";
            } else {
                buildMode = "RAG";
            }
        }

        if (!"DIFY".equals(buildMode) && !"RAG".equals(buildMode) && !"AGENT_APP".equals(buildMode)
                && !"DEEPAGENTS".equals(buildMode)) {
            buildMode = "RAG";
        }
        agent.setBuildMode(buildMode);
        if (isBlank(agent.getAgentType())) {
            agent.setAgentType("SPECIALIST");
        }
        if (agent.getSortOrder() == null) {
            agent.setSortOrder(0);
        }

        if ("DIFY".equals(buildMode)) {
            agent.setKnowledgeBase(null);
            agent.setRagInstruction(null);
            agent.setAgentAppTools(null);
        } else if ("RAG".equals(buildMode)) {
            agent.setDifyApiKey(null);
            agent.setDifyApiBase(null);
            agent.setAgentAppTools(null);
        } else {
            agent.setKnowledgeBase(null);
            agent.setRagInstruction(null);
            agent.setDifyApiKey(null);
            agent.setDifyApiBase(null);
            if ("DEEPAGENTS".equals(buildMode)) {
                agent.setAgentAppTools(null);
            }
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
