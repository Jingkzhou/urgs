import React, { useEffect, useState } from 'react';
import { CheckCircle2, FileCode2, LoaderCircle, RefreshCw, Save } from 'lucide-react';
import { readGrokConfig, saveGrokConfig, type GrokConfigFile } from '@/services/grokDesktop';

interface GrokConfigEditorProps {
    workspace: string;
    onError: (message: string) => void;
}

type ConfigScope = 'user' | 'project';
type ConfigKind = 'config' | 'appearance';

const templates: Array<{ id: string; label: string; content: string }> = [
    { id: 'basic', label: '基础模型与 CLI', content: `[cli]
auto_update = false

[models]
default = "grok-4.5-build-free"
web_search = "grok-4.20-multi-agent"

[features]
telemetry = false
feedback = true
lsp_tools = false
codebase_indexing = true
` },
    { id: 'tools', label: '工具与权限', content: `[tools]
respect_gitignore = true

[toolset.bash]
timeout_secs = 120.0
output_byte_limit = 20000

[toolset.ask_user_question]
timeout_enabled = true
timeout_secs = 1800
` },
    { id: 'mcp', label: 'MCP Server', content: `[mcp_servers.example]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-example"]
enabled = true
startup_timeout_sec = 30
tool_timeout_sec = 6000
` },
    { id: 'memory', label: '记忆、子 Agent 与技能', content: `[memory]
enabled = true

[memory.session]
save_on_end = true

[subagents]
enabled = true

[skills]
paths = ["~/my-grok-skills"]
ignore = []
disabled = []
` },
    { id: 'compat', label: '兼容与插件', content: `[compat.cursor]
skills = true
rules = true
agents = true
mcps = true
hooks = true

[compat.claude]
skills = true
rules = true
agents = true
mcps = true
hooks = true

[plugins]
paths = ["~/my-grok-plugins"]
disabled = []
` },
];

const appearanceTemplate = `[terminal]
alt_screen = "auto"

[animation]
fps = 30
wave_rows = 32

[prompt]
collapse_unfocused = true
mouse_hover = true
show_prefix = true

[scrollback.scrollbar]
enabled = true
gap_left = 0
gap_right = 0

[scrollback.display]
sticky_headers = true
tab_width = 4
`;

