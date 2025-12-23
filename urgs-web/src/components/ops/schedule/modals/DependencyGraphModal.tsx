import React from 'react';
import { Modal } from 'antd';
import WorkflowCanvas from '../../WorkflowCanvas';

interface DependencyGraphModalProps {
    visible: boolean;
    onCancel: () => void;
    nodes: any[];
    edges: any[];
    onNodeContextMenu?: (event: React.MouseEvent, node: any) => void;
    showStatus?: boolean;
}

const DependencyGraphModal: React.FC<DependencyGraphModalProps> = ({ visible, onCancel, nodes, edges, onNodeContextMenu, showStatus = false }) => {
    return (
        <Modal
            title="依赖关系图"
            open={visible}
            onCancel={onCancel}
            width="100vw"
            style={{ top: 0, maxWidth: '100vw', padding: 0, margin: 0 }}
            styles={{ body: { height: 'calc(100vh - 55px)', padding: 0, overflow: 'hidden' } }}
            footer={null}
            destroyOnHidden
            maskClosable={false}
        >
            <div className="h-full w-full bg-slate-50">
                <WorkflowCanvas
                    key={nodes.map(n => n.id).join(',')} // Force remount when nodes change
                    initialNodes={nodes}
                    initialEdges={edges}
                    autoLayoutOnMount={true}
                    readOnly={true}
                    onNodeContextMenu={onNodeContextMenu}
                    showStatus={showStatus}
                />
            </div>
        </Modal>
    );
};

export default DependencyGraphModal;
