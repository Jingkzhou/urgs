import React, { useState, useEffect, useRef } from 'react';
import { Search, Plus, X, Edit, Trash2, Upload, Download, Database, Layers, ChevronRight, ChevronDown, Folder } from 'lucide-react';
import Pagination from '../common/Pagination';
import { systemService, SsoConfig } from '../../services/systemService';
import Auth from '../Auth';

const CodeDirectory: React.FC = () => {
    // Code List State
    const [codeData, setCodeData] = useState<any[]>([]);
    const [page, setPage] = useState(1);
    const [size, setSize] = useState(10);
    const [total, setTotal] = useState(0);
    const [keyword, setKeyword] = useState('');

    // Table List State
    const [tables, setTables] = useState<any[]>([]);
    const [selectedTable, setSelectedTable] = useState<any>(null);
    const [tableSearch, setTableSearch] = useState('');

    const [systems, setSystems] = useState<SsoConfig[]>([]); // Systems list

    const [showCodeModal, setShowCodeModal] = useState(false);
    const [showTableModal, setShowTableModal] = useState(false); // New: Separate modal for tables
    const [editingCode, setEditingCode] = useState<any>(null);
    const [editingTable, setEditingTable] = useState<any>(null); // New: State for table editing
    const [isImporting, setIsImporting] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Collapsed Systems State
    // Store IDs of EXPANDED systems. Default empty (all collapsed) or basic logic.
    const [expandedSystems, setExpandedSystems] = useState<Set<string>>(new Set());

    const toggleSystem = (sysCode: string) => {
        const newSet = new Set(expandedSystems);
        if (newSet.has(sysCode)) {
            newSet.delete(sysCode);
        } else {
            newSet.add(sysCode);
        }
        setExpandedSystems(newSet);
    };

    // Fetch Systems
    useEffect(() => {
        const fetchSystems = async () => {
            try {
                const data = await systemService.list();
                setSystems(data);
            } catch (error) {
                console.error('Failed to fetch systems:', error);
            }
        };
        fetchSystems();
    }, []);

    // Fetch Tables (Value Domains)
    const fetchTables = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            // Updated endpoint to fetch from code_table entity
            const res = await fetch('/api/metadata/code-tables', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (Array.isArray(data)) {
                setTables(data);
            }
        } catch (error) {
            console.error('Failed to fetch tables:', error);
        }
    };

    useEffect(() => {
        fetchTables();
    }, []);

    // Deep Linking: Select table from URL
    useEffect(() => {
        const handleHashChange = () => {
            const hash = window.location.hash;
            if (hash.includes('?') && tables.length > 0) {
                const params = new URLSearchParams(hash.split('?')[1]);
                const tableCodeParam = params.get('tableCode');

                // If tableCode param exists, try to select it
                if (tableCodeParam) {
                    const target = tables.find(t => t.tableCode === tableCodeParam);
                    if (target) {
                        setSelectedTable(target);
                        if (target.systemCode) {
                            setExpandedSystems(prev => {
                                const newSet = new Set(prev);
                                newSet.add(target.systemCode);
                                return newSet;
                            });
                        }
                    }
                }
            }
        };

        handleHashChange(); // Check on mount/update
        window.addEventListener('hashchange', handleHashChange);
        return () => window.removeEventListener('hashchange', handleHashChange);
    }, [tables]);

    const fetchCodes = async (currentPage = page, currentSize = size, currentKeyword = keyword, currentTableCode = selectedTable?.tableCode) => {
        try {
            const token = localStorage.getItem('auth_token');
            let url = `/api/metadata/code-directory?page=${currentPage}&size=${currentSize}`;
            if (currentKeyword) {
                url += `&keyword=${encodeURIComponent(currentKeyword)}`;
            }
            if (currentTableCode) {
                url += `&tableCode=${encodeURIComponent(currentTableCode)}`;
            }

            const res = await fetch(url, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (data && data.records) {
                setCodeData(data.records);
                setTotal(data.total);
            } else {
                setCodeData([]);
                setTotal(0);
            }
        } catch (error) {
            console.error('Failed to fetch codes:', error);
            setCodeData([]);
            setTotal(0);
        }
    };

    useEffect(() => {
        fetchCodes(page, size, keyword, selectedTable?.tableCode);
    }, [page, size, selectedTable]);

    const handleSearch = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter') {
            setPage(1);
            fetchCodes(1, size, keyword, selectedTable?.tableCode);
        }
    };

    const handleEditCode = (record: any) => {
        setEditingCode(record);
        setShowCodeModal(true);
    };

    const handleAddCode = () => {
        // If a table is selected, pre-fill the table info
        const initialData = selectedTable ? {
            tableName: selectedTable.tableName,
            tableCode: selectedTable.tableCode,
            systemCode: selectedTable.systemCode,
            // Assuming we might want to default other fields or leave blank
        } : null;

        setEditingCode(initialData);
        setShowCodeModal(true);
    };

    // New: Handle adding a new Value Domain (Table)
    const handleAddTable = () => {
        setEditingTable(null);
        setShowTableModal(true);
    };

    const handleEditTable = (e: React.MouseEvent, table: any) => {
        e.stopPropagation();
        setEditingTable(table);
        setShowTableModal(true);
    };

    const handleDeleteTable = async (e: React.MouseEvent, id: string) => {
        e.stopPropagation();
        if (window.confirm('确定要删除该码表及其定义吗？')) {
            try {
                const token = localStorage.getItem('auth_token');
                await fetch(`/api/metadata/code-tables/${id}`, {
                    method: 'DELETE',
                    headers: { 'Authorization': `Bearer ${token}` }
                });
                if (selectedTable?.id === id) {
                    setSelectedTable(null);
                    setCodeData([]);
                }
                fetchTables();
            } catch (error) {
                console.error('Failed to delete table:', error);
            }
        }
    };

    const handleSaveTable = async (e: React.FormEvent) => {
        e.preventDefault();
        const form = e.target as HTMLFormElement;
        const formData = new FormData(form);

        const tableData = {
            id: editingTable?.id,
            tableName: formData.get('tableName'),
            tableCode: formData.get('tableCode'),
            systemCode: formData.get('systemCode'),
            standard: formData.get('standard'),
            description: formData.get('description'),
        };

        try {
            const token = localStorage.getItem('auth_token');
            const method = editingTable?.id ? 'PUT' : 'POST';
            const res = await fetch('/api/metadata/code-tables', {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(tableData)
            });

            if (res.ok) {
                setShowTableModal(false);
                fetchTables();
            } else {
                const errorData = await res.json();
                alert(errorData.message || '保存失败');
            }
        } catch (error) {
            console.error('Failed to save table:', error);
            alert('保存失败，请检查网络或重试');
        }
    };

    const handleDeleteCode = async (id: string) => {
        if (window.confirm('确定要删除该代码吗？')) {
            try {
                const token = localStorage.getItem('auth_token');
                await fetch(`/api/metadata/code-directory/${id}`, {
                    method: 'DELETE',
                    headers: { 'Authorization': `Bearer ${token}` }
                });
                fetchCodes(page, size, keyword, selectedTable?.tableCode);
                // Refresh tables if we deleted the last code of a table? 
                // Might need to check if table list needs update.
                // For now, simpler to just leave it or refresh periodically. 
                // Ideally backend assumes "Value Domain" exists even without codes? No, it's flat.
                // So if we delete the last one, the table disappears from list.
                fetchTables();
            } catch (error) {
                console.error('Failed to delete code:', error);
            }
        }
    };

    const handleSaveCode = async (e: React.FormEvent) => {
        e.preventDefault();
        const form = e.target as HTMLFormElement;
        const formData = new FormData(form);

        const codeData = {
            id: editingCode?.id,
            tableName: formData.get('tableName'),
            tableCode: formData.get('tableCode'),
            sortOrder: formData.get('sortOrder'),
            code: formData.get('code'),
            name: formData.get('name'),
            systemCode: formData.get('systemCode'),
            parentCode: formData.get('parentCode'),
            level: formData.get('level'),
            startDate: formData.get('startDate'),
            endDate: formData.get('endDate'),
            standard: formData.get('standard'),
            description: formData.get('description')
        };

        try {
            const token = localStorage.getItem('auth_token');
            const method = editingCode?.id ? 'PUT' : 'POST';
            await fetch('/api/metadata/code-directory', {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(codeData)
            });
            setShowCodeModal(false);
            fetchCodes(page, size, keyword, selectedTable?.tableCode);
            fetchTables(); // Refresh table list in case new table created/renamed
        } catch (error) {
            console.error('Failed to save code:', error);
        }
    };

    const handleExport = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/metadata/code-directory/export', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const blob = await res.blob();
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'code_directory_export.xlsx';
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
        } catch (error) {
            console.error('Export failed:', error);
            alert('导出失败');
        }
    };

    const handleImportClick = () => {
        fileInputRef.current?.click();
    };

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        const formData = new FormData();
        formData.append('file', file);

        setIsImporting(true);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/metadata/code-directory/import', {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${token}` },
                body: formData
            });
            if (res.ok) {
                alert('导入成功');
                fetchCodes(page, size, keyword, selectedTable?.tableCode);
                fetchTables();
            } else {
                alert('导入失败');
            }
        } catch (error) {
            console.error('Import failed:', error);
            alert('导入失败');
        } finally {
            setIsImporting(false);
            if (fileInputRef.current) {
                fileInputRef.current.value = '';
            }
        }
    };

    const getSystemName = (code: string) => {
        const sys = systems.find(s => s.clientId === code);
        return sys ? sys.name : code;
    };

    const filteredTables = tables.filter(t =>
        (t.tableName && t.tableName.includes(tableSearch)) ||
        (t.tableCode && t.tableCode.includes(tableSearch))
    );

    return (
        <div className="flex-1 bg-white rounded-xl shadow-sm border border-slate-200 flex overflow-hidden h-full relative">
            {/* Left Sidebar: Value Domains */}
            <div className="w-80 border-r border-slate-200 flex flex-col bg-slate-50/30">
                <div className="p-4 border-b border-slate-100">
                    <div className="flex items-center gap-2 mb-3 text-slate-800 font-bold">
                        <Layers size={20} className="text-blue-600" />
                        <span>码表目录</span>
                    </div>
                    <div className="relative mb-3">
                        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            type="text"
                            placeholder="筛选值域..."
                            value={tableSearch}
                            onChange={(e) => setTableSearch(e.target.value)}
                            className="w-full pl-9 pr-3 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                        />
                    </div>
                    <Auth code="metadata:code:table:add">
                        <button
                            onClick={handleAddTable}
                            className="w-full flex items-center justify-center gap-2 px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 text-sm font-medium rounded-lg transition-colors border border-blue-200 border-dashed"
                        >
                            <Plus size={14} />
                            新增值域
                        </button>
                    </Auth>
                </div>
                <div className="flex-1 overflow-y-auto p-2 space-y-1">
                    <div
                        onClick={() => setSelectedTable(null)}
                        className={`px-3 py-2 rounded-lg text-sm font-medium cursor-pointer transition-colors flex items-center gap-2 ${selectedTable === null
                            ? 'bg-blue-50 text-blue-700'
                            : 'text-slate-600 hover:bg-slate-100'
                            }`}
                    >
                        <Database size={16} className={selectedTable === null ? 'text-blue-600' : 'text-slate-400'} />
                        <span>全部代码 (All Codes)</span>
                    </div>

                    {/* System Groups */}
                    {systems.map(system => {
                        const systemTables = filteredTables.filter(t => t.systemCode === system.clientId);
                        if (systemTables.length === 0 && tableSearch) return null; // Hide empty systems when searching

                        const isExpanded = expandedSystems.has(system.clientId) || !!tableSearch;

                        return (
                            <div key={system.id || system.clientId} className="mb-2">
                                <div
                                    onClick={() => toggleSystem(system.clientId)}
                                    className="px-3 py-1.5 text-xs font-bold text-slate-500 uppercase flex items-center justify-between cursor-pointer hover:bg-slate-100/50 rounded transition-colors"
                                >
                                    <div className="flex items-center gap-2">
                                        <Folder size={12} />
                                        {system.name}
                                    </div>
                                    {isExpanded ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                                </div>
                                {isExpanded && (
                                    <div className="pl-2 space-y-0.5 border-l border-slate-200 ml-3 animate-fade-in">
                                        {systemTables.map((table, idx) => (
                                            <div
                                                key={`${table.tableCode}-${idx}`}
                                                onClick={() => {
                                                    setSelectedTable(table);
                                                    setPage(1);
                                                }}
                                                className={`px-3 py-1.5 rounded-lg text-sm cursor-pointer transition-colors group flex items-center justify-between ${selectedTable?.tableCode === table.tableCode
                                                    ? 'bg-blue-50 text-blue-700 shadow-sm border border-blue-100/50'
                                                    : 'text-slate-600 hover:bg-slate-100 border border-transparent'
                                                    }`}
                                            >
                                                <div className="flex flex-col min-w-0">
                                                    <span className="font-medium truncate">{table.tableName}</span>
                                                    <span className="text-[10px] opacity-70 font-mono">{table.tableCode}</span>
                                                </div>
                                                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                    <Auth code="metadata:code:table:edit">
                                                        <button onClick={(e) => handleEditTable(e, table)} className="p-1 hover:bg-blue-100 rounded text-blue-600">
                                                            <Edit size={12} />
                                                        </button>
                                                    </Auth>
                                                    <Auth code="metadata:code:table:delete">
                                                        <button onClick={(e) => handleDeleteTable(e, table.id)} className="p-1 hover:bg-red-100 rounded text-red-600">
                                                            <Trash2 size={12} />
                                                        </button>
                                                    </Auth>
                                                </div>
                                            </div>
                                        ))}
                                        {systemTables.length === 0 && !tableSearch && (
                                            <div className="px-3 py-2 text-xs text-slate-400 italic">
                                                暂无码表
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>
                        );
                    })}

                    {/* Uncategorized Tables */}
                    {filteredTables.filter(t => !t.systemCode || !systems.find(s => s.clientId === t.systemCode)).length > 0 && (
                        <div className="mb-2">
                            <div className="px-3 py-1.5 text-xs font-bold text-slate-500 uppercase flex items-center gap-2">
                                <Folder size={12} />
                                其他 (Unassigned)
                            </div>
                            <div className="pl-2 space-y-0.5 border-l border-slate-200 ml-3">
                                {filteredTables.filter(t => !t.systemCode || !systems.find(s => s.clientId === t.systemCode)).map((table, idx) => (
                                    <div
                                        key={`${table.tableCode}-${idx}`}
                                        onClick={() => {
                                            setSelectedTable(table);
                                            setPage(1);
                                        }}
                                        className={`px-3 py-1.5 rounded-lg text-sm cursor-pointer transition-colors group flex items-center justify-between ${selectedTable?.tableCode === table.tableCode
                                            ? 'bg-blue-50 text-blue-700 shadow-sm border border-blue-100/50'
                                            : 'text-slate-600 hover:bg-slate-100 border border-transparent'
                                            }`}
                                    >
                                        <div className="flex flex-col min-w-0">
                                            <span className="font-medium truncate">{table.tableName}</span>
                                            <span className="text-[10px] opacity-70 font-mono">{table.tableCode}</span>
                                        </div>
                                        {selectedTable?.tableCode === table.tableCode && <ChevronRight size={14} />}
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* Right Content: Codes */}
            <div className="flex-1 flex flex-col min-w-0">
                {selectedTable && (
                    <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/50 flex flex-col gap-2">
                        <div className="flex items-center gap-2">
                            <span className="text-xs font-mono text-slate-500 bg-slate-200 px-1.5 py-0.5 rounded text-nowrap">{selectedTable.tableCode}</span>
                            <h2 className="text-xl font-bold text-slate-800 truncate">{selectedTable.tableName}</h2>
                        </div>
                        <div className="flex gap-4 text-sm text-slate-500">
                            <div className="flex items-center gap-1.5">
                                <Layers size={14} />
                                <span>System: {getSystemName(selectedTable.systemCode)}</span>
                            </div>
                            {selectedTable.standard && (
                                <div className="flex items-center gap-1.5">
                                    <Folder size={14} />
                                    <span>Standard: {selectedTable.standard}</span>
                                </div>
                            )}
                        </div>
                    </div>
                )}

                <div className="p-4 border-b border-slate-100 flex justify-between items-center bg-white sticky top-0 z-20">
                    <div className="flex items-center gap-3">
                        <div className="relative">
                            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                            <input
                                type="text"
                                placeholder={selectedTable ? "在此值域中搜索..." : "搜索全部代码..."}
                                value={keyword}
                                onChange={(e) => setKeyword(e.target.value)}
                                onKeyDown={handleSearch}
                                className="pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 w-64 transition-all"
                            />
                        </div>
                    </div>
                    <div className="flex gap-2">
                        <input
                            type="file"
                            ref={fileInputRef}
                            className="hidden"
                            accept=".xlsx,.xls"
                            onChange={handleFileChange}
                        />
                        <Auth code="metadata:code:import">
                            <button
                                className="flex items-center gap-2 px-3 py-2 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-sm font-medium rounded-lg transition-colors shadow-sm disabled:opacity-50"
                                onClick={handleImportClick}
                                disabled={isImporting}
                            >
                                {isImporting ? <div className="w-4 h-4 border-2 border-slate-400 border-t-transparent rounded-full animate-spin"></div> : <Upload size={16} />}
                                导入
                            </button>
                        </Auth>
                        <Auth code="metadata:code:export">
                            <button
                                className="flex items-center gap-2 px-3 py-2 bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-sm font-medium rounded-lg transition-colors shadow-sm"
                                onClick={handleExport}
                            >
                                <Download size={16} />
                                导出
                            </button>
                        </Auth>
                        {selectedTable && (
                            <Auth code="metadata:code:add">
                                <button
                                    className="flex items-center gap-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-bold rounded-lg transition-colors shadow-sm animate-in fade-in zoom-in duration-200"
                                    onClick={handleAddCode}
                                >
                                    <Plus size={16} />
                                    新增代码
                                </button>
                            </Auth>
                        )}
                    </div>
                </div>

                <div className="flex-1 overflow-auto bg-slate-50/30">
                    <table className="w-full text-sm text-left">
                        <thead className="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-100 sticky top-0 z-10">
                            <tr>
                                {/* If no table selected, show Table info columns. If selected, hide them for cleaner view? 
                                    Let's keep them but maybe deemphasize. 
                                    Actually, if a table is selected, Table Name and Code are redundant in every row.
                                    Let's validly conditionally hide them or just keep them. Keeping is safer for now.
                                */}
                                {!selectedTable && <th className="px-6 py-3 font-medium whitespace-nowrap">码表编号</th>}
                                {!selectedTable && <th className="px-6 py-3 font-medium whitespace-nowrap">码表名称</th>}
                                {!selectedTable && <th className="px-6 py-3 font-medium whitespace-nowrap">归属系统</th>}
                                <th className="px-6 py-3 font-medium whitespace-nowrap">代码</th>
                                <th className="px-6 py-3 font-medium whitespace-nowrap">名称</th>
                                <th className="px-6 py-3 font-medium whitespace-nowrap">排序号</th>
                                <th className="px-6 py-3 font-medium whitespace-nowrap">上级代码</th>
                                <th className="px-6 py-3 font-medium whitespace-nowrap">代码级别</th>
                                <th className="px-6 py-3 font-medium whitespace-nowrap">特别说明</th>
                                <th className="px-6 py-3 font-medium whitespace-nowrap text-right">操作</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100 bg-white">
                            {codeData.map((row) => (
                                <tr key={row.id} className="hover:bg-slate-50 transition-colors">
                                    {!selectedTable && <td className="px-6 py-4 font-mono text-slate-700 font-medium whitespace-nowrap">{row.tableCode}</td>}
                                    {!selectedTable && <td className="px-6 py-4 text-slate-600 whitespace-nowrap">{row.tableName}</td>}
                                    {!selectedTable && <td className="px-6 py-4 text-slate-600 whitespace-nowrap">{getSystemName(row.systemCode)}</td>}

                                    <td className="px-6 py-4 font-mono text-blue-600 font-medium whitespace-nowrap">{row.code}</td>
                                    <td className="px-6 py-4 text-slate-700 whitespace-nowrap">{row.name}</td>
                                    <td className="px-6 py-4 text-slate-500 whitespace-nowrap">{row.sortOrder}</td>
                                    <td className="px-6 py-4 text-slate-500 whitespace-nowrap">{row.parentCode}</td>
                                    <td className="px-6 py-4 text-slate-500 whitespace-nowrap">{row.level}</td>
                                    <td className="px-6 py-4 text-slate-500 max-w-[200px] truncate" title={row.description}>{row.description}</td>
                                    <td className="px-6 py-4 text-right whitespace-nowrap">
                                        <Auth code="metadata:code:edit">
                                            <button className="text-blue-600 hover:text-blue-800 font-medium mr-3" onClick={() => handleEditCode(row)}>
                                                <Edit size={16} />
                                            </button>
                                        </Auth>
                                        <Auth code="metadata:code:delete">
                                            <button className="text-red-600 hover:text-red-800 font-medium" onClick={() => handleDeleteCode(row.id)}>
                                                <Trash2 size={16} />
                                            </button>
                                        </Auth>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                <div className="p-4 border-t border-slate-200 bg-slate-50">
                    <Pagination
                        current={page}
                        total={total}
                        pageSize={size}
                        showSizeChanger={true}
                        onChange={(p, s) => {
                            setPage(p);
                            setSize(s);
                        }}
                    />
                </div>
            </div>

            {/* Code Edit Modal */}
            {
                showCodeModal && (
                    <div className="fixed inset-0 z-[100] flex items-center justify-center">
                        <div className="absolute inset-0 bg-black/20 backdrop-blur-sm" onClick={() => setShowCodeModal(false)}></div>
                        <div className="w-[900px] max-h-[90vh] bg-white rounded-xl shadow-2xl relative flex flex-col animate-scale-in">
                            <div className="p-5 border-b border-slate-100 flex justify-between items-center bg-slate-50 rounded-t-xl flex-none">
                                <h3 className="text-lg font-bold text-slate-800">
                                    {editingCode?.id ? '编辑代码' : '新增代码'}
                                </h3>
                                <button onClick={() => setShowCodeModal(false)} className="p-2 hover:bg-slate-200 rounded-full text-slate-500 transition-colors">
                                    <X size={20} />
                                </button>
                            </div>
                            <form onSubmit={handleSaveCode} className="flex flex-col flex-1 overflow-hidden">
                                <div className="p-6 grid grid-cols-3 gap-4 overflow-y-auto flex-1">
                                    {/* Value Domain Info - ReadOnly if selecting a table? Maybe allow edit if creating new domain. */}
                                    {/* Code Edit Modal - Only code details now. We inherit Table info from selectedTable usually. */}
                                    {/* But what if we want to change code info? The previous fields for table are ignored mostly? */}
                                    {/* Let's keep table code display but read only */}

                                    <div className="col-span-3 bg-slate-50 p-3 rounded-lg border border-slate-100 mb-2 flex gap-4 text-sm text-slate-500">
                                        <div>
                                            <span className="font-bold mr-1">所属码表:</span>
                                            <span className="font-mono bg-white px-1 border rounded">{editingCode?.tableCode || selectedTable?.tableCode}</span>
                                            <span className="ml-1">{editingCode?.tableName || selectedTable?.tableName}</span>
                                        </div>
                                        <input type="hidden" name="tableCode" value={editingCode?.tableCode || selectedTable?.tableCode || ''} />
                                        <input type="hidden" name="tableName" value={editingCode?.tableName || selectedTable?.tableName || ''} />
                                        <input type="hidden" name="systemCode" value={editingCode?.systemCode || selectedTable?.systemCode || ''} />
                                        <input type="hidden" name="standard" value={editingCode?.standard || selectedTable?.standard || ''} />
                                    </div>

                                    <div className="col-span-3 border-t border-slate-100 my-1"></div>

                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">代码 (Code)</label>
                                        <input name="code" type="text" className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.code} required />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">名称 (Name)</label>
                                        <input name="name" type="text" className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.name} required />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">排序号</label>
                                        <input name="sortOrder" type="number" className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.sortOrder} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">上级代码</label>
                                        <input name="parentCode" type="text" className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.parentCode} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">代码级别</label>
                                        <input name="level" type="text" className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.level} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">执行标准</label>
                                        <input name="standard" type="text" className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.standard} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">启用日期</label>
                                        <input name="startDate" type="date" className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.startDate} />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">废止日期</label>
                                        <input name="endDate" type="date" className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.endDate} />
                                    </div>
                                    <div className="col-span-3">
                                        <label className="block text-sm font-medium text-slate-700 mb-1">特别说明</label>
                                        <textarea name="description" rows={3} className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20" defaultValue={editingCode?.description}></textarea>
                                    </div>
                                </div>
                                <div className="p-5 border-t border-slate-100 flex justify-end gap-2 bg-slate-50 rounded-b-xl flex-none">
                                    <button type="button" onClick={() => setShowCodeModal(false)} className="px-4 py-2 text-slate-600 font-medium hover:bg-slate-200 rounded-lg transition-colors">取消</button>
                                    <button type="submit" className="px-4 py-2 bg-blue-600 text-white font-medium hover:bg-blue-700 rounded-lg transition-colors">保存</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )
            }


            {/* Table Management Modal */}
            {
                showTableModal && (
                    <div className="fixed inset-0 z-[100] flex items-center justify-center">
                        <div className="absolute inset-0 bg-black/20 backdrop-blur-sm" onClick={() => setShowTableModal(false)}></div>
                        <div className="w-[600px] bg-white rounded-xl shadow-2xl relative flex flex-col animate-scale-in">
                            <div className="p-5 border-b border-slate-100 flex justify-between items-center bg-slate-50 rounded-t-xl">
                                <h3 className="text-lg font-bold text-slate-800">
                                    {editingTable?.id ? '编辑值域 (Edit Table)' : '新增值域 (New Table)'}
                                </h3>
                                <button onClick={() => setShowTableModal(false)} className="p-2 hover:bg-slate-200 rounded-full text-slate-500 transition-colors">
                                    <X size={20} />
                                </button>
                            </div>
                            <form onSubmit={handleSaveTable} className="flex flex-col">
                                <div className="p-6 grid grid-cols-2 gap-4">
                                    <div className="col-span-2">
                                        <label className="block text-sm font-medium text-slate-700 mb-1">归属系统 (System)</label>
                                        <select
                                            name="systemCode"
                                            className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                                            defaultValue={editingTable?.systemCode || ''}
                                            required
                                        >
                                            <option value="">-- 请选择 --</option>
                                            {systems.map(sys => (
                                                <option key={sys.id || sys.clientId} value={sys.clientId}>{sys.name}</option>
                                            ))}
                                        </select>
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">码表编号 (Code)</label>
                                        <input
                                            name="tableCode"
                                            type="text"
                                            className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                            defaultValue={editingTable?.tableCode}
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-sm font-medium text-slate-700 mb-1">码表名称 (Name)</label>
                                        <input
                                            name="tableName"
                                            type="text"
                                            className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                            defaultValue={editingTable?.tableName}
                                            required
                                        />
                                    </div>
                                    <div className="col-span-2">
                                        <label className="block text-sm font-medium text-slate-700 mb-1">执行标准 (Standard)</label>
                                        <input
                                            name="standard"
                                            type="text"
                                            className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                            defaultValue={editingTable?.standard}
                                        />
                                    </div>
                                    <div className="col-span-2">
                                        <label className="block text-sm font-medium text-slate-700 mb-1">描述 (Description)</label>
                                        <textarea
                                            name="description"
                                            rows={3}
                                            className="w-full px-3 py-2 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                            defaultValue={editingTable?.description}
                                        ></textarea>
                                    </div>
                                </div>
                                <div className="p-5 border-t border-slate-100 flex justify-end gap-2 bg-slate-50 rounded-b-xl">
                                    <button type="button" onClick={() => setShowTableModal(false)} className="px-4 py-2 text-slate-600 font-medium hover:bg-slate-200 rounded-lg transition-colors">取消</button>
                                    <button type="submit" className="px-4 py-2 bg-blue-600 text-white font-medium hover:bg-blue-700 rounded-lg transition-colors">保存</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )
            }
        </div >
    );
};

export default CodeDirectory;
