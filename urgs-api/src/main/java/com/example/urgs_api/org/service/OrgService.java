package com.example.urgs_api.org.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.org.dto.OrgImportRequest;
import com.example.urgs_api.org.model.Org;

import java.util.List;

public interface OrgService extends IService<Org> {
    void batchUpsert(List<OrgImportRequest> requests);
}
