import React, { useEffect, useMemo, useState } from 'react';
import {
    Database,
    Search,
    RefreshCw,
    Table,
    Server,
    Users,
    Hash,
    Layers,
    ChevronRight,
    ChevronLeft,
    Filter,
    Info,
    Calendar,
    ArrowRight,
    Activity,
    DatabaseZap
} from 'lucide-react';
import Pagination from '../common/Pagination';
import { get, post } from '@/utils/request';
import Auth from '../Auth';

interface DataSourceConfig {
    id: number;
    name: string;
    metaId: number;
    connectionParams: Record<string, any>;
    status: number;
    metaName?: string;
    metaCategory?: string;
    metaCode?: string;
}

interface DataSourceMeta {
    id: number;
    code: string;
    name: string;
    category: string;
}

interface ModelTable {
    id: string;
    name: string;
    cnName?: string;
    owner?: string;
    dataSourceId?: number;
    createTime?: string;
}

interface ModelField {
    id: string;
    name: string;
    cnName?: string;
    type?: string;
    isPk?: boolean;
    nullable?: boolean;
    domain?: string;
    remark?: string;
    sortOrder?: number;
}

interface CodeEntry {
    id: string;
    code: string;
    name: string;
    description?: string;
}

interface PageResult<T> {
    records: T[];
    total: number;
}

