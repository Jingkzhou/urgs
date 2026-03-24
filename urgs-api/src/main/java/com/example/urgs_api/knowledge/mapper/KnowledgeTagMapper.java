package com.example.urgs_api.knowledge.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.knowledge.entity.KnowledgeTag;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 知识标签 Mapper 接口
 */
@Mapper
public interface KnowledgeTagMapper extends BaseMapper<KnowledgeTag> {

    /**
     * 查询用户的所有标签
     */
    @Select("SELECT * FROM knowledge_tag WHERE user_id = #{userId} ORDER BY id")
    List<KnowledgeTag> findByUserId(@Param("userId") Long userId);

    /**
     * 根据名称查询标签
     */
    @Select("SELECT * FROM knowledge_tag WHERE user_id = #{userId} AND name = #{name}")
    KnowledgeTag findByUserIdAndName(@Param("userId") Long userId, @Param("name") String name);

    /**
     * 根据文档ID查询关联的标签
     */
    @Select("SELECT t.* FROM knowledge_tag t " +
            "INNER JOIN knowledge_document_tag dt ON t.id = dt.tag_id " +
            "WHERE dt.document_id = #{documentId}")
    List<KnowledgeTag> findByDocumentId(@Param("documentId") Long documentId);

    /**
     * 批量查询多个文档的标签（返回带 document_id 的结果）
     */
    @Select("<script>" +
            "SELECT dt.document_id, t.id, t.user_id, t.name, t.color, t.create_time " +
            "FROM knowledge_tag t " +
            "INNER JOIN knowledge_document_tag dt ON t.id = dt.tag_id " +
            "WHERE dt.document_id IN " +
            "<foreach item='id' collection='documentIds' open='(' separator=',' close=')'>" +
            "#{id}" +
            "</foreach>" +
            "</script>")
    List<Map<String, Object>> findTagsByDocumentIds(@Param("documentIds") List<Long> documentIds);
}
