package com.example.urgs_api.system.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.system.mapper.SysSystemMapper;
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
    private SysSystemMapper sysSystemMapper;

    @GetMapping("/list")
    public List<SysSystem> list() {
        return sysSystemMapper.selectList(new QueryWrapper<SysSystem>().orderByAsc("id"));
    }
}