const MetadataModel: React.FC = () => {
    // --- State ---
    const [sources, setSources] = useState<DataSourceConfig[]>([]);
    const [selectedSourceId, setSelectedSourceId] = useState<number | null>(null);
    const [owners, setOwners] = useState<string[]>([]);
    const [selectedOwner, setSelectedOwner] = useState<string | null>(null);

    const [tables, setTables] = useState<ModelTable[]>([]);
    const [tablePage, setTablePage] = useState(1);
    const [tableSize, setTableSize] = useState(10);
    const [tableTotal, setTableTotal] = useState(0);
    const [tableKeyword, setTableKeyword] = useState('');
    const [selectedTable, setSelectedTable] = useState<ModelTable | null>(null);

    const [fields, setFields] = useState<ModelField[]>([]);
    const [selectedField, setSelectedField] = useState<ModelField | null>(null);

    const [domainValues, setDomainValues] = useState<CodeEntry[]>([]);
    const [domainPage, setDomainPage] = useState(1);
    const [domainSize, setDomainSize] = useState(10);
    const [domainTotal, setDomainTotal] = useState(0);

    const [loadingSources, setLoadingSources] = useState(false);
    const [loadingOwners, setLoadingOwners] = useState(false);
    const [loadingTables, setLoadingTables] = useState(false);
    const [loadingFields, setLoadingFields] = useState(false);
    const [loadingDomain, setLoadingDomain] = useState(false);
    const [syncing, setSyncing] = useState(false);
    const [lastSyncAt, setLastSyncAt] = useState<string | null>(null);

    const [isSidebarOpen, setIsSidebarOpen] = useState(true);
    const [isRightPanelOpen, setIsRightPanelOpen] = useState(false);

    // --- Memoed ---
    const selectedSource = useMemo(
        () => sources.find((source) => source.id === selectedSourceId),
        [sources, selectedSourceId]
    );

    // --- Actions ---
    const fetchSources = async () => {
        setLoadingSources(true);
        try {
            const [metaData, configData] = await Promise.all([
                get<DataSourceMeta[]>('/api/datasource/meta'),
                get<DataSourceConfig[]>('/api/datasource/config'),
            ]);

            const metas = Array.isArray(metaData) ? metaData : [];
            const configs = Array.isArray(configData) ? configData : [];
            const metaMap = new Map<number, DataSourceMeta>();
            metas.forEach((meta) => metaMap.set(meta.id, meta));

            const dbSources = configs
                .map((config) => {
                    const meta = metaMap.get(config.metaId);
                    return {
                        ...config,
                        metaName: meta?.name,
                        metaCategory: meta?.category,
                        metaCode: meta?.code,
                    };
                })
                .filter((config) => (config.metaCategory || '').toUpperCase() === 'RDBMS');

            setSources(dbSources);
            if (dbSources.length > 0) {
                setSelectedSourceId((prev) => (prev && dbSources.some((item) => item.id === prev) ? prev : dbSources[0].id));
            } else {
                setSelectedSourceId(null);
            }
        } catch (error) {
            console.error('Failed to fetch data sources:', error);
            setSources([]);
            setSelectedSourceId(null);
        } finally {
            setLoadingSources(false);
        }
    };

    const fetchOwners = async (sourceId: number) => {
        setLoadingOwners(true);
        try {
            const data = await get<string[]>('/api/metadata/model-table/owners', { dataSourceId: String(sourceId) });
            const ownerList = Array.isArray(data) ? data : [];
            setOwners(ownerList);
            setSelectedOwner((prev) => (prev && ownerList.includes(prev) ? prev : ownerList[0] ?? null));
        } catch (error) {
            console.error('Failed to fetch owners:', error);
            setOwners([]);
            setSelectedOwner(null);
        } finally {
            setLoadingOwners(false);
        }
    };

    const fetchTables = async (sourceId: number, owner: string | null, page = tablePage, size = tableSize) => {
        setLoadingTables(true);
        try {
            const data = await get<PageResult<ModelTable>>('/api/metadata/model-table', {
                dataSourceId: String(sourceId),
                owner: owner ?? undefined,
                keyword: tableKeyword || undefined,
                page: String(page),
                size: String(size),
            });
            const records = data?.records ?? [];
            setTables(records);
            setTableTotal(data?.total ?? 0);
            if (!selectedTable || !records.some(r => r.id === selectedTable.id)) {
                // 不自动选择，除非之前没选或者被切掉了
                // setSelectedTable(records[0] ?? null);
            }
        } catch (error) {
            console.error('Failed to fetch tables:', error);
            setTables([]);
            setTableTotal(0);
        } finally {
            setLoadingTables(false);
        }
    };

    const fetchFields = async (tableId: string) => {
        setLoadingFields(true);
        try {
            const data = await get<ModelField[]>('/api/metadata/model-field', { tableId });
            setFields(Array.isArray(data) ? data : []);
            setSelectedField(null);
        } catch (error) {
            console.error('Failed to fetch fields:', error);
            setFields([]);
        } finally {
            setLoadingFields(false);
        }
    };

    const fetchDomainValues = async (domain: string, page = domainPage, size = domainSize) => {
        setLoadingDomain(true);
        try {
            const data = await get<PageResult<CodeEntry>>('/api/metadata/code-directory', {
                tableCode: domain,
                page: String(page),
                size: String(size),
            });
            setDomainValues(data?.records ?? []);
            setDomainTotal(data?.total ?? 0);
        } catch (error) {
            console.error('Failed to fetch domain values:', error);
            setDomainValues([]);
            setDomainTotal(0);
        } finally {
            setLoadingDomain(false);
        }
    };

    const handleSync = async () => {
        if (!selectedSourceId) return;
        setSyncing(true);
        try {
            await post('/api/metadata/model-table/sync', { dataSourceId: selectedSourceId });
            setLastSyncAt(new Date().toLocaleString());
            await fetchOwners(selectedSourceId);
        } catch (error) {
            console.error('Sync failed:', error);
        } finally {
            setSyncing(false);
        }
    };

    const handleSearch = (event: React.KeyboardEvent<HTMLInputElement>) => {
        if (event.key !== 'Enter' || !selectedSourceId) return;
        if (tablePage === 1) {
            fetchTables(selectedSourceId, selectedOwner, 1, tableSize);
        } else {
            setTablePage(1);
        }
    };

    const handleTableSelect = (table: ModelTable) => {
        setSelectedTable(table);
        setIsRightPanelOpen(false); // 重置右侧面板，当点击新表时
    };

    const handleFieldSelect = (field: ModelField) => {
        setSelectedField(field);
        if (field.domain) {
            setIsRightPanelOpen(true);
            setDomainPage(1);
        } else {
            setIsRightPanelOpen(true); // 即使没值域也显示详情
        }
    };

    // --- Effects ---
    useEffect(() => {
        fetchSources();
    }, []);

    useEffect(() => {
        if (!selectedSourceId) {
            setOwners([]);
            setSelectedOwner(null);
            setTables([]);
            setSelectedTable(null);
            return;
        }
        fetchOwners(selectedSourceId);
    }, [selectedSourceId]);

    useEffect(() => {
        if (!selectedSourceId) return;
        fetchTables(selectedSourceId, selectedOwner, tablePage, tableSize);
    }, [selectedSourceId, selectedOwner, tablePage, tableSize]);

    useEffect(() => {
        if (!selectedTable?.id) {
            setFields([]);
            return;
        }
        fetchFields(selectedTable.id);
    }, [selectedTable?.id]);

    useEffect(() => {
        if (!selectedField?.domain) {
            setDomainValues([]);
            setDomainTotal(0);
            return;
        }
        fetchDomainValues(selectedField.domain, domainPage, domainSize);
    }, [selectedField?.domain, domainPage, domainSize]);

    return (
        <div className="flex h-[calc(100vh-140px)] w-full overflow-hidden rounded-3xl border border-slate-200 bg-[#F9FAFB] shadow-2xl transition-all duration-500"
            style={{ fontFamily: '"Inter", "Outfit", sans-serif' }}>

            {/* --- Sidebar (Navigator) --- */}
            <aside className={`relative flex flex-col border-r border-slate-200 bg-white transition-all duration-300 ease-in-out ${isSidebarOpen ? 'w-80' : 'w-0 opacity-0 overflow-hidden'}`}>
                <div className="flex flex-col h-full">
                    {/* Sidebar Header */}
                    <div className="p-6 pb-4">
                        <div className="mb-6 flex items-center gap-3">
                            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-lg shadow-indigo-200">
                                <DatabaseZap size={20} />
                            </div>
                            <div>
                                <h2 className="text-lg font-bold text-slate-900 tracking-tight">物理仓库</h2>
                                <p className="text-[10px] font-medium uppercase tracking-widest text-slate-400">Warehouse Navigator</p>
                            </div>
                        </div>

                        {/* Source Selector */}
                        <div className="space-y-2">
                            <label className="text-[11px] font-bold uppercase tracking-wider text-slate-400">数据源</label>
                            <div className="relative group">
                                <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-indigo-500 transition-colors">
                                    <Server size={14} />
                                </div>
                                <select
                                    value={selectedSourceId ?? ''}
                                    onChange={(e) => setSelectedSourceId(Number(e.target.value))}
                                    className="h-10 w-full appearance-none rounded-xl border border-slate-200 bg-slate-50 pl-9 pr-8 text-sm font-medium text-slate-700 focus:border-indigo-500 focus:outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all cursor-pointer"
                                    disabled={loadingSources}
                                >
                                    {sources.map(s => (
                                        <option key={s.id} value={s.id}>{s.name}</option>
                                    ))}
                                </select>
                                <div className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-slate-400">
                                    <ChevronRight size={14} className="rotate-90" />
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Owner List */}
                    <div className="flex-1 overflow-y-auto px-6 pb-6">
                        <div className="mb-2 mt-4 flex items-center justify-between">
                            <label className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Schema / 用户</label>
                            <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-500">{owners.length}</span>
                        </div>
                        {loadingOwners ? (
                            <div className="mt-4 space-y-2">
                                {[1, 2, 3].map(i => <div key={i} className="h-10 w-full animate-pulse rounded-xl bg-slate-50" />)}
                            </div>
                        ) : (
                            <div className="space-y-1">
                                {owners.map(owner => (
                                    <button
                                        key={owner}
                                        onClick={() => setSelectedOwner(owner)}
                                        className={`group flex w-full items-center justify-between rounded-xl px-4 py-2.5 text-left text-sm transition-all duration-200 ${selectedOwner === owner
                                            ? 'bg-indigo-50 text-indigo-700 font-semibold ring-1 ring-inset ring-indigo-200 shadow-sm'
                                            : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                                            }`}
                                    >
                                        <div className="flex items-center gap-3">
                                            <Users size={16} className={selectedOwner === owner ? 'text-indigo-500' : 'text-slate-400 group-hover:text-slate-600'} />
                                            <span>{owner}</span>
                                        </div>
                                        {selectedOwner === owner && <Activity size={12} className="text-indigo-400" />}
                                    </button>
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Sidebar Footer */}
                    <div className="border-t border-slate-100 p-6">
                        <Auth code="metadata:model:sync">
                            <button
                                onClick={handleSync}
                                disabled={syncing || !selectedSourceId}
                                className="flex w-full items-center justify-center gap-2 rounded-xl bg-slate-900 py-3 text-sm font-semibold text-white shadow-xl shadow-slate-200 transition-all hover:bg-indigo-600 hover:shadow-indigo-200 disabled:opacity-50"
                            >
                                <RefreshCw size={16} className={syncing ? 'animate-spin' : ''} />
                                {syncing ? '同步中...' : '同步元数据'}
                            </button>
                        </Auth>
                    </div>
                </div>
            </aside>

            {/* --- Main Content (Canvas) --- */}
            <main className="flex flex-1 flex-col min-w-0 bg-white/50 relative overflow-hidden">

                {/* Visual Background Accents */}
                <div className="absolute top-0 right-0 -mr-24 -mt-24 h-64 w-64 rounded-full bg-indigo-50/50 blur-3xl" />
                <div className="absolute bottom-0 left-0 -ml-24 -mb-24 h-64 w-64 rounded-full bg-purple-50/50 blur-3xl" />

                {/* Header / Search Area */}
                <header className="relative z-10 flex items-center justify-between border-b border-slate-200 bg-white/60 px-8 py-5 backdrop-blur-md">
                    <div className="flex items-center gap-4">
                        <button
                            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
                            className="flex h-10 w-10 items-center justify-center rounded-xl bg-white border border-slate-200 text-slate-500 hover:text-indigo-600 hover:border-indigo-100 transition-all shadow-sm"
                        >
                            {isSidebarOpen ? <ChevronLeft size={18} /> : <ChevronRight size={18} />}
                        </button>
                        <div className="flex flex-col">
                            <nav className="flex items-center gap-2 text-xs font-medium text-slate-400 mb-0.5">
                                <span>{selectedSource?.name || '仓库'}</span>
                                <ChevronRight size={12} />
                                <span className="text-indigo-500 font-semibold">{selectedOwner || '全选'}</span>
                            </nav>
                            <h1 className="text-lg font-bold text-slate-900">
                                {selectedTable ? selectedTable.name : '物理表资产目录'}
                            </h1>
                        </div>
                    </div>

                    <div className="flex items-center gap-4">
                        {/* Global Search */}
                        <div className="relative w-72">
                            <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">
                                <Search size={16} />
                            </div>
                            <input
                                type="text"
                                placeholder="搜索物理表..."
                                value={tableKeyword}
                                onChange={(e) => setTableKeyword(e.target.value)}
                                onKeyDown={handleSearch}
                                className="h-10 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm focus:border-indigo-500 focus:outline-none focus:ring-4 focus:ring-indigo-500/10 transition-all shadow-sm"
                            />
                        </div>

                        <div className="flex gap-2">
                            <div className="flex items-center gap-1.5 rounded-xl border border-slate-100 bg-slate-50/50 px-3 py-1.5 shadow-sm">
                                <Table size={14} className="text-amber-500" />
                                <span className="text-xs font-bold text-slate-600">{tableTotal}</span>
                            </div>
                            <div className="flex items-center gap-1.5 rounded-xl border border-slate-100 bg-slate-50/50 px-3 py-1.5 shadow-sm">
                                <Hash size={14} className="text-indigo-500" />
                                <span className="text-xs font-bold text-slate-600">{fields.length}</span>
                            </div>
                        </div>
                    </div>
                </header>

                {/* Content Body */}
                <div className="relative z-10 flex-1 overflow-hidden p-8 flex flex-col min-h-0">
                    {!selectedTable ? (
                        /* Table Grid View */
                        <div className="flex flex-col h-full">
                            <div className="mb-6 flex items-center gap-2">
                                <Filter size={16} className="text-slate-400" />
                                <span className="text-sm font-bold text-slate-600">全部物理表</span>
                            </div>
                            <div className="flex-1 overflow-y-auto pr-2 custom-scrollbar">
                                {loadingTables ? (
                                    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
                                        {[1, 2, 3, 4, 5, 6].map(i => <div key={i} className="h-32 animate-pulse rounded-2xl bg-white border border-slate-100" />)}
                                    </div>
                                ) : tables.length === 0 ? (
                                    <div className="flex h-64 flex-col items-center justify-center rounded-3xl border border-dashed border-slate-200 bg-white/40">
                                        <div className="mb-4 rounded-full bg-slate-100 p-4 text-slate-400"><Search size={32} /></div>
                                        <p className="text-sm font-medium text-slate-500">未找到任何表资产</p>
                                    </div>
                                ) : (
                                    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
                                        {tables.map(table => (
                                            <button
                                                key={table.id}
                                                onClick={() => handleTableSelect(table)}
                                                className="group relative h-full flex flex-col rounded-2xl border border-slate-200 bg-white p-5 text-left transition-all hover:border-indigo-300 hover:shadow-xl hover:shadow-indigo-500/5"
                                            >
                                                <div className="mb-3 flex items-start justify-between">
                                                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-50 text-amber-600 group-hover:bg-amber-100 transition-colors">
                                                        <Table size={20} />
                                                    </div>
                                                    <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">{table.owner}</span>
                                                </div>
                                                <h3 className="mb-1 font-mono text-sm font-bold text-slate-900 truncate group-hover:text-indigo-600 transition-colors">{table.name}</h3>
                                                <p className="text-xs text-slate-500 line-clamp-2">{table.cnName || '暂无描述'}</p>
                                                <div className="mt-4 flex items-center justify-end opacity-0 group-hover:opacity-100 transition-all transform translate-x-2 group-hover:translate-x-0">
                                                    <span className="text-[11px] font-bold text-indigo-600 flex items-center gap-1">查看详细 <ArrowRight size={12} /></span>
                                                </div>
                                            </button>
                                        ))}
                                    </div>
                                )}
                            </div>
                            <div className="mt-6">
                                <Pagination
                                    current={tablePage}
                                    total={tableTotal}
                                    pageSize={tableSize}
                                    onChange={(p, s) => { setTablePage(p); setTableSize(s); }}
                                />
                            </div>
                        </div>
                    ) : (
                        /* Field Table View */
                        <div className="flex flex-col h-full">
                            <div className="mb-6 flex items-center justify-between">
                                <div className="flex items-center gap-3">
                                    <button
                                        onClick={() => setSelectedTable(null)}
                                        className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-600 hover:bg-slate-50 transition-all shadow-sm"
                                    >
                                        <ChevronLeft size={14} /> 返回目录
                                    </button>
                                    <div className="h-4 w-px bg-slate-200 mx-1" />
                                    <h2 className="text-sm font-bold text-slate-800 flex items-center gap-2">
                                        {selectedTable.name}
                                        <span className="text-xs font-normal text-slate-400 font-sans italic">{selectedTable.cnName}</span>
                                    </h2>
                                </div>
                                <div className="flex gap-2 text-[11px] font-medium text-slate-400">
                                    <span className="flex items-center gap-1"><Calendar size={12} /> 创建于 {selectedTable.createTime || '未知'}</span>
                                </div>
                            </div>

                            <div className="flex-1 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm flex flex-col">
                                <div className="grid grid-cols-[300px_minmax(150px,1fr)_120px_150px] gap-4 border-b border-slate-100 bg-slate-50/80 px-4 py-3 text-[11px] font-bold uppercase tracking-wider text-slate-500">
                                    <span>字段名称 / 注释</span>
                                    <span>数据类型</span>
                                    <span>属性</span>
                                    <span className="text-right">关联值域</span>
                                </div>
                                <div className="flex-1 overflow-y-auto">
                                    {loadingFields ? (
                                        <div className="p-4 space-y-4">
                                            {[1, 2, 3, 4, 5].map(i => <div key={i} className="h-10 animate-pulse bg-slate-50 rounded-lg" />)}
                                        </div>
                                    ) : (
                                        fields.map((field, idx) => (
                                            <div
                                                key={field.id}
                                                onClick={() => handleFieldSelect(field)}
                                                className={`grid grid-cols-[300px_minmax(150px,1fr)_120px_150px] gap-4 border-b border-slate-50 px-4 py-3.5 items-center transition-all cursor-pointer group ${selectedField?.id === field.id ? 'bg-indigo-50/50' : 'hover:bg-slate-50/50'}`}
                                            >
                                                <div className="flex items-start gap-3">
                                                    <div className={`mt-0.5 flex h-6 w-6 items-center justify-center rounded bg-slate-100 text-[10px] font-bold ${field.isPk ? 'bg-amber-100 text-amber-700' : 'text-slate-400'}`}>
                                                        {field.isPk ? 'PK' : idx + 1}
                                                    </div>
                                                    <div className="min-w-0">
                                                        <div className="font-mono text-sm font-semibold text-slate-900 group-hover:text-indigo-600 truncate transition-colors">{field.name}</div>
                                                        <div className="text-xs text-slate-400 truncate mt-0.5">{field.cnName || '—'}</div>
                                                    </div>
                                                </div>
                                                <div className="font-mono text-[13px] text-slate-600">{field.type}</div>
                                                <div className="flex flex-wrap gap-1.5">
                                                    {field.isPk && <span className="rounded bg-amber-100 px-1.5 py-0.5 text-[9px] font-bold text-amber-700">主键</span>}
                                                    {field.nullable === false && <span className="rounded bg-indigo-100 px-1.5 py-0.5 text-[9px] font-bold text-indigo-700">必填</span>}
                                                    {!field.isPk && field.nullable !== false && <span className="text-[10px] text-slate-300">—</span>}
                                                </div>
                                                <div className="text-right">
                                                    {field.domain ? (
                                                        <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-bold text-emerald-700 ring-1 ring-inset ring-emerald-200">
                                                            <Layers size={10} /> {field.domain}
                                                        </span>
                                                    ) : (
                                                        <span className="text-[11px] text-slate-300 group-hover:text-slate-400 transition-colors">无关联</span>
                                                    )}
                                                </div>
                                            </div>
                                        ))
                                    )}
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </main>

            {/* --- Right Side Panel (Detail / Domain) --- */}
            <aside className={`relative flex flex-col border-l border-slate-200 bg-white transition-all duration-300 ease-in-out ${isRightPanelOpen ? 'w-96' : 'w-0 opacity-0 overflow-hidden shadow-none ring-0 border-l-0'}`}>
                <div className="flex h-full flex-col">
                    <div className="flex items-center justify-between border-b border-slate-100 p-6">
                        <div className="flex items-center gap-3">
                            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-100 text-slate-600">
                                <Info size={20} />
                            </div>
                            <h2 className="text-lg font-bold text-slate-900">详情看板</h2>
                        </div>
                        <button
                            onClick={() => setIsRightPanelOpen(false)}
                            className="text-slate-400 hover:text-slate-600 transition-colors"
                        >
                            <ChevronRight size={20} />
                        </button>
                    </div>

                    <div className="flex-1 overflow-y-auto custom-scrollbar">
                        {selectedField ? (
                            <div className="space-y-8 p-6">
                                {/* Field Basic Info */}
                                <section>
                                    <label className="text-[11px] font-bold uppercase tracking-widest text-slate-400">字段定义</label>
                                    <div className="mt-3 rounded-2xl border border-slate-100 bg-slate-50/50 p-4">
                                        <div className="mb-1 font-mono text-base font-bold text-slate-900 underline decoration-indigo-200 underline-offset-4">{selectedField.name}</div>
                                        <div className="text-sm font-medium text-slate-600">{selectedField.cnName}</div>
                                        <div className="mt-4 grid grid-cols-2 gap-4">
                                            <div className="space-y-1">
                                                <p className="text-[10px] font-bold text-slate-400 uppercase">数据类型</p>
                                                <p className="font-mono text-xs font-medium text-indigo-600 bg-indigo-50 px-2 py-1 rounded inline-block">{selectedField.type || 'UNKNOWN'}</p>
                                            </div>
                                            <div className="space-y-1">
                                                <p className="text-[10px] font-bold text-slate-400 uppercase">是否空值</p>
                                                <p className="text-xs font-semibold text-slate-700">{selectedField.nullable !== false ? '✅ 可空' : '❌ 不可空'}</p>
                                            </div>
                                        </div>
                                    </div>
                                    {selectedField.remark && (
                                        <div className="mt-4 px-1">
                                            <p className="text-[10px] font-bold text-slate-400 uppercase mb-2">备注说明</p>
                                            <p className="text-xs text-slate-600 leading-relaxed italic">{selectedField.remark}</p>
                                        </div>
                                    )}
                                </section>

                                {/* Domain Values if exist */}
                                <section>
                                    <div className="flex items-center justify-between mb-4">
                                        <label className="text-[11px] font-bold uppercase tracking-widest text-slate-400">值域对照 (Domain)</label>
                                        {selectedField.domain && (
                                            <span className="rounded-full bg-emerald-100 px-2.5 py-0.5 text-[10px] font-bold text-emerald-700">{selectedField.domain}</span>
                                        )}
                                    </div>

                                    {!selectedField.domain ? (
                                        <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50/50 px-4 py-8 text-center">
                                            <div className="mx-auto mb-3 flex h-10 w-10 items-center justify-center rounded-full bg-white text-slate-300 shadow-sm"><Layers size={20} /></div>
                                            <p className="text-xs font-medium text-slate-400">未配置值域代码路径</p>
                                        </div>
                                    ) : (
                                        <div className="space-y-3">
                                            {loadingDomain ? (
                                                [1, 2, 3].map(i => <div key={i} className="h-12 animate-pulse rounded-xl bg-slate-50" />)
                                            ) : domainValues.length === 0 ? (
                                                <p className="text-center text-xs text-slate-400 py-4 italic">暂无对应对照表数据</p>
                                            ) : (
                                                <>
                                                    {domainValues.map(entry => (
                                                        <div key={entry.id} className="group rounded-xl border border-slate-100 bg-white p-3 shadow-sm hover:border-emerald-200 hover:shadow-emerald-500/5 transition-all">
                                                            <div className="flex items-center justify-between">
                                                                <span className="font-mono text-xs font-bold text-slate-800 bg-slate-50 px-2 py-0.5 rounded group-hover:bg-emerald-50 group-hover:text-emerald-700 transition-colors">{entry.code}</span>
                                                                <span className="text-xs font-semibold text-slate-700">{entry.name}</span>
                                                            </div>
                                                            {entry.description && (
                                                                <p className="mt-1.5 text-[10px] text-slate-400 leading-tight">{entry.description}</p>
                                                            )}
                                                        </div>
                                                    ))}
                                                    <div className="mt-4 border-t border-slate-100 pt-4">
                                                        <Pagination
                                                            current={domainPage}
                                                            total={domainTotal}
                                                            pageSize={domainSize}
                                                            simple={true}
                                                            onChange={(page) => setDomainPage(page)}
                                                        />
                                                    </div>
                                                </>
                                            )}
                                        </div>
                                    )}
                                </section>
                            </div>
                        ) : (
                            <div className="flex h-full flex-col items-center justify-center p-8 text-center opacity-60">
                                <Info size={48} className="text-slate-200 mb-4" />
                                <p className="text-sm font-medium text-slate-400">点击左侧字段查看元数据详情与值域定义</p>
                            </div>
                        )}
                    </div>
                </div>
            </aside>

            {/* Custom Styles for Scrollbar and additional effects */}
            <style dangerouslySetInnerHTML={{
                __html: `
                .model-page-container {
                    background: #f8fafc;
                    min-height: 100vh;
                    font-family: system-ui, -apple-system, sans-serif;
                }
                
                .custom-scrollbar::-webkit-scrollbar {
                    width: 6px;
                }
                .custom-scrollbar::-webkit-scrollbar-track {
                    background: transparent;
                }
                .custom-scrollbar::-webkit-scrollbar-thumb {
                    background: #E2E8F0;
                    border-radius: 10px;
                }
                .custom-scrollbar::-webkit-scrollbar-thumb:hover {
                    background: #CBD5E1;
                }
                
                @keyframes float {
                    0% { transform: translateY(0px); }
                    50% { transform: translateY(-10px); }
                    100% { transform: translateY(0px); }
                }
            ` }} />
        </div>
    );
};

export default MetadataModel;
