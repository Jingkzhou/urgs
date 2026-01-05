package com.example.urgs_api.system.controller;

import com.example.urgs_api.system.model.SysSystem;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/sys/system")
public class SysSystemController {

    @Autowired
    private com.example.urgs_api.system.service.SysSystemService sysSystemService;

    @Autowired
    private jakarta.servlet.http.HttpServletRequest request;

    @GetMapping("/list")
    public List<SysSystem> list() {
        Long userId = (Long) request.getAttribute("userId");
        return sysSystemService.list(userId);
    }
}
