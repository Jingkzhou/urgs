import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Drawer, Timeline } from 'antd';
import { Plus, Trash2, Edit, RefreshCw, Send, CheckCircle, XCircle, Clock, FileText, Rocket } from 'lucide-react';
import {
    getReleaseRecords, createReleaseRecord, updateReleaseRecord, deleteReleaseRecord,
    submitForApproval, approveRelease, rejectRelease, markAsReleased, getApprovalHistory,
    getSsoList,
    ReleaseRecord, ApprovalRecord, SsoConfig
} from '@/api/version';
import PageHeader from '../common/PageHeader';
import StatusTag from '../common/StatusTag';

const { Option } = Select;
const { TextArea } = Input;

const statusConfig: Record<string, { color: string; icon: React.ReactNode; label: string }> = {
    draft: { color: 'default', icon: <FileText size={14} />, label: '草稿' },
    pending: { color: 'processing', icon: <Clock size={14} />, label: '待审批' },
    approved: { color: 'success', icon: <CheckCircle size={14} />, label: '已审批' },
    rejected: { color: 'error', icon: <XCircle size={14} />, label: '已拒绝' },
    released: { color: 'purple', icon: <Rocket size={14} />, label: '已发布' },
};

const releaseTypeConfig: Record<string, { color: string; label: string }> = {
    feature: { color: 'blue', label: '功能发布' },
    bugfix: { color: 'orange', label: '问题修复' },
    hotfix: { color: 'red', label: '紧急修复' },
};

interface Props {
    ssoId?: number;
}

