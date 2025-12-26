import React, { useState, useEffect } from 'react';
import { Table2, X, Search } from 'lucide-react';

export const CodeValuesModal: React.FC<{ tableCode: string; onClose: () => void }> = ({ tableCode, onClose }) => {
    const [codes, setCodes] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [keyword, setKeyword] = useState('');
    const [tableInfo, setTableInfo] = useState<any>(null);

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
