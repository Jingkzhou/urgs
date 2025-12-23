package com.example.urgs_api.im.controller;

import com.example.urgs_api.im.entity.ImFriendship;
import com.example.urgs_api.im.entity.ImGroup;
import com.example.urgs_api.im.entity.ImUser;
import com.example.urgs_api.im.service.ImGroupService;
import com.example.urgs_api.im.service.ImUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/im")
public class ImDataController {

    @Autowired
    private ImUserService userService;
    @Autowired
    private ImGroupService groupService;
    @Autowired
    private com.example.urgs_api.im.service.ImSessionService sessionService;

    // User Related
    @GetMapping("/user/me")
    public ImUser getMyInfo(@RequestAttribute("userId") Long userId) {
        return userService.getUser(userId);
    }

    public ImUser getUser(@PathVariable Long id) {
        return userService.getUser(id);
    }

    @GetMapping("/users")
    public List<ImUser> getAllUsers() {
        return userService.getAllUsers();
    }

    @GetMapping("/users/search")
    public List<ImUser> searchUsers(@RequestParam(required = false) String keyword) {
        return userService.searchUsers(keyword);
    }

    @GetMapping("/friends")
    public List<ImFriendship> getFriends(@RequestAttribute("userId") Long userId) {
        return userService.getFriendList(userId);
    }

    @PostMapping("/friend/add")
    public String addFriend(@RequestAttribute("userId") Long userId, @RequestParam Long friendId,
            @RequestParam String remark) {
        userService.addFriend(userId, friendId, remark);
        return "success";
    }

    // Group Related
    @PostMapping("/group/create")
    public ImGroup createGroup(@RequestAttribute("userId") Long userId, @RequestBody CreateGroupRequest request) {
        String name = request.getName();
        List<Long> members = request.getMembers();

        // Ensure creator is in members
        if (members == null)
            members = new java.util.ArrayList<>();
        if (!members.contains(userId)) {
            members.add(userId);
        }
        // Default name if empty
        if (name == null || name.isEmpty()) {
            name = "Unnamed Group";
        }
        return groupService.createGroup(userId, name, members);
    }

    @lombok.Data
    public static class CreateGroupRequest {
        private String name;
        private List<Long> members;
    }

    @PostMapping("/group/addMembers")
    public String addMembers(@RequestBody AddMembersRequest request) {
        groupService.addMembers(request.getGroupId(), request.getMemberIds());
        return "success";
    }

    @lombok.Data
    public static class AddMembersRequest {
        private Long groupId;
        private List<Long> memberIds;
    }

    @PostMapping("/group/kick")
    public String kickMembers(@RequestAttribute("userId") Long userId, @RequestBody AddMembersRequest request) {
        groupService.removeMembers(userId, request.getGroupId(), request.getMemberIds());
        return "success";
    }

    @GetMapping("/groups")
    public List<ImGroup> getGroups(@RequestAttribute("userId") Long userId) {
        return groupService.getUserGroups(userId);
    }

    @GetMapping("/group/{groupId}/members")
    public List<ImUser> getGroupMembers(@PathVariable Long groupId) {
        return groupService.getGroupMembers(groupId);
    }

    @GetMapping("/sessions")
    public List<com.example.urgs_api.im.entity.ImConversation> getSessions(@RequestAttribute("userId") Long userId) {
        return sessionService.getSessionList(userId);
    }
}
