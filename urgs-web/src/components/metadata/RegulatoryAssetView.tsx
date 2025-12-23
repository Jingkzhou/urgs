import React, { useState, useEffect } from 'react';
import { Search, Plus, Edit, Trash2, X, Server, Database, Layers, ArrowLeft, Table2, Hash, Target, FileText, Calendar, Code, Zap, BookOpen, Info, Download, Upload, RefreshCw, FileCode } from 'lucide-react';
import { systemService, SsoConfig } from '../../services/systemService';
import Pagination from '../common/Pagination';
import Editor from '@monaco-editor/react';

interface RegTable {
    id?: number | string;
    name: string;
    cnName: string;
    code: string;
    systemCode: string;
    subjectCode?: string;
    subjectName?: string;
    theme?: string;
    frequency?: string;
    sourceType?: string;
    autoFetchStatus?: string;
    documentNo?: string;
    documentTitle?: string;
    effectiveDate?: string;
    businessCaliber?: string;
    devNotes?: string;
    owner?: string;
    status?: number;
}

interface CodeTable {
    id: string;
    tableCode: string;
    tableName: string;
    systemCode?: string;
    autoFetchStatus?: string;
}

interface RegElement {
    id?: number | string;
    tableId: number | string;
    type: 'FIELD' | 'INDICATOR';
    name: string;
    cnName?: string;
    code?: string;
    dataType?: string;
    length?: number;
    isPk?: number;
    nullable?: number;
    formula?: string;
    fetchSql?: string;
    codeSnippet?: string;  // 代码片段 (指标类型专用)
    codeTableCode?: string;
    valueRange?: string;
    validationRule?: string;
    documentNo?: string;
    documentTitle?: string;
    effectiveDate?: string;
    businessCaliber?: string;
    fillInstruction?: string;
    devNotes?: string;
    autoFetchStatus?: string;
    owner?: string;
    status?: number;
    sortOrder?: number;
    isInit?: number;
    isMergeFormula?: number;
    isFillBusiness?: number;
}

