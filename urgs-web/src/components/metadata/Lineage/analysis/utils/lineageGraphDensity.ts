import { LinkData, NodeData, RELATION_STYLES } from '../types';

export const TABLE_LEVEL_COLUMN = '__table_level__';
export const DEFAULT_RELATION_TYPE = 'DERIVES_TO';

export interface LineageGraphStats {
    originalNodeCount: number;
    originalLinkCount: number;
    visibleNodeCount: number;
    visibleLinkCount: number;
    hiddenNodeCount: number;
    hiddenLinkCount: number;
    compactApplied: boolean;
    compactReason: string;
}

export interface ImpactRow {
    key: string;
    nodeId: string;
    qualifiedName: string;
    owner: string;
    tableName: string;
    direction: 'upstream' | 'downstream' | 'same';
    hop: number;
    relationTypes: string[];
    relationLabels: string;
    relationCount: number;
    sourceColumns: string[];
    targetColumns: string[];
    sourceFiles: string[];
    hasSnippet: boolean;
}

export const splitQualifiedTitle = (title: string) => {
    const index = title.lastIndexOf('.');
    if (index <= 0 || index === title.length - 1) {
        return { owner: '', table: title };
    }
    return {
        owner: title.slice(0, index),
        table: title.slice(index + 1),
    };
};

export const normalizeTableName = (value?: string | null) => String(value || '').trim().toLowerCase();

export const sameTable = (left: string, right?: string | null) => (
    !!right && normalizeTableName(left) === normalizeTableName(right)
);

export const sameTableLoose = (left: string, right?: string | null) => {
    const normalizedLeft = normalizeTableName(left);
    const normalizedRight = normalizeTableName(right);
    if (!normalizedRight) {
        return false;
    }
    const leftLeaf = normalizedLeft.slice(normalizedLeft.lastIndexOf('.') + 1);
    const rightLeaf = normalizedRight.slice(normalizedRight.lastIndexOf('.') + 1);
    return normalizedLeft === normalizedRight || leftLeaf === rightLeaf;
};

export const normalizeRelationType = (type?: string) => type || DEFAULT_RELATION_TYPE;

export const getRelationStyle = (type?: string) => (
    RELATION_STYLES[normalizeRelationType(type)] || RELATION_STYLES[DEFAULT_RELATION_TYPE]
);

export const getRelationLabel = (type?: string) => (
    RELATION_STYLES[normalizeRelationType(type)]?.label || normalizeRelationType(type)
);

export const normalizeArray = (value: any): string[] => {
    if (Array.isArray(value)) {
        return value.filter(Boolean).map(String);
    }
    return value ? [String(value)] : [];
};

const getRelationCount = (link: LinkData) => Number(link.properties?.relationCount || 1) || 1;

export const findMainNode = (
    nodes: NodeData[],
    selectedTable: string | null,
    selectedField?: { nodeId: string; colId: string } | null
) => (
    nodes.find(node => node.id === selectedField?.nodeId)
    || nodes.find(node => sameTableLoose(node.title, selectedTable))
    || nodes[0]
);

export const buildNodeRanks = (
    nodes: NodeData[],
    links: LinkData[],
    selectedTable: string | null,
    selectedField?: { nodeId: string; colId: string } | null
) => {
    const nodeIds = new Set(nodes.map(node => node.id));
    const selectedNode = findMainNode(nodes, selectedTable, selectedField);
    const ranks = new Map<string, number>();
    if (!selectedNode) {
        return ranks;
    }

    const outgoing = new Map<string, string[]>();
    const incoming = new Map<string, string[]>();
    links.forEach(link => {
        if (!nodeIds.has(link.sourceNodeId) || !nodeIds.has(link.targetNodeId)) {
            return;
        }
        outgoing.set(link.sourceNodeId, [...(outgoing.get(link.sourceNodeId) || []), link.targetNodeId]);
        incoming.set(link.targetNodeId, [...(incoming.get(link.targetNodeId) || []), link.sourceNodeId]);
    });

    const queue = [selectedNode.id];
    ranks.set(selectedNode.id, 0);
    while (queue.length > 0) {
        const current = queue.shift()!;
        const currentRank = ranks.get(current) || 0;
        (incoming.get(current) || []).forEach(sourceId => {
            if (!ranks.has(sourceId)) {
                ranks.set(sourceId, currentRank - 1);
                queue.push(sourceId);
            }
        });
        (outgoing.get(current) || []).forEach(targetId => {
            if (!ranks.has(targetId)) {
                ranks.set(targetId, currentRank + 1);
                queue.push(targetId);
            }
        });
    }

    nodes.forEach(node => {
        if (!ranks.has(node.id)) {
            ranks.set(node.id, Math.round((node.x || 0) / 480));
        }
    });
    return ranks;
};

