import React from 'react';
import { Table2, Calendar, Database, Info, Edit, Clock, Trash2 } from 'lucide-react';
import { RegTable } from '../types';
import { getAutoFetchStatusBadge } from './RegAssetHelper';

interface ReportCardProps {
    table: RegTable;
    onClick: () => void;
    isSelected: boolean;
    onToggleSelect: (e: React.ChangeEvent<HTMLInputElement>) => void;
    onShowDetail: () => void;
    onEdit: () => void;
    onDelete: () => void;
    onShowHistory: () => void;
}

export const ReportCard: React.FC<ReportCardProps> = ({
    table,
    onClick,
    isSelected,
    onToggleSelect,
    onShowDetail,
    onEdit,
    onDelete,
    onShowHistory
}) => (
    <div
        onClick={onClick}
        className={`group bg-white rounded-2xl border transition-all duration-300 relative overflow-hidden flex flex-col ${isSelected ? 'border-indigo-500 ring-2 ring-indigo-50 shadow-lg shadow-indigo-100/50' : 'border-slate-200 hover:border-indigo-300 hover:shadow-xl hover:shadow-slate-200/50'}`}
    >
        <div className="p-5 flex-1 flex flex-col gap-4">
            <div className="flex justify-between items-start">
                <div className={`p-3 rounded-xl transition-colors duration-300 ${isSelected ? 'bg-indigo-600 text-white shadow-md shadow-indigo-200' : 'bg-indigo-50 text-indigo-600 group-hover:bg-indigo-600 group-hover:text-white'}`}>
                    <Table2 size={24} />
                </div>
                <div className="flex flex-col items-end gap-2">
                    {getAutoFetchStatusBadge(table.autoFetchStatus)}
                    <div onClick={e => e.stopPropagation()}>
                        <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={onToggleSelect}
                            className="w-5 h-5 text-indigo-600 rounded-md border-slate-300 shadow-sm focus:ring-indigo-500 transition-all cursor-pointer"
                        />
                    </div>
                </div>
            </div>

            <div className="space-y-1 content-start">
                <h3 className="text-base font-bold text-slate-800 leading-tight group-hover:text-indigo-600 transition-colors line-clamp-2 min-h-[2.5rem]" title={table.cnName}>
                    {table.cnName || table.name}
                </h3>
                <code className="text-[10px] text-slate-400 font-mono tracking-tight block truncate uppercase bg-slate-50 px-1.5 py-0.5 rounded w-fit max-w-full">
                    {table.name}
                </code>
            </div>

            <div className="flex flex-wrap gap-2 mt-auto">
                <div className="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-slate-50 text-slate-600 text-[10px] font-bold border border-slate-100">
                    <Calendar size={10} className="text-slate-400" /> {table.frequency || '未知频度'}
                </div>
                <div className="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-slate-50 text-slate-600 text-[10px] font-bold border border-slate-100">
                    <Database size={10} className="text-slate-400" /> {table.sourceType || '未知来源'}
                </div>
            </div>
        </div>

        <div className="bg-slate-50/50 border-t border-slate-100 p-3 flex justify-between items-center opacity-0 group-hover:opacity-100 transition-all transform translate-y-2 group-hover:translate-y-0">
            <div className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">排序: {table.sortOrder || '-'}</div>
            <div className="flex gap-1" onClick={e => e.stopPropagation()}>
                <button onClick={onShowDetail} className="p-1.5 hover:bg-white hover:text-indigo-600 rounded-lg text-slate-400 transition-all shadow-sm hover:shadow" title="详情"><Info size={14} /></button>
                <button onClick={onEdit} className="p-1.5 hover:bg-white hover:text-slate-800 rounded-lg text-slate-400 transition-all shadow-sm hover:shadow" title="编辑"><Edit size={14} /></button>
                <button onClick={onShowHistory} className="p-1.5 hover:bg-white hover:text-orange-600 rounded-lg text-slate-400 transition-all shadow-sm hover:shadow" title="历史"><Clock size={14} /></button>
                <button onClick={onDelete} className="p-1.5 hover:bg-white hover:text-red-600 rounded-lg text-slate-400 transition-all shadow-sm hover:shadow" title="删除"><Trash2 size={14} /></button>
            </div>
        </div>
    </div>
);
