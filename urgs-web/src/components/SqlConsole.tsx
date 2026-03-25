import React, { useState, useEffect, useRef, useCallback } from 'react';
import Editor, { loader } from '@monaco-editor/react';
import * as monaco from 'monaco-editor';
import { Play, AlertCircle, CheckCircle2, Database, ChevronLeft, ChevronRight, History, Download, X, Trash2, Star, StarOff } from 'lucide-react';
import { get } from '@/utils/request';
import { executeSql, fetchSchemaMetadata, SqlExecuteResponse, TableMeta } from '@/api/sql';
import { useSqlHistory } from '@/hooks/useSqlHistory';
import { useSqlFavorites } from '@/hooks/useSqlFavorites';

// Configure Monaco to use local instance (Offline Mode)
if (typeof window !== 'undefined') {
    (window as any).MonacoEnvironment = {
        getWorkerUrl: function (_moduleId: any, label: string) {
            return `data:text/javascript;charset=utf-8,${encodeURIComponent(`
                self.MonacoEnvironment = { baseUrl: '${window.location.origin}/' };
                importScripts('https://cdn.jsdelivr.net/npm/monaco-editor@0.44.0/min/vs/base/worker/workerMain.js');
            `)}`;
        }
    };
}
loader.config({ monaco });

const PAGE_SIZE_OPTIONS = [50, 100, 200, 500];

