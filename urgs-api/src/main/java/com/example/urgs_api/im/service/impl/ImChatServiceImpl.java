package com.example.urgs_api.im.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.im.entity.ImMessage;
import com.example.urgs_api.im.vo.ImMessageVO;
import com.example.urgs_api.im.mapper.ImMessageMapper;
import com.example.urgs_api.im.service.ImChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ImChatServiceImpl implements ImChatService {

    @Autowired
    private ImMessageMapper messageMapper;

    @Autowired
    private com.example.urgs_api.im.ws.ImWebSocketHandler webSocketHandler;

    @Autowired
    private com.example.urgs_api.im.mapper.ImConversationMapper conversationMapper;
    @Autowired
    private com.example.urgs_api.im.mapper.ImFriendshipMapper friendshipMapper;

    @Autowired
    private com.example.urgs_api.im.mapper.ImUserMapper userMapper; // Added for Name lookup

    @Autowired
    private com.example.urgs_api.im.mapper.ImGroupMemberMapper groupMemberMapper; // Added for Group Logic

    @Autowired
    private com.example.urgs_api.user.mapper.UserMapper sysUserMapper;

    @Override
    public void sendMessage(ImMessage message) {

        if (message.getGroupId() != null) {
            handleGroupMessage(message);
        } else {
            handlePrivateMessage(message);
        }
    }

    private void handlePrivateMessage(ImMessage message) {
        // ... (Existing logic)
        if (message.getReceiverId() != null) {
            long min = Math.min(message.getSenderId(), message.getReceiverId());
            long max = Math.max(message.getSenderId(), message.getReceiverId());
            message.setConversationId(min + "_" + max);
        }

        messageMapper.insert(message);

        String preview = message.getMsgType() == 2 ? "[Image]" : message.getContent();

        updateConversation(message.getSenderId(), message.getReceiverId(), preview, false, 1);
        updateConversation(message.getReceiverId(), message.getSenderId(), preview, true, 1);

        webSocketHandler.sendMessageToUser(message.getReceiverId(), convertToVO(message));
    }

    private void handleGroupMessage(ImMessage message) {
        Long groupId = message.getGroupId();
        message.setConversationId("GROUP_" + groupId);

        messageMapper.insert(message);

        QueryWrapper<com.example.urgs_api.im.entity.ImGroupMember> query = new QueryWrapper<>();
        query.eq("group_id", groupId);
        List<com.example.urgs_api.im.entity.ImGroupMember> members = groupMemberMapper.selectList(query);

        // Fetch Sender Name for Preview
        com.example.urgs_api.im.entity.ImUser sender = userMapper.selectById(message.getSenderId());
        String senderName = sender != null ? sender.getWxId() : "User " + message.getSenderId();
        String content = message.getMsgType() == 2 ? "[Image]" : message.getContent();
        String preview = senderName + ": " + content;

        // Convert to VO for push
        ImMessageVO vo = convertToVO(message);

        // Broadcast
        members.parallelStream().forEach(member -> {
            Long memberId = member.getUserId();
            if (!memberId.equals(message.getSenderId())) {
                webSocketHandler.sendMessageToUser(memberId, vo);
            }
        });

        // Update Conversations for all members
        for (com.example.urgs_api.im.entity.ImGroupMember member : members) {
            Long memberId = member.getUserId();
            boolean isSender = memberId.equals(message.getSenderId());
            boolean incrementUnread = !isSender;
            // Use formatted preview for all
            updateConversation(memberId, groupId, preview, incrementUnread, 2);
        }
    }

    private void updateConversation(Long userId, Long peerId, String lastMsgContent, boolean incrementUnread,
            int chatType) {
        QueryWrapper<com.example.urgs_api.im.entity.ImConversation> query = new QueryWrapper<>();
        query.eq("user_id", userId).eq("peer_id", peerId);
        com.example.urgs_api.im.entity.ImConversation conversation = conversationMapper.selectOne(query);

        if (conversation == null) {
            conversation = new com.example.urgs_api.im.entity.ImConversation();
            conversation.setUserId(userId);
            conversation.setPeerId(peerId);
            conversation.setChatType(chatType);
            conversation.setUnreadCount(incrementUnread ? 1 : 0);
            conversation.setIsTop(false);
            conversation.setIsHidden(false);
        } else {
            if (incrementUnread) {
                conversation.setUnreadCount(conversation.getUnreadCount() + 1);
            }
        }

        conversation.setLastMsgContent(lastMsgContent);
        conversation.setLastMsgTime(java.time.LocalDateTime.now());

        if (conversation.getId() == null) {
            conversationMapper.insert(conversation);
        } else {
            conversationMapper.updateById(conversation);
        }
    }

    @Override
    public List<ImMessageVO> getHistory(String conversationId, Long lastMsgId, int limit) {
        QueryWrapper<ImMessage> query = new QueryWrapper<>();
        query.eq("conversation_id", conversationId)
                .lt(lastMsgId != null, "id", lastMsgId)
                .orderByDesc("id")
                .last("LIMIT " + limit);
        List<ImMessage> messages = messageMapper.selectList(query);

        List<ImMessageVO> vos = new java.util.ArrayList<>();
        for (ImMessage msg : messages) {
            ImMessageVO vo = new ImMessageVO();
            org.springframework.beans.BeanUtils.copyProperties(msg, vo);

            // Resolve Sender Name and Avatar
            com.example.urgs_api.user.model.User sysUser = sysUserMapper.selectById(msg.getSenderId());
            if (sysUser != null) {
                vo.setSenderName(sysUser.getName());
                vo.setSenderAvatar(sysUser.getAvatarUrl());
            } else {
                com.example.urgs_api.im.entity.ImUser imUser = userMapper.selectById(msg.getSenderId());
                if (imUser != null) {
                    vo.setSenderName(imUser.getWxId());
                    vo.setSenderAvatar(imUser.getAvatarUrl());
                } else {
                    vo.setSenderName("User " + msg.getSenderId());
                }
            }
            vos.add(vo);
        }
        return vos;
    }

    @Override
    public void sendSystemMessage(Long groupId, String content) {
        ImMessage message = new ImMessage();
        message.setGroupId(groupId);
        message.setSenderId(0L); // System Sender ID
        message.setContent(content);
        message.setMsgType(1000); // System Message Type
        message.setSendTime(java.time.LocalDateTime.now());

        sendMessage(message);
    }

    private ImMessageVO convertToVO(ImMessage msg) {
        ImMessageVO vo = new ImMessageVO();
        org.springframework.beans.BeanUtils.copyProperties(msg, vo);
        com.example.urgs_api.user.model.User sysUser = sysUserMapper.selectById(msg.getSenderId());
        if (sysUser != null) {
            vo.setSenderName(sysUser.getName());
            vo.setSenderAvatar(sysUser.getAvatarUrl());
        } else {
            com.example.urgs_api.im.entity.ImUser imUser = userMapper.selectById(msg.getSenderId());
            if (imUser != null) {
                vo.setSenderName(imUser.getWxId());
                vo.setSenderAvatar(imUser.getAvatarUrl());
            } else {
                vo.setSenderName("User " + msg.getSenderId());
            }
        }
        return vo;
    }
}
