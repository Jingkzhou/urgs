import React, { useState } from 'react';
import { X, Clock } from 'lucide-react';
import { RegTable } from '../types';
import { FormField } from './RegAssetHelper';
import ReqInfoFormGroup from '../../ReqInfoFormGroup';
import { AiOptimizeButton } from '../../../common/AiOptimizeButton';

// Define the system interface locally if needed, or pass only what's necessary
interface SsoConfig {
    id: number;
    clientId: string;
    name: string;
}

interface TableModalProps {
    table: RegTable | null;
    systems: SsoConfig[];
    defaultSystemCode?: string;
    onSave: (data: RegTable) => void;
    onClose: () => void;
}

export const TableModal: React.FC<TableModalProps> = ({ table, systems, defaultSystemCode, onSave, onClose }) => {
    const [form, setForm] = useState<RegTable>(table || {
        name: '', cnName: '', sortOrder: 0, systemCode: defaultSystemCode || '',
        subjectCode: '', subjectName: '', theme: '', frequency: '',
        sourceType: '', autoFetchStatus: '', documentNo: '', documentTitle: '',
        businessCaliber: '', devNotes: '', owner: '', status: 1,
        reqId: '', plannedDate: ''
    });

    return (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-2xl w-[700px] max-h-[90vh] flex flex-col animate-in slide-in-from-bottom-5 duration-200">
                <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-slate-50 rounded-t-xl">
                    <h3 className="text-lg font-bold text-slate-800">{table ? '编辑表' : '新增表'}</h3>
                    <button onClick={onClose} className="p-1 hover:bg-slate-200 rounded-full"><X size={20} /></button>
                </div>
                <div className="p-6 overflow-y-auto grid grid-cols-2 gap-4">
                    <FormField label="表名 *" value={form.name} onChange={v => setForm({ ...form, name: v })} />
                    <FormField label="中文名" value={form.cnName} onChange={v => setForm({ ...form, cnName: v })} />
                    <FormField label="序号" value={String(form.sortOrder)} onChange={v => setForm({ ...form, sortOrder: Number(v) })} />
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">所属系统</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.systemCode || ''} onChange={e => setForm({ ...form, systemCode: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            {systems.map(s => <option key={s.id} value={s.clientId}>{s.name}</option>)}
                        </select>
                    </div>
                    <FormField label="科目号" value={form.subjectCode} onChange={v => setForm({ ...form, subjectCode: v })} />
                    <FormField label="科目名称" value={form.subjectName} onChange={v => setForm({ ...form, subjectName: v })} />
                    <FormField label="监管主题" value={form.theme} onChange={v => setForm({ ...form, theme: v })} />
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">报送频度</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.frequency || ''} onChange={e => setForm({ ...form, frequency: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            <option value="日">日</option>
                            <option value="周">周</option>
                            <option value="月">月</option>
                            <option value="季">季</option>
                            <option value="年">年</option>
                        </select>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">取数来源</label>
                        <select className="w-full border border-slate-200 rounded-lg p-2 text-sm focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.sourceType || ''} onChange={e => setForm({ ...form, sourceType: e.target.value })}>
                            <option value="">-- 请选择 --</option>
                            <option value="手工">手工</option>
                            <option value="接口">接口</option>
                            <option value="SQL">SQL</option>
                        </select>
                    </div>
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
                        <div className="flex justify-between items-center mb-1">
                            <label className="block text-sm font-medium text-slate-700">业务口径</label>
                            <AiOptimizeButton
                                value={form.businessCaliber || ''}
                                onApply={(val) => setForm({ ...form, businessCaliber: val })}
                                promptGenerator={(val) => `你是一个金融监管报送专家。请优化以下【业务口径】描述，使其更加专业、准确，符合监管规范。保持语义不变，语言精炼。内容：${val}`}
                            />
                        </div>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-20 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.businessCaliber || ''} onChange={e => setForm({ ...form, businessCaliber: e.target.value })} />
                    </div>
                    <div className="col-span-2">
                        <div className="flex justify-between items-center mb-1">
                            <label className="block text-sm font-medium text-slate-700">开发备注</label>
                            <AiOptimizeButton
                                value={form.devNotes || ''}
                                onApply={(val) => setForm({ ...form, devNotes: val })}
                                promptGenerator={(val) => `你是一个资深数据工程师。请优化以下【开发备注】，使其技术表述更清晰、逻辑更严密，便于开发人员理解。内容：${val}`}
                            />
                        </div>
                        <textarea className="w-full border border-slate-200 rounded-lg p-2 text-sm h-20 focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 outline-none" value={form.devNotes || ''} onChange={e => setForm({ ...form, devNotes: e.target.value })} />
                    </div>

                    <div className="col-span-2 border-t border-slate-100 pt-4 mt-2">
                        <ReqInfoFormGroup
                            data={{
                                reqId: form.reqId || '',
                                plannedDate: form.plannedDate || '',
                                changeDescription: form.changeDescription || ''
                            }}
                            onChange={(info) => setForm({ ...form, ...info })}
                        />
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
