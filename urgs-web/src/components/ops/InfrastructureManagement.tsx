import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Card, Row, Col, Badge, AutoComplete, Upload } from 'antd';
import { Plus, Server, Cpu, HardDrive, Database, Search, RefreshCw, Edit, Trash2, Globe, Shield, Activity, Download, UploadCloud, Users } from 'lucide-react';
import {
    getDeployEnvironments, SsoConfig,
} from '@/api/version';
import {
    getInfrastructureAssets, createInfrastructureAsset, updateInfrastructureAsset, deleteInfrastructureAsset,
    InfrastructureAsset, exportInfrastructureAssets, importInfrastructureAssets, getSystemList as getSsoList
} from '@/api/ops';

const { Option } = Select;

const InfrastructureManagement: React.FC = () => {
    const [assets, setAssets] = useState<InfrastructureAsset[]>([]);
    const [ssoList, setSsoList] = useState<SsoConfig[]>([]);
    const [envs, setEnvs] = useState<any[]>([]);
    const [modalEnvs, setModalEnvs] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingAsset, setEditingAsset] = useState<InfrastructureAsset | null>(null);
    const [form] = Form.useForm();

    const [filterSystemId, setFilterSystemId] = useState<number | undefined>();
    const [filterEnvId, setFilterEnvId] = useState<number | undefined>();
    const [filterEnvType, setFilterEnvType] = useState<string | undefined>();

    useEffect(() => {
        fetchAssets();
        fetchSsoList();
    }, []);

    const fetchAssets = async () => {
        setLoading(true);
        try {
            const data = await getInfrastructureAssets({
                appSystemId: filterSystemId,
                envId: filterEnvId,
                envType: filterEnvType
            });
            setAssets(data || []);
        } catch (error) {
            message.error('获取资产列表失败');
        } finally {
            setLoading(false);
        }
    };

    const fetchSsoList = async () => {
        try {
            const data = await getSsoList();
            setSsoList(data || []);
        } catch (error) {
            console.error(error);
        }
    };

    const handleSystemChange = async (systemId: number | undefined) => {
        setFilterSystemId(systemId);
        setFilterEnvId(undefined); // Reset env filter
        if (systemId) {
            fetchEnvs(systemId);
        } else {
            setEnvs([]);
        }
    };

    const fetchEnvs = async (systemId: number, isModal: boolean = false) => {
        try {
            const data = await getDeployEnvironments(systemId);
            if (isModal) {
                setModalEnvs(data || []);
            } else {
                setEnvs(data || []);
            }
        } catch (error) {
            console.error(error);
        }
    };

    const handleAdd = () => {
        setEditingAsset(null);
        setModalEnvs([]);
        form.resetFields();
        form.setFieldsValue({ status: 'active', osType: 'Linux' });
        setModalVisible(true);
    };

    const handleEdit = (record: InfrastructureAsset) => {
        setEditingAsset(record);
        if (record.appSystemId) {
            fetchEnvs(record.appSystemId, true);
        }
        form.setFieldsValue(record);
        setModalVisible(true);
    };

    const handleDelete = async (id: number) => {
        try {
            await deleteInfrastructureAsset(id);
            message.success('删除成功');
            fetchAssets();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleSubmit = async () => {
        try {
            const values = await form.validateFields();
            if (editingAsset?.id) {
                await updateInfrastructureAsset(editingAsset.id, values);
                message.success('更新成功');
            } else {
                await createInfrastructureAsset(values);
                message.success('创建成功');
            }
            setModalVisible(false);
            fetchAssets();
        } catch (error) {
            message.error('保存失败');
        }
    };

    const handleExport = async () => {
        try {
            const blob = await exportInfrastructureAssets();
            if (blob) {
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'infrastructure_assets.xlsx';
                a.click();
                window.URL.revokeObjectURL(url);
                message.success('导出成功');
            }
        } catch (error) {
            message.error('导出失败');
        }
    };

    const handleImport = async (options: any) => {
        const { file, onSuccess, onError } = options;
        try {
            await importInfrastructureAssets(file);
            message.success('导入成功');
            onSuccess("ok");
            fetchAssets();
        } catch (error) {
            message.error('导入失败');
            onError(error);
        }
    };


    const getStatusTag = (status: string) => {
        switch (status) {
            case 'active': return <Tag color="success">运行中</Tag>;
            case 'maintenance': return <Tag color="warning">维护中</Tag>;
            case 'offline': return <Tag color="default">已下线</Tag>;
            default: return <Tag>{status}</Tag>;
        }
    };

    const columns = [
        {
            title: '主机名/IP',
            key: 'host',
            render: (_: any, record: InfrastructureAsset) => (
                <div className="flex flex-col">
                    <span className="font-bold text-slate-800 flex items-center gap-1">
                        <Server size={14} className="text-blue-500" />
                        {record.hostname}
                    </span>
                    <span className="text-xs text-slate-500 font-mono">{record.internalIp}</span>
                </div>
            )
        },
        {
            title: '关联系统/环境',
            key: 'context',
            render: (_: any, record: InfrastructureAsset) => (
                <div className="flex flex-col gap-1">
                    <Tag className="m-0 border-none bg-blue-50 text-blue-700 text-[11px]">
                        {ssoList.find(s => s.id === record.appSystemId)?.name || '未关联'}
                    </Tag>
                    <div className="flex items-center gap-1">
                        {record.envType && <Tag className="m-0 text-[10px]" color="cyan">{record.envType}</Tag>}
                        {record.envId && (
                            <span className="text-[10px] text-slate-400">
                                (E{record.envId})
                            </span>
                        )}
                    </div>
                </div>
            )
        },
        {
            title: '硬件配置',
            key: 'config',
            render: (_: any, record: InfrastructureAsset) => (
                <div className="flex flex-col gap-1 text-xs text-slate-600">
                    <div className="flex items-center gap-3">
                        <span className="flex items-center gap-1" title="CPU"><Cpu size={12} /> {record.cpu || '-'}</span>
                        <span className="flex items-center gap-1" title="内存"><Activity size={12} /> {record.memory || '-'}</span>
                    </div>
                    <div className="flex items-center gap-3">
                        <span className="flex items-center gap-1" title="磁盘"><HardDrive size={12} /> {record.disk || '-'}</span>
                        {record.hardwareModel && (
                            <span className="flex items-center gap-1 text-slate-500" title="硬件型号">
                                <Server size={12} /> {record.hardwareModel}
                            </span>
                        )}
                    </div>
                    {record.users && record.users.length > 0 && (
                        <span className="flex items-center gap-1 text-blue-600 mt-0.5" title={`已配置 ${record.users.length} 个账号`}>
                            <Users size={12} /> {record.users.length}
                        </span>
                    )}
                </div>
            )
        },
        {
            title: '角色',
            dataIndex: 'role',
            key: 'role',
            render: (role: string) => <Tag className="uppercase font-mono text-[10px]">{role || 'UNCATEGORIZED'}</Tag>
        },
        {
            title: '状态',
            dataIndex: 'status',
            key: 'status',
            render: (status: string) => getStatusTag(status)
        },
        {
            title: '操作',
            key: 'actions',
            render: (_: any, record: InfrastructureAsset) => (
                <Space>
                    <Button type="text" size="small" icon={<Edit size={14} />} onClick={() => handleEdit(record)} />
                    <Popconfirm title="确定删除资产？" onConfirm={() => handleDelete(record.id!)}>
                        <Button type="text" size="small" danger icon={<Trash2 size={14} />} />
                    </Popconfirm>
                </Space>
            )
        }
    ];

    return (
        <div className="space-y-4">
            {/* Stats Cards */}
            <Row gutter={16}>
                <Col span={6}>
                    <Card size="small" className="bg-gradient-to-br from-blue-500 to-blue-600 text-white border-none shadow-md">
                        <div className="flex justify-between items-center">
                            <div>
                                <p className="text-[10px] opacity-80 uppercase font-bold">总服务器数</p>
                                <h3 className="text-2xl font-bold">{assets.length}</h3>
                            </div>
                            <Server size={32} className="opacity-20" />
                        </div>
                    </Card>
                </Col>
                <Col span={6}>
                    <Card size="small" className="bg-white shadow-sm border-slate-100">
                        <div className="flex justify-between items-center">
                            <div>
                                <p className="text-[10px] text-slate-400 uppercase font-bold">运行中</p>
                                <h3 className="text-2xl font-bold text-green-600">
                                    {assets.filter(a => a.status === 'active').length}
                                </h3>
                            </div>
                            <Badge status="success" />
                        </div>
                    </Card>
                </Col>
            </Row>

            {/* Filter Area */}
            <Card size="small" className="shadow-sm border-slate-100">
                <div className="flex flex-wrap gap-4 items-center">
                    <div className="flex items-center gap-2">
                        <Search size={16} className="text-slate-400" />
                        <Select
                            placeholder="按系统筛选"
                            style={{ width: 180 }}
                            allowClear
                            onChange={handleSystemChange}
                            value={filterSystemId}
                        >
                            {ssoList.map(s => <Option key={s.id} value={s.id}>{s.name}</Option>)}
                        </Select>
                        <Select
                            placeholder="按环境筛选"
                            style={{ width: 140 }}
                            allowClear
                            disabled={!filterSystemId}
                            onChange={setFilterEnvId}
                            value={filterEnvId}
                        >
                            {envs.map(e => <Option key={e.id} value={e.id}>{e.name}</Option>)}
                        </Select>
                        <AutoComplete
                            placeholder="环境类型"
                            style={{ width: 120 }}
                            allowClear
                            onChange={setFilterEnvType}
                            value={filterEnvType}
                            options={[
                                { value: '测试环境' },
                                { value: '生产环境' },
                                { value: '开发环境' },
                            ]}
                            filterOption={(inputValue, option) =>
                                option!.value.toUpperCase().indexOf(inputValue.toUpperCase()) !== -1
                            }
                        />
                    </div>
                    <Button icon={<RefreshCw size={14} />} onClick={fetchAssets}>刷新</Button>
                    <div className="ml-auto flex gap-2">
                        <Upload customRequest={handleImport} showUploadList={false} accept=".xlsx, .xls">
                            <Button icon={<UploadCloud size={14} />}>导入</Button>
                        </Upload>
                        <Button icon={<Download size={14} />} onClick={handleExport}>导出</Button>
                        <Button type="primary" icon={<Plus size={14} />} onClick={handleAdd}>
                            新增服务器
                        </Button>
                    </div>
                </div>
            </Card>

            <Table
                columns={columns}
                dataSource={assets}
                rowKey="id"
                loading={loading}
                pagination={{ pageSize: 12, size: 'small' }}
                className="bg-white rounded-lg shadow-sm border border-slate-100"
            />

            {/* Manage Asset Modal */}
            <Modal
                title={editingAsset ? '编辑服务器资产' : '新增服务器资产'}
                open={modalVisible}
                onOk={handleSubmit}
                onCancel={() => setModalVisible(false)}
                width={700}
                centered
            >
                <Form form={form} layout="vertical" className="mt-4">
                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item name="hostname" label="主机名" rules={[{ required: true, message: '请输入主机名' }]}>
                                <Input placeholder="例如: web-prod-01" prefix={<Server size={14} className="text-slate-400" />} />
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item name="internalIp" label="内网 IP" rules={[{ required: true, message: '请输入内网 IP' }]}>
                                <Input placeholder="192.168.1.10" prefix={<Globe size={14} className="text-slate-400" />} />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item name="appSystemId" label="关联系统" rules={[{ required: true }]}>
                                <Select placeholder="选择系统" onChange={(val) => {
                                    form.setFieldValue('envId', undefined);
                                    fetchEnvs(val, true);
                                }}>
                                    {ssoList.map(s => <Option key={s.id} value={s.id}>{s.name}</Option>)}
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item name="role" label="服务器角色">
                                <Select placeholder="选择角色">
                                    <Option value="app">应用服务器</Option>
                                    <Option value="db">数据库服务器</Option>
                                    <Option value="redis">缓存服务器</Option>
                                    <Option value="nginx">Web 代理/负载均衡</Option>
                                    <Option value="jump">跳板机</Option>
                                </Select>
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={12}>
                            <Form.Item name="envId" label="具体部署环境" extra={modalEnvs.length === 0 && form.getFieldValue('appSystemId') ? "该系统暂未配置部署环境，请先在[版本管理]中添加" : null}>
                                <Select placeholder="选择环境" allowClear>
                                    {modalEnvs.map(e => <Option key={e.id} value={e.id}>{e.name}</Option>)}
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col span={12}>
                            <Form.Item name="envType" label="环境类型" rules={[{ required: true, message: '请输入或选择环境类型' }]}>
                                <AutoComplete
                                    placeholder="测试环境 / 生产环境 / 或自定义输入"
                                    options={[
                                        { value: '测试环境' },
                                        { value: '生产环境' },
                                        { value: '预发布环境' },
                                        { value: '开发环境' },
                                    ]}
                                    filterOption={(inputValue, option) =>
                                        option!.value.toUpperCase().indexOf(inputValue.toUpperCase()) !== -1
                                    }
                                />
                            </Form.Item>
                        </Col>
                    </Row>

                    <p className="text-[11px] font-bold text-slate-400 uppercase mt-2 mb-4 tracking-wider">硬件与系统配置</p>

                    <Row gutter={16}>
                        <Col span={8}>
                            <Form.Item name="cpu" label="CPU">
                                <Input placeholder="8核" />
                            </Form.Item>
                        </Col>
                        <Col span={8}>
                            <Form.Item name="memory" label="内存">
                                <Input placeholder="16GB" />
                            </Form.Item>
                        </Col>
                        <Col span={8}>
                            <Form.Item name="disk" label="磁盘">
                                <Input placeholder="500GB SSD" />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={24}>
                            <Form.Item name="hardwareModel" label="服务器型号">
                                <Input placeholder="例如: Dell PowerEdge R740 / 华为泰山200" prefix={<Server size={14} className="text-slate-400" />} />
                            </Form.Item>
                        </Col>
                    </Row>

                    <Row gutter={16}>
                        <Col span={8}>
                            <Form.Item name="osType" label="操作系统">
                                <Select>
                                    <Option value="CentOS">CentOS</Option>
                                    <Option value="Ubuntu">Ubuntu</Option>
                                    <Option value="RedHat">RedHat</Option>
                                    <Option value="Windows">Windows Server</Option>
                                    <Select.OptGroup label="信创系统">
                                        <Option value="UnionTech">统信 UOS</Option>
                                        <Option value="Kylin">麒麟操作系统</Option>
                                        <Option value="EulerOS">欧拉操作系统</Option>
                                        <Option value="Anolis">龙蜥操作系统</Option>
                                    </Select.OptGroup>
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col span={16}>
                            <Form.Item name="osVersion" label="核心版本">
                                <Input placeholder="7.9.2009" />
                            </Form.Item>
                        </Col>
                    </Row>

                    <p className="text-[11px] font-bold text-slate-400 uppercase mt-4 mb-4 tracking-wider">鉴权账号管理</p>
                    <Form.List name="users">
                        {(fields, { add, remove }) => (
                            <div className="bg-slate-50 p-3 rounded-md mb-4 border border-slate-100">
                                {fields.map(({ key, name, ...restField }) => (
                                    <div key={key} className="flex gap-2 items-start mb-2 last:mb-0">
                                        <Form.Item
                                            {...restField}
                                            name={[name, 'username']}
                                            rules={[{ required: true, message: 'Required' }]}
                                            className="mb-0 w-1/4"
                                        >
                                            <Input placeholder="用户名" size="small" />
                                        </Form.Item>
                                        <Form.Item
                                            {...restField}
                                            name={[name, 'password']}
                                            className="mb-0 w-1/4"
                                        >
                                            <Input.Password placeholder="密码" size="small" />
                                        </Form.Item>
                                        <Form.Item
                                            {...restField}
                                            name={[name, 'description']}
                                            className="mb-0 flex-1"
                                        >
                                            <Input placeholder="用途说明" size="small" />
                                        </Form.Item>
                                        <Button
                                            type="text"
                                            danger
                                            size="small"
                                            icon={<Trash2 size={14} />}
                                            onClick={() => remove(name)}
                                            className="mt-1"
                                        />
                                    </div>
                                ))}
                                <Button type="dashed" size="small" onClick={() => add()} block icon={<Plus size={14} />} className="mt-2 text-slate-500 border-slate-300">
                                    添加账号信息
                                </Button>
                            </div>
                        )}
                    </Form.List>

                    <Row gutter={16}>
                        <Col span={8}>
                            <Form.Item name="status" label="资产状态">
                                <Select>
                                    <Option value="active">运行中</Option>
                                    <Option value="maintenance">维护中</Option>
                                    <Option value="offline">已下线</Option>
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col span={16}>
                            <Form.Item name="description" label="备注说明">
                                <Input.TextArea rows={2} placeholder="详细用途说明..." />
                            </Form.Item>
                        </Col>
                    </Row>
                </Form >
            </Modal >
        </div >
    );
};

export default InfrastructureManagement;
