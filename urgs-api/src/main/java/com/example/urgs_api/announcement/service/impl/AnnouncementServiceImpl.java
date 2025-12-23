package com.example.urgs_api.announcement.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.announcement.mapper.AnnouncementMapper;
import com.example.urgs_api.announcement.model.Announcement;
import com.example.urgs_api.announcement.service.AnnouncementService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.announcement.dto.AnnouncementQuery;
import com.example.urgs_api.announcement.mapper.AnnouncementReadMapper;
import com.example.urgs_api.announcement.mapper.AnnouncementCommentMapper;
import com.example.urgs_api.announcement.model.AnnouncementComment;
import com.example.urgs_api.announcement.model.AnnouncementRead;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class AnnouncementServiceImpl extends ServiceImpl<AnnouncementMapper, Announcement>
                implements AnnouncementService {

        @Autowired
        private AnnouncementReadMapper readMapper;

        @Autowired
        private AnnouncementCommentMapper commentMapper;

        @Override
        public Page<Announcement> getAnnouncementList(Page<Announcement> page, AnnouncementQuery query) {
                return baseMapper.selectAnnouncementList(page, query.getKeyword(), query.getType(), query.getCategory(),
                                query.getUserId(),
                                query.getUserSystems());
        }

        @Override
        public void markAsRead(String announcementId, String userId) {
                long count = readMapper.selectCount(new QueryWrapper<AnnouncementRead>()
                                .eq("announcement_id", announcementId)
                                .eq("user_id", userId));

                if (count == 0) {
                        AnnouncementRead read = new AnnouncementRead();
                        read.setAnnouncementId(announcementId);
                        read.setUserId(userId);
                        read.setReadTime(LocalDateTime.now());
                        readMapper.insert(read);
                }
        }

        @Override
        public void addComment(AnnouncementComment comment) {
                comment.setCreateTime(LocalDateTime.now());
                commentMapper.insert(comment);
        }

        @Override
        public List<AnnouncementComment> getComments(String announcementId) {
                return commentMapper.selectList(new QueryWrapper<AnnouncementComment>()
                                .eq("announcement_id", announcementId)
                                .orderByAsc("create_time"));
        }
}
