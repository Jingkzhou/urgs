export type GrokCliCategory = 'runtime' | 'sessions' | 'mcp' | 'plugins' | 'memory' | 'worktrees' | 'agent' | 'developer';
export type GrokCliFieldType = 'text' | 'number' | 'select' | 'boolean' | 'multiline' | 'arguments';

export interface GrokCliField {
    key: string;
    label: string;
    type: GrokCliFieldType;
    flag?: string;
    positional?: boolean;
    required?: boolean;
    repeatLines?: boolean;
    beforeSubcommand?: boolean;
    placeholder?: string;
    defaultValue?: string | boolean;
    options?: Array<{ label: string; value: string }>;
}

export interface GrokCliAction {
    id: string;
    category: GrokCliCategory;
    title: string;
    description: string;
    baseArguments: string[];
    fields?: GrokCliField[];
    confirmation?: string;
    timeoutSeconds?: number;
    execution?: 'command' | 'managed' | 'service';
    mappedFeature?: string;
}

export const GROK_CLI_CATEGORY_LABELS: Record<GrokCliCategory, string> = {
    runtime: '运行时与模型',
    sessions: '会话与导出',
    mcp: 'MCP 服务',
    plugins: '插件与市场',
    memory: '记忆',
    worktrees: '工作树',
    agent: 'Agent 服务',
    developer: '开发与诊断',
};

const text = (key: string, label: string, options: Partial<GrokCliField> = {}): GrokCliField => ({ key, label, type: 'text', ...options });
const bool = (key: string, label: string, flag: string, defaultValue = false): GrokCliField => ({ key, label, type: 'boolean', flag, defaultValue });

const agentServiceFields: GrokCliField[] = [
    text('model', '模型', { flag: '--model', beforeSubcommand: true }),
    text('reasoningEffort', 'Reasoning Effort', { flag: '--reasoning-effort', beforeSubcommand: true }),
    { key: 'alwaysApprove', label: '自动批准工具', type: 'boolean', flag: '--always-approve', defaultValue: false, beforeSubcommand: true },
    text('agentProfile', 'Agent Profile 文件', { flag: '--agent-profile', beforeSubcommand: true }),
    { key: 'pluginDirs', label: '临时插件目录', type: 'multiline', flag: '--plugin-dir', repeatLines: true, beforeSubcommand: true, placeholder: '每行一个目录' },
    { key: 'leaderMode', label: 'Leader 连接模式', type: 'select', defaultValue: '', beforeSubcommand: true, options: [{ label: '使用配置默认值', value: '' }, { label: '连接共享 Leader', value: '--leader' }, { label: '独立 Agent', value: '--no-leader' }] },
    text('grokWsOrigin', '任务服务 WS Origin', { flag: '--grok-ws-origin', beforeSubcommand: true }),
    text('grokWsUrl', '任务服务 WS URL', { flag: '--grok-ws-url', beforeSubcommand: true }),
];

