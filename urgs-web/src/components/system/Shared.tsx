import React from 'react';
import { Search, Plus, Edit, Trash2 } from 'lucide-react';
import { TreeNode, FunctionPoint } from './types';
import Auth from '../Auth';

export const ActionToolbar: React.FC<{
    title: string;
    placeholder?: string;
    codePrefix?: string;
    onAdd?: () => void;
    onSearch?: (term: string) => void;
    children?: React.ReactNode;
    className?: string;
}> = ({ title, placeholder = "请输入关键字搜索...", codePrefix, onAdd, onSearch, children, className }) => (
    <div className={`flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-4 rounded-lg border border-slate-200 ${className}`}>
        <div className="flex items-center gap-2">
            <span className="font-bold text-slate-700">{title}</span>
        </div>
        <div className="flex flex-wrap items-center gap-2 w-full sm:w-auto">
            {children}
            <div className="relative flex-1 sm:w-64">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <input
                    type="text"
                    placeholder={placeholder}
                    onChange={(e) => onSearch?.(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 border border-slate-200 rounded-md text-sm focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none"
                />
            </div>
            {codePrefix && (
                <div className="hidden lg:flex text-xs text-slate-400 bg-slate-50 px-2 py-2 rounded border border-slate-100 font-mono">
                    权限域: {codePrefix}:*
                </div>
            )}
            <Auth code={codePrefix ? `${codePrefix}:add` : ''}>
                <button onClick={onAdd} className="flex items-center gap-1 bg-red-600 text-white px-3 py-2 rounded-md text-sm font-medium hover:bg-red-700 transition-colors shadow-sm whitespace-nowrap">
                    <Plus className="w-4 h-4" />
                    <span className="hidden sm:inline">新增</span>
                </button>
            </Auth>
        </div>
    </div>
);

export const DataTable: React.FC<{ headers: string[]; rows: any[][] }> = ({ headers, rows }) => (
    <div className="bg-white rounded-lg border border-slate-200 overflow-x-auto">
        <table className="w-full text-sm text-left">
            <thead className="bg-slate-50 text-slate-700 font-semibold border-b border-slate-200">
                <tr>
                    {headers.map((h, i) => (
                        <th key={i} className="px-6 py-4 whitespace-nowrap">{h}</th>
                    ))}
                </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
                {rows.map((row, idx) => (
                    <tr key={idx} className="hover:bg-slate-50 transition-colors">
                        {row.map((cell, cIdx) => (
                            <td key={cIdx} className="px-6 py-4 text-slate-600">
                                {cell === 'active' ? (
                                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                                        正常
                                    </span>
                                ) : cell === 'inactive' ? (
                                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-500">
                                        停用
                                    </span>
                                ) : cell === 'maintenance' ? (
                                    <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
                                        维护中
                                    </span>
                                ) : cell === 'actions' ? (
                                    <div className="flex items-center gap-3">
                                        <button className="text-slate-400 hover:text-blue-600"><Edit className="w-4 h-4" /></button>
                                        <button className="text-slate-400 hover:text-red-600"><Trash2 className="w-4 h-4" /></button>
                                    </div>
                                ) : (
                                    <span className="truncate max-w-[200px] block" title={cell.toString()}>{cell}</span>
                                )}
                            </td>
                        ))}
                    </tr>
                ))}
            </tbody>
        </table>
        <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>共 {rows.length} 条数据</span>
            <div className="flex gap-2">
                <button className="px-2 py-1 border border-slate-200 rounded hover:bg-slate-50 disabled:opacity-50" disabled>上一页</button>
                <button className="px-2 py-1 border border-slate-200 rounded hover:bg-slate-50">下一页</button>
            </div>
        </div>
    </div>
);

// Helper function to convert flat list to tree
export const buildTree = (items: FunctionPoint[]): TreeNode[] => {
    const map = new Map<string, TreeNode>();
    const roots: TreeNode[] = [];

    // 1. Initialize nodes
    items.forEach(item => {
        map.set(item.id, { ...item, children: [] });
    });

    // 2. Build hierarchy
    items.forEach(item => {
        const node = map.get(item.id)!;
        if (item.parentId === 'root') {
            roots.push(node);
        } else {
            const parent = map.get(item.parentId);
            if (parent) {
                parent.children?.push(node);
            } else {
                // Fallback for safety if parent doesn't exist in dataset
                roots.push(node);
            }
        }
    });
    return roots;
};
