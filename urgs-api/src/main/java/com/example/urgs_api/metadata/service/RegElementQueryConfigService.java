package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.metadata.dto.RegElementQueryConfigDTO;
import com.example.urgs_api.metadata.dto.RegElementQueryConfigValidationResult;
import com.example.urgs_api.metadata.model.RegElementQueryConfig;

public interface RegElementQueryConfigService extends IService<RegElementQueryConfig> {
    RegElementQueryConfigDTO getByElementId(Long elementId);

    RegElementQueryConfigDTO saveForElement(Long elementId, RegElementQueryConfigDTO request);

    RegElementQueryConfigValidationResult validateForElement(Long elementId, RegElementQueryConfigDTO request);

    void removeByElementId(Long elementId);
}
