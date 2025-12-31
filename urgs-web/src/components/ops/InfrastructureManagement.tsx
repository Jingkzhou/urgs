import React, { useState, useEffect, useMemo } from 'react';
import { Table, Button, Modal, Form, Input, Select, Tag, Space, message, Popconfirm, Card, Row, Col, Badge, AutoComplete, Upload, Drawer, Descriptions, Divider, Tooltip, Typography } from 'antd';
import { Plus, Server, Cpu, HardDrive, Database, Search, RefreshCw, Edit, Trash2, Globe, Shield, Activity, Download, UploadCloud, Users, X, Terminal, Info, Monitor, ChevronRight, Eye } from 'lucide-react';
import {
    getDeployEnvironments, SsoConfig,
} from '@/api/version';
import {
    getInfrastructureAssets, createInfrastructureAsset, updateInfrastructureAsset, deleteInfrastructureAsset,
    InfrastructureAsset, exportInfrastructureAssets, importInfrastructureAssets, getSystemList as getSsoList
} from '@/api/ops';

const { Option } = Select;
const { Text } = Typography;

const InfrastructureManagement: React.FC = () => {
    const [assets, setAssets] = useState<InfrastructureAsset[]>([]);
    const [ssoList, setSsoList] = useState<SsoConfig[]>([]);
    const [envs, setEnvs] = useState<any[]>([]);
    const [modalEnvs, setModalEnvs] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingAsset, setEditingAsset] = useState<InfrastructureAsset | null>(null);
    const [form] = Form.useForm();

    // 搜索条件状态
    const [filterSystemId, setFilterSystemId] = useState<number | undefined>();
    const [filterEnvId, setFilterEnvId] = useState<number | undefined>();
    const [filterEnvType, setFilterEnvType] = useState<string | undefined>();
    const [filterHostname, setFilterHostname] = useState<string>('');
    const [filterIp, setFilterIp] = useState<string>('');

    // 详情抽屉状态
    const [detailVisible, setDetailVisible] = useState(false);
    const [selectedAsset, setSelectedAsset] = useState<InfrastructureAsset | null>(null);

    // 批量选择状态
    const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);

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

    useEffect(() => {
        fetchAssets();
        fetchSsoList();
    }, []);

    // 前端过滤（主机名和 IP 搜索）
    const filteredAssets = useMemo(() => {
        return assets.filter(asset => {
            const hostnameMatch = !filterHostname ||
                asset.hostname?.toLowerCase().includes(filterHostname.toLowerCase());
            const ipMatch = !filterIp ||
                asset.internalIp?.toLowerCase().includes(filterIp.toLowerCase()) ||
                asset.externalIp?.toLowerCase().includes(filterIp.toLowerCase());
            return hostnameMatch && ipMatch;
        });
    }, [assets, filterHostname, filterIp]);

    // 打开详情抽屉
    const handleViewDetail = (record: InfrastructureAsset) => {
        setSelectedAsset(record);
        setDetailVisible(true);
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
            width: 180,
            render: (_: any, record: InfrastructureAsset) => {
                const systemName = ssoList.find(s => s.id === record.appSystemId)?.name;
                return (
                    <div className="flex items-center gap-1.5 text-sm">
                        <span className="text-slate-700 truncate max-w-[100px]" title={systemName}>
                            {systemName || '-'}
                        </span>
                        {record.envType && (
                            <>
                                <span className="text-slate-300">/</span>
                                <Tag color="cyan" className="m-0 text-[10px] leading-tight px-1.5">
                                    {record.envType}
                                </Tag>
                            </>
                        )}
                    </div>
                );
            }
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
        }
    ];

    // 批量删除函数
    const handleBatchDelete = async () => {
        if (selectedRowKeys.length === 0) {
            message.warning('请先选择要删除的资产');
            return;
        }
        try {
            await Promise.all(selectedRowKeys.map(id => deleteInfrastructureAsset(Number(id))));
            message.success(`成功删除 ${selectedRowKeys.length} 个资产`);
            setSelectedRowKeys([]);
            fetchAssets();
        } catch (error) {
            message.error('批量删除失败');
        }
    };

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
                <div className="flex flex-wrap gap-3 items-center">
                    {/* 主机名搜索 */}
                    <Input
                        placeholder="搜索主机名"
                        style={{ width: 160 }}
                        allowClear
                        prefix={<Server size={14} className="text-slate-400" />}
                        value={filterHostname}
                        onChange={e => setFilterHostname(e.target.value)}
                    />
                    {/* IP 搜索 */}
                    <Input
                        placeholder="搜索 IP 地址"
                        style={{ width: 160 }}
                        allowClear
                        prefix={<Globe size={14} className="text-slate-400" />}
                        value={filterIp}
                        onChange={e => setFilterIp(e.target.value)}
                    />
                    <Divider type="vertical" className="h-6 mx-1" />
                    {/* 下拉筛选 */}
                    <Select
                        placeholder="按系统筛选"
                        style={{ width: 160 }}
                        allowClear
                        onChange={handleSystemChange}
                        value={filterSystemId}
                    >
                        {ssoList.map(s => <Option key={s.id} value={s.id}>{s.name}</Option>)}
                    </Select>
                    <Select
                        placeholder="按环境筛选"
                        style={{ width: 130 }}
                        allowClear
                        disabled={!filterSystemId}
                        onChange={setFilterEnvId}
                        value={filterEnvId}
                    >
                        {envs.map(e => <Option key={e.id} value={e.id}>{e.name}</Option>)}
                    </Select>
                    <AutoComplete
                        placeholder="环境类型"
                        style={{ width: 110 }}
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
                    <Button icon={<RefreshCw size={14} />} onClick={fetchAssets}>刷新</Button>
                    {selectedRowKeys.length > 0 && (
                        <Popconfirm
                            title={`确定删除选中的 ${selectedRowKeys.length} 个资产？`}
                            onConfirm={handleBatchDelete}
                            okText="删除"
                            okButtonProps={{ danger: true }}
                        >
                            <Button danger icon={<Trash2 size={14} />}>
                                删除选中 ({selectedRowKeys.length})
                            </Button>
                        </Popconfirm>
                    )}
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
                dataSource={filteredAssets}
                rowKey="id"
                loading={loading}
                pagination={{ pageSize: 12, size: 'small', showTotal: (total) => `共 ${total} 条` }}
                className="bg-white rounded-lg shadow-sm border border-slate-100"
                rowSelection={{
                    selectedRowKeys,
                    onChange: (keys) => setSelectedRowKeys(keys),
                    columnWidth: 48
                }}
                onRow={(record) => ({
                    onClick: () => handleViewDetail(record),
                    className: 'cursor-pointer hover:bg-blue-50/50 transition-colors'
                })}
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

            {/* 详情抽屉 - 工业风格深色调设计 */}
            <Drawer
                title={null}
                placement="right"
                width={520}
                open={detailVisible}
                onClose={() => setDetailVisible(false)}
                closable={false}
                styles={{
                    header: { display: 'none' },
                    body: { padding: 0, background: 'linear-gradient(135deg, #1e293b 0%, #0f172a 100%)' }
                }}
            >
                {selectedAsset && (
                    <div className="min-h-full">
                        {/* 头部区域 */}
                        <div className="relative px-6 pt-6 pb-8 border-b border-slate-700/50">
                            {/* 关闭按钮 */}
                            <button
                                onClick={() => setDetailVisible(false)}
                                className="absolute top-4 right-4 w-8 h-8 flex items-center justify-center rounded-full bg-slate-700/50 hover:bg-slate-600 transition-colors"
                            >
                                <X size={16} className="text-slate-400" />
                            </button>

                            {/* 标题区 */}
                            <div className="flex items-start gap-4">
                                <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-cyan-500 to-blue-600 flex items-center justify-center shadow-lg shadow-cyan-500/20">
                                    <Server size={28} className="text-white" />
                                </div>
                                <div className="flex-1 pt-1">
                                    <h2 className="text-xl font-bold text-white tracking-tight mb-1">
                                        {selectedAsset.hostname}
                                    </h2>
                                    <div className="flex items-center gap-2">
                                        <span className="font-mono text-sm text-cyan-400">{selectedAsset.internalIp}</span>
                                        {getStatusTag(selectedAsset.status)}
                                    </div>
                                </div>
                            </div>

                            {/* 快速信息栏 */}
                            <div className="grid grid-cols-3 gap-3 mt-6">
                                <div className="bg-slate-800/50 rounded-lg p-3 border border-slate-700/50">
                                    <div className="text-[10px] uppercase text-slate-400 mb-1 font-medium">CPU</div>
                                    <div className="text-white font-semibold flex items-center gap-1.5">
                                        <Cpu size={14} className="text-cyan-400" />
                                        {selectedAsset.cpu || '-'}
                                    </div>
                                </div>
                                <div className="bg-slate-800/50 rounded-lg p-3 border border-slate-700/50">
                                    <div className="text-[10px] uppercase text-slate-400 mb-1 font-medium">内存</div>
                                    <div className="text-white font-semibold flex items-center gap-1.5">
                                        <Activity size={14} className="text-green-400" />
                                        {selectedAsset.memory || '-'}
                                    </div>
                                </div>
                                <div className="bg-slate-800/50 rounded-lg p-3 border border-slate-700/50">
                                    <div className="text-[10px] uppercase text-slate-400 mb-1 font-medium">磁盘</div>
                                    <div className="text-white font-semibold flex items-center gap-1.5">
                                        <HardDrive size={14} className="text-amber-400" />
                                        {selectedAsset.disk || '-'}
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* 详情主体 */}
                        <div className="px-6 py-5 space-y-6">
                            {/* 基础信息 */}
                            <div>
                                <h3 className="text-xs uppercase font-bold text-slate-400 tracking-wider mb-3 flex items-center gap-2">
                                    <Monitor size={14} />
                                    基础信息
                                </h3>
                                <div className="bg-slate-800/30 rounded-lg border border-slate-700/50 divide-y divide-slate-700/50">
                                    <div className="flex px-4 py-3">
                                        <span className="text-slate-400 text-sm w-24">主机名</span>
                                        <span className="text-white font-medium">{selectedAsset.hostname}</span>
                                    </div>
                                    <div className="flex px-4 py-3">
                                        <span className="text-slate-400 text-sm w-24">内网 IP</span>
                                        <span className="text-cyan-400 font-mono">{selectedAsset.internalIp}</span>
                                    </div>
                                    {selectedAsset.externalIp && (
                                        <div className="flex px-4 py-3">
                                            <span className="text-slate-400 text-sm w-24">外网 IP</span>
                                            <span className="text-cyan-400 font-mono">{selectedAsset.externalIp}</span>
                                        </div>
                                    )}
                                    <div className="flex px-4 py-3">
                                        <span className="text-slate-400 text-sm w-24">服务器角色</span>
                                        <Tag className="uppercase font-mono text-[10px] m-0">{selectedAsset.role || 'UNCATEGORIZED'}</Tag>
                                    </div>
                                </div>
                            </div>

                            {/* 系统与环境 */}
                            <div>
                                <h3 className="text-xs uppercase font-bold text-slate-400 tracking-wider mb-3 flex items-center gap-2">
                                    <Globe size={14} />
                                    系统与环境
                                </h3>
                                <div className="bg-slate-800/30 rounded-lg border border-slate-700/50 divide-y divide-slate-700/50">
                                    <div className="flex px-4 py-3">
                                        <span className="text-slate-400 text-sm w-24">关联系统</span>
                                        <span className="text-white">{ssoList.find(s => s.id === selectedAsset.appSystemId)?.name || '未关联'}</span>
                                    </div>
                                    <div className="flex px-4 py-3">
                                        <span className="text-slate-400 text-sm w-24">环境类型</span>
                                        <Tag color="cyan" className="m-0">{selectedAsset.envType || '-'}</Tag>
                                    </div>
                                    <div className="flex px-4 py-3">
                                        <span className="text-slate-400 text-sm w-24">操作系统</span>
                                        <span className="text-white">{selectedAsset.osType || '-'}</span>
                                    </div>
                                    <div className="flex px-4 py-3">
                                        <span className="text-slate-400 text-sm w-24">系统版本</span>
                                        <span className="text-slate-300 font-mono text-sm">{selectedAsset.osVersion || '-'}</span>
                                    </div>
                                </div>
                            </div>

                            {/* 硬件配置 */}
                            {selectedAsset.hardwareModel && (
                                <div>
                                    <h3 className="text-xs uppercase font-bold text-slate-400 tracking-wider mb-3 flex items-center gap-2">
                                        <Server size={14} />
                                        硬件信息
                                    </h3>
                                    <div className="bg-slate-800/30 rounded-lg border border-slate-700/50 px-4 py-3">
                                        <span className="text-white">{selectedAsset.hardwareModel}</span>
                                    </div>
                                </div>
                            )}

                            {/* 鉴权账号 */}
                            {selectedAsset.users && selectedAsset.users.length > 0 && (
                                <div>
                                    <h3 className="text-xs uppercase font-bold text-slate-400 tracking-wider mb-3 flex items-center gap-2">
                                        <Users size={14} />
                                        鉴权账号 ({selectedAsset.users.length})
                                    </h3>
                                    <div className="space-y-2">
                                        {selectedAsset.users.map((user, idx) => (
                                            <div key={idx} className="bg-slate-800/30 rounded-lg border border-slate-700/50 px-4 py-3 flex items-center gap-4">
                                                <div className="w-8 h-8 rounded-full bg-blue-500/20 flex items-center justify-center">
                                                    <Terminal size={14} className="text-blue-400" />
                                                </div>
                                                <div className="flex-1">
                                                    <div className="text-white font-medium font-mono">{user.username}</div>
                                                    {user.description && (
                                                        <div className="text-slate-400 text-xs mt-0.5">{user.description}</div>
                                                    )}
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {/* 备注说明 */}
                            {selectedAsset.description && (
                                <div>
                                    <h3 className="text-xs uppercase font-bold text-slate-400 tracking-wider mb-3 flex items-center gap-2">
                                        <Info size={14} />
                                        备注说明
                                    </h3>
                                    <div className="bg-slate-800/30 rounded-lg border border-slate-700/50 px-4 py-3">
                                        <Text className="text-slate-300 whitespace-pre-wrap">{selectedAsset.description}</Text>
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* 底部操作栏 */}
                        <div className="px-6 py-4 border-t border-slate-700/50 bg-slate-900/50">
                            <div className="flex gap-3">
                                <Button
                                    type="primary"
                                    icon={<Edit size={14} />}
                                    onClick={() => {
                                        setDetailVisible(false);
                                        handleEdit(selectedAsset);
                                    }}
                                    className="flex-1"
                                >
                                    编辑资产
                                </Button>
                                <Popconfirm
                                    title="确定删除该资产？"
                                    onConfirm={() => {
                                        handleDelete(selectedAsset.id!);
                                        setDetailVisible(false);
                                    }}
                                >
                                    <Button danger icon={<Trash2 size={14} />}>删除</Button>
                                </Popconfirm>
                            </div>
                        </div>
                    </div>
                )}
            </Drawer>
        </div >
    );
};

export default InfrastructureManagement;
