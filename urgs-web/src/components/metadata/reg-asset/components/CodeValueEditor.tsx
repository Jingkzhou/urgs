import React, { useEffect, useMemo, useState } from 'react';
import { Loader2, Plus, RotateCcw, Trash2 } from 'lucide-react';
import { CodeDirectoryChange, CodeDirectoryItem } from '../types';

type EditableCodeItem = CodeDirectoryItem & {
    clientId: string;
    operation?: CodeDirectoryChange['operation'];
};

interface CodeValueEditorProps {
    tableCode?: string;
    tableName?: string;
    systemCode?: string;
    onChangesChange: (changes: CodeDirectoryChange[]) => void;
}

const createClientId = () => `new-${Date.now()}-${Math.random().toString(36).slice(2)}`;

const toChangeData = (item: EditableCodeItem): CodeDirectoryItem => ({
    id: item.operation === 'CREATE' ? undefined : item.id,
    tableCode: item.tableCode,
    tableName: item.tableName,
    sortOrder: item.sortOrder,
    code: item.code,
    name: item.name,
    parentCode: item.parentCode,
    level: item.level,
    description: item.description,
    startDate: item.startDate,
    endDate: item.endDate,
    standard: item.standard,
    systemCode: item.systemCode,
});

export const CodeValueEditor: React.FC<CodeValueEditorProps> = ({
    tableCode,
    tableName,
    systemCode,
    onChangesChange,
}) => {
    const [items, setItems] = useState<EditableCodeItem[]>([]);
    const [loading, setLoading] = useState(false);
    const [loadError, setLoadError] = useState('');

    useEffect(() => {
        onChangesChange(
            items
                .filter(item => item.operation)
                .map(item => ({
                    operation: item.operation!,
                    data: toChangeData(item),
                }))
        );
    }, [items, onChangesChange]);

    useEffect(() => {
        if (!tableCode) {
            setItems([]);
            setLoadError('');
            return;
        }

        const fetchCodes = async () => {
            setLoading(true);
            setLoadError('');
            try {
                const token = localStorage.getItem('auth_token');
                const params = new URLSearchParams({
                    tableCode,
                    page: '1',
                    size: '1000',
                });
                const response = await fetch(`/api/metadata/code-directory?${params.toString()}`, {
                    headers: { 'Authorization': `Bearer ${token}` },
                });
                if (!response.ok) {
                    throw new Error('加载码值失败');
                }
                const data = await response.json();
                const records = Array.isArray(data?.records) ? data.records : [];
                setItems(records.map((record: CodeDirectoryItem) => ({
                    ...record,
                    clientId: record.id || createClientId(),
                })));
            } catch (error) {
                console.error('Failed to fetch code values', error);
                setItems([]);
                setLoadError('码值加载失败，请重试');
            } finally {
                setLoading(false);
            }
        };

        fetchCodes();
    }, [tableCode]);

    const changeSummary = useMemo(() => {
        const created = items.filter(item => item.operation === 'CREATE').length;
        const updated = items.filter(item => item.operation === 'UPDATE').length;
        const deleted = items.filter(item => item.operation === 'DELETE').length;
        return { created, updated, deleted, total: created + updated + deleted };
    }, [items]);

    const addItem = () => {
        setItems(current => [
            ...current,
            {
                clientId: createClientId(),
                operation: 'CREATE',
                tableCode: tableCode || '',
                tableName: tableName || '',
                systemCode,
                sortOrder: current.filter(item => item.operation !== 'DELETE').length + 1,
                code: '',
                name: '',
            },
        ]);
    };

    const updateItem = (
        clientId: string,
        field: keyof CodeDirectoryItem,
        value: string | number | undefined
    ) => {
        setItems(current => current.map(item => {
            if (item.clientId !== clientId) {
                return item;
            }
            return {
                ...item,
                [field]: value,
                operation: item.operation === 'CREATE' ? 'CREATE' : 'UPDATE',
            };
        }));
    };

    const deleteItem = (clientId: string) => {
        setItems(current => current.flatMap(item => {
            if (item.clientId !== clientId) {
                return [item];
            }
            return item.operation === 'CREATE' ? [] : [{ ...item, operation: 'DELETE' }];
        }));
    };

    const restoreItem = (clientId: string) => {
        setItems(current => current.map(item => (
            item.clientId === clientId ? { ...item, operation: undefined } : item
        )));
    };

    if (!tableCode) {
        return (
            <div className="col-span-2 rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center text-sm text-slate-400">
                选择值域代码表后，可在这里直接维护对应码值
            </div>
        );
    }

    return (
        <div className="col-span-2 rounded-xl border border-slate-200 bg-slate-50/50 overflow-hidden">
            <div className="px-4 py-3 border-b border-slate-200 bg-white flex items-center justify-between">
                <div>
                    <div className="text-sm font-semibold text-slate-700">码值明细</div>
                    <div className="text-xs text-slate-400 mt-0.5">
                        {tableCode}{tableName ? ` · ${tableName}` : ''}
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    {changeSummary.total > 0 && (
                        <span className="text-xs text-indigo-600">
                            待保存：新增 {changeSummary.created}、修改 {changeSummary.updated}、删除 {changeSummary.deleted}
                        </span>
                    )}
                    <button
                        type="button"
                        onClick={addItem}
                        className="h-8 px-3 rounded-lg bg-indigo-50 text-indigo-600 hover:bg-indigo-100 text-xs font-medium flex items-center gap-1"
                    >
                        <Plus size={14} /> 新增码值
                    </button>
                </div>
            </div>

            {loading ? (
                <div className="h-24 flex items-center justify-center text-sm text-slate-400">
                    <Loader2 size={16} className="animate-spin mr-2" /> 加载码值
                </div>
            ) : loadError ? (
                <div className="h-24 flex items-center justify-center text-sm text-red-500">{loadError}</div>
            ) : (
                <div className="max-h-64 overflow-auto">
                    <div className="min-w-[780px]">
                        <div className="grid grid-cols-[70px_140px_180px_130px_100px_1fr_70px] gap-2 px-3 py-2 bg-slate-100 text-[11px] font-medium text-slate-500 sticky top-0 z-[1]">
                            <span>序号</span>
                            <span>编码 *</span>
                            <span>名称 *</span>
                            <span>上级编码</span>
                            <span>层级</span>
                            <span>说明</span>
                            <span className="text-right">操作</span>
                        </div>
                        {items.length === 0 ? (
                            <div className="py-8 text-center text-sm text-slate-400">当前代码表暂无码值</div>
                        ) : items.map(item => {
                            const deleted = item.operation === 'DELETE';
                            const inputClass = "w-full h-8 px-2 border border-slate-200 rounded-md text-xs bg-white focus:outline-none focus:ring-2 focus:ring-indigo-100 disabled:bg-slate-100";
                            return (
                                <div
                                    key={item.clientId}
                                    className={`grid grid-cols-[70px_140px_180px_130px_100px_1fr_70px] gap-2 px-3 py-2 border-t border-slate-100 items-center ${deleted ? 'bg-red-50/70 opacity-70' : 'bg-white'}`}
                                >
                                    <input
                                        type="number"
                                        disabled={deleted}
                                        className={inputClass}
                                        value={item.sortOrder ?? ''}
                                        onChange={event => updateItem(item.clientId, 'sortOrder', event.target.value ? Number(event.target.value) : undefined)}
                                    />
                                    <input
                                        disabled={deleted}
                                        className={inputClass}
                                        value={item.code}
                                        onChange={event => updateItem(item.clientId, 'code', event.target.value)}
                                    />
                                    <input
                                        disabled={deleted}
                                        className={inputClass}
                                        value={item.name}
                                        onChange={event => updateItem(item.clientId, 'name', event.target.value)}
                                    />
                                    <input
                                        disabled={deleted}
                                        className={inputClass}
                                        value={item.parentCode || ''}
                                        onChange={event => updateItem(item.clientId, 'parentCode', event.target.value)}
                                    />
                                    <input
                                        disabled={deleted}
                                        className={inputClass}
                                        value={item.level || ''}
                                        onChange={event => updateItem(item.clientId, 'level', event.target.value)}
                                    />
                                    <input
                                        disabled={deleted}
                                        className={inputClass}
                                        value={item.description || ''}
                                        onChange={event => updateItem(item.clientId, 'description', event.target.value)}
                                    />
                                    <div className="flex justify-end">
                                        {deleted ? (
                                            <button
                                                type="button"
                                                onClick={() => restoreItem(item.clientId)}
                                                className="p-1.5 text-slate-500 hover:text-indigo-600"
                                                title="撤销删除"
                                            >
                                                <RotateCcw size={14} />
                                            </button>
                                        ) : (
                                            <button
                                                type="button"
                                                onClick={() => deleteItem(item.clientId)}
                                                className="p-1.5 text-slate-400 hover:text-red-600"
                                                title="删除码值"
                                            >
                                                <Trash2 size={14} />
                                            </button>
                                        )}
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}
        </div>
    );
};
