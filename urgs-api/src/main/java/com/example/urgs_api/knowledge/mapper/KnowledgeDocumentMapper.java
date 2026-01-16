package com.example.urgs_api.knowledge.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.knowledge.entity.KnowledgeDocument;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.util.List;

/**
 * 知识文档 Mapper 接口
 */
@Mapper
public interface KnowledgeDocumentMapper extends BaseMapper<KnowledgeDocument> {

    /**
     * 查询文档关联的标签ID列表
     */
    @Select("SELECT tag_id FROM knowledge_document_tag WHERE document_id = #{documentId}")
    List<Long> findTagIdsByDocumentId(@Param("documentId") Long documentId);

    /**
     * 添加文档标签关联
     */
    @Insert("INSERT INTO knowledge_document_tag (document_id, tag_id) VALUES (#{documentId}, #{tagId})")
    void addDocumentTag(@Param("documentId") Long documentId, @Param("tagId") Long tagId);

    /**
     * 删除文档的所有标签关联
     */
    @Delete("DELETE FROM knowledge_document_tag WHERE document_id = #{documentId}")
    void deleteDocumentTags(@Param("documentId") Long documentId);

    /**
     * 删除标签的所有文档关联
     */
    @Delete("DELETE FROM knowledge_document_tag WHERE tag_id = #{tagId}")
    void deleteTagDocuments(@Param("tagId") Long tagId);

    /**
     * 增加查看次数
     */
    @Update("UPDATE knowledge_document SET view_count = view_count + 1 WHERE id = #{id}")
    void incrementViewCount(@Param("id") Long id);

    /**
     * 按标签查询文档ID
     */
    @Select("SELECT document_id FROM knowledge_document_tag WHERE tag_id = #{tagId}")
    List<Long> findDocumentIdsByTagId(@Param("tagId") Long tagId);
}
