import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
    LoaderCircle,
    PackageCheck,
    PackageSearch,
    Plug,
    RefreshCw,
    ShieldAlert,
} from 'lucide-react';
import {
    addGrokMarketplaceSource,
    chooseGrokPluginDirectory,
    getGrokPluginDetails,
    inspectGrokExtensions,
    installGrokMarketplacePlugin,
    installTrustedLocalGrokPlugin,
    listGrokInstalledPlugins,
    listGrokMarketplaceSources,
    listGrokPluginMarketplace,
    removeGrokMarketplaceSource,
    removeGrokInspectedMcp,
    removeGrokSkill,
    setGrokPluginEnabled,
    setGrokInspectedMcpEnabled,
    setGrokSkillEnabled,
    uninstallGrokPlugin,
    updateGrokMarketplaceSource,
    updateGrokPlugin,
    validateGrokPluginDirectory,
    type GrokExtensionInventory,
    type GrokInstalledPlugin,
    type GrokInspectedMcpServer,
    type GrokInspectedSkill,
    type GrokMarketplacePlugin,
    type GrokMarketplaceSource,
    type GrokMcpServerState,
    type GrokPluginDetails,
} from '@/services/grokDesktop';
import GrokInstalledPluginsTab from './GrokInstalledPluginsTab';
import GrokPluginMarketplaceTab from './GrokPluginMarketplaceTab';

type ExtensionTab = 'plugins' | 'marketplace';

interface GrokPluginManagerProps {
    workspace: string;
    mcpServers: GrokMcpServerState[];
    onRefreshMcp: (workspace?: string) => Promise<unknown>;
    onChanged: () => Promise<void>;
    onError: (message: string) => void;
}

const emptyInventory: GrokExtensionInventory = {
    grokVersion: '',
    projectTrusted: true,
    hooks: [],
    skills: [],
    plugins: [],
    mcpServers: [],
    lspServers: [],
};

const tabDefinitions: Array<{
    id: ExtensionTab;
    label: string;
    icon: React.ElementType;
}> = [
    { id: 'marketplace', label: 'Marketplace', icon: PackageSearch },
    { id: 'plugins', label: 'Plugins', icon: PackageCheck },
];

