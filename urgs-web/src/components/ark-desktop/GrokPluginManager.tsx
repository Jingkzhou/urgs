import React, { useCallback, useEffect, useState } from 'react';
import {
    CheckCircle2, ChevronDown, ChevronUp, FolderPlus, GitBranch, LoaderCircle,
    Plug, Plus, RefreshCw, ShieldAlert, Trash2,
} from 'lucide-react';
import {
    chooseGrokPluginDirectory,
    addGrokMarketplaceSource,
    getGrokPluginDetails,
    installGrokMarketplacePlugin,
    installTrustedLocalGrokPlugin,
    listGrokPluginMarketplace,
    listGrokMarketplaceSources,
    listGrokInstalledPlugins,
    setGrokPluginEnabled,
    removeGrokMarketplaceSource,
    uninstallGrokPlugin,
    updateGrokPlugin,
    updateGrokMarketplaceSource,
    validateGrokPluginDirectory,
    type GrokInstalledPlugin,
    type GrokPluginComponents,
    type GrokPluginDetails,
    type GrokMarketplaceSource,
} from '@/services/grokDesktop';

interface GrokPluginManagerProps {
    workspace: string;
    onChanged: () => Promise<void>;
    onError: (message: string) => void;
}

const componentLabels = (components: GrokPluginComponents) => {
    const labels: string[] = [];
    if (components.skillDirectories) labels.push(`${components.skillDirectories} 个技能目录`);
    if (components.commandDirectories) labels.push(`${components.commandDirectories} 个命令目录`);
    if (components.agentDirectories) labels.push(`${components.agentDirectories} 个 Agent 目录`);
    if (components.hasHooks) labels.push('Hooks');
    if (components.hasMcpServers) labels.push('MCP 服务');
    if (components.hasLspServers) labels.push('LSP 服务');
    return labels.length ? labels.join('、') : '未声明可加载组件';
};

interface MarketplacePlugin {
    name: string;
    version?: string;
    description?: string;
    marketplace?: string;
    installed?: boolean;
}

const normalizeMarketplacePlugins = (value: unknown): MarketplacePlugin[] => {
    const sources = Array.isArray(value)
        ? value
        : value && typeof value === 'object'
            ? Object.values(value as Record<string, unknown>).flatMap((item) => Array.isArray(item) ? item : item && typeof item === 'object' && Array.isArray((item as Record<string, unknown>).plugins) ? (item as Record<string, unknown>).plugins as unknown[] : [])
            : [];
    return sources.flatMap((item) => {
        if (!item || typeof item !== 'object') return [];
        const plugin = item as Record<string, unknown>;
        const name = String(plugin.name || plugin.id || plugin.plugin || '').trim();
        if (!name) return [];
        return [{
            name,
            version: typeof plugin.version === 'string' ? plugin.version : undefined,
            description: typeof plugin.description === 'string' ? plugin.description : undefined,
            marketplace: typeof plugin.marketplace === 'string' ? plugin.marketplace : typeof plugin.source === 'string' ? plugin.source : undefined,
            installed: plugin.installed === true,
        }];
    });
};

