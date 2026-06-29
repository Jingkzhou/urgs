package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.metadata.component.MaintenanceLogManager;
import com.example.urgs_api.metadata.dto.RegElementMaintenanceDTO;
import com.example.urgs_api.metadata.model.CodeDirectory;
import com.example.urgs_api.metadata.model.CodeTable;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.service.CodeDirectoryService;
import com.example.urgs_api.metadata.service.CodeTableService;
import com.example.urgs_api.metadata.service.RegElementMaintenanceService;
import com.example.urgs_api.metadata.service.RegElementService;
import com.example.urgs_api.metadata.service.RegPhysicalBindingService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;

@Service
public class RegElementMaintenanceServiceImpl implements RegElementMaintenanceService {

    private final RegElementService regElementService;
    private final RegPhysicalBindingService regPhysicalBindingService;
    private final CodeDirectoryService codeDirectoryService;
    private final CodeTableService codeTableService;
    private final MaintenanceLogManager maintenanceLogManager;

    public RegElementMaintenanceServiceImpl(
            RegElementService regElementService,
            RegPhysicalBindingService regPhysicalBindingService,
            CodeDirectoryService codeDirectoryService,
            CodeTableService codeTableService,
            MaintenanceLogManager maintenanceLogManager) {
        this.regElementService = regElementService;
        this.regPhysicalBindingService = regPhysicalBindingService;
        this.codeDirectoryService = codeDirectoryService;
        this.codeTableService = codeTableService;
        this.maintenanceLogManager = maintenanceLogManager;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean maintain(RegElementMaintenanceDTO request, String operator) {
        if (request == null || request.getElement() == null) {
            throw new IllegalArgumentException("监管字段不能为空");
        }

        RegElement element = request.getElement();
        validateRequiredFields(element);
        List<RegElementMaintenanceDTO.CodeChangeDTO> codeChanges = request.getCodeChanges() == null
                ? List.of()
                : request.getCodeChanges();

        RegElement oldElement = element.getId() == null ? null : regElementService.getById(element.getId());
        LocalDateTime now = LocalDateTime.now();
        if (element.getId() == null) {
            element.setCreateTime(now);
        }
        element.setUpdateTime(now);

        if (!regElementService.saveOrUpdate(element)) {
            return false;
        }
        regPhysicalBindingService.replaceElementBindings(element.getId(), element.getPhysicalFields());

        CodeTable codeTable = resolveCodeTable(element.getCodeTableCode(), codeChanges);
        ChangeCount changeCount = new ChangeCount();
        for (RegElementMaintenanceDTO.CodeChangeDTO change : codeChanges) {
            applyCodeChange(change, codeTable, element, operator, changeCount);
        }

        MaintenanceLogManager.MaintenanceContext elementContext = buildContext(
                element,
                changeCount.total() == 0 ? null : changeCount.summary());
        maintenanceLogManager.logChange(
                MaintenanceLogManager.LogType.ELEMENT,
                oldElement,
                element,
                operator,
                elementContext);
        return true;
    }

    private void validateRequiredFields(RegElement element) {
        if (isBlank(element.getBusinessCaliber())) {
            throw new IllegalArgumentException("业务口径不能为空");
        }
        if (isBlank(element.getFillInstruction())) {
            throw new IllegalArgumentException("填报说明不能为空");
        }
        if (isBlank(element.getReqId())) {
            throw new IllegalArgumentException("需求编号不能为空");
        }
        if (element.getPlannedDate() == null) {
            throw new IllegalArgumentException("计划上线日期不能为空");
        }
        if (isBlank(element.getChangeDescription())) {
            throw new IllegalArgumentException("需求变更描述不能为空");
        }
    }

    private CodeTable resolveCodeTable(
            String tableCode,
            List<RegElementMaintenanceDTO.CodeChangeDTO> codeChanges) {
        if (codeChanges.isEmpty()) {
            return null;
        }
        if (isBlank(tableCode)) {
            throw new IllegalArgumentException("请先选择值域代码表");
        }

        CodeTable codeTable = codeTableService.getOne(
                new QueryWrapper<CodeTable>().eq("table_code", tableCode),
                false);
        if (codeTable == null) {
            throw new IllegalArgumentException("值域代码表不存在：" + tableCode);
        }
        return codeTable;
    }

    private void applyCodeChange(
            RegElementMaintenanceDTO.CodeChangeDTO change,
            CodeTable codeTable,
            RegElement element,
            String operator,
            ChangeCount changeCount) {
        if (change == null || change.getData() == null || isBlank(change.getOperation())) {
            throw new IllegalArgumentException("码值变更数据不完整");
        }

        String operation = change.getOperation().toUpperCase(Locale.ROOT);
        CodeDirectory submitted = change.getData();
        CodeDirectory oldCode = submitted.getId() == null ? null : codeDirectoryService.getById(submitted.getId());

        if ("DELETE".equals(operation)) {
            if (oldCode == null || !codeTable.getTableCode().equals(oldCode.getTableCode())) {
                throw new IllegalArgumentException("待删除码值不属于当前代码表");
            }
            if (!codeDirectoryService.removeById(oldCode.getId())) {
                throw new IllegalStateException("删除码值失败：" + oldCode.getCode());
            }
            changeCount.deleted++;
            logCodeChange(oldCode, null, element, operator, "删除码值 " + oldCode.getCode());
            return;
        }

        if (!"CREATE".equals(operation) && !"UPDATE".equals(operation)) {
            throw new IllegalArgumentException("不支持的码值操作：" + operation);
        }
        if (isBlank(submitted.getCode()) || isBlank(submitted.getName())) {
            throw new IllegalArgumentException("码值编码和名称不能为空");
        }
        if ("UPDATE".equals(operation)
                && (oldCode == null || !codeTable.getTableCode().equals(oldCode.getTableCode()))) {
            throw new IllegalArgumentException("待修改码值不属于当前代码表");
        }

        QueryWrapper<CodeDirectory> duplicateQuery = new QueryWrapper<CodeDirectory>()
                .eq("table_code", codeTable.getTableCode())
                .eq("code", submitted.getCode());
        if (submitted.getId() != null) {
            duplicateQuery.ne("id", submitted.getId());
        }
        if (codeDirectoryService.count(duplicateQuery) > 0) {
            throw new IllegalArgumentException("码值编码已存在：" + submitted.getCode());
        }

        submitted.setTableCode(codeTable.getTableCode());
        submitted.setTableName(codeTable.getTableName());
        submitted.setSystemCode(codeTable.getSystemCode());
        submitted.setReqId(element.getReqId());
        submitted.setPlannedDate(element.getPlannedDate());
        submitted.setChangeDescription(element.getChangeDescription());
        if ("CREATE".equals(operation)) {
            submitted.setId(null);
            submitted.setCreateTime(LocalDateTime.now());
            changeCount.created++;
        } else {
            submitted.setCreateTime(oldCode.getCreateTime());
            changeCount.updated++;
        }
        submitted.setUpdateTime(LocalDateTime.now());

        if (!codeDirectoryService.saveOrUpdate(submitted)) {
            throw new IllegalStateException("保存码值失败：" + submitted.getCode());
        }
        logCodeChange(
                oldCode,
                submitted,
                element,
                operator,
                ("CREATE".equals(operation) ? "新增码值 " : "修改码值 ") + submitted.getCode());
    }

    private void logCodeChange(
            CodeDirectory oldCode,
            CodeDirectory newCode,
            RegElement element,
            String operator,
            String summary) {
        maintenanceLogManager.logChange(
                MaintenanceLogManager.LogType.CODE_DIR,
                oldCode,
                newCode,
                operator,
                buildContext(element, summary));
    }

    private MaintenanceLogManager.MaintenanceContext buildContext(RegElement element, String summary) {
        MaintenanceLogManager.MaintenanceContext context = new MaintenanceLogManager.MaintenanceContext();
        context.setReqId(element.getReqId());
        context.setPlannedDate(element.getPlannedDate());
        String description = element.getChangeDescription();
        if (!isBlank(summary)) {
            description = isBlank(description) ? summary : description + "；" + summary;
        }
        context.setChangeDescription(description);
        return context;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private static class ChangeCount {
        private int created;
        private int updated;
        private int deleted;

        private int total() {
            return created + updated + deleted;
        }

        private String summary() {
            return String.format("码值变更：新增%d项、修改%d项、删除%d项", created, updated, deleted);
        }
    }
}
