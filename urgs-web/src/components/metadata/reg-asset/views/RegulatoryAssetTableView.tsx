import React from 'react';
import {
    BarChart3,
    CheckCircle,
    ChevronDown,
    ChevronUp,
    Clock,
    Database,
    Download,
    Edit,
    Filter,
    Info,
    LayoutGrid,
    List,
    Plus,
    RefreshCw,
    Search,
    Table2,
    Trash2,
    TrendingUp,
    Upload,
} from 'lucide-react';
import Auth from '../../../Auth';
import Pagination from '../../../common/Pagination';
import { ReportCard } from '../components/ReportCard';
import { CardSkeleton, TableSkeleton, getAutoFetchStatusBadge } from '../components/RegAssetHelper';
import { RegElement, RegTable, Stats } from '../types';

type TableViewMode = 'table' | 'card';

interface RegulatoryAssetTableViewProps {
    stats: Stats | null;
    loadingStats: boolean;
    showAdvancedFilter: boolean;
    setShowAdvancedFilter: React.Dispatch<React.SetStateAction<boolean>>;
    appliedFilterCount: number;
    tableKeyword: string;
    setTableKeyword: React.Dispatch<React.SetStateAction<string>>;
    handleTableSearch: () => void;
    viewMode: TableViewMode;
    setViewMode: React.Dispatch<React.SetStateAction<TableViewMode>>;
    selectedTableIds: Set<number | string>;
    setSelectedTableIds: React.Dispatch<React.SetStateAction<Set<number | string>>>;
    tableFileInputRef: React.RefObject<HTMLInputElement>;
    handleTableImport: (e: React.ChangeEvent<HTMLInputElement>) => void;
    handleTableExport: () => void;
    handleBatchDeleteTables: () => void;
    selectedSystem?: string;
    isSyncing: boolean;
    isGeneratingHiveSql: boolean;
    handleSyncCodeSnippets: () => void;
    handleGenerateHiveSql: () => void;
    handleAddTable: () => void;
    filterStatus: string;
    setFilterStatus: React.Dispatch<React.SetStateAction<string>>;
    filterFrequency: string;
    setFilterFrequency: React.Dispatch<React.SetStateAction<string>>;
    filterSourceType: string;
    setFilterSourceType: React.Dispatch<React.SetStateAction<string>>;
    setTablePage: React.Dispatch<React.SetStateAction<number>>;
    fetchTables: (page?: number, size?: number) => void;
    tables: RegTable[];
    loading: boolean;
    tablePage: number;
    tableSize: number;
    setTableSize: React.Dispatch<React.SetStateAction<number>>;
    tableTotal: number;
    handleTableClick: (table: RegTable) => void;
    onShowHistory: (table: RegTable) => void;
    handleShowDetail: (type: 'TABLE' | 'ELEMENT', data: RegTable | RegElement) => void;
    handleEditTable: (table: RegTable) => void;
    handleDeleteTable: (id: number | string) => void;
}

const RegulatoryAssetTableView: React.FC<RegulatoryAssetTableViewProps> = ({
    stats,
    loadingStats,
    showAdvancedFilter,
    setShowAdvancedFilter,
    appliedFilterCount,
    tableKeyword,
    setTableKeyword,
    handleTableSearch,
    viewMode,
    setViewMode,
    selectedTableIds,
    setSelectedTableIds,
    tableFileInputRef,
    handleTableImport,
    handleTableExport,
    handleBatchDeleteTables,
    selectedSystem,
    isSyncing,
    isGeneratingHiveSql,
    handleSyncCodeSnippets,
    handleGenerateHiveSql,
    handleAddTable,
    filterStatus,
    setFilterStatus,
    filterFrequency,
    setFilterFrequency,
    filterSourceType,
    setFilterSourceType,
    setTablePage,
    fetchTables,
    tables,
    loading,
    tablePage,
    tableSize,
    setTableSize,
    tableTotal,
    handleTableClick,
    onShowHistory,
    handleShowDetail,
    handleEditTable,
    handleDeleteTable,
}) => {
    return (
        <div className="flex flex-col h-full animate-in fade-in slide-in-from-top-2 duration-300">
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

                    <div className="hidden xl:flex items-center gap-4 px-4 border-l border-slate-200 mx-2">
                        <div className="flex items-center gap-1.5 text-xs text-slate-600" title="总报表数">
                            <div className="p-1 rounded bg-indigo-50 text-indigo-500">
                                <Table2 size={14} />
                            </div>
                            <div className="flex flex-col leading-none">
                                <span className="font-bold text-slate-700">{loadingStats ? '-' : stats?.tableCount || 0}</span>
                                <span className="text-[10px] scale-90 origin-left text-slate-400">总数</span>
                            </div>
                        </div>
                        <div className="flex items-center gap-1.5 text-xs text-slate-600" title="已上线">
                            <div className="p-1 rounded bg-emerald-50 text-emerald-500">
                                <CheckCircle size={14} />
                            </div>
                            <div className="flex flex-col leading-none">
                                <span className="font-bold text-slate-700">{loadingStats ? '-' : stats?.onlineCount || 0}</span>
                                <span className="text-[10px] scale-90 origin-left text-slate-400">上线</span>
                            </div>
                        </div>
                        <div className="flex items-center gap-1.5 text-xs text-slate-600" title="开发中">
                            <div className="p-1 rounded bg-amber-50 text-amber-500">
                                <TrendingUp size={14} />
                            </div>
                            <div className="flex flex-col leading-none">
                                <span className="font-bold text-slate-700">{loadingStats ? '-' : stats?.developingCount || 0}</span>
                                <span className="text-[10px] scale-90 origin-left text-slate-400">开发</span>
                            </div>
                        </div>
                        <div className="flex items-center gap-1.5 text-xs text-slate-600" title="字段/指标">
                            <div className="p-1 rounded bg-blue-50 text-blue-500">
                                <BarChart3 size={14} />
                            </div>
                            <div className="flex flex-col leading-none">
                                <span className="font-bold text-slate-700">{loadingStats ? '-' : stats?.elementCount || 0}</span>
                                <span className="text-[10px] scale-90 origin-left text-slate-400">元素</span>
                            </div>
                        </div>
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
                                            onClick={() => onShowHistory(table)}
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
                                    onShowHistory={() => onShowHistory(table)}
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
    );
};

export default RegulatoryAssetTableView;