const GrokConfigEditor: React.FC<GrokConfigEditorProps> = ({ workspace, onError }) => {
    const [scope, setScope] = useState<ConfigScope>('user');
    const [kind, setKind] = useState<ConfigKind>('config');
    const [file, setFile] = useState<GrokConfigFile>();
    const [content, setContent] = useState('');
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const [saved, setSaved] = useState(false);

    const load = async (nextScope = scope, nextKind = kind) => {
        if (nextScope === 'project' && !workspace) return;
        setLoading(true);
        setSaved(false);
        try {
            const next = await readGrokConfig(nextScope, workspace, nextKind);
            setFile(next);
            setContent(next.content);
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { void load(scope, kind); }, [scope, kind, workspace]);

    const appendTemplate = (templateId: string) => {
        const text = templateId === 'appearance' ? appearanceTemplate : templates.find((item) => item.id === templateId)?.content;
        if (!text) return;
        setSaved(false);
        setContent((current) => current.trim() ? `${current.trimEnd()}\n\n${text}` : text);
    };

    const save = async () => {
        if (scope === 'project' && !workspace) return;
        if (!window.confirm(`确认保存 Grok ${scope === 'user' ? '用户级' : '项目级'}配置？已有文件会自动备份。`)) return;
        setSaving(true);
        setSaved(false);
        try {
            const next = await saveGrokConfig(scope, content, workspace, kind);
            setFile(next);
            setContent(next.content);
            setSaved(true);
        } catch (error) {
            onError(error instanceof Error ? error.message : String(error));
        } finally {
            setSaving(false);
        }
    };

    return <div className="rounded-2xl border border-slate-200 p-5">
        <div className="flex flex-wrap items-start justify-between gap-3">
            <div><div className="flex items-center gap-2"><FileCode2 size={17} className="text-slate-500" /><h3 className="font-semibold text-slate-900">Grok 原生配置</h3></div><p className="mt-1 text-sm leading-6 text-slate-500">直接编辑 Grok 的 config.toml 或 pager.toml；保存前由本地端校验 TOML，并为旧文件创建 .urgs-backup 备份。</p></div>
            <div className="flex rounded-xl bg-slate-100 p-1 text-xs">
                {(['user', 'project'] as ConfigScope[]).map((item) => <button key={item} type="button" disabled={(item === 'project' && !workspace) || (item === 'project' && kind === 'appearance')} onClick={() => setScope(item)} className={`rounded-lg px-3 py-1.5 ${scope === item ? 'bg-white font-medium text-slate-900 shadow-sm' : 'text-slate-500 disabled:opacity-40'}`}>{item === 'user' ? '用户配置' : '项目配置'}</button>)}
            </div>
        </div>
        {scope === 'project' && <p className="mt-3 rounded-xl bg-amber-50 px-3 py-2 text-xs leading-5 text-amber-700">项目级配置写入当前工作区 .grok/config.toml；Grok 仅从这里合并 MCP、插件与权限相关项目配置，其余全局选项请写入用户配置。</p>}
        <div className="mt-4 flex flex-wrap items-center gap-2">
            <select aria-label="Grok 配置文件类型" value={kind} onChange={(event) => { const next = event.target.value as ConfigKind; setKind(next); if (next === 'appearance') setScope('user'); }} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs text-slate-600 outline-none"><option value="config">config.toml（功能配置）</option><option value="appearance">pager.toml（TUI 外观）</option></select>
            <select aria-label="Grok 配置模板" defaultValue="" onChange={(event) => { appendTemplate(event.target.value); event.target.value = ''; }} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs text-slate-600 outline-none">
                <option value="" disabled>插入配置片段…</option>
                {kind === 'config' ? templates.map((template) => <option key={template.id} value={template.id}>{template.label}</option>) : <option value="appearance">完整外观模板</option>}
            </select>
            <button type="button" disabled={loading || (scope === 'project' && !workspace)} onClick={() => void load()} className="flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-xs text-slate-600 disabled:opacity-40"><RefreshCw size={14} className={loading ? 'animate-spin' : ''} />重新读取</button>
            <span className="min-w-0 flex-1 break-all text-right text-[11px] text-slate-400">{file?.path || (scope === 'project' && !workspace ? '请先选择默认工作区' : '正在读取配置路径')}</span>
        </div>
        <textarea aria-label={`Grok ${kind === 'config' ? 'config.toml' : 'pager.toml'}`} spellCheck={false} value={content} onChange={(event) => { setContent(event.target.value); setSaved(false); }} rows={22} className="mt-3 w-full resize-y rounded-xl border border-slate-200 bg-slate-950 p-4 font-mono text-xs leading-6 text-slate-100 outline-none focus:border-slate-400" placeholder={`# 在此编辑 Grok ${kind === 'config' ? 'config.toml' : 'pager.toml'}`} />
        <div className="mt-3 flex items-center justify-between gap-3">
            <span className="text-xs text-slate-400">{file?.exists ? '配置文件已存在' : '尚未创建配置文件'}</span>
            <div className="flex items-center gap-3">{saved && <span className="flex items-center gap-1 text-xs text-emerald-600"><CheckCircle2 size={14} />已保存并通过校验</span>}<button type="button" disabled={saving || loading || (scope === 'project' && !workspace)} onClick={() => void save()} className="flex items-center gap-1.5 rounded-lg bg-slate-900 px-3 py-2 text-xs text-white disabled:opacity-40">{saving ? <LoaderCircle size={14} className="animate-spin" /> : <Save size={14} />}保存 Grok 配置</button></div>
        </div>
    </div>;
};

export default GrokConfigEditor;
