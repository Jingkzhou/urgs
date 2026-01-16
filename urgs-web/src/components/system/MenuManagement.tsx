import React, { useState, useEffect, useMemo, useRef } from 'react';
import { RefreshCw, AlertCircle, Search, Scan, Plus, FolderTree, FileText, MousePointerClick, Edit, Trash2, Save } from 'lucide-react';
import { FunctionPoint } from './types';
import { permissionManifest, manifestMeta } from '../../permissions/manifest';
import Auth from '../Auth';

const MenuManagement: React.FC = () => {
    const [funcPoints, setFuncPoints] = useState<FunctionPoint[]>([]);
    const [pendingDiff, setPendingDiff] = useState<FunctionPoint[]>([]);
    const [isScanning, setIsScanning] = useState(false);
    const [isApplying, setIsApplying] = useState(false);
    const [syncError, setSyncError] = useState<string | null>(null);
    const manifestSignature = useMemo(
        () => `${manifestMeta.version}-${permissionManifest.length}-${permissionManifest.map(p => p.code).sort().join('|')}`,
        []
    );
    const lastSyncedSignature = useRef<string | null>(localStorage.getItem('permission_manifest_synced'));

    const computeLocalDiff = (baseline: FunctionPoint[]) => {
        // Compare by code to avoid DB自增ID与manifest ID不一致导致全部被视为差异
        const baselineCodes = new Set(baseline.map((b) => b.code));
        return permissionManifest.filter((fp) => !baselineCodes.has(fp.code));
    };

    const loadAndDiff = async (manual = false) => {
        setIsScanning(true);
        setSyncError(null);
        try {
            // Try backend diff first
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/permissions/diff', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ items: permissionManifest })
            });
            if (res.ok) {
                const data = await res.json();
                const current = data.current ?? permissionManifest.filter((p: FunctionPoint) => p.level < 2);

                // Combine diffs from backend
                const added = Array.isArray(data.added) ? data.added : [];
                const modified = Array.isArray(data.modified) ? data.modified : [];
                const removed = Array.isArray(data.removed) ? data.removed : [];
                const diffFromApi = [...added, ...modified, ...removed];

                // If backend returns no diff but frontend detects mismatch (fallback), use local diff
                // But local diff only detects additions. Ideally backend is source of truth.
                const computedDiff = computeLocalDiff(current);
                const finalDiff = diffFromApi.length > 0 ? diffFromApi : (computedDiff.length > 0 ? computedDiff : []);

                setFuncPoints(current);
                setPendingDiff(finalDiff);
            } else {
                throw new Error(`diff failed: ${res.status}`);
            }
        } catch (err) {
            // Fallback to front-end diff to still give user a prompt
            const baseline = permissionManifest.filter((p) => p.level < 2);
            setFuncPoints(baseline);
            const diff = computeLocalDiff(baseline);
            setPendingDiff(diff);
            if (manual) {
                setSyncError('后端差异接口不可用，已使用前端扫描结果（manifest）。');
            }
        } finally {
            setIsScanning(false);
        }
    };

    useEffect(() => {
        loadAndDiff();
    }, []);

    const handleApplyToDb = async () => {
        setIsApplying(true);
        setSyncError(null);
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/permissions/sync', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ items: permissionManifest, meta: manifestMeta }),
            });
            if (!res.ok) {
                throw new Error(`sync failed: ${res.status}`);
            }
        } catch (err) {
            setSyncError('同步接口调用失败，已更新前端展示，请稍后重试。');
        } finally {
            setFuncPoints(permissionManifest);
            setPendingDiff([]);
            lastSyncedSignature.current = manifestSignature;
            localStorage.setItem('permission_manifest_synced', manifestSignature);
            setIsApplying(false);
        }
    };

    return (
        <div className="space-y-4 animate-fade-in">
            <div className="flex flex-col gap-2">
                {isScanning && (
                    <div className="flex items-center gap-2 text-sm text-slate-600 bg-slate-100 border border-slate-200 px-3 py-2 rounded">
                        <RefreshCw className="w-4 h-4 animate-spin text-amber-500" />
                        正在与数据库对比最新的功能点，请稍候...
                    </div>
                )}
                {!isScanning && pendingDiff.length > 0 && (
                    <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <div className="p-2 bg-amber-100 rounded-full text-amber-600">
                                <AlertCircle size={20} />
                            </div>
                            <div>
                                <h3 className="font-medium text-amber-900">权限配置更新</h3>
                                <p className="text-sm text-amber-700">
                                    检测到本地权限配置(manifest)与数据库不一致:
                                    差异数量 {pendingDiff.length} 项
                                </p>
                            </div>
                        </div>
                        <Auth code="sys:menu:sync">
                            <button
                                onClick={handleApplyToDb}
                                disabled={isApplying}
                                className="px-4 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors text-sm font-medium flex items-center gap-2 disabled:opacity-70"
                            >
                                {isApplying ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
                                立即同步
                            </button>
                        </Auth>
                    </div>
                )}
                {syncError && (
                    <div className="text-xs text-red-600 bg-red-50 border border-red-200 px-3 py-2 rounded">
                        {syncError}
                    </div>
                )}
            </div>

            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-4 rounded-lg border border-slate-200">
                <div className="flex items-center gap-2">
                    <span className="font-bold text-slate-700">功能资源维护</span>
                    <span className="text-xs text-slate-400 bg-slate-100 px-2 py-1 rounded">
                        manifest v{manifestMeta.version}
                    </span>
                </div>
                <div className="flex items-center gap-2 w-full sm:w-auto">
                    <div className="relative flex-1 sm:w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                        <input
                            type="text"
                            placeholder="搜索菜单或按钮权限..."
                            className="w-full pl-9 pr-3 py-2 border border-slate-200 rounded-md text-sm focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none"
                        />
                    </div>

                    <Auth code="sys:menu:add">
                        <button className="flex items-center gap-1 bg-red-600 text-white px-3 py-2 rounded-md text-sm font-medium hover:bg-red-700 transition-colors shadow-sm">
                            <Plus className="w-4 h-4" />
                            <span className="hidden sm:inline">新增</span>
                        </button>
                    </Auth>
                </div>
            </div>

            <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
                <div className="p-4 bg-slate-50 border-b border-slate-200 grid grid-cols-12 gap-4 font-bold text-sm text-slate-700">
                    <div className="col-span-4">资源名称</div>
                    <div className="col-span-3">权限标识 (Code)</div>
                    <div className="col-span-2">类型</div>
                    <div className="col-span-2">路由路径</div>
                    <div className="col-span-1 text-right">操作</div>
                </div>
                <div className="divide-y divide-slate-100 max-h-[600px] overflow-y-auto custom-scrollbar">
                    {funcPoints.map((item) => (
                        <div key={item.id} className="p-4 grid grid-cols-12 gap-4 items-center hover:bg-slate-50 transition-colors group animate-fade-in">
                            <div className="col-span-4 flex items-center gap-2" style={{ paddingLeft: `${item.level * 24}px` }}>
                                {item.level > 0 && <span className="text-slate-300">└─</span>}
                                {item.type === 'dir' && <FolderTree className="w-4 h-4 text-slate-500" />}
                                {item.type === 'menu' && <FileText className="w-4 h-4 text-red-600" />}
                                {item.type === 'button' && <MousePointerClick className="w-4 h-4 text-amber-500" />}
                                <span className={`font-medium ${item.type === 'button' ? 'text-slate-600' : 'text-slate-800'}`}>{item.name}</span>
                            </div>
                            <div className="col-span-3 text-xs text-slate-500 font-mono bg-slate-100 px-2 py-1 rounded w-fit">
                                {item.code}
                            </div>
                            <div className="col-span-2">
                                <span className={`text-xs px-2 py-1 rounded border 
                            ${item.type === 'dir' ? 'bg-slate-100 text-slate-600 border-slate-200' : ''}
                            ${item.type === 'menu' ? 'bg-indigo-50 text-indigo-700 border-indigo-100' : ''}
                            ${item.type === 'button' ? 'bg-amber-50 text-amber-700 border-amber-100' : ''}
                        `}>
                                    {item.type === 'dir' ? '目录' : item.type === 'menu' ? '菜单' : '按钮'}
                                </span>
                            </div>
                            <div className="col-span-2 text-xs text-slate-400 font-mono truncate">{item.path}</div>
                            <div className="col-span-1 text-right opacity-0 group-hover:opacity-100 transition-opacity">
                                <div className="flex items-center justify-end gap-2">
                                    <Auth code="sys:menu:edit">
                                        <button className="text-slate-400 hover:text-blue-600"><Edit className="w-4 h-4" /></button>
                                    </Auth>
                                    <Auth code="sys:menu:del">
                                        <button className="text-slate-400 hover:text-red-600"><Trash2 className="w-4 h-4" /></button>
                                    </Auth>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
                <div className="p-3 bg-slate-50 border-t border-slate-200 text-xs text-slate-500 flex justify-between items-center">
                    <span>已加载 {funcPoints.length} 个功能点</span>

                </div>
            </div>
        </div>
    );
}

export default MenuManagement;
