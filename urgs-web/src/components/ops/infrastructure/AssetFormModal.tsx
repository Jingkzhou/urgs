import React, { useEffect, useState } from 'react';
import { AutoComplete, Button, Col, Form, Input, Modal, Row, Select } from 'antd';
import { Globe, Plus, Server, Trash2 } from 'lucide-react';
import type { InfrastructureAsset } from '@/api/ops';
import type { SsoConfig } from '@/api/version';
import { getDeployEnvironments } from '@/api/version';

const { Option } = Select;

interface AssetFormModalProps {
    open: boolean;
    asset: InfrastructureAsset | null;
    systems: SsoConfig[];
    defaultSystemId?: number;
    onCancel: () => void;
    onSubmit: (values: InfrastructureAsset) => Promise<void>;
}

const AssetFormModal: React.FC<AssetFormModalProps> = ({
    open,
    asset,
    systems,
    defaultSystemId,
    onCancel,
    onSubmit,
}) => {
    const [form] = Form.useForm();
    const [envs, setEnvs] = useState<any[]>([]);
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        if (!open) return;
        const nextSystemId = asset?.appSystemId || defaultSystemId;
        form.resetFields();
        form.setFieldsValue(asset || {
            appSystemId: nextSystemId,
            status: 'active',
            osType: 'Linux',
        });
        if (nextSystemId) {
            fetchEnvs(nextSystemId);
        } else {
            setEnvs([]);
        }
    }, [asset, defaultSystemId, form, open]);

    const fetchEnvs = async (systemId: number) => {
        const data = await getDeployEnvironments(systemId);
        setEnvs(data || []);
    };

    const handleSubmit = async () => {
        try {
            setSubmitting(true);
            const values = await form.validateFields();
            await onSubmit(values);
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <Modal
            title={asset ? '编辑服务器资产' : '新增服务器资产'}
            open={open}
            onOk={handleSubmit}
            onCancel={onCancel}
            confirmLoading={submitting}
            width={760}
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
                        <Form.Item name="externalIp" label="公网 IP">
                            <Input placeholder="可选" prefix={<Globe size={14} className="text-slate-400" />} />
                        </Form.Item>
                    </Col>
                    <Col span={12}>
                        <Form.Item name="appSystemId" label="关联系统" rules={[{ required: true, message: '请选择关联系统' }]}>
                            <Select
                                placeholder="选择系统"
                                onChange={(val) => {
                                    form.setFieldValue('envId', undefined);
                                    fetchEnvs(val);
                                }}
                            >
                                {systems.map(system => <Option key={system.id} value={system.id}>{system.name}</Option>)}
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                <Row gutter={16}>
                    <Col span={12}>
                        <Form.Item noStyle shouldUpdate={(prev, current) => prev.appSystemId !== current.appSystemId}>
                            {({ getFieldValue }) => {
                                const appSystemId = getFieldValue('appSystemId');
                                return (
                                    <Form.Item
                                        name="envId"
                                        label="具体部署环境"
                                        extra={envs.length === 0 && appSystemId ? '该系统暂未配置部署环境，请先在版本管理中添加' : null}
                                    >
                                        <Select placeholder="选择环境" allowClear>
                                            {envs.map(env => <Option key={env.id} value={env.id}>{env.name}</Option>)}
                                        </Select>
                                    </Form.Item>
                                );
                            }}
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
                            />
                        </Form.Item>
                    </Col>
                </Row>

                <Row gutter={16}>
                    <Col span={12}>
                        <Form.Item name="role" label="服务器角色">
                            <Select placeholder="选择角色" allowClear>
                                <Option value="app">应用服务器</Option>
                                <Option value="db">数据库服务器</Option>
                                <Option value="redis">缓存服务器</Option>
                                <Option value="nginx">Web 代理/负载均衡</Option>
                                <Option value="jump">跳板机</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                    <Col span={12}>
                        <Form.Item name="status" label="资产状态">
                            <Select>
                                <Option value="active">运行中</Option>
                                <Option value="maintenance">维护中</Option>
                                <Option value="offline">已下线</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                <Form.Item noStyle shouldUpdate={(prev, current) => prev.role !== current.role}>
                    {({ getFieldValue }) => getFieldValue('role') === 'db' ? (
                        <>
                            <Row gutter={16}>
                                <Col span={12}>
                                    <Form.Item name="dbType" label="数据库类型" rules={[{ required: true, message: '请选择数据库类型' }]}>
                                        <Select placeholder="选择数据库类型">
                                            <Option value="Oracle">Oracle</Option>
                                            <Option value="MySQL">MySQL</Option>
                                            <Option value="gbase">gbase</Option>
                                            <Option value="达梦">达梦</Option>
                                            <Option value="hive">hive</Option>
                                            <Option value="云树">云树</Option>
                                        </Select>
                                    </Form.Item>
                                </Col>
                                <Col span={12}>
                                    <Form.Item name="dbPort" label="数据库端口">
                                        <Input type="number" placeholder="Oracle:1521 / MySQL:3306" />
                                    </Form.Item>
                                </Col>
                            </Row>
                            <Row gutter={16}>
                                <Col span={12}>
                                    <Form.Item name="dbName" label="数据库名/SID">
                                        <Input placeholder="Oracle SID 或 MySQL database" />
                                    </Form.Item>
                                </Col>
                                <Col span={12}>
                                    <Form.Item name="dbServiceName" label="服务名 (Oracle)">
                                        <Input placeholder="Oracle 服务名（与 SID 二选一）" />
                                    </Form.Item>
                                </Col>
                            </Row>
                        </>
                    ) : null}
                </Form.Item>

                <p className="mb-4 mt-2 text-[11px] font-bold uppercase tracking-wider text-slate-400">硬件与系统配置</p>
                <Row gutter={16}>
                    <Col span={8}><Form.Item name="cpu" label="CPU"><Input placeholder="8核" /></Form.Item></Col>
                    <Col span={8}><Form.Item name="memory" label="内存"><Input placeholder="16GB" /></Form.Item></Col>
                    <Col span={8}><Form.Item name="disk" label="磁盘"><Input placeholder="500GB SSD" /></Form.Item></Col>
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
                    <Col span={16}><Form.Item name="osVersion" label="核心版本"><Input placeholder="7.9.2009" /></Form.Item></Col>
                </Row>

                <p className="mb-4 mt-4 text-[11px] font-bold uppercase tracking-wider text-slate-400">鉴权账号管理</p>
                <Form.List name="users">
                    {(fields, { add, remove }) => (
                        <div className="mb-4 rounded-md border border-slate-100 bg-slate-50 p-3">
                            {fields.map(({ key, name, ...restField }) => (
                                <div key={key} className="mb-2 flex items-start gap-2 last:mb-0">
                                    <Form.Item {...restField} name={[name, 'userType']} className="mb-0 w-20" initialValue="os">
                                        <Select size="small" placeholder="类型">
                                            <Option value="os">OS</Option>
                                            <Option value="db">DB</Option>
                                        </Select>
                                    </Form.Item>
                                    <Form.Item {...restField} name={[name, 'username']} rules={[{ required: true, message: 'Required' }]} className="mb-0 flex-1">
                                        <Input placeholder="用户名" size="small" />
                                    </Form.Item>
                                    <Form.Item {...restField} name={[name, 'password']} className="mb-0 flex-1">
                                        <Input.Password placeholder="密码" size="small" />
                                    </Form.Item>
                                    <Form.Item {...restField} name={[name, 'description']} className="mb-0 flex-1">
                                        <Input placeholder="用途说明" size="small" />
                                    </Form.Item>
                                    <Button type="text" danger size="small" icon={<Trash2 size={14} />} onClick={() => remove(name)} />
                                </div>
                            ))}
                            <Button type="dashed" size="small" onClick={() => add()} block icon={<Plus size={14} />}>
                                添加账号信息
                            </Button>
                        </div>
                    )}
                </Form.List>

                <Form.Item name="description" label="备注说明">
                    <Input.TextArea rows={2} placeholder="详细用途说明..." />
                </Form.Item>
            </Form>
        </Modal>
    );
};

export default AssetFormModal;
