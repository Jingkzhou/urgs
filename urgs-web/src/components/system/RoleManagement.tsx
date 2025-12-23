import React, { useEffect, useState, useMemo } from 'react';
import { Plus, Edit, Trash2, Shield, Save, X, Check, ChevronRight, ChevronDown, Box, Layout, Users, Settings, Database, Terminal, Lock, Search } from 'lucide-react';

import { permissionManifest } from '../../permissions/manifest';
import {
    Message, Session, getSessions, createSession, saveSession, streamChatResponse, loadSessionMessages, generateSessionTitle, getAgents, getRoleAgents, updateRoleAgents
} from '../../api/chat';
import Auth from '../Auth';

interface Role {
    id: number;
    name: string;
    code: string;
    description: string;
}

interface Permission {
    id: string;
    code: string;
    name: string;
    description: string;
    type?: 'menu' | 'button' | 'dir' | string;
    order?: number;
    parentId?: string;
    children?: Permission[];
}

interface PermissionGroup {
    key: string;
    label: string;
    icon: React.ReactNode;
    permissions: Permission[];
}

const RoleManagement: React.FC = () => {
    const [roles, setRoles] = useState<Role[]>([]);
    const [loading, setLoading] = useState(true);
    const [editingRole, setEditingRole] = useState<Role | null>(null);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [rolePermissions, setRolePermissions] = useState<string[]>([]);
    const [formData, setFormData] = useState({ name: '', code: '', description: '' });

    const [systemPermissions, setSystemPermissions] = useState<Permission[]>([]);
    const [expandedGroups, setExpandedGroups] = useState<string[]>([]);
    const [roleAgents, setRoleAgents] = useState<number[]>([]);
    const [allAgents, setAllAgents] = useState<any[]>([]);

    const manifestOrder = useMemo(() => {
        return new Map<string, { id: string; order: number; type?: string; name?: string; parentId?: string }>(
            permissionManifest.map((item, index) => [
                item.code,
                { id: item.id, order: index, type: item.type, name: item.name, parentId: item.parentId },
            ])
        );
    }, []);

    const permMap = useMemo(() => new Map(systemPermissions.map(p => [p.code, p])), [systemPermissions]);

    const hierarchy = useMemo(() => {
        const codeToId = new Map<string, string>();
        const idToCode = new Map<string, string>();
        const parentMap = new Map<string, string | undefined>();
        const childrenMap = new Map<string, string[]>();

        systemPermissions.forEach(p => {
            codeToId.set(p.code, p.id);
            idToCode.set(p.id, p.code);
        });

        systemPermissions.forEach(p => {
            if (p.parentId && p.parentId !== 'root') {
                const parentCode = idToCode.get(p.parentId);
                if (parentCode) {
                    parentMap.set(p.code, parentCode);
                    if (!childrenMap.has(parentCode)) {
                        childrenMap.set(parentCode, []);
                    }
                    childrenMap.get(parentCode)!.push(p.code);
                }
            }
        });

        return { parentMap, childrenMap };
    }, [systemPermissions]);

    const treeData = useMemo(() => {
        const nodes: Permission[] = [];
        const map = new Map<string, Permission>();

        systemPermissions.forEach(p => {
            map.set(p.id, { ...p, children: [] });
        });

        systemPermissions.forEach(p => {
            const node = map.get(p.id)!;
            if (p.parentId && p.parentId !== 'root' && map.has(p.parentId)) {
                map.get(p.parentId)!.children!.push(node);
            } else {
                nodes.push(node);
            }
        });

        const sortNodes = (list: Permission[]) => {
            list.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
            list.forEach(node => {
                if (node.children && node.children.length > 0) {
                    sortNodes(node.children);
                }
            });
        };
        sortNodes(nodes);

        return nodes;
    }, [systemPermissions]);

    useEffect(() => {
        fetchRoles();
        fetchSystemPermissions();
        fetchAgents();
    }, []);

    const fetchAgents = async () => {
        try {
            const data = await getAgents();
            setAllAgents(data);
        } catch (e) {
            console.error('Failed to fetch agents', e);
        }
    };

    const fetchRoles = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/roles', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setRoles(data);
            }
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    const fetchSystemPermissions = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/permissions', {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                const mapped = data.map((p: any) => {
                    const meta = manifestOrder.get(p.code);
                    return {
                        id: p.id ? String(p.id) : (meta?.id ?? p.code),
                        code: p.code,
                        name: p.name,
                        description: meta?.name ?? p.name ?? p.description ?? p.code,
                        type: meta?.type ?? p.type,
                        order: meta?.order ?? Number.MAX_SAFE_INTEGER,
                        parentId: p.parentId ?? meta?.parentId,
                    } as Permission;
                });
                const withFallback = mapped.length > 0 ? mapped : Array.from(manifestOrder.entries()).map(([code, meta]) => ({
                    id: meta.id,
                    code,
                    name: meta.name || code,
                    description: meta.name || code,
                    type: meta.type,
                    order: meta.order,
                    parentId: meta.parentId,
                }));
                withFallback.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
                setSystemPermissions(withFallback);
            }
        } catch (err) {
            console.error(err);
        }
    };

    const handleEdit = async (role: Role) => {
        setEditingRole(role);
        setFormData({ name: role.name, code: role.code, description: role.description || '' });
        setIsModalOpen(true);
        try {
            const token = localStorage.getItem('auth_token');
            const permRes = await fetch(`/api/roles/${role.id}/permissions`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (permRes.ok) {
                const perms = await permRes.json();
                setRolePermissions(perms);
            }

            const agents = await getRoleAgents(role.id);
            setRoleAgents(agents);
        } catch (err) {
            console.error(err);
        }
        expandAll();
    };

    const handleCreate = () => {
        setEditingRole(null);
        setFormData({ name: '', code: '', description: '' });
        setRolePermissions([]);
        setRoleAgents([]);
        setIsModalOpen(true);
        expandAll();
    };

    const expandAll = () => {
        const allIds: string[] = [];
        const traverse = (nodes: Permission[]) => {
            nodes.forEach(node => {
                allIds.push(node.id);
                if (node.children) traverse(node.children);
            });
        };
        traverse(treeData);
        setExpandedGroups(allIds);
    };

    const handleDelete = async (id: number) => {
        if (!window.confirm('确定要删除这个角色吗？')) return;
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/roles/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                fetchRoles();
            }
        } catch (err) {
            console.error(err);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        const token = localStorage.getItem('auth_token');
        const url = editingRole ? `/api/roles/${editingRole.id}` : '/api/roles';
        const method = editingRole ? 'PUT' : 'POST';

        try {
            const roleRes = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(formData)
            });

            if (!roleRes.ok) throw new Error('Failed to save role');
            const savedRole = await roleRes.json();
            const roleId = editingRole ? editingRole.id : savedRole.id;

            await fetch(`/api/roles/${roleId}/permissions`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ permissions: rolePermissions })
            });

            await updateRoleAgents(roleId, roleAgents);

            setIsModalOpen(false);
            fetchRoles();
        } catch (err) {
            alert('保存失败');
            console.error(err);
        }
    };

    const addWithAncestors = (code: string, current: Set<string>) => {
        let cursor: string | undefined = code;
        while (cursor) {
            current.add(cursor);
            cursor = hierarchy.parentMap.get(cursor);
        }
    };

    const collectDescendants = (code: string, bag: Set<string>) => {
        const children = hierarchy.childrenMap.get(code);
        if (!children) return;
        children.forEach(child => {
            bag.add(child);
            collectDescendants(child, bag);
        });
    };

    const togglePermission = (code: string) => {
        setRolePermissions(prev => {
            const current = new Set<string>(prev);
            const isSelected = current.has(code);
            const perm = permMap.get(code);

            if (isSelected) {
                current.delete(code);
                if (perm?.type === 'menu' || perm?.type === 'dir') {
                    const toRemove = new Set<string>();
                    collectDescendants(code, toRemove);
                    toRemove.forEach(c => current.delete(c));
                }
            } else {
                addWithAncestors(code, current);
                collectDescendants(code, current);
            }

            return Array.from(current);
        });
    };

    const toggleAgent = (agentId: number) => {
        setRoleAgents(prev => {
            if (prev.includes(agentId)) {
                return prev.filter(id => id !== agentId);
            } else {
                return [...prev, agentId];
            }
        });
    };

    const toggleGroup = (id: string) => {
        setExpandedGroups(prev =>
            prev.includes(id)
                ? prev.filter(k => k !== id)
                : [...prev, id]
        );
    };

    const renderTreeNodes = (nodes: Permission[]) => {
        return nodes.map(node => {
            const isExpanded = expandedGroups.includes(node.id);
            const isSelected = rolePermissions.includes(node.code);
            const hasChildren = node.children && node.children.length > 0;

            return (
                <div key={node.id} className="ml-2">
                    <div className="flex items-center gap-1 py-1 hover:bg-slate-50 rounded px-1 group">
                        <div className="w-5 flex justify-center flex-shrink-0">
                            {hasChildren && (
                                <button
                                    type="button"
                                    onClick={(e) => { e.stopPropagation(); toggleGroup(node.id); }}
                                    className="p-0.5 text-slate-400 hover:text-slate-600"
                                >
                                    {isExpanded ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                                </button>
                            )}
                        </div>
                        <label className="flex items-center gap-2 cursor-pointer select-none flex-1 min-w-0">
                            <div className={`
                                w-4 h-4 rounded border flex items-center justify-center transition-colors flex-shrink-0
                                ${isSelected
                                    ? 'bg-red-600 border-red-600 text-white'
                                    : 'border-slate-300 bg-white group-hover:border-slate-400'
                                }
                            `}>
                                {isSelected && <Check size={10} strokeWidth={3} />}
                            </div>
                            <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => togglePermission(node.code)}
                                className="hidden"
                            />
                            <div className="flex items-center gap-2 min-w-0 flex-1">
                                <span className="text-sm text-slate-700 truncate" title={node.description}>{node.description}</span>
                                {node.type === 'menu' && <span className="text-[10px] px-1.5 py-0.5 bg-blue-100 text-blue-700 rounded flex-shrink-0">菜单</span>}
                                <span className="text-xs text-slate-400 font-mono truncate hidden group-hover:inline-block">{node.code}</span>
                            </div>
                        </label>
                    </div>
                    {hasChildren && isExpanded && (
                        <div className="border-l border-slate-200 ml-3.5 pl-1">
                            {renderTreeNodes(node.children!)}
                        </div>
                    )}
                </div>
            );
        });
    };

    return (
        <div className="space-y-4">
            <div className="flex justify-between items-center">
                <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                    <Shield className="w-5 h-5 text-red-600" />
                    角色管理
                </h2>
                <Auth code="sys:role:add">
                    <button
                        onClick={handleCreate}
                        className="flex items-center gap-2 px-3 py-1.5 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors text-sm font-medium"
                    >
                        <Plus size={16} />
                        新建角色
                    </button>
                </Auth>
            </div>

            <div className="overflow-x-auto">
                <table className="w-full text-sm text-left">
                    <thead className="bg-slate-50 text-slate-500 font-medium border-b border-slate-200">
                        <tr>
                            <th className="px-4 py-3">角色名称</th>
                            <th className="px-4 py-3">角色代码</th>
                            <th className="px-4 py-3">描述</th>
                            <th className="px-4 py-3 text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                        {roles.map(role => (
                            <tr key={role.id} className="hover:bg-slate-50">
                                <td className="px-4 py-3 font-medium text-slate-800">{role.name}</td>
                                <td className="px-4 py-3 text-slate-600 font-mono text-xs">{role.code}</td>
                                <td className="px-4 py-3 text-slate-500">{role.description}</td>
                                <td className="px-4 py-3 text-right">
                                    <div className="flex items-center justify-end gap-2">
                                        <Auth code="sys:role:edit">
                                            <button
                                                onClick={() => handleEdit(role)}
                                                className="p-1 text-slate-400 hover:text-blue-600 transition-colors"
                                                title="编辑权限"
                                            >
                                                <Edit size={16} />
                                            </button>
                                        </Auth>
                                        <Auth code="sys:role:del">
                                            <button
                                                onClick={() => handleDelete(role.id)}
                                                className="p-1 text-slate-400 hover:text-red-600 transition-colors"
                                                title="删除角色"
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        </Auth>
                                    </div>
                                </td>
                            </tr>
                        ))}
                        {roles.length === 0 && !loading && (
                            <tr>
                                <td colSpan={4} className="px-4 py-8 text-center text-slate-400">
                                    暂无角色数据
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>

            {isModalOpen && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <div className="bg-white rounded-xl shadow-2xl w-full max-w-5xl mx-4 overflow-hidden animate-fade-in flex flex-col max-h-[90vh]">
                        <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50">
                            <h3 className="font-bold text-slate-800">
                                {editingRole ? '编辑角色' : '新建角色'}
                            </h3>
                            <button onClick={() => setIsModalOpen(false)} className="text-slate-400 hover:text-slate-600">
                                <X size={20} />
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} className="flex-1 overflow-hidden flex flex-col">
                            <div className="flex-1 overflow-y-auto p-6">
                                <div className="flex gap-10 h-full">
                                    <div className="w-1/4 space-y-5">
                                        <h4 className="font-medium text-slate-800 border-b border-slate-100 pb-2 mb-4">基本信息</h4>
                                        <div>
                                            <label className="block text-sm font-medium text-slate-700 mb-1">角色名称</label>
                                            <input
                                                type="text"
                                                required
                                                value={formData.name}
                                                onChange={e => setFormData({ ...formData, name: e.target.value })}
                                                className="w-full px-3 py-2 border border-slate-300 rounded-md focus:ring-2 focus:ring-red-500 focus:border-red-500"
                                                placeholder="例如：数据分析师"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-sm font-medium text-slate-700 mb-1">角色代码</label>
                                            <input
                                                type="text"
                                                required
                                                value={formData.code}
                                                onChange={e => setFormData({ ...formData, code: e.target.value })}
                                                className="w-full px-3 py-2 border border-slate-300 rounded-md focus:ring-2 focus:ring-red-500 focus:border-red-500 font-mono text-sm"
                                                placeholder="例如：data_analyst"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-sm font-medium text-slate-700 mb-1">描述</label>
                                            <textarea
                                                value={formData.description}
                                                onChange={e => setFormData({ ...formData, description: e.target.value })}
                                                className="w-full px-3 py-2 border border-slate-300 rounded-md focus:ring-2 focus:ring-red-500 focus:border-red-500 h-24 resize-none"
                                                placeholder="角色职责描述..."
                                            />
                                        </div>

                                        <div className="pt-4 mt-4 border-t border-slate-100">
                                            <h4 className="font-medium text-slate-800 mb-3 flex items-center justify-between">
                                                <span>智能体授权</span>
                                                <span className="text-[10px] bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded">AI Agent</span>
                                            </h4>
                                            <div className="space-y-1 max-h-48 overflow-y-auto pr-1">
                                                {allAgents.map(agent => (
                                                    <label key={agent.id} className="flex items-center gap-2 p-1.5 hover:bg-slate-50 rounded-md cursor-pointer group">
                                                        <div className={`w-3.5 h-3.5 rounded border flex items-center justify-center transition-colors ${roleAgents.includes(agent.id) ? 'bg-purple-600 border-purple-600 text-white' : 'border-slate-300 bg-white'}`}>
                                                            {roleAgents.includes(agent.id) && <Check size={8} strokeWidth={4} />}
                                                        </div>
                                                        <input type="checkbox" className="hidden" checked={roleAgents.includes(agent.id)} onChange={() => toggleAgent(agent.id)} />
                                                        <span className="text-sm text-slate-700 group-hover:text-purple-700 transition-colors truncate">{agent.name}</span>
                                                    </label>
                                                ))}
                                                {allAgents.length === 0 && <span className="text-xs text-slate-400 italic">加载中或无数据...</span>}
                                            </div>
                                        </div>
                                    </div>

                                    <div className="flex-1 border-l border-slate-100 pl-8 flex flex-col">
                                        <h4 className="font-medium text-slate-800 border-b border-slate-100 pb-2 mb-4 flex justify-between items-center">
                                            <span>功能权限配置</span>
                                            <span className="text-xs text-slate-400 font-normal">
                                                已选 {rolePermissions.length} 项
                                            </span>
                                        </h4>

                                        <div className="flex-1 overflow-y-auto pr-2">
                                            {treeData.length > 0 ? (
                                                renderTreeNodes(treeData)
                                            ) : (
                                                <div className="text-center text-slate-400 py-8 text-sm">
                                                    暂无权限数据，请先同步权限配置
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="px-6 py-4 border-t border-slate-100 bg-slate-50 flex justify-end gap-3">
                                <button
                                    type="button"
                                    onClick={() => setIsModalOpen(false)}
                                    className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-md text-sm font-medium"
                                >
                                    取消
                                </button>
                                <button
                                    type="submit"
                                    className="px-4 py-2 bg-red-600 text-white hover:bg-red-700 rounded-md text-sm font-medium flex items-center gap-2"
                                >
                                    <Save size={16} />
                                    保存
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default RoleManagement;
