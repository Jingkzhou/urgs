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

        @Autowired
        private com.example.urgs_api.im.service.ImChatService imChatService;

        @Override
        public void addComment(AnnouncementComment comment) {
                comment.setCreateTime(LocalDateTime.now());
                commentMapper.insert(comment);

                // Notify mentioned users
                if (comment.getMentionedUserIds() != null && !comment.getMentionedUserIds().isEmpty()) {
                        // Get sender info
                        com.example.urgs_api.user.model.User sender = userMapper
                                        .selectOne(new QueryWrapper<com.example.urgs_api.user.model.User>()
                                                        .eq("emp_id", comment.getUserId()));
                        String senderName = sender != null ? sender.getName() : comment.getUserId();

                        for (String mentionedEmpId : comment.getMentionedUserIds()) {
                                com.example.urgs_api.user.model.User mentionedUser = userMapper
                                                .selectOne(new QueryWrapper<com.example.urgs_api.user.model.User>()
                                                                .eq("emp_id", mentionedEmpId));
                                if (mentionedUser != null) {
                                        com.example.urgs_api.im.entity.ImMessage msg = new com.example.urgs_api.im.entity.ImMessage();
                                        msg.setSenderId(sender != null ? sender.getId() : 0L); // Or System ID? Let's
                                                                                               // use sender ID for now
                                        msg.setReceiverId(mentionedUser.getId());
                                        // Generate conversation ID: smaller_larger
                                        long uid1 = msg.getSenderId();
                                        long uid2 = msg.getReceiverId();
                                        msg.setConversationId(uid1 < uid2 ? uid1 + "_" + uid2 : uid2 + "_" + uid1);
                                        msg.setMsgType(1); // Text
                                        msg.setContent(senderName + " 在公告评论中提到了你：" + comment.getContent());
                                        msg.setSendTime(LocalDateTime.now());
                                        imChatService.sendMessage(msg);
                                }
                        }
                }
        }

        @Autowired
        private com.example.urgs_api.user.mapper.UserMapper userMapper;

        @Override
        public List<AnnouncementComment> getComments(String announcementId) {
                List<AnnouncementComment> comments = commentMapper.selectList(new QueryWrapper<AnnouncementComment>()
                                .eq("announcement_id", announcementId)
                                .orderByAsc("create_time"));

                // Enrich with user info
                if (!comments.isEmpty()) {
                        // Bulk fetch approach could be better, but loop is fine for comments per post
                        for (AnnouncementComment c : comments) {
                                com.example.urgs_api.user.model.User user = userMapper
                                                .selectOne(new QueryWrapper<com.example.urgs_api.user.model.User>()
                                                                .eq("emp_id", c.getUserId()));
                                if (user != null) {
                                        c.setUserName(user.getName());
                                        c.setUserAvatar(user.getAvatarUrl());
                                } else {
                                        c.setUserName(c.getUserId()); // Fallback
                                }
                        }
                }
                return comments;
        }
}