const RegulatoryAssetView: React.FC = () => {
    // Systems
    const [systems, setSystems] = useState<SsoConfig[]>([]);
    const [selectedSystem, setSelectedSystem] = useState<string | undefined>(undefined);

    // View State
    const [activeView, setActiveView] = useState<'TABLE_LIST' | 'ELEMENT_LIST'>('TABLE_LIST');
    const [currentTable, setCurrentTable] = useState<RegTable | null>(null);

    // Tables
    const [tables, setTables] = useState<RegTable[]>([]);
    const [tableKeyword, setTableKeyword] = useState('');
    const [tablePage, setTablePage] = useState(1);
    const [tableSize, setTableSize] = useState(10);
    const [tableTotal, setTableTotal] = useState(0);
    const [selectedTableIds, setSelectedTableIds] = useState<Set<number | string>>(new Set()); // 选中的报表ID

    // Elements (Fields/Indicators)
    const [elements, setElements] = useState<RegElement[]>([]);
    const [elementKeyword, setElementKeyword] = useState('');
    const [elementPage, setElementPage] = useState(1);
    const [elementSize, setElementSize] = useState(10);
    const [elementTotal, setElementTotal] = useState(0);

    // Modal State
    const [showTableModal, setShowTableModal] = useState(false);
    const [showElementModal, setShowElementModal] = useState(false);
    const [showDetailModal, setShowDetailModal] = useState(false);
    const [detailItem, setDetailItem] = useState<{ type: 'TABLE' | 'ELEMENT', data: RegTable | RegElement } | null>(null);

    const [editingTable, setEditingTable] = useState<RegTable | null>(null);
    const [editingElement, setEditingElement] = useState<RegElement | null>(null);
    const [viewingCodeTable, setViewingCodeTable] = useState<string | null>(null);
    const [allCodeTables, setAllCodeTables] = useState<CodeTable[]>([]);

    // Fetch Systems
    useEffect(() => {
        const fetchSystems = async () => {
            try {
                const data = await systemService.list();
                setSystems(data);
            } catch (e) {
                console.error('Failed to fetch systems', e);
            }
        };
        fetchSystems();
    }, []);

    // Fetch Tables
    const fetchTables = async (page = tablePage, size = tableSize) => {
        try {
            const token = localStorage.getItem('auth_token');
            let url = `/api/reg/table/list?page=${page}&size=${size}`;
            const params = new URLSearchParams();
            if (selectedSystem) params.append('systemCode', selectedSystem);
            if (tableKeyword) params.append('keyword', tableKeyword);
            if (params.toString()) url += '&' + params.toString();

            const res = await fetch(url, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();

            if (data && data.records) {
                setTables(data.records);
                setTableTotal(data.total);
            } else {
                setTables([]);
                setTableTotal(0);
            }
        } catch (e) {
            console.error('Failed to fetch tables', e);
            setTables([]);
            setTableTotal(0);
        }
    };

    useEffect(() => {
        if (activeView === 'TABLE_LIST') {
            fetchTables(tablePage, tableSize);
        } else {
            setActiveView('TABLE_LIST');
            setCurrentTable(null);
            fetchTables(1, tableSize); // Reset to page 1 on system change
            setTablePage(1);
        }
    }, [selectedSystem]);

    useEffect(() => {
        if (activeView === 'TABLE_LIST') {
            fetchTables(tablePage, tableSize);
        }
    }, [tablePage, tableSize]);

    // Fetch Elements for a table
    const fetchElements = async (tableId: number | string, page = elementPage, size = elementSize, explicitKeyword?: string) => {
        try {
            const token = localStorage.getItem('auth_token');

            // Use explicit keyword if provided, otherwise use state
            // Note: explicitKeyword can be empty string '', so check for undefined
            const searchKw = explicitKeyword !== undefined ? explicitKeyword : elementKeyword;

            let url = `/api/reg/element/list?tableId=${tableId}&page=${page}&size=${size}`;
            if (searchKw) {
                // Encode keyword to handle special characters safely
                url += `&keyword=${encodeURIComponent(searchKw)}`;
            }

            const res = await fetch(url, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();

            if (data && data.records) {
                // Client-side filtering is problematic with pagination. 
                // Displaying whatever backend returns for now.
                // If keyword filtering is critical, backend update is needed. 
                // Based on user request "表列表和字段列表分页显示", pagination is the key.
                setElements(data.records);
                setElementTotal(data.total);
            } else {
                setElements([]);
                setElementTotal(0);
            }

        } catch (e) {
            console.error('Failed to elements', e);
            setElements([]);
            setElementTotal(0);
        }
    };

    useEffect(() => {
        if (activeView === 'ELEMENT_LIST' && currentTable) {
            fetchElements(currentTable.id!, elementPage, elementSize);
            // Fetch Code Tables for display mapping
            const fetchCodeTables = async () => {
                try {
                    const token = localStorage.getItem('auth_token');
                    const res = await fetch('/api/metadata/code-tables', {
                        headers: { 'Authorization': `Bearer ${token}` }
                    });
                    if (res.ok) {
                        const data = await res.json();
                        setAllCodeTables(data);
                    }
                } catch (error) {
                    console.error('Failed to fetch code tables', error);
                }
            };
            fetchCodeTables();
        }
    }, [elementPage, elementSize, activeView, currentTable]);

    const getCodeTableName = (code: string) => {
        const found = allCodeTables.find(t => t.tableCode === code);
        return found ? found.tableName : code;
    };

    // Search Handlers
    const handleTableSearch = () => {
        setTablePage(1);
        fetchTables(1, tableSize);
    };

    // Handlers
    const handleTableDoubleClick = (table: RegTable) => {
        setCurrentTable(table);
        setActiveView('ELEMENT_LIST');
        setElementKeyword('');
        setElementPage(1); // Reset element page
        fetchElements(table.id!, 1, elementSize, ''); // Explicitly pass empty keyword
    };

    const handleBackToTables = () => {
        setActiveView('TABLE_LIST');
        setCurrentTable(null);
        setElements([]);
        // fetchTables will be triggered by re-render or we can leave it to state
    };

    const handleShowDetail = (type: 'TABLE' | 'ELEMENT', data: RegTable | RegElement) => {
        setDetailItem({ type, data });
        setShowDetailModal(true);
    };

    const handleAddTable = () => {
        setEditingTable(null);
        setShowTableModal(true);
    };

    const handleEditTable = (table: RegTable) => {
        setEditingTable(table);
        setShowTableModal(true);
    };

    const handleDeleteTable = async (id: number | string) => {
        if (window.confirm('确定要删除该表吗？关联的字段/指标也将被删除。')) {
            const token = localStorage.getItem('auth_token');
            await fetch(`/api/reg/table/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            fetchTables();
        }
    };

    const handleAddElement = (type: 'FIELD' | 'INDICATOR') => {
        if (!currentTable) return;
        setEditingElement({ tableId: currentTable.id!, type, name: '', sortOrder: 0 });
        setShowElementModal(true);
    };

    const handleEditElement = (element: RegElement) => {
        setEditingElement(element);
        setShowElementModal(true);
    };

    const handleDeleteElement = async (id: number | string) => {
        if (!confirm('确定要删除该字段/指标吗？')) return;
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/reg/element/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                if (currentTable) fetchElements(currentTable.id!);
            }
        } catch (e) {
            console.error('Failed to delete element', e);
        }
    };

    // Import / Export for Tables (报表级批量导入导出)
    const tableFileInputRef = React.useRef<HTMLInputElement>(null);

    const handleTableExport = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const params = new URLSearchParams();
            if (selectedSystem) {
                params.append('systemCode', selectedSystem);
            }
            // 如果有选中的报表，导出选中的；否则导出全部
            if (selectedTableIds.size > 0) {
                params.append('tableIds', Array.from(selectedTableIds).join(','));
            }
            const url = '/api/reg/table/export' + (params.toString() ? '?' + params.toString() : '');
            const res = await fetch(url, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok) throw new Error('Export failed');
            const blob = await res.blob();
            const blobUrl = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = blobUrl;
            const now = new Date();
            const timestamp = now.getFullYear() +
                String(now.getMonth() + 1).padStart(2, '0') +
                String(now.getDate()).padStart(2, '0') +
                String(now.getHours()).padStart(2, '0') +
                String(now.getMinutes()).padStart(2, '0');
            a.download = `报表数据导出_${timestamp}.xlsx`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(blobUrl);
            document.body.removeChild(a);
        } catch (e) {
            console.error('Export failed', e);
            alert('导出失败');
        }
    };

    const handleTableImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        const formData = new FormData();
        formData.append('file', file);

        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/reg/table/import', {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${token}` },
                body: formData
            });
            if (res.ok) {
                const result = await res.json();
                alert(`导入成功！\n报表：${result.tableCount} 个\n字段/指标：${result.elementCount} 个`);
                fetchTables();
            } else {
                alert('导入失败');
            }
        } catch (e) {
            console.error('Import failed', e);
            alert('导入失败');
        } finally {
            if (tableFileInputRef.current) tableFileInputRef.current.value = '';
        }
    };

    // Import / Export for Elements (单表字段导入导出)
    const fileInputRef = React.useRef<HTMLInputElement>(null);

    const handleExport = async () => {
        if (!currentTable) return;
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/reg/element/export?tableId=${currentTable.id}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok) throw new Error('Export failed');
            const blob = await res.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            const now = new Date();
            const timestamp = now.getFullYear() +
                String(now.getMonth() + 1).padStart(2, '0') +
                String(now.getDate()).padStart(2, '0') +
                String(now.getHours()).padStart(2, '0') +
                String(now.getMinutes()).padStart(2, '0') +
                String(now.getSeconds()).padStart(2, '0');
            a.download = `${currentTable.cnName || currentTable.name || 'RegulatoryElements'}_${timestamp}.xlsx`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
        } catch (e) {
            console.error('Export failed', e);
            alert('导出失败');
        }
    };

    const handleImportClick = () => {
        fileInputRef.current?.click();
    };

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file || !currentTable) return;

        const formData = new FormData();
        formData.append('file', file);
        formData.append('tableId', String(currentTable.id));

        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/reg/element/import', {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${token}` },
                body: formData
            });
            if (res.ok) {
                alert('导入成功');
                fetchElements(currentTable.id!);
            } else {
                alert('导入失败');
            }
        } catch (e) {
            console.error('Import failed', e);
            alert('导入失败');
        } finally {
            if (fileInputRef.current) fileInputRef.current.value = '';
        }
    };

    const handleSaveTable = async (formData: RegTable) => {
        const token = localStorage.getItem('auth_token');
        await fetch('/api/reg/table', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ ...formData, systemCode: formData.systemCode || selectedSystem })
        });
        setShowTableModal(false);
        fetchTables();
    };

    const handleSaveElement = async (formData: RegElement) => {
        const token = localStorage.getItem('auth_token');
        await fetch('/api/reg/element', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(formData)
        });
        setShowElementModal(false);
        if (currentTable) fetchElements(currentTable.id!);
    };

    // 同步代码片段
    const [isSyncing, setIsSyncing] = useState(false);
    const handleSyncCodeSnippets = async () => {
        if (!selectedSystem) {
            alert('请先选择一个系统');
            return;
        }

        if (!confirm(`确认要同步 ${selectedSystem} 系统的代码片段吗？\n将从 SQL 文件中匹配并更新指标的代码片段。`)) {
            return;
        }

        setIsSyncing(true);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/reg/table/sync-code-snippets?systemCode=${encodeURIComponent(selectedSystem)}`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            const result = await res.json();
            if (result.success) {
                alert(`同步成功！\n匹配指标数: ${result.matchedCount}\n更新指标数: ${result.updatedCount}`);
                // 刷新数据
                fetchTables();
                if (currentTable) {
                    fetchElements(currentTable.id!);
                }
            } else {
                alert('同步失败: ' + result.message);
            }
        } catch (e) {
            console.error('Sync failed', e);
            alert('同步失败');
        } finally {
            setIsSyncing(false);
        }
    };

    // 生成 Hive SQL 文件
    const [isGeneratingHiveSql, setIsGeneratingHiveSql] = useState(false);
    const handleGenerateHiveSql = async () => {
        if (!selectedSystem) {
            alert('请先选择一个系统');
            return;
        }

        if (!confirm(`确认要生成 ${selectedSystem} 系统的 Hive SQL 文件吗？\n将遍历所有有代码片段的指标，生成用于血缘分析的 SQL 文件。`)) {
            return;
        }

        setIsGeneratingHiveSql(true);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/reg/table/generateHiveSql?systemCode=${encodeURIComponent(selectedSystem)}`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            const result = await res.json();
            if (result.success) {
                alert(`生成成功！\n处理指标数: ${result.indicatorCount}\n生成文件数: ${result.filesGenerated}`);
            } else {
                alert('生成失败: ' + result.message);
            }
        } catch (e) {
            console.error('Generate Hive SQL failed', e);
            alert('生成失败');
        } finally {
            setIsGeneratingHiveSql(false);
        }
    };

    const getAutoFetchStatusBadge = (status?: string) => {
        const map: Record<string, { bg: string; text: string; label: string }> = {
            '已上线': { bg: 'bg-green-50', text: 'text-green-600', label: '已上线' },
            '开发中': { bg: 'bg-yellow-50', text: 'text-yellow-600', label: '开发中' },
            '未开发': { bg: 'bg-slate-100', text: 'text-slate-500', label: '未开发' },
        };
        const s = map[status || ''] || map['未开发'];
        return <span className={`px-2 py-0.5 rounded text-xs font-medium ${s.bg} ${s.text}`}>{s.label}</span>;
    };

    return (
        <div className="flex h-full bg-white rounded-lg overflow-hidden">
            {/* Left Sidebar: Systems - Always visible or hidden in drill-down? Usually distinct filters stay. */}
            <div className="w-56 border-r border-slate-200 bg-slate-50 flex flex-col flex-shrink-0">
                <div className="p-3 border-b border-slate-200">
                    <h2 className="font-bold text-slate-700 flex items-center gap-2 text-sm">
                        <Server size={16} /> 所属系统
                    </h2>
                </div>
                <div className="flex-1 overflow-y-auto p-2 space-y-1">
                    <button onClick={() => setSelectedSystem(undefined)} className={`w-full text-left px-3 py-2 rounded-lg text-sm font-medium transition-colors flex items-center gap-2 ${!selectedSystem ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-600 hover:bg-slate-200/50'}`}>
                        <Layers size={14} /> 全部系统
                    </button>
                    {systems.map(sys => (
                        <button key={sys.id} onClick={() => setSelectedSystem(sys.clientId)} className={`w-full text-left px-3 py-2 rounded-lg text-sm font-medium transition-colors flex items-center gap-2 ${selectedSystem === sys.clientId ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-600 hover:bg-slate-200/50'}`}>
                            <Database size={14} className="text-slate-400" />
                            <span className="truncate">{sys.name}</span>
                        </button>
                    ))}
                </div>
            </div>

            {/* Main Content Area */}
            <div className="flex-1 flex flex-col overflow-hidden bg-white relative">

                {/* View 1: Table List */}
                {activeView === 'TABLE_LIST' && (
                    <div className="flex flex-col h-full animate-in fade-in duration-300">
                        <div className="p-3 border-b border-slate-200 flex items-center gap-2">
                            <div className="relative flex-1 max-w-md">
                                <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
                                <input
                                    type="text"
                                    placeholder="搜索表..."
                                    value={tableKeyword}
                                    onChange={(e) => setTableKeyword(e.target.value)}
                                    onKeyDown={(e) => e.key === 'Enter' && handleTableSearch()}
                                    className="w-full pl-8 pr-3 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100"
                                />
                            </div>
                            <div className="flex gap-2">
                                <input
                                    type="file"
                                    ref={tableFileInputRef}
                                    className="hidden"
                                    accept=".xlsx, .xls"
                                    onChange={handleTableImport}
                                />
                                <button onClick={() => tableFileInputRef.current?.click()} className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-green-300 hover:text-green-600 flex items-center gap-1 px-3 transition-colors" title="导入报表">
                                    <Upload size={14} className="text-green-500" /> <span className="text-sm">导入</span>
                                </button>
                                <button onClick={handleTableExport} className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-blue-300 hover:text-blue-600 flex items-center gap-1 px-3 transition-colors" title="导出报表">
                                    <Download size={14} className="text-blue-500" /> <span className="text-sm">导出{selectedTableIds.size > 0 ? `(${selectedTableIds.size})` : '全部'}</span>
                                </button>
                                {(selectedSystem === 'PBOC' || selectedSystem === 'CBRC') && (
                                    <>
                                        <button
                                            onClick={handleSyncCodeSnippets}
                                            disabled={isSyncing}
                                            className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-purple-300 hover:text-purple-600 flex items-center gap-1 px-3 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                            title="同步代码片段（从SQL文件匹配指标编号）"
                                        >
                                            <RefreshCw size={14} className={`text-purple-500 ${isSyncing ? 'animate-spin' : ''}`} />
                                            <span className="text-sm">{isSyncing ? '同步中...' : '同步代码片段'}</span>
                                        </button>
                                        <button
                                            onClick={handleGenerateHiveSql}
                                            disabled={isGeneratingHiveSql}
                                            className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-orange-300 hover:text-orange-600 flex items-center gap-1 px-3 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                            title="生成 Hive SQL（用于血缘分析）"
                                        >
                                            <FileCode size={14} className={`text-orange-500 ${isGeneratingHiveSql ? 'animate-pulse' : ''}`} />
                                            <span className="text-sm">{isGeneratingHiveSql ? '生成中...' : '生成Hive SQL'}</span>
                                        </button>
                                    </>
                                )}
                            </div>
                            <button onClick={handleAddTable} className="p-1.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 flex items-center gap-1 px-3">
                                <Plus size={16} /> <span className="text-sm">新增表</span>
                            </button>
                        </div>

                        {/* Table Header */}
                        <div className="flex items-center px-4 py-2 bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-500">
                            <div className="w-8 flex items-center justify-center">
                                <input
                                    type="checkbox"
                                    checked={tables.length > 0 && selectedTableIds.size === tables.length}
                                    onChange={(e) => {
                                        if (e.target.checked) {
                                            setSelectedTableIds(new Set(tables.map(t => t.id!)));
                                        } else {
                                            setSelectedTableIds(new Set());
                                        }
                                    }}
                                    className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
                                />
                            </div>
                            <div className="w-10"></div>
                            <div className="w-48">中文名/表名</div>
                            <div className="w-32">编码</div>
                            <div className="w-24">报送频度</div>
                            <div className="w-24">取数来源</div>
                            <div className="w-24">状态</div>
                            <div className="flex-1">业务口径</div>
                            <div className="w-32 text-right">操作</div>
                        </div>

                        <div className="flex-1 overflow-y-auto">
                            {tables.map((table, index) => (
                                <div
                                    key={`${table.id}-${index}`}
                                    onDoubleClick={() => handleTableDoubleClick(table)}
                                    className="flex items-center px-4 py-3 cursor-pointer border-b border-slate-100 hover:bg-slate-50 transition-colors group"
                                >
                                    <div className="w-8 flex items-center justify-center" onClick={e => e.stopPropagation()}>
                                        <input
                                            type="checkbox"
                                            checked={selectedTableIds.has(table.id!)}
                                            onChange={(e) => {
                                                const newSet = new Set(selectedTableIds);
                                                if (e.target.checked) {
                                                    newSet.add(table.id!);
                                                } else {
                                                    newSet.delete(table.id!);
                                                }
                                                setSelectedTableIds(newSet);
                                            }}
                                            className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
                                        />
                                    </div>
                                    <div className="w-10 text-center">
                                        <Table2 size={16} className="text-blue-500 mx-auto" />
                                    </div>
                                    <div className="w-48 pr-2">
                                        <div className="font-medium text-sm text-slate-800 truncate" title={table.cnName}>{table.cnName || '-'}</div>
                                        <div className="text-xs text-slate-400 font-mono truncate" title={table.name}>{table.name}</div>
                                    </div>
                                    <div className="w-32 text-xs text-slate-500 font-mono truncate px-1" title={table.code}>{table.code || '-'}</div>
                                    <div className="w-24 text-xs text-slate-600 px-1">{table.frequency || '-'}</div>
                                    <div className="w-24 text-xs text-slate-600 px-1">{table.sourceType || '-'}</div>
                                    <div className="w-24 px-1">{getAutoFetchStatusBadge(table.autoFetchStatus)}</div>
                                    <div className="flex-1 text-xs text-slate-500 truncate px-1" title={table.businessCaliber}>{table.businessCaliber || '-'}</div>
                                    <div className="w-32 flex justify-end gap-1 opacity-100 md:opacity-0 md:group-hover:opacity-100 transition-opacity" onClick={e => e.stopPropagation()}>
                                        <button onClick={() => handleShowDetail('TABLE', table)} className="p-1.5 hover:bg-indigo-100 text-indigo-600 rounded" title="详情"><Info size={14} /></button>
                                        <button onClick={() => handleEditTable(table)} className="p-1.5 hover:bg-slate-200 text-slate-600 rounded" title="编辑"><Edit size={14} /></button>
                                        <button onClick={() => handleDeleteTable(table.id!)} className="p-1.5 hover:bg-red-50 text-red-500 rounded" title="删除"><Trash2 size={14} /></button>
                                    </div>
                                </div>
                            ))}
                            {tables.length === 0 && (
                                <div className="p-12 text-center text-slate-400 flex flex-col items-center">
                                    <Table2 size={40} className="text-slate-200 mb-2" />
                                    <p className="text-sm">暂无表数据</p>
                                </div>
                            )}
                        </div>

                        {/* Pagination */}
                        <div className="p-2 border-t border-slate-200 bg-slate-50">
                            <Pagination
                                current={tablePage}
                                total={tableTotal}
                                pageSize={tableSize}
                                showSizeChanger={true}
                                onChange={(p, s) => {
                                    setTablePage(p);
                                    setTableSize(s);
                                }}
                            />
                        </div>
                    </div>
                )}

                {/* View 2: Element List (Drill-Down) */}
                {activeView === 'ELEMENT_LIST' && currentTable && (
                    <div className="flex flex-col h-full animate-in slide-in-from-right-10 duration-300">
                        {/* Header with Back Button */}
                        <div className="p-3 border-b border-slate-200 flex items-center justify-between bg-white shadow-sm z-10">
                            <div className="flex items-center gap-3">
                                <button onClick={handleBackToTables} className="p-1.5 hover:bg-slate-100 text-slate-500 hover:text-slate-800 rounded-full transition-colors">
                                    <ArrowLeft size={20} />
                                </button>
                                <div>
                                    <h2 className="font-bold text-slate-800 flex items-center gap-2">
                                        <Table2 size={18} className="text-blue-500" />
                                        {currentTable.cnName || currentTable.name}
                                    </h2>
                                    <div className="text-xs text-slate-500 font-mono mt-0.5 flex gap-2">
                                        <span>{currentTable.name}</span>
                                        {currentTable.code && <span className="text-slate-300">|</span>}
                                        <span>{currentTable.code}</span>
                                    </div>
                                </div>
                            </div>
                            <div className="flex items-center gap-2">
                                <div className="relative w-48 mr-2">
                                    <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
                                    <input
                                        type="text"
                                        placeholder="搜索字段/指标..."
                                        value={elementKeyword}
                                        onChange={(e) => setElementKeyword(e.target.value)}
                                        onKeyDown={(e) => e.key === 'Enter' && fetchElements(currentTable.id!, 1, elementSize)}
                                        className="w-full pl-8 pr-3 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100"
                                    />
                                </div>
                                <button onClick={() => handleShowDetail('TABLE', currentTable)} className="p-1.5 hover:bg-indigo-50 text-indigo-600 rounded-lg border border-transparent hover:border-indigo-100" title="查看表详情">
                                    <Info size={16} />
                                </button>
                            </div>
                        </div>

                        {/* Toolbar */}
                        <div className="px-4 py-2 bg-slate-50 border-b border-slate-200 flex justify-between items-center">
                            <span className="text-xs font-semibold text-slate-500">字段与指标列表 ({elementTotal})</span>
                            <div className="flex gap-2">
                                <input
                                    type="file"
                                    ref={fileInputRef}
                                    className="hidden"
                                    accept=".xlsx, .xls"
                                    onChange={handleFileChange}
                                />
                                <button onClick={handleImportClick} className="text-xs bg-white border border-slate-200 px-2 py-1.5 rounded flex items-center gap-1 hover:border-green-300 hover:text-green-600 shadow-sm transition-colors" title="导入">
                                    <Upload size={12} className="text-green-500" /> 导入
                                </button>
                                <button onClick={handleExport} className="text-xs bg-white border border-slate-200 px-2 py-1.5 rounded flex items-center gap-1 hover:border-blue-300 hover:text-blue-600 shadow-sm transition-colors" title="导出">
                                    <Download size={12} className="text-blue-500" /> 导出
                                </button>
                                <div className="w-px h-6 bg-slate-200 mx-1"></div>
                                <button onClick={() => handleAddElement('FIELD')} className="text-xs bg-white border border-slate-200 px-2 py-1.5 rounded flex items-center gap-1 hover:border-indigo-300 hover:text-indigo-600 shadow-sm transition-colors">
                                    <Hash size={12} className="text-indigo-500" /> 添加字段
                                </button>
                                <button onClick={() => handleAddElement('INDICATOR')} className="text-xs bg-white border border-slate-200 px-2 py-1.5 rounded flex items-center gap-1 hover:border-purple-300 hover:text-purple-600 shadow-sm transition-colors">
                                    <Target size={12} className="text-purple-500" /> 添加指标
                                </button>
                            </div>
                        </div>

                        {/* Element Header */}
                        <div className="flex items-center px-4 py-2 bg-white border-b border-slate-100 text-xs font-medium text-slate-500">
                            <div className="w-10"></div> {/* Icon */}
                            <div className="w-12 text-center">序号</div>
                            <div className="w-48">名称</div>
                            <div className="w-32">编码</div>
                            <div className="w-48">值域/计算公式</div>
                            <div className="w-32">自动取数/状态</div>
                            <div className="flex-1">业务口径/说明</div>
                            <div className="w-32 text-right">操作</div>
                        </div>

                        <div className="flex-1 overflow-y-auto bg-slate-50/30">
                            {elements.map((el, index) => (
                                <div
                                    key={`${el.id}-${index}`}
                                    onDoubleClick={() => handleShowDetail('ELEMENT', el)}
                                    className="flex items-center px-4 py-2.5 bg-white border-b border-slate-100 hover:bg-slate-50 transition-colors group"
                                >
                                    <div className="w-10 flex justify-center">
                                        {el.type === 'FIELD' ? <Hash size={16} className="text-slate-400" /> : <Target size={16} className="text-purple-500" />}
                                    </div>
                                    <div className="w-12 text-center text-xs text-slate-500 font-mono">
                                        {el.sortOrder ?? '-'}
                                    </div>
                                    <div className="w-48 pr-2 truncate">
                                        <div className="text-sm text-slate-700 font-medium">{el.cnName || el.name}</div>
                                        {el.cnName && <div className="text-xs text-slate-400 font-mono">{el.name}</div>}
                                    </div>
                                    <div className="w-32 text-xs text-slate-500 font-mono truncate">{el.code || '-'}</div>
                                    <div className="w-48 text-xs text-slate-500 px-1">
                                        {el.type === 'FIELD' ? (
                                            // 字段：显示值域
                                            el.codeTableCode ? (
                                                <div
                                                    className="cursor-pointer hover:bg-amber-50 rounded p-1 -mx-1 group/code transition-colors"
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        setViewingCodeTable(el.codeTableCode!);
                                                    }}
                                                >
                                                    <div className="font-medium text-amber-600 group-hover/code:text-amber-700">{getCodeTableName(el.codeTableCode)}</div>
                                                    <div className="text-[10px] text-slate-400 font-mono group-hover/code:text-amber-600/70">{el.codeTableCode}</div>
                                                </div>
                                            ) : '-'
                                        ) : (
                                            // 指标：显示计算公式
                                            el.formula ? (
                                                <div className="text-purple-600 truncate" title={el.formula}>
                                                    <code className="text-xs bg-purple-50 px-1.5 py-0.5 rounded">{el.formula}</code>
                                                </div>
                                            ) : '-'
                                        )}
                                    </div>
                                    <div className="w-32 px-1 flex flex-col gap-0.5">
                                        <div>{getAutoFetchStatusBadge(el.autoFetchStatus)}</div>
                                        <div>
                                            {el.status === 1 ? (
                                                <span className="px-2 py-0.5 rounded text-xs font-medium bg-green-50 text-green-600">启用</span>
                                            ) : el.status === 0 ? (
                                                <span className="px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-500">停用</span>
                                            ) : null}
                                        </div>
                                    </div>
                                    <div className="flex-1 text-xs text-slate-500 truncate pr-4" title={el.devNotes || el.businessCaliber}>{el.devNotes || el.businessCaliber || '-'}</div>
                                    <div className="w-32 flex justify-end gap-1 opacity-100 md:opacity-0 md:group-hover:opacity-100 transition-opacity">
                                        <button onClick={() => handleShowDetail('ELEMENT', el)} className="p-1.5 hover:bg-indigo-100 text-indigo-600 rounded" title="详情"><Info size={14} /></button>
                                        <button onClick={() => handleEditElement(el)} className="p-1.5 hover:bg-slate-200 text-slate-600 rounded" title="编辑"><Edit size={14} /></button>
                                        <button onClick={() => handleDeleteElement(el.id!)} className="p-1.5 hover:bg-red-50 text-red-500 rounded" title="删除"><Trash2 size={14} /></button>
                                    </div>
                                </div>
                            ))}
                            {elements.length === 0 && (
                                <div className="p-12 text-center text-slate-400 flex flex-col items-center border-t border-slate-100">
                                    <div className="bg-slate-100 p-3 rounded-full mb-3">
                                        <Database size={24} className="text-slate-300" />
                                    </div>
                                    <p className="text-sm">该表暂无字段或指标</p>
                                    <div className="flex gap-3 mt-4">
                                        <button onClick={() => handleAddElement('FIELD')} className="text-xs text-indigo-600 hover:underline">立即添加字段</button>
                                        <button onClick={() => handleAddElement('INDICATOR')} className="text-xs text-purple-600 hover:underline">立即添加指标</button>
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* Pagination */}
                        <div className="p-2 border-t border-slate-200 bg-slate-50">
                            <Pagination
                                current={elementPage}
                                total={elementTotal}
                                pageSize={elementSize}
                                showSizeChanger={true}
                                onChange={(p, s) => {
                                    setElementPage(p);
                                    setElementSize(s);
                                }}
                            />
                        </div>
                    </div>
                )}
            </div>

            {/* Table Modal (Add/Edit) */}
            {showTableModal && (
                <TableModal
                    table={editingTable}
                    systems={systems}
                    defaultSystemCode={selectedSystem}
                    onSave={handleSaveTable}
                    onClose={() => setShowTableModal(false)}
                />
            )}

            {/* Element Modal (Add/Edit) */}
            {showElementModal && editingElement && (
                <ElementModal
                    element={editingElement}
                    systemCode={currentTable?.systemCode}
                    onSave={handleSaveElement}
                    onClose={() => setShowElementModal(false)}
                />
            )}

            {/* Detail Modal (View Only) */}
            {showDetailModal && detailItem && (
                <DetailModal
                    type={detailItem.type}
                    data={detailItem.data}
                    onClose={() => setShowDetailModal(false)}
                />
            )}

            {/* Code Values Modal */}
            {viewingCodeTable && (
                <CodeValuesModal
                    tableCode={viewingCodeTable}
                    onClose={() => setViewingCodeTable(null)}
                />
            )}
        </div>
    );
};

