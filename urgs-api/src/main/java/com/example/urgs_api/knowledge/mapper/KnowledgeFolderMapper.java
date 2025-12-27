package com.example.urgs_api.knowledge.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.knowledge.entity.KnowledgeFolder;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 知识文件夹 Mapper 接口
 */
@Mapper
public interface KnowledgeFolderMapper extends BaseMapper<KnowledgeFolder> {

    /**
     * 查询用户的所有文件夹
     */
    @Select("SELECT * FROM knowledge_folder WHERE user_id = #{userId} ORDER BY sort_order, id")
    List<KnowledgeFolder> findByUserId(@Param("userId") Long userId);

    /**
     * 查询子文件夹
     */
    @Select("SELECT * FROM knowledge_folder WHERE parent_id = #{parentId} ORDER BY sort_order, id")
    List<KnowledgeFolder> findByParentId(@Param("parentId") Long parentId);
}
