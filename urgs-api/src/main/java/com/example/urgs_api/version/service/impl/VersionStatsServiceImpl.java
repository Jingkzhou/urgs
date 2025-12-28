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

        // 暂时模拟一些基于时间的统计数据，因为 Repository 方法不支持自定义查询
        // 在实际实现中，需要在 Repository 中添加 countByCreatedAtBetween 方法
        vo.setThisMonthReleases(5L);
        vo.setPendingReleases(deploymentRepository.countByStatus("PENDING")); // 假设此方法存在或使用 count

        long successCount = deploymentRepository.countByStatus("SUCCESS");
        long total = vo.getTotalReleases();
        vo.setSuccessRate(total == 0 ? 0.0 : (double) successCount / total * 100);

        // 为了简化，本次模拟最近的发布记录，实际应获取前 5 条
        vo.setRecentReleases(new ArrayList<>());

        return vo;
    }

    @Override
    public List<DeveloperKpiVO> getDeveloperKpis(Long systemId) {
        // 1. 获取所有开发人员（如果需要可以按系统过滤，目前获取所有）
        List<User> users = userMapper.selectList(new QueryWrapper<>());

        // 2. 获取所有评审记录
        List<AiCodeReview> reviews = reviewMapper.selectList(new QueryWrapper<>());

        List<DeveloperKpiVO> kpis = new ArrayList<>();

        for (User user : users) {
            // 基本过滤：只考虑有邮箱的用户
            if (user.getEmail() == null)
                continue;

            vo.setUserId(user.getId());
            vo.setName(user.getName());
            vo.setEmail(user.getEmail());

            // 根据评审记录计算统计数据
            List<AiCodeReview> userReviews = reviews.stream()
                    .filter(r -> r.getDeveloperId() != null && r.getDeveloperId().equals(user.getId()))
                    .collect(Collectors.toList());

            vo.setTotalCommits(userReviews.size()); // 近似值：提交数 = 已评审的提交数
            vo.setTotalReviews(userReviews.size());

            double avgScore = userReviews.stream()
                    .filter(r -> r.getScore() != null)
                    .mapToInt(AiCodeReview::getScore)
                    .average()
                    .orElse(0.0);
            vo.setAverageCodeScore(avgScore);

            vo.setActiveDays(0); // TODO: 根据 createdAt 计算不同天数
            vo.setBugCount(0); // TODO: 集成 Issue 系统？

            kpis.add(vo);
        }

        // 如果需要，过滤掉 0 活动的用户，或者保留以显示 0
        return kpis.stream().filter(k -> k.getTotalCommits() > 0).collect(Collectors.toList());
    }

    @Override
    public Map<String, Object> getQualityTrend(Long userId) {
        Map<String, Object> result = new HashMap<>();
        // 模拟趋势数据
        result.put("dates", List.of("2023-12-01", "2023-12-02", "2023-12-03", "2023-12-04"));
        result.put("scores", List.of(80, 82, 78, 85));
        return result;
    }
}