// Code Values Modal
const CodeValuesModal: React.FC<{ tableCode: string; onClose: () => void }> = ({ tableCode, onClose }) => {
    const [codes, setCodes] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [keyword, setKeyword] = useState('');
    const [tableInfo, setTableInfo] = useState<any>(null);

    useEffect(() => {
        fetchCodes();
        // Also fetch table info for title
        const fetchTableInfo = async () => {
            try {
                const token = localStorage.getItem('auth_token');
                const res = await fetch(`/api/metadata/code-tables`, { headers: { 'Authorization': `Bearer ${token}` } });
                if (res.ok) {
                    const tables = await res.json();
                    const found = tables.find((t: any) => t.tableCode === tableCode);
                    if (found) setTableInfo(found);
                }
            } catch (e) { console.error(e); }
        };
        fetchTableInfo();
    }, [tableCode]);

    const fetchCodes = async (kw = keyword) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            let url = `/api/metadata/code-directory?page=1&size=100&tableCode=${encodeURIComponent(tableCode)}`;
            if (kw) url += `&keyword=${encodeURIComponent(kw)}`;

            const res = await fetch(url, { headers: { 'Authorization': `Bearer ${token}` } });
            const data = await res.json();
            if (data && data.records) {
                setCodes(data.records);
            } else {
                setCodes([]);
            }
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-2xl w-[800px] max-h-[85vh] flex flex-col animate-in zoom-in-95 duration-200">
                <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-slate-50 rounded-t-xl">
                    <div>
                        <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                            <Table2 size={18} className="text-blue-500" />
                            {tableInfo ? tableInfo.tableName : tableCode}
                        </h3>
                        <div className="text-xs text-slate-500 font-mono mt-0.5">
                            {tableCode} {tableInfo?.systemCode && <span className="ml-2 bg-slate-200 px-1 rounded text-slate-600">{tableInfo.systemCode}</span>}
                        </div>
                    </div>
                    <button onClick={onClose} className="p-1 hover:bg-slate-200 rounded-full"><X size={20} /></button>
                </div>

                <div className="p-4 border-b border-slate-100 flex items-center gap-2">
                    <div className="relative flex-1">
                        <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            type="text"
                            placeholder="搜索码值..."
                            className="w-full pl-8 pr-3 py-1.5 text-sm border border-slate-200 rounded-lg outline-none focus:ring-2 focus:ring-blue-100"
                            value={keyword}
                            onChange={(e) => setKeyword(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && fetchCodes(e.currentTarget.value)}
                        />
                    </div>
                </div>

                <div className="flex-1 overflow-y-auto p-0">
                    <table className="w-full text-sm text-left">
                        <thead className="text-xs text-slate-500 bg-slate-50 uppercase sticky top-0">
                            <tr>
                                <th className="px-4 py-3">码值</th>
                                <th className="px-4 py-3">名称</th>
                                <th className="px-4 py-3">描述</th>
                                <th className="px-4 py-3">标准依据</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {loading ? (
                                <tr><td colSpan={4} className="text-center py-8 text-slate-400">加载中...</td></tr>
                            ) : codes.length > 0 ? (
                                codes.map((c, i) => (
                                    <tr key={i} className="hover:bg-slate-50">
                                        <td className="px-4 py-2 font-mono text-slate-600">{c.code}</td>
                                        <td className="px-4 py-2 font-medium text-slate-800">{c.name}</td>
                                        <td className="px-4 py-2 text-slate-500">{c.description || '-'}</td>
                                        <td className="px-4 py-2 text-slate-500 text-xs">{c.standard || '-'}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr><td colSpan={4} className="text-center py-8 text-slate-400">暂无数据</td></tr>
                            )}
                        </tbody>
                    </table>
                </div>

                <div className="p-3 border-t border-slate-200 bg-slate-50 rounded-b-xl flex justify-end">
                    <button onClick={onClose} className="px-4 py-2 bg-white border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 text-sm font-medium shadow-sm">关闭</button>
                </div>
            </div>
        </div>
    );
};

// --- Helper Components ---

const DetailItem: React.FC<{ icon?: React.ReactNode; label: string; value: React.ReactNode; fullWidth?: boolean }> = ({ icon, label, value, fullWidth }) => (
    <div className={`bg-slate-50 rounded-lg p-3 ${fullWidth ? 'col-span-2' : ''}`}>
        <div className="flex items-center gap-1.5 text-xs text-slate-500 mb-1">
            {icon}
            {label}
        </div>
        <div className="text-sm text-slate-800 break-words">{value || '-'}</div>
    </div>
);

// Detail Modal
const DetailModal: React.FC<{
    type: 'TABLE' | 'ELEMENT';
    data: RegTable | RegElement;
    onClose: () => void;
}> = ({ type, data, onClose }) => {
    const isTable = type === 'TABLE';
    const table = data as RegTable;
    const element = data as RegElement;

    // Helper to render badge
    const getAutoFetchStatusBadge = (status?: string) => {
        const map: Record<string, { bg: string; text: string; label: string }> = {
            '已上线': { bg: 'bg-green-50', text: 'text-green-600', label: '已上线' },
            '开发中': { bg: 'bg-yellow-50', text: 'text-yellow-600', label: '开发中' },
            '未开发': { bg: 'bg-slate-100', text: 'text-slate-500', label: '未开发' },
        };
        const s = map[status || ''] || map['未开发'];
        return <span className={`px-2 py-0.5 rounded text-xs font-medium ${s.bg} ${s.text}`}>{s.label}</span>;
    };

    return (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl shadow-2xl w-[600px] max-h-[90vh] flex flex-col animate-in zoom-in-95 duration-200">
                <div className="p-5 border-b border-slate-200 flex justify-between items-start bg-slate-50 rounded-t-xl">
                    <div className="flex gap-4">
                        <div className="p-3 bg-white rounded-lg shadow-sm">
                            {isTable ? <Table2 size={24} className="text-blue-500" /> :
                                element.type === 'FIELD' ? <Hash size={24} className="text-slate-500" /> :
                                    <Target size={24} className="text-purple-500" />}
                        </div>
                        <div>
                            <h3 className="text-lg font-bold text-slate-800">{data.cnName || data.name}</h3>
                            <div className="flex items-center gap-2 text-sm text-slate-500 font-mono mt-1">
                                {data.name}
                                {data.code && <span className="bg-slate-200 px-1.5 py-0.5 rounded text-xs text-slate-600">{data.code}</span>}
                            </div>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-1 hover:bg-slate-200 rounded-full text-slate-500"><X size={20} /></button>
                </div>

                <div className="p-6 overflow-y-auto">
                    <div className="grid grid-cols-2 gap-4">
                        {isTable ? (
                            <>
                                <DetailItem label="所属系统" value={table.systemCode} />
                                <DetailItem label="监管主题" value={table.theme} />
                                <DetailItem label="科目号" value={table.subjectCode} />
                                <DetailItem label="科目名称" value={table.subjectName} />
                                <DetailItem label="报送频度" value={table.frequency} />
                                <DetailItem label="取数来源" value={table.sourceType} />
                                <DetailItem label="自动取数状态" value={getAutoFetchStatusBadge(table.autoFetchStatus)} />
                                <DetailItem icon={<Calendar size={14} />} label="生效日期" value={table.effectiveDate} />
                                <DetailItem icon={<FileText size={14} />} label="发文号" value={table.documentNo} fullWidth />
                                <DetailItem label="发文标题" value={table.documentTitle} fullWidth />
                                <DetailItem icon={<BookOpen size={14} />} label="业务口径" value={table.businessCaliber} fullWidth />
                                <DetailItem label="开发备注" value={table.devNotes} fullWidth />
                            </>
                        ) : (
                            <>
                                <DetailItem label="序号" value={element.sortOrder} />
                                <DetailItem label="类型" value={element.type === 'FIELD' ? '字段' : '指标'} />
                                {element.type === 'FIELD' && (
                                    <>
                                        <DetailItem icon={<Code size={14} />} label="数据类型" value={element.dataType} />
                                        <DetailItem label="长度" value={element.length} />
                                        <DetailItem label="主键" value={element.isPk ? '是' : '否'} />
                                    </>
                                )}
                                {element.type === 'INDICATOR' && (
                                    <>
                                        <DetailItem icon={<Zap size={14} />} label="计算公式" value={element.formula} fullWidth />
                                        <DetailItem icon={<Code size={14} />} label="代码片段" value={
                                            element.codeSnippet ? (
                                                <div className="border border-slate-200 rounded-lg overflow-hidden">
                                                    <Editor
                                                        height="150px"
                                                        language="sql"
                                                        value={element.codeSnippet}
                                                        theme="vs-dark"
                                                        options={{
                                                            readOnly: true,
                                                            minimap: { enabled: false },
                                                            scrollBeyondLastLine: false,
                                                            lineNumbers: 'off',
                                                            folding: false,
                                                            fontSize: 12,
                                                            wordWrap: 'on'
                                                        }}
                                                    />
                                                </div>
                                            ) : '-'
                                        } fullWidth />
                                    </>
                                )}
                                <DetailItem label="值域代码表" value={element.codeTableCode} />
                                <DetailItem label="取值范围" value={element.valueRange} />
                                <DetailItem label="自动取数状态" value={getAutoFetchStatusBadge(element.autoFetchStatus)} />
                                <DetailItem icon={<Calendar size={14} />} label="生效日期" value={element.effectiveDate} />
                                <DetailItem icon={<FileText size={14} />} label="发文号" value={element.documentNo} fullWidth />
                                <DetailItem label="发文标题" value={element.documentTitle} fullWidth />
                                <DetailItem icon={<BookOpen size={14} />} label="业务口径" value={element.businessCaliber} fullWidth />
                                <DetailItem label="填报说明" value={element.fillInstruction} fullWidth />
                                <DetailItem label="开发备注" value={element.devNotes} fullWidth />
                            </>
                        )}
                    </div>
                </div>

                <div className="p-4 border-t border-slate-200 bg-slate-50 rounded-b-xl flex justify-end">
                    <button onClick={onClose} className="px-4 py-2 bg-white border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 font-medium shadow-sm">关闭</button>
                    {isTable ? (
                        <button className="px-4 py-2 ml-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 font-medium shadow-sm">
                            编辑表
                        </button>
                    ) : (
                        <button className="px-4 py-2 ml-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 font-medium shadow-sm">
                            编辑{element.type === 'FIELD' ? '字段' : '指标'}
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
};

// Table Modal
const TableModal: React.FC<{
    table: RegTable | null;
    systems: SsoConfig[];
    defaultSystemCode?: string;
    onSave: (data: RegTable) => void;
    onClose: () => void;
}> = ({ table, systems, defaultSystemCode, onSave, onClose }) => {
    const [form, setForm] = useState<RegTable>(table || {
        name: '', cnName: '', code: '', systemCode: defaultSystemCode || '',
        subjectCode: '', subjectName: '', theme: '', frequency: '',
        sourceType: '', autoFetchStatus: '', documentNo: '', documentTitle: '',
        businessCaliber: '', devNotes: '', owner: '', status: 1
    });

    return (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-2xl w-[700px] max-h-[90vh] flex flex-col animate-in slide-in-from-bottom-5 duration-200">
                <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-slate-50 rounded-t-xl">
                    <h3 className="text-lg font-bold text-slate-800">{table ? '编辑表' : '新增表'}</h3>
                    <button onClick={onClose} className="p-1 hover:bg-slate-200 rounded-full"><X size={20} /></button>
                </div>
                <div className="p-6 overflow-y-auto grid grid-cols-2 gap-4">
                    <FormField label="表名 *" value={form.name} onChange={v => setForm({ ...form, name: v })} />
                    <FormField label="中文名" value={form.cnName} onChange={v => setForm({ ...form, cnName: v })} />
                    <FormField label="编码" value={form.code} onChange={v => setForm({ ...form, code: v })} />
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">所属系统</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.systemCode || ''} onChange={e => setForm({ ...form, systemCode: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            {systems.map(s => <option key={s.id} value={s.clientId}>{s.name}</option>)}
                        </select>
                    </div>
                    <FormField label="科目号" value={form.subjectCode} onChange={v => setForm({ ...form, subjectCode: v })} />
                    <FormField label="科目名称" value={form.subjectName} onChange={v => setForm({ ...form, subjectName: v })} />
                    <FormField label="监管主题" value={form.theme} onChange={v => setForm({ ...form, theme: v })} />
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">报送频度</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.frequency || ''} onChange={e => setForm({ ...form, frequency: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            <option value="日">日</option>
                            <option value="周">周</option>
                            <option value="月">月</option>
                            <option value="季">季</option>
                            <option value="年">年</option>
                        </select>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">取数来源</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.sourceType || ''} onChange={e => setForm({ ...form, sourceType: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            <option value="手工">手工</option>
                            <option value="接口">接口</option>
                            <option value="SQL">SQL</option>
                        </select>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">自动取数状态</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.autoFetchStatus || ''} onChange={e => setForm({ ...form, autoFetchStatus: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            <option value="未开发">未开发</option>
                            <option value="开发中">开发中</option>
                            <option value="已上线">已上线</option>
                        </select>
                    </div>
                    <FormField label="发文号" value={form.documentNo} onChange={v => setForm({ ...form, documentNo: v })} />
                    <FormField label="发文标题" value={form.documentTitle} onChange={v => setForm({ ...form, documentTitle: v })} />
                    <FormField label="责任人" value={form.owner} onChange={v => setForm({ ...form, owner: v })} />
                    <div className="col-span-2">
                        <label className="block text-sm font-medium text-slate-700 mb-1">业务口径</label>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-20 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.businessCaliber || ''} onChange={e => setForm({ ...form, businessCaliber: e.target.value })} />
                    </div>
                    <div className="col-span-2">
                        <label className="block text-sm font-medium text-slate-700 mb-1">开发备注</label>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-20 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.devNotes || ''} onChange={e => setForm({ ...form, devNotes: e.target.value })} />
                    </div>
                </div>
                <div className="p-4 border-t border-slate-200 flex justify-end gap-2 bg-slate-50 rounded-b-xl">
                    <button onClick={onClose} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">取消</button>
                    <button onClick={() => onSave(form)} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 shadow-sm shadow-indigo-200">保存</button>
                </div>
            </div>
        </div>
    );
};

// Element Modal
const ElementModal: React.FC<{
    element: RegElement;
    systemCode?: string;
    onSave: (data: RegElement) => void;
    onClose: () => void;
}> = ({ element, systemCode, onSave, onClose }) => {
    const [form, setForm] = useState<RegElement>(element);
    const isField = form.type === 'FIELD';
    const [codeTables, setCodeTables] = useState<any[]>([]);

    useEffect(() => {
        const fetchCodeTables = async () => {
            try {
                const token = localStorage.getItem('auth_token');
                const res = await fetch('/api/metadata/code-tables', {
                    headers: { 'Authorization': `Bearer ${token}` }
                });
                if (res.ok) {
                    const data = await res.json();
                    setCodeTables(data);
                }
            } catch (error) {
                console.error('Failed to fetch code tables', error);
            }
        };
        fetchCodeTables();
    }, []);

    // Searchable Code Table State
    const [ctSearch, setCtSearch] = useState(form.codeTableCode || '');
    const [showCtDropdown, setShowCtDropdown] = useState(false);

    // Update search text if form changes externally (unlikely but good practice)
    useEffect(() => {
        setCtSearch(form.codeTableCode || '');
    }, [form.codeTableCode]);

    const filteredCodeTables = codeTables.filter(ct => {
        // Filter by System: strict match or global (no system code)
        if (systemCode && ct.systemCode && ct.systemCode !== systemCode) {
            return false;
        }

        const kw = ctSearch.toLowerCase();
        return (ct.tableCode?.toLowerCase().includes(kw) || ct.tableName?.toLowerCase().includes(kw));
    });

    return (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-2xl w-[700px] max-h-[90vh] flex flex-col animate-in slide-in-from-bottom-5 duration-200">
                <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-slate-50 rounded-t-xl">
                    <h3 className="text-lg font-bold text-slate-800">{element.id ? '编辑' : '新增'}{isField ? '字段' : '指标'}</h3>
                    <button onClick={onClose} className="p-1 hover:bg-slate-200 rounded-full"><X size={20} /></button>
                </div>
                <div className="p-6 overflow-y-auto grid grid-cols-2 gap-4" onClick={() => setShowCtDropdown(false)}>
                    <FormField label="名称 *" value={form.name} onChange={v => setForm({ ...form, name: v })} />
                    <FormField label="序号" value={String(form.sortOrder ?? 0)} onChange={v => setForm({ ...form, sortOrder: v ? parseInt(v) : 0 })} />
                    <FormField label="中文名" value={form.cnName} onChange={v => setForm({ ...form, cnName: v })} />
                    <FormField label="编码" value={form.code} onChange={v => setForm({ ...form, code: v })} />
                    {isField && (
                        <>
                            <FormField label="数据类型" value={form.dataType} onChange={v => setForm({ ...form, dataType: v })} />
                            <FormField label="长度" value={String(form.length || '')} onChange={v => setForm({ ...form, length: v ? parseInt(v) : undefined })} />
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">是否主键</label>
                                <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.isPk || 0} onChange={e => setForm({ ...form, isPk: parseInt(e.target.value) })}>
                                    <option value={0}>否</option>
                                    <option value={1}>是</option>
                                </select>
                            </div>
                        </>
                    )}
                    {!isField && (
                        <>
                            <div className="col-span-2">
                                <label className="block text-sm font-medium text-slate-700 mb-1">计算公式</label>
                                <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-16 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.formula || ''} onChange={e => setForm({ ...form, formula: e.target.value })} />
                            </div>
                            <div className="col-span-2">
                                <label className="block text-sm font-medium text-slate-700 mb-1">代码片段</label>
                                <div className="border border-slate-200 rounded-lg overflow-hidden">
                                    <Editor
                                        height="120px"
                                        language="sql"
                                        value={form.codeSnippet || ''}
                                        theme="vs-dark"
                                        onChange={(value) => setForm({ ...form, codeSnippet: value || '' })}
                                        options={{
                                            minimap: { enabled: false },
                                            scrollBeyondLastLine: false,
                                            lineNumbers: 'on',
                                            fontSize: 12,
                                            wordWrap: 'on',
                                            automaticLayout: true
                                        }}
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">是否初始化项</label>
                                <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.isInit ?? 0} onChange={e => setForm({ ...form, isInit: parseInt(e.target.value) })}>
                                    <option value={0}>否</option>
                                    <option value={1}>是</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">是否归并公式项</label>
                                <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.isMergeFormula ?? 0} onChange={e => setForm({ ...form, isMergeFormula: parseInt(e.target.value) })}>
                                    <option value={0}>否</option>
                                    <option value={1}>是</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">是否填报业务项</label>
                                <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.isFillBusiness ?? 0} onChange={e => setForm({ ...form, isFillBusiness: parseInt(e.target.value) })}>
                                    <option value={0}>否</option>
                                    <option value={1}>是</option>
                                </select>
                            </div>
                        </>
                    )}
                    <div className="relative" onClick={(e) => e.stopPropagation()}>
                        <label className="block text-sm font-medium text-slate-700 mb-1">值域代码表</label>
                        <div className="relative">
                            <input
                                type="text"
                                className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none"
                                placeholder="搜索名称或编码..."
                                value={ctSearch}
                                onChange={(e) => {
                                    setCtSearch(e.target.value);
                                    setShowCtDropdown(true);
                                    if (!e.target.value) setForm({ ...form, codeTableCode: '' });
                                }}
                                onFocus={() => setShowCtDropdown(true)}
                            />
                            {showCtDropdown && (
                                <div className="absolute top-full left-0 w-full mt-1 bg-white border border-slate-200 rounded-lg shadow-lg max-h-48 overflow-y-auto z-10">
                                    {filteredCodeTables.length > 0 ? (
                                        filteredCodeTables.map((ct: any) => (
                                            <div
                                                key={ct.id}
                                                className="px-3 py-2 text-sm hover:bg-slate-50 cursor-pointer border-b border-slate-50 last:border-0"
                                                onClick={() => {
                                                    setForm({ ...form, codeTableCode: ct.tableCode });
                                                    setCtSearch(ct.tableCode);
                                                    setShowCtDropdown(false);
                                                }}
                                            >
                                                <div className="font-medium text-slate-700">{ct.tableCode}</div>
                                                <div className="text-xs text-slate-500">{ct.tableName}</div>
                                            </div>
                                        ))
                                    ) : (
                                        <div className="p-2 text-xs text-slate-400 text-center">无匹配项</div>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>
                    <FormField label="取值范围" value={form.valueRange} onChange={v => setForm({ ...form, valueRange: v })} />
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">自动取数状态</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.autoFetchStatus || ''} onChange={e => setForm({ ...form, autoFetchStatus: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            <option value="未开发">未开发</option>
                            <option value="开发中">开发中</option>
                            <option value="已上线">已上线</option>
                        </select>
                    </div>
                    <FormField label="发文号" value={form.documentNo} onChange={v => setForm({ ...form, documentNo: v })} />
                    <FormField label="发文标题" value={form.documentTitle} onChange={v => setForm({ ...form, documentTitle: v })} />
                    <FormField label="责任人" value={form.owner} onChange={v => setForm({ ...form, owner: v })} />
                    <div className="col-span-2">
                        <label className="block text-sm font-medium text-slate-700 mb-1">业务口径</label>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-16 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.businessCaliber || ''} onChange={e => setForm({ ...form, businessCaliber: e.target.value })} />
                    </div>
                    <div className="col-span-2">
                        <label className="block text-sm font-medium text-slate-700 mb-1">填报说明</label>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-16 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.fillInstruction || ''} onChange={e => setForm({ ...form, fillInstruction: e.target.value })} />
                    </div>
                    <div className="col-span-2">
                        <label className="block text-sm font-medium text-slate-700 mb-1">开发备注</label>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-16 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.devNotes || ''} onChange={e => setForm({ ...form, devNotes: e.target.value })} />
                    </div>
                </div>
                <div className="p-4 border-t border-slate-200 flex justify-end gap-2 bg-slate-50 rounded-b-xl">
                    <button onClick={onClose} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">取消</button>
                    <button onClick={() => onSave(form)} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 shadow-sm shadow-indigo-200">保存</button>
                </div>
            </div>
        </div>
    );
};

// Form Field Helper
const FormField: React.FC<{ label: string; value?: string; onChange: (v: string) => void }> = ({ label, value, onChange }) => (
    <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">{label}</label>
        <input type="text" className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={value || ''} onChange={e => onChange(e.target.value)} />
    </div>
);

export default RegulatoryAssetView;
