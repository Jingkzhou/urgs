package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class AgentExecutionContextService {

    private final UserService userService;

    public AgentExecutionContextService(UserService userService) {
        this.userService = userService;
    }

    public Map<String, Object> build(Long requesterUserId) {
        Set<String> permissions = requesterUserId == null
                ? Set.of()
                : userService.getUserPermissions(requesterUserId);
        User user = requesterUserId == null ? null : userService.getById(requesterUserId);
        List<String> allowedSystems = new ArrayList<>();
        List<String> allowedOrganizations = new ArrayList<>();
        if (user != null) {
            String systems = user.getSystem();
            if (systems == null || systems.isBlank() || "ALL".equalsIgnoreCase(systems.trim())) {
                allowedSystems.add("ALL");
            } else {
                Arrays.stream(systems.split(","))
                        .map(String::trim)
                        .filter(value -> !value.isEmpty())
                        .forEach(allowedSystems::add);
            }
            if (user.getOrgName() != null && !user.getOrgName().isBlank()) {
                allowedOrganizations.add(user.getOrgName().trim());
            }
        }
        Map<String, Object> context = new LinkedHashMap<>();
        context.put("requester_user_id", requesterUserId);
        context.put("permissions", permissions);
        context.put("allowed_systems", allowedSystems);
        context.put("allowed_organizations", allowedOrganizations);
        return context;
    }
}
