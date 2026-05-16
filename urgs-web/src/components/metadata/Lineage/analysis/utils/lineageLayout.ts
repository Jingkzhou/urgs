import dagre from 'dagre';
import { COLUMN_ROW_HEIGHT, NODE_HEADER_HEIGHT } from '../constants';
import { LinkData, NodeData } from '../types';

type RawLineageNode = {
    id: string;
    labels: string[];
    properties: Record<string, any>;
};

type RawLineageEdge = {
    id: string;
    source: string;
    target: string;
    type: string;
    properties?: Record<string, any>;
};

const isTableNode = (node: RawLineageNode) => node.labels.includes('Table');
const isColumnNode = (node: RawLineageNode) => node.labels.includes('Column');
const sameTableName = (left: string, right: string) => left.toLowerCase() === right.toLowerCase();

const collectDownstreamGraph = (
    rawNodes: RawLineageNode[],
    rawEdges: RawLineageEdge[],
    mainTableName: string
) => {
    const nodeIdToInfo = new Map<string, { type: 'Table' | 'Column'; tableName: string }>();
    rawNodes.forEach(node => {
        if (isTableNode(node)) {
            nodeIdToInfo.set(node.id, { type: 'Table', tableName: node.properties.name });
        } else if (isColumnNode(node)) {
            nodeIdToInfo.set(node.id, { type: 'Column', tableName: node.properties.table || '' });
        }
    });

    const edgesBySource = new Map<string, RawLineageEdge[]>();
    rawEdges.forEach(edge => {
        if (edge.type === 'BELONGS_TO') {
            return;
        }
        const list = edgesBySource.get(edge.source) || [];
        list.push(edge);
        edgesBySource.set(edge.source, list);
    });

    const downstreamNodeIds = new Set<string>();
    const downstreamEdges: RawLineageEdge[] = [];
    const processedSources = new Set<string>();
    const queue: string[] = [];

    rawNodes.forEach(node => {
        const info = nodeIdToInfo.get(node.id);
        if (info && sameTableName(info.tableName, mainTableName)) {
            queue.push(node.id);
            downstreamNodeIds.add(node.id);
        }
    });

    while (queue.length > 0) {
        const currentId = queue.shift()!;
        if (processedSources.has(currentId)) {
            continue;
        }
        processedSources.add(currentId);

        (edgesBySource.get(currentId) || []).forEach(edge => {
            downstreamEdges.push(edge);
            downstreamNodeIds.add(edge.target);
            if (!processedSources.has(edge.target)) {
                queue.push(edge.target);
            }
        });
    }

    downstreamNodeIds.forEach(nodeId => {
        const info = nodeIdToInfo.get(nodeId);
        if (info?.type !== 'Column') {
            return;
        }
        rawEdges
            .filter(edge => edge.type === 'BELONGS_TO' && edge.source === nodeId)
            .forEach(edge => downstreamNodeIds.add(edge.target));
    });

    return {
        nodes: rawNodes.filter(node => downstreamNodeIds.has(node.id)),
        edges: [
            ...downstreamEdges,
            ...rawEdges.filter(edge => edge.type === 'BELONGS_TO' && downstreamNodeIds.has(edge.source)),
        ],
    };
};

