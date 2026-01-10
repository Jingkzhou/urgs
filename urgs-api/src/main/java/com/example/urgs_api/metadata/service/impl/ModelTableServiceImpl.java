package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.IdWorker;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.datasource.service.DynamicDataSourceService;
import com.example.urgs_api.metadata.dto.ModelSyncResult;
import com.example.urgs_api.metadata.model.ModelField;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.ModelTableMapper;
import com.example.urgs_api.metadata.model.ModelDirectory;
import com.example.urgs_api.metadata.model.ModelTable;
import com.example.urgs_api.metadata.service.ModelDirectoryService;
import com.example.urgs_api.metadata.service.ModelTableService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
/**
 * 模型表服务实现类
 */
public class ModelTableServiceImpl extends ServiceImpl<ModelTableMapper, ModelTable> implements ModelTableService {

    @Autowired
    private ModelDirectoryService modelDirectoryService;

    @Autowired
    private DynamicDataSourceService dynamicDataSourceService;

    @Override
    /**
     * 根据目录列表
     */
    public com.baomidou.mybatisplus.core.metadata.IPage<ModelTable> listByDirectory(String directoryId, int page,
            int size) {
        if (directoryId == null || directoryId.isEmpty()) {
            return page(new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(page, size));
        }

        // Find all child directory IDs recursively
        List<String> allDirectoryIds = new ArrayList<>();
        allDirectoryIds.add(directoryId);
        collectChildDirectoryIds(directoryId, allDirectoryIds);

        return page(new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(page, size),
                new LambdaQueryWrapper<ModelTable>()
                        .in(ModelTable::getDirectoryId, allDirectoryIds));
    }

    private void collectChildDirectoryIds(String parentId, List<String> allIds) {
        List<ModelDirectory> children = modelDirectoryService.list(new LambdaQueryWrapper<ModelDirectory>()
                .eq(ModelDirectory::getParentId, parentId));
        for (ModelDirectory child : children) {
            allIds.add(child.getId());
            collectChildDirectoryIds(child.getId(), allIds);
        }
    }

    @Autowired
    private com.example.urgs_api.metadata.service.MaintenanceRecordService maintenanceRecordService;

    @Autowired
    @org.springframework.context.annotation.Lazy
    private com.example.urgs_api.metadata.service.ModelFieldService modelFieldService;

    @Override
    public com.baomidou.mybatisplus.core.metadata.IPage<ModelTable> listBySource(Long dataSourceId, String owner,
            String keyword, int page, int size) {
        if (dataSourceId == null) {
            return new Page<>(page, size);
        }
        LambdaQueryWrapper<ModelTable> wrapper = new LambdaQueryWrapper<ModelTable>()
                .eq(ModelTable::getDataSourceId, dataSourceId);
        if (owner != null && !owner.isBlank()) {
            wrapper.eq(ModelTable::getOwner, owner);
        }
        if (keyword != null && !keyword.isBlank()) {
            final String lowerKeyword = keyword.toLowerCase();
            wrapper.and(qw -> qw.apply("LOWER(name) LIKE {0}", "%" + lowerKeyword + "%")
                    .or()
                    .apply("LOWER(cn_name) LIKE {0}", "%" + lowerKeyword + "%"));
        }
        wrapper.orderByAsc(ModelTable::getName);
        return page(new Page<>(page, size), wrapper);
    }

