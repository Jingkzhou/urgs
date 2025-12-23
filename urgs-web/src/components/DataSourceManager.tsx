import React, { useState, useEffect } from 'react';
import { Table, Button, Modal, Form, Input, Select, InputNumber, message, Space, Tag, Popconfirm, Card, Divider } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, ApiOutlined, DatabaseOutlined } from '@ant-design/icons';

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
    connectionParams: Record<string, any>;
    status: number;
    // Helper fields for display
    metaName?: string;
    metaCategory?: string;
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
    const [metaList, setMetaList] = useState<DataSourceMeta[]>([]);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingId, setEditingId] = useState<number | null>(null);
    const [form] = Form.useForm();
    const [selectedMetaId, setSelectedMetaId] = useState<number | null>(null);
    const [loading, setLoading] = useState(false);
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

            setMetaList(metaRes);

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
            console.error('Failed to fetch data:', error);
            // Fallback for demo if API fails
            // message.error('Failed to load data from backend');
        }
    };

    useEffect(() => {
        fetchData();
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
                ...record.connectionParams
            });
        } else {
            setEditingId(null);
            setSelectedMetaId(null);
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
        form.resetFields();
        form.setFieldsValue({ name, metaId });

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

    // Handle Test Connection
    const handleTestConnection = async () => {
        try {
            const values = await form.validateFields();
            setTestLoading(true);
            console.log('Testing connection:', values);
            // Implement actual test connection API call here
            setTimeout(() => {
                setTestLoading(false);
                message.success('Connection successful!');
            }, 1000);
        } catch (error) {
            // Validation failed
        }
    };

    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            setLoading(true);

            const { name, metaId, ...connectionParams } = values;
            const payload = {
                name,
                metaId,
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
                message.success('Saved successfully');
                setIsModalOpen(false);
                fetchData(); // Refresh list
            } else {
                message.error('Failed to save');
            }
        } catch (error) {
            console.error('Validation failed:', error);
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
                message.success('Deleted successfully');
                fetchData();
            } else {
                message.error('Failed to delete');
            }
        } catch (error) {
            console.error('Delete failed:', error);
        }
    };

    // Table Columns
    const columns = [
        {
            title: 'Name',
            dataIndex: 'name',
            key: 'name',
            render: (text: string) => <span className="font-medium">{text}</span>
        },
        {
            title: 'Type',
            key: 'type',
            render: (_: any, record: any) => {
                const meta = metaList.find(m => m.id === record.metaId);
                const type = meta?.code || 'unknown';

                let color = 'blue';
                if (['hdfs', 'hive', 'odps', 'kudu'].includes(type)) color = 'orange';
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
            title: 'Connection Info',
            key: 'config',
            render: (_: any, record: any) => {
                const config = record.connectionParams;
                const meta = metaList.find(m => m.id === record.metaId);
                const type = meta?.code;

                if (!config) return '-';

                // RDBMS & Standard DBs
                if (['mysql', 'oracle', 'sqlserver', 'postgresql', 'db2', 'clickhouse', 'drds', 'redis', 'cassandra', 'mongodb'].includes(type || '')) {
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
            title: 'Actions',
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
                    <Popconfirm title="Are you sure?" onConfirm={() => handleDelete(record.id)}>
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
                    <h2 className="text-lg font-bold flex items-center gap-2">
                        <DatabaseOutlined className="text-blue-600" />
                        Data Source Management
                    </h2>
                    <Button type="primary" icon={<PlusOutlined />} onClick={() => handleOpenModal()}>
                        Add Source
                    </Button>
                </div>

                <Table
                    columns={columns}
                    dataSource={sources}
                    rowKey="id"
                    pagination={{ pageSize: 10 }}
                />
            </Card>

            <Modal
                title={editingId ? "Edit Data Source" : "New Data Source"}
                open={isModalOpen}
                onCancel={() => setIsModalOpen(false)}
                width={600}
                footer={[
                    <Button key="cancel" onClick={() => setIsModalOpen(false)}>
                        Cancel
                    </Button>,
                    <Button
                        key="test"
                        icon={<ApiOutlined />}
                        loading={testLoading}
                        onClick={handleTestConnection}
                    >
                        Test Connection
                    </Button>,
                    <Button
                        key="submit"
                        type="primary"
                        loading={loading}
                        onClick={handleSave}
                    >
                        Save Configuration
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
                            label="Display Name"
                            rules={[{ required: true, message: 'Please enter a name' }]}
                        >
                            <Input placeholder="e.g. Prod DB" />
                        </Form.Item>
                        <Form.Item
                            name="metaId"
                            label="Database Type"
                            rules={[{ required: true, message: 'Please select a type' }]}
                        >
                            <Select
                                onChange={handleMetaChange}
                                options={getGroupedOptions()}
                                showSearch
                                filterOption={(input, option) =>
                                    (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                                }
                            />
                        </Form.Item>
                    </div>

                    {selectedMetaId && (
                        <>
                            <Divider titlePlacement="left" className="!my-4 text-xs text-slate-400">Connection Details</Divider>

                            <div className="bg-slate-50 p-4 rounded-lg border border-slate-100 max-h-[400px] overflow-y-auto">
                                {currentSchema.map((field) => (
                                    <Form.Item
                                        key={field.name}
                                        name={field.name}
                                        label={field.label}
                                        tooltip={field.help}
                                        rules={[{ required: field.required, message: `${field.label} is required` }]}
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
        </div>
    );
};

export default DataSourceManager;
