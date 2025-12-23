package com.example.urgs_api.org.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.org.mapper.OrgMapper;
import com.example.urgs_api.org.model.Org;
import com.example.urgs_api.org.service.OrgService;
import org.springframework.stereotype.Service;

@Service
public class OrgServiceImpl extends ServiceImpl<OrgMapper, Org> implements OrgService {
}
