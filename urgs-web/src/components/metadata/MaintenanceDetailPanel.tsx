import React from 'react';
import { X, Copy, Check, FileText, Tag, Calendar, User, Hash, Code } from 'lucide-react';
import Editor from '@monaco-editor/react';

export interface MaintenanceRecordItem {
    id: string;
    tableName: string;
    tableCnName: string;
    fieldName: string;
    fieldCnName: string;
    modType: string;
    description: string;
    operator: string;
    time: string;
    reqId?: string;
    plannedDate?: string;
    script?: string;
    systemCode?: string;
    assetType?: string;
}

interface MaintenanceDetailPanelProps {
    record: MaintenanceRecordItem;
    onClose: () => void;
}

const MaintenanceDetailPanel: React.FC<MaintenanceDetailPanelProps> = ({ record, onClose }) => {
    const [copied, setCopied] = React.useState(false);

    const handleCopy = () => {
        if (record.script) {
            navigator.clipboard.writeText(record.script);
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        }
    };

    return (
        <div className="w-[450px] bg-white border-l border-slate-200 flex flex-col h-full shadow-xl z-20 animate-in slide-in-from-right duration-300">
            {/* Header */}
            <div className="p-4 border-b border-slate-100 flex justify-between items-start bg-slate-50">
                <div>
                    <h3 className="text-lg font-bold text-slate-800 break-all">{record.tableName}</h3>
                    <div className="flex items-center gap-2 mt-1">
                        <span className="text-xs font-medium px-2 py-0.5 rounded bg-white border border-slate-200 text-slate-600">
                            {record.tableCnName || '未命名'}
                        </span>
                        {record.fieldName && (
                            <span className="text-xs font-medium px-2 py-0.5 rounded bg-indigo-50 text-indigo-700 border border-indigo-100 flex items-center gap-1">
                                <Hash size={10} /> {record.fieldName}
                            </span>
                        )}
                    </div>
                </div>
                <button
                    onClick={onClose}
                    className="p-1.5 hover:bg-slate-200 rounded-full transition-colors text-slate-500"
                >
                    <X size={18} />
                </button>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-5 space-y-6">

                {/* 变更概述 */}
                <div>
                    <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">变更概况</div>
                    <div className="bg-slate-50 rounded-xl p-4 border border-slate-100 space-y-3">
                        <div className="flex justify-between items-center">
                            <span className="text-sm text-slate-500">变更类型</span>
                            <span className={`px-2 py-1 rounded-md text-xs font-bold ${record.modType.includes('新增') ? 'bg-emerald-100 text-emerald-700' :
                                record.modType.includes('删除') ? 'bg-red-100 text-red-700' :
                                    'bg-blue-100 text-blue-700'
                                }`}>
                                {record.modType}
                            </span>
                        </div>
                        <div className="flex justify-between items-center">
                            <span className="text-sm text-slate-500">变更时间</span>
                            <span className="text-sm font-mono text-slate-700">{record.time}</span>
                        </div>
                        <div className="flex justify-between items-center">
                            <span className="text-sm text-slate-500">操作人</span>
                            <div className="flex items-center gap-1.5">
                                <div className="w-5 h-5 rounded-full bg-slate-200 flex items-center justify-center text-[10px] text-slate-600 font-bold">
                                    {record.operator?.[0]?.toUpperCase()}
                                </div>
                                <span className="text-sm font-medium text-slate-700">{record.operator}</span>
                            </div>
                        </div>
                    </div>
                </div>


                {/* 需求与变更详情 */}
                <div className="bg-amber-50 rounded-xl p-4 border border-amber-100 space-y-4">
                    <div className="flex items-center gap-2 mb-1">
                        <Tag size={16} className="text-amber-600" />
                        <h4 className="text-sm font-bold text-amber-800">需求变更详情</h4>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="bg-white/60 p-2.5 rounded-lg border border-amber-200/50">
                            <div className="text-xs text-amber-600/70 mb-0.5">需求编号</div>
                            <div className="text-sm font-medium text-amber-800">{record.reqId || '-'}</div>
                        </div>
                        <div className="bg-white/60 p-2.5 rounded-lg border border-amber-200/50">
                            <div className="text-xs text-amber-600/70 mb-0.5">计划上线</div>
                            <div className="text-sm font-medium text-amber-800">{record.plannedDate || '-'}</div>
                        </div>
                    </div>

                    <div>
                        <div className="text-xs font-medium text-amber-800/70 mb-1.5">变更描述</div>
                        <div className="text-sm text-amber-900 leading-relaxed bg-white/60 p-3 rounded-lg border border-amber-200/50 min-h-[60px]">
                            {record.description || '暂无描述'}
                        </div>
                    </div>
                </div>

                {/* DDL 脚本 */}
                {record.script && (
                    <div className="flex flex-col h-64">
                        <div className="flex justify-between items-center mb-2">
                            <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider flex items-center gap-1">
                                <Code size={12} /> DDL 脚本
                            </div>
                            <button
                                onClick={handleCopy}
                                className={`flex items-center gap-1 text-xs px-2 py-1 rounded transition-colors ${copied ? 'bg-green-100 text-green-700' : 'hover:bg-slate-100 text-slate-500'
                                    }`}
                            >
                                {copied ? <Check size={12} /> : <Copy size={12} />}
                                {copied ? '已复制' : '复制'}
                            </button>
                        </div>
                        <div className="flex-1 rounded-lg overflow-hidden border border-slate-200 bg-[#1e1e1e] shadow-inner">
                            <Editor
                                height="100%"
                                defaultLanguage="sql"
                                value={record.script}
                                theme="vs-dark"
                                options={{
                                    readOnly: true,
                                    minimap: { enabled: false },
                                    fontSize: 12,
                                    scrollBeyondLastLine: false,
                                    lineNumbers: 'off',
                                    padding: { top: 10, bottom: 10 }
                                }}
                            />
                        </div>
                    </div>
                )}
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-slate-100 bg-slate-50 text-xs text-center text-slate-400">
                Record ID: {record.id} • Created at {new Date(record.time).toLocaleString()}
            </div>
        </div>
    );
};

export default MaintenanceDetailPanel;
