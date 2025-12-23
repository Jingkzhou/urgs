package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.MaintenanceRecordMapper;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.service.MaintenanceRecordService;
import org.springframework.stereotype.Service;

@Service
/**
 * 维护记录服务实现类
 */
public class MaintenanceRecordServiceImpl extends ServiceImpl<MaintenanceRecordMapper, MaintenanceRecord>
                implements MaintenanceRecordService {
}
