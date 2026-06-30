package com.example.urgs_api.im.service;

import com.example.urgs_api.im.entity.ImConversation;
import java.util.List;

public interface ImSessionService {
    List<ImConversation> getSessionList(Long userId);

    void updateSession(Long userId, Long peerId, String content);

    void clearUnread(Long userId, Long peerId, Integer chatType);

    void deleteSession(Long userId, Long peerId, Integer chatType);

    void updateSettings(Long userId, Long peerId, Integer chatType, Boolean isTop, Boolean isMuted);

    void clearHistory(Long userId, Long peerId, Integer chatType);

    Long getClearedBeforeMsgId(Long userId, Long peerId, Integer chatType);
}
