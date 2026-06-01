package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.ai.entity.AgentAppSkill;
import com.example.urgs_api.ai.repository.AgentAppSkillRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
public class AgentAppSkillService {

    private static final List<DefaultSkill> DEFAULT_SKILLS = List.of(
            new DefaultSkill("plan", "任务规划", "拆解用户请求，给出执行计划和风险点。"),
            new DefaultSkill("code-review", "代码审查", "审查代码变更中的缺陷、回归风险和测试缺口。"),
            new DefaultSkill("debug", "问题排查", "根据报错、日志或现象定位根因并提出修复方案。"),
            new DefaultSkill("implement", "编码实现", "按用户需求直接修改代码并完成必要验证。"));

    @Autowired
    private AgentAppSkillRepository skillRepository;

    public List<AgentAppSkill> listSkills() {
        return skillRepository.selectList(new QueryWrapper<AgentAppSkill>()
                .orderByAsc("app_code")
                .orderByAsc("sort_order")
                .orderByDesc("id"));
    }

    public List<AgentAppSkill> listEnabledSkills(String appCodes) {
        QueryWrapper<AgentAppSkill> wrapper = new QueryWrapper<AgentAppSkill>()
                .eq("status", 1)
                .orderByAsc("app_code")
                .orderByAsc("sort_order")
                .orderByDesc("id");
        List<String> parsedAppCodes = parseAppCodes(appCodes);
        if (!parsedAppCodes.isEmpty()) {
            wrapper.in("app_code", parsedAppCodes);
        }
        return skillRepository.selectList(wrapper);
    }

    public AgentAppSkill getEnabledSkill(String appCode, String code) {
        if (appCode == null || appCode.isBlank() || code == null || code.isBlank()) {
            return null;
        }
        return skillRepository.selectOne(new QueryWrapper<AgentAppSkill>()
                .eq("app_code", appCode.trim().toLowerCase())
                .eq("code", code.trim())
                .eq("status", 1)
                .last("LIMIT 1"));
    }

    public AgentAppSkill saveSkill(AgentAppSkill skill) {
        Date now = new Date();
        skill.setAppCode(normalizeAppCode(skill.getAppCode()));
        if (skill.getStatus() == null) {
            skill.setStatus(1);
        }
        if (skill.getSortOrder() == null) {
            skill.setSortOrder(0);
        }
        skill.setUpdatedAt(now);
        if (skill.getId() == null) {
            skill.setCreatedAt(now);
            skillRepository.insert(skill);
        } else {
            skillRepository.updateById(skill);
        }
        return skill;
    }

    public void deleteSkill(Long id) {
        skillRepository.deleteById(id);
    }

    @Transactional
    public List<AgentAppSkill> syncDefaultSkills(String appCode) {
        String normalizedAppCode = normalizeAppCode(appCode);
        if (normalizedAppCode == null) {
            return List.of();
        }
        if ("hermesagent".equals(normalizedAppCode)) {
            return syncHermesSkills();
        }

        List<AgentAppSkill> created = new ArrayList<>();
        for (int i = 0; i < DEFAULT_SKILLS.size(); i++) {
            DefaultSkill item = DEFAULT_SKILLS.get(i);
            AgentAppSkill skill = upsertSkill(normalizedAppCode, item.code(), item.name(),
                    appDisplayName(normalizedAppCode) + " 技能", item.instruction(), (i + 1) * 10);
            created.add(skill);
        }
        return created;
    }