const GrokPluginManager: React.FC<GrokPluginManagerProps> = ({ workspace, onChanged, onError }) => {
    const [plugins, setPlugins] = useState<GrokInstalledPlugin[]>([]);
    const [details, setDetails] = useState<Record<string, GrokPluginDetails>>({});
    const [expandedId, setExpandedId] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const [pendingId, setPendingId] = useState<string | null>(null);
    const [marketplace, setMarketplace] = useState<MarketplacePlugin[]>([]);
    const [marketplaceSources, setMarketplaceSources] = useState<GrokMarketplaceSource[]>([]);
    const [marketplaceQuery, setMarketplaceQuery] = useState('');
    const [newMarketplaceSource, setNewMarketplaceSource] = useState('');
    const [marketplaceLoading, setMarketplaceLoading] = useState(false);

    const reportError = useCallback((error: unknown) => {
        onError(error instanceof Error ? error.message : String(error));
    }, [onError]);

    const refresh = useCallback(async () => {
        setLoading(true);
        try {
            setPlugins(await listGrokInstalledPlugins(workspace));
        } catch (error) {
            reportError(error);
        } finally {
            setLoading(false);
        }
    }, [workspace, reportError]);

    useEffect(() => { void refresh(); }, [refresh]);

    const refreshMarketplace = useCallback(async () => {
        setMarketplaceLoading(true);
        try {
            setMarketplaceSources(await listGrokMarketplaceSources(workspace));
        } catch (error) {
            reportError(error);
        }
        try {
            setMarketplace(normalizeMarketplacePlugins(await listGrokPluginMarketplace(workspace)));
        } catch (error) {
            reportError(error);
        } finally {
            setMarketplaceLoading(false);
        }
    }, [reportError, workspace]);

    const addMarketplace = async () => {
        const source = newMarketplaceSource.trim();
        if (!source) return;
        if (!window.confirm(`确认添加插件市场源“${source}”吗？添加后会读取该来源中的插件清单。`)) return;
        setPendingId('market-source:add');
        try {
            await addGrokMarketplaceSource(source, workspace);
            setNewMarketplaceSource('');
            await Promise.all([refreshMarketplace(), onChanged()]);
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const updateMarketplace = async (source: GrokMarketplaceSource) => {
        setPendingId(`market-source:update:${source.name}`);
        try {
            await updateGrokMarketplaceSource(source.url, workspace);
            await refreshMarketplace();
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const removeMarketplace = async (source: GrokMarketplaceSource) => {
        if (!window.confirm(`确认移除市场源“${source.name}”吗？这会同时卸载该来源安装的插件。`)) return;
        setPendingId(`market-source:remove:${source.name}`);
        try {
            await removeGrokMarketplaceSource(source.url, workspace);
            await Promise.all([refreshMarketplace(), onChanged()]);
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const addLocalPlugin = async () => {
        const path = await chooseGrokPluginDirectory();
        if (!path) return;
        setPendingId('install');
        try {
            const validation = await validateGrokPluginDirectory(path, workspace);
            const summary = componentLabels(validation.components);
            const confirmed = window.confirm(
                `确认信任并安装本地插件“${validation.name}”吗？\n\n` +
                `${validation.description || '该插件未提供说明'}\n组件：${summary}\n\n` +
                '插件可能在本机运行 Hooks、MCP/LSP 服务和技能。请仅安装你已审查并信任的目录。',
            );
            if (!confirmed) return;
            await installTrustedLocalGrokPlugin(path, workspace);
            await Promise.all([refresh(), onChanged()]);
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const togglePlugin = async (plugin: GrokInstalledPlugin) => {
        setPendingId(plugin.id);
        try {
            await setGrokPluginEnabled(plugin.name, !plugin.enabled, workspace);
            await Promise.all([refresh(), onChanged()]);
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const toggleDetails = async (plugin: GrokInstalledPlugin) => {
        if (expandedId === plugin.id) {
            setExpandedId(null);
            return;
        }
        setExpandedId(plugin.id);
        if (details[plugin.id]) return;
        setPendingId(`details:${plugin.id}`);
        try {
            const value = await getGrokPluginDetails(plugin, workspace);
            setDetails((current) => ({ ...current, [plugin.id]: value }));
        } catch (error) {
            setExpandedId(null);
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const updatePlugin = async (plugin?: GrokInstalledPlugin) => {
        const label = plugin ? `“${plugin.name}”` : '全部插件';
        if (!window.confirm(`确认更新${label}吗？更新可能会替换插件中的可执行组件。`)) return;
        setPendingId(plugin ? `update:${plugin.id}` : 'update-all');
        try {
            await updateGrokPlugin(plugin?.name, workspace);
            await Promise.all([refresh(), onChanged()]);
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const uninstallPlugin = async (plugin: GrokInstalledPlugin) => {
        if (!window.confirm(`确认卸载插件“${plugin.name}”吗？这会移除插件及其已加载组件。`)) return;
        setPendingId(`uninstall:${plugin.id}`);
        try {
            await uninstallGrokPlugin(plugin.name, workspace);
            await Promise.all([refresh(), onChanged()]);
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const installMarketplace = async (plugin: MarketplacePlugin) => {
        if (!window.confirm(`确认信任并安装市场插件“${plugin.name}”吗？\n\n${plugin.description || '该插件未提供说明'}\n\n安装后它可能加载本地 Hooks、MCP 或其他可执行组件。`)) return;
        setPendingId(`market:${plugin.name}`);
        try {
            await installGrokMarketplacePlugin(plugin.name, workspace);
            await Promise.all([refresh(), refreshMarketplace(), onChanged()]);
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    return <div className="space-y-5" role="tabpanel">
        <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <div className="flex flex-wrap items-start justify-between gap-3">
                <div><h2 className="text-xl font-semibold text-slate-900">插件生命周期</h2><p className="mt-1 max-w-2xl text-sm leading-6 text-slate-500">在页面内完成本地插件校验、安装、启停、更新和卸载；已配置市场的安装也保留明确的信任确认。</p></div>
                <div className="flex items-center gap-2"><button type="button" disabled={loading || pendingId !== null} onClick={() => void refresh()} className="rounded-xl border border-slate-200 p-2.5 text-slate-500 transition hover:bg-slate-50 disabled:opacity-40" title="刷新插件"><RefreshCw size={16} className={loading ? 'animate-spin' : ''} /></button><button type="button" disabled={pendingId !== null} onClick={() => void updatePlugin()} className="rounded-xl border border-slate-200 px-3 py-2.5 text-xs font-medium text-slate-600 disabled:opacity-40">更新全部</button><button type="button" disabled={pendingId !== null} onClick={() => void addLocalPlugin()} className="flex items-center gap-2 rounded-xl bg-slate-900 px-3.5 py-2.5 text-sm font-medium text-white disabled:opacity-40">{pendingId === 'install' ? <LoaderCircle size={16} className="animate-spin" /> : <FolderPlus size={16} />}添加本地插件</button></div>
            </div>
            <div className="mt-4 flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 px-3.5 py-3 text-xs leading-5 text-amber-800"><ShieldAlert size={16} className="mt-0.5 shrink-0" /><span>安装前会先运行清单校验并展示组件摘要；确认安装即代表信任该目录中的可执行组件。启用状态会同步到后续新会话，已打开会话保持原状态。</span></div>
        </div>

        {loading && plugins.length === 0 ? <div className="flex items-center justify-center rounded-2xl border border-slate-200 bg-white py-16 text-sm text-slate-400"><LoaderCircle size={18} className="mr-2 animate-spin" />正在读取插件</div> : plugins.length === 0 ? <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-6 py-16 text-center"><Plug size={28} className="mx-auto text-slate-300" /><h3 className="mt-3 font-medium text-slate-700">尚未安装本地插件</h3><p className="mt-1 text-sm text-slate-400">选择包含 plugin.json 或标准组件目录的本机文件夹开始。</p></div> : <div className="space-y-3">{plugins.map((plugin) => {
            const detail = details[plugin.id];
            const expanded = expandedId === plugin.id;
            const pending = pendingId === plugin.id;
            return <div key={plugin.id} className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
                <div className="flex flex-wrap items-center justify-between gap-4 p-5">
                    <div className="min-w-0"><div className="flex flex-wrap items-center gap-2"><span className="font-semibold text-slate-900">{plugin.name}</span>{plugin.version && <span className="rounded-md bg-slate-100 px-2 py-0.5 text-[11px] text-slate-500">v{plugin.version}</span>}<span className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] ${plugin.enabled ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'}`}>{plugin.enabled && <CheckCircle2 size={11} />}{plugin.enabled ? '已启用' : '已禁用'}</span></div><p className="mt-1 max-w-2xl truncate text-xs text-slate-400" title={plugin.source || plugin.path}>{plugin.marketplace || plugin.source || plugin.path || '本地来源'}</p></div>
                    <div className="flex items-center gap-2"><button type="button" disabled={pendingId !== null} onClick={() => void toggleDetails(plugin)} className="flex items-center gap-1 rounded-lg border border-slate-200 px-2.5 py-2 text-xs text-slate-600 disabled:opacity-40">{pendingId === `details:${plugin.id}` ? <LoaderCircle size={13} className="animate-spin" /> : expanded ? <ChevronUp size={13} /> : <ChevronDown size={13} />}详情</button><button type="button" disabled={pendingId !== null} onClick={() => void updatePlugin(plugin)} className="rounded-lg border border-slate-200 px-2.5 py-2 text-xs text-slate-600 disabled:opacity-40">{pendingId === `update:${plugin.id}` ? <LoaderCircle size={13} className="animate-spin" /> : '更新'}</button><button type="button" disabled={pendingId !== null} onClick={() => void togglePlugin(plugin)} className={`rounded-lg px-3 py-2 text-xs font-medium disabled:opacity-40 ${plugin.enabled ? 'bg-slate-100 text-slate-600' : 'bg-slate-900 text-white'}`}>{pending ? <LoaderCircle size={13} className="animate-spin" /> : plugin.enabled ? '禁用' : '启用'}</button><button type="button" disabled={pendingId !== null} onClick={() => void uninstallPlugin(plugin)} className="rounded-lg border border-red-200 px-2.5 py-2 text-xs text-red-600 disabled:opacity-40">{pendingId === `uninstall:${plugin.id}` ? <LoaderCircle size={13} className="animate-spin" /> : '卸载'}</button></div>
                </div>
                {expanded && detail && <div className="border-t border-slate-100 bg-slate-50/70 px-5 py-4"><p className="text-sm text-slate-600">{detail.description || '该插件未提供说明。'}</p><div className="mt-3 grid gap-2 text-xs text-slate-500 sm:grid-cols-2"><div className="rounded-lg bg-white px-3 py-2"><span className="font-medium text-slate-700">组件</span><p className="mt-1 leading-5">{componentLabels(detail.components)}</p></div><div className="rounded-lg bg-white px-3 py-2"><span className="font-medium text-slate-700">安装路径</span><p className="mt-1 break-all leading-5">{detail.path || plugin.path}</p></div></div></div>}
            </div>;
        })}</div>}
        <div className="rounded-2xl border border-slate-200 bg-white p-5"><div className="flex flex-wrap items-start justify-between gap-3"><div><h3 className="font-semibold text-slate-900">插件市场</h3><p className="mt-1 text-sm leading-6 text-slate-500">市场源、可用插件和安装信任分开管理；版本能力以当前 ACP 运行时实际声明为准。</p></div><button type="button" disabled={marketplaceLoading || pendingId !== null} onClick={() => void refreshMarketplace()} className="flex items-center gap-1.5 rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-40"><RefreshCw size={14} className={marketplaceLoading ? 'animate-spin' : ''} />读取市场</button></div><div className="mt-4 rounded-xl border border-indigo-100 bg-indigo-50/60 p-3.5"><div className="flex items-center gap-2 text-xs font-medium text-indigo-800"><GitBranch size={14} />市场源</div><div className="mt-2 flex flex-wrap gap-2"><input value={newMarketplaceSource} onChange={(event) => setNewMarketplaceSource(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') void addMarketplace(); }} placeholder="Git URL、GitHub 简写或本地路径" className="min-w-[240px] flex-1 rounded-lg border border-indigo-200 bg-white px-3 py-2 text-xs text-slate-700 outline-none placeholder:text-slate-400 focus:border-indigo-400" /><button type="button" disabled={pendingId !== null || !newMarketplaceSource.trim()} onClick={() => void addMarketplace()} className="flex items-center gap-1.5 rounded-lg bg-indigo-600 px-3 py-2 text-xs font-medium text-white disabled:opacity-40">{pendingId === 'market-source:add' ? <LoaderCircle size={13} className="animate-spin" /> : <Plus size={13} />}添加源</button></div>{marketplaceSources.length > 0 && <div className="mt-3 space-y-1.5">{marketplaceSources.map((source) => <div key={`${source.name}:${source.url}`} className="flex flex-wrap items-center gap-2 rounded-lg bg-white px-3 py-2"><div className="min-w-0 flex-1"><div className="flex items-center gap-2 text-xs font-medium text-slate-700"><span className="truncate">{source.name}</span><span className="rounded bg-slate-100 px-1.5 py-0.5 text-[10px] text-slate-500">{source.kind}</span></div><p className="mt-0.5 truncate text-[10px] text-slate-400" title={source.url}>{source.url}{source.branch ? ` · ${source.branch}` : ''}</p></div><button type="button" disabled={pendingId !== null} onClick={() => void updateMarketplace(source)} className="rounded-md px-2 py-1 text-[10px] text-slate-600 hover:bg-slate-50 disabled:opacity-40">{pendingId === `market-source:update:${source.name}` ? <LoaderCircle size={12} className="animate-spin" /> : '刷新'}</button><button type="button" disabled={pendingId !== null} onClick={() => void removeMarketplace(source)} className="rounded-md px-2 py-1 text-[10px] text-red-600 hover:bg-red-50 disabled:opacity-40">{pendingId === `market-source:remove:${source.name}` ? <LoaderCircle size={12} className="animate-spin" /> : <Trash2 size={12} />}</button></div>)}</div>}{!marketplaceLoading && marketplaceSources.length === 0 && <p className="mt-2 text-[10px] text-indigo-600/70">尚未读取市场源。</p>}</div><div className="mt-4 flex flex-wrap items-center justify-between gap-2"><div><h4 className="text-sm font-medium text-slate-800">可用插件</h4><p className="mt-0.5 text-[10px] text-slate-400">只展示前 20 个匹配项，避免大型市场索引阻塞界面。</p></div><input value={marketplaceQuery} onChange={(event) => setMarketplaceQuery(event.target.value)} placeholder="搜索插件" className="w-44 rounded-lg border border-slate-200 px-2.5 py-1.5 text-xs text-slate-600 outline-none focus:border-indigo-300" /></div>{marketplace.length > 0 && <div className="mt-3 space-y-2">{marketplace.filter((plugin) => { const query = marketplaceQuery.trim().toLowerCase(); return !query || `${plugin.name} ${plugin.description || ''} ${plugin.marketplace || ''}`.toLowerCase().includes(query); }).slice(0, 20).map((plugin) => <div key={`${plugin.marketplace || 'market'}:${plugin.name}`} className="flex flex-wrap items-center gap-3 rounded-xl border border-slate-200 px-3.5 py-3"><div className="min-w-0 flex-1"><div className="flex items-center gap-2"><span className="font-medium text-slate-800">{plugin.name}</span>{plugin.version && <span className="text-[10px] text-slate-400">v{plugin.version}</span>}</div><p className="mt-1 truncate text-xs text-slate-400">{plugin.description || plugin.marketplace || '市场插件'}</p></div><button type="button" disabled={pendingId !== null || plugin.installed} onClick={() => void installMarketplace(plugin)} className="rounded-lg bg-slate-900 px-3 py-2 text-xs font-medium text-white disabled:cursor-not-allowed disabled:opacity-40">{pendingId === `market:${plugin.name}` ? <LoaderCircle size={13} className="animate-spin" /> : plugin.installed ? '已安装' : '信任并安装'}</button></div>)}</div>}{!marketplaceLoading && marketplace.length === 0 && <p className="mt-4 text-xs text-slate-400">尚未读取市场源，或当前没有可用市场插件。</p>}</div>
    </div>;
};

export default GrokPluginManager;
