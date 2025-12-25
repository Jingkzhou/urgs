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
     * 记录变更日志 (异步执行，不阻塞主流程)
     *
     * @param type     对象类型 (TABLE, ELEMENT, CODE_DIR)
     * @param oldVal   旧值 (null 表示新增)
     * @param newVal   新值 (null 表示删除)
     * @param operator 操作人
     */
    @Async
    public void logChange(LogType type, Object oldVal, Object newVal, String operator) {
        try {
            // 1. 确定操作类型
            String action = "UPDATE";
            if (oldVal == null)
                action = "CREATE";
            else if (newVal == null)
                action = "DELETE";

            if (oldVal == null && newVal == null)
                return; // 无效调用

            // 2. 准备数据快照
            String oldJson = oldVal != null ? objectMapper.writeValueAsString(oldVal) : "null";
            String newJson = newVal != null ? objectMapper.writeValueAsString(newVal) : "null";

            // 3. 构建 Prompt 调用 AI
            String prompt = String.format(
                    """
                            Context: User performed %s on %s.
                            Old Data: %s
                            New Data: %s
                            Task: Generate a single sentence description of the key changes in Chinese (e.g., "Updated table 'User': changed status to 'Active'", "Deleted field 'age'").
                            Focus on meaningful business fields change, ignore technical ids or timestamps.
                            """,
                    action, type, oldJson, newJson);

            String description = aiClient.chat("You are an audit logger.", prompt);

            // 清理可能的 AI 废话，只保留核心描述
            description = description.replace("Here is the description:", "").trim();
            // 如果 AI 返回带引号，去掉
            if (description.startsWith("\"") && description.endsWith("\"")) {
                description = description.substring(1, description.length() - 1);
            }

            // 4. 保存记录
            MaintenanceRecord record = new MaintenanceRecord();
            record.setModType(action);
            record.setTime(LocalDateTime.now());
            record.setOperator(operator != null ? operator : "system");
            record.setDescription(description);

            // 根据类型填充关联信息
            fillContextInfo(record, type, oldVal != null ? oldVal : newVal);

            maintenanceRecordService.save(record);
            log.info("Logged maintenance record: {}", description);

        } catch (Exception e) {
            log.error("Failed to generate AI description", e);
            // Fallback: save record without AI description
            try {
                MaintenanceRecord record = new MaintenanceRecord();
                String action = "UPDATE";
                if (oldVal == null)
                    action = "CREATE";
                else if (newVal == null)
                    action = "DELETE";

                record.setModType(action);
                record.setTime(LocalDateTime.now());
                record.setOperator(operator != null ? operator : "system");
                record.setDescription("Auto-generated log (AI failed): " + action + " operation performed.");
                fillContextInfo(record, type, oldVal != null ? oldVal : newVal);
                maintenanceRecordService.save(record);
            } catch (Exception ex) {
                log.error("Failed to save fallback maintenance record", ex);
            }
        }
    }

    @Autowired
    private com.example.urgs_api.metadata.service.RegTableService regTableService;

    private void fillContextInfo(MaintenanceRecord record, LogType type, Object entity) {
        if (entity instanceof RegTable table) {
            record.setTableName(table.getName());
            record.setTableCnName(table.getCnName());
        } else if (entity instanceof RegElement element) {
            // Need to fetch table info
            try {
                RegTable table = regTableService.getById(element.getTableId());
                if (table != null) {
                    record.setTableName(table.getName());
                    record.setTableCnName(table.getCnName());
                } else {
                    record.setTableName("Unknown Table (ID:" + element.getTableId() + ")");
                }
            } catch (Exception e) {
                record.setTableName("TableID:" + element.getTableId());
            }
            record.setFieldName(element.getName());
            record.setFieldCnName(element.getCnName());
        } else if (entity instanceof CodeDirectory codeDir) {
            record.setTableName("CodeTable:" + codeDir.getTableName());
            record.setFieldName(codeDir.getCode());
            record.setFieldCnName(codeDir.getName());
        }
    }

    public enum LogType {
        TABLE, ELEMENT, CODE_DIR
    }
}
