import React, { useState, useEffect, useMemo } from 'react';
import { UserCircle, Edit, Trash2, Save, X, Filter, ChevronLeft, ChevronRight, Lock, Shield, Ban, CheckSquare, Square, Search } from 'lucide-react';
import { User } from './types';
import { ActionToolbar } from './Shared';
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
        roleId: initialData?.roleId || (safeRoleOptions[0]?.id || ''), // Use roleId
        roleName: initialData?.roleName || (safeRoleOptions[0]?.name || ''),
        ssoSystems: initialData?.system ? initialData.system.split(',').filter(Boolean) : [],
        phone: initialData?.phone || '',
        status: initialData?.status || 'active',
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSave({ ...formData, id: initialData?.id, system: formData.ssoSystems.join(',') });
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
                                        const selectedId = Number(e.target.value);
                                        const selectedRole = safeRoleOptions.find(r => r.id === selectedId);
                                        setFormData({
                                            ...formData,
                                            roleId: selectedId,
                                            roleName: selectedRole?.name || ''
                                        });
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
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [orgOptions, setOrgOptions] = useState<string[]>([]);
    const [roleOptions, setRoleOptions] = useState<{ id: number; name: string }[]>([]); // Refactored to object array
    const [ssoOptions, setSsoOptions] = useState<string[]>([]);

    const [showForm, setShowForm] = useState(false);
    const [editingUser, setEditingUser] = useState<User | null>(null);

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
                fetch('/api/system', { headers })
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
            if (res.status === 401) {
                localStorage.removeItem('auth_token');
                localStorage.removeItem('auth_user');
                window.location.href = '/login';
                return;
            }
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
        return users.filter(user => {
            const matchesSearch = user.name.includes(searchTerm) || user.empId.includes(searchTerm);
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
                if (!res.ok) throw new Error('Update failed');
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
                if (!res.ok) throw new Error('Create failed');
            }
            await fetchUsers();
            setShowForm(false);
        } catch (err) {
            console.error(err);
            alert('保存失败，请稍后重试');
            // Fallback for demo/mock environment if API fails
            if (userData.id) {
                setUsers(prev => prev.map(u => u.id === userData.id ? { ...u, ...userData, lastLogin: u.lastLogin } : u));
            } else {
                setUsers(prev => [...prev, { ...userData, id: Date.now().toString(), lastLogin: '-' } as User]);
            }
            setShowForm(false);
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

    return (
        <div className="space-y-4 animate-fade-in relative">
            <ActionToolbar
                title="用户列表"
                placeholder="输入工号/姓名搜索..."
                codePrefix="sys:user"
                onAdd={handleAdd}
                className="mb-0"
            >
                {/* Custom Filters */}
                <div className="flex items-center gap-2">
                    <div className="relative">
                        <Filter className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400" />
                        <select
                            value={filterOrg}
                            onChange={e => setFilterOrg(e.target.value)}
                            className="pl-8 pr-3 py-2 border border-slate-200 rounded-md text-sm focus:ring-2 focus:ring-red-500 outline-none bg-slate-50 hover:bg-white transition-colors min-w-[120px]"
                        >
                            <option value="all">所有机构</option>
                            {orgOptions.map(o => <option key={o} value={o}>{o}</option>)}
                        </select>
                    </div>
                    <div className="relative">
                        <Shield className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400" />
                        <select
                            value={filterRole}
                            onChange={e => setFilterRole(e.target.value)}
                            className="pl-8 pr-3 py-2 border border-slate-200 rounded-md text-sm focus:ring-2 focus:ring-red-500 outline-none bg-slate-50 hover:bg-white transition-colors min-w-[120px]"
                        >
                            <option value="all">所有角色</option>
                            {roleOptions.map(r => <option key={r.id.toString()} value={r.name}>{r.name}</option>)}
                        </select>
                    </div>
                    <select
                        value={filterStatus}
                        onChange={e => setFilterStatus(e.target.value)}
                        className="px-3 py-2 border border-slate-200 rounded-md text-sm focus:ring-2 focus:ring-red-500 outline-none bg-slate-50 hover:bg-white transition-colors"
                    >
                        <option value="all">所有状态</option>
                        <option value="active">正常</option>
                        <option value="inactive">停用</option>
                    </select>
                </div>
            </ActionToolbar>

            {/* Batch Action Bar */}
            {selectedIds.size > 0 && (
                <div className="bg-red-50 border border-red-100 px-4 py-2 rounded-lg flex items-center justify-between animate-fade-in">
                    <span className="text-sm text-red-800 font-medium">已选择 {selectedIds.size} 项</span>
                    <div className="flex gap-2">
                        <Auth code="sys:user:edit">
                            <button onClick={() => handleBatchStatus('active')} className="px-3 py-1.5 text-xs bg-white text-green-700 border border-green-200 rounded hover:bg-green-50">批量启用</button>
                            <button onClick={() => handleBatchStatus('inactive')} className="px-3 py-1.5 text-xs bg-white text-slate-700 border border-slate-200 rounded hover:bg-slate-50">批量停用</button>
                        </Auth>
                        <Auth code="sys:user:del">
                            <button onClick={handleBatchDelete} className="px-3 py-1.5 text-xs bg-white text-red-700 border border-red-200 rounded hover:bg-red-50">批量删除</button>
                        </Auth>
                    </div>
                </div>
            )}

            {error && (
                <div className="text-sm text-red-600 bg-red-50 border border-red-200 px-3 py-2 rounded">{error}</div>
            )}

            <div className="bg-white rounded-lg border border-slate-200 overflow-hidden shadow-sm">
                <div className="overflow-x-auto min-h-[400px]">
                    <table className="w-full text-sm text-left">
                        <thead className="bg-slate-50 text-slate-700 font-semibold border-b border-slate-200">
                            <tr>
                                <th className="px-4 py-4 w-10">
                                    <div className="flex items-center justify-center cursor-pointer" onClick={toggleSelectAll}>
                                        {selectedIds.size === paginatedUsers.length && paginatedUsers.length > 0 ?
                                            <CheckSquare className="w-4 h-4 text-red-600" /> :
                                            <Square className="w-4 h-4 text-slate-300" />
                                        }
                                    </div>
                                </th>
                                <th className="px-4 py-4 whitespace-nowrap">工号</th>
                                <th className="px-4 py-4 whitespace-nowrap">姓名</th>
                                <th className="px-4 py-4 whitespace-nowrap">所属机构</th>
                                <th className="px-4 py-4 whitespace-nowrap">关联角色</th>
                                <th className="px-4 py-4 whitespace-nowrap">手机号</th>
                                <th className="px-4 py-4 whitespace-nowrap">关联系统</th>
                                <th className="px-4 py-4 whitespace-nowrap">最后登录</th>
                                <th className="px-4 py-4 whitespace-nowrap">状态</th>
                                <th className="px-4 py-4 whitespace-nowrap text-right">操作</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {loading ? (
                                // Skeleton Loading
                                Array.from({ length: 5 }).map((_, i) => (
                                    <tr key={i}>
                                        <td className="px-4 py-4"><div className="h-4 w-4 bg-slate-100 rounded animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-4 w-16 bg-slate-100 rounded animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-4 w-20 bg-slate-100 rounded animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-4 w-24 bg-slate-100 rounded animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-4 w-20 bg-slate-100 rounded animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-4 w-24 bg-slate-100 rounded animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-4 w-16 bg-slate-100 rounded animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-4 w-32 bg-slate-100 rounded animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-6 w-12 bg-slate-100 rounded-full animate-pulse"></div></td>
                                        <td className="px-4 py-4"><div className="h-6 w-20 bg-slate-100 rounded ml-auto animate-pulse"></div></td>
                                    </tr>
                                ))
                            ) : paginatedUsers.length === 0 ? (
                                <tr>
                                    <td colSpan={10} className="py-20 text-center text-slate-400 flex flex-col items-center justify-center">
                                        <div className="bg-slate-50 p-4 rounded-full mb-3">
                                            <Search className="w-8 h-8 text-slate-300" />
                                        </div>
                                        <p>没有找到匹配的用户数据</p>
                                    </td>
                                </tr>
                            ) : (
                                paginatedUsers.map((user) => (
                                    <tr key={user.id} className={`hover:bg-slate-50 transition-colors ${selectedIds.has(user.id) ? 'bg-red-50/30' : ''}`}>
                                        <td className="px-4 py-4">
                                            <div className="flex items-center justify-center cursor-pointer" onClick={() => toggleSelect(user.id)}>
                                                {selectedIds.has(user.id) ?
                                                    <CheckSquare className="w-4 h-4 text-red-600" /> :
                                                    <Square className="w-4 h-4 text-slate-300 hover:text-slate-400" />
                                                }
                                            </div>
                                        </td>
                                        <td className="px-4 py-4 text-slate-500 font-mono">{user.empId}</td>
                                        <td className="px-4 py-4 text-slate-900 font-bold flex items-center gap-2">
                                            <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
                                                <UserCircle size={20} />
                                            </div>
                                            {user.name}
                                        </td>
                                        <td className="px-4 py-4 text-slate-600">{user.orgName}</td>
                                        <td className="px-4 py-4 text-slate-600">
                                            <span className="bg-slate-100 text-slate-600 px-2 py-1 rounded text-xs border border-slate-200">
                                                {user.roleName}
                                            </span>
                                        </td>
                                        <td className="px-4 py-4 text-slate-500 font-mono text-xs">{user.phone}</td>
                                        <td className="px-4 py-4 text-slate-500 text-xs">
                                            {user.system ? user.system.split(',').filter(Boolean).map((sso, idx) => (
                                                <span key={sso + idx} className="inline-flex items-center px-2 py-1 rounded bg-blue-50 text-blue-700 border border-blue-100 mr-1 mb-1">
                                                    {sso}
                                                </span>
                                            )) : <span className="text-slate-400">未关联</span>}
                                        </td>
                                        <td className="px-4 py-4 text-slate-400 text-xs font-mono">{user.lastLogin}</td>
                                        <td className="px-4 py-4">
                                            {user.status === 'active' ? (
                                                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 border border-green-200">
                                                    正常
                                                </span>
                                            ) : (
                                                <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-500 border border-slate-200">
                                                    停用
                                                </span>
                                            )}
                                        </td>
                                        <td className="px-4 py-4 text-right">
                                            <div className="flex items-center justify-end gap-2">
                                                <Auth code="sys:user:edit">
                                                    <button
                                                        onClick={() => handleResetPassword(user.id)}
                                                        className="p-1.5 text-slate-400 hover:text-amber-600 bg-slate-100 hover:bg-amber-50 rounded transition-colors"
                                                        title="重置密码"
                                                    >
                                                        <Lock size={14} />
                                                    </button>
                                                    <button
                                                        onClick={() => handleEdit(user)}
                                                        className="p-1.5 text-slate-400 hover:text-blue-600 bg-slate-100 hover:bg-blue-50 rounded transition-colors"
                                                        title="编辑用户"
                                                    >
                                                        <Edit size={14} />
                                                    </button>
                                                </Auth>
                                                <Auth code="sys:user:del">
                                                    <button
                                                        onClick={() => handleDelete(user.id)}
                                                        className="p-1.5 text-slate-400 hover:text-red-600 bg-slate-100 hover:bg-red-50 rounded transition-colors"
                                                        title="删除用户"
                                                    >
                                                        <Trash2 size={14} />
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

                {/* Pagination Footer */}
                <div className="px-6 py-4 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-500 gap-4">
                    <div className="flex items-center gap-4">
                        <span>共 {filteredUsers.length} 条数据</span>
                        <select
                            value={pageSize}
                            onChange={(e) => setPageSize(Number(e.target.value))}
                            className="border border-slate-200 rounded px-2 py-1 bg-slate-50 outline-none focus:border-red-500"
                        >
                            <option value={10}>10 条/页</option>
                            <option value={20}>20 条/页</option>
                            <option value={50}>50 条/页</option>
                        </select>
                    </div>

                    <div className="flex items-center gap-2">
                        <button
                            onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                            disabled={currentPage === 1}
                            className="p-1.5 border border-slate-200 rounded hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            <ChevronLeft size={14} />
                        </button>
                        <span className="mx-2">
                            第 <span className="font-bold text-slate-700">{currentPage}</span> / {totalPages || 1} 页
                        </span>
                        <button
                            onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                            disabled={currentPage === totalPages || totalPages === 0}
                            className="p-1.5 border border-slate-200 rounded hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            <ChevronRight size={14} />
                        </button>
                    </div>
                </div>
            </div>

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
