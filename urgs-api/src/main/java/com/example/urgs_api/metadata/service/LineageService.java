package com.example.urgs_api.metadata.service;

import org.neo4j.driver.Driver;
import org.neo4j.driver.Session;
import org.neo4j.driver.Result;
import org.neo4j.driver.types.Node;
import org.neo4j.driver.types.Relationship;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import com.alibaba.excel.EasyExcel;
import com.example.urgs_api.metadata.dto.LineageExportDTO;
import com.example.urgs_api.metadata.dto.LineageRelationEvidenceRequest;

@Service
/**
 * 血缘服务类
 * 负责与图数据库交互，提供血缘分析、搜索和追溯功能
 */
public class LineageService {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(LineageService.class);
    private static final int CLEAR_RELATIONSHIP_BATCH_SIZE = 2000;
    private static final int CLEAR_NODE_BATCH_SIZE = 2000;

    // 所有血缘关系类型
    private static final List<String> ALL_LINEAGE_RELATION_TYPES = Arrays.asList(
            "DERIVES_TO", "FILTERS", "JOINS", "GROUPS", "ORDERS", "DISTRIBUTES", "CLUSTERS",
            "CALLS", "REFERENCES", "CASE_WHEN");

    @Autowired
    private Driver driver;

    /**
     * 清空 Neo4j 数据库中的所有节点和关系
     */
    public Map<String, Object> clearAll() {
        Map<String, Object> result = new HashMap<>();
        try (Session session = driver.session()) {
            // 先分批删除关系，再删除孤立节点，避免 DETACH DELETE 在高密度图上一批事务占用过多内存。
            String deleteRelationshipsQuery = "MATCH ()-[r]->() WITH r LIMIT $batchSize DELETE r RETURN count(*) AS deleted";
            String deleteNodesQuery = "MATCH (n) WITH n LIMIT $batchSize DELETE n RETURN count(*) AS deleted";
            long totalRelationshipsDeleted = 0;
            long totalDeleted = 0;
            while (true) {
                Result res = session.run(deleteRelationshipsQuery, Map.of("batchSize", CLEAR_RELATIONSHIP_BATCH_SIZE));
                long deleted = res.single().get("deleted").asLong();
                totalRelationshipsDeleted += deleted;
                if (deleted == 0) break;
            }
            while (true) {
                Result res = session.run(deleteNodesQuery, Map.of("batchSize", CLEAR_NODE_BATCH_SIZE));
                long deleted = res.single().get("deleted").asLong();
                totalDeleted += deleted;
                if (deleted == 0) break;
            }
            log.info("Neo4j 数据库已清空，共删除 {} 个节点、{} 条关系", totalDeleted, totalRelationshipsDeleted);
            result.put("success", true);
            result.put("message", "数据库已清空，共删除 " + totalDeleted + " 个节点、" + totalRelationshipsDeleted + " 条关系");
            result.put("deletedCount", totalDeleted);
            result.put("deletedRelationshipCount", totalRelationshipsDeleted);
        } catch (Exception e) {
            log.error("清空 Neo4j 数据库失败", e);
            result.put("success", false);
            result.put("message", "清空失败: " + e.getMessage());
        }
        return result;
    }

    /**
     * 搜索表
     * 
     * @param keyword 关键词
     * @return 表及其列的列表
     */
    /**
     * Search tables with pagination
     * 
     * @param keyword Search keyword
     * @param page    Page number (1-based)
     * @param size    Page size
     * @param ownerName Optional owner/schema filter for table pagination
     * @return Map containing owner summaries and paginated table list
     */
    public Map<String, Object> searchTables(String keyword, int page, int size, String ownerName) {
        int queryPage = Math.max(1, page);
        int querySize = Math.min(Math.max(1, size), 100);
        int skip = (queryPage - 1) * querySize;
        String normalizedKeyword = keyword == null ? "" : keyword.trim().toUpperCase(Locale.ROOT);
        String normalizedOwner = ownerName == null ? "" : ownerName.trim().toUpperCase(Locale.ROOT);
        String ownerExpression = "toUpper(coalesce(n.owner, coalesce(n.schema, coalesce(n.user, coalesce(n.default_user, 'DEFAULT')))))";
        String keywordFilter = "($keyword = '' OR "
                + "toUpper(coalesce(n.name, '')) CONTAINS $keyword OR "
                + "toUpper(coalesce(n.qualifiedName, '')) CONTAINS $keyword OR "
                + ownerExpression + " CONTAINS $keyword OR EXISTS { "
                + "MATCH (matchedColumn:Column)-[:BELONGS_TO]->(n) "
                + "WHERE toUpper(coalesce(matchedColumn.name, '')) CONTAINS $keyword })";
        String ownerFilter = "($ownerName = '' OR " + ownerExpression + " = $ownerName)";
        Map<String, Object> queryParams = Map.of(
                "keyword", normalizedKeyword,
                "ownerName", normalizedOwner,
                "skip", skip,
                "size", querySize);

        String ownerSummaryQuery = "MATCH (n:Table) WHERE " + keywordFilter + " "
                + "WITH " + ownerExpression + " AS ownerName, count(DISTINCT n) AS tableCount "
                + "RETURN ownerName, tableCount ORDER BY ownerName";
        String countQuery = "MATCH (n:Table) WHERE " + keywordFilter + " AND " + ownerFilter + " "
                + "RETURN count(DISTINCT n) AS total";
        String dataQuery = "MATCH (n:Table) WHERE " + keywordFilter + " AND " + ownerFilter + " "
                + "WITH n, " + ownerExpression + " AS ownerSort, toUpper(coalesce(n.name, '')) AS tableSort "
                + "ORDER BY ownerSort, tableSort SKIP $skip LIMIT $size "
                + "OPTIONAL MATCH (c:Column)-[:BELONGS_TO]->(n) "
                + "RETURN properties(n) AS tableProps, ownerSort, tableSort, collect(DISTINCT c.name) AS columns "
                + "ORDER BY ownerSort, tableSort";

        List<Map<String, Object>> list = new ArrayList<>();
        List<Map<String, Object>> groupedOwners = new ArrayList<>();
        long total;
        long allOwnerTotal = 0;
        try (Session session = driver.session()) {
            Result ownerResult = session.run(ownerSummaryQuery, queryParams);
            while (ownerResult.hasNext()) {
                var record = ownerResult.next();
                long tableCount = record.get("tableCount").asLong();
                allOwnerTotal += tableCount;
                Map<String, Object> group = new LinkedHashMap<>();
                group.put("ownerName", record.get("ownerName").asString("DEFAULT"));
                group.put("tableCount", tableCount);
                group.put("tables", Collections.emptyList());
                groupedOwners.add(group);
            }
            total = session.run(countQuery, queryParams).single().get("total").asLong();
            Result dataResult = session.run(dataQuery, queryParams);
            while (dataResult.hasNext()) {
                var record = dataResult.next();
                Map<String, Object> tableProps = record.get("tableProps").asMap();
                String rawName = toSafeUpperString(tableProps.get("name"));
                String itemOwnerName = resolveOwnerName(tableProps, rawName);
                String itemTableName = resolveTableName(tableProps, rawName);
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("ownerName", itemOwnerName);
                item.put("tableName", itemTableName);
                item.put("qualifiedName", buildQualifiedName(itemOwnerName, itemTableName));
                item.put("objectUid", tableProps.get("objectUid"));
                item.put("dataSourceId", tableProps.get("dataSourceId"));
                item.put("columns", record.get("columns").asList(value -> value.isNull() ? null : value.asString()).stream()
                        .filter(Objects::nonNull).sorted().toList());
                list.add(item);
            }
        }
        if (!normalizedOwner.isEmpty()) {
            groupedOwners.stream()
                    .filter(group -> normalizedOwner.equals(group.get("ownerName")))
                    .findFirst()
                    .ifPresent(group -> group.put("tables", list));
        }

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("total", allOwnerTotal);
        response.put("selectedOwnerTotal", total);
        response.put("list", list);
        response.put("groupedList", groupedOwners);
        response.put("totalOwners", groupedOwners.size());
        response.put("selectedOwner", normalizedOwner);
        response.put("page", queryPage);
        response.put("size", querySize);
        return response;
    }

