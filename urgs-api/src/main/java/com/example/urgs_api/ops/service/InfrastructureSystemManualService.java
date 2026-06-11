package com.example.urgs_api.ops.service;

import com.example.urgs_api.ops.entity.InfrastructureSystemManual;
import com.example.urgs_api.ops.repository.InfrastructureSystemManualRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class InfrastructureSystemManualService {

    private final InfrastructureSystemManualRepository repository;

    public List<InfrastructureSystemManual> findByFilter(Long appSystemId, String keyword) {
        List<InfrastructureSystemManual> manuals = appSystemId == null
                ? repository.findAll()
                : repository.findByAppSystemIdOrderByCreatedAtDesc(appSystemId);

        String normalizedKeyword = keyword == null ? "" : keyword.trim().toLowerCase(Locale.ROOT);
        return manuals.stream()
                .filter(manual -> !StringUtils.hasText(normalizedKeyword) || matchesKeyword(manual, normalizedKeyword))
                .sorted(Comparator.comparing(InfrastructureSystemManual::getCreatedAt,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();
    }

    public InfrastructureSystemManual save(InfrastructureSystemManual manual) {
        return repository.save(manual);
    }

    public void delete(Long id) {
        repository.deleteById(id);
    }

    private boolean matchesKeyword(InfrastructureSystemManual manual, String keyword) {
        return contains(manual.getTitle(), keyword)
                || contains(manual.getFileName(), keyword)
                || contains(manual.getDescription(), keyword);
    }

    private boolean contains(String value, String keyword) {
        return value != null && value.toLowerCase(Locale.ROOT).contains(keyword);
    }
}
