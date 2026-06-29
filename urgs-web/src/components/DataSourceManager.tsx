import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, InputNumber, message, Space, Tag, Popconfirm, Card, Divider, Switch } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, ApiOutlined, DatabaseOutlined } from '@ant-design/icons';
import { getDeployEnvironments, type DeployEnvironment, type SsoConfig } from '@/api/version';
import { getSystemList } from '@/api/ops';

// ==========================================
// 1. Types Definitions
// ==========================================
// Component Registry
const COMPONENT_MAP: Record<string, any> = {
    'input': Input,
    'password': Input.Password,
    'number': InputNumber,
    'select': Select,
    'textarea': Input.TextArea,
};

interface FieldSchema {
    name: string;
    label: string;
    type: string;
    required?: boolean;
    props?: Record<string, any>; // Component specific props (placeholder, options, style, etc.)
    defaultValue?: any;
    help?: string;
}

interface DataSourceMeta {
    id: number;
    code: string;
    name: string;
    category: string;
    formSchema: FieldSchema[];
}

interface DataSourceConfig {
    id: number;
    name: string;
    metaId: number;
    appSystemId?: number;
    envId?: number;
    connectionParams: Record<string, any>;
    status: number;
    // Helper fields for display
    metaName?: string;
    metaCategory?: string;
}

interface DataSourcePoolMember {
    id?: number;
    datasourceId: number;
    datasourceName?: string;
    enabled?: number;
    weight?: number;
    maxConcurrency?: number | null;
    sortNo?: number;
    remark?: string | null;
}

interface DataSourcePool {
    id?: number;
    name: string;
    poolType?: string;
    strategy?: string;
    status?: number;
    remark?: string | null;
    memberCount?: number;
    enabledMemberCount?: number;
    members?: DataSourcePoolMember[];
}

const FieldRenderer = ({ field, ...formProps }: { field: FieldSchema } & any) => {
    const Component = COMPONENT_MAP[field.type] || Input;

    // Merge props: metadata props + form props (value, onChange)
    // We explicitly extract known non-prop fields to avoid passing them to the DOM
    const { name, label, type, required, defaultValue, help, props: metaProps, ...rest } = field;

    return (
        <Component
            style={{ width: '100%' }} // Default style, can be overridden by metaProps
            {...metaProps}
            {...formProps}
        />
    );
};

