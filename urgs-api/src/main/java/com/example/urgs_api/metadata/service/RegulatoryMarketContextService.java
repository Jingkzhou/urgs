package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.dto.PhysicalFieldBindingDTO;
import com.example.urgs_api.metadata.dto.PhysicalTableBindingDTO;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.CodeTableContext;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.CodeValue;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.CodeValueCheck;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.DevelopmentContextRequest;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.DevelopmentContextResponse;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.ElementContext;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.Relationship;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.RelationshipRequest;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.RelationshipResponse;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.SearchItem;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.SearchResponse;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.SqlValidationRequest;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.SqlValidationResult;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.TableContext;
import com.example.urgs_api.metadata.mapper.RegTableModelTableRelMapper;
import com.example.urgs_api.metadata.model.CodeDirectory;
import com.example.urgs_api.metadata.model.CodeTable;
import com.example.urgs_api.metadata.model.ModelField;
import com.example.urgs_api.metadata.model.ModelTable;
import com.example.urgs_api.metadata.model.RegElement;
import com.example.urgs_api.metadata.model.RegTable;
import com.example.urgs_api.metadata.model.RegTableModelTableRel;
import net.sf.jsqlparser.parser.CCJSqlParserUtil;
import net.sf.jsqlparser.schema.Column;
import net.sf.jsqlparser.schema.Table;
import net.sf.jsqlparser.statement.Statement;
import net.sf.jsqlparser.statement.insert.Insert;
import net.sf.jsqlparser.statement.select.Select;
import net.sf.jsqlparser.statement.select.SelectItem;
import net.sf.jsqlparser.statement.select.FromItem;
import net.sf.jsqlparser.statement.select.Join;
import net.sf.jsqlparser.statement.select.ParenthesedSelect;
import net.sf.jsqlparser.statement.select.PlainSelect;
import net.sf.jsqlparser.statement.select.Values;
import net.sf.jsqlparser.statement.select.WithItem;
import net.sf.jsqlparser.util.TablesNamesFinder;
import org.apache.commons.lang3.StringUtils;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Deque;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class RegulatoryMarketContextService {

    private static final int MAX_SEARCH_LIMIT = 50;
    private static final int DEFAULT_ELEMENT_LIMIT = 100;
    private static final int MAX_CODE_VALUE_LIMIT = 500;
    private static final int MAX_DEVELOPMENT_TABLES = 5;
    private static final int MAX_DEVELOPMENT_ELEMENTS = 30;
    private static final String SQL_IDENTIFIER_PATTERN =
            "(?:[A-Za-z_][A-Za-z0-9_$]*|`[^`]+`|\"[^\"]+\")";
    private static final Pattern QUALIFIED_COLUMN_PATTERN = Pattern.compile(
            "(?<![A-Za-z0-9_$])(" + SQL_IDENTIFIER_PATTERN + ")(?:\\.("
                    + SQL_IDENTIFIER_PATTERN + "))?\\.(" + SQL_IDENTIFIER_PATTERN
                    + ")(?![A-Za-z0-9_$])");
    private static final Pattern SQL_LITERAL_OR_COMMENT_PATTERN = Pattern.compile(
            "/\\*[\\s\\S]*?\\*/|--(?=\\s|$)[^\\r\\n]*|#[^\\r\\n]*|'(?:''|\\\\.|[^'])*'");

    private final RegTableService regTableService;
    private final RegElementService regElementService;
    private final CodeTableService codeTableService;
    private final CodeDirectoryService codeDirectoryService;
    private final ModelTableService modelTableService;
    private final ModelFieldService modelFieldService;
    private final RegTableModelTableRelMapper tableRelMapper;
    private final RegPhysicalBindingService regPhysicalBindingService;

    public RegulatoryMarketContextService(
            RegTableService regTableService,
            RegElementService regElementService,
            CodeTableService codeTableService,
            CodeDirectoryService codeDirectoryService,
            ModelTableService modelTableService,
            ModelFieldService modelFieldService,
            RegTableModelTableRelMapper tableRelMapper,
            RegPhysicalBindingService regPhysicalBindingService) {
        this.regTableService = regTableService;
        this.regElementService = regElementService;
        this.codeTableService = codeTableService;
        this.codeDirectoryService = codeDirectoryService;
        this.modelTableService = modelTableService;
        this.modelFieldService = modelFieldService;
        this.tableRelMapper = tableRelMapper;
        this.regPhysicalBindingService = regPhysicalBindingService;
    }

    public SearchResponse search(String keyword, String systemCode, String allowedSystemsValue, int requestedLimit) {
        AccessScope scope = AccessScope.parse(allowedSystemsValue);
        if (scope.denied()) {
            return new SearchResponse(normalizeKeyword(keyword), List.of(), false);
        }
        int limit = Math.max(1, Math.min(requestedLimit, MAX_SEARCH_LIMIT));
        String normalizedKeyword = normalizeKeyword(keyword);
        List<SearchItem> items = new ArrayList<>();

        LambdaQueryWrapper<RegTable> tableQuery = new LambdaQueryWrapper<RegTable>()
                .eq(RegTable::getStatus, 1)
                .orderByAsc(RegTable::getSortOrder)
                .orderByAsc(RegTable::getId);
        applyRegTableScope(tableQuery, scope, systemCode);
        if (StringUtils.isNotBlank(normalizedKeyword)) {
            tableQuery.and(query -> query.like(RegTable::getName, normalizedKeyword)
                    .or().like(RegTable::getCnName, normalizedKeyword)
                    .or().like(RegTable::getBusinessCaliber, normalizedKeyword)
                    .or().like(RegTable::getFillInstruction, normalizedKeyword)
                    .or().like(RegTable::getSubjectName, normalizedKeyword));
        }
        List<RegTable> tables = regTableService.list(tableQuery.last("LIMIT " + limit));
        tables.forEach(table -> items.add(toSearchItem(table)));

        if (items.size() < limit) {
            List<RegTable> allowedTables = listAllowedTables(scope, systemCode);
            List<Long> allowedTableIds = allowedTables.stream()
                    .map(RegTable::getId)
                    .filter(Objects::nonNull)
                    .toList();
            Map<Long, RegTable> tableById = allowedTables.stream()
                    .collect(Collectors.toMap(RegTable::getId, Function.identity(), (left, right) -> left));
            if (!allowedTableIds.isEmpty()) {
                LambdaQueryWrapper<RegElement> elementQuery = new LambdaQueryWrapper<RegElement>()
                        .in(RegElement::getTableId, allowedTableIds)
                        .eq(RegElement::getStatus, 1)
                        .orderByAsc(RegElement::getSortOrder)
                        .orderByAsc(RegElement::getId);
                if (StringUtils.isNotBlank(normalizedKeyword)) {
                    elementQuery.and(query -> query.like(RegElement::getName, normalizedKeyword)
                            .or().like(RegElement::getCnName, normalizedKeyword)
                            .or().like(RegElement::getBusinessCaliber, normalizedKeyword)
                            .or().like(RegElement::getFillInstruction, normalizedKeyword)
                            .or().like(RegElement::getFormula, normalizedKeyword));
                }
                int remaining = limit - items.size();
                regElementService.list(elementQuery.last("LIMIT " + remaining)).forEach(element -> {
                    RegTable parent = tableById.get(element.getTableId());
                    items.add(toSearchItem(element, parent));
                });
            }
        }

        if (items.size() < limit) {
            LambdaQueryWrapper<CodeTable> codeTableQuery = new LambdaQueryWrapper<CodeTable>()
                    .orderByAsc(CodeTable::getTableCode);
            applyCodeTableScope(codeTableQuery, scope, systemCode);
            if (StringUtils.isNotBlank(normalizedKeyword)) {
                codeTableQuery.and(query -> query.like(CodeTable::getTableCode, normalizedKeyword)
                        .or().like(CodeTable::getTableName, normalizedKeyword)
                        .or().like(CodeTable::getDescription, normalizedKeyword));
            }
            int remaining = limit - items.size();
            codeTableService.list(codeTableQuery.last("LIMIT " + remaining))
                    .forEach(codeTable -> items.add(toSearchItem(codeTable)));
        }
        return new SearchResponse(normalizedKeyword, items, items.size() >= limit);
    }

    public TableContext getTable(Long tableId, String allowedSystemsValue, int requestedElementLimit) {
        AccessScope scope = AccessScope.parse(allowedSystemsValue);
        RegTable table = regTableService.getById(tableId);
        requireAllowed(table, scope);
        int elementLimit = Math.max(1, Math.min(requestedElementLimit, DEFAULT_ELEMENT_LIMIT));
        regPhysicalBindingService.enrichTable(table);
        LambdaQueryWrapper<RegElement> query = new LambdaQueryWrapper<RegElement>()
                .eq(RegElement::getTableId, tableId)
                .eq(RegElement::getStatus, 1)
                .orderByAsc(RegElement::getSortOrder)
                .orderByAsc(RegElement::getId);
        long count = regElementService.count(query);
        List<RegElement> elements = regElementService.list(query.last("LIMIT " + elementLimit));
        regPhysicalBindingService.enrichElements(elements);
        List<ElementContext> elementContexts = elements.stream()
                .map(element -> toElementContext(element, false, scope))
                .toList();
        return toTableContext(table, elementContexts, count, count > elementContexts.size());
    }

    public ElementContext getElement(Long elementId, String allowedSystemsValue) {
        AccessScope scope = AccessScope.parse(allowedSystemsValue);
        RegElement element = regElementService.getById(elementId);
        if (element == null || element.getStatus() == null || element.getStatus() != 1) {
            throw notFound("监管字段或指标不存在或已停用");
        }
        RegTable table = regTableService.getById(element.getTableId());
        requireAllowed(table, scope);
        regPhysicalBindingService.enrichElement(element);
        return toElementContext(element, true, scope);
    }

    public CodeTableContext getCodeValues(String tableCode, String allowedSystemsValue, int requestedLimit) {
        AccessScope scope = AccessScope.parse(allowedSystemsValue);
        if (scope.denied()) {
            throw forbidden();
        }
        int limit = Math.max(1, Math.min(requestedLimit, MAX_CODE_VALUE_LIMIT));
        // code_table.uk_table_code 保证 table_code 全局唯一；唯一表头的 system_code 决定访问范围。
        CodeTable codeTable = codeTableService.getOne(new LambdaQueryWrapper<CodeTable>()
                .eq(CodeTable::getTableCode, tableCode), false);
        if (codeTable != null && !scope.allows(codeTable.getSystemCode())) {
            throw forbidden();
        }
        LambdaQueryWrapper<CodeDirectory> query = new LambdaQueryWrapper<CodeDirectory>()
                .eq(CodeDirectory::getTableCode, tableCode)
                .orderByAsc(CodeDirectory::getSortOrder)
                .orderByAsc(CodeDirectory::getCode);
        applyEffectiveCodeDate(query);
        if (!scope.all()) {
            query.and(item -> item.isNull(CodeDirectory::getSystemCode)
                    .or().in(CodeDirectory::getSystemCode, scope.systems()));
        }
        long total = codeDirectoryService.count(query);
        List<CodeValue> values = codeDirectoryService.list(query.last("LIMIT " + limit)).stream()
                .map(this::toCodeValue)
                .toList();
        if (codeTable == null && values.isEmpty()) {
            throw notFound("码表不存在或当前用户无权访问");
        }
        return new CodeTableContext(
                tableCode,
                codeTable == null ? null : codeTable.getTableName(),
                codeTable == null ? null : codeTable.getSystemCode(),
                codeTable == null ? null : codeTable.getDescription(),
                values,
                total,
                total > values.size());
    }

    public RelationshipResponse getRelationships(RelationshipRequest request) {
        AccessScope scope = AccessScope.parse(request == null ? null : request.allowedSystems());
        List<Long> tableIds = request == null || request.tableIds() == null
                ? List.of()
                : request.tableIds().stream().filter(Objects::nonNull).distinct().limit(10).toList();
        List<TableContext> contexts = tableIds.stream()
                .map(tableId -> getTable(tableId, scope.serialized(), 1))
                .toList();
        Map<String, LinkedHashSet<String>> tablesByPhysicalTable = new LinkedHashMap<>();
        for (TableContext context : contexts) {
            for (PhysicalTableBindingDTO binding : context.physicalTables()) {
                String physicalName = qualifiedName(binding.getOwner(), binding.getTableName());
                tablesByPhysicalTable.computeIfAbsent(physicalName, ignored -> new LinkedHashSet<>())
                        .add(context.id());
            }
        }
        List<Relationship> relationships = tablesByPhysicalTable.entrySet().stream()
                .filter(entry -> entry.getValue().size() > 1)
                .map(entry -> new Relationship(
                        "SHARED_PHYSICAL_TABLE",
                        List.copyOf(entry.getValue()),
                        entry.getKey(),
                        true,
                        "这些监管表绑定到同一物理表；当前资产未维护表间 JOIN 键，不能据此推断连接条件。"))
                .toList();
        List<String> warnings = relationships.isEmpty()
                ? List.of("未发现已确认的共享物理表关系；不得根据字段同名自行推断 JOIN 条件。")
                : List.of("共享物理表只证明资产绑定关系，不代表监管表之间存在可直接使用的 JOIN 关系。");
        return new RelationshipResponse(relationships, warnings);
    }

    public DevelopmentContextResponse buildDevelopmentContext(DevelopmentContextRequest request) {
        if (request == null || StringUtils.isBlank(request.requirement())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "指标开发需求不能为空");
        }
        AccessScope scope = AccessScope.parse(request.allowedSystems());
        if (scope.denied()) {
            throw forbidden();
        }
        LinkedHashSet<Long> tableIds = distinctIds(request.tableIds());
        LinkedHashSet<Long> elementIds = distinctIds(request.elementIds());
        boolean hasExplicitTables = !tableIds.isEmpty();
        boolean hasExplicitElements = !elementIds.isEmpty();
        LinkedHashSet<Long> explicitTableIds = new LinkedHashSet<>(tableIds);
        List<String> keywords = request.keywords() == null ? List.of() : request.keywords().stream()
                .filter(StringUtils::isNotBlank)
                .map(String::trim)
                .distinct()
                .limit(8)
                .toList();
        for (String keyword : keywords) {
            SearchResponse response = search(keyword, null, scope.serialized(), 12);
            for (SearchItem item : response.items()) {
                if ("REG_TABLE".equals(item.assetType()) && !hasExplicitTables) {
                    tableIds.add(Long.valueOf(item.assetId()));
                } else if ("REG_ELEMENT".equals(item.assetType()) && !hasExplicitElements) {
                    Long parentId = Long.valueOf(item.parentId());
                    if (hasExplicitTables && !explicitTableIds.contains(parentId)) {
                        continue;
                    }
                    elementIds.add(Long.valueOf(item.assetId()));
                    tableIds.add(parentId);
                }
            }
        }
        List<ElementContext> selectedElements = elementIds.stream()
                .limit(MAX_DEVELOPMENT_ELEMENTS)
                .map(elementId -> getElement(elementId, scope.serialized()))
                .toList();
        selectedElements.stream().map(ElementContext::tableId).map(Long::valueOf).forEach(tableIds::add);
        List<TableContext> tables = tableIds.stream()
                .limit(MAX_DEVELOPMENT_TABLES)
                .map(tableId -> getTable(tableId, scope.serialized(), 1))
                .toList();

        List<String> missingInformation = new ArrayList<>();
        if (tables.isEmpty()) {
            missingInformation.add("未定位到可用监管表，请补充监管系统、业务主题或候选表名。");
        }
        tables.stream().filter(table -> table.physicalTables().isEmpty())
                .forEach(table -> missingInformation.add("监管表 " + table.name() + " 尚未绑定物理表。"));
        selectedElements.stream().filter(element -> element.physicalFields().isEmpty())
                .forEach(element -> missingInformation.add("监管项 " + element.name() + " 尚未绑定物理字段。"));
        if (selectedElements.isEmpty()) {
            missingInformation.add("尚未确认指标使用的具体监管字段或监管指标。");
        }
        List<String> evidence = new ArrayList<>();
        tables.forEach(table -> evidence.add("REG_TABLE:" + table.id() + "@" + table.updateTime()));
        selectedElements.forEach(element -> evidence.add("REG_ELEMENT:" + element.id() + "@" + element.updateTime()));
        return new DevelopmentContextResponse(
                request.requirement().trim(), tables, selectedElements, missingInformation, evidence);
    }

    public SqlValidationResult validateSql(SqlValidationRequest request) {
        List<String> errors = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        List<String> statementTypes = new ArrayList<>();
        LinkedHashSet<String> referencedTables = new LinkedHashSet<>();
        LinkedHashSet<String> checkedColumns = new LinkedHashSet<>();
        List<TableReference> tableReferences = new ArrayList<>();
        List<ColumnReference> columnReferences = new ArrayList<>();
        Map<String, Set<String>> derivedColumns = new LinkedHashMap<>();
        if (request == null || StringUtils.isBlank(request.sql())) {
            return new SqlValidationResult(false, List.of(), List.of(), List.of(),
                    List.of("SQL 不能为空"), List.of());
        }
        AccessScope scope = AccessScope.parse(request.allowedSystems());
        if (scope.denied()) {
            return new SqlValidationResult(false, List.of(), List.of(), List.of(),
                    List.of("当前用户没有监管集市访问范围"), List.of());
        }
        try {
            List<Statement> statements = CCJSqlParserUtil.parseStatements(request.sql()).getStatements();
            if (statements.isEmpty()) {
                errors.add("SQL 中没有可解析的语句");
            }
            for (Statement statement : statements) {
                statementTypes.add(statement.getClass().getSimpleName().toUpperCase(Locale.ROOT));
                if (statement instanceof Select select) {
                    TableReferenceFinder finder = new TableReferenceFinder();
                    Set<String> foundTables = finder.getTables((Statement) select);
                    referencedTables.addAll(foundTables.stream()
                            .filter(table -> !finder.isDerivedTable(table))
                            .toList());
                    tableReferences.addAll(finder.references());
                    columnReferences.addAll(finder.columns());
                    derivedColumns.putAll(finder.derivedColumns());
                } else if (statement instanceof Insert insert) {
                    Select sourceQuery = insert.getSelect();
                    if (sourceQuery == null || sourceQuery instanceof Values) {
                        errors.add("第一阶段只允许生成 INSERT SELECT，不允许 INSERT VALUES 或 INSERT SET");
                        continue;
                    }
                    TableReferenceFinder finder = new TableReferenceFinder();
                    Set<String> foundTables = finder.getTables((Statement) sourceQuery);
                    referencedTables.addAll(foundTables.stream()
                            .filter(table -> !finder.isDerivedTable(table))
                            .toList());
                    tableReferences.addAll(finder.references());
                    columnReferences.addAll(finder.columns());
                    derivedColumns.putAll(finder.derivedColumns());
                } else {
                    errors.add("第一阶段只允许生成 SELECT 或 INSERT SELECT，不允许 "
                            + statement.getClass().getSimpleName());
                }
            }
        } catch (Exception e) {
            errors.add("SQL 语法解析失败: " + safeMessage(e));
        }

        PhysicalCatalog catalog = buildPhysicalCatalog(scope, referencedTables);
        for (String tableName : referencedTables) {
            if (!catalog.hasTable(tableName)) {
                errors.add("SQL 引用了未绑定或无权限的物理表: " + tableName);
            }
        }
        String sqlForIdentifierValidation = maskSqlLiteralsAndComments(request.sql());
        Map<String, String> aliases = buildAliases(tableReferences);
        Set<String> tableIdentifierTokens = tableReferences.stream()
                .map(TableReference::qualifiedName)
                .map(this::normalizeIdentifier)
                .collect(Collectors.toSet());
        Matcher matcher = QUALIFIED_COLUMN_PATTERN.matcher(sqlForIdentifierValidation);
        while (matcher.find()) {
            if (tableIdentifierTokens.contains(normalizeIdentifier(matcher.group()))) {
                continue;
            }
            String qualifier = matcher.group(2) == null
                    ? normalizeIdentifier(matcher.group(1))
                    : normalizeIdentifier(matcher.group(1) + "." + matcher.group(2));
            String column = normalizeIdentifier(matcher.group(3));
            String resolvedTable = aliases.getOrDefault(qualifier, qualifier);
            if (!catalog.hasTable(resolvedTable)) {
                Set<String> availableColumns = derivedColumns.get(resolvedTable);
                if (availableColumns != null) {
                    String display = matcher.group();
                    checkedColumns.add(display);
                    if (!availableColumns.contains(column)) {
                        errors.add("派生表 " + resolvedTable + " 中不存在字段 " + matcher.group(3));
                    }
                } else {
                    checkedColumns.add(matcher.group());
                    errors.add("SQL 使用了无法解析的物理表或别名: " + qualifier);
                }
                continue;
            }
            String display = matcher.group();
            checkedColumns.add(display);
            if (!catalog.hasColumn(resolvedTable, column)) {
                errors.add("物理表 " + catalog.displayName(resolvedTable) + " 中不存在字段 " + matcher.group(3));
            }
        }
        columnReferences.stream()
                .filter(column -> StringUtils.isBlank(column.qualifier()))
                .filter(column -> !column.allowedProjectionAliasReference())
                .distinct()
                .forEach(reference -> {
                    String column = reference.column();
                    checkedColumns.add(column);
                    List<String> sourceAliases = reference.scopeSources().stream().distinct().toList();
                    if (sourceAliases.size() != 1) {
                        errors.add("SQL 未限定字段 " + column + " 的来源表，请使用表别名.字段名");
                        return;
                    }
                    String source = aliases.getOrDefault(sourceAliases.get(0), sourceAliases.get(0));
                    Set<String> availableDerivedColumns = derivedColumns.get(source);
                    if (availableDerivedColumns != null) {
                        if (!availableDerivedColumns.contains(normalizeIdentifier(column))) {
                            errors.add("派生表 " + source + " 中不存在字段 " + column);
                        }
                    } else if (!catalog.hasTable(source)) {
                        errors.add("SQL 使用了无法解析的物理表或别名: " + source);
                    } else if (!catalog.hasColumn(source, column)) {
                        errors.add("物理表 " + catalog.displayName(source) + " 中不存在字段 " + column);
                    }
                });
        if (!referencedTables.isEmpty() && columnReferences.isEmpty()) {
            warnings.add("SQL 未使用可确定归属的限定字段，当前只能校验表名；建议使用表别名.字段名。");
        }
        validateCodeChecks(request.codeChecks(), scope, errors);
        if (errors.isEmpty() && statementTypes.stream().anyMatch("INSERT"::equals)) {
            warnings.add("INSERT SELECT 仅完成静态校验，未连接数据库执行或验证目标表写入权限。");
        }
        return new SqlValidationResult(
                errors.isEmpty(), statementTypes, List.copyOf(referencedTables), List.copyOf(checkedColumns),
                errors, warnings);
    }

    private void validateCodeChecks(List<CodeValueCheck> checks, AccessScope scope, List<String> errors) {
        if (checks == null) {
            return;
        }
        checks.stream().filter(Objects::nonNull).limit(50).forEach(check -> {
            if (StringUtils.isAnyBlank(check.tableCode(), check.code())) {
                errors.add("码值校验必须同时提供 tableCode 和 code");
                return;
            }
            // 与 getCodeValues 保持一致：table_code 由 uk_table_code 保证全局唯一。
            CodeTable codeTable = codeTableService.getOne(new LambdaQueryWrapper<CodeTable>()
                    .eq(CodeTable::getTableCode, check.tableCode()), false);
            if (codeTable != null && !scope.allows(codeTable.getSystemCode())) {
                errors.add("码表不存在或无权访问: " + check.tableCode());
                return;
            }
            LambdaQueryWrapper<CodeDirectory> query = new LambdaQueryWrapper<CodeDirectory>()
                    .eq(CodeDirectory::getTableCode, check.tableCode())
                    .eq(CodeDirectory::getCode, check.code());
            applyEffectiveCodeDate(query);
            if (!scope.all()) {
                query.and(item -> item.isNull(CodeDirectory::getSystemCode)
                        .or().in(CodeDirectory::getSystemCode, scope.systems()));
            }
            boolean exists = codeDirectoryService.count(query) > 0;
            if (!exists) {
                errors.add("码表 " + check.tableCode() + " 中不存在码值 " + check.code());
            }
        });
    }

    private PhysicalCatalog buildPhysicalCatalog(AccessScope scope, Collection<String> referencedTables) {
        LinkedHashSet<String> referencedNames = referencedTables.stream()
                .map(this::normalizeIdentifier)
                .filter(StringUtils::isNotBlank)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        LinkedHashSet<String> shortNames = referencedTables.stream()
                .map(this::shortName)
                .map(this::normalizeIdentifier)
                .filter(StringUtils::isNotBlank)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (shortNames.isEmpty()) {
            return PhysicalCatalog.from(Map.of(), Map.of());
        }
        List<ModelTable> candidates = modelTableService.list(new LambdaQueryWrapper<ModelTable>()
                .in(ModelTable::getName, shortNames));
        candidates = candidates.stream()
                .filter(table -> matchesReference(table, referencedNames, shortNames))
                .toList();
        if (candidates.isEmpty()) {
            return PhysicalCatalog.from(Map.of(), Map.of());
        }
        List<String> candidateIds = candidates.stream().map(ModelTable::getId).toList();
        List<RegTableModelTableRel> relations = tableRelMapper.selectList(
                new LambdaQueryWrapper<RegTableModelTableRel>()
                        .in(RegTableModelTableRel::getModelTableId, candidateIds));
        List<Long> regulatoryTableIds = relations.stream()
                .map(RegTableModelTableRel::getRegTableId)
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        Set<Long> allowedRegulatoryTableIds = regulatoryTableIds.isEmpty()
                ? Set.of()
                : regTableService.listByIds(regulatoryTableIds).stream()
                        .filter(table -> table.getStatus() != null && table.getStatus() == 1)
                        .filter(table -> scope.allows(table.getSystemCode()))
                        .map(RegTable::getId)
                        .collect(Collectors.toSet());
        Set<String> allowedModelTableIds = relations.stream()
                .filter(relation -> allowedRegulatoryTableIds.contains(relation.getRegTableId()))
                .map(RegTableModelTableRel::getModelTableId)
                .collect(Collectors.toSet());
        Map<String, PhysicalTableBindingDTO> bindingById = candidates.stream()
                .filter(table -> allowedModelTableIds.contains(table.getId()))
                .collect(Collectors.toMap(ModelTable::getId, this::toPhysicalTableBinding,
                        (left, right) -> left, LinkedHashMap::new));
        Map<String, Set<String>> columnsByTableId = new LinkedHashMap<>();
        if (!bindingById.isEmpty()) {
            modelFieldService.list(new LambdaQueryWrapper<ModelField>()
                    .in(ModelField::getTableId, bindingById.keySet()))
                    .forEach(field -> columnsByTableId
                            .computeIfAbsent(field.getTableId(), ignored -> new LinkedHashSet<>())
                            .add(normalizeIdentifier(field.getName())));
        }
        return PhysicalCatalog.from(bindingById, columnsByTableId);
    }

    private boolean matchesReference(
            ModelTable table, Set<String> referencedNames, Set<String> shortNames) {
        String shortName = normalizeIdentifier(table.getName());
        String qualifiedName = normalizeIdentifier(qualifiedName(table.getOwner(), table.getName()));
        return shortNames.contains(shortName) && (referencedNames.contains(shortName)
                || referencedNames.contains(qualifiedName));
    }

    private PhysicalTableBindingDTO toPhysicalTableBinding(ModelTable table) {
        PhysicalTableBindingDTO binding = new PhysicalTableBindingDTO();
        binding.setModelTableId(table.getId());
        binding.setDataSourceId(table.getDataSourceId());
        binding.setOwner(table.getOwner());
        binding.setTableName(table.getName());
        binding.setTableCnName(table.getCnName());
        return binding;
    }

    private Map<String, String> buildAliases(List<TableReference> tableReferences) {
        Map<String, String> aliases = new LinkedHashMap<>();
        Set<String> ambiguousShortNames = new LinkedHashSet<>();
        for (TableReference reference : tableReferences) {
            String table = normalizeIdentifier(reference.qualifiedName());
            String shortTable = normalizeIdentifier(reference.shortName());
            aliases.put(table, table);
            String existingShortTarget = aliases.putIfAbsent(shortTable, table);
            if (existingShortTarget != null && !existingShortTarget.equals(table)) {
                ambiguousShortNames.add(shortTable);
            }
            String alias = normalizeIdentifier(reference.alias());
            if (StringUtils.isNotBlank(alias)) {
                aliases.put(alias, table);
            }
        }
        ambiguousShortNames.forEach(aliases::remove);
        return aliases;
    }

    private void applyEffectiveCodeDate(LambdaQueryWrapper<CodeDirectory> query) {
        LocalDate today = LocalDate.now();
        query.and(item -> item.isNull(CodeDirectory::getStartDate)
                        .or().le(CodeDirectory::getStartDate, today))
                .and(item -> item.isNull(CodeDirectory::getEndDate)
                        .or().ge(CodeDirectory::getEndDate, today));
    }

    private String maskSqlLiteralsAndComments(String sql) {
        Matcher matcher = SQL_LITERAL_OR_COMMENT_PATTERN.matcher(sql);
        StringBuilder masked = new StringBuilder(sql);
        while (matcher.find()) {
            for (int index = matcher.start(); index < matcher.end(); index++) {
                char current = masked.charAt(index);
                if (current != '\r' && current != '\n') {
                    masked.setCharAt(index, ' ');
                }
            }
        }
        return masked.toString();
    }

    private final class TableReferenceFinder extends TablesNamesFinder<Void> {
        private final List<TableReference> references = new ArrayList<>();
        private final List<ColumnReference> columns = new ArrayList<>();
        private final Set<String> derivedTables = new LinkedHashSet<>();
        private final Map<String, Set<String>> derivedColumns = new LinkedHashMap<>();
        private final Deque<List<String>> sourceScopes = new ArrayDeque<>();
        private final Deque<Set<Column>> allowedProjectionAliasScopes = new ArrayDeque<>();

        @Override
        public <S> Void visit(PlainSelect plainSelect, S context) {
            List<String> sources = new ArrayList<>();
            addSource(sources, plainSelect.getFromItem());
            if (plainSelect.getJoins() != null) {
                for (Join join : plainSelect.getJoins()) {
                    addSource(sources, join.getRightItem());
                }
            }
            sourceScopes.push(List.copyOf(sources));
            Set<String> projectionAliases = plainSelect.getSelectItems().stream()
                    .map(SelectItem::getAlias)
                    .filter(Objects::nonNull)
                    .map(alias -> normalizeIdentifier(alias.getName()))
                    .collect(Collectors.toSet());
            Set<Column> allowedProjectionAliasReferences = Collections.newSetFromMap(
                    new IdentityHashMap<>());
            if (plainSelect.getOrderByElements() != null) {
                plainSelect.getOrderByElements().forEach(orderBy -> {
                    if (orderBy.getExpression() instanceof Column column
                            && (column.getTable() == null
                                    || StringUtils.isBlank(column.getTable().getName()))
                            && projectionAliases.contains(normalizeIdentifier(column.getColumnName()))) {
                        allowedProjectionAliasReferences.add(column);
                    }
                });
            }
            allowedProjectionAliasScopes.push(allowedProjectionAliasReferences);
            try {
                return super.visit(plainSelect, context);
            } finally {
                allowedProjectionAliasScopes.pop();
                sourceScopes.pop();
            }
        }

        private void addSource(List<String> sources, FromItem item) {
            if (item == null) {
                return;
            }
            if (item.getAlias() != null && StringUtils.isNotBlank(item.getAlias().getName())) {
                String alias = normalizeIdentifier(item.getAlias().getName());
                sources.add(alias);
                if (item instanceof ParenthesedSelect parenthesedSelect) {
                    derivedColumns.put(alias, selectOutputColumns(parenthesedSelect.getSelect()));
                }
            } else if (item instanceof Table table) {
                sources.add(normalizeIdentifier(table.getFullyQualifiedName()));
            }
        }

        @Override
        public <S> Void visit(WithItem withItem, S context) {
            if (withItem.getAlias() != null) {
                String name = normalizeIdentifier(withItem.getAlias().getName());
                derivedTables.add(name);
                derivedColumns.put(name, selectOutputColumns(withItem));
            }
            return super.visit(withItem, context);
        }

        private Set<String> selectOutputColumns(WithItem withItem) {
            List<SelectItem<?>> explicitColumns = withItem.getWithItemList();
            if (explicitColumns != null && !explicitColumns.isEmpty()) {
                return outputColumnNames(explicitColumns);
            }
            return selectOutputColumns(withItem.getSelect());
        }

        private Set<String> selectOutputColumns(Select body) {
            if (body == null || body.getPlainSelect() == null) {
                return Set.of();
            }
            return outputColumnNames(body.getPlainSelect().getSelectItems());
        }

        private Set<String> outputColumnNames(List<SelectItem<?>> items) {
            if (items == null) {
                return Set.of();
            }
            return items.stream()
                    .map(item -> {
                        if (item.getAlias() != null) {
                            return item.getAlias().getName();
                        }
                        if (item.getExpression() instanceof Column column) {
                            return column.getColumnName();
                        }
                        return null;
                    })
                    .filter(StringUtils::isNotBlank)
                    .map(RegulatoryMarketContextService.this::normalizeIdentifier)
                    .collect(Collectors.toCollection(LinkedHashSet::new));
        }

        @Override
        public <S> Void visit(Table table, S context) {
            references.add(new TableReference(
                    table.getFullyQualifiedName(),
                    table.getName(),
                    table.getAlias() == null ? null : table.getAlias().getName()));
            return super.visit(table, context);
        }

        @Override
        public <S> Void visit(Column column, S context) {
            Table table = column.getTable();
            columns.add(new ColumnReference(
                    table == null ? null : table.getFullyQualifiedName(),
                    column.getColumnName(),
                    sourceScopes.isEmpty() ? List.of() : sourceScopes.peek(),
                    !allowedProjectionAliasScopes.isEmpty()
                            && allowedProjectionAliasScopes.peek().contains(column)));
            return super.visit(column, context);
        }

        List<TableReference> references() {
            return List.copyOf(references);
        }

        List<ColumnReference> columns() {
            return List.copyOf(columns);
        }

        boolean isDerivedTable(String tableName) {
            return derivedTables.contains(normalizeIdentifier(tableName));
        }

        Map<String, Set<String>> derivedColumns() {
            return derivedColumns.entrySet().stream().collect(Collectors.toMap(
                    Map.Entry::getKey,
                    entry -> Set.copyOf(entry.getValue()),
                    (left, right) -> left,
                    LinkedHashMap::new));
        }
    }

    private List<RegTable> listAllowedTables(AccessScope scope, String requestedSystemCode) {
        if (scope.denied()) {
            return List.of();
        }
        LambdaQueryWrapper<RegTable> query = new LambdaQueryWrapper<RegTable>()
                .eq(RegTable::getStatus, 1)
                .orderByAsc(RegTable::getSortOrder)
                .orderByAsc(RegTable::getId);
        applyRegTableScope(query, scope, requestedSystemCode);
        return regTableService.list(query);
    }

    private void applyRegTableScope(
            LambdaQueryWrapper<RegTable> query, AccessScope scope, String requestedSystemCode) {
        String normalizedRequested = StringUtils.trimToNull(requestedSystemCode);
        if (normalizedRequested != null && !scope.allows(normalizedRequested)) {
            query.apply("1 = 0");
            return;
        }
        if (normalizedRequested != null) {
            query.eq(RegTable::getSystemCode, normalizedRequested);
        } else if (!scope.all()) {
            query.in(RegTable::getSystemCode, scope.systems());
        }
    }

    private void applyCodeTableScope(
            LambdaQueryWrapper<CodeTable> query, AccessScope scope, String requestedSystemCode) {
        String normalizedRequested = StringUtils.trimToNull(requestedSystemCode);
        if (normalizedRequested != null && !scope.allows(normalizedRequested)) {
            query.apply("1 = 0");
            return;
        }
        if (normalizedRequested != null) {
            query.eq(CodeTable::getSystemCode, normalizedRequested);
        } else if (!scope.all()) {
            query.in(CodeTable::getSystemCode, scope.systems());
        }
    }

    private void requireAllowed(RegTable table, AccessScope scope) {
        if (table == null || table.getStatus() == null || table.getStatus() != 1) {
            throw notFound("监管表不存在或已停用");
        }
        if (!scope.allows(table.getSystemCode())) {
            throw forbidden();
        }
    }

    private SearchItem toSearchItem(RegTable table) {
        return new SearchItem(
                "REG_TABLE", String.valueOf(table.getId()), null, table.getSystemCode(), table.getName(),
                table.getCnName(), firstNonBlank(table.getBusinessCaliber(), table.getFillInstruction()),
                table.getUpdateTime());
    }

    private SearchItem toSearchItem(RegElement element, RegTable table) {
        return new SearchItem(
                "REG_ELEMENT", String.valueOf(element.getId()), String.valueOf(element.getTableId()),
                table == null ? null : table.getSystemCode(), element.getName(), element.getCnName(),
                firstNonBlank(element.getBusinessCaliber(), element.getFillInstruction(), element.getFormula()),
                element.getUpdateTime());
    }

    private SearchItem toSearchItem(CodeTable codeTable) {
        return new SearchItem(
                "CODE_TABLE", codeTable.getId(), null, codeTable.getSystemCode(), codeTable.getTableCode(),
                codeTable.getTableName(), codeTable.getDescription(), codeTable.getUpdateTime());
    }

    private TableContext toTableContext(
            RegTable table, List<ElementContext> elements, long elementCount, boolean elementsTruncated) {
        return new TableContext(
                String.valueOf(table.getId()), table.getSystemCode(), table.getName(), table.getCnName(),
                table.getSubjectCode(), table.getSubjectName(), table.getTheme(), table.getFrequency(),
                table.getQueryTableType(), table.getBusinessCaliber(), table.getFillInstruction(), table.getDevNotes(),
                nullToEmpty(table.getPhysicalTables()), elements, elementCount, elementsTruncated, table.getUpdateTime());
    }

    private ElementContext toElementContext(RegElement element, boolean includeCodeValues, AccessScope scope) {
        CodeTableContext codeTable = null;
        if (includeCodeValues && StringUtils.isNotBlank(element.getCodeTableCode())) {
            try {
                codeTable = getCodeValues(element.getCodeTableCode(), scope.serialized(), 200);
            } catch (ResponseStatusException ignored) {
                // 保留监管项本身，码表缺失会在输出中表现为 null，供 Agent 标记待确认。
            }
        }
        return new ElementContext(
                String.valueOf(element.getId()), String.valueOf(element.getTableId()), element.getType(),
                element.getName(), element.getCnName(), element.getDataType(), element.getLength(),
                element.getNullable(), element.getIsPk(), element.getIsDesensitized(), element.getFormula(),
                element.getCodeSnippet(), element.getCodeTableCode(), element.getValueRange(),
                element.getValidationRule(), element.getBusinessCaliber(), element.getFillInstruction(),
                element.getDevNotes(), nullToEmpty(element.getPhysicalFields()), codeTable, element.getUpdateTime());
    }

    private CodeValue toCodeValue(CodeDirectory item) {
        return new CodeValue(
                item.getCode(), item.getName(), item.getParentCode(), item.getLevel(), item.getDescription(),
                item.getStartDate(), item.getEndDate());
    }

    private String normalizeKeyword(String keyword) {
        return StringUtils.defaultString(keyword).trim();
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (StringUtils.isNotBlank(value)) {
                return value;
            }
        }
        return null;
    }

    private String qualifiedName(String owner, String tableName) {
        return StringUtils.isBlank(owner) ? tableName : owner + "." + tableName;
    }

    private String safeMessage(Exception exception) {
        String message = exception.getMessage();
        return StringUtils.abbreviate(StringUtils.defaultIfBlank(message, exception.getClass().getSimpleName()), 240);
    }

    private String normalizeIdentifier(String identifier) {
        if (identifier == null) {
            return "";
        }
        return identifier.replace("`", "").replace("\"", "").trim().toUpperCase(Locale.ROOT);
    }

    private String shortName(String tableName) {
        String clean = tableName == null ? "" : tableName.replace("`", "").replace("\"", "");
        int index = clean.lastIndexOf('.');
        return index < 0 ? clean : clean.substring(index + 1);
    }

    private ResponseStatusException notFound(String message) {
        return new ResponseStatusException(HttpStatus.NOT_FOUND, message);
    }

    private ResponseStatusException forbidden() {
        return new ResponseStatusException(HttpStatus.FORBIDDEN, "当前用户无权访问该监管系统资产");
    }

    private <T> List<T> nullToEmpty(List<T> values) {
        return values == null ? List.of() : values;
    }

    private LinkedHashSet<Long> distinctIds(Collection<Long> ids) {
        if (ids == null) {
            return new LinkedHashSet<>();
        }
        return ids.stream().filter(Objects::nonNull).collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private record AccessScope(boolean all, LinkedHashSet<String> systems) {
        static AccessScope parse(String serialized) {
            LinkedHashSet<String> systems = StringUtils.isBlank(serialized)
                    ? new LinkedHashSet<>()
                    : List.of(serialized.split(",")).stream()
                            .map(String::trim)
                            .filter(StringUtils::isNotBlank)
                            .collect(Collectors.toCollection(LinkedHashSet::new));
            boolean all = systems.stream().anyMatch("ALL"::equalsIgnoreCase);
            return new AccessScope(all, systems);
        }

        boolean denied() {
            return !all && systems.isEmpty();
        }

        boolean allows(String systemCode) {
            return !denied() && (all || StringUtils.isBlank(systemCode)
                    || systems.stream().anyMatch(system -> system.equalsIgnoreCase(systemCode)));
        }

        String serialized() {
            return all ? "ALL" : String.join(",", systems);
        }
    }

    private record TableReference(String qualifiedName, String shortName, String alias) {
    }

    private record ColumnReference(
            String qualifier,
            String column,
            List<String> scopeSources,
            boolean allowedProjectionAliasReference) {
    }

    private record PhysicalCatalog(
            Map<String, String> canonicalByName,
            Map<String, String> displayByCanonical,
            Map<String, Set<String>> columnsByCanonical) {

        static PhysicalCatalog from(
                Map<String, PhysicalTableBindingDTO> bindingById, Map<String, Set<String>> columnsByTableId) {
            Map<String, String> canonicalByName = new LinkedHashMap<>();
            Map<String, String> displayByCanonical = new LinkedHashMap<>();
            Map<String, Set<String>> columnsByCanonical = new LinkedHashMap<>();
            Map<String, List<String>> canonicalsByShortName = new LinkedHashMap<>();
            bindingById.forEach((modelTableId, binding) -> {
                String shortName = normalizeStatic(binding.getTableName());
                String qualified = normalizeStatic(
                        StringUtils.isBlank(binding.getOwner())
                                ? binding.getTableName()
                                : binding.getOwner() + "." + binding.getTableName());
                String canonical = qualified;
                canonicalByName.put(qualified, canonical);
                canonicalsByShortName.computeIfAbsent(shortName, ignored -> new ArrayList<>()).add(canonical);
                displayByCanonical.put(canonical,
                        StringUtils.isBlank(binding.getOwner())
                                ? binding.getTableName()
                                : binding.getOwner() + "." + binding.getTableName());
                columnsByCanonical.computeIfAbsent(canonical, ignored -> new LinkedHashSet<>())
                        .addAll(columnsByTableId.getOrDefault(modelTableId, Collections.emptySet()));
            });
            canonicalsByShortName.forEach((shortName, canonicals) -> {
                if (canonicals.size() == 1) {
                    canonicalByName.put(shortName, canonicals.get(0));
                }
            });
            return new PhysicalCatalog(canonicalByName, displayByCanonical, columnsByCanonical);
        }

        boolean hasTable(String tableName) {
            return resolve(tableName) != null;
        }

        boolean hasColumn(String tableName, String columnName) {
            String canonical = resolve(tableName);
            return canonical != null
                    && columnsByCanonical.getOrDefault(canonical, Set.of()).contains(normalizeStatic(columnName));
        }

        String displayName(String tableName) {
            String canonical = resolve(tableName);
            return canonical == null ? tableName : displayByCanonical.getOrDefault(canonical, tableName);
        }

        private String resolve(String tableName) {
            String normalized = normalizeStatic(tableName);
            return canonicalByName.get(normalized);
        }

        private static String normalizeStatic(String identifier) {
            return identifier == null
                    ? ""
                    : identifier.replace("`", "").replace("\"", "").trim().toUpperCase(Locale.ROOT);
        }
    }
}
