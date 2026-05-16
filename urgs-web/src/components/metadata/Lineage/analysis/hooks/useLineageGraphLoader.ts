import { useCallback, useState } from 'react';
import { message } from 'antd';
import { getLineageGraph, LineageGraphDirection, LineageGraphResponse } from '@/api/lineage';
import { LinkData, NodeData } from '../types';
import { processLayoutImpact, processLayoutTrace } from '../utils/lineageLayout';

export const useLineageGraphLoader = (direction: LineageGraphDirection) => {
    const [selectedTable, setSelectedTable] = useState<string | null>(null);
    const [selectedQualifiedName, setSelectedQualifiedName] = useState<string | null>(null);
    const [selectedField, setSelectedField] = useState<{ nodeId: string; colId: string } | null>(null);
    const [nodes, setNodes] = useState<NodeData[]>([]);
    const [links, setLinks] = useState<LinkData[]>([]);
    const [listNodes, setListNodes] = useState<NodeData[]>([]);
    const [listLinks, setListLinks] = useState<LinkData[]>([]);
    const [graphMeta, setGraphMeta] = useState<Partial<LineageGraphResponse> | null>(null);
    const [graphLoading, setGraphLoading] = useState(false);
    const [listLoading, setListLoading] = useState(false);
    const [listDetailsLoaded, setListDetailsLoaded] = useState(false);
    const layoutGraph = useCallback((response: LineageGraphResponse, tableName: string) => (
        direction === 'downstream'
            ? processLayoutImpact(response.nodes, response.edges, tableName)
            : processLayoutTrace(response.nodes, response.edges, tableName)
    ), [direction]);

    const handleSelectTable = useCallback(async (tableName: string, qualifiedName?: string, targetColName?: string) => {
        setGraphLoading(true);
        setSelectedTable(tableName);
        setSelectedQualifiedName(qualifiedName || tableName);
        try {
            const response = await getLineageGraph(tableName, targetColName, {
                depth: 2,
                qualifiedName,
                direction,
                limit: 1000,
                relationLevel: targetColName ? 'column' : 'table',
            });

            if (!response) {
                return;
            }
            if (response.nodes && response.nodes.length === 0) {
                message.info('未找到血缘信息');
                setNodes([]);
                setLinks([]);
                setListNodes([]);
                setListLinks([]);
                setGraphMeta(null);
                return;
            }

            const layoutResult = layoutGraph(response, tableName);
            setNodes(layoutResult.layoutedNodes);
            setLinks(layoutResult.layoutedLinks);
            setGraphMeta(response);

            if (targetColName) {
                setListNodes(layoutResult.layoutedNodes);
                setListLinks(layoutResult.layoutedLinks);
                setListDetailsLoaded(true);
                const tableNode = layoutResult.layoutedNodes.find(node => node.title === tableName);
                const column = tableNode?.columns.find(item => item.name === targetColName);
                setSelectedField(tableNode && column ? { nodeId: tableNode.id, colId: column.id } : null);
            } else {
                setListNodes([]);
                setListLinks([]);
                setListDetailsLoaded(false);
                setSelectedField(null);
            }
        } catch (error: any) {
            message.error(`加载血缘失败: ${error.message}`);
        } finally {
            setGraphLoading(false);
        }
    }, [direction, layoutGraph]);

    const loadListDetails = useCallback(async () => {
        if (!selectedTable) {
            return;
        }
        setListLoading(true);
        try {
            const response = await getLineageGraph(selectedTable, undefined, {
                depth: 2,
                qualifiedName: selectedQualifiedName || undefined,
                direction,
                limit: 5000,
                relationLevel: 'column',
            });
            if (!response || !response.nodes || response.nodes.length === 0) {
                setListNodes([]);
                setListLinks([]);
                setListDetailsLoaded(true);
                return;
            }
            const layoutResult = layoutGraph(response, selectedTable);
            setListNodes(layoutResult.layoutedNodes);
            setListLinks(layoutResult.layoutedLinks);
            setListDetailsLoaded(true);
        } catch (error: any) {
            message.error(`加载字段级明细失败: ${error.message}`);
        } finally {
            setListLoading(false);
        }
    }, [direction, layoutGraph, selectedQualifiedName, selectedTable]);

    return {
        selectedTable,
        selectedQualifiedName,
        selectedField,
        nodes,
        links,
        listNodes,
        listLinks,
        graphMeta,
        graphLoading,
        listLoading,
        listDetailsLoaded,
        handleSelectTable,
        loadListDetails,
    };
};
