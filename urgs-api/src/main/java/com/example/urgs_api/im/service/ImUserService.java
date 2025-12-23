package com.example.urgs_api.im.service;

import com.example.urgs_api.im.entity.ImFriendship;
import com.example.urgs_api.im.entity.ImUser;
import java.util.List;

public interface ImUserService {
    ImUser getUser(Long userId);

    void addFriend(Long userId, Long friendId, String remark);

    List<ImFriendship> getFriendList(Long userId);

    List<ImUser> getAllUsers();

    List<ImUser> searchUsers(String keyword);
}
