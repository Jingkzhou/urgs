import React, { useState, useMemo, useEffect } from 'react';
import { Building2, Landmark, LayoutGrid, ChevronDown, ChevronRight, Plus, Edit, Trash2, Save, X, ArrowLeft, FolderTree } from 'lucide-react';
import { OrgNode } from './types';
import { ActionToolbar } from './Shared';
import Auth from '../Auth';

const OrgForm: React.FC<{
    initialData?: OrgNode | null;
    parentOptions: { id: string; name: string }[];
    defaultParentId?: string;
    onClose: () => void;
    onSave: (payload: Partial<OrgNode> & { id?: string }) => void;
}> = ({ initialData, parentOptions, defaultParentId = 'root', onClose, onSave }) => {
    const [formData, setFormData] = useState({
        name: initialData?.name || '',
        code: initialData?.code || '',
        type: initialData?.type || 'BRANCH',
        typeName: initialData?.typeName || '',
        status: initialData?.status || 'active',
        parentId: initialData?.parentId || defaultParentId,
        orderNum: initialData?.orderNum ?? 0,
    });

    const typeLabel = (t: string) => {
        switch (t) {
            case 'HEAD': return '总行';
            case 'BRANCH': return '一级分行';
            case 'SUB_BRANCH': return '二级支行';
            case 'DEPT': return '部门/中心';
            default: return '';
        }
    };

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSave({
            id: initialData?.id,
            ...formData,
            typeName: formData.typeName || typeLabel(formData.type),
        });
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/20 backdrop-blur-sm animate-fade-in">
            <div className="bg-white w-full max-w-2xl rounded-xl shadow-2xl pointer-events-auto relative flex flex-col max-h-[90vh]">
                <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <ArrowLeft className="w-5 h-5 text-slate-400 cursor-pointer" onClick={onClose} />
                        <h3 className="text-lg font-bold text-slate-800">{initialData ? '编辑机构' : '新增机构'}</h3>
                    </div>
                    <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
                        <X className="w-5 h-5" />
                    </button>
                </div>

                <div className="p-6 overflow-y-auto">
                    <form id="orgForm" onSubmit={handleSubmit} className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div className="col-span-2">
                                <label className="block text-sm font-bold text-slate-700 mb-2">上级机构</label>
                                <div className="relative">
                                    <FolderTree className="absolute left-3 top-3 w-4 h-4 text-slate-400" />
                                    <select
                                        value={formData.parentId}
                                        onChange={e => setFormData({ ...formData, parentId: e.target.value })}
                                        className="w-full pl-10 pr-3 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 bg-white"
                                    >
                                        {parentOptions.map(opt => (
                                            <option key={opt.id} value={opt.id}>{opt.name}</option>
                                        ))}
                                    </select>
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-slate-700 mb-2">机构名称</label>
                                <input
                                    type="text"
                                    required
                                    value={formData.name}
                                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                                    className="w-full px-3 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500"
                                    placeholder="请输入机构名称"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-slate-700 mb-2">机构代码</label>
                                <input
                                    type="text"
                                    required
                                    value={formData.code}
                                    onChange={e => setFormData({ ...formData, code: e.target.value })}
                                    className="w-full px-3 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus-border-red-500 font-mono text-sm"
                                    placeholder="如: JLB_HEAD"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-slate-700 mb-2">机构类型</label>
                                <select
                                    value={formData.type}
                                    onChange={e => setFormData({ ...formData, type: e.target.value as OrgNode['type'] })}
                                    className="w-full px-3 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus-border-red-500 bg-white"
                                >
                                    <option value="HEAD">总行</option>
                                    <option value="BRANCH">一级分行</option>
                                    <option value="SUB_BRANCH">二级支行</option>
                                    <option value="DEPT">部门/中心</option>
                                </select>
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-slate-700 mb-2">类型名称</label>
                                <input
                                    type="text"
                                    value={formData.typeName}
                                    onChange={e => setFormData({ ...formData, typeName: e.target.value })}
                                    className="w-full px-3 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus-border-red-500"
                                    placeholder="如不填，自动随类型"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-bold text-slate-700 mb-2">显示排序</label>
                                <input
                                    type="number"
                                    value={formData.orderNum}
                                    onChange={e => setFormData({ ...formData, orderNum: Number(e.target.value) })}
                                    className="w-full px-3 py-2.5 border border-slate-300 rounded-lg focus:ring-2 focus:ring-red-500 focus-border-red-500"
                                    placeholder="0"
                                />
                            </div>

                            <div className="col-span-2">
                                <label className="block text-sm font-bold text-slate-700 mb-2">机构状态</label>
                                <div className="flex gap-6">
                                    <label className="flex items-center gap-2 cursor-pointer">
                                        <input
                                            type="radio"
                                            name="orgStatus"
                                            checked={formData.status === 'active'}
                                            onChange={() => setFormData({ ...formData, status: 'active' })}
                                            className="w-4 h-4 text-red-600 border-slate-300 focus:ring-red-500"
                                        />
                                        <span className="text-sm text-slate-700">正常</span>
                                    </label>
                                    <label className="flex items-center gap-2 cursor-pointer">
                                        <input
                                            type="radio"
                                            name="orgStatus"
                                            checked={formData.status === 'inactive'}
                                            onChange={() => setFormData({ ...formData, status: 'inactive' })}
                                            className="w-4 h-4 text-slate-400 border-slate-300 focus:ring-slate-400"
                                        />
                                        <span className="text-sm text-slate-700">停用</span>
                                    </label>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>

                <div className="px-6 py-4 border-t border-slate-100 bg-slate-50 rounded-b-xl flex justify-end gap-3">
                    <button onClick={onClose} className="px-4 py-2 text-sm font-bold text-slate-600 hover:bg-slate-200 rounded-lg transition-colors">
                        取消
                    </button>
                    <button form="orgForm" type="submit" className="px-4 py-2 text-sm font-bold text-white bg-red-600 hover:bg-red-700 rounded-lg shadow-md shadow-red-200 transition-colors flex items-center gap-2">
                        <Save className="w-4 h-4" />
                        保存
                    </button>
                </div>
            </div>
        </div>
    );
};

