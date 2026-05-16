import React from 'react';
import { Empty, Spin } from 'antd';
import LineageListView from './LineageListView';
import G6LineageDiagram from './G6LineageDiagram';
import { LinkData, NodeData } from '../types';
import type { LineageGraphResponse } from '@/api/lineage';

interface LineageGraphContentProps {
    graphLoading: boolean;
    nodes: NodeData[];
    links: LinkData[];
    listLoading: boolean;
    listNodes: NodeData[];
    listLinks: LinkData[];
    mode: 'trace' | 'impact';
    viewMode: 'canvas' | 'list';
    selectedTable: string | null;
    selectedField: { nodeId: string; colId: string } | null;
    graphMeta?: Partial<LineageGraphResponse> | null;
    onGenerateReport?: () => void;
}

const LineageGraphContent: React.FC<LineageGraphContentProps> = ({
    graphLoading,
    nodes,
    links,
    listLoading,
    listNodes,
    listLinks,
    mode,
    viewMode,
    selectedTable,
    selectedField,
    graphMeta,
    onGenerateReport,
}) => {
    return (
        <Spin spinning={viewMode === 'list' ? listLoading : graphLoading} description="加载血缘关系...">
            <div style={{ height: '100%', width: '100%' }}>
                {nodes.length > 0 ? (
                    viewMode === 'canvas' ? (
                        <G6LineageDiagram
                            mode={mode}
                            nodes={nodes}
                            links={links}
                            selectedTable={selectedTable}
                            selectedField={selectedField}
                            graphMeta={graphMeta}
                            onGenerateReport={onGenerateReport}
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
                    !graphLoading && <Empty description="请从左侧选择表查看血缘" style={{ marginTop: '100px' }} />
                )}
            </div>
        </Spin>
    );
};

export default LineageGraphContent;
