package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.dto.PhysicalFieldBindingDTO;
import com.example.urgs_api.metadata.dto.PhysicalTableBindingDTO;
import com.example.urgs_api.metadata.mapper.RegElementModelFieldRelMapper;
import com.example.urgs_api.metadata.mapper.RegTableModelTableRelMapper;
import com.example.urgs_api.metadata.model.ModelField;
import com.example.urgs_api.metadata.model.ModelTable;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegElementModelFieldRel;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.metadata.model.RegTableModelTableRel;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class RegPhysicalBindingService {
    private final RegTableModelTableRelMapper tableRelMapper;
    private final RegElementModelFieldRelMapper fieldRelMapper;
    private final ModelTableService modelTableService;
    private final ModelFieldService modelFieldService;

    public RegPhysicalBindingService(
            RegTableModelTableRelMapper tableRelMapper,
            RegElementModelFieldRelMapper fieldRelMapper,
            ModelTableService modelTableService,
            ModelFieldService modelFieldService) {
        this.tableRelMapper = tableRelMapper;
        this.fieldRelMapper = fieldRelMapper;
        this.modelTableService = modelTableService;
        this.modelFieldService = modelFieldService;
    }

    public void enrichTables(List<RegTable> tables) {
        if (tables == null || tables.isEmpty()) {
            return;
        }
        List<Long> regTableIds = tables.stream().map(RegTable::getId).filter(Objects::nonNull).toList();
        Map<Long, List<PhysicalTableBindingDTO>> bindings = listTableBindings(regTableIds);
        tables.forEach(table -> table.setPhysicalTables(bindings.getOrDefault(table.getId(), Collections.emptyList())));
    }

    public void enrichTable(RegTable table) {
        if (table == null || table.getId() == null) {
            return;
        }
        table.setPhysicalTables(listTableBindings(List.of(table.getId())).getOrDefault(table.getId(), Collections.emptyList()));
    }

    public void enrichElements(List<RegElement> elements) {
        if (elements == null || elements.isEmpty()) {
            return;
        }
        List<Long> regElementIds = elements.stream().map(RegElement::getId).filter(Objects::nonNull).toList();
        Map<Long, List<PhysicalFieldBindingDTO>> bindings = listFieldBindings(regElementIds);
        elements.forEach(element -> element.setPhysicalFields(bindings.getOrDefault(element.getId(), Collections.emptyList())));
    }

    public void enrichElement(RegElement element) {
        if (element == null || element.getId() == null) {
            return;
        }
        element.setPhysicalFields(listFieldBindings(List.of(element.getId())).getOrDefault(element.getId(), Collections.emptyList()));
    }

    public void replaceTableBindings(Long regTableId, List<PhysicalTableBindingDTO> physicalTables) {
        if (regTableId == null) {
            return;
        }
        tableRelMapper.delete(new LambdaQueryWrapper<RegTableModelTableRel>()
                .eq(RegTableModelTableRel::getRegTableId, regTableId));

        List<String> modelTableIds = normalizeTableIds(physicalTables);
        if (modelTableIds.isEmpty()) {
            return;
        }
        LocalDateTime now = LocalDateTime.now();
        for (String modelTableId : modelTableIds) {
            RegTableModelTableRel rel = new RegTableModelTableRel();
            rel.setRegTableId(regTableId);
            rel.setModelTableId(modelTableId);
            rel.setCreateTime(now);
            tableRelMapper.insert(rel);
        }
    }

    public void replaceElementBindings(Long regElementId, List<PhysicalFieldBindingDTO> physicalFields) {
        if (regElementId == null) {
            return;
        }
        fieldRelMapper.delete(new LambdaQueryWrapper<RegElementModelFieldRel>()
                .eq(RegElementModelFieldRel::getRegElementId, regElementId));

        List<PhysicalFieldBindingDTO> normalized = normalizeFieldBindings(physicalFields);
        if (normalized.isEmpty()) {
            return;
        }
        LocalDateTime now = LocalDateTime.now();
        for (PhysicalFieldBindingDTO binding : normalized) {
            RegElementModelFieldRel rel = new RegElementModelFieldRel();
            rel.setRegElementId(regElementId);
            rel.setModelTableId(binding.getModelTableId());
            rel.setModelFieldId(binding.getModelFieldId());
            rel.setCreateTime(now);
            fieldRelMapper.insert(rel);
        }
    }

    public void removeTableBindings(List<Long> regTableIds) {
        if (regTableIds == null || regTableIds.isEmpty()) {
            return;
        }
        tableRelMapper.delete(new LambdaQueryWrapper<RegTableModelTableRel>()
                .in(RegTableModelTableRel::getRegTableId, regTableIds));
    }

    public void removeElementBindings(List<Long> regElementIds) {
        if (regElementIds == null || regElementIds.isEmpty()) {
            return;
        }
        fieldRelMapper.delete(new LambdaQueryWrapper<RegElementModelFieldRel>()
                .in(RegElementModelFieldRel::getRegElementId, regElementIds));
    }

    public List<PhysicalTableBindingDTO> resolveTableBindings(String value, List<String> skipped) {
        List<PhysicalTableBindingDTO> result = new ArrayList<>();
        for (String token : splitBindingValue(value)) {
            String[] parts = token.split("\\.", 2);
            if (parts.length != 2 || StringUtils.isAnyBlank(parts[0], parts[1])) {
                skipped.add(token);
                continue;
            }
            ModelTable table = findModelTable(parts[0].trim(), parts[1].trim());
            if (table == null) {
                skipped.add(token);
                continue;
            }
            result.add(toTableBinding(table));
        }
        return result;
    }

    public List<PhysicalFieldBindingDTO> resolveFieldBindings(String value, List<String> skipped) {
        List<PhysicalFieldBindingDTO> result = new ArrayList<>();
        for (String token : splitBindingValue(value)) {
            String[] parts = token.split("\\.", 3);
            if (parts.length != 3 || StringUtils.isAnyBlank(parts[0], parts[1], parts[2])) {
                skipped.add(token);
                continue;
            }
            ModelTable table = findModelTable(parts[0].trim(), parts[1].trim());
            if (table == null) {
                skipped.add(token);
                continue;
            }
            ModelField field = findModelField(table.getId(), parts[2].trim());
            if (field == null) {
                skipped.add(token);
                continue;
            }
            result.add(toFieldBinding(field, table));
        }
        return result;
    }

    public String formatTableBindings(List<PhysicalTableBindingDTO> bindings) {
        if (bindings == null || bindings.isEmpty()) {
            return null;
        }
        return bindings.stream()
                .map(binding -> joinQualified(binding.getOwner(), binding.getTableName()))
                .filter(StringUtils::isNotBlank)
                .collect(Collectors.joining(";"));
    }

    public String formatFieldBindings(List<PhysicalFieldBindingDTO> bindings) {
        if (bindings == null || bindings.isEmpty()) {
            return null;
        }
        return bindings.stream()
                .map(binding -> joinQualified(binding.getOwner(), binding.getTableName(), binding.getFieldName()))
                .filter(StringUtils::isNotBlank)
                .collect(Collectors.joining(";"));
    }

    private Map<Long, List<PhysicalTableBindingDTO>> listTableBindings(List<Long> regTableIds) {
        if (regTableIds == null || regTableIds.isEmpty()) {
            return Collections.emptyMap();
        }
        List<RegTableModelTableRel> rels = tableRelMapper.selectList(new LambdaQueryWrapper<RegTableModelTableRel>()
                .in(RegTableModelTableRel::getRegTableId, regTableIds)
                .orderByAsc(RegTableModelTableRel::getId));
        if (rels.isEmpty()) {
            return Collections.emptyMap();
        }
        List<String> modelTableIds = rels.stream().map(RegTableModelTableRel::getModelTableId).distinct().toList();
        Map<String, ModelTable> tableMap = modelTableService.listByIds(modelTableIds).stream()
                .collect(Collectors.toMap(ModelTable::getId, Function.identity(), (a, b) -> a));
        return rels.stream()
                .map(rel -> new java.util.AbstractMap.SimpleEntry<>(rel.getRegTableId(),
                        toTableBinding(tableMap.get(rel.getModelTableId()))))
                .filter(entry -> entry.getValue() != null)
                .collect(Collectors.groupingBy(Map.Entry::getKey,
                        Collectors.mapping(Map.Entry::getValue, Collectors.toList())));
    }

    private Map<Long, List<PhysicalFieldBindingDTO>> listFieldBindings(List<Long> regElementIds) {
        if (regElementIds == null || regElementIds.isEmpty()) {
            return Collections.emptyMap();
        }
        List<RegElementModelFieldRel> rels = fieldRelMapper.selectList(new LambdaQueryWrapper<RegElementModelFieldRel>()
                .in(RegElementModelFieldRel::getRegElementId, regElementIds)
                .orderByAsc(RegElementModelFieldRel::getId));
        if (rels.isEmpty()) {
            return Collections.emptyMap();
        }
        List<String> modelFieldIds = rels.stream().map(RegElementModelFieldRel::getModelFieldId).distinct().toList();
        List<String> modelTableIds = rels.stream().map(RegElementModelFieldRel::getModelTableId).distinct().toList();
        Map<String, ModelField> fieldMap = modelFieldService.listByIds(modelFieldIds).stream()
                .collect(Collectors.toMap(ModelField::getId, Function.identity(), (a, b) -> a));
        Map<String, ModelTable> tableMap = modelTableService.listByIds(modelTableIds).stream()
                .collect(Collectors.toMap(ModelTable::getId, Function.identity(), (a, b) -> a));
        return rels.stream()
                .map(rel -> new java.util.AbstractMap.SimpleEntry<>(rel.getRegElementId(),
                        toFieldBinding(fieldMap.get(rel.getModelFieldId()), tableMap.get(rel.getModelTableId()))))
                .filter(entry -> entry.getValue() != null)
                .collect(Collectors.groupingBy(Map.Entry::getKey,
                        Collectors.mapping(Map.Entry::getValue, Collectors.toList())));
    }

    private List<String> normalizeTableIds(List<PhysicalTableBindingDTO> physicalTables) {
        if (physicalTables == null) {
            return Collections.emptyList();
        }
        return physicalTables.stream()
                .map(PhysicalTableBindingDTO::getModelTableId)
                .filter(StringUtils::isNotBlank)
                .collect(Collectors.collectingAndThen(Collectors.toCollection(LinkedHashSet::new), ArrayList::new));
    }

    private List<PhysicalFieldBindingDTO> normalizeFieldBindings(List<PhysicalFieldBindingDTO> physicalFields) {
        if (physicalFields == null) {
            return Collections.emptyList();
        }
        Set<String> seen = new LinkedHashSet<>();
        List<PhysicalFieldBindingDTO> result = new ArrayList<>();
        for (PhysicalFieldBindingDTO binding : physicalFields) {
            if (binding == null || StringUtils.isBlank(binding.getModelFieldId())) {
                continue;
            }
            String modelTableId = binding.getModelTableId();
            if (StringUtils.isBlank(modelTableId)) {
                ModelField field = modelFieldService.getById(binding.getModelFieldId());
                modelTableId = field == null ? null : field.getTableId();
            }
            if (StringUtils.isBlank(modelTableId) || !seen.add(binding.getModelFieldId())) {
                continue;
            }
            PhysicalFieldBindingDTO normalized = new PhysicalFieldBindingDTO();
            normalized.setModelFieldId(binding.getModelFieldId());
            normalized.setModelTableId(modelTableId);
            result.add(normalized);
        }
        return result;
    }

    private List<String> splitBindingValue(String value) {
        if (StringUtils.isBlank(value)) {
            return Collections.emptyList();
        }
        return Arrays.stream(value.split("[;；]"))
                .map(String::trim)
                .filter(StringUtils::isNotBlank)
                .toList();
    }

    private ModelTable findModelTable(String owner, String tableName) {
        try {
            return modelTableService.getOne(new LambdaQueryWrapper<ModelTable>()
                    .eq(ModelTable::getOwner, owner)
                    .eq(ModelTable::getName, tableName));
        } catch (Exception e) {
            return null;
        }
    }

    private ModelField findModelField(String modelTableId, String fieldName) {
        try {
            return modelFieldService.getOne(new LambdaQueryWrapper<ModelField>()
                    .eq(ModelField::getTableId, modelTableId)
                    .eq(ModelField::getName, fieldName));
        } catch (Exception e) {
            return null;
        }
    }

    private PhysicalTableBindingDTO toTableBinding(ModelTable table) {
        if (table == null) {
            return null;
        }
        PhysicalTableBindingDTO dto = new PhysicalTableBindingDTO();
        dto.setModelTableId(table.getId());
        dto.setDataSourceId(table.getDataSourceId());
        dto.setOwner(table.getOwner());
        dto.setTableName(table.getName());
        dto.setTableCnName(table.getCnName());
        return dto;
    }

    private PhysicalFieldBindingDTO toFieldBinding(ModelField field, ModelTable table) {
        if (field == null || table == null) {
            return null;
        }
        PhysicalFieldBindingDTO dto = new PhysicalFieldBindingDTO();
        dto.setModelFieldId(field.getId());
        dto.setModelTableId(table.getId());
        dto.setDataSourceId(table.getDataSourceId());
        dto.setOwner(table.getOwner());
        dto.setTableName(table.getName());
        dto.setTableCnName(table.getCnName());
        dto.setFieldName(field.getName());
        dto.setFieldCnName(field.getCnName());
        dto.setFieldType(field.getType());
        return dto;
    }

    private String joinQualified(String... parts) {
        return String.join(".",
                Arrays.stream(parts)
                        .filter(StringUtils::isNotBlank)
                        .toList());
    }
}
