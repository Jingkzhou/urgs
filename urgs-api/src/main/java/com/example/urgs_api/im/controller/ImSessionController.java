package com.example.urgs_api.im.controller;

import com.example.urgs_api.im.service.ImSessionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/im/session")
public class ImSessionController {

    @Autowired
    private ImSessionService sessionService;

    @PostMapping("/{peerId}/read")
    public String markRead(@RequestAttribute("userId") Long userId, @PathVariable Long peerId,
            @RequestParam(required = false) Integer chatType) {
        sessionService.clearUnread(userId, peerId, chatType);
        return "success";
    }

    @DeleteMapping("/{peerId}")
    public String deleteSession(@RequestAttribute("userId") Long userId, @PathVariable Long peerId,
            @RequestParam(required = false) Integer chatType) {
        sessionService.deleteSession(userId, peerId, chatType);
        return "success";
    }
}
