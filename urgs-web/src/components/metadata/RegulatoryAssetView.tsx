import React, { useState, useEffect } from 'react';
import { Search, Plus, Edit, Trash2, Server, Database, Layers, ArrowLeft, Table2, Hash, Target, Info, Download, Upload, RefreshCw, Clock, LayoutGrid, List, Filter, TrendingUp, CheckCircle, BarChart3, ChevronDown, ChevronUp } from 'lucide-react';
import { systemService, SsoConfig } from '../../services/systemService';
import Pagination from '../common/Pagination';
import Auth from '../Auth';
import MaintenanceHistoryModal from './MaintenanceHistoryModal';
import { Stats, RegTable, CodeTable, RegElement } from './reg-asset/types';
import { ReportCard } from './reg-asset/components/ReportCard';
import { TableModal } from './reg-asset/components/TableModal';
import { ElementModal } from './reg-asset/components/ElementModal';
import { AssetDetailSidebar } from './reg-asset/AssetDetailSidebar';

// ... (rest of imports)



import { CodeValuesModal } from './reg-asset/components/CodeValuesModal';
import { getAutoFetchStatusBadge, StatsCard, TableSkeleton, CardSkeleton } from './reg-asset/components/RegAssetHelper';
import DeleteWithReasonModal from './DeleteWithReasonModal';
import { ReqInfo } from './ReqInfoFormGroup';

