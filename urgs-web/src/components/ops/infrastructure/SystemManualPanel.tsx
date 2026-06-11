import React, { useState } from 'react';
import { Button, Empty, Form, Input, List, Modal, Popconfirm, Space, Upload, message } from 'antd';
import type { UploadProps } from 'antd';
import { BookOpen, Download, Eye, FileText, Plus, Trash2, UploadCloud } from 'lucide-react';
import {
    createInfrastructureSystemManual,
    deleteInfrastructureSystemManual,
    uploadCommonFile,
    type InfrastructureSystemManual,
} from '@/api/ops';
import type { SsoConfig } from '@/api/version';
import type { KnowledgeDocument } from '@/api/knowledge';
import FilePreviewModal from '@/components/knowledge/FilePreviewModal';
import { getSystemName } from './utils';

interface SystemManualPanelProps {
    manuals: InfrastructureSystemManual[];
    selectedSystemId: number | 'all';
    systems: SsoConfig[];
    onChanged: () => void;
}

const formatFileSize = (value?: number) => {
    if (!value) return '-';
    if (value < 1024 * 1024) return `${(value / 1024).toFixed(1)} KB`;
    return `${(value / 1024 / 1024).toFixed(1)} MB`;
};

const toPreviewDocument = (manual: InfrastructureSystemManual): KnowledgeDocument => ({
    id: manual.id || 0,
    userId: 0,
    folderId: null,
    title: manual.title,
    scope: 'shared',
    sourceDocId: null,
    fileUrl: manual.fileUrl,
    fileName: manual.fileName,
    fileSize: manual.fileSize || null,
    isFavorite: 0,
    viewCount: 0,
    createTime: manual.createdAt || '',
    updateTime: manual.updatedAt || '',
});

const SystemManualPanel: React.FC<SystemManualPanelProps> = ({
    manuals,
    selectedSystemId,
    systems,
    onChanged,
}) => {
    const [modalOpen, setModalOpen] = useState(false);
    const [previewManual, setPreviewManual] = useState<InfrastructureSystemManual | null>(null);
    const [uploading, setUploading] = useState(false);
    const [form] = Form.useForm();

    const canUpload = selectedSystemId !== 'all';
    const previewIndex = previewManual
        ? manuals.findIndex(manual => manual.id === previewManual.id)
        : -1;

    const handleUpload: NonNullable<UploadProps['customRequest']> = async (options) => {
        const { file, onSuccess, onError } = options;
        if (!canUpload) {
            message.warning('请先选择具体系统');
            onError?.(new Error('system required'));
            return;
        }
        try {
            setUploading(true);
            const values = await form.validateFields();
            const uploadResult = await uploadCommonFile(file as File);
            await createInfrastructureSystemManual({
                appSystemId: selectedSystemId,
                title: values.title || uploadResult.name,
                description: values.description,
                fileName: uploadResult.name,
                fileUrl: uploadResult.url,
                fileSize: (file as File).size,
            });
            message.success('上传成功');
            form.resetFields();
            setModalOpen(false);
            onSuccess?.(uploadResult);
            onChanged();
        } catch (error: any) {
            message.error(error?.message || '上传失败');
            onError?.(error);
        } finally {
            setUploading(false);
        }
    };

    const handleDelete = async (id?: number) => {
        if (!id) return;
        await deleteInfrastructureSystemManual(id);
        message.success('删除成功');
        if (previewManual?.id === id) {
            setPreviewManual(null);
        }
        onChanged();
    };

    const handleDownload = (doc: KnowledgeDocument) => {
        if (!doc.fileUrl) return;
        const link = document.createElement('a');
        link.href = doc.fileUrl;
        link.download = doc.fileName || doc.title || 'manual';
        link.target = '_blank';
        link.click();
    };

    return (
        <div className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
            <div className="mb-3 flex items-center justify-between">
                <div>
                    <h3 className="flex items-center gap-2 text-base font-bold text-slate-800">
                        <BookOpen size={18} className="text-blue-600" />
                        运维手册
                    </h3>
                    <p className="mt-1 text-xs text-slate-500">
                        {canUpload ? getSystemName(systems, selectedSystemId) : '选择具体系统后可上传资料'}
                    </p>
                </div>
                <Button
                    type="primary"
                    icon={<Plus size={14} />}
                    disabled={!canUpload}
                    onClick={() => setModalOpen(true)}
                >
                    上传手册
                </Button>
            </div>

            {manuals.length === 0 ? (
                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无运维手册" />
            ) : (
                <List
                    size="small"
                    dataSource={manuals}
                    renderItem={manual => (
                        <List.Item
                            actions={[
                                <Button
                                    key="preview"
                                    type="link"
                                    size="small"
                                    icon={<Eye size={13} />}
                                    onClick={() => setPreviewManual(manual)}
                                >
                                    预览
                                </Button>,
                                <Button
                                    key="download"
                                    type="link"
                                    size="small"
                                    icon={<Download size={13} />}
                                    href={manual.fileUrl}
                                    target="_blank"
                                >
                                    下载
                                </Button>,
                                <Popconfirm
                                    key="delete"
                                    title="确定删除该手册记录？"
                                    onConfirm={() => handleDelete(manual.id)}
                                    okText="删除"
                                    okButtonProps={{ danger: true }}
                                >
                                    <Button type="link" danger size="small" icon={<Trash2 size={13} />}>删除</Button>
                                </Popconfirm>,
                            ]}
                        >
                            <List.Item.Meta
                                avatar={<FileText size={18} className="mt-1 text-blue-500" />}
                                title={<span className="font-medium text-slate-800">{manual.title}</span>}
                                description={(
                                    <Space size={10} wrap className="text-xs text-slate-500">
                                        {selectedSystemId === 'all' && <span>{getSystemName(systems, manual.appSystemId)}</span>}
                                        <span>{manual.fileName}</span>
                                        <span>{formatFileSize(manual.fileSize)}</span>
                                        {manual.description && <span>{manual.description}</span>}
                                    </Space>
                                )}
                            />
                        </List.Item>
                    )}
                />
            )}

            <Modal
                title="上传运维手册"
                open={modalOpen}
                onCancel={() => setModalOpen(false)}
                footer={null}
                destroyOnClose
            >
                <Form form={form} layout="vertical" className="mt-4">
                    <Form.Item name="title" label="手册标题" rules={[{ required: true, message: '请输入手册标题' }]}>
                        <Input placeholder="例如：生产部署手册" />
                    </Form.Item>
                    <Form.Item name="description" label="说明">
                        <Input.TextArea rows={3} placeholder="资料用途、适用环境等" />
                    </Form.Item>
                    <Upload customRequest={handleUpload} showUploadList={false}>
                        <Button block loading={uploading} icon={<UploadCloud size={14} />}>
                            选择文件并上传
                        </Button>
                    </Upload>
                </Form>
            </Modal>

            <FilePreviewModal
                open={!!previewManual}
                document={previewManual ? toPreviewDocument(previewManual) : null}
                onClose={() => setPreviewManual(null)}
                onDownload={handleDownload}
                hasPrev={previewIndex > 0}
                hasNext={previewIndex >= 0 && previewIndex < manuals.length - 1}
                onPrev={() => {
                    if (previewIndex > 0) setPreviewManual(manuals[previewIndex - 1]);
                }}
                onNext={() => {
                    if (previewIndex >= 0 && previewIndex < manuals.length - 1) {
                        setPreviewManual(manuals[previewIndex + 1]);
                    }
                }}
            />
        </div>
    );
};

export default SystemManualPanel;
