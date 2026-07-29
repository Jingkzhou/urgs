import React from 'react';
import { AlertTriangle, ShieldCheck, SlidersHorizontal } from 'lucide-react';
import type { GrokExecutionSettings } from './types';

interface GrokExecutionSettingsPanelProps {
    value: GrokExecutionSettings;
    onChange: (value: GrokExecutionSettings) => void;
}

const inputClass = 'w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none transition focus:border-slate-400 focus:ring-2 focus:ring-slate-100';
const Field: React.FC<{ label: string; children: React.ReactNode; hint?: string }> = ({ label, children, hint }) => <label className="block"><span className="mb-1.5 block text-xs font-medium text-slate-600">{label}</span>{children}{hint && <span className="mt-1 block text-[11px] leading-5 text-slate-400">{hint}</span>}</label>;
const Toggle: React.FC<{ checked: boolean; label: string; onChange: (checked: boolean) => void }> = ({ checked, label, onChange }) => <label className="flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-700"><input type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} />{label}</label>;

const GrokExecutionSettingsPanel: React.FC<GrokExecutionSettingsPanelProps> = ({ value, onChange }) => {
    const set = <K extends keyof GrokExecutionSettings>(key: K, next: GrokExecutionSettings[K]) => onChange({ ...value, [key]: next });
    const dangerous = value.permissionMode === 'bypassPermissions';
    const isHeadless = value.engine === 'headless';

    return <div className="space-y-4">
        <div className="rounded-2xl border border-slate-200 p-5">
            <div className="mb-4 flex items-center gap-2"><SlidersHorizontal size={17} className="text-slate-500" /><h3 className="font-semibold text-slate-900">任务执行引擎</h3></div>
            <div className="grid gap-4 sm:grid-cols-2">
                <Field label="执行模式" hint="ACP 支持流式步骤与逐次授权；Headless 开放完整 CLI 参数。"><select className={inputClass} value={value.engine} onChange={(event) => set('engine', event.target.value as GrokExecutionSettings['engine'])}><option value="acp">ACP 交互模式</option><option value="headless">CLI Headless 模式</option></select></Field>
                <Field label="Reasoning Effort"><input className={inputClass} value={value.reasoningEffort} onChange={(event) => set('reasoningEffort', event.target.value)} placeholder="留空使用模型默认值" /></Field>
                <Field label="权限模式" hint="其他持久化权限策略请在运行配置中设置。"><select className={inputClass} value={value.permissionMode} onChange={(event) => set('permissionMode', event.target.value as GrokExecutionSettings['permissionMode'])}><option value="default">请求批准（default）</option><option value="bypassPermissions">完全访问权限（bypassPermissions）</option></select></Field>
                <Field label="Sandbox Profile"><input className={inputClass} value={value.sandboxProfile} onChange={(event) => set('sandboxProfile', event.target.value)} placeholder="留空使用默认沙箱" /></Field>
                {isHeadless && <><Field label="输出格式"><select className={inputClass} value={value.outputFormat} onChange={(event) => set('outputFormat', event.target.value as GrokExecutionSettings['outputFormat'])}><option value="json">JSON</option><option value="plain">纯文本</option><option value="streaming-json">Streaming JSON</option></select></Field><Field label="最大轮数"><input type="number" min={0} className={inputClass} value={value.maxTurns} onChange={(event) => set('maxTurns', Number(event.target.value))} /></Field></>}
            </div>
            {dangerous && <div className="mt-4 flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 px-3 py-2.5 text-xs leading-5 text-red-700"><AlertTriangle size={15} className="mt-0.5 shrink-0" />当前配置允许智能体无需逐次确认执行本地操作，发起任务时会再次确认。</div>}
        </div>

        {isHeadless && <><details className="rounded-2xl border border-slate-200 p-5" open>
            <summary className="cursor-pointer text-sm font-semibold text-slate-900">工具、权限与记忆</summary>
            <div className="mt-4 grid gap-4 sm:grid-cols-2">
                <Toggle checked={value.noPlan} label="禁用计划模式 (--no-plan)" onChange={(checked) => set('noPlan', checked)} />
                <Toggle checked={value.noSubagents} label="禁用子 Agent (--no-subagents)" onChange={(checked) => set('noSubagents', checked)} />
                <Toggle checked={value.disableWebSearch} label="禁用 Web 搜索" onChange={(checked) => set('disableWebSearch', checked)} />
                <Toggle checked={value.verbatim} label="原样发送 Prompt" onChange={(checked) => set('verbatim', checked)} />
                <Field label="记忆模式"><select className={inputClass} value={value.memoryMode} onChange={(event) => set('memoryMode', event.target.value as GrokExecutionSettings['memoryMode'])}><option value="default">默认</option><option value="disabled">禁用</option><option value="experimental">实验性跨会话记忆</option></select></Field>
                <Field label="允许的工具"><input className={inputClass} value={value.allowedTools} onChange={(event) => set('allowedTools', event.target.value)} placeholder="逗号分隔" /></Field>
                <Field label="禁用的工具"><input className={inputClass} value={value.disallowedTools} onChange={(event) => set('disallowedTools', event.target.value)} placeholder="逗号分隔" /></Field>
                <Field label="允许规则"><textarea className={inputClass} rows={4} value={value.allowRules} onChange={(event) => set('allowRules', event.target.value)} placeholder="每行一条，例如 Bash(git status:*)" /></Field>
                <Field label="拒绝规则"><textarea className={inputClass} rows={4} value={value.denyRules} onChange={(event) => set('denyRules', event.target.value)} placeholder="每行一条" /></Field>
            </div>
        </details>

        <details className="rounded-2xl border border-slate-200 p-5">
            <summary className="cursor-pointer text-sm font-semibold text-slate-900">Agent、系统指令与结构化输出</summary>
            <div className="mt-4 grid gap-4 sm:grid-cols-2">
                <Field label="CLI Agent 名称或文件"><input className={inputClass} value={value.agentName} onChange={(event) => set('agentName', event.target.value)} /></Field>
                <Field label="Inline Subagents JSON"><textarea className={inputClass} rows={4} value={value.inlineAgentsJson} onChange={(event) => set('inlineAgentsJson', event.target.value)} /></Field>
                <Field label="追加 Rules"><textarea className={inputClass} rows={5} value={value.additionalRules} onChange={(event) => set('additionalRules', event.target.value)} /></Field>
                <Field label="覆盖 System Prompt"><textarea className={inputClass} rows={5} value={value.systemPromptOverride} onChange={(event) => set('systemPromptOverride', event.target.value)} /></Field>
                <Field label="JSON Schema"><textarea className={inputClass} rows={5} value={value.jsonSchema} onChange={(event) => set('jsonSchema', event.target.value)} placeholder='{"type":"object"}' /></Field>
            </div>
        </details>

        <details className="rounded-2xl border border-slate-200 p-5">
            <summary className="cursor-pointer text-sm font-semibold text-slate-900">会话、Prompt 与工作树</summary>
            <div className="mt-4 grid gap-4 sm:grid-cols-2">
                <Field label="会话模式"><select className={inputClass} value={value.sessionMode} onChange={(event) => set('sessionMode', event.target.value as GrokExecutionSettings['sessionMode'])}><option value="new">新会话</option><option value="continue">继续最近会话</option><option value="resume">恢复指定会话</option></select></Field>
                {value.sessionMode === 'resume' && <Field label="恢复会话 ID"><input className={inputClass} value={value.resumeSessionId} onChange={(event) => set('resumeSessionId', event.target.value)} /></Field>}
                <Field label="新会话 UUID"><input className={inputClass} value={value.newSessionId} onChange={(event) => set('newSessionId', event.target.value)} /></Field>
                <Field label="Prompt 模式"><select className={inputClass} value={value.promptMode} onChange={(event) => set('promptMode', event.target.value as GrokExecutionSettings['promptMode'])}><option value="text">输入框文本</option><option value="file">Prompt 文件</option><option value="json">JSON 内容块</option></select></Field>
                {value.promptMode === 'file' && <Field label="Prompt 文件路径"><input className={inputClass} value={value.promptFile} onChange={(event) => set('promptFile', event.target.value)} /></Field>}
                {value.promptMode === 'json' && <Field label="Prompt JSON"><textarea className={inputClass} rows={4} value={value.promptJson} onChange={(event) => set('promptJson', event.target.value)} /></Field>}
                <Toggle checked={value.forkSession} label="恢复时创建分支会话" onChange={(checked) => set('forkSession', checked)} />
                <Toggle checked={value.restoreCode} label="恢复会话原始代码" onChange={(checked) => set('restoreCode', checked)} />
                <Toggle checked={value.useWorktree} label="在新 Worktree 中执行" onChange={(checked) => set('useWorktree', checked)} />
                {value.useWorktree && <><Field label="Worktree 名称"><input className={inputClass} value={value.worktreeName} onChange={(event) => set('worktreeName', event.target.value)} /></Field><Field label="Worktree 基准"><input className={inputClass} value={value.worktreeRef} onChange={(event) => set('worktreeRef', event.target.value)} /></Field></>}
            </div>
        </details></>}

        <details className="rounded-2xl border border-slate-200 p-5" open={!isHeadless}>
            <summary className="cursor-pointer text-sm font-semibold text-slate-900">{isHeadless ? '认证与调试' : 'ACP 进程与诊断'}</summary>
            <div className="mt-4 grid gap-4 sm:grid-cols-2">
                {isHeadless ? <Toggle checked={value.oauth} label="使用 OAuth" onChange={(checked) => set('oauth', checked)} /> : <Toggle checked={value.reauth} label="启动前重新认证" onChange={(checked) => set('reauth', checked)} />}
                <Toggle checked={value.debug} label="启用 Debug" onChange={(checked) => set('debug', checked)} />
                {!isHeadless && <><Field label="ACP Agent Profile"><input className={inputClass} value={value.agentProfile} onChange={(event) => set('agentProfile', event.target.value)} /></Field><Field label="临时插件目录" hint="每行一个目录，仅对本次 ACP 进程生效。"><textarea className={inputClass} rows={4} value={value.pluginDirs} onChange={(event) => set('pluginDirs', event.target.value)} /></Field><Field label="Leader 连接模式"><select className={inputClass} value={value.leaderMode} onChange={(event) => set('leaderMode', event.target.value as GrokExecutionSettings['leaderMode'])}><option value="default">配置默认值</option><option value="leader">连接共享 Leader</option><option value="standalone">独立进程</option></select></Field><Field label="任务服务 WS Origin"><input className={inputClass} value={value.grokWsOrigin} onChange={(event) => set('grokWsOrigin', event.target.value)} /></Field><Field label="任务服务 WS URL"><input className={inputClass} value={value.grokWsUrl} onChange={(event) => set('grokWsUrl', event.target.value)} /></Field><Field label="CLI Chat Proxy URL"><input className={inputClass} value={value.cliChatProxyUrl} onChange={(event) => set('cliChatProxyUrl', event.target.value)} /></Field><Field label="服务 API Base URL"><input className={inputClass} value={value.xaiApiBaseUrl} onChange={(event) => set('xaiApiBaseUrl', event.target.value)} /></Field></>}
                <Field label="Debug 文件"><input className={inputClass} value={value.debugFile} onChange={(event) => set('debugFile', event.target.value)} /></Field>
                <Field label="Leader Socket"><input className={inputClass} value={value.leaderSocket} onChange={(event) => set('leaderSocket', event.target.value)} /></Field>
            </div>
        </details>

        <div className="flex items-start gap-2 rounded-xl border border-blue-200 bg-blue-50 px-3 py-2.5 text-xs leading-5 text-blue-700"><ShieldCheck size={15} className="mt-0.5 shrink-0" />{isHeadless ? 'Headless 适合自动化和结构化输出，不提供 ACP 的实时工具时间线与逐次授权界面。' : '当前只显示 ACP 会实际应用的选项；流式步骤、工具调用和权限请求会在会话中实时呈现。'}</div>
    </div>;
};

export default GrokExecutionSettingsPanel;
