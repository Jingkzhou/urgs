package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.marketplace.dto.WorkCreateDTO;
import com.example.urgs_api.marketplace.dto.WorkImportDTO;
import com.example.urgs_api.marketplace.model.Work;

import java.util.List;

public interface WorkService extends IService<Work> {
    Work createWork(WorkCreateDTO dto, String userId);

    int importWorks(List<WorkImportDTO> works, String userId);

    boolean publishWork(String workId, String userId);

    boolean cancelWork(String workId, String userId);

    int batchDeleteWorks(List<String> workIds, String userId);

    void recomputeTotalPoints(String workId);
}
