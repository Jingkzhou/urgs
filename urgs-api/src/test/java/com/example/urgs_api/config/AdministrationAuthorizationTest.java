package com.example.urgs_api.config;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.permission.controller.PermissionController;
import com.example.urgs_api.permission.dto.PermissionSyncRequest;
import com.example.urgs_api.role.controller.RoleController;
import com.example.urgs_api.role.dto.RolePermissionRequest;
import com.example.urgs_api.role.dto.RoleRequest;
import com.example.urgs_api.user.controller.UserController;
import com.example.urgs_api.user.dto.ChangePasswordRequest;
import com.example.urgs_api.user.dto.UserDTO;
import com.example.urgs_api.user.dto.UserRequest;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class AdministrationAuthorizationTest {

    @Test
    void protectsUserAdministrationEndpoints() throws Exception {
        assertPermission(UserController.class, "list", "sys:user:query", String.class);
        assertPermission(UserController.class, "create", "sys:user:add", UserRequest.class);
        assertPermission(UserController.class, "resetPassword", "sys:user:edit", Long.class);
        assertPermission(UserController.class, "update", "sys:user:edit", Long.class, UserRequest.class);
        assertPermission(UserController.class, "delete", "sys:user:del", Long.class);
        assertPermission(UserController.class, "batch", "sys:user:add", List.class);
        assertPermission(UserController.class, "export", "sys:user:query");
    }

    @Test
    void protectsRoleAndPermissionMutationEndpoints() throws Exception {
        assertPermission(RoleController.class, "list", "sys:role:query");
        assertPermission(RoleController.class, "create", "sys:role:add", RoleRequest.class);
        assertPermission(RoleController.class, "update", "sys:role:edit", Long.class, RoleRequest.class);
        assertPermission(RoleController.class, "delete", "sys:role:del", Long.class);
        assertPermission(RoleController.class, "listPermissions", "sys:role:query", Long.class);
        assertPermission(RoleController.class, "savePermissions", "sys:role:edit", Long.class,
                RolePermissionRequest.class);
        assertPermission(PermissionController.class, "diff", "sys:menu:sync", PermissionSyncRequest.class);
        assertPermission(PermissionController.class, "sync", "sys:menu:sync", PermissionSyncRequest.class);
    }

    @Test
    void keepsSelfServiceUserEndpointsAvailableWithoutAdminPermission() throws Exception {
        assertNoPermission(UserController.class, "getMyPermissions", Long.class);
        assertNoPermission(UserController.class, "changePassword", Long.class, ChangePasswordRequest.class);
        assertNoPermission(UserController.class, "updateProfile", Long.class, UserDTO.class);
    }

    private void assertPermission(Class<?> controller, String methodName, String expected, Class<?>... params)
            throws Exception {
        Method method = controller.getDeclaredMethod(methodName, params);
        assertEquals(expected, method.getAnnotation(RequirePermission.class).value());
    }

    private void assertNoPermission(Class<?> controller, String methodName, Class<?>... params) throws Exception {
        Method method = controller.getDeclaredMethod(methodName, params);
        assertNull(method.getAnnotation(RequirePermission.class));
    }
}
