import React from 'react';
import { AutoComplete, Button, Input, Popconfirm, Select, Upload } from 'antd';
import type { UploadProps } from 'antd';
import { Download, Plus, RefreshCw, Search, Trash2, UploadCloud } from 'lucide-react';
import type { AssetFilters } from './types';
import { roleLabels, statusLabels } from './utils';

interface InfrastructureToolbarProps {
    filters: AssetFilters;
    envOptions: Array<{ id: number; name: string }>;
    envTypeOptions: string[];
    roleOptions: string[];
    selectedCount: number;
    onFiltersChange: (filters: AssetFilters) => void;
    onRefresh: () => void;
    onAdd: () => void;
    onExport: () => void;
    onImport: NonNullable<UploadProps['customRequest']>;
    onBatchDelete: () => void;
}

const InfrastructureToolbar: React.FC<InfrastructureToolbarProps> = ({
    filters,
    envOptions,
    envTypeOptions,
    roleOptions,
    selectedCount,
    onFiltersChange,
    onRefresh,
    onAdd,
    onExport,
    onImport,
    onBatchDelete,
}) => {
    const patchFilters = (patch: Partial<AssetFilters>) => onFiltersChange({ ...filters, ...patch });

    return (
        <div className="rounded-lg border border-slate-200 bg-white p-3 shadow-sm">
            <div className="flex items-center gap-3">
                <div className="flex min-w-0 flex-1 items-center gap-2">
                    <div className="min-w-[220px] flex-1">
                        <Input
                            placeholder="全局搜索资产/手册"
                            allowClear
                            prefix={<Search size={14} className="text-slate-400" />}
                            value={filters.keyword}
                            onChange={event => patchFilters({ keyword: event.target.value })}
                        />
                    </div>
                    <Select
                        placeholder="部署环境"
                        className="w-32 shrink-0"
                        allowClear
                        value={filters.envId}
                        onChange={value => patchFilters({ envId: value })}
                        options={envOptions.map(env => ({ value: env.id, label: env.name }))}
                    />
                    <AutoComplete
                        placeholder="环境类型"
                        className="w-32 shrink-0"
                        allowClear
                        value={filters.envType}
                        onChange={value => patchFilters({ envType: value || undefined })}
                        options={envTypeOptions.map(value => ({ value }))}
                        filterOption={(inputValue, option) =>
                            option!.value.toUpperCase().includes(inputValue.toUpperCase())
                        }
                    />
                    <Select
                        placeholder="资产状态"
                        className="w-28 shrink-0"
                        allowClear
                        value={filters.status}
                        onChange={value => patchFilters({ status: value })}
                        options={Object.entries(statusLabels).map(([value, label]) => ({ value, label }))}
                    />
                    <Select
                        placeholder="服务器角色"
                        className="w-32 shrink-0"
                        allowClear
                        value={filters.role}
                        onChange={value => patchFilters({ role: value })}
                        options={roleOptions.map(value => ({ value, label: roleLabels[value] || value }))}
                    />
                    <Button className="shrink-0" icon={<RefreshCw size={14} />} onClick={onRefresh}>刷新</Button>
                    {selectedCount > 0 && (
                        <Popconfirm
                            title={`确定删除选中的 ${selectedCount} 个资产？`}
                            onConfirm={onBatchDelete}
                            okText="删除"
                            okButtonProps={{ danger: true }}
                        >
                            <Button className="shrink-0" danger icon={<Trash2 size={14} />}>删除选中 ({selectedCount})</Button>
                        </Popconfirm>
                    )}
                </div>
                <div className="flex shrink-0 items-center gap-2 border-l border-slate-100 pl-3">
                    <Upload customRequest={onImport} showUploadList={false} accept=".xlsx,.xls">
                        <Button icon={<UploadCloud size={14} />}>导入</Button>
                    </Upload>
                    <Button icon={<Download size={14} />} onClick={onExport}>导出</Button>
                    <Button type="primary" icon={<Plus size={14} />} onClick={onAdd}>新增服务器</Button>
                </div>
            </div>
        </div>
    );
};

export default InfrastructureToolbar;
