import React, { useEffect, useMemo, useState } from 'react';
import { Save, ShieldCheck } from 'lucide-react';
import { physicalAssetService } from '../../../../services/physicalAssetService';
import {
    PhysicalFieldBinding,
    PhysicalTableBinding,
    RegElementQueryConfigValidationResult,
    RegElement,
    RegTableQueryConfig
} from '../types';
import { PhysicalBindingSelector } from './PhysicalBindingSelector';

interface TableQueryConfigPanelProps {
    tableId?: number | string;
    physicalTables: PhysicalTableBinding[];
    onPhysicalTablesChange: (physicalTables: PhysicalTableBinding[]) => void;
}

const EMPTY_CONFIG: RegTableQueryConfig = {
    enabled: 0,
    defaultReturnFieldIds: [],
    filterFieldIds: [],
    sortFieldIds: [],
    maskFieldIds: [],
    detailMaxRows: 5
};

const token = () => localStorage.getItem('auth_token') || '';

const fieldLabel = (field: PhysicalFieldBinding) => (
    field.fieldCnName ? `${field.fieldName}（${field.fieldCnName}）` : field.fieldName
);

export const TableQueryConfigPanel: React.FC<TableQueryConfigPanelProps> = ({
    tableId,
    physicalTables,
    onPhysicalTablesChange
}) => {
    const [config, setConfig] = useState<RegTableQueryConfig>(EMPTY_CONFIG);
    const [fields, setFields] = useState<PhysicalFieldBinding[]>([]);
    const [desensitizedFields, setDesensitizedFields] = useState<PhysicalFieldBinding[]>([]);
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const [validation, setValidation] = useState<RegElementQueryConfigValidationResult | null>(null);

    const selectedQueryTable = useMemo(() => (
        physicalTables.find(table => table.modelTableId === config.modelTableId)
        || (physicalTables.length === 1 ? physicalTables[0] : undefined)
    ), [config.modelTableId, physicalTables]);

    useEffect(() => {
        if (!tableId) {
            setConfig(EMPTY_CONFIG);
            return;
        }
        const loadConfig = async () => {
            setLoading(true);
            try {
                const res = await fetch(`/api/reg/table/${tableId}/query-config`, {
                    headers: { Authorization: `Bearer ${token()}` }
                });
                if (res.ok) {
                    const data = await res.json();
                    setConfig({ ...EMPTY_CONFIG, ...data });
                }
            } finally {
                setLoading(false);
            }
        };
        loadConfig();
    }, [tableId]);

    useEffect(() => {
        if (!tableId) {
            setDesensitizedFields([]);
            return;
        }
        const loadDesensitizedFields = async () => {
            try {
                const params = new URLSearchParams({
                    tableId: String(tableId),
                    type: 'FIELD',
                    page: '1',
                    size: '1000'
                });
                const res = await fetch(`/api/reg/element/list?${params.toString()}`, {
                    headers: { Authorization: `Bearer ${token()}` }
                });
                if (!res.ok) {
                    setDesensitizedFields([]);
                    return;
                }
                const data = await res.json();
                const elements: RegElement[] = Array.isArray(data?.records) ? data.records : [];
                const physicalFields = elements
                    .filter(element => element.isDesensitized === 1)
                    .flatMap(element => element.physicalFields || []);
                setDesensitizedFields(physicalFields);
            } catch {
                setDesensitizedFields([]);
            }
        };
        loadDesensitizedFields();
    }, [tableId]);

    useEffect(() => {
        const table = selectedQueryTable;
        if (!table) {
            setFields([]);
            return;
        }
        physicalAssetService.listFields(table).then(setFields).catch(() => setFields([]));
    }, [selectedQueryTable]);

    useEffect(() => {
        if (!selectedQueryTable) return;
        const nextDataSourceId = selectedQueryTable.dataSourceId;
        if (
            config.modelTableId !== selectedQueryTable.modelTableId
            || String(config.dataSourceId || '') !== String(nextDataSourceId || '')
        ) {
            patchConfig({
                modelTableId: selectedQueryTable.modelTableId,
                dataSourceId: nextDataSourceId
            });
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [selectedQueryTable]);

    const patchConfig = (patch: Partial<RegTableQueryConfig>) => {
        setConfig(prev => ({ ...prev, ...patch }));
        setValidation(null);
    };

    const clearFieldMapping = () => ({
        dateFieldId: undefined,
        orgCodeFieldId: undefined,
        orgNameFieldId: undefined,
        defaultReturnFieldIds: [],
        filterFieldIds: [],
        sortFieldIds: []
    });

    const autoMaskFieldIds = useMemo(() => {
        if (!selectedQueryTable) return [];
        const seen = new Set<string>();
        return desensitizedFields
            .filter(field => field.modelTableId === selectedQueryTable.modelTableId)
            .map(field => field.modelFieldId)
            .filter(fieldId => {
                if (seen.has(fieldId)) return false;
                seen.add(fieldId);
                return true;
            });
    }, [desensitizedFields, selectedQueryTable]);

    useEffect(() => {
        const current = (config.maskFieldIds || []).join(',');
        const next = autoMaskFieldIds.join(',');
        if (current !== next) {
            patchConfig({ maskFieldIds: autoMaskFieldIds });
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [autoMaskFieldIds]);

    const payload = () => ({
        ...config,
        dataSourceId: config.dataSourceId ? Number(config.dataSourceId) : undefined,
        maskFieldIds: autoMaskFieldIds
    });

    const multiValue = (event: React.ChangeEvent<HTMLSelectElement>) => (
        Array.from(event.target.selectedOptions).map(option => option.value)
    );

    const validate = async () => {
        if (!tableId) return null;
        const res = await fetch(`/api/reg/table/${tableId}/query-config/validate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token()}`
            },
            body: JSON.stringify(payload())
        });
        const data = await res.json();
        setValidation(data);
        return data as RegElementQueryConfigValidationResult;
    };

    const save = async () => {
        if (!tableId) return;
        setSaving(true);
        try {
            const result = await validate();
            if (config.enabled === 1 && result && !result.valid) return;
            const res = await fetch(`/api/reg/table/${tableId}/query-config`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token()}`
                },
                body: JSON.stringify(payload())
            });
            if (!res.ok) {
                const text = await res.text();
                throw new Error(text || '保存查询配置失败');
            }
            const data = await res.json();
            setConfig({ ...EMPTY_CONFIG, ...data });
        } catch (error: any) {
            setValidation({
                valid: false,
                errors: [error?.message || '保存查询配置失败'],
                warnings: []
            });
        } finally {
            setSaving(false);
        }
    };

    const selectClass = "w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none";

    return (
        <div className="col-span-2 border border-indigo-100 rounded-lg p-3 bg-indigo-50/30">
            <div className="flex items-center justify-between mb-3">
                <div>
                    <div className="text-sm font-bold text-slate-800">明细表物理绑定与查询配置</div>
                    <div className="text-xs text-slate-500">先绑定物理表，再配置字段白名单；字段资产本身不需要单独配置查询。</div>
                </div>
                <label className="inline-flex items-center gap-2 text-sm text-slate-700">
                    <input
                        type="checkbox"
                        disabled={!tableId}
                        checked={config.enabled === 1}
                        onChange={event => patchConfig({ enabled: event.target.checked ? 1 : 0 })}
                    />
                    启用
                </label>
            </div>

            <div className="mb-3 rounded-lg border border-white/70 bg-white/60 p-3">
                <PhysicalBindingSelector
                    mode="table"
                    selectedTables={physicalTables}
                    onTablesChange={(nextTables) => {
                        onPhysicalTablesChange(nextTables);
                        if (!nextTables.some(item => item.modelTableId === config.modelTableId)) {
                            const nextMainTable = nextTables.length === 1 ? nextTables[0] : undefined;
                            patchConfig({
                                modelTableId: nextMainTable?.modelTableId,
                                dataSourceId: nextMainTable?.dataSourceId,
                                ...clearFieldMapping()
                            });
                        }
                    }}
                />
            </div>

            {!tableId && (
                <div className="mb-3 border border-dashed border-slate-200 rounded-lg p-3 text-sm text-slate-500 bg-white/70">
                    保存明细表后可继续保存查询配置；物理表绑定会随表资产一起保存。
                </div>
            )}

            <div className="grid grid-cols-2 gap-3">
                <div className="col-span-2">
                    <label className="block text-xs font-medium text-slate-600 mb-1">主查询物理表</label>
                    {physicalTables.length > 1 ? (
                        <select
                            className={selectClass}
                            disabled={!tableId}
                            value={config.modelTableId || ''}
                            onChange={event => {
                                const table = physicalTables.find(item => item.modelTableId === event.target.value);
                                patchConfig({
                                    modelTableId: table?.modelTableId,
                                    dataSourceId: table?.dataSourceId,
                                    ...clearFieldMapping()
                                });
                            }}
                        >
                            <option value="">-- 从已绑定物理表中选择 --</option>
                            {physicalTables.map(table => (
                                <option key={table.modelTableId} value={table.modelTableId}>
                                    {[table.owner, table.tableName].filter(Boolean).join('.')}
                                    {table.tableCnName ? `（${table.tableCnName}）` : ''}
                                </option>
                            ))}
                        </select>
                    ) : (
                        <div className="border border-slate-200 rounded-lg p-2 text-sm bg-white text-slate-600">
                            {selectedQueryTable
                                ? [selectedQueryTable.owner, selectedQueryTable.tableName].filter(Boolean).join('.')
                                : '请先在上方绑定物理表'}
                        </div>
                    )}
                </div>
                {[
                    ['dateFieldId', '日期字段 *'],
                    ['orgCodeFieldId', '机构编号字段 *'],
                    ['orgNameFieldId', '机构名称字段']
                ].map(([key, label]) => (
                    <div key={key}>
                        <label className="block text-xs font-medium text-slate-600 mb-1">{label}</label>
                        <select
                            className={selectClass}
                            disabled={!tableId}
                            value={(config as any)[key] || ''}
                            onChange={event => patchConfig({ [key]: event.target.value || undefined } as any)}
                        >
                            <option value="">-- 请选择 --</option>
                            {fields.map(field => (
                                <option key={field.modelFieldId} value={field.modelFieldId}>
                                    {fieldLabel(field)}
                                </option>
                            ))}
                        </select>
                    </div>
                ))}
                {[
                    ['defaultReturnFieldIds', '默认返回字段 *'],
                    ['filterFieldIds', '允许筛选字段'],
                    ['sortFieldIds', '允许排序字段']
                ].map(([key, label]) => (
                    <div key={key}>
                        <label className="block text-xs font-medium text-slate-600 mb-1">{label}</label>
                        <select
                            multiple
                            className={`${selectClass} h-24`}
                            disabled={!tableId}
                            value={((config as any)[key] || []) as string[]}
                            onChange={event => patchConfig({ [key]: multiValue(event) } as any)}
                        >
                            {fields.map(field => (
                                <option key={field.modelFieldId} value={field.modelFieldId}>
                                    {fieldLabel(field)}
                                </option>
                            ))}
                        </select>
                    </div>
                ))}
                <div>
                    <label className="block text-xs font-medium text-slate-600 mb-1">脱敏字段</label>
                    <div className={`${selectClass} min-h-24 bg-white overflow-y-auto`}>
                        {autoMaskFieldIds.length > 0 ? (
                            <div className="flex flex-wrap gap-1.5">
                                {desensitizedFields
                                    .filter(field => autoMaskFieldIds.includes(field.modelFieldId))
                                    .map(field => (
                                        <span
                                            key={field.modelFieldId}
                                            className="px-2 py-1 rounded bg-amber-50 border border-amber-100 text-amber-700 text-xs"
                                            title={[field.owner, field.tableName, field.fieldName].filter(Boolean).join('.')}
                                        >
                                            {field.fieldCnName || field.fieldName}
                                        </span>
                                    ))}
                            </div>
                        ) : (
                            <span className="text-xs text-slate-400">当前表字段未标记脱敏</span>
                        )}
                    </div>
                </div>
                <div>
                    <label className="block text-xs font-medium text-slate-600 mb-1">明细最大返回行数</label>
                    <input
                        type="number"
                        min={1}
                        max={5}
                        className={selectClass}
                        disabled={!tableId}
                        value={config.detailMaxRows ?? 5}
                        onChange={event => patchConfig({ detailMaxRows: Number(event.target.value || 5) })}
                    />
                </div>
            </div>

            {validation && (
                <div className="mt-3 text-xs">
                    {validation.errors?.map(error => (
                        <div key={error} className="text-red-600">{error}</div>
                    ))}
                    {validation.warnings?.map(warning => (
                        <div key={warning} className="text-amber-600">{warning}</div>
                    ))}
                    {validation.valid && <div className="text-emerald-600">查询配置校验通过</div>}
                </div>
            )}

            <div className="mt-3 flex justify-end gap-2">
                <button
                    type="button"
                    disabled={!tableId || loading || saving}
                    onClick={validate}
                    className="inline-flex items-center gap-1 px-3 py-1.5 text-sm border border-slate-200 rounded-lg text-slate-600 hover:bg-white"
                >
                    <ShieldCheck size={14} /> 校验
                </button>
                <button
                    type="button"
                    disabled={!tableId || loading || saving}
                    onClick={save}
                    className="inline-flex items-center gap-1 px-3 py-1.5 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
                >
                    <Save size={14} /> 保存配置
                </button>
            </div>
        </div>
    );
};