const SqlConsole: React.FC = () => {
    const [sql, setSql] = useState('SELECT * FROM sys_sso_config LIMIT 10');
    const [result, setResult] = useState<SqlExecuteResponse | null>(null);
    const [loading, setLoading] = useState(false);
    const [dataSources, setDataSources] = useState<any[]>([]);
    const [selectedSourceId, setSelectedSourceId] = useState<string>('');
    const [page, setPage] = useState(1);
    const [pageSize, setPageSize] = useState(100);
    const [showHistory, setShowHistory] = useState(false);
    const [showFavorites, setShowFavorites] = useState(false);
    const [saveFavName, setSaveFavName] = useState('');
    const [showSaveFav, setShowSaveFav] = useState(false);
    const [viewCell, setViewCell] = useState<{ col: string; value: string } | null>(null);
    const [editorHeight, setEditorHeight] = useState(256);
    const executeRef = useRef<() => void>(() => {});
    const isDragging = useRef(false);
    const schemaRef = useRef<TableMeta[]>([]);
    const completionDisposableRef = useRef<monaco.IDisposable | null>(null);

    const { history, addEntry, clearHistory } = useSqlHistory();
    const { favorites, addFavorite, removeFavorite } = useSqlFavorites();

    useEffect(() => {
        fetchDataSources();
        loadSchema();
    }, []);

    // 切换数据源时重新加载 schema
    useEffect(() => {
        loadSchema();
    }, [selectedSourceId]);

    const fetchDataSources = async () => {
        try {
            const list = await get<any[]>('/api/datasource/config');
            const dbSources = (list || []).filter((ds: any) =>
                ['RDBMS', 'NoSQL', 'Big Data', 'OLAP', 'Others'].includes(ds.category) &&
                !['ssh', 'http', 'stream'].includes(ds.typeCode)
            );
            setDataSources(dbSources);
        } catch (err) {
            console.error(err);
        }
    };

    const loadSchema = async () => {
        try {
            const dsId = selectedSourceId ? Number(selectedSourceId) : undefined;
            const data = await fetchSchemaMetadata(dsId);
            schemaRef.current = data?.tables || [];
        } catch (err) {
            console.error('Failed to load schema:', err);
            schemaRef.current = [];
        }
    };

    const handleExecute = useCallback(async (targetPage?: number) => {
        if (!sql.trim()) return;
        setLoading(true);
        setResult(null);

        const currentPage = targetPage ?? page;

        try {
            const data = await executeSql({
                sql,
                dataSourceId: selectedSourceId ? Number(selectedSourceId) : null,
                page: currentPage,
                pageSize,
            });
            setResult(data);
            if (targetPage) setPage(targetPage);
            if (data.success) {
                addEntry(sql.trim(), selectedSourceId);
            }
        } catch (error) {
            setResult({
                success: false,
                error: '网络错误或服务器无响应',
            });
        } finally {
            setLoading(false);
        }
    }, [sql, selectedSourceId, page, pageSize, addEntry]);

    useEffect(() => {
        executeRef.current = () => handleExecute();
    }, [handleExecute]);

    const handleEditorMount = (editor: monaco.editor.IStandaloneCodeEditor) => {
        editor.addAction({
            id: 'execute-sql',
            label: '执行查询',
            keybindings: [
                monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter,
            ],
            run: () => { executeRef.current(); },
        });

        // 注册 SQL 自动补全
        if (completionDisposableRef.current) {
            completionDisposableRef.current.dispose();
        }
        completionDisposableRef.current = monaco.languages.registerCompletionItemProvider('sql', {
            provideCompletionItems: (model, position) => {
                const word = model.getWordUntilPosition(position);
                const range = {
                    startLineNumber: position.lineNumber,
                    endLineNumber: position.lineNumber,
                    startColumn: word.startColumn,
                    endColumn: word.endColumn,
                };
                const suggestions: monaco.languages.CompletionItem[] = [];

                for (const table of schemaRef.current) {
                    suggestions.push({
                        label: table.tableName,
                        kind: monaco.languages.CompletionItemKind.Class,
                        insertText: table.tableName,
                        detail: '表',
                        range,
                    });
                    for (const col of table.columns) {
                        suggestions.push({
                            label: col.columnName,
                            kind: monaco.languages.CompletionItemKind.Field,
                            insertText: col.columnName,
                            detail: `${table.tableName} (${col.dataType})`,
                            documentation: col.comment || undefined,
                            range,
                        });
                    }
                }

                return { suggestions };
            },
        });
    };

    const handlePageChange = (newPage: number) => {
        setPage(newPage);
        handleExecute(newPage);
    };

    const handleExportCsv = () => {
        if (!result?.columns || !result?.data) return;
        const header = result.columns.join(',');
        const rows = result.data.map(row =>
            result.columns!.map(col => {
                const val = row[col]?.toString() ?? '';
                return val.includes(',') || val.includes('"') || val.includes('\n')
                    ? `"${val.replace(/"/g, '""')}"` : val;
            }).join(',')
        );
        const csv = [header, ...rows].join('\n');
        const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `query_result_${Date.now()}.csv`;
        a.click();
        URL.revokeObjectURL(url);
    };

    const handleSaveFavorite = () => {
        if (!saveFavName.trim() || !sql.trim()) return;
        addFavorite(saveFavName.trim(), sql.trim(), selectedSourceId);
        setSaveFavName('');
        setShowSaveFav(false);
    };

    const handleDragStart = (e: React.MouseEvent) => {
        isDragging.current = true;
        const startY = e.clientY;
        const startHeight = editorHeight;
        const onMouseMove = (ev: MouseEvent) => {
            if (!isDragging.current) return;
            setEditorHeight(Math.max(120, Math.min(600, startHeight + ev.clientY - startY)));
        };
        const onMouseUp = () => {
            isDragging.current = false;
            document.removeEventListener('mousemove', onMouseMove);
            document.removeEventListener('mouseup', onMouseUp);
        };
        document.addEventListener('mousemove', onMouseMove);
        document.addEventListener('mouseup', onMouseUp);
    };

    const totalPages = result?.totalRows && result.totalRows > 0 && result.pageSize
        ? Math.ceil(result.totalRows / result.pageSize)
        : 0;

    return (
        <div className="h-full flex flex-col bg-slate-50 p-6 gap-4">
            {/* 顶部工具栏 */}
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <h1 className="text-2xl font-bold text-slate-800 flex items-center gap-2">
                        <Database className="w-6 h-6 text-blue-600" />
                        SQL 数据查询
                    </h1>
                    <div className="h-6 w-px bg-slate-300 mx-2" />
                    <select
                        className="px-3 py-1.5 border border-slate-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 outline-none bg-white min-w-[200px]"
                        value={selectedSourceId}
                        onChange={(e) => setSelectedSourceId(e.target.value)}
                    >
                        <option value="">默认数据库（本地）</option>
                        {dataSources.map(ds => (
                            <option key={ds.id} value={ds.id}>{ds.name} ({ds.typeName || '未知'})</option>
                        ))}
                    </select>
                </div>
                <div className="flex items-center gap-2">
                    <button
                        onClick={() => { setShowHistory(!showHistory); setShowFavorites(false); }}
                        className={`p-2 rounded-md border transition-colors ${showHistory ? 'bg-blue-50 border-blue-300 text-blue-600' : 'bg-white border-slate-300 text-slate-500 hover:bg-slate-50'}`}
                        title="查询历史"
                    >
                        <History className="w-4 h-4" />
                    </button>
                    <button
                        onClick={() => { setShowFavorites(!showFavorites); setShowHistory(false); }}
                        className={`p-2 rounded-md border transition-colors ${showFavorites ? 'bg-yellow-50 border-yellow-300 text-yellow-600' : 'bg-white border-slate-300 text-slate-500 hover:bg-slate-50'}`}
                        title="收藏查询"
                    >
                        <Star className="w-4 h-4" />
                    </button>
                    <button
                        onClick={() => setShowSaveFav(true)}
                        className="p-2 rounded-md border bg-white border-slate-300 text-slate-500 hover:bg-slate-50 transition-colors"
                        title="收藏当前查询"
                    >
                        <StarOff className="w-4 h-4" />
                    </button>
                    <div className="h-6 w-px bg-slate-200" />
                    <div className="flex items-center gap-1.5 text-sm text-slate-500">
                        <span>每页</span>
                        <select
                            className="px-2 py-1 border border-slate-300 rounded text-sm bg-white"
                            value={pageSize}
                            onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}
                        >
                            {PAGE_SIZE_OPTIONS.map(size => (
                                <option key={size} value={size}>{size}</option>
                            ))}
                        </select>
                        <span>行</span>
                    </div>
                    <button
                        onClick={() => { setPage(1); handleExecute(1); }}
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
                        执行查询
                    </button>
                    <span className="text-xs text-slate-400">(Ctrl+Enter)</span>
                </div>
            </div>

            {/* 查询历史面板 */}
            {showHistory && (
                <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 max-h-48 overflow-auto">
                    <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium text-slate-700">查询历史</span>
                        {history.length > 0 && (
                            <button onClick={clearHistory} className="text-xs text-red-500 hover:text-red-600 flex items-center gap-1">
                                <Trash2 className="w-3 h-3" /> 清空
                            </button>
                        )}
                    </div>
                    {history.length === 0 ? (
                        <p className="text-xs text-slate-400">暂无查询历史</p>
                    ) : (
                        <div className="space-y-1">
                            {history.map((entry, idx) => (
                                <button
                                    key={idx}
                                    onClick={() => { setSql(entry.sql); setShowHistory(false); }}
                                    className="w-full text-left px-3 py-2 text-xs font-mono text-slate-600 bg-slate-50 rounded hover:bg-blue-50 hover:text-blue-700 truncate transition-colors"
                                    title={entry.sql}
                                >
                                    {entry.sql}
                                </button>
                            ))}
                        </div>
                    )}
                </div>
            )}

            {/* 收藏查询面板 */}
            {showFavorites && (
                <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4 max-h-48 overflow-auto">
                    <div className="flex items-center justify-between mb-2">
                        <span className="text-sm font-medium text-slate-700">收藏查询</span>
                    </div>
                    {favorites.length === 0 ? (
                        <p className="text-xs text-slate-400">暂无收藏查询</p>
                    ) : (
                        <div className="space-y-1">
                            {favorites.map((fav) => (
                                <div key={fav.id} className="flex items-center gap-2">
                                    <button
                                        onClick={() => { setSql(fav.sql); setShowFavorites(false); }}
                                        className="flex-1 text-left px-3 py-2 text-xs bg-slate-50 rounded hover:bg-yellow-50 hover:text-yellow-700 truncate transition-colors"
                                        title={fav.sql}
                                    >
                                        <span className="font-medium text-slate-700">{fav.name}</span>
                                        <span className="text-slate-400 ml-2 font-mono">{fav.sql}</span>
                                    </button>
                                    <button
                                        onClick={() => removeFavorite(fav.id)}
                                        className="p-1 text-slate-400 hover:text-red-500 flex-shrink-0"
                                    >
                                        <X className="w-3 h-3" />
                                    </button>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            )}

            {/* 编辑器区域 */}
            <div
                className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col flex-shrink-0"
                style={{ height: editorHeight }}
            >
                <div className="bg-slate-50 px-4 py-2 border-b border-slate-200 text-xs font-medium text-slate-500 uppercase tracking-wider">
                    查询编辑器
                </div>
                <div className="flex-1">
                    <Editor
                        height="100%"
                        defaultLanguage="sql"
                        value={sql}
                        onChange={(value) => setSql(value || '')}
                        onMount={handleEditorMount}
                        options={{
                            minimap: { enabled: false },
                            fontSize: 14,
                            scrollBeyondLastLine: false,
                            automaticLayout: true,
                            padding: { top: 16, bottom: 16 },
                            quickSuggestions: true,
                            suggestOnTriggerCharacters: true,
                        }}
                    />
                </div>
            </div>

            {/* 拖拽分隔条 */}
            <div
                className="h-2 cursor-row-resize bg-slate-100 hover:bg-blue-200 transition-colors flex items-center justify-center rounded -my-1 flex-shrink-0"
                onMouseDown={handleDragStart}
            >
                <div className="w-8 h-0.5 bg-slate-300 rounded" />
            </div>

            {/* 结果区域 */}
            <div className="flex-1 bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col min-h-[200px]">
                <div className="bg-slate-50 px-4 py-2 border-b border-slate-200 flex items-center justify-between">
                    <span className="text-xs font-medium text-slate-500 uppercase tracking-wider">
                        查询结果
                    </span>
                    <div className="flex items-center gap-3">
                        {result?.success && result.executionTimeMs !== undefined && (
                            <span className="text-xs text-slate-400">
                                耗时 {result.executionTimeMs}ms
                            </span>
                        )}
                        {result?.success && result.data && result.data.length > 0 && (
                            <button
                                onClick={handleExportCsv}
                                className="text-xs text-slate-500 hover:text-blue-600 flex items-center gap-1 transition-colors"
                                title="导出 CSV"
                            >
                                <Download className="w-3.5 h-3.5" />
                                导出
                            </button>
                        )}
                        {result && (
                            <span className={`text-xs font-medium flex items-center gap-1.5 ${result.success ? 'text-green-600' : 'text-red-600'}`}>
                                {result.success ? <CheckCircle2 className="w-3.5 h-3.5" /> : <AlertCircle className="w-3.5 h-3.5" />}
                                {result.success
                                    ? (result.totalRows !== undefined && result.totalRows >= 0
                                        ? `${result.totalRows} 行（第 ${result.page} 页）`
                                        : `${result.data?.length || 0} 行`)
                                    : '错误'}
                            </span>
                        )}
                    </div>
                </div>

                <div className="flex-1 overflow-auto p-0">
                    {!result && (
                        <div className="h-full flex flex-col items-center justify-center text-slate-400">
                            <Database className="w-12 h-12 mb-3 opacity-20" />
                            <p>执行查询以查看结果</p>
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
                                            <td
                                                key={`${idx}-${col}`}
                                                className="px-4 py-2.5 text-sm text-slate-600 border-b border-slate-100 whitespace-nowrap max-w-xs truncate cursor-pointer hover:text-blue-600"
                                                onClick={() => setViewCell({ col, value: row[col]?.toString() ?? 'null' })}
                                                title="点击查看完整内容"
                                            >
                                                {row[col]?.toString() ?? <span className="text-slate-300 italic">null</span>}
                                            </td>
                                        ))}
                                    </tr>
                                ))}
                                {result.data?.length === 0 && (
                                    <tr>
                                        <td colSpan={result.columns.length} className="px-4 py-8 text-center text-slate-400 text-sm">
                                            查询无返回数据
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    )}
                </div>

                {/* 分页控件 */}
                {result?.success && totalPages > 1 && (
                    <div className="bg-slate-50 px-4 py-2 border-t border-slate-200 flex items-center justify-between">
                        <span className="text-xs text-slate-500">
                            共 {result.totalRows} 行，第 {result.page}/{totalPages} 页
                        </span>
                        <div className="flex items-center gap-1">
                            <button
                                onClick={() => handlePageChange((result.page || 1) - 1)}
                                disabled={loading || (result.page || 1) <= 1}
                                className="p-1 rounded hover:bg-slate-200 disabled:opacity-30 disabled:cursor-not-allowed"
                            >
                                <ChevronLeft className="w-4 h-4" />
                            </button>
                            {Array.from({ length: Math.min(totalPages, 7) }, (_, i) => {
                                let pageNum: number;
                                const currentPage = result.page || 1;
                                if (totalPages <= 7) {
                                    pageNum = i + 1;
                                } else if (currentPage <= 4) {
                                    pageNum = i + 1;
                                } else if (currentPage >= totalPages - 3) {
                                    pageNum = totalPages - 6 + i;
                                } else {
                                    pageNum = currentPage - 3 + i;
                                }
                                return (
                                    <button
                                        key={pageNum}
                                        onClick={() => handlePageChange(pageNum)}
                                        disabled={loading}
                                        className={`px-2 py-1 text-xs rounded ${pageNum === currentPage
                                            ? 'bg-blue-600 text-white'
                                            : 'hover:bg-slate-200 text-slate-600'
                                            }`}
                                    >
                                        {pageNum}
                                    </button>
                                );
                            })}
                            <button
                                onClick={() => handlePageChange((result.page || 1) + 1)}
                                disabled={loading || (result.page || 1) >= totalPages}
                                className="p-1 rounded hover:bg-slate-200 disabled:opacity-30 disabled:cursor-not-allowed"
                            >
                                <ChevronRight className="w-4 h-4" />
                            </button>
                        </div>
                    </div>
                )}
            </div>

            {/* 单元格内容查看 Modal */}
            {viewCell && (
                <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center" onClick={() => setViewCell(null)}>
                    <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] flex flex-col" onClick={e => e.stopPropagation()}>
                        <div className="px-4 py-3 border-b flex items-center justify-between">
                            <span className="font-medium text-slate-700">{viewCell.col}</span>
                            <button onClick={() => setViewCell(null)} className="p-1 hover:bg-slate-100 rounded">
                                <X className="w-4 h-4 text-slate-400" />
                            </button>
                        </div>
                        <div className="p-4 overflow-auto flex-1 text-sm text-slate-600 whitespace-pre-wrap font-mono select-text">
                            {viewCell.value}
                        </div>
                    </div>
                </div>
            )}

            {/* 收藏保存弹窗 */}
            {showSaveFav && (
                <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center" onClick={() => setShowSaveFav(false)}>
                    <div className="bg-white rounded-xl shadow-xl w-96 mx-4 flex flex-col" onClick={e => e.stopPropagation()}>
                        <div className="px-4 py-3 border-b flex items-center justify-between">
                            <span className="font-medium text-slate-700">收藏当前查询</span>
                            <button onClick={() => setShowSaveFav(false)} className="p-1 hover:bg-slate-100 rounded">
                                <X className="w-4 h-4 text-slate-400" />
                            </button>
                        </div>
                        <div className="p-4 space-y-3">
                            <div>
                                <label className="text-sm text-slate-600 block mb-1">名称</label>
                                <input
                                    type="text"
                                    value={saveFavName}
                                    onChange={(e) => setSaveFavName(e.target.value)}
                                    onKeyDown={(e) => { if (e.key === 'Enter') handleSaveFavorite(); }}
                                    placeholder="输入收藏名称"
                                    className="w-full px-3 py-2 border border-slate-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 outline-none"
                                    autoFocus
                                />
                            </div>
                            <div className="text-xs text-slate-400 font-mono bg-slate-50 p-2 rounded max-h-20 overflow-auto">
                                {sql.trim() || '(空查询)'}
                            </div>
                        </div>
                        <div className="px-4 py-3 border-t flex justify-end gap-2">
                            <button onClick={() => setShowSaveFav(false)} className="px-3 py-1.5 text-sm bg-slate-100 rounded hover:bg-slate-200">
                                取消
                            </button>
                            <button
                                onClick={handleSaveFavorite}
                                disabled={!saveFavName.trim() || !sql.trim()}
                                className="px-3 py-1.5 text-sm bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
                            >
                                保存
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default SqlConsole;
