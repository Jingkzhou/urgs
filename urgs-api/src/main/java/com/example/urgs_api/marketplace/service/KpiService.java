package com.example.urgs_api.marketplace.service;

import com.example.urgs_api.marketplace.dto.KpiDetailDTO;
import com.example.urgs_api.marketplace.dto.KpiSummaryDTO;
import com.example.urgs_api.marketplace.dto.TeamKpiDTO;
import com.example.urgs_api.marketplace.model.KpiSnapshot;

import java.time.LocalDate;
import java.util.List;

public interface KpiService {
    KpiSummaryDTO getUserSummary(String userId, LocalDate startDate, LocalDate endDate);

    List<KpiDetailDTO> getUserDetails(String userId, LocalDate startDate, LocalDate endDate);

    TeamKpiDTO getTeamKpi(LocalDate startDate, LocalDate endDate);

    List<KpiSummaryDTO> getLeaderboard(String dimension, LocalDate startDate, LocalDate endDate);

    List<KpiSnapshot> generateMonthlySnapshot(String period, String generatedBy);

    List<KpiSnapshot> listSnapshots(String period);
}