const buildTableGraph = (
    rawNodes: RawLineageNode[],
    rawEdges: RawLineageEdge[],
    mainTableName: string,
    keepMainLineageOnly: boolean
) => {
    const dagreGraph = new dagre.graphlib.Graph();
    dagreGraph.setGraph({ rankdir: 'LR', nodesep: 100, ranksep: 300 });
    dagreGraph.setDefaultEdgeLabel(() => ({}));

    const tableMap = new Map<string, NodeData>();
    const tableIdMap = new Map<string, NodeData>();
    const colToTableId = new Map<string, string>();

    rawNodes.forEach(node => {
        if (!isTableNode(node)) {
            return;
        }
        const tableName = node.properties.name;
        const tableNode: NodeData = {
            id: node.id,
            type: 'default',
            title: tableName,
            columns: [],
            x: 0,
            y: 0,
            width: 240,
            isCollapsed: false,
        };
        tableMap.set(tableName, tableNode);
        tableIdMap.set(node.id, tableNode);
    });

    rawEdges.forEach(edge => {
        if (edge.type === 'BELONGS_TO') {
            colToTableId.set(edge.source, edge.target);
        }
    });

    rawNodes.forEach(node => {
        if (!isColumnNode(node)) {
            return;
        }
        const tableNode = tableIdMap.get(colToTableId.get(node.id) || '');
        if (tableNode) {
            tableNode.columns.push({ id: node.id, name: node.properties.name });
        }
    });

    const hasTableLevelEdges = rawEdges.some(edge =>
        edge.type !== 'BELONGS_TO' && tableIdMap.has(edge.source) && tableIdMap.has(edge.target)
    );

    tableMap.forEach((node, tableName) => {
        if (!hasTableLevelEdges && node.columns.length === 0) {
            tableMap.delete(tableName);
            return;
        }
        node.columns.sort((a, b) => a.name.localeCompare(b.name));
        dagreGraph.setNode(node.id, {
            width: node.width,
            height: NODE_HEADER_HEIGHT + node.columns.length * COLUMN_ROW_HEIGHT,
        });
    });

    const links: LinkData[] = [];
    rawEdges.forEach(edge => {
        if (edge.type === 'BELONGS_TO') {
            return;
        }
        const sourceTableId = colToTableId.get(edge.source) || (tableIdMap.has(edge.source) ? edge.source : undefined);
        const targetTableId = colToTableId.get(edge.target) || (tableIdMap.has(edge.target) ? edge.target : undefined);
        if (!sourceTableId || !targetTableId) {
            return;
        }
        links.push({
            id: edge.id,
            sourceNodeId: sourceTableId,
            sourceColumnId: colToTableId.has(edge.source) ? edge.source : '',
            targetNodeId: targetTableId,
            targetColumnId: colToTableId.has(edge.target) ? edge.target : '',
            type: edge.type,
            properties: edge.properties,
        });
        dagreGraph.setEdge(sourceTableId, targetTableId);
    });

    dagre.layout(dagreGraph);

    const validNodeIds = keepMainLineageOnly
        ? collectMainLineageNodeIds(tableMap, links, mainTableName)
        : collectConnectedNodeIds(tableMap, links, mainTableName);
    const layoutedNodes: NodeData[] = [];

    tableMap.forEach(node => {
        if (!validNodeIds.has(node.id)) {
            return;
        }
        const dagreNode = dagreGraph.node(node.id);
        if (!dagreNode) {
            return;
        }
        node.x = dagreNode.x - node.width / 2;
        node.y = dagreNode.y - (NODE_HEADER_HEIGHT + node.columns.length * COLUMN_ROW_HEIGHT) / 2;
        layoutedNodes.push(node);
    });

    return {
        layoutedNodes,
        layoutedLinks: links.filter(link => validNodeIds.has(link.sourceNodeId) && validNodeIds.has(link.targetNodeId)),
    };
};

const collectConnectedNodeIds = (tableMap: Map<string, NodeData>, links: LinkData[], mainTableName: string) => {
    const validNodeIds = new Set<string>();
    links.forEach(link => {
        validNodeIds.add(link.sourceNodeId);
        validNodeIds.add(link.targetNodeId);
    });

    const mainTableNode = [...tableMap.values()].find(node => sameTableName(node.title, mainTableName));
    if (mainTableNode) {
        validNodeIds.add(mainTableNode.id);
    }
    return validNodeIds;
};

const collectMainLineageNodeIds = (tableMap: Map<string, NodeData>, links: LinkData[], mainTableName: string) => {
    const lineageNodeIds = new Set<string>();
    const queue: string[] = [];
    const mainTableNode = [...tableMap.values()].find(node => sameTableName(node.title, mainTableName));
    if (mainTableNode) {
        lineageNodeIds.add(mainTableNode.id);
        queue.push(mainTableNode.id);
    }

    const bySource = new Map<string, string[]>();
    const byTarget = new Map<string, string[]>();
    links.forEach(link => {
        bySource.set(link.sourceNodeId, [...(bySource.get(link.sourceNodeId) || []), link.targetNodeId]);
        byTarget.set(link.targetNodeId, [...(byTarget.get(link.targetNodeId) || []), link.sourceNodeId]);
    });

    while (queue.length > 0) {
        const currentId = queue.shift()!;
        [...(bySource.get(currentId) || []), ...(byTarget.get(currentId) || [])].forEach(nextId => {
            if (!lineageNodeIds.has(nextId)) {
                lineageNodeIds.add(nextId);
                queue.push(nextId);
            }
        });
    }

    return lineageNodeIds;
};

export const processLayoutImpact = (rawNodes: any[], rawEdges: any[], mainTableName: string) => {
    const downstreamGraph = collectDownstreamGraph(rawNodes, rawEdges, mainTableName);
    return buildTableGraph(downstreamGraph.nodes, downstreamGraph.edges, mainTableName, true);
};

export const processLayoutTrace = (rawNodes: any[], rawEdges: any[], mainTableName: string) => (
    buildTableGraph(rawNodes, rawEdges, mainTableName, false)
);
