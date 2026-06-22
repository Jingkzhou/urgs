import React, { useEffect, useMemo, useState } from 'react';
import { Save, ShieldCheck } from 'lucide-react';
import { physicalAssetService } from '../../../../services/physicalAssetService';
import {
    PhysicalFieldBinding,
    PhysicalTableBinding,
    RegElementQueryConfig,
    RegElementQueryConfigValidationResult
} from '../types';

interface QueryConfigPanelProps {
    elementId?: number | string;
    preferredPhysicalTables: PhysicalTableBinding[];
}

const EMPTY_CONFIG: RegElementQueryConfig = {
    enabled: 0,
    queryMode: 'SUMMARY',
    defaultReturnFieldIds: [],
    filterFieldIds: [],
    sortFieldIds: [],
    maskFieldIds: [],
    detailMaxRows: 5
};

const fieldLabel = (field: PhysicalFieldBinding) => (
    field.fieldCnName ? `${field.fieldName}（${field.fieldCnName}）` : field.fieldName
);

const token = () => localStorage.getItem('auth_token') || '';

export const QueryConfigPanel: React.FC<QueryConfigPanelProps> = ({
    elementId,
    preferredPhysicalTables
}) => {
    const [config, setConfig] = useState<RegElementQueryConfig>(EMPTY_CONFIG);
    const [fields, setFields] = useState<PhysicalFieldBinding[]>([]);
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const [validation, setValidation] = useState<RegElementQueryConfigValidationResult | null>(null);

    const dataSourceOptions = useMemo(() => {
        const seen = new Set<string>();
        return preferredPhysicalTables
            .filter(table => table.dataSourceId !== undefined && table.dataSourceId !== null)
            .filter(table => {
                const key = String(table.dataSourceId);
                if (seen.has(key)) return false;
                seen.add(key);
                return true;
            })
            .map(table => ({ value: String(table.dataSourceId), label: `数据源 ${table.dataSourceId}` }));
    }, [preferredPhysicalTables]);

    const tableOptions = useMemo(() => {
        const selectedDataSource = config.dataSourceId ? String(config.dataSourceId) : '';
        return preferredPhysicalTables.filter(table => (
            !selectedDataSource || String(table.dataSourceId || '') === selectedDataSource
        ));
    }, [config.dataSourceId, preferredPhysicalTables]);

    useEffect(() => {
        if (!elementId) {
            setConfig(EMPTY_CONFIG);
            return;
        }
        const loadConfig = async () => {
            setLoading(true);
            try {
                const res = await fetch(`/api/reg/element/${elementId}/query-config`, {
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
    }, [elementId]);

    useEffect(() => {
        const table = preferredPhysicalTables.find(item => item.modelTableId === config.modelTableId);
        if (!table) {
            setFields([]);
            return;
        }
        physicalAssetService.listFields(table).then(setFields).catch(() => setFields([]));
    }, [config.modelTableId, preferredPhysicalTables]);

    const patchConfig = (patch: Partial<RegElementQueryConfig>) => {
        setConfig(prev => ({ ...prev, ...patch }));
        setValidation(null);
    };

    const multiValue = (event: React.ChangeEvent<HTMLSelectElement>) => (
        Array.from(event.target.selectedOptions).map(option => option.value)
    );

    const validate = async () => {
        if (!elementId) return null;
        const payload = {
            ...config,
            dataSourceId: config.dataSourceId ? Number(config.dataSourceId) : undefined
        };
        const res = await fetch(`/api/reg/element/${elementId}/query-config/validate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token()}`
            },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        setValidation(data);
        return data as RegElementQueryConfigValidationResult;
    };

    const save = async () => {
        if (!elementId) return;
        setSaving(true);
        try {
            const result = await validate();
            if (config.enabled === 1 && result && !result.valid) {
                return;
            }
            const res = await fetch(`/api/reg/element/${elementId}/query-config`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${token()}`
                },
                body: JSON.stringify({
                    ...config,
                    dataSourceId: config.dataSourceId ? Number(config.dataSourceId) : undefined
                })
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

    if (!elementId) {
        return (
            <div className="col-span-2 border border-dashed border-slate-200 rounded-lg p-3 text-sm text-slate-500">
                保存指标后可配置数据查询。
            </div>
        );
    }

    const selectClass = "w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none";

    return (
        <div className="col-span-2 border border-indigo-100 rounded-lg p-3 bg-indigo-50/30">
            <div className="flex items-center justify-between mb-3">
                <div>
                    <div className="text-sm font-bold text-slate-800">数据查询配置</div>
                    <div className="text-xs text-slate-500">仅使用已绑定物理表字段生成受控查询，不执行代码片段。</div>
                </div>
                <label className="inline-flex items-center gap-2 text-sm text-slate-700">
                    <input
                        type="checkbox"
                        checked={config.enabled === 1}
                        onChange={event => patchConfig({ enabled: event.target.checked ? 1 : 0 })}
                    />
                    启用
                </label>
            </div>

            <div className="grid grid-cols-2 gap-3">
                <div>
                    <label className="block text-xs font-medium text-slate-600 mb-1">查询模式</label>
                    <select
                        className={selectClass}
                        value={config.queryMode || 'SUMMARY'}
                        onChange={event => patchConfig({ queryMode: event.target.value as 'SUMMARY' | 'DETAIL' })}
                    >
                        <option value="SUMMARY">汇总</option>
                        <option value="DETAIL">明细</option>
                    </select>
                </div>
                <div>
                    <label className="block text-xs font-medium text-slate-600 mb-1">数据源</label>
                    <select
                        className={selectClass}
                        value={config.dataSourceId ? String(config.dataSourceId) : ''}
                        onChange={event => patchConfig({
                            dataSourceId: event.target.value,
                            modelTableId: undefined,
                            dateFieldId: undefined,
                            orgCodeFieldId: undefined,
                            orgNameFieldId: undefined,
                            metricCodeFieldId: undefined,
                            valueFieldId: undefined,
                            defaultReturnFieldIds: [],
                            filterFieldIds: [],
                            sortFieldIds: [],
                            maskFieldIds: []
                        })}
                    >
                        <option value="">-- 请选择 --</option>
                        {dataSourceOptions.map(option => (
                            <option key={option.value} value={option.value}>{option.label}</option>
                        ))}
                    </select>
                </div>
                <div className="col-span-2">
                    <label className="block text-xs font-medium text-slate-600 mb-1">主查询物理表</label>
                    <select
                        className={selectClass}
                        value={config.modelTableId || ''}
                        onChange={event => patchConfig({
                            modelTableId: event.target.value || undefined,
                            dateFieldId: undefined,
                            orgCodeFieldId: undefined,
                            orgNameFieldId: undefined,
                            metricCodeFieldId: undefined,
                            valueFieldId: undefined,
                            defaultReturnFieldIds: [],
                            filterFieldIds: [],
                            sortFieldIds: [],
                            maskFieldIds: []
                        })}
                    >
                        <option value="">-- 请选择 --</option>
                        {tableOptions.map(table => (
                            <option key={table.modelTableId} value={table.modelTableId}>
                                {[table.owner, table.tableName].filter(Boolean).join('.')}
                                {table.tableCnName ? `（${table.tableCnName}）` : ''}
                            </option>
                        ))}
                    </select>
                </div>
                {[
                    ['dateFieldId', '日期字段 *'],
                    ['orgCodeFieldId', '机构编号字段 *'],
                    ['orgNameFieldId', '机构名称字段'],
                    ['metricCodeFieldId', '指标编号字段'],
                    ['valueFieldId', '指标值字段 *']
                ].map(([key, label]) => (
                    <div key={key}>
                        <label className="block text-xs font-medium text-slate-600 mb-1">{label}</label>
                        <select
                            className={selectClass}
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
                    ['sortFieldIds', '允许排序字段'],
                    ['maskFieldIds', '脱敏字段']
                ].map(([key, label]) => (
                    <div key={key}>
                        <label className="block text-xs font-medium text-slate-600 mb-1">{label}</label>
                        <select
                            multiple
                            className={`${selectClass} h-24`}
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
                    <label className="block text-xs font-medium text-slate-600 mb-1">明细最大返回行数</label>
                    <input
                        type="number"
                        min={1}
                        max={5}
                        className={selectClass}
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
                    disabled={loading || saving}
                    onClick={validate}
                    className="inline-flex items-center gap-1 px-3 py-1.5 text-sm border border-slate-200 rounded-lg text-slate-600 hover:bg-white"
                >
                    <ShieldCheck size={14} /> 校验
                </button>
                <button
                    type="button"
                    disabled={loading || saving}
                    onClick={save}
                    className="inline-flex items-center gap-1 px-3 py-1.5 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
                >
                    <Save size={14} /> 保存配置
                </button>
            </div>
        </div>
    );
};
