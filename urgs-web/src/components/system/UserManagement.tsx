import React, { useState, useEffect, useMemo } from 'react';
import { UserCircle, Edit, Trash2, Save, X, Filter, ChevronLeft, ChevronRight, Lock, Shield, Ban, CheckSquare, Square, Search, Upload, Download, Plus, GitBranch } from 'lucide-react';
import * as XLSX from 'xlsx';
import { User } from './types';
import Auth from '../Auth';

// --- Custom UI Components ---

const FormInput: React.FC<React.InputHTMLAttributes<HTMLInputElement> & { label: string; icon?: React.ReactNode }> = ({ label, icon, className, ...props }) => (
    <div className={className}>
        <label className="block text-sm font-bold text-slate-700 mb-1.5">{label}</label>
        <div className="relative group">
            {icon && <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-red-500 transition-colors">{icon}</div>}
            <input
                {...props}
                className={`w-full ${icon ? 'pl-10' : 'pl-3'} pr-3 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-red-500/20 focus:border-red-500 outline-none transition-all hover:bg-white hover:border-slate-300 ${props.disabled ? 'opacity-60 cursor-not-allowed' : ''}`}
            />
        </div>
    </div>
);

const FormSelect: React.FC<React.SelectHTMLAttributes<HTMLSelectElement> & { label: string; icon?: React.ReactNode }> = ({ label, icon, children, className, ...props }) => (
    <div className={className}>
        <label className="block text-sm font-bold text-slate-700 mb-1.5">{label}</label>
        <div className="relative group">
            {icon && <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-red-500 transition-colors">{icon}</div>}
            <select
                {...props}
                className={`w-full ${icon ? 'pl-10' : 'pl-3'} pr-8 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-red-500/20 focus:border-red-500 outline-none transition-all hover:bg-white hover:border-slate-300 appearance-none cursor-pointer`}
            >
                {children}
            </select>
            <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                <ChevronRight className="w-4 h-4 rotate-90" />
            </div>
        </div>
    </div>
);

const MultiSelect: React.FC<{
    label: string;
    options: string[];
    value: string[];
    onChange: (val: string[]) => void;
    placeholder?: string
}> = ({ label, options, value, onChange, placeholder = "请选择..." }) => {
    const [isOpen, setIsOpen] = useState(false);
    const containerRef = React.useRef<HTMLDivElement>(null);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const toggleOption = (option: string) => {
        if (value.includes(option)) {
            onChange(value.filter(v => v !== option));
        } else {
            onChange([...value, option]);
        }
    };

    const removeValue = (e: React.MouseEvent, option: string) => {
        e.stopPropagation();
        onChange(value.filter(v => v !== option));
    };

    return (
        <div className="relative" ref={containerRef}>
            <label className="block text-sm font-bold text-slate-700 mb-1.5">{label}</label>
            <div
                className={`min-h-[42px] w-full px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus-within:ring-2 focus-within:ring-red-500/20 focus-within:border-red-500 transition-all hover:bg-white hover:border-slate-300 cursor-pointer flex flex-wrap gap-1.5 items-center ${isOpen ? 'ring-2 ring-red-500/20 border-red-500 bg-white' : ''}`}
                onClick={() => setIsOpen(!isOpen)}
            >
                {value.length === 0 && <span className="text-slate-400 py-1">{placeholder}</span>}
                {value.map(v => (
                    <span key={v} className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-red-50 text-red-700 border border-red-100 text-xs font-medium animate-scale-in">
                        {v}
                        <X className="w-3 h-3 hover:text-red-900 cursor-pointer" onClick={(e) => removeValue(e, v)} />
                    </span>
                ))}
                <div className="ml-auto text-slate-400">
                    <ChevronRight className={`w-4 h-4 transition-transform ${isOpen ? '-rotate-90' : 'rotate-90'}`} />
                </div>
            </div>

            {isOpen && (
                <div className="absolute z-50 w-full mt-1 bg-white border border-slate-200 rounded-lg shadow-xl max-h-60 overflow-y-auto animate-fade-in">
                    {options.length > 0 && (
                        <div
                            className="px-3 py-2.5 text-sm cursor-pointer flex items-center justify-between hover:bg-slate-50 transition-colors border-b border-slate-100 font-bold text-slate-600"
                            onClick={() => {
                                if (value.length === options.length) {
                                    onChange([]);
                                } else {
                                    onChange([...options]);
                                }
                            }}
                        >
                            {value.length === options.length ? '取消全选' : '全选'}
                            {value.length === options.length && <CheckSquare className="w-4 h-4 text-red-600" />}
                        </div>
                    )}
                    {options.length === 0 ? (
                        <div className="p-3 text-center text-slate-400 text-xs">暂无选项</div>
                    ) : (
                        options.map(opt => (
                            <div
                                key={opt}
                                className={`px-3 py-2.5 text-sm cursor-pointer flex items-center justify-between hover:bg-slate-50 transition-colors ${value.includes(opt) ? 'bg-red-50 text-red-700 font-medium' : 'text-slate-700'}`}
                                onClick={() => toggleOption(opt)}
                            >
                                {opt}
                                {value.includes(opt) && <CheckSquare className="w-4 h-4 text-red-600" />}
                            </div>
                        ))
                    )}
                </div>
            )}
        </div>
    );
};

const SearchableSelect: React.FC<{
    label: string;
    icon?: React.ReactNode;
    options: string[];
    value: string;
    onChange: (val: string) => void;
    onSearch: (keyword: string) => void;
    placeholder?: string;
}> = ({ label, icon, options, value, onChange, onSearch, placeholder = "请选择..." }) => {
    const [isOpen, setIsOpen] = useState(false);
    const [inputValue, setInputValue] = useState(value);
    const containerRef = React.useRef<HTMLDivElement>(null);

    useEffect(() => {
        setInputValue(value);
    }, [value]);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
                setIsOpen(false);
                setInputValue(value); // Reset to selected value on blur without selection
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, [value]);

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const newValue = e.target.value;
        setInputValue(newValue);
        onSearch(newValue);
        setIsOpen(true);
    };

    const handleSelect = (option: string) => {
        onChange(option);
        setInputValue(option);
        setIsOpen(false);
    };

    return (
        <div className="relative" ref={containerRef}>
            <label className="block text-sm font-bold text-slate-700 mb-1.5">{label}</label>
            <div className="relative group">
                {icon && <div className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-red-500 transition-colors">{icon}</div>}
                <input
                    type="text"
                    value={inputValue}
                    onChange={handleInputChange}
                    onFocus={() => setIsOpen(true)}
                    placeholder={placeholder}
                    className={`w-full ${icon ? 'pl-10' : 'pl-3'} pr-8 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-red-500/20 focus:border-red-500 outline-none transition-all hover:bg-white hover:border-slate-300`}
                />
                <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                    <ChevronRight className={`w-4 h-4 transition-transform ${isOpen ? '-rotate-90' : 'rotate-90'}`} />
                </div>
            </div>

            {isOpen && (
                <div className="absolute z-50 w-full mt-1 bg-white border border-slate-200 rounded-lg shadow-xl max-h-60 overflow-y-auto animate-fade-in">
                    {options.length === 0 ? (
                        <div className="p-3 text-center text-slate-400 text-xs">
                            {inputValue ? '无匹配选项' : '暂无选项'}
                        </div>
                    ) : (
                        options.map(opt => (
                            <div
                                key={opt}
                                className={`px-3 py-2.5 text-sm cursor-pointer hover:bg-slate-50 transition-colors ${value === opt ? 'bg-red-50 text-red-700 font-medium' : 'text-slate-700'}`}
                                onClick={() => handleSelect(opt)}
                            >
                                {opt}
                            </div>
                        ))
                    )}
                </div>
            )}
        </div>
    );
};

const SegmentedControl: React.FC<{
    label: string;
    options: { value: string; label: string }[];
    value: string;
    onChange: (val: string) => void;
}> = ({ label, options, value, onChange }) => (
    <div>
        <label className="block text-sm font-bold text-slate-700 mb-1.5">{label}</label>
        <div className="flex p-1 bg-slate-100 rounded-lg border border-slate-200">
            {options.map(opt => (
                <button
                    key={opt.value}
                    type="button"
                    onClick={() => onChange(opt.value)}
                    className={`flex-1 py-1.5 text-sm font-medium rounded-md transition-all ${value === opt.value
                        ? 'bg-white text-slate-800 shadow-sm ring-1 ring-black/5'
                        : 'text-slate-500 hover:text-slate-700 hover:bg-slate-200/50'
                        }`}
                >
                    {opt.label}
                </button>
            ))}
        </div>
    </div>
);

const UserForm: React.FC<{
    initialData?: User | null;
    orgOptions?: string[];
    roleOptions?: { id: number; name: string }[]; // Updated to object array
    ssoOptions?: string[];
    onOrgSearch: (keyword: string) => void;
    onClose: () => void;
    onSave: (user: Omit<User, 'id' | 'lastLogin'> & { id?: string }) => void;
}> = ({ initialData, orgOptions, roleOptions, ssoOptions, onOrgSearch, onClose, onSave }) => {
    const safeOrgOptions = orgOptions || [];
    const safeRoleOptions = roleOptions || [];
    const safeSsoOptions = ssoOptions || [];
    const [formData, setFormData] = useState({
        name: initialData?.name || '',
        empId: initialData?.empId || '',
        orgName: initialData?.orgName || (safeOrgOptions[0] || ''),
        roleId: initialData?.roleId || (safeRoleOptions.find(r => r.name === initialData?.roleName)?.id || (safeRoleOptions[0]?.id || 0)),
        roleName: initialData?.roleName || (safeRoleOptions[0]?.name || ''),
        ssoSystems: initialData?.system ? initialData.system.split(',').filter(Boolean) : [],
        phone: initialData?.phone || '',
        status: initialData?.status || 'active',
        gitUsername: initialData?.gitUsername || '',
        gitEmail: initialData?.gitEmail || '',
        gitUserId: initialData?.gitUserId || '',
    });

    // Auto-sync roleId if roleOptions load after initialData or if initialData changes
    useEffect(() => {
        if (initialData && safeRoleOptions.length > 0) {
            // If we have a roleName but roleId is 0 or mismatched, try to find the correct ID
            const matchedRole = safeRoleOptions.find(r => r.name === initialData.roleName);
            if (matchedRole && formData.roleId !== matchedRole.id) {
                setFormData(prev => ({
                    ...prev,
                    roleId: matchedRole.id,
                    roleName: matchedRole.name
                }));
            }
        }
    }, [safeRoleOptions, initialData]);

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        const { ssoSystems, ...dataToSave } = formData;
        onSave({ ...dataToSave, id: initialData?.id, system: ssoSystems.join(',') });
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center pointer-events-none animate-fade-in">
            <div className="absolute inset-0 bg-black/20 backdrop-blur-sm pointer-events-auto" onClick={onClose}></div>
            <div className="bg-white w-full max-w-2xl rounded-xl shadow-2xl pointer-events-auto z-10 relative flex flex-col max-h-[90vh] animate-scale-in">
                <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50 rounded-t-xl">
                    <div>
                        <h3 className="text-lg font-bold text-slate-800">
                            {initialData ? '修改用户' : '新增用户'}
                        </h3>
                        <p className="text-xs text-slate-500 mt-0.5">请完善以下用户基础信息及权限配置</p>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-full transition-colors text-slate-400 hover:text-slate-600">
                        <X className="w-5 h-5" />
                    </button>
                </div>

                <div className="p-8 overflow-y-auto custom-scrollbar">
                    <form id="userForm" onSubmit={handleSubmit} className="space-y-8">
                        {/* Basic Info Section */}
                        <div className="space-y-4">
                            <div className="flex items-center gap-2 text-sm font-bold text-slate-900 pb-2 border-b border-slate-100">
                                <UserCircle className="w-4 h-4 text-red-600" />
                                基础信息
                            </div>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                                <FormInput
                                    label="姓名"
                                    placeholder="请输入真实姓名"
                                    value={formData.name}
                                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                                    required
                                    icon={<UserCircle className="w-4 h-4" />}
                                />
                                <FormInput
                                    label="工号 (登录ID)"
                                    placeholder="请输入唯一工号"
                                    value={formData.empId}
                                    onChange={e => setFormData({ ...formData, empId: e.target.value })}
                                    required
                                    icon={<Shield className="w-4 h-4" />}
                                    className="font-mono"
                                />
                                <FormInput
                                    label="手机号码"
                                    placeholder="11位手机号码"
                                    value={formData.phone}
                                    onChange={e => setFormData({ ...formData, phone: e.target.value })}
                                    icon={<div className="text-xs font-bold">CN</div>}
                                />
                                <SegmentedControl
                                    label="账号状态"
                                    value={formData.status}
                                    onChange={(val) => setFormData({ ...formData, status: val as 'active' | 'inactive' })}
                                    options={[
                                        { value: 'active', label: '正常启用' },
                                        { value: 'inactive', label: '暂时停用' }
                                    ]}
                                />
                            </div>
                        </div>

                        {/* Permission Section */}
                        <div className="space-y-4">
                            <div className="flex items-center gap-2 text-sm font-bold text-slate-900 pb-2 border-b border-slate-100">
                                <Lock className="w-4 h-4 text-amber-500" />
                                权限配置
                            </div>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                                <div>
                                    <SearchableSelect
                                        label="所属机构"
                                        icon={<div className="w-4 h-4 flex items-center justify-center font-bold text-xs">🏢</div>}
                                        options={safeOrgOptions}
                                        value={formData.orgName}
                                        onChange={(val) => setFormData({ ...formData, orgName: val })}
                                        onSearch={onOrgSearch}
                                        placeholder="输入关键字搜索机构..."
                                    />
                                </div>

                                <FormSelect
                                    label="关联角色"
                                    value={formData.roleId}
                                    onChange={e => {
                                        const selectedId = e.target.value; // Keep as string first
                                        // Use loose comparison or string conversion to find role
                                        const selectedRole = safeRoleOptions.find(r => String(r.id) === String(selectedId));
                                        setFormData({
                                            ...formData,
                                            roleId: Number(selectedId), // Still save as number if backend expects number
                                            roleName: selectedRole?.name || ''
                                        });
                                        if (!selectedRole && selectedId) {
                                            console.warn("Role not found for ID:", selectedId, "Available:", safeRoleOptions);
                                        }
                                    }}
                                    icon={<div className="w-4 h-4 flex items-center justify-center font-bold text-xs">👤</div>}
                                >
                                    {safeRoleOptions.length === 0 && <option value="">暂无角色选项</option>}
                                    {safeRoleOptions.map(opt => (
                                        <option key={opt.id} value={opt.id}>{opt.name}</option>
                                    ))}
                                </FormSelect>

                                <div className="md:col-span-2">
                                    <MultiSelect
                                        label="关联监管系统 (SSO)"
                                        options={safeSsoOptions}
                                        value={formData.ssoSystems}
                                        onChange={(val) => setFormData({ ...formData, ssoSystems: val })}
                                        placeholder="请选择需要关联的监管系统..."
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div className="flex items-center gap-2 text-sm font-bold text-slate-900 pb-2 border-b border-slate-100">
                                <GitBranch className="w-4 h-4 text-purple-500" />
                                Git 身份
                            </div>
                            <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
                                <FormInput
                                    label="GitLab 用户名"
                                    placeholder="如 liudan"
                                    value={formData.gitUsername}
                                    onChange={e => setFormData({ ...formData, gitUsername: e.target.value })}
                                    icon={<GitBranch className="w-4 h-4" />}
                                />
                                <FormInput
                                    label="提交邮箱"
                                    placeholder="如 liudan@example.com"
                                    value={formData.gitEmail}
                                    onChange={e => setFormData({ ...formData, gitEmail: e.target.value })}
                                />
                                <FormInput
                                    label="Git 用户ID"
                                    placeholder="平台用户ID，可选"
                                    value={formData.gitUserId}
                                    onChange={e => setFormData({ ...formData, gitUserId: e.target.value })}
                                />
                            </div>
                        </div>
                    </form>
                </div>

                <div className="px-6 py-4 border-t border-slate-100 bg-slate-50 rounded-b-xl flex justify-end gap-3">
                    <button onClick={onClose} className="px-5 py-2.5 text-sm font-bold text-slate-600 hover:bg-slate-200 rounded-lg transition-colors">
                        取消
                    </button>
                    <button form="userForm" type="submit" className="px-6 py-2.5 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg shadow-lg shadow-red-200 transition-transform hover:scale-[1.02] flex items-center gap-2">
                        <Save className="w-4 h-4" />
                        保存配置
                    </button>
                </div>
            </div>
        </div>
    );
};

