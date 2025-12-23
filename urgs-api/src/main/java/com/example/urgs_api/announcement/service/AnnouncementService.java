package com.example.urgs_api.announcement.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.announcement.model.Announcement;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.announcement.dto.AnnouncementQuery;

import com.example.urgs_api.announcement.model.AnnouncementComment;
import java.util.List;

public interface AnnouncementService extends IService<Announcement> {
    Page<Announcement> getAnnouncementList(Page<Announcement> page, AnnouncementQuery query);

    void markAsRead(String announcementId, String userId);

    void addComment(AnnouncementComment comment);

    List<AnnouncementComment> getComments(String announcementId);
}
