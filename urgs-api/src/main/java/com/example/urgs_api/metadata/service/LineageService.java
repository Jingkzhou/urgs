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

@Service
/**
 * 血缘服务类
 * 负责与图数据库交互，提供血缘分析、搜索和追溯功能
 */
public class LineageService {

    // 所有血缘关系类型
    private static final List<String> ALL_LINEAGE_RELATION_TYPES = Arrays.asList(
            "DERIVES_TO", "FILTERS", "JOINS", "GROUPS", "ORDERS", "CALLS", "REFERENCES", "CASE_WHEN");

    @Autowired
    private Driver driver;

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
     * @return Map containing "total" (Long) and "list" (List<Map>)
     */
    public Map<String, Object> searchTables(String keyword, int page, int size) {
        int skip = (page - 1) * size;

        // 1. Count query
        String countQuery = "MATCH (n:Table) WHERE toLower(n.name) CONTAINS toLower($keyword) RETURN count(n) as total";

        // 2. Data query
        String dataQuery = "MATCH (n:Table) WHERE toLower(n.name) CONTAINS toLower($keyword) " +
                "OPTIONAL MATCH (c:Column)-[:BELONGS_TO]->(n) " +
                "RETURN n.name AS name, collect(c.name) AS columns ORDER BY n.name SKIP $skip LIMIT $limit";

        List<Map<String, Object>> list = new ArrayList<>();
        long total = 0;

        try (Session session = driver.session()) {
            // Execute count
            Result countResult = session.run(countQuery, Map.of("keyword", keyword));
            if (countResult.hasNext()) {
                total = countResult.next().get("total").asLong();
            }

            // Execute data fetch
            Result result = session.run(dataQuery, Map.of("keyword", keyword, "skip", skip, "limit", size));
            while (result.hasNext()) {
                var record = result.next();
                Map<String, Object> item = new HashMap<>();
                item.put("tableName", record.get("name").asString());
                item.put("columns", record.get("columns").asList(v -> v.asString()));
                list.add(item);
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("total", total);
        response.put("list", list);
        return response;
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
    public Map<String, Object> getGraphData(String tableName, String columnName, int depth) {
        String baseStart;
        Map<String, Object> params = new HashMap<>();
        params.put("tableName", tableName);

        // Handle infinite depth request with a safe upper bound to prevent timeouts
        int queryDepth = (depth == -1) ? 30 : depth;
        // Ensure depth is at least 1
        if (queryDepth < 1)
            queryDepth = 1;

        if (columnName != null && !columnName.isEmpty()) {
            params.put("colName", columnName);
            // Start from specific column.
            baseStart = "MATCH (t:Table)<-[:BELONGS_TO]-(c:Column {name: $colName}) WHERE toLower(t.name) = toLower($tableName) WITH c as startNode ";
        } else {
            // Start from Table and all its Columns
            baseStart = "MATCH (n:Table) WHERE toLower(n.name) = toLower($tableName) OPTIONAL MATCH (n)<-[:BELONGS_TO]-(c:Column) "
                    +
                    "WITH n, collect(c) + n as startNodes UNWIND startNodes as startNode ";
        }

        // 查询所有血缘关系类型
        String allRelTypes = "DERIVES_TO|FILTERS|JOINS|GROUPS|ORDERS|CALLS|REFERENCES|CASE_WHEN";

        // Optimized Query:
        // 1. Use variable length path with specified depth
        // 2. UNWIND relationships and return DISTINCT to avoid combinatorial explosion
        // of paths
        String lineageQuery =
                // Downstream
                baseStart +
                        "MATCH p = (startNode)-[:" + allRelTypes + "*0.." + queryDepth + "]->(m) " +
                        "UNWIND relationships(p) as r " +
                        "RETURN DISTINCT r, startNode(r) as source, endNode(r) as target " +
                        "UNION " +
                        // Upstream
                        baseStart +
                        "MATCH p = (startNode)<-[:" + allRelTypes + "*0.." + queryDepth + "]-(m) " +
                        "UNWIND relationships(p) as r " +
                        "RETURN DISTINCT r, startNode(r) as target, endNode(r) as source"; // Note reverse for upstream
                                                                                           // to maintain flow direction
                                                                                           // if needed, but here we
                                                                                           // just need nodes/edges

        Map<String, Object> graph = new HashMap<>();
        List<Map<String, Object>> nodes = new ArrayList<>();
        List<Map<String, Object>> edges = new ArrayList<>();
        Set<String> seenNodes = new HashSet<>();
        Set<String> seenEdges = new HashSet<>();
        Set<String> columnElementIds = new HashSet<>();

        try (Session session = driver.session()) {
            Result result = session.run(lineageQuery, params);
            while (result.hasNext()) {
                var record = result.next();
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
        return graph;
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
            String version, int depth, List<String> types) {
        List<String> relationTypes = (types != null && !types.isEmpty()) ? types : ALL_LINEAGE_RELATION_TYPES;
        String relTypesStr = String.join("|", relationTypes);

        Map<String, Object> params = new HashMap<>();
        params.put("tableName", tableName);
        params.put("columnName", columnName);

        // 构建版本过滤条件
        String versionFilter = "";
        if (version != null && !version.isEmpty()) {
            versionFilter = "WHERE ALL(rel IN relationships(path) WHERE rel.version = $version)";
            params.put("version", version);
        }

        String query = String.format(
                "MATCH path = (c:Column {name: $columnName, table: $tableName})-[:%s*1..%d]->(downstream:Column) " +
                        "%s RETURN path",
                relTypesStr, depth, versionFilter);

        return executePathQuery(query, params);
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
            String direction, String version, int depth) {
        Map<String, Object> params = new HashMap<>();
        params.put("tableName", tableName);
        params.put("columnName", columnName);

        String versionFilter = "";
        if (version != null && !version.isEmpty()) {
            versionFilter = "WHERE ALL(rel IN relationships(path) WHERE rel.version = $version)";
            params.put("version", version);
        }

        String query;
        if ("downstream".equals(direction)) {
            query = String.format(
                    "MATCH path = (c:Column {name: $columnName, table: $tableName})-[:DERIVES_TO*1..%d]->(downstream:Column) "
                            +
                            "%s RETURN path",
                    depth, versionFilter);
        } else {
            // 上游 (默认)
            query = String.format(
                    "MATCH path = (upstream:Column)-[:DERIVES_TO*1..%d]->(c:Column {name: $columnName, table: $tableName}) "
                            +
                            "%s RETURN path",
                    depth, versionFilter);
        }

        return executePathQuery(query, params);
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
    private Map<String, Object> executePathQuery(String query, Map<String, Object> params) {
        Map<String, Object> graph = new HashMap<>();
        List<Map<String, Object>> nodes = new ArrayList<>();
        List<Map<String, Object>> edges = new ArrayList<>();
        Set<String> seenNodes = new HashSet<>();
        Set<String> seenEdges = new HashSet<>();

        try (Session session = driver.session()) {
            Result result = session.run(query, params);
            while (result.hasNext()) {
                org.neo4j.driver.types.Path path = result.next().get("path").asPath();
                path.nodes().forEach(node -> addNode(node, nodes, seenNodes));
                path.relationships().forEach(rel -> addEdge(rel, edges, seenEdges));
            }
        }

        graph.put("nodes", nodes);
        graph.put("edges", edges);
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
            edgeData.put("id", rel.elementId());
            edgeData.put("source", rel.startNodeElementId());
            edgeData.put("target", rel.endNodeElementId());
            edgeData.put("type", rel.type());
            edgeData.put("properties", rel.asMap());
            edges.add(edgeData);
            seenEdges.add(rel.elementId());
        }
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
    public void exportLineage(String tableName, String columnName, int depth, HttpServletResponse response)
            throws IOException {
        // 1. 获取血缘数据 (Use provided depth, or safe max if -1 is handled inside
        // getGraphData)
        Map<String, Object> graph = getGraphData(tableName, columnName, depth);
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

        String fileNameStr = tableName;
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
