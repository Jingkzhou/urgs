import React, { useState, useEffect } from 'react';
import { X, FileText, Hash, Calendar, Tag, User, Code, Save } from 'lucide-react';

interface AddMaintenanceModalProps {
    onClose: () => void;
    onSuccess: () => void;
}

const modTypeOptions = [
    { value: '新增表', label: '新增表', color: 'bg-emerald-100 text-emerald-700' },
    { value: '新增字段', label: '新增字段', color: 'bg-emerald-100 text-emerald-700' },
    { value: '修改属性', label: '修改属性', color: 'bg-blue-100 text-blue-700' },
    { value: '修改字段', label: '修改字段', color: 'bg-blue-100 text-blue-700' },
    { value: '删除字段', label: '删除字段', color: 'bg-red-100 text-red-700' },
    { value: '删除表', label: '删除表', color: 'bg-red-100 text-red-700' },
];

const AddMaintenanceModal: React.FC<AddMaintenanceModalProps> = ({ onClose, onSuccess }) => {
    const [form, setForm] = useState({
        tableName: '',
        tableCnName: '',
        fieldName: '',
        fieldCnName: '',
        modType: '新增字段',
        description: '',
        reqId: '',
        plannedDate: '',
        script: '',
        operator: ''
    });
    const [submitting, setSubmitting] = useState(false);
    const [currentUser, setCurrentUser] = useState('');

    useEffect(() => {
        // Get current user from localStorage or context
        const userStr = localStorage.getItem('user');
        if (userStr) {
            try {
                const user = JSON.parse(userStr);
                setCurrentUser(user.nickName || user.username || '');
                setForm(prev => ({ ...prev, operator: user.nickName || user.username || '' }));
            } catch (e) {
                console.error('Failed to parse user', e);
            }
        }
    }, []);

    const handleSubmit = async () => {
        if (!form.tableName || !form.modType || !form.description) {
            alert('请填写必填字段：表名、变更类型、变更描述');
            return;
        }

        setSubmitting(true);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/metadata/maintenance-record', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    ...form,
                    time: new Date().toISOString()
                })
            });

            if (res.ok) {
                onSuccess();
            } else {
                alert('保存失败，请重试');
            }
        } catch (error) {
            console.error('Submit failed:', error);
            alert('保存失败，请重试');
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col animate-in fade-in zoom-in-95 duration-200">
                {/* Header */}
                <div className="flex items-center justify-between p-5 border-b border-slate-100 bg-gradient-to-r from-slate-50 to-slate-100 rounded-t-2xl">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-indigo-100 rounded-lg">
                            <FileText className="w-5 h-5 text-indigo-600" />
                        </div>
                        <div>
                            <h2 className="text-lg font-bold text-slate-800">新增维护记录</h2>
                            <p className="text-sm text-slate-500">手动登记元数据变更</p>
                        </div>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-slate-200 rounded-full transition-colors"
                    >
                        <X className="w-5 h-5 text-slate-500" />
                    </button>
                </div>

                {/* Form Body */}
                <div className="flex-1 overflow-y-auto p-5 space-y-5">
                    {/* 表信息 */}
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                                <Hash size={14} className="text-slate-400" />
                                表名 <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="text"
                                placeholder="如: CBRC_1104_01"
                                className="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 transition-all"
                                value={form.tableName}
                                onChange={(e) => setForm({ ...form, tableName: e.target.value })}
                            />
                        </div>
                        <div>
                            <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                                <FileText size={14} className="text-slate-400" />
                                表中文名
                            </label>
                            <input
                                type="text"
                                placeholder="如: 资产负债表"
                                className="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 transition-all"
                                value={form.tableCnName}
                                onChange={(e) => setForm({ ...form, tableCnName: e.target.value })}
                            />
                        </div>
                    </div>

                    {/* 字段信息 */}
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                                <Hash size={14} className="text-slate-400" />
                                字段名
                            </label>
                            <input
                                type="text"
                                placeholder="如: BALANCE_AMT"
                                className="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 transition-all"
                                value={form.fieldName}
                                onChange={(e) => setForm({ ...form, fieldName: e.target.value })}
                            />
                        </div>
                        <div>
                            <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                                <FileText size={14} className="text-slate-400" />
                                字段中文名
                            </label>
                            <input
                                type="text"
                                placeholder="如: 余额"
                                className="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 transition-all"
                                value={form.fieldCnName}
                                onChange={(e) => setForm({ ...form, fieldCnName: e.target.value })}
                            />
                        </div>
                    </div>

                    {/* 变更类型 */}
                    <div>
                        <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-2">
                            <Tag size={14} className="text-slate-400" />
                            变更类型 <span className="text-red-500">*</span>
                        </label>
                        <div className="flex flex-wrap gap-2">
                            {modTypeOptions.map(opt => (
                                <button
                                    key={opt.value}
                                    type="button"
                                    onClick={() => setForm({ ...form, modType: opt.value })}
                                    className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-all border-2 ${form.modType === opt.value
                                            ? `${opt.color} border-current`
                                            : 'bg-slate-50 text-slate-600 border-transparent hover:bg-slate-100'
                                        }`}
                                >
                                    {opt.label}
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* 需求信息 */}
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                                <Tag size={14} className="text-slate-400" />
                                需求编号
                            </label>
                            <input
                                type="text"
                                placeholder="如: REQ-2024-001"
                                className="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 transition-all"
                                value={form.reqId}
                                onChange={(e) => setForm({ ...form, reqId: e.target.value })}
                            />
                        </div>
                        <div>
                            <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                                <Calendar size={14} className="text-slate-400" />
                                计划上线日期
                            </label>
                            <input
                                type="date"
                                className="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 transition-all"
                                value={form.plannedDate}
                                onChange={(e) => setForm({ ...form, plannedDate: e.target.value })}
                            />
                        </div>
                    </div>

                    {/* 操作人 */}
                    <div>
                        <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                            <User size={14} className="text-slate-400" />
                            操作人
                        </label>
                        <input
                            type="text"
                            placeholder="默认为当前登录用户"
                            className="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 transition-all bg-slate-50"
                            value={form.operator}
                            onChange={(e) => setForm({ ...form, operator: e.target.value })}
                        />
                    </div>

                    {/* 变更描述 */}
                    <div>
                        <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                            <FileText size={14} className="text-slate-400" />
                            变更描述 <span className="text-red-500">*</span>
                        </label>
                        <textarea
                            rows={3}
                            placeholder="请描述本次变更的内容和原因..."
                            className="w-full px-3 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-100 focus:border-indigo-400 transition-all resize-none"
                            value={form.description}
                            onChange={(e) => setForm({ ...form, description: e.target.value })}
                        />
                    </div>

                    {/* DDL 脚本 */}
                    <div>
                        <label className="flex items-center gap-1.5 text-sm font-medium text-slate-700 mb-1.5">
                            <Code size={14} className="text-slate-400" />
                            DDL 脚本
                        </label>
                        <textarea
                            rows={4}
                            placeholder="ALTER TABLE xxx ADD COLUMN yyy VARCHAR(100);"
                            className="w-full px-3 py-2.5 text-sm font-mono bg-slate-900 text-green-400 border border-slate-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-400 transition-all resize-none"
                            value={form.script}
                            onChange={(e) => setForm({ ...form, script: e.target.value })}
                        />
                    </div>
                </div>

                {/* Footer */}
                <div className="p-4 border-t border-slate-100 flex justify-end gap-3 bg-slate-50 rounded-b-2xl">
                    <button
                        onClick={onClose}
                        className="px-4 py-2 text-slate-600 hover:bg-slate-200 rounded-lg font-medium transition-colors"
                    >
                        取消
                    </button>
                    <button
                        onClick={handleSubmit}
                        disabled={submitting}
                        className="px-5 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 font-medium shadow-lg shadow-indigo-200 transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        <Save size={16} />
                        {submitting ? '保存中...' : '保存记录'}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default AddMaintenanceModal;
