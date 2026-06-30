package com.example.urgs_api.im.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.example.urgs_api.im.entity.ImConversation;
import com.example.urgs_api.im.entity.ImGroup;
import com.example.urgs_api.im.entity.ImGroupMember;
import com.example.urgs_api.im.entity.ImMessage;
import com.example.urgs_api.im.mapper.ImConversationMapper;
import com.example.urgs_api.im.mapper.ImGroupMapper;
import com.example.urgs_api.im.mapper.ImGroupMemberMapper;
import com.example.urgs_api.im.mapper.ImMessageMapper;
import com.example.urgs_api.im.service.ImSessionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class ImSessionServiceImpl implements ImSessionService {

    @Autowired
    private ImConversationMapper conversationMapper;

    @Autowired
    private com.example.urgs_api.im.mapper.ImUserMapper userMapper;

    @Autowired
    private com.example.urgs_api.user.mapper.UserMapper sysUserMapper;

    @Autowired
    private ImGroupMapper groupMapper;

    @Autowired
    private ImGroupMemberMapper groupMemberMapper;

    @Autowired
    private ImMessageMapper messageMapper;

    @Override
    public List<ImConversation> getSessionList(Long userId) {
        List<ImConversation> rawList = conversationMapper.selectList(new QueryWrapper<ImConversation>()
                .eq("user_id", userId)
                .orderByDesc("is_top")
                .orderByDesc("last_msg_time")
                .orderByDesc("id"));

        List<ImConversation> list = new ArrayList<>();
        Set<String> seenSessionKeys = new HashSet<>();
        for (ImConversation conv : rawList) {
            String sessionKey = conv.getChatType() + ":" + conv.getPeerId();
            if (seenSessionKeys.add(sessionKey)) {
                list.add(conv);
            }
        }

        for (ImConversation conv : list) {
            if (conv.getChatType() == 1) { // Private
                // Try from ImUser first for basic info
                com.example.urgs_api.im.entity.ImUser peer = userMapper.selectById(conv.getPeerId());
                // Also try sys_user for latest avatar (Source of Truth)
                com.example.urgs_api.user.model.User sysUser = sysUserMapper.selectById(conv.getPeerId());

                if (sysUser != null) {
                    conv.setName(sysUser.getName()); // Sync name too
                    conv.setAvatar(sysUser.getAvatarUrl());
                } else if (peer != null) {
                    conv.setName(peer.getWxId());
                    conv.setAvatar(peer.getAvatarUrl());
                } else {
                    conv.setName("User " + conv.getPeerId());
                }
            } else {
                // Group: keep custom names, but replace legacy placeholders with member names.
                if (isDefaultGroupName(conv.getName())) {
                    conv.setName(resolveGroupDisplayName(conv.getPeerId()));
                }
            }
        }
        return list;

    }

    @Override
    public void updateSession(Long userId, Long peerId, String content) {
        // Logic to update or create session
    }

    @Override
    public void clearUnread(Long userId, Long peerId, Integer chatType) {
        UpdateWrapper<ImConversation> update = new UpdateWrapper<ImConversation>()
                .eq("user_id", userId)
                .eq("peer_id", peerId)
                .eq(chatType != null, "chat_type", chatType)
                .set("unread_count", 0);
        conversationMapper.update(null, update);
    }

    @Override
    public void deleteSession(Long userId, Long peerId, Integer chatType) {
        conversationMapper.delete(new QueryWrapper<ImConversation>()
                .eq("user_id", userId)
                .eq("peer_id", peerId)
                .eq(chatType != null, "chat_type", chatType));
    }

    @Override
    public void updateSettings(Long userId, Long peerId, Integer chatType, Boolean isTop, Boolean isMuted) {
        if (isTop == null && isMuted == null) {
            return;
        }
        UpdateWrapper<ImConversation> update = new UpdateWrapper<ImConversation>()
                .eq("user_id", userId)
                .eq("peer_id", peerId)
                .eq(chatType != null, "chat_type", chatType)
                .set(isTop != null, "is_top", isTop)
                .set(isMuted != null, "is_muted", isMuted);
        conversationMapper.update(null, update);
    }

    @Override
    public void clearHistory(Long userId, Long peerId, Integer chatType) {
        String conversationId = chatType != null && chatType == 2
                ? "GROUP_" + peerId
                : Math.min(userId, peerId) + "_" + Math.max(userId, peerId);
        ImMessage latestMessage = messageMapper.selectOne(new QueryWrapper<ImMessage>()
                .eq("conversation_id", conversationId)
                .orderByDesc("id")
                .last("LIMIT 1"));
        Long clearedBeforeMsgId = latestMessage == null ? 0L : latestMessage.getId();

        conversationMapper.update(null, new UpdateWrapper<ImConversation>()
                .eq("user_id", userId)
                .eq("peer_id", peerId)
                .eq(chatType != null, "chat_type", chatType)
                .set("cleared_before_msg_id", clearedBeforeMsgId)
                .set("last_msg_id", null)
                .set("last_msg_content", "")
                .set("last_msg_time", null)
                .set("unread_count", 0));
    }

    @Override
    public Long getClearedBeforeMsgId(Long userId, Long peerId, Integer chatType) {
        ImConversation conversation = conversationMapper.selectOne(new QueryWrapper<ImConversation>()
                .eq("user_id", userId)
                .eq("peer_id", peerId)
                .eq(chatType != null, "chat_type", chatType)
                .orderByDesc("id")
                .last("LIMIT 1"));
        return conversation == null ? null : conversation.getClearedBeforeMsgId();
    }

    private boolean isDefaultGroupName(String name) {
        if (name == null || name.trim().isEmpty()) {
            return true;
        }
        String trimmed = name.trim();
        return "Unnamed Group".equalsIgnoreCase(trimmed) || "Group Chat".equalsIgnoreCase(trimmed);
    }

    private String resolveGroupDisplayName(Long groupId) {
        ImGroup group = groupMapper.selectById(groupId);
        if (group != null && !isDefaultGroupName(group.getName())) {
            return truncateGroupName(group.getName());
        }

        List<ImGroupMember> members = groupMemberMapper.selectList(new QueryWrapper<ImGroupMember>()
                .eq("group_id", groupId)
                .orderByAsc("join_time"));
        if (members.isEmpty()) {
            return "群聊";
        }

        List<String> names = new ArrayList<>();
        for (ImGroupMember member : members) {
            String displayName = resolveUserDisplayName(member.getUserId());
            if (displayName != null && !displayName.isBlank() && !names.contains(displayName)) {
                names.add(displayName);
            }
        }
        if (names.isEmpty()) {
            return "群聊";
        }

        int visibleCount = Math.min(names.size(), 4);
        String baseName = names.stream().limit(visibleCount).collect(Collectors.joining("、"));
        if (names.size() > visibleCount) {
            baseName = baseName + "等" + names.size() + "人";
        }
        return truncateGroupName(baseName);
    }

    private String resolveUserDisplayName(Long userId) {
        com.example.urgs_api.user.model.User sysUser = sysUserMapper.selectById(userId);
        if (sysUser != null && sysUser.getName() != null && !sysUser.getName().isBlank()) {
            return sysUser.getName();
        }

        com.example.urgs_api.im.entity.ImUser imUser = userMapper.selectById(userId);
        if (imUser != null && imUser.getWxId() != null && !imUser.getWxId().isBlank()) {
            return imUser.getWxId();
        }
        if (sysUser != null && sysUser.getEmpId() != null && !sysUser.getEmpId().isBlank()) {
            return sysUser.getEmpId();
        }
        return "用户" + userId;
    }

    private String truncateGroupName(String name) {
        int maxLength = 32;
        if (name.length() <= maxLength) {
            return name;
        }
        return name.substring(0, maxLength - 3) + "...";
    }
}
