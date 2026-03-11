package com.example.urgs_api.announcement.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.announcement.model.AnnouncementRead;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AnnouncementReadMapper extends BaseMapper<AnnouncementRead> {
    
    @Insert("INSERT IGNORE INTO sys_announcement_read (id, announcement_id, user_id, read_time) " +
            "VALUES (#{id}, #{announcementId}, #{userId}, #{readTime})")
    int insertIgnore(AnnouncementRead announcementRead);
}
