import React, { useEffect, useMemo, useState } from 'react';
import { message, Tabs } from 'antd';
import type { UploadProps } from 'antd';
import { getDeployEnvironments, type SsoConfig } from '@/api/version';
import {
    createInfrastructureAsset,
    deleteInfrastructureAsset,
    exportInfrastructureAssets,
    getInfrastructureAssets,
    getInfrastructureSystemManuals,
    getSystemList as getSsoList,
    importInfrastructureAssets,
    type InfrastructureAsset,
    type InfrastructureSystemManual,
    updateInfrastructureAsset,
} from '@/api/ops';
import AssetDetailDrawer from './infrastructure/AssetDetailDrawer';
import AssetFormModal from './infrastructure/AssetFormModal';
import AssetTable from './infrastructure/AssetTable';
import InfrastructureToolbar from './infrastructure/InfrastructureToolbar';
import SystemManualPanel from './infrastructure/SystemManualPanel';
import SystemSidebar from './infrastructure/SystemSidebar';
import type { AssetFilters } from './infrastructure/types';
import {
    buildSystemOptions,
    filterAssets,
    filterManuals,
    getSystemName,
    getUniqueValues,
} from './infrastructure/utils';

const defaultFilters: AssetFilters = {
    keyword: '',
};

const InfrastructureManagement: React.FC = () => {
    const [assets, setAssets] = useState<InfrastructureAsset[]>([]);
    const [manuals, setManuals] = useState<InfrastructureSystemManual[]>([]);
    const [systems, setSystems] = useState<SsoConfig[]>([]);
    const [envs, setEnvs] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [selectedSystemId, setSelectedSystemId] = useState<number | 'all'>('all');
    const [filters, setFilters] = useState<AssetFilters>(defaultFilters);
    const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);
    const [formOpen, setFormOpen] = useState(false);
    const [editingAsset, setEditingAsset] = useState<InfrastructureAsset | null>(null);
    const [detailOpen, setDetailOpen] = useState(false);
    const [selectedAsset, setSelectedAsset] = useState<InfrastructureAsset | null>(null);

    const fetchAssets = async () => {
        setLoading(true);
        try {
            const data = await getInfrastructureAssets();
            setAssets(data || []);
        } catch (error) {
            message.error('获取资产列表失败');
        } finally {
            setLoading(false);
        }
    };

    const fetchManuals = async () => {
        try {
            const data = await getInfrastructureSystemManuals();
            setManuals(data || []);
        } catch (error) {
            message.error('获取运维手册失败');
        }
    };

    const fetchSystems = async () => {
        try {
            const data = await getSsoList({ showAll: true });
            setSystems(data || []);
        } catch (error) {
            message.error('获取系统列表失败');
        }
    };

    const fetchSelectedSystemEnvs = async (systemId: number | 'all') => {
        if (systemId === 'all') {
            setEnvs([]);
            return;
        }
        try {
            const data = await getDeployEnvironments(systemId);
            setEnvs(data || []);
        } catch (error) {
            setEnvs([]);
        }
    };

    const refreshAll = async () => {
        await Promise.all([fetchAssets(), fetchManuals(), fetchSystems()]);
    };

    useEffect(() => {
        refreshAll();
    }, []);

    useEffect(() => {
        fetchSelectedSystemEnvs(selectedSystemId);
        setFilters(prev => ({ ...prev, envId: undefined }));
        setSelectedRowKeys([]);
    }, [selectedSystemId]);

    const systemOptions = useMemo(
        () => buildSystemOptions(systems, assets, manuals),
        [assets, manuals, systems],
    );

    const filteredAssets = useMemo(
        () => filterAssets(assets, systems, manuals, selectedSystemId, filters),
        [assets, filters, manuals, selectedSystemId, systems],
    );

    const visibleManuals = useMemo(
        () => filterManuals(manuals, selectedSystemId, filters.keyword),
        [filters.keyword, manuals, selectedSystemId],
    );

    const scopedAssets = useMemo(
        () => selectedSystemId === 'all' ? assets : assets.filter(asset => asset.appSystemId === selectedSystemId),
        [assets, selectedSystemId],
    );

    const envTypeOptions = useMemo(
        () => getUniqueValues(scopedAssets.map(asset => asset.envType)),
        [scopedAssets],
    );

    const roleOptions = useMemo(
        () => getUniqueValues(scopedAssets.map(asset => asset.role)),
        [scopedAssets],
    );

    const handleAdd = () => {
        setEditingAsset(null);
        setFormOpen(true);
    };

    const handleSelectSystem = (systemId: number | 'all') => {
        setSelectedSystemId(systemId);
        setFilters(prev => ({ ...prev, envId: undefined, envType: undefined }));
    };

    const handleSelectEnvType = (systemId: number, envType: string) => {
        setSelectedSystemId(systemId);
        setFilters(prev => ({ ...prev, envId: undefined, envType }));
    };

    const handleEdit = (asset: InfrastructureAsset) => {
        setEditingAsset(asset);
        setDetailOpen(false);
        setFormOpen(true);
    };

    const handleView = (asset: InfrastructureAsset) => {
        setSelectedAsset(asset);
        setDetailOpen(true);
    };

    const handleSubmit = async (values: InfrastructureAsset) => {
        if (editingAsset?.id) {
            await updateInfrastructureAsset(editingAsset.id, values);
            message.success('更新成功');
        } else {
            await createInfrastructureAsset(values);
            message.success('创建成功');
        }
        setFormOpen(false);
        setEditingAsset(null);
        await fetchAssets();
    };

    const handleDelete = async (id: number) => {
        try {
            await deleteInfrastructureAsset(id);
            message.success('删除成功');
            setSelectedRowKeys(prev => prev.filter(key => key !== id));
            if (selectedAsset?.id === id) {
                setDetailOpen(false);
                setSelectedAsset(null);
            }
            await fetchAssets();
        } catch (error) {
            message.error('删除失败');
        }
    };

    const handleBatchDelete = async () => {
        if (selectedRowKeys.length === 0) {
            message.warning('请先选择要删除的资产');
            return;
        }
        try {
            await Promise.all(selectedRowKeys.map(id => deleteInfrastructureAsset(Number(id))));
            message.success(`成功删除 ${selectedRowKeys.length} 个资产`);
            setSelectedRowKeys([]);
            await fetchAssets();
        } catch (error) {
            message.error('批量删除失败');
        }
    };

    const handleExport = async () => {
        try {
            const blob = await exportInfrastructureAssets();
            if (!blob) return;
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = 'infrastructure_assets.xlsx';
            link.click();
            window.URL.revokeObjectURL(url);
            message.success('导出成功');
        } catch (error) {
            message.error('导出失败');
        }
    };

    const handleImport: NonNullable<UploadProps['customRequest']> = async (options) => {
        const { file, onSuccess, onError } = options;
        try {
            await importInfrastructureAssets(file as File);
            message.success('导入成功');
            onSuccess?.('ok');
            await fetchAssets();
        } catch (error: any) {
            message.error('导入失败');
            onError?.(error);
        }
    };

    const defaultSystemId = selectedSystemId === 'all' ? undefined : selectedSystemId;

    return (
        <div className="flex flex-col gap-4 lg:flex-row">
            <SystemSidebar
                systems={systemOptions}
                selectedSystemId={selectedSystemId}
                selectedEnvType={filters.envType}
                totalAssets={assets.length}
                totalManuals={manuals.length}
                onSelect={handleSelectSystem}
                onSelectEnvType={handleSelectEnvType}
            />

            <div className="min-w-0 flex-1 space-y-4">
                <Tabs
                    defaultActiveKey="environment"
                    className="rounded-lg border border-slate-200 bg-white px-4 pt-3 shadow-sm"
                    tabBarExtraContent={{
                        left: (
                            <div className="mr-5 flex h-full items-center text-base font-semibold text-slate-800">
                                {selectedSystemId === 'all' ? '全部系统' : getSystemName(systems, selectedSystemId)}
                            </div>
                        ),
                        right: (
                            <div className="hidden text-xs text-slate-500 sm:block">
                                当前显示 {filteredAssets.length} 台服务器，{visibleManuals.length} 份手册
                            </div>
                        ),
                    }}
                    items={[
                        {
                            key: 'environment',
                            label: '系统环境',
                            children: (
                                <div className="space-y-4 pb-4">
                                    <div className="text-xs text-slate-500 sm:hidden">
                                        当前显示 {filteredAssets.length} 台服务器，{visibleManuals.length} 份手册
                                    </div>
                                    <InfrastructureToolbar
                                        filters={filters}
                                        envOptions={envs}
                                        envTypeOptions={envTypeOptions}
                                        roleOptions={roleOptions}
                                        selectedCount={selectedRowKeys.length}
                                        onFiltersChange={setFilters}
                                        onRefresh={refreshAll}
                                        onAdd={handleAdd}
                                        onExport={handleExport}
                                        onImport={handleImport}
                                        onBatchDelete={handleBatchDelete}
                                    />

                                    <AssetTable
                                        assets={filteredAssets}
                                        systems={systems}
                                        loading={loading}
                                        selectedRowKeys={selectedRowKeys}
                                        onSelectionChange={setSelectedRowKeys}
                                        onView={handleView}
                                        onEdit={handleEdit}
                                        onDelete={handleDelete}
                                    />
                                </div>
                            ),
                        },
                        {
                            key: 'manuals',
                            label: '运维手册',
                            children: (
                                <div className="pb-4">
                                    <SystemManualPanel
                                        manuals={visibleManuals}
                                        selectedSystemId={selectedSystemId}
                                        systems={systems}
                                        onChanged={fetchManuals}
                                    />
                                </div>
                            ),
                        },
                    ]}
                />
            </div>

            <AssetFormModal
                open={formOpen}
                asset={editingAsset}
                systems={systems}
                defaultSystemId={defaultSystemId}
                onCancel={() => {
                    setFormOpen(false);
                    setEditingAsset(null);
                }}
                onSubmit={handleSubmit}
            />

            <AssetDetailDrawer
                open={detailOpen}
                asset={selectedAsset}
                systems={systems}
                onClose={() => setDetailOpen(false)}
                onEdit={handleEdit}
                onDelete={handleDelete}
            />
        </div>
    );
};

export default InfrastructureManagement;
