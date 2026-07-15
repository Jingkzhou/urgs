package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.core.MybatisConfiguration;
import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.baomidou.mybatisplus.core.metadata.TableInfoHelper;
import com.example.urgs_api.metadata.dto.PhysicalTableBindingDTO;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.CodeValueCheck;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.DevelopmentContextRequest;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.SqlValidationRequest;
import com.example.urgs_api.metadata.mapper.RegTableModelTableRelMapper;
import com.example.urgs_api.metadata.model.CodeDirectory;
import com.example.urgs_api.metadata.model.ModelField;
import com.example.urgs_api.metadata.model.ModelTable;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.metadata.model.RegTableModelTableRel;
import org.apache.ibatis.builder.MapperBuilderAssistant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RegulatoryMarketContextServiceTest {

    @Mock
    private RegTableService regTableService;
    @Mock
    private RegElementService regElementService;
    @Mock
    private CodeTableService codeTableService;
    @Mock
    private CodeDirectoryService codeDirectoryService;
    @Mock
    private ModelTableService modelTableService;
    @Mock
    private ModelFieldService modelFieldService;
    @Mock
    private RegTableModelTableRelMapper tableRelMapper;
    private RegPhysicalBindingService regPhysicalBindingService;

    private RegulatoryMarketContextService service;

    @BeforeEach
    void setUp() {
        regPhysicalBindingService = new RegPhysicalBindingService(null, null, null, null) {
            @Override
            public void enrichTables(List<RegTable> tables) {
                if (tables == null || tables.isEmpty()) {
                    return;
                }
                bindPhysicalTable(tables.get(0));
            }

            @Override
            public void enrichTable(RegTable table) {
                bindPhysicalTable(table);
            }

            @Override
            public void enrichElements(List<RegElement> elements) {
                elements.forEach(element -> element.setPhysicalFields(List.of()));
            }

            private void bindPhysicalTable(RegTable table) {
                PhysicalTableBindingDTO binding = new PhysicalTableBindingDTO();
                binding.setModelTableId("model-table-1");
                binding.setOwner("CORE");
                binding.setTableName("LOAN_FACT");
                table.setPhysicalTables(List.of(binding));
            }
        };
        service = new RegulatoryMarketContextService(
                regTableService,
                regElementService,
                codeTableService,
                codeDirectoryService,
                modelTableService,
                modelFieldService,
                tableRelMapper,
                regPhysicalBindingService);
    }

    private void stubPhysicalCatalog() {
        RegTable table = new RegTable();
        table.setId(1L);
        table.setName("LOAN_SUMMARY");
        table.setSystemCode("1104");
        table.setStatus(1);
        when(regTableService.listByIds(List.of(1L))).thenReturn(List.of(table));
        ModelField amount = field("AMOUNT");
        ModelField classCode = field("CLASS_CODE");
        ModelTable modelTable = new ModelTable();
        modelTable.setId("model-table-1");
        modelTable.setOwner("CORE");
        modelTable.setName("LOAN_FACT");
        when(modelTableService.list(org.mockito.ArgumentMatchers.<Wrapper<ModelTable>>any()))
                .thenReturn(List.of(modelTable));
        RegTableModelTableRel relation = new RegTableModelTableRel();
        relation.setRegTableId(1L);
        relation.setModelTableId("model-table-1");
        when(tableRelMapper.selectList(
                org.mockito.ArgumentMatchers.<Wrapper<RegTableModelTableRel>>any()))
                .thenReturn(List.of(relation));
        when(modelFieldService.list(org.mockito.ArgumentMatchers.<Wrapper<ModelField>>any()))
                .thenReturn(List.of(amount, classCode));
    }

    @Test
    void validatesBoundTablesAndQualifiedColumnsWithoutExecutingSql() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "SELECT t.AMOUNT FROM CORE.LOAN_FACT t WHERE t.CLASS_CODE = '3'",
                List.of(),
                "1104"));

        assertTrue(result.valid());
        assertTrue(result.referencedTables().stream().anyMatch(name -> name.contains("LOAN_FACT")));
        assertTrue(result.checkedColumns().contains("t.AMOUNT"));
        assertTrue(result.checkedColumns().contains("t.CLASS_CODE"));
    }

    @Test
    void rejectsUnknownColumnsAndMutatingStatements() {
        stubPhysicalCatalog();
        var unknownColumn = service.validateSql(new SqlValidationRequest(
                "SELECT t.NOT_EXISTS FROM CORE.LOAN_FACT t",
                List.of(),
                "1104"));
        var delete = service.validateSql(new SqlValidationRequest(
                "DELETE FROM CORE.LOAN_FACT WHERE AMOUNT = 0",
                List.of(),
                "1104"));

        assertFalse(unknownColumn.valid());
        assertTrue(unknownColumn.errors().stream().anyMatch(error -> error.contains("NOT_EXISTS")));
        assertFalse(delete.valid());
        assertTrue(delete.errors().stream().anyMatch(error -> error.contains("只允许")));
    }

    @Test
    void validatesUnqualifiedColumnsAgainstSingleBoundSourceTable() {
        stubPhysicalCatalog();
        var knownColumn = service.validateSql(new SqlValidationRequest(
                "SELECT AMOUNT FROM CORE.LOAN_FACT",
                List.of(),
                "1104"));
        var unknownColumn = service.validateSql(new SqlValidationRequest(
                "SELECT NOT_EXISTS FROM CORE.LOAN_FACT",
                List.of(),
                "1104"));

        assertTrue(knownColumn.valid());
        assertTrue(knownColumn.checkedColumns().contains("AMOUNT"));
        assertFalse(unknownColumn.valid());
        assertTrue(unknownColumn.errors().stream().anyMatch(error -> error.contains("NOT_EXISTS")));
    }

    @Test
    void validatesCteAgainstItsPhysicalSourceWithoutTreatingCteAsTable() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "WITH base AS (SELECT t.AMOUNT FROM CORE.LOAN_FACT t) "
                        + "SELECT base.AMOUNT FROM base",
                List.of(),
                "1104"));

        assertTrue(result.valid());
        assertTrue(result.referencedTables().stream().anyMatch(name -> name.contains("LOAN_FACT")));
        assertTrue(result.referencedTables().stream().noneMatch("base"::equalsIgnoreCase));
    }

    @Test
    void rejectsUnknownCteOutputColumns() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "WITH base AS (SELECT t.AMOUNT FROM CORE.LOAN_FACT t) "
                        + "SELECT base.NOT_EXISTS FROM base",
                List.of(),
                "1104"));

        assertFalse(result.valid());
        assertTrue(result.errors().stream()
                .anyMatch(error -> error.contains("派生表 BASE") && error.contains("NOT_EXISTS")));
    }

    @Test
    void rejectsUnqualifiedColumnsMissingFromCteOutput() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "WITH base AS (SELECT t.AMOUNT FROM CORE.LOAN_FACT t) "
                        + "SELECT CLASS_CODE FROM base",
                List.of(),
                "1104"));

        assertFalse(result.valid());
        assertTrue(result.errors().stream()
                .anyMatch(error -> error.contains("派生表 BASE") && error.contains("CLASS_CODE")));
    }

    @Test
    void validatesInlineDerivedTableOutputColumns() {
        stubPhysicalCatalog();
        var valid = service.validateSql(new SqlValidationRequest(
                "SELECT d.AMOUNT FROM (SELECT t.AMOUNT FROM CORE.LOAN_FACT t) d",
                List.of(),
                "1104"));
        var invalid = service.validateSql(new SqlValidationRequest(
                "SELECT d.NOT_EXISTS FROM (SELECT t.AMOUNT FROM CORE.LOAN_FACT t) d",
                List.of(),
                "1104"));

        assertTrue(valid.valid());
        assertFalse(invalid.valid());
        assertTrue(invalid.errors().stream()
                .anyMatch(error -> error.contains("派生表 D") && error.contains("NOT_EXISTS")));
    }

    @Test
    void rejectsUnknownTableAliases() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "SELECT x.NOT_EXISTS FROM CORE.LOAN_FACT t",
                List.of(),
                "1104"));

        assertFalse(result.valid());
        assertTrue(result.errors().stream()
                .anyMatch(error -> error.contains("无法解析的物理表或别名") && error.contains("X")));
    }

    @Test
    void rejectsAmbiguousUnqualifiedColumnsInSelfJoin() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "SELECT AMOUNT FROM CORE.LOAN_FACT a "
                        + "JOIN CORE.LOAN_FACT b ON a.AMOUNT = b.AMOUNT",
                List.of(),
                "1104"));

        assertFalse(result.valid());
        assertTrue(result.errors().stream()
                .anyMatch(error -> error.contains("未限定字段 AMOUNT 的来源表")));
    }

    @Test
    void validatesInsertSelectSourcesWithoutRequiringTargetBinding() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "INSERT INTO INDICATOR_RESULT (AMOUNT) SELECT t.AMOUNT FROM CORE.LOAN_FACT t",
                List.of(),
                "1104"));

        assertTrue(result.valid());
        assertFalse(result.referencedTables().contains("INDICATOR_RESULT"));
        assertTrue(result.referencedTables().stream().anyMatch(name -> name.contains("LOAN_FACT")));
        assertTrue(result.warnings().stream().anyMatch(warning -> warning.contains("目标表写入权限")));
    }

    @Test
    void rejectsInsertValues() {
        var result = service.validateSql(new SqlValidationRequest(
                "INSERT INTO CORE.LOAN_FACT (AMOUNT) VALUES (1)",
                List.of(),
                "1104"));

        assertFalse(result.valid());
        assertTrue(result.errors().stream().anyMatch(error -> error.contains("INSERT SELECT")));
    }

    @Test
    void keepsSameNamedTablesInDifferentOwnersSeparate() {
        stubDuplicateTableNames();
        var result = service.validateSql(new SqlValidationRequest(
                "SELECT c.ARCHIVE_ONLY FROM CORE.LOAN_FACT c "
                        + "JOIN ARCHIVE.LOAN_FACT a ON c.AMOUNT = a.ARCHIVE_ONLY",
                List.of(),
                "1104"));

        assertFalse(result.valid());
        assertTrue(result.errors().stream()
                .anyMatch(error -> error.contains("CORE.LOAN_FACT") && error.contains("ARCHIVE_ONLY")));
    }

    @Test
    void validatesSpecificCodeWithoutDependingOnListingPageSize() {
        stubPhysicalCatalog();
        MapperBuilderAssistant assistant = new MapperBuilderAssistant(new MybatisConfiguration(), "");
        assistant.setCurrentNamespace("regulatory-market-context-test");
        TableInfoHelper.initTableInfo(assistant, CodeDirectory.class);
        when(codeDirectoryService.count(
                org.mockito.ArgumentMatchers.<Wrapper<CodeDirectory>>any())).thenAnswer(invocation -> {
                    Wrapper<CodeDirectory> query = invocation.getArgument(0);
                    String sqlSegment = query.getSqlSegment().toLowerCase();
                    assertTrue(sqlSegment.contains("start_date"));
                    assertTrue(sqlSegment.contains("end_date"));
                    return 1L;
                });
        var result = service.validateSql(new SqlValidationRequest(
                "SELECT t.AMOUNT FROM CORE.LOAN_FACT t",
                List.of(new CodeValueCheck("LOAN_CLASS", "VALID_AFTER_FIRST_500")),
                "1104"));

        assertTrue(result.valid());
    }

    @Test
    void ignoresQualifiedLookingTextInsideLiteralsAndComments() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "SELECT t.AMOUNT FROM CORE.LOAN_FACT t "
                        + "WHERE t.AMOUNT > 0 AND 't.NOT_EXISTS' = 't.NOT_EXISTS' "
                        + "/* t.BAD_COLUMN */ -- t.WORSE_COLUMN\n",
                List.of(),
                "1104"));

        assertTrue(result.valid());
        assertTrue(result.checkedColumns().contains("t.AMOUNT"));
    }

    @Test
    void validatesAliasesIntroducedByCommaJoins() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "SELECT a.AMOUNT, b.NOT_EXISTS "
                        + "FROM CORE.LOAN_FACT a, CORE.LOAN_FACT b",
                List.of(),
                "1104"));

        assertFalse(result.valid());
        assertTrue(result.errors().stream().anyMatch(error -> error.contains("NOT_EXISTS")));
    }

    @Test
    void rejectsUnknownFullyQualifiedColumn() {
        stubPhysicalCatalog();
        var result = service.validateSql(new SqlValidationRequest(
                "SELECT CORE.LOAN_FACT.NOT_EXISTS FROM CORE.LOAN_FACT",
                List.of(),
                "1104"));

        assertFalse(result.valid());
        assertTrue(result.errors().stream().anyMatch(error -> error.contains("NOT_EXISTS")));
    }

    @Test
    void rejectsUnknownQuotedQualifiedColumns() {
        stubPhysicalCatalog();
        var backtickQuoted = service.validateSql(new SqlValidationRequest(
                "SELECT t.`NOT_EXISTS` FROM `CORE`.`LOAN_FACT` t",
                List.of(),
                "1104"));
        var doubleQuoted = service.validateSql(new SqlValidationRequest(
                "SELECT t.\"NOT_EXISTS\" FROM \"CORE\".\"LOAN_FACT\" t",
                List.of(),
                "1104"));

        assertFalse(backtickQuoted.valid());
        assertTrue(backtickQuoted.errors().stream().anyMatch(error -> error.contains("NOT_EXISTS")));
        assertFalse(doubleQuoted.valid());
        assertTrue(doubleQuoted.errors().stream().anyMatch(error -> error.contains("NOT_EXISTS")));
    }

    @Test
    void rejectsInactiveAssetsRetrievedById() {
        RegTable inactiveTable = new RegTable();
        inactiveTable.setId(10L);
        inactiveTable.setSystemCode("1104");
        inactiveTable.setStatus(0);
        when(regTableService.getById(10L)).thenReturn(inactiveTable);

        RegElement inactiveElement = new RegElement();
        inactiveElement.setId(20L);
        inactiveElement.setStatus(0);
        when(regElementService.getById(20L)).thenReturn(inactiveElement);

        var tableError = assertThrows(
                org.springframework.web.server.ResponseStatusException.class,
                () -> service.getTable(10L, "1104", 10));
        var elementError = assertThrows(
                org.springframework.web.server.ResponseStatusException.class,
                () -> service.getElement(20L, "1104"));

        assertEquals(404, tableError.getStatusCode().value());
        assertEquals(404, elementError.getStatusCode().value());
    }

    @Test
    void developmentContextKeepsOnlyOnePreviewElementPerTable() {
        RegTable table = regulatoryTable(1L);
        when(regTableService.getById(1L)).thenReturn(table);
        RegElement first = new RegElement();
        first.setId(11L);
        first.setTableId(1L);
        first.setName("FIRST_FIELD");
        first.setStatus(1);
        when(regElementService.list(org.mockito.ArgumentMatchers.<Wrapper<RegElement>>any()))
                .thenReturn(List.of(first));
        when(regElementService.count(org.mockito.ArgumentMatchers.<Wrapper<RegElement>>any()))
                .thenReturn(20L);

        var result = service.buildDevelopmentContext(new DevelopmentContextRequest(
                "开发客户数量指标",
                List.of(),
                List.of(1L),
                List.of(),
                "1104"));

        assertEquals(1, result.tables().size());
        assertEquals(1, result.tables().get(0).elements().size());
        assertTrue(result.tables().get(0).elementsTruncated());
        assertTrue(result.missingInformation().stream()
                .anyMatch(message -> message.contains("尚未确认指标使用的具体监管字段")));
    }

    @Test
    void developmentContextKeepsKeywordCandidatesInsideExplicitTables() {
        RegTable explicitTable = regulatoryTable(1L);
        RegTable unrelatedTable = regulatoryTable(2L);
        when(regTableService.getById(1L)).thenReturn(explicitTable);
        when(regTableService.list(org.mockito.ArgumentMatchers.<Wrapper<RegTable>>any()))
                .thenReturn(List.of(unrelatedTable), List.of(explicitTable, unrelatedTable));
        RegElement preview = new RegElement();
        preview.setId(11L);
        preview.setTableId(1L);
        preview.setName("CUST_ID");
        preview.setStatus(1);
        when(regElementService.list(org.mockito.ArgumentMatchers.<Wrapper<RegElement>>any()))
                .thenReturn(List.of(), List.of(preview));
        when(regElementService.count(org.mockito.ArgumentMatchers.<Wrapper<RegElement>>any()))
                .thenReturn(1L);

        var result = service.buildDevelopmentContext(new DevelopmentContextRequest(
                "基于指定客户表开发客户数",
                List.of("客户数"),
                List.of(1L),
                List.of(),
                "1104"));

        assertEquals(List.of("1"), result.tables().stream().map(table -> table.id()).toList());
        assertTrue(result.evidence().stream().noneMatch(item -> item.startsWith("REG_TABLE:2@")));
    }

    private void stubDuplicateTableNames() {
        RegTable currentTable = regulatoryTable(1L);
        RegTable archiveTable = regulatoryTable(2L);
        when(regTableService.listByIds(List.of(1L, 2L))).thenReturn(List.of(currentTable, archiveTable));

        ModelTable currentModel = modelTable("model-table-1", "CORE");
        ModelTable archiveModel = modelTable("model-table-2", "ARCHIVE");
        when(modelTableService.list(org.mockito.ArgumentMatchers.<Wrapper<ModelTable>>any()))
                .thenReturn(List.of(currentModel, archiveModel));

        RegTableModelTableRel currentRelation = relation(1L, "model-table-1");
        RegTableModelTableRel archiveRelation = relation(2L, "model-table-2");
        when(tableRelMapper.selectList(
                org.mockito.ArgumentMatchers.<Wrapper<RegTableModelTableRel>>any()))
                .thenReturn(List.of(currentRelation, archiveRelation));
        when(modelFieldService.list(org.mockito.ArgumentMatchers.<Wrapper<ModelField>>any()))
                .thenReturn(List.of(
                        field("model-table-1", "AMOUNT"),
                        field("model-table-2", "ARCHIVE_ONLY")));
    }

    private RegTable regulatoryTable(Long id) {
        RegTable table = new RegTable();
        table.setId(id);
        table.setName("LOAN_SUMMARY_" + id);
        table.setSystemCode("1104");
        table.setStatus(1);
        return table;
    }

    private ModelTable modelTable(String id, String owner) {
        ModelTable table = new ModelTable();
        table.setId(id);
        table.setOwner(owner);
        table.setName("LOAN_FACT");
        return table;
    }

    private RegTableModelTableRel relation(Long regTableId, String modelTableId) {
        RegTableModelTableRel relation = new RegTableModelTableRel();
        relation.setRegTableId(regTableId);
        relation.setModelTableId(modelTableId);
        return relation;
    }

    private ModelField field(String name) {
        return field("model-table-1", name);
    }

    private ModelField field(String tableId, String name) {
        ModelField field = new ModelField();
        field.setId(name.toLowerCase());
        field.setTableId(tableId);
        field.setName(name);
        return field;
    }
}
