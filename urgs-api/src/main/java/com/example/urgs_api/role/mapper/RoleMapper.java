package com.example.urgs_api.role.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.role.model.Role;
import org.apache.ibatis.annotations.*;

import java.util.Set;

@Mapper
public interface RoleMapper extends BaseMapper<Role> {

    @Select("SELECT perm_code FROM sys_role_permission WHERE role_id = #{roleId}")
    Set<String> selectRolePermissions(Long roleId);

    @Delete("DELETE FROM sys_role_permission WHERE role_id = #{roleId}")
    void deleteRolePermissions(Long roleId);

    @Insert("<script>" +
            "INSERT INTO sys_role_permission (role_id, perm_code) VALUES " +
            "<foreach collection='permissions' item='perm' separator=','>" +
            "(#{roleId}, #{perm}) " +
            "</foreach>" +
            "</script>")
    void insertRolePermissions(@Param("roleId") Long roleId, @Param("permissions") Set<String> permissions);
}