export const GROK_CLI_ACTIONS: GrokCliAction[] = [
    { id: 'version', category: 'runtime', title: '版本详情', description: '读取内置运行组件的结构化版本信息。', baseArguments: ['version', '--json'] },
    { id: 'inspect', category: 'runtime', title: '检查生效配置', description: '检查当前工作区发现的规则、配置、插件和 MCP。', baseArguments: ['inspect', '--json'] },
    { id: 'doctor', category: 'runtime', title: '运行环境诊断', description: '检查终端、剪贴板、颜色和输入支持并输出结构化报告。', baseArguments: ['doctor', '--json'] },
    { id: 'doctor-fix', category: 'runtime', title: '修复运行环境', description: '执行内置诊断建议的自动修复。', baseArguments: ['doctor', 'fix'], confirmation: '这会修改本地运行环境配置，确认执行自动修复？' },

    { id: 'session-list', category: 'sessions', title: '最近会话', description: '列出本地会话。', baseArguments: ['sessions', 'list'], fields: [{ key: 'limit', label: '数量', type: 'number', flag: '--limit', defaultValue: '20' }] },
    { id: 'session-search', category: 'sessions', title: '搜索会话', description: '按摘要和首条提示搜索会话。', baseArguments: ['sessions', 'search'], fields: [text('query', '关键词', { positional: true, required: true }), { key: 'limit', label: '数量', type: 'number', flag: '--limit', defaultValue: '20' }] },
    { id: 'session-delete', category: 'sessions', title: '删除会话', description: '从本地历史中永久删除指定会话。', baseArguments: ['sessions', 'delete'], fields: [text('sessionId', '会话 ID', { positional: true, required: true })], confirmation: '该本地会话会被永久删除，确认继续？' },
    { id: 'session-export', category: 'sessions', title: '导出 Markdown', description: '把指定会话导出为 Markdown、文件或系统剪贴板。', baseArguments: ['export'], fields: [text('sessionId', '会话 ID', { positional: true, required: true }), text('output', '输出文件', { positional: true, placeholder: '可选：绝对路径' }), bool('clipboard', '复制到系统剪贴板', '--clipboard')] },
    { id: 'session-trace', category: 'sessions', title: '导出诊断 Trace', description: '为指定会话生成本地诊断包。', baseArguments: ['trace'], fields: [text('sessionId', '会话 ID', { positional: true, required: true }), bool('local', '仅保存在本地', '--local', true), text('output', '输出文件', { flag: '--output', placeholder: '可选：.tar.gz 路径' }), bool('json', 'JSON 输出', '--json', true)], timeoutSeconds: 180 },

    { id: 'mcp-list', category: 'mcp', title: 'MCP 列表', description: '列出全局和项目作用域 MCP 服务。', baseArguments: ['mcp', 'list', '--json'] },
    { id: 'mcp-doctor', category: 'mcp', title: 'MCP 诊断', description: '诊断全部或指定 MCP 服务配置与连通性。', baseArguments: ['mcp', 'doctor'], fields: [text('name', '服务名称', { positional: true, placeholder: '留空检查全部' }), bool('json', 'JSON 输出', '--json', true)], timeoutSeconds: 180 },
    { id: 'mcp-add', category: 'mcp', title: '添加或更新 MCP', description: '配置 stdio、HTTP 或 SSE MCP 服务。', baseArguments: ['mcp', 'add'], fields: [text('name', '名称', { positional: true, required: true }), text('commandOrUrl', '命令或 URL', { positional: true, required: true }), { key: 'args', label: '命令参数', type: 'arguments', positional: true, placeholder: '支持引号，例如 -y package-name' }, { key: 'transport', label: '传输类型', type: 'select', flag: '--transport', defaultValue: 'stdio', options: [{ label: 'stdio', value: 'stdio' }, { label: 'HTTP', value: 'http' }, { label: 'SSE', value: 'sse' }] }, { key: 'scope', label: '作用域', type: 'select', flag: '--scope', defaultValue: 'user', options: [{ label: '用户', value: 'user' }, { label: '项目', value: 'project' }] }, { key: 'env', label: '环境变量', type: 'multiline', flag: '--env', repeatLines: true, placeholder: '每行 KEY=value' }, { key: 'headers', label: 'HTTP Headers', type: 'multiline', flag: '--header', repeatLines: true, placeholder: '每行 NAME: VALUE' }], confirmation: '确认写入该 MCP 服务配置？' },
    { id: 'mcp-remove', category: 'mcp', title: '移除 MCP', description: '从指定作用域或所有作用域移除 MCP 服务。', baseArguments: ['mcp', 'remove'], fields: [text('name', '名称', { positional: true, required: true }), { key: 'scope', label: '作用域', type: 'select', flag: '--scope', defaultValue: '', options: [{ label: '搜索全部作用域', value: '' }, { label: '用户', value: 'user' }, { label: '项目', value: 'project' }] }], confirmation: '确认移除该 MCP 服务？' },

    { id: 'plugin-list', category: 'plugins', title: '插件列表', description: '列出已安装插件和可选市场插件。', baseArguments: ['plugin', 'list', '--json'], fields: [bool('available', '包含市场可用插件', '--available')] },
    { id: 'plugin-install', category: 'plugins', title: '安装插件', description: '从 Git、GitHub 简写或本地目录安装插件。', baseArguments: ['plugin', 'install'], fields: [text('source', '来源', { positional: true, required: true, placeholder: 'user/repo@v1.0 或本地路径' }), bool('trust', '立即信任插件', '--trust')], confirmation: '插件可以扩展智能体工具和本地访问能力，确认安装？', timeoutSeconds: 300 },
    { id: 'plugin-uninstall', category: 'plugins', title: '卸载插件', description: '卸载指定插件。', baseArguments: ['plugin', 'uninstall'], fields: [text('name', '插件名称', { positional: true, required: true }), bool('confirm', '确认多插件仓库卸载', '--confirm'), bool('keepData', '保留插件数据', '--keep-data')], confirmation: '确认卸载该插件？' },
    { id: 'plugin-update', category: 'plugins', title: '更新插件', description: '更新指定插件；名称留空时更新全部。', baseArguments: ['plugin', 'update'], fields: [text('name', '插件名称', { positional: true, placeholder: '留空更新全部' })], timeoutSeconds: 300 },
    { id: 'plugin-enable', category: 'plugins', title: '启用插件', description: '启用已禁用的插件。', baseArguments: ['plugin', 'enable'], fields: [text('name', '插件名称', { positional: true, required: true })] },
    { id: 'plugin-disable', category: 'plugins', title: '禁用插件', description: '禁用插件但不卸载。', baseArguments: ['plugin', 'disable'], fields: [text('name', '插件名称', { positional: true, required: true })] },
    { id: 'plugin-details', category: 'plugins', title: '插件详情', description: '查看插件组件清单。', baseArguments: ['plugin', 'details'], fields: [text('name', '插件名称', { positional: true, required: true })] },
    { id: 'plugin-validate', category: 'plugins', title: '校验插件', description: '校验插件清单与目录结构。', baseArguments: ['plugin', 'validate'], fields: [text('path', '插件目录', { positional: true, placeholder: '默认当前工作区' })] },
    { id: 'plugin-tag', category: 'plugins', title: '创建插件版本标签', description: '根据插件清单版本创建 Git 标签。', baseArguments: ['plugin', 'tag'], fields: [text('path', '插件目录', { positional: true, placeholder: '默认当前工作区' }), bool('push', '推送标签', '--push'), bool('force', '强制执行', '--force'), bool('dryRun', '仅预览', '--dry-run', true)], confirmation: '关闭“仅预览”后会创建 Git 标签，确认执行？' },
    { id: 'market-list', category: 'plugins', title: '市场源列表', description: '列出插件市场源及其插件。', baseArguments: ['plugin', 'marketplace', 'list', '--json'] },
    { id: 'market-add', category: 'plugins', title: '添加市场源', description: '添加 Git、GitHub 或本地插件市场源。', baseArguments: ['plugin', 'marketplace', 'add'], fields: [text('url', '来源', { positional: true, required: true }), bool('force', '跳过连通性探测', '--force')], confirmation: '确认添加该插件市场源？' },
    { id: 'market-remove', category: 'plugins', title: '移除市场源', description: '移除市场源并卸载其插件。', baseArguments: ['plugin', 'marketplace', 'remove'], fields: [text('url', '来源', { positional: true, required: true })], confirmation: '这会移除市场源并卸载其插件，确认继续？' },
    { id: 'market-update', category: 'plugins', title: '刷新市场源', description: '刷新指定市场源；留空刷新全部。', baseArguments: ['plugin', 'marketplace', 'update'], fields: [text('name', '来源', { positional: true, placeholder: '留空刷新全部' })], timeoutSeconds: 300 },

    { id: 'memory-clear', category: 'memory', title: '清理本地记忆', description: '清理工作区、全局或全部本地记忆。', baseArguments: ['memory', 'clear'], fields: [{ key: 'scope', label: '范围', type: 'select', defaultValue: '--workspace', options: [{ label: '当前工作区', value: '--workspace' }, { label: '全局', value: '--global' }, { label: '全部', value: '--all' }] }, bool('yes', '跳过二次确认', '--yes', true)], confirmation: '记忆文件删除后无法恢复，确认清理？' },

    { id: 'worktree-list', category: 'worktrees', title: '工作树列表', description: '列出内置运行时跟踪的工作树。', baseArguments: ['worktree', 'list'], fields: [text('repo', '仓库', { flag: '--repo' }), text('type', '类型', { flag: '--type' }), bool('all', '包含全部', '--all'), bool('json', 'JSON 输出', '--json', true)] },
    { id: 'worktree-show', category: 'worktrees', title: '工作树详情', description: '查看指定工作树详情。', baseArguments: ['worktree', 'show'], fields: [text('id', 'ID 或路径', { positional: true, required: true })] },
    { id: 'worktree-remove', category: 'worktrees', title: '移除工作树', description: '移除一个或多个本地工作树。', baseArguments: ['worktree', 'rm'], fields: [{ key: 'ids', label: 'ID 列表', type: 'arguments', positional: true, required: true, placeholder: '多个 ID 以空格分隔' }, bool('force', '强制移除', '--force'), bool('dryRun', '仅预览', '--dry-run', true)], confirmation: '关闭“仅预览”后会移除工作树，确认执行？' },
    { id: 'worktree-gc', category: 'worktrees', title: '清理过期工作树', description: '垃圾回收孤立或过期工作树。', baseArguments: ['worktree', 'gc'], fields: [bool('dryRun', '仅预览', '--dry-run', true), text('maxAge', '最大年龄', { flag: '--max-age', placeholder: '例如 7d' }), bool('force', '强制清理', '--force')], confirmation: '关闭“仅预览”后会清理工作树，确认执行？' },
    { id: 'worktree-db-stats', category: 'worktrees', title: '工作树数据库统计', description: '显示工作树数据库统计信息。', baseArguments: ['worktree', 'db', 'stats'] },
    { id: 'worktree-db-path', category: 'worktrees', title: '工作树数据库路径', description: '显示工作树数据库文件位置。', baseArguments: ['worktree', 'db', 'path'] },
    { id: 'worktree-db-rebuild', category: 'worktrees', title: '重建工作树数据库', description: '扫描文件系统重建工作树索引。', baseArguments: ['worktree', 'db', 'rebuild'], confirmation: '确认重建本地工作树数据库？' },

    { id: 'leader-list', category: 'agent', title: '协调进程', description: '列出本地协调后台进程。', baseArguments: ['leader', 'list', '--json'] },
    { id: 'leader-info', category: 'agent', title: 'Leader 详情', description: '查看指定或默认 Leader 进程信息。', baseArguments: ['leader', 'info', '--json'], fields: [text('pid', '进程 PID', { flag: '--pid' })] },
    { id: 'leader-kill', category: 'agent', title: '停止协调进程', description: '停止全部本地协调进程。', baseArguments: ['leader', 'kill'], confirmation: '确认停止全部本地协调进程？' },
    { id: 'agent-stdio', category: 'agent', title: 'ACP stdio Agent', description: 'ARK Desktop 任务执行所使用的托管 ACP 进程。', baseArguments: ['agent', 'stdio'], execution: 'managed', mappedFeature: '由“新建任务”自动启动，并提供流式消息、授权和停止控制。' },
    { id: 'agent-headless', category: 'agent', title: '后台中转智能体', description: '启动 WebSocket 中转智能体。', baseArguments: ['agent', 'headless'], execution: 'service', fields: agentServiceFields },
    { id: 'agent-serve', category: 'agent', title: 'WebSocket 智能体服务', description: '启动可连接的智能体服务。', baseArguments: ['agent', 'serve'], execution: 'service', fields: [...agentServiceFields, text('bind', '监听地址', { flag: '--bind', placeholder: '127.0.0.1:0' }), text('secret', '连接密钥', { flag: '--secret' }), text('remote', '远端地址', { flag: '--remote' })] },
    { id: 'agent-leader', category: 'agent', title: '共享 Leader Agent', description: '启动供多个客户端共享的 Leader。', baseArguments: ['agent', 'leader'], execution: 'service', fields: [...agentServiceFields, bool('noExit', '断开后不退出', '--no-exit-on-disconnect'), bool('relayOnDemand', '按需 Relay', '--relay-on-demand')] },

    { id: 'help', category: 'developer', title: '命令帮助', description: '查看内置命令完整帮助。', baseArguments: ['help'] },
    { id: 'completions', category: 'developer', title: '生成补全脚本', description: '为指定 Shell 生成命令补全脚本。', baseArguments: ['completions'], fields: [{ key: 'shell', label: 'Shell', type: 'select', positional: true, required: true, defaultValue: 'zsh', options: ['bash', 'zsh', 'fish', 'powershell', 'elvish'].map((value) => ({ label: value, value })) }] },
    { id: 'dashboard', category: 'developer', title: '智能体工作台', description: '命令的全屏工作台在前台映射为当前智能任务中心。', baseArguments: ['dashboard'], execution: 'managed', mappedFeature: '当前 URGS 智能任务中心页面即图形化工作台。' },
    { id: 'tui-rendering', category: 'developer', title: '终端显示模式', description: '命令的 --fullscreen、--minimal 和 --no-alt-screen 仅控制终端渲染。', baseArguments: [], execution: 'managed', mappedFeature: 'URGS 智能任务中心使用原生图形界面呈现任务、步骤和输出，不启动终端界面，因此这三个显示参数不适用。终端默认值仍可在设置中的 pager.toml 编辑。' },
    { id: 'wrap', category: 'developer', title: '终端剪贴板包装', description: '命令 wrap 只服务于终端 PTY 的 OSC 52 剪贴板转发。', baseArguments: ['wrap'], execution: 'managed', mappedFeature: 'URGS 智能任务中心直接使用系统剪贴板；命令输出区和会话导出均提供复制功能，因此无需启动终端 PTY 包装器。' },
];

