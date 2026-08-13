import React, { useMemo, useState } from 'react';
import {
    CheckCircle2,
    ChevronDown,
    GitBranch,
    LoaderCircle,
    PackagePlus,
    Plus,
    RefreshCw,
    Search,
    ShieldCheck,
    Trash2,
} from 'lucide-react';
import type { GrokInstalledPlugin, GrokMarketplacePlugin, GrokMarketplaceSource } from '@/services/grokDesktop';
import GrokPluginComponentBadges from './GrokPluginComponentBadges';

interface GrokPluginMarketplaceTabProps {
    plugins: GrokMarketplacePlugin[];
    installedPlugins: GrokInstalledPlugin[];
    sources: GrokMarketplaceSource[];
    loading: boolean;
    pendingId: string | null;
    onRefresh: () => Promise<void>;
    onAddSource: (source: string) => Promise<void>;
    onUpdateSource: (source: GrokMarketplaceSource) => Promise<void>;
    onRemoveSource: (source: GrokMarketplaceSource) => Promise<void>;
    onInstall: (plugin: GrokMarketplacePlugin) => Promise<void>;
}

const componentGroups = (plugin: GrokMarketplacePlugin) => [
    ['Skills', plugin.components.skills],
    ['Commands', plugin.components.commands],
    ['Agents', plugin.components.agents],
    ['MCP Servers', plugin.components.mcpServers],
    ['Hooks', plugin.components.hooks],
    ['LSP Servers', plugin.components.lspServers],
] as const;

type CapabilityFilter = 'all' | 'skills' | 'mcp' | 'hooks' | 'combined' | 'undeclared';

const componentCount = (plugin: GrokMarketplacePlugin) => componentGroups(plugin)
    .reduce((total, [, items]) => total + items.length, 0);

const matchesCapability = (plugin: GrokMarketplacePlugin, capability: CapabilityFilter) => {
    if (capability === 'all') return true;
    if (capability === 'skills') return plugin.components.skills.length > 0;
    if (capability === 'mcp') return plugin.components.mcpServers.length > 0;
    if (capability === 'hooks') return plugin.components.hooks.length > 0;
    if (capability === 'combined') return componentGroups(plugin).filter(([, items]) => items.length > 0).length > 1;
    return componentCount(plugin) === 0;
};