const UserManagement: React.FC = () => {
    const EXCEL_COLUMNS = [
        { key: 'empId', label: '工号', required: true, description: '必填' },
        { key: 'name', label: '姓名', required: true, description: '必填' },
        { key: 'orgName', label: '所属机构', required: true, description: '必填，按机构名称匹配' },
        { key: 'roleName', label: '关联角色', required: true, description: '必填，按角色名称匹配' },
        { key: 'phone', label: '手机号', required: false, description: '可选' },
        { key: 'system', label: '关联系统', required: false, description: '可选，多个系统用英文逗号分隔' },
        { key: 'status', label: '状态', required: false, description: '可选：正常/停用，不填默认 正常' },
    ] as const;
    const EXCEL_LABEL_TO_KEY = EXCEL_COLUMNS.reduce((acc, column) => {
        acc[column.label] = column.key;
        return acc;
    }, {} as Record<string, typeof EXCEL_COLUMNS[number]['key']>);
    const REQUIRED_IMPORT_COLUMNS = EXCEL_COLUMNS.filter(column => column.required);
    const STATUS_ALIASES: Record<string, 'active' | 'inactive'> = {
        active: 'active',
        inactive: 'inactive',
        '正常': 'active',
        '停用': 'inactive',
    };

    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [orgOptions, setOrgOptions] = useState<string[]>([]);
    const [roleOptions, setRoleOptions] = useState<{ id: number; name: string }[]>([]); // Refactored to object array
    const [ssoOptions, setSsoOptions] = useState<string[]>([]);

    const [showForm, setShowForm] = useState(false);
    const [editingUser, setEditingUser] = useState<User | null>(null);
    const fileInputRef = React.useRef<HTMLInputElement>(null);

    const normalizeImportHeader = (header: string) => {
        return header
            .replace(/^\uFEFF/, '')
            .replace(/\*/g, '')
            .replace(/（必填）|\(必填\)/g, '')
            .replace(/\s+/g, '')
            .trim();
    };

    const normalizeStatus = (status?: string) => {
        const normalizedStatus = (status || '').trim();
        return STATUS_ALIASES[normalizedStatus] || 'active';
    };

    const formatImportError = (errors: string[]) => {
        const preview = errors.slice(0, 8);
        return preview.join('\n') + (errors.length > preview.length ? `\n...共 ${errors.length} 处错误` : '');
    };

    const parseWorksheetRows = (sheet: XLSX.WorkSheet) => {
        return XLSX.utils.sheet_to_json<(string | number | boolean | null)[]>(sheet, {
            header: 1,
            defval: '',
            raw: false,
        }).map(row => row.map(cell => String(cell ?? '').trim()));
    };

    const handleExport = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/users/export', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok) throw new Error('Export failed');
            const data = await res.json();
            const headers = EXCEL_COLUMNS.map(column => `${column.label}${column.required ? '*' : ''}`);
            const descriptionRow = EXCEL_COLUMNS.map(column => column.description);
            const rows = data.map((u: User) => [
                u.empId ?? '',
                u.name ?? '',
                u.orgName ?? '',
                u.roleName ?? '',
                u.phone ?? '',
                u.system || '',
                normalizeStatus(u.status) === 'inactive' ? '停用' : '正常'
            ]);
            const sheet = XLSX.utils.aoa_to_sheet([headers, descriptionRow, ...rows]);
            const workbook = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(workbook, sheet, '用户模板');
            XLSX.writeFile(workbook, `用户列表_${new Date().toLocaleDateString()}.xlsx`);
        } catch (err) {
            alert('导出失败，请重试');
        }
    };

    const handleImportClick = () => {
        fileInputRef.current?.click();
    };

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = async (event) => {
            try {
                let payload: any[] = [];

                if (file.name.endsWith('.json')) {
                    const text = event.target?.result as string;
                    payload = JSON.parse(text);
                } else if (file.name.endsWith('.xlsx') || file.name.endsWith('.xls')) {
                    const workbook = XLSX.read(event.target?.result, { type: 'array' });
                    const firstSheetName = workbook.SheetNames[0];
                    const firstSheet = workbook.Sheets[firstSheetName];
                    const rows = parseWorksheetRows(firstSheet).filter(row => row.some(cell => cell !== ''));

                    if (rows.length === 0) {
                        alert('导入文件为空');
                        return;
                    }

                    const headers = rows[0].map(normalizeImportHeader);
                    const missingHeaders = REQUIRED_IMPORT_COLUMNS
                        .map(column => column.label)
                        .filter(label => !headers.includes(label));

                    if (missingHeaders.length > 0) {
                        alert(`导入模板不正确，缺少表头：${missingHeaders.join('、')}`);
                        return;
                    }

                    const validationErrors: string[] = [];
                    payload = rows.slice(1).map((values, index) => {
                        const obj: any = {};
                        const rowNumber = index + 2;

                        headers.forEach((h, i) => {
                            const key = EXCEL_LABEL_TO_KEY[h];
                            if (!key) return;
                            obj[key] = values[i];
                        });

                        const isInstructionRow = EXCEL_COLUMNS.every(column => {
                            const cellValue = String(obj[column.key] ?? '').trim();
                            return !cellValue || cellValue.includes('必填') || cellValue.includes('可选');
                        });

                        if (isInstructionRow) {
                            return null;
                        }

                        obj.empId = String(obj.empId || '').trim();
                        obj.name = String(obj.name || '').trim();
                        obj.orgName = String(obj.orgName || '').trim();
                        obj.roleName = String(obj.roleName || '').trim();
                        obj.phone = String(obj.phone || '').trim();
                        obj.system = String(obj.system || '').trim();

                        const statusRaw = String(obj.status || '').trim();
                        if (statusRaw && !(statusRaw in STATUS_ALIASES)) {
                            validationErrors.push(`第 ${rowNumber} 行：状态只能填写“正常”或“停用”`);
                        }
                        obj.status = normalizeStatus(statusRaw);

                        if (!obj.empId) validationErrors.push(`第 ${rowNumber} 行：工号不能为空`);
                        if (!obj.name) validationErrors.push(`第 ${rowNumber} 行：姓名不能为空`);
                        if (!obj.orgName) validationErrors.push(`第 ${rowNumber} 行：所属机构不能为空`);
                        if (!obj.roleName) validationErrors.push(`第 ${rowNumber} 行：关联角色不能为空`);
                        if (obj.orgName && !orgOptions.includes(obj.orgName)) {
                            validationErrors.push(`第 ${rowNumber} 行：所属机构“${obj.orgName}”不存在`);
                        }
                        if (obj.roleName && !roleOptions.some(role => role.name === obj.roleName)) {
                            validationErrors.push(`第 ${rowNumber} 行：关联角色“${obj.roleName}”不存在`);
                        }

                        return obj;
                    }).filter(item => item !== null);

                    if (validationErrors.length > 0) {
                        alert(`导入失败，请先修正以下问题：\n${formatImportError(validationErrors)}`);
                        return;
                    }
                }

                if (payload.length === 0) {
                    alert('文件内容为空，或没有可导入的数据行');
                    return;
                }

                const normalizedPayload = payload.map(item => ({
                    empId: item.empId,
                    name: item.name,
                    orgName: item.orgName,
                    roleName: item.roleName,
                    roleId: roleOptions.find(role => role.name === item.roleName)?.id,
                    phone: item.phone || '',
                    system: item.system || '',
                    status: normalizeStatus(item.status),
                })).filter(item => item.empId && item.name && item.orgName && item.roleName);

                const token = localStorage.getItem('auth_token');
                const res = await fetch('/api/users/batch', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify(normalizedPayload)
                });

                if (!res.ok) throw new Error('Batch import failed');
                const result = await res.json();
                alert(
                    `导入完成：新增 ${result.inserted ?? 0} 条，更新 ${result.updated ?? 0} 条，跳过 ${result.skipped ?? 0} 条`
                );
                await fetchUsers();
            } catch (err) {
                console.error(err);
                alert('解析或导入失败，请检查 Excel 模板表头、必填项和字段格式');
            }
            // Reset input
            if (fileInputRef.current) fileInputRef.current.value = '';
        };
        if (file.name.endsWith('.json')) {
            reader.readAsText(file);
        } else {
            reader.readAsArrayBuffer(file);
        }
    };

    // Filter & Pagination State
    const [searchTerm, setSearchTerm] = useState('');
    const [filterOrg, setFilterOrg] = useState('all');
    const [filterRole, setFilterRole] = useState('all');
    const [filterStatus, setFilterStatus] = useState('all');
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

    const fetchOrgRoleOptions = async (orgKeyword = '') => {
        try {
            const token = localStorage.getItem('auth_token');
            const headers = { 'Authorization': `Bearer ${token}` };
            const [orgRes, roleRes, ssoRes] = await Promise.all([
                fetch(`/api/orgs${orgKeyword ? `?keyword=${encodeURIComponent(orgKeyword)}` : ''}`, { headers }),
                fetch('/api/roles', { headers }),
                fetch('/api/system?showAll=true', { headers })
            ]);
            if (orgRes.ok) {
                const orgs = await orgRes.json();
                setOrgOptions(orgs.map((o: any) => o.name));
            }
            if (roleRes.ok) {
                const roles = await roleRes.json();
                setRoleOptions(roles.map((r: any) => ({ id: r.id, name: r.name }))); // Store ID and Name
            }
            if (ssoRes.ok) {
                const ssos = await ssoRes.json();
                setSsoOptions(ssos.map((s: any) => s.name));
            }
        } catch (err) {
            // ignore
        }
    };

    const fetchUsers = async () => {
        setLoading(true);
        setError(null);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/users', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok) throw new Error(`load users failed: ${res.status}`);
            const data = await res.json();
            setUsers(data);
        } catch (err) {
            setError('用户列表获取失败，请稍后重试');
            // Fallback mock data if API fails
            setUsers([
                { id: '1', name: '张三', empId: '1001', orgName: '总行', roleName: '系统管理员', phone: '13800138000', lastLogin: '2023-11-25 10:00', status: 'active' },
                { id: '2', name: '李四', empId: '1002', orgName: '北京分行', roleName: '业务主管', phone: '13900139000', lastLogin: '2023-11-24 15:30', status: 'active' },
                { id: '3', name: '王五', empId: '1003', orgName: '上海分行', roleName: '普通用户', phone: '13700137000', lastLogin: '2023-11-20 09:15', status: 'inactive' },
                // Add more mock data for pagination testing
                ...Array.from({ length: 25 }).map((_, i) => ({
                    id: `${i + 4}`,
                    name: `测试用户${i + 1}`,
                    empId: `${2000 + i}`,
                    orgName: i % 2 === 0 ? '总行' : '深圳分行',
                    roleName: '普通用户',
                    phone: `1360000${2000 + i}`,
                    lastLogin: '-',
                    status: i % 3 === 0 ? 'inactive' : 'active' as 'active' | 'inactive'
                }))
            ]);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchUsers();
        fetchOrgRoleOptions();
    }, []);

    // Filtering Logic
    const filteredUsers = useMemo(() => {
        const normalizedSearchTerm = searchTerm.replace(/\s+/g, '').toLowerCase();
        return users.filter(user => {
            const matchesSearch = !normalizedSearchTerm
                || user.name.toLowerCase().includes(normalizedSearchTerm)
                || user.empId.toLowerCase().includes(normalizedSearchTerm)
                || (user.gitUsername || '').toLowerCase().includes(normalizedSearchTerm)
                || (user.gitEmail || '').toLowerCase().includes(normalizedSearchTerm)
                || user.namePinyin?.includes(normalizedSearchTerm)
                || user.namePinyinInitials?.includes(normalizedSearchTerm);
            const matchesOrg = filterOrg === 'all' || user.orgName === filterOrg;
            const matchesRole = filterRole === 'all' || user.roleName === filterRole;
            const matchesStatus = filterStatus === 'all' || user.status === filterStatus;
            return matchesSearch && matchesOrg && matchesRole && matchesStatus;
        });
    }, [users, searchTerm, filterOrg, filterRole, filterStatus]);

    // Pagination Logic
    const totalPages = Math.ceil(filteredUsers.length / pageSize);
    const paginatedUsers = useMemo(() => {
        const start = (currentPage - 1) * pageSize;
        return filteredUsers.slice(start, start + pageSize);
    }, [filteredUsers, currentPage, pageSize]);

    // Reset page when filters change
    useEffect(() => {
        setCurrentPage(1);
        setSelectedIds(new Set());
    }, [searchTerm, filterOrg, filterRole, filterStatus, pageSize]);

    const handleAdd = () => {
        setEditingUser(null);
        setShowForm(true);
    };

    const handleEdit = (user: User) => {
        setEditingUser(user);
        setShowForm(true);
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm('确认删除该用户吗？')) return;
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/users/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok && res.status !== 204) throw new Error('delete failed');
            await fetchUsers();
        } catch (err) {
            setError('删除用户失败，请稍后重试');
            // Mock delete
            setUsers(prev => prev.filter(u => u.id !== id));
        }
    };

    const handleSave = async (userData: Omit<User, 'id' | 'lastLogin'> & { id?: string }) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const readErrorMessage = async (res: Response, fallback: string) => {
                const text = await res.text();
                if (!text) return fallback;
                try {
                    const data = JSON.parse(text);
                    return data.message || data.error || fallback;
                } catch (e) {
                    return text;
                }
            };
            if (userData.id) {
                // Update existing user
                const res = await fetch(`/api/users/${userData.id}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify(userData)
                });
                if (!res.ok) throw new Error(await readErrorMessage(res, '保存失败，请稍后重试'));
            } else {
                // Create new user with default password
                const res = await fetch('/api/users', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify({ ...userData, password: '123456' })
                });
                if (!res.ok) throw new Error(await readErrorMessage(res, '保存失败，请稍后重试'));
            }
            await fetchUsers();
            setShowForm(false);
        } catch (err: any) {
            console.error(err);
            alert(err?.message || '保存失败，请稍后重试');
        } finally {
            setLoading(false);
        }
    };

    // Batch Operations
    const toggleSelectAll = () => {
        if (selectedIds.size === paginatedUsers.length && paginatedUsers.length > 0) {
            setSelectedIds(new Set());
        } else {
            setSelectedIds(new Set(paginatedUsers.map(u => u.id)));
        }
    };

    const toggleSelect = (id: string) => {
        const newSet = new Set(selectedIds);
        if (newSet.has(id)) newSet.delete(id);
        else newSet.add(id);
        setSelectedIds(newSet);
    };

    const handleBatchDelete = () => {
        if (!window.confirm(`确认删除选中的 ${selectedIds.size} 个用户吗？`)) return;
        // Mock batch delete
        setUsers(prev => prev.filter(u => !selectedIds.has(u.id)));
        setSelectedIds(new Set());
    };

    const handleBatchStatus = (status: 'active' | 'inactive') => {
        // Mock batch update
        setUsers(prev => prev.map(u => selectedIds.has(u.id) ? { ...u, status } : u));
        setSelectedIds(new Set());
    };

    const handleResetPassword = async (id: string) => {
        if (!window.confirm('确认重置该用户的密码吗？重置后密码将变为 123456')) return;
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/users/${id}/reset-password`, {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok) throw new Error('Reset failed');
            alert('密码已成功重置为 123456');
        } catch (err) {
            console.error(err);
            // Fallback for demo
            alert(`(模拟) 用户 ${id} 密码已重置为默认密码 123456`);
        }
    };

    const activeFilterCount = [filterOrg, filterRole, filterStatus].filter(v => v !== 'all').length;

    return (
        <div className="space-y-4 animate-fade-in relative">
            {/* === 顶部标题栏 === */}
            <div className="bg-white rounded-lg border border-slate-200 px-5 py-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <h2 className="text-lg font-bold text-slate-800">用户列表</h2>
                    <span className="text-xs text-slate-400 bg-slate-50 px-2 py-1 rounded border border-slate-100 font-mono hidden lg:inline">
                        sys:user:*
                    </span>
                </div>
                <div className="flex items-center gap-2">
                    <button
                        onClick={handleExport}
                        className="flex items-center gap-1.5 px-3 py-2 text-sm text-slate-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors font-medium"
                        title="导出全量数据"
                    >
                        <Download className="w-4 h-4" />
                        <span className="hidden sm:inline">导出</span>
                    </button>
                    <button
                        onClick={handleImportClick}
                        className="flex items-center gap-1.5 px-3 py-2 text-sm text-slate-600 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors font-medium"
                        title="批量导入"
                    >
                        <Upload className="w-4 h-4" />
                        <span className="hidden sm:inline">导入</span>
                    </button>
                    <input
                        type="file"
                        ref={fileInputRef}
                        onChange={handleFileChange}
                        accept=".xlsx,.xls,.json"
                        className="hidden"
                    />
                    <Auth code="sys:user:add">
                        <button
                            onClick={handleAdd}
                            className="flex items-center gap-1.5 px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-lg hover:bg-red-700 transition-colors shadow-sm shadow-red-200"
                        >
                            <Plus className="w-4 h-4" />
                            <span className="hidden sm:inline">新增用户</span>
                        </button>
                    </Auth>
                </div>
            </div>

            {/* === 搜索 & 筛选栏 === */}
            <div className="bg-white rounded-lg border border-slate-200 px-5 py-3 flex flex-col sm:flex-row items-start sm:items-center gap-3">
                <div className="relative flex-1 w-full sm:max-w-sm">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <input
                        type="text"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        placeholder="输入工号/姓名搜索..."
                        className="w-full pl-9 pr-3 py-2 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-red-500/20 focus:border-red-500 outline-none bg-slate-50 hover:bg-white transition-colors"
                    />
                    {searchTerm && (
                        <button
                            onClick={() => setSearchTerm('')}
                            className="absolute right-2.5 top-1/2 -translate-y-1/2 p-0.5 text-slate-400 hover:text-slate-600"
                        >
                            <X className="w-3.5 h-3.5" />
                        </button>
                    )}
                </div>

                <div className="hidden sm:block w-px h-6 bg-slate-200 self-center" />

                <div className="flex items-center gap-2 flex-wrap">
                    <div className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-50 rounded-lg border border-slate-200 text-sm">
                        <Filter className="w-3.5 h-3.5 text-slate-400" />
                        <select
                            value={filterOrg}
                            onChange={e => setFilterOrg(e.target.value)}
                            className="bg-transparent text-slate-600 outline-none text-sm min-w-[100px] cursor-pointer"
                        >
                            <option value="all">所有机构</option>
                            {orgOptions.map(o => <option key={o} value={o}>{o}</option>)}
                        </select>
                    </div>
                    <div className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-50 rounded-lg border border-slate-200 text-sm">
                        <Shield className="w-3.5 h-3.5 text-slate-400" />
                        <select
                            value={filterRole}
                            onChange={e => setFilterRole(e.target.value)}
                            className="bg-transparent text-slate-600 outline-none text-sm min-w-[100px] cursor-pointer"
                        >
                            <option value="all">所有角色</option>
                            {roleOptions.map(r => <option key={r.id.toString()} value={r.name}>{r.name}</option>)}
                        </select>
                    </div>
                    <select
                        value={filterStatus}
                        onChange={e => setFilterStatus(e.target.value)}
                        className="px-3 py-1.5 bg-slate-50 rounded-lg border border-slate-200 text-sm text-slate-600 outline-none cursor-pointer"
                    >
                        <option value="all">所有状态</option>
                        <option value="active">正常</option>
                        <option value="inactive">停用</option>
                    </select>
                    {activeFilterCount > 0 && (
                        <button
                            onClick={() => { setFilterOrg('all'); setFilterRole('all'); setFilterStatus('all'); setSearchTerm(''); }}
                            className="text-xs text-red-500 hover:text-red-700 font-medium px-2 py-1"
                        >
                            清除筛选 ({activeFilterCount})
                        </button>
                    )}
                </div>
            </div>

            {/* === 批量操作栏 === */}
            {selectedIds.size > 0 && (
                <div className="bg-red-50 border border-red-100 px-4 py-3 rounded-lg flex items-center justify-between animate-fade-in">
                    <span className="text-sm text-red-800 font-medium">已选择 {selectedIds.size} 项</span>
                    <div className="flex gap-2">
                        <Auth code="sys:user:edit">
                            <button onClick={() => handleBatchStatus('active')} className="px-3 py-1.5 text-xs font-medium bg-white text-green-700 border border-green-200 rounded-lg hover:bg-green-50 transition-colors">批量启用</button>
                            <button onClick={() => handleBatchStatus('inactive')} className="px-3 py-1.5 text-xs font-medium bg-white text-slate-700 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">批量停用</button>
                        </Auth>
                        <Auth code="sys:user:del">
                            <button onClick={handleBatchDelete} className="px-3 py-1.5 text-xs font-medium bg-white text-red-700 border border-red-200 rounded-lg hover:bg-red-50 transition-colors">批量删除</button>
                        </Auth>
                    </div>
                </div>
            )}

            {/* === 错误提示 === */}
            {error && (
                <div className="flex items-center gap-2 text-sm text-red-600 bg-red-50 border border-red-200 px-4 py-3 rounded-lg">
                    <Ban className="w-4 h-4 flex-shrink-0" />
                    {error}
                </div>
            )}

            {/* === 数据表格 === */}
            <div className="bg-white rounded-lg border border-slate-200 overflow-hidden shadow-sm">
                <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                        <thead>
                            <tr className="bg-slate-50/80 border-b border-slate-200">
                                <th className="pl-5 pr-2 py-3.5 w-10">
                                    <div className="flex items-center justify-center cursor-pointer" onClick={toggleSelectAll}>
                                        {selectedIds.size === paginatedUsers.length && paginatedUsers.length > 0 ?
                                            <CheckSquare className="w-4 h-4 text-red-600" /> :
                                            <Square className="w-4 h-4 text-slate-300" />
                                        }
                                    </div>
                                </th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">工号</th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">姓名</th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">所属机构</th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">关联角色</th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">手机号</th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">关联系统</th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Git 身份</th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">最后登录</th>
                                <th className="px-3 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">状态</th>
                                <th className="px-3 pr-5 py-3.5 text-right text-xs font-semibold text-slate-500 uppercase tracking-wide">操作</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-50">
                            {loading ? (
                                Array.from({ length: 5 }).map((_, i) => (
                                    <tr key={i} className="animate-pulse">
                                        <td className="pl-5 pr-2 py-4"><div className="h-4 w-4 bg-slate-100 rounded" /></td>
                                        <td className="px-3 py-4"><div className="h-4 w-14 bg-slate-100 rounded" /></td>
                                        <td className="px-3 py-4"><div className="flex items-center gap-2"><div className="h-8 w-8 rounded-full bg-slate-100" /><div className="h-4 w-16 bg-slate-100 rounded" /></div></td>
                                        <td className="px-3 py-4"><div className="h-4 w-20 bg-slate-100 rounded" /></td>
                                        <td className="px-3 py-4"><div className="h-5 w-16 bg-slate-100 rounded" /></td>
                                        <td className="px-3 py-4"><div className="h-4 w-24 bg-slate-100 rounded" /></td>
                                        <td className="px-3 py-4"><div className="h-4 w-16 bg-slate-100 rounded" /></td>
                                        <td className="px-3 py-4"><div className="h-4 w-20 bg-slate-100 rounded" /></td>
                                        <td className="px-3 py-4"><div className="h-4 w-28 bg-slate-100 rounded" /></td>
                                        <td className="px-3 py-4"><div className="h-5 w-10 bg-slate-100 rounded-full" /></td>
                                        <td className="px-3 pr-5 py-4"><div className="h-6 w-20 bg-slate-100 rounded ml-auto" /></td>
                                    </tr>
                                ))
                            ) : paginatedUsers.length === 0 ? (
                                <tr>
                                    <td colSpan={11} className="py-24 text-center">
                                        <div className="flex flex-col items-center gap-3">
                                            <div className="bg-slate-50 p-4 rounded-full">
                                                <Search className="w-8 h-8 text-slate-300" />
                                            </div>
                                            <p className="text-slate-400 text-sm">没有找到匹配的用户数据</p>
                                            {activeFilterCount > 0 && (
                                                <button
                                                    onClick={() => { setFilterOrg('all'); setFilterRole('all'); setFilterStatus('all'); setSearchTerm(''); }}
                                                    className="text-xs text-red-500 hover:text-red-700 font-medium"
                                                >
                                                    清除所有筛选条件
                                                </button>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ) : (
                                paginatedUsers.map((user) => (
                                    <tr key={user.id} className={`hover:bg-slate-50/80 transition-colors ${selectedIds.has(user.id) ? 'bg-red-50/30' : ''}`}>
                                        <td className="pl-5 pr-2 py-3.5">
                                            <div className="flex items-center justify-center cursor-pointer" onClick={() => toggleSelect(user.id)}>
                                                {selectedIds.has(user.id) ?
                                                    <CheckSquare className="w-4 h-4 text-red-600" /> :
                                                    <Square className="w-4 h-4 text-slate-300 hover:text-slate-400" />
                                                }
                                            </div>
                                        </td>
                                        <td className="px-3 py-3.5">
                                            <span className="text-slate-500 font-mono text-xs">{user.empId}</span>
                                        </td>
                                        <td className="px-3 py-3.5">
                                            <div className="flex items-center gap-2.5">
                                                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-slate-100 to-slate-200 flex items-center justify-center text-slate-500 flex-shrink-0">
                                                    <UserCircle size={18} />
                                                </div>
                                                <span className="font-medium text-slate-800">{user.name}</span>
                                            </div>
                                        </td>
                                        <td className="px-3 py-3.5 text-slate-600">{user.orgName}</td>
                                        <td className="px-3 py-3.5">
                                            <span className="inline-flex px-2 py-0.5 rounded-md text-xs font-medium bg-slate-100 text-slate-600 border border-slate-200">
                                                {user.roleName}
                                            </span>
                                        </td>
                                        <td className="px-3 py-3.5 text-slate-500 text-xs font-mono">{user.phone || '-'}</td>
                                        <td className="px-3 py-3.5">
                                            {user.system ? (() => {
                                                const systems = user.system.split(',').filter(Boolean);
                                                if (systems.length === 0) return <span className="text-slate-400 text-xs">-</span>;
                                                const displayLimit = 2;
                                                const visibleSystems = systems.slice(0, displayLimit);
                                                const remainingCount = systems.length - displayLimit;
                                                return (
                                                    <div className="flex flex-wrap items-center gap-1">
                                                        {visibleSystems.map((sso, idx) => (
                                                            <span key={sso + idx} className="inline-flex px-2 py-0.5 rounded text-xs bg-blue-50 text-blue-700 border border-blue-100">
                                                                {sso}
                                                            </span>
                                                        ))}
                                                        {remainingCount > 0 && (
                                                            <span className="inline-flex px-2 py-0.5 rounded text-xs bg-slate-100 text-slate-600 border border-slate-200 cursor-help font-medium hover:bg-slate-200 transition-colors" title={systems.join('\n')}>
                                                                +{remainingCount}
                                                            </span>
                                                        )}
                                                    </div>
                                                );
                                            })() : <span className="text-slate-400 text-xs">-</span>}
                                        </td>
                                        <td className="px-3 py-3.5">
                                            {(user.gitUsername || user.gitEmail || user.gitUserId) ? (
                                                <div className="space-y-0.5 text-xs">
                                                    {user.gitUsername && <div className="font-mono text-purple-700">{user.gitUsername}</div>}
                                                    {user.gitEmail && <div className="font-mono text-slate-500">{user.gitEmail}</div>}
                                                    {!user.gitUsername && user.gitUserId && <div className="font-mono text-slate-500">ID: {user.gitUserId}</div>}
                                                </div>
                                            ) : (
                                                <span className="text-slate-400 text-xs">-</span>
                                            )}
                                        </td>
                                        <td className="px-3 py-3.5 text-slate-400 text-xs font-mono">{user.lastLogin || '-'}</td>
                                        <td className="px-3 py-3.5">
                                            {user.status === 'active' ? (
                                                <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 border border-emerald-100">
                                                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                                                    正常
                                                </span>
                                            ) : (
                                                <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-500 border border-slate-200">
                                                    <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
                                                    停用
                                                </span>
                                            )}
                                        </td>
                                        <td className="px-3 pr-5 py-3.5">
                                            <div className="flex items-center justify-end gap-1">
                                                <Auth code="sys:user:edit">
                                                    <button
                                                        onClick={() => handleResetPassword(user.id)}
                                                        className="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                                                        title="重置密码"
                                                    >
                                                        <Lock size={15} />
                                                    </button>
                                                    <button
                                                        onClick={() => handleEdit(user)}
                                                        className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                                        title="编辑用户"
                                                    >
                                                        <Edit size={15} />
                                                    </button>
                                                </Auth>
                                                <Auth code="sys:user:del">
                                                    <button
                                                        onClick={() => handleDelete(user.id)}
                                                        className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                                        title="删除用户"
                                                    >
                                                        <Trash2 size={15} />
                                                    </button>
                                                </Auth>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>

                {/* === 分页栏 === */}
                <div className="px-5 py-3 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-3">
                    <div className="flex items-center gap-4 text-xs text-slate-500">
                        <span>共 <span className="font-semibold text-slate-700">{filteredUsers.length}</span> 条记录</span>
                        <div className="flex items-center gap-1.5">
                            <span>每页</span>
                            <select
                                value={pageSize}
                                onChange={(e) => setPageSize(Number(e.target.value))}
                                className="border border-slate-200 rounded-md px-2 py-1 bg-slate-50 text-slate-600 outline-none focus:border-red-400 text-xs cursor-pointer"
                            >
                                <option value={10}>10</option>
                                <option value={20}>20</option>
                                <option value={50}>50</option>
                            </select>
                            <span>条</span>
                        </div>
                    </div>

                    <div className="flex items-center gap-1">
                        <button
                            onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                            disabled={currentPage === 1}
                            className="p-1.5 rounded-md border border-slate-200 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-slate-600"
                        >
                            <ChevronLeft size={14} />
                        </button>

                        {(() => {
                            const pages: (number | '...')[] = [];
                            if (totalPages <= 7) {
                                for (let i = 1; i <= totalPages; i++) pages.push(i);
                            } else {
                                pages.push(1);
                                if (currentPage > 3) pages.push('...');
                                const start = Math.max(2, currentPage - 1);
                                const end = Math.min(totalPages - 1, currentPage + 1);
                                for (let i = start; i <= end; i++) pages.push(i);
                                if (currentPage < totalPages - 2) pages.push('...');
                                pages.push(totalPages);
                            }
                            return pages.map((p, i) =>
                                p === '...' ? (
                                    <span key={`dots-${i}`} className="px-1.5 text-slate-400 text-xs">...</span>
                                ) : (
                                    <button
                                        key={p}
                                        onClick={() => setCurrentPage(p)}
                                        className={`min-w-[32px] h-8 rounded-md text-xs font-medium transition-colors ${currentPage === p ? 'bg-red-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100'}`}
                                    >
                                        {p}
                                    </button>
                                )
                            );
                        })()}

                        <button
                            onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                            disabled={currentPage === totalPages || totalPages === 0}
                            className="p-1.5 rounded-md border border-slate-200 hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-slate-600"
                        >
                            <ChevronRight size={14} />
                        </button>
                    </div>
                </div>
            </div>

            {/* === 新增/编辑弹窗 === */}
            {showForm && (
                <UserForm
                    initialData={editingUser}
                    orgOptions={orgOptions}
                    roleOptions={roleOptions}
                    ssoOptions={ssoOptions}
                    onOrgSearch={(kw) => fetchOrgRoleOptions(kw)}
                    onClose={() => { setShowForm(false); setEditingUser(null); }}
                    onSave={handleSave}
                />
            )}
        </div>
    );
};

export default UserManagement;
