package com.example.urgs_api.im.service;

import com.example.urgs_api.im.entity.ImGroup;
import java.util.List;

public interface ImGroupService {
    ImGroup createGroup(Long ownerId, String name, List<Long> initialMembers);

    List<ImGroup> getUserGroups(Long userId);

    List<com.example.urgs_api.im.entity.ImUser> getGroupMembers(Long groupId);

    void addMembers(Long groupId, List<Long> memberIds);

    void removeMembers(Long requesterId, Long groupId, List<Long> memberIds);
}
