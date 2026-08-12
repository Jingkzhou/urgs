import React from 'react';
import type {
    GrokPluginCatalogComponents,
    GrokPluginComponents,
    GrokPluginProvides,
} from '@/services/grokDesktop';

interface GrokPluginComponentBadgesProps {
    catalog?: GrokPluginCatalogComponents;
    provides?: GrokPluginProvides;
    summary?: GrokPluginComponents;
    muted?: boolean;
    undeclaredWarning?: boolean;
}

interface ComponentBadge {
    label: string;
    count?: number;
}

const catalogBadges = (components: GrokPluginCatalogComponents): ComponentBadge[] => [
    { label: 'Skills', count: components.skills.length },
    { label: 'Commands', count: components.commands.length },
    { label: 'Agents', count: components.agents.length },
    { label: 'MCP', count: components.mcpServers.length },
    { label: 'Hooks', count: components.hooks.length },
    { label: 'LSP', count: components.lspServers.length },
].filter((item) => Boolean(item.count));

const providesBadges = (provides: GrokPluginProvides): ComponentBadge[] => [
    { label: 'Skills', count: provides.skills },
    { label: 'Agents', count: provides.agents },
    { label: 'MCP', count: provides.mcpServers },
    { label: 'Hooks', count: provides.hooks ? 1 : 0 },
].filter((item) => Boolean(item.count));

const summaryBadges = (summary: GrokPluginComponents): ComponentBadge[] => [
    { label: 'Skills', count: summary.skillDirectories },
    { label: 'Commands', count: summary.commandDirectories },
    { label: 'Agents', count: summary.agentDirectories },
    { label: 'MCP', count: summary.hasMcpServers ? 1 : 0 },
    { label: 'Hooks', count: summary.hasHooks ? 1 : 0 },
    { label: 'LSP', count: summary.hasLspServers ? 1 : 0 },
].filter((item) => Boolean(item.count));

const GrokPluginComponentBadges: React.FC<GrokPluginComponentBadgesProps> = ({
    catalog,
    provides,
    summary,
    muted = false,
    undeclaredWarning = false,
}) => {
    const badges = catalog
        ? catalogBadges(catalog)
        : provides
            ? providesBadges(provides)
            : summary
                ? summaryBadges(summary)
                : [];

    if (badges.length === 0) {
        return <span className={undeclaredWarning
            ? 'inline-flex rounded-md bg-amber-50 px-2 py-1 text-xs font-medium text-amber-800'
            : 'text-xs text-slate-400'}>{undeclaredWarning ? '能力类型未声明' : '未发现组件清单'}</span>;
    }

    const mutedBadgeTone = 'bg-slate-100 text-slate-700';
    const activeBadgeTone = 'bg-blue-50 text-blue-800';
    const badgeTone = muted ? mutedBadgeTone : activeBadgeTone;

    return <div className="flex flex-wrap gap-1.5" aria-label="插件组件">
        {badges.map((badge) => <span
            key={badge.label}
            className={`rounded-md px-2 py-1 text-[11px] font-medium ${badgeTone}`}
        >
            {badge.label}{badge.count && badge.count > 1 ? ` ${badge.count}` : ''}
        </span>)}
    </div>;
};

export default GrokPluginComponentBadges;
