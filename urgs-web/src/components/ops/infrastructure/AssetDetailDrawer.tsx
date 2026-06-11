import React from 'react';
import { Button, Drawer, Popconfirm, Space, Tag, Typography } from 'antd';
import { Activity, Cpu, Edit, Globe, HardDrive, Info, Monitor, Server, Terminal, Trash2, Users, X } from 'lucide-react';
import type { InfrastructureAsset } from '@/api/ops';
import type { SsoConfig } from '@/api/version';
import { getSystemName, roleLabels, statusLabels } from './utils';

const { Text } = Typography;

interface AssetDetailDrawerProps {
    open: boolean;
    asset: InfrastructureAsset | null;
    systems: SsoConfig[];
    onClose: () => void;
    onEdit: (asset: InfrastructureAsset) => void;
    onDelete: (id: number) => void;
}

const statusColors: Record<string, string> = {
    active: 'success',
    maintenance: 'warning',
    offline: 'default',
};

const DetailRow = ({ label, children }: { label: string; children: React.ReactNode }) => (
    <div className="flex px-4 py-3">
        <span className="w-24 text-sm text-slate-400">{label}</span>
        <span className="min-w-0 flex-1 text-white">{children}</span>
    </div>
);

const AssetDetailDrawer: React.FC<AssetDetailDrawerProps> = ({
    open,
    asset,
    systems,
    onClose,
    onEdit,
    onDelete,
}) => (
    <Drawer
        title={null}
        placement="right"
        size="large"
        open={open}
        onClose={onClose}
        closable={false}
        styles={{
            header: { display: 'none' },
            body: { padding: 0, background: 'linear-gradient(135deg, #1e293b 0%, #0f172a 100%)' },
        }}
    >
        {asset && (
            <div className="min-h-full">
                <div className="relative border-b border-slate-700/50 px-6 pb-8 pt-6">
                    <button
                        onClick={onClose}
                        className="absolute right-4 top-4 flex h-8 w-8 items-center justify-center rounded-full bg-slate-700/50 transition-colors hover:bg-slate-600"
                    >
                        <X size={16} className="text-slate-400" />
                    </button>
                    <div className="flex items-start gap-4">
                        <div className="flex h-14 w-14 items-center justify-center rounded-xl bg-gradient-to-br from-cyan-500 to-blue-600 shadow-lg shadow-cyan-500/20">
                            <Server size={28} className="text-white" />
                        </div>
                        <div className="flex-1 pt-1">
                            <h2 className="mb-1 text-xl font-bold tracking-tight text-white">{asset.hostname}</h2>
                            <div className="flex items-center gap-2">
                                <span className="font-mono text-sm text-cyan-400">{asset.internalIp}</span>
                                <Tag color={statusColors[asset.status] || 'default'}>{statusLabels[asset.status] || asset.status}</Tag>
                            </div>
                        </div>
                    </div>
                    <div className="mt-6 grid grid-cols-3 gap-3">
                        <div className="rounded-lg border border-slate-700/50 bg-slate-800/50 p-3">
                            <div className="mb-1 text-[10px] font-medium uppercase text-slate-400">CPU</div>
                            <div className="flex items-center gap-1.5 font-semibold text-white"><Cpu size={14} className="text-cyan-400" />{asset.cpu || '-'}</div>
                        </div>
                        <div className="rounded-lg border border-slate-700/50 bg-slate-800/50 p-3">
                            <div className="mb-1 text-[10px] font-medium uppercase text-slate-400">内存</div>
                            <div className="flex items-center gap-1.5 font-semibold text-white"><Activity size={14} className="text-green-400" />{asset.memory || '-'}</div>
                        </div>
                        <div className="rounded-lg border border-slate-700/50 bg-slate-800/50 p-3">
                            <div className="mb-1 text-[10px] font-medium uppercase text-slate-400">磁盘</div>
                            <div className="flex items-center gap-1.5 font-semibold text-white"><HardDrive size={14} className="text-amber-400" />{asset.disk || '-'}</div>
                        </div>
                    </div>
                </div>

                <div className="space-y-6 px-6 py-5">
                    <section>
                        <h3 className="mb-3 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400">
                            <Monitor size={14} /> 基础信息
                        </h3>
                        <div className="divide-y divide-slate-700/50 rounded-lg border border-slate-700/50 bg-slate-800/30">
                            <DetailRow label="主机名">{asset.hostname}</DetailRow>
                            <DetailRow label="内网 IP"><span className="font-mono text-cyan-400">{asset.internalIp}</span></DetailRow>
                            {asset.externalIp && <DetailRow label="外网 IP"><span className="font-mono text-cyan-400">{asset.externalIp}</span></DetailRow>}
                            <DetailRow label="服务器角色">
                                <Space size={8}>
                                    <Tag className="m-0 text-[10px] font-mono uppercase">{roleLabels[asset.role || ''] || asset.role || 'UNCATEGORIZED'}</Tag>
                                    {asset.dbType && <Tag color="cyan" className="m-0 text-[10px] font-mono">{asset.dbType}</Tag>}
                                </Space>
                            </DetailRow>
                        </div>
                    </section>

                    <section>
                        <h3 className="mb-3 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400">
                            <Globe size={14} /> 系统与环境
                        </h3>
                        <div className="divide-y divide-slate-700/50 rounded-lg border border-slate-700/50 bg-slate-800/30">
                            <DetailRow label="关联系统">{getSystemName(systems, asset.appSystemId)}</DetailRow>
                            <DetailRow label="环境类型"><Tag color="cyan" className="m-0">{asset.envType || '-'}</Tag></DetailRow>
                            <DetailRow label="操作系统">{asset.osType || '-'}</DetailRow>
                            <DetailRow label="系统版本"><span className="font-mono text-sm text-slate-300">{asset.osVersion || '-'}</span></DetailRow>
                        </div>
                    </section>

                    {asset.hardwareModel && (
                        <section>
                            <h3 className="mb-3 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400">
                                <Server size={14} /> 硬件信息
                            </h3>
                            <div className="rounded-lg border border-slate-700/50 bg-slate-800/30 px-4 py-3 text-white">{asset.hardwareModel}</div>
                        </section>
                    )}

                    {!!asset.users?.length && (
                        <section>
                            <h3 className="mb-3 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400">
                                <Users size={14} /> 鉴权账号 ({asset.users.length})
                            </h3>
                            <div className="space-y-2">
                                {asset.users.map((user, idx) => (
                                    <div key={idx} className="flex items-center gap-4 rounded-lg border border-slate-700/50 bg-slate-800/30 px-4 py-3">
                                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-500/20">
                                            <Terminal size={14} className="text-blue-400" />
                                        </div>
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2">
                                                <span className="font-mono font-medium text-white">{user.username}</span>
                                                <span className={`rounded px-1.5 py-0.5 text-[10px] ${user.userType === 'db' ? 'bg-amber-500/20 text-amber-400' : 'bg-blue-500/20 text-blue-400'}`}>
                                                    {user.userType === 'db' ? 'DB' : 'OS'}
                                                </span>
                                            </div>
                                            {user.description && <div className="mt-0.5 text-xs text-slate-400">{user.description}</div>}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </section>
                    )}

                    {asset.description && (
                        <section>
                            <h3 className="mb-3 flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-slate-400">
                                <Info size={14} /> 备注说明
                            </h3>
                            <div className="rounded-lg border border-slate-700/50 bg-slate-800/30 px-4 py-3">
                                <Text className="whitespace-pre-wrap text-slate-300">{asset.description}</Text>
                            </div>
                        </section>
                    )}
                </div>

                <div className="border-t border-slate-700/50 bg-slate-900/50 px-6 py-4">
                    <div className="flex gap-3">
                        <Button type="primary" icon={<Edit size={14} />} onClick={() => onEdit(asset)} className="flex-1">
                            编辑资产
                        </Button>
                        <Popconfirm
                            title="确定删除该资产？"
                            onConfirm={() => asset.id && onDelete(asset.id)}
                            okText="删除"
                            okButtonProps={{ danger: true }}
                        >
                            <Button danger icon={<Trash2 size={14} />}>删除</Button>
                        </Popconfirm>
                    </div>
                </div>
            </div>
        )}
    </Drawer>
);

export default AssetDetailDrawer;
