import React, { useState, useEffect } from 'react';
import { Search, Plus, Filter, Database, MoreHorizontal, ChevronRight, LayoutList, List, RefreshCw, Calendar, ArrowUpRight, ArrowDownRight, User, X, Tag, BarChart3, TrendingUp, ChevronDown, Download, Check, Edit, Trash2 } from 'lucide-react';
import Pagination from '../common/Pagination';
import AddMaintenanceModal from './AddMaintenanceModal';
import MaintenanceDetailPanel, { MaintenanceRecordItem } from './MaintenanceDetailPanel';
import Auth from '../Auth';

// 模拟统计数据（后续对接API）
const MOCK_STATS = {
    totalThisMonth: 45,
    addCount: 12,
    updateCount: 28,
    deleteCount: 5,
    activeTablesCount: 8,
    trend: '+12%'
};

interface MaintenanceFilters {
    globalSearch: string;
    tableName: string;
    fieldName: string;
    modTypes: string[];
    operator: string;
    reqId: string;
    dateRange: [string, string] | null;
}

const defaultFilters: MaintenanceFilters = {
    globalSearch: '',
    tableName: '',
    fieldName: '',
    modTypes: [],
    operator: '',
    reqId: '',
    dateRange: null
};

// 变更类型选项
const MOD_TYPE_OPTIONS = ['新增资产', '修改调整', '删除资产'];

