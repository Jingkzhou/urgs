package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.ApplyResult;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.CaliberChangeRequest;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.ChangePreview;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.ElementCaliberChange;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.PreviewResponse;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.RegElementContext;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.RegTableContext;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

@Service
public class AssetCaliberService {

    private static final String VIEW_PERMISSION = "metadata:asset:view";
    private static final String TABLE_WRITE_PERMISSION = "metadata:asset:edit";
    private static final String ELEMENT_WRITE_PERMISSION = "metadata:asset:element:edit";
    private static final int MAX_ELEMENT_CHANGES = 500;
    private static final int MAX_CALIBER_LENGTH = 10_000;
    private static final int MAX_SOURCE_SQL_BYTES = 60_000;
    private static final int MAX_DESCRIPTION_LENGTH = 500;
    private static final int MAX_REQ_ID_LENGTH = 50;

    private final RegTableService regTableService;
    private final RegElementService regElementService;
    private final MaintenanceRecordService maintenanceRecordService;
    private final UserService userService;
    private final SysSystemService sysSystemService;

    public AssetCaliberService(
            RegTableService regTableService,
            RegElementService regElementService,
            MaintenanceRecordService maintenanceRecordService,
            UserService userService,
            SysSystemService sysSystemService) {
        this.regTableService = regTableService;
        this.regElementService = regElementService;
        this.maintenanceRecordService = maintenanceRecordService;
        this.userService = userService;
        this.sysSystemService = sysSystemService;
    }

