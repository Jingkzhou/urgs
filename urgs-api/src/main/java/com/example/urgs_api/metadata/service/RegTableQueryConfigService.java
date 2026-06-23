package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.metadata.dto.RegElementQueryConfigValidationResult;
import com.example.urgs_api.metadata.dto.RegTableQueryConfigDTO;
import com.example.urgs_api.metadata.model.RegTableQueryConfig;

public interface RegTableQueryConfigService extends IService<RegTableQueryConfig> {
    RegTableQueryConfigDTO getByTableId(Long tableId);

    RegTableQueryConfigDTO saveForTable(Long tableId, RegTableQueryConfigDTO request);

    RegElementQueryConfigValidationResult validateForTable(Long tableId, RegTableQueryConfigDTO request);

    void removeByTableId(Long tableId);
}
