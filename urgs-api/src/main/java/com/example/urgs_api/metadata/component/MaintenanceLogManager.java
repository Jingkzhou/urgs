package com.example.urgs_api.metadata.component;

import com.example.urgs_api.ai.client.AiClient;
import com.example.urgs_api.metadata.model.CodeDirectory;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.metadata.service.MaintenanceRecordService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 维护日志管理器
 * 负责对比数据变更，调用 AI 生成描述，并保存维护记录
 */
@Component
public class MaintenanceLogManager {

    private static final Logger log = LoggerFactory.getLogger(MaintenanceLogManager.class);

    @Autowired
    private AiClient aiClient;

    @Autowired
    private MaintenanceRecordService maintenanceRecordService;

    private final ObjectMapper objectMapper = new ObjectMapper()
            .registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule())
            .disable(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    /**
     * Context object for passing transient requirement info
     */
    @lombok.Data
    public static class MaintenanceContext {
        private String reqId;
        private java.time.LocalDate plannedDate;
        private String changeDescription;
    }

    public void logChange(LogType type, Object oldVal, Object newVal, String operator) {
        logChange(type, oldVal, newVal, operator, null);
    }

    @Async
    public void logChange(LogType type, Object oldVal, Object newVal, String operator, MaintenanceContext context) {
        try {
            // 1. Determine Action
            String action = "UPDATE";
            if (oldVal == null)
                action = "CREATE";
            else if (newVal == null)
                action = "DELETE";

            if (oldVal == null && newVal == null)
                return;

            // 2. Prepare Snapshot
            String oldJson = oldVal != null ? objectMapper.writeValueAsString(oldVal) : "null";
            String newJson = newVal != null ? objectMapper.writeValueAsString(newVal) : "null";

            // 3. AI Description or Manual Description
            // If changeDescription is provided (via Context or Entity), PREPEND/USE it.
            // But user wants manual description to be THE description if provided?
            // "Requirement Change Description" usually explains WHY.
            // The AI explains WHAT.
            // Maybe combine? "User Reason. AI Summary."

            String manualDesc = extractChangeDescription(newVal, context);
            String aiDesc = "";

            if (newVal != null || oldVal != null) {
                // Only ask AI if we want auto-generated diff (maybe skip if manual is enough?)
                // Existing logic calls AI.
                String prompt = String.format(
                        """
                                Context: User performed %s on %s.
                                Old Data: %s
                                New Data: %s
                                Task: Generate a single sentence description of the key changes in Chinese (e.g., "Updated table 'User': changed status to 'Active'", "Deleted field 'age'").
                                Focus on meaningful business fields change, ignore technical ids or timestamps.
                                """,
                        action, type, oldJson, newJson);
                try {
                    aiDesc = aiClient.chat("You are an audit logger.", prompt);
                    aiDesc = aiDesc.replace("Here is the description:", "").trim();
                    if (aiDesc.startsWith("\"") && aiDesc.endsWith("\"")) {
                        aiDesc = aiDesc.substring(1, aiDesc.length() - 1);
                    }
                } catch (Exception e) {
                    log.error("AI Gen Failed", e);
                    aiDesc = action + " operation performed.";
                }
            }

            String finalDesc = aiDesc;
            if (manualDesc != null && !manualDesc.isBlank()) {
                finalDesc = manualDesc + " (" + aiDesc + ")";
            }

            // 4. Save Record
            MaintenanceRecord record = new MaintenanceRecord();
            record.setModType(action);
            record.setTime(LocalDateTime.now());
            record.setOperator(operator != null ? operator : "system");
            record.setDescription(finalDesc);

            fillContextInfo(record, type, oldVal != null ? oldVal : newVal);

            // 5. Fill Req Info (Context > NewVal)
            fillReqInfo(record, newVal, context);

            maintenanceRecordService.save(record);
            log.info("Logged maintenance record: {}", finalDesc);

        } catch (Exception e) {
            log.error("Log Change Failed", e);
        }
    }

    private String extractChangeDescription(Object entity, MaintenanceContext context) {
        if (context != null && context.getChangeDescription() != null)
            return context.getChangeDescription();
        if (entity == null)
            return null;
        if (entity instanceof RegTable t)
            return t.getChangeDescription();
        if (entity instanceof RegElement e)
            return e.getChangeDescription();
        if (entity instanceof CodeDirectory c)
            return c.getChangeDescription();
        if (entity instanceof com.example.urgs_api.metadata.model.CodeTable c)
            return c.getChangeDescription();
        return null;
    }

    private void fillReqInfo(MaintenanceRecord record, Object entity, MaintenanceContext context) {
        if (context != null) {
            if (context.getReqId() != null)
                record.setReqId(context.getReqId());
            if (context.getPlannedDate() != null)
                record.setPlannedDate(context.getPlannedDate());
        }
        // If not found in context, check entity
        if (record.getReqId() == null && entity != null) {
            if (entity instanceof RegTable t)
                record.setReqId(t.getReqId());
            else if (entity instanceof RegElement e)
                record.setReqId(e.getReqId());
            else if (entity instanceof CodeDirectory c)
                record.setReqId(c.getReqId());
            else if (entity instanceof com.example.urgs_api.metadata.model.CodeTable c)
                record.setReqId(c.getReqId());
        }
        if (record.getPlannedDate() == null && entity != null) {
            if (entity instanceof RegTable t)
                record.setPlannedDate(t.getPlannedDate());
            else if (entity instanceof RegElement e)
                record.setPlannedDate(e.getPlannedDate());
            else if (entity instanceof CodeDirectory c)
                record.setPlannedDate(c.getPlannedDate());
            else if (entity instanceof com.example.urgs_api.metadata.model.CodeTable c)
                record.setPlannedDate(c.getPlannedDate());
        }
    }

    @Autowired
    private com.example.urgs_api.metadata.service.RegTableService regTableService;

    private void fillContextInfo(MaintenanceRecord record, LogType type, Object entity) {
        if (entity instanceof RegTable table) {
            record.setTableName(table.getName());
            record.setTableCnName(table.getCnName());
            record.setSystemCode(table.getSystemCode());
            record.setAssetType("REG_ASSET");
            // Extract transient fields
            if (table.getReqId() != null)
                record.setReqId(table.getReqId());
            if (table.getPlannedDate() != null)
                record.setPlannedDate(table.getPlannedDate());
        } else if (entity instanceof RegElement element) {
            // Need to fetch table info
            try {
                RegTable table = regTableService.getById(element.getTableId());
                if (table != null) {
                    record.setTableName(table.getName());
                    record.setTableCnName(table.getCnName());
                    record.setSystemCode(table.getSystemCode());
                } else {
                    record.setTableName("Unknown Table (ID:" + element.getTableId() + ")");
                }
            } catch (Exception e) {
                record.setTableName("TableID:" + element.getTableId());
            }
            record.setAssetType("REG_ASSET");
            record.setFieldName(element.getName());
            record.setFieldCnName(element.getCnName());
            // Extract transient fields
            if (element.getReqId() != null)
                record.setReqId(element.getReqId());
            if (element.getPlannedDate() != null)
                record.setPlannedDate(element.getPlannedDate());
        } else if (entity instanceof CodeDirectory codeDir) {
            record.setTableName("CodeTable:" + codeDir.getTableName());
            record.setFieldName(codeDir.getCode());
            record.setFieldCnName(codeDir.getName());
            record.setAssetType("CODE_VAL");
            record.setSystemCode(codeDir.getSystemCode());
        } else if (entity instanceof com.example.urgs_api.metadata.model.CodeTable codeTable) {
            record.setTableName(codeTable.getTableName());
            record.setTableCnName(codeTable.getTableName()); // Reuse name
            record.setModType(record.getModType() != null ? record.getModType() : "UPDATE");
            record.setAssetType("CODE_TABLE");
            record.setSystemCode(codeTable.getSystemCode());
        }
    }

    public enum LogType {
        TABLE, ELEMENT, CODE_DIR, CODE_TABLE
    }
}
