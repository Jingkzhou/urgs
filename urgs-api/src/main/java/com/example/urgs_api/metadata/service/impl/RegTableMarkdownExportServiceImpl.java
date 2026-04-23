package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.metadata.model.CodeDirectory;
import com.example.urgs_api.metadata.model.CodeTable;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.metadata.service.CodeDirectoryService;
import com.example.urgs_api.metadata.service.CodeTableService;
import com.example.urgs_api.metadata.service.RegElementService;
import com.example.urgs_api.metadata.service.RegTableMarkdownExportService;
import com.example.urgs_api.metadata.service.RegTableService;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class RegTableMarkdownExportServiceImpl implements RegTableMarkdownExportService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    @Autowired
    private RegTableService regTableService;

    @Autowired
    private RegElementService regElementService;

    @Autowired
    private CodeTableService codeTableService;

    @Autowired
    private CodeDirectoryService codeDirectoryService;

    @Override
    public void exportMarkdownZip(
            String systemCode,
            String keyword,
            String autoFetchStatus,
            String frequency,
            String sourceType,
            String tableIds,
            HttpServletResponse response) throws IOException {
        List<RegTable> tables = queryTables(systemCode, keyword, autoFetchStatus, frequency, sourceType, tableIds);
        Map<Long, List<RegElement>> elementMap = queryElements(tables);
        CodeLookup codeLookup = queryCodeLookup(elementMap);

        response.setContentType("application/zip");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        String fileName = URLEncoder.encode("监管报表Markdown导出", StandardCharsets.UTF_8)
                .replaceAll("\\+", "%20");
        response.setHeader("Content-Disposition", "attachment;filename*=utf-8''" + fileName + ".zip");

        try (ZipOutputStream zos = new ZipOutputStream(response.getOutputStream(), StandardCharsets.UTF_8)) {
            Map<Long, String> fileNameMap = buildMarkdownFileNames(tables);

            writeZipEntry(zos, "README.md", buildIndexMarkdown(tables, elementMap, fileNameMap));

            for (RegTable table : tables) {
                List<RegElement> elements = elementMap.getOrDefault(table.getId(), Collections.emptyList());
                String markdown = buildTableMarkdown(table, elements, codeLookup);
                writeZipEntry(zos, "tables/" + fileNameMap.get(table.getId()), markdown);
            }
        }
    }

    private List<RegTable> queryTables(
            String systemCode,
            String keyword,
            String autoFetchStatus,
            String frequency,
            String sourceType,
            String tableIds) {
        QueryWrapper<RegTable> query = new QueryWrapper<>();

        if (StringUtils.isNotBlank(tableIds)) {
            List<Long> ids = Arrays.stream(tableIds.split(","))
                    .map(String::trim)
                    .filter(StringUtils::isNotBlank)
                    .map(Long::parseLong)
                    .toList();
            query.in("id", ids);
        } else {
            if (StringUtils.isNotBlank(systemCode)) {
                query.eq("system_code", systemCode);
            }
            if (StringUtils.isNotBlank(autoFetchStatus)) {
                query.eq("auto_fetch_status", autoFetchStatus);
            }
            if (StringUtils.isNotBlank(frequency)) {
                query.eq("frequency", frequency);
            }
            if (StringUtils.isNotBlank(sourceType)) {
                query.eq("source_type", sourceType);
            }
            if (StringUtils.isNotBlank(keyword)) {
                String kw = keyword.toLowerCase();
                query.and(w -> w.like("LOWER(name)", kw).or().like("LOWER(cn_name)", kw));
            }
        }

        query.orderByAsc("sort_order", "id");
        return regTableService.list(query);
    }

    private Map<Long, List<RegElement>> queryElements(List<RegTable> tables) {
        if (tables.isEmpty()) {
            return Collections.emptyMap();
        }

        List<Long> tableIds = tables.stream()
                .map(RegTable::getId)
                .toList();

        List<RegElement> elements = regElementService.list(new LambdaQueryWrapper<RegElement>()
                .in(RegElement::getTableId, tableIds)
                .orderByAsc(RegElement::getSortOrder, RegElement::getId));

        return elements.stream().collect(Collectors.groupingBy(RegElement::getTableId));
    }

    private CodeLookup queryCodeLookup(Map<Long, List<RegElement>> elementMap) {
        Set<String> codeTableCodes = elementMap.values().stream()
                .flatMap(List::stream)
                .map(RegElement::getCodeTableCode)
                .filter(StringUtils::isNotBlank)
                .collect(Collectors.toCollection(HashSet::new));

        if (codeTableCodes.isEmpty()) {
            return new CodeLookup(Collections.emptyMap(), Collections.emptyMap());
        }

        List<CodeTable> codeTables = codeTableService.list(new LambdaQueryWrapper<CodeTable>()
                .in(CodeTable::getTableCode, codeTableCodes));

        List<CodeDirectory> codeDirectories = codeDirectoryService.list(new LambdaQueryWrapper<CodeDirectory>()
                .in(CodeDirectory::getTableCode, codeTableCodes)
                .orderByAsc(CodeDirectory::getTableCode, CodeDirectory::getSortOrder, CodeDirectory::getCode));

        Map<String, CodeTable> codeTableMap = codeTables.stream()
                .collect(Collectors.toMap(CodeTable::getTableCode, item -> item, (left, right) -> left));

        Map<String, List<CodeDirectory>> codeDirectoryMap = codeDirectories.stream()
                .collect(Collectors.groupingBy(CodeDirectory::getTableCode, TreeMap::new, Collectors.toList()));

        return new CodeLookup(codeTableMap, codeDirectoryMap);
    }

    private Map<Long, String> buildMarkdownFileNames(List<RegTable> tables) {
        Map<Long, String> result = new LinkedHashMap<>();
        Set<String> usedNames = new HashSet<>();

        for (RegTable table : tables) {
            String baseName = buildBaseFileName(table);
            String candidate = baseName + ".md";
            int counter = 2;
            while (!usedNames.add(candidate.toLowerCase())) {
                candidate = baseName + "_" + counter++ + ".md";
            }
            result.put(table.getId(), candidate);
        }

        return result;
    }

    private String buildBaseFileName(RegTable table) {
        List<String> parts = new ArrayList<>();
        if (table.getSortOrder() != null) {
            parts.add(String.format("%03d", table.getSortOrder()));
        }
        if (StringUtils.isNotBlank(table.getSystemCode())) {
            parts.add(sanitizeFileName(table.getSystemCode()));
        }
        if (StringUtils.isNotBlank(table.getName())) {
            parts.add(sanitizeFileName(table.getName()));
        }
        if (StringUtils.isNotBlank(table.getCnName())) {
            parts.add(sanitizeFileName(table.getCnName()));
        }

        String joined = String.join("_", parts.stream()
                .filter(StringUtils::isNotBlank)
                .toList());

        if (StringUtils.isBlank(joined)) {
            return "reg_table_" + table.getId();
        }

        return StringUtils.abbreviate(joined, 120);
    }

    private String buildIndexMarkdown(
            List<RegTable> tables,
            Map<Long, List<RegElement>> elementMap,
            Map<Long, String> fileNameMap) {
        StringBuilder builder = new StringBuilder();
        builder.append("# 监管报表 Markdown 导出索引\n\n");
        builder.append("## 导出说明\n\n");
        builder.append("- 每个报表一个 Markdown 文件，位于 `tables/` 目录。\n");
        builder.append("- 文档包含报表概览、字段明细，以及字段引用的码表和码值清单。\n");
        builder.append("- 字段级别若配置了 `codeTableCode`，会在对应报表文档中自动展开码值详情。\n\n");
        builder.append("## 报表清单\n\n");
        builder.append("| 序号 | 系统 | 物理表名 | 中文名 | 字段数 | 引用码表数 | 文档 |\n");
        builder.append("| --- | --- | --- | --- | --- | --- | --- |\n");

        for (RegTable table : tables) {
            List<RegElement> elements = elementMap.getOrDefault(table.getId(), Collections.emptyList());
            long codeTableCount = elements.stream()
                    .map(RegElement::getCodeTableCode)
                    .filter(StringUtils::isNotBlank)
                    .distinct()
                    .count();
            builder.append("| ")
                    .append(nullSafe(table.getSortOrder()))
                    .append(" | ")
                    .append(mdCell(table.getSystemCode()))
                    .append(" | ")
                    .append(mdCell(table.getName()))
                    .append(" | ")
                    .append(mdCell(table.getCnName()))
                    .append(" | ")
                    .append(elements.size())
                    .append(" | ")
                    .append(codeTableCount)
                    .append(" | ")
                    .append("[打开](tables/")
                    .append(fileNameMap.get(table.getId()))
                    .append(") |\n");
        }

        return builder.toString();
    }

    private String buildTableMarkdown(RegTable table, List<RegElement> elements, CodeLookup codeLookup) {
        StringBuilder builder = new StringBuilder();
        String title = StringUtils.defaultIfBlank(table.getCnName(), table.getName());
        builder.append("# ").append(mdText(title)).append("\n\n");
        builder.append("> 物理表名：`").append(codeText(table.getName())).append("`");
        if (StringUtils.isNotBlank(table.getSystemCode())) {
            builder.append("  \n> 所属系统：`").append(codeText(table.getSystemCode())).append("`");
        }
        builder.append("\n\n");

        builder.append("## 1. 报表概览\n\n");
        builder.append("| 项目 | 内容 |\n");
        builder.append("| --- | --- |\n");
        appendKvRow(builder, "报表ID", nullSafe(table.getId()));
        appendKvRow(builder, "排序号", nullSafe(table.getSortOrder()));
        appendKvRow(builder, "物理表名", codeWrap(table.getName()));
        appendKvRow(builder, "中文名", table.getCnName());
        appendKvRow(builder, "所属系统", codeWrap(table.getSystemCode()));
        appendKvRow(builder, "主题", table.getTheme());
        appendKvRow(builder, "频率", table.getFrequency());
        appendKvRow(builder, "来源类型", table.getSourceType());
        appendKvRow(builder, "自动取数状态", table.getAutoFetchStatus());
        appendKvRow(builder, "发文号", table.getDispatchNo());
        appendKvRow(builder, "生效日期", formatDate(table.getEffectiveDate()));
        appendKvRow(builder, "科目编码", table.getSubjectCode());
        appendKvRow(builder, "科目名称", table.getSubjectName());
        appendKvRow(builder, "负责人", table.getOwner());
        appendKvRow(builder, "状态", formatStatus(table.getStatus()));
        builder.append("\n");

        appendRichSection(builder, "## 2. 填报与口径说明", table.getBusinessCaliber(), "业务口径");
        appendRichSection(builder, null, table.getFillInstruction(), "填报说明");
        appendRichSection(builder, null, table.getDevNotes(), "研发备注");

        builder.append("## 3. 字段总览\n\n");
        builder.append("- 字段总数：`").append(elements.size()).append("`\n");
        builder.append("- 字段类型分布：`FIELD` = ")
                .append(countByType(elements, "FIELD"))
                .append("，`INDICATOR` = ")
                .append(countByType(elements, "INDICATOR"))
                .append("\n");
        builder.append("- 引用码表数：`")
                .append(elements.stream().map(RegElement::getCodeTableCode).filter(StringUtils::isNotBlank).distinct().count())
                .append("`\n\n");

        builder.append("| 序号 | 类型 | 字段名 | 中文名 | 数据类型 | 长度 | 主键 | 可空 | 码表 | 自动取数 | 状态 |\n");
        builder.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n");
        for (RegElement element : elements) {
            builder.append("| ")
                    .append(nullSafe(element.getSortOrder()))
                    .append(" | ")
                    .append(mdCell(element.getType()))
                    .append(" | ")
                    .append(codeCell(element.getName()))
                    .append(" | ")
                    .append(mdCell(element.getCnName()))
                    .append(" | ")
                    .append(mdCell(element.getDataType()))
                    .append(" | ")
                    .append(mdCell(element.getLength()))
                    .append(" | ")
                    .append(mdCell(formatBooleanFlag(element.getIsPk())))
                    .append(" | ")
                    .append(mdCell(formatBooleanFlag(element.getNullable() == null ? null : element.getNullable() == 1 ? 1 : 0)))
                    .append(" | ")
                    .append(codeCell(element.getCodeTableCode()))
                    .append(" | ")
                    .append(mdCell(element.getAutoFetchStatus()))
                    .append(" | ")
                    .append(mdCell(formatStatus(element.getStatus())))
                    .append(" |\n");
        }
        builder.append("\n");

        builder.append("## 4. 字段详细说明\n\n");
        for (int i = 0; i < elements.size(); i++) {
            RegElement element = elements.get(i);
            builder.append("### 4.")
                    .append(i + 1)
                    .append(" ")
                    .append(mdText(StringUtils.defaultIfBlank(element.getCnName(), element.getName())))
                    .append("\n\n");
            builder.append("| 项目 | 内容 |\n");
            builder.append("| --- | --- |\n");
            appendKvRow(builder, "元素ID", nullSafe(element.getId()));
            appendKvRow(builder, "类型", element.getType());
            appendKvRow(builder, "字段名", codeWrap(element.getName()));
            appendKvRow(builder, "中文名", element.getCnName());
            appendKvRow(builder, "数据类型", element.getDataType());
            appendKvRow(builder, "长度", element.getLength());
            appendKvRow(builder, "排序号", nullSafe(element.getSortOrder()));
            appendKvRow(builder, "是否主键", formatBooleanFlag(element.getIsPk()));
            appendKvRow(builder, "是否允许为空", formatNullable(element.getNullable()));
            appendKvRow(builder, "是否脱敏", formatBooleanFlag(element.getIsDesensitized()));
            appendKvRow(builder, "脱敏类型", element.getDesensitizeType());
            appendKvRow(builder, "自动取数状态", element.getAutoFetchStatus());
            appendKvRow(builder, "发文号", element.getDispatchNo());
            appendKvRow(builder, "生效日期", formatDate(element.getEffectiveDate()));
            appendKvRow(builder, "值域", element.getValueRange());
            appendKvRow(builder, "校验规则", element.getValidationRule());
            appendKvRow(builder, "负责人", element.getOwner());
            appendKvRow(builder, "状态", formatStatus(element.getStatus()));
            appendKvRow(builder, "是否初始化项", formatBooleanFlag(element.getIsInit()));
            appendKvRow(builder, "是否归并公式项", formatBooleanFlag(element.getIsMergeFormula()));
            appendKvRow(builder, "是否填报业务项", formatBooleanFlag(element.getIsFillBusiness()));
            appendKvRow(builder, "引用码表", codeWrap(element.getCodeTableCode()));
            builder.append("\n");

            appendTextBlock(builder, "业务口径", element.getBusinessCaliber());
            appendTextBlock(builder, "填报说明", element.getFillInstruction());
            appendTextBlock(builder, "研发备注", element.getDevNotes());
            appendCodeBlock(builder, "计算公式", element.getFormula(), "");
            appendCodeBlock(builder, "取数 SQL", element.getFetchSql(), "sql");
            appendCodeBlock(builder, "代码片段", element.getCodeSnippet(), "java");

            if (StringUtils.isNotBlank(element.getCodeTableCode())) {
                appendCodeTableSection(builder, element, codeLookup);
            }
        }

        return builder.toString();
    }

    private void appendCodeTableSection(StringBuilder builder, RegElement element, CodeLookup codeLookup) {
        String tableCode = element.getCodeTableCode();
        CodeTable codeTable = codeLookup.codeTableMap.get(tableCode);
        List<CodeDirectory> codeDirectories = codeLookup.codeDirectoryMap
                .getOrDefault(tableCode, Collections.emptyList())
                .stream()
                .sorted(Comparator.comparing(CodeDirectory::getSortOrder, Comparator.nullsLast(Integer::compareTo))
                        .thenComparing(CodeDirectory::getCode, Comparator.nullsLast(String::compareTo)))
                .toList();

        builder.append("#### 码值清单：`").append(codeText(tableCode)).append("`\n\n");
        builder.append("| 项目 | 内容 |\n");
        builder.append("| --- | --- |\n");
        appendKvRow(builder, "码表编码", codeWrap(tableCode));
        appendKvRow(builder, "码表名称", codeTable != null ? codeTable.getTableName() : null);
        appendKvRow(builder, "所属系统", codeTable != null ? codeWrap(codeTable.getSystemCode()) : null);
        appendKvRow(builder, "标准依据", codeTable != null ? codeTable.getStandard() : null);
        appendKvRow(builder, "码表说明", codeTable != null ? codeTable.getDescription() : null);
        appendKvRow(builder, "码值数量", String.valueOf(codeDirectories.size()));
        builder.append("\n");

        if (codeDirectories.isEmpty()) {
            builder.append("> 未查询到该码表的码值明细。\n\n");
            return;
        }

        if (shouldSummarizeOnly(codeTable, tableCode)) {
            builder.append("> 该码表属于地区/行业类大码表，导出时仅保留说明，不展开逐条码值，避免文档过长。\n\n");
            return;
        }

        builder.append("| 排序 | 码值 | 名称 | 上级码值 | 层级 | 开始日期 | 结束日期 | 描述 | 标准依据 |\n");
        builder.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n");
        for (CodeDirectory code : codeDirectories) {
            builder.append("| ")
                    .append(nullSafe(code.getSortOrder()))
                    .append(" | ")
                    .append(codeCell(code.getCode()))
                    .append(" | ")
                    .append(mdCell(code.getName()))
                    .append(" | ")
                    .append(codeCell(code.getParentCode()))
                    .append(" | ")
                    .append(mdCell(code.getLevel()))
                    .append(" | ")
                    .append(mdCell(formatDate(code.getStartDate())))
                    .append(" | ")
                    .append(mdCell(formatDate(code.getEndDate())))
                    .append(" | ")
                    .append(mdCell(code.getDescription()))
                    .append(" | ")
                    .append(mdCell(code.getStandard()))
                    .append(" |\n");
        }
        builder.append("\n");
    }

    private boolean shouldSummarizeOnly(CodeTable codeTable, String tableCode) {
        String text = String.join(" ",
                StringUtils.defaultString(tableCode),
                codeTable != null ? StringUtils.defaultString(codeTable.getTableName()) : "",
                codeTable != null ? StringUtils.defaultString(codeTable.getDescription()) : "")
                .toLowerCase();

        List<String> keywords = List.of(
                "地区",
                "区域",
                "行政区划",
                "国家",
                "国家代码",
                "国别",
                "region",
                "area",
                "country",
                "nation",
                "province",
                "city",
                "county",
                "industry",
                "行业",
                "国民经济行业",
                "行业分类",
                "产业分类",
                "sector");

        return keywords.stream().anyMatch(text::contains);
    }

    private void appendRichSection(StringBuilder builder, String title, String content, String fallbackLabel) {
        if (StringUtils.isBlank(content) && title == null) {
            return;
        }

        if (title != null) {
            builder.append(title).append("\n\n");
        }

        if (StringUtils.isBlank(content)) {
            builder.append("- ").append(fallbackLabel).append("：未维护\n\n");
            return;
        }

        builder.append(content.trim()).append("\n\n");
    }

    private void appendTextBlock(StringBuilder builder, String label, String content) {
        if (StringUtils.isBlank(content)) {
            return;
        }
        builder.append("**").append(label).append("**\n\n");
        builder.append(content.trim()).append("\n\n");
    }

    private void appendCodeBlock(StringBuilder builder, String label, String content, String language) {
        if (StringUtils.isBlank(content)) {
            return;
        }
        builder.append("**").append(label).append("**\n\n");
        builder.append("```").append(language).append("\n");
        builder.append(content.trim()).append("\n");
        builder.append("```\n\n");
    }

    private void appendKvRow(StringBuilder builder, String label, Object value) {
        builder.append("| ")
                .append(mdCell(label))
                .append(" | ")
                .append(mdCell(value == null ? null : String.valueOf(value)))
                .append(" |\n");
    }

    private long countByType(List<RegElement> elements, String type) {
        return elements.stream()
                .filter(item -> StringUtils.equalsIgnoreCase(type, item.getType()))
                .count();
    }

    private void writeZipEntry(ZipOutputStream zos, String path, String content) throws IOException {
        ZipEntry entry = new ZipEntry(path);
        zos.putNextEntry(entry);
        zos.write(content.getBytes(StandardCharsets.UTF_8));
        zos.closeEntry();
    }

    private String sanitizeFileName(String raw) {
        if (StringUtils.isBlank(raw)) {
            return "";
        }
        return raw.replaceAll("[\\\\/:*?\"<>|\\s]+", "_")
                .replaceAll("_+", "_")
                .replaceAll("^_|_$", "");
    }

    private String mdCell(String value) {
        if (StringUtils.isBlank(value)) {
            return "-";
        }
        return value.replace("|", "\\|")
                .replace("\r\n", "<br>")
                .replace("\n", "<br>");
    }

    private String mdText(String value) {
        if (StringUtils.isBlank(value)) {
            return "未命名报表";
        }
        return value.replace("\r\n", " ").replace("\n", " ");
    }

    private String codeWrap(String value) {
        if (StringUtils.isBlank(value)) {
            return "-";
        }
        return "`" + codeText(value) + "`";
    }

    private String codeCell(String value) {
        if (StringUtils.isBlank(value)) {
            return "-";
        }
        return "`" + codeText(value) + "`";
    }

    private String codeText(String value) {
        return value.replace("`", "\\`");
    }

    private String nullSafe(Object value) {
        return value == null ? "-" : String.valueOf(value);
    }

    private String formatBooleanFlag(Integer value) {
        if (value == null) {
            return "-";
        }
        return value == 1 ? "是" : "否";
    }

    private String formatNullable(Integer value) {
        if (value == null) {
            return "-";
        }
        return value == 1 ? "允许" : "不允许";
    }

    private String formatStatus(Integer value) {
        if (value == null) {
            return "-";
        }
        return value == 1 ? "正常" : "停用";
    }

    private String formatDate(LocalDate date) {
        return date == null ? "-" : DATE_FORMATTER.format(date);
    }

    private record CodeLookup(
            Map<String, CodeTable> codeTableMap,
            Map<String, List<CodeDirectory>> codeDirectoryMap) {
    }
}
