import { LinkData, NodeData } from '../types';
import {
    DEFAULT_RELATION_TYPE,
    TABLE_LEVEL_COLUMN,
    findMainNode,
    getRelationLabel,
    normalizeArray,
    normalizeRelationType,
    splitQualifiedTitle,
} from './lineageGraphDensity';

export type LineageDisplayMode = 'full' | 'endToEnd';

export interface EndToEndPathStep {
    nodeId: string;
    columnId: string;
    tableName: string;
    columnName: string;
}

export interface EndToEndRelation {
    key: string;
    source: EndToEndPathStep;
    target: EndToEndPathStep;
    current?: EndToEndPathStep;
    targetCategory: string;
    pathCount: number;
    minLevel: number;
    maxLevel: number;
    schemaPath: string;
    tableCount: number;
    fieldCount: number;
    taskCount: number;
    relationTypeSummary: string;
    relationTypes: Record<string, number>;
    completeness: string;
    paths: EndToEndPathStep[][];
    links: LinkData[][];
}

interface ColumnRef {
    nodeId: string;
    columnId: string;
}

const MAX_PATHS = 1200;
const MAX_DEPTH = 24;

const columnKey = (nodeId: string, columnId?: string) => `${nodeId}::${columnId || TABLE_LEVEL_COLUMN}`;
const parseColumnKey = (key: string): ColumnRef => {
    const [nodeId, columnId] = key.split('::');
    return { nodeId, columnId: columnId || TABLE_LEVEL_COLUMN };
};

const getLinkSourceKey = (link: LinkData) => columnKey(link.sourceNodeId, link.sourceColumnId);
const getLinkTargetKey = (link: LinkData) => columnKey(link.targetNodeId, link.targetColumnId);

const getColumnName = (node: NodeData | undefined, columnId: string) => (
    node?.columns.find(column => column.id === columnId)?.name
    || (columnId === TABLE_LEVEL_COLUMN ? '表级关系' : columnId)
);

const makeStep = (key: string, nodeMap: Map<string, NodeData>): EndToEndPathStep => {
    const ref = parseColumnKey(key);
    const node = nodeMap.get(ref.nodeId);
    return {
        nodeId: ref.nodeId,
        columnId: ref.columnId,
        tableName: node?.title || ref.nodeId,
        columnName: getColumnName(node, ref.columnId),
    };
};

const collectSelectedKeys = (
    nodes: NodeData[],
    links: LinkData[],
    selectedTable: string | null,
    selectedField?: { nodeId: string; colId: string } | null
) => {
    if (selectedField) {
        return [columnKey(selectedField.nodeId, selectedField.colId)];
    }

    const mainNode = findMainNode(nodes, selectedTable, selectedField);
    if (!mainNode) {
        return [];
    }

    const usedColumns = new Set<string>();
    links.forEach(link => {
        if (link.sourceNodeId === mainNode.id) {
            usedColumns.add(link.sourceColumnId || TABLE_LEVEL_COLUMN);
        }
        if (link.targetNodeId === mainNode.id) {
            usedColumns.add(link.targetColumnId || TABLE_LEVEL_COLUMN);
        }
    });

    const columns = usedColumns.size > 0 ? Array.from(usedColumns) : mainNode.columns.map(column => column.id);
    return columns.map(columnId => columnKey(mainNode.id, columnId));
};

const buildPaths = (
    startKey: string,
    edgeMap: Map<string, LinkData[]>,
    getNextKey: (link: LinkData) => string
) => {
    const paths: LinkData[][] = [];

    const walk = (currentKey: string, trail: LinkData[], visited: Set<string>) => {
        if (paths.length >= MAX_PATHS || trail.length >= MAX_DEPTH) {
            paths.push(trail);
            return;
        }

        const nextLinks = (edgeMap.get(currentKey) || []).filter(link => !visited.has(getNextKey(link)));
        if (nextLinks.length === 0) {
            paths.push(trail);
            return;
        }

        nextLinks.forEach(link => {
            const nextKey = getNextKey(link);
            const nextVisited = new Set(visited);
            nextVisited.add(nextKey);
            walk(nextKey, [...trail, link], nextVisited);
        });
    };

    walk(startKey, [], new Set([startKey]));
    return paths;
};

const linkPathToKeys = (startKey: string, path: LinkData[], direction: 'downstream' | 'upstream') => {
    const keys = [startKey];
    path.forEach(link => {
        keys.push(direction === 'downstream' ? getLinkTargetKey(link) : getLinkSourceKey(link));
    });
    return direction === 'downstream' ? keys : keys.slice().reverse();
};

