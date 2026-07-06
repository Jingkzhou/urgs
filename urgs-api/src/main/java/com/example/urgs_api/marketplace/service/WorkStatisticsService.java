package com.example.urgs_api.marketplace.service;

import com.example.urgs_api.marketplace.dto.WorkStatisticsDTO;

import java.time.LocalDate;

public interface WorkStatisticsService {
    WorkStatisticsDTO getStatistics(String publisherId, LocalDate startDate, LocalDate endDate);
}