const OrgManagement: React.FC = () => {
    const [orgs, setOrgs] = useState<OrgNode[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set(['root']));
    const [showForm, setShowForm] = useState(false);
    const [editingOrg, setEditingOrg] = useState<OrgNode | null>(null);
    const [defaultParentId, setDefaultParentId] = useState<string>('root');

    const toggleExpand = (id: string) => {
        const newExpanded = new Set(expandedIds);
        if (newExpanded.has(id)) {
            newExpanded.delete(id);
        } else {
            newExpanded.add(id);
        }
        setExpandedIds(newExpanded);
    };

    const buildOrgTree = (items: OrgNode[]) => {
        const map = new Map<string, OrgNode & { children: OrgNode[] }>();
        const roots: OrgNode[] = [];
        items.forEach(item => map.set(item.id, { ...item, children: [] }));
        items.forEach(item => {
            const node = map.get(item.id)!;
            const pid = item.parentId || 'root';
            if (pid === 'root') {
                roots.push(node);
            } else {
                const parent = map.get(pid);
                if (parent) parent.children!.push(node);
                else roots.push(node);
            }
        });
        return roots;
    };

    const treeData = useMemo(() => buildOrgTree(orgs), [orgs]);
    const parentOptions = useMemo(() => [{ id: 'root', name: '根节点/总行' }, ...orgs.map(o => ({ id: o.id, name: o.name }))], [orgs]);

    const fetchOrgs = async () => {
        setLoading(true);
        setError(null);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/orgs', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok) throw new Error(`load orgs failed: ${res.status}`);
            const data = await res.json();
            setOrgs(data);
        } catch (err) {
            setError('机构数据获取失败，请稍后重试');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchOrgs();
    }, []);

    const handleSaveOrg = async (payload: Partial<OrgNode> & { id?: string }) => {
        const body = {
            name: payload.name,
            code: payload.code,
            type: payload.type,
            typeName: payload.typeName,
            status: payload.status,
            parentId: payload.parentId || 'root',
            orderNum: payload.orderNum ?? 0,
        };
        try {
            const token = localStorage.getItem('auth_token');
            if (payload.id) {
                const res = await fetch(`/api/orgs/${payload.id}`, {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify(body),
                });
                if (!res.ok) throw new Error(`update org failed: ${res.status}`);
            } else {
                const res = await fetch('/api/orgs', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify(body),
                });
                if (!res.ok) throw new Error(`create org failed: ${res.status}`);
            }
            await fetchOrgs();
            setShowForm(false);
            setEditingOrg(null);
            setError(null);
        } catch (err) {
            setError('保存机构失败，请稍后重试');
        }
    };

    const handleDeleteOrg = async (id: string) => {
        if (!window.confirm('确认删除该机构吗？')) return;
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/orgs/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!res.ok && res.status !== 204) throw new Error('delete failed');
            await fetchOrgs();
        } catch (err) {
            setError('删除机构失败，请稍后重试');
        }
    };

    const openForm = (org?: OrgNode | null, parentId: string = 'root') => {
        setEditingOrg(org ?? null);
        setDefaultParentId(parentId);
        setShowForm(true);
    };

    const OrgTreeRow = ({ node, level, isLastChild }: { node: OrgNode; level: number; isLastChild: boolean }) => {
        const hasChildren = node.children && node.children.length > 0;
        const isExpanded = expandedIds.has(node.id);
        const paddingLeft = level * 28;

        // Icon Selection based on type
        let Icon = Building2;
        if (node.type === 'BRANCH') Icon = Landmark;
        if (node.type === 'DEPT') Icon = LayoutGrid;
        if (node.type === 'SUB_BRANCH') Icon = Building2;

        return (
            <>
                <div className="grid grid-cols-12 gap-4 py-3 px-4 hover:bg-slate-50 transition-colors border-b border-slate-50 items-center group">
                    {/* Name Column with Indentation & Tree Lines */}
                    <div className="col-span-5 flex items-center relative">
                        <div style={{ paddingLeft: `${paddingLeft}px` }} className="flex items-center h-full relative">
                            {/* Connecting Lines for Tree Structure */}
                            {level > 0 && (
                                <div className="absolute top-1/2 left-0 w-[28px] border-t border-slate-300 -translate-x-full -translate-y-1/2"></div>
                            )}
                            {level > 0 && !isLastChild && (
                                <div className="absolute top-0 left-[-28px] h-full border-l border-slate-300"></div>
                            )}
                            {level > 0 && isLastChild && (
                                <div className="absolute top-0 left-[-28px] h-1/2 border-l border-slate-300"></div>
                            )}

                            {/* Expand/Collapse Toggle */}
                            <button
                                onClick={() => toggleExpand(node.id)}
                                className={`mr-2 p-1 rounded hover:bg-slate-200 text-slate-500 transition-transform ${hasChildren ? 'visible' : 'invisible'}`}
                            >
                                {isExpanded ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                            </button>

                            {/* Icon & Name */}
                            <Icon size={16} className={`mr-2 ${node.type === 'HEAD' ? 'text-red-600' : 'text-slate-500'}`} />
                            <span className={`font-medium ${node.type === 'HEAD' ? 'text-slate-900 font-bold' : 'text-slate-700'}`}>
                                {node.name}
                            </span>
                        </div>
                    </div>

                    <div className="col-span-2 text-sm font-mono text-slate-500 bg-slate-50/50 px-2 py-1 rounded w-fit">
                        {node.code}
                    </div>

                    <div className="col-span-2">
                        <span className={`text-xs px-2 py-1 rounded border 
                         ${node.type === 'HEAD' ? 'bg-red-50 text-red-700 border-red-100' : ''}
                         ${node.type === 'BRANCH' ? 'bg-indigo-50 text-indigo-700 border-indigo-100' : ''}
                         ${node.type === 'DEPT' ? 'bg-amber-50 text-amber-700 border-amber-100' : ''}
                         ${node.type === 'SUB_BRANCH' ? 'bg-slate-50 text-slate-600 border-slate-200' : ''}
                    `}>
                            {node.typeName}
                        </span>
                    </div>

                    <div className="col-span-1">
                        {node.status === 'active' ? (
                            <span className="inline-flex items-center gap-1 text-xs text-green-600 bg-green-50 px-2 py-1 rounded-full">
                                <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span> 正常
                            </span>
                        ) : (
                            <span className="inline-flex items-center gap-1 text-xs text-slate-500 bg-slate-100 px-2 py-1 rounded-full">
                                <span className="w-1.5 h-1.5 rounded-full bg-slate-400"></span> 停用
                            </span>
                        )}
                    </div>

                    <div className="col-span-2 text-right opacity-0 group-hover:opacity-100 transition-opacity">
                        <div className="flex items-center justify-end gap-2">
                            <Auth code="sys:org:add">
                                <button
                                    onClick={() => openForm(null, node.id)}
                                    className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors"
                                    title="新增下级"
                                >
                                    <Plus size={14} />
                                </button>
                            </Auth>
                            <Auth code="sys:org:edit">
                                <button
                                    onClick={() => openForm(node, node.parentId || 'root')}
                                    className="p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded transition-colors"
                                    title="编辑">
                                    <Edit size={14} />
                                </button>
                            </Auth>
                            <Auth code="sys:org:del">
                                <button
                                    onClick={() => handleDeleteOrg(node.id)}
                                    className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
                                    title="删除">
                                    <Trash2 size={14} />
                                </button>
                            </Auth>
                        </div>
                    </div>
                </div>

                {/* Recursive Rendering of Children */}
                {hasChildren && isExpanded && (
                    <div className="relative">
                        {/* Vertical Line Guide for Children */}
                        <div className="absolute top-0 bottom-0 border-l border-slate-200" style={{ left: `${paddingLeft + 24}px` }}></div>

                        {node.children!.map((child, index) => (
                            <OrgTreeRow
                                key={child.id}
                                node={child}
                                level={level + 1}
                                isLastChild={index === node.children!.length - 1}
                            />
                        ))}
                    </div>
                )}
            </>
        );
    };

    return (
        <div className="space-y-4 animate-fade-in">
            <ActionToolbar title="机构层级管理" codePrefix="sys:org" onAdd={() => openForm(null, 'root')} />
            {error && (
                <div className="text-sm text-red-600 bg-red-50 border border-red-200 px-3 py-2 rounded">{error}</div>
            )}
            {loading && (
                <div className="text-sm text-slate-500 bg-slate-50 border border-slate-200 px-3 py-2 rounded">机构数据加载中...</div>
            )}
            <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
                {/* Table Header */}
                <div className="grid grid-cols-12 gap-4 px-4 py-3 bg-slate-50 border-b border-slate-200 font-bold text-sm text-slate-700">
                    <div className="col-span-5 pl-8">机构名称</div>
                    <div className="col-span-2">机构代码</div>
                    <div className="col-span-2">机构类型</div>
                    <div className="col-span-1">状态</div>
                    <div className="col-span-2 text-right pr-4">操作</div>
                </div>

                {/* Tree Body */}
                <div className="divide-y divide-slate-50">
                    {treeData.length > 0 ? (
                        treeData.map((node, index) => (
                            <OrgTreeRow key={node.id} node={node} level={0} isLastChild={index === treeData.length - 1} />
                        ))
                    ) : (
                        <div className="py-10 text-center text-slate-400">暂无机构数据</div>
                    )}
                </div>
                <div className="p-3 border-t border-slate-100 bg-slate-50 text-xs text-slate-400 text-center">
                    显示全行组织架构树
                </div>
            </div>

            {showForm && (
                <OrgForm
                    initialData={editingOrg}
                    parentOptions={parentOptions}
                    defaultParentId={defaultParentId}
                    onClose={() => { setShowForm(false); setEditingOrg(null); }}
                    onSave={handleSaveOrg}
                />
            )}
        </div>
    );
};

export default OrgManagement;