const ReleaseLedger: React.FC<Props> = ({ ssoId }) => {
    const [records, setRecords] = useState<ReleaseRecord[]>([]);
    const [ssoList, setSsoList] = useState<SsoConfig[]>([]);
    const [loading, setLoading] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingRecord, setEditingRecord] = useState<ReleaseRecord | null>(null);
    const [form] = Form.useForm();

    // 审批抽屉
    const [approvalDrawerVisible, setApprovalDrawerVisible] = useState(false);
    const [selectedRecord, setSelectedRecord] = useState<ReleaseRecord | null>(null);
    const [approvalHistory, setApprovalHistory] = useState<ApprovalRecord[]>([]);
    const [approvalComment, setApprovalComment] = useState('');

    useEffect(() => {
        fetchRecords();
        fetchSsoList();
    }, []);

    const fetchRecords = async () => {
        setLoading(true);
        try {
            const data = await getReleaseRecords({ ssoId });
            setRecords(data || []);
        } catch (error) {
            message.error('获取发布记录失败');
        } finally {
            setLoading(false);
        }
    };

    const fetchSsoList = async () => {
        try {
            const data = await getSsoList();
            setSsoList(data || []);
        } catch (error) {
            console.error('获取监管系统列表失败', error);
        }
    };

    const handleAdd = () => {
        setEditingRecord(null);
        form.resetFields();
        form.setFieldsValue({
            releaseType: 'feature',
            ssoId: ssoId
        });
        setModalVisible(true);
    };

    const handleEdit = (record: ReleaseRecord) => {
        setEditingRecord(record);
        form.setFieldsValue(record);
        setModalVisible(true);
    };

    const handleDelete = async (id: number) => {
        try {
            await deleteReleaseRecord(id);
            message.success('删除成功');
            fetchRecords();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            if (editingRecord?.id) {
                await updateReleaseRecord(editingRecord.id, values);
                message.success('更新成功');
            } else {
                await createReleaseRecord(values);
                message.success('创建成功');
            }
            setModalVisible(false);
            fetchRecords();
        } catch (error) {
            message.error('保存失败');
        }
    };

    const handleSubmitApproval = async (record: ReleaseRecord) => {
        try {
            await submitForApproval(record.id!);
            message.success('已提交审批');
            fetchRecords();
        } catch (error) {
            message.error('提交失败');
        }
    };

    const openApprovalDrawer = async (record: ReleaseRecord) => {
        setSelectedRecord(record);
        setApprovalDrawerVisible(true);
        setApprovalComment('');
        try {
            const history = await getApprovalHistory(record.id!);
            setApprovalHistory(history || []);
        } catch (error) {
            console.error('获取审批历史失败', error);
        }
    };

    const handleApprove = async () => {
        if (!selectedRecord) return;
        try {
            await approveRelease(selectedRecord.id!, { comment: approvalComment });
            message.success('审批通过');
            setApprovalDrawerVisible(false);
            fetchRecords();
        } catch (error) {
            message.error('审批失败');
        }
    };

    const handleReject = async () => {
        if (!selectedRecord) return;
        try {
            await rejectRelease(selectedRecord.id!, { comment: approvalComment });
            message.success('已拒绝');
            setApprovalDrawerVisible(false);
            fetchRecords();
        } catch (error) {
            message.error('操作失败');
        }
    };

    const handleRelease = async (record: ReleaseRecord) => {
        try {
            await markAsReleased(record.id!);
            message.success('已标记为发布');
            fetchRecords();
        } catch (error) {
            message.error('操作失败');
        }
    };

    const columns = [
        {
            title: '发布标题',
            dataIndex: 'title',
            key: 'title',
            render: (text: string, record: ReleaseRecord) => (
                <div>
                    <div className="font-medium">{text}</div>
                    {record.version && <div className="text-xs text-slate-500">v{record.version}</div>}
                </div>
            ),
        },
        !ssoId ? {
            title: '关联系统',
            dataIndex: 'ssoId',
            key: 'ssoId',
            render: (ssoId: number) => ssoList.find(s => s.id === ssoId)?.name || '-',
        } : null,
        {
            title: '类型',
            dataIndex: 'releaseType',
            key: 'releaseType',
            render: (type: string) => {
                const config = releaseTypeConfig[type] || releaseTypeConfig.feature;
                return <Tag color={config.color}>{config.label}</Tag>;
            },
        },
        {
            title: '状态',
            dataIndex: 'status',
            key: 'status',
            render: (status: string) => (
                <StatusTag status={status} config={statusConfig} />
            ),
        },
        { title: '创建时间', dataIndex: 'createdAt', key: 'createdAt' },
        { title: '发布时间', dataIndex: 'releasedAt', key: 'releasedAt' },
        {
            title: '操作',
            key: 'actions',
            render: (_: any, record: ReleaseRecord) => (
                <Space>
                    {record.status === 'draft' && (
                        <>
                            <Button type="text" icon={<Edit size={14} />} onClick={() => handleEdit(record)} />
                            <Popconfirm title="提交审批后不可编辑，确定？" onConfirm={() => handleSubmitApproval(record)}>
                                <Button type="primary" size="small" icon={<Send size={14} />}>提交审批</Button>
                            </Popconfirm>
                            <Popconfirm title="确定删除？" onConfirm={() => handleDelete(record.id!)}>
                                <Button type="text" danger icon={<Trash2 size={14} />} />
                            </Popconfirm>
                        </>
                    )}
                    {record.status === 'pending' && (
                        <Button type="primary" size="small" onClick={() => openApprovalDrawer(record)}>审批</Button>
                    )}
                    {record.status === 'approved' && (
                        <Popconfirm title="确定标记为已发布？" onConfirm={() => handleRelease(record)}>
                            <Button type="primary" size="small" icon={<Rocket size={14} />}>发布</Button>
                        </Popconfirm>
                    )}
                    <Button type="text" size="small" onClick={() => openApprovalDrawer(record)}>详情</Button>
                </Space>
            ),
        },
    ].filter(Boolean) as any;

    return (
        <div className="space-y-4">
            <PageHeader
                title="版本发布台账"
                extra={
                    <Space>
                        <Button icon={<RefreshCw className="w-4 h-4" />} onClick={fetchRecords}>刷新</Button>
                        <Button type="primary" icon={<Plus className="w-4 h-4" />} onClick={handleAdd}>
                            新建发布
                        </Button>
                    </Space>
                }
            />

            <Table
                columns={columns}
                dataSource={records}
                rowKey="id"
                loading={loading}
                pagination={{ pageSize: 10 }}
            />

            {/* 创建/编辑 Modal */}
            <Modal
                title={editingRecord ? '编辑发布' : '新建发布'}
                open={modalVisible}
                onOk={handleSubmit}
                onCancel={() => setModalVisible(false)}
                width={600}
            >
                <Form form={form} layout="vertical" className="mt-4">
                    {!ssoId && (
                        <Form.Item name="ssoId" label="关联系统" rules={[{ required: true }]}>
                            <Select placeholder="选择监管系统">
                                {ssoList.map(sso => (
                                    <Option key={sso.id} value={sso.id}>{sso.name}</Option>
                                ))}
                            </Select>
                        </Form.Item>
                    )}
                    <Form.Item name="title" label="发布标题" rules={[{ required: true }]}>
                        <Input placeholder="例如：2024年12月功能更新" />
                    </Form.Item>
                    <Form.Item name="version" label="版本号">
                        <Input placeholder="例如：1.2.0" />
                    </Form.Item>
                    <Form.Item name="releaseType" label="发布类型">
                        <Select>
                            <Option value="feature">功能发布</Option>
                            <Option value="bugfix">问题修复</Option>
                            <Option value="hotfix">紧急修复</Option>
                        </Select>
                    </Form.Item>
                    <Form.Item name="description" label="变更说明">
                        <TextArea rows={4} placeholder="描述本次发布的主要变更内容..." />
                    </Form.Item>
                </Form>
            </Modal>

            {/* 审批/详情 Drawer */}
            <Drawer
                title={`发布详情 - ${selectedRecord?.title || ''}`}
                open={approvalDrawerVisible}
                onClose={() => setApprovalDrawerVisible(false)}
                width={500}
            >
                {selectedRecord && (
                    <div className="space-y-4">
                        <div className="bg-slate-50 p-4 rounded-lg">
                            <div className="grid grid-cols-2 gap-2 text-sm">
                                <div><span className="text-slate-500">版本：</span>{selectedRecord.version || '-'}</div>
                                <div><span className="text-slate-500">类型：</span>
                                    {releaseTypeConfig[selectedRecord.releaseType || 'feature']?.label}
                                </div>
                                <div><span className="text-slate-500">状态：</span>
                                    <Tag color={statusConfig[selectedRecord.status]?.color}>
                                        {statusConfig[selectedRecord.status]?.label}
                                    </Tag>
                                </div>
                            </div>
                            {selectedRecord.description && (
                                <div className="mt-3 text-sm">
                                    <div className="text-slate-500 mb-1">变更说明：</div>
                                    <div className="whitespace-pre-wrap">{selectedRecord.description}</div>
                                </div>
                            )}
                        </div>

                        {selectedRecord.status === 'pending' && (
                            <div className="border-t pt-4">
                                <div className="mb-2 font-medium">审批操作</div>
                                <TextArea
                                    rows={3}
                                    placeholder="审批意见（可选）"
                                    value={approvalComment}
                                    onChange={e => setApprovalComment(e.target.value)}
                                />
                                <div className="flex gap-2 mt-3">
                                    <Button type="primary" icon={<CheckCircle size={14} />} onClick={handleApprove}>
                                        通过
                                    </Button>
                                    <Button danger icon={<XCircle size={14} />} onClick={handleReject}>
                                        拒绝
                                    </Button>
                                </div>
                            </div>
                        )}

                        <div className="border-t pt-4">
                            <div className="mb-2 font-medium">审批历史</div>
                            {approvalHistory.length === 0 ? (
                                <div className="text-slate-500 text-sm">暂无审批记录</div>
                            ) : (
                                <Timeline>
                                    {approvalHistory.map(record => (
                                        <Timeline.Item
                                            key={record.id}
                                            color={record.action === 'approve' ? 'green' : 'red'}
                                        >
                                            <div className="text-sm">
                                                <span className="font-medium">{record.approverName || '审批人'}</span>
                                                <Tag color={record.action === 'approve' ? 'green' : 'red'} className="ml-2">
                                                    {record.action === 'approve' ? '通过' : '拒绝'}
                                                </Tag>
                                            </div>
                                            {record.comment && <div className="text-xs text-slate-500 mt-1">{record.comment}</div>}
                                            <div className="text-xs text-slate-400">{record.createdAt}</div>
                                        </Timeline.Item>
                                    ))}
                                </Timeline>
                            )}
                        </div>
                    </div>
                )}
            </Drawer>
        </div>
    );
};

export default ReleaseLedger;