const GrokPluginMarketplaceTab: React.FC<GrokPluginMarketplaceTabProps> = ({
    plugins,
    installedPlugins,
    sources,
    loading,
    pendingId,
    onRefresh,
    onAddSource,
    onUpdateSource,
    onRemoveSource,
    onInstall,
}) => {
    const [sourceInput, setSourceInput] = useState('');
    const [query, setQuery] = useState('');
    const [selectedSource, setSelectedSource] = useState('all');
    const [selectedCapability, setSelectedCapability] = useState<CapabilityFilter>('all');
    const [visibleCount, setVisibleCount] = useState(24);

    const filteredPlugins = useMemo(() => {
        const normalizedQuery = query.trim().toLowerCase();
        return plugins.filter((plugin) => {
            if (selectedSource !== 'all' && plugin.marketplace !== selectedSource) return false;
            if (!matchesCapability(plugin, selectedCapability)) return false;
            if (!normalizedQuery) return true;
            const componentText = componentGroups(plugin)
                .flatMap(([label, items]) => [label, ...items.flatMap((item) => [item.name, item.description])]);
            const haystack = [
                plugin.name,
                plugin.description,
                plugin.marketplace,
                plugin.category,
                plugin.author,
                ...plugin.tags,
                ...plugin.keywords,
                ...plugin.domains,
                ...componentText,
            ].filter(Boolean).join(' ').toLowerCase();
            return haystack.includes(normalizedQuery);
        });
    }, [plugins, query, selectedCapability, selectedSource]);

    const submitSource = async () => {
        const source = sourceInput.trim();
        if (!source) return;
        await onAddSource(source);
        setSourceInput('');
    };

    return <div className="space-y-5">
        <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
            <div className="flex flex-wrap items-start justify-between gap-3 border-b border-slate-100 px-5 py-4">
                <div>
                    <div className="flex items-center gap-2">
                        <GitBranch size={17} className="text-indigo-600" />
                        <h3 className="font-semibold text-slate-900">内网市场连接</h3>
                    </div>
                    <p className="mt-1 text-sm leading-6 text-slate-500">连接 GitLab 仓库后，客户端读取市场清单并从指定来源安装插件。</p>
                </div>
                <button
                    type="button"
                    disabled={loading || pendingId !== null}
                    onClick={() => void onRefresh()}
                    className="flex min-h-10 items-center gap-2 rounded-xl border border-slate-200 px-3 text-xs font-medium text-slate-600 transition hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 disabled:opacity-40"
                >
                    <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />刷新市场
                </button>
            </div>

            <div className="bg-slate-50/70 px-5 py-4">
                <label className="text-xs font-medium text-slate-700" htmlFor="grok-marketplace-source">GitLab 仓库地址</label>
                <div className="mt-2 flex flex-col gap-2 sm:flex-row">
                    <input
                        id="grok-marketplace-source"
                        value={sourceInput}
                        onChange={(event) => setSourceInput(event.target.value)}
                        onKeyDown={(event) => { if (event.key === 'Enter') void submitSource(); }}
                        placeholder="git@gitlab.intra.example:ai/grok-plugin-marketplace.git"
                        className="min-h-11 min-w-0 flex-1 rounded-xl border border-slate-200 bg-white px-3.5 text-sm text-slate-700 outline-none transition placeholder:text-slate-400 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100"
                    />
                    <button
                        type="button"
                        disabled={pendingId !== null || !sourceInput.trim()}
                        onClick={() => void submitSource()}
                        className="flex min-h-11 items-center justify-center gap-2 rounded-xl bg-slate-900 px-4 text-sm font-medium text-white transition hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-500 disabled:opacity-40"
                    >
                        {pendingId === 'market-source:add' ? <LoaderCircle size={15} className="animate-spin" /> : <Plus size={15} />}
                        连接仓库
                    </button>
                </div>
                <div className="mt-3 flex items-start gap-2 text-xs leading-5 text-slate-500">
                    <ShieldCheck size={14} className="mt-0.5 shrink-0 text-emerald-600" />
                    <span>推荐使用 SSH 地址或系统 Git 凭据，不要把账号、密码或 Access Token 写入仓库 URL。</span>
                </div>
            </div>

            {sources.length > 0 && <div className="divide-y divide-slate-100">
                {sources.map((source) => <div key={`${source.name}:${source.url}`} className="flex flex-wrap items-center gap-3 px-5 py-3">
                    <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-emerald-50 text-emerald-700"><CheckCircle2 size={17} /></span>
                    <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2">
                            <span className="font-medium text-slate-800">{source.name}</span>
                            <span className="rounded-md bg-slate-100 px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide text-slate-500">{source.kind}</span>
                        </div>
                        <p className="mt-0.5 truncate text-xs text-slate-500" title={source.url}>{source.url}{source.branch ? ` · ${source.branch}` : ''}</p>
                    </div>
                    <div className="flex items-center gap-1">
                        <button type="button" disabled={pendingId !== null} onClick={() => void onUpdateSource(source)} className="min-h-9 rounded-lg px-3 text-xs font-medium text-slate-600 transition hover:bg-slate-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 disabled:opacity-40">
                            {pendingId === `market-source:update:${source.name}` ? <LoaderCircle size={13} className="animate-spin" /> : '同步'}
                        </button>
                        <button type="button" disabled={pendingId !== null} onClick={() => void onRemoveSource(source)} className="flex h-9 w-9 items-center justify-center rounded-lg text-red-600 transition hover:bg-red-50 hover:text-red-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-500 disabled:opacity-40" title={`移除 ${source.name}`} aria-label={`移除 ${source.name}`}>
                            {pendingId === `market-source:remove:${source.name}` ? <LoaderCircle size={13} className="animate-spin" /> : <Trash2 size={14} />}
                        </button>
                    </div>
                </div>)}
            </div>}
        </section>

        <section>
            <div className="flex flex-col gap-3">
                <div>
                    <h3 className="font-semibold text-slate-900">可安装插件</h3>
                    <p className="mt-1 text-sm text-slate-500">先按能力类型筛选，再确认插件包含的 Skills、MCP 或 Hooks；无需安装后猜测。</p>
                </div>
                <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-[minmax(220px,1fr)_160px_180px]">
                    <label className="relative block">
                        <Search size={15} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input value={query} onChange={(event) => { setQuery(event.target.value); setVisibleCount(24); }} placeholder="搜索名称、能力或标签" className="min-h-10 w-full rounded-xl border border-slate-200 bg-white pl-9 pr-3 text-sm text-slate-700 outline-none transition placeholder:text-slate-400 focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100" />
                    </label>
                    <select value={selectedSource} onChange={(event) => { setSelectedSource(event.target.value); setVisibleCount(24); }} className="min-h-10 rounded-xl border border-slate-200 bg-white px-3 text-sm text-slate-600 outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100" aria-label="筛选市场源">
                        <option value="all">全部市场源</option>
                        {Array.from(new Set(plugins.map((plugin) => plugin.marketplace))).map((source) => <option key={source} value={source}>{source}</option>)}
                    </select>
                    <select value={selectedCapability} onChange={(event) => { setSelectedCapability(event.target.value as CapabilityFilter); setVisibleCount(24); }} className="min-h-10 rounded-xl border border-slate-200 bg-white px-3 text-sm text-slate-600 outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100" aria-label="筛选插件能力类型">
                        <option value="all">全部能力类型</option>
                        <option value="skills">包含 Skills</option>
                        <option value="mcp">包含 MCP Servers</option>
                        <option value="hooks">包含 Hooks</option>
                        <option value="combined">组合能力插件</option>
                        <option value="undeclared">能力类型未声明</option>
                    </select>
                </div>
            </div>

            {loading && plugins.length === 0 ? <div className="mt-4 flex min-h-52 items-center justify-center rounded-2xl border border-slate-200 bg-white text-sm text-slate-500"><LoaderCircle size={18} className="mr-2 animate-spin" />正在读取市场索引</div> : filteredPlugins.length === 0 ? <div className="mt-4 rounded-2xl border border-dashed border-slate-300 bg-white px-6 py-14 text-center"><PackagePlus size={28} className="mx-auto text-slate-300" /><p className="mt-3 font-medium text-slate-700">没有找到可安装插件</p><p className="mt-1 text-sm text-slate-500">请连接内网 GitLab 市场，或调整搜索条件。</p></div> : <div className="mt-4 grid gap-3 lg:grid-cols-2">
                {filteredPlugins.slice(0, visibleCount).map((plugin) => {
                    const groups = componentGroups(plugin).filter(([, items]) => items.length > 0);
                    const pending = pendingId === `market:${plugin.marketplace}:${plugin.name}`;
                    const installedPlugin = installedPlugins.find((installed) => installed.name === plugin.name && installed.marketplace === plugin.marketplace);
                    return <article key={`${plugin.marketplace}:${plugin.name}`} className="flex min-w-0 flex-col rounded-2xl border border-slate-200 bg-white p-4 transition hover:border-slate-300 hover:shadow-[0_10px_30px_rgba(15,23,42,0.06)]">
                        <div className="flex items-start gap-3">
                            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-indigo-700"><PackagePlus size={18} /></span>
                            <div className="min-w-0 flex-1">
                                <div className="flex flex-wrap items-center gap-2">
                                    <h4 className="font-semibold text-slate-900">{plugin.name}</h4>
                                    {plugin.version && <span className="text-xs tabular-nums text-slate-400">v{plugin.version}</span>}
                                </div>
                                <p className="mt-0.5 truncate text-xs font-medium text-indigo-700" title={plugin.marketplace}>{plugin.marketplace}</p>
                            </div>
                            <button type="button" disabled={pendingId !== null || Boolean(installedPlugin)} onClick={() => void onInstall(plugin)} className={`flex min-h-9 shrink-0 items-center gap-1.5 rounded-lg px-3 text-xs font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-500 disabled:cursor-default ${installedPlugin ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-900 text-white hover:bg-slate-800 disabled:opacity-40'}`}>
                                {pending ? <LoaderCircle size={13} className="animate-spin" /> : installedPlugin ? <CheckCircle2 size={13} /> : <PackagePlus size={13} />}
                                {installedPlugin ? (installedPlugin.enabled ? '已安装' : '已禁用') : '安装'}
                            </button>
                        </div>
                        <p className="mt-3 line-clamp-2 min-h-10 text-sm leading-5 text-slate-600">{plugin.description || '该插件未提供说明。'}</p>
                        <div className="mt-3"><GrokPluginComponentBadges catalog={plugin.components} undeclaredWarning /></div>
                        {(plugin.category || plugin.author || plugin.tags.length > 0) && <div className="mt-3 flex flex-wrap gap-1.5 text-[11px] text-slate-500">
                            {plugin.category && <span className="rounded-md bg-slate-100 px-2 py-1">{plugin.category}</span>}
                            {plugin.author && <span className="rounded-md bg-slate-100 px-2 py-1">{plugin.author}</span>}
                            {plugin.tags.slice(0, 3).map((tag) => <span key={tag} className="rounded-md bg-slate-100 px-2 py-1">{tag}</span>)}
                        </div>}
                        {groups.length > 0 && <details className="group mt-3 border-t border-slate-100 pt-3">
                            <summary className="flex cursor-pointer list-none items-center justify-between text-xs font-medium text-slate-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500">
                                查看组件清单
                                <ChevronDown size={14} className="transition group-open:rotate-180" />
                            </summary>
                            <div className="mt-3 space-y-2">
                                {groups.map(([label, items]) => <div key={label} className="grid gap-1 sm:grid-cols-[104px_1fr]">
                                    <span className="text-xs font-medium text-slate-500">{label}</span>
                                    <span className="text-xs leading-5 text-slate-600">{items.slice(0, 8).map((item) => item.name).join('、')}{items.length > 8 ? ` 等 ${items.length} 项` : ''}</span>
                                </div>)}
                            </div>
                        </details>}
                    </article>;
                })}
            </div>}
            {visibleCount < filteredPlugins.length && <div className="mt-4 flex justify-center"><button type="button" onClick={() => setVisibleCount((current) => current + 24)} className="min-h-10 rounded-xl border border-slate-200 bg-white px-5 text-sm font-medium text-slate-600 transition hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500">显示更多</button></div>}
        </section>
    </div>;
};

export default GrokPluginMarketplaceTab;
