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
        return agentRepository.selectList(new QueryWrapper<Agent>().orderByDesc("id"));
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
}
