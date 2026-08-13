import React from 'react';
import { AlertTriangle, ShieldCheck, SlidersHorizontal } from 'lucide-react';
import type { GrokModelCatalog } from '@/services/grokDesktop';
import type { GrokExecutionSettings } from './types';

interface GrokExecutionSettingsPanelProps {
    value: GrokExecutionSettings;
    onChange: (value: GrokExecutionSettings) => void;
    modelCatalog?: GrokModelCatalog | null;
}

const inputClass = 'w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-800 outline-none transition focus:border-slate-400 focus:ring-2 focus:ring-slate-100';
const Field: React.FC<{ label: string; children: React.ReactNode; hint?: string }> = ({ label, children, hint }) => <label className="block"><span className="mb-1.5 block text-xs font-medium text-slate-600">{label}</span>{children}{hint && <span className="mt-1 block text-[11px] leading-5 text-slate-400">{hint}</span>}</label>;
const Toggle: React.FC<{ checked: boolean; label: string; onChange: (checked: boolean) => void }> = ({ checked, label, onChange }) => <label className="flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5 text-sm text-slate-700"><input type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} />{label}</label>;
const visibleReasoningEfforts = new Set(['none', 'low', 'high', 'max']);

const GrokExecutionSettingsPanel: React.FC<GrokExecutionSettingsPanelProps> = ({ value, onChange, modelCatalog }) => {
    const set = <K extends keyof GrokExecutionSettings>(key: K, next: GrokExecutionSettings[K]) => onChange({ ...value, [key]: next });
    const dangerous = value.permissionMode === 'bypassPermissions';
    const isHeadless = value.engine === 'headless';
    const model = modelCatalog?.availableModels.find((item) => item.modelId === modelCatalog.currentModelId)
        || modelCatalog?.availableModels.find((item) => item.supportsReasoningEffort);
    const reasoningOptions = (model?.reasoningEfforts || []).filter((option) => visibleReasoningEfforts.has(option.value));

    return <div className="space-y-4">
        <div className="rounded-2xl border border-slate-200 p-5">
            <div className="mb-4 flex items-center gap-2"><SlidersHorizontal size={17} className="text-slate-500" /><h3 className="font-semibold text-slate-900">任务执行引擎</h3></div>
            <div className="grid gap-4 sm:grid-cols-2">
                <Field label="执行模式" hint="ACP 支持流式步骤与逐次授权；Headless 开放完整 CLI 参数。"><select className={inputClass} value={value.engine} onChange={(event) => set('engine', event.target.value as GrokExecutionSettings['engine'])}><option value="acp">ACP 交互模式</option><option value="headless">CLI Headless 模式</option></select></Field>
                <Field label="Reasoning Effort" hint={modelCatalog?.totalContextTokens ? `当前模型上下文窗口：${modelCatalog.totalContextTokens.toLocaleString()} tokens` : '默认使用高思考级别。'}>{reasoningOptions.length > 0 ? <select className={inputClass} value={value.reasoningEffort} onChange={(event) => set('reasoningEffort', event.target.value)}>{reasoningOptions.map((option) => <option key={option.id || option.value} value={option.value}>{option.label || option.value}{option.description ? ` · ${option.description}` : ''}</option>)}</select> : <input className={inputClass} value={value.reasoningEffort} onChange={(event) => set('reasoningEffort', event.target.value)} placeholder="high" />}</Field>
                <Field label="权限模式" hint="其他持久化权限策略请在运行配置中设置。"><select className={inputClass} value={value.permissionMode} onChange={(event) => set('permissionMode', event.target.value as GrokExecutionSettings['permissionMode'])}><option value="default">请求批准（default）</option><option value="bypassPermissions">完全访问权限（bypassPermissions）</option></select></Field>
                {!isHeadless && <Field label="交互模式" hint="Plan 只分析和产出计划；Ask 优先向你确认关键选择。"><select className={inputClass} value={value.interactionMode} onChange={(event) => set('interactionMode', event.target.value as GrokExecutionSettings['interactionMode'])}><option value="default">正常执行（default）</option><option value="plan">计划模式（plan）</option><option value="ask">询问模式（ask）</option></select></Field>}
                <Field label="Sandbox Profile"><input className={inputClass} value={value.sandboxProfile} onChange={(event) => set('sandboxProfile', event.target.value)} placeholder="留空使用默认沙箱" /></Field>
                {isHeadless && <><Field label="输出格式"><select className={inputClass} value={value.outputFormat} onChange={(event) => set('outputFormat', event.target.value as GrokExecutionSettings['outputFormat'])}><option value="json">JSON</option><option value="plain">纯文本</option><option value="streaming-json">Streaming JSON</option></select></Field><Field label="最大轮数"><input type="number" min={0} className={inputClass} value={value.maxTurns} onChange={(event) => set('maxTurns', Number(event.target.value))} /></Field></>}
            </div>
            {dangerous && <div className="mt-4 flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 px-3 py-2.5 text-xs leading-5 text-red-700"><AlertTriangle size={15} className="mt-0.5 shrink-0" />当前配置允许智能体无需逐次确认执行本地操作，发起任务时会再次确认。</div>}
        </div>

        <div className="rounded-2xl border border-indigo-200 bg-indigo-50/40 p-5">
            <div className="mb-3 flex items-center gap-2"><SlidersHorizontal size={17} className="text-indigo-600" /><h3 className="font-semibold text-slate-900">代码隔离与 Git</h3></div>
            <div className="grid gap-4 sm:grid-cols-2">
                <Field label="任务代码位置" hint="默认直接使用当前工作区，行为与 VS Code 等本地开发工具一致；需要并行隔离时再选择独立 Worktree。只读分析使用独立 detached 快照，不回写源仓库。">
                    <select className={inputClass} value={value.gitMode} onChange={(event) => { const gitMode = event.target.value as GrokExecutionSettings['gitMode']; onChange({ ...value, gitMode, useWorktree: gitMode === 'worktree' }); }}>
                        <option value="workspace">当前工作区（推荐）</option>
                        <option value="worktree">独立 Worktree</option>
                        <option value="readonly">只读分析</option>
                    </select>
                </Field>
                {value.gitMode === 'worktree' && <>
                    <Field label="Worktree 名称" hint="会生成任务分支，留空使用任务标题。"><input className={inputClass} value={value.worktreeName} onChange={(event) => set('worktreeName', event.target.value)} placeholder="例如：报表校验" /></Field>
                    <Field label="Worktree 基准" hint="留空从当前 HEAD 创建，也可以填 main、origin/main 或提交号。"><input className={inputClass} value={value.worktreeRef} onChange={(event) => set('worktreeRef', event.target.value)} placeholder="HEAD" /></Field>
                </>}
            </div>
            <p className="mt-3 text-[11px] leading-5 text-indigo-700">智能体实际运行目录、会话 cwd、Git 状态和后续审查对象保持一致；应用 Worktree 前必须先完成审查与提交。只读分析不会把源仓库切换到 detached 状态。</p>
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
            </div>
        </details></>}

        <details className="rounded-2xl border border-slate-200 p-5" open={!isHeadless}>
            <summary className="cursor-pointer text-sm font-semibold text-slate-900">{isHeadless ? '调试选项' : 'ACP 进程与诊断'}</summary>
            <div className="mt-4 grid gap-4 sm:grid-cols-2">
                <Toggle checked={value.debug} label="启用 Debug" onChange={(checked) => set('debug', checked)} />
                {!isHeadless && <><Field label="ACP Agent Profile"><input className={inputClass} value={value.agentProfile} onChange={(event) => set('agentProfile', event.target.value)} /></Field><Field label="临时插件目录" hint="每行一个目录，仅对本次 ACP 进程生效。"><textarea className={inputClass} rows={4} value={value.pluginDirs} onChange={(event) => set('pluginDirs', event.target.value)} /></Field><Field label="Leader 连接模式"><select className={inputClass} value={value.leaderMode} onChange={(event) => set('leaderMode', event.target.value as GrokExecutionSettings['leaderMode'])}><option value="default">配置默认值</option><option value="leader">连接共享 Leader</option><option value="standalone">独立进程</option></select></Field><Field label="任务服务 WS Origin"><input className={inputClass} value={value.grokWsOrigin} onChange={(event) => set('grokWsOrigin', event.target.value)} /></Field><Field label="任务服务 WS URL"><input className={inputClass} value={value.grokWsUrl} onChange={(event) => set('grokWsUrl', event.target.value)} /></Field></>}
                <Field label="Debug 文件"><input className={inputClass} value={value.debugFile} onChange={(event) => set('debugFile', event.target.value)} /></Field>
                <Field label="Leader Socket"><input className={inputClass} value={value.leaderSocket} onChange={(event) => set('leaderSocket', event.target.value)} /></Field>
            </div>
        </details>

        <div className="flex items-start gap-2 rounded-xl border border-blue-200 bg-blue-50 px-3 py-2.5 text-xs leading-5 text-blue-700"><ShieldCheck size={15} className="mt-0.5 shrink-0" />{isHeadless ? 'Headless 适合自动化和结构化输出，不提供 ACP 的实时工具时间线与逐次授权界面。' : '当前只显示 ACP 会实际应用的选项；流式步骤、工具调用和权限请求会在会话中实时呈现。'}</div>
    </div>;
};

export default GrokExecutionSettingsPanel;
