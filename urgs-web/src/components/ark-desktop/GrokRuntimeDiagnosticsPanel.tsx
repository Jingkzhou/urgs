import React, { useState } from 'react';
import { Activity, CheckCircle2, ChevronDown, CircleAlert, CircleOff, RefreshCw, Terminal } from 'lucide-react';
import type { GrokRuntimeDiagnostics } from '@/services/grokDesktop';

interface GrokRuntimeDiagnosticsPanelProps {
    diagnostics: GrokRuntimeDiagnostics[];
    onRefresh: () => Promise<void>;
    onError: (message: string) => void;
}

const jsonText = (value: unknown) => {
    if (value === undefined || value === null) return '—';
    try {
        return JSON.stringify(value, null, 2);
    } catch {
        return String(value);
    }
};

const HookPolicy: React.FC<{ meta: Record<string, any> | null }> = ({ meta }) => {
    const hooks = meta?.['x.ai/hooks'];
    if (!hooks || typeof hooks !== 'object') return null;
    const blockingEvents = Array.isArray(hooks.blockingEvents) ? hooks.blockingEvents : [];
    const decisions = Array.isArray(hooks.decisions) ? hooks.decisions : [];
    const stopSignals = Array.isArray(hooks.stopSignals) ? hooks.stopSignals : [];
    return <div className="rounded-lg bg-white px-3 py-2 text-xs"><span className="font-medium text-slate-700">Hooks 策略</span><div className="mt-2 grid gap-2 text-slate-500 sm:grid-cols-3"><div><span className="text-[10px] text-slate-400">阻断事件</span><p className="mt-0.5 break-words">{blockingEvents.length ? blockingEvents.join('、') : '—'}</p></div><div><span className="text-[10px] text-slate-400">可用决策</span><p className="mt-0.5 break-words">{decisions.length ? decisions.join('、') : '—'}</p></div><div><span className="text-[10px] text-slate-400">停止信号</span><p className="mt-0.5 break-words">{stopSignals.length ? stopSignals.join('、') : '—'}</p></div></div><p className="mt-2 text-[10px] leading-4 text-slate-400">阻断原因会随对应任务事件进入时间线；这里展示的是 ACP 实际声明的策略。</p></div>;
};

const AgentCapabilitySummary: React.FC<{
    capabilities: Record<string, any> | null;
    meta: Record<string, any> | null;
    availableCommands: Array<{ name: string }>;
}> = ({ capabilities, meta, availableCommands }) => {
    const prompt = capabilities?.promptCapabilities || {};
    const mcp = capabilities?.mcpCapabilities || {};
    const items = [
        ['工作流', availableCommands.some((command) => command.name === 'workflow')],
        ['历史会话恢复', capabilities?.loadSession === true],
        ['上下文注入', prompt.embeddedContext === true],
        ['图片输入', prompt.image === true],
        ['音频输入', prompt.audio === true],
        ['MCP HTTP', mcp.http === true],
        ['MCP SSE', mcp.sse === true],
        ['MCP Apps', meta?.mcpApps === true],
        ['语音模式', meta?.voiceMode === true],
    ];
    return <div className="rounded-lg bg-white px-3 py-2 text-xs"><div className="flex flex-wrap items-center justify-between gap-2"><span className="font-medium text-slate-700">0.2.119 能力声明</span><span className="text-[10px] text-slate-400">{String(meta?.agentVersion || '版本未知')}</span></div><div className="mt-2 flex flex-wrap gap-1.5">{items.map(([label, enabled]) => <span key={label as string} className={`flex items-center gap-1 rounded-full px-2 py-1 text-[10px] ${enabled ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-400'}`}>{enabled ? <CheckCircle2 size={11} /> : <CircleOff size={11} />}{label as string}{enabled ? '' : '未声明'}</span>)}</div><p className="mt-2 text-[10px] leading-4 text-slate-400">这些状态直接来自 ACP initialize，不代表静态配置中存在同名功能；未声明的输入类型不会被 Desktop 强行展示为可用。</p></div>;
};