    public Map<String, Object> searchNodes(String keyword, int page, int size,
            List<String> nodeTypes, String status) {
        int queryPage = Math.max(1, page);
        int querySize = Math.min(Math.max(1, size), 100);
        List<String> normalizedTypes = normalizeNodeTypes(nodeTypes);
        Map<String, Object> params = Map.of(
                "keyword", keyword == null ? "" : keyword.trim().toUpperCase(Locale.ROOT),
                "status", status == null ? "" : status.trim().toUpperCase(Locale.ROOT),
                "types", normalizedTypes,
                "skip", (queryPage - 1) * querySize,
                "size", querySize);
        String unionQuery = buildNodeSearchUnion();
        String filteredQuery = "CALL { " + unionQuery + " } "
                + "WITH n, nodeType, displayName, qualifiedName, ownerName "
                + "WHERE ($status = '' OR toUpper(coalesce(n.status, coalesce(n.parseStatus, ''))) = $status) ";
        String countQuery = filteredQuery + "RETURN count(*) AS total";
        String dataQuery = filteredQuery
                + "RETURN elementId(n) AS id, nodeType, displayName, qualifiedName, ownerName, "
                + "labels(n) AS labels, properties(n) AS properties "
                + "ORDER BY nodeType, displayName SKIP $skip LIMIT $size";

        List<Map<String, Object>> items = new ArrayList<>();
        long total;
        try (Session session = driver.session()) {
            total = session.run(countQuery, params).single().get("total").asLong();
            Result result = session.run(dataQuery, params);
            while (result.hasNext()) {
                var record = result.next();
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("id", record.get("id").asString());
                item.put("nodeType", record.get("nodeType").asString());
                item.put("displayName", record.get("displayName").asString(""));
                item.put("qualifiedName", record.get("qualifiedName").asString(""));
                item.put("ownerName", record.get("ownerName").asString(""));
                item.put("labels", record.get("labels").asList(value -> value.asString()));
                item.put("properties", record.get("properties").asMap());
                items.add(item);
            }
        }
        return Map.of(
                "total", total,
                "page", queryPage,
                "size", querySize,
                "list", items);
    }

    public Map<String, Object> getNodeDetails(String elementId) {
        String relationTypes = String.join("|", ALL_LINEAGE_RELATION_TYPES);
        String query = "MATCH (n) WHERE elementId(n) = $elementId "
                + "OPTIONAL MATCH (n)-[out:" + relationTypes + "]->() "
                + "WITH n, count(DISTINCT out) AS downstreamCount "
                + "OPTIONAL MATCH ()-[incoming:" + relationTypes + "]->(n) "
                + "RETURN elementId(n) AS id, labels(n) AS labels, properties(n) AS properties, "
                + "downstreamCount, count(DISTINCT incoming) AS upstreamCount";
        try (Session session = driver.session()) {
            Result result = session.run(query, Map.of("elementId", elementId));
            if (!result.hasNext()) {
                return Collections.emptyMap();
            }
            var record = result.next();
            return Map.of(
                    "id", record.get("id").asString(),
                    "labels", record.get("labels").asList(value -> value.asString()),
                    "properties", record.get("properties").asMap(),
                    "upstreamCount", record.get("upstreamCount").asLong(),
                    "downstreamCount", record.get("downstreamCount").asLong());
        }
    }

    public Map<String, Object> getRelationDetails(String elementId) {
        String query = "MATCH (source)-[r]->(target) WHERE elementId(r) = $elementId "
                + "OPTIONAL MATCH (fact:LineageFact {relationUid: r.relationUid})-[:IN_STATEMENT]->(stmt:SqlStatement) "
                + "RETURN elementId(r) AS id, type(r) AS type, properties(r) AS properties, "
                + "elementId(source) AS sourceId, properties(source) AS sourceProperties, "
                + "elementId(target) AS targetId, properties(target) AS targetProperties, "
                + "properties(fact) AS fact, properties(stmt) AS statement LIMIT 1";
        try (Session session = driver.session()) {
            Result result = session.run(query, Map.of("elementId", elementId));
            if (!result.hasNext()) {
                return Collections.emptyMap();
            }
            var record = result.next();
            Map<String, Object> details = new LinkedHashMap<>();
            details.put("id", record.get("id").asString());
            details.put("type", record.get("type").asString());
            details.put("properties", record.get("properties").asMap());
            details.put("sourceId", record.get("sourceId").asString());
            details.put("sourceProperties", record.get("sourceProperties").asMap());
            details.put("targetId", record.get("targetId").asString());
            details.put("targetProperties", record.get("targetProperties").asMap());
            details.put("fact", record.get("fact").isNull() ? Collections.emptyMap() : record.get("fact").asMap());
            details.put("statement", record.get("statement").isNull() ? Collections.emptyMap() : record.get("statement").asMap());
            return details;
        }
    }

