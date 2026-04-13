package com.example.urgs_api.org.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.org.dto.OrgImportRequest;
import com.example.urgs_api.org.mapper.OrgMapper;
import com.example.urgs_api.org.model.Org;
import com.example.urgs_api.org.service.OrgService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class OrgServiceImpl extends ServiceImpl<OrgMapper, Org> implements OrgService {

    @Override
    @Transactional
    public void batchUpsert(List<OrgImportRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        for (OrgImportRequest request : requests) {
            if (!StringUtils.hasText(request.getCode())) {
                continue;
            }

            Org existing = baseMapper.selectOne(new LambdaQueryWrapper<Org>()
                    .eq(Org::getCode, request.getCode())
                    .last("limit 1"));

            Org org = existing != null ? existing : new Org();
            org.setName(request.getName());
            org.setCode(request.getCode());
            org.setType(request.getType());
            org.setTypeName(request.getTypeName());
            org.setStatus(request.getStatus());
            org.setOrderNum(request.getOrderNum() == null ? 0 : request.getOrderNum());
            org.setParentId(normalizeRootParentId(request.getParentId()));

            if (existing != null) {
                this.updateById(org);
            } else {
                this.save(org);
            }
        }

        List<Org> allOrgs = this.list();
        Map<String, Org> orgByCode = new HashMap<>();
        Map<String, Org> orgByName = new HashMap<>();
        Map<String, Org> orgById = new HashMap<>();

        for (Org org : allOrgs) {
            if (StringUtils.hasText(org.getCode())) {
                orgByCode.put(org.getCode(), org);
            }
            if (StringUtils.hasText(org.getName())) {
                orgByName.putIfAbsent(org.getName(), org);
            }
            if (org.getId() != null) {
                orgById.put(String.valueOf(org.getId()), org);
            }
        }

        for (OrgImportRequest request : requests) {
            if (!StringUtils.hasText(request.getCode())) {
                continue;
            }

            Org current = orgByCode.get(request.getCode());
            if (current == null) {
                continue;
            }

            String resolvedParentId = resolveParentId(request, current, orgById, orgByCode, orgByName);
            if (!equalsNullable(current.getParentId(), resolvedParentId)) {
                current.setParentId(resolvedParentId);
                this.updateById(current);
            }
        }
    }

    private String resolveParentId(
            OrgImportRequest request,
            Org current,
            Map<String, Org> orgById,
            Map<String, Org> orgByCode,
            Map<String, Org> orgByName) {
        if (isRootParent(request.getParentId(), request.getParentCode(), request.getParentName())) {
            return "root";
        }

        if (StringUtils.hasText(request.getParentCode())) {
            Org parent = orgByCode.get(request.getParentCode());
            if (isValidParent(current, parent)) {
                return String.valueOf(parent.getId());
            }
        }

        if (StringUtils.hasText(request.getParentName())) {
            Org parent = orgByName.get(request.getParentName());
            if (isValidParent(current, parent)) {
                return String.valueOf(parent.getId());
            }
        }

        if (StringUtils.hasText(request.getParentId())) {
            Org parent = orgById.get(request.getParentId());
            if (isValidParent(current, parent)) {
                return String.valueOf(parent.getId());
            }
        }

        return normalizeRootParentId(request.getParentId());
    }

    private boolean isRootParent(String parentId, String parentCode, String parentName) {
        return (!StringUtils.hasText(parentId) && !StringUtils.hasText(parentCode) && !StringUtils.hasText(parentName))
                || "root".equals(parentId)
                || "ROOT".equals(parentCode)
                || "根节点/总行".equals(parentName);
    }

    private boolean isValidParent(Org current, Org parent) {
        return parent != null && current.getId() != null && !current.getId().equals(parent.getId());
    }

    private String normalizeRootParentId(String parentId) {
        return StringUtils.hasText(parentId) ? parentId : "root";
    }

    private boolean equalsNullable(String left, String right) {
        if (left == null) {
            return right == null;
        }
        return left.equals(right);
    }
}