const GrokPluginManager: React.FC<GrokPluginManagerProps> = ({
    workspace,
    mcpServers,
    onRefreshMcp,
    onChanged,
    onError,
}) => {
    const [activeTab, setActiveTab] = useState<ExtensionTab>('marketplace');
    const [plugins, setPlugins] = useState<GrokInstalledPlugin[]>([]);
    const [details, setDetails] = useState<Record<string, GrokPluginDetails>>({});
    const [marketplacePlugins, setMarketplacePlugins] = useState<GrokMarketplacePlugin[]>([]);
    const [marketplaceSources, setMarketplaceSources] = useState<GrokMarketplaceSource[]>([]);
    const [inventory, setInventory] = useState<GrokExtensionInventory>(emptyInventory);
    const [loading, setLoading] = useState(true);
    const [marketplaceLoading, setMarketplaceLoading] = useState(true);
    const [inventoryLoading, setInventoryLoading] = useState(true);
    const [pendingId, setPendingId] = useState<string | null>(null);

    const reportError = useCallback((error: unknown) => {
        onError(error instanceof Error ? error.message : String(error));
    }, [onError]);

    const refreshPlugins = useCallback(async () => {
        setLoading(true);
        try {
            setPlugins(await listGrokInstalledPlugins(workspace || undefined));
        } catch (error) {
            reportError(error);
        } finally {
            setLoading(false);
        }
    }, [reportError, workspace]);

    const refreshInventory = useCallback(async () => {
        setInventoryLoading(true);
        try {
            setInventory(await inspectGrokExtensions(workspace || undefined));
        } catch (error) {
            reportError(error);
        } finally {
            setInventoryLoading(false);
        }
    }, [reportError, workspace]);

    const refreshMarketplace = useCallback(async () => {
        setMarketplaceLoading(true);
        try {
            try {
                setMarketplaceSources(await listGrokMarketplaceSources(workspace || undefined));
            } catch (error) {
                reportError(error);
            }
            try {
                setMarketplacePlugins(await listGrokPluginMarketplace(workspace || undefined));
            } catch (error) {
                reportError(error);
            }
        } finally {
            setMarketplaceLoading(false);
        }
    }, [reportError, workspace]);

    const refreshAll = useCallback(async () => {
        // Grok CLI 每次调用都会创建 sidecar 管道。Desktop 首屏必须受控串行刷新，
        // 避免同时查询插件、市场、清单和 MCP 时耗尽文件描述符。
        await refreshPlugins();
        await refreshInventory();
        await refreshMarketplace();
        await onRefreshMcp(workspace || undefined).catch(reportError);
    }, [onRefreshMcp, refreshInventory, refreshMarketplace, refreshPlugins, reportError, workspace]);

    const refreshAllRef = useRef(refreshAll);
    refreshAllRef.current = refreshAll;
    useEffect(() => {
        void refreshAllRef.current();
    }, [workspace]);

    const runAction = async (id: string, action: () => Promise<void>) => {
        if (pendingId) return;
        setPendingId(id);
        try {
            await action();
        } catch (error) {
            reportError(error);
        } finally {
            setPendingId(null);
        }
    };

    const addMarketplace = async (source: string) => {
        if (!window.confirm(`确认连接内网插件市场“${source}”吗？连接后会读取仓库中的市场清单。`)) return;
        await runAction('market-source:add', async () => {
            await addGrokMarketplaceSource(source, workspace || undefined);
            await refreshMarketplace();
            await onChanged();
        });
    };

    const updateMarketplace = async (source: GrokMarketplaceSource) => runAction(`market-source:update:${source.name}`, async () => {
        await updateGrokMarketplaceSource(source.url, workspace || undefined);
        await refreshMarketplace();
    });

    const removeMarketplace = async (source: GrokMarketplaceSource) => {
        if (!window.confirm(`确认移除市场源“${source.name}”吗？Grok 会同时卸载从该来源安装的插件。`)) return;
        await runAction(`market-source:remove:${source.name}`, async () => {
            await removeGrokMarketplaceSource(source.url, workspace || undefined);
            await refreshAll();
            await onChanged();
        });
    };

    const installMarketplace = async (plugin: GrokMarketplacePlugin) => {
        const componentCount = Object.values(plugin.components).reduce((total, items) => total + items.length, 0);
        const componentText = componentCount > 0
            ? `市场已声明 ${componentCount} 个组件，可在卡片中展开核对。`
            : '该市场没有发布能力清单，当前无法确认它包含 Skill、MCP 还是其他可执行组件。建议联系市场维护人补齐 plugin-index.json 后再安装。';
        if (!window.confirm(`确认从“${plugin.marketplace}”安装“${plugin.name}”吗？\n\n${plugin.description || '该插件未提供说明。'}\n${componentText}\n\n安装即代表信任该来源中的可执行组件。`)) return;
        await runAction(`market:${plugin.marketplace}:${plugin.name}`, async () => {
            await installGrokMarketplacePlugin(plugin.name, plugin.marketplace, workspace || undefined);
            await refreshAll();
            await onChanged();
            setActiveTab('plugins');
        });
    };

    const addLocalPlugin = async () => {
        const path = await chooseGrokPluginDirectory();
        if (!path) return;
        await runAction('install-local', async () => {
            const validation = await validateGrokPluginDirectory(path, workspace || undefined);
            const summary = [
                validation.components.skillDirectories ? `${validation.components.skillDirectories} 个 Skills 目录` : '',
                validation.components.commandDirectories ? `${validation.components.commandDirectories} 个 Commands 目录` : '',
                validation.components.agentDirectories ? `${validation.components.agentDirectories} 个 Agents 目录` : '',
                validation.components.hasHooks ? 'Hooks' : '',
                validation.components.hasMcpServers ? 'MCP Servers' : '',
                validation.components.hasLspServers ? 'LSP Servers' : '',
            ].filter(Boolean).join('、') || '未声明可加载组件';
            if (!window.confirm(`确认信任并安装本地插件“${validation.name}”吗？\n\n${validation.description || '该插件未提供说明。'}\n组件：${summary}`)) return;
            await installTrustedLocalGrokPlugin(path, workspace || undefined);
            await refreshAll();
            await onChanged();
        });
    };

    const loadDetails = async (plugin: GrokInstalledPlugin) => runAction(`details:${plugin.id}`, async () => {
        const value = await getGrokPluginDetails(plugin, workspace || undefined);
        setDetails((current) => ({ ...current, [plugin.id]: value }));
    });

    const togglePlugin = async (plugin: GrokInstalledPlugin) => runAction(`toggle:${plugin.id}`, async () => {
        await setGrokPluginEnabled(plugin.name, !plugin.enabled, workspace || undefined);
        await refreshPlugins();
        await refreshInventory();
        await onChanged();
    });

    const updatePlugin = async (plugin: GrokInstalledPlugin) => {
        if (!window.confirm(`确认更新插件“${plugin.name}”吗？更新会替换该插件中的可执行组件。`)) return;
        await runAction(`update:${plugin.id}`, async () => {
            await updateGrokPlugin(plugin.name, workspace || undefined);
            await refreshAll();
            await onChanged();
        });
    };

    const updateAll = async () => {
        if (!window.confirm('确认更新全部已安装插件吗？')) return;
        await runAction('update-all', async () => {
            await updateGrokPlugin(undefined, workspace || undefined);
            await refreshAll();
            await onChanged();
        });
    };

    const uninstallPlugin = async (plugin: GrokInstalledPlugin) => {
        const skillCount = inventory.skills.filter((skill) => skill.source.pluginName === plugin.name).length;
        const mcpCount = inventory.mcpServers.filter((server) => server.source.pluginName === plugin.name).length;
        const hookCount = inventory.hooks.filter((hook) => hook.source.pluginName === plugin.name).length;
        const capabilityText = [skillCount ? `${skillCount} 个 Skills` : '', mcpCount ? `${mcpCount} 个 MCP` : '', hookCount ? `${hookCount} 个 Hooks` : ''].filter(Boolean).join('、');
        if (!window.confirm(`确认卸载插件“${plugin.name}”吗？${capabilityText ? `\n\n将同时移除：${capabilityText}。` : ''}`)) return;
        await runAction(`uninstall:${plugin.id}`, async () => {
            await uninstallGrokPlugin(plugin.name, workspace || undefined);
            setDetails((current) => {
                const next = { ...current };
                delete next[plugin.id];
                return next;
            });
            await refreshAll();
            await onChanged();
        });
    };

    const toggleSkill = async (skill: GrokInspectedSkill) => runAction(`toggle:skill:${skill.source.label}:${skill.name}`, async () => {
        await setGrokSkillEnabled(skill.name, skill.disabled);
        await refreshInventory();
        await onChanged();
    });

    const removeSkill = async (skill: GrokInspectedSkill) => {
        if (!skill.source.path) return reportError(new Error('该 Skill 没有可移除的来源路径'));
        if (!window.confirm(`确认从 Grok 移除 Skill“${skill.name}”吗？\n\n源文件不会被删除，Grok 会在配置中忽略该路径，后续可由管理员恢复。`)) return;
        await runAction(`remove:skill:${skill.source.label}:${skill.name}`, async () => {
            await removeGrokSkill(skill.name, skill.source.path!);
            await refreshInventory();
            await onChanged();
        });
    };

    const toggleInspectedMcp = async (server: GrokInspectedMcpServer) => runAction(`toggle:mcp:${server.source.label}:${server.name}`, async () => {
        await setGrokInspectedMcpEnabled(server.name, server.disabled, workspace || undefined);
        await refreshInventory();
        await onRefreshMcp(workspace || undefined);
        await onChanged();
    });

    const removeInspectedMcp = async (server: GrokInspectedMcpServer) => {
        if (!window.confirm(`确认卸载 MCP 服务“${server.name}”吗？\n\n系统会先备份“${server.source.label}”，再删除该服务的配置项。`)) return;
        await runAction(`remove:mcp:${server.source.label}:${server.name}`, async () => {
            await removeGrokInspectedMcp(server.name, server.source, workspace || undefined);
            await refreshInventory();
            await onRefreshMcp(workspace || undefined);
            await onChanged();
        });
    };

    const tabCounts = useMemo<Record<ExtensionTab, number>>(() => ({
        plugins: plugins.length,
        marketplace: marketplacePlugins.length,
    }), [marketplacePlugins.length, plugins.length]);

    const enabledPluginCount = plugins.filter((plugin) => plugin.enabled).length;
    const capabilityCount = inventory.skills.length + inventory.mcpServers.length + inventory.hooks.length;

    return <div className="space-y-5" role="tabpanel">
        <header className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
            <div className="flex flex-col gap-5 px-5 py-5 lg:flex-row lg:items-center lg:justify-between">
                <div className="max-w-2xl">
                    <div className="flex items-center gap-2"><Plug size={20} className="text-blue-700" /><h2 className="text-xl font-semibold tracking-[-0.02em] text-slate-900">插件中心</h2></div>
                    <p className="mt-2 text-sm leading-6 text-slate-500">从内网 GitLab 市场安装插件，并在“已安装”中统一管理插件及其 Skills、MCP 和 Hooks。</p>
                </div>
                <div className="flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-slate-500">
                    <span><strong className="mr-1 text-base font-semibold tabular-nums text-slate-900">{marketplaceSources.length}</strong>市场源</span>
                    <span><strong className="mr-1 text-base font-semibold tabular-nums text-slate-900">{enabledPluginCount}</strong>已启用</span>
                    <span><strong className="mr-1 text-base font-semibold tabular-nums text-slate-900">{capabilityCount}</strong>运行时能力</span>
                    <button type="button" disabled={loading || marketplaceLoading || inventoryLoading} onClick={() => void refreshAll()} className="flex min-h-10 items-center gap-2 rounded-xl border border-slate-200 px-3 text-xs font-medium text-slate-600 transition hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 disabled:opacity-40">
                        <RefreshCw size={14} className={loading || marketplaceLoading || inventoryLoading ? 'animate-spin' : ''} />刷新全部
                    </button>
                </div>
            </div>
            {!inventory.projectTrusted && <div className="flex items-start gap-2 border-t border-amber-200 bg-amber-50 px-5 py-3 text-xs leading-5 text-amber-800"><ShieldAlert size={15} className="mt-0.5 shrink-0" /><span>当前工作区尚未被 Grok 信任，项目级 Hooks、Plugins 和 MCP 可能不会加载。</span></div>}
            <nav className="overflow-x-auto border-t border-slate-100 px-2" aria-label="插件中心分类">
                <div className="flex min-w-max gap-1 py-2" role="tablist">
                    {tabDefinitions.map((tab) => {
                        const Icon = tab.icon;
                        const active = activeTab === tab.id;
                        return <button key={tab.id} type="button" role="tab" aria-selected={active} onClick={() => setActiveTab(tab.id)} className={`flex min-h-10 items-center gap-2 rounded-xl px-3.5 text-sm font-medium transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 ${active ? 'bg-slate-900 text-white' : 'text-slate-500 hover:bg-slate-100 hover:text-slate-800'}`}>
                            <Icon size={15} />{tab.label}<span className={`rounded-md px-1.5 py-0.5 text-[10px] tabular-nums ${active ? 'bg-white/15 text-white' : 'bg-slate-100 text-slate-500'}`}>{tabCounts[tab.id]}</span>
                        </button>;
                    })}
                </div>
            </nav>
        </header>

        {activeTab === 'plugins' && <GrokInstalledPluginsTab plugins={plugins} details={details} inventory={inventory} mcpStates={mcpServers} loading={loading} pendingId={pendingId} onAddLocal={addLocalPlugin} onUpdateAll={updateAll} onLoadDetails={loadDetails} onToggle={togglePlugin} onUpdate={updatePlugin} onUninstall={uninstallPlugin} onToggleSkill={toggleSkill} onRemoveSkill={removeSkill} onToggleMcp={toggleInspectedMcp} onRemoveMcp={removeInspectedMcp} />}
        {activeTab === 'marketplace' && <GrokPluginMarketplaceTab plugins={marketplacePlugins} installedPlugins={plugins} sources={marketplaceSources} loading={marketplaceLoading} pendingId={pendingId} onRefresh={refreshMarketplace} onAddSource={addMarketplace} onUpdateSource={updateMarketplace} onRemoveSource={removeMarketplace} onInstall={installMarketplace} />}
    </div>;
};

export default GrokPluginManager;
