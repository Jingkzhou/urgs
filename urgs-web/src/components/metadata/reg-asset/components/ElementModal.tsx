import React, { useState, useEffect } from 'react';
import { X, Clock } from 'lucide-react';
import Editor from '@monaco-editor/react';
import { RegElement } from '../types';
import { FormField } from './RegAssetHelper';

interface ElementModalProps {
    element: RegElement;
    systemCode?: string;
    onSave: (data: RegElement) => void;
    onClose: () => void;
}

export const ElementModal: React.FC<ElementModalProps> = ({ element, systemCode, onSave, onClose }) => {
    const [form, setForm] = useState<RegElement>(element);
    const isField = form.type === 'FIELD';
    const [codeTables, setCodeTables] = useState<any[]>([]);

    useEffect(() => {
        const fetchCodeTables = async () => {
            try {
                const token = localStorage.getItem('auth_token');
                const res = await fetch('/api/metadata/code-tables', {
                    headers: { 'Authorization': `Bearer ${token}` }
                });
                if (res.ok) {
                    const data = await res.json();
                    setCodeTables(data);
                }
            } catch (error) {
                console.error('Failed to fetch code tables', error);
            }
        };
        fetchCodeTables();
    }, []);

    const [ctSearch, setCtSearch] = useState(form.codeTableCode || '');
    const [showCtDropdown, setShowCtDropdown] = useState(false);

    useEffect(() => {
        setCtSearch(form.codeTableCode || '');
    }, [form.codeTableCode]);

    const filteredCodeTables = codeTables.filter(ct => {
        if (systemCode && ct.systemCode && ct.systemCode !== systemCode) {
            return false;
        }
        const kw = ctSearch.toLowerCase();
        return (ct.tableCode?.toLowerCase().includes(kw) || ct.tableName?.toLowerCase().includes(kw));
    });

    return (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-2xl w-[700px] max-h-[90vh] flex flex-col animate-in slide-in-from-bottom-5 duration-200">
                <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-slate-50 rounded-t-xl">
                    <h3 className="text-lg font-bold text-slate-800">{element.id ? '编辑' : '新增'}{isField ? '字段' : '指标'}</h3>
                    <button onClick={onClose} className="p-1 hover:bg-slate-200 rounded-full"><X size={20} /></button>
                </div>
                <div className="p-6 overflow-y-auto grid grid-cols-2 gap-4" onClick={() => setShowCtDropdown(false)}>
                    <FormField label="名称 *" value={form.name} onChange={v => setForm({ ...form, name: v })} />
                    <FormField label="序号" value={String(form.sortOrder ?? 0)} onChange={v => setForm({ ...form, sortOrder: v ? parseInt(v) : 0 })} />
                    <FormField label="中文名" value={form.cnName} onChange={v => setForm({ ...form, cnName: v })} />

                    {isField && (
                        <>
                            <FormField label="数据类型" value={form.dataType} onChange={v => setForm({ ...form, dataType: v })} />
                            <FormField label="长度" value={String(form.length || '')} onChange={v => setForm({ ...form, length: v ? parseInt(v) : undefined })} />
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">是否主键</label>
                                <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.isPk || 0} onChange={e => setForm({ ...form, isPk: parseInt(e.target.value) })}>
                                    <option value={0}>否</option>
                                    <option value={1}>是</option>
                                </select>
                            </div>
                        </>
                    )}
                    {!isField && (
                        <>
                            <div className="col-span-2">
                                <label className="block text-sm font-medium text-slate-700 mb-1">计算公式</label>
                                <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-16 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.formula || ''} onChange={e => setForm({ ...form, formula: e.target.value })} />
                            </div>
                            <div className="col-span-2">
                                <label className="block text-sm font-medium text-slate-700 mb-1">代码片段</label>
                                <div className="border border-slate-200 rounded-lg overflow-hidden">
                                    <Editor
                                        height="120px"
                                        language="sql"
                                        value={form.codeSnippet || ''}
                                        theme="vs-dark"
                                        onChange={(value) => setForm({ ...form, codeSnippet: value || '' })}
                                        options={{
                                            minimap: { enabled: false },
                                            scrollBeyondLastLine: false,
                                            lineNumbers: 'on',
                                            fontSize: 12,
                                            wordWrap: 'on',
                                            automaticLayout: true
                                        }}
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">是否初始化项</label>
                                <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.isInit ?? 0} onChange={e => setForm({ ...form, isInit: parseInt(e.target.value) })}>
                                    <option value={0}>否</option>
                                    <option value={1}>是</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">是否归并公式项</label>
                                <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.isMergeFormula ?? 0} onChange={e => setForm({ ...form, isMergeFormula: parseInt(e.target.value) })}>
                                    <option value={0}>否</option>
                                    <option value={1}>是</option>
                                </select>
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">是否填报业务项</label>
                                <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.isFillBusiness ?? 0} onChange={e => setForm({ ...form, isFillBusiness: parseInt(e.target.value) })}>
                                    <option value={0}>否</option>
                                    <option value={1}>是</option>
                                </select>
                            </div>
                        </>
                    )}
                    <div className="relative" onClick={(e) => e.stopPropagation()}>
                        <label className="block text-sm font-medium text-slate-700 mb-1">值域代码表</label>
                        <div className="relative">
                            <input
                                type="text"
                                className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none"
                                placeholder="搜索名称或编码..."
                                value={ctSearch}
                                onChange={(e) => {
                                    setCtSearch(e.target.value);
                                    setShowCtDropdown(true);
                                    if (!e.target.value) setForm({ ...form, codeTableCode: '' });
                                }}
                                onFocus={() => setShowCtDropdown(true)}
                            />
                            {showCtDropdown && (
                                <div className="absolute top-full left-0 w-full mt-1 bg-white border border-slate-200 rounded-lg shadow-lg max-h-48 overflow-y-auto z-10">
                                    {filteredCodeTables.length > 0 ? (
                                        filteredCodeTables.map((ct: any) => (
                                            <div
                                                key={ct.id}
                                                className="px-3 py-2 text-sm hover:bg-slate-50 cursor-pointer border-b border-slate-50 last:border-0"
                                                onClick={() => {
                                                    setForm({ ...form, codeTableCode: ct.tableCode });
                                                    setCtSearch(ct.tableCode);
                                                    setShowCtDropdown(false);
                                                }}
                                            >
                                                <div className="font-medium text-slate-700">{ct.tableCode}</div>
                                                <div className="text-xs text-slate-500">{ct.tableName}</div>
                                            </div>
                                        ))
                                    ) : (
                                        <div className="p-2 text-xs text-slate-400 text-center">无匹配项</div>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>
                    <FormField label="取值范围" value={form.valueRange} onChange={v => setForm({ ...form, valueRange: v })} />
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">自动取数状态</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.autoFetchStatus || ''} onChange={e => setForm({ ...form, autoFetchStatus: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            <option value="未开发">未开发</option>
                            <option value="开发中">开发中</option>
                            <option value="已上线">已上线</option>
                        </select>
                    </div>
                    <FormField label="发文号" value={form.documentNo} onChange={v => setForm({ ...form, documentNo: v })} />
                    <FormField label="发文标题" value={form.documentTitle} onChange={v => setForm({ ...form, documentTitle: v })} />
                    <FormField label="责任人" value={form.owner} onChange={v => setForm({ ...form, owner: v })} />
                    <div className="col-span-2">
                        <label className="block text-sm font-medium text-slate-700 mb-1">业务口径</label>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-16 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.businessCaliber || ''} onChange={e => setForm({ ...form, businessCaliber: e.target.value })} />
                    </div>
                    <div className="col-span-2">
                        <label className="block text-sm font-medium text-slate-700 mb-1">填报说明</label>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-16 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.fillInstruction || ''} onChange={e => setForm({ ...form, fillInstruction: e.target.value })} />
                    </div>
                    <div className="col-span-2">
                        <label className="block text-sm font-medium text-slate-700 mb-1">开发备注</label>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-16 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.devNotes || ''} onChange={e => setForm({ ...form, devNotes: e.target.value })} />
                    </div>

                    <div className="col-span-2 border-t border-slate-100 pt-4 mt-2">
                        <h4 className="text-xs font-bold text-slate-500 uppercase mb-3 flex items-center gap-1">
                            <Clock size={12} /> 变更登记
                        </h4>
                        <div className="grid grid-cols-2 gap-4">
                            <FormField label="需求编号" value={form.reqId} onChange={v => setForm({ ...form, reqId: v })} />
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">计划上线日期</label>
                                <input
                                    type="date"
                                    className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none"
                                    value={form.plannedDate || ''}
                                    onChange={e => setForm({ ...form, plannedDate: e.target.value })}
                                />
                            </div>
                        </div>
                    </div>
                </div>
                <div className="p-4 border-t border-slate-200 flex justify-end gap-2 bg-slate-50 rounded-b-xl">
                    <button onClick={onClose} className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg">取消</button>
                    <button onClick={() => onSave(form)} className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 shadow-sm shadow-indigo-200">保存</button>
                </div>
            </div>
        </div>
    );
};
