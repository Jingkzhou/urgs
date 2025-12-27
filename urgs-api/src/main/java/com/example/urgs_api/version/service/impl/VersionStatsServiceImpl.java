package com.example.urgs_api.version.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.version.dto.DeveloperKpiVO;
import com.example.urgs_api.version.entity.AICodeReview;
import com.example.urgs_api.version.repository.AICodeReviewRepository;
import com.example.urgs_api.version.service.VersionStatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class VersionStatsServiceImpl implements VersionStatsService {

    private final AICodeReviewRepository reviewRepository;
    private final UserMapper userMapper;

    @Override
    public List<DeveloperKpiVO> getDeveloperKpis(Long systemId) {
        // 1. Get all developers (filtered by system if needed, currently getting all)
        List<User> users = userMapper.selectList(new QueryWrapper<>());

        // 2. Get all reviews
        List<AICodeReview> reviews = reviewRepository.findAll();

        List<DeveloperKpiVO> kpis = new ArrayList<>();

        for (User user : users) {
            // Basic filter: only consider users with email or gitlab username
            if (user.getEmail() == null && user.getGitlabUsername() == null)
                continue;

            DeveloperKpiVO vo = new DeveloperKpiVO();
            vo.setUserId(user.getId());
            vo.setName(user.getName());
            vo.setEmail(user.getEmail());
            vo.setGitlabUsername(user.getGitlabUsername());

            // Calculate stats from reviews
            List<AICodeReview> userReviews = reviews.stream()
                    .filter(r -> r.getDeveloperId() != null && r.getDeveloperId().equals(user.getId()))
                    .collect(Collectors.toList());

            vo.setTotalCommits(userReviews.size()); // Approximation: Commits = Reviewed Commits
            vo.setTotalReviews(userReviews.size());

            double avgScore = userReviews.stream()
                    .filter(r -> r.getScore() != null)
                    .mapToInt(AICodeReview::getScore)
                    .average()
                    .orElse(0.0);
            vo.setAverageCodeScore(avgScore);

            vo.setActiveDays(0); // TODO: Calculate distinct days from createdAt
            vo.setBugCount(0); // TODO: Integrate with Issue system?

            kpis.add(vo);
        }

        // Filter out users with 0 activity if desired, or keep to show 0s
        return kpis.stream().filter(k -> k.getTotalCommits() > 0).collect(Collectors.toList());
    }

    @Override
    public Map<String, Object> getQualityTrend(Long userId) {
        Map<String, Object> result = new HashMap<>();
        // Mock data for trend
        result.put("dates", List.of("2023-12-01", "2023-12-02", "2023-12-03", "2023-12-04"));
        result.put("scores", List.of(80, 82, 78, 85));
        return result;
    }
}
