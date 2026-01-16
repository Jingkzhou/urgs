package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.AppSystem;
import com.example.urgs_api.version.repository.AppSystemRepository;
import com.example.urgs_api.user.service.UserService;
import com.example.urgs_api.user.model.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;
import java.util.Arrays;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
/**
 * 应用系统服务
 * 提供应用系统的增删改查及搜索功能
 */
public class AppSystemService {

    private final AppSystemRepository repository;
    private final UserService userService;

    /**
     * 获取所有应用系统（基础方法，不含权限过滤）
     * 
     * @return 所有应用系统列表
     */
    public List<AppSystem> findAll() {
        return repository.findAll();
    }

    /**
     * 获取用户有权访问的所有应用系统
     * 
     * @param userId 用户 ID
     * @return 应用系统列表
     */
    public List<AppSystem> findAll(Long userId) {
        List<String> allowedNames = getAllowedSystemNames(userId);
        if (allowedNames == null) {
            return repository.findAll();
        }
        return repository.findByNameIn(allowedNames);
    }

    /**
     * 根据 ID 获取应用系统
     * 
     * @param id 系统 ID
     * @return Optional 包装的应用系统对象
     */
    public Optional<AppSystem> findById(Long id) {
        return repository.findById(id);
    }

    /**
     * 根据编码获取应用系统
     * 
     * @param code 系统编码
     * @return Optional 包装的应用系统对象
     */
    public Optional<AppSystem> findByCode(String code) {
        return repository.findByCode(code);
    }

    /**
     * 搜索应用系统（已弃用，建议使用带权限的参数）
     */
    @Deprecated
    public List<AppSystem> search(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return findAll();
        }
        return repository.findByNameContaining(keyword);
    }

    /**
     * 搜索用户有权访问的应用系统
     * 
     * @param userId  用户 ID
     * @param keyword 搜索关键字（匹配名称）
     * @return 匹配的应用系统列表
     */
    public List<AppSystem> search(Long userId, String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return findAll(userId);
        }

        List<String> allowedNames = getAllowedSystemNames(userId);
        List<AppSystem> searchResults = repository.findByNameContaining(keyword);

        if (allowedNames == null) {
            return searchResults;
        }

        return searchResults.stream()
                .filter(app -> allowedNames.contains(app.getName()))
                .collect(Collectors.toList());
    }

    /**
     * 获取用户允许访问的系统名称列表
     */
    private List<String> getAllowedSystemNames(Long userId) {
        if (userId == null) {
            return null;
        }
        User user = userService.getById(userId);
        if (user == null || user.getSystem() == null || user.getSystem().isBlank()
                || "ALL".equalsIgnoreCase(user.getSystem())) {
            return null;
        }
        return Arrays.stream(user.getSystem().split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    /**
     * 创建应用系统
     * 
     * @param app 应用系统实体
     * @return 创建后的应用系统
     * @throws IllegalArgumentException 如果编码已存在
     */
    @Transactional
    public AppSystem create(AppSystem app) {
        if (repository.existsByCode(app.getCode())) {
            throw new IllegalArgumentException("应用编码已存在: " + app.getCode());
        }
        return repository.save(app);
    }

    /**
     * 更新应用系统
     * 
     * @param id  系统 ID
     * @param app 更新的应用系统信息
     * @return 更新后的应用系统
     * @throws IllegalArgumentException 如果系统不存在
     */
    @Transactional
    public AppSystem update(Long id, AppSystem app) {
        AppSystem existing = repository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("应用不存在: " + id));

        existing.setName(app.getName());
        existing.setDescription(app.getDescription());
        existing.setOwnerId(app.getOwnerId());
        existing.setTeam(app.getTeam());
        existing.setStatus(app.getStatus());

        return repository.save(existing);
    }

    /**
     * 删除应用系统
     * 
     * @param id 系统 ID
     */
    @Transactional
    public void delete(Long id) {
        repository.deleteById(id);
    }
}
