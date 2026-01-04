package com.example.urgs_api.metadata.controller;

import org.springframework.transaction.annotation.Transactional;

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
import org.apache.commons.lang3.StringUtils;
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
import java.util.stream.Collectors;

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
    private com.example.urgs_api.metadata.component.MaintenanceLogManager maintenanceLogManager;

    @Autowired
    private RegElementService regElementService;

    @Autowired
    private com.example.urgs_api.user.service.UserService userService;

    @Autowired
    private jakarta.servlet.http.HttpServletRequest request;

    private String getCurrentOperator() {
        Object userIdObj = request.getAttribute("userId");
        if (userIdObj != null) {
            Long userId = (Long) userIdObj;
            com.example.urgs_api.user.model.User user = userService.getById(userId);
            if (user != null) {
                return user.getName();
            }
        }
        return "admin";
    }

    /**
     * 统计报表及元素数量（可按所属系统过滤）
     *
     * @param systemCode 系统代码（可选）
     * @return 统计结果
     */
    @GetMapping("/stats")
    public Map<String, Long> stats(@RequestParam(required = false) String systemCode) {
        LambdaQueryWrapper<RegTable> tableWrapper = new LambdaQueryWrapper<>();
        if (StringUtils.isNotBlank(systemCode)) {
            tableWrapper.eq(RegTable::getSystemCode, systemCode);
        }

        long tableCount = regTableService.count(tableWrapper);
        long onlineCount = regTableService.count(tableWrapper.clone().eq(RegTable::getAutoFetchStatus, "已上线"));
        long developingCount = regTableService.count(tableWrapper.clone().eq(RegTable::getAutoFetchStatus, "开发中"));
        long notStartedCount = regTableService.count(tableWrapper.clone().eq(RegTable::getAutoFetchStatus, "未开发"));

        List<Long> tableIds = regTableService.list(tableWrapper).stream()
                .map(RegTable::getId)
                .collect(Collectors.toList());
        LambdaQueryWrapper<RegElement> elementWrapper = new LambdaQueryWrapper<>();
        if (!tableIds.isEmpty()) {
            elementWrapper.in(RegElement::getTableId, tableIds);
        } else if (StringUtils.isNotBlank(systemCode)) {
            // 指定系统且无报表时直接返回零值
            elementWrapper.eq(RegElement::getTableId, -1L);
        }

        long elementCount = regElementService.count(elementWrapper);
        long fieldCount = regElementService.count(elementWrapper.clone().eq(RegElement::getType, "FIELD"));
        long indicatorCount = regElementService.count(elementWrapper.clone().eq(RegElement::getType, "INDICATOR"));

        Map<String, Long> result = new HashMap<>();
        result.put("tableCount", tableCount);
        result.put("onlineCount", onlineCount);
        result.put("developingCount", developingCount);
        result.put("notStartedCount", notStartedCount);
        result.put("elementCount", elementCount);
        result.put("fieldCount", fieldCount);
        result.put("indicatorCount", indicatorCount);
        return result;
    }

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
    public PageResult<RegTable> list(@RequestParam(required = false) String keyword,
            @RequestParam(required = false) String systemCode, @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {

        QueryWrapper<RegTable> query = new QueryWrapper<>();

        if (systemCode != null && !systemCode.isEmpty()) {
            query.eq("system_code", systemCode);
        }

        if (keyword != null && !keyword.isEmpty()) {
            String kw = keyword.toLowerCase();
            query.and(w -> w.like("LOWER(name)", kw).or().like("LOWER(cn_name)", kw));
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
        RegTable oldTable = null;
        if (regTable.getId() != null) {
            oldTable = regTableService.getById(regTable.getId());
        } else {
            regTable.setCreateTime(LocalDateTime.now());
        }

        regTable.setUpdateTime(LocalDateTime.now());
        if (regTable.getStatus() == null) {
            regTable.setStatus(1);
        }

        boolean result = regTableService.saveOrUpdate(regTable);

        if (result) {
            maintenanceLogManager.logChange(com.example.urgs_api.metadata.component.MaintenanceLogManager.LogType.TABLE,
                    oldTable, regTable, getCurrentOperator());
        }

        return result;
    }

    /**
     * 删除报表
     *
     * @param id 报表ID
     * @return 是否成功
     */
    @DeleteMapping("/{id}")
    public boolean delete(@PathVariable Long id) {
        RegTable oldTable = regTableService.getById(id);
        boolean result = regTableService.removeById(id);

        if (result && oldTable != null) {
            // Cascade delete: remove all associated elements (fields/indicators)
            regElementService.remove(new LambdaQueryWrapper<RegElement>().eq(RegElement::getTableId, id));

            maintenanceLogManager.logChange(com.example.urgs_api.metadata.component.MaintenanceLogManager.LogType.TABLE,
                    oldTable, null, getCurrentOperator());
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
            List<RegTable> tables = regTableService
                    .list(new LambdaQueryWrapper<RegTable>().eq(RegTable::getSystemCode, systemCode));

            for (RegTable table : tables) {
                String tableName = table.getName();
                List<RegElement> elements = regElementService.list(new LambdaQueryWrapper<RegElement>()
                        .eq(RegElement::getTableId, table.getId()).eq(RegElement::getType, "INDICATOR")
                        .isNotNull(RegElement::getCodeSnippet).ne(RegElement::getCodeSnippet, ""));

                if (elements.isEmpty())
                    continue;

                // 2. 按逻辑对指标进行分组
                // LogicKey -> List<IndicatorCode>
                Map<String, List<String>> logicGroups = new LinkedHashMap<>();
                for (RegElement element : elements) {
                    String indicatorCode = "N/A"; // Code
                                                  // removed
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
                            fileContent.append("FROM (\n").append(selectPart).append("\n) q_").append(groupIdx)
                                    .append("\n");
                            for (int k = 0; k < indicatorCodes.size(); k++) {
                                String code = indicatorCodes.get(k);
                                // 尝试从本组的指标逻辑中找回原本的字段列表（如果有的话）
                                // 注意：此处简化处理，假设同组逻辑的字段列表也是一致的
                                String columnList = extractColumnList(logicKey);
                                // Ensure newline after column list to prevent potential comment issues
                                fileContent.append("INSERT INTO `").append(code).append("` ")
                                        .append(columnList != null ? "(" + columnList + ")\n" : "").append("SELECT *");
                                if (k == indicatorCodes.size() - 1) {
                                    fileContent.append(";");
                                }
                                fileContent.append("\n");
                            }
                        } else {
                            // 退化模式：逐个输出（或者只有一个指标时也无需逻辑聚合）
                            for (String code : indicatorCodes) {
                                String snippet = replaceInsertTableNameWithBackticks(logicKey, code);
                                fileContent.append("-- 指标: ").append(code).append("\n").append(snippet);
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
        java.nio.file.Path targetDir = java.nio.file.Paths.get(basePath).getParent().resolve("urgs-agent")
                .resolve("tests").resolve("sql").resolve("hive");
        java.nio.file.Files.createDirectories(targetDir);

        java.nio.file.Path sqlFile = targetDir.resolve(fileName + ".sql");
        String header = String.format(
                "-- ============================================================\n" + "-- 文件名: %s.sql\n"
                        + "-- 生成时间: %s\n" + "-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力\n"
                        + "-- ============================================================\n\n",
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
     * 批量导出报表（多 Sheet Excel）
     * 第一个 Sheet：报表列表
     * 后续 Sheet：每个报表的字段详情（以报表名称命名）
     */
    @GetMapping("/export")
    public void exportTables(
            @RequestParam(required = false) String systemCode,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String autoFetchStatus,
            @RequestParam(required = false) String frequency,
            @RequestParam(required = false) String sourceType,
            @RequestParam(required = false) String tableIds,
            HttpServletResponse response) throws IOException {

        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");
        String fileName = URLEncoder.encode("报表数据导出", "UTF-8").replaceAll("\\+", "%20");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

        // 1. 构建过滤条件
        QueryWrapper<RegTable> query = new QueryWrapper<>();
        if (StringUtils.isNotBlank(tableIds)) {
            List<Long> ids = Arrays.stream(tableIds.split(","))
                    .map(String::trim)
                    .filter(StringUtils::isNotBlank)
                    .map(Long::parseLong)
                    .toList();
            query.in("id", ids);
        } else {
            if (StringUtils.isNotBlank(systemCode))
                query.eq("system_code", systemCode);
            if (StringUtils.isNotBlank(autoFetchStatus))
                query.eq("auto_fetch_status", autoFetchStatus);
            if (StringUtils.isNotBlank(frequency))
                query.eq("frequency", frequency);
            if (StringUtils.isNotBlank(sourceType))
                query.eq("source_type", sourceType);
            if (StringUtils.isNotBlank(keyword)) {
                String kw = keyword.toLowerCase();
                query.and(w -> w.like("LOWER(name)", kw).or().like("LOWER(cn_name)", kw));
            }
        }
        query.orderByAsc("sort_order");
        List<RegTable> tables = regTableService.list(query);

        // 2. 预获取所有相关的指标字段（优化 N+1 查询）
        Map<Long, List<RegElement>> elementMap = new HashMap<>();
        if (!tables.isEmpty()) {
            List<Long> tIds = tables.stream().map(RegTable::getId).collect(Collectors.toList());
            List<RegElement> allElements = regElementService.list(new LambdaQueryWrapper<RegElement>()
                    .in(RegElement::getTableId, tIds)
                    .orderByAsc(RegElement::getSortOrder));
            elementMap = allElements.stream().collect(Collectors.groupingBy(RegElement::getTableId));
        }

        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        Set<String> usedSheetNames = new HashSet<>();

        try (ExcelWriter excelWriter = EasyExcel.write(response.getOutputStream()).build()) {
            // 3. 写汇总 Sheet
            List<RegTableImportExportDTO> tableDtos = tables.stream().map(table -> {
                RegTableImportExportDTO dto = new RegTableImportExportDTO();
                dto.setSortOrder(table.getSortOrder());
                dto.setName(table.getName());
                dto.setCnName(table.getCnName());
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
                dto.setBusinessCaliber(safeTruncate(table.getBusinessCaliber()));
                dto.setDevNotes(safeTruncate(table.getDevNotes()));
                dto.setOwner(table.getOwner());
                return dto;
            }).collect(Collectors.toList());

            WriteSheet summarySheet = EasyExcel.writerSheet(0, "报表列表").head(RegTableImportExportDTO.class).build();
            excelWriter.write(tableDtos, summarySheet);

            // 4. 写字段详情 Sheet
            int sheetIndex = 1;
            for (RegTable table : tables) {
                // 清洗并处理重名页签
                final int currentIdx = sheetIndex;
                String rawName = StringUtils.getIfBlank(table.getName(), () -> "Sheet" + currentIdx);
                String safeName = rawName.replaceAll("[\\\\/\\?\\*\\s\\[\\]\\:]", "_");
                if (safeName.length() > 31)
                    safeName = safeName.substring(0, 31);

                String finalName = safeName;
                int counter = 1;
                while (usedSheetNames.contains(finalName.toLowerCase())) {
                    String suffix = "_" + (counter++);
                    if (safeName.length() + suffix.length() > 31) {
                        finalName = safeName.substring(0, 31 - suffix.length()) + suffix;
                    } else {
                        finalName = safeName + suffix;
                    }
                }
                usedSheetNames.add(finalName.toLowerCase());

                List<RegElement> elements = elementMap.getOrDefault(table.getId(), new ArrayList<>());
                List<RegElementImportExportDTO> elementDtos = elements.stream().map(el -> {
                    RegElementImportExportDTO dto = new RegElementImportExportDTO();
                    dto.setSortOrder(el.getSortOrder());
                    dto.setType(el.getType());
                    dto.setName(el.getName());
                    dto.setCnName(el.getCnName());
                    dto.setDataType(el.getDataType());
                    dto.setLength(el.getLength());
                    dto.setIsPk(el.getIsPk());
                    dto.setNullable(el.getNullable());
                    dto.setFormula(safeTruncate(el.getFormula()));
                    dto.setFetchSql(safeTruncate(el.getFetchSql()));
                    dto.setCodeTableCode(el.getCodeTableCode());
                    dto.setValueRange(el.getValueRange());
                    dto.setValidationRule(el.getValidationRule());
                    dto.setDocumentNo(el.getDocumentNo());
                    dto.setDocumentTitle(el.getDocumentTitle());
                    dto.setEffectiveDate(
                            el.getEffectiveDate() != null ? el.getEffectiveDate().format(dateFormatter) : null);
                    dto.setBusinessCaliber(safeTruncate(el.getBusinessCaliber()));
                    dto.setFillInstruction(safeTruncate(el.getFillInstruction()));
                    dto.setDevNotes(safeTruncate(el.getDevNotes()));
                    dto.setAutoFetchStatus(el.getAutoFetchStatus());
                    dto.setOwner(el.getOwner());
                    dto.setStatus(el.getStatus());
                    dto.setIsInit(el.getIsInit());
                    dto.setIsMergeFormula(el.getIsMergeFormula());
                    dto.setIsFillBusiness(el.getIsFillBusiness());
                    return dto;
                }).collect(Collectors.toList());

                WriteSheet detailSheet = EasyExcel.writerSheet(sheetIndex++, finalName)
                        .head(RegElementImportExportDTO.class).build();
                excelWriter.write(elementDtos, detailSheet);
            }
        }
    }

    /**
     * 批量导入报表（多 Sheet Excel）
     * 第一个 Sheet：报表列表（按 systemCode + name 匹配更新/新增）
     * 后续 Sheet：字段详情（按 Sheet 名匹配报表 code/name）
     */
    @PostMapping("/import")
    @Transactional(rollbackFor = Exception.class)
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

                // 序号仅用于排序，不再作为唯一标识
                Integer sortOrder = getIntValue(row.getCell(0));
                String cnName = getCellValue(row.getCell(1));
                String name = getCellValue(row.getCell(2));
                String systemCode = getCellValue(row.getCell(3));

                if (StringUtils.isBlank(name) || StringUtils.isBlank(systemCode)) {
                    continue;
                }

                // 查找或创建报表 (按 系统代码 + 物理表名 匹配)
                RegTable table = null;
                try {
                    table = regTableService.getOne(new LambdaQueryWrapper<RegTable>()
                            .eq(RegTable::getName, name)
                            .eq(RegTable::getSystemCode, systemCode));
                } catch (Exception e) {
                    throw new RuntimeException(String.format("匹配报表失败：系统[%s] 表名[%s] 存在重复记录", systemCode, name), e);
                }

                if (table == null) {
                    table = new RegTable();
                    table.setCreateTime(LocalDateTime.now());
                }

                table.setSortOrder(sortOrder);
                table.setCnName(cnName);
                table.setName(name);
                table.setSystemCode(systemCode);
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
                nameToTable.put(table.getName(), table);
                tableCount++;
            }

            // 2. 读取后续 Sheet（字段详情）
            for (int sheetIdx = 1; sheetIdx < workbook.getNumberOfSheets(); sheetIdx++) {
                Sheet sheet = workbook.getSheetAt(sheetIdx);
                String sheetName = sheet.getSheetName();

                // 根据 sheet 名找到对应的报表 (使用物理表名匹配)
                RegTable table = nameToTable.get(sheetName);
                if (table == null) {
                    // 尝试从数据库查找（仅限本次导入中未出现的表名，提高鲁棒性）
                    try {
                        // 这里的匹配由于没有 systemCode 上下文，可能存在风险，但在 Sheet 命名规范的情况下通常没问题
                        table = regTableService
                                .getOne(new LambdaQueryWrapper<RegTable>().eq(RegTable::getName, sheetName));
                    } catch (Exception e) {
                        // 如果有多个同名表存在于不同系统，此处无法简单定位，跳过该 Sheet 并记录日志
                        System.err.println("警告：无法唯一确定 Sheet [" + sheetName + "] 所属的报表系统上下文");
                        continue;
                    }
                }
                if (table == null)
                    continue;

                // 删除该表原有字段（覆盖更新）
                regElementService
                        .remove(new LambdaQueryWrapper<RegElement>().eq(RegElement::getTableId, table.getId()));

                // 导入新字段
                List<RegElement> elementsToSave = new ArrayList<>();
                for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                    Row row = sheet.getRow(i);
                    if (row == null)
                        continue;

                    String elementName = getCellValue(row.getCell(2));
                    if (StringUtils.isBlank(elementName))
                        continue;

                    RegElement el = new RegElement();
                    el.setTableId(table.getId());
                    el.setSortOrder(getIntValue(row.getCell(0)));
                    el.setType(getCellValue(row.getCell(1)));
                    el.setName(elementName);
                    el.setCnName(getCellValue(row.getCell(3)));
                    el.setDataType(getCellValue(row.getCell(4)));
                    el.setLength(getIntValue(row.getCell(5)));
                    el.setIsPk(getIntValue(row.getCell(6)));
                    el.setNullable(getIntValue(row.getCell(7)));
                    el.setFormula(getCellValue(row.getCell(8)));
                    el.setFetchSql(getCellValue(row.getCell(9)));
                    el.setCodeTableCode(getCellValue(row.getCell(10)));
                    el.setValueRange(getCellValue(row.getCell(11)));
                    el.setValidationRule(getCellValue(row.getCell(12)));
                    el.setDocumentNo(getCellValue(row.getCell(13)));
                    el.setDocumentTitle(getCellValue(row.getCell(14)));
                    String effDate = getCellValue(row.getCell(15));
                    if (effDate != null && !effDate.isEmpty()) {
                        try {
                            el.setEffectiveDate(LocalDate.parse(effDate, dateFormatter));
                        } catch (Exception ignored) {
                        }
                    }
                    el.setBusinessCaliber(getCellValue(row.getCell(16)));
                    el.setFillInstruction(getCellValue(row.getCell(17)));
                    el.setDevNotes(getCellValue(row.getCell(18)));
                    el.setAutoFetchStatus(getCellValue(row.getCell(19)));
                    el.setOwner(getCellValue(row.getCell(20)));
                    el.setStatus(getIntValue(row.getCell(21)));
                    if (el.getStatus() == null)
                        el.setStatus(1);
                    el.setIsInit(getIntValue(row.getCell(22)));
                    el.setIsMergeFormula(getIntValue(row.getCell(23)));
                    el.setIsFillBusiness(getIntValue(row.getCell(24)));

                    if (el.getSortOrder() == null)
                        el.setSortOrder(0);
                    el.setCreateTime(LocalDateTime.now());
                    el.setUpdateTime(LocalDateTime.now());

                    elementsToSave.add(el);
                }

                if (!elementsToSave.isEmpty()) {
                    regElementService.saveBatch(elementsToSave);
                    elementCount += elementsToSave.size();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("导入报表数据失败：" + e.getMessage(), e);
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

    /**
     * 安全截断字符串，防止 Excel 单元格超长 (32767) 报错
     */
    private String safeTruncate(String val) {
        if (val == null || val.length() <= 32700) {
            return val;
        }
        return val.substring(0, 32700) + "... [Truncated due to Excel Limit]";
    }
}
