import React, { useState, useEffect } from 'react';
import { Database, Server, Upload } from 'lucide-react';
import { systemService, SsoConfig } from '../../services/systemService';
import MaintenanceHistoryModal from './MaintenanceHistoryModal';
import { Stats, RegTable, CodeTable, RegElement } from './reg-asset/types';
import { TableModal } from './reg-asset/components/TableModal';
import { ElementModal } from './reg-asset/components/ElementModal';
import { AssetDetailSidebar } from './reg-asset/AssetDetailSidebar';
import RegulatoryAssetTableView from './reg-asset/views/RegulatoryAssetTableView';
import RegulatoryAssetElementView from './reg-asset/views/RegulatoryAssetElementView';

// ... (rest of imports)



import { CodeValuesModal } from './reg-asset/components/CodeValuesModal';
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
                if (data.length > 0) {
                    setSelectedSystem(data[0].clientId);
                }
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
        if (!selectedSystem) return;

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
        if (activeView === 'TABLE_LIST' && selectedSystem) {
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

            const result = await res.json();
            if (res.ok && result.success) {
                alert(`导入成功！\n报表：${result.tableCount} 个\n字段/指标：${result.elementCount} 个`);
                fetchTables();
                fetchStats();
            } else {
                alert(`导入失败：${result.message || '未知错误'}`);
            }
        } catch (e: any) {
            console.error('Import failed', e);
            alert('导入失败：' + (e.message || '网络或系统异常'));
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
            const result = await res.json();
            if (res.ok && result.success) {
                alert('导入成功');
                fetchElements(currentTable.id!);
            } else {
                alert('导入失败：' + (result.message || '未知错误'));
            }
        } catch (e: any) {
            console.error('Import failed', e);
            alert('导入失败：' + (e.message || '网络或系统异常'));
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
                {activeView === 'TABLE_LIST' && (
                    <RegulatoryAssetTableView
                        stats={stats}
                        loadingStats={loadingStats}
                        showAdvancedFilter={showAdvancedFilter}
                        setShowAdvancedFilter={setShowAdvancedFilter}
                        appliedFilterCount={appliedFilterCount}
                        tableKeyword={tableKeyword}
                        setTableKeyword={setTableKeyword}
                        handleTableSearch={handleTableSearch}
                        viewMode={viewMode}
                        setViewMode={setViewMode}
                        selectedTableIds={selectedTableIds}
                        setSelectedTableIds={setSelectedTableIds}
                        tableFileInputRef={tableFileInputRef}
                        handleTableImport={handleTableImport}
                        handleTableExport={handleTableExport}
                        handleBatchDeleteTables={handleBatchDeleteTables}
                        selectedSystem={selectedSystem}
                        isSyncing={isSyncing}
                        isGeneratingHiveSql={isGeneratingHiveSql}
                        handleSyncCodeSnippets={handleSyncCodeSnippets}
                        handleGenerateHiveSql={handleGenerateHiveSql}
                        handleAddTable={handleAddTable}
                        filterStatus={filterStatus}
                        setFilterStatus={setFilterStatus}
                        filterFrequency={filterFrequency}
                        setFilterFrequency={setFilterFrequency}
                        filterSourceType={filterSourceType}
                        setFilterSourceType={setFilterSourceType}
                        setTablePage={setTablePage}
                        fetchTables={fetchTables}
                        tables={tables}
                        loading={loading}
                        tablePage={tablePage}
                        tableSize={tableSize}
                        setTableSize={setTableSize}
                        tableTotal={tableTotal}
                        handleTableClick={handleTableClick}
                        onShowHistory={(table) => {
                            setHistoryTarget({
                                tableName: table.name,
                                tableId: table.id,
                                tableCnName: table.cnName
                            });
                            setShowHistoryModal(true);
                        }}
                        handleShowDetail={handleShowDetail}
                        handleEditTable={handleEditTable}
                        handleDeleteTable={handleDeleteTable}
                    />
                )}

                {activeView === 'ELEMENT_LIST' && currentTable && (
                    <RegulatoryAssetElementView
                        currentTable={currentTable}
                        elementKeyword={elementKeyword}
                        setElementKeyword={setElementKeyword}
                        fetchElements={fetchElements}
                        elementSize={elementSize}
                        showElementFilter={showElementFilter}
                        setShowElementFilter={setShowElementFilter}
                        appliedElementFilterCount={appliedElementFilterCount}
                        elementFilterStatus={elementFilterStatus}
                        setElementFilterStatus={setElementFilterStatus}
                        elementFilterAutoFetch={elementFilterAutoFetch}
                        setElementFilterAutoFetch={setElementFilterAutoFetch}
                        setElementPage={setElementPage}
                        handleBackToTables={handleBackToTables}
                        handleShowDetail={handleShowDetail}
                        selectedElementIds={selectedElementIds}
                        setSelectedElementIds={setSelectedElementIds}
                        handleBatchDeleteElements={handleBatchDeleteElements}
                        fileInputRef={fileInputRef}
                        handleFileChange={handleFileChange}
                        handleImportClick={handleImportClick}
                        handleExport={handleExport}
                        handleAddElement={handleAddElement}
                        elements={elements}
                        elementTotal={elementTotal}
                        elementPage={elementPage}
                        setElementSize={setElementSize}
                        getCodeTableName={getCodeTableName}
                        onViewCodeTable={(tableCode) => setViewingCodeTable(tableCode)}
                        handleEditElement={handleEditElement}
                        handleDeleteElement={handleDeleteElement}
                        onShowHistory={(el) => {
                            setHistoryTarget({
                                tableName: currentTable.name,
                                tableCnName: currentTable.cnName,
                                fieldName: el.name,
                                fieldCnName: el.cnName
                            });
                            setShowHistoryModal(true);
                        }}
                    />
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
