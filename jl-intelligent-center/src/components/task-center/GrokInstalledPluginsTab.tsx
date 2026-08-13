import React, { useMemo, useState } from 'react';
import {
    Braces,
    CheckCircle2,
    ChevronDown,
    CircleOff,
    FolderPlus,
    LoaderCircle,
    PackageCheck,
    Plug,
    RefreshCw,
    Search,
    ShieldAlert,
    Sparkles,
    Trash2,
} from 'lucide-react';
import type {
    GrokExtensionInventory,
    GrokInstalledPlugin,
    GrokInspectedMcpServer,
    GrokInspectedSkill,
    GrokMcpServerState,
    GrokPluginDetails,
} from '@/services/grokDesktop';
import GrokPluginComponentBadges from './GrokPluginComponentBadges';

interface GrokInstalledPluginsTabProps {
    plugins: GrokInstalledPlugin[];
    details: Record<string, GrokPluginDetails>;
    inventory: GrokExtensionInventory;
    mcpStates: GrokMcpServerState[];
    loading: boolean;
    pendingId: string | null;
    onAddLocal: () => Promise<void>;
    onUpdateAll: () => Promise<void>;
    onLoadDetails: (plugin: GrokInstalledPlugin) => Promise<void>;
    onToggle: (plugin: GrokInstalledPlugin) => Promise<void>;
    onUpdate: (plugin: GrokInstalledPlugin) => Promise<void>;
    onUninstall: (plugin: GrokInstalledPlugin) => Promise<void>;
    onToggleSkill: (skill: GrokInspectedSkill) => Promise<void>;
    onRemoveSkill: (skill: GrokInspectedSkill) => Promise<void>;
    onToggleMcp: (server: GrokInspectedMcpServer) => Promise<void>;
    onRemoveMcp: (server: GrokInspectedMcpServer) => Promise<void>;
}

const sourceTypeLabel: Record<string, string> = {
    bundled: '内置',
    user: '用户',
    project: '项目',
    server: '服务端下发',
    configToml: 'Grok 配置',
    claudeJson: 'Claude 导入',
    mcpJson: '.mcp.json',
    managed: '管理员下发',
};

const eventLabels: Record<string, string> = {
    session_start: '会话开始',
    user_prompt_submit: '提交指令',
    pre_tool_use: '工具调用前',
    post_tool_use: '工具调用后',
    stop: '任务停止',
    notification: '运行时通知',
    session_end: '会话结束',
};

const belongsToPlugin = (plugin: GrokInstalledPlugin, pluginName?: string) => pluginName === plugin.name;

const IconButton: React.FC<{
    title: string;
    pending: boolean;
    disabled: boolean;
    onClick: () => void;
}> = ({ title, pending, disabled, onClick }) => <button type="button" title={title} aria-label={title} disabled={disabled} onClick={onClick} className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-red-600 transition hover:bg-red-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-500 disabled:opacity-40">
    {pending ? <LoaderCircle size={13} className="animate-spin" /> : <Trash2 size={14} />}
</button>;

