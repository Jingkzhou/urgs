package com.example.urgs_api.metadata.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.metadata.model.MaintenanceRecord;
import com.example.urgs_api.metadata.model.ReqSummaryVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
/**
 * 维护记录Mapper接口
 */
public interface MaintenanceRecordMapper extends BaseMapper<MaintenanceRecord> {

    /**
     * 按需求编号分组查询变更汇总
     */
    @Select("SELECT req_id AS reqId, " +
            "MAX(req_name) AS reqName, " +
            "MAX(operator) AS operator, " +
            "MAX(planned_date) AS plannedDate, " +
            "COUNT(*) AS changeCount " +
            "FROM maintenance_record " +
            "WHERE req_id IS NOT NULL AND req_id != '' " +
            "AND time >= #{startDate} AND time <= #{endDate} " +
            "GROUP BY req_id " +
            "ORDER BY MAX(planned_date) DESC")
    List<ReqSummaryVO> selectReqSummary(@Param("startDate") String startDate,
                                         @Param("endDate") String endDate);
}
