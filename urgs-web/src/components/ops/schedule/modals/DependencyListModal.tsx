import React from 'react';
import { Modal, Table, Tag } from 'antd';

interface DependencyListModalProps {
    visible: boolean;
    onCancel: () => void;
    list: any[];
    task: any;
}

const DependencyListModal: React.FC<DependencyListModalProps> = ({ visible, onCancel, list, task }) => {
    const columns = [
        { title: '任务名称', dataIndex: 'name', key: 'name' },
        { title: '任务类型', dataIndex: 'type', key: 'type', render: (text: string) => <Tag>{text}</Tag> },
        { title: '任务ID', dataIndex: 'id', key: 'id', render: (text: string) => <span className="text-xs text-gray-400">{text}</span> },
    ];

    return (
        <Modal
            title={`依赖于 "${task?.name}" 的任务`}
            open={visible}
            onCancel={onCancel}
            width={800}
            footer={null}
            destroyOnHidden
        >
            <div className="max-h-[500px] overflow-auto">
                {list.length > 0 ? (
                    <Table
                        dataSource={list}
                        columns={columns}
                        rowKey="id"
                        pagination={false}
                        size="small"
                    />
                ) : (
                    <div className="text-center py-8 text-slate-500">
                        没有任务依赖于此任务
                    </div>
                )}
            </div>
        </Modal>
    );
};

export default DependencyListModal;
