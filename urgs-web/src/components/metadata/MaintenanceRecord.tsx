import React, { useState } from 'react';
import { Search, Filter, Download, Calendar, RefreshCw, Copy } from 'lucide-react';
import Pagination from '../common/Pagination';

const MaintenanceRecord: React.FC = () => {
    const [maintenanceFilters, setMaintenanceFilters] = useState({
        tableName: '',
        tableCnName: '',
        fieldName: '',
        fieldCnName: '',
        plannedDate: '',
        reqId: ''
    });
    const [records, setRecords] = useState<any[]>([]);
    const [page, setPage] = useState(1);
    const [total, setTotal] = useState(0);
    const PAGE_SIZE = 10;

    const fetchRecords = async (currentPage = 1) => {
        try {
            const token = localStorage.getItem('auth_token');
            const params = new URLSearchParams();
            if (maintenanceFilters.tableName) params.append('tableName', maintenanceFilters.tableName);
            if (maintenanceFilters.tableCnName) params.append('tableCnName', maintenanceFilters.tableCnName);
            if (maintenanceFilters.fieldName) params.append('fieldName', maintenanceFilters.fieldName);
            if (maintenanceFilters.fieldCnName) params.append('fieldCnName', maintenanceFilters.fieldCnName);
            if (maintenanceFilters.plannedDate) params.append('plannedDate', maintenanceFilters.plannedDate);
            if (maintenanceFilters.reqId) params.append('reqId', maintenanceFilters.reqId);
            params.append('page', currentPage.toString());
            params.append('size', PAGE_SIZE.toString());

            const res = await fetch(`/api/metadata/maintenance-record?${params.toString()}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            setRecords(data.records || []);
            setTotal(data.total || 0);
            setPage(currentPage);
        } catch (error) {
            console.error('Failed to fetch maintenance records:', error);
        }
    };

    // Debounce fetch when filters change
    React.useEffect(() => {
        const timer = setTimeout(() => {
            fetchRecords(1);
        }, 500);
        return () => clearTimeout(timer);
    }, [maintenanceFilters]);

    return (
        <div className="flex-1 bg-white rounded-xl shadow-sm border border-slate-200 flex flex-col overflow-hidden h-full">
            {/* Search Filters */}
            <div className="p-4 bg-white border-b border-slate-100 grid grid-cols-6 gap-3">
                <input
                    type="text"
                    placeholder="表名"
                    className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                    value={maintenanceFilters.tableName}
                    onChange={(e) => setMaintenanceFilters({ ...maintenanceFilters, tableName: e.target.value })}
                />
                <input
                    type="text"
                    placeholder="表中文名"
                    className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                    value={maintenanceFilters.tableCnName}
                    onChange={(e) => setMaintenanceFilters({ ...maintenanceFilters, tableCnName: e.target.value })}
                />
                <input
                    type="text"
                    placeholder="字段名"
                    className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                    value={maintenanceFilters.fieldName}
                    onChange={(e) => setMaintenanceFilters({ ...maintenanceFilters, fieldName: e.target.value })}
                />
                <input
                    type="text"
                    placeholder="字段中文名"
                    className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                    value={maintenanceFilters.fieldCnName}
                    onChange={(e) => setMaintenanceFilters({ ...maintenanceFilters, fieldCnName: e.target.value })}
                />
                <input
                    type="text"
                    placeholder="计划上线日期"
                    className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                    value={maintenanceFilters.plannedDate}
                    onChange={(e) => setMaintenanceFilters({ ...maintenanceFilters, plannedDate: e.target.value })}
                />
                <input
                    type="text"
                    placeholder="需求编号"
                    className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                    value={maintenanceFilters.reqId}
                    onChange={(e) => setMaintenanceFilters({ ...maintenanceFilters, reqId: e.target.value })}
                />
            </div>

            <div className="flex-1 overflow-auto">
                <table className="w-full text-sm text-left">
                    <thead className="bg-slate-50 text-xs text-slate-500 uppercase border-b border-slate-100 sticky top-0 z-10">
                        <tr>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">表名</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">表中文名</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">修改类型</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">字段名称</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">字段中文名</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">时间</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">计划上线</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">操作人</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">需求编号</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">变更描述</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">执行脚本</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                        {records.map((record) => (
                            <tr key={record.id} className="hover:bg-slate-50 transition-colors">
                                <td className="px-6 py-4 font-mono font-medium text-blue-600 whitespace-nowrap">{record.tableName}</td>
                                <td className="px-6 py-4 text-slate-600 whitespace-nowrap">{record.tableCnName}</td>
                                <td className="px-6 py-4 whitespace-nowrap">
                                    <span className={`px-2 py-0.5 rounded text-xs border ${record.modType.includes('新增') ? 'bg-emerald-50 text-emerald-600 border-emerald-100' :
                                        'bg-amber-50 text-amber-600 border-amber-100'
                                        }`}>
                                        {record.modType}
                                    </span>
                                </td>
                                <td className="px-6 py-4 font-mono text-slate-600 whitespace-nowrap">{record.fieldName}</td>
                                <td className="px-6 py-4 text-slate-600 whitespace-nowrap">{record.fieldCnName}</td>
                                <td className="px-6 py-4 text-slate-500 font-mono text-xs whitespace-nowrap">{record.time}</td>
                                <td className="px-6 py-4 text-slate-500 font-mono text-xs whitespace-nowrap">{record.plannedDate}</td>
                                <td className="px-6 py-4 text-slate-700 whitespace-nowrap">{record.operator}</td>
                                <td className="px-6 py-4 text-slate-500 font-mono text-xs whitespace-nowrap">{record.reqId}</td>
                                <td className="px-6 py-4 text-slate-600 max-w-[200px] truncate" title={record.description}>{record.description}</td>
                                <td className="px-6 py-4 font-mono text-xs text-slate-400 max-w-[150px] relative group">
                                    <div className="truncate cursor-help decoration-dotted underline underline-offset-2">{record.script}</div>
                                    {/* Custom Tooltip */}
                                    <div className="hidden group-hover:block absolute right-0 top-full w-[400px] z-50 pt-1">
                                        <div className="max-h-[300px] overflow-y-auto bg-slate-800 text-slate-200 text-xs rounded-lg shadow-xl border border-slate-700">
                                            <div className="p-3 border-b border-slate-700 flex justify-between items-center bg-slate-900/50">
                                                <span className="font-bold text-slate-400">完整脚本</span>
                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        navigator.clipboard.writeText(record.script);
                                                    }}
                                                    className="flex items-center gap-1 text-blue-400 hover:text-blue-300 transition-colors"
                                                >
                                                    <Copy size={12} />
                                                    <span>复制</span>
                                                </button>
                                            </div>
                                            <div className="p-3 break-all whitespace-pre-wrap font-mono select-text">
                                                {record.script}
                                            </div>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
            {/* Pagination */}
            {total > 0 && (
                <div className="mt-4 bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
                    <Pagination
                        current={page}
                        total={total}
                        pageSize={PAGE_SIZE}
                        onChange={(p) => fetchRecords(p)}
                    />
                </div>
            )}
        </div>
    );
};

export default MaintenanceRecord;
