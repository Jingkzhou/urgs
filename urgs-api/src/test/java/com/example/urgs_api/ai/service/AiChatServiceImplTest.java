package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.repository.AgentRepository;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AiChatServiceImplTest {

    @Test
    void listRoutingAgentsOnlyIncludesAgentsAuthorizedForUserRole() {
        AgentRepository agentRepository = mock(AgentRepository.class);
        UserService userService = mock(UserService.class);
        AgentService agentService = mock(AgentService.class);
        Agent authorizedAgent = agent(10L, "authorized-agent", 1);
        Agent unauthorizedAgent = agent(20L, "unauthorized-agent", 1);
        when(userService.getById(1L)).thenReturn(user(100L));
        when(agentService.getRoleAgents(100L)).thenReturn(List.of(10L));
        when(agentRepository.selectList(any())).thenReturn(List.of(authorizedAgent, unauthorizedAgent));

        AiChatServiceImpl service = new AiChatServiceImpl();
        ReflectionTestUtils.setField(service, "agentRepository", agentRepository);
        ReflectionTestUtils.setField(service, "userService", userService);
        ReflectionTestUtils.setField(service, "agentService", agentService);

        @SuppressWarnings("unchecked")
        List<Agent> result = (List<Agent>) ReflectionTestUtils.invokeMethod(
                service, "listRoutingAgents", 1L);

        assertEquals(List.of("authorized-agent"), result.stream().map(Agent::getAgentCode).toList());
    }

    @Test
    void listRoutingAgentsReturnsEmptyWhenRoleHasNoAgents() {
        AgentRepository agentRepository = mock(AgentRepository.class);
        UserService userService = mock(UserService.class);
        AgentService agentService = mock(AgentService.class);
        when(userService.getById(2L)).thenReturn(user(200L));
        when(agentService.getRoleAgents(200L)).thenReturn(List.of());

        AiChatServiceImpl service = new AiChatServiceImpl();
        ReflectionTestUtils.setField(service, "agentRepository", agentRepository);
        ReflectionTestUtils.setField(service, "userService", userService);
        ReflectionTestUtils.setField(service, "agentService", agentService);

        @SuppressWarnings("unchecked")
        List<Agent> result = (List<Agent>) ReflectionTestUtils.invokeMethod(
                service, "listRoutingAgents", 2L);

        assertTrue(result.isEmpty());
        verify(agentRepository, never()).selectList(any());
    }

    @Test
    void canUseAgentRequiresRoleAuthorizationAndEnabledStatus() {
        AiChatServiceImpl service = new AiChatServiceImpl();
        Agent enabledAgent = agent(10L, "enabled-agent", 1);
        Agent disabledAgent = agent(10L, "disabled-agent", 0);

        assertTrue(Boolean.TRUE.equals(ReflectionTestUtils.invokeMethod(
                service, "canUseAgent", Set.of(10L), enabledAgent)));
        assertFalse(Boolean.TRUE.equals(ReflectionTestUtils.invokeMethod(
                service, "canUseAgent", Set.of(20L), enabledAgent)));
        assertFalse(Boolean.TRUE.equals(ReflectionTestUtils.invokeMethod(
                service, "canUseAgent", Set.of(10L), disabledAgent)));
    }

    private Agent agent(Long id, String agentCode, Integer status) {
        Agent agent = new Agent();
        agent.setId(id);
        agent.setAgentCode(agentCode);
        agent.setStatus(status);
        return agent;
    }

    private User user(Long roleId) {
        User user = new User();
        user.setRoleId(roleId);
        return user;
    }
}
