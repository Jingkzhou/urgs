package com.example.urgs_api.marketplace.service.impl;

import com.example.urgs_api.marketplace.dto.WorkCreateDTO;
import com.example.urgs_api.marketplace.dto.WorkImportDTO;
import com.example.urgs_api.marketplace.model.Work;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;

class WorkServiceImplTest {

    @Test
    void importWorksCreatesSystemMainTask() {
        WorkServiceImpl service = spy(new WorkServiceImpl());
        doReturn(new Work()).when(service).createWork(any(WorkCreateDTO.class), eq("1001"));

        WorkImportDTO importDTO = buildImportDTO();
        int importedCount = service.importWorks(List.of(importDTO), "1001");

        ArgumentCaptor<WorkCreateDTO> captor = ArgumentCaptor.forClass(WorkCreateDTO.class);
        verify(service).createWork(captor.capture(), eq("1001"));

        WorkCreateDTO createDTO = captor.getValue();
        assertEquals(1, importedCount);
        assertEquals("测试导入工作", createDTO.getTitle());
        assertEquals("测试导入工作", createDTO.getMainTask().getTitle());
        assertEquals("这是一段用于验证工作导入功能的详细描述", createDTO.getMainTask().getDescription());
        assertEquals("ASSIGN", createDTO.getMainTask().getAssignMode());
        assertEquals("1001", createDTO.getMainTask().getAssigneeId());
        assertEquals(0, createDTO.getMainTask().getPoints());
    }

    @Test
    void importWorksRejectsMissingPrimarySystemName() {
        WorkServiceImpl service = spy(new WorkServiceImpl());
        WorkImportDTO importDTO = buildImportDTO();
        importDTO.setPrimarySystem(false);
        importDTO.setPrimarySystemName(" ");

        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> service.importWorks(List.of(importDTO), "1001")
        );

        assertEquals("第2行：非主系统必须填写主系统名称", error.getMessage());
        verify(service, never()).createWork(any(WorkCreateDTO.class), eq("1001"));
    }

    private WorkImportDTO buildImportDTO() {
        WorkImportDTO dto = new WorkImportDTO();
        dto.setTitle(" 测试导入工作 ");
        dto.setDescription(" 这是一段用于验证工作导入功能的详细描述 ");
        dto.setPriority("P2");
        dto.setApplicationDepartment("科技开发部");
        dto.setApplicantName("测试用户");
        dto.setOwningSystem("统一监管报送系统");
        dto.setPrimarySystem(true);
        dto.setProjectType("变更类");
        return dto;
    }
}
