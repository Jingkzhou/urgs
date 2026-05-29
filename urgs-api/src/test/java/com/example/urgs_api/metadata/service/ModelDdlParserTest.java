package com.example.urgs_api.metadata.service;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

class ModelDdlParserTest {

    private final ModelDdlParser parser = new ModelDdlParser();

    @Test
    void parsesInceptorCreateTableWithCommentsAndPartitions() {
        String ddl = """
                CREATE TABLE IF NOT EXISTS pm_rsdata.t_customer (
                  id bigint NOT NULL COMMENT '主键',
                  name string COMMENT '客户名称',
                  amount decimal(18,2) COMMENT '金额',
                  tags array<string> COMMENT '标签',
                  CONSTRAINT pk_customer PRIMARY KEY (id)
                )
                COMMENT '客户表'
                PARTITIONED BY (data_dt string COMMENT '数据日期');
                """;

        List<ModelDdlParser.DdlTable> tables = parser.parse(ddl, null, "Inceptor SQL");

        assertEquals(1, tables.size());
        ModelDdlParser.DdlTable table = tables.get(0);
        assertEquals("pm_rsdata", table.getOwner());
        assertEquals("t_customer", table.getName());
        assertEquals("客户表", table.getComment());
        assertEquals(5, table.getFields().size());
        assertEquals("id", table.getFields().get(0).getName());
        assertEquals("bigint", table.getFields().get(0).getType());
        assertEquals("主键", table.getFields().get(0).getComment());
        assertEquals(true, table.getFields().get(0).isPrimaryKey());
        assertEquals(false, table.getFields().get(0).isNullable());
        assertEquals("decimal(18,2)", table.getFields().get(2).getType());
        assertEquals("array<string>", table.getFields().get(3).getType());
        assertEquals("data_dt", table.getFields().get(4).getName());
        assertEquals(true, table.getFields().get(4).isPartitionField());
    }
}
