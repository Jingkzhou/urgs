package com.example.urgs_api.issue.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.issue.dto.IssueStatsDTO;
import com.example.urgs_api.issue.model.Issue;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.multipart.MultipartFile;

public interface IssueService extends IService<Issue> {
    Page<Issue> getIssueList(Page<Issue> page, String keyword, String status, String issueType, String system,
            String reporter, String handler, String startTime, String endTime);

    void importData(MultipartFile file);

    void exportData(HttpServletResponse response, String keyword, String status, String issueType, String handler);

    IssueStatsDTO getStats(String frequency, String startDate, String endDate);
}
