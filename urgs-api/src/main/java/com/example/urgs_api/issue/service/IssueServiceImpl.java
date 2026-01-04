package com.example.urgs_api.issue.service;

import com.alibaba.excel.EasyExcel;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.issue.dto.IssueExportDTO;
import com.example.urgs_api.issue.mapper.IssueMapper;
import com.example.urgs_api.issue.model.Issue;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import com.example.urgs_api.issue.dto.IssueStatsDTO;

@Service
public class IssueServiceImpl extends ServiceImpl<IssueMapper, Issue> implements IssueService {

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Override
    public Page<Issue> getIssueList(Page<Issue> page, String keyword, String status, String issueType, String system,
            String reporter, String handler, String startTime, String endTime) {
        LambdaQueryWrapper<Issue> wrapper = new LambdaQueryWrapper<>();

        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w
                    .like(Issue::getTitle, keyword)
                    .or()
                    .like(Issue::getId, keyword)
                    .or()
                    .like(Issue::getSystem, keyword));
        }

        if (StringUtils.hasText(status) && !"all".equals(status)) {
            wrapper.eq(Issue::getStatus, status);
        }

        if (StringUtils.hasText(issueType) && !"all".equals(issueType)) {
            wrapper.eq(Issue::getIssueType, issueType);
        }

        if (StringUtils.hasText(system)) {
            wrapper.eq(Issue::getSystem, system);
        }

        if (StringUtils.hasText(reporter)) {
            wrapper.like(Issue::getReporter, reporter);
        }

        if (StringUtils.hasText(handler)) {
            wrapper.like(Issue::getHandler, handler);
        }

        if (StringUtils.hasText(startTime)) {
            try {
                wrapper.ge(Issue::getOccurTime, LocalDateTime.parse(startTime + " 00:00:00", DATE_TIME_FORMATTER));
            } catch (Exception e) {
                // Ignore invalid date format
            }
        }

        if (StringUtils.hasText(endTime)) {
            try {
                wrapper.le(Issue::getOccurTime, LocalDateTime.parse(endTime + " 23:59:59", DATE_TIME_FORMATTER));
            } catch (Exception e) {
                // Ignore invalid date format
            }
        }

        wrapper.orderByDesc(Issue::getCreateTime);

        return this.page(page, wrapper);
    }

    @Override
    public void importData(MultipartFile file) {
        try {
            EasyExcel.read(file.getInputStream(), IssueExportDTO.class,
                    new com.alibaba.excel.read.listener.PageReadListener<IssueExportDTO>(dataList -> {
                        for (IssueExportDTO dto : dataList) {
                            Issue issue = new Issue();
                            issue.setTitle(dto.getTitle());
                            issue.setDescription(dto.getDescription());
                            issue.setSystem(dto.getSystem());
                            issue.setReporter(dto.getReporter());
                            issue.setHandler(dto.getHandler());
                            issue.setIssueType(dto.getIssueType());
                            issue.setStatus(dto.getStatus() != null ? dto.getStatus() : "新建");

                            // Parse dates
                            if (StringUtils.hasText(dto.getOccurTime())) {
                                try {
                                    issue.setOccurTime(LocalDateTime.parse(dto.getOccurTime(), DATE_TIME_FORMATTER));
                                } catch (Exception e) {
                                    // Ignore parse error
                                }
                            }
                            if (StringUtils.hasText(dto.getResolveTime())) {
                                try {
                                    issue.setResolveTime(
                                            LocalDateTime.parse(dto.getResolveTime(), DATE_TIME_FORMATTER));
                                } catch (Exception e) {
                                    // Ignore parse error
                                }
                            }

                            // Parse work hours
                            if (StringUtils.hasText(dto.getWorkHours())) {
                                try {
                                    issue.setWorkHours(new BigDecimal(dto.getWorkHours()));
                                } catch (Exception e) {
                                    issue.setWorkHours(BigDecimal.ZERO);
                                }
                            }

                            // Check if exists by id
                            if (StringUtils.hasText(dto.getId())) {
                                Issue existing = getById(dto.getId());
                                if (existing != null) {
                                    issue.setId(existing.getId());
                                    issue.setUpdateTime(LocalDateTime.now());
                                    updateById(issue);
                                    continue;
                                }
                            }

                            // New issue
                            issue.setCreateTime(LocalDateTime.now());
                            issue.setUpdateTime(LocalDateTime.now());
                            save(issue);
                        }
                    })).sheet().doRead();
        } catch (IOException e) {
            throw new RuntimeException("导入失败: " + e.getMessage());
        }
    }

    @Override
    public void exportData(HttpServletResponse response, String keyword, String status, String issueType,
            String handler) {
        try {
            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setCharacterEncoding("utf-8");
            String fileName = URLEncoder.encode("问题列表导出", "UTF-8").replaceAll("\\+", "%20");
            response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

            // Build query
            LambdaQueryWrapper<Issue> wrapper = new LambdaQueryWrapper<>();
            if (StringUtils.hasText(keyword)) {
                wrapper.and(w -> w
                        .like(Issue::getTitle, keyword)
                        .or()
                        .like(Issue::getId, keyword)
                        .or()
                        .like(Issue::getSystem, keyword));
            }
            if (StringUtils.hasText(status) && !"all".equals(status)) {
                wrapper.eq(Issue::getStatus, status);
            }
            if (StringUtils.hasText(issueType) && !"all".equals(issueType)) {
                wrapper.eq(Issue::getIssueType, issueType);
            }
            if (StringUtils.hasText(handler)) {
                wrapper.like(Issue::getHandler, handler);
            }
            wrapper.orderByDesc(Issue::getCreateTime);

            List<Issue> list = list(wrapper);
            List<IssueExportDTO> exportList = new ArrayList<>();

            for (Issue issue : list) {
                IssueExportDTO dto = new IssueExportDTO();
                dto.setId(issue.getId());
                dto.setTitle(issue.getTitle());
                dto.setDescription(issue.getDescription());
                dto.setSystem(issue.getSystem());
                dto.setReporter(issue.getReporter());
                dto.setHandler(issue.getHandler());
                dto.setSolution(issue.getSolution());
                dto.setIssueType(issue.getIssueType());
                dto.setStatus(issue.getStatus());

                if (issue.getOccurTime() != null) {
                    dto.setOccurTime(issue.getOccurTime().format(DATE_TIME_FORMATTER));
                }
                if (issue.getResolveTime() != null) {
                    dto.setResolveTime(issue.getResolveTime().format(DATE_TIME_FORMATTER));
                }
                if (issue.getWorkHours() != null) {
                    dto.setWorkHours(issue.getWorkHours().toString());
                }

                exportList.add(dto);
            }

            EasyExcel.write(response.getOutputStream(), IssueExportDTO.class)
                    .sheet("问题列表")
                    .doWrite(exportList);
        } catch (IOException e) {
            throw new RuntimeException("导出失败: " + e.getMessage());
        }
    }

    @Override
    public IssueStatsDTO getStats(String frequency) {
        IssueStatsDTO stats = new IssueStatsDTO();

        List<Issue> allIssues = list();

        // 总数统计
        stats.setTotalCount(allIssues.size());
        stats.setNewCount(allIssues.stream().filter(i -> "新建".equals(i.getStatus())).count());
        stats.setInProgressCount(allIssues.stream().filter(i -> "处理中".equals(i.getStatus())).count());
        stats.setCompletedCount(allIssues.stream().filter(i -> "完成".equals(i.getStatus())).count());
        stats.setLeftoverCount(allIssues.stream().filter(i -> "遗留".equals(i.getStatus())).count());

        // 总工时
        BigDecimal totalHours = allIssues.stream()
                .map(Issue::getWorkHours)
                .filter(h -> h != null)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        stats.setTotalWorkHours(totalHours);

        // 按状态统计
        Map<String, Long> statusMap = allIssues.stream()
                .map(i -> {
                    String s = i.getStatus();
                    return (s == null || s.trim().isEmpty()) ? "新建" : s;
                })
                .collect(java.util.stream.Collectors.groupingBy(s -> s,
                        java.util.stream.Collectors.counting()));
        List<IssueStatsDTO.StatItem> statusStats = statusMap.entrySet().stream()
                .map(e -> new IssueStatsDTO.StatItem(e.getKey(), e.getValue()))
                .collect(java.util.stream.Collectors.toList());
        stats.setStatusStats(statusStats);

        // 按问题类型统计
        Map<String, Long> typeMap = allIssues.stream()
                .filter(i -> i.getIssueType() != null)
                .collect(java.util.stream.Collectors.groupingBy(Issue::getIssueType,
                        java.util.stream.Collectors.counting()));
        List<IssueStatsDTO.StatItem> typeStats = typeMap.entrySet().stream()
                .map(e -> new IssueStatsDTO.StatItem(e.getKey(), e.getValue()))
                .collect(java.util.stream.Collectors.toList());
        stats.setTypeStats(typeStats);

        // 按归属系统统计
        Map<String, Long> systemMap = allIssues.stream()
                .filter(i -> i.getSystem() != null)
                .collect(java.util.stream.Collectors.groupingBy(Issue::getSystem,
                        java.util.stream.Collectors.counting()));
        List<IssueStatsDTO.StatItem> systemStats = systemMap.entrySet().stream()
                .map(e -> new IssueStatsDTO.StatItem(e.getKey(), e.getValue()))
                .collect(java.util.stream.Collectors.toList());
        stats.setSystemStats(systemStats);

        // 按处理人统计
        Map<String, List<Issue>> handlerMap = allIssues.stream()
                .filter(i -> i.getHandler() != null && !i.getHandler().isEmpty())
                .collect(java.util.stream.Collectors.groupingBy(Issue::getHandler));
        List<IssueStatsDTO.HandlerStats> handlerStats = handlerMap.entrySet().stream()
                .map(e -> {
                    BigDecimal hours = e.getValue().stream()
                            .map(Issue::getWorkHours)
                            .filter(h -> h != null)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                    return new IssueStatsDTO.HandlerStats(e.getKey(), e.getValue().size(), hours);
                })
                .sorted((a, b) -> Long.compare(b.getIssueCount(), a.getIssueCount()))
                .collect(java.util.stream.Collectors.toList());
        stats.setHandlerStats(handlerStats);

        // 按时间频度统计趋势
        Map<String, Long> trendMap = allIssues.stream()
                .filter(i -> i.getOccurTime() != null)
                .collect(java.util.stream.Collectors.groupingBy(
                        i -> formatByFrequency(i.getOccurTime(), frequency),
                        java.util.stream.Collectors.counting()));

        List<IssueStatsDTO.TrendItem> trend = trendMap.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> new IssueStatsDTO.TrendItem(e.getKey(), e.getValue()))
                .collect(java.util.stream.Collectors.toList());
        stats.setTrend(trend);

        return stats;
    }

    private String formatByFrequency(LocalDateTime dateTime, String frequency) {
        if ("day".equals(frequency)) {
            return dateTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        } else if ("month".equals(frequency)) {
            return dateTime.format(DateTimeFormatter.ofPattern("yyyy-MM"));
        } else if ("year".equals(frequency)) {
            return dateTime.format(DateTimeFormatter.ofPattern("yyyy"));
        } else if ("quarter".equals(frequency)) {
            int quarter = (dateTime.getMonthValue() - 1) / 3 + 1;
            return dateTime.getYear() + "-Q" + quarter;
        } else if ("half".equals(frequency)) {
            int half = dateTime.getMonthValue() <= 6 ? 1 : 2;
            return dateTime.getYear() + "-H" + half;
        }
        // Default to month
        return dateTime.format(DateTimeFormatter.ofPattern("yyyy-MM"));
    }
}
