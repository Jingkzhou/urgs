package com.example.urgs_api.im.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.im.entity.ImFriendship;
import com.example.urgs_api.im.entity.ImUser;
import com.example.urgs_api.im.mapper.ImFriendshipMapper;
import com.example.urgs_api.im.mapper.ImUserMapper;
import com.example.urgs_api.im.service.ImUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ImUserServiceImpl implements ImUserService {

    @Autowired
    private ImUserMapper userMapper;
    @Autowired
    private ImFriendshipMapper friendshipMapper;
    @Autowired
    private com.example.urgs_api.user.mapper.UserMapper sysUserMapper;
    @Autowired
    private com.example.urgs_api.im.mapper.ImConversationMapper conversationMapper;

    @Override
    public ImUser getUser(Long userId) {
        ImUser imUser = userMapper.selectById(userId);
        com.example.urgs_api.user.model.User sysUser = sysUserMapper.selectById(userId);
        if (sysUser != null) {
            if (imUser == null) {
                imUser = new ImUser();
                imUser.setUserId(sysUser.getId());
                imUser.setWxId(sysUser.getName());
                imUser.setAvatarUrl(sysUser.getAvatarUrl());
                // Can optionally insert into DB here to persist, but transient is fine for
                // query
            } else {
                // Always use system source of truth for these fields
                imUser.setWxId(sysUser.getName());
                imUser.setAvatarUrl(sysUser.getAvatarUrl());
            }
        }
        return imUser;
    }

    @Override
    public void addFriend(Long userId, Long friendId, String remark) {
        // Ensure friend exists in im_user
        ImUser friendImUser = userMapper.selectById(friendId);
        if (friendImUser == null) {
            com.example.urgs_api.user.model.User sysUser = sysUserMapper.selectById(friendId);
            if (sysUser != null) {
                friendImUser = new ImUser();
                friendImUser.setUserId(sysUser.getId());
                friendImUser.setWxId(sysUser.getName()); // Use name as display name/wxId equivalent for now
                friendImUser.setAvatarUrl(""); // Default to empty, let frontend handle
                friendImUser.setCreatedAt(LocalDateTime.now());
                friendImUser.setUpdatedAt(LocalDateTime.now());
                userMapper.insert(friendImUser);
            } else {
                throw new RuntimeException("User not found: " + friendId);
            }
        }

        // Check if friendship already exists
        Long count = friendshipMapper.selectCount(new QueryWrapper<ImFriendship>()
                .eq("user_id", userId)
                .eq("friend_id", friendId));

        if (count == 0) {
            ImFriendship friendship = new ImFriendship();
            friendship.setUserId(userId);
            friendship.setFriendId(friendId);
            friendship.setRemark(remark);
            friendship.setStatus(0);
            friendship.setCreatedAt(LocalDateTime.now());
            friendshipMapper.insert(friendship);

            // Add reverse direction
            ImFriendship reverse = new ImFriendship();
            reverse.setUserId(friendId);
            reverse.setFriendId(userId);
            reverse.setStatus(0);
            reverse.setCreatedAt(LocalDateTime.now());
            friendshipMapper.insert(reverse);
        }

        // Auto-create Conversation for User
        createConversationIfNotExists(userId, friendId);
        // Auto-create Conversation for Friend
        createConversationIfNotExists(friendId, userId);
    }

    private void createConversationIfNotExists(Long userId, Long peerId) {
        Long count = conversationMapper.selectCount(new QueryWrapper<com.example.urgs_api.im.entity.ImConversation>()
                .eq("user_id", userId)
                .eq("peer_id", peerId));

        if (count == 0) {
            com.example.urgs_api.im.entity.ImConversation conversation = new com.example.urgs_api.im.entity.ImConversation();
            conversation.setUserId(userId);
            conversation.setPeerId(peerId);
            conversation.setChatType(1); // Private
            conversation.setLastMsgContent("You are now friends");
            conversation.setLastMsgTime(LocalDateTime.now());
            conversation.setUnreadCount(0);
            conversation.setIsTop(false);
            conversation.setIsHidden(false);
            conversationMapper.insert(conversation);
        }
    }

    @Override
    public List<ImFriendship> getFriendList(Long userId) {
        return friendshipMapper.selectList(new QueryWrapper<ImFriendship>().eq("user_id", userId));
    }

    @Override
    public List<ImUser> getAllUsers() {
        return userMapper.selectList(null);
    }

    @Override
    public List<ImUser> searchUsers(String keyword) {
        // Search in sys_user
        QueryWrapper<com.example.urgs_api.user.model.User> qw = new QueryWrapper<>();
        if (keyword != null && !keyword.trim().isEmpty()) {
            qw.like("name", keyword).or().like("emp_id", keyword);
        }
        List<com.example.urgs_api.user.model.User> sysUsers = sysUserMapper.selectList(qw);

        // Convert to ImUser (Transient, not checking DB existence)
        return sysUsers.stream().map(u -> {
            ImUser imUser = new ImUser();
            imUser.setUserId(u.getId());
            imUser.setWxId(u.getName());
            imUser.setAvatarUrl(u.getAvatarUrl());
            // Check if exists in im_user to get real avatar/signature?
            // For performance, we might skip or do a batch query.
            // For now, simple mapping is enough for "Add Friend" list.
            return imUser;
        }).collect(java.util.stream.Collectors.toList());
    }

}