    @Override
    public List<String> listOwners(Long dataSourceId) {
        if (dataSourceId == null) {
            return new ArrayList<>();
        }
        QueryWrapper<ModelTable> query = new QueryWrapper<ModelTable>()
                .select("distinct owner")
                .eq("data_source_id", dataSourceId)
                .orderByAsc("owner");
        List<ModelTable> tables = list(query);
        List<String> owners = new ArrayList<>();
        for (ModelTable table : tables) {
            if (table.getOwner() != null && !table.getOwner().isBlank()) {
                owners.add(table.getOwner());
            }
        }
        return owners;
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public ModelSyncResult syncFromDataSource(Long dataSourceId, String ownerFilter) {
        if (dataSourceId == null) {
            throw new IllegalArgumentException("dataSourceId is required");
        }

        JdbcTemplate template = dynamicDataSourceService.getJdbcTemplate(dataSourceId);
        DataSource dataSource = template.getDataSource();
        if (dataSource == null) {
            throw new IllegalStateException("No DataSource available for id: " + dataSourceId);
        }

        LocalDateTime now = LocalDateTime.now();
        List<ModelTable> existingTables = list(new LambdaQueryWrapper<ModelTable>()
                .eq(ModelTable::getDataSourceId, dataSourceId)
                .eq(ownerFilter != null && !ownerFilter.isBlank(), ModelTable::getOwner, ownerFilter));
        if (!existingTables.isEmpty()) {
            List<String> tableIds = new ArrayList<>();
            for (ModelTable table : existingTables) {
                tableIds.add(table.getId());
            }
            if (!tableIds.isEmpty()) {
                modelFieldService.remove(new LambdaQueryWrapper<ModelField>()
                        .in(ModelField::getTableId, tableIds));
            }
            removeByIds(tableIds);
        }

        List<TableMeta> tableMetas = new ArrayList<>();
        Set<String> owners = new HashSet<>();

        try (Connection connection = dataSource.getConnection()) {
            DatabaseMetaData meta = connection.getMetaData();
            String product = meta.getDatabaseProductName() == null ? "" : meta.getDatabaseProductName().toLowerCase();

            String schemaPattern = ownerFilter;
            if (product.contains("oracle") && (schemaPattern == null || schemaPattern.isBlank())) {
                try {
                    schemaPattern = meta.getUserName();
                } catch (Exception e) {
                    // Ignore, fallback to null (search all)
                }
            }

            try (ResultSet tables = meta.getTables(connection.getCatalog(), schemaPattern, "%",
                    new String[] { "TABLE" })) {
                while (tables.next()) {
                    String tableName = tables.getString("TABLE_NAME");
                    String schema = tables.getString("TABLE_SCHEM");
                    String catalog = tables.getString("TABLE_CAT");
                    String owner = resolveOwner(schema, catalog);

                    if (ownerFilter != null && !ownerFilter.isBlank()
                            && !owner.equalsIgnoreCase(ownerFilter)) {
                        continue;
                    }
                    if (shouldSkipSchema(product, owner)) {
                        continue;
                    }

                    String comment = tables.getString("REMARKS");
                    TableMeta metaRow = new TableMeta();
                    metaRow.id = IdWorker.getIdStr();
                    metaRow.name = tableName;
                    metaRow.schema = schema;
                    metaRow.catalog = catalog;
                    metaRow.owner = owner;
                    metaRow.comment = comment;
                    tableMetas.add(metaRow);
                    owners.add(owner);
                }
            }

            List<ModelTable> newTables = new ArrayList<>();
            List<ModelField> newFields = new ArrayList<>();

            for (TableMeta tableMeta : tableMetas) {
                ModelTable table = new ModelTable();
                table.setId(tableMeta.id);
                table.setName(tableMeta.name);
                table.setCnName(tableMeta.comment);
                table.setOwner(tableMeta.owner);
                table.setDataSourceId(dataSourceId);
                table.setCreateTime(now);
                table.setUpdateTime(now);
                newTables.add(table);

                Set<String> pkColumns = new HashSet<>();
                try (ResultSet pkRs = meta.getPrimaryKeys(tableMeta.catalog, tableMeta.schema, tableMeta.name)) {
                    while (pkRs.next()) {
                        pkColumns.add(pkRs.getString("COLUMN_NAME"));
                    }
                }

                try (ResultSet columns = meta.getColumns(tableMeta.catalog, tableMeta.schema, tableMeta.name, "%")) {
                    while (columns.next()) {
                        String columnName = columns.getString("COLUMN_NAME");
                        String typeName = columns.getString("TYPE_NAME");
                        int size = columns.getInt("COLUMN_SIZE");
                        int scale = columns.getInt("DECIMAL_DIGITS");
                        String nullable = columns.getString("IS_NULLABLE");
                        String remarks = columns.getString("REMARKS");
                        int ordinal = columns.getInt("ORDINAL_POSITION");

                        ModelField field = new ModelField();
                        field.setId(java.util.UUID.randomUUID().toString().replace("-", ""));
                        field.setTableId(tableMeta.id);
                        field.setName(columnName);
                        field.setCnName(remarks);
                        field.setType(formatType(typeName, size, scale));
                        field.setIsPk(pkColumns.contains(columnName));
                        field.setNullable(!"NO".equalsIgnoreCase(nullable));
                        field.setSortOrder(ordinal);
                        field.setCreateTime(now);
                        field.setUpdateTime(now);
                        newFields.add(field);
                    }
                }
            }

            if (!newTables.isEmpty()) {
                saveBatch(newTables, 500);
            }
            if (!newFields.isEmpty()) {
                modelFieldService.saveBatch(newFields, 500);
            }

            ModelSyncResult result = new ModelSyncResult();
            result.setTableCount(newTables.size());
            result.setFieldCount(newFields.size());
            result.setOwnerCount(owners.size());
            return result;
        } catch (Exception e) {
            throw new RuntimeException("Sync model metadata failed", e);
        }
    }

    private String resolveOwner(String schema, String catalog) {
        if (schema != null && !schema.isBlank()) {
            return schema;
        }
        if (catalog != null && !catalog.isBlank()) {
            return catalog;
        }
        return "default";
    }

    private boolean shouldSkipSchema(String product, String owner) {
        if (owner == null) {
            return true;
        }
        String lower = owner.toLowerCase();
        if (lower.isBlank()) {
            return true;
        }
        if (lower.equals("information_schema") || lower.equals("performance_schema") || lower.equals("mysql")
                || lower.equals("sys") || lower.equals("pg_catalog")) {
            return true;
        }
        if (product.contains("oracle")) {
            return lower.equals("sys") || lower.equals("system") || lower.equals("outln") || lower.equals("dbsnmp")
                    || lower.startsWith("apex_") || lower.startsWith("flow_") || lower.equals("xdb")
                    || lower.equals("wmsys") || lower.equals("ctxsys") || lower.equals("mdsys")
                    || lower.equals("ordsys") || lower.equals("ordplugins") || lower.equals("olapsys")
                    || lower.equals("si_informtn_schema");
        }
        if (product.contains("hive") || product.contains("impala")) {
            // Hive system databases
            return lower.equals("sys") || lower.equals("system");
        }
        if (product.contains("gbase")) {
            // GBase 8a/8s system schemas
            return lower.equals("gbase") || lower.equals("gbasedbt") || lower.equals("sys")
                    || lower.equals("sysuser") || lower.equals("information_schema")
                    || lower.equals("performance_schema");
        }
        return false;
    }

    private String formatType(String typeName, int size, int scale) {
        if (typeName == null) {
            return null;
        }
        if (size > 0) {
            if (scale > 0) {
                return String.format("%s(%d,%d)", typeName, size, scale);
            }
            return String.format("%s(%d)", typeName, size);
        }
        return typeName;
    }

    private static class TableMeta {
        private String id;
        private String name;
        private String schema;
        private String catalog;
        private String owner;
        private String comment;
    }

    @Override
    /**
     * 创建表并记录
     */
    public boolean createWithRecord(com.example.urgs_api.metadata.dto.ModelTableOperationDTO dto) {
        ModelTable table = dto.getTable();
        boolean success = save(table);
        if (success) {
            recordMaintenance(table, "新增表", dto);
        }
        return success;
    }

    @Override
    /**
     * 更新表并记录
     */
    public boolean updateWithRecord(com.example.urgs_api.metadata.dto.ModelTableOperationDTO dto) {
        ModelTable table = dto.getTable();
        boolean success = updateById(table);
        if (success) {
            recordMaintenance(table, "修改表", dto);
        }
        return success;
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    /**
     * 删除表并记录
     */
    public boolean deleteWithRecord(String id, String reqId, String description) {
        ModelTable table = getById(id);
        if (table != null) {
            removeById(id);
            com.example.urgs_api.metadata.dto.ModelTableOperationDTO opDto = new com.example.urgs_api.metadata.dto.ModelTableOperationDTO();
            opDto.setReqId(reqId);
            opDto.setDescription(description);
            recordMaintenance(table, "删除表", opDto);
            return true;
        }
        return false;
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public boolean deleteBatchWithRecord(List<String> ids, String reqId, String description) {
        if (ids == null || ids.isEmpty()) {
            return false;
        }
        for (String id : ids) {
            deleteWithRecord(id, reqId, description);
        }
        return true;
    }

    @Override
    /**
     * 导出模型表
     */
    public void exportModels(List<String> tableIds, jakarta.servlet.http.HttpServletResponse response) {
        try {
            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setCharacterEncoding("utf-8");
            String fileName = java.net.URLEncoder.encode("model_export", "UTF-8").replaceAll("\\+", "%20");
            response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

            List<ModelTable> tables;
            if (tableIds == null || tableIds.isEmpty()) {
                tables = list();
            } else {
                tables = listByIds(tableIds);
            }

            try (com.alibaba.excel.ExcelWriter excelWriter = com.alibaba.excel.EasyExcel
                    .write(response.getOutputStream()).build()) {
                // 1. Write Summary Sheet "模型列表"
                List<com.example.urgs_api.metadata.dto.ModelTableExportDTO> tableDtos = new ArrayList<>();
                for (ModelTable table : tables) {
                    com.example.urgs_api.metadata.dto.ModelTableExportDTO dto = new com.example.urgs_api.metadata.dto.ModelTableExportDTO();
                    dto.setName(table.getName());
                    dto.setCnName(table.getCnName());
                    dto.setSubjectCode(table.getSubjectCode());
                    dto.setSubjectName(table.getSubjectName());
                    dto.setTheme(table.getTheme());
                    dto.setBusinessScope(table.getBusinessScope());
                    dto.setFreq(table.getFreq());
                    dto.setVersion(table.getVersion());
                    dto.setRetentionTime(table.getRetentionTime());
                    dto.setRemark(table.getRemark());
                    tableDtos.add(dto);
                }

                // Custom Handler for Hyperlinks
                com.alibaba.excel.write.handler.WriteHandler hyperlinkHandler = new com.alibaba.excel.write.handler.AbstractRowWriteHandler() {
                    @Override
                    public void afterRowDispose(
                            com.alibaba.excel.write.handler.context.RowWriteHandlerContext context) {
                        if (context.getHead() || context.getRelativeRowIndex() == null) {
                            return;
                        }
                        // Index of "中文名称" is 1 (0-based)
                        int cellIndex = 1;
                        org.apache.poi.ss.usermodel.Cell cell = context.getRow().getCell(cellIndex);
                        if (cell != null) {
                            org.apache.poi.ss.usermodel.Workbook workbook = context.getWriteContext()
                                    .writeWorkbookHolder().getWorkbook();
                            org.apache.poi.ss.usermodel.CreationHelper createHelper = workbook.getCreationHelper();
                            org.apache.poi.ss.usermodel.Hyperlink link = createHelper
                                    .createHyperlink(org.apache.poi.common.usermodel.HyperlinkType.DOCUMENT);

                            // Link to the sheet with the table name (which is in column 0)
                            String tableName = context.getRow().getCell(0).getStringCellValue();
                            // Excel sheet names with spaces or special chars need single quotes, but let's
                            // assume simple names for now or quote it
                            link.setAddress("'" + tableName + "'!A1");
                            cell.setHyperlink(link);

                            // Optional: Set style to look like a link (blue, underlined)
                            org.apache.poi.ss.usermodel.CellStyle linkStyle = workbook.createCellStyle();
                            org.apache.poi.ss.usermodel.Font linkFont = workbook.createFont();
                            linkFont.setUnderline(org.apache.poi.ss.usermodel.Font.U_SINGLE);
                            linkFont.setColor(org.apache.poi.ss.usermodel.IndexedColors.BLUE.getIndex());
                            linkStyle.setFont(linkFont);
                            cell.setCellStyle(linkStyle);
                        }
                    }
                };

                com.alibaba.excel.write.metadata.WriteSheet summarySheet = com.alibaba.excel.EasyExcel
                        .writerSheet(0, "模型列表")
                        .head(com.example.urgs_api.metadata.dto.ModelTableExportDTO.class)
                        .registerWriteHandler(hyperlinkHandler)
                        .build();
                excelWriter.write(tableDtos, summarySheet);

                // 2. Write Detail Sheets
                for (int i = 0; i < tables.size(); i++) {
                    ModelTable table = tables.get(i);
                    List<com.example.urgs_api.metadata.model.ModelField> fields = modelFieldService.list(
                            new LambdaQueryWrapper<com.example.urgs_api.metadata.model.ModelField>()
                                    .eq(com.example.urgs_api.metadata.model.ModelField::getTableId, table.getId()));

                    List<com.example.urgs_api.metadata.dto.ModelImportExportDTO> fieldDtos = new ArrayList<>();
                    for (com.example.urgs_api.metadata.model.ModelField field : fields) {
                        com.example.urgs_api.metadata.dto.ModelImportExportDTO dto = new com.example.urgs_api.metadata.dto.ModelImportExportDTO();
                        dto.setTableName(table.getName());
                        dto.setFieldName(field.getName());
                        dto.setFieldCnName(field.getCnName());
                        dto.setType(field.getType());
                        dto.setIsPk(field.getIsPk() ? "是" : "否");
                        dto.setNullable(field.getNullable() ? "是" : "否");
                        dto.setDomain(field.getDomain());
                        dto.setRemark(field.getRemark());
                        fieldDtos.add(dto);
                    }

                    com.alibaba.excel.write.metadata.WriteSheet detailSheet = com.alibaba.excel.EasyExcel
                            .writerSheet(i + 1, table.getName())
                            .head(com.example.urgs_api.metadata.dto.ModelImportExportDTO.class)
                            .build();
                    excelWriter.write(fieldDtos, detailSheet);
                }
            }

        } catch (Exception e) {
            throw new RuntimeException("Export failed", e);
        }
    }

    private boolean isModified(String dbVal, String excelVal) {
        String cleanDb = dbVal == null ? "" : dbVal.trim();
        String cleanExcel = excelVal == null ? "" : excelVal.trim();
        return !cleanDb.equals(cleanExcel);
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    /**
     * 导入模型表
     */
    public boolean importModels(org.springframework.web.multipart.MultipartFile file, String reqId,
            String description, String operator, String directoryId) {
        try {
            // Read all sheets
            com.alibaba.excel.ExcelReader excelReader = com.alibaba.excel.EasyExcel.read(file.getInputStream()).build();
            List<com.alibaba.excel.read.metadata.ReadSheet> sheets = excelReader.excelExecutor().sheetList();

            System.out.println("Importing models... Found sheets: " + (sheets != null ? sheets.size() : "null"));

            if (sheets == null || sheets.isEmpty()) {
                System.out.println("No sheets found in the Excel file.");
                return false;
            }

            // 1. Process Summary Sheet "模型列表" if it exists
            com.alibaba.excel.read.metadata.ReadSheet summarySheet = sheets.stream()
                    .filter(s -> "模型列表".equals(s.getSheetName()))
                    .findFirst()
                    .orElse(null);

            if (summarySheet != null) {
                System.out.println("Processing summary sheet: 模型列表");
                List<com.example.urgs_api.metadata.dto.ModelTableExportDTO> tableDtos = com.alibaba.excel.EasyExcel
                        .read(file.getInputStream())
                        .sheet(summarySheet.getSheetNo())
                        .head(com.example.urgs_api.metadata.dto.ModelTableExportDTO.class)
                        .doReadSync();

                for (com.example.urgs_api.metadata.dto.ModelTableExportDTO dto : tableDtos) {
                    if (dto.getName() == null || dto.getName().trim().isEmpty())
                        continue;
                    String tableName = dto.getName().trim();

                    ModelTable table = getOne(
                            new LambdaQueryWrapper<ModelTable>().eq(ModelTable::getName, tableName));
                    if (table == null) {
                        // Create new table
                        System.out.println("Creating new table from summary: " + tableName);
                        table = new ModelTable();
                        table.setName(tableName);
                        table.setCnName(dto.getCnName() != null ? dto.getCnName().trim() : null);
                        table.setSubjectCode(dto.getSubjectCode() != null ? dto.getSubjectCode().trim() : null);
                        table.setSubjectName(dto.getSubjectName() != null ? dto.getSubjectName().trim() : null);
                        table.setTheme(dto.getTheme() != null ? dto.getTheme().trim() : null);
                        table.setBusinessScope(dto.getBusinessScope() != null ? dto.getBusinessScope().trim() : null);
                        table.setFreq(dto.getFreq() != null ? dto.getFreq().trim() : null);
                        table.setVersion(dto.getVersion() != null ? dto.getVersion().trim() : null);
                        table.setRetentionTime(dto.getRetentionTime() != null ? dto.getRetentionTime().trim() : null);
                        table.setRemark(dto.getRemark() != null ? dto.getRemark().trim() : null);
                        table.setDirectoryId(directoryId);
                        save(table);

                        com.example.urgs_api.metadata.dto.ModelTableOperationDTO opDto = new com.example.urgs_api.metadata.dto.ModelTableOperationDTO();
                        opDto.setReqId(reqId);
                        opDto.setDescription(description);
                        opDto.setOperator(operator);
                        recordMaintenance(table, "新增表", opDto);
                    } else {
                        // Update existing table
                        System.out.println("Updating table from summary: " + tableName);
                        boolean changed = false;
                        com.example.urgs_api.metadata.dto.ModelTableOperationDTO opDto = new com.example.urgs_api.metadata.dto.ModelTableOperationDTO();
                        opDto.setReqId(reqId);
                        opDto.setDescription(description);
                        opDto.setOperator(operator);

                        if (isModified(table.getCnName(), dto.getCnName())) {
                            table.setCnName(dto.getCnName() != null ? dto.getCnName().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表中文名", opDto);
                        }
                        if (isModified(table.getSubjectCode(), dto.getSubjectCode())) {
                            table.setSubjectCode(dto.getSubjectCode() != null ? dto.getSubjectCode().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表科目号", opDto);
                        }
                        if (isModified(table.getSubjectName(), dto.getSubjectName())) {
                            table.setSubjectName(dto.getSubjectName() != null ? dto.getSubjectName().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表科目中文名", opDto);
                        }
                        if (isModified(table.getTheme(), dto.getTheme())) {
                            table.setTheme(dto.getTheme() != null ? dto.getTheme().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表监管主题", opDto);
                        }
                        if (isModified(table.getBusinessScope(), dto.getBusinessScope())) {
                            table.setBusinessScope(
                                    dto.getBusinessScope() != null ? dto.getBusinessScope().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表业务范围", opDto);
                        }
                        if (isModified(table.getFreq(), dto.getFreq())) {
                            table.setFreq(dto.getFreq() != null ? dto.getFreq().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表报送频度", opDto);
                        }
                        if (isModified(table.getVersion(), dto.getVersion())) {
                            table.setVersion(dto.getVersion() != null ? dto.getVersion().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表版本", opDto);
                        }
                        if (isModified(table.getRetentionTime(), dto.getRetentionTime())) {
                            table.setRetentionTime(
                                    dto.getRetentionTime() != null ? dto.getRetentionTime().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表保留时间", opDto);
                        }
                        if (isModified(table.getRemark(), dto.getRemark())) {
                            table.setRemark(dto.getRemark() != null ? dto.getRemark().trim() : null);
                            changed = true;
                            recordMaintenance(table, "修改表备注", opDto);
                        }

                        if (changed) {
                            updateById(table);
                        }
                    }
                }
            }

            // 2. Process Detail Sheets
            for (com.alibaba.excel.read.metadata.ReadSheet sheet : sheets) {
                String sheetName = sheet.getSheetName();
                if ("模型列表".equals(sheetName)) {
                    continue; // Already processed
                }

                System.out.println("Processing detail sheet: " + sheetName);
                String tableName = sheetName.trim();

                // Read fields from this sheet
                List<com.example.urgs_api.metadata.dto.ModelImportExportDTO> importFields = com.alibaba.excel.EasyExcel
                        .read(file.getInputStream())
                        .sheet(sheet.getSheetNo())
                        .head(com.example.urgs_api.metadata.dto.ModelImportExportDTO.class)
                        .doReadSync();

                System.out.println("Read " + importFields.size() + " fields for table: " + tableName);

                // Ensure tableName in DTO matches sheet name
                for (com.example.urgs_api.metadata.dto.ModelImportExportDTO dto : importFields) {
                    if (dto.getTableName() == null || dto.getTableName().isEmpty()) {
                        dto.setTableName(tableName);
                    }
                }

                ModelTable table = getOne(new LambdaQueryWrapper<ModelTable>().eq(ModelTable::getName, tableName));
                if (table != null) {
                    System.out.println("Found table in DB: " + table.getName());
                    // Sync fields logic
                    List<com.example.urgs_api.metadata.model.ModelField> existingFields = modelFieldService.list(
                            new LambdaQueryWrapper<com.example.urgs_api.metadata.model.ModelField>()
                                    .eq(com.example.urgs_api.metadata.model.ModelField::getTableId, table.getId()));

                    // 1. Handle Updates and Adds
                    int sortIndex = 0;
                    for (com.example.urgs_api.metadata.dto.ModelImportExportDTO dto : importFields) {
                        if (dto.getFieldName() == null || dto.getFieldName().trim().isEmpty())
                            continue;

                        sortIndex++;
                        String fieldName = dto.getFieldName().trim();
                        com.example.urgs_api.metadata.model.ModelField existingField = existingFields.stream()
                                .filter(f -> f.getName().equals(fieldName))
                                .findFirst()
                                .orElse(null);

                        if (existingField != null) {
                            // Update
                            boolean changed = false;

                            // Update sort order if changed
                            if (existingField.getSortOrder() == null
                                    || !existingField.getSortOrder().equals(sortIndex)) {
                                existingField.setSortOrder(sortIndex);
                                changed = true;
                            }

                            // Type comparison
                            if (isModified(existingField.getType(), dto.getType())) {
                                System.out.println("Field " + fieldName + " Type changed: '" + existingField.getType()
                                        + "' -> '" + dto.getType() + "'");
                                existingField.setType(dto.getType() != null ? dto.getType().trim() : null);
                                changed = true;
                            }

                            // CN Name comparison
                            if (isModified(existingField.getCnName(), dto.getFieldCnName())) {
                                System.out.println("Field " + fieldName + " CN Name changed: '"
                                        + existingField.getCnName() + "' -> '" + dto.getFieldCnName() + "'");
                                existingField
                                        .setCnName(dto.getFieldCnName() != null ? dto.getFieldCnName().trim() : null);
                                changed = true;
                            }

                            // PK comparison
                            String newPkStr = dto.getIsPk() != null ? dto.getIsPk().trim() : "";
                            boolean newPk = "是".equals(newPkStr);
                            // If DB is null, treat as false (not PK)
                            boolean dbPk = existingField.getIsPk() != null && existingField.getIsPk();
                            if (dbPk != newPk) {
                                System.out.println("Field " + fieldName + " PK changed: " + dbPk + " -> " + newPk);
                                existingField.setIsPk(newPk);
                                changed = true;
                            }

                            // Nullable comparison
                            String newNullableStr = dto.getNullable() != null ? dto.getNullable().trim() : "";
                            boolean newNullable = !"否".equals(newNullableStr); // Default to true unless "否"
                            // If DB is null, treat as true (nullable)
                            boolean dbNullable = existingField.getNullable() == null || existingField.getNullable();
                            if (dbNullable != newNullable) {
                                System.out.println("Field " + fieldName + " Nullable changed: "
                                        + dbNullable + " -> " + newNullable);
                                existingField.setNullable(newNullable);
                                changed = true;
                            }

                            // Domain comparison
                            if (isModified(existingField.getDomain(), dto.getDomain())) {
                                System.out.println("Field " + fieldName + " Domain changed: '"
                                        + existingField.getDomain() + "' -> '" + dto.getDomain() + "'");
                                existingField.setDomain(dto.getDomain() != null ? dto.getDomain().trim() : null);
                                changed = true;
                            }

                            // Remark comparison
                            if (isModified(existingField.getRemark(), dto.getRemark())) {
                                System.out.println("Field " + fieldName + " Remark changed: '"
                                        + existingField.getRemark() + "' -> '" + dto.getRemark() + "'");
                                existingField.setRemark(dto.getRemark() != null ? dto.getRemark().trim() : null);
                                changed = true;
                            }

                            if (changed) {
                                System.out.println("Updating field in DB: " + fieldName);
                                modelFieldService.updateById(existingField);
                                recordFieldMaintenance(table, existingField.getName(), existingField.getCnName(),
                                        "修改字段", reqId, description,
                                        "UPDATE " + tableName + " MODIFY " + existingField.getName(), operator);
                            } else {
                                System.out.println("Field " + fieldName + " no changes detected.");
                            }
                        } else {
                            // Add
                            System.out.println("Adding new field: " + fieldName);
                            com.example.urgs_api.metadata.model.ModelField newField = new com.example.urgs_api.metadata.model.ModelField();
                            newField.setTableId(table.getId());
                            newField.setName(fieldName);
                            newField.setCnName(dto.getFieldCnName() != null ? dto.getFieldCnName().trim() : null);
                            newField.setType(dto.getType() != null ? dto.getType().trim() : null);
                            newField.setIsPk("是".equals(dto.getIsPk() != null ? dto.getIsPk().trim() : ""));
                            newField.setNullable("是".equals(dto.getNullable() != null ? dto.getNullable().trim() : ""));
                            newField.setDomain(dto.getDomain() != null ? dto.getDomain().trim() : null);
                            newField.setRemark(dto.getRemark() != null ? dto.getRemark().trim() : null);
                            newField.setSortOrder(sortIndex);
                            modelFieldService.save(newField);
                            recordFieldMaintenance(table, newField.getName(), newField.getCnName(), "新增字段", reqId,
                                    description, "ALTER TABLE " + tableName + " ADD " + newField.getName(), operator);
                        }
                    }

                    // 2. Handle Deletes (Fields in DB but not in Import)
                    List<String> importFieldNames = importFields.stream()
                            .map(com.example.urgs_api.metadata.dto.ModelImportExportDTO::getFieldName)
                            .filter(java.util.Objects::nonNull)
                            .map(String::trim)
                            .collect(java.util.stream.Collectors.toList());

                    for (com.example.urgs_api.metadata.model.ModelField field : existingFields) {
                        if (!importFieldNames.contains(field.getName())) {
                            System.out.println("Deleting field: " + field.getName());
                            modelFieldService.removeById(field.getId());
                            recordFieldMaintenance(table, field.getName(), field.getCnName(), "删除字段", reqId,
                                    description, "ALTER TABLE " + tableName + " DROP " + field.getName(), operator);
                        }
                    }
                } else {
                    System.out.println("Table not found in DB (and not created from summary): " + tableName);
                }
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Import failed: " + e.getMessage());
        }
    }

    private void recordFieldMaintenance(ModelTable table, String fieldName, String fieldCnName, String type,
            String reqId, String description, String script, String operator) {
        com.example.urgs_api.metadata.model.MaintenanceRecord record = new com.example.urgs_api.metadata.model.MaintenanceRecord();
        record.setTableName(table.getName());
        record.setTableCnName(table.getCnName());
        record.setFieldName(fieldName);
        record.setFieldCnName(fieldCnName);
        record.setModType(type);
        record.setTime(java.time.LocalDateTime.now());
        record.setReqId(reqId);
        record.setDescription(description);
        record.setScript(script);
        // Operator could be fetched from context if needed, for now leaving null or
        // "System"
        record.setOperator(operator != null && !operator.isEmpty() ? operator : "System Import");
        maintenanceRecordService.save(record);
    }

    private void recordMaintenance(ModelTable table, String type,
            com.example.urgs_api.metadata.dto.ModelTableOperationDTO dto) {
        com.example.urgs_api.metadata.model.MaintenanceRecord record = new com.example.urgs_api.metadata.model.MaintenanceRecord();
        record.setTableName(table.getName());
        record.setTableCnName(table.getCnName());
        record.setModType(type);
        record.setTime(java.time.LocalDateTime.now());
        record.setReqId(dto.getReqId());
        record.setDescription(dto.getDescription());

        if (dto.getPlannedDate() != null && !dto.getPlannedDate().isEmpty()) {
            try {
                record.setPlannedDate(java.time.LocalDate.parse(dto.getPlannedDate()));
            } catch (Exception e) {
                // Ignore parse error or log it
            }
        }
        record.setScript(dto.getScript());
        record.setOperator(dto.getOperator());

        maintenanceRecordService.save(record);
    }
}
