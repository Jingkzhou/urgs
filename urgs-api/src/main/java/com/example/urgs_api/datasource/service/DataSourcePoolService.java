package com.example.urgs_api.datasource.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.datasource.dto.DataSourcePoolDTO;
import com.example.urgs_api.datasource.dto.DataSourcePoolMemberDTO;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourcePool;
import com.example.urgs_api.datasource.entity.DataSourcePoolMember;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.datasource.repository.DataSourcePoolMapper;
import com.example.urgs_api.datasource.repository.DataSourcePoolMemberMapper;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class DataSourcePoolService {

    private final DataSourcePoolMapper poolMapper;
    private final DataSourcePoolMemberMapper memberMapper;
    private final DataSourceConfigMapper configMapper;
    private final DataSourceService dataSourceService;

    public DataSourcePoolService(DataSourcePoolMapper poolMapper,
                                 DataSourcePoolMemberMapper memberMapper,
                                 DataSourceConfigMapper configMapper,
                                 DataSourceService dataSourceService) {
        this.poolMapper = poolMapper;
        this.memberMapper = memberMapper;
        this.configMapper = configMapper;
        this.dataSourceService = dataSourceService;
    }

    public List<DataSourcePoolDTO> listPools() {
        List<DataSourcePool> pools = poolMapper.selectList(new LambdaQueryWrapper<DataSourcePool>()
                .orderByDesc(DataSourcePool::getUpdateTime)
                .orderByAsc(DataSourcePool::getId));
        if (pools.isEmpty()) {
            return List.of();
        }
        Map<Long, List<DataSourcePoolMember>> memberMap = memberMapper.selectList(
                        new LambdaQueryWrapper<DataSourcePoolMember>()
                                .in(DataSourcePoolMember::getPoolId, pools.stream().map(DataSourcePool::getId).toList())
                                .orderByAsc(DataSourcePoolMember::getSortNo)
                                .orderByAsc(DataSourcePoolMember::getId))
                .stream()
                .collect(Collectors.groupingBy(DataSourcePoolMember::getPoolId));
        Map<Long, DataSourceConfig> configMap = dataSourceService.getAllConfigs().stream()
                .collect(Collectors.toMap(DataSourceConfig::getId, config -> config, (left, right) -> left));

        return pools.stream()
                .map(pool -> toDTO(pool, memberMap.getOrDefault(pool.getId(), List.of()), configMap))
                .toList();
    }

    public DataSourcePoolDTO getPool(Long id) {
        DataSourcePool pool = poolMapper.selectById(id);
        if (pool == null) {
            return null;
        }
        List<DataSourcePoolMember> members = memberMapper.selectList(new LambdaQueryWrapper<DataSourcePoolMember>()
                .eq(DataSourcePoolMember::getPoolId, id)
                .orderByAsc(DataSourcePoolMember::getSortNo)
                .orderByAsc(DataSourcePoolMember::getId));
        Map<Long, DataSourceConfig> configMap = dataSourceService.getAllConfigs().stream()
                .collect(Collectors.toMap(DataSourceConfig::getId, config -> config, (left, right) -> left));
        return toDTO(pool, members, configMap);
    }

    @Transactional(rollbackFor = Throwable.class)
    public boolean savePool(DataSourcePoolDTO dto) {
        validatePool(dto);
        DataSourcePool pool = new DataSourcePool();
        BeanUtils.copyProperties(dto, pool);
        if (pool.getStatus() == null) {
            pool.setStatus(1);
        }
        if (pool.getPoolType() == null || pool.getPoolType().isBlank()) {
            pool.setPoolType("MIXED");
        }
        if (pool.getStrategy() == null || pool.getStrategy().isBlank()) {
            pool.setStrategy("LEAST_RUNNING");
        }

        if (pool.getId() == null) {
            poolMapper.insert(pool);
        } else {
            poolMapper.updateById(pool);
            memberMapper.delete(new LambdaQueryWrapper<DataSourcePoolMember>()
                    .eq(DataSourcePoolMember::getPoolId, pool.getId()));
        }
        saveMembers(pool.getId(), dto.getMembers());
        return true;
    }

    @Transactional(rollbackFor = Throwable.class)
    public boolean deletePool(Long id) {
        memberMapper.delete(new LambdaQueryWrapper<DataSourcePoolMember>()
                .eq(DataSourcePoolMember::getPoolId, id));
        return poolMapper.deleteById(id) > 0;
    }

    private void saveMembers(Long poolId, List<DataSourcePoolMemberDTO> members) {
        int index = 0;
        for (DataSourcePoolMemberDTO memberDTO : members) {
            DataSourcePoolMember member = new DataSourcePoolMember();
            member.setPoolId(poolId);
            member.setDatasourceId(memberDTO.getDatasourceId());
            member.setEnabled(memberDTO.getEnabled() == null ? 1 : memberDTO.getEnabled());
            member.setWeight(memberDTO.getWeight() == null || memberDTO.getWeight() <= 0 ? 1 : memberDTO.getWeight());
            member.setMaxConcurrency(memberDTO.getMaxConcurrency());
            member.setSortNo(memberDTO.getSortNo() == null ? index : memberDTO.getSortNo());
            member.setRemark(memberDTO.getRemark());
            memberMapper.insert(member);
            index += 1;
        }
    }

    private void validatePool(DataSourcePoolDTO dto) {
        if (dto == null || dto.getName() == null || dto.getName().isBlank()) {
            throw new IllegalArgumentException("数据池名称不能为空");
        }
        List<DataSourcePoolMemberDTO> members = dto.getMembers() == null ? List.of() : dto.getMembers();
        if (members.stream().anyMatch(member -> member.getDatasourceId() == null)) {
            throw new IllegalArgumentException("数据池成员数据源不能为空");
        }
        List<Long> datasourceIds = members.stream()
                .map(DataSourcePoolMemberDTO::getDatasourceId)
                .distinct()
                .toList();
        if (datasourceIds.isEmpty()) {
            throw new IllegalArgumentException("数据池至少需要选择一个数据源");
        }
        if (datasourceIds.size() != members.stream().map(DataSourcePoolMemberDTO::getDatasourceId).filter(Objects::nonNull).count()) {
            throw new IllegalArgumentException("数据池中不能重复选择同一个数据源");
        }
        long existingCount = configMapper.selectBatchIds(datasourceIds).size();
        if (existingCount != datasourceIds.size()) {
            throw new IllegalArgumentException("数据池包含不存在的数据源");
        }
    }

    private DataSourcePoolDTO toDTO(DataSourcePool pool,
                                    List<DataSourcePoolMember> members,
                                    Map<Long, DataSourceConfig> configMap) {
        DataSourcePoolDTO dto = new DataSourcePoolDTO();
        BeanUtils.copyProperties(pool, dto);
        List<DataSourcePoolMemberDTO> memberDTOList = new ArrayList<>();
        for (DataSourcePoolMember member : members.stream()
                .sorted(Comparator.comparing(DataSourcePoolMember::getSortNo, Comparator.nullsLast(Integer::compareTo))
                        .thenComparing(DataSourcePoolMember::getId, Comparator.nullsLast(Long::compareTo)))
                .toList()) {
            DataSourcePoolMemberDTO memberDTO = new DataSourcePoolMemberDTO();
            BeanUtils.copyProperties(member, memberDTO);
            DataSourceConfig config = configMap.get(member.getDatasourceId());
            if (config != null) {
                memberDTO.setDatasourceName(config.getName());
                memberDTO.setTypeName(config.getTypeName());
                memberDTO.setTypeCode(config.getTypeCode());
                memberDTO.setCategory(config.getCategory());
            }
            memberDTOList.add(memberDTO);
        }
        dto.setMembers(memberDTOList);
        dto.setMemberCount(memberDTOList.size());
        dto.setEnabledMemberCount((int) memberDTOList.stream()
                .filter(member -> member.getEnabled() == null || member.getEnabled() == 1)
                .count());
        return dto;
    }
}
