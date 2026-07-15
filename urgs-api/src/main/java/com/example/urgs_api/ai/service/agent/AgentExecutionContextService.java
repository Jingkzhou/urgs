package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class AgentExecutionContextService {

    private final UserService userService;
    private final SysSystemService sysSystemService;

    public AgentExecutionContextService(UserService userService, SysSystemService sysSystemService) {
        this.userService = userService;
        this.sysSystemService = sysSystemService;
    }

    public Map<String, Object> build(Long requesterUserId) {
        Set<String> permissions = requesterUserId == null
                ? Set.of()
                : userService.getUserPermissions(requesterUserId);
        User user = requesterUserId == null ? null : userService.getById(requesterUserId);
        List<String> allowedSystems = new ArrayList<>();
        List<String> allowedSystemNames = new ArrayList<>();
        List<String> allowedOrganizations = new ArrayList<>();
        if (user != null) {
            String systems = user.getSystem();
            if (systems == null || systems.isBlank() || "ALL".equalsIgnoreCase(systems.trim())) {
                allowedSystems.add("ALL");
                allowedSystemNames.add("ALL");
            } else {
                List<String> configuredSystems = Arrays.stream(systems.split(","))
                        .map(String::trim)
                        .filter(value -> !value.isEmpty())
                        .toList();
                allowedSystemNames.addAll(configuredSystems);
                allowedSystems.addAll(resolveSystemCodes(configuredSystems));
            }
            if (user.getOrgName() != null && !user.getOrgName().isBlank()) {
                allowedOrganizations.add(user.getOrgName().trim());
            }
        }
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("requester_user_id", requesterUserId);
        context.put("permissions", permissions);
        context.put("allowed_systems", allowedSystems);
        context.put("allowed_system_names", allowedSystemNames);
        context.put("allowed_organizations", allowedOrganizations);
        return context;
    }

    private List<String> resolveSystemCodes(List<String> configuredSystems) {
        Map<String, SysSystem> systemByNameOrCode = new LinkedHashMap<>();
        for (SysSystem system : sysSystemService.getSystems(null, true)) {
            if (!normalize(system.getName()).isEmpty()) {
                systemByNameOrCode.putIfAbsent(normalize(system.getName()), system);
            }
            if (!normalize(system.getClientId()).isEmpty()) {
                systemByNameOrCode.putIfAbsent(normalize(system.getClientId()), system);
            }
        }
        LinkedHashSet<String> resolved = new LinkedHashSet<>();
        for (String configured : configuredSystems) {
            SysSystem matched = systemByNameOrCode.get(normalize(configured));
            String code = matched == null ? configured : matched.getClientId();
            resolved.add(code == null || code.isBlank() ? configured : code.trim());
        }
        return List.copyOf(resolved);
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(java.util.Locale.ROOT);
    }
}
