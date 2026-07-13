import React from 'react';
import { Empty, Spin } from 'antd';
import LineageListView from './LineageListView';
import ColumnLineageDiagram from './ColumnLineageDiagram';
import { LinkData, NodeData } from '../types';
import {
    LineageDisplayMode,
    buildEndToEndGraph,
    buildEndToEndRelations,
} from '../utils/endToEndLineage';

interface LineageGraphContentProps {
    graphLoading: boolean;
    nodes: NodeData[];
    links: LinkData[];
    listLoading: boolean;
    listNodes: NodeData[];
    listLinks: LinkData[];
    listDetailsLoaded: boolean;
    viewMode: 'canvas' | 'list';
    displayMode: LineageDisplayMode;
    selectedTable: string | null;
    selectedField: { nodeId: string; colId: string } | null;
    onLoadFieldDetails?: () => Promise<void>;
    onTableDoubleClick?: (tableName: string, qualifiedName: string, objectUid?: string) => void;
    onFieldDoubleClick?: (tableName: string, qualifiedName: string, columnName: string, objectUid?: string) => void;
}

const LineageGraphContent: React.FC<LineageGraphContentProps> = ({
    graphLoading,
    nodes,
    links,
    listLoading,
    listNodes,
    listLinks,
    listDetailsLoaded,
    viewMode,
    displayMode,
    selectedTable,
    selectedField,
    onLoadFieldDetails,
    onTableDoubleClick,
    onFieldDoubleClick,
}) => {
    const sourceNodes = listDetailsLoaded ? listNodes : nodes;
    const sourceLinks = listDetailsLoaded ? listLinks : links;
    const endToEndRelations = buildEndToEndRelations(sourceNodes, sourceLinks, selectedTable, selectedField);
    const endToEndGraph = buildEndToEndGraph(sourceNodes, endToEndRelations);
    const isEndToEnd = displayMode !== 'full';
    const canvasNodes = isEndToEnd ? endToEndGraph.nodes : nodes;
    const canvasLinks = isEndToEnd ? endToEndGraph.links : links;
    const activeNodes = viewMode === 'canvas' ? canvasNodes : listNodes;

    return (
        <div style={{ flex: 1, minHeight: viewMode === 'canvas' ? 640 : 0, width: '100%' }}>
            <Spin spinning={viewMode === 'list' ? listLoading : graphLoading} description="加载血缘关系...">
                <div style={{ height: '100%', minHeight: viewMode === 'canvas' ? 640 : 0, width: '100%' }}>
                {activeNodes.length > 0 ? (
                    viewMode === 'canvas' ? (
                        <ColumnLineageDiagram
                            nodes={canvasNodes}
                            links={canvasLinks}
                            fieldNodes={listNodes}
                            fieldLinks={listLinks}
                            fieldLoading={listLoading}
                            fieldDetailsLoaded={listDetailsLoaded}
                            selectedTable={selectedTable}
                            selectedField={selectedField}
                            onLoadFieldDetails={onLoadFieldDetails}
                            onTableDoubleClick={onTableDoubleClick}
                            onFieldDoubleClick={onFieldDoubleClick}
                        />
                    ) : (
                        <LineageListView
                            nodes={listNodes}
                            links={listLinks}
                            displayMode={displayMode}
                            endToEndRelations={endToEndRelations}
                            selectedTable={selectedTable}
                            selectedField={selectedField}
                        />
                    )
                ) : (
                    !graphLoading && (
                        <Empty
                            description={selectedTable ? '暂无流程图数据，请切换查询方向或选择其他表' : '请从左侧选择表查看血缘'}
                            style={{ marginTop: '100px' }}
                        />
                    )
                )}
                </div>
            </Spin>
        </div>
    );
};

export default LineageGraphContent;
