package com.example.urgs_api.im.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
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
        ImGroup group = new ImGroup();
        group.setOwnerId(ownerId);
        group.setName(name);
        group.setMemberCount(initialMembers.size() + 1);
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
        for (Long memberId : initialMembers) {
            // Owner already added with Role 2
            if (memberId.equals(ownerId)) {
                continue;
            }
            ImGroupMember member = new ImGroupMember();
            member.setGroupId(group.getId());
            member.setUserId(memberId);
            member.setRole(0);
            member.setJoinTime(LocalDateTime.now());
            groupMemberMapper.insert(member);

            // Create Conversation for Member
            createGroupConversation(memberId, group.getId(), name);
        }

        // Create Conversation for Owner (skipped in loop)
        createGroupConversation(ownerId, group.getId(), name);
        return group;
    }

    @Autowired
    private com.example.urgs_api.im.mapper.ImConversationMapper conversationMapper;

    private void createGroupConversation(Long userId, Long groupId, String groupName) {
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

    @Autowired
    private com.example.urgs_api.im.service.ImChatService chatService;

    @Override
    @Transactional
    public void addMembers(Long groupId, List<Long> memberIds) {
        ImGroup group = groupMapper.selectById(groupId);
        if (group == null) {
            throw new RuntimeException("Group not found");
        }

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
            chatService.sendSystemMessage(groupId, "用户 " + memberId + " 加入群聊");
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
