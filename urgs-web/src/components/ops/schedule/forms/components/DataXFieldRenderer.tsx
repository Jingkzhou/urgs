import React from 'react';
import Editor from '@monaco-editor/react';
import { Plus, Trash2, Info } from 'lucide-react';

interface DataXFieldRendererProps {
    mode: 'reader' | 'writer';
    dataSourceType: string;
    formData: any;
    handleChange: (field: string | Record<string, any>, value?: any) => void;
}

// Group Definitions
const RDBMS_TYPES = ['MYSQL', 'ORACLE', 'SQLSERVER', 'POSTGRESQL', 'DB2', 'CLICKHOUSE', 'DRDS', 'GENERIC', 'HIVE', 'ODPS', 'KUDU'];
const FILE_TYPES = ['HDFS', 'TXTFILE', 'FTP', 'SFTP', 'OSS'];
const NOSQL_TYPES = ['MONGODB', 'HBASE', 'OTS', 'REDIS', 'CASSANDRA'];
const OTHER_TYPES = ['ELASTICSEARCH', 'OPENTSDB', 'TSDB', 'SSH', 'STREAM', 'HTTP'];

export const DataXFieldRenderer: React.FC<DataXFieldRendererProps> = ({ mode, dataSourceType, formData, handleChange }) => {
    const type = dataSourceType?.toUpperCase();

    if (!type) return null;

    // Helper to check type group
    const isRDBMS = RDBMS_TYPES.includes(type);
    const isFile = FILE_TYPES.includes(type);
    const isNoSQL = NOSQL_TYPES.includes(type);
    const isStream = type === 'STREAM';
    const isHttp = type === 'HTTP';

    // --- RDBMS Rendering ---
    if (isRDBMS) {
        if (mode === 'reader') {
            const readerMode = formData.readerMode || 'querySql'; // Default to Query SQL

            return (
                <div className="space-y-4">
                    {/* Mode Selector */}
                    <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1.5">读取方式</label>
                        <div className="flex bg-slate-100 p-1 rounded-lg w-fit">
                            <button
                                className={`px-3 py-1 text-xs font-medium rounded-md transition-all ${readerMode === 'querySql' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                                onClick={() => handleChange('readerMode', 'querySql')}
                            >
                                自定义SQL
                            </button>
                            <button
                                className={`px-3 py-1 text-xs font-medium rounded-md transition-all ${readerMode === 'table' ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
                                onClick={() => handleChange('readerMode', 'table')}
                            >
                                表同步
                            </button>
                        </div>
                    </div>

                    {/* Query SQL Mode */}
                    {readerMode === 'querySql' && (
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>SQL语句
                            </label>
                            <div className="flex border border-slate-200 rounded-lg overflow-hidden h-64">
                                <div className="w-8 bg-slate-50 border-r border-slate-200 flex items-center justify-center text-xs text-slate-400">1</div>
                                <div className="flex-1">
                                    <Editor
                                        height="100%"
                                        defaultLanguage="sql"
                                        value={formData.sql || ''}
                                        onChange={(value) => handleChange('sql', value || '')}
                                        options={{
                                            minimap: { enabled: false },
                                            lineNumbers: 'off',
                                            folding: false,
                                            lineDecorationsWidth: 0,
                                            lineNumbersMinChars: 0,
                                            scrollBeyondLastLine: false,
                                            automaticLayout: true,
                                            padding: { top: 8, bottom: 8 },
                                            fontSize: 13
                                        }}
                                    />
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Table Mode */}
                    {readerMode === 'table' && (
                        <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                        <span className="text-red-500 mr-1">*</span>表名 (Table)
                                    </label>
                                    <input
                                        type="text"
                                        value={formData.table || ''}
                                        onChange={(e) => handleChange('table', e.target.value)}
                                        className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                        placeholder="e.g. users"
                                    />
                                </div>
                                <div>
                                    <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                        切分主键 (SplitPK)
                                    </label>
                                    <input
                                        type="text"
                                        value={formData.splitPk || ''}
                                        onChange={(e) => handleChange('splitPk', e.target.value)}
                                        className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                        placeholder="e.g. id"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                    <span className="text-red-500 mr-1">*</span>列名 (Column)
                                </label>
                                <input
                                    type="text"
                                    value={formData.column || '*'}
                                    onChange={(e) => handleChange('column', e.target.value)}
                                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                    placeholder="Use * for all, or col1,col2"
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                    过滤条件 (Where)
                                </label>
                                <input
                                    type="text"
                                    value={formData.where || ''}
                                    onChange={(e) => handleChange('where', e.target.value)}
                                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                    placeholder="e.g. id > 100"
                                />
                            </div>
                        </div>
                    )}
                </div>
            );
        } else {
            // RDBMS Writer
            return (
                <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>表名 (Table)
                            </label>
                            <input
                                type="text"
                                value={formData.targetTable || ''}
                                onChange={(e) => handleChange('targetTable', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                                placeholder="e.g. target_users"
                            />
                        </div>
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                写入模式 (WriteMode)
                            </label>
                            <select
                                value={formData.writeMode || 'insert'}
                                onChange={(e) => handleChange('writeMode', e.target.value)}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                            >
                                <option value="insert">insert</option>
                                <option value="replace">replace</option>
                                <option value="update">update</option>
                            </select>
                        </div>
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1.5">
                            <span className="text-red-500 mr-1">*</span>列名 (Column)
                        </label>
                        <input
                            type="text"
                            value={formData.targetColumn || '*'}
                            onChange={(e) => handleChange('targetColumn', e.target.value)}
                            className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                            placeholder="Use * for all, or col1,col2"
                        />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1.5">
                            执行前SQL (PreSQL)
                        </label>
                        <textarea
                            value={formData.preSql || ''}
                            onChange={(e) => handleChange('preSql', e.target.value)}
                            className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 h-20 resize-y"
                            placeholder="SQL to run before writing"
                        />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1.5">
                            执行后SQL (PostSQL)
                        </label>
                        <textarea
                            value={formData.postSql || ''}
                            onChange={(e) => handleChange('postSql', e.target.value)}
                            className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 h-20 resize-y"
                            placeholder="SQL to run after writing"
                        />
                    </div>
                </div>
            );
        }
    }

    // --- Stream Rendering ---
    if (isStream) {
        if (mode === 'reader') {
            return (
                <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-xs font-medium text-slate-500 mb-1.5">
                                <span className="text-red-500 mr-1">*</span>记录数 (SliceRecordCount)
                            </label>
                            <input
                                type="number"
                                value={formData.sliceRecordCount || 10}
                                onChange={(e) => handleChange('sliceRecordCount', parseInt(e.target.value))}
                                className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                            />
                        </div>
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1.5">
                            <span className="text-red-500 mr-1">*</span>列定义 (Column)
                        </label>
                        <div className="h-40 border border-slate-200 rounded-lg overflow-hidden">
                            <Editor
                                height="100%"
                                defaultLanguage="json"
                                value={formData.streamColumn || '[\n  {\n    "type": "string",\n    "value": "test"\n  }\n]'}
                                onChange={(value) => handleChange('streamColumn', value || '')}
                                options={{ minimap: { enabled: false }, lineNumbers: 'off', fontSize: 12 }}
                            />
                        </div>
                    </div>
                </div>
            );
        } else {
            return (
                <div className="space-y-4">
                    <div className="flex items-center gap-2">
                        <input
                            type="checkbox"
                            checked={formData.print || false}
                            onChange={(e) => handleChange('print', e.target.checked)}
                            className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                        />
                        <label className="text-sm text-slate-700">打印到控制台 (Print)</label>
                    </div>
                </div>
            );
        }
    }

    // --- File/Storage Rendering ---
    if (isFile) {
        return (
            <div className="space-y-4">
                <div>
                    <label className="block text-xs font-medium text-slate-500 mb-1.5">
                        <span className="text-red-500 mr-1">*</span>路径 (Path)
                    </label>
                    <input
                        type="text"
                        value={mode === 'reader' ? (formData.path || '') : (formData.targetPath || '')}
                        onChange={(e) => handleChange(mode === 'reader' ? 'path' : 'targetPath', e.target.value)}
                        className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                        placeholder="/path/to/data"
                    />
                </div>
                <div className="grid grid-cols-2 gap-4">
                    <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1.5">
                            文件类型 (FileType)
                        </label>
                        <select
                            value={formData.fileType || 'text'}
                            onChange={(e) => handleChange('fileType', e.target.value)}
                            className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                        >
                            <option value="text">text</option>
                            <option value="csv">csv</option>
                            <option value="orc">orc</option>
                            <option value="parquet">parquet</option>
                        </select>
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1.5">
                            字段分隔符 (FieldDelimiter)
                        </label>
                        <input
                            type="text"
                            value={formData.fieldDelimiter || ','}
                            onChange={(e) => handleChange('fieldDelimiter', e.target.value)}
                            className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                        />
                    </div>
                </div>
                {mode === 'writer' && (
                    <div>
                        <label className="block text-xs font-medium text-slate-500 mb-1.5">
                            <span className="text-red-500 mr-1">*</span>文件名 (FileName)
                        </label>
                        <input
                            type="text"
                            value={formData.fileName || ''}
                            onChange={(e) => handleChange('fileName', e.target.value)}
                            className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                            placeholder="data_file"
                        />
                    </div>
                )}
            </div>
        );
    }

    // --- Default / Fallback ---
    return (
        <div className="p-4 bg-slate-50 rounded-lg border border-slate-200 text-center text-slate-500 text-sm">
            <Info className="w-8 h-8 mx-auto mb-2 text-slate-400" />
            Generic configuration for {type}
            <div className="mt-2 text-xs text-slate-400">
                Please configure JSON parameters manually in the Advanced Settings if needed.
            </div>
        </div>
    );
};
