package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.ai.entity.LineageReport;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;

/**
 * 血缘报告服务接口
 */
public interface LineageReportService extends IService<LineageReport> {

    /**
     * 生成血缘影响报告（流式）
     * 
     * @param tableName      表名
     * @param columnName     列名
     * @param lineageContext 血缘上下文数据
     * @return SSE 发射器
     */
    SseEmitter generateReportStream(String tableName, String columnName, Map<String, Object> lineageContext);

    /**
     * 保存报告
     * 
     * @param report 报告实体
     * @return 保存后的报告（含 ID）
     */
    LineageReport saveReport(LineageReport report);

    /**
     * 获取历史报告列表
     * 
     * @param tableName  表名
     * @param columnName 列名（可选）
     * @return 报告列表
     */
    List<LineageReport> getReportHistory(String tableName, String columnName);

    /**
     * 导出报告为 PDF
     * 
     * @param reportId 报告 ID
     * @return PDF 字节数组
     */
    byte[] exportToPdf(Long reportId);

    /**
     * 导出报告为 Word
     * 
     * @param reportId 报告 ID
     * @return Word 字节数组
     */
    byte[] exportToWord(Long reportId);
}
