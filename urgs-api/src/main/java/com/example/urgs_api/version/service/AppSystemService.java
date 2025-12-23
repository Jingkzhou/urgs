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
public class AppSystemService {

    private final AppSystemRepository repository;

    public List<AppSystem> findAll() {
        return repository.findAll();
    }

    public Optional<AppSystem> findById(Long id) {
        return repository.findById(id);
    }

    public Optional<AppSystem> findByCode(String code) {
        return repository.findByCode(code);
    }

    public List<AppSystem> search(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return findAll();
        }
        return repository.findByNameContaining(keyword);
    }

    @Transactional
    public AppSystem create(AppSystem app) {
        if (repository.existsByCode(app.getCode())) {
            throw new IllegalArgumentException("应用编码已存在: " + app.getCode());
        }
        return repository.save(app);
    }

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

    @Transactional
    public void delete(Long id) {
        repository.deleteById(id);
    }
}
