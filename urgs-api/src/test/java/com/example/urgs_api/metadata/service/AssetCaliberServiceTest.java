package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.CaliberChangeRequest;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.ElementCaliberChange;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AssetCaliberServiceTest {

    private static final Long USER_ID = 7L;
    private static final Long TABLE_ID = 101L;
    private static final Long ELEMENT_ID = 201L;
    private static final LocalDateTime UPDATE_TIME = LocalDateTime.of(2026, 7, 15, 10, 20, 30);

    @Mock
    private RegTableService regTableService;
    @Mock
    private RegElementService regElementService;
    @Mock
    private MaintenanceRecordService maintenanceRecordService;
    @Mock
    private UserService userService;
    @Mock
    private SysSystemService sysSystemService;

    private AssetCaliberService service;

    @BeforeEach
    void setUp() {
        service = new AssetCaliberService(
                regTableService,
                regElementService,
                maintenanceRecordService,
                userService,
                sysSystemService);
    }

    @Test
    void rejectsPreviewWhenRequesterLacksRegulatoryAssetPermission() {
        stubUser(Set.of(), "系统1104", "1104");

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.preview(request(false, null, List.of())));

        assertEquals(403, exception.getStatusCode().value());
        verify(regTableService, never()).getById(any());
    }

    @Test
    void rejectsTableOutsideRequesterSystemScope() {
        stubUser(Set.of("metadata:asset:view"), "系统1105", "1105");
        when(regTableService.getById(TABLE_ID)).thenReturn(table(null, UPDATE_TIME));

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.preview(request(false, "新表口径", List.of())));

        assertEquals(403, exception.getStatusCode().value());
        verify(regElementService, never()).list(any(Wrapper.class));
    }

    @Test
    void reportsOptimisticConflictInPreview() {
        stubUser(Set.of("metadata:asset:view"), "系统1104", "1104");
        when(regTableService.getById(TABLE_ID)).thenReturn(table("旧表口径", UPDATE_TIME));
        when(regElementService.list(any(Wrapper.class))).thenReturn(List.of());

        CaliberChangeRequest request = new CaliberChangeRequest(
                USER_ID,
                TABLE_ID,
                UPDATE_TIME.minusMinutes(1),
                "新表口径",
                List.of(),
                null,
                null,
                "SELECT 1",
                false);
        var preview = service.preview(request);

        assertFalse(preview.valid());
        assertTrue(preview.changes().get(0).conflict());
        assertTrue(preview.errors().stream().anyMatch(message -> message.contains("更新时间")));
    }

    @Test
    void rejectsElementsOutsideTheTargetRegulatoryTable() {
        stubUser(Set.of("metadata:asset:view"), "系统1104", "1104");
        when(regTableService.getById(TABLE_ID)).thenReturn(table(null, UPDATE_TIME));
        when(regElementService.list(any(Wrapper.class))).thenReturn(List.of());

        var preview = service.preview(request(
                false,
                null,
                List.of(new ElementCaliberChange(999L, UPDATE_TIME, "字段口径"))));

        assertFalse(preview.valid());
        assertTrue(preview.errors().stream().anyMatch(message -> message.contains("不属于目标监管表")));
    }

    @Test
    void rejectsAmbiguousRegulatoryTableResolution() {
        stubUser(Set.of("metadata:asset:view"), "系统1104", "1104");
        when(regTableService.list(any(Wrapper.class)))
                .thenReturn(List.of(table(null, UPDATE_TIME), table(null, UPDATE_TIME)));

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.resolveTable(USER_ID, "1104", "LOAN_SUMMARY"));

        assertEquals(409, exception.getStatusCode().value());
    }

    @Test
    void applyRequiresExplicitConfirmation() {
        stubUser(Set.of("metadata:asset:view", "metadata:asset:element:edit"), "系统1104", "1104");

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.apply(request(false, null, List.of())));

        assertEquals(400, exception.getStatusCode().value());
        verify(regTableService, never()).getById(any());
    }

    @Test
    void tableCaliberApplyRequiresTableEditPermission() {
        stubUser(Set.of("metadata:asset:view"), "系统1104", "1104");
        when(regTableService.getById(TABLE_ID)).thenReturn(table("旧表口径", UPDATE_TIME));
        when(regElementService.list(any(Wrapper.class))).thenReturn(List.of());

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.apply(request(true, "新表口径", List.of())));

        assertEquals(403, exception.getStatusCode().value());
        verify(regTableService, never()).update(any(Wrapper.class));
    }

    @Test
    void appliesChangedElementWritesAuditAndReturnsFreshValue() {
        stubUser(Set.of("metadata:asset:view", "metadata:asset:element:edit"), "系统1104", "1104");
        RegTable table = table(null, UPDATE_TIME);
        RegElement oldElement = element("旧指标口径", UPDATE_TIME);
        RegElement updatedElement = element("新指标口径", UPDATE_TIME.plusSeconds(1));
        when(regTableService.getById(TABLE_ID)).thenReturn(table, table);
        when(regElementService.list(any(Wrapper.class)))
                .thenReturn(List.of(oldElement), List.of(updatedElement));
        when(regElementService.update(any(Wrapper.class))).thenReturn(true);
        when(maintenanceRecordService.save(any(MaintenanceRecord.class))).thenReturn(true);

        var result = service.apply(request(
                true,
                null,
                List.of(new ElementCaliberChange(ELEMENT_ID, UPDATE_TIME, "新指标口径"))));

        assertEquals(1, result.updatedCount());
        assertEquals(0, result.skippedCount());
        assertEquals("新指标口径", result.table().elements().get(0).businessCaliber());
        verify(regElementService).update(any(Wrapper.class));
        verify(maintenanceRecordService).save(any(MaintenanceRecord.class));
    }

    private void stubUser(Set<String> permissions, String systems, String allowedClientId) {
        User user = new User();
        user.setId(USER_ID);
        user.setName("测试用户");
        user.setEmpId("E0007");
        user.setSystem(systems);
        when(userService.getById(USER_ID)).thenReturn(user);
        when(userService.getUserPermissions(USER_ID)).thenReturn(permissions);
        SysSystem system = new SysSystem();
        system.setName(systems);
        system.setClientId(allowedClientId);
        lenient().when(sysSystemService.list(USER_ID)).thenReturn(List.of(system));
    }

    private CaliberChangeRequest request(
            boolean confirmed,
            String tableBusinessCaliber,
            List<ElementCaliberChange> elements) {
        return new CaliberChangeRequest(
                USER_ID,
                TABLE_ID,
                UPDATE_TIME,
                tableBusinessCaliber,
                elements,
                "REQ-1",
                "测试回写",
                "INSERT INTO target SELECT * FROM source",
                confirmed);
    }

    private RegTable table(String businessCaliber, LocalDateTime updateTime) {
        RegTable table = new RegTable();
        table.setId(TABLE_ID);
        table.setName("LOAN_SUMMARY");
        table.setCnName("贷款汇总");
        table.setSystemCode("1104");
        table.setBusinessCaliber(businessCaliber);
        table.setUpdateTime(updateTime);
        return table;
    }

    private RegElement element(String businessCaliber, LocalDateTime updateTime) {
        RegElement element = new RegElement();
        element.setId(ELEMENT_ID);
        element.setTableId(TABLE_ID);
        element.setType("INDICATOR");
        element.setName("LOAN_BALANCE");
        element.setCnName("贷款余额");
        element.setBusinessCaliber(businessCaliber);
        element.setUpdateTime(updateTime);
        return element;
    }
}
