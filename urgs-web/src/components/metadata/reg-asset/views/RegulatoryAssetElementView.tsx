import React from 'react';
import {
    ArrowLeft,
    Clock,
    Database,
    Download,
    Edit,
    Filter,
    Hash,
    Info,
    RefreshCw,
    Search,
    Table2,
    Target,
    Trash2,
    Upload,
} from 'lucide-react';
import Auth from '../../../Auth';
import Pagination from '../../../common/Pagination';
import { getAutoFetchStatusBadge } from '../components/RegAssetHelper';
import { RegElement, RegTable } from '../types';

interface RegulatoryAssetElementViewProps {
    currentTable: RegTable;
    elementKeyword: string;
    setElementKeyword: React.Dispatch<React.SetStateAction<string>>;
    fetchElements: (tableId: number | string, page?: number, size?: number, explicitKeyword?: string) => void;
    elementSize: number;
    showElementFilter: boolean;
    setShowElementFilter: React.Dispatch<React.SetStateAction<boolean>>;
    appliedElementFilterCount: number;
    elementFilterStatus: string;
    setElementFilterStatus: React.Dispatch<React.SetStateAction<string>>;
    elementFilterAutoFetch: string;
    setElementFilterAutoFetch: React.Dispatch<React.SetStateAction<string>>;
    setElementPage: React.Dispatch<React.SetStateAction<number>>;
    handleBackToTables: () => void;
    handleShowDetail: (type: 'TABLE' | 'ELEMENT', data: RegTable | RegElement) => void;
    selectedElementIds: Set<number | string>;
    setSelectedElementIds: React.Dispatch<React.SetStateAction<Set<number | string>>>;
    handleBatchDeleteElements: () => void;
    fileInputRef: React.RefObject<HTMLInputElement>;
    handleFileChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
    handleImportClick: () => void;
    handleExport: () => void;
    handleAddElement: (type: 'FIELD' | 'INDICATOR') => void;
    elements: RegElement[];
    elementTotal: number;
    elementPage: number;
    setElementSize: React.Dispatch<React.SetStateAction<number>>;
    getCodeTableName: (code: string) => string;
    onViewCodeTable: (tableCode: string) => void;
    handleEditElement: (element: RegElement) => void;
    handleDeleteElement: (id: number | string) => void;
    onShowHistory: (element: RegElement) => void;
}

const RegulatoryAssetElementView: React.FC<RegulatoryAssetElementViewProps> = ({
    currentTable,
    elementKeyword,
    setElementKeyword,
    fetchElements,
    elementSize,
    showElementFilter,
    setShowElementFilter,
    appliedElementFilterCount,
    elementFilterStatus,
    setElementFilterStatus,
    elementFilterAutoFetch,
    setElementFilterAutoFetch,
    setElementPage,
    handleBackToTables,
    handleShowDetail,
    selectedElementIds,
    setSelectedElementIds,
    handleBatchDeleteElements,
    fileInputRef,
    handleFileChange,
    handleImportClick,
    handleExport,
    handleAddElement,
    elements,
    elementTotal,
    elementPage,
    setElementSize,
    getCodeTableName,
    onViewCodeTable,
    handleEditElement,
    handleDeleteElement,
    onShowHistory,
}) => {
    return (
        <div className="flex flex-col h-full animate-in slide-in-from-right-10 duration-300">
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
                    <div className="hidden xl:flex items-center gap-4 px-4 border-l border-slate-200 mx-4 h-8" key="element-stats">
                        <div className="flex items-center gap-1.5 text-xs text-slate-600" title="字段总数">
                            <div className="p-1 rounded bg-indigo-50 text-indigo-500">
                                <Hash size={14} />
                            </div>
                            <div className="flex flex-col leading-none">
                                <span className="font-bold text-slate-700">{currentTable.fieldCount || 0}</span>
                                <span className="text-[10px] scale-90 origin-left text-slate-400">字段</span>
                            </div>
                        </div>
                        <div className="flex items-center gap-1.5 text-xs text-slate-600" title="指标总数">
                            <div className="p-1 rounded bg-purple-50 text-purple-500">
                                <Target size={14} />
                            </div>
                            <div className="flex flex-col leading-none">
                                <span className="font-bold text-slate-700">{currentTable.indicatorCount || 0}</span>
                                <span className="text-[10px] scale-90 origin-left text-slate-400">指标</span>
                            </div>
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
                            onClick={() => fetchElements(currentTable.id!, 1, elementSize)}
                            className="h-9 px-4 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-all flex items-center justify-center gap-1.5 flex-[1.5] shadow-md shadow-indigo-100"
                        >
                            应用筛选
                        </button>
                    </div>
                </div>
            )}

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
                <div className="w-10"></div>
                <div className="w-12 text-center">序号</div>
                <div className="w-48">名称</div>
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
                                el.codeTableCode ? (
                                    <div
                                        className="cursor-pointer hover:bg-amber-50 rounded p-1 -mx-1 group/code transition-colors"
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            onViewCodeTable(el.codeTableCode!);
                                        }}
                                    >
                                        <div className="font-medium text-amber-600 group-hover/code:text-amber-700">{getCodeTableName(el.codeTableCode)}</div>
                                        <div className="text-[10px] text-slate-400 font-mono group-hover/code:text-amber-600/70">{el.codeTableCode}</div>
                                    </div>
                                ) : '-'
                            ) : (
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
                                    onShowHistory(el);
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
    );
};

export default RegulatoryAssetElementView;
