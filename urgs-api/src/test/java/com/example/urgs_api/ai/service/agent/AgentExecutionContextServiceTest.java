package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
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
        SysSystemService sysSystemService = mock(SysSystemService.class);
        User user = new User();
        user.setSystem("credit,征信系统");
        user.setOrgName("分行一");
        when(userService.getUserPermissions(7L)).thenReturn(Set.of("ai:regulatory-query:use"));
        when(userService.getById(7L)).thenReturn(user);
        SysSystem creditSystem = new SysSystem();
        creditSystem.setName("征信系统");
        creditSystem.setClientId("CREDIT_BUREAU");
        when(sysSystemService.getSystems(null, true)).thenReturn(List.of(creditSystem));

        AgentExecutionContextService service = new AgentExecutionContextService(userService, sysSystemService);
        Map<String, Object> result = service.build(7L);

        assertEquals(7L, result.get("requester_user_id"));
        assertEquals(Set.of("ai:regulatory-query:use"), result.get("permissions"));
        assertEquals(List.of("credit", "CREDIT_BUREAU"), result.get("allowed_systems"));
        assertEquals(List.of("credit", "征信系统"), result.get("allowed_system_names"));
        assertEquals(List.of("分行一"), result.get("allowed_organizations"));
        assertFalse(result.containsKey("can_view_detail"));
    }

    @Test
    void convertsConfiguredSystemNamesToRegulatorySystemCodes() {
        UserService userService = mock(UserService.class);
        SysSystemService sysSystemService = mock(SysSystemService.class);
        User user = new User();
        user.setSystem("监管集市,EAST5.0");
        when(userService.getUserPermissions(7L)).thenReturn(Set.of("ai:regulatory-query:use"));
        when(userService.getById(7L)).thenReturn(user);
        SysSystem market = new SysSystem();
        market.setName("监管集市");
        market.setClientId("SMTMODS");
        SysSystem east = new SysSystem();
        east.setName("EAST5.0");
        east.setClientId("EAST5");
        when(sysSystemService.getSystems(null, true)).thenReturn(List.of(market, east));

        Map<String, Object> result = new AgentExecutionContextService(userService, sysSystemService)
                .build(7L);

        assertEquals(List.of("SMTMODS", "EAST5"), result.get("allowed_systems"));
        assertEquals(List.of("监管集市", "EAST5.0"), result.get("allowed_system_names"));
    }
}
