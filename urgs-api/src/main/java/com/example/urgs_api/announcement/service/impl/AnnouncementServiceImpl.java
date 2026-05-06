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
import com.baomidou.mybatisplus.core.toolkit.IdWorker;
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
                // 使用 INSERT IGNORE 实现原子性幂等操作，解决并发下的唯一键冲突 ( uk_announcement_user )
                AnnouncementRead read = new AnnouncementRead();
                read.setId(IdWorker.getIdStr());
                read.setAnnouncementId(announcementId);
                read.setUserId(userId);
                read.setReadTime(LocalDateTime.now());
                readMapper.insertIgnore(read);
        }

        @Override
        public java.util.Map<String, Object> getStats(String userId, List<String> userSystems) {
                java.util.Map<String, Object> stats = new java.util.HashMap<>();
                
                // 本月发布总数
                LocalDateTime monthStart = LocalDateTime.now().withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
                QueryWrapper<Announcement> monthlyWrapper = new QueryWrapper<Announcement>()
                        .eq("status", 1)
                        .ge("create_time", monthStart);
                applyVisibilityScope(monthlyWrapper, userId, userSystems);
                stats.put("monthlyCount", baseMapper.selectCount(monthlyWrapper));
                
                // 紧急通知总数：与前台公告列表口径保持一致，只统计当前用户可见的通知公告
                QueryWrapper<Announcement> urgentWrapper = new QueryWrapper<Announcement>()
                        .eq("status", 1)
                        .eq("category", "Announcement")
                        .eq("type", "urgent");
                applyVisibilityScope(urgentWrapper, userId, userSystems);
                stats.put("urgentCount", baseMapper.selectCount(urgentWrapper));
                
                // 待发布总数
                QueryWrapper<Announcement> pendingWrapper = new QueryWrapper<Announcement>()
                        .eq("status", 0);
                applyVisibilityScope(pendingWrapper, userId, userSystems);
                stats.put("pendingCount", baseMapper.selectCount(pendingWrapper));
                
                return stats;
        }

        private void applyVisibilityScope(QueryWrapper<Announcement> wrapper, String userId, List<String> userSystems) {
                if (userId == null || userId.isEmpty()) {
                        return;
                }

                wrapper.and(scope -> {
                        scope.eq("create_by", userId);
                        if (userSystems != null) {
                                for (String system : userSystems) {
                                        if (system != null && !system.isBlank()) {
                                                scope.or().like("systems", system);
                                        }
                                }
                        }
                });
        }

        @Override
        public void markAllAsRead(String category, String userId, List<String> userSystems) {
                // 查询该分类下所有已发布且当前用户未读的公告 ID
                // 这通常涉及一个复杂的子查询或多步操作。为了实现幂等性且不报错：
                // 1. 获取所有符合条件的公告 ID
                QueryWrapper<Announcement> qw = new QueryWrapper<Announcement>().eq("status", 1);
                if (category != null && !category.isEmpty()) {
                        qw.eq("category", category);
                }
                applyVisibilityScope(qw, userId, userSystems);
                List<Announcement> list = baseMapper.selectList(qw.select("id"));
                
                for (Announcement a : list) {
                        AnnouncementRead read = new AnnouncementRead();
                        read.setId(IdWorker.getIdStr());
                        read.setAnnouncementId(a.getId());
                        read.setUserId(userId);
                        read.setReadTime(LocalDateTime.now());
                        readMapper.insertIgnore(read);
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
