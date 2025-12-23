package com.example.urgs_api.im.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.im.entity.ImConversation;
import com.example.urgs_api.im.mapper.ImConversationMapper;
import com.example.urgs_api.im.service.ImSessionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ImSessionServiceImpl implements ImSessionService {

    @Autowired
    private ImConversationMapper conversationMapper;

    @Autowired
    private com.example.urgs_api.im.mapper.ImUserMapper userMapper;

    @Autowired
    private com.example.urgs_api.user.mapper.UserMapper sysUserMapper;

    @Override
    public List<ImConversation> getSessionList(Long userId) {
        List<ImConversation> list = conversationMapper.selectList(new QueryWrapper<ImConversation>()
                .eq("user_id", userId)
                .orderByDesc("last_msg_time"));

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
                // Group: Use persisted name or fallback
                if (conv.getName() == null || conv.getName().isEmpty()) {
                    conv.setName("Group Chat");
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
    public void clearUnread(Long userId, Long peerId) {
        com.example.urgs_api.im.entity.ImConversation conversation = conversationMapper
                .selectOne(new QueryWrapper<ImConversation>()
                        .eq("user_id", userId)
                        .eq("peer_id", peerId));

        if (conversation != null) {
            conversation.setUnreadCount(0);
            conversationMapper.updateById(conversation);
        }
    }

    @Override
    public void deleteSession(Long userId, Long peerId) {
        conversationMapper.delete(new QueryWrapper<ImConversation>()
                .eq("user_id", userId)
                .eq("peer_id", peerId));
    }
}
