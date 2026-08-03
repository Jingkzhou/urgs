import React, { useState } from 'react';
import { CheckCircle2, CircleOff, LoaderCircle, Plug, RefreshCw, Server, ShieldAlert, Wrench } from 'lucide-react';
import type { GrokMcpServerState } from '@/services/grokDesktop';

interface GrokMcpManagerProps {
    workspace: string;
    servers: GrokMcpServerState[];
    onToggle: (name: string, enabled: boolean) => Promise<void>;
    onReload: () => Promise<void>;
    onRefresh: () => Promise<void>;
    onError: (message: string) => void;
}

const healthLabel = (health: string, enabled: boolean) => {
    if (!enabled) return { label: '已禁用', className: 'bg-slate-100 text-slate-500' };
    if (/fail|error|unhealthy/i.test(health)) return { label: '连接异常', className: 'bg-red-50 text-red-700' };
    if (/connected|ready|healthy/i.test(health)) return { label: '已连接', className: 'bg-emerald-50 text-emerald-700' };
    return { label: health || '已配置', className: 'bg-amber-50 text-amber-700' };
};

const GrokMcpManager: React.FC<GrokMcpManagerProps> = ({ workspace, servers, onToggle, onReload, onRefresh, onError }) => {
    const [pending, setPending] = useState<string | null>(null);
    const run = async (key: string, callback: () => Promise<void>) => {
        if (pending) return;
        setPending(key);
        try {
            await callback();
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        } finally {
            setPending(null);
        }
    };

    return <div className="rounded-2xl border border-slate-200 bg-white p-5">
        <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
                <div className="flex items-center gap-2"><Plug size={17} className="text-[#6657d9]" /><h3 className="font-semibold text-slate-900">MCP 服务</h3></div>
                <p className="mt-1 max-w-2xl text-sm leading-6 text-slate-500">管理当前工作区实际加载的 MCP 服务。开关会写入配置并热更新 ACP 会话；密钥只展示变量名，不会在界面回显。</p>
            </div>
            <div className="flex items-center gap-2"><button type="button" disabled={pending !== null} onClick={() => void run('refresh', onRefresh)} className="flex items-center gap-1.5 rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-40"><RefreshCw size={14} className={pending === 'refresh' ? 'animate-spin' : ''} />刷新状态</button><button type="button" disabled={pending !== null || !workspace} onClick={() => void run('reload', onReload)} className="flex items-center gap-1.5 rounded-xl bg-slate-900 px-3 py-2 text-xs font-medium text-white disabled:opacity-40"><Server size={14} />热更新当前会话</button></div>
        </div>
        <div className="mt-4 flex items-start gap-2 rounded-xl border border-blue-200 bg-blue-50 px-3.5 py-3 text-xs leading-5 text-blue-700"><ShieldAlert size={15} className="mt-0.5 shrink-0" /><span>配置来源：用户级与项目级 <code>.grok/config.toml</code>。项目配置同名服务会覆盖用户配置。</span></div>
        {servers.length === 0 ? <div className="mt-4 rounded-xl border border-dashed border-slate-300 bg-slate-50 px-5 py-10 text-center"><CircleOff size={24} className="mx-auto text-slate-300" /><p className="mt-2 text-sm text-slate-500">当前工作区没有发现 MCP 服务</p><p className="mt-1 text-xs text-slate-400">添加与移除仍可在“CLI 与诊断”中的 MCP 命令中心完成。</p></div> : <div className="mt-4 space-y-2">{servers.map((server) => { const health = healthLabel(server.health, server.enabled); const key = `toggle:${server.name}`; return <div key={server.name} className="flex flex-wrap items-center gap-3 rounded-xl border border-slate-200 px-3.5 py-3"><span className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${server.enabled ? 'bg-indigo-50 text-indigo-600' : 'bg-slate-100 text-slate-400'}`}><Plug size={16} /></span><div className="min-w-0 flex-1"><div className="flex flex-wrap items-center gap-2"><span className="font-medium text-slate-800">{server.name}</span><span className="rounded bg-slate-100 px-1.5 py-0.5 text-[10px] text-slate-500">{server.transport}</span><span className={`flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] ${health.className}`}>{server.enabled && !/fail|error|unhealthy/i.test(server.health) ? <CheckCircle2 size={11} /> : <CircleOff size={11} />}{health.label}</span></div><p className="mt-1 truncate text-xs text-slate-400" title={server.command || server.url || server.source}>{server.command || server.url || server.source || '未提供连接地址'}</p><div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-[10px] text-slate-400"><span>{server.tools.length} 个工具</span>{server.envKeys.length > 0 && <span>{server.envKeys.length} 个环境变量</span>}{server.headerNames.length > 0 && <span>{server.headerNames.length} 个 Header</span>}<span className="flex items-center gap-1"><Wrench size={10} />{server.source}</span></div></div><button type="button" disabled={pending !== null} onClick={() => void run(key, () => onToggle(server.name, !server.enabled))} className={`rounded-lg px-3 py-2 text-xs font-medium disabled:opacity-40 ${server.enabled ? 'border border-slate-200 text-slate-600 hover:bg-slate-50' : 'bg-slate-900 text-white hover:bg-slate-700'}`}>{pending === key ? <LoaderCircle size={13} className="animate-spin" /> : server.enabled ? '禁用' : '启用'}</button></div>; })}</div>}
    </div>;
};

export default GrokMcpManager;
