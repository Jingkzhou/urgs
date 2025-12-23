package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.RegElementMapper;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.service.RegElementService;
import org.springframework.stereotype.Service;

@Service
/**
 * 监管元素服务实现类
 */
public class RegElementServiceImpl extends ServiceImpl<RegElementMapper, RegElement> implements RegElementService {
}
