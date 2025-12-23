package com.example.urgs_api.user.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.user.model.User;

public interface UserMapper extends BaseMapper<User> {
    @org.apache.ibatis.annotations.Select("SELECT rp.perm_code FROM sys_role_permission rp " +
            "JOIN sys_role r ON rp.role_id = r.id " +
            "JOIN sys_user u ON u.role_name = r.name " +
            "WHERE u.id = #{userId}")
    java.util.Set<String> selectUserPermissions(Long userId);
}
