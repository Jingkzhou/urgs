package com.example.executor.quartz.service;

import com.example.executor.datasource.DataSourceConfigClient;
import com.example.executor.datasource.ResolvedDataSourceConfig;
import com.example.executor.quartz.dao.DataSourcePoolDao;
import com.example.executor.quartz.domain.entity.DataSourcePoolMemberEntity;
import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

@Service
public class TaskDataSourceSelector {

    private static final String STRATEGY_ROUND_ROBIN = "ROUND_ROBIN";
    private static final String STRATEGY_WEIGHTED_ROUND_ROBIN = "WEIGHTED_ROUND_ROBIN";

    private final DataSourcePoolDao dataSourcePoolDao;
    private final DataSourceConfigClient dataSourceConfigClient;
    private final Map<Long, AtomicInteger> poolCounters = new ConcurrentHashMap<>();
    private final Map<Long, AtomicInteger> reservedDatasourceCounts = new ConcurrentHashMap<>();

    public TaskDataSourceSelector(DataSourcePoolDao dataSourcePoolDao,
                                  DataSourceConfigClient dataSourceConfigClient) {
        this.dataSourcePoolDao = dataSourcePoolDao;
        this.dataSourceConfigClient = dataSourceConfigClient;
    }

    public TaskDataSourceSelection select(QuartzTaskEntity task) {
        if (task.getDatasourcePoolId() != null) {
            List<DataSourcePoolMemberEntity> members = dataSourcePoolDao.listEnabledMembers(task.getDatasourcePoolId());
            if (members.isEmpty()) {
                throw new IllegalStateException("数据池无可用数据源: " + task.getDatasourcePoolId());
            }
            DataSourcePoolMemberEntity member = reserveMember(members);
            if (member == null) {
                return null;
            }
            try {
                return buildSelection(member, dataSourceConfigClient.getResolvedConfig(member.getDatasourceId()));
            } catch (RuntimeException e) {
                release(member.getDatasourceId());
                throw e;
            }
        }
        if (task.getDatasourceId() == null) {
            return null;
        }
        ResolvedDataSourceConfig config = dataSourceConfigClient.getResolvedConfig(task.getDatasourceId());
        TaskDataSourceSelection selection = new TaskDataSourceSelection();
        selection.setDatasourceId(config == null ? task.getDatasourceId() : config.getId());
        selection.setDatasourceName(config == null ? task.getDatasourceName() : config.getName());
        selection.setConfig(config);
        return selection;
    }

    public boolean hasAvailablePoolMember(Long poolId) {
        return poolId != null && dataSourcePoolDao.listEnabledMembers(poolId).stream().anyMatch(this::hasCapacity);
    }

    public void release(TaskDataSourceSelection selection) {
        if (selection != null && selection.getPoolId() != null) {
            release(selection.getDatasourceId());
        }
    }

    private synchronized DataSourcePoolMemberEntity reserveMember(List<DataSourcePoolMemberEntity> members) {
        List<DataSourcePoolMemberEntity> availableMembers = members.stream()
                .filter(this::hasCapacity)
                .toList();
        if (availableMembers.isEmpty()) {
            return null;
        }
        DataSourcePoolMemberEntity member = chooseMember(availableMembers);
        reservedDatasourceCounts
                .computeIfAbsent(member.getDatasourceId(), ignored -> new AtomicInteger())
                .incrementAndGet();
        return member;
    }

    private boolean hasCapacity(DataSourcePoolMemberEntity member) {
        return member.getMaxConcurrency() == null
                || member.getMaxConcurrency() <= 0
                || runningWithReservation(member) < member.getMaxConcurrency();
    }

    private DataSourcePoolMemberEntity chooseMember(List<DataSourcePoolMemberEntity> members) {
        String strategy = members.get(0).getStrategy();
        if (STRATEGY_ROUND_ROBIN.equals(strategy)) {
            return chooseRoundRobin(members);
        }
        if (STRATEGY_WEIGHTED_ROUND_ROBIN.equals(strategy)) {
            return chooseWeightedRoundRobin(members);
        }
        return members.stream()
                .min(Comparator.comparingInt(this::runningWithReservation)
                        .thenComparing((left, right) -> Integer.compare(nullToOne(right.getWeight()), nullToOne(left.getWeight())))
                        .thenComparingInt(member -> nullToZero(member.getSortNo()))
                        .thenComparing(DataSourcePoolMemberEntity::getDatasourceId))
                .orElse(members.get(0));
    }

    private void release(Long datasourceId) {
        if (datasourceId == null) {
            return;
        }
        reservedDatasourceCounts.computeIfPresent(datasourceId, (ignored, counter) -> {
            int remaining = counter.updateAndGet(value -> Math.max(0, value - 1));
            return remaining == 0 ? null : counter;
        });
    }

    private int runningWithReservation(DataSourcePoolMemberEntity member) {
        return nullToZero(member.getRunningCount()) + reservedCount(member.getDatasourceId());
    }

    private int reservedCount(Long datasourceId) {
        AtomicInteger counter = reservedDatasourceCounts.get(datasourceId);
        return counter == null ? 0 : counter.get();
    }

    private DataSourcePoolMemberEntity chooseRoundRobin(List<DataSourcePoolMemberEntity> members) {
        List<DataSourcePoolMemberEntity> sorted = members.stream()
                .sorted(Comparator.comparingInt((DataSourcePoolMemberEntity member) -> nullToZero(member.getSortNo()))
                        .thenComparing(DataSourcePoolMemberEntity::getDatasourceId))
                .toList();
        int index = nextIndex(sorted.get(0).getPoolId());
        return sorted.get(Math.floorMod(index, sorted.size()));
    }

    private DataSourcePoolMemberEntity chooseWeightedRoundRobin(List<DataSourcePoolMemberEntity> members) {
        List<DataSourcePoolMemberEntity> sorted = members.stream()
                .sorted(Comparator.comparingInt((DataSourcePoolMemberEntity member) -> nullToZero(member.getSortNo()))
                        .thenComparing(DataSourcePoolMemberEntity::getDatasourceId))
                .toList();
        int totalWeight = sorted.stream().mapToInt(member -> Math.max(1, nullToOne(member.getWeight()))).sum();
        int index = Math.floorMod(nextIndex(sorted.get(0).getPoolId()), totalWeight);
        int cursor = 0;
        for (DataSourcePoolMemberEntity member : sorted) {
            cursor += Math.max(1, nullToOne(member.getWeight()));
            if (index < cursor) {
                return member;
            }
        }
        return sorted.get(0);
    }

    private int nextIndex(Long poolId) {
        return poolCounters.computeIfAbsent(poolId, ignored -> new AtomicInteger()).getAndIncrement();
    }

    private TaskDataSourceSelection buildSelection(DataSourcePoolMemberEntity member, ResolvedDataSourceConfig config) {
        TaskDataSourceSelection selection = new TaskDataSourceSelection();
        selection.setPoolId(member.getPoolId());
        selection.setPoolName(member.getPoolName());
        selection.setDatasourceId(config == null ? member.getDatasourceId() : config.getId());
        selection.setDatasourceName(config == null ? member.getDatasourceName() : config.getName());
        selection.setConfig(config);
        return selection;
    }

    private int nullToZero(Integer value) {
        return value == null ? 0 : value;
    }

    private int nullToOne(Integer value) {
        return value == null ? 1 : value;
    }
}
