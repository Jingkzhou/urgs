import React, { useEffect } from 'react';
import { Modal, Form, Input } from 'antd';
import type { FolderTreeNode } from '../../api/knowledge';

const FOLDER_NAME_MAX_LENGTH = 100;

interface FolderModalProps {
    open: boolean;
    editingFolder: FolderTreeNode | null;
    onSave: (values: { name: string }) => void;
    onCancel: () => void;
}

const FolderModal: React.FC<FolderModalProps> = ({ open, editingFolder, onSave, onCancel }) => {
    const [form] = Form.useForm();

    useEffect(() => {
        if (open) {
            if (editingFolder) {
                form.setFieldsValue({ name: editingFolder.name });
            } else {
                form.resetFields();
            }
        }
    }, [open, editingFolder, form]);

    return (
        <Modal
            title={editingFolder ? '重命名文件夹' : '新建文件夹'}
            open={open}
            onCancel={onCancel}
            onOk={() => form.submit()}
            destroyOnHidden
        >
            <Form form={form} layout="vertical" onFinish={onSave}>
                <Form.Item
                    name="name"
                    label="名称"
                    rules={[
                        { required: true, message: '请输入名称' },
                        { max: FOLDER_NAME_MAX_LENGTH, message: `名称不能超过 ${FOLDER_NAME_MAX_LENGTH} 个字符` },
                    ]}
                >
                    <Input
                        placeholder="文件夹名称"
                        autoFocus
                        maxLength={FOLDER_NAME_MAX_LENGTH}
                        showCount
                    />
                </Form.Item>
            </Form>
        </Modal>
    );
};

export default FolderModal;