const uniqueOrdered = (items: string[]) => {
    const seen = new Set<string>();
    return items.filter(item => {
        if (!item || seen.has(item)) {
            return false;
        }
        seen.add(item);
        return true;
    });
};

const collectTaskNames = (links: LinkData[]) => {
    const names = new Set<string>();
    links.forEach(link => {
        normalizeArray(link.properties?.sourceFiles).forEach(item => names.add(item));
        normalizeArray(link.properties?.taskNames).forEach(item => names.add(item));
        const single = link.properties?.sourceFile || link.properties?.source_file || link.properties?.taskName;
        if (single) {
            names.add(String(single));
        }
    });
    return names;
};

const getCategory = (step: EndToEndPathStep, direction: 'upstream' | 'downstream') => {
    const text = `${step.tableName}.${step.columnName}`.toLowerCase();
    if (/(report|rpt|dashboard|bi|报表)/.test(text)) {
        return '最终报表字段';
    }
    if (/(api|interface|接口)/.test(text)) {
        return '最终接口字段';
    }
    if (/(^|\.)(ads|dm)(\.|_|$)/.test(text)) {
        return '最终ADS/DM字段';
    }
    return direction === 'upstream' ? '最原始来源字段' : '没有下游的叶子字段';
};

const summarizeRelationTypes = (typeCounts: Record<string, number>) => (
    Object.entries(typeCounts)
        .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
        .map(([type, count]) => `${getRelationLabel(type)} ${count}`)
        .join(' / ') || `${getRelationLabel(DEFAULT_RELATION_TYPE)} 0`
);

const mergePath = (
    relationMap: Map<string, EndToEndRelation>,
    keys: string[],
    links: LinkData[],
    currentKey: string,
    nodeMap: Map<string, NodeData>,
    direction: 'upstream' | 'downstream'
) => {
    if (keys.length === 0) {
        return;
    }

    const source = makeStep(keys[0], nodeMap);
    const target = makeStep(keys[keys.length - 1], nodeMap);
    const current = keys.includes(currentKey) ? makeStep(currentKey, nodeMap) : undefined;
    const relationKey = `${keys[0]}=>${keys[keys.length - 1]}`;
    const level = Math.max(0, keys.length - 1);
    const schemas = uniqueOrdered(keys.map(key => splitQualifiedTitle(makeStep(key, nodeMap).tableName).owner || '默认'));
    const fields = new Set(keys);
    const tables = new Set(keys.map(key => makeStep(key, nodeMap).tableName));
    const tasks = collectTaskNames(links);

    const relation = relationMap.get(relationKey) || {
        key: relationKey,
        source,
        target,
        current,
        targetCategory: getCategory(target, direction),
        pathCount: 0,
        minLevel: level,
        maxLevel: level,
        schemaPath: schemas.join(' -> '),
        tableCount: 0,
        fieldCount: 0,
        taskCount: 0,
        relationTypeSummary: '',
        relationTypes: {},
        completeness: '完整路径',
        paths: [],
        links: [],
    };

    relation.pathCount += 1;
    relation.minLevel = Math.min(relation.minLevel, level);
    relation.maxLevel = Math.max(relation.maxLevel, level);
    relation.tableCount = Math.max(relation.tableCount, tables.size);
    relation.fieldCount = Math.max(relation.fieldCount, fields.size);
    relation.taskCount = Math.max(relation.taskCount, tasks.size);
    relation.schemaPath = uniqueOrdered([...relation.schemaPath.split(' -> '), ...schemas]).join(' -> ');
    links.forEach(link => {
        const type = normalizeRelationType(link.type);
        relation.relationTypes[type] = (relation.relationTypes[type] || 0) + 1;
    });
    relation.relationTypeSummary = summarizeRelationTypes(relation.relationTypes);
    relation.paths.push(keys.map(key => makeStep(key, nodeMap)));
    relation.links.push(links);
    relationMap.set(relationKey, relation);
};

