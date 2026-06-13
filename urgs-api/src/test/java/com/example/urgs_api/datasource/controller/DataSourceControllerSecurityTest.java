package com.example.urgs_api.datasource.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class DataSourceControllerSecurityTest {

    @Test
    void protectsCredentialBearingManagementEndpoints() throws Exception {
        assertPermission("testConnection", DataSourceConfig.class);
        assertPermission("getConfigs");
        assertPermission("createConfig", DataSourceConfig.class);
        assertPermission("updateConfig", Long.class, DataSourceConfig.class);
        assertPermission("deleteConfig", Long.class);
    }

    @Test
    void doesNotExposeResolvedCredentialEndpoint() {
        assertThrows(NoSuchMethodException.class,
                () -> DataSourceController.class.getDeclaredMethod("getResolvedConfig", Long.class));
    }

    private void assertPermission(String methodName, Class<?>... parameterTypes) throws Exception {
        Method method = DataSourceController.class.getDeclaredMethod(methodName, parameterTypes);
        RequirePermission permission = method.getAnnotation(RequirePermission.class);
        assertEquals("datasource:list", permission.value());
    }
}
