package com.example.urgs_api.metadata.service;

import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * 监管报表 Markdown 导出服务
 */
public interface RegTableMarkdownExportService {

    /**
     * 将报表定义导出为 Markdown 压缩包
     *
     * @param systemCode      系统编码
     * @param keyword         报表关键字
     * @param autoFetchStatus 自动取数状态
     * @param frequency       频率
     * @param sourceType      来源类型
     * @param tableIds        报表 ID 列表，逗号分隔
     * @param response        HTTP 响应
     * @throws IOException IO 异常
     */
    void exportMarkdownZip(
            String systemCode,
            String keyword,
            String autoFetchStatus,
            String frequency,
            String sourceType,
            String tableIds,
            HttpServletResponse response) throws IOException;
}
