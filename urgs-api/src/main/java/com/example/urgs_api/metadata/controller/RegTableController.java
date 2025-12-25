package com.example.urgs_api.metadata.controller;

import com.alibaba.excel.EasyExcel;
import com.alibaba.excel.ExcelWriter;
import com.alibaba.excel.write.metadata.WriteSheet;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.metadata.dto.RegElementImportExportDTO;
import com.example.urgs_api.metadata.dto.RegTableImportExportDTO;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.metadata.service.RegElementService;
import com.example.urgs_api.metadata.service.RegTableService;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URLEncoder;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@RestController
@RequestMapping("/api/reg/table")
/**
 * 报表及指标管理控制器
 * 处理报表（RegTable）和指标元素（RegElement）的CRUD及导入导出、代码片段同步等
 */
public class RegTableController {

    @Autowired
    private RegTableService regTableService;

    @Autowired
    private RegElementService regElementService;

    /**
     * 分页查询报表列表
     *
     * @param keyword    搜索关键词（匹配名称、中文名、代码）
     * @param systemCode 系统代码
     * @param page       页码
     * @param size       每页大小
     * @return 报表分页结果
     */
    @GetMapping("/list")
    public PageResult<RegTable> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String systemCode,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        QueryWrapper<RegTable> query = new QueryWrapper<>();

        if (systemCode != null && !systemCode.isEmpty()) {
            query.eq("system_code", systemCode);
        }

        if (keyword != null && !keyword.isEmpty()) {
            String kw = keyword.toLowerCase();
            query.and(w -> w.like("LOWER(name)", kw)
                    .or().like("LOWER(cn_name)", kw));
        }

        query.orderByAsc("sort_order");

