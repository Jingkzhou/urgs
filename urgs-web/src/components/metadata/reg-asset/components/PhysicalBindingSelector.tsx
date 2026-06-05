import React, { useEffect, useMemo, useState } from 'react';
import { Database, Hash, Plus, Search, X } from 'lucide-react';
import {
    PhysicalFieldBinding,
    PhysicalTableBinding,
} from '../types';
import { physicalAssetService, PhysicalDataSourceOption } from '../../../../services/physicalAssetService';

interface PhysicalBindingSelectorProps {
    mode: 'table' | 'field';
    selectedTables?: PhysicalTableBinding[];
    selectedFields?: PhysicalFieldBinding[];
    preferredTables?: PhysicalTableBinding[];
    onTablesChange?: (tables: PhysicalTableBinding[]) => void;
    onFieldsChange?: (fields: PhysicalFieldBinding[]) => void;
}

const EMPTY_TABLES: PhysicalTableBinding[] = [];
const EMPTY_FIELDS: PhysicalFieldBinding[] = [];

export const PhysicalBindingSelector: React.FC<PhysicalBindingSelectorProps> = ({
    mode,
    selectedTables = EMPTY_TABLES,
    selectedFields = EMPTY_FIELDS,
    preferredTables = EMPTY_TABLES,
    onTablesChange,
    onFieldsChange,
}) => {
    const [sources, setSources] = useState<PhysicalDataSourceOption[]>([]);
    const [sourceId, setSourceId] = useState<number | undefined>();
    const [owners, setOwners] = useState<string[]>([]);
    const [owner, setOwner] = useState<string>('');
    const [keyword, setKeyword] = useState('');
    const [tables, setTables] = useState<PhysicalTableBinding[]>([]);
    const [fieldTables, setFieldTables] = useState<PhysicalTableBinding[]>([]);
    const [fields, setFields] = useState<PhysicalFieldBinding[]>([]);
    const [loading, setLoading] = useState(false);

    const selectedTableIds = useMemo(() => new Set(selectedTables.map(item => item.modelTableId)), [selectedTables]);
    const selectedFieldIds = useMemo(() => new Set(selectedFields.map(item => item.modelFieldId)), [selectedFields]);
    const filteredFields = useMemo(() => {
        if (mode !== 'field' || !keyword.trim()) {
            return fields;
        }
        const tokens = buildSearchTokens(keyword);
        return fields.filter(field => {
            const searchText = normalizeSearchText([
                field.owner,
                field.tableName,
                field.tableCnName,
                field.fieldName,
                field.fieldCnName,
                field.fieldType,
                [field.owner, field.tableName, field.fieldName].filter(Boolean).join('.'),
            ].filter(Boolean).join(' '));
            return tokens.every(token => searchText.includes(token));
        });
    }, [fields, keyword, mode]);

    useEffect(() => {
        if (mode !== 'table') {
            return;
        }
        physicalAssetService.listDataSources()
            .then(data => {
                setSources(data);
                if (data.length > 0) {
                    const preferredSource = preferredTables.find(item => item.dataSourceId)?.dataSourceId;
                    setSourceId(preferredSource ?? data[0].id);
                }
            })
            .catch(error => console.error('Failed to load physical data sources', error));
    }, [mode, preferredTables]);

    useEffect(() => {
        if (mode !== 'table') {
            return;
        }
        if (!sourceId) {
            setOwners([]);
            setOwner('');
            return;
        }
        physicalAssetService.listOwners(sourceId)
            .then(data => {
                const ownerList = Array.isArray(data) ? data : [];
                setOwners(ownerList);
                const preferredOwner = preferredTables.find(item => item.dataSourceId === sourceId && item.owner)?.owner;
                setOwner(prev => (prev && ownerList.includes(prev) ? prev : preferredOwner ?? ownerList[0] ?? ''));
            })
            .catch(error => {
                console.error('Failed to load physical owners', error);
                setOwners([]);
                setOwner('');
            });
    }, [sourceId, preferredTables, mode]);

    useEffect(() => {
        if (mode === 'field' && preferredTables.length > 0) {
            setFieldTables(preferredTables);
        }
    }, [mode, preferredTables]);

    const searchTables = async () => {
        if (mode !== 'table' || !sourceId) return;
        setLoading(true);
        try {
            const data = await physicalAssetService.listTables({
                dataSourceId: sourceId,
                owner: owner || undefined,
                keyword: keyword || undefined,
                page: 1,
                size: 20,
            });
            setTables(data);
        } catch (error) {
            console.error('Failed to search physical tables', error);
            setTables([]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (mode === 'table' && sourceId) {
            searchTables();
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [sourceId, owner, mode]);

    useEffect(() => {
        const loadPreferredFields = async () => {
            if (mode !== 'field') return;
            setFieldTables(preferredTables);
            if (preferredTables.length === 0) {
                setFields([]);
                return;
            }
            setLoading(true);
            setFields([]);
            try {
                const fieldGroups = await Promise.all(preferredTables.map(table => physicalAssetService.listFields(table)));
                setFields(fieldGroups.flat());
            } catch (error) {
                console.error('Failed to load preferred physical fields', error);
            } finally {
                setLoading(false);
            }
        };
        loadPreferredFields();
    }, [mode, preferredTables]);

    const addTable = (table: PhysicalTableBinding) => {
        if (selectedTableIds.has(table.modelTableId)) return;
        onTablesChange?.([...selectedTables, table]);
    };

    const removeTable = (id: string) => {
        onTablesChange?.(selectedTables.filter(item => item.modelTableId !== id));
    };

    const addField = (field: PhysicalFieldBinding) => {
        if (selectedFieldIds.has(field.modelFieldId)) return;
        onFieldsChange?.([...selectedFields, field]);
    };

    const removeField = (id: string) => {
        onFieldsChange?.(selectedFields.filter(item => item.modelFieldId !== id));
    };

    const renderTableName = (table: PhysicalTableBinding) => (
        <>
            <div className="font-medium text-slate-700 font-mono">{[table.owner, table.tableName].filter(Boolean).join('.')}</div>
            {table.tableCnName && <div className="text-xs text-slate-500">{table.tableCnName}</div>}
        </>
    );

    const renderFieldName = (field: PhysicalFieldBinding) => (
        <>
            <div className="font-medium text-slate-700 font-mono">{field.fieldName}</div>
            <div className="text-xs text-slate-500">
                {[field.fieldCnName, field.fieldType].filter(Boolean).join(' / ') || '-'}
            </div>
            <div className="text-[10px] text-slate-400 font-mono truncate">
                {[field.owner, field.tableName].filter(Boolean).join('.')}
            </div>
        </>
    );

    return (
        <div className="col-span-2 border border-slate-200 rounded-lg p-3 bg-slate-50/60">
            <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2 text-sm font-semibold text-slate-700">
                    {mode === 'table' ? <Database size={15} className="text-indigo-500" /> : <Hash size={15} className="text-indigo-500" />}
                    {mode === 'table' ? '绑定物理表' : '绑定物理字段'}
                </div>
                {loading && <span className="text-xs text-slate-400">加载中...</span>}
            </div>

            <div className="flex flex-wrap gap-2 mb-3 min-h-[28px]">
                {mode === 'table' && selectedTables.map(table => (
                    <span key={table.modelTableId} className="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-indigo-50 text-indigo-700 border border-indigo-100 text-xs">
                        {[table.owner, table.tableName].filter(Boolean).join('.')}
                        <button onClick={() => removeTable(table.modelTableId)} className="hover:text-red-500"><X size={12} /></button>
                    </span>
                ))}
                {mode === 'field' && selectedFields.map(field => (
                    <span
                        key={field.modelFieldId}
                        className="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-indigo-50 text-indigo-700 border border-indigo-100 text-xs"
                        title={[field.owner, field.tableName, field.fieldName].filter(Boolean).join('.')}
                    >
                        {field.fieldName}
                        <button onClick={() => removeField(field.modelFieldId)} className="hover:text-red-500"><X size={12} /></button>
                    </span>
                ))}
                {((mode === 'table' && selectedTables.length === 0) || (mode === 'field' && selectedFields.length === 0)) && (
                    <span className="text-xs text-slate-400">暂未绑定</span>
                )}
            </div>

            {mode === 'table' ? (
                <div className="grid grid-cols-12 gap-2 mb-3">
                    <select
                        className="col-span-4 border border-slate-200 rounded-lg p-2 text-xs bg-white outline-none"
                        value={sourceId || ''}
                        onChange={e => setSourceId(e.target.value ? Number(e.target.value) : undefined)}
                    >
                        <option value="">数据源</option>
                        {sources.map(source => <option key={source.id} value={source.id}>{source.name}</option>)}
                    </select>
                    <select
                        className="col-span-3 border border-slate-200 rounded-lg p-2 text-xs bg-white outline-none"
                        value={owner}
                        onChange={e => setOwner(e.target.value)}
                    >
                        <option value="">全部 Schema</option>
                        {owners.map(item => <option key={item} value={item}>{item}</option>)}
                    </select>
                    <div className="col-span-4 relative">
                        <Search size={13} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            className="w-full pl-8 pr-2 py-2 border border-slate-200 rounded-lg text-xs outline-none bg-white"
                            placeholder="搜索表名"
                            value={keyword}
                            onChange={e => setKeyword(e.target.value)}
                            onKeyDown={e => e.key === 'Enter' && searchTables()}
                        />
                    </div>
                    <button
                        type="button"
                        onClick={searchTables}
                        className="col-span-1 border border-indigo-200 bg-indigo-50 text-indigo-600 rounded-lg flex items-center justify-center hover:bg-indigo-100"
                        title="搜索"
                    >
                        <Search size={14} />
                    </button>
                </div>
            ) : (
                <div className="mb-3 space-y-2">
                    <div className="flex flex-wrap gap-1.5">
                        {preferredTables.map(table => (
                            <span key={table.modelTableId} className="px-2 py-1 rounded bg-white border border-slate-200 text-[10px] text-slate-600 font-mono">
                                {[table.owner, table.tableName].filter(Boolean).join('.')}
                            </span>
                        ))}
                        {preferredTables.length === 0 && (
                            <span className="text-xs text-amber-600 bg-amber-50 border border-amber-100 px-2 py-1 rounded">
                                当前表未绑定物理表，请先在表维度绑定物理表
                            </span>
                        )}
                    </div>
                    <div className="relative">
                        <Search size={13} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            className="w-full pl-8 pr-2 py-2 border border-slate-200 rounded-lg text-xs outline-none bg-white"
                            placeholder="在已绑定物理表下搜索字段"
                            value={keyword}
                            onChange={e => setKeyword(e.target.value)}
                        />
                    </div>
                </div>
            )}

            <div className="max-h-44 overflow-y-auto border border-slate-100 rounded-lg bg-white">
                {mode === 'table' && tables.map(table => (
                    <div key={table.modelTableId} className="flex items-center justify-between px-3 py-2 border-b border-slate-50 last:border-0 text-xs">
                        <div>{renderTableName(table)}</div>
                        <button
                            type="button"
                            onClick={() => addTable(table)}
                            disabled={selectedTableIds.has(table.modelTableId)}
                            className="p-1 rounded text-indigo-600 hover:bg-indigo-50 disabled:text-slate-300"
                            title="绑定"
                        >
                            <Plus size={14} />
                        </button>
                    </div>
                ))}

                {mode === 'field' && fieldTables.length > 0 && filteredFields.length === 0 && !loading && (
                    <div className="p-3 text-xs text-slate-400 text-center">未找到字段</div>
                )}
                {mode === 'field' && filteredFields.length > 0 && (
                    <div className="border-y border-slate-100 bg-slate-50 px-3 py-1.5 text-[10px] font-semibold text-slate-400">已绑定物理表下的字段</div>
                )}
                {mode === 'field' && filteredFields.map(field => (
                    <div key={field.modelFieldId} className="flex items-center justify-between px-3 py-2 border-b border-slate-50 last:border-0 text-xs">
                        <div>{renderFieldName(field)}</div>
                        <button
                            type="button"
                            onClick={() => addField(field)}
                            disabled={selectedFieldIds.has(field.modelFieldId)}
                            className="p-1 rounded text-indigo-600 hover:bg-indigo-50 disabled:text-slate-300"
                            title="绑定"
                        >
                            <Plus size={14} />
                        </button>
                    </div>
                ))}
                {mode === 'table' && tables.length === 0 && !loading && (
                    <div className="p-3 text-xs text-slate-400 text-center">暂无可选数据</div>
                )}
                {mode === 'field' && preferredTables.length === 0 && !loading && (
                    <div className="p-3 text-xs text-slate-400 text-center">暂无可选数据</div>
                )}
            </div>
        </div>
    );
};

const normalizeSearchText = (value: string) => (
    value
        .toLowerCase()
        .replace(/[\s._\-`"'[\]()（）【】]+/g, '')
);

const buildSearchTokens = (value: string) => (
    value
        .trim()
        .toLowerCase()
        .split(/[\s;；,，]+/)
        .map(normalizeSearchText)
        .filter(Boolean)
);
