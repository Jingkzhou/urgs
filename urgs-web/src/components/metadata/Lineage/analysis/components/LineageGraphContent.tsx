import React from 'react';
import { Empty, Spin } from 'antd';
import LineageDiagramImpact from './LineageDiagram';
import LineageDiagramTrace from '../../origin/components/LineageDiagram';
import LineageListView from './LineageListView';
import { LinkData, NodeData, ViewportState } from '../types';

interface LineageGraphContentProps {
    graphLoading: boolean;
    nodes: NodeData[];
    links: LinkData[];
    mode: 'trace' | 'impact';
    viewMode: 'canvas' | 'list';
    viewport: ViewportState;
    setViewport: React.Dispatch<React.SetStateAction<ViewportState>>;
    setNodes: React.Dispatch<React.SetStateAction<NodeData[]>>;
    selectedTable: string | null;
    selectedField: { nodeId: string; colId: string } | null;
    setSelectedField: React.Dispatch<React.SetStateAction<{ nodeId: string; colId: string } | null>>;
    onGenerateReport: () => void;
}

const LineageGraphContent: React.FC<LineageGraphContentProps> = ({
    graphLoading,
    nodes,
    links,
    mode,
    viewMode,
    viewport,
    setViewport,
    setNodes,
    selectedTable,
    selectedField,
    setSelectedField,
    onGenerateReport,
}) => {
    return (
        <Spin spinning={graphLoading} description="加载血缘关系...">
            <div style={{ height: '100%', width: '100%' }}>
                {nodes.length > 0 ? (
                    viewMode === 'canvas' ? (
                        mode === 'impact' ? (
                            <LineageDiagramImpact
                                viewport={viewport}
                                setViewport={setViewport}
                                nodes={nodes}
                                setNodes={setNodes}
                                links={links}
                                selectedTable={selectedTable}
                                selectedField={selectedField}
                                onFieldSelect={setSelectedField}
                                onGenerateReport={onGenerateReport}
                            />
                        ) : (
                            <LineageDiagramTrace
                                viewport={viewport}
                                setViewport={setViewport}
                                nodes={nodes}
                                setNodes={setNodes}
                                links={links}
                                selectedTable={selectedTable}
                                selectedField={selectedField}
                                onFieldSelect={setSelectedField}
                            />
                        )
                    ) : (
                        <LineageListView
                            nodes={nodes}
                            links={links}
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
