import React, { useEffect, useMemo, useState } from 'react';
import {
    AlertTriangle, CheckCircle2, Clipboard, Code2, LoaderCircle, Play,
    RefreshCw, Server, Square, TerminalSquare, XCircle,
} from 'lucide-react';
import {
    listGrokCliServices,
    runGrokCli,
    startGrokCliService,
    stopGrokCliService,
    type GrokCliResult,
    type GrokCliServiceInfo,
} from '@/services/grokDesktop';
import {
    buildGrokCliArguments,
    defaultGrokCliValues,
    GROK_CLI_ACTIONS,
    GROK_CLI_CATEGORY_LABELS,
    parseGrokCliCommand,
    type GrokCliAction,
    type GrokCliCategory,
    type GrokCliField,
} from './cliCatalog';

interface GrokCliCenterProps {
    workspace: string;
    onError: (message: string) => void;
    onLogin: (method?: 'browser' | 'oauth' | 'device') => Promise<void>;
    onRuntimeRefresh: () => Promise<void>;
}

const inputClass = 'w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none transition focus:border-slate-400 focus:ring-2 focus:ring-slate-100';

const redactVendorText = (value: string) => value
    .replace(/\bgrok(?:\s+build)?\b/gi, '内置智能引擎')
    .replace(/\bxai\b/gi, '服务');

const formatOutput = (result: GrokCliResult) => {
    const output = result.stdout || result.stderr || '命令执行完成，没有输出。';
    try {
        return redactVendorText(JSON.stringify(JSON.parse(output), null, 2));
    } catch {
        return redactVendorText(output);
    }
};

const FieldControl: React.FC<{
    field: GrokCliField;
    value: string | boolean;
    onChange: (value: string | boolean) => void;
}> = ({ field, value, onChange }) => {
    if (field.type === 'boolean') {
        return <label className="flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-700"><input type="checkbox" checked={Boolean(value)} onChange={(event) => onChange(event.target.checked)} />{field.label}</label>;
    }
    if (field.type === 'select') {
        return <label className="block"><span className="mb-1.5 block text-xs font-medium text-slate-600">{field.label}{field.required && ' *'}</span><select className={inputClass} value={String(value)} onChange={(event) => onChange(event.target.value)}>{field.options?.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}</select></label>;
    }
    if (field.type === 'multiline') {
        return <label className="block sm:col-span-2"><span className="mb-1.5 block text-xs font-medium text-slate-600">{field.label}{field.required && ' *'}</span><textarea className={inputClass} rows={4} value={String(value)} placeholder={field.placeholder} onChange={(event) => onChange(event.target.value)} /></label>;
    }
    return <label className="block"><span className="mb-1.5 block text-xs font-medium text-slate-600">{field.label}{field.required && ' *'}</span><input type={field.type === 'number' ? 'number' : 'text'} className={inputClass} value={String(value)} placeholder={field.placeholder} onChange={(event) => onChange(event.target.value)} /></label>;
};