const directionFromRank = (rank: number): ImpactRow['direction'] => {
    if (rank < 0) {
        return 'upstream';
    }
    if (rank > 0) {
        return 'downstream';
    }
    return 'same';
};

export const collectRelationOptions = (links: LinkData[]) => {
    const order = new Map(Object.keys(RELATION_STYLES).map((type, index) => [type, index]));
    return Array.from(new Set(links.map(link => normalizeRelationType(link.type))))
        .sort((a, b) => (order.get(a) ?? 99) - (order.get(b) ?? 99) || a.localeCompare(b));
};

export const buildImpactRows = (
    nodes: NodeData[],
    links: LinkData[],
    selectedTable: string | null,
    selectedField?: { nodeId: string; colId: string } | null
): ImpactRow[] => {
    const mainNode = findMainNode(nodes, selectedTable, selectedField);
    const ranks = buildNodeRanks(nodes, links, selectedTable, selectedField);
    const linksByNode = new Map<string, LinkData[]>();
    links.forEach(link => {
        linksByNode.set(link.sourceNodeId, [...(linksByNode.get(link.sourceNodeId) || []), link]);
        linksByNode.set(link.targetNodeId, [...(linksByNode.get(link.targetNodeId) || []), link]);
    });

    return nodes
        .filter(node => node.id !== mainNode?.id && !node.isGroupNode)
        .map(node => {
            const nodeLinks = linksByNode.get(node.id) || [];
            const relationTypes = collectRelationOptions(nodeLinks);
            const sourceColumns = new Set<string>();
            const targetColumns = new Set<string>();
            const sourceFiles = new Set<string>();
            let relationCount = 0;
            let hasSnippet = false;

            nodeLinks.forEach(link => {
                relationCount += getRelationCount(link);
                normalizeArray(link.properties?.sourceColumns).forEach(item => sourceColumns.add(item));
                normalizeArray(link.properties?.targetColumns).forEach(item => targetColumns.add(item));
                normalizeArray(link.properties?.sourceFiles).forEach(item => sourceFiles.add(item));
                if (link.properties?.sourceFile || link.properties?.source_file) {
                    sourceFiles.add(String(link.properties.sourceFile || link.properties.source_file));
                }
                hasSnippet = hasSnippet || !!link.properties?.snippet;
            });

            const rank = ranks.get(node.id) || 0;
            const { owner, table } = splitQualifiedTitle(node.title);
            return {
                key: node.id,
                nodeId: node.id,
                qualifiedName: node.title,
                owner,
                tableName: table,
                direction: directionFromRank(rank),
                hop: Math.abs(rank),
                relationTypes,
                relationLabels: relationTypes.map(getRelationLabel).join('、') || '-',
                relationCount,
                sourceColumns: Array.from(sourceColumns),
                targetColumns: Array.from(targetColumns),
                sourceFiles: Array.from(sourceFiles),
                hasSnippet,
            };
        })
        .sort((a, b) => a.hop - b.hop || b.relationCount - a.relationCount || a.qualifiedName.localeCompare(b.qualifiedName));
};

const createGroupNode = (
    rank: number,
    hiddenCount: number,
    index: number
): NodeData => {
    const direction = directionFromRank(rank);
    const label = direction === 'upstream'
        ? `更多上游 ${hiddenCount} 张`
        : (direction === 'downstream' ? `更多下游 ${hiddenCount} 张` : `更多同层 ${hiddenCount} 张`);
    return {
        id: `__lineage_group__${rank}_${index}`,
        x: 0,
        y: 0,
        width: 290,
        type: 'default',
        title: label,
        isGroupNode: true,
        groupDirection: direction,
        hiddenNodeCount: hiddenCount,
        columns: [{ id: TABLE_LEVEL_COLUMN, name: '在右侧影响清单中查看' }],
    };
};