export const buildEndToEndRelations = (
    nodes: NodeData[],
    links: LinkData[],
    selectedTable: string | null,
    selectedField?: { nodeId: string; colId: string } | null
) => {
    const nodeMap = new Map(nodes.map(node => [node.id, node]));
    const outgoing = new Map<string, LinkData[]>();
    const incoming = new Map<string, LinkData[]>();
    links.forEach(link => {
        outgoing.set(getLinkSourceKey(link), [...(outgoing.get(getLinkSourceKey(link)) || []), link]);
        incoming.set(getLinkTargetKey(link), [...(incoming.get(getLinkTargetKey(link)) || []), link]);
    });

    const selectedKeys = collectSelectedKeys(nodes, links, selectedTable, selectedField);
    const relationMap = new Map<string, EndToEndRelation>();

    selectedKeys.forEach(currentKey => {
        const downstreamPaths = buildPaths(currentKey, outgoing, getLinkTargetKey).filter(path => path.length > 0);
        const upstreamPaths = buildPaths(currentKey, incoming, getLinkSourceKey).filter(path => path.length > 0);

        if (upstreamPaths.length > 0 && downstreamPaths.length > 0) {
            upstreamPaths.forEach(upstreamPath => {
                downstreamPaths.forEach(downstreamPath => {
                    const upstreamKeys = linkPathToKeys(currentKey, upstreamPath, 'upstream');
                    const downstreamKeys = linkPathToKeys(currentKey, downstreamPath, 'downstream');
                    mergePath(
                        relationMap,
                        [...upstreamKeys, ...downstreamKeys.slice(1)],
                        [...upstreamPath].reverse().concat(downstreamPath),
                        currentKey,
                        nodeMap,
                        'downstream'
                    );
                });
            });
            return;
        }

        downstreamPaths.forEach(path => {
            mergePath(relationMap, linkPathToKeys(currentKey, path, 'downstream'), path, currentKey, nodeMap, 'downstream');
        });
        upstreamPaths.forEach(path => {
            mergePath(relationMap, linkPathToKeys(currentKey, path, 'upstream'), path.slice().reverse(), currentKey, nodeMap, 'upstream');
        });
    });

    return Array.from(relationMap.values())
        .sort((a, b) => (
            b.pathCount - a.pathCount
            || a.targetCategory.localeCompare(b.targetCategory)
            || a.target.tableName.localeCompare(b.target.tableName)
            || a.target.columnName.localeCompare(b.target.columnName)
        ));
};

const cloneEndpointNode = (step: EndToEndPathStep, nodeMap: Map<string, NodeData>): NodeData => {
    const source = nodeMap.get(step.nodeId);
    return {
        ...(source || {
            id: step.nodeId,
            x: 0,
            y: 0,
            width: 290,
            type: 'default' as const,
            title: step.tableName,
            columns: [],
        }),
        columns: [{ id: step.columnId, name: step.columnName }],
    };
};

const makeSummaryLink = (
    id: string,
    source: EndToEndPathStep,
    target: EndToEndPathStep,
    relation: EndToEndRelation
): LinkData => ({
    id,
    sourceNodeId: source.nodeId,
    sourceColumnId: source.columnId,
    targetNodeId: target.nodeId,
    targetColumnId: target.columnId,
    type: DEFAULT_RELATION_TYPE,
    properties: {
        relationLevel: 'end_to_end',
        relationCount: relation.pathCount,
        sourceColumn: source.columnName,
        targetColumn: target.columnName,
        sourceColumns: [source.columnName],
        targetColumns: [target.columnName],
        schemaPath: relation.schemaPath,
        minLevel: relation.minLevel,
        maxLevel: relation.maxLevel,
        tableCount: relation.tableCount,
        fieldCount: relation.fieldCount,
        taskCount: relation.taskCount,
        relationTypeSummary: relation.relationTypeSummary,
        completeness: relation.completeness,
    },
});

export const buildEndToEndGraph = (
    nodes: NodeData[],
    relations: EndToEndRelation[]
) => {
    const nodeMap = new Map(nodes.map(node => [node.id, node]));
    const nextNodes = new Map<string, NodeData>();
    const nextLinks: LinkData[] = [];

    relations.forEach((relation, index) => {
        [relation.source, relation.current, relation.target].filter(Boolean).forEach(step => {
            const item = step as EndToEndPathStep;
            if (!nextNodes.has(item.nodeId)) {
                nextNodes.set(item.nodeId, cloneEndpointNode(item, nodeMap));
            } else {
                const node = nextNodes.get(item.nodeId)!;
                if (!node.columns.some(column => column.id === item.columnId)) {
                    node.columns = [...node.columns, { id: item.columnId, name: item.columnName }];
                }
            }
        });

        if (relation.current && relation.current.nodeId !== relation.source.nodeId) {
            nextLinks.push(makeSummaryLink(`end-to-end-${index}-in`, relation.source, relation.current, relation));
        }
        if (relation.current && relation.current.nodeId !== relation.target.nodeId) {
            nextLinks.push(makeSummaryLink(`end-to-end-${index}-out`, relation.current, relation.target, relation));
        }
        if (!relation.current || (relation.current.nodeId === relation.source.nodeId && relation.current.nodeId === relation.target.nodeId)) {
            nextLinks.push(makeSummaryLink(`end-to-end-${index}`, relation.source, relation.target, relation));
        }
    });

    return {
        nodes: Array.from(nextNodes.values()),
        links: nextLinks,
    };
};
