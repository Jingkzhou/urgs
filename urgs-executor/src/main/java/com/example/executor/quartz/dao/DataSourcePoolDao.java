package com.example.executor.quartz.dao;

import com.example.executor.quartz.domain.entity.DataSourcePoolMemberEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface DataSourcePoolDao {

    List<DataSourcePoolMemberEntity> listEnabledMembers(@Param("poolId") Long poolId);
}
