package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AgentExecutionContextServiceTest {

    @Test
    void buildsGenericTrustedUserContextWithoutAgentPolicy() {
        UserService userService = mock(UserService.class);
        User user = new User();
        user.setSystem("credit,征信系统");
        user.setOrgName("分行一");
        when(userService.getUserPermissions(7L)).thenReturn(Set.of("ai:regulatory-query:use"));
        when(userService.getById(7L)).thenReturn(user);

        AgentExecutionContextService service = new AgentExecutionContextService(userService);
        Map<String, Object> result = service.build(7L);

        assertEquals(7L, result.get("requester_user_id"));
        assertEquals(Set.of("ai:regulatory-query:use"), result.get("permissions"));
        assertEquals(List.of("credit", "征信系统"), result.get("allowed_systems"));
        assertEquals(List.of("分行一"), result.get("allowed_organizations"));
        assertFalse(result.containsKey("can_view_detail"));
    }
}
