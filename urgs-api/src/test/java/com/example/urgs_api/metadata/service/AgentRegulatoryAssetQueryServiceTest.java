package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.metadata.dto.AgentRegulatoryAssetSearchResponse;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AgentRegulatoryAssetQueryServiceTest {

    private RegTableService regTableService;
    private SysSystemService sysSystemService;
    private AgentRegulatoryAssetQueryService queryService;

    @BeforeEach
    void setUp() {
        regTableService = mock(RegTableService.class);
        sysSystemService = mock(SysSystemService.class);
        queryService = new AgentRegulatoryAssetQueryService(regTableService, sysSystemService);
    }

    @Test
    void searchesOnlyWithinAuthenticatedUsersAllowedSystem() {
        when(sysSystemService.getSystems(7L, false)).thenReturn(List.of(system("EAST5"), system("SMTMODS")));
        when(regTableService.page(any(Page.class), any(Wrapper.class)))
                .thenReturn(pageOf(table(10L, "L_ACCT_LOAN", "贷款账户", "EAST5")))
                .thenReturn(pageOf());

        AgentRegulatoryAssetSearchResponse result = queryService.search(
                7L,
                "L_ACCT_LOAN",
                "east5",
                10,
                "trace-1");

        assertEquals(List.of("EAST5"), result.effectiveSystemCodes());
        assertEquals(1, result.count());
        assertEquals("10", result.items().get(0).assetId());
        assertEquals("L_ACCT_LOAN", result.items().get(0).tableCode());
        assertEquals("reg_table", result.items().get(0).evidence().get(0).source());
    }

    @Test
    void rejectsExplicitSystemOutsideAuthenticatedUsersScope() {
        when(sysSystemService.getSystems(7L, false)).thenReturn(List.of(system("EAST5")));

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> queryService.search(7L, "贷款", "SMTMODS", 10, "trace-2"));

        assertEquals(HttpStatus.FORBIDDEN, error.getStatusCode());
        verify(regTableService, never()).page(any(Page.class), any(Wrapper.class));
    }

    @Test
    void rejectsInvalidLimitBeforeQueryingAssets() {
        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> queryService.search(7L, "贷款", null, 21, "trace-3"));

        assertEquals(HttpStatus.BAD_REQUEST, error.getStatusCode());
        verify(regTableService, never()).page(any(Page.class), any(Wrapper.class));
    }

    private SysSystem system(String clientId) {
        SysSystem system = new SysSystem();
        system.setClientId(clientId);
        return system;
    }

    private RegTable table(Long id, String name, String cnName, String systemCode) {
        RegTable table = new RegTable();
        table.setId(id);
        table.setName(name);
        table.setCnName(cnName);
        table.setSystemCode(systemCode);
        table.setBusinessCaliber("监管业务口径");
        table.setUpdateTime(LocalDateTime.of(2026, 8, 13, 10, 0));
        return table;
    }

    private Page<RegTable> pageOf(RegTable... tables) {
        Page<RegTable> page = new Page<>(1, 20, false);
        page.setRecords(List.of(tables));
        return page;
    }
}
