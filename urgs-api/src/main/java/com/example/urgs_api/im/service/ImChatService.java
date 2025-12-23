package com.example.urgs_api.im.service;

import com.example.urgs_api.im.entity.ImMessage;
import java.util.List;

public interface ImChatService {
    void sendMessage(ImMessage message);

    List<ImMessage> getHistory(String conversationId, Long lastMsgId, int limit);

    void sendSystemMessage(Long groupId, String content);
}
