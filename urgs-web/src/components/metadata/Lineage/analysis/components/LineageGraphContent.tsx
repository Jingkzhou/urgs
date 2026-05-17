import React from 'react';
import { Empty, Spin } from 'antd';
import LineageListView from './LineageListView';
import ColumnLineageDiagram from './ColumnLineageDiagram';
import { LinkData, NodeData } from '../types';

interface LineageGraphContentProps {
    graphLoading: boolean;
    nodes: NodeData[];
    links: LinkData[];
    listLoading: boolean;
    listNodes: NodeData[];
    listLinks: LinkData[];
    viewMode: 'canvas' | 'list';
    selectedTable: string | null;
    selectedField: { nodeId: string; colId: string } | null;
    onTableDoubleClick?: (tableName: string, qualifiedName: string) => void;
}

const LineageGraphContent: React.FC<LineageGraphContentProps> = ({
    graphLoading,
    nodes,
    links,
    listLoading,
    listNodes,
    listLinks,
    viewMode,
    selectedTable,
    selectedField,
    onTableDoubleClick,
}) => {
    const canvasNodes = listNodes.length > 0 ? listNodes : nodes;
    const canvasLinks = listNodes.length > 0 ? listLinks : links;
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
                            selectedTable={selectedTable}
                            selectedField={selectedField}
                            onTableDoubleClick={onTableDoubleClick}
                        />
                    ) : (
                        <LineageListView
                            nodes={listNodes}
                            links={listLinks}
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