const MaintenanceRecord: React.FC = () => {
    // 状态
    const [stats, setStats] = useState(MOCK_STATS);
    const [viewMode, setViewMode] = useState<'TABLE' | 'TIMELINE'>('TABLE');
    const [showAdvancedFilter, setShowAdvancedFilter] = useState(false);
    const [filters, setFilters] = useState<MaintenanceFilters>(defaultFilters);
    const [records, setRecords] = useState<MaintenanceRecordItem[]>([]);
    const [page, setPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [total, setTotal] = useState(60); // Mock total
    const [loading, setLoading] = useState(false);

    // 交互状态
    const [selectedRecord, setSelectedRecord] = useState<MaintenanceRecordItem | null>(null);
    const [showAddModal, setShowAddModal] = useState(false);
    const [editingRecord, setEditingRecord] = useState<MaintenanceRecordItem | null>(null);

    // Fetch Stats
    const fetchStats = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/metadata/maintenance-record/stats', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (data) setStats(data);
        } catch (error) {
            console.error('Failed to fetch stats:', error);
        }
    };

    // Fetch Records
    const fetchRecords = async (currentPage = page) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const params = new URLSearchParams();

            // 全局搜索
            if (filters.globalSearch) params.append('keyword', filters.globalSearch);

            // 高级筛选
            if (filters.tableName) params.append('tableName', filters.tableName);
            if (filters.fieldName) params.append('fieldName', filters.fieldName);
            if (filters.modTypes.length > 0) params.append('modTypes', filters.modTypes.join(','));
            if (filters.reqId) params.append('reqId', filters.reqId);
            if (filters.dateRange) {
                if (filters.dateRange[0]) params.append('startDate', filters.dateRange[0]);
                if (filters.dateRange[1]) params.append('endDate', filters.dateRange[1]);
            }

            params.append('page', currentPage.toString());
            params.append('size', pageSize.toString());

            const res = await fetch(`/api/metadata/maintenance-record?${params.toString()}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();

            // 适配字段
            const adaptedRecords = (data.records || []).map((r: any) => {
                let modType = r.modType || '未知类型';
                if (modType === 'CREATE') modType = '新增资产';
                if (modType === 'UPDATE') modType = '修改调整';
                if (modType === 'DELETE') modType = '删除资产';

                return {
                    id: r.id?.toString() || Math.random().toString(),
                    tableName: r.tableName || '未知表',
                    tableCnName: r.tableCnName || '',
                    fieldName: r.fieldName || '',
                    fieldCnName: r.fieldCnName || '',
                    modType: modType,
                    description: r.description || '',
                    operator: r.operator || '系统',
                    time: r.time || new Date().toISOString(),
                    reqId: r.reqId,
                    plannedDate: r.plannedDate,
                    script: r.script,
                    systemCode: r.systemCode,
                    assetType: r.assetType
                };
            }).sort((a: any, b: any) => new Date(b.time).getTime() - new Date(a.time).getTime());

            setRecords(adaptedRecords);
            setTotal(data.total || 0);
            setPage(currentPage);
        } catch (error) {
            console.error('Failed to fetch records:', error);
            setRecords([]);
        } finally {
            setLoading(false);
        }
    };

    // Initial load
    useEffect(() => {
        fetchStats();
    }, []);

    // Debounce Search
    useEffect(() => {
        const timer = setTimeout(() => fetchRecords(1), 500);
        return () => clearTimeout(timer);
    }, [filters]);

    // Handlers
    const handleAddSuccess = () => {
        setShowAddModal(false);
        setEditingRecord(null);
        fetchRecords(1);
        fetchStats();
    };

    const handleEdit = (record: MaintenanceRecordItem, e: React.MouseEvent) => {
        e.stopPropagation(); // Prevent row click
        setEditingRecord(record);
        setShowAddModal(true);
    };

    const handleDelete = async (id: string, e: React.MouseEvent) => {
        e.stopPropagation(); // Prevent row click
        if (!window.confirm('确定要删除这条维护记录吗？此操作不可恢复。')) return;

        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/metadata/maintenance-record/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                fetchRecords(page);
                fetchStats();
            } else {
                alert('删除失败，请重试');
            }
        } catch (error) {
            console.error('Delete failed:', error);
            alert('删除失败，可能由于网络原因');
        }
    };

    const handleOpenAddModal = () => {
        setEditingRecord(null);
        setShowAddModal(true);
    };

    const handleExport = () => {
        // Implement export logic
        alert('正在导出本次筛选结果...');
    };

    const toggleModTypeFilter = (type: string) => {
        setFilters(prev => {
            const newTypes = prev.modTypes.includes(type)
                ? prev.modTypes.filter(t => t !== type)
                : [...prev.modTypes, type];
            return { ...prev, modTypes: newTypes };
        });
    };

    const clearFilters = () => {
        setFilters({ ...defaultFilters, globalSearch: filters.globalSearch });
    };

    // Helper to get color for mod type
    const getModTypeColor = (type: string) => {
        const t = type.toUpperCase();
        if (t.includes('新增') || t.includes('CREATE')) return 'bg-emerald-50 text-emerald-600 border-emerald-200';
        if (t.includes('删除') || t.includes('DELETE')) return 'bg-red-50 text-red-600 border-red-200';
        return 'bg-blue-50 text-blue-600 border-blue-200'; // Default for UPDATE / 修改
    };

    return (
        <div className="flex flex-col h-full bg-slate-50 relative overflow-hidden">
            {/* 1. 统计概览卡片区 */}
            <div className="grid grid-cols-4 gap-4 px-4 pt-4 mb-2 flex-none">
                <StatsCard
                    title="本月变更总数"
                    value={stats.totalThisMonth}
                    trend={stats.trend}
                    icon={<BarChart3 className="text-white opacity-20" size={48} />}
                    className="bg-gradient-to-br from-indigo-500 to-indigo-600 text-white"
                />
                <StatsCard
                    title="新增资产"
                    value={stats.addCount}
                    icon={<Plus className="text-emerald-500 opacity-20" size={48} />}
                    className="bg-white border-l-4 border-emerald-500"
                    valueColor="text-emerald-600"
                />
                <StatsCard
                    title="修改调整"
                    value={stats.updateCount}
                    icon={<RefreshCw className="text-blue-500 opacity-20" size={48} />}
                    className="bg-white border-l-4 border-blue-500"
                    valueColor="text-blue-600"
                />
                <StatsCard
                    title="删除资产"
                    value={stats.deleteCount}
                    icon={<TrendingUp className="text-rose-500 opacity-20" size={48} />} // Placeholder icon
                    className="bg-white border-l-4 border-rose-500"
                    valueColor="text-rose-600"
                />
            </div>

            {/* 2. 主操作栏 */}
            <div className="px-4 py-2 flex-none">
                <div className="bg-white p-3 rounded-xl border border-slate-200 shadow-sm space-y-3">
                    {/* Top Row: Search & Actions */}
                    <div className="flex justify-between items-center gap-4">
                        <div className="flex-1 max-w-2xl relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                            <input
                                type="text"
                                placeholder="全局搜索：表名、字段名、需求号、变更描述..."
                                className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 transition-all font-medium text-slate-700"
                                value={filters.globalSearch}
                                onChange={(e) => setFilters(prev => ({ ...prev, globalSearch: e.target.value }))}
                            />
                        </div>
                        <div className="flex items-center gap-2">
                            <button
                                onClick={() => setShowAdvancedFilter(!showAdvancedFilter)}
                                className={`px-3 py-2.5 rounded-lg border font-medium text-sm flex items-center gap-2 transition-colors ${showAdvancedFilter ? 'bg-indigo-50 border-indigo-200 text-indigo-600' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
                                    }`}
                            >
                                <Filter size={16} />
                                高级筛选
                                <ChevronDown size={14} className={`transition-transform ${showAdvancedFilter ? 'rotate-180' : ''}`} />
                            </button>
                            <div className="h-6 w-px bg-slate-200 mx-1"></div>
                            <button onClick={() => fetchRecords()} className="p-2.5 text-slate-500 hover:bg-slate-100 rounded-lg transition-colors" title="刷新">
                                <RefreshCw size={18} />
                            </button>
                            <Auth code="metadata:maintenance:export">
                                <button onClick={handleExport} className="p-2.5 text-slate-500 hover:bg-slate-100 rounded-lg transition-colors" title="导出">
                                    <Download size={18} />
                                </button>
                            </Auth>
                            <Auth code="metadata:maintenance:add">
                                <button
                                    onClick={handleOpenAddModal}
                                    className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium text-sm flex items-center gap-2 shadow-sm transition-colors"
                                >
                                    <Plus size={16} />
                                    新增记录
                                </button>
                            </Auth>
                        </div>
                    </div>

                    {/* Advanced Filter Panel */}
                    {showAdvancedFilter && (
                        <div className="pt-3 border-t border-slate-100 animate-in slide-in-from-top-2 duration-200">
                            <div className="grid grid-cols-4 gap-4 mb-3">
                                <div>
                                    <label className="text-xs font-semibold text-slate-500 mb-1.5 block">表名/中文名</label>
                                    <input
                                        className="w-full px-3 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100"
                                        placeholder="输入表名..."
                                        value={filters.tableName}
                                        onChange={e => setFilters(prev => ({ ...prev, tableName: e.target.value }))}
                                    />
                                </div>
                                <div>
                                    <label className="text-xs font-semibold text-slate-500 mb-1.5 block">字段名/中文名</label>
                                    <input
                                        className="w-full px-3 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100"
                                        placeholder="输入字段名..."
                                        value={filters.fieldName}
                                        onChange={e => setFilters(prev => ({ ...prev, fieldName: e.target.value }))}
                                    />
                                </div>
                                <div>
                                    <label className="text-xs font-semibold text-slate-500 mb-1.5 block">变更时间范围</label>
                                    <div className="flex items-center gap-2">
                                        <div className="relative flex-1">
                                            <Calendar className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
                                            <input
                                                type="date"
                                                className="w-full pl-8 pr-2 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100"
                                                value={filters.dateRange?.[0] || ''}
                                                onChange={e => setFilters(prev => ({ ...prev, dateRange: [e.target.value, prev.dateRange?.[1] || ''] }))}
                                            />
                                        </div>
                                        <span className="text-slate-300">-</span>
                                        <div className="relative flex-1">
                                            <Calendar className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
                                            <input
                                                type="date"
                                                className="w-full pl-8 pr-2 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100"
                                                value={filters.dateRange?.[1] || ''}
                                                onChange={e => setFilters(prev => ({ ...prev, dateRange: [prev.dateRange?.[0] || '', e.target.value] }))}
                                            />
                                        </div>
                                    </div>
                                </div>
                                <div>
                                    <label className="text-xs font-semibold text-slate-500 mb-1.5 block">需求编号</label>
                                    <input
                                        className="w-full px-3 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100"
                                        placeholder="如: REQ-2024..."
                                        value={filters.reqId}
                                        onChange={e => setFilters(prev => ({ ...prev, reqId: e.target.value }))}
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="text-xs font-semibold text-slate-500 mb-2 block">变更类型</label>
                                <div className="flex flex-wrap gap-2">
                                    {MOD_TYPE_OPTIONS.map(type => (
                                        <button
                                            key={type}
                                            onClick={() => toggleModTypeFilter(type)}
                                            className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-all ${filters.modTypes.includes(type)
                                                ? 'bg-indigo-600 text-white border-indigo-600 shadow-md shadow-indigo-200'
                                                : 'bg-white text-slate-600 border-slate-200 hover:border-slate-300'
                                                }`}
                                        >
                                            {filters.modTypes.includes(type) && <Check size={12} className="inline mr-1" />}
                                            {type}
                                        </button>
                                    ))}
                                    <button
                                        onClick={clearFilters}
                                        className="px-3 py-1.5 rounded-full text-xs font-medium text-slate-400 hover:text-slate-600 transition-colors ml-auto"
                                    >
                                        重置筛选
                                    </button>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* 3. 内容展示区 (Table + Side Panel) */}
            <div className="flex-1 flex overflow-hidden px-4 pb-4 gap-4">

                {/* Main List */}
                <div className="flex-1 bg-white rounded-xl shadow-sm border border-slate-200 flex flex-col overflow-hidden">
                    {/* View Toolbar */}
                    <div className="px-4 py-3 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                        <div className="text-sm text-slate-500 font-medium">共 {total} 条记录</div>
                        <div className="flex bg-slate-200 p-0.5 rounded-lg">
                            <button
                                onClick={() => setViewMode('TABLE')}
                                className={`p-1.5 rounded-md transition-all ${viewMode === 'TABLE' ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                                title="表格视图"
                            >
                                <List size={16} />
                            </button>
                            <button
                                onClick={() => setViewMode('TIMELINE')}
                                className={`p-1.5 rounded-md transition-all ${viewMode === 'TIMELINE' ? 'bg-white text-indigo-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                                title="时间线视图"
                            >
                                <LayoutList size={16} />
                            </button>
                        </div>
                    </div>

                    {/* Content View Area */}
                    <div className="flex-1 overflow-auto relative">
                        {loading && (
                            <div className="absolute inset-0 bg-white/60 backdrop-blur-[1px] z-10 flex items-center justify-center">
                                <RefreshCw className="animate-spin text-indigo-600" size={32} />
                            </div>
                        )}

                        {viewMode === 'TABLE' ? (
                            <table className="w-full text-sm text-left">
                                <thead className="bg-slate-50 text-xs text-slate-500 uppercase font-semibold sticky top-0 z-10 border-b border-slate-200">
                                    <tr>
                                        <th className="px-6 py-3 w-4"></th>
                                        <th className="px-4 py-3">表名/中文名</th>
                                        <th className="px-4 py-3">字段/中文名</th>
                                        <th className="px-4 py-3">变更类型</th>
                                        <th className="px-4 py-3">所属系统</th>
                                        <th className="px-4 py-3">资产类型</th>
                                        <th className="px-4 py-3">变更描述</th>
                                        <th className="px-4 py-3">需求/计划</th>
                                        <th className="px-4 py-3">操作人</th>
                                        <th className="px-4 py-3 text-right">时间</th>
                                        <th className="px-4 py-3 text-right">操作</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {records.map((record) => (
                                        <tr
                                            key={record.id}
                                            onClick={() => setSelectedRecord(record)}
                                            className={`cursor-pointer transition-colors group ${selectedRecord?.id === record.id ? 'bg-indigo-50/60' : 'hover:bg-slate-50'
                                                }`}
                                        >
                                            <td className="px-6 py-4">
                                                <div className={`w-2 h-2 rounded-full ${(record.modType.toUpperCase().includes('新增') || record.modType.toUpperCase().includes('CREATE')) ? 'bg-emerald-500' :
                                                    (record.modType.toUpperCase().includes('删除') || record.modType.toUpperCase().includes('DELETE')) ? 'bg-red-500' :
                                                        'bg-blue-500'
                                                    }`}></div>
                                            </td>
                                            <td className="px-4 py-4 min-w-[200px]">
                                                <div className="font-medium text-slate-900 font-mono">{record.tableName}</div>
                                                <div className="text-xs text-slate-500">{record.tableCnName}</div>
                                            </td>
                                            <td className="px-4 py-4 min-w-[150px]">
                                                <div className="font-mono text-slate-700">{record.fieldName || '-'}</div>
                                                <div className="text-xs text-slate-500">{record.fieldCnName}</div>
                                            </td>
                                            <td className="px-4 py-4 whitespace-nowrap">
                                                <span className={`px-2 py-1 rounded-md text-xs font-semibold border ${getModTypeColor(record.modType)}`}>
                                                    {record.modType}
                                                </span>
                                            </td>
                                            <td className="px-4 py-4 whitespace-nowrap text-slate-600 text-xs font-medium">
                                                {record.systemCode || '-'}
                                            </td>
                                            <td className="px-4 py-4 whitespace-nowrap">
                                                <span className="px-2 py-1 bg-slate-100 text-slate-600 rounded text-xs font-medium border border-slate-200">
                                                    {record.assetType === 'REG_ASSET' ? '监管资产' : (record.assetType === 'CODE_VAL' ? '值域代码' : record.assetType) || '-'}
                                                </span>
                                            </td>
                                            <td className="px-4 py-4 text-slate-600 max-w-[300px] truncate" title={record.description}>
                                                {record.description}
                                            </td>
                                            <td className="px-4 py-4 whitespace-nowrap">
                                                {record.reqId && (
                                                    <div className="flex items-center gap-1 text-xs text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded border border-amber-100 w-fit mb-1">
                                                        <span className="font-mono">{record.reqId}</span>
                                                    </div>
                                                )}
                                                {record.plannedDate && (
                                                    <div className="text-xs text-slate-400 font-mono">{record.plannedDate}</div>
                                                )}
                                            </td>
                                            <td className="px-4 py-4">
                                                <div className="flex items-center gap-2">
                                                    <div className="w-6 h-6 rounded-full bg-slate-200 flex items-center justify-center text-xs font-bold text-slate-600">
                                                        {record.operator?.[0]?.toUpperCase()}
                                                    </div>
                                                    <span className="text-slate-700 text-sm">{record.operator}</span>
                                                </div>
                                            </td>
                                            <td className="px-4 py-4 text-right whitespace-nowrap text-slate-400 font-mono text-xs">
                                                {record.time.split('T')[0]}<br />
                                                {record.time.split('T')[1]?.split('.')[0]}
                                            </td>
                                            <td className="px-4 py-4 text-right whitespace-nowrap">
                                                <div className="flex items-center justify-end gap-2">
                                                    <Auth code="metadata:maintenance:edit">
                                                        <button
                                                            onClick={(e) => handleEdit(record, e)}
                                                            className="p-1.5 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                                                            title="编辑"
                                                        >
                                                            <Edit size={14} />
                                                        </button>
                                                    </Auth>
                                                    <Auth code="metadata:maintenance:delete">
                                                        <button
                                                            onClick={(e) => handleDelete(record.id, e)}
                                                            className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                                            title="删除"
                                                        >
                                                            <Trash2 size={14} />
                                                        </button>
                                                    </Auth>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                    {records.length === 0 && !loading && (
                                        <tr>
                                            <td colSpan={8} className="py-20 text-center text-slate-400">
                                                <div className="flex flex-col items-center gap-2">
                                                    <div className="bg-slate-50 p-4 rounded-full">
                                                        <Search size={32} className="text-slate-300" />
                                                    </div>
                                                    <p>未找到相关记录</p>
                                                    <button onClick={clearFilters} className="text-indigo-600 hover:underline text-sm font-medium">清除筛选</button>
                                                </div>
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        ) : (
                            <div className="p-8 max-w-4xl mx-auto h-full">
                                <div className="relative border-l-2 border-slate-200 ml-4 space-y-8 pb-10">
                                    {records.map((record) => (
                                        <div key={record.id} className="relative pl-8 group">
                                            {/* Dot */}
                                            <div className={`absolute -left-[9px] top-1.5 w-4 h-4 rounded-full border-4 border-white shadow-sm transition-all duration-300 group-hover:scale-125 group-hover:shadow-md ${(record.modType.toUpperCase().includes('新增') || record.modType.toUpperCase().includes('CREATE')) ? 'bg-emerald-500' :
                                                (record.modType.toUpperCase().includes('删除') || record.modType.toUpperCase().includes('DELETE')) ? 'bg-red-500' :
                                                    'bg-blue-500'
                                                }`}></div>

                                            {/* Date Header (only if date changed? simplified for now) */}
                                            <div className="text-xs font-bold text-slate-400 mb-2 flex items-center gap-2 tracking-wider">
                                                <Calendar size={12} className="text-indigo-400" />
                                                {new Date(record.time).toLocaleString('zh-CN', {
                                                    month: 'long',
                                                    day: 'numeric',
                                                    hour: '2-digit',
                                                    minute: '2-digit'
                                                })}
                                            </div>

                                            {/* Card */}
                                            <div
                                                onClick={() => setSelectedRecord(record)}
                                                className={`bg-white p-5 rounded-2xl border transition-all cursor-pointer hover:shadow-lg group/card ${selectedRecord?.id === record.id
                                                    ? 'border-indigo-400 shadow-md ring-4 ring-indigo-50'
                                                    : 'border-slate-100 hover:border-slate-300 shadow-sm'
                                                    }`}
                                            >
                                                <div className="flex justify-between items-start mb-3">
                                                    <div className="flex items-center gap-3">
                                                        <span className={`px-2 py-1 rounded-lg text-[10px] font-bold uppercase border shadow-sm ${getModTypeColor(record.modType)}`}>
                                                            {record.modType}
                                                        </span>
                                                        <div>
                                                            <h4 className="font-bold text-slate-800 text-base group-hover/card:text-indigo-600 transition-colors uppercase font-mono">{record.tableName}</h4>
                                                            <div className="text-xs text-slate-400 font-medium">{record.tableCnName}</div>
                                                        </div>
                                                    </div>
                                                    <div className="flex items-center gap-2 bg-slate-50 px-2 py-1 rounded-full border border-slate-100">
                                                        <div className="w-5 h-5 rounded-full bg-indigo-100 flex items-center justify-center text-[10px] font-bold text-indigo-600">
                                                            {record.operator?.[0]?.toUpperCase()}
                                                        </div>
                                                        <span className="text-slate-600 text-[10px] font-bold">{record.operator}</span>
                                                    </div>
                                                </div>

                                                <p className="text-sm text-slate-600 mb-4 leading-relaxed font-medium">{record.description}</p>

                                                <div className="flex flex-wrap gap-3 items-end">
                                                    {record.fieldName && (
                                                        <div className="flex-1 min-w-[200px] text-xs bg-slate-50 p-2.5 rounded-xl border border-slate-100 font-mono text-slate-500">
                                                            <div className="flex items-center gap-2 opacity-70 mb-1">
                                                                <Database size={10} />
                                                                <span className="font-bold tracking-widest uppercase">Target Field</span>
                                                            </div>
                                                            <div className="text-slate-700 font-bold">
                                                                {record.fieldName} {record.fieldCnName && <span className="text-slate-400 font-medium italic ml-1">({record.fieldCnName})</span>}
                                                            </div>
                                                        </div>
                                                    )}

                                                    {record.reqId && (
                                                        <div className="text-[10px] text-amber-700 font-bold bg-amber-50 px-2.5 py-1.5 rounded-lg border border-amber-200 flex items-center gap-1.5 shadow-sm">
                                                            <Tag size={10} />
                                                            REQ: {record.reqId}
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                    {records.length === 0 && !loading && (
                                        <div className="flex flex-col items-center justify-center py-20 text-slate-300">
                                            <LayoutList size={48} className="opacity-20 mb-4" />
                                            <p className="font-medium">暂无变更足迹</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Pagination */}
                    <div className="p-3 border-t border-slate-200">
                        <Pagination
                            current={page}
                            total={total}
                            pageSize={pageSize}
                            onChange={(p, s) => {
                                setPage(p);
                                if (s) setPageSize(s);
                                fetchRecords(p);
                            }}
                        />
                    </div>
                </div>

                {/* Side Detail Panel (Overlay or Split) */}
                {selectedRecord && (
                    <MaintenanceDetailPanel
                        record={selectedRecord}
                        onClose={() => setSelectedRecord(null)}
                    />
                )}
            </div>

            {/* Modals */}
            {showAddModal && <AddMaintenanceModal onClose={() => setShowAddModal(false)} onSuccess={handleAddSuccess} initialData={editingRecord} />}
        </div>
    );
};

// UI Components
const StatsCard: React.FC<{
    title: string;
    value: number | string;
    icon?: React.ReactNode;
    trend?: string;
    className?: string;
    valueColor?: string;
}> = ({ title, value, icon, trend, className, valueColor }) => (
    <div className={`rounded-xl p-5 relative overflow-hidden shadow-sm transition-all hover:shadow-md ${className}`}>
        <div className="relative z-10">
            <div className="text-sm font-medium opacity-80 mb-1">{title}</div>
            <div className={`text-3xl font-bold ${valueColor || ''} flex items-end gap-2`}>
                {value}
                {trend && <span className="text-sm font-medium text-emerald-300 mb-1.5">{trend}</span>}
            </div>
        </div>
        <div className="absolute right-0 bottom-0 p-4">
            {icon}
        </div>
    </div>
);

export default MaintenanceRecord;