// ==========================================
// 3. Main Component
// ==========================================
const DataSourceManager: React.FC = () => {
    const [sources, setSources] = useState<DataSourceConfig[]>([]);
    const [pools, setPools] = useState<DataSourcePool[]>([]);
    const [metaList, setMetaList] = useState<DataSourceMeta[]>([]);
    const [activeTab, setActiveTab] = useState<'source' | 'pool'>('source');
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isPoolModalOpen, setIsPoolModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [editingPoolId, setEditingPoolId] = useState<number | null>(null);
    const [form] = Form.useForm();
    const [poolForm] = Form.useForm();
    const selectedSystemInForm = Form.useWatch('appSystemId', form);
    const [selectedMetaId, setSelectedMetaId] = useState<number | null>(null);
    const [systems, setSystems] = useState<SsoConfig[]>([]);
    const [allEnvironments, setAllEnvironments] = useState<DeployEnvironment[]>([]);
    const [environments, setEnvironments] = useState<DeployEnvironment[]>([]);
    const [loading, setLoading] = useState(false);
    const [poolLoading, setPoolLoading] = useState(false);
    const [testLoading, setTestLoading] = useState(false);

    // Fetch Data
    const fetchData = async () => {
        try {
            // Mock API calls - replace with real fetch
            const token = localStorage.getItem('auth_token');
            const metaRes = await fetch('/api/datasource/meta', {
                headers: { 'Authorization': `Bearer ${token}` }
            }).then(res => res.json());
            const configRes = await fetch('/api/datasource/config', {
                headers: { 'Authorization': `Bearer ${token}` }
            }).then(res => res.json());
            const poolRes = await fetch('/api/datasource/pool', {
                headers: { 'Authorization': `Bearer ${token}` }
            }).then(res => res.json());

            setMetaList(metaRes);
            setPools(Array.isArray(poolRes) ? poolRes : []);

            // Enrich config with meta info
            const enrichedConfigs = configRes.map((config: any) => {
                const meta = metaRes.find((m: any) => m.id === config.metaId);
                return {
                    ...config,
                    metaName: meta?.name,
                    metaCategory: meta?.category,
                    metaCode: meta?.code
                };
            });
            setSources(enrichedConfigs);
        } catch (error) {
            console.error('获取数据失败:', error);
            // message.error('加载后端数据失败');
        }
    };

    const fetchSystems = async () => {
        try {
            const data = await getSystemList({ showAll: true });
            setSystems(data || []);
            const envData = await getDeployEnvironments();
            setAllEnvironments(envData || []);
        } catch {
            setSystems([]);
            setAllEnvironments([]);
        }
    };

    const fetchEnvironments = async (systemId?: number) => {
        if (!systemId) {
            setEnvironments([]);
            return;
        }
        try {
            const data = await getDeployEnvironments(systemId);
            setEnvironments(data || []);
        } catch {
            setEnvironments([]);
        }
    };

    useEffect(() => {
        fetchData();
        fetchSystems();
    }, []);

    // Handle Modal Open
    const handleOpenModal = (record?: DataSourceConfig) => {
        form.resetFields();
        if (record) {
            setEditingId(record.id);
            setSelectedMetaId(record.metaId);
            form.setFieldsValue({
                name: record.name,
                metaId: record.metaId,
                appSystemId: record.appSystemId,
                envId: record.envId,
                ...record.connectionParams
            });
            void fetchEnvironments(record.appSystemId);
        } else {
            setEditingId(null);
            setSelectedMetaId(null);
            setEnvironments([]);
            // Default to first meta if available
            if (metaList.length > 0) {
                // Don't auto select to force user choice
                // setSelectedMetaId(metaList[0].id);
                // form.setFieldsValue({ metaId: metaList[0].id });
            }
        }
        setIsModalOpen(true);
    };

    // Handle Meta Change
    const handleMetaChange = (metaId: number) => {
        setSelectedMetaId(metaId);
        const name = form.getFieldValue('name');
        const appSystemId = form.getFieldValue('appSystemId');
        const envId = form.getFieldValue('envId');
        form.resetFields();
        form.setFieldsValue({ name, metaId, appSystemId, envId });

        const meta = metaList.find(m => m.id === metaId);
        if (meta) {
            const defaultValues: Record<string, any> = {};
            meta.formSchema.forEach(field => {
                const val = field.defaultValue ?? field.props?.defaultValue;
                if (val !== undefined) {
                    defaultValues[field.name] = val;
                }
            });
            form.setFieldsValue(defaultValues);
        }
    };

    const handleSystemChange = (systemId?: number) => {
        form.setFieldsValue({ appSystemId: systemId, envId: undefined });
        void fetchEnvironments(systemId);
    };

    const getSystemName = (systemId?: number) =>
        systems.find(system => system.id === systemId)?.name || '-';

    const getEnvName = (envId?: number) =>
        allEnvironments.find(env => env.id === envId)?.name || '-';

    // Handle Test Connection
    const handleTestConnection = async () => {
        try {
            const values = await form.validateFields();
            setTestLoading(true);

            const { name, metaId, appSystemId, envId, ...connectionParams } = values;
            const payload = { id: editingId, metaId, appSystemId, envId, connectionParams };

            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/datasource/test', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            setTestLoading(false);
            if (res.ok) {
                message.success('连接成功！');
            } else {
                const errorMsg = await res.text();
                message.error(errorMsg || '连接失败');
            }
        } catch (error) {
            // 校验失败，错误信息已在表单显示
        }
    };

    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            setLoading(true);

            const { name, metaId, appSystemId, envId, ...connectionParams } = values;
            const payload = {
                name,
                metaId,
                appSystemId,
                envId,
                connectionParams,
                status: 1
            };

            const url = editingId ? `/api/datasource/config/${editingId}` : '/api/datasource/config';
            const method = editingId ? 'PUT' : 'POST';

            const token = localStorage.getItem('auth_token');
            const res = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                message.success('保存成功');
                setIsModalOpen(false);
                fetchData(); // 刷新列表
            } else {
                message.error('保存失败');
            }
        } catch (error) {
            console.error('表单校验失败:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: number) => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/datasource/config/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                message.success('删除成功');
                fetchData();
            } else {
                message.error('删除失败');
            }
        } catch (error) {
            console.error('删除失败:', error);
        }
    };

    const handleOpenPoolModal = (record?: DataSourcePool) => {
        poolForm.resetFields();
        if (record) {
            setEditingPoolId(record.id ?? null);
            poolForm.setFieldsValue({
                name: record.name,
                poolType: record.poolType || 'MIXED',
                strategy: record.strategy || 'LEAST_RUNNING',
                status: record.status ?? 1,
                remark: record.remark || undefined,
                members: (record.members || []).map((member, index) => ({
                    datasourceId: member.datasourceId,
                    enabled: member.enabled ?? 1,
                    weight: member.weight ?? 1,
                    maxConcurrency: member.maxConcurrency ?? null,
                    sortNo: member.sortNo ?? index,
                    remark: member.remark || undefined,
                })),
            });
        } else {
            setEditingPoolId(null);
            poolForm.setFieldsValue({
                poolType: 'MIXED',
                strategy: 'LEAST_RUNNING',
                status: 1,
                members: [{ enabled: 1, weight: 1, sortNo: 0 }],
            });
        }
        setIsPoolModalOpen(true);
    };

    const handleSavePool = async () => {
        try {
            const values = await poolForm.validateFields();
            setPoolLoading(true);
            const members = (values.members || []).map((member: any, index: number) => ({
                datasourceId: member.datasourceId,
                enabled: member.enabled ? 1 : 0,
                weight: member.weight || 1,
                maxConcurrency: member.maxConcurrency ?? null,
                sortNo: member.sortNo ?? index,
                remark: member.remark || null,
            }));
            const payload = {
                id: editingPoolId,
                name: values.name,
                poolType: values.poolType || 'MIXED',
                strategy: values.strategy || 'LEAST_RUNNING',
                status: values.status ? 1 : 0,
                remark: values.remark || null,
                members,
            };
            const token = localStorage.getItem('auth_token');
            const res = await fetch(editingPoolId ? `/api/datasource/pool/${editingPoolId}` : '/api/datasource/pool', {
                method: editingPoolId ? 'PUT' : 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                },
                body: JSON.stringify(payload),
            });
            if (res.ok) {
                message.success('数据池保存成功');
                setIsPoolModalOpen(false);
                fetchData();
            } else {
                const text = await res.text();
                message.error(text || '数据池保存失败');
            }
        } catch (error) {
            console.error('数据池表单校验失败:', error);
        } finally {
            setPoolLoading(false);
        }
    };

    const handleDeletePool = async (id?: number) => {
        if (!id) return;
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/datasource/pool/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                message.success('数据池删除成功');
                fetchData();
            } else {
                message.error('数据池删除失败');
            }
        } catch (error) {
            console.error('数据池删除失败:', error);
        }
    };

    // Table Columns
    const columns = [
        {
            title: '名称',
            dataIndex: 'name',
            key: 'name',
            render: (text: string) => <span className="font-medium">{text}</span>
        },
        {
            title: '类型',
            key: 'type',
            render: (_: any, record: any) => {
                const meta = metaList.find(m => m.id === record.metaId);
                const type = meta?.code || 'unknown';

                let color = 'blue';
                if (['hdfs', 'hive', 'inceptor', 'xinghuan', 'transwarp', 'odps', 'kudu'].includes(type)) color = 'orange';
                if (['mongodb', 'hbase', 'ots', 'redis', 'cassandra'].includes(type)) color = 'purple';
                if (['txtfile', 'ftp', 'sftp', 'oss'].includes(type)) color = 'green';
                if (['elasticsearch', 'opentsdb', 'tsdb', 'stream', 'http'].includes(type)) color = 'cyan';

                return (
                    <Space>
                        <Tag color={color}>{meta?.name || type}</Tag>
                        <span className="text-xs text-slate-400">({meta?.category})</span>
                    </Space>
                );
            }
        },
        {
            title: '连接信息',
            key: 'config',
            render: (_: any, record: any) => {
                const config = record.connectionParams;
                const meta = metaList.find(m => m.id === record.metaId);
                const type = meta?.code;

                if (!config) return '-';

                // RDBMS & Standard DBs
                if (['mysql', 'oracle', 'sqlserver', 'postgresql', 'db2', 'clickhouse', 'drds', 'redis', 'cassandra', 'mongodb', 'inceptor', 'xinghuan', 'transwarp'].includes(type || '')) {
                    return <span className="text-slate-500 font-mono text-xs">{config.host || config.address}:{config.port}/{config.database || config.serviceName || config.keyspace || ''}</span>;
                }
                // File Systems
                if (['ftp', 'sftp'].includes(type || '')) {
                    return <span className="text-slate-500 font-mono text-xs">{config.host}:{config.port}{config.rootPath}</span>;
                }
                // Big Data
                if (['hdfs', 'hive'].includes(type || '')) {
                    return <span className="text-slate-500 font-mono text-xs">{config.defaultFS}</span>;
                }
                // Others
                if (['elasticsearch', 'opentsdb', 'tsdb', 'ots', 'odps', 'oss'].includes(type || '')) {
                    return <span className="text-slate-500 font-mono text-xs">{config.endpoint}</span>;
                }
                if (type === 'hbase') return <span className="text-slate-500 font-mono text-xs">{config.zkQuorum}</span>;
                if (type === 'http') return <span className="text-slate-500 font-mono text-xs">{config.method} {config.url}</span>;

                return '-';
            }
        },
        {
            title: '归属',
            key: 'binding',
            width: 190,
            render: (_: any, record: DataSourceConfig) => (
                <div className="text-xs leading-5 text-slate-600">
                    <div>{getSystemName(record.appSystemId)}</div>
                    <div className="text-slate-400">{getEnvName(record.envId)}</div>
                </div>
            )
        },
        {
            title: '操作',
            key: 'actions',
            align: 'right' as const,
            render: (_: any, record: any) => (
                <Space>
                    <Button
                        type="text"
                        icon={<EditOutlined />}
                        onClick={() => handleOpenModal(record)}
                        className="text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                    />
                    <Popconfirm title="确定要删除吗？" onConfirm={() => handleDelete(record.id)}>
                        <Button
                            type="text"
                            icon={<DeleteOutlined />}
                            className="text-red-500 hover:text-red-700 hover:bg-red-50"
                        />
                    </Popconfirm>
                </Space>
            )
        }
    ];

    const poolColumns = [
        {
            title: '数据池名称',
            dataIndex: 'name',
            key: 'name',
            render: (text: string, record: DataSourcePool) => (
                <Space>
                    <span className="font-medium">{text}</span>
                    <Tag color={record.status === 0 ? 'default' : 'green'}>{record.status === 0 ? '停用' : '启用'}</Tag>
                </Space>
            )
        },
        {
            title: '分配规则',
            dataIndex: 'strategy',
            key: 'strategy',
            render: (value: string) => {
                const labelMap: Record<string, string> = {
                    LEAST_RUNNING: '最少运行数',
                    ROUND_ROBIN: '轮询',
                    WEIGHTED_ROUND_ROBIN: '权重轮询',
                };
                return <Tag color="blue">{labelMap[value] || value || '最少运行数'}</Tag>;
            }
        },
        {
            title: '成员',
            key: 'members',
            render: (_: any, record: DataSourcePool) => (
                <span className="text-slate-600">
                    可用 {record.enabledMemberCount ?? 0} / 总数 {record.memberCount ?? record.members?.length ?? 0}
                </span>
            )
        },
        {
            title: '池内数据源',
            key: 'memberNames',
            render: (_: any, record: DataSourcePool) => (
                <Space wrap size={[4, 4]}>
                    {(record.members || []).slice(0, 4).map(member => (
                        <Tag key={member.datasourceId}>{member.datasourceName || member.datasourceId}</Tag>
                    ))}
                    {(record.members || []).length > 4 && <Tag>+{(record.members || []).length - 4}</Tag>}
                </Space>
            )
        },
        {
            title: '操作',
            key: 'actions',
            align: 'right' as const,
            render: (_: any, record: DataSourcePool) => (
                <Space>
                    <Button
                        type="text"
                        icon={<EditOutlined />}
                        onClick={() => handleOpenPoolModal(record)}
                        className="text-blue-600 hover:text-blue-700 hover:bg-blue-50"
                    />
                    <Popconfirm title="确定要删除这个数据池吗？" onConfirm={() => handleDeletePool(record.id)}>
                        <Button
                            type="text"
                            icon={<DeleteOutlined />}
                            className="text-red-500 hover:text-red-700 hover:bg-red-50"
                        />
                    </Popconfirm>
                </Space>
            )
        }
    ];

    const currentMeta = metaList.find(m => m.id === selectedMetaId);
    const currentSchema = currentMeta?.formSchema || [];

    // Grouped Options for Select
    const getGroupedOptions = () => {
        const groups: Record<string, { label: string, value: number }[]> = {};
        metaList.forEach(meta => {
            if (!groups[meta.category]) {
                groups[meta.category] = [];
            }
            groups[meta.category].push({ label: meta.name, value: meta.id });
        });

        return Object.keys(groups).map(category => ({
            label: category,
            options: groups[category]
        }));
    };

    return (
        <div className="p-6 bg-slate-50 min-h-screen">
            <Card variant="borderless" className="shadow-sm">
                <div className="flex justify-between items-center mb-4">
                    <div className="flex items-center gap-3">
                        <h2 className="text-lg font-bold flex items-center gap-2">
                            <DatabaseOutlined className="text-blue-600" />
                            数据源管理
                        </h2>
                        <div className="inline-flex rounded-lg border border-slate-200 bg-slate-50 p-0.5">
                            <button
                                type="button"
                                onClick={() => setActiveTab('source')}
                                className={`rounded-md px-3 py-1 text-sm ${activeTab === 'source' ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-500'}`}
                            >
                                数据源配置
                            </button>
                            <button
                                type="button"
                                onClick={() => setActiveTab('pool')}
                                className={`rounded-md px-3 py-1 text-sm ${activeTab === 'pool' ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-500'}`}
                            >
                                数据池
                            </button>
                        </div>
                    </div>
                    {activeTab === 'source' ? (
                        <Button type="primary" icon={<PlusOutlined />} onClick={() => handleOpenModal()}>
                            新增数据源
                        </Button>
                    ) : (
                        <Button type="primary" icon={<PlusOutlined />} onClick={() => handleOpenPoolModal()}>
                            新增数据池
                        </Button>
                    )}
                </div>

                {activeTab === 'source' ? (
                    <Table
                        columns={columns}
                        dataSource={sources}
                        rowKey="id"
                        pagination={{ pageSize: 10 }}
                    />
                ) : (
                    <Table
                        columns={poolColumns}
                        dataSource={pools}
                        rowKey="id"
                        pagination={{ pageSize: 10 }}
                    />
                )}
            </Card>

            <Modal
                title={editingId ? "编辑数据源" : "新建数据源"}
                open={isModalOpen}
                onCancel={() => setIsModalOpen(false)}
                width={600}
                footer={[
                    <Button key="cancel" onClick={() => setIsModalOpen(false)}>
                        取消
                    </Button>,
                    <Button
                        key="test"
                        icon={<ApiOutlined />}
                        loading={testLoading}
                        onClick={handleTestConnection}
                    >
                        测试连接
                    </Button>,
                    <Button
                        key="submit"
                        type="primary"
                        loading={loading}
                        onClick={handleSave}
                    >
                        保存配置
                    </Button>
                ]}
            >
                <Form
                    form={form}
                    layout="vertical"
                >
                    <div className="grid grid-cols-2 gap-4">
                        <Form.Item
                            name="name"
                            label="显示名称"
                            rules={[{ required: true, message: '请输入名称' }]}
                        >
                            <Input placeholder="例如：生产环境数据库" />
                        </Form.Item>
                        <Form.Item
                            name="metaId"
                            label="数据库类型"
                            rules={[{ required: true, message: '请选择类型' }]}
                        >
                            <Select
                                onChange={handleMetaChange}
                                options={getGroupedOptions()}
                                placeholder="选择数据库类型"
                                showSearch
                                filterOption={(input, option) =>
                                    (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                                }
                            />
                        </Form.Item>
                        <Form.Item
                            name="appSystemId"
                            label="关联系统"
                            rules={[{ required: true, message: '请选择关联系统' }]}
                        >
                            <Select
                                allowClear
                                showSearch
                                optionFilterProp="label"
                                placeholder="选择所属系统"
                                onChange={handleSystemChange}
                                options={systems.map(system => ({ value: system.id, label: system.name }))}
                            />
                        </Form.Item>
                        <Form.Item
                            name="envId"
                            label="关联环境"
                        >
                            <Select
                                allowClear
                                disabled={!selectedSystemInForm}
                                placeholder="选择所属环境"
                                options={environments.map(env => ({ value: env.id!, label: env.name }))}
                            />
                        </Form.Item>
                    </div>

                    {selectedMetaId && (
                        <>
                            <Divider titlePlacement="left" className="!my-4 text-xs text-slate-400">连接详情</Divider>

                            <div className="bg-slate-50 p-4 rounded-lg border border-slate-100 max-h-[400px] overflow-y-auto">
                                {currentSchema.map((field) => (
                                    <Form.Item
                                        key={field.name}
                                        name={field.name}
                                        label={field.label}
                                        tooltip={field.help}
                                        rules={[{ required: field.required, message: `${field.label}是必填项` }]}
                                        className="mb-4"
                                    >
                                        <FieldRenderer field={field} />
                                    </Form.Item>
                                ))}
                            </div>
                        </>
                    )}
                </Form>
            </Modal>

            <Modal
                title={editingPoolId ? '编辑数据池' : '新建数据池'}
                open={isPoolModalOpen}
                onCancel={() => setIsPoolModalOpen(false)}
                width={860}
                footer={[
                    <Button key="cancel" onClick={() => setIsPoolModalOpen(false)}>
                        取消
                    </Button>,
                    <Button key="submit" type="primary" loading={poolLoading} onClick={handleSavePool}>
                        保存数据池
                    </Button>
                ]}
            >
                <Form form={poolForm} layout="vertical">
                    <div className="grid grid-cols-2 gap-4">
                        <Form.Item
                            name="name"
                            label="数据池名称"
                            rules={[{ required: true, message: '请输入数据池名称' }]}
                        >
                            <Input placeholder="例如：监管批量执行池" />
                        </Form.Item>
                        <Form.Item name="poolType" label="数据池类型">
                            <Select
                                options={[
                                    { label: '混合执行池', value: 'MIXED' },
                                    { label: 'SQL 执行池', value: 'SQL' },
                                    { label: 'Shell 执行池', value: 'SHELL' },
                                ]}
                            />
                        </Form.Item>
                        <Form.Item name="strategy" label="分配规则">
                            <Select
                                options={[
                                    { label: '最少运行数', value: 'LEAST_RUNNING' },
                                    { label: '轮询', value: 'ROUND_ROBIN' },
                                    { label: '权重轮询', value: 'WEIGHTED_ROUND_ROBIN' },
                                ]}
                            />
                        </Form.Item>
                        <Form.Item name="status" label="状态" valuePropName="checked">
                            <Switch checkedChildren="启用" unCheckedChildren="停用" />
                        </Form.Item>
                    </div>
                    <Form.Item name="remark" label="备注">
                        <Input.TextArea rows={2} placeholder="可填写用途、适用任务或维护说明" />
                    </Form.Item>

                    <Divider titlePlacement="left" className="!my-4 text-xs text-slate-400">池内数据源</Divider>
                    <Form.List
                        name="members"
                        rules={[
                            {
                                validator: async (_, members) => {
                                    if (!members || members.length < 1) {
                                        return Promise.reject(new Error('请至少添加一个数据源'));
                                    }
                                    return Promise.resolve();
                                }
                            }
                        ]}
                    >
                        {(fields, { add, remove }, { errors }) => (
                            <div className="space-y-3">
                                {fields.map(({ key, name, ...restField }) => (
                                    <div key={key} className="grid grid-cols-[minmax(220px,1fr)_80px_90px_110px_90px_40px] items-end gap-2 rounded-lg border border-slate-100 bg-slate-50 p-3">
                                        <Form.Item
                                            {...restField}
                                            name={[name, 'datasourceId']}
                                            label="数据源"
                                            rules={[{ required: true, message: '请选择数据源' }]}
                                            className="!mb-0"
                                        >
                                            <Select
                                                showSearch
                                                placeholder="选择数据源"
                                                options={sources.map(source => ({
                                                    value: source.id,
                                                    label: source.name,
                                                }))}
                                                filterOption={(input, option) =>
                                                    (option?.label ?? '').toString().toLowerCase().includes(input.toLowerCase())
                                                }
                                            />
                                        </Form.Item>
                                        <Form.Item
                                            {...restField}
                                            name={[name, 'enabled']}
                                            label="启用"
                                            valuePropName="checked"
                                            className="!mb-0"
                                        >
                                            <Switch />
                                        </Form.Item>
                                        <Form.Item
                                            {...restField}
                                            name={[name, 'weight']}
                                            label="权重"
                                            className="!mb-0"
                                        >
                                            <InputNumber min={1} max={100} className="w-full" />
                                        </Form.Item>
                                        <Form.Item
                                            {...restField}
                                            name={[name, 'maxConcurrency']}
                                            label="最大并发"
                                            className="!mb-0"
                                        >
                                            <InputNumber min={1} className="w-full" placeholder="不限" />
                                        </Form.Item>
                                        <Form.Item
                                            {...restField}
                                            name={[name, 'sortNo']}
                                            label="排序"
                                            className="!mb-0"
                                        >
                                            <InputNumber min={0} className="w-full" />
                                        </Form.Item>
                                        <Button type="text" danger icon={<DeleteOutlined />} onClick={() => remove(name)} />
                                    </div>
                                ))}
                                <Form.ErrorList errors={errors} />
                                <Button type="dashed" block icon={<PlusOutlined />} onClick={() => add({ enabled: 1, weight: 1, sortNo: fields.length })}>
                                    添加池内数据源
                                </Button>
                            </div>
                        )}
                    </Form.List>
                </Form>
            </Modal>
        </div>
    );
};

export default DataSourceManager;