const splitArguments = (input: string) => {
    const values: string[] = [];
    let current = '';
    let quote = '';
    let escaped = false;
    for (const character of input.trim()) {
        if (escaped) {
            current += character;
            escaped = false;
        } else if (character === '\\') {
            escaped = true;
        } else if (quote) {
            if (character === quote) quote = '';
            else current += character;
        } else if (character === '"' || character === "'") {
            quote = character;
        } else if (/\s/.test(character)) {
            if (current) values.push(current);
            current = '';
        } else {
            current += character;
        }
    }
    if (escaped || quote) throw new Error('参数中的引号或转义符没有闭合');
    if (current) values.push(current);
    return values;
};

export const buildGrokCliArguments = (action: GrokCliAction, values: Record<string, string | boolean>) => {
    if (action.id === 'mcp-add') {
        const name = String(values.name || '').trim();
        const commandOrUrl = String(values.commandOrUrl || '').trim();
        if (!name) throw new Error('请填写名称');
        if (!commandOrUrl) throw new Error('请填写命令或 URL');
        const transport = String(values.transport || 'stdio');
        const result = ['mcp', 'add', '--transport', transport];
        const scope = String(values.scope || '').trim();
        if (scope) result.push('--scope', scope);
        for (const [key, flag] of [['env', '--env'], ['headers', '--header']] as const) {
            for (const line of String(values[key] || '').split('\n').map((item) => item.trim()).filter(Boolean)) result.push(flag, line);
        }
        result.push(name);
        if (transport === 'stdio') result.push('--');
        result.push(commandOrUrl, ...splitArguments(String(values.args || '')));
        return result;
    }
    const beforeSubcommand: string[] = [];
    const arguments_ = [...action.baseArguments];
    for (const field of action.fields || []) {
        const target = field.beforeSubcommand ? beforeSubcommand : arguments_;
        const value = values[field.key];
        if (field.required && (value === '' || value === false || value == null)) {
            throw new Error(`请填写${field.label}`);
        }
        if (field.type === 'boolean') {
            if (value && field.flag) target.push(field.flag);
            continue;
        }
        const normalized = String(value || '').trim();
        if (!normalized) continue;
        if (field.key === 'scope' && action.id === 'memory-clear') {
            target.push(normalized);
        } else if (field.type === 'arguments') {
            target.push(...splitArguments(normalized));
        } else if (field.repeatLines) {
            for (const line of normalized.split('\n').map((item) => item.trim()).filter(Boolean)) {
                if (field.flag) target.push(field.flag);
                target.push(line);
            }
        } else {
            if (field.flag) target.push(field.flag);
            target.push(normalized);
        }
    }
    return beforeSubcommand.length > 0
        ? [arguments_[0], ...beforeSubcommand, ...arguments_.slice(1)]
        : arguments_;
};

export const defaultGrokCliValues = (action: GrokCliAction) => Object.fromEntries(
    (action.fields || []).map((field) => [field.key, field.defaultValue ?? (field.type === 'boolean' ? false : '')]),
) as Record<string, string | boolean>;

export const parseGrokCliCommand = splitArguments;
