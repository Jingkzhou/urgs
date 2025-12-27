package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.AppSystem;
import com.example.urgs_api.version.repository.AppSystemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
/**
 * 应用系统服务
 * 提供应用系统的增删改查及搜索功能
 */
public class AppSystemService {

    private final AppSystemRepository repository;

    /**
     * 获取所有应用系统
     * 
     * @return 应用系统列表
     */
    public List<AppSystem> findAll() {
        return repository.findAll();
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
     * 搜索应用系统
     * 
     * @param keyword 搜索关键字（匹配名称）
     * @return 匹配的应用系统列表
     */
    public List<AppSystem> search(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return findAll();
        }
        return repository.findByNameContaining(keyword);
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
