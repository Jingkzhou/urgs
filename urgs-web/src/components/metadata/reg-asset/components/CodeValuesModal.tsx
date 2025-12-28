import React, { useState, useEffect, useCallback } from 'react';
import { Database, X, Search, Sparkles } from 'lucide-react';

export const CodeValuesModal: React.FC<{ tableCode: string; onClose: () => void }> = ({ tableCode, onClose }) => {
    const [codes, setCodes] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [keyword, setKeyword] = useState('');
    const [tableInfo, setTableInfo] = useState<any>(null);

    // ESC 键关闭弹窗
    useEffect(() => {
        const handleEsc = (e: KeyboardEvent) => {
            if (e.key === 'Escape') onClose();
        };
        window.addEventListener('keydown', handleEsc);
        return () => window.removeEventListener('keydown', handleEsc);
    }, [onClose]);

    useEffect(() => {
        fetchCodes();
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

    const fetchCodes = useCallback(async (kw = keyword) => {
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
    }, [tableCode, keyword]);

    return (
        <div
            className="fixed inset-0 code-modal-backdrop backdrop-blur-sm flex items-center justify-center z-50 p-4"
            onClick={(e) => e.target === e.currentTarget && onClose()}
        >
            <div className="code-modal-crystal rounded-2xl w-[880px] max-h-[85vh] flex flex-col animate-crystal-in overflow-hidden">

                {/* Header */}
                <div className="code-modal-header p-5 flex justify-between items-start">
                    <div className="flex gap-4 items-center">
                        {/* 发光图标容器 */}
                        <div className="code-modal-icon p-3 rounded-xl">
                            <Database size={28} className="text-blue-500" />
                        </div>
                        <div>
                            <h3 className="text-xl font-semibold text-slate-800 flex items-center gap-2">
                                {tableInfo ? tableInfo.tableName : tableCode}
                                <Sparkles size={16} className="text-blue-400 opacity-60" />
                            </h3>
                            <div className="flex items-center gap-2 mt-1">
                                <span className="code-modal-code-cell text-sm">
                                    {tableCode}
                                </span>
                                {tableInfo?.systemCode && (
                                    <span className="code-modal-badge px-2 py-0.5 rounded-md text-xs font-medium">
                                        {tableInfo.systemCode}
                                    </span>
                                )}
                            </div>
                        </div>
                    </div>
                    <button
                        onClick={onClose}
                        className="code-modal-close p-2 rounded-lg text-slate-500 hover:text-blue-500"
                    >
                        <X size={20} />
                    </button>
                </div>

                {/* Search Bar */}
                <div className="px-5 pb-4">
                    <div className="relative">
                        <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            type="text"
                            placeholder="输入关键词搜索码值..."
                            className="code-modal-search w-full pl-12 pr-4 py-3 text-sm rounded-xl text-slate-700 placeholder-slate-400 outline-none"
                            value={keyword}
                            onChange={(e) => setKeyword(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && fetchCodes(e.currentTarget.value)}
                        />
                    </div>
                    {!loading && (
                        <div className="mt-2 text-xs text-slate-500 px-1">
                            共 <span className="text-blue-500 font-medium">{codes.length}</span> 条记录
                        </div>
                    )}
                </div>

                {/* Table Area */}
                <div className="flex-1 overflow-y-auto code-modal-scroll mx-5 mb-4 rounded-xl border border-slate-200">
                    <table className="w-full text-sm text-left">
                        <thead className="code-modal-table-header text-xs text-slate-500 uppercase tracking-wider sticky top-0">
                            <tr>
                                <th className="px-5 py-4 font-medium">码值</th>
                                <th className="px-5 py-4 font-medium">名称</th>
                                <th className="px-5 py-4 font-medium">描述</th>
                                <th className="px-5 py-4 font-medium">标准依据</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan={4} className="text-center py-16">
                                        <div className="flex flex-col items-center gap-3">
                                            <div className="w-8 h-8 border-2 border-blue-200 border-t-blue-500 rounded-full animate-spin" />
                                            <span className="text-slate-400 animate-pulse-glow">加载中...</span>
                                        </div>
                                    </td>
                                </tr>
                            ) : codes.length > 0 ? (
                                codes.map((c, i) => (
                                    <tr key={i} className="code-modal-row">
                                        <td className="px-5 py-3">
                                            <span className="code-modal-code-cell text-sm font-medium">
                                                {c.code}
                                            </span>
                                        </td>
                                        <td className="px-5 py-3 text-slate-700 font-medium">
                                            <span className="flex items-center gap-2">
                                                <span className="w-1.5 h-1.5 rounded-full bg-blue-400" />
                                                {c.name}
                                            </span>
                                        </td>
                                        <td className="px-5 py-3 text-slate-500">
                                            {c.description || <span className="text-slate-300">—</span>}
                                        </td>
                                        <td className="px-5 py-3 text-slate-400 text-xs">
                                            {c.standard || <span className="text-slate-300">—</span>}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan={4} className="text-center py-16">
                                        <div className="flex flex-col items-center gap-2">
                                            <Database size={32} className="text-slate-300" />
                                            <span className="text-slate-400">暂无数据</span>
                                        </div>
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>

                {/* Footer */}
                <div className="px-5 py-4 border-t border-slate-100 flex justify-between items-center bg-slate-50/50">
                    <span className="text-xs text-slate-400">
                        按 <kbd className="px-1.5 py-0.5 bg-white border border-slate-200 rounded text-slate-500 font-mono text-[10px]">ESC</kbd> 关闭
                    </span>
                    <button
                        onClick={onClose}
                        className="code-modal-btn px-5 py-2.5 rounded-lg text-sm font-medium"
                    >
                        关闭
                    </button>
                </div>
            </div>
        </div>
    );
};
