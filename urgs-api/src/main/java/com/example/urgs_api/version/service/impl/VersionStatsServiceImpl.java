package com.example.urgs_api.version.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.version.audit.entity.AiCodeReview;
import com.example.urgs_api.version.audit.mapper.AiCodeReviewMapper;
import com.example.urgs_api.version.dto.DeveloperKpiVO;
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

    private final AiCodeReviewMapper reviewMapper;
    private final UserMapper userMapper;
    private final com.example.urgs_api.version.repository.AppSystemRepository appSystemRepository;
    private final com.example.urgs_api.version.repository.DeploymentRepository deploymentRepository;

    @Override
    public com.example.urgs_api.version.dto.VersionOverviewVO getOverviewStats() {
        com.example.urgs_api.version.dto.VersionOverviewVO vo = new com.example.urgs_api.version.dto.VersionOverviewVO();

        vo.setTotalApps(appSystemRepository.count());
        vo.setTotalReleases(deploymentRepository.count());

        // Mocking some time-based stats for now as Repository methods need update for
        // custom queries
        // In real implementation, add method countByCreatedAtBetween to Repository
        vo.setThisMonthReleases(5L);
        vo.setPendingReleases(deploymentRepository.countByStatus("PENDING")); // Assuming this method exists or we use
                                                                              // count

        long successCount = deploymentRepository.countByStatus("SUCCESS");
        long total = vo.getTotalReleases();
        vo.setSuccessRate(total == 0 ? 0.0 : (double) successCount / total * 100);

        // Mock recent releases for simplicity in this turn, or fetch top 5
        vo.setRecentReleases(new ArrayList<>());

        return vo;
    }

    @Override
    public List<DeveloperKpiVO> getDeveloperKpis(Long systemId) {
        // 1. Get all developers (filtered by system if needed, currently getting all)
        List<User> users = userMapper.selectList(new QueryWrapper<>());

        // 2. Get all reviews
        List<AiCodeReview> reviews = reviewMapper.selectList(new QueryWrapper<>());

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
            List<AiCodeReview> userReviews = reviews.stream()
                    .filter(r -> r.getDeveloperId() != null && r.getDeveloperId().equals(user.getId()))
                    .collect(Collectors.toList());

            vo.setTotalCommits(userReviews.size()); // Approximation: Commits = Reviewed Commits
            vo.setTotalReviews(userReviews.size());

            double avgScore = userReviews.stream()
                    .filter(r -> r.getScore() != null)
                    .mapToInt(AiCodeReview::getScore)
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