    public List<Map<String, Object>> getRelationEvidence(LineageRelationEvidenceRequest request) {
        if (request == null) {
            return Collections.emptyList();
        }
        List<String> statementUids = normalizeEvidenceStatementUids(request.getStatementUids());
        if (statementUids.isEmpty() && hasText(request.getRelationId())) {
            statementUids = loadRelationStatementUids(request.getRelationId());
        }
        if (statementUids.isEmpty()) {
            return Collections.emptyList();
        }

        String relationType = normalizeUpper(request.getRelationType());
        if (!ALL_LINEAGE_RELATION_TYPES.contains(relationType)) {
            relationType = "";
        }
        String query = "MATCH (stmt:SqlStatement) "
                + "WHERE stmt.statementUid IN $statementUids "
                + "OPTIONAL MATCH (fact:LineageFact)-[:IN_STATEMENT]->(stmt) "
                + "WHERE ($sourceTable = '' OR toUpper(coalesce(fact.sourceTable, '')) = $sourceTable) "
                + "  AND ($sourceColumn = '' OR toUpper(coalesce(fact.sourceColumn, '')) = $sourceColumn) "
                + "  AND ($targetTable = '' OR toUpper(coalesce(fact.targetTable, '')) = $targetTable) "
                + "  AND ($targetColumn = '' OR toUpper(coalesce(fact.targetColumn, '')) = $targetColumn) "
                + "  AND ($relationType = '' OR toUpper(coalesce(fact.relationType, '')) = $relationType) "
                + "RETURN stmt.statementUid AS statementUid, "
                + "       coalesce(stmt.statementHash, '') AS statementHash, "
                + "       coalesce(stmt.statementIndex, 0) AS statementIndex, "
                + "       coalesce(stmt.sqlText, '') AS snippet, "
                + "       coalesce(stmt.sourceFiles, []) AS sourceFiles, "
                + "       [value IN collect(DISTINCT coalesce(fact.sourceColumn, '')) WHERE value <> ''] AS sourceColumns, "
                + "       [value IN collect(DISTINCT coalesce(fact.targetColumn, '')) WHERE value <> ''] AS targetColumns, "
                + "       [value IN collect(DISTINCT coalesce(fact.relationType, '')) WHERE value <> ''] AS relationTypes, "
                + "       [value IN collect(DISTINCT coalesce(fact.confidence, '')) WHERE value <> ''] AS confidences, "
                + "       [value IN collect(DISTINCT coalesce(fact.ambiguityCode, '')) WHERE value <> ''] AS ambiguityCodes "
                + "ORDER BY coalesce(sourceFiles[0], ''), statementIndex, statementUid";
        Map<String, Object> params = new HashMap<>();
        params.put("statementUids", statementUids);
        params.put("sourceTable", normalizeUpper(request.getSourceTable()));
        params.put("sourceColumn", normalizeUpper(request.getSourceColumn()));
        params.put("targetTable", normalizeUpper(request.getTargetTable()));
        params.put("targetColumn", normalizeUpper(request.getTargetColumn()));
        params.put("relationType", relationType);

        List<Map<String, Object>> evidence = new ArrayList<>();
        try (Session session = driver.session()) {
            Result result = session.run(query, params);
            while (result.hasNext()) {
                var record = result.next();
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("statementUid", record.get("statementUid").asString(""));
                item.put("statementHash", record.get("statementHash").asString(""));
                item.put("statementIndex", record.get("statementIndex").asLong(0));
                item.put("snippet", record.get("snippet").asString(""));
                item.put("sourceFiles", record.get("sourceFiles").asList(value -> value.asString("")));
                item.put("sourceColumns", record.get("sourceColumns").asList(value -> value.asString("")));
                item.put("targetColumns", record.get("targetColumns").asList(value -> value.asString("")));
                item.put("relationTypes", record.get("relationTypes").asList(value -> value.asString("")));
                item.put("confidences", record.get("confidences").asList(value -> value.asString("")));
                item.put("ambiguityCodes", record.get("ambiguityCodes").asList(value -> value.asString("")));
                evidence.add(item);
            }
        }
        return evidence;
    }

    private List<String> loadRelationStatementUids(String relationId) {
        String query = "MATCH ()-[r]->() WHERE elementId(r) = $relationId "
                + "RETURN CASE "
                + "  WHEN size(coalesce(r.statementUids, [])) > 0 THEN r.statementUids "
                + "  WHEN coalesce(r.statementUid, '') <> '' THEN [r.statementUid] "
                + "  ELSE [] END AS statementUids";
        try (Session session = driver.session()) {
            Result result = session.run(query, Map.of("relationId", relationId));
            if (!result.hasNext()) {
                return Collections.emptyList();
            }
            return normalizeEvidenceStatementUids(
                    result.next().get("statementUids").asList(value -> value.asString("")));
        }
    }