    private List<AgentAppSkill> syncHermesSkills() {
        List<HermesSkillRow> rows = queryHermesSkills();
        List<AgentAppSkill> synced = new ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            HermesSkillRow row = rows.get(i);
            AgentAppSkill skill = upsertSkill("hermesagent", row.name(), row.name(),
                    buildHermesDescription(row), "使用 Hermes skill: " + row.name(), (i + 1) * 10);
            synced.add(skill);
        }
        return synced;
    }

    private List<HermesSkillRow> queryHermesSkills() {
        String executable = resolveExecutable("hermes");
        if (executable == null) {
            throw new RuntimeException("当前后端环境未安装 hermes 或 hermes 不在 PATH 中");
        }

        try {
            Process process = new ProcessBuilder(executable, "skills", "list", "--enabled-only")
                    .redirectErrorStream(true)
                    .start();
            String output;
            try (InputStreamReader reader = new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8)) {
                StringBuilder builder = new StringBuilder();
                char[] buffer = new char[2048];
                int len;
                while ((len = reader.read(buffer)) != -1) {
                    builder.append(buffer, 0, len);
                }
                output = builder.toString();
            }

            boolean finished = process.waitFor(15, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                throw new RuntimeException("查询 Hermes 技能列表超时");
            }
            if (process.exitValue() != 0) {
                throw new RuntimeException("查询 Hermes 技能列表失败: " + output);
            }

            List<HermesSkillRow> rows = parseHermesSkillRows(output);
            if (rows.isEmpty()) {
                throw new RuntimeException("Hermes 技能列表为空或输出格式无法识别");
            }
            return rows;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("查询 Hermes 技能列表被中断", e);
        } catch (Exception e) {
            if (e instanceof RuntimeException runtimeException) {
                throw runtimeException;
            }
            throw new RuntimeException("查询 Hermes 技能列表失败", e);
        }
    }

    private List<HermesSkillRow> parseHermesSkillRows(String output) {
        List<HermesSkillRow> rows = new ArrayList<>();
        for (String line : output.split("\\R")) {
            String trimmed = line.trim();
            if (!trimmed.startsWith("│") || !trimmed.endsWith("│")) {
                continue;
            }
            String[] columns = trimmed.substring(1, trimmed.length() - 1).split("│");
            if (columns.length < 5) {
                continue;
            }
            String name = columns[0].trim();
            if (name.isEmpty() || "Name".equalsIgnoreCase(name)) {
                continue;
            }
            String category = columns[1].trim();
            String source = columns[2].trim();
            String trust = columns[3].trim();
            String status = columns[4].trim();
            if (!"enabled".equalsIgnoreCase(status)) {
                continue;
            }
            rows.add(new HermesSkillRow(name, category, source, trust));
        }
        return rows;
    }

    private AgentAppSkill upsertSkill(String appCode, String code, String name, String description, String instruction,
            Integer sortOrder) {
        AgentAppSkill skill = skillRepository.selectOne(new QueryWrapper<AgentAppSkill>()
                .eq("app_code", appCode)
                .eq("code", code)
                .last("LIMIT 1"));
        boolean creating = skill == null;
        if (creating) {
            skill = new AgentAppSkill();
            skill.setAppCode(appCode);
            skill.setCode(code);
            skill.setCreatedAt(new Date());
        }
        skill.setName(name);
        skill.setDescription(description);
        skill.setInstruction(instruction);
        skill.setStatus(1);
        skill.setSortOrder(sortOrder);
        skill.setUpdatedAt(new Date());
        if (creating) {
            skillRepository.insert(skill);
        } else {
            skillRepository.updateById(skill);
        }
        return skill;
    }

    private String buildHermesDescription(HermesSkillRow row) {
        List<String> parts = new ArrayList<>();
        if (!row.category().isBlank()) {
            parts.add(row.category());
        }
        if (!row.source().isBlank()) {
            parts.add(row.source());
        }
        if (!row.trust().isBlank()) {
            parts.add(row.trust());
        }
        return parts.isEmpty() ? "Hermes Skill" : String.join(" / ", parts);
    }

    private String resolveExecutable(String executableName) {
        List<String> dirs = new ArrayList<>();
        String path = System.getenv("PATH");
        if (path != null && !path.isBlank()) {
            dirs.addAll(Arrays.asList(path.split(java.io.File.pathSeparator)));
        }
        dirs.add("/opt/homebrew/bin");
        dirs.add("/usr/local/bin");
        dirs.add(System.getProperty("user.home") + "/.local/bin");

        for (String dir : dirs) {
            java.io.File candidate = new java.io.File(dir, executableName);
            if (candidate.isFile() && candidate.canExecute()) {
                return candidate.getAbsolutePath();
            }
        }
        return null;
    }

    private List<String> parseAppCodes(String rawAppCodes) {
        if (rawAppCodes == null || rawAppCodes.isBlank()) {
            return List.of();
        }
        return Arrays.stream(rawAppCodes.split(","))
                .map(this::normalizeAppCode)
                .filter(value -> value != null)
                .distinct()
                .toList();
    }

    private String normalizeAppCode(String appCode) {
        if (appCode == null || appCode.isBlank()) {
            return null;
        }
        String normalized = appCode.trim().toLowerCase();
        if ("hermes".equals(normalized)) {
            return "hermesagent";
        }
        return normalized;
    }

    private String appDisplayName(String appCode) {
        if ("hermesagent".equals(appCode)) {
            return "Hermes Agent";
        }
        if ("opencode".equals(appCode)) {
            return "OpenCode";
        }
        if ("openclaw".equals(appCode)) {
            return "OpenClaw";
        }
        return appCode;
    }

    private record DefaultSkill(String code, String name, String instruction) {
    }

    private record HermesSkillRow(String name, String category, String source, String trust) {
    }
}
