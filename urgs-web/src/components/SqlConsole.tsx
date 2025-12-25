import React, { useState, useEffect } from 'react';
import Editor from '@monaco-editor/react';
import { Play, AlertCircle, CheckCircle2, Database } from 'lucide-react';

interface SqlResult {
    success: boolean;
    columns?: string[];
    data?: any[];
    error?: string;
}

const SqlConsole: React.FC = () => {
    const [sql, setSql] = useState('SELECT * FROM sys_sso_config LIMIT 10');
    const [result, setResult] = useState<SqlResult | null>(null);
    const [loading, setLoading] = useState(false);
    const [dataSources, setDataSources] = useState<any[]>([]);
    const [selectedSourceId, setSelectedSourceId] = useState<string>('');

    useEffect(() => {
        fetchDataSources();
    }, []);

    const fetchDataSources = async () => {
        const token = localStorage.getItem('auth_token');
        try {
            const res = await fetch('/api/datasource/config', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const list = await res.json();
                setDataSources(list);
            }
        } catch (err) {
            console.error(err);
        }
    };

    const handleExecute = async () => {
        if (!sql.trim()) return;
        setLoading(true);
        setResult(null);

        try {
            const token = localStorage.getItem('auth_token');
            const response = await fetch('/api/sql/execute', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    sql,
                    dataSourceId: selectedSourceId ? Number(selectedSourceId) : null
                })
            });

            const data = await response.json();
            setResult(data);
        } catch (error) {
            setResult({
                success: false,
                error: 'Network error or server failed to respond.'
            });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="h-full flex flex-col bg-slate-50 p-6 gap-4">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <h1 className="text-2xl font-bold text-slate-800 flex items-center gap-2">
                        <Database className="w-6 h-6 text-blue-600" />
                        SQL Data Console
                    </h1>
                    <div className="h-6 w-px bg-slate-300 mx-2" />
                    <select
                        className="px-3 py-1.5 border border-slate-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 outline-none bg-white min-w-[200px]"
                        value={selectedSourceId}
                        onChange={(e) => setSelectedSourceId(e.target.value)}
                    >
                        <option value="">Default Database (Local)</option>
                        {dataSources.map(ds => (
                            <option key={ds.id} value={ds.id}>{ds.name} ({ds.type})</option>
                        ))}
                    </select>
                </div>
                <button
                    onClick={handleExecute}
                    disabled={loading}
                    className={`flex items-center gap-2 px-4 py-2 rounded-md text-white font-medium transition-colors ${loading
                        ? 'bg-blue-400 cursor-not-allowed'
                        : 'bg-blue-600 hover:bg-blue-700 shadow-sm'
                        }`}
                >
                    {loading ? (
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    ) : (
                        <Play className="w-4 h-4" />
                    )}
                    Execute Query
                </button>
            </div>

            {/* Editor Section */}
            <div className="h-64 bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col">
                <div className="bg-slate-50 px-4 py-2 border-b border-slate-200 text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Query Editor
                </div>
                <div className="flex-1">
                    <Editor
                        height="100%"
                        defaultLanguage="sql"
                        value={sql}
                        onChange={(value) => setSql(value || '')}
                        options={{
                            minimap: { enabled: false },
                            fontSize: 14,
                            scrollBeyondLastLine: false,
                            automaticLayout: true,
                            padding: { top: 16, bottom: 16 },
                        }}
                    />
                </div>
            </div>

            {/* Results Section */}
            <div className="flex-1 bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col min-h-[300px]">
                <div className="bg-slate-50 px-4 py-2 border-b border-slate-200 flex items-center justify-between">
                    <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">
                        Results
                    </span>
                    {result && (
                        <span className={`text-xs font-medium flex items-center gap-1.5 ${result.success ? 'text-green-600' : 'text-red-600'}`}>
                            {result.success ? <CheckCircle2 className="w-3.5 h-3.5" /> : <AlertCircle className="w-3.5 h-3.5" />}
                            {result.success ? `${result.data?.length || 0} rows` : 'Error'}
                        </span>
                    )}
                </div>

                <div className="flex-1 overflow-auto p-0">
                    {!result && (
                        <div className="h-full flex flex-col items-center justify-center text-slate-400">
                            <Database className="w-12 h-12 mb-3 opacity-20" />
                            <p>Execute a query to see results here</p>
                        </div>
                    )}

                    {result && !result.success && (
                        <div className="p-6">
                            <div className="bg-red-50 border border-red-100 rounded-lg p-4 text-red-700 text-sm font-mono whitespace-pre-wrap">
                                {result.error}
                            </div>
                        </div>
                    )}

                    {result && result.success && result.columns && (
                        <table className="w-full text-left border-collapse">
                            <thead className="bg-slate-50 sticky top-0 z-10">
                                <tr>
                                    {result.columns.map((col) => (
                                        <th key={col} className="px-4 py-3 text-xs font-semibold text-slate-600 border-b border-slate-200 whitespace-nowrap">
                                            {col}
                                        </th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {result.data?.map((row, idx) => (
                                    <tr key={idx} className="hover:bg-slate-50/50 transition-colors">
                                        {result.columns?.map((col) => (
                                            <td key={`${idx}-${col}`} className="px-4 py-2.5 text-sm text-slate-600 border-b border-slate-100 whitespace-nowrap max-w-xs truncate">
                                                {row[col]?.toString() ?? <span className="text-slate-300 italic">null</span>}
                                            </td>
                                        ))}
                                    </tr>
                                ))}
                                {result.data?.length === 0 && (
                                    <tr>
                                        <td colSpan={result.columns.length} className="px-4 py-8 text-center text-slate-400 text-sm">
                                            No data returned
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    )}
                </div>
            </div>
        </div>
    );
};

export default SqlConsole;
