package com.example.urgs_api.im.service;

import com.example.urgs_api.im.entity.ImMessage;
import com.example.urgs_api.im.vo.ImMessageVO;
import java.util.List;

public interface ImChatService {
    void sendMessage(ImMessage message);

    List<ImMessageVO> getHistory(String conversationId, Long lastMsgId, int limit);

    void sendSystemMessage(Long groupId, String content);
}
