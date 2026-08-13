package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.metadata.dto.AgentRegulatoryAssetSearchResponse;
import com.example.urgs_api.metadata.dto.AgentRegulatoryAssetSearchResponse.Evidence;
import com.example.urgs_api.metadata.dto.AgentRegulatoryAssetSearchResponse.Item;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Consumer;

@Service
public class AgentRegulatoryAssetQueryService {

    private static final int MAX_LIMIT = 20;
    private static final int MAX_KEYWORD_LENGTH = 100;
    private static final int MAX_SUMMARY_LENGTH = 500;

    private final RegTableService regTableService;
    private final SysSystemService sysSystemService;

    public AgentRegulatoryAssetQueryService(
            RegTableService regTableService,
            SysSystemService sysSystemService) {
        this.regTableService = regTableService;
        this.sysSystemService = sysSystemService;
    }

    public AgentRegulatoryAssetSearchResponse search(
            Long requesterUserId,
            String keyword,
            String requestedSystemCode,
            int limit,
            String traceId) {
        String normalizedKeyword = normalizeRequiredKeyword(keyword);
        int effectiveLimit = validateLimit(limit);
        Map<String, String> allowedSystemCodes = resolveAllowedSystemCodes(requesterUserId);
        List<String> effectiveSystemCodes = resolveEffectiveSystemCodes(requestedSystemCode, allowedSystemCodes);

        if (effectiveSystemCodes.isEmpty()) {
            return new AgentRegulatoryAssetSearchResponse(List.of(), 0, List.of(), traceId);
        }

        LinkedHashMap<Long, RegTable> matches = new LinkedHashMap<>();
        Page<RegTable> exactPage = regTableService.page(
                new Page<>(1, effectiveLimit, false),
                createSearchQuery(effectiveSystemCodes, wrapper -> wrapper.and(group -> group
                        .eq(RegTable::getName, normalizedKeyword)
                        .or()
                        .eq(RegTable::getCnName, normalizedKeyword))));
        exactPage.getRecords().forEach(table -> matches.put(table.getId(), table));

        if (matches.size() < effectiveLimit) {
            int fuzzyLimit = effectiveLimit - matches.size();
            LambdaQueryWrapper<RegTable> fuzzyQuery = createSearchQuery(effectiveSystemCodes, wrapper -> wrapper
                    .and(group -> group
                            .like(RegTable::getName, normalizedKeyword)
                            .or()
                            .like(RegTable::getCnName, normalizedKeyword)
                            .or()
                            .like(RegTable::getBusinessCaliber, normalizedKeyword)
                            .or()
                            .like(RegTable::getFillInstruction, normalizedKeyword)));
            if (!matches.isEmpty()) {
                fuzzyQuery.notIn(RegTable::getId, matches.keySet());
            }
            Page<RegTable> fuzzyPage = regTableService.page(new Page<>(1, fuzzyLimit, false), fuzzyQuery);
            fuzzyPage.getRecords().forEach(table -> matches.put(table.getId(), table));
        }

        List<Item> items = matches.values().stream()
                .limit(effectiveLimit)
                .map(this::toItem)
                .toList();
        return new AgentRegulatoryAssetSearchResponse(
                items,
                items.size(),
                effectiveSystemCodes,
                traceId);
    }

    private LambdaQueryWrapper<RegTable> createSearchQuery(
            List<String> effectiveSystemCodes,
            Consumer<LambdaQueryWrapper<RegTable>> searchCondition) {
        LambdaQueryWrapper<RegTable> query = new LambdaQueryWrapper<>();
        query.in(RegTable::getSystemCode, effectiveSystemCodes);
        searchCondition.accept(query);
        query.orderByAsc(RegTable::getSortOrder).orderByAsc(RegTable::getId);
        return query;
    }

    private Map<String, String> resolveAllowedSystemCodes(Long requesterUserId) {
        if (requesterUserId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "缺少当前用户身份");
        }
        Map<String, String> result = new LinkedHashMap<>();
        for (SysSystem system : sysSystemService.getSystems(requesterUserId, false)) {
            String clientId = trimToNull(system.getClientId());
            if (clientId != null) {
                result.putIfAbsent(clientId.toLowerCase(Locale.ROOT), clientId);
            }
        }
        return result;
    }

    private List<String> resolveEffectiveSystemCodes(
            String requestedSystemCode,
            Map<String, String> allowedSystemCodes) {
        String normalizedRequestedSystem = trimToNull(requestedSystemCode);
        if (normalizedRequestedSystem == null) {
            return new ArrayList<>(allowedSystemCodes.values());
        }
        String matchedSystemCode = allowedSystemCodes.get(normalizedRequestedSystem.toLowerCase(Locale.ROOT));
        if (matchedSystemCode == null) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权访问指定监管系统");
        }
        return List.of(matchedSystemCode);
    }

    private Item toItem(RegTable table) {
        String sourceId = table.getId() == null ? null : table.getId().toString();
        return new Item(
                sourceId,
                table.getName(),
                table.getCnName(),
                table.getSystemCode(),
                table.getSubjectCode(),
                table.getSubjectName(),
                buildSummary(table),
                List.of(new Evidence("reg_table", sourceId, table.getUpdateTime())));
    }

    private String buildSummary(RegTable table) {
        String summary = firstNonBlank(
                table.getBusinessCaliber(),
                table.getFillInstruction(),
                table.getDevNotes(),
                table.getCnName());
        if (summary == null || summary.length() <= MAX_SUMMARY_LENGTH) {
            return summary;
        }
        return summary.substring(0, MAX_SUMMARY_LENGTH);
    }

    private String normalizeRequiredKeyword(String keyword) {
        String normalized = trimToNull(keyword);
        if (normalized == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "keyword 不能为空");
        }
        if (normalized.length() > MAX_KEYWORD_LENGTH) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "keyword 长度不能超过 100");
        }
        return normalized;
    }

    private int validateLimit(int limit) {
        if (limit < 1 || limit > MAX_LIMIT) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "limit 必须在 1 到 20 之间");
        }
        return limit;
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            String normalized = trimToNull(value);
            if (normalized != null) {
                return normalized;
            }
        }
        return null;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String normalized = value.trim();
        return normalized.isEmpty() ? null : normalized;
    }
}
