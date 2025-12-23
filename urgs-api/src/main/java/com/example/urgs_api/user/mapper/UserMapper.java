package com.example.urgs_api.user.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.user.model.User;

public interface UserMapper extends BaseMapper<User> {
    @org.apache.ibatis.annotations.Select("SELECT rp.perm_code FROM sys_role_permission rp " +
            "JOIN sys_role r ON rp.role_id = r.id " +
            "JOIN sys_user u ON u.role_id = r.id " +
            "WHERE u.id = #{userId}")
    java.util.Set<String> selectUserPermissions(Long userId);

    @org.apache.ibatis.annotations.Select("<script>" +
            "SELECT u.*, r.name AS role_name " +
            "FROM sys_user u " +
            "LEFT JOIN sys_role r ON u.role_id = r.id " +
            "WHERE 1=1 " +
            "<if test='keyword != null and keyword != \"\"'>" +
            "AND (u.name LIKE CONCAT('%', #{keyword}, '%') OR u.emp_id LIKE CONCAT('%', #{keyword}, '%') OR r.name LIKE CONCAT('%', #{keyword}, '%')) "
            +
            "</if>" +
            "ORDER BY u.id DESC" +
            "</script>")
    java.util.List<User> searchUsers(@org.apache.ibatis.annotations.Param("keyword") String keyword);
}
