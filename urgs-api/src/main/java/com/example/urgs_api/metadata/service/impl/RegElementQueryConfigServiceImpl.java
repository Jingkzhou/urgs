package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.metadata.dto.RegElementQueryConfigDTO;
import com.example.urgs_api.metadata.dto.RegElementQueryConfigValidationResult;
import com.example.urgs_api.metadata.mapper.RegElementQueryConfigMapper;
import com.example.urgs_api.metadata.mapper.RegTableModelTableRelMapper;
import com.example.urgs_api.metadata.model.ModelField;
import com.example.urgs_api.metadata.model.ModelTable;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegElementQueryConfig;
import com.example.urgs_api.metadata.model.RegTableModelTableRel;
import com.example.urgs_api.metadata.service.ModelFieldService;
import com.example.urgs_api.metadata.service.ModelTableService;
import com.example.urgs_api.metadata.service.RegElementQueryConfigService;
import com.example.urgs_api.metadata.service.RegElementService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class RegElementQueryConfigServiceImpl
        extends ServiceImpl<RegElementQueryConfigMapper, RegElementQueryConfig>
        implements RegElementQueryConfigService {

    private static final TypeReference<List<String>> STRING_LIST_TYPE = new TypeReference<>() {
    };
    private static final Set<String> QUERY_MODES = Set.of("SUMMARY", "DETAIL");

    private final ObjectMapper objectMapper;
    private final RegElementService regElementService;
    private final ModelTableService modelTableService;
    private final ModelFieldService modelFieldService;
    private final RegTableModelTableRelMapper tableRelMapper;
    private final DataSourceConfigMapper dataSourceConfigMapper;

    public RegElementQueryConfigServiceImpl(
            ObjectMapper objectMapper,
            RegElementService regElementService,
            ModelTableService modelTableService,
            ModelFieldService modelFieldService,
            RegTableModelTableRelMapper tableRelMapper,
            DataSourceConfigMapper dataSourceConfigMapper) {
        this.objectMapper = objectMapper;
        this.regElementService = regElementService;
        this.modelTableService = modelTableService;
        this.modelFieldService = modelFieldService;
        this.tableRelMapper = tableRelMapper;
        this.dataSourceConfigMapper = dataSourceConfigMapper;
    }

    @Override
    public RegElementQueryConfigDTO getByElementId(Long elementId) {
        RegElementQueryConfig config = getOne(new LambdaQueryWrapper<RegElementQueryConfig>()
                .eq(RegElementQueryConfig::getRegElementId, elementId), false);
        if (config == null) {
            RegElementQueryConfigDTO dto = new RegElementQueryConfigDTO();
            dto.setRegElementId(elementId);
            return dto;
        }
        return toDTO(config);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public RegElementQueryConfigDTO saveForElement(Long elementId, RegElementQueryConfigDTO request) {
        RegElementQueryConfigDTO normalized = normalizeDTO(elementId, request);
        RegElementQueryConfigValidationResult validation = validateForElement(elementId, normalized);
        if (normalized.getEnabled() != null && normalized.getEnabled() == 1 && !validation.isValid()) {
            throw new IllegalArgumentException(String.join("；", validation.getErrors()));
        }

        RegElementQueryConfig existing = getOne(new LambdaQueryWrapper<RegElementQueryConfig>()
                .eq(RegElementQueryConfig::getRegElementId, elementId), false);
        RegElementQueryConfig entity = existing == null ? new RegElementQueryConfig() : existing;
        copyToEntity(normalized, entity);
        if (entity.getCreateTime() == null) {
            entity.setCreateTime(LocalDateTime.now());
        }
        entity.setUpdateTime(LocalDateTime.now());
        saveOrUpdate(entity);
        return toDTO(entity);
    }

    @Override
    public RegElementQueryConfigValidationResult validateForElement(
            Long elementId, RegElementQueryConfigDTO request) {
        RegElementQueryConfigValidationResult result = RegElementQueryConfigValidationResult.ok();
        RegElement element = regElementService.getById(elementId);
        if (element == null) {
            result.addError("监管字段/指标不存在");
            return result;
        }
        if (!"INDICATOR".equalsIgnoreCase(StringUtils.defaultString(element.getType()))) {
            result.addError("只有指标类型可以配置查询");
            return result;
        }

        RegElementQueryConfigDTO dto = normalizeDTO(elementId, request);
        if (dto.getEnabled() == null || dto.getEnabled() != 1) {
            result.addWarning("查询配置未启用，仅保存为草稿");
            return result;
        }

        if (!QUERY_MODES.contains(dto.getQueryMode())) {
            result.addError("查询模式只支持 SUMMARY 或 DETAIL");
        }
        if (dto.getDataSourceId() == null) {
            result.addError("数据源不能为空");
        } else {
            DataSourceConfig dataSource = dataSourceConfigMapper.selectById(dto.getDataSourceId());
            if (dataSource == null) {
                result.addError("数据源不存在");
            }
        }
        if (dto.getDetailMaxRows() == null || dto.getDetailMaxRows() < 1 || dto.getDetailMaxRows() > 5) {
            result.addError("明细最大返回行数必须在 1 到 5 之间");
        }
        if (StringUtils.isBlank(dto.getModelTableId())) {
            result.addError("主查询物理表不能为空");
            return result;
        }

        ModelTable table = modelTableService.getById(dto.getModelTableId());
        if (table == null) {
            result.addError("主查询物理表不存在");
            return result;
        }
        if (dto.getDataSourceId() != null && !Objects.equals(table.getDataSourceId(), dto.getDataSourceId())) {
            result.addError("主查询物理表不属于所选数据源");
        }
        boolean boundToRegTable = tableRelMapper.selectCount(new LambdaQueryWrapper<RegTableModelTableRel>()
                .eq(RegTableModelTableRel::getRegTableId, element.getTableId())
                .eq(RegTableModelTableRel::getModelTableId, dto.getModelTableId())) > 0;
        if (!boundToRegTable) {
            result.addError("主查询物理表未绑定到该监管报表");
        }

        List<ModelField> fields = modelFieldService.getFieldsByTableId(dto.getModelTableId());
        Map<String, ModelField> fieldMap = fields.stream()
                .collect(Collectors.toMap(ModelField::getId, Function.identity(), (a, b) -> a));
        requireField(result, fieldMap, dto.getDateFieldId(), "日期字段");
        requireField(result, fieldMap, dto.getOrgCodeFieldId(), "机构编号字段");
        requireField(result, fieldMap, dto.getValueFieldId(), "指标值字段");
        optionalField(result, fieldMap, dto.getOrgNameFieldId(), "机构名称字段");
        optionalField(result, fieldMap, dto.getMetricCodeFieldId(), "指标编号字段");
        requireFieldList(result, fieldMap, dto.getDefaultReturnFieldIds(), "默认返回字段");
        validateFieldList(result, fieldMap, dto.getFilterFieldIds(), "允许筛选字段");
        validateFieldList(result, fieldMap, dto.getSortFieldIds(), "允许排序字段");
        validateFieldList(result, fieldMap, dto.getMaskFieldIds(), "脱敏字段");
        return result;
    }

    @Override
    public void removeByElementId(Long elementId) {
        remove(new LambdaQueryWrapper<RegElementQueryConfig>()
                .eq(RegElementQueryConfig::getRegElementId, elementId));
    }

    private void requireField(
            RegElementQueryConfigValidationResult result,
            Map<String, ModelField> fields,
            String fieldId,
            String label) {
        if (StringUtils.isBlank(fieldId)) {
            result.addError(label + "不能为空");
            return;
        }
        optionalField(result, fields, fieldId, label);
    }

    private void optionalField(
            RegElementQueryConfigValidationResult result,
            Map<String, ModelField> fields,
            String fieldId,
            String label) {
        if (StringUtils.isBlank(fieldId)) {
            return;
        }
        if (!fields.containsKey(fieldId)) {
            result.addError(label + "不属于主查询物理表");
        }
    }

    private void requireFieldList(
            RegElementQueryConfigValidationResult result,
            Map<String, ModelField> fields,
            List<String> fieldIds,
            String label) {
        if (fieldIds == null || fieldIds.isEmpty()) {
            result.addError(label + "不能为空");
            return;
        }
        validateFieldList(result, fields, fieldIds, label);
    }

    private void validateFieldList(
            RegElementQueryConfigValidationResult result,
            Map<String, ModelField> fields,
            List<String> fieldIds,
            String label) {
        for (String fieldId : fieldIds == null ? List.<String>of() : fieldIds) {
            if (!fields.containsKey(fieldId)) {
                result.addError(label + "包含不属于主查询物理表的字段: " + fieldId);
            }
        }
    }

    private RegElementQueryConfigDTO normalizeDTO(Long elementId, RegElementQueryConfigDTO request) {
        RegElementQueryConfigDTO dto = request == null ? new RegElementQueryConfigDTO() : request;
        dto.setRegElementId(elementId);
        dto.setEnabled(dto.getEnabled() != null && dto.getEnabled() == 1 ? 1 : 0);
        dto.setQueryMode(StringUtils.defaultIfBlank(dto.getQueryMode(), "SUMMARY").trim().toUpperCase());
        dto.setModelTableId(blankToNull(dto.getModelTableId()));
        dto.setDateFieldId(blankToNull(dto.getDateFieldId()));
        dto.setOrgCodeFieldId(blankToNull(dto.getOrgCodeFieldId()));
        dto.setOrgNameFieldId(blankToNull(dto.getOrgNameFieldId()));
        dto.setMetricCodeFieldId(blankToNull(dto.getMetricCodeFieldId()));
        dto.setValueFieldId(blankToNull(dto.getValueFieldId()));
        dto.setDefaultReturnFieldIds(normalizeList(dto.getDefaultReturnFieldIds()));
        dto.setFilterFieldIds(normalizeList(dto.getFilterFieldIds()));
        dto.setSortFieldIds(normalizeList(dto.getSortFieldIds()));
        dto.setMaskFieldIds(normalizeList(dto.getMaskFieldIds()));
        dto.setDetailMaxRows(dto.getDetailMaxRows() == null ? 5 : dto.getDetailMaxRows());
        return dto;
    }

    private List<String> normalizeList(List<String> values) {
        if (values == null) {
            return new ArrayList<>();
        }
        return values.stream()
                .map(this::blankToNull)
                .filter(Objects::nonNull)
                .collect(Collectors.collectingAndThen(
                        Collectors.toCollection(LinkedHashSet::new), ArrayList::new));
    }

    private String blankToNull(String value) {
        String trimmed = StringUtils.trimToNull(value);
        return trimmed == null ? null : trimmed;
    }

    private RegElementQueryConfigDTO toDTO(RegElementQueryConfig entity) {
        RegElementQueryConfigDTO dto = new RegElementQueryConfigDTO();
        dto.setId(entity.getId());
        dto.setRegElementId(entity.getRegElementId());
        dto.setEnabled(entity.getEnabled());
        dto.setQueryMode(entity.getQueryMode());
        dto.setDataSourceId(entity.getDataSourceId());
        dto.setModelTableId(entity.getModelTableId());
        dto.setDateFieldId(entity.getDateFieldId());
        dto.setOrgCodeFieldId(entity.getOrgCodeFieldId());
        dto.setOrgNameFieldId(entity.getOrgNameFieldId());
        dto.setMetricCodeFieldId(entity.getMetricCodeFieldId());
        dto.setValueFieldId(entity.getValueFieldId());
        dto.setDefaultReturnFieldIds(readList(entity.getDefaultReturnFieldIds()));
        dto.setFilterFieldIds(readList(entity.getFilterFieldIds()));
        dto.setSortFieldIds(readList(entity.getSortFieldIds()));
        dto.setMaskFieldIds(readList(entity.getMaskFieldIds()));
        dto.setDetailMaxRows(entity.getDetailMaxRows());
        return dto;
    }

    private void copyToEntity(RegElementQueryConfigDTO dto, RegElementQueryConfig entity) {
        entity.setRegElementId(dto.getRegElementId());
        entity.setEnabled(dto.getEnabled());
        entity.setQueryMode(dto.getQueryMode());
        entity.setDataSourceId(dto.getDataSourceId());
        entity.setModelTableId(dto.getModelTableId());
        entity.setDateFieldId(dto.getDateFieldId());
        entity.setOrgCodeFieldId(dto.getOrgCodeFieldId());
        entity.setOrgNameFieldId(dto.getOrgNameFieldId());
        entity.setMetricCodeFieldId(dto.getMetricCodeFieldId());
        entity.setValueFieldId(dto.getValueFieldId());
        entity.setDefaultReturnFieldIds(writeList(dto.getDefaultReturnFieldIds()));
        entity.setFilterFieldIds(writeList(dto.getFilterFieldIds()));
        entity.setSortFieldIds(writeList(dto.getSortFieldIds()));
        entity.setMaskFieldIds(writeList(dto.getMaskFieldIds()));
        entity.setDetailMaxRows(dto.getDetailMaxRows());
    }

    private List<String> readList(String value) {
        if (StringUtils.isBlank(value)) {
            return new ArrayList<>();
        }
        try {
            return normalizeList(objectMapper.readValue(value, STRING_LIST_TYPE));
        } catch (JsonProcessingException e) {
            return new ArrayList<>();
        }
    }

    private String writeList(List<String> values) {
        try {
            return objectMapper.writeValueAsString(normalizeList(values));
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("字段列表无法序列化", e);
        }
    }
}
