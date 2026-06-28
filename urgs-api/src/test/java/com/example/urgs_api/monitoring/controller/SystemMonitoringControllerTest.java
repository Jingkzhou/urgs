package com.example.urgs_api.monitoring.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class SystemMonitoringControllerTest {

    @Test
    void protectsEveryPublicEndpointWithExpectedPermission() {
        Map<String, String> expected = Map.of(
                "overview", "sys:monitor:query",
                "servers", "sys:monitor:query",
                "serverTrend", "sys:monitor:query",
                "databases", "sys:monitor:query",
                "databaseTrend", "sys:monitor:query",
                "slowSql", "sys:monitor:query",
                "thresholds", "sys:monitor:query",
                "updateThresholds", "sys:monitor:config",
                "collect", "sys:monitor:collect"
        );

        for (Method method : SystemMonitoringController.class.getDeclaredMethods()) {
            if (!expected.containsKey(method.getName())) continue;
            RequirePermission permission = method.getAnnotation(RequirePermission.class);
            assertThat(permission).as(method.getName()).isNotNull();
            assertThat(permission.value()).isEqualTo(expected.get(method.getName()));
        }
    }
}
