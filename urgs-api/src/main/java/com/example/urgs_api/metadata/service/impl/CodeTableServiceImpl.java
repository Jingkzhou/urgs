package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.CodeTableMapper;
import com.example.urgs_api.metadata.model.CodeTable;
import com.example.urgs_api.metadata.service.CodeTableService;
import org.springframework.stereotype.Service;

@Service
/**
 * 码表服务实现类
 */
public class CodeTableServiceImpl extends ServiceImpl<CodeTableMapper, CodeTable> implements CodeTableService {
}
