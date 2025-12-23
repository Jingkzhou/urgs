package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.ReleaseStrategy;
import com.example.urgs_api.version.repository.ReleaseStrategyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/version/strategies")
@RequiredArgsConstructor
public class ReleaseStrategyController {

    private final ReleaseStrategyRepository strategyRepository;

    @GetMapping
    public List<ReleaseStrategy> list() {
        return strategyRepository.findAllByOrderByIdAsc();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ReleaseStrategy> getById(@PathVariable Long id) {
        return strategyRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ReleaseStrategy create(@RequestBody ReleaseStrategy strategy) {
        return strategyRepository.save(strategy);
    }

    @PutMapping("/{id}")
    public ReleaseStrategy update(@PathVariable Long id, @RequestBody ReleaseStrategy strategy) {
        ReleaseStrategy existing = strategyRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("策略不存在: " + id));

        existing.setName(strategy.getName());
        existing.setType(strategy.getType());
        existing.setTrafficPercent(strategy.getTrafficPercent());
        existing.setConfig(strategy.getConfig());
        existing.setDescription(strategy.getDescription());

        return strategyRepository.save(existing);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        strategyRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
