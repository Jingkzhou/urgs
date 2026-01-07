package com.example.urgs_api.metadata.service.impl;

import com.alibaba.excel.EasyExcel;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.dto.CodeDirectoryImportExportDTO;
import com.example.urgs_api.metadata.dto.ImportResultDTO;
import com.example.urgs_api.metadata.mapper.CodeDirectoryMapper;
import com.example.urgs_api.metadata.model.CodeDirectory;
import com.example.urgs_api.metadata.service.CodeDirectoryService;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URLEncoder;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 代码目录服务实现类
 * 负责处理代码目录（码表项）的业务逻辑，包括：
 * 1. 基本的 CRUD 操作（继承自 ServiceImpl）
 * 2. Excel 导入逻辑（支持全量覆盖模式）
 * 3. Excel 导出逻辑
 */
@Service
public class CodeDirectoryServiceImpl extends ServiceImpl<CodeDirectoryMapper, CodeDirectory>
                implements CodeDirectoryService {

        @org.springframework.beans.factory.annotation.Autowired
        private com.example.urgs_api.metadata.service.CodeTableService codeTableService;

        /**
         * 导入代码目录数据
         * <p>
         * 导入逻辑说明：
         * 1. <b>读取数据</b>：使用 `doReadSync()` 一次性读取 Excel 所有数据到内存。
         * 注意：不使用 PageReadListener 监听器模式，因为监听器是分批处理（如每100条一批），
         * 会导致后一批次执行“清除旧数据”逻辑时，错误地删除了前一批次刚插入的数据。
         * 2. <b>分组处理</b>：将数据按“系统代码(SystemCode)”和“码表编号(TableCode)”进行分组。
         * 3. <b>全量覆盖</b>：针对每一组（即每一个具体的码表）：
         * - <b>清除</b>：删除数据库中该系统该码表下的所有旧数据。
         * - <b>表头检查</b>：检查 `CodeTable`（码表头信息）是否存在，不存在则创建，存在则选择性更新名称。
         * - <b>插入</b>：批量插入 Excel 中的新数据。
         *
         * @param file 上传的 Excel 文件
         * @return 导入结果统计 (删除条数, 插入条数, 失败条数)
         */
        @Override
        public ImportResultDTO importData(MultipartFile file) {
                ImportResultDTO stats = new ImportResultDTO();
                final AtomicInteger deletedCount = new AtomicInteger(0);
                final AtomicInteger insertedCount = new AtomicInteger(0);
                final AtomicInteger failedCount = new AtomicInteger(0);

                try {
                        // 1. 读取 Excel 数据
                        // 使用 doReadSync 同步读取所有数据，避免分批处理导致的数据覆盖问题
                        List<CodeDirectoryImportExportDTO> dataList = EasyExcel.read(file.getInputStream())
                                        .head(CodeDirectoryImportExportDTO.class)
                                        .sheet()
                                        .doReadSync();

                        // 2. 数据分组
                        // Key 1: SystemCode (系统代码)
                        // Key 2: TableCode (码表编号)
                        // Value: 该组下的所有行数据
                        java.util.Map<String, java.util.Map<String, List<CodeDirectoryImportExportDTO>>> groupedData = dataList
                                        .stream()
                                        .filter(dto -> dto.getSystemCode() != null && !dto.getSystemCode().isEmpty()
                                                        && dto.getTableCode() != null && !dto.getTableCode().isEmpty())
                                        .collect(java.util.stream.Collectors.groupingBy(
                                                        CodeDirectoryImportExportDTO::getSystemCode,
                                                        java.util.stream.Collectors.groupingBy(
                                                                        CodeDirectoryImportExportDTO::getTableCode)));

                        // 3. 遍历分组进行处理
                        groupedData.forEach((systemCode, tableMap) -> {
                                tableMap.forEach((tableCode, dtoList) -> {
                                        if (dtoList.isEmpty())
                                                return;

                                        // 3.1 清除旧数据
                                        // 根据 系统代码 + 码表编号，删除该码表下的所有旧代码项
                                        QueryWrapper<CodeDirectory> deleteWrapper = new QueryWrapper<>();
                                        deleteWrapper.eq("system_code", systemCode)
                                                        .eq("table_code", tableCode);
                                        // 记录删除条数（需要先 count 再 remove，或者 remove 返回影响行数？MP remove 默认返回 boolean）
                                        // 为了准确统计，先 count
                                        long count = count(deleteWrapper);
                                        deletedCount.addAndGet((int) count);
                                        remove(deleteWrapper);

                                        // 3.2 维护码表头信息 (CodeTable)
                                        // 检查该系统下是否存在该码表定义
                                        com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<com.example.urgs_api.metadata.model.CodeTable> tableQuery = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<>();
                                        tableQuery.eq("system_code", systemCode)
                                                        .eq("table_code", tableCode);
                                        com.example.urgs_api.metadata.model.CodeTable codeTable = codeTableService
                                                        .getOne(tableQuery);

                                        // 取第一行数据的表名作为码表名称
                                        String tableName = dtoList.get(0).getTableName();

                                        if (codeTable == null) {
                                                // 如果不存在，则新建码表头信息
                                                codeTable = new com.example.urgs_api.metadata.model.CodeTable();
                                                codeTable.setSystemCode(systemCode);
                                                codeTable.setTableCode(tableCode);
                                                codeTable.setTableName(tableName);
                                                codeTable.setCreateTime(LocalDateTime.now());
                                                codeTable.setUpdateTime(LocalDateTime.now());
                                                codeTableService.save(codeTable);
                                        } else {
                                                // 如果存在，且 Excel 中的表名有变化，则更新表名
                                                if (tableName != null && !tableName.isEmpty()
                                                                && !tableName.equals(codeTable.getTableName())) {
                                                        codeTable.setTableName(tableName);
                                                        codeTable.setUpdateTime(LocalDateTime.now());
                                                        codeTableService.updateById(codeTable);
                                                }
                                        }

                                        // 3.3 插入新数据
                                        // 将 DTO 转换为实体并批量插入
                                        List<CodeDirectory> entitiesToSave = new ArrayList<>();
                                        for (CodeDirectoryImportExportDTO dto : dtoList) {
                                                CodeDirectory codeDirectory = new CodeDirectory();
                                                BeanUtils.copyProperties(dto, codeDirectory);

                                                // 处理日期格式转换 (String -> LocalDate)
                                                if (dto.getStartDate() != null && !dto.getStartDate().isEmpty()) {
                                                        try {
                                                                codeDirectory.setStartDate(LocalDate.parse(
                                                                                dto.getStartDate(),
                                                                                DateTimeFormatter.ofPattern(
                                                                                                "yyyy-MM-dd")));
                                                        } catch (Exception e) {
                                                                // 忽略日期解析错误
                                                        }
                                                }
                                                if (dto.getEndDate() != null && !dto.getEndDate().isEmpty()) {
                                                        try {
                                                                codeDirectory.setEndDate(LocalDate.parse(
                                                                                dto.getEndDate(),
                                                                                DateTimeFormatter.ofPattern(
                                                                                                "yyyy-MM-dd")));
                                                        } catch (Exception e) {
                                                                // 忽略日期解析错误
                                                        }
                                                }

                                                // 确保 SystemCode 被正确设置 (防止 DTO 复制遗漏)
                                                if (codeDirectory.getSystemCode() == null) {
                                                        codeDirectory.setSystemCode(systemCode);
                                                }

                                                codeDirectory.setCreateTime(LocalDateTime.now());
                                                codeDirectory.setUpdateTime(LocalDateTime.now());
                                                entitiesToSave.add(codeDirectory);
                                        }
                                        // 批量保存
                                        boolean batchResult = saveBatch(entitiesToSave);
                                        if (batchResult) {
                                                insertedCount.addAndGet(entitiesToSave.size());
                                        } else {
                                                failedCount.addAndGet(entitiesToSave.size());
                                        }
                                });
                        });

                } catch (IOException e) {
                        // 如果读取文件 IO 异常，视为全部失败（无法统计具体条数，直接抛出）
                        throw new RuntimeException("Import failed: " + e.getMessage());
                } catch (Exception e) {
                        throw new RuntimeException("Import process error: " + e.getMessage());
                }

                stats.setDeleted(deletedCount.get());
                stats.setInserted(insertedCount.get());
                stats.setFailed(failedCount.get());
                return stats;
        }

        /**
         * 导出代码目录数据
         * 
         * @param response HTTP 响应对象，用于写入 Excel 文件流
         */
        @Override
        public void exportData(HttpServletResponse response) {
                try {
                        // 设置响应头，指定返回类型为 Excel
                        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
                        response.setCharacterEncoding("utf-8");
                        // 文件名 URL 编码，防止中文乱码
                        String fileName = URLEncoder.encode("code_directory_export", "UTF-8").replaceAll("\\+", "%20");
                        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

                        // 1. 查询所有代码目录数据
                        List<CodeDirectory> list = list();
                        List<CodeDirectoryImportExportDTO> exportList = new ArrayList<>();

                        // 2. 转换为导出 DTO
                        for (CodeDirectory cd : list) {
                                CodeDirectoryImportExportDTO dto = new CodeDirectoryImportExportDTO();
                                BeanUtils.copyProperties(cd, dto);

                                // 处理日期格式化 (LocalDate -> String)
                                if (cd.getStartDate() != null) {
                                        dto.setStartDate(cd.getStartDate()
                                                        .format(DateTimeFormatter.ofPattern("yyyy-MM-dd")));
                                }
                                if (cd.getEndDate() != null) {
                                        dto.setEndDate(cd.getEndDate()
                                                        .format(DateTimeFormatter.ofPattern("yyyy-MM-dd")));
                                }
                                exportList.add(dto);
                        }

                        // 3. 写出 Excel
                        EasyExcel.write(response.getOutputStream(), CodeDirectoryImportExportDTO.class)
                                        .sheet("码表数据")
                                        .doWrite(exportList);
                } catch (IOException e) {
                        throw new RuntimeException("Export failed: " + e.getMessage());
                }
        }
}