export const buildDensityGraph = (options: {
    nodes: NodeData[];
    links: LinkData[];
    selectedTable: string | null;
    selectedField?: { nodeId: string; colId: string } | null;
    focusedNodeId?: string | null;
    compactEnabled: boolean;
    perLayerLimit: number;
    relationTypes: string[];
}) => {
    const {
        nodes,
        links,
        selectedTable,
        selectedField,
        focusedNodeId,
        compactEnabled,
        perLayerLimit,
        relationTypes,
    } = options;
    const activeTypes = relationTypes.length > 0 ? new Set(relationTypes) : null;
    const filteredLinks = activeTypes
        ? links.filter(link => activeTypes.has(normalizeRelationType(link.type)))
        : links;
    const mainNode = findMainNode(nodes, selectedTable, selectedField);
    const connectedIds = new Set<string>();
    filteredLinks.forEach(link => {
        connectedIds.add(link.sourceNodeId);
        connectedIds.add(link.targetNodeId);
    });
    if (mainNode) {
        connectedIds.add(mainNode.id);
    }
    if (focusedNodeId) {
        connectedIds.add(focusedNodeId);
    }
    const baseNodes = nodes.filter(node => connectedIds.has(node.id));
    const shouldCompact = compactEnabled && (baseNodes.length > 30 || filteredLinks.length > 200);

    if (!shouldCompact) {
        return {
            nodes: baseNodes,
            links: filteredLinks.filter(link => connectedIds.has(link.sourceNodeId) && connectedIds.has(link.targetNodeId)),
            stats: {
                originalNodeCount: baseNodes.length,
                originalLinkCount: filteredLinks.length,
                visibleNodeCount: baseNodes.length,
                visibleLinkCount: filteredLinks.length,
                hiddenNodeCount: 0,
                hiddenLinkCount: 0,
                compactApplied: false,
                compactReason: '',
            } satisfies LineageGraphStats,
        };
    }

    const ranks = buildNodeRanks(baseNodes, filteredLinks, selectedTable, selectedField);
    const nodeWeights = new Map<string, number>();
    filteredLinks.forEach(link => {
        const weight = getRelationCount(link);
        nodeWeights.set(link.sourceNodeId, (nodeWeights.get(link.sourceNodeId) || 0) + weight);
        nodeWeights.set(link.targetNodeId, (nodeWeights.get(link.targetNodeId) || 0) + weight);
    });

    const grouped = new Map<number, NodeData[]>();
    baseNodes.forEach(node => {
        const rank = ranks.get(node.id) || 0;
        grouped.set(rank, [...(grouped.get(rank) || []), node]);
    });

    const visibleIds = new Set<string>();
    const hiddenByRank = new Map<number, NodeData[]>();
    Array.from(grouped.entries()).forEach(([rank, rankNodes]) => {
        const sorted = rankNodes.slice().sort((a, b) => {
            if (a.id === mainNode?.id) return -1;
            if (b.id === mainNode?.id) return 1;
            if (a.id === focusedNodeId) return -1;
            if (b.id === focusedNodeId) return 1;
            return (nodeWeights.get(b.id) || 0) - (nodeWeights.get(a.id) || 0) || a.title.localeCompare(b.title);
        });
        const limit = Math.max(3, perLayerLimit);
        sorted.slice(0, limit).forEach(node => visibleIds.add(node.id));
        const hidden = sorted.slice(limit);
        if (hidden.length > 0) {
            hiddenByRank.set(rank, hidden);
        }
    });

    if (mainNode) {
        visibleIds.add(mainNode.id);
    }
    if (focusedNodeId) {
        visibleIds.add(focusedNodeId);
    }

    const visibleLinks = filteredLinks.filter(link => visibleIds.has(link.sourceNodeId) && visibleIds.has(link.targetNodeId));
    const groupNodes: NodeData[] = [];
    const groupLinks: LinkData[] = [];

    if (mainNode) {
        Array.from(hiddenByRank.entries()).forEach(([rank, hidden], index) => {
            const groupNode = createGroupNode(rank, hidden.length, index);
            const hiddenIds = new Set(hidden.map(node => node.id));
            const relationCount = filteredLinks
                .filter(link => hiddenIds.has(link.sourceNodeId) || hiddenIds.has(link.targetNodeId))
                .reduce((sum, link) => sum + getRelationCount(link), 0);
            groupNodes.push(groupNode);
            groupLinks.push({
                id: `${groupNode.id}__link`,
                sourceNodeId: rank < 0 ? groupNode.id : mainNode.id,
                sourceColumnId: '',
                targetNodeId: rank < 0 ? mainNode.id : groupNode.id,
                targetColumnId: '',
                type: DEFAULT_RELATION_TYPE,
                properties: {
                    relationCount,
                    relationLevel: 'summary_group',
                    isGroup: true,
                    hiddenNodeCount: hidden.length,
                },
            });
        });
    }

    const hiddenNodeCount = Array.from(hiddenByRank.values()).reduce((sum, item) => sum + item.length, 0);
    return {
        nodes: [...baseNodes.filter(node => visibleIds.has(node.id)), ...groupNodes],
        links: [...visibleLinks, ...groupLinks],
        stats: {
            originalNodeCount: baseNodes.length,
            originalLinkCount: filteredLinks.length,
            visibleNodeCount: visibleIds.size + groupNodes.length,
            visibleLinkCount: visibleLinks.length + groupLinks.length,
            hiddenNodeCount,
            hiddenLinkCount: Math.max(0, filteredLinks.length - visibleLinks.length),
            compactApplied: true,
            compactReason: baseNodes.length > 30 ? '节点过多' : '连线过多',
        } satisfies LineageGraphStats,
    };
};