        com.baomidou.mybatisplus.extension.plugins.pagination.Page<RegTable> pageParam = new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(
                page, size);
        return PageResult.of(regTableService.page(pageParam, query));
    }

    /**
     * 获取报表详情
     *
     * @param id 报表ID
     * @return 报表详情
     */
    @GetMapping("/{id}")
    public RegTable get(@PathVariable Long id) {
        return regTableService.getById(id);
    }

    /**
     * 新增或更新报表
     *
     * @param regTable 报表对象
     * @return 是否成功
     */
    @PostMapping
    public boolean save(@RequestBody RegTable regTable) {
        if (regTable.getId() == null) {
            regTable.setCreateTime(LocalDateTime.now());
        }
        regTable.setUpdateTime(LocalDateTime.now());
        if (regTable.getStatus() == null) {
            regTable.setStatus(1);
        }
        return regTableService.saveOrUpdate(regTable);
    }

    /**
     * 删除报表
     *
     * @param id 报表ID
     * @return 是否成功
     */
    @DeleteMapping("/{id}")
    public boolean delete(@PathVariable Long id) {
        return regTableService.removeById(id);
    }

    /**
     * 同步代码片段
     * 从 docs/sql/{systemCode}/ 目录下读取 SQL 文件，
     * 根据指标编号匹配提取对应的 SQL 语句作为代码片段
     */
    @PostMapping("/sync-code-snippets")
    public Map<String, Object> syncCodeSnippets(@RequestParam String systemCode) {
        Map<String, Object> result = new HashMap<>();
        int matchedCount = 0;
        int updatedCount = 0;
        List<String> matchedIndicators = new ArrayList<>();

        try {
            // 1. 获取项目根目录下的 SQL 文件目录
            String basePath = System.getProperty("user.dir");
            java.nio.file.Path sqlDir = java.nio.file.Paths.get(basePath, "docs", "sql", systemCode);

            if (!java.nio.file.Files.exists(sqlDir)) {
                result.put("success", false);
                result.put("message", "SQL 目录不存在: " + sqlDir.toString());
                return result;
            }

            // 2. 读取所有 SQL 文件内容
            Map<String, String> sqlFileContents = new HashMap<>();
            try (java.nio.file.DirectoryStream<java.nio.file.Path> stream = java.nio.file.Files
                    .newDirectoryStream(sqlDir, "*.sql")) {
                for (java.nio.file.Path sqlFile : stream) {
                    String content = java.nio.file.Files.readString(sqlFile);
                    String fileName = sqlFile.getFileName().toString().toLowerCase();
                    sqlFileContents.put(fileName, content);
                }
            }

            if (sqlFileContents.isEmpty()) {
                result.put("success", false);
                result.put("message", "SQL 目录中没有找到 .sql 文件");
                return result;
            }

            // 3. 查询该系统下所有表
            List<RegTable> tables = regTableService.list(
                    new LambdaQueryWrapper<RegTable>().eq(RegTable::getSystemCode, systemCode));

            // 4. 遍历每个表的指标，查找匹配的代码片段
            for (RegTable table : tables) {
                List<RegElement> elements = regElementService.list(
                        new LambdaQueryWrapper<RegElement>()
                                .eq(RegElement::getTableId, table.getId())
                                .eq(RegElement::getType, "INDICATOR"));

                for (RegElement element : elements) {
                    String indicatorCode = element.getCode();
                    if (indicatorCode == null || indicatorCode.isEmpty()) {
                        continue;
                    }

                    // 在所有 SQL 文件中查找包含该指标编号的语句
                    for (Map.Entry<String, String> entry : sqlFileContents.entrySet()) {
                        String sqlContent = entry.getValue();

                        // 查找包含该指标编号的 SQL 语句
                        String codeSnippet = extractCodeSnippet(sqlContent, indicatorCode);
                        if (codeSnippet != null && !codeSnippet.isEmpty()) {
                            // 更新元素的代码片段
                            element.setCodeSnippet(codeSnippet);
                            element.setUpdateTime(LocalDateTime.now());
                            regElementService.updateById(element);

                            matchedCount++;
                            updatedCount++;
                            matchedIndicators.add(indicatorCode);
                            break; // 找到就停止，每个指标只匹配一次
                        }
                    }
                }
            }

            result.put("success", true);
            result.put("message", String.format("同步完成，共匹配 %d 个指标", matchedCount));
            result.put("matchedCount", matchedCount);
            result.put("updatedCount", updatedCount);
            result.put("matchedIndicators", matchedIndicators);

        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "同步失败: " + e.getMessage());
            e.printStackTrace();
        }

        return result;
    }

    /**
     * 生成 Hive SQL 文件
     * 优化点：
     * 1. 逻辑去重：对于相同的取数逻辑，使用 CTE (WITH) 语法只定义一次。
     * 2. 文件分片：支持按表名分片（table_1.sql, table_2.sql），避免单文件过大。
     */
    @PostMapping("/generateHiveSql")
    public Map<String, Object> generateHiveSql(@RequestParam String systemCode) {
        Map<String, Object> result = new HashMap<>();
        int totalIndicatorCount = 0;
        int totalFilesGenerated = 0;

        try {
            // 1. 查询该系统下所有表
            List<RegTable> tables = regTableService.list(
                    new LambdaQueryWrapper<RegTable>().eq(RegTable::getSystemCode, systemCode));

            for (RegTable table : tables) {
                String tableName = table.getName();
                List<RegElement> elements = regElementService.list(
                        new LambdaQueryWrapper<RegElement>()
                                .eq(RegElement::getTableId, table.getId())
                                .eq(RegElement::getType, "INDICATOR")
                                .isNotNull(RegElement::getCodeSnippet)
                                .ne(RegElement::getCodeSnippet, ""));

                if (elements.isEmpty())
                    continue;

                // 2. 按逻辑对指标进行分组
                // LogicKey -> List<IndicatorCode>
                Map<String, List<String>> logicGroups = new LinkedHashMap<>();
                for (RegElement element : elements) {
                    String indicatorCode = element.getCode();
                    String codeSnippet = element.getCodeSnippet();

                    // 使用占位符替换表名，以此作为逻辑主键
                    String logicKey = replaceInsertTableNameWithBackticks(codeSnippet, "__INDICATOR_PLACEHOLDER__");
                    logicGroups.computeIfAbsent(logicKey, k -> new ArrayList<>()).add(indicatorCode);
                    totalIndicatorCount++;
                }

                // 3. 将逻辑组分片生成文件 (例如每 100 个逻辑组一个文件)
                int maxGroupsPerFile = 100;
                List<String> allLogicKeys = new ArrayList<>(logicGroups.keySet());
                for (int i = 0; i < allLogicKeys.size(); i += maxGroupsPerFile) {
                    int end = Math.min(i + maxGroupsPerFile, allLogicKeys.size());
                    List<String> subKeys = allLogicKeys.subList(i, end);

                    StringBuilder fileContent = new StringBuilder();
                    for (int groupIdx = 0; groupIdx < subKeys.size(); groupIdx++) {
                        String logicKey = subKeys.get(groupIdx);
                        List<String> indicatorCodes = logicGroups.get(logicKey);

                        // 尝试提取 SELECT 部分作为 CTE 内容
                        // 如果无法提取（比如是复杂的多语句），则退化为普通模式
                        String selectPart = extractSelectPart(logicKey);

                        if (selectPart != null && indicatorCodes.size() > 1) {
                            fileContent.append("-- ========== 逻辑组 ").append(groupIdx).append(": 共 ")
                                    .append(indicatorCodes.size()).append(" 个指标 ==========\n");
                            fileContent.append("FROM (\n")
                                    .append(selectPart).append("\n) q_").append(groupIdx).append("\n");
                            for (int k = 0; k < indicatorCodes.size(); k++) {
                                String code = indicatorCodes.get(k);
                                // 尝试从本组的指标逻辑中找回原本的字段列表（如果有的话）
                                // 注意：此处简化处理，假设同组逻辑的字段列表也是一致的
                                String columnList = extractColumnList(logicKey);
                                // Ensure newline after column list to prevent potential comment issues
                                fileContent.append("INSERT INTO `").append(code).append("` ")
                                        .append(columnList != null ? "(" + columnList + ")\n" : "")
                                        .append("SELECT *");
                                if (k == indicatorCodes.size() - 1) {
                                    fileContent.append(";");
                                }
                                fileContent.append("\n");
                            }
                        } else {
                            // 退化模式：逐个输出（或者只有一个指标时也无需逻辑聚合）
                            for (String code : indicatorCodes) {
                                String snippet = replaceInsertTableNameWithBackticks(logicKey, code);
                                fileContent.append("-- 指标: ").append(code).append("\n")
                                        .append(snippet);
                                if (!snippet.trim().endsWith(";"))
                                    fileContent.append(";");
                                fileContent.append("\n\n");
                            }
                        }
                        fileContent.append("\n");
                    }

                    // 生成物理文件
                    String fileNameSuffix = (allLogicKeys.size() > maxGroupsPerFile) ? "_" + (i / maxGroupsPerFile + 1)
                            : "";
                    writeTableSqlFile(tableName + fileNameSuffix, fileContent.toString());
                    totalFilesGenerated++;
                }
            }

            result.put("success", true);
            result.put("message",
                    String.format("生成完成，共处理 %d 个指标，分片生成 %d 个 SQL 文件", totalIndicatorCount, totalFilesGenerated));
            result.put("indicatorCount", totalIndicatorCount);
            result.put("filesGenerated", totalFilesGenerated);

        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "生成失败: " + e.getMessage());
            e.printStackTrace();
        }

        return result;
    }

    /**
     * 从带占位符的脚本中提取 SELECT 部分
     * 支持 INSERT INTO / INSERT OVERWRITE [TABLE] `__INDICATOR_PLACEHOLDER__` SELECT
     * ...
     */
    private String extractSelectPart(String logicKey) {
        String placeholder = "__INDICATOR_PLACEHOLDER__";
        String upperLogic = logicKey.toUpperCase();

        // 正则查找占位符之后，SELECT 及其之后的所有内容
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile(
                "INSERT\\s+(?:INTO|OVERWRITE)\\s+(?:TABLE\\s+)?(?:`?" + placeholder + "`?|`?[\\w.]+`?)",
                java.util.regex.Pattern.CASE_INSENSITIVE);
        java.util.regex.Matcher matcher = pattern.matcher(logicKey);

        if (matcher.find()) {
            int placeholderEnd = matcher.end();
            int selectStart = upperLogic.indexOf("SELECT", placeholderEnd);
            if (selectStart != -1) {
                String selectPart = logicKey.substring(selectStart).trim();
                if (selectPart.endsWith(";")) {
                    selectPart = selectPart.substring(0, selectPart.length() - 1);
                }
                return selectPart;
            }
        }
        return null;
    }

    /**
     * 提取 INSERT 语句中的字段列表，如 (col1, col2)
     */
    /**
     * 提取 INSERT 语句中的字段列表，如 (col1, col2)
     * 先移除注释，再进行正则匹配，防止注释中包含 ')' 导致截断
     */
    private String extractColumnList(String logicKey) {
        // 移除注释
        String cleanLogic = removeComments(logicKey);

        String placeholder = "__INDICATOR_PLACEHOLDER__";
        // 匹配占位符到 SELECT 之间的内容，捕获括号内的部分
        // 使用非贪婪匹配或更宽松的字符类，因为注释已移除，风险降低
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile(
                "INSERT\\s+(?:INTO|OVERWRITE)\\s+(?:TABLE\\s+)?(?:`?" + placeholder + "`?)\\s*\\(([^)]+)\\)",
                java.util.regex.Pattern.CASE_INSENSITIVE);
        java.util.regex.Matcher matcher = pattern.matcher(cleanLogic);
        if (matcher.find()) {
            return matcher.group(1).trim();
        }
        return null;
    }

    /**
     * 移除 SQL 中的单行注释 (--) 和多行注释 (&#47;* ... *&#47;)
     * 注意：简单的正则可能误伤字符串中的注释符号，但在提取字段列表场景下通常可接受
     */
    private String removeComments(String sql) {
        if (sql == null)
            return null;
        // 移除 /* ... */
        String noBlockComments = sql.replaceAll("/\\*[\\s\\S]*?\\*/", " ");
        // 移除 -- ... (直到行尾)
        // 注意：需处理 Windows/Unix 换行
        String noLineComments = noBlockComments.replaceAll("--.*", " ");
        return noLineComments.trim();
    }

    private void writeTableSqlFile(String fileName, String content) throws IOException {
        String basePath = System.getProperty("user.dir");
        java.nio.file.Path targetDir = java.nio.file.Paths.get(basePath).getParent()
                .resolve("urgs-agent").resolve("tests").resolve("sql").resolve("hive");
        java.nio.file.Files.createDirectories(targetDir);

        java.nio.file.Path sqlFile = targetDir.resolve(fileName + ".sql");
        String header = String.format(
                "-- ============================================================\n" +
                        "-- 文件名: %s.sql\n" +
                        "-- 生成时间: %s\n" +
                        "-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力\n" +
                        "-- ============================================================\n\n",
                fileName,
                LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));

        java.nio.file.Files.writeString(sqlFile, header + content, java.nio.charset.StandardCharsets.UTF_8);
    }

    /**
     * 替换 INSERT INTO 后面的表名为用反引号包裹的指标号
     * 支持带前缀（如 schema.table_name）和不带前缀的情况
     */
    private String replaceInsertTableNameWithBackticks(String codeSnippet, String indicatorCode) {
        if (codeSnippet == null || indicatorCode == null) {
            return codeSnippet;
        }
        // 正则匹配 INSERT (INTO|OVERWRITE) [TABLE] [schema.]table_name 或已替换过的占位符
        // 增加对反引号的处理
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile(
                "(INSERT\\s+(?:INTO|OVERWRITE)\\s+(?:TABLE\\s+)?)(?:\\w+\\.)?(`?[\\w]+`?)",
                java.util.regex.Pattern.CASE_INSENSITIVE);
        java.util.regex.Matcher matcher = pattern.matcher(codeSnippet);
        StringBuffer result = new StringBuffer();
        while (matcher.find()) {
            // 使用反引号包裹的指标号替换
            String replacement = matcher.group(1) + "`" + indicatorCode + "`";
            matcher.appendReplacement(result, java.util.regex.Matcher.quoteReplacement(replacement));
        }
        matcher.appendTail(result);
        return result.toString();
    }

    // 已移除旧的 generateSqlFiles，由新的 writeTableSqlFile 替代

    /**
     * 从 SQL 内容中提取包含指定指标编号的代码片段
     */
    private String extractCodeSnippet(String sqlContent, String indicatorCode) {
        if (sqlContent == null || indicatorCode == null) {
            return null;
        }

        // 将 SQL 内容按语句分割（以分号为分隔符）
        String[] statements = sqlContent.split(";");
        StringBuilder matchedSnippets = new StringBuilder();

        for (String stmt : statements) {
            String trimmedStmt = stmt.trim();
            if (trimmedStmt.isEmpty()) {
                continue;
            }

            // 检查该语句是否包含指标编号（精确匹配，考虑引号包围）
            // 匹配 'G01_5..B' 或 "G01_5..B" 形式
            if (trimmedStmt.contains("'" + indicatorCode + "'") ||
                    trimmedStmt.contains("\"" + indicatorCode + "\"") ||
                    trimmedStmt.contains("'" + indicatorCode.toUpperCase() + "'") ||
                    trimmedStmt.contains("'" + indicatorCode.toLowerCase() + "'")) {

                if (matchedSnippets.length() > 0) {
                    matchedSnippets.append("\n\n");
                }
                matchedSnippets.append(trimmedStmt).append(";");
            }
        }

        return matchedSnippets.length() > 0 ? matchedSnippets.toString() : null;
    }

    /**
     * 批量导出报表（多 Sheet Excel）
     * 第一个 Sheet：报表列表
     * 后续 Sheet：每个报表的字段详情（以报表编码命名）
     */
    @GetMapping("/export")
    public void exportTables(
            @RequestParam(required = false) String systemCode,
            @RequestParam(required = false) String tableIds,
            HttpServletResponse response) throws IOException {

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");
        String fileName = URLEncoder.encode("报表数据导出", "UTF-8").replaceAll("\\+", "%20");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

        // 查询报表
        List<RegTable> tables;
        if (tableIds != null && !tableIds.isEmpty()) {
            // 导出选中的报表
            List<Long> ids = Arrays.stream(tableIds.split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .map(Long::parseLong)
                    .toList();
            tables = regTableService.listByIds(ids);
        } else {
            // 导出全部（或按系统过滤）
            LambdaQueryWrapper<RegTable> query = new LambdaQueryWrapper<>();
            if (systemCode != null && !systemCode.isEmpty()) {
                query.eq(RegTable::getSystemCode, systemCode);
            }
            query.orderByAsc(RegTable::getSortOrder);
            tables = regTableService.list(query);
        }

        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

        try (ExcelWriter excelWriter = EasyExcel.write(response.getOutputStream()).build()) {
            // 1. 写报表汇总 Sheet
            List<RegTableImportExportDTO> tableDtos = new ArrayList<>();
            for (RegTable table : tables) {
                RegTableImportExportDTO dto = new RegTableImportExportDTO();
                dto.setSortOrder(table.getSortOrder());
                dto.setName(table.getName());
                dto.setCnName(table.getCnName());
                // dto.setCode(table.getCode()); // Removed
                dto.setSystemCode(table.getSystemCode());
                dto.setSubjectCode(table.getSubjectCode());
                dto.setSubjectName(table.getSubjectName());
                dto.setTheme(table.getTheme());
                dto.setFrequency(table.getFrequency());
                dto.setSourceType(table.getSourceType());
                dto.setAutoFetchStatus(table.getAutoFetchStatus());
                dto.setDocumentNo(table.getDocumentNo());
                dto.setDocumentTitle(table.getDocumentTitle());
                dto.setEffectiveDate(
                        table.getEffectiveDate() != null ? table.getEffectiveDate().format(dateFormatter) : null);
                dto.setBusinessCaliber(table.getBusinessCaliber());
                dto.setDevNotes(table.getDevNotes());
                dto.setOwner(table.getOwner());
                tableDtos.add(dto);
            }

            WriteSheet summarySheet = EasyExcel.writerSheet(0, "报表列表")
                    .head(RegTableImportExportDTO.class)
                    .build();
            excelWriter.write(tableDtos, summarySheet);

            // 2. 每个报表一个详情 Sheet
            int sheetIndex = 1;
            for (RegTable table : tables) {
                String sheetName = table.getName();
                if (sheetName == null || sheetName.isEmpty()) {
                    sheetName = "Sheet" + sheetIndex; // Fallback
                }
                // Excel sheet 名称限制 31 字符
                if (sheetName.length() > 31) {
                    sheetName = sheetName.substring(0, 31);
                }

                List<RegElement> elements = regElementService.list(
                        new LambdaQueryWrapper<RegElement>()
                                .eq(RegElement::getTableId, table.getId())
                                .orderByAsc(RegElement::getSortOrder));

                List<RegElementImportExportDTO> elementDtos = new ArrayList<>();
                for (RegElement el : elements) {
                    RegElementImportExportDTO dto = new RegElementImportExportDTO();
                    dto.setSortOrder(el.getSortOrder());
                    dto.setType(el.getType());
                    dto.setName(el.getName());
                    dto.setCnName(el.getCnName());
                    dto.setCode(el.getCode());
                    dto.setDataType(el.getDataType());
                    dto.setLength(el.getLength());
                    dto.setIsPk(el.getIsPk());
                    dto.setNullable(el.getNullable());
                    dto.setFormula(el.getFormula());
                    dto.setFetchSql(el.getFetchSql());
                    dto.setCodeTableCode(el.getCodeTableCode());
                    dto.setValueRange(el.getValueRange());
                    dto.setValidationRule(el.getValidationRule());
                    dto.setDocumentNo(el.getDocumentNo());
                    dto.setDocumentTitle(el.getDocumentTitle());
                    dto.setEffectiveDate(
                            el.getEffectiveDate() != null ? el.getEffectiveDate().format(dateFormatter) : null);
                    dto.setBusinessCaliber(el.getBusinessCaliber());
                    dto.setFillInstruction(el.getFillInstruction());
                    dto.setDevNotes(el.getDevNotes());
                    dto.setAutoFetchStatus(el.getAutoFetchStatus());
                    dto.setOwner(el.getOwner());
                    dto.setStatus(el.getStatus());
                    dto.setIsInit(el.getIsInit());
                    dto.setIsMergeFormula(el.getIsMergeFormula());
                    dto.setIsFillBusiness(el.getIsFillBusiness());
                    dto.setCodeSnippet(el.getCodeSnippet());
                    elementDtos.add(dto);
                }

                WriteSheet detailSheet = EasyExcel.writerSheet(sheetIndex++, sheetName)
                        .head(RegElementImportExportDTO.class)
                        .build();
                excelWriter.write(elementDtos, detailSheet);
            }
        }
    }

    /**
     * 批量导入报表（多 Sheet Excel）
     * 第一个 Sheet：报表列表（按 code 匹配更新/新增）
     * 后续 Sheet：字段详情（按 Sheet 名匹配报表 code）
     */
    @PostMapping("/import")
    public Map<String, Object> importTables(@RequestParam("file") MultipartFile file) throws IOException {
        Map<String, Object> result = new HashMap<>();
        int tableCount = 0;
        int elementCount = 0;

        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

        try (Workbook workbook = new XSSFWorkbook(file.getInputStream())) {
            // 1. 读取第一个 Sheet（报表列表）
            Sheet summarySheet = workbook.getSheetAt(0);
            Map<String, RegTable> nameToTable = new HashMap<>();

            // 跳过表头
            for (int i = 1; i <= summarySheet.getLastRowNum(); i++) {
                Row row = summarySheet.getRow(i);
                if (row == null)
                    continue;

                Integer sortOrder = getIntValue(row.getCell(0)); // 序号
                if (sortOrder == null)
                    continue;

                // 查找或创建报表 (按序号匹配)
                RegTable table = regTableService.getOne(
                        new LambdaQueryWrapper<RegTable>().eq(RegTable::getSortOrder, sortOrder));
                if (table == null) {
                    table = new RegTable();
                    table.setCreateTime(LocalDateTime.now());
                    table.setSortOrder(sortOrder);
                }

                table.setCnName(getCellValue(row.getCell(1))); // 中文名/表名 (Index 1)
                table.setName(getCellValue(row.getCell(2))); // 表名 (Index 2)
                // Index 3: System Code
                table.setSystemCode(getCellValue(row.getCell(3)));
                table.setSubjectCode(getCellValue(row.getCell(4)));
                table.setSubjectName(getCellValue(row.getCell(5)));
                table.setTheme(getCellValue(row.getCell(6)));
                table.setFrequency(getCellValue(row.getCell(7)));
                table.setSourceType(getCellValue(row.getCell(8)));
                table.setAutoFetchStatus(getCellValue(row.getCell(9)));
                table.setDocumentNo(getCellValue(row.getCell(10)));
                table.setDocumentTitle(getCellValue(row.getCell(11)));
                String effDate = getCellValue(row.getCell(12));
                if (effDate != null && !effDate.isEmpty()) {
                    try {
                        table.setEffectiveDate(LocalDate.parse(effDate, dateFormatter));
                    } catch (Exception ignored) {
                    }
                }
                table.setBusinessCaliber(getCellValue(row.getCell(13)));
                table.setDevNotes(getCellValue(row.getCell(14)));
                table.setOwner(getCellValue(row.getCell(15)));
                table.setUpdateTime(LocalDateTime.now());
                table.setStatus(1);

                regTableService.saveOrUpdate(table);
                if (table.getName() != null) {
                    nameToTable.put(table.getName(), table);
                }
                tableCount++;
            }

            // 2. 读取后续 Sheet（字段详情）
            for (int sheetIdx = 1; sheetIdx < workbook.getNumberOfSheets(); sheetIdx++) {
                Sheet sheet = workbook.getSheetAt(sheetIdx);
                String sheetName = sheet.getSheetName();

                // 根据 sheet 名找到对应的报表 (使用物理表名匹配)
                RegTable table = nameToTable.get(sheetName);
                if (table == null) {
                    // 尝试从数据库查找 (按名称)
                    try {
                        table = regTableService.getOne(
                                new LambdaQueryWrapper<RegTable>().eq(RegTable::getName, sheetName));
                    } catch (Exception e) {
                        // ignore duplicates error for robustness
                    }
                }
                if (table == null)
                    continue;

                // 删除该表原有字段（覆盖更新）
                regElementService.remove(
                        new LambdaQueryWrapper<RegElement>().eq(RegElement::getTableId, table.getId()));

                // 导入新字段
                for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                    Row row = sheet.getRow(i);
                    if (row == null)
                        continue;

                    RegElement el = new RegElement();
                    el.setTableId(table.getId());
                    el.setSortOrder(getIntValue(row.getCell(0)));
                    el.setType(getCellValue(row.getCell(1)));
                    el.setName(getCellValue(row.getCell(2)));
                    el.setCnName(getCellValue(row.getCell(3)));
                    el.setCode(getCellValue(row.getCell(4)));
                    el.setDataType(getCellValue(row.getCell(5)));
                    el.setLength(getIntValue(row.getCell(6)));
                    el.setIsPk(getIntValue(row.getCell(7)));
                    el.setNullable(getIntValue(row.getCell(8)));
                    el.setFormula(getCellValue(row.getCell(9)));
                    el.setFetchSql(getCellValue(row.getCell(10)));
                    el.setCodeTableCode(getCellValue(row.getCell(11)));
                    el.setValueRange(getCellValue(row.getCell(12)));
                    el.setValidationRule(getCellValue(row.getCell(13)));
                    el.setDocumentNo(getCellValue(row.getCell(14)));
                    el.setDocumentTitle(getCellValue(row.getCell(15)));
                    String effDate = getCellValue(row.getCell(16));
                    if (effDate != null && !effDate.isEmpty()) {
                        try {
                            el.setEffectiveDate(LocalDate.parse(effDate, dateFormatter));
                        } catch (Exception ignored) {
                        }
                    }
                    el.setBusinessCaliber(getCellValue(row.getCell(17)));
                    el.setFillInstruction(getCellValue(row.getCell(18)));
                    el.setDevNotes(getCellValue(row.getCell(19)));
                    el.setAutoFetchStatus(getCellValue(row.getCell(20)));
                    el.setOwner(getCellValue(row.getCell(21)));
                    el.setStatus(getIntValue(row.getCell(22)));
                    if (el.getStatus() == null)
                        el.setStatus(1);

                    el.setIsInit(getIntValue(row.getCell(23)));
                    el.setIsMergeFormula(getIntValue(row.getCell(24)));
                    el.setIsFillBusiness(getIntValue(row.getCell(25)));
                    el.setCodeSnippet(getCellValue(row.getCell(26)));

                    if (el.getSortOrder() == null)
                        el.setSortOrder(0);

                    el.setCreateTime(LocalDateTime.now());
                    el.setUpdateTime(LocalDateTime.now());

                    if (el.getName() != null && !el.getName().isEmpty()) {
                        regElementService.save(el);
                        elementCount++;
                    }
                }
            }
        }

        result.put("success", true);
        result.put("tableCount", tableCount);
        result.put("elementCount", elementCount);
        return result;
    }

    private String getCellValue(Cell cell) {
        if (cell == null)
            return null;
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue() != null ? cell.getStringCellValue().trim() : null;
            case NUMERIC:
                // 可能是数字或日期
                return String.valueOf((long) cell.getNumericCellValue());
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                try {
                    return cell.getStringCellValue();
                } catch (Exception e) {
                    return String.valueOf(cell.getNumericCellValue());
                }
            default:
                return null;
        }
    }

    private Integer getIntValue(Cell cell) {
        if (cell == null)
            return null;
        try {
            if (cell.getCellType() == CellType.NUMERIC) {
                return (int) cell.getNumericCellValue();
            }
            String val = cell.getStringCellValue();
            if (val != null && !val.trim().isEmpty()) {
                return Integer.parseInt(val.trim());
            }
        } catch (Exception ignored) {
        }
        return null;
    }
}
