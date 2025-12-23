package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.RegulatoryAssetMapper;
import com.example.urgs_api.metadata.model.RegulatoryAsset;
import com.example.urgs_api.metadata.service.RegulatoryAssetService;
import org.springframework.stereotype.Service;

@Service
/**
 * 监管资产服务实现类
 */
public class RegulatoryAssetServiceImpl extends ServiceImpl<RegulatoryAssetMapper, RegulatoryAsset>
                implements RegulatoryAssetService {
}
