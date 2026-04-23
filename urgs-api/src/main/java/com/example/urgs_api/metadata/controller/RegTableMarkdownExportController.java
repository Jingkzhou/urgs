package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.metadata.service.RegTableMarkdownExportService;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;

/**
 * 监管报表 Markdown 导出控制器
 */
@RestController
@RequestMapping("/api/reg/table-docs")
public class RegTableMarkdownExportController {

    @Autowired
    private RegTableMarkdownExportService regTableMarkdownExportService;

    /**
     * 导出报表 Markdown 压缩包
     */
    @GetMapping("/export")
    public void exportMarkdown(
            @RequestParam(required = false) String systemCode,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String autoFetchStatus,
            @RequestParam(required = false) String frequency,
            @RequestParam(required = false) String sourceType,
            @RequestParam(required = false) String tableIds,
            HttpServletResponse response) throws IOException {
        regTableMarkdownExportService.exportMarkdownZip(
                systemCode,
                keyword,
                autoFetchStatus,
                frequency,
                sourceType,
                tableIds,
                response);
    }
}
