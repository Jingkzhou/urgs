import React, { useState, useEffect, useMemo } from 'react';
import { Edit, Trash2, Save, X } from 'lucide-react';
import { SsoConfig } from './types';
import { ActionToolbar } from './Shared';
import { IconRegistry, getIcon } from '../../utils/icons';
import Auth from '../Auth';
import Pagination from '../common/Pagination';

const SsoForm: React.FC<{
    initialData?: SsoConfig | null;
    onClose: () => void;
    onSave: (payload: Partial<SsoConfig> & { id?: string }) => void;
}> = ({ initialData, onClose, onSave }) => {
    const [formData, setFormData] = useState({
        name: initialData?.name || '',
        protocol: initialData?.protocol || 'OAuth 2.0',
        clientId: initialData?.clientId || '',
        callbackUrl: initialData?.callbackUrl || '',
        algorithm: initialData?.algorithm || 'RS256',
        network: initialData?.network || '内网',
        status: initialData?.status || 'active',
        icon: initialData?.icon || 'Globe',
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSave({ id: initialData?.id, ...formData });
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/20 backdrop-blur-sm animate-fade-in">
            <div className="bg-white w-full max-w-xl rounded-xl shadow-2xl pointer-events-auto relative flex flex-col max-h-[90vh]">
                <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
                    <h3 className="text-lg font-bold text-slate-800">{initialData ? '编辑 SSO 配置' : '新增 SSO 配置'}</h3>
                    <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
                        <X className="w-5 h-5" />
                    </button>
                </div>

                <div className="p-6 overflow-y-auto">
                    <form id="ssoForm" onSubmit={handleSubmit} className="space-y-4">
                        <div>
                            <label className="block text-sm font-bold text-slate-700 mb-1">系统名称</label>
                            <input
                                type="text"
                                required
                                value={formData.name}
                                onChange={e => setFormData({ ...formData, name: e.target.value })}
                                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                                placeholder="如：反洗钱监测系统"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-slate-700 mb-2">系统图标</label>
                            <div className="grid grid-cols-6 gap-2 p-3 border border-slate-200 rounded-lg bg-slate-50 max-h-40 overflow-y-auto custom-scrollbar">
                                {Object.entries(IconRegistry).map(([name, Icon]) => (
                                    <button
                                        key={name}
                                        type="button"
                                        onClick={() => setFormData({ ...formData, icon: name })}
                                        className={`p-2 rounded-lg flex flex-col items-center justify-center gap-1 transition-all ${formData.icon === name ? 'bg-red-100 text-red-600 ring-2 ring-red-500 ring-offset-1' : 'hover:bg-white hover:shadow-sm text-slate-500'}`}
                                        title={name}
                                    >
                                        <Icon size={20} />
                                    </button>
                                ))}
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-slate-700 mb-1">协议</label>
                            <select
                                value={formData.protocol}
                                onChange={e => setFormData({ ...formData, protocol: e.target.value })}
                                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 bg-white"
                            >
                                <option>OAuth 2.0</option>
                                <option>OIDC</option>
                                <option>CAS 3.0</option>
                                <option>SAML 2.0</option>
                                <option>JWT Token</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-slate-700 mb-1">Client ID / AppID</label>
                            <input
                                type="text"
                                required
                                value={formData.clientId}
                                onChange={e => setFormData({ ...formData, clientId: e.target.value })}
                                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 font-mono text-sm"
                                placeholder="如：AML_SYS_PROD"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-slate-700 mb-1">回调地址</label>
                            <input
                                type="text"
                                required
                                value={formData.callbackUrl}
                                onChange={e => setFormData({ ...formData, callbackUrl: e.target.value })}
                                className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 text-sm"
                                placeholder="https://..."
                            />
                        </div>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label className="block text-sm font-bold text-slate-700 mb-1">加密算法</label>
                                <input
                                    type="text"
                                    value={formData.algorithm}
                                    onChange={e => setFormData({ ...formData, algorithm: e.target.value })}
                                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                                    placeholder="RS256 / HS256 / AES-128"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-bold text-slate-700 mb-1">网络区域</label>
                                <input
                                    type="text"
                                    value={formData.network}
                                    onChange={e => setFormData({ ...formData, network: e.target.value })}
                                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                                    placeholder="内网/专线/互联网"
                                />
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-slate-700 mb-1">状态</label>
                            <div className="flex gap-4 mt-1">
                                <label className="flex items-center gap-2 cursor-pointer">
                                    <input type="radio" name="ssoStatus" checked={formData.status === 'active'} onChange={() => setFormData({ ...formData, status: 'active' })} className="text-red-600 focus:ring-red-500" />
                                    <span className="text-sm">正常</span>
                                </label>
                                <label className="flex items-center gap-2 cursor-pointer">
                                    <input type="radio" name="ssoStatus" checked={formData.status === 'maintenance'} onChange={() => setFormData({ ...formData, status: 'maintenance' })} className="text-amber-600 focus:ring-amber-500" />
                                    <span className="text-sm">维护</span>
                                </label>
                                <label className="flex items-center gap-2 cursor-pointer">
                                    <input type="radio" name="ssoStatus" checked={formData.status === 'inactive'} onChange={() => setFormData({ ...formData, status: 'inactive' })} className="text-slate-400 focus:ring-slate-400" />
                                    <span className="text-sm">停用</span>
                                </label>
                            </div>
                        </div>
                    </form>
                </div>

                <div className="px-6 py-4 border-t border-slate-100 bg-slate-50 rounded-b-xl flex justify-end gap-3">
                    <button onClick={onClose} className="px-4 py-2 text-sm font-bold text-slate-600 hover:bg-slate-200 rounded-lg transition-colors">取消</button>
                    <button form="ssoForm" type="submit" className="px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg shadow-md shadow-red-200 transition-colors flex items-center gap-2">
                        <Save className="w-4 h-4" />
                        保存
                    </button>
                </div>
            </div>
        </div>
    );
};

const RegSystemManagement: React.FC = () => {
    const [items, setItems] = useState<SsoConfig[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [showForm, setShowForm] = useState(false);
    const [editing, setEditing] = useState<SsoConfig | null>(null);

    // Pagination & Search State
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);

    // Filter Items
    const filteredItems = useMemo(() => {
        return items.filter(item => {
            const lowerTerm = searchTerm.toLowerCase();
            return (
                item.name.toLowerCase().includes(lowerTerm) ||
                item.clientId.toLowerCase().includes(lowerTerm) ||
                (item.network && item.network.toLowerCase().includes(lowerTerm))
            );
        });
    }, [items, searchTerm]);

    // Paginate Items
    const paginatedItems = useMemo(() => {
        const start = (currentPage - 1) * pageSize;
        return filteredItems.slice(start, start + pageSize);
    }, [filteredItems, currentPage, pageSize]);

    // Reset page when search changes
    useEffect(() => {
        setCurrentPage(1);
    }, [searchTerm]);

    const fetchItems = async () => {
        setLoading(true);
        setError(null);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/system', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok) throw new Error(`load sso failed ${res.status}`);
            const data = await res.json();
            setItems(data);
        } catch (err) {
            setError('SSO 配置获取失败，请稍后重试');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchItems();
    }, []);

    const handleDelete = async (id: string) => {
        if (!window.confirm('确认删除该配置吗？')) return;
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/system/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok && res.status !== 204) throw new Error('delete failed');
            await fetchItems();
        } catch (err) {
            setError('删除失败，请稍后重试');
        }
    };

    const handlePing = async (id: string) => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/system/${id}/ping`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const updated = await res.json();
                setItems(prev => prev.map(i => i.id === id ? updated : i));
            }
        } catch (err) {
            setError('心跳检测失败');
        }
    };

    const handleSave = async (payload: Partial<SsoConfig> & { id?: string }) => {
        const body = {
            name: payload.name,
            protocol: payload.protocol,
            clientId: payload.clientId,
            callbackUrl: payload.callbackUrl,
            algorithm: payload.algorithm,
            network: payload.network,
            status: payload.status,
            icon: payload.icon,
        };
        try {
            const token = localStorage.getItem('auth_token');
            if (payload.id) {
                const res = await fetch(`/api/system/${payload.id}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify(body),
                });
                if (!res.ok) throw new Error('update failed');
            } else {
                const res = await fetch('/api/system', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify(body),
                });
                if (!res.ok) throw new Error('create failed');
            }
            await fetchItems();
            setShowForm(false);
            setEditing(null);
            setError(null);
        } catch (err) {
            setError('保存失败，请稍后重试');
        }
    };

    const openForm = (item?: SsoConfig | null) => {
        setEditing(item ?? null);
        setShowForm(true);
    };

    return (
        <div className="space-y-4 animate-fade-in">
            <ActionToolbar
                title="监管系统配置 (System)"
                placeholder="搜索系统名称或AppID..."
                codePrefix="sys:system"
                onAdd={() => openForm(null)}
                onSearch={setSearchTerm}
            />
            {error && <div className="text-sm text-red-600 bg-red-50 border border-red-200 px-3 py-2 rounded">{error}</div>}
            {loading && <div className="text-sm text-slate-500 bg-slate-50 border border-slate-200 px-3 py-2 rounded">加载中...</div>}

            <div className="bg-white rounded-lg border border-slate-200 overflow-x-auto">
                <table className="w-full text-sm text-left">
                    <thead className="bg-slate-50 text-slate-700 font-semibold border-b border-slate-200">
                        <tr>
                            <th className="px-4 py-3 whitespace-nowrap">系统名称</th>
                            <th className="px-4 py-3 whitespace-nowrap">协议</th>
                            <th className="px-4 py-3 whitespace-nowrap">Client ID / AppID</th>
                            <th className="px-4 py-3 whitespace-nowrap">回调地址</th>
                            <th className="px-4 py-3 whitespace-nowrap">算法</th>
                            <th className="px-4 py-3 whitespace-nowrap">网络</th>
                            <th className="px-4 py-3 whitespace-nowrap">状态</th>
                            <th className="px-4 py-3 whitespace-nowrap text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                        {paginatedItems.map((item) => (
                            <tr key={item.id} className="hover:bg-slate-50 transition-colors">
                                <td className="px-4 py-3 font-medium text-slate-900 flex items-center gap-2">
                                    {(() => {
                                        const Icon = getIcon(item.icon);
                                        return <Icon size={16} className="text-slate-500" />;
                                    })()}
                                    {item.name}
                                </td>
                                <td className="px-4 py-3 text-slate-600">{item.protocol}</td>
                                <td className="px-4 py-3 text-slate-600 font-mono text-xs">{item.clientId}</td>
                                <td className="px-4 py-3 text-slate-500 text-xs max-w-[220px] truncate">{item.callbackUrl}</td>
                                <td className="px-4 py-3 text-slate-600">{item.algorithm}</td>
                                <td className="px-4 py-3 text-slate-600">{item.network}</td>
                                <td className="px-4 py-3">
                                    {item.status === 'active' ? (
                                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">正常</span>
                                    ) : item.status === 'maintenance' ? (
                                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">维护</span>
                                    ) : (
                                        <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-500">停用</span>
                                    )}
                                </td>
                                <td className="px-4 py-3 text-right">
                                    <div className="flex items-center justify-end gap-2">
                                        <button onClick={() => handlePing(item.id)} className="px-2 py-1 text-xs bg-slate-100 text-slate-700 rounded hover:bg-slate-200">心跳</button>
                                        <Auth code="sys:system:edit">
                                            <button onClick={() => openForm(item)} className="p-1.5 text-slate-400 hover:text-blue-600 bg-slate-100 hover:bg-blue-50 rounded transition-colors" title="编辑">
                                                <Edit size={14} />
                                            </button>
                                        </Auth>
                                        <Auth code="sys:system:del">
                                            <button onClick={() => handleDelete(item.id)} className="p-1.5 text-slate-400 hover:text-red-600 bg-slate-100 hover:bg-red-50 rounded transition-colors" title="删除">
                                                <Trash2 size={14} />
                                            </button>
                                        </Auth>
                                    </div>
                                </td>
                            </tr>
                        ))}

                        {filteredItems.length === 0 && !loading && (
                            <tr>
                                <td colSpan={8} className="px-4 py-6 text-center text-slate-400">暂无数据，可点击新增</td>
                            </tr>
                        )}
                    </tbody>
                </table>
                <div className="px-4 border-t border-slate-200">
                    <Pagination
                        current={currentPage}
                        total={filteredItems.length}
                        pageSize={pageSize}
                        onChange={(page, size) => {
                            setCurrentPage(page);
                            setPageSize(size);
                        }}
                        showSizeChanger
                    />
                </div>
            </div>

            {showForm && (
                <SsoForm
                    initialData={editing}
                    onClose={() => { setShowForm(false); setEditing(null); }}
                    onSave={handleSave}
                />
            )}
        </div>
    );
};

export default RegSystemManagement;
