import React from 'react';
import { X, Table2, Hash, Target, Calendar, FileText, BookOpen, Code, Zap } from 'lucide-react';
import Editor from '@monaco-editor/react';
import { RegTable, RegElement } from '../types';
import { DetailItem, getAutoFetchStatusBadge } from './RegAssetHelper';

interface DetailModalProps {
    type: 'TABLE' | 'ELEMENT';
    data: RegTable | RegElement;
    onClose: () => void;
}

export const DetailModal: React.FC<DetailModalProps> = ({ type, data, onClose }) => {
    const isTable = type === 'TABLE';
    const table = data as RegTable;
    const element = data as RegElement;

    return (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl shadow-2xl w-[600px] max-h-[90vh] flex flex-col animate-in zoom-in-95 duration-200">
                <div className="p-5 border-b border-slate-200 flex justify-between items-start bg-slate-50 rounded-t-xl">
                    <div className="flex gap-4">
                        <div className="p-3 bg-white rounded-lg shadow-sm">
                            {isTable ? <Table2 size={24} className="text-blue-500" /> :
                                element.type === 'FIELD' ? <Hash size={24} className="text-slate-500" /> :
                                    <Target size={24} className="text-purple-500" />}
                        </div>
                        <div>
                            <h3 className="text-lg font-bold text-slate-800">{data.cnName || data.name}</h3>
                            <div className="flex items-center gap-2 text-sm text-slate-500 font-mono mt-1">
                                {data.name}
                                {!isTable && <span className="text-xs text-slate-400 font-mono">ID: {element.id}</span>}
                                {isTable && table.sortOrder !== undefined && <span className="bg-slate-200 px-1.5 py-0.5 rounded text-xs text-slate-600">Seq: {table.sortOrder}</span>}
                            </div>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-1 hover:bg-slate-200 rounded-full text-slate-500"><X size={20} /></button>
                </div>

                <div className="p-6 overflow-y-auto">
                    <div className="grid grid-cols-2 gap-4">
                        {isTable ? (
                            <>
                                <DetailItem label="所属系统" value={table.systemCode} />
                                <DetailItem label="监管主题" value={table.theme} />
                                <DetailItem label="科目号" value={table.subjectCode} />
                                <DetailItem label="科目名称" value={table.subjectName} />
                                <DetailItem label="报送频度" value={table.frequency} />
                                <DetailItem label="取数来源" value={table.sourceType} />
                                <DetailItem label="自动取数状态" value={getAutoFetchStatusBadge(table.autoFetchStatus)} />
                                <DetailItem icon={<Calendar size={14} />} label="生效日期" value={table.effectiveDate} />
                                <DetailItem icon={<FileText size={14} />} label="发文号" value={table.documentNo} fullWidth />
                                <DetailItem label="发文标题" value={table.documentTitle} fullWidth />
                                <DetailItem icon={<BookOpen size={14} />} label="业务口径" value={table.businessCaliber} fullWidth />
                                <DetailItem label="开发备注" value={table.devNotes} fullWidth />
                            </>
                        ) : (
                            <>
                                <DetailItem label="序号" value={element.sortOrder} />
                                <DetailItem label="类型" value={element.type === 'FIELD' ? '字段' : '指标'} />
                                {element.type === 'FIELD' && (
                                    <>
                                        <DetailItem icon={<Code size={14} />} label="数据类型" value={element.dataType} />
                                        <DetailItem label="长度" value={element.length} />
                                        <DetailItem label="主键" value={element.isPk ? '是' : '否'} />
                                        <DetailItem label="允许为空" value={element.nullable ? '是' : '否'} />
                                        <DetailItem label="校验规则" value={element.validationRule} />
                                    </>
                                )}
                                {element.type === 'INDICATOR' && (
                                    <>
                                        <DetailItem icon={<Zap size={14} />} label="计算公式" value={element.formula} fullWidth />
                                        <DetailItem icon={<Code size={14} />} label="代码片段" value={
                                            element.codeSnippet ? (
                                                <div className="border border-slate-200 rounded-lg overflow-hidden">
                                                    <Editor
                                                        height="150px"
                                                        language="sql"
                                                        value={element.codeSnippet}
                                                        theme="vs-dark"
                                                        options={{
                                                            readOnly: true,
                                                            minimap: { enabled: false },
                                                            scrollBeyondLastLine: false,
                                                            lineNumbers: 'off',
                                                            folding: false,
                                                            fontSize: 12,
                                                            wordWrap: 'on'
                                                        }}
                                                    />
                                                </div>
                                            ) : '-'
                                        } fullWidth />
                                    </>
                                )}
                                <DetailItem label="值域代码表" value={element.codeTableCode} />
                                <DetailItem label="取值范围" value={element.valueRange} />
                                <DetailItem label="自动取数状态" value={getAutoFetchStatusBadge(element.autoFetchStatus)} />
                                <DetailItem icon={<Calendar size={14} />} label="生效日期" value={element.effectiveDate} />
                                <DetailItem icon={<FileText size={14} />} label="发文号" value={element.documentNo} fullWidth />
                                <DetailItem label="发文标题" value={element.documentTitle} fullWidth />
                                <DetailItem icon={<BookOpen size={14} />} label="业务口径" value={element.businessCaliber} fullWidth />
                                <DetailItem label="填报说明" value={element.fillInstruction} fullWidth />
                                <DetailItem label="开发备注" value={element.devNotes} fullWidth />
                            </>
                        )}
                    </div>
                </div>

                <div className="p-4 border-t border-slate-200 bg-slate-50 rounded-b-xl flex justify-end">
                    <button onClick={onClose} className="px-4 py-2 bg-white border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 font-medium shadow-sm">关闭</button>
                    {/* The original handles edit inside of modal but we can just use external controls or add them if needed */}
                </div>
            </div>
        </div>
    );
};