const GrokInstalledPluginsTab: React.FC<GrokInstalledPluginsTabProps> = ({
    plugins,
    details,
    inventory,
    mcpStates,
    loading,
    pendingId,
    onAddLocal,
    onUpdateAll,
    onLoadDetails,
    onToggle,
    onUpdate,
    onUninstall,
    onToggleSkill,
    onRemoveSkill,
    onToggleMcp,
    onRemoveMcp,
}) => {
    const [expandedId, setExpandedId] = useState<string | null>(null);
    const [query, setQuery] = useState('');
    const [capabilityFilter, setCapabilityFilter] = useState<'all' | 'skill' | 'mcp' | 'hook'>('all');

    const standaloneSkills = inventory.skills.filter((skill) => skill.source.type !== 'plugin');
    const standaloneMcps = inventory.mcpServers.filter((server) => server.source.type !== 'plugin');
    const standaloneHooks = inventory.hooks.filter((hook) => hook.source.type !== 'plugin');
    const independentCount = standaloneSkills.length + standaloneMcps.length + standaloneHooks.length;
    const normalizedQuery = query.trim().toLowerCase();
    const matches = (value: string) => !normalizedQuery || value.toLowerCase().includes(normalizedQuery);
    const filteredSkills = capabilityFilter === 'all' || capabilityFilter === 'skill'
        ? standaloneSkills.filter((skill) => matches(`${skill.name} ${skill.description} ${skill.source.label}`))
        : [];
    const filteredMcps = capabilityFilter === 'all' || capabilityFilter === 'mcp'
        ? standaloneMcps.filter((server) => matches(`${server.name} ${server.target} ${server.source.label}`))
        : [];
    const filteredHooks = capabilityFilter === 'all' || capabilityFilter === 'hook'
        ? standaloneHooks.filter((hook) => matches(`${hook.event} ${hook.target} ${hook.source.label}`))
        : [];

    const liveMcpByName = useMemo(() => new Map(mcpStates.map((server) => [server.name, server])), [mcpStates]);

    const toggleDetails = async (plugin: GrokInstalledPlugin) => {
        if (expandedId === plugin.id) {
            setExpandedId(null);
            return;
        }
        setExpandedId(plugin.id);
        if (!details[plugin.id]) await onLoadDetails(plugin);
    };

    return <div className="space-y-6">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
                <h3 className="font-semibold text-slate-900">已安装</h3>
                <p className="mt-1 max-w-3xl text-sm leading-6 text-slate-500">插件是可安装、禁用和卸载的包；Skills、MCP 和 Hooks 是包内能力。非插件来源的能力统一列在下方单独管理。</p>
            </div>
            <div className="flex flex-wrap gap-2">
                <button type="button" disabled={pendingId !== null || plugins.length === 0} onClick={() => void onUpdateAll()} className="flex min-h-10 items-center gap-2 rounded-xl border border-slate-200 bg-white px-3 text-xs font-medium text-slate-600 transition hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 disabled:opacity-40">
                    {pendingId === 'update-all' ? <LoaderCircle size={14} className="animate-spin" /> : <RefreshCw size={14} />}更新全部
                </button>
                <button type="button" disabled={pendingId !== null} onClick={() => void onAddLocal()} className="flex min-h-10 items-center gap-2 rounded-xl bg-slate-900 px-3.5 text-xs font-medium text-white transition hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-500 disabled:opacity-40">
                    {pendingId === 'install-local' ? <LoaderCircle size={14} className="animate-spin" /> : <FolderPlus size={14} />}安装本地插件
                </button>
            </div>
        </div>

        <div className="flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 px-3.5 py-3 text-xs leading-5 text-amber-800">
            <ShieldAlert size={15} className="mt-0.5 shrink-0" />
            <span>禁用插件会停用它提供的全部能力；卸载插件会同时移除其中的 Skills、MCP、Hooks 和本地脚本。</span>
        </div>

        {loading && plugins.length === 0 ? <div className="flex min-h-52 items-center justify-center rounded-2xl border border-slate-200 bg-white text-sm text-slate-500"><LoaderCircle size={18} className="mr-2 animate-spin" />正在读取已安装插件</div> : plugins.length === 0 ? <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-6 py-14 text-center">
            <PackageCheck size={30} className="mx-auto text-slate-300" />
            <h4 className="mt-3 font-medium text-slate-700">尚未安装插件</h4>
            <p className="mt-1 text-sm text-slate-500">从 Marketplace 安装内网插件，或选择已审查的本地目录。</p>
        </div> : <div className="space-y-3">
            {plugins.map((plugin) => {
                const expanded = expandedId === plugin.id;
                const detail = details[plugin.id];
                const skills = inventory.skills.filter((skill) => belongsToPlugin(plugin, skill.source.pluginName));
                const mcps = inventory.mcpServers.filter((server) => belongsToPlugin(plugin, server.source.pluginName));
                const hooks = inventory.hooks.filter((hook) => belongsToPlugin(plugin, hook.source.pluginName));
                return <article key={plugin.id} className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
                    <div className="flex flex-col gap-4 p-4 sm:flex-row sm:items-center">
                        <span className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-slate-100 ${plugin.enabled ? 'text-emerald-700' : 'text-slate-500'}`}>{plugin.enabled ? <CheckCircle2 size={18} /> : <CircleOff size={18} />}</span>
                        <div className="min-w-0 flex-1">
                            <div className="flex flex-wrap items-center gap-2"><h4 className="font-semibold text-slate-900">{plugin.name}</h4>{plugin.version && <span className="text-xs tabular-nums text-slate-400">v{plugin.version}</span>}<span className={`rounded-full border px-2 py-0.5 text-[10px] font-medium ${plugin.enabled ? 'border-emerald-200 text-emerald-700' : 'border-slate-200 text-slate-600'}`}>{plugin.enabled ? '已启用' : '已禁用'}</span></div>
                            <p className="mt-1 truncate text-xs text-slate-500" title={plugin.marketplace || plugin.source || plugin.path}>{plugin.marketplace || plugin.source || plugin.path || '本地来源'}</p>
                            <div className="mt-2"><GrokPluginComponentBadges provides={plugin.provides} muted /></div>
                        </div>
                        <div className="flex flex-wrap items-center gap-1.5">
                            <button type="button" disabled={pendingId !== null} onClick={() => void toggleDetails(plugin)} className="flex min-h-9 items-center gap-1.5 rounded-lg border border-slate-200 px-3 text-xs font-medium text-slate-600 transition hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 disabled:opacity-40">{pendingId === `details:${plugin.id}` ? <LoaderCircle size={13} className="animate-spin" /> : <ChevronDown size={13} className={`transition ${expanded ? 'rotate-180' : ''}`} />}包含的能力</button>
                            <button type="button" disabled={pendingId !== null} onClick={() => void onUpdate(plugin)} className="min-h-9 rounded-lg border border-slate-200 px-3 text-xs font-medium text-slate-600 transition hover:bg-slate-50 disabled:opacity-40">更新</button>
                            <button type="button" disabled={pendingId !== null} onClick={() => void onToggle(plugin)} className={`min-h-9 rounded-lg px-3 text-xs font-medium transition disabled:opacity-40 ${plugin.enabled ? 'border border-slate-200 text-slate-600 hover:bg-slate-50' : 'bg-slate-900 text-white hover:bg-slate-800'}`}>{pendingId === `toggle:${plugin.id}` ? <LoaderCircle size={13} className="animate-spin" /> : plugin.enabled ? '禁用' : '启用'}</button>
                            <IconButton title={`卸载 ${plugin.name}`} pending={pendingId === `uninstall:${plugin.id}`} disabled={pendingId !== null} onClick={() => void onUninstall(plugin)} />
                        </div>
                    </div>
                    {expanded && <div className="border-t border-slate-100 bg-slate-50/70 px-4 py-4">
                        <div className="grid gap-4 lg:grid-cols-[0.8fr_1.2fr]">
                            <div>
                                <p className="text-sm leading-6 text-slate-600">{detail?.description || '该插件未提供说明。'}</p>
                                <p className="mt-2 break-all text-xs leading-5 text-slate-400">{detail?.path || plugin.path || '未返回安装路径'}</p>
                            </div>
                            <div className="space-y-2 rounded-xl bg-white p-3">
                                {skills.map((skill) => <div key={`skill:${skill.name}`} className="flex items-center gap-2 text-xs"><Sparkles size={13} className="text-amber-600" /><span className="min-w-0 flex-1 truncate text-slate-700">{skill.name}</span><span className="text-slate-400">Skill</span></div>)}
                                {mcps.map((server) => <div key={`mcp:${server.name}`} className="flex items-center gap-2 text-xs"><Plug size={13} className="text-indigo-600" /><span className="min-w-0 flex-1 truncate text-slate-700">{server.name}</span><span className="text-slate-400">MCP</span></div>)}
                                {hooks.map((hook, index) => <div key={`hook:${hook.event}:${index}`} className="flex items-center gap-2 text-xs"><Braces size={13} className="text-blue-600" /><span className="min-w-0 flex-1 truncate text-slate-700">{eventLabels[hook.event] || hook.event}</span><span className="text-slate-400">Hook</span></div>)}
                                {skills.length + mcps.length + hooks.length === 0 && <p className="py-2 text-xs text-slate-400">插件已禁用，或运行时没有返回可枚举的子能力。</p>}
                            </div>
                        </div>
                    </div>}
                </article>;
            })}
        </div>}

        <section className="space-y-4 border-t border-slate-200 pt-6">
            <div className="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
                <div>
                    <div className="flex items-center gap-2"><h3 className="font-semibold text-slate-900">独立能力</h3><span className="rounded-md bg-slate-100 px-2 py-0.5 text-[10px] tabular-nums text-slate-500">{independentCount}</span></div>
                    <p className="mt-1 max-w-3xl text-sm leading-6 text-slate-500">这些能力不是由已安装插件提供，所以数量不会与插件数量一致。仍可在这里直接禁用或从 Grok 移除。</p>
                </div>
                <div className="flex flex-col gap-2 sm:flex-row">
                    <label className="relative block"><Search size={15} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="搜索能力或来源" className="min-h-10 w-full rounded-xl border border-slate-200 bg-white pl-9 pr-3 text-sm outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-100 sm:w-56" /></label>
                    <div className="flex rounded-xl border border-slate-200 bg-white p-1">{([['all', '全部'], ['skill', 'Skills'], ['mcp', 'MCP'], ['hook', 'Hooks']] as const).map(([id, label]) => <button key={id} type="button" onClick={() => setCapabilityFilter(id)} className={`min-h-8 rounded-lg px-2.5 text-xs font-medium ${capabilityFilter === id ? 'bg-slate-900 text-white' : 'text-slate-500 hover:bg-slate-50'}`}>{label}</button>)}</div>
                </div>
            </div>

            {filteredSkills.length + filteredMcps.length + filteredHooks.length === 0 ? <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-6 py-12 text-center text-sm text-slate-500">没有匹配的独立能力</div> : <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white"><div className="divide-y divide-slate-100">
                {filteredSkills.map((skill) => { const key = `skill:${skill.source.label}:${skill.name}`; return <div key={key} className="flex flex-col gap-3 px-4 py-3.5 sm:flex-row sm:items-center"><span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-slate-100 ${skill.disabled ? 'text-slate-400' : 'text-amber-700'}`}><Sparkles size={16} /></span><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium text-slate-800">{skill.name}</span><span className="rounded-md border border-amber-200 px-2 py-0.5 text-[10px] text-amber-700">Skill</span>{skill.disabled && <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] text-slate-500">已禁用</span>}</div><p className="mt-1 truncate text-xs text-slate-500" title={skill.source.path || skill.source.label}>{sourceTypeLabel[skill.source.type] || skill.source.type} · {skill.description || skill.source.label}</p></div><button type="button" disabled={pendingId !== null} onClick={() => void onToggleSkill(skill)} className={`min-h-9 rounded-lg px-3 text-xs font-medium disabled:opacity-40 ${skill.disabled ? 'bg-slate-900 text-white' : 'border border-slate-200 text-slate-600 hover:bg-slate-50'}`}>{pendingId === `toggle:${key}` ? <LoaderCircle size={13} className="animate-spin" /> : skill.disabled ? '启用' : '禁用'}</button><IconButton title={`从 Grok 移除 ${skill.name}`} pending={pendingId === `remove:${key}`} disabled={pendingId !== null || !skill.source.path} onClick={() => void onRemoveSkill(skill)} /></div>; })}
                {filteredMcps.map((server) => { const key = `mcp:${server.source.label}:${server.name}`; const live = liveMcpByName.get(server.name); const runtimeReported = live && !/^(configured|disabled)$/i.test(live.health); const canRemove = ['configToml', 'claudeJson', 'mcpJson'].includes(server.source.type); return <div key={key} className="flex flex-col gap-3 px-4 py-3.5 sm:flex-row sm:items-center"><span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-slate-100 ${server.disabled ? 'text-slate-400' : 'text-indigo-700'}`}><Plug size={16} /></span><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium text-slate-800">{server.name}</span><span className="rounded-md border border-indigo-200 px-2 py-0.5 text-[10px] text-indigo-700">MCP</span>{server.disabled && <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] text-slate-500">已禁用</span>}{runtimeReported && <span className="rounded-full border border-emerald-200 px-2 py-0.5 text-[10px] text-emerald-700">会话已连接 · {live.tools.length} 工具</span>}</div><p className="mt-1 truncate text-xs text-slate-500" title={server.target || server.source.path}>{sourceTypeLabel[server.source.type] || server.source.type} · {server.target || server.source.label}</p></div><button type="button" disabled={pendingId !== null} onClick={() => void onToggleMcp(server)} className={`min-h-9 rounded-lg px-3 text-xs font-medium disabled:opacity-40 ${server.disabled ? 'bg-slate-900 text-white' : 'border border-slate-200 text-slate-600 hover:bg-slate-50'}`}>{pendingId === `toggle:${key}` ? <LoaderCircle size={13} className="animate-spin" /> : server.disabled ? '启用' : '禁用'}</button><IconButton title={canRemove ? `卸载 ${server.name}` : '该能力由管理员或临时参数提供，不能在此卸载'} pending={pendingId === `remove:${key}`} disabled={pendingId !== null || !canRemove} onClick={() => void onRemoveMcp(server)} /></div>; })}
                {filteredHooks.map((hook, index) => <div key={`hook:${hook.source.label}:${hook.event}:${index}`} className="flex flex-col gap-3 px-4 py-3.5 sm:flex-row sm:items-center"><span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-blue-700"><Braces size={16} /></span><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium text-slate-800">{eventLabels[hook.event] || hook.event}</span><span className="rounded-md border border-blue-200 px-2 py-0.5 text-[10px] text-blue-700">Hook</span></div><p className="mt-1 truncate text-xs text-slate-500" title={hook.source.path || hook.target}>{sourceTypeLabel[hook.source.type] || hook.source.type} · {hook.target || hook.source.label}</p></div><span className="text-xs text-slate-400">由配置源管理</span></div>)}
            </div></div>}
        </section>
    </div>;
};

export default GrokInstalledPluginsTab;
