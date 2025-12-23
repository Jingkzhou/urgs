package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.RegTableMapper;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.metadata.service.RegTableService;
import org.springframework.stereotype.Service;

@Service
/**
 * 监管报表服务实现类
 */
public class RegTableServiceImpl extends ServiceImpl<RegTableMapper, RegTable> implements RegTableService {
}
