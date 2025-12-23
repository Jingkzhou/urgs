package com.example.urgs_api.permission.support;

import com.example.urgs_api.permission.dto.PermissionDTO;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class PermissionSeedProvider {

    /**
     * Baseline permissions used to diff against DB. Keep this in sync with front-end FULL_APP_STRUCTURE.
     */
    public List<PermissionDTO> seeds() {
        List<PermissionDTO> list = new ArrayList<>();
        list.add(new PermissionDTO(null, "工作台", "dashboard", "menu", "/dashboard", 0, "root"));
        list.add(new PermissionDTO(null, "系统跳转区", "dash:systems", "button", "-", 1, "1"));
        list.add(new PermissionDTO(null, "统计分析区", "dash:stats", "button", "-", 1, "1"));
        list.add(new PermissionDTO(null, "公告查看", "dash:notice:view", "button", "-", 1, "1"));

        list.add(new PermissionDTO(null, "数据查询", "query", "menu", "/query", 0, "root"));

        list.add(new PermissionDTO(null, "系统管理", "sys", "dir", "/admin", 0, "root"));

        list.add(new PermissionDTO(null, "机构管理", "sys:org", "menu", "/admin/org", 1, "3"));
        list.add(new PermissionDTO(null, "查询", "sys:org:query", "button", "-", 2, "3-1"));
        list.add(new PermissionDTO(null, "新增", "sys:org:add", "button", "-", 2, "3-1"));
        list.add(new PermissionDTO(null, "编辑", "sys:org:edit", "button", "-", 2, "3-1"));
        list.add(new PermissionDTO(null, "删除", "sys:org:del", "button", "-", 2, "3-1"));

        list.add(new PermissionDTO(null, "角色管理", "sys:role", "menu", "/admin/role", 1, "3"));
        list.add(new PermissionDTO(null, "查询", "sys:role:query", "button", "-", 2, "3-2"));
        list.add(new PermissionDTO(null, "新增", "sys:role:add", "button", "-", 2, "3-2"));
        list.add(new PermissionDTO(null, "编辑", "sys:role:edit", "button", "-", 2, "3-2"));
        list.add(new PermissionDTO(null, "删除", "sys:role:del", "button", "-", 2, "3-2"));

        list.add(new PermissionDTO(null, "用户管理", "sys:user", "menu", "/admin/user", 1, "3"));
        list.add(new PermissionDTO(null, "查询", "sys:user:query", "button", "-", 2, "3-3"));
        list.add(new PermissionDTO(null, "新增", "sys:user:add", "button", "-", 2, "3-3"));
        list.add(new PermissionDTO(null, "编辑", "sys:user:edit", "button", "-", 2, "3-3"));
        list.add(new PermissionDTO(null, "删除", "sys:user:del", "button", "-", 2, "3-3"));

        list.add(new PermissionDTO(null, "菜单功能管理", "sys:menu", "menu", "/admin/menu", 1, "3"));
        list.add(new PermissionDTO(null, "动态捕捉", "sys:menu:sync", "button", "-", 2, "3-4"));
        list.add(new PermissionDTO(null, "新增", "sys:menu:add", "button", "-", 2, "3-4"));
        list.add(new PermissionDTO(null, "编辑", "sys:menu:edit", "button", "-", 2, "3-4"));
        list.add(new PermissionDTO(null, "删除", "sys:menu:del", "button", "-", 2, "3-4"));

        list.add(new PermissionDTO(null, "监管系统管理", "sys:sso", "menu", "/admin/sso", 1, "3"));
        list.add(new PermissionDTO(null, "查询", "sys:sso:query", "button", "-", 2, "3-5"));
        list.add(new PermissionDTO(null, "新增配置", "sys:sso:add", "button", "-", 2, "3-5"));
        list.add(new PermissionDTO(null, "编辑配置", "sys:sso:edit", "button", "-", 2, "3-5"));
        list.add(new PermissionDTO(null, "删除配置", "sys:sso:del", "button", "-", 2, "3-5"));
        return list;
    }
}