const GrokCliCenter: React.FC<GrokCliCenterProps> = ({ workspace, onError, onLogin, onRuntimeRefresh }) => {
    const [category, setCategory] = useState<GrokCliCategory>('runtime');
    const initialAction = GROK_CLI_ACTIONS.find((action) => action.category === 'runtime')!;
    const [actionId, setActionId] = useState(initialAction.id);
    const [values, setValues] = useState<Record<string, string | boolean>>(defaultGrokCliValues(initialAction));
    const [result, setResult] = useState<GrokCliResult | null>(null);
    const [running, setRunning] = useState(false);
    const [rawCommand, setRawCommand] = useState('version --json');
    const [debug, setDebug] = useState(false);
    const [debugFile, setDebugFile] = useState('');
    const [leaderSocket, setLeaderSocket] = useState('');
    const [loginMethod, setLoginMethod] = useState<'browser' | 'oauth' | 'device'>('browser');
    const [services, setServices] = useState<GrokCliServiceInfo[]>([]);

    const categoryActions = useMemo(() => GROK_CLI_ACTIONS.filter((action) => action.category === category), [category]);
    const action = GROK_CLI_ACTIONS.find((item) => item.id === actionId) || categoryActions[0];

    const refreshServices = async () => {
        try {
            setServices(await listGrokCliServices());
        } catch (error) {
            onError(redactVendorText(error instanceof Error ? error.message : String(error)));
        }
    };

    useEffect(() => {
        if (category !== 'agent') return;
        void refreshServices();
        const timer = window.setInterval(() => void refreshServices(), 2_000);
        return () => window.clearInterval(timer);
    }, [category]);

    const chooseCategory = (nextCategory: GrokCliCategory) => {
        const first = GROK_CLI_ACTIONS.find((item) => item.category === nextCategory)!;
        setCategory(nextCategory);
        setActionId(first.id);
        setValues(defaultGrokCliValues(first));
        setResult(null);
    };

    const chooseAction = (nextAction: GrokCliAction) => {
        setActionId(nextAction.id);
        setValues(defaultGrokCliValues(nextAction));
        setResult(null);
    };

    const appendCommonArguments = (arguments_: string[]) => {
        const result = [...arguments_];
        if (debug) result.push('--debug');
        if (debugFile.trim()) result.push('--debug-file', debugFile.trim());
        if (leaderSocket.trim()) result.push('--leader-socket', leaderSocket.trim());
        return result;
    };

    const executeArguments = async (arguments_: string[], timeoutSeconds = 120, confirmation?: string) => {
        if (confirmation && !window.confirm(confirmation)) return;
        if (!workspace && !['version', 'models', 'login', 'logout', 'update', 'setup', 'completions', 'help'].includes(arguments_[0])) {
            onError('该 CLI 功能需要工作区，请先在设置中选择本地目录');
            return;
        }
        setRunning(true);
        setResult(null);
        try {
            const response = await runGrokCli(appendCommonArguments(arguments_), workspace, timeoutSeconds);
            setResult(response);
            if (!response.success) onError(redactVendorText(response.stderr || `内置命令退出码：${response.exitCode ?? '未知'}`));
            if (arguments_[0] === 'logout' || arguments_[0] === 'setup') await onRuntimeRefresh();
        } catch (error) {
            onError(redactVendorText(error instanceof Error ? error.message : String(error)));
        } finally {
            setRunning(false);
        }
    };

    const executeAction = async () => {
        if (action.execution === 'managed') {
            onError(action.mappedFeature || '该功能由 ARK Desktop 托管');
            return;
        }
        if (action.execution === 'service') {
            try {
                const arguments_ = appendCommonArguments(buildGrokCliArguments(action, values));
                if (action.confirmation && !window.confirm(action.confirmation)) return;
                setRunning(true);
                await startGrokCliService(arguments_, workspace);
                await refreshServices();
            } catch (error) {
                onError(redactVendorText(error instanceof Error ? error.message : String(error)));
            } finally {
                setRunning(false);
            }
            return;
        }
        try {
            await executeArguments(buildGrokCliArguments(action, values), action.timeoutSeconds, action.confirmation);
        } catch (error) {
            onError(redactVendorText(error instanceof Error ? error.message : String(error)));
        }
    };

    const executeRaw = async () => {
        try {
            const arguments_ = parseGrokCliCommand(rawCommand);
            if (arguments_[0] === 'agent' && arguments_.some((argument) => ['headless', 'serve', 'leader'].includes(argument))) {
                if (!window.confirm(`确认启动后台智能体服务：${rawCommand}？`)) return;
                setRunning(true);
                await startGrokCliService(appendCommonArguments(arguments_), workspace);
                await refreshServices();
                chooseCategory('agent');
                return;
            }
            await executeArguments(arguments_, 600, `确认执行内置命令：${rawCommand}？`);
        } catch (error) {
            onError(redactVendorText(error instanceof Error ? error.message : String(error)));
        } finally {
            setRunning(false);
        }
    };

    return <div className="p-6 md:p-8">
        <div className="mb-6">
            <h1 className="text-2xl font-semibold text-slate-900">运行管理</h1>
            <p className="mt-1 text-sm text-slate-500">内置 CLI 的所有能力按运行时、会话、MCP、插件、记忆、工作树和 Agent 服务分类呈现。</p>
        </div>

        <div className="mb-5 flex flex-wrap gap-2">
            {(Object.keys(GROK_CLI_CATEGORY_LABELS) as GrokCliCategory[]).map((key) => <button key={key} type="button" onClick={() => chooseCategory(key)} className={`rounded-full px-3.5 py-2 text-xs font-medium transition ${category === key ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}>{GROK_CLI_CATEGORY_LABELS[key]}</button>)}
        </div>

        <div className="grid gap-5 xl:grid-cols-[280px_minmax(0,1fr)]">
            <div className="space-y-2">
                {category === 'runtime' && <div className="mb-2 rounded-xl bg-slate-900 p-2"><select value={loginMethod} onChange={(event) => setLoginMethod(event.target.value as typeof loginMethod)} className="mb-2 w-full rounded-lg border border-white/20 bg-white/10 px-2 py-2 text-xs text-white"><option className="text-slate-900" value="browser">浏览器登录</option><option className="text-slate-900" value="oauth">OAuth 登录</option><option className="text-slate-900" value="device">设备码登录</option></select><button type="button" onClick={() => void onLogin(loginMethod).catch((error) => onError(redactVendorText(String(error))))} className="flex w-full items-center gap-2 rounded-lg px-1 py-1 text-left text-sm font-medium text-white"><Server size={16} />登录服务</button></div>}
                {categoryActions.map((item) => <button key={item.id} type="button" onClick={() => chooseAction(item)} className={`w-full rounded-xl border px-3 py-3 text-left transition ${action.id === item.id ? 'border-slate-900 bg-slate-50' : 'border-slate-200 hover:border-slate-300'}`}><span className="block text-sm font-medium text-slate-800">{item.title}</span><span className="mt-1 block text-xs leading-5 text-slate-400">{item.description}</span></button>)}
            </div>

            <div className="min-w-0 space-y-4">
                <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
                    <div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="font-semibold text-slate-900">{action.title}</h2><p className="mt-1 text-sm text-slate-500">{action.description}</p></div>{action.execution === 'managed' && <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs text-emerald-600">GUI 已映射</span>}{action.execution === 'service' && <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs text-blue-600">后台服务</span>}</div>
                    {(action.fields?.length || 0) > 0 && <div className="mt-5 grid gap-4 sm:grid-cols-2">{action.fields?.map((field) => <FieldControl key={field.key} field={field} value={values[field.key] ?? ''} onChange={(value) => setValues((current) => ({ ...current, [field.key]: value }))} />)}</div>}
                    {action.mappedFeature && <div className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2.5 text-sm text-emerald-700">{action.mappedFeature}</div>}
                    <div className="mt-5 flex justify-end"><button type="button" disabled={running} onClick={() => void executeAction()} className="flex items-center gap-2 rounded-xl bg-slate-900 px-4 py-2.5 text-sm font-medium text-white disabled:opacity-50">{running ? <LoaderCircle size={16} className="animate-spin" /> : <Play size={16} />}{action.execution === 'managed' ? '查看映射' : action.execution === 'service' ? '管理服务' : '执行'}</button></div>
                </div>

                <details className="rounded-2xl border border-slate-200 bg-white p-5">
                    <summary className="cursor-pointer text-sm font-semibold text-slate-800">CLI 通用选项</summary>
                    <div className="mt-4 grid gap-4 sm:grid-cols-2"><label className="flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-700"><input type="checkbox" checked={debug} onChange={(event) => setDebug(event.target.checked)} />启用调试日志</label><label className="block"><span className="mb-1.5 block text-xs font-medium text-slate-600">调试日志文件</span><input className={inputClass} value={debugFile} onChange={(event) => setDebugFile(event.target.value)} /></label><label className="block sm:col-span-2"><span className="mb-1.5 block text-xs font-medium text-slate-600">Leader Socket</span><input className={inputClass} value={leaderSocket} placeholder="留空使用默认路径" onChange={(event) => setLeaderSocket(event.target.value)} /></label></div>
                </details>

                {category === 'developer' && <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5"><div className="flex items-center gap-2 text-sm font-semibold text-amber-900"><TerminalSquare size={17} />完整命令模式</div><p className="mt-1 text-xs leading-5 text-amber-700">填写内置命令参数。使用参数数组直接启动本地运行时，不经过系统 Shell。</p><div className="mt-3 flex gap-2"><input className={inputClass} value={rawCommand} onChange={(event) => setRawCommand(event.target.value)} /><button type="button" disabled={running} onClick={() => void executeRaw()} className="shrink-0 rounded-xl bg-amber-900 px-4 text-sm text-white">执行</button></div></div>}

                {category === 'agent' && <div className="rounded-2xl border border-slate-200 bg-white p-5"><div className="mb-3 flex items-center justify-between"><h2 className="text-sm font-semibold text-slate-800">后台智能体服务</h2><button type="button" onClick={() => void refreshServices()} className="rounded-lg p-2 text-slate-500 hover:bg-slate-100"><RefreshCw size={15} /></button></div>{services.length === 0 ? <p className="text-sm text-slate-400">暂无后台智能体服务。</p> : <div className="space-y-3">{services.map((service) => <div key={service.id} className="rounded-xl border border-slate-200 p-3"><div className="flex items-center justify-between gap-3"><div className="min-w-0"><div className="truncate font-mono text-xs text-slate-700">内置命令 {service.arguments.join(' ')}</div><div className="mt-1 text-[11px] text-slate-400">PID {service.pid} · {service.alive ? '运行中' : `已退出 ${service.exitCode ?? ''}`}</div></div>{service.alive && <button type="button" onClick={() => void stopGrokCliService(service.id).then(refreshServices).catch((error) => onError(redactVendorText(String(error))))} className="flex shrink-0 items-center gap-1 rounded-lg bg-red-50 px-2.5 py-1.5 text-xs text-red-600"><Square size={12} />停止</button>}</div>{(service.stdout || service.stderr) && <pre className="mt-3 max-h-48 overflow-auto whitespace-pre-wrap rounded-lg bg-slate-950 p-3 text-xs leading-5 text-slate-300">{redactVendorText(`${service.stdout}${service.stderr ? `\n${service.stderr}` : ''}`)}</pre>}</div>)}</div>}</div>}

                {result && <div className={`rounded-2xl border p-5 ${result.success ? 'border-emerald-200 bg-emerald-50/40' : 'border-red-200 bg-red-50/40'}`}><div className="mb-3 flex items-center justify-between gap-3"><div className={`flex items-center gap-2 text-sm font-semibold ${result.success ? 'text-emerald-700' : 'text-red-700'}`}>{result.success ? <CheckCircle2 size={17} /> : <XCircle size={17} />}{result.success ? '执行成功' : `执行失败（${result.exitCode ?? '未知'}）`}</div><div className="flex gap-1"><button type="button" onClick={() => void navigator.clipboard.writeText(formatOutput(result))} className="rounded-lg p-2 text-slate-500 hover:bg-white" title="复制输出"><Clipboard size={15} /></button><button type="button" onClick={() => setResult(null)} className="rounded-lg p-2 text-slate-500 hover:bg-white"><RefreshCw size={15} /></button></div></div><div className="mb-2 overflow-x-auto rounded-lg bg-slate-900 px-3 py-2 font-mono text-xs text-slate-300">内置命令 {result.arguments.join(' ')}</div><pre className="max-h-[420px] overflow-auto whitespace-pre-wrap break-words rounded-xl bg-white p-4 text-xs leading-6 text-slate-700">{formatOutput(result)}</pre>{result.stderr && result.stdout && <details className="mt-3"><summary className="cursor-pointer text-xs text-amber-700"><AlertTriangle size={13} className="mr-1 inline" />查看错误输出</summary><pre className="mt-2 whitespace-pre-wrap rounded-lg bg-amber-50 p-3 text-xs text-amber-800">{redactVendorText(result.stderr)}</pre></details>}</div>}
            </div>
        </div>
    </div>;
};

export default GrokCliCenter;