    public RegTableContext resolveTable(Long requesterUserId, String systemCode, String tableName) {
        User user = requirePermission(requesterUserId, VIEW_PERMISSION);
        if (isBlank(systemCode)) {
            throw badRequest("systemCode 不能为空");
        }
        if (isBlank(tableName)) {
            throw badRequest("tableName 不能为空");
        }
        requireSystemAccess(user, systemCode.trim());

        List<RegTable> tables = regTableService.list(new LambdaQueryWrapper<RegTable>()
                .eq(RegTable::getSystemCode, systemCode.trim())
                .eq(RegTable::getName, tableName.trim()));
        if (tables.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "未找到匹配的监管资产表");
        }
        if (tables.size() > 1) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "监管资产表不唯一，请先清理重复数据");
        }
        return toContext(tables.get(0));
    }

    public RegTableContext getTable(Long requesterUserId, Long tableId) {
        User user = requirePermission(requesterUserId, VIEW_PERMISSION);
        RegTable table = requireTable(tableId);
        requireSystemAccess(user, table.getSystemCode());
        return toContext(table);
    }

    public PreviewResponse preview(CaliberChangeRequest request) {
        User user = requirePermission(request == null ? null : request.requesterUserId(), VIEW_PERMISSION);
        return inspect(request, user).response();
    }

    @Transactional(rollbackFor = Exception.class)
    public ApplyResult apply(CaliberChangeRequest request) {
        User user = requirePermission(request == null ? null : request.requesterUserId(), VIEW_PERMISSION);
        if (request == null || !request.confirmed()) {
            throw badRequest("回写前必须显式设置 confirmed=true");
        }

        Inspection inspection = inspect(request, user);
        if (request.tableBusinessCaliber() != null) {
            requirePermission(request.requesterUserId(), TABLE_WRITE_PERMISSION);
        }
        if (request.elements() != null && !request.elements().isEmpty()) {
            requirePermission(request.requesterUserId(), ELEMENT_WRITE_PERMISSION);
        }

        PreviewResponse preview = inspection.response();
        if (!preview.valid()) {
            HttpStatus status = preview.changes().stream().anyMatch(ChangePreview::conflict)
                    ? HttpStatus.CONFLICT
                    : HttpStatus.BAD_REQUEST;
            throw new ResponseStatusException(status, String.join("；", preview.errors()));
        }

        LocalDateTime now = LocalDateTime.now();
        int updatedCount = 0;
        int skippedCount = 0;
        for (ChangePreview change : preview.changes()) {
            if (!change.changed()) {
                skippedCount++;
                continue;
            }
            boolean updated;
            if ("TABLE".equals(change.assetType())) {
                updated = updateTableCaliber(inspection.table(), change.newValue(), now);
                if (updated) {
                    saveMaintenanceRecord(inspection.table(), null, user, request,
                            "更新监管表业务口径", now);
                }
            } else {
                RegElement element = inspection.elementsById().get(change.assetId());
                updated = updateElementCaliber(element, change.newValue(), now);
                if (updated) {
                    String modType = "INDICATOR".equalsIgnoreCase(element.getType())
                            ? "更新监管指标业务口径"
                            : "更新监管字段业务口径";
                    saveMaintenanceRecord(inspection.table(), element, user, request, modType, now);
                }
            }
            if (!updated) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "监管资产已被其他操作更新，请重新读取并预览");
            }
            updatedCount++;
        }

        return new ApplyResult(updatedCount, skippedCount, toContext(requireTable(request.tableId())), preview.warnings());
    }

    private Inspection inspect(CaliberChangeRequest request, User user) {
        if (request == null) {
            throw badRequest("请求体不能为空");
        }
        RegTable table = requireTable(request.tableId());
        requireSystemAccess(user, table.getSystemCode());
        List<RegElement> tableElements = listElements(table.getId());
        Map<Long, RegElement> elementsById = new HashMap<>();
        for (RegElement element : tableElements) {
            elementsById.put(element.getId(), element);
        }

        List<String> errors = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        List<ChangePreview> changes = new ArrayList<>();
        validateAuditInput(request, errors);

        boolean tableRequested = request.tableBusinessCaliber() != null;
        List<ElementCaliberChange> elementChanges = request.elements() == null ? List.of() : request.elements();
        if (!tableRequested && elementChanges.isEmpty()) {
            errors.add("至少提供一项监管表或监管字段/指标业务口径变更");
        }
        if (elementChanges.size() > MAX_ELEMENT_CHANGES) {
            errors.add("单次字段/指标变更不能超过 " + MAX_ELEMENT_CHANGES + " 项");
        }

        if (tableRequested) {
            String newValue = normalizeCaliber(request.tableBusinessCaliber(), "监管表业务口径", errors);
            boolean conflict = !Objects.equals(request.expectedTableUpdateTime(), table.getUpdateTime());
            if (conflict) {
                errors.add("监管表更新时间已变化，请重新读取后再生成口径");
            }
            changes.add(new ChangePreview(
                    "TABLE",
                    table.getId(),
                    displayName(table.getName(), table.getCnName()),
                    table.getBusinessCaliber(),
                    newValue,
                    table.getUpdateTime(),
                    !Objects.equals(table.getBusinessCaliber(), newValue),
                    conflict));
        }

        Set<Long> seenElementIds = new HashSet<>();
        for (ElementCaliberChange elementChange : elementChanges) {
            if (elementChange == null || elementChange.elementId() == null) {
                errors.add("elementId 不能为空");
                continue;
            }
            if (!seenElementIds.add(elementChange.elementId())) {
                errors.add("字段/指标变更重复：" + elementChange.elementId());
                continue;
            }
            RegElement element = elementsById.get(elementChange.elementId());
            if (element == null) {
                errors.add("字段/指标不属于目标监管表：" + elementChange.elementId());
                continue;
            }
            String newValue = normalizeCaliber(elementChange.businessCaliber(), "字段/指标业务口径", errors);
            boolean conflict = !Objects.equals(elementChange.expectedUpdateTime(), element.getUpdateTime());
            if (conflict) {
                errors.add("字段/指标 " + element.getName() + " 的更新时间已变化，请重新读取后再生成口径");
            }
            changes.add(new ChangePreview(
                    "ELEMENT",
                    element.getId(),
                    displayName(element.getName(), element.getCnName()),
                    element.getBusinessCaliber(),
                    newValue,
                    element.getUpdateTime(),
                    !Objects.equals(element.getBusinessCaliber(), newValue),
                    conflict));
        }

        if (!changes.isEmpty() && changes.stream().noneMatch(ChangePreview::changed)) {
            warnings.add("提交内容与当前业务口径一致，不会产生数据更新");
        }
        return new Inspection(table, elementsById,
                new PreviewResponse(errors.isEmpty(), List.copyOf(changes), List.copyOf(errors), List.copyOf(warnings)));
    }

    private void validateAuditInput(CaliberChangeRequest request, List<String> errors) {
        if (isBlank(request.sourceSql())) {
            errors.add("sourceSql 不能为空，加工 SQL 必须作为口径分析和审计证据");
        } else if (request.sourceSql().getBytes(StandardCharsets.UTF_8).length > MAX_SOURCE_SQL_BYTES) {
            errors.add("sourceSql 的 UTF-8 内容不能超过 " + MAX_SOURCE_SQL_BYTES + " 字节");
        }
        if (request.description() != null && request.description().length() > MAX_DESCRIPTION_LENGTH) {
            errors.add("description 长度不能超过 " + MAX_DESCRIPTION_LENGTH + " 个字符");
        }
        if (request.reqId() != null && request.reqId().length() > MAX_REQ_ID_LENGTH) {
            errors.add("reqId 长度不能超过 " + MAX_REQ_ID_LENGTH + " 个字符");
        }
    }

    private boolean updateTableCaliber(RegTable table, String businessCaliber, LocalDateTime updateTime) {
        UpdateWrapper<RegTable> update = new UpdateWrapper<RegTable>()
                .eq("id", table.getId())
                .set("business_caliber", businessCaliber)
                .set("update_time", updateTime);
        addUpdateTimeCondition(update, table.getUpdateTime());
        return regTableService.update(update);
    }

    private boolean updateElementCaliber(RegElement element, String businessCaliber, LocalDateTime updateTime) {
        UpdateWrapper<RegElement> update = new UpdateWrapper<RegElement>()
                .eq("id", element.getId())
                .eq("table_id", element.getTableId())
                .set("business_caliber", businessCaliber)
                .set("update_time", updateTime);
        addUpdateTimeCondition(update, element.getUpdateTime());
        return regElementService.update(update);
    }

    private void addUpdateTimeCondition(UpdateWrapper<?> update, LocalDateTime currentUpdateTime) {
        if (currentUpdateTime == null) {
            update.isNull("update_time");
        } else {
            update.eq("update_time", currentUpdateTime);
        }
    }

    private void saveMaintenanceRecord(
            RegTable table,
            RegElement element,
            User user,
            CaliberChangeRequest request,
            String modType,
            LocalDateTime now) {
        MaintenanceRecord record = new MaintenanceRecord();
        record.setTableName(table.getName());
        record.setTableCnName(table.getCnName());
        record.setSystemCode(table.getSystemCode());
        record.setModType(modType);
        if (element != null) {
            record.setFieldName(element.getName());
            record.setFieldCnName(element.getCnName());
        }
        record.setTime(now);
        record.setOperator(limitLength(displayName(user.getName(), user.getEmpId()), 50));
        record.setReqId(request.reqId());
        record.setDescription(isBlank(request.description())
                ? "依据加工 SQL 和监管集市证据回写业务口径"
                : request.description().trim());
        record.setScript(request.sourceSql());
        record.setAssetType("REG_ASSET");
        record.setCreateTime(now);
        record.setUpdateTime(now);
        if (!maintenanceRecordService.save(record)) {
            throw new IllegalStateException("业务口径已更新，但维护记录保存失败");
        }
    }

    private RegTableContext toContext(RegTable table) {
        List<RegElementContext> elements = listElements(table.getId()).stream()
                .map(element -> new RegElementContext(
                        element.getId(),
                        element.getTableId(),
                        element.getType(),
                        element.getName(),
                        element.getCnName(),
                        element.getDataType(),
                        element.getFormula(),
                        element.getCodeTableCode(),
                        element.getValueRange(),
                        element.getValidationRule(),
                        element.getBusinessCaliber(),
                        element.getFillInstruction(),
                        element.getUpdateTime()))
                .toList();
        return new RegTableContext(
                table.getId(),
                table.getName(),
                table.getCnName(),
                table.getSystemCode(),
                table.getSubjectName(),
                table.getTheme(),
                table.getFrequency(),
                table.getBusinessCaliber(),
                table.getFillInstruction(),
                table.getUpdateTime(),
                elements);
    }

    private List<RegElement> listElements(Long tableId) {
        return regElementService.list(new LambdaQueryWrapper<RegElement>()
                .eq(RegElement::getTableId, tableId)
                .orderByAsc(RegElement::getSortOrder)
                .orderByAsc(RegElement::getId));
    }

    private RegTable requireTable(Long tableId) {
        if (tableId == null) {
            throw badRequest("tableId 不能为空");
        }
        RegTable table = regTableService.getById(tableId);
        if (table == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "监管资产表不存在：" + tableId);
        }
        return table;
    }

    private User requireUser(Long requesterUserId) {
        if (requesterUserId == null) {
            throw badRequest("requesterUserId 不能为空");
        }
        User user = userService.getById(requesterUserId);
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "请求用户不存在");
        }
        return user;
    }

    private User requirePermission(Long requesterUserId, String permission) {
        User user = requireUser(requesterUserId);
        Set<String> permissions = userService.getUserPermissions(requesterUserId);
        if (permissions == null || !permissions.contains(permission)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "当前用户缺少权限：" + permission);
        }
        return user;
    }

    private void requireSystemAccess(User user, String systemCode) {
        if (isBlank(systemCode)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "监管资产未配置所属系统，禁止自动回写");
        }
        String userSystems = user.getSystem();
        if (isBlank(userSystems) || "ALL".equalsIgnoreCase(userSystems.trim())) {
            return;
        }
        boolean allowed = sysSystemService.list(user.getId()).stream()
                .map(SysSystem::getClientId)
                .filter(value -> !isBlank(value))
                .anyMatch(value -> value.equalsIgnoreCase(systemCode));
        if (!allowed) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "当前用户无权访问监管系统：" + systemCode);
        }
    }

    private String normalizeCaliber(String value, String label, List<String> errors) {
        if (isBlank(value)) {
            errors.add(label + "不能为空");
            return value;
        }
        String normalized = value.strip();
        if (normalized.length() > MAX_CALIBER_LENGTH) {
            errors.add(label + "长度不能超过 " + MAX_CALIBER_LENGTH + " 个字符");
        }
        return normalized;
    }

    private String displayName(String primary, String secondary) {
        if (isBlank(primary)) {
            return secondary;
        }
        if (isBlank(secondary)) {
            return primary;
        }
        return primary + "（" + secondary + "）";
    }

    private String limitLength(String value, int maxLength) {
        return value == null || value.length() <= maxLength ? value : value.substring(0, maxLength);
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private ResponseStatusException badRequest(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }

    private record Inspection(
            RegTable table,
            Map<Long, RegElement> elementsById,
            PreviewResponse response) {
    }
}
