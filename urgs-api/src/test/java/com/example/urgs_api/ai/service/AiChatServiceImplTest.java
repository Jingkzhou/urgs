package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.repository.AgentRepository;
import com.example.urgs_api.user.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AiChatServiceImplTest {

    @Test
    void listRoutingAgentsExcludesRegulatoryQueryAgentWithoutPermission() {
        AgentRepository agentRepository = mock(AgentRepository.class);
        UserService userService = mock(UserService.class);
        Agent generalAgent = agent("general-agent");
        Agent regulatoryQueryAgent = agent("regulatory-data-query-agent");
        when(agentRepository.selectList(any())).thenReturn(List.of(generalAgent, regulatoryQueryAgent));
        when(userService.getUserPermissions(1L)).thenReturn(Set.of());

        AiChatServiceImpl service = new AiChatServiceImpl();
        ReflectionTestUtils.setField(service, "agentRepository", agentRepository);
        ReflectionTestUtils.setField(service, "userService", userService);

        @SuppressWarnings("unchecked")
        List<Agent> result = (List<Agent>) ReflectionTestUtils.invokeMethod(
                service, "listRoutingAgents", 1L);

        assertEquals(List.of("general-agent"), result.stream().map(Agent::getAgentCode).toList());
    }

    @Test
    void listRoutingAgentsIncludesRegulatoryQueryAgentWithPermission() {
        AgentRepository agentRepository = mock(AgentRepository.class);
        UserService userService = mock(UserService.class);
        Agent regulatoryQueryAgent = agent("regulatory-data-query-agent");
        when(agentRepository.selectList(any())).thenReturn(List.of(regulatoryQueryAgent));
        when(userService.getUserPermissions(2L)).thenReturn(Set.of("ai:regulatory-query:use"));

        AiChatServiceImpl service = new AiChatServiceImpl();
        ReflectionTestUtils.setField(service, "agentRepository", agentRepository);
        ReflectionTestUtils.setField(service, "userService", userService);

        @SuppressWarnings("unchecked")
        List<Agent> result = (List<Agent>) ReflectionTestUtils.invokeMethod(
                service, "listRoutingAgents", 2L);

        assertEquals(List.of(regulatoryQueryAgent), result);
    }

    private Agent agent(String agentCode) {
        Agent agent = new Agent();
        agent.setAgentCode(agentCode);
        return agent;
    }
}
