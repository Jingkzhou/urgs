import React from 'react';
import { Modal, Form, Input, Button, Tag } from 'antd';
import { Plus } from 'lucide-react';
import type { KnowledgeTag } from '../../api/knowledge';

const TAG_NAME_MAX_LENGTH = 50;

interface TagManagerModalProps {
    open: boolean;
    tags: KnowledgeTag[];
    onClose: () => void;
    onCreateTag: (values: { name: string; color?: string }) => Promise<void>;
    onDeleteTag: (id: number) => Promise<void>;
}

const TagManagerModal: React.FC<TagManagerModalProps> = ({ open, tags, onClose, onCreateTag, onDeleteTag }) => {
    const [form] = Form.useForm();

    const handleCreate = async (values: { name: string; color?: string }) => {
        await onCreateTag(values);
        form.resetFields();
    };

    return (
        <Modal
            title="标签管理"
            open={open}
            onCancel={onClose}
            footer={null}
        >
            <div className="mb-6">
                <Form form={form} layout="inline" onFinish={handleCreate}>
                    <Form.Item
                        name="name"
                        rules={[
                            { required: true, message: '请输入标签名称' },
                            { max: TAG_NAME_MAX_LENGTH, message: `标签名称不能超过 ${TAG_NAME_MAX_LENGTH} 个字符` },
                        ]}
                        style={{ flex: 1 }}
                    >
                        <Input placeholder="新标签名称" maxLength={TAG_NAME_MAX_LENGTH} showCount />
                    </Form.Item>
                    <Form.Item name="color" initialValue="#3b82f6">
                        <Input type="color" className="w-12 p-0 h-8 border-none" />
                    </Form.Item>
                    <Form.Item>
                        <Button type="primary" htmlType="submit" icon={<Plus size={14} />} />
                    </Form.Item>
                </Form>
            </div>
            <div className="flex flex-wrap gap-2">
                {tags.map(t => (
                    <Tag
                        key={t.id}
                        color={t.color}
                        closable
                        onClose={() => onDeleteTag(t.id)}
                        className="px-3 py-1 rounded-full border-none shadow-sm"
                    >
                        <span className="inline-block max-w-64 truncate align-bottom" title={t.name}>
                            {t.name}
                        </span>
                    </Tag>
                ))}
            </div>
        </Modal>
    );
};

export default TagManagerModal;