    private List<String> normalizeEvidenceStatementUids(List<String> values) {
        if (values == null || values.isEmpty()) {
            return Collections.emptyList();
        }
        return values.stream()
                .filter(this::hasText)
                .map(String::trim)
                .distinct()
                .toList();
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private String normalizeUpper(String value) {
        return hasText(value) ? value.trim().toUpperCase(Locale.ROOT) : "";
    }

    private List<String> normalizeNodeTypes(List<String> nodeTypes) {
        Set<String> allowed = Set.of("TABLE", "COLUMN", "SQL_TASK", "ANALYSIS");
        if (nodeTypes == null || nodeTypes.isEmpty()) {
            return new ArrayList<>(allowed);
        }
        List<String> normalized = nodeTypes.stream()
                .filter(Objects::nonNull)
                .map(value -> value.trim().toUpperCase(Locale.ROOT))
                .filter(allowed::contains)
                .distinct()
                .toList();
        return normalized.isEmpty() ? new ArrayList<>(allowed) : normalized;
    }

    private String buildNodeSearchUnion() {
        return "MATCH (n:Table) WHERE 'TABLE' IN $types AND ($keyword = '' OR "
                + "toUpper(coalesce(n.name, '')) CONTAINS $keyword OR toUpper(coalesce(n.qualifiedName, '')) CONTAINS $keyword) "
                + "RETURN n, 'TABLE' AS nodeType, coalesce(n.name, '') AS displayName, "
                + "coalesce(n.qualifiedName, n.name, '') AS qualifiedName, coalesce(n.owner, n.schema, '') AS ownerName "
                + "UNION ALL MATCH (n:Column) WHERE 'COLUMN' IN $types AND ($keyword = '' OR "
                + "toUpper(coalesce(n.name, '')) CONTAINS $keyword OR toUpper(coalesce(n.table, '')) CONTAINS $keyword) "
                + "RETURN n, 'COLUMN' AS nodeType, coalesce(n.name, '') AS displayName, "
                + "coalesce(n.table, '') + '.' + coalesce(n.name, '') AS qualifiedName, '' AS ownerName "
                + "UNION ALL MATCH (n:SqlStatement) WHERE 'SQL_TASK' IN $types AND ($keyword = '' OR "
                + "toUpper(coalesce(n.sqlText, '')) CONTAINS $keyword OR "
                + "any(file IN coalesce(n.sourceFiles, []) WHERE toUpper(file) CONTAINS $keyword)) "
                + "RETURN n, 'SQL_TASK' AS nodeType, coalesce(n.sourceFiles[0], n.statementUid, '') AS displayName, "
                + "coalesce(n.statementUid, '') AS qualifiedName, '' AS ownerName "
                + "UNION ALL MATCH (n:LineageAnalysis) WHERE 'ANALYSIS' IN $types AND ($keyword = '' OR "
                + "toUpper(coalesce(n.sourceFile, '')) CONTAINS $keyword OR toUpper(coalesce(n.error, '')) CONTAINS $keyword) "
                + "RETURN n, 'ANALYSIS' AS nodeType, coalesce(n.sourceFile, n.analysisUid, '') AS displayName, "
                + "coalesce(n.analysisUid, '') AS qualifiedName, '' AS ownerName";
    }

    /**
     * 获取血缘图数据
     * 
     * @param tableName  表名
     * @param columnName 列名（可选）
     * @param depth      深度
     * @return 图节点和边数据
     */
    /**
     * 获取血缘图数据
     * 
     * @param tableName  表名
     * @param columnName 列名（可选）
     * @param depth      深度
     * @return 图节点和边数据
     */
    public Map<String, Object> getGraphData(String tableName, String qualifiedName, String columnName, int depth) {
        return getGraphData(tableName, qualifiedName, columnName, depth, "both", 1000, "column");
    }

    public Map<String, Object> getGraphData(String tableName, String qualifiedName, String columnName, int depth,
            String direction, int limit, String relationLevel) {
        return getGraphData(tableName, qualifiedName, null, columnName, depth, direction, limit, relationLevel);
    }

    public Map<String, Object> getGraphData(String tableName, String qualifiedName, String objectUid,
            String columnName, int depth, String direction, int limit, String relationLevel) {
        String baseStart;
        Map<String, Object> params = new HashMap<>();

        String normalizedQualifiedName = (qualifiedName != null) ? qualifiedName.toUpperCase() : "";
        String normalizedTableName = (tableName != null) ? tableName.toUpperCase() : "";
        String normalizedColumnName = (columnName != null && !columnName.isEmpty()) ? columnName.toUpperCase() : null;
        String resolvedTableName = normalizedTableName;
        String resolvedOwnerName = "";

        if (!normalizedQualifiedName.isEmpty()) {
            String[] qualifiedParts = splitQualifiedName(normalizedQualifiedName);
            resolvedOwnerName = qualifiedParts[0];
            resolvedTableName = qualifiedParts[1];
        } else if (normalizedTableName.contains(".")) {
            String[] qualifiedParts = splitQualifiedName(normalizedTableName);
            resolvedOwnerName = qualifiedParts[0];
            resolvedTableName = qualifiedParts[1];
        }

        params.put("tableName", resolvedTableName);
        params.put("ownerName", resolvedOwnerName);
        params.put("qualifiedName", buildQualifiedName(resolvedOwnerName, resolvedTableName));
        params.put("objectUid", objectUid == null ? "" : objectUid.trim());

        int queryDepth = normalizeDepth(depth);
        int queryLimit = normalizeLimit(limit);
        String normalizedDirection = normalizeDirection(direction);
        String normalizedRelationLevel = normalizeRelationLevel(relationLevel, normalizedColumnName);
        params.put("rowLimit", queryLimit + 1);

        if (normalizedColumnName != null) {
            params.put("colName", normalizedColumnName);
            baseStart = buildTableMatchClause("t") +
                    "MATCH (t)<-[:BELONGS_TO]-(c:Column) WHERE toUpper(c.name) = $colName WITH c as startNode ";
        } else {
            baseStart = buildTableMatchClause("n") +
                    "OPTIONAL MATCH (n)<-[:BELONGS_TO]-(c:Column) " +
                    "WITH n, collect(c) + n as startNodes UNWIND startNodes as startNode ";
        }

        String allRelTypes = String.join("|", ALL_LINEAGE_RELATION_TYPES);

        if ("table".equals(normalizedRelationLevel)) {
            return getTableLevelGraphData(baseStart, params, allRelTypes, queryDepth, normalizedDirection, queryLimit);
        }

        // Optimized Query:
        // 1. Use variable length path with specified depth
        // 2. UNWIND relationships and return DISTINCT to avoid combinatorial explosion
        // of paths
        String lineageQuery = buildColumnLineageQuery(baseStart, allRelTypes, queryDepth, normalizedDirection);

        Map<String, Object> graph = new HashMap<>();
        List<Map<String, Object>> nodes = new ArrayList<>();
        List<Map<String, Object>> edges = new ArrayList<>();
        Set<String> seenNodes = new HashSet<>();
        Set<String> seenEdges = new HashSet<>();
        Set<String> columnElementIds = new HashSet<>();
        boolean truncated = false;

        try (Session session = driver.session()) {
            Result result = session.run(lineageQuery, params);
            while (result.hasNext()) {
                var record = result.next();
                if (seenEdges.size() >= queryLimit) {
                    truncated = true;
                    break;
                }
                Relationship rel = record.get("r").asRelationship();
                Node source = record.get("source").asNode();
                Node target = record.get("target").asNode();

                addNode(source, nodes, seenNodes);
                addNode(target, nodes, seenNodes);
                addEdge(rel, edges, seenEdges);

                if (source.hasLabel("Column"))
                    columnElementIds.add(source.elementId());
                if (target.hasLabel("Column"))
                    columnElementIds.add(target.elementId());
            }

            // Enrichment: Fetch Tables for all found Columns
            if (!columnElementIds.isEmpty()) {
                // Batch processing for enrichment if too many columns
                List<String> allIds = new ArrayList<>(columnElementIds);
                int batchSize = 1000;
                for (int i = 0; i < allIds.size(); i += batchSize) {
                    List<String> batchIds = allIds.subList(i, Math.min(i + batchSize, allIds.size()));

                    String enrichQuery = "MATCH (c:Column)-[r:BELONGS_TO]->(t:Table) WHERE elementId(c) IN $ids RETURN c, r, t";
                    Result enrichResult = session.run(enrichQuery, Map.of("ids", batchIds));
                    while (enrichResult.hasNext()) {
                        var record = enrichResult.next();
                        addNode(record.get("t").asNode(), nodes, seenNodes);
                        // c is already added, but good to be safe
                        addNode(record.get("c").asNode(), nodes, seenNodes);
                        addEdge(record.get("r").asRelationship(), edges, seenEdges);
                    }

                    // Indirect edges
                    String indirectRelTypes = "FILTERS|JOINS|GROUPS|ORDERS";
                    String indirectEdgesQuery = "MATCH (c:Column)-[r:" + indirectRelTypes + "]->(t:Table) " +
                            "WHERE elementId(c) IN $ids RETURN c, r, t";
                    Result indirectResult = session.run(indirectEdgesQuery, Map.of("ids", batchIds));
                    while (indirectResult.hasNext()) {
                        var record = indirectResult.next();
                        addNode(record.get("c").asNode(), nodes, seenNodes);
                        addNode(record.get("t").asNode(), nodes, seenNodes);
                        addEdge(record.get("r").asRelationship(), edges, seenEdges);
                    }
                }
            }
        }

        graph.put("nodes", nodes);
        graph.put("edges", edges);
        graph.put("truncated", truncated);
        graph.put("totalNodes", nodes.size());
        graph.put("totalEdges", edges.size());
        graph.put("limit", queryLimit);
        graph.put("depth", queryDepth);
        graph.put("direction", normalizedDirection);
        graph.put("relationLevel", normalizedRelationLevel);
        return graph;
    }

    private Map<String, Object> getTableLevelGraphData(String baseStart, Map<String, Object> params,
            String allRelTypes, int queryDepth, String direction, int queryLimit) {
        Map<String, Object> graph = new HashMap<>();
        List<Map<String, Object>> nodes = new ArrayList<>();
        List<Map<String, Object>> edges = new ArrayList<>();
        Set<String> seenNodes = new HashSet<>();
        Set<String> seenEdges = new HashSet<>();
        boolean truncated = false;

        String query = buildTableLineageQuery(baseStart, allRelTypes, queryDepth, direction);

        try (Session session = driver.session()) {
            Result result = session.run(query, params);
            while (result.hasNext()) {
                var record = result.next();
                if (seenEdges.size() >= queryLimit) {
                    truncated = true;
                    break;
                }

                Node sourceTable = record.get("sourceTable").asNode();
                Node targetTable = record.get("targetTable").asNode();
                String relType = record.get("relType").asString("DERIVES_TO");
                long relationCount = record.get("relationCount").asLong(1);
                String snippet = record.get("snippet").asString("");
                List<String> sourceFiles = record.get("sourceFiles").asList(value -> value.asString());
                List<String> sourceColumns = record.get("sourceColumns").asList(value -> value.asString());
                List<String> targetColumns = record.get("targetColumns").asList(value -> value.asString());
                long fallbackCount = record.get("fallbackCount").asLong(0);
                long snippetCount = record.get("snippetCount").asLong(0);
                List<String> relationLevels = record.get("relationLevels").asList(value -> value.asString());
                List<String> lineageOrigins = record.get("lineageOrigins").asList(value -> value.asString());
                List<String> statementUids = record.get("statementUids").asList(value -> value.asString()).stream()
                        .filter(this::hasText)
                        .distinct()
                        .toList();

                addNode(sourceTable, nodes, seenNodes);
                addNode(targetTable, nodes, seenNodes);
                addTableEdge(sourceTable, targetTable, relType, relationCount, snippet, sourceFiles,
                        sourceColumns, targetColumns, fallbackCount, snippetCount, relationLevels, lineageOrigins,
                        statementUids,
                        edges, seenEdges);
            }
        }

        graph.put("nodes", nodes);
        graph.put("edges", edges);
        graph.put("truncated", truncated);
        graph.put("totalNodes", nodes.size());
        graph.put("totalEdges", edges.size());
        graph.put("limit", queryLimit);
        graph.put("depth", queryDepth);
        graph.put("direction", direction);
        graph.put("relationLevel", "table");
        return graph;
    }

    private String buildColumnLineageQuery(String baseStart, String allRelTypes, int queryDepth, String direction) {
        List<String> branches = new ArrayList<>();
        if ("downstream".equals(direction) || "both".equals(direction)) {
            branches.add("WITH startNode MATCH p = (startNode)-[:" + allRelTypes + "*1.." + queryDepth + "]->(m) " +
                    "UNWIND relationships(p) as r RETURN DISTINCT r, startNode(r) as source, endNode(r) as target");
        }
        if ("upstream".equals(direction) || "both".equals(direction)) {
            branches.add("WITH startNode MATCH p = (startNode)<-[:" + allRelTypes + "*1.." + queryDepth + "]-(m) " +
                    "UNWIND relationships(p) as r RETURN DISTINCT r, startNode(r) as source, endNode(r) as target");
        }
        return baseStart +
                "CALL { " + String.join(" UNION ", branches) + " } " +
                "RETURN DISTINCT r, source, target LIMIT $rowLimit";
    }

    private String buildTableLineageQuery(String baseStart, String allRelTypes, int queryDepth, String direction) {
        List<String> branches = new ArrayList<>();
        if ("downstream".equals(direction) || "both".equals(direction)) {
            branches.add("WITH startNode MATCH p = (startNode)-[:" + allRelTypes + "*1.." + queryDepth + "]->(m) " +
                    "UNWIND relationships(p) as r RETURN DISTINCT r, startNode(r) as source, endNode(r) as target");
        }
        if ("upstream".equals(direction) || "both".equals(direction)) {
            branches.add("WITH startNode MATCH p = (startNode)<-[:" + allRelTypes + "*1.." + queryDepth + "]-(m) " +
                    "UNWIND relationships(p) as r RETURN DISTINCT r, startNode(r) as source, endNode(r) as target");
        }

        return baseStart +
                "CALL { " + String.join(" UNION ", branches) + " } " +
                "OPTIONAL MATCH (source)-[:BELONGS_TO]->(sourceParent:Table) " +
                "OPTIONAL MATCH (target)-[:BELONGS_TO]->(targetParent:Table) " +
                "WITH coalesce(sourceParent, source) as sourceTable, coalesce(targetParent, target) as targetTable, source, target, r " +
                "WHERE sourceTable:Table AND targetTable:Table AND elementId(sourceTable) <> elementId(targetTable) " +
                "WITH sourceTable, targetTable, type(r) AS relType, " +
                "     count(DISTINCT elementId(r)) AS relationCount, " +
                "     count(DISTINCT CASE WHEN coalesce(r.relationLevel, '') = 'table_fallback' OR coalesce(r.isTableFallback, false) OR coalesce(r.hasTableFallback, false) OR 'table_fallback' IN coalesce(r.relationLevels, []) THEN elementId(r) END) AS fallbackCount, " +
                "     count(DISTINCT CASE WHEN coalesce(r.snippet, '') <> '' THEN elementId(r) END) AS snippetCount, " +
                "     collect(DISTINCT CASE WHEN source:Column THEN coalesce(source.name, '') ELSE '' END) AS nodeSourceColumns, " +
                "     collect(DISTINCT CASE WHEN target:Column THEN coalesce(target.name, '') ELSE '' END) AS nodeTargetColumns, " +
                "     collect(coalesce(r.sourceColumns, [])) AS relationSourceColumnGroups, " +
                "     collect(coalesce(r.targetColumns, [])) AS relationTargetColumnGroups, " +
                "     collect(DISTINCT coalesce(r.sourceColumn, '')) AS relationSourceColumnNames, " +
                "     collect(DISTINCT coalesce(r.targetColumn, '')) AS relationTargetColumnNames, " +
                "     collect(DISTINCT coalesce(r.relationLevel, '')) AS relationLevels, " +
                "     collect(coalesce(r.relationLevels, [])) AS relationLevelGroups, " +
                "     collect(DISTINCT coalesce(r.lineageOrigin, '')) AS lineageOrigins, " +
                "     collect(coalesce(r.lineageOrigins, [])) AS lineageOriginGroups, " +
                "     collect(CASE WHEN size(coalesce(r.statementUids, [])) > 0 THEN r.statementUids WHEN coalesce(r.statementUid, '') <> '' THEN [r.statementUid] ELSE [] END) AS statementUidGroups, " +
                "     collect(DISTINCT coalesce(r.snippet, '')) AS snippets, " +
                "     collect(coalesce(r.sourceFiles, [])) AS sourceFileGroups, " +
                "     collect(DISTINCT coalesce(r.source_file, coalesce(r.sourceFile, ''))) AS sourceFileNames " +
                "RETURN sourceTable, targetTable, relType, relationCount, fallbackCount, snippetCount, " +
                "       [column IN nodeSourceColumns + reduce(columns = [], group IN relationSourceColumnGroups | columns + group) + [column IN relationSourceColumnNames WHERE column <> ''] WHERE column <> ''] AS sourceColumns, " +
                "       [column IN nodeTargetColumns + reduce(columns = [], group IN relationTargetColumnGroups | columns + group) + [column IN relationTargetColumnNames WHERE column <> ''] WHERE column <> ''] AS targetColumns, " +
                "       [level IN relationLevels + reduce(levels = [], group IN relationLevelGroups | levels + group) WHERE level <> ''] AS relationLevels, " +
                "       [origin IN lineageOrigins + reduce(origins = [], group IN lineageOriginGroups | origins + group) WHERE origin <> ''] AS lineageOrigins, " +
                "       reduce(statementUids = [], group IN statementUidGroups | statementUids + group) AS statementUids, " +
                "       [snippet IN snippets WHERE snippet <> ''][0] AS snippet, " +
                "       reduce(files = [], group IN sourceFileGroups | files + group) + [file IN sourceFileNames WHERE file <> ''] AS sourceFiles " +
                "ORDER BY relationCount DESC " +
                "LIMIT $rowLimit";
    }

    /**
     * 影响分析 - 返回所有类型的下游依赖
     * 
     * @param tableName  表名
     * @param columnName 列名
     * @param version    版本
     * @param depth      深度
     * @param types      关系类型列表
     * @return 路径图数据
     */
    public Map<String, Object> getImpactAnalysis(String tableName, String columnName,
            String objectUid, String version, int depth, int limit, List<String> types) {
        List<String> relationTypes = types == null ? Collections.emptyList() : types.stream()
                .filter(Objects::nonNull)
                .map(value -> value.trim().toUpperCase(Locale.ROOT))
                .filter(ALL_LINEAGE_RELATION_TYPES::contains)
                .distinct()
                .toList();
        if (relationTypes.isEmpty()) {
            relationTypes = ALL_LINEAGE_RELATION_TYPES;
        }
        String relTypesStr = String.join("|", relationTypes);
        int queryDepth = normalizeDepth(depth);
        int queryLimit = normalizeLimit(limit);

        // 预处理表名和列名为大写，以匹配索引
        String normalizedTableName = (tableName != null) ? tableName.toUpperCase() : "";
        String normalizedColumnName = (columnName != null) ? columnName.toUpperCase() : "";

        Map<String, Object> params = new HashMap<>();
        params.put("tableName", normalizedTableName);
        params.put("columnName", normalizedColumnName);
        params.put("objectUid", objectUid == null ? "" : objectUid.trim());
        params.put("pathLimit", queryLimit + 1);

        // 构建版本过滤条件
        String versionFilter = "";
        if (version != null && !version.isEmpty()) {
            versionFilter = "WHERE ALL(rel IN relationships(path) WHERE rel.version = $version)";
            params.put("version", version);
        }

        String query = buildColumnStartClause(objectUid) + String.format(
                "MATCH path = (c)-[:%s*1..%d]->(downstream:Column) " +
                        "%s RETURN path LIMIT $pathLimit",
                relTypesStr, queryDepth, versionFilter);

        return executePathQuery(query, params, queryLimit);
    }

    /**
     * 血缘追溯 - 只返回直接数据流 (DERIVES_TO)
     * 
     * @param tableName  表名
     * @param columnName 列名
     * @param direction  方向 (upstream/downstream)
     * @param version    版本
     * @param depth      深度
     * @return 路径图数据
     */
    public Map<String, Object> getLineageTrace(String tableName, String columnName,
            String objectUid, String direction, String version, int depth, int limit) {
        // 预处理表名和列名为大写，以匹配索引
        String normalizedTableName = (tableName != null) ? tableName.toUpperCase() : "";
        String normalizedColumnName = (columnName != null) ? columnName.toUpperCase() : "";

        Map<String, Object> params = new HashMap<>();
        params.put("tableName", normalizedTableName);
        params.put("columnName", normalizedColumnName);
        params.put("objectUid", objectUid == null ? "" : objectUid.trim());
        int queryDepth = normalizeDepth(depth);
        int queryLimit = normalizeLimit(limit);
        params.put("pathLimit", queryLimit + 1);

        String versionFilter = "";
        if (version != null && !version.isEmpty()) {
            versionFilter = "WHERE ALL(rel IN relationships(path) WHERE rel.version = $version)";
            params.put("version", version);
        }

        String query;
        String startClause = buildColumnStartClause(objectUid);
        if ("downstream".equals(direction)) {
            query = startClause + String.format(
                    "MATCH path = (c)-[:DERIVES_TO*1..%d]->(downstream:Column) "
                            +
                            "%s RETURN path LIMIT $pathLimit",
                    queryDepth, versionFilter);
        } else {
            // 上游 (默认)
            query = startClause + String.format(
                    "MATCH path = (upstream:Column)-[:DERIVES_TO*1..%d]->(c) "
                            +
                            "%s RETURN path LIMIT $pathLimit",
                    queryDepth, versionFilter);
        }

        return executePathQuery(query, params, queryLimit);
    }

    private String buildColumnStartClause(String objectUid) {
        if (objectUid != null && !objectUid.isBlank()) {
            return "MATCH (centerTable:Table {objectUid: $objectUid})<-[:BELONGS_TO]-(c:Column) "
                    + "WHERE toUpper(coalesce(c.name, '')) = $columnName WITH c ";
        }
        return "MATCH (c:Column {name: $columnName, table: $tableName}) ";
    }

    /**
     * 获取所有血缘版本
     * 
     * @return 版本列表
     */
    public List<Map<String, Object>> getLineageVersions() {
        List<Map<String, Object>> versions = new ArrayList<>();
        String query = "MATCH (v:LineageVersion) RETURN v.id as id, v.createdAt as createdAt, " +
                "v.sourceDirectory as sourceDirectory, v.description as description " +
                "ORDER BY v.createdAt DESC";

        try (Session session = driver.session()) {
            Result result = session.run(query);
            while (result.hasNext()) {
                var record = result.next();
                Map<String, Object> item = new HashMap<>();
                item.put("id", record.get("id").asString(null));
                item.put("createdAt", record.get("createdAt").isNull() ? null : record.get("createdAt").asString());
                item.put("sourceDirectory", record.get("sourceDirectory").asString(null));
                item.put("description", record.get("description").asString(null));
                versions.add(item);
            }
        }
        return versions;
    }

    /**
     * 执行路径查询并返回图数据
     */
    private Map<String, Object> executePathQuery(String query, Map<String, Object> params, int limit) {
        Map<String, Object> graph = new HashMap<>();
        List<Map<String, Object>> nodes = new ArrayList<>();
        List<Map<String, Object>> edges = new ArrayList<>();
        Set<String> seenNodes = new HashSet<>();
        Set<String> seenEdges = new HashSet<>();
        boolean truncated = false;

        try (Session session = driver.session()) {
            Result result = session.run(query, params);
            while (result.hasNext()) {
                if (seenEdges.size() >= limit) {
                    truncated = true;
                    break;
                }
                org.neo4j.driver.types.Path path = result.next().get("path").asPath();
                path.nodes().forEach(node -> addNode(node, nodes, seenNodes));
                path.relationships().forEach(rel -> addEdge(rel, edges, seenEdges));
            }
        }

        graph.put("nodes", nodes);
        graph.put("edges", edges);
        graph.put("truncated", truncated);
        graph.put("limit", limit);
        return graph;
    }

    private void addNode(Node node, List<Map<String, Object>> nodes, Set<String> seenNodes) {
        if (!seenNodes.contains(node.elementId())) {
            Map<String, Object> nodeData = new HashMap<>();
            nodeData.put("id", node.elementId());
            nodeData.put("elementId", node.elementId());
            nodeData.put("labels", node.labels());
            nodeData.put("properties", node.asMap());
            if (node.asMap().containsKey("name")) {
                nodeData.put("label", node.asMap().get("name"));
            }
            nodes.add(nodeData);
            seenNodes.add(node.elementId());
        }
    }

    private void addEdge(Relationship rel, List<Map<String, Object>> edges, Set<String> seenEdges) {
        if (!seenEdges.contains(rel.elementId())) {
            Map<String, Object> edgeData = new HashMap<>();
            Map<String, Object> properties = new HashMap<>(rel.asMap());
            List<String> statementUids = objectStringList(properties.get("statementUids"));
            if (statementUids.isEmpty() && hasText(Objects.toString(properties.get("statementUid"), ""))) {
                statementUids = List.of(Objects.toString(properties.get("statementUid")));
            }
            List<String> snippets = objectStringList(properties.get("snippets"));
            int evidenceCount = !statementUids.isEmpty()
                    ? statementUids.size()
                    : (!snippets.isEmpty() ? snippets.size()
                            : (hasText(Objects.toString(properties.get("snippet"), "")) ? 1 : 0));
            properties.put("statementUids", statementUids);
            properties.put("evidenceCount", evidenceCount);
            edgeData.put("id", rel.elementId());
            edgeData.put("source", rel.startNodeElementId());
            edgeData.put("target", rel.endNodeElementId());
            edgeData.put("type", rel.type());
            edgeData.put("properties", properties);
            edges.add(edgeData);
            seenEdges.add(rel.elementId());
        }
    }

    private void addTableEdge(Node sourceTable, Node targetTable, String relType, long relationCount,
            String snippet, List<String> sourceFiles, List<String> sourceColumns, List<String> targetColumns,
            long fallbackCount, long snippetCount, List<String> relationLevels, List<String> lineageOrigins,
            List<String> statementUids,
            List<Map<String, Object>> edges, Set<String> seenEdges) {
        String edgeId = sourceTable.elementId() + "::" + targetTable.elementId() + "::" + relType;
        if (!seenEdges.contains(edgeId)) {
            Map<String, Object> edgeData = new HashMap<>();
            Map<String, Object> properties = new HashMap<>();
            long fieldRelationCount = Math.max(0, relationCount - fallbackCount);
            String edgeRelationLevel = fallbackCount >= relationCount
                    ? "table_fallback"
                    : (fallbackCount > 0 ? "table_mixed" : "table");
            properties.put("relationCount", relationCount);
            properties.put("relationLevel", edgeRelationLevel);
            properties.put("fallbackRelationCount", fallbackCount);
            properties.put("fieldRelationCount", fieldRelationCount);
            properties.put("snippetCount", snippetCount);
            properties.put("statementUids", statementUids);
            properties.put("evidenceCount", statementUids.isEmpty() ? snippetCount : statementUids.size());
            properties.put("hasSnippet", snippetCount > 0 || (snippet != null && !snippet.isBlank()));
            properties.put("relationLevels", relationLevels.stream().filter(Objects::nonNull).distinct().toList());
            properties.put("lineageOrigins", lineageOrigins.stream().filter(Objects::nonNull).distinct().toList());
            properties.put("snippet", snippet);
            properties.put("sourceFiles", sourceFiles.stream().filter(Objects::nonNull).distinct().toList());
            properties.put("sourceColumns", sourceColumns.stream().filter(Objects::nonNull).distinct().toList());
            properties.put("targetColumns", targetColumns.stream().filter(Objects::nonNull).distinct().toList());

            edgeData.put("id", edgeId);
            edgeData.put("source", sourceTable.elementId());
            edgeData.put("target", targetTable.elementId());
            edgeData.put("type", relType);
            edgeData.put("properties", properties);
            edges.add(edgeData);
            seenEdges.add(edgeId);
        }
    }

    private List<String> objectStringList(Object value) {
        if (!(value instanceof Collection<?> collection)) {
            return Collections.emptyList();
        }
        return collection.stream()
                .filter(Objects::nonNull)
                .map(String::valueOf)
                .filter(this::hasText)
                .distinct()
                .toList();
    }

    private int normalizeDepth(int depth) {
        if (depth == -1) {
            return 30;
        }
        return Math.min(30, Math.max(1, depth));
    }

    private int normalizeLimit(int limit) {
        if (limit <= 0) {
            return 1000;
        }
        return Math.min(limit, 5000);
    }

    private String normalizeDirection(String direction) {
        if ("upstream".equalsIgnoreCase(direction)) {
            return "upstream";
        }
        if ("downstream".equalsIgnoreCase(direction)) {
            return "downstream";
        }
        return "both";
    }

    private String normalizeRelationLevel(String relationLevel, String normalizedColumnName) {
        if ("column".equalsIgnoreCase(relationLevel) || normalizedColumnName != null) {
            return "column";
        }
        return "table";
    }

    private String buildTableMatchClause(String alias) {
        return "MATCH (" + alias + ":Table) " +
                "WHERE (($objectUid <> '' AND coalesce(" + alias + ".objectUid, '') = $objectUid) " +
                "OR ($objectUid = '' AND (( $qualifiedName <> '' AND (" +
                "toUpper(coalesce(" + alias + ".qualifiedName, '')) = $qualifiedName " +
                "OR toUpper(coalesce(" + alias + ".name, '')) = $qualifiedName " +
                "OR (toUpper(coalesce(" + alias + ".owner, coalesce(" + alias + ".schema, coalesce(" + alias + ".user, coalesce(" + alias + ".default_user, ''))))) = $ownerName " +
                "AND toUpper(coalesce(" + alias + ".name, '')) = $tableName)" +
                ")) " +
                "OR ($qualifiedName = '' AND toUpper(coalesce(" + alias + ".name, '')) = $tableName)))) ";
    }

    private String resolveOwnerName(Map<String, Object> props, String rawName) {
        String explicitOwner = firstNonBlank(
                toSafeUpperString(props.get("owner")),
                toSafeUpperString(props.get("schema")),
                toSafeUpperString(props.get("user")),
                toSafeUpperString(props.get("default_user")));
        if (!explicitOwner.isEmpty()) {
            return explicitOwner;
        }
        String[] qualifiedParts = splitQualifiedName(rawName);
        if (!qualifiedParts[0].isEmpty()) {
            return qualifiedParts[0];
        }
        return "DEFAULT";
    }

    private String resolveTableName(Map<String, Object> props, String rawName) {
        String explicitTable = toSafeUpperString(props.get("tableName"));
        if (!explicitTable.isEmpty()) {
            return explicitTable;
        }
        return splitQualifiedName(rawName)[1];
    }

    private String[] splitQualifiedName(String name) {
        if (name == null) {
            return new String[] { "", "" };
        }
        String normalized = name.trim().toUpperCase();
        int index = normalized.lastIndexOf('.');
        if (index <= 0 || index >= normalized.length() - 1) {
            return new String[] { "", normalized };
        }
        return new String[] { normalized.substring(0, index), normalized.substring(index + 1) };
    }

    private String buildQualifiedName(String ownerName, String tableName) {
        String normalizedOwner = ownerName == null ? "" : ownerName.trim().toUpperCase();
        String normalizedTable = tableName == null ? "" : tableName.trim().toUpperCase();
        if (normalizedOwner.isEmpty() || "DEFAULT".equals(normalizedOwner)) {
            return normalizedTable;
        }
        return normalizedOwner + "." + normalizedTable;
    }

    private String toSafeUpperString(Object value) {
        if (value == null) {
            return "";
        }
        String text = String.valueOf(value).trim();
        return text.isEmpty() ? "" : text.toUpperCase();
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return "";
    }

    /**
     * 导出血缘Excel
     *
     * @param tableName  表名
     * @param columnName 字段名 (可选)
     * @param depth      查询深度 (-1表示全部)
     * @param response   HttpServletResponse
     * @throws IOException
     */
    public void exportLineage(String tableName, String qualifiedName, String columnName, int depth, String direction,
            String relationLevel, HttpServletResponse response)
            throws IOException {
        // 使用与当前画布一致的方向和层级，避免导出结果与页面显示不一致。
        Map<String, Object> graph = getGraphData(tableName, qualifiedName, columnName, depth, direction, 5000, relationLevel);
        List<Map<String, Object>> nodes = (List<Map<String, Object>>) graph.get("nodes");
        List<Map<String, Object>> edges = (List<Map<String, Object>>) graph.get("edges");

        // 2. 构建节点映射 (ElementId -> Node Data)
        Map<String, Map<String, Object>> nodeMap = new HashMap<>();
        if (nodes != null) {
            for (Map<String, Object> node : nodes) {
                nodeMap.put((String) node.get("elementId"), node);
            }
        }

        // 3. 转换为导出DTO列表
        List<LineageExportDTO> exportList = new ArrayList<>();
        if (edges != null) {
            for (Map<String, Object> edge : edges) {
                String sourceId = (String) edge.get("source");
                String targetId = (String) edge.get("target");
                String type = (String) edge.get("type");

                if (!"BELONGS_TO".equals(type)) { // 忽略BELONGS_TO关系
                    Map<String, Object> sourceNode = nodeMap.get(sourceId);
                    Map<String, Object> targetNode = nodeMap.get(targetId);

                    if (sourceNode != null && targetNode != null) {
                        LineageExportDTO dto = new LineageExportDTO();
                        String typeName = type;
                        if (type != null) {
                            switch (type) {
                                case "DERIVES_TO":
                                    typeName = "直接依赖";
                                    break;
                                case "FILTERS":
                                    typeName = "过滤条件";
                                    break;
                                case "JOINS":
                                    typeName = "关联条件";
                                    break;
                                case "GROUPS":
                                    typeName = "聚合条件";
                                    break;
                                case "ORDERS":
                                    typeName = "排序条件";
                                    break;
                                case "CALLS":
                                    typeName = "调用";
                                    break;
                                case "REFERENCES":
                                    typeName = "引用";
                                    break;
                                case "CASE_WHEN":
                                    typeName = "条件表达式";
                                    break;
                                default:
                                    break;
                            }
                        }
                        dto.setRelationType(typeName);

                        // 设置源信息
                        fillNodeInfo(dto, sourceNode, true);
                        // 设置目标信息
                        fillNodeInfo(dto, targetNode, false);

                        exportList.add(dto);
                    }
                }
            }
        }

        // 4. 写出Excel
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setCharacterEncoding("utf-8");

        String fileNameStr = (qualifiedName != null && !qualifiedName.isEmpty()) ? qualifiedName : tableName;
        if (columnName != null && !columnName.isEmpty()) {
            fileNameStr += "_" + columnName;
        }
        fileNameStr += "_血缘导出";

        String fileName = URLEncoder.encode(fileNameStr, StandardCharsets.UTF_8).replaceAll("\\+", "%20");
        response.setHeader("Content-disposition", "attachment;filename*=utf-8''" + fileName + ".xlsx");

        EasyExcel.write(response.getOutputStream(), LineageExportDTO.class)
                .sheet("血缘明细")
                .doWrite(exportList);
    }

    private void fillNodeInfo(LineageExportDTO dto, Map<String, Object> node, boolean isSource) {
        Map<String, Object> props = (Map<String, Object>) node.get("properties");
        Iterable<String> labels = (Iterable<String>) node.get("labels");
        boolean isTable = false;
        for (String label : labels) {
            if ("Table".equals(label)) {
                isTable = true;
                break;
            }
        }

        String name = (String) props.get("name");
        String tableName = isTable ? name : (String) props.getOrDefault("table", "");
        String colName = isTable ? "-" : name;

        if (isSource) {
            dto.setSourceTable(tableName);
            dto.setSourceColumn(colName);
        } else {
            dto.setTargetTable(tableName);
            dto.setTargetColumn(colName);
        }
    }
}