export const buildLocalFieldTraceGraph = (options: {
    tableNodes: NodeData[];
    tableLinks: LinkData[];
    fieldNodes: NodeData[];
    fieldLinks: LinkData[];
    selectedTable: string | null;
    focusedNodeId?: string | null;
    focusedLinkId?: string | null;
}) => {
    const {
        tableNodes,
        tableLinks,
        fieldNodes,
        fieldLinks,
        selectedTable,
        focusedNodeId,
        focusedLinkId,
    } = options;

    if (fieldNodes.length === 0 || fieldLinks.length === 0) {
        return { nodes: tableNodes, links: tableLinks };
    }

    const tableNodeMap = new Map(tableNodes.map(node => [node.id, node]));
    const focusTitles = new Set<string>();
    const pairTitles = new Set<string>();

    const focusedLink = focusedLinkId ? tableLinks.find(link => link.id === focusedLinkId) : null;
    if (focusedLink) {
        const sourceTitle = tableNodeMap.get(focusedLink.sourceNodeId)?.title;
        const targetTitle = tableNodeMap.get(focusedLink.targetNodeId)?.title;
        if (sourceTitle) {
            focusTitles.add(sourceTitle);
            pairTitles.add(sourceTitle);
        }
        if (targetTitle) {
            focusTitles.add(targetTitle);
            pairTitles.add(targetTitle);
        }
    } else {
        const focusNode = tableNodeMap.get(focusedNodeId || '') || findMainNode(tableNodes, selectedTable);
        if (focusNode) {
            focusTitles.add(focusNode.title);
            tableLinks.forEach(link => {
                if (link.sourceNodeId === focusNode.id) {
                    const targetTitle = tableNodeMap.get(link.targetNodeId)?.title;
                    if (targetTitle) focusTitles.add(targetTitle);
                }
                if (link.targetNodeId === focusNode.id) {
                    const sourceTitle = tableNodeMap.get(link.sourceNodeId)?.title;
                    if (sourceTitle) focusTitles.add(sourceTitle);
                }
            });
        }
    }

    if (focusTitles.size === 0) {
        return { nodes: tableNodes, links: tableLinks };
    }

    const fieldNodeById = new Map(fieldNodes.map(node => [node.id, node]));
    const fieldTableMatches = (nodeId: string) => {
        const node = fieldNodeById.get(nodeId);
        return !!node && Array.from(focusTitles).some(title => sameTableLoose(node.title, title));
    };
    const fieldPairMatches = (link: LinkData) => {
        if (pairTitles.size !== 2) {
            return true;
        }
        const sourceTitle = fieldNodeById.get(link.sourceNodeId)?.title || '';
        const targetTitle = fieldNodeById.get(link.targetNodeId)?.title || '';
        return Array.from(pairTitles).some(title => sameTableLoose(sourceTitle, title))
            && Array.from(pairTitles).some(title => sameTableLoose(targetTitle, title));
    };

    const scopedLinks = fieldLinks.filter(link => (
        fieldTableMatches(link.sourceNodeId)
        && fieldTableMatches(link.targetNodeId)
        && fieldPairMatches(link)
    ));
    const scopedNodeIds = new Set<string>();
    scopedLinks.forEach(link => {
        scopedNodeIds.add(link.sourceNodeId);
        scopedNodeIds.add(link.targetNodeId);
    });
    fieldNodes.forEach(node => {
        if (Array.from(focusTitles).some(title => sameTableLoose(node.title, title))) {
            scopedNodeIds.add(node.id);
        }
    });

    const scopedNodes = fieldNodes.filter(node => scopedNodeIds.has(node.id));
    if (scopedNodes.length === 0) {
        return { nodes: tableNodes, links: tableLinks };
    }

    return { nodes: scopedNodes, links: scopedLinks };
};
