import React from 'react';
import { Search, Plus } from 'lucide-react';
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