const GrokRuntimeDiagnosticsPanel: React.FC<GrokRuntimeDiagnosticsPanelProps> = ({ diagnostics, onRefresh, onError }) => {
    const [loading, setLoading] = useState(false);
    const refresh = async () => {
        setLoading(true);
        try {
            await onRefresh();
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        } finally {
            setLoading(false);
        }
    };

    return <div className="rounded-2xl border border-slate-200 bg-white p-5">
        <div className="flex flex-wrap items-start justify-between gap-3"><div><div className="flex items-center gap-2"><Activity size={17} className="text-[#6657d9]" /><h3 className="font-semibold text-slate-900">ACP 运行诊断</h3></div><p className="mt-1 max-w-2xl text-sm leading-6 text-slate-500">显示当前 Rust/Tauri 桥接看到的 ACP 进程、会话、模型目录、MCP 状态和初始化元数据。会话中的未知事件会记录在对应任务时间线。</p></div><button type="button" disabled={loading} onClick={() => void refresh()} className="flex items-center gap-1.5 rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-40"><RefreshCw size={14} className={loading ? 'animate-spin' : ''} />刷新诊断</button></div>
        {diagnostics.length === 0 ? <div className="mt-4 rounded-xl border border-dashed border-slate-300 bg-slate-50 px-5 py-10 text-center"><CircleAlert size={24} className="mx-auto text-slate-300" /><p className="mt-2 text-sm text-slate-500">当前没有已初始化的 ACP 进程</p><p className="mt-1 text-xs text-slate-400">发起或打开一个 Desktop 会话后，再回来刷新。</p></div> : <div className="mt-4 space-y-3">{diagnostics.map((item) => <details key={item.processId} className="overflow-hidden rounded-xl border border-slate-200" open><summary className="flex cursor-pointer list-none items-center gap-3 px-3.5 py-3"><span className={`h-2 w-2 rounded-full ${item.alive ? 'bg-emerald-500' : 'bg-slate-300'}`} /><span className="min-w-0 flex-1"><span className="block truncate text-sm font-medium text-slate-800">{item.workspace.split(/[\\/]/).filter(Boolean).pop() || item.workspace}</span><span className="mt-0.5 block truncate text-[10px] text-slate-400">PID {item.processId} · {item.sessionIds.length} 个会话 · {item.alive ? '运行中' : '已退出'}</span></span><ChevronDown size={15} className="text-slate-400" /></summary><div className="space-y-3 border-t border-slate-100 bg-slate-50/60 px-3.5 py-3"><div className="grid gap-2 text-xs sm:grid-cols-2"><div className="rounded-lg bg-white px-3 py-2"><span className="font-medium text-slate-700">会话</span><p className="mt-1 break-all leading-5 text-slate-500">{item.sessionIds.length ? item.sessionIds.join('\n') : '暂无会话'}</p></div><div className="rounded-lg bg-white px-3 py-2"><span className="font-medium text-slate-700">可用命令</span><p className="mt-1 leading-5 text-slate-500">{item.availableCommands.length ? item.availableCommands.map((command) => command.name).join('、') : '暂无命令'}</p></div></div><AgentCapabilitySummary capabilities={item.agentCapabilities} meta={item.initializeMeta} availableCommands={item.availableCommands} /><div className="rounded-lg bg-white px-3 py-2 text-xs"><span className="font-medium text-slate-700">MCP 状态</span>{item.mcpServers.length ? <div className="mt-2 space-y-1">{item.mcpServers.map((server) => <div key={server.name} className="flex items-center gap-2 text-slate-500"><span className={`h-1.5 w-1.5 rounded-full ${server.enabled && !/fail|error/i.test(server.health) ? 'bg-emerald-500' : 'bg-amber-400'}`} /><span className="min-w-0 flex-1 truncate">{server.name} · {server.transport}</span><span>{server.health || 'configured'} · {server.tools.length} tools</span></div>)}</div> : <p className="mt-1 text-slate-400">暂无 MCP 服务</p>}</div><HookPolicy meta={item.initializeMeta} /><details className="rounded-lg bg-white px-3 py-2"><summary className="flex cursor-pointer items-center gap-2 text-xs font-medium text-slate-700"><Terminal size={13} />ACP 初始化元数据</summary><pre className="mt-2 max-h-64 overflow-auto whitespace-pre-wrap break-all text-[10px] leading-4 text-slate-500">{jsonText(item.initializeMeta)}</pre></details>{item.stderr && <details className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2"><summary className="flex cursor-pointer items-center gap-2 text-xs font-medium text-amber-800"><CircleAlert size={13} />最近 stderr</summary><pre className="mt-2 max-h-48 overflow-auto whitespace-pre-wrap break-all text-[10px] leading-4 text-amber-700">{item.stderr}</pre></details>}</div></details>)}</div>}
    </div>;
};

export default GrokRuntimeDiagnosticsPanel;