const RegulatoryAssetView: React.FC = () => {
    // Systems
    const [systems, setSystems] = useState<SsoConfig[]>([]);
    const [selectedSystem, setSelectedSystem] = useState<string | undefined>(undefined);

    // View State
    const [activeView, setActiveView] = useState<'TABLE_LIST' | 'ELEMENT_LIST'>('TABLE_LIST');
    const [currentTable, setCurrentTable] = useState<RegTable | null>(null);

    // View Mode: card or table
    const [viewMode, setViewMode] = useState<'table' | 'card'>('card');

    // Stats
    const [stats, setStats] = useState<Stats | null>(null);
    const [loadingStats, setLoadingStats] = useState(false);

    // Advanced Filter
    const [showAdvancedFilter, setShowAdvancedFilter] = useState(false);
    const [filterStatus, setFilterStatus] = useState<string>('');
    const [filterFrequency, setFilterFrequency] = useState<string>('');
    const [filterSourceType, setFilterSourceType] = useState<string>('');
    const appliedFilterCount = [filterStatus, filterFrequency, filterSourceType].filter(Boolean).length;

    // Loading State
    const [loading, setLoading] = useState(false);

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
    const [selectedElementIds, setSelectedElementIds] = useState<Set<number | string>>(new Set()); // 选中的字段/指标ID

    // Element Advanced Filter
    const [showElementFilter, setShowElementFilter] = useState(false);
    const [elementFilterStatus, setElementFilterStatus] = useState<string>('');
    const [elementFilterAutoFetch, setElementFilterAutoFetch] = useState<string>('');
    const appliedElementFilterCount = [elementFilterStatus, elementFilterAutoFetch].filter(Boolean).length;

    // Modal State
    const [showTableModal, setShowTableModal] = useState(false);
    const [showElementModal, setShowElementModal] = useState(false);
    const [showDetailModal, setShowDetailModal] = useState(false);
    const [detailItem, setDetailItem] = useState<{ type: 'TABLE' | 'ELEMENT', data: RegTable | RegElement } | null>(null);

    const [editingTable, setEditingTable] = useState<RegTable | null>(null);
    const [editingElement, setEditingElement] = useState<RegElement | null>(null);
    const [viewingCodeTable, setViewingCodeTable] = useState<string | null>(null);
    const [allCodeTables, setAllCodeTables] = useState<CodeTable[]>([]);

    // Loading for Import
    const [isImporting, setIsImporting] = useState(false);

    // Delete Modal State
    const [deleteModal, setDeleteModal] = useState<{
        show: boolean;
        title: string;
        warning: string;
        type: 'TABLE' | 'TABLE_BATCH' | 'ELEMENT' | 'ELEMENT_BATCH';
        targetId?: number | string;
    }>({ show: false, title: '', warning: '', type: 'TABLE' });

    // History Modal State
    const [showHistoryModal, setShowHistoryModal] = useState(false);
    const [historyTarget, setHistoryTarget] = useState<{
        tableName: string;
        tableId?: number | string; // Added tableId
        tableCnName?: string;
        fieldName?: string;
        fieldCnName?: string;
    }>({ tableName: '' });

    // Fetch Stats
    const fetchStats = async () => {
        setLoadingStats(true);
        try {
            const token = localStorage.getItem('auth_token');
            let url = '/api/reg/table/stats';
            if (selectedSystem) {
                url += `?systemCode=${encodeURIComponent(selectedSystem)}`;
            }
            const res = await fetch(url, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setStats(data);
            }
        } catch (e) {
            console.error('Failed to fetch stats', e);
        } finally {
            setLoadingStats(false);
        }
    };

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
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            let url = `/api/reg/table/list?page=${page}&size=${size}`;
            const params = new URLSearchParams();
            if (selectedSystem) params.append('systemCode', selectedSystem);
            if (tableKeyword) params.append('keyword', tableKeyword);
            // Advanced filters
            if (filterStatus) params.append('autoFetchStatus', filterStatus);
            if (filterFrequency) params.append('frequency', filterFrequency);
            if (filterSourceType) params.append('sourceType', filterSourceType);
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
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (activeView === 'TABLE_LIST') {
            fetchTables(tablePage, tableSize);
            fetchStats();
        } else {
            setActiveView('TABLE_LIST');
            setCurrentTable(null);
            fetchTables(1, tableSize); // Reset to page 1 on system change
            fetchStats();
            setTablePage(1);
        }
        setSelectedTableIds(new Set()); // 【核心修复】切换系统时清空选中项
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
            if (elementFilterStatus) url += `&status=${elementFilterStatus}`;
            if (elementFilterAutoFetch) url += `&autoFetchStatus=${elementFilterAutoFetch}`;

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
    const handleTableClick = (table: RegTable) => {
        setCurrentTable(table);
        setActiveView('ELEMENT_LIST');
        setElementKeyword('');
        setElementFilterStatus('');
        setElementFilterAutoFetch('');
        setElementPage(1); // Reset element page
        setSelectedElementIds(new Set()); // Clear element selection
        fetchElements(table.id!, 1, elementSize, ''); // Explicitly pass empty keyword
    };

    const handleBackToTables = () => {
        setActiveView('TABLE_LIST');
        setCurrentTable(null);
        setElements([]);
        setSelectedElementIds(new Set()); // Clear element selection
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

    const handleDeleteTable = (id: number | string) => {
        setDeleteModal({
            show: true,
            title: '删除报表',
            warning: '确定要删除该报表吗？关联的字段/指标也将被删除，且此操作不可恢复。',
            type: 'TABLE',
            targetId: id
        });
    };

    const handleBatchDeleteTables = () => {
        if (selectedTableIds.size === 0) return;
        setDeleteModal({
            show: true,
            title: '批量删除报表',
            warning: `确定要批量删除选中的 ${selectedTableIds.size} 张报表吗？此操作不可恢复，关联的字段/指标也将被删除。`,
            type: 'TABLE_BATCH'
        });
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

    const handleDeleteElement = (id: number | string) => {
        setDeleteModal({
            show: true,
            title: '删除字段/指标',
            warning: '确定要删除该字段/指标吗？此操作不可恢复。',
            type: 'ELEMENT',
            targetId: id
        });
    };

    const handleBatchDeleteElements = () => {
        if (selectedElementIds.size === 0) return;
        setDeleteModal({
            show: true,
            title: '批量删除字段/指标',
            warning: `确定要批量删除选中的 ${selectedElementIds.size} 个字段/指标吗？此操作不可恢复。`,
            type: 'ELEMENT_BATCH'
        });
    };

    // Import / Export for Tables (报表级批量导入导出)
    const tableFileInputRef = React.useRef<HTMLInputElement>(null);

    const handleTableExport = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const params = new URLSearchParams();
            if (selectedSystem) params.append('systemCode', selectedSystem);
            if (tableKeyword) params.append('keyword', tableKeyword);
            if (filterStatus) params.append('autoFetchStatus', filterStatus);
            if (filterFrequency) params.append('frequency', filterFrequency);
            if (filterSourceType) params.append('sourceType', filterSourceType);

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

        setIsImporting(true);
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
                fetchStats();
            } else {
                alert('导入失败');
            }
        } catch (e) {
            console.error('Import failed', e);
            alert('导入失败');
        } finally {
            setIsImporting(false);
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




    // Delete Confirm Handler
    const handleDeleteConfirm = async (reqInfo: ReqInfo) => {
        const token = localStorage.getItem('auth_token');
        const headers = {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        };

        try {
            if (deleteModal.type === 'TABLE') {
                const res = await fetch('/api/reg/table/delete', {
                    method: 'POST',
                    headers,
                    body: JSON.stringify({
                        id: deleteModal.targetId,
                        ...reqInfo
                    })
                });
                if (res.ok) {
                    fetchTables();
                    if (selectedTableIds.has(deleteModal.targetId as string)) {
                        const newSet = new Set(selectedTableIds);
                        newSet.delete(deleteModal.targetId as string);
                        setSelectedTableIds(newSet);
                    }
                } else {
                    alert('删除失败');
                }
            } else if (deleteModal.type === 'TABLE_BATCH') {
                const res = await fetch('/api/reg/table/delete/batch', {
                    method: 'POST',
                    headers,
                    body: JSON.stringify({
                        ids: Array.from(selectedTableIds),
                        ...reqInfo
                    })
                });
                if (res.ok) {
                    setSelectedTableIds(new Set());
                    fetchTables();
                    alert('批量删除成功');
                } else {
                    alert('部分或全部删除失败');
                }
            } else if (deleteModal.type === 'ELEMENT') {
                const res = await fetch('/api/reg/element/delete', {
                    method: 'POST',
                    headers,
                    body: JSON.stringify({
                        id: deleteModal.targetId,
                        ...reqInfo
                    })
                });
                if (res.ok) {
                    if (currentTable) fetchElements(currentTable.id!);
                    if (selectedElementIds.has(deleteModal.targetId as string)) {
                        const newSet = new Set(selectedElementIds);
                        newSet.delete(deleteModal.targetId as string);
                        setSelectedElementIds(newSet);
                    }
                } else {
                    alert('删除失败');
                }
            } else if (deleteModal.type === 'ELEMENT_BATCH') {
                const res = await fetch('/api/reg/element/delete/batch', {
                    method: 'POST',
                    headers,
                    body: JSON.stringify({
                        ids: Array.from(selectedElementIds),
                        ...reqInfo
                    })
                });
                if (res.ok) {
                    setSelectedElementIds(new Set());
                    if (currentTable) fetchElements(currentTable.id!);
                    alert('批量删除成功');
                } else {
                    alert('批量删除失败');
                }
            }
        } catch (error) {
            console.error('Delete failed', error);
            alert('删除操作失败');
        }
    };

    return (
        <div className="flex h-full bg-white rounded-lg overflow-hidden relative">
            {/* Delete Modal */}
            {deleteModal.show && (
                <DeleteWithReasonModal
                    title={deleteModal.title}
                    warningMessage={deleteModal.warning}
                    onClose={() => setDeleteModal({ ...deleteModal, show: false })}
                    onConfirm={handleDeleteConfirm}
                />
            )}

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
                    <div className="flex flex-col h-full animate-in fade-in slide-in-from-top-2 duration-300">
                        {/* Stats Panel */}
                        <div className="p-4 grid grid-cols-1 md:grid-cols-4 gap-4 bg-slate-50/50 border-b border-slate-100">
                            <StatsCard
                                title="总报表数"
                                value={stats?.tableCount || 0}
                                icon={<Table2 size={20} />}
                                color="indigo"
                                loading={loadingStats}
                            />
                            <StatsCard
                                title="已上线报表"
                                value={stats?.onlineCount || 0}
                                icon={<CheckCircle size={20} />}
                                color="emerald"
                                loading={loadingStats}
                            />
                            <StatsCard
                                title="开发中报表"
                                value={stats?.developingCount || 0}
                                icon={<TrendingUp size={20} />}
                                color="amber"
                                loading={loadingStats}
                            />
                            <StatsCard
                                title="字段/指标总数"
                                value={stats?.elementCount || 0}
                                icon={<BarChart3 size={20} />}
                                color="blue"
                                loading={loadingStats}
                            />
                        </div>

                        {/* Toolbar */}
                        <div className="p-3 border-b border-slate-200 flex flex-col gap-3 bg-white/95 backdrop-blur sticky top-0 z-10 shadow-sm">
                            <div className="flex flex-wrap items-center gap-2">
                                <div className="relative flex-1 min-w-[260px] max-w-xl">
                                    <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
                                    <input
                                        type="text"
                                        placeholder="搜索表..."
                                        value={tableKeyword}
                                        onChange={(e) => setTableKeyword(e.target.value)}
                                        onKeyDown={(e) => e.key === 'Enter' && handleTableSearch()}
                                        className="w-full pl-8 pr-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 transition-all shadow-sm bg-white"
                                    />
                                </div>

                                <button
                                    onClick={() => setShowAdvancedFilter(!showAdvancedFilter)}
                                    className={`h-10 rounded-lg border transition-all flex items-center gap-1.5 px-3 text-sm ${showAdvancedFilter ? 'bg-indigo-50 border-indigo-200 text-indigo-700 font-medium' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50 shadow-sm'}`}
                                >
                                    <Filter size={14} className={showAdvancedFilter ? 'text-indigo-600' : 'text-slate-400'} />
                                    筛选
                                    {appliedFilterCount > 0 && (
                                        <span className="ml-0.5 px-1.5 py-0.5 rounded-full bg-indigo-100 text-indigo-700 text-[11px] font-semibold">
                                            {appliedFilterCount}
                                        </span>
                                    )}
                                    {showAdvancedFilter ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                                </button>

                                <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-lg border border-slate-200 shadow-inner">
                                    <button
                                        onClick={() => setViewMode('card')}
                                        className={`p-2 rounded-md transition-all ${viewMode === 'card' ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                                        title="卡片视图"
                                    >
                                        <LayoutGrid size={16} />
                                    </button>
                                    <button
                                        onClick={() => setViewMode('table')}
                                        className={`p-2 rounded-md transition-all ${viewMode === 'table' ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                                        title="表格视图"
                                    >
                                        <List size={16} />
                                    </button>
                                </div>

                                <div className="flex-1" />

                                <div className="flex gap-2 flex-wrap justify-end items-center">
                                    {selectedTableIds.size > 0 && (
                                        <span className="px-2 py-1 text-xs text-indigo-700 bg-indigo-50 border border-indigo-100 rounded-md">
                                            已选 {selectedTableIds.size} 张
                                        </span>
                                    )}
                                    <input
                                        type="file"
                                        ref={tableFileInputRef}
                                        className="hidden"
                                        accept=".xlsx, .xls"
                                        onChange={handleTableImport}
                                    />
                                    <Auth code="metadata:asset:import">
                                        <button onClick={() => tableFileInputRef.current?.click()} className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-emerald-300 hover:text-emerald-700 hover:bg-emerald-50/50 flex items-center gap-1 px-3 transition-all shadow-sm group" title="导入报表">
                                            <Upload size={14} className="text-emerald-500 group-hover:scale-110 transition-transform" /> <span className="text-sm">导入</span>
                                        </button>
                                    </Auth>
                                    <Auth code="metadata:asset:export">
                                        <button onClick={handleTableExport} className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-blue-300 hover:text-blue-700 hover:bg-blue-50/50 flex items-center gap-1 px-3 transition-all shadow-sm group" title="导出报表">
                                            <Download size={14} className="text-blue-500 group-hover:scale-110 transition-transform" /> <span className="text-sm">导出{selectedTableIds.size > 0 ? `(${selectedTableIds.size})` : '全部'}</span>
                                        </button>
                                    </Auth>
                                    {selectedTableIds.size > 0 && (
                                        <Auth code="metadata:asset:delete">
                                            <button onClick={handleBatchDeleteTables} className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-red-300 hover:text-red-700 hover:bg-red-50/50 flex items-center gap-1 px-3 transition-all shadow-sm group" title="批量删除">
                                                <Trash2 size={14} className="text-red-500 group-hover:scale-110 transition-transform" /> <span className="text-sm">删除({selectedTableIds.size})</span>
                                            </button>
                                        </Auth>
                                    )}
                                    {selectedSystem && (
                                        <>
                                            <Auth code="metadata:asset:sync">
                                                <button onClick={handleSyncCodeSnippets} disabled={isSyncing} className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-orange-300 hover:text-orange-700 hover:bg-orange-50/50 flex items-center gap-1 px-3 transition-all shadow-sm group" title="同步逻辑">
                                                    <RefreshCw size={14} className={`text-orange-500 group-hover:scale-110 transition-transform ${isSyncing ? 'animate-spin' : ''}`} /> <span className="text-sm">同步</span>
                                                </button>
                                            </Auth>
                                            <Auth code="metadata:asset:script">
                                                <button onClick={handleGenerateHiveSql} disabled={isGeneratingHiveSql} className="p-1.5 bg-white border border-slate-200 text-slate-600 rounded-lg hover:border-purple-300 hover:text-purple-700 hover:bg-purple-50/50 flex items-center gap-1 px-3 transition-all shadow-sm group" title="生成脚本">
                                                    <Database size={14} className="text-purple-500 group-hover:scale-110 transition-transform" /> <span className="text-sm">脚本</span>
                                                </button>
                                            </Auth>
                                            <Auth code="metadata:asset:add">
                                                <button onClick={handleAddTable} className="p-1.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 hover:shadow-lg hover:shadow-indigo-200 flex items-center gap-1 px-3 transition-all">
                                                    <Plus size={16} /> <span className="text-sm font-medium">新增报表</span>
                                                </button>
                                            </Auth>
                                        </>
                                    )}
                                </div>
                            </div>

                            {/* Advanced Filter Panel */}
                            {showAdvancedFilter && (
                                <div className="grid grid-cols-1 md:grid-cols-4 gap-4 p-4 border border-indigo-100 bg-indigo-50/20 rounded-xl animate-in slide-in-from-top-2 duration-200">
                                    <div>
                                        <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 ml-1">报送状态</label>
                                        <select
                                            value={filterStatus}
                                            onChange={(e) => {
                                                setFilterStatus(e.target.value);
                                                setTablePage(1);
                                            }}
                                            className="w-full border border-slate-200 rounded-lg p-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-indigo-100 transition-all outline-none"
                                        >
                                            <option value="">全部状态</option>
                                            <option value="已上线">已上线</option>
                                            <option value="开发中">开发中</option>
                                            <option value="未开发">未开发</option>
                                        </select>
                                    </div>
                                    <div>
                                        <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 ml-1">报送频度</label>
                                        <select
                                            value={filterFrequency}
                                            onChange={(e) => {
                                                setFilterFrequency(e.target.value);
                                                setTablePage(1);
                                            }}
                                            className="w-full border border-slate-200 rounded-lg p-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-indigo-100 transition-all outline-none"
                                        >
                                            <option value="">全部频度</option>
                                            <option value="日">日报</option>
                                            <option value="周">周报</option>
                                            <option value="月">月报</option>
                                            <option value="季">季报</option>
                                            <option value="年">年报</option>
                                        </select>
                                    </div>
                                    <div>
                                        <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 ml-1">取数来源</label>
                                        <select
                                            value={filterSourceType}
                                            onChange={(e) => {
                                                setFilterSourceType(e.target.value);
                                                setTablePage(1);
                                            }}
                                            className="w-full border border-slate-200 rounded-lg p-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-indigo-100 transition-all outline-none"
                                        >
                                            <option value="">全部来源</option>
                                            <option value="手工">手工填报</option>
                                            <option value="接口">系统接口</option>
                                            <option value="SQL">SQL取数</option>
                                        </select>
                                    </div>
                                    <div className="flex items-end gap-2">
                                        <button
                                            onClick={() => {
                                                setFilterStatus('');
                                                setFilterFrequency('');
                                                setFilterSourceType('');
                                                setTableKeyword('');
                                                setTablePage(1);
                                            }}
                                            className="h-9 px-4 text-sm bg-white border border-slate-200 text-slate-500 rounded-lg hover:bg-slate-50 transition-all flex items-center justify-center gap-1.5 flex-1 shadow-sm"
                                        >
                                            <RefreshCw size={14} /> 重置
                                        </button>
                                        <button
                                            onClick={() => fetchTables(1)}
                                            className="h-9 px-4 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-all flex items-center justify-center gap-1.5 flex-[1.5] shadow-md shadow-indigo-100"
                                        >
                                            应用筛选
                                        </button>
                                    </div>
                                </div>
                            )}
                        </div>

                        <div className="flex-1 overflow-y-auto overflow-x-auto min-h-0 bg-slate-50/30">
                            {loading ? (
                                viewMode === 'table' ? <TableSkeleton /> : <CardSkeleton />
                            ) : tables.length > 0 ? (
                                viewMode === 'table' ? (
                                    <div className="bg-white min-w-[960px]">
                                        {/* Table Header */}
                                        <div className="flex items-center px-4 py-3 bg-slate-50/80 border-b border-slate-200 text-xs font-bold text-slate-500 uppercase tracking-wider sticky top-0 z-[5]">
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
                                                    className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500 cursor-pointer"
                                                />
                                            </div>
                                            <div className="w-10"></div>
                                            <div className="w-16 text-center">序号</div>
                                            <div className="w-64">中文名/表代码</div>
                                            <div className="w-24">报送频度</div>
                                            <div className="w-24">取数来源</div>
                                            <div className="w-28">状态</div>
                                            <div className="w-20 text-center">字段数</div>
                                            <div className="w-20 text-center">指标数</div>
                                            <div className="flex-1">业务口径</div>
                                            <div className="w-40 text-right pr-4">操作</div>
                                        </div>
                                        {tables.map((table, index) => (
                                            <div
                                                key={`${table.id}-${index}`}
                                                onClick={() => handleTableClick(table)}
                                                className={`flex items-center px-4 py-3.5 cursor-pointer border-b border-slate-50 transition-all hover:bg-indigo-50/30 group ${selectedTableIds.has(table.id!) ? 'bg-indigo-50/50' : ''}`}
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
                                                        className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500 cursor-pointer"
                                                    />
                                                </div>
                                                <div className="w-10 text-center">
                                                    <div className="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-500 flex items-center justify-center group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-300">
                                                        <Table2 size={16} />
                                                    </div>
                                                </div>
                                                <div className="w-16 text-center text-xs text-slate-400 font-mono font-bold tracking-tighter">{table.sortOrder || '-'}</div>
                                                <div className="w-64 pr-4">
                                                    <div className="font-bold text-sm text-slate-800 transition-colors group-hover:text-indigo-600 truncate" title={table.cnName}>{table.cnName || '-'}</div>
                                                    <div className="text-[10px] text-slate-400 font-mono mt-0.5 flex items-center gap-1">
                                                        <span className="bg-slate-100 px-1 py-px rounded uppercase tracking-tighter">{table.name}</span>
                                                    </div>
                                                </div>
                                                <div className="w-24 text-xs font-semibold text-slate-600">{table.frequency || '-'}</div>
                                                <div className="w-24 text-xs font-medium text-slate-500">{table.sourceType || '-'}</div>
                                                <div className="w-28">{getAutoFetchStatusBadge(table.autoFetchStatus)}</div>
                                                <div className="w-20 text-center text-xs font-mono text-slate-500">
                                                    {table.fieldCount !== undefined ? table.fieldCount : '-'}
                                                </div>
                                                <div className="w-20 text-center text-xs font-mono text-indigo-600 font-medium">
                                                    {table.indicatorCount !== undefined ? table.indicatorCount : '-'}
                                                </div>
                                                <div className="flex-1 text-xs text-slate-400 line-clamp-1 pr-4" title={table.businessCaliber}>{table.businessCaliber || '-'}</div>
                                                <div className="w-40 flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity" onClick={e => e.stopPropagation()}>
                                                    <button
                                                        onClick={() => {
                                                            setHistoryTarget({
                                                                tableName: table.name,
                                                                tableId: table.id,
                                                                tableCnName: table.cnName
                                                            });
                                                            setShowHistoryModal(true);
                                                        }}
                                                        className="p-1.5 hover:bg-white text-orange-600 rounded-lg shadow-sm border border-transparent hover:border-orange-100 transition-all"
                                                        title="变更历史"
                                                    >
                                                        <Clock size={14} />
                                                    </button>
                                                    <button onClick={() => handleShowDetail('TABLE', table)} className="p-1.5 hover:bg-white text-indigo-600 rounded-lg shadow-sm border border-transparent hover:border-indigo-100 transition-all" title="详情"><Info size={14} /></button>
                                                    <button onClick={() => handleEditTable(table)} className="p-1.5 hover:bg-white text-slate-600 rounded-lg shadow-sm border border-transparent hover:border-slate-200 transition-all" title="编辑"><Edit size={14} /></button>
                                                    <button onClick={() => handleDeleteTable(table.id!)} className="p-1.5 hover:bg-white text-red-500 rounded-lg shadow-sm border border-transparent hover:border-red-100 transition-all" title="删除"><Trash2 size={14} /></button>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                ) : (
                                    <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4 lg:gap-6 p-4 lg:p-6 auto-rows-fr">
                                        {tables.map((table) => (
                                            <ReportCard
                                                key={table.id}
                                                table={table}
                                                onClick={() => handleTableClick(table)}
                                                isSelected={selectedTableIds.has(table.id!)}
                                                onToggleSelect={(e) => {
                                                    const newSet = new Set(selectedTableIds);
                                                    if (e.target.checked) {
                                                        newSet.add(table.id!);
                                                    } else {
                                                        newSet.delete(table.id!);
                                                    }
                                                    setSelectedTableIds(newSet);
                                                }}
                                                onShowDetail={() => handleShowDetail('TABLE', table)}
                                                onEdit={() => handleEditTable(table)}
                                                onDelete={() => handleDeleteTable(table.id!)}
                                                onShowHistory={() => {
                                                    setHistoryTarget({
                                                        tableName: table.name,
                                                        tableId: table.id,
                                                        tableCnName: table.cnName
                                                    });
                                                    setShowHistoryModal(true);
                                                }}
                                            />
                                        ))}
                                    </div>
                                )
                            ) : (
                                <div className="p-12 text-center text-slate-400 flex flex-col items-center justify-center h-full">
                                    <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mb-6 text-slate-300">
                                        <BarChart3 size={40} />
                                    </div>
                                    <h3 className="text-lg font-bold text-slate-600 mb-2">未找到匹配的报表</h3>
                                    <p className="text-sm text-slate-400 max-w-xs mx-auto leading-relaxed">
                                        尝试调整您的搜索关键词或筛选条件，或者点击右上角的“新增报表”手动创建一个。
                                    </p>
                                    <button
                                        onClick={() => {
                                            setFilterStatus('');
                                            setFilterFrequency('');
                                            setFilterSourceType('');
                                            setTableKeyword('');
                                            setTablePage(1);
                                        }}
                                        className="mt-6 px-4 py-2 bg-white border border-slate-200 text-slate-600 rounded-lg hover:bg-slate-50 transition-all shadow-sm"
                                    >
                                        清除所有筛选
                                    </button>
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
                                        <span className="text-slate-300">|</span>
                                        <span className="bg-slate-100 px-1 py-0.5 rounded">Seq: {currentTable.sortOrder}</span>
                                    </div>
                                </div>
                            </div>
                            <div className="flex items-center gap-2">
                                <div className="relative w-48">
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
                                <button
                                    onClick={() => setShowElementFilter(!showElementFilter)}
                                    className={`h-9 px-3 rounded-lg border transition-all flex items-center gap-1.5 text-xs ${showElementFilter ? 'bg-indigo-50 border-indigo-200 text-indigo-700 font-medium' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50 shadow-sm'}`}
                                >
                                    <Filter size={14} className={showElementFilter ? 'text-indigo-600' : 'text-slate-400'} />
                                    筛选
                                    {appliedElementFilterCount > 0 && (
                                        <span className="ml-0.5 px-1.5 py-0.5 rounded-full bg-indigo-100 text-indigo-700 text-[10px] font-semibold">
                                            {appliedElementFilterCount}
                                        </span>
                                    )}
                                </button>
                                <button onClick={() => handleShowDetail('TABLE', currentTable)} className="p-1.5 hover:bg-indigo-50 text-indigo-600 rounded-lg border border-transparent hover:border-indigo-100" title="查看表详情">
                                    <Info size={16} />
                                </button>
                            </div>
                        </div>

                        {/* Element Advanced Filter Panel */}
                        {showElementFilter && (
                            <div className="mx-4 mt-2 mb-2 p-4 border border-indigo-100 bg-indigo-50/20 rounded-xl animate-in slide-in-from-top-2 duration-200 grid grid-cols-1 md:grid-cols-3 gap-4">
                                <div>
                                    <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 ml-1">状态</label>
                                    <select
                                        value={elementFilterStatus}
                                        onChange={(e) => {
                                            setElementFilterStatus(e.target.value);
                                            setElementPage(1);
                                        }}
                                        className="w-full border border-slate-200 rounded-lg p-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-indigo-100 transition-all outline-none"
                                    >
                                        <option value="">全部状态</option>
                                        <option value="1">启用</option>
                                        <option value="0">停用</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 ml-1">自动取数状态</label>
                                    <select
                                        value={elementFilterAutoFetch}
                                        onChange={(e) => {
                                            setElementFilterAutoFetch(e.target.value);
                                            setElementPage(1);
                                        }}
                                        className="w-full border border-slate-200 rounded-lg p-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-indigo-100 transition-all outline-none"
                                    >
                                        <option value="">全部状态</option>
                                        <option value="已上线">已上线</option>
                                        <option value="开发中">开发中</option>
                                        <option value="未开发">未开发</option>
                                    </select>
                                </div>
                                <div className="flex items-end gap-2">
                                    <button
                                        onClick={() => {
                                            setElementFilterStatus('');
                                            setElementFilterAutoFetch('');
                                            setElementKeyword('');
                                            setElementPage(1);
                                        }}
                                        className="h-9 px-4 text-sm bg-white border border-slate-200 text-slate-500 rounded-lg hover:bg-slate-50 transition-all flex items-center justify-center gap-1.5 flex-1 shadow-sm"
                                    >
                                        <RefreshCw size={14} /> 重置
                                    </button>
                                    <button
                                        onClick={() => fetchElements(currentTable!.id!, 1, elementSize)}
                                        className="h-9 px-4 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-all flex items-center justify-center gap-1.5 flex-[1.5] shadow-md shadow-indigo-100"
                                    >
                                        应用筛选
                                    </button>
                                </div>
                            </div>
                        )}

                        {/* Toolbar */}
                        <div className="px-4 py-2 bg-slate-50 border-b border-slate-200 flex justify-between items-center">
                            <span className="text-xs font-semibold text-slate-500">字段与指标列表 ({elementTotal})</span>
                            <div className="flex gap-2">
                                {selectedElementIds.size > 0 && (
                                    <div className="flex items-center gap-2 mr-2">
                                        <span className="text-[10px] text-indigo-600 bg-indigo-50 px-2 py-1 rounded border border-indigo-100 font-bold">
                                            已选 {selectedElementIds.size}
                                        </span>
                                        <button
                                            onClick={handleBatchDeleteElements}
                                            className="text-xs bg-white border border-red-200 text-red-600 px-2 py-1.5 rounded flex items-center gap-1 hover:bg-red-50 shadow-sm transition-colors"
                                        >
                                            <Trash2 size={12} /> 批量删除
                                        </button>
                                    </div>
                                )}
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
                            <div className="w-8 flex items-center justify-center">
                                <input
                                    type="checkbox"
                                    checked={elements.length > 0 && selectedElementIds.size === elements.length}
                                    onChange={(e) => {
                                        if (e.target.checked) {
                                            setSelectedElementIds(new Set(elements.map(el => el.id!)));
                                        } else {
                                            setSelectedElementIds(new Set());
                                        }
                                    }}
                                    className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500 cursor-pointer"
                                />
                            </div>
                            <div className="w-10"></div> {/* Icon */}
                            <div className="w-12 text-center">序号</div>
                            <div className="w-48">名称</div>
                            {/* <div className="w-32">编码</div> Removed */}
                            <div className="w-24">数据类型</div>
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
                                    className={`flex items-center px-4 py-2.5 bg-white border-b border-slate-100 hover:bg-slate-50 transition-colors group ${selectedElementIds.has(el.id!) ? 'bg-indigo-50/30' : ''}`}
                                >
                                    <div className="w-8 flex items-center justify-center">
                                        <input
                                            type="checkbox"
                                            checked={selectedElementIds.has(el.id!)}
                                            onChange={(e) => {
                                                const newSet = new Set(selectedElementIds);
                                                if (e.target.checked) {
                                                    newSet.add(el.id!);
                                                } else {
                                                    newSet.delete(el.id!);
                                                }
                                                setSelectedElementIds(newSet);
                                            }}
                                            className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500 cursor-pointer"
                                        />
                                    </div>
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
                                    <div className="w-24 text-xs text-slate-600 px-1 font-mono flex flex-col">
                                        <span>
                                            {el.type === 'FIELD' ? ((el.dataType || '-') + (el.length ? `(${el.length})` : '')) : '-'}
                                        </span>
                                        {el.type === 'FIELD' && (
                                            <div className="flex gap-1 mt-0.5">
                                                {el.isPk === 1 && <span className="px-1 py-px rounded bg-yellow-100 text-yellow-700 text-[10px]">PK</span>}
                                                {el.nullable === 0 && <span className="px-1 py-px rounded bg-red-50 text-red-500 text-[10px]">NN</span>}
                                            </div>
                                        )}
                                    </div>
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
                                    <div className="w-40 flex justify-end gap-1 opacity-100 md:opacity-0 md:group-hover:opacity-100 transition-opacity">
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                setHistoryTarget({
                                                    tableName: currentTable.name,
                                                    tableCnName: currentTable.cnName,
                                                    fieldName: el.name,
                                                    fieldCnName: el.cnName
                                                });
                                                setShowHistoryModal(true);
                                            }}
                                            className="p-1.5 hover:bg-orange-100 text-orange-600 rounded"
                                            title="变更历史"
                                        >
                                            <Clock size={14} />
                                        </button>
                                        <button onClick={() => handleShowDetail('ELEMENT', el)} className="p-1.5 hover:bg-indigo-100 text-indigo-600 rounded" title="详情"><Info size={14} /></button>
                                        <Auth code="metadata:asset:element:edit">
                                            <button onClick={() => handleEditElement(el)} className="p-1.5 hover:bg-slate-200 text-slate-600 rounded" title="编辑"><Edit size={14} /></button>
                                        </Auth>
                                        <Auth code="metadata:asset:element:edit">
                                            <button onClick={() => handleDeleteElement(el.id!)} className="p-1.5 hover:bg-red-50 text-red-500 rounded" title="删除"><Trash2 size={14} /></button>
                                        </Auth>
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
                                        <Auth code="metadata:asset:element:edit">
                                            <button onClick={() => handleAddElement('FIELD')} className="text-xs text-indigo-600 hover:underline">立即添加字段</button>
                                        </Auth>
                                        <Auth code="metadata:asset:element:edit">
                                            <button onClick={() => handleAddElement('INDICATOR')} className="text-xs text-purple-600 hover:underline">立即添加指标</button>
                                        </Auth>
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

            {/* Detail Sidebar (Replaces DetailModal) */}
            <AssetDetailSidebar
                isOpen={showDetailModal}
                onClose={() => setShowDetailModal(false)}
                type={detailItem?.type || 'TABLE'}
                data={detailItem?.data || null}
            />

            {/* Global Loading Overlay for Import */}
            {isImporting && (
                <div className="fixed inset-0 z-[9999] bg-slate-900/50 backdrop-blur-sm flex items-center justify-center animate-in fade-in duration-300">
                    <div className="bg-white p-6 rounded-2xl shadow-2xl flex flex-col items-center gap-4 animate-in zoom-in-95 duration-300">
                        <div className="relative">
                            <div className="w-12 h-12 border-4 border-indigo-100 border-t-indigo-600 rounded-full animate-spin"></div>
                            <Upload className="absolute inset-0 m-auto text-indigo-600 animate-pulse" size={20} />
                        </div>
                        <div className="text-center">
                            <h3 className="font-bold text-slate-800">正在导入数据...</h3>
                            <p className="text-sm text-slate-500 mt-1">请勿关闭页面，系统正在处理您的 Excel 文件</p>
                        </div>
                    </div>
                </div>
            )}

            {/* Code Values Modal */}
            {viewingCodeTable && (
                <CodeValuesModal
                    tableCode={viewingCodeTable}
                    onClose={() => setViewingCodeTable(null)}
                />
            )}

            {/* History Modal */}
            <MaintenanceHistoryModal
                isOpen={showHistoryModal}
                onClose={() => setShowHistoryModal(false)}
                tableName={historyTarget.tableName}
                tableId={historyTarget.tableId} // Pass tableId
                tableCnName={historyTarget.tableCnName}
                fieldName={historyTarget.fieldName}
                fieldCnName={historyTarget.fieldCnName}
            />
        </div>
    );
};

export default RegulatoryAssetView;
