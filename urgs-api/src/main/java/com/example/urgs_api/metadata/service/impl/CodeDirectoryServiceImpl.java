package com.example.urgs_api.metadata.service.impl;

import com.alibaba.excel.EasyExcel;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.dto.CodeDirectoryImportExportDTO;
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

@Service
/**
 * 代码目录服务实现类
 */
public class CodeDirectoryServiceImpl extends ServiceImpl<CodeDirectoryMapper, CodeDirectory>
                implements CodeDirectoryService {

        @Override
        /**
         * 导入代码目录数据
         */
        public void importData(MultipartFile file) {
                try {
                        EasyExcel.read(file.getInputStream(), CodeDirectoryImportExportDTO.class,
                                        new com.alibaba.excel.read.listener.PageReadListener<CodeDirectoryImportExportDTO>(
                                                        dataList -> {
                                                                for (CodeDirectoryImportExportDTO dto : dataList) {
                                                                        CodeDirectory codeDirectory = new CodeDirectory();
                                                                        BeanUtils.copyProperties(dto, codeDirectory);

                                                                        // Handle date conversion if needed, assuming
                                                                        // DTO has String dates
                                                                        if (dto.getStartDate() != null && !dto
                                                                                        .getStartDate().isEmpty()) {
                                                                                try {
                                                                                        codeDirectory.setStartDate(
                                                                                                        LocalDate.parse(dto
                                                                                                                        .getStartDate(),
                                                                                                                        DateTimeFormatter
                                                                                                                                        .ofPattern("yyyy-MM-dd")));
                                                                                } catch (Exception e) {
                                                                                        // Ignore parse error
                                                                                }
                                                                        }
                                                                        if (dto.getEndDate() != null && !dto
                                                                                        .getEndDate().isEmpty()) {
                                                                                try {
                                                                                        codeDirectory.setEndDate(
                                                                                                        LocalDate.parse(dto
                                                                                                                        .getEndDate(),
                                                                                                                        DateTimeFormatter
                                                                                                                                        .ofPattern("yyyy-MM-dd")));
                                                                                } catch (Exception e) {
                                                                                        // Ignore parse error
                                                                                }
                                                                        }

                                                                        // Check if exists by code and tableCode
                                                                        QueryWrapper<CodeDirectory> queryWrapper = new QueryWrapper<>();
                                                                        queryWrapper.eq("code", codeDirectory.getCode())
                                                                                        .eq("table_code", codeDirectory
                                                                                                        .getTableCode());
                                                                        CodeDirectory existing = getOne(queryWrapper);

                                                                        if (existing != null) {
                                                                                codeDirectory.setId(existing.getId());
                                                                                codeDirectory.setUpdateTime(
                                                                                                LocalDateTime.now());
                                                                                updateById(codeDirectory);
                                                                        } else {
                                                                                codeDirectory.setCreateTime(
                                                                                                LocalDateTime.now());
                                                                                codeDirectory.setUpdateTime(
                                                                                                LocalDateTime.now());
                                                                                save(codeDirectory);
                                                                        }
                                                                }
                                                        }))
                                        .sheet().doRead();
                } catch (IOException e) {
                        throw new RuntimeException("Import failed: " + e.getMessage());
                }
        }

        @Override
        /**
         * 导出代码目录数据
         */
        public void exportData(HttpServletResponse response) {
                try {
                        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
                        response.setCharacterEncoding("utf-8");
                        String fileName = URLEncoder.encode("code_directory_export", "UTF-8").replaceAll("\\+", "%20");
                        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

                        List<CodeDirectory> list = list();
                        List<CodeDirectoryImportExportDTO> exportList = new ArrayList<>();

                        for (CodeDirectory cd : list) {
                                CodeDirectoryImportExportDTO dto = new CodeDirectoryImportExportDTO();
                                BeanUtils.copyProperties(cd, dto);
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

                        EasyExcel.write(response.getOutputStream(), CodeDirectoryImportExportDTO.class)
                                        .sheet("码表数据")
                                        .doWrite(exportList);
                } catch (IOException e) {
                        throw new RuntimeException("Export failed: " + e.getMessage());
                }
        }
}
