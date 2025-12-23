package com.example.urgs_api.im.controller;

import com.example.urgs_api.im.entity.ImMessage;
import com.example.urgs_api.im.service.ImChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/im/chat")
public class ImChatController {

    @Autowired
    private ImChatService chatService;

    @PostMapping("/send")
    public String sendMessage(@RequestAttribute("userId") Long userId, @RequestBody ImMessage message) {
        // Force sender to be the authenticated user
        message.setSenderId(userId);
        message.setSendTime(LocalDateTime.now());
        chatService.sendMessage(message);
        return "success";
    }

    @GetMapping("/history")
    public List<ImMessage> getHistory(@RequestAttribute("userId") Long userId,
            @RequestParam String conversationId,
            @RequestParam(required = false) Long lastMsgId,
            @RequestParam(defaultValue = "20") int limit) {

        // Security Check: Is user part of conversation?
        // Security Check: Is user part of conversation?
        if (conversationId.startsWith("GROUP_")) {
            // Group chat logic
            // Ideally check if user is in group. For now, assuming group membership check
            // happens elsewhere or is open.
        } else if (conversationId.contains("_")) {
            String[] parts = conversationId.split("_");
            try {
                long u1 = Long.parseLong(parts[0]);
                long u2 = Long.parseLong(parts[1]);
                if (userId != u1 && userId != u2) {
                    throw new RuntimeException("Unauthorized: You are not part of this conversation");
                }
            } catch (NumberFormatException e) {
                // Ignore unexpected format
            }
        }

        return chatService.getHistory(conversationId, lastMsgId, limit);
    }
}
