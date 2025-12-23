package com.example.urgs_api.announcement.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.announcement.model.Announcement;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface AnnouncementMapper extends BaseMapper<Announcement> {

        @Select("<script>" +
                        "SELECT a.*, " +
                        "(CASE WHEN r.id IS NOT NULL THEN 1 ELSE 0 END) as has_read, " +
                        "(SELECT COUNT(*) FROM sys_announcement_read WHERE announcement_id = a.id) as read_count " +
                        "FROM sys_announcement a " +
                        "LEFT JOIN sys_announcement_read r ON a.id = r.announcement_id AND r.user_id = #{userId} " +
                        "WHERE a.status = 1 " +
                        "<if test='keyword != null and keyword != \"\"'>" +
                        "  AND a.title LIKE CONCAT('%', #{keyword}, '%') " +
                        "</if>" +
                        "<if test='type != null and type != \"all\" and type != \"\"'>" +
                        "  AND a.type = #{type} " +
                        "</if>" +
                        "<if test='category != null and category != \"\"'>" +
                        "  AND a.category = #{category} " +
                        "</if>" +
                        "AND (" +
                        "  a.create_by = #{userId} " + // Created by me
                        "  <if test='systems != null and systems.size() > 0'>" +
                        "    OR (" +
                        "      <foreach collection='systems' item='sys' separator=' OR '>" +
                        "        a.systems LIKE CONCAT('%', #{sys}, '%')" +
                        "      </foreach>" +
                        "    )" +
                        "  </if>" +
                        ") " +
                        "ORDER BY a.create_time DESC" +
                        "</script>")
        Page<Announcement> selectAnnouncementList(Page<Announcement> page,
                        @Param("keyword") String keyword,
                        @Param("type") String type,
                        @Param("category") String category,
                        @Param("userId") String userId,
                        @Param("systems") List<String> systems);
}
