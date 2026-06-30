package com.example.urgs_api.im.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.example.urgs_api.im.entity.ImGroup;
import com.example.urgs_api.im.entity.ImGroupMember;
import com.example.urgs_api.im.mapper.ImGroupMapper;
import com.example.urgs_api.im.mapper.ImGroupMemberMapper;
import com.example.urgs_api.im.service.ImGroupService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ImGroupServiceImpl implements ImGroupService {

    @Autowired
    private ImGroupMapper groupMapper;
    @Autowired
    private ImGroupMemberMapper groupMemberMapper;

    @Override
    @Transactional
    public ImGroup createGroup(Long ownerId, String name, List<Long> initialMembers) {
        List<Long> memberIds = initialMembers == null ? List.of()
                : initialMembers.stream()
                        .filter(memberId -> memberId != null && !memberId.equals(ownerId))
                        .distinct()
                        .collect(Collectors.toList());

        ImGroup group = new ImGroup();
        group.setOwnerId(ownerId);
        String groupName = resolveGroupName(name, ownerId, memberIds);
        group.setName(groupName);
        group.setMemberCount(memberIds.size() + 1);
        group.setCreatedAt(LocalDateTime.now());
        groupMapper.insert(group);

        // Add owner
        ImGroupMember ownerMember = new ImGroupMember();
        ownerMember.setGroupId(group.getId());
        ownerMember.setUserId(ownerId);
        ownerMember.setRole(2); // Owner
        ownerMember.setJoinTime(LocalDateTime.now());
        groupMemberMapper.insert(ownerMember);

        // Add members
        for (Long memberId : memberIds) {
            ImGroupMember member = new ImGroupMember();
            member.setGroupId(group.getId());
            member.setUserId(memberId);
            member.setRole(0);
            member.setJoinTime(LocalDateTime.now());
            groupMemberMapper.insert(member);

            // Create Conversation for Member
            createGroupConversation(memberId, group.getId(), groupName);
        }

        // Create Conversation for Owner (skipped in loop)
        createGroupConversation(ownerId, group.getId(), groupName);
        return group;
    }

    @Autowired
    private com.example.urgs_api.im.mapper.ImConversationMapper conversationMapper;

    private void createGroupConversation(Long userId, Long groupId, String groupName) {
        Long existingCount = conversationMapper.selectCount(new QueryWrapper<com.example.urgs_api.im.entity.ImConversation>()
                .eq("user_id", userId)
                .eq("peer_id", groupId)
                .eq("chat_type", 2));
        if (existingCount != null && existingCount > 0) {
            conversationMapper.update(null, new UpdateWrapper<com.example.urgs_api.im.entity.ImConversation>()
                    .eq("user_id", userId)
                    .eq("peer_id", groupId)
                    .eq("chat_type", 2)
                    .set("name", groupName)
                    .set("is_hidden", false));
            return;
        }

        com.example.urgs_api.im.entity.ImConversation conversation = new com.example.urgs_api.im.entity.ImConversation();
        conversation.setUserId(userId);
        conversation.setPeerId(groupId);
        conversation.setChatType(2); // Group
        conversation.setName(groupName); // Might be redundant if getSessionList handles dynamic names
        conversation.setLastMsgTime(LocalDateTime.now());
        conversation.setLastMsgContent("Group Created");
        conversation.setUnreadCount(0);
        conversation.setIsTop(false);
        conversation.setIsHidden(false);
        conversationMapper.insert(conversation);
    }

    @Override
    public List<ImGroup> getUserGroups(Long userId) {
        // This requires a join, for simplicity using simple query logic or custom SQL
        // in XML
        // Here we simulate by finding group IDs then fetching groups
        List<ImGroupMember> members = groupMemberMapper
                .selectList(new QueryWrapper<ImGroupMember>().eq("user_id", userId));
        if (members.isEmpty())
            return List.of();

        List<Long> groupIds = members.stream().map(ImGroupMember::getGroupId).collect(Collectors.toList());
        return groupMapper.selectBatchIds(groupIds);
    }

    @Autowired
    private com.example.urgs_api.im.service.ImUserService userService;

    @Override
    public List<com.example.urgs_api.im.entity.ImUser> getGroupMembers(Long groupId) {
        List<ImGroupMember> members = groupMemberMapper
                .selectList(new QueryWrapper<ImGroupMember>().eq("group_id", groupId));
        if (members.isEmpty())
            return List.of();

        List<Long> userIds = members.stream().map(ImGroupMember::getUserId).collect(Collectors.toList());
        // Batch fetch users
        return userIds.stream().map(uid -> userService.getUser(uid)).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void renameGroup(Long requesterId, Long groupId, String name) {
        String groupName = name == null ? "" : name.trim();
        if (groupName.isEmpty()) {
            throw new RuntimeException("Group name cannot be empty");
        }

        ImGroup group = groupMapper.selectById(groupId);
        if (group == null) {
            throw new RuntimeException("Group not found");
        }

        Long count = groupMemberMapper.selectCount(new QueryWrapper<ImGroupMember>()
                .eq("group_id", groupId)
                .eq("user_id", requesterId));
        if (count == null || count == 0) {
            throw new RuntimeException("Only group members can rename group");
        }

        group.setName(truncateGroupName(groupName));
        groupMapper.updateById(group);

        com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<com.example.urgs_api.im.entity.ImConversation> update = new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<>();
        update.eq("peer_id", groupId)
                .eq("chat_type", 2)
                .set("name", group.getName());
        conversationMapper.update(null, update);
    }

    private String resolveGroupName(String name, Long ownerId, List<Long> memberIds) {
        if (name != null && !name.trim().isEmpty()) {
            return truncateGroupName(name.trim());
        }
        List<Long> userIds = new java.util.ArrayList<>();
        userIds.add(ownerId);
        userIds.addAll(memberIds);
        List<String> names = userIds.stream()
                .map(this::resolveUserDisplayName)
                .filter(displayName -> displayName != null && !displayName.isBlank())
                .distinct()
                .collect(Collectors.toList());
        if (names.isEmpty()) {
            return "群聊";
        }
        int visibleCount = Math.min(names.size(), 4);
        String baseName = String.join("、", names.subList(0, visibleCount));
        if (names.size() > visibleCount) {
            baseName = baseName + "等" + names.size() + "人";
        }
        return truncateGroupName(baseName);
    }

    private String resolveUserDisplayName(Long userId) {
        com.example.urgs_api.im.entity.ImUser user = userService.getUser(userId);
        if (user == null) {
            return "用户" + userId;
        }
        if (user.getName() != null && !user.getName().isBlank()) {
            return user.getName();
        }
        if (user.getWxId() != null && !user.getWxId().isBlank()) {
            return user.getWxId();
        }
        if (user.getEmpId() != null && !user.getEmpId().isBlank()) {
            return user.getEmpId();
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

    @Autowired
    private com.example.urgs_api.im.service.ImChatService chatService;

    @Override
    @Transactional
    public void addMembers(Long requesterId, Long groupId, List<Long> memberIds) {
        ImGroup group = groupMapper.selectById(groupId);
        if (group == null) {
            throw new RuntimeException("Group not found");
        }

        String requesterName = resolveUserDisplayName(requesterId);
        for (Long memberId : memberIds) {
            QueryWrapper<ImGroupMember> query = new QueryWrapper<>();
            query.eq("group_id", groupId).eq("user_id", memberId);
            if (groupMemberMapper.selectCount(query) > 0) {
                continue;
            }

            ImGroupMember member = new ImGroupMember();
            member.setGroupId(groupId);
            member.setUserId(memberId);
            member.setRole(0);
            member.setJoinTime(LocalDateTime.now());
            groupMemberMapper.insert(member);

            createGroupConversation(memberId, groupId, group.getName());
            String memberName = resolveUserDisplayName(memberId);
            chatService.sendSystemMessage(groupId,
                    "\"" + requesterName + "\" 邀请 \"" + memberName + "\" 加入了群聊");
        }
    }

    @Override
    @Transactional
    public void removeMembers(Long requesterId, Long groupId, List<Long> memberIds) {
        ImGroup group = groupMapper.selectById(groupId);
        if (group == null)
            throw new RuntimeException("Group not found");

        if (!group.getOwnerId().equals(requesterId)) {
            throw new RuntimeException("Only owner can remove members");
        }

        for (Long uid : memberIds) {
            // Cannot remove owner
            if (uid.equals(group.getOwnerId()))
                continue;

            QueryWrapper<ImGroupMember> query = new QueryWrapper<>();
            query.eq("group_id", groupId).eq("user_id", uid);
            groupMemberMapper.delete(query);

            // Send System Notification
            // Ideally fetch user name, for now use ID or simple message
            chatService.sendSystemMessage(groupId, "用户 " + uid + " 被移出群聊");

            // Also delete conversation for the removed user
            com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<com.example.urgs_api.im.entity.ImConversation> convQuery = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
            convQuery.eq("user_id", uid).eq("peer_id", groupId);
            conversationMapper.delete(convQuery);
        }
    }
}
