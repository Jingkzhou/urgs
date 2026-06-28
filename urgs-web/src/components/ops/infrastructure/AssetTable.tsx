import React from 'react';
import { Button, Popconfirm, Space, Switch, Table, Tag, Tooltip } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { Activity, Cpu, Edit, Eye, HardDrive, Server, Trash2, Users } from 'lucide-react';
import type { InfrastructureAsset } from '@/api/ops';
import type { ServerMonitorSummary } from '@/api/systemMonitor';
import type { SsoConfig } from '@/api/version';
import Auth from '@/components/Auth';
import { getSystemName, roleLabels, statusLabels } from './utils';

interface AssetTableProps {
    assets: InfrastructureAsset[];
    systems: SsoConfig[];
    loading: boolean;
    selectedRowKeys: React.Key[];
    monitorSummaryByAssetId: Record<number, ServerMonitorSummary>;
    monitorUpdatingIds: React.Key[];
    onSelectionChange: (keys: React.Key[]) => void;
    onView: (asset: InfrastructureAsset) => void;
    onEdit: (asset: InfrastructureAsset) => void;
    onDelete: (id: number) => void;
    onToggleMonitor: (asset: InfrastructureAsset, enabled: boolean) => void;
}

const statusColors: Record<string, string> = {
    active: 'success',
    maintenance: 'warning',
    offline: 'default',
};

const AssetTable: React.FC<AssetTableProps> = ({
    assets,
    systems,
    loading,
    selectedRowKeys,
    monitorSummaryByAssetId,
    monitorUpdatingIds,
    onSelectionChange,
    onView,
    onEdit,
    onDelete,
    onToggleMonitor,
}) => {
    const columns: ColumnsType<InfrastructureAsset> = [
        {
            title: '主机名/IP',
            key: 'host',
            render: (_, record) => (
                <div className="flex flex-col">
                    <span className="flex items-center gap-1 font-bold text-slate-800">
                        <Server size={14} className="text-blue-500" />
                        {record.hostname}
                    </span>
                    <span className="font-mono text-xs text-slate-500">{record.internalIp}</span>
                    {record.externalIp && <span className="font-mono text-xs text-slate-400">{record.externalIp}</span>}
                </div>
            ),
        },
        {
            title: '系统/环境',
            key: 'context',
            width: 220,
            render: (_, record) => (
                <div className="flex flex-col gap-1 text-sm">
                    <span className="truncate text-slate-700" title={getSystemName(systems, record.appSystemId)}>
                        {getSystemName(systems, record.appSystemId)}
                    </span>
                    <div className="flex items-center gap-1">
                        {record.envType ? <Tag color="cyan" className="m-0">{record.envType}</Tag> : <span className="text-xs text-slate-400">未设置环境类型</span>}
                    </div>
                </div>
            ),
        },
        {
            title: '硬件配置',
            key: 'config',
            render: (_, record) => (
                <div className="flex flex-col gap-1 text-xs text-slate-600">
                    <div className="flex items-center gap-3">
                        <span className="flex items-center gap-1"><Cpu size={12} /> {record.cpu || '-'}</span>
                        <span className="flex items-center gap-1"><Activity size={12} /> {record.memory || '-'}</span>
                    </div>
                    <div className="flex items-center gap-3">
                        <span className="flex items-center gap-1"><HardDrive size={12} /> {record.disk || '-'}</span>
                        {record.hardwareModel && <span className="text-slate-500">{record.hardwareModel}</span>}
                    </div>
                    {!!record.users?.length && (
                        <span className="mt-0.5 flex items-center gap-1 text-blue-600">
                            <Users size={12} /> {record.users.length} 个账号
                        </span>
                    )}
                </div>
            ),
        },
        {
            title: '角色',
            key: 'role',
            width: 150,
            render: (_, record) => (
                <Space size={4} wrap>
                    <Tag className="m-0 text-[10px] font-mono uppercase">
                        {roleLabels[record.role || ''] || record.role || 'UNCATEGORIZED'}
                    </Tag>
                    {record.dbType && <Tag color="blue" className="m-0 text-[10px] font-mono">{record.dbType}</Tag>}
                </Space>
            ),
        },
        {
            title: '状态',
            dataIndex: 'status',
            key: 'status',
            width: 100,
            render: status => <Tag color={statusColors[status] || 'default'}>{statusLabels[status] || status}</Tag>,
        },
        {
            title: '监控',
            key: 'monitor',
            width: 110,
            render: (_, record) => {
                const assetId = Number(record.id);
                const summary = monitorSummaryByAssetId[assetId];
                const checked = !!summary?.monitorEnabled;
                const disabled = !record.id || record.status !== 'active';
                return (
                    <Auth code="sys:monitor:config">
                        <Tooltip title={disabled ? '仅 active 主机可开启监控' : checked ? '关闭后停止采集该主机' : '开启后纳入服务器性能采集'}>
                            <Switch
                                size="small"
                                checked={checked}
                                disabled={disabled}
                                loading={monitorUpdatingIds.includes(assetId)}
                                checkedChildren="开"
                                unCheckedChildren="关"
                                onChange={value => onToggleMonitor(record, value)}
                            />
                        </Tooltip>
                    </Auth>
                );
            },
        },
        {
            title: '操作',
            key: 'action',
            width: 150,
            render: (_, record) => (
                <Space size={4}>
                    <Button type="text" size="small" icon={<Eye size={14} />} onClick={() => onView(record)} />
                    <Button type="text" size="small" icon={<Edit size={14} />} onClick={() => onEdit(record)} />
                    <Popconfirm
                        title="确定删除该资产？"
                        onConfirm={() => record.id && onDelete(record.id)}
                        okText="删除"
                        okButtonProps={{ danger: true }}
                    >
                        <Button type="text" danger size="small" icon={<Trash2 size={14} />} />
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    return (
        <Table
            columns={columns}
            dataSource={assets}
            rowKey="id"
            loading={loading}
            pagination={{ pageSize: 12, size: 'small', showTotal: total => `共 ${total} 条` }}
            className="rounded-lg border border-slate-100 bg-white shadow-sm"
            rowSelection={{
                selectedRowKeys,
                onChange: onSelectionChange,
                columnWidth: 48,
            }}
        />
    );
};

export default AssetTable;
