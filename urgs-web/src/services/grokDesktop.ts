import { isDesktopRuntime } from '@/config';

export interface GrokRuntimeStatus {
    available: boolean;
    authenticated: boolean;
    version?: string | null;
    grokHome: string;
    message?: string | null;
}

export interface GrokSession {
    sessionId: string;
    workspace: string;
    processId: string;
    availableCommands: GrokAvailableCommand[];
    modelCatalog?: GrokModelCatalog | null;
    mcpServers: GrokMcpServerState[];
    replayedEvents: Array<Record<string, any>>;
}

export interface GrokAvailableCommand {
    name: string;
    description: string;
    inputHint?: string | null;
}

export interface GrokWorkflowListing {
    name: string;
    description: string;
    whenToUse?: string | null;
    source: string;
    path?: string | null;
}

export interface GrokWorkflowFile extends GrokWorkflowListing {
    content?: string | null;
}

export interface GrokReasoningEffort {
    id: string;
    value: string;
    label: string;
    description: string;
    default: boolean;
}

export interface GrokModelOption {
    modelId: string;
    name: string;
    description: string;
    supportsReasoningEffort: boolean;
    reasoningEfforts: GrokReasoningEffort[];
    totalContextTokens?: number | null;
}

export interface GrokModelCatalog {
    currentModelId?: string | null;
    availableModels: GrokModelOption[];
    totalContextTokens?: number | null;
}

export interface GrokMcpServerState {
    name: string;
    transport: string;
    enabled: boolean;
    source: string;
    command?: string | null;
    args: string[];
    url?: string | null;
    envKeys: string[];
    headerNames: string[];
    health: string;
    tools: string[];
}

export interface GrokSessionSummary {
    sessionId: string;
    title: string;
    summary: string;
    firstPrompt?: string | null;
    updatedAt?: string | null;
    createdAt?: string | null;
    cwd: string;
    source?: string | null;
    modelId?: string | null;
    numMessages?: number;
    lastActiveAt?: string | null;
    snippet?: string | null;
    score?: number;
}

export interface GrokSessionListResponse {
    sessions: GrokSessionSummary[];
    nextCursor?: string | null;
}

export interface GrokSessionSearchResponse {
    results: GrokSessionSummary[];
    nextOffset?: number | null;
    totalEstimate?: number | null;
    bootstrapping?: boolean;
}

export interface GrokContextInfo {
    used: number;
    total: number;
    systemPromptTokens: number;
    toolDefinitionsCount: number;
    toolDefinitionsTokens: number;
    compactionCount: number;
    turnCount: number;
    toolCallCount: number;
    messageCount: number;
    messageTokens: number;
    freeTokens: number;
    usagePct: number;
    autoCompactThresholdPercent: number;
    usageCategories?: Array<Record<string, any>>;
}

export interface GrokSessionInfo {
    sessionId: string;
    cwd: string;
    agentName?: string | null;
    model?: string | null;
    modelDisplayName?: string | null;
    resolvedModelId?: string | null;
    turns: number;
    turnIndex: number;
    context: GrokContextInfo;
}

export interface GrokBackgroundTask {
    taskId: string;
    command?: string;
    displayCommand?: string | null;
    cwd?: string;
    output?: string;
    outputFile?: string;
    truncated?: boolean;
    exitCode?: number | null;
    signal?: string | null;
    completed: boolean;
    kind?: string;
}

export interface GrokRuntimeDiagnostics {
    processId: string;
    workspace: string;
    alive: boolean;
    sessionIds: string[];
    availableCommands: GrokAvailableCommand[];
    modelCatalog?: GrokModelCatalog | null;
    mcpServers: GrokMcpServerState[];
    initializeMeta: Record<string, any> | null;
    agentCapabilities: Record<string, any> | null;
    stderr: string;
}

export interface GrokAcpOptions {
    reasoningEffort?: string;
    permissionMode?: string;
    sandboxProfile?: string;
    alwaysApprove?: boolean;
    reauth?: boolean;
    agentProfile?: string;
    pluginDirs?: string[];
    leaderMode?: 'default' | 'leader' | 'standalone';
    grokWsOrigin?: string;
    grokWsUrl?: string;
    cliChatProxyUrl?: string;
    xaiApiBaseUrl?: string;
    debug?: boolean;
    debugFile?: string;
    leaderSocket?: string;
}

export interface GrokBridgeEvent {
    eventType: string;
    payload: Record<string, any>;
}

export interface GrokQueueEntry {
    id: string;
    version: number;
    owner?: string | null;
    lastEditor?: string | null;
    kind: string;
    text: string;
    position: number;
}

export interface GrokQueueChanged {
    sessionId: string;
    entries: GrokQueueEntry[];
    runningPromptId?: string | null;
}

export interface GrokCliResult {
    arguments: string[];
    success: boolean;
    exitCode?: number | null;
    stdout: string;
    stderr: string;
}

export interface GrokDiscoveredPlugin {
    id: string;
    name: string;
    version: string;
    path: string;
    source: string;
    enabled: boolean;
}

export interface GrokPluginComponents {
    skillDirectories: number;
    commandDirectories: number;
    agentDirectories: number;
    hasHooks: boolean;
    hasMcpServers: boolean;
    hasLspServers: boolean;
}

export interface GrokInstalledPlugin {
    id: string;
    name: string;
    repoKey: string;
    version: string;
    path: string;
    source: string;
    marketplace: string;
    enabled: boolean;
}

export interface GrokPluginValidation {
    name: string;
    version: string;
    description: string;
    components: GrokPluginComponents;
    output: string;
}

export interface GrokPluginDetails extends GrokPluginValidation {
    path: string;
    source: string;
}

export interface GrokMarketplaceSource {
    name: string;
    kind: string;
    url: string;
    branch?: string | null;
}

export interface GrokCliServiceInfo {
    id: string;
    arguments: string[];
    pid: number;
    alive: boolean;
    startedAt: number;
    exitCode?: number | null;
    stdout: string;
    stderr: string;
}

export interface GrokConfigFile {
    scope: 'user' | 'project';
    kind: 'config' | 'appearance';
    path: string;
    exists: boolean;
    content: string;
}

export interface GrokModelProvider {
    id: string;
    name: string;
    model: string;
    baseUrl: string;
    apiBackend: 'chat_completions' | 'responses' | 'messages';
    authScheme: 'bearer' | 'x_api_key';
    contextWindow: number;
    enabled: boolean;
    hasApiKey: boolean;
}

export interface GrokModelProviderInput extends Omit<GrokModelProvider, 'hasApiKey'> {
    apiKey?: string;
}

const assertDesktopRuntime = () => {
    if (!isDesktopRuntime()) {
        throw new Error('ARK Desktop 仅能在 URGS 桌面客户端中使用');
    }
};

const invokeGrok = async <T>(command: string, args?: Record<string, unknown>) => {
    assertDesktopRuntime();
    const { invoke } = await import('@tauri-apps/api/core');
    return invoke<T>(command, args);
};

export const getGrokRuntimeStatus = () => invokeGrok<GrokRuntimeStatus>('grok_runtime_status');

export const listGrokAvailableCommands = (workspace: string) =>
    invokeGrok<GrokAvailableCommand[]>('grok_available_commands', { workspace });

export const listGrokWorkflows = (sessionId: string) =>
    invokeGrok<GrokWorkflowListing[]>('grok_workflow_list', { sessionId });

export const readGrokWorkflow = (sessionId: string, name: string) =>
    invokeGrok<GrokWorkflowFile>('grok_workflow_read', { sessionId, name });

export const getGrokModelCatalog = (workspace: string) =>
    invokeGrok<GrokModelCatalog | null>('grok_model_catalog', { workspace });

const normalizeSessionSummary = (item: any, workspace = ''): GrokSessionSummary => ({
    sessionId: String(item?.sessionId ?? item?.session_id ?? ''),
    title: String(item?.title ?? item?.summary ?? item?.firstPrompt ?? '未命名会话'),
    summary: String(item?.summary ?? item?.title ?? item?.firstPrompt ?? ''),
    firstPrompt: item?.firstPrompt ?? item?.first_prompt ?? null,
    updatedAt: item?.updatedAt ?? item?.updated_at ?? item?.lastActiveAt ?? item?.last_active_at ?? null,
    createdAt: item?.createdAt ?? item?.created_at ?? null,
    cwd: String(item?.cwd ?? workspace),
    source: item?.source ?? null,
    modelId: item?.modelId ?? item?.model_id ?? null,
    numMessages: Number(item?.numMessages ?? item?.num_messages ?? 0),
    lastActiveAt: item?.lastActiveAt ?? item?.last_active_at ?? null,
    snippet: item?.snippet ?? null,
    score: typeof item?.score === 'number' ? item.score : undefined,
});

export const listGrokSessions = (workspace: string, query?: string, limit = 50, cursor?: string) =>
    invokeGrok<any>('grok_session_list', {
        workspace,
        query: query?.trim() || null,
        limit,
        cursor: cursor?.trim() || null,
    }).then((response) => ({
        sessions: Array.isArray(response?.sessions)
            ? response.sessions.map((item: any) => normalizeSessionSummary(item, workspace)).filter((item: GrokSessionSummary) => item.sessionId)
            : [],
        nextCursor: response?.nextCursor ?? response?.next_cursor ?? null,
    } as GrokSessionListResponse));

export const searchGrokSessions = (workspace: string, query: string, limit = 20) =>
    invokeGrok<any>('grok_session_search', { workspace, query, limit }).then((response) => ({
        results: Array.isArray(response?.results)
            ? response.results.map((item: any) => normalizeSessionSummary(item, workspace)).filter((item: GrokSessionSummary) => item.sessionId)
            : [],
        nextOffset: response?.nextOffset ?? response?.next_offset ?? null,
        totalEstimate: response?.totalEstimate ?? response?.total_estimate ?? null,
        bootstrapping: Boolean(response?.bootstrapping),
    } as GrokSessionSearchResponse));

const normalizeContextInfo = (value: any): GrokContextInfo => ({
    used: Number(value?.used ?? 0),
    total: Number(value?.total ?? 0),
    systemPromptTokens: Number(value?.systemPromptTokens ?? value?.system_prompt_tokens ?? 0),
    toolDefinitionsCount: Number(value?.toolDefinitionsCount ?? value?.tool_definitions_count ?? 0),
    toolDefinitionsTokens: Number(value?.toolDefinitionsTokens ?? value?.tool_definitions_tokens ?? 0),
    compactionCount: Number(value?.compactionCount ?? value?.compaction_count ?? 0),
    turnCount: Number(value?.turnCount ?? value?.turn_count ?? 0),
    toolCallCount: Number(value?.toolCallCount ?? value?.tool_call_count ?? 0),
    messageCount: Number(value?.messageCount ?? value?.message_count ?? 0),
    messageTokens: Number(value?.messageTokens ?? value?.message_tokens ?? 0),
    freeTokens: Number(value?.freeTokens ?? value?.free_tokens ?? 0),
    usagePct: Number(value?.usagePct ?? value?.usage_pct ?? 0),
    autoCompactThresholdPercent: Number(value?.autoCompactThresholdPercent ?? value?.auto_compact_threshold_percent ?? 85),
    usageCategories: Array.isArray(value?.usageCategories ?? value?.usage_categories)
        ? (value?.usageCategories ?? value?.usage_categories)
        : [],
});

export const getGrokSessionInfo = (sessionId: string) =>
    invokeGrok<any>('grok_session_info', { sessionId }).then((value) => ({
        sessionId: String(value?.sessionId ?? value?.session_id ?? sessionId),
        cwd: String(value?.cwd ?? ''),
        agentName: value?.agentName ?? value?.agent_name ?? null,
        model: value?.model ?? null,
        modelDisplayName: value?.modelDisplayName ?? value?.model_display_name ?? null,
        resolvedModelId: value?.resolvedModelId ?? value?.resolved_model_id ?? null,
        turns: Number(value?.turns ?? 0),
        turnIndex: Number(value?.turnIndex ?? value?.turn_index ?? 0),
        context: normalizeContextInfo(value?.context),
    } as GrokSessionInfo));

export const compactGrokSession = (sessionId: string, userContext?: string) =>
    invokeGrok<Record<string, any>>('grok_compact_session', { sessionId, userContext: userContext?.trim() || null });

export const recapGrokSession = (sessionId: string) =>
    invokeGrok<Record<string, any>>('grok_recap_session', { sessionId });

export const renameGrokSession = (sessionId: string, title: string, workspace?: string) =>
    invokeGrok<Record<string, any>>('grok_session_rename', { sessionId, title, workspace: workspace || null });

export const deleteGrokSession = (sessionId: string, workspace?: string) =>
    invokeGrok<Record<string, any>>('grok_session_delete', { sessionId, workspace: workspace || null });

const normalizeBackgroundTask = (item: any): GrokBackgroundTask => ({
    taskId: String(item?.taskId ?? item?.task_id ?? ''),
    command: item?.command,
    displayCommand: item?.displayCommand ?? item?.display_command ?? null,
    cwd: item?.cwd,
    output: item?.output,
    outputFile: item?.outputFile ?? item?.output_file,
    truncated: Boolean(item?.truncated),
    exitCode: item?.exitCode ?? item?.exit_code ?? null,
    signal: item?.signal ?? null,
    completed: Boolean(item?.completed),
    kind: item?.kind,
});

export const listGrokBackgroundTasks = (sessionId: string) =>
    invokeGrok<any>('grok_list_background_tasks', { sessionId }).then((value) =>
        (Array.isArray(value?.tasks) ? value.tasks : []).map(normalizeBackgroundTask));

export const killGrokBackgroundTask = (sessionId: string, taskId: string) =>
    invokeGrok<Record<string, any>>('grok_kill_background_task', { sessionId, taskId });

export const getGrokSubagent = (subagentId: string) =>
    invokeGrok<Record<string, any>>('grok_get_subagent', { subagentId });

export const cancelGrokSubagent = (subagentId: string) =>
    invokeGrok<Record<string, any>>('grok_cancel_subagent', { subagentId });

export const listGrokMcpServers = (workspace: string) =>
    invokeGrok<GrokMcpServerState[]>('grok_mcp_list', { workspace });

export const setGrokMcpEnabled = (name: string, enabled: boolean, workspace?: string) =>
    invokeGrok<GrokMcpServerState[]>('grok_mcp_set_enabled', { name, enabled, workspace: workspace || null });

export const reloadGrokMcpServers = (workspace: string) =>
    invokeGrok<Record<string, any>>('grok_reload_mcp_servers', { workspace });

export const updateGrokSessionMcpServers = (sessionId: string, mcpServers: Array<Record<string, any>>) =>
    invokeGrok<Record<string, any>>('grok_session_update_mcp_servers', { sessionId, mcpServers });

export const flushGrokMemory = (sessionId: string) =>
    invokeGrok<Record<string, any>>('grok_memory_flush', { sessionId });

export const getGrokRuntimeDiagnostics = () =>
    invokeGrok<GrokRuntimeDiagnostics[]>('grok_runtime_diagnostics');

export const prepareGrokRuntime = (workspace: string, model: string, options?: GrokAcpOptions, rules?: string) =>
    invokeGrok<void>('grok_runtime_prepare', { workspace, model, options: options || null, rules: rules || null });

export const invalidatePreparedGrokRuntime = () => invokeGrok<void>('grok_runtime_invalidate_prepared');
export const releaseGrokSession = (sessionId: string) =>
    invokeGrok<void>('grok_release_session', { sessionId });

export const runGrokCli = (arguments_: string[], workspace?: string, timeoutSeconds = 120) =>
    invokeGrok<GrokCliResult>('grok_cli_run', {
        arguments: arguments_,
        workspace: workspace || null,
        timeoutSeconds,
    });

export const openGrokWorkspace = async (workspace: string) => {
    assertDesktopRuntime();
    const { openPath } = await import('@tauri-apps/plugin-opener');
    await openPath(workspace);
};

const parseGrokPluginState = (content: string) => {
    const section = content.match(/(?:^|\n)\[plugins\]\s*\n([\s\S]*?)(?=\n\[|$)/)?.[1] || '';
    const readList = (key: string) => {
        const body = section.match(new RegExp(`^\\s*${key}\\s*=\\s*\\[([\\s\\S]*?)\\]`, 'm'))?.[1] || '';
        return new Set(Array.from(body.matchAll(/["']([^"']+)["']/g), (match) => match[1].trim()).filter(Boolean));
    };
    return { enabled: readList('enabled'), disabled: readList('disabled') };
};

const readGrokPluginState = async (workspace?: string) => {
    const config = await invokeGrok<GrokConfigFile>('grok_config_read', {
        scope: 'user',
        kind: 'config',
        workspace: workspace || null,
    });
    return parseGrokPluginState(config.content);
};

export const inspectGrokPlugins = async (workspace?: string): Promise<GrokDiscoveredPlugin[]> => {
    const [result, pluginState] = await Promise.all([
        runGrokCli(['inspect', '--json'], workspace, 30),
        readGrokPluginState(workspace).catch(() => ({ enabled: new Set<string>(), disabled: new Set<string>() })),
    ]);
    if (!result.success) throw new Error(result.stderr.trim() || '无法读取 Grok 插件');
    const payload = JSON.parse(result.stdout) as { plugins?: unknown };
    if (!Array.isArray(payload.plugins)) return [];
    return payload.plugins.flatMap((item) => {
        if (!item || typeof item !== 'object') return [];
        const plugin = item as Record<string, unknown>;
        const id = typeof plugin.id === 'string' ? plugin.id.trim() : '';
        const name = typeof plugin.name === 'string' ? plugin.name.trim() : '';
        if (!id && !name) return [];
        const identifiers = [id, name].filter(Boolean);
        const explicitlyDisabled = identifiers.some((identifier) => pluginState.disabled.has(identifier));
        const explicitlyEnabled = identifiers.some((identifier) => pluginState.enabled.has(identifier));
        return [{
            id: id || name,
            name: name || id,
            version: typeof plugin.version === 'string' ? plugin.version.trim() : '',
            path: typeof plugin.path === 'string' ? plugin.path.trim() : '',
            source: typeof plugin.source === 'string' ? plugin.source.trim() : '',
            enabled: explicitlyDisabled
                ? false
                : explicitlyEnabled || plugin.enabled === true,
        }];
    });
};

const emptyPluginComponents = (): GrokPluginComponents => ({
    skillDirectories: 0,
    commandDirectories: 0,
    agentDirectories: 0,
    hasHooks: false,
    hasMcpServers: false,
    hasLspServers: false,
});

const parsePluginComponents = (output: string): GrokPluginComponents => {
    const match = output.match(/components:\s*(\d+) skill dir\(s\),\s*(\d+) command dir\(s\),\s*(\d+) agent dir\(s\)([^\n]*)/i);
    if (!match) return emptyPluginComponents();
    const suffix = match[4].toLowerCase();
    return {
        skillDirectories: Number(match[1]),
        commandDirectories: Number(match[2]),
        agentDirectories: Number(match[3]),
        hasHooks: suffix.includes('hooks'),
        hasMcpServers: suffix.includes('mcp servers'),
        hasLspServers: suffix.includes('lsp servers'),
    };
};

const pluginOutputValue = (output: string, key: string) => {
    const match = output.match(new RegExp(`^\\s*${key}:\\s*(.+)$`, 'im'));
    return match?.[1]?.trim() || '';
};

const assertSuccessfulPluginCommand = (result: GrokCliResult, fallback: string) => {
    if (!result.success) throw new Error(result.stderr.trim() || result.stdout.trim() || fallback);
    return result;
};

const assertLocalPluginPath = (path: string) => {
    const normalized = path.trim();
    const absolute = normalized.startsWith('/') || /^[A-Za-z]:[\\/]/.test(normalized);
    if (!absolute || normalized.includes('\0') || normalized.includes('://')) {
        throw new Error('插件来源必须是通过目录选择器选取的本地绝对路径');
    }
    return normalized;
};

const assertPluginName = (name: string) => {
    const normalized = name.trim();
    if (normalized.length > 128 || !/^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/.test(normalized)) {
        throw new Error('插件名称不合法');
    }
    return normalized;
};

const assertMarketplaceSource = (source: string) => {
    const normalized = source.trim();
    if (!normalized || normalized.length > 512 || normalized.includes('\0') || normalized.startsWith('-')) {
        throw new Error('插件市场源不能为空、不能超过 512 个字符，也不能以短横线开头');
    }
    return normalized;
};

export const listGrokInstalledPlugins = async (workspace?: string): Promise<GrokInstalledPlugin[]> => {
    const [listResult, discovered] = await Promise.all([
        runGrokCli(['plugin', 'list', '--json'], workspace, 30),
        inspectGrokPlugins(workspace).catch(() => []),
    ]);
    assertSuccessfulPluginCommand(listResult, '无法读取已安装插件');
    const payload = JSON.parse(listResult.stdout) as unknown;
    if (!Array.isArray(payload)) return [];
    return payload.flatMap((item) => {
        if (!item || typeof item !== 'object') return [];
        const plugin = item as Record<string, unknown>;
        if (plugin.status !== 'installed' || typeof plugin.name !== 'string') return [];
        const name = plugin.name.trim();
        if (!name) return [];
        const inspected = discovered.find((candidate) => candidate.name === name);
        const repoKey = typeof plugin.repo_key === 'string' ? plugin.repo_key.trim() : '';
        return [{
            id: `${repoKey || 'local'}:${name}`,
            name,
            repoKey,
            version: typeof plugin.version === 'string' ? plugin.version.trim() : '',
            path: typeof plugin.path === 'string' ? plugin.path.trim() : inspected?.path || '',
            source: typeof plugin.source === 'string' ? plugin.source.trim() : inspected?.source || '',
            marketplace: typeof plugin.marketplace === 'string' ? plugin.marketplace.trim() : '',
            enabled: inspected?.enabled === true,
        }];
    });
};

export const validateGrokPluginDirectory = async (path: string, workspace?: string): Promise<GrokPluginValidation> => {
    const localPath = assertLocalPluginPath(path);
    const result = assertSuccessfulPluginCommand(
        await runGrokCli(['plugin', 'validate', localPath], workspace, 30),
        '插件校验失败',
    );
    return {
        name: pluginOutputValue(result.stdout, 'name') || localPath.split(/[\\/]/).filter(Boolean).pop() || '本地插件',
        version: pluginOutputValue(result.stdout, 'version'),
        description: pluginOutputValue(result.stdout, 'description'),
        components: parsePluginComponents(result.stdout),
        output: result.stdout,
    };
};

export const installTrustedLocalGrokPlugin = async (path: string, workspace?: string) => {
    const localPath = assertLocalPluginPath(path);
    return assertSuccessfulPluginCommand(
        await runGrokCli(['plugin', 'install', localPath, '--trust'], workspace, 120),
        '插件安装失败',
    );
};

export const uninstallGrokPlugin = async (name: string, workspace?: string) => {
    const pluginName = assertPluginName(name);
    return assertSuccessfulPluginCommand(
        await runGrokCli(['plugin', 'uninstall', pluginName, '--confirm'], workspace, 120),
        '插件卸载失败',
    );
};

export const updateGrokPlugin = async (name?: string, workspace?: string) => {
    const arguments_ = ['plugin', 'update'];
    if (name?.trim()) arguments_.push(assertPluginName(name));
    return assertSuccessfulPluginCommand(
        await runGrokCli(arguments_, workspace, 300),
        '插件更新失败',
    );
};

export const listGrokPluginMarketplace = async (workspace?: string) => {
    const result = assertSuccessfulPluginCommand(
        await runGrokCli(['plugin', 'list', '--available', '--json'], workspace, 120),
        '无法读取可用市场插件',
    );
    try {
        return JSON.parse(result.stdout) as unknown;
    } catch {
        throw new Error('可用市场插件返回了无法解析的数据');
    }
};

export const listGrokMarketplaceSources = async (workspace?: string): Promise<GrokMarketplaceSource[]> => {
    const result = assertSuccessfulPluginCommand(
        await runGrokCli(['plugin', 'marketplace', 'list', '--json'], workspace, 60),
        '无法读取插件市场源',
    );
    let payload: unknown;
    try {
        payload = JSON.parse(result.stdout);
    } catch {
        throw new Error('插件市场源返回了无法解析的数据');
    }
    if (!Array.isArray(payload)) return [];
    return payload.flatMap((item) => {
        if (!item || typeof item !== 'object') return [];
        const value = item as Record<string, any>;
        const source = value.source && typeof value.source === 'object' ? value.source : {};
        const url = String(source.url || value.url || value.path || '').trim();
        const name = String(value.name || url || '').trim();
        if (!name || !url) return [];
        return [{
            name,
            kind: String(value.kind || 'source').trim(),
            url,
            branch: typeof source.branch === 'string' ? source.branch : typeof value.branch === 'string' ? value.branch : null,
        }];
    });
};

export const addGrokMarketplaceSource = async (source: string, workspace?: string, force = false) => {
    const arguments_ = ['plugin', 'marketplace', 'add', assertMarketplaceSource(source)];
    if (force) arguments_.push('--force');
    return assertSuccessfulPluginCommand(
        await runGrokCli(arguments_, workspace, 300),
        '插件市场源添加失败',
    );
};

export const removeGrokMarketplaceSource = async (source: string, workspace?: string) => assertSuccessfulPluginCommand(
    await runGrokCli(['plugin', 'marketplace', 'remove', assertMarketplaceSource(source)], workspace, 300),
    '插件市场源移除失败',
);

export const updateGrokMarketplaceSource = async (source?: string, workspace?: string) => {
    const arguments_ = ['plugin', 'marketplace', 'update'];
    if (source?.trim()) arguments_.push(assertMarketplaceSource(source));
    return assertSuccessfulPluginCommand(
        await runGrokCli(arguments_, workspace, 300),
        '插件市场源刷新失败',
    );
};

export const installGrokMarketplacePlugin = async (name: string, workspace?: string) => {
    const pluginName = assertPluginName(name);
    return assertSuccessfulPluginCommand(
        await runGrokCli(['plugin', 'install', pluginName, '--trust'], workspace, 300),
        '市场插件安装失败',
    );
};

export const setGrokPluginEnabled = async (name: string, enabled: boolean, workspace?: string) => {
    const pluginName = assertPluginName(name);
    return assertSuccessfulPluginCommand(
        await runGrokCli(['plugin', enabled ? 'enable' : 'disable', pluginName], workspace, 30),
        enabled ? '插件启用失败' : '插件禁用失败',
    );
};

export const getGrokPluginDetails = async (plugin: GrokInstalledPlugin, workspace?: string): Promise<GrokPluginDetails> => {
    const result = assertSuccessfulPluginCommand(
        await runGrokCli(['plugin', 'details', assertPluginName(plugin.name)], workspace, 30),
        '无法读取插件详情',
    );
    return {
        name: plugin.name,
        version: plugin.version,
        description: pluginOutputValue(result.stdout, 'description'),
        components: parsePluginComponents(result.stdout),
        path: pluginOutputValue(result.stdout, 'path') || plugin.path,
        source: pluginOutputValue(result.stdout, 'kind') || plugin.source,
        output: result.stdout,
    };
};

export const startGrokCliService = (arguments_: string[], workspace?: string) =>
    invokeGrok<GrokCliServiceInfo>('grok_cli_service_start', { arguments: arguments_, workspace: workspace || null });

export const listGrokCliServices = () => invokeGrok<GrokCliServiceInfo[]>('grok_cli_service_list');

export const stopGrokCliService = (serviceId: string) => invokeGrok<void>('grok_cli_service_stop', { serviceId });

export const readGrokConfig = (scope: 'user' | 'project', workspace?: string, kind: 'config' | 'appearance' = 'config') =>
    invokeGrok<GrokConfigFile>('grok_config_read', { scope, kind, workspace: workspace || null });

export const saveGrokConfig = (scope: 'user' | 'project', content: string, workspace?: string, kind: 'config' | 'appearance' = 'config') =>
    invokeGrok<GrokConfigFile>('grok_config_save', { scope, kind, content, workspace: workspace || null });

export const applyGrokModel = (model: string) => invokeGrok<void>('grok_model_apply', { model });

export const listGrokModelProviders = () => invokeGrok<GrokModelProvider[]>('grok_model_provider_list');

export const authorizeGrokModelProvider = (providerId: string) =>
    invokeGrok<GrokModelProvider>('grok_model_provider_authorize', { providerId });

export const saveGrokModelProvider = (input: GrokModelProviderInput) =>
    invokeGrok<GrokModelProvider>('grok_model_provider_save', { input });

export const deleteGrokModelProvider = (providerId: string) =>
    invokeGrok<void>('grok_model_provider_delete', { providerId });

export const createGrokSession = (workspace: string, rules?: string, model?: string, options?: GrokAcpOptions) =>
    invokeGrok<GrokSession>('grok_create_session', { workspace, rules: rules || null, model: model || null, options: options || null });

export const loadGrokSession = (sessionId: string, workspace: string, rules?: string, model?: string, options?: GrokAcpOptions) =>
    invokeGrok<GrokSession>('grok_load_session', { sessionId, workspace, rules: rules || null, model: model || null, options: options || null });

export const sendGrokPrompt = (
    sessionId: string,
    prompt: string,
    attachments: string[] = [],
    attachmentGrants: string[] = [],
    queued = false,
) =>
    invokeGrok<void>('grok_send_prompt', {
        sessionId,
        prompt,
        attachments: attachments.length > 0 ? attachments : null,
        attachmentGrants: attachmentGrants.length > 0 ? attachmentGrants : null,
        queued,
    });

export const applyGrokQueueAction = (
    sessionId: string,
    action: 'remove' | 'edit' | 'reorder' | 'clear' | 'send_now' | 'interject',
    options: { id?: string; expectedVersion?: number; newText?: string; orderedIds?: string[] } = {},
) =>
    invokeGrok<void>('grok_queue_action', {
        sessionId,
        action,
        id: options.id || null,
        expectedVersion: options.expectedVersion ?? null,
        newText: options.newText || null,
        orderedIds: options.orderedIds || null,
    });

export interface GrokPromptAttachmentSelection {
    paths: string[];
    grantId?: string;
}

export const setGrokSessionModel = (sessionId: string, model: string) =>
    invokeGrok<void>('grok_session_set_model', { sessionId, model });

export interface GrokRewindPoint {
    promptIndex: number;
    createdAt?: string;
    numFileSnapshots?: number;
    promptPreview?: string;
    hasFileChanges: boolean;
}

export interface GrokRewindPointsResponse {
    rewindPoints: GrokRewindPoint[];
}

export interface GrokRewindConflict {
    path: string;
    conflictType: string;
}

export interface GrokRewindResponse {
    success: boolean;
    targetPromptIndex: number;
    revertedFiles: string[];
    cleanFiles: string[];
    conflicts: GrokRewindConflict[];
    error?: string;
    mode?: string;
}

export const listGrokRewindPoints = (sessionId: string) =>
    invokeGrok<any>('grok_rewind_points', { sessionId }).then((response) => ({
        rewindPoints: (response.rewindPoints || response.rewind_points || []).map((point: any) => ({
            promptIndex: point.promptIndex ?? point.prompt_index,
            createdAt: point.createdAt ?? point.created_at,
            numFileSnapshots: point.numFileSnapshots ?? point.num_file_snapshots,
            promptPreview: point.promptPreview ?? point.prompt_preview,
            hasFileChanges: point.hasFileChanges ?? point.has_file_changes ?? false,
        })),
    }));

export const rewindGrokFiles = (
    sessionId: string,
    targetPromptIndex: number,
    workspace: string,
    model: string,
    rules?: string,
    options?: GrokAcpOptions,
    force = false,
) =>
    invokeGrok<any>('grok_rewind_files', {
        sessionId,
        targetPromptIndex,
        workspace,
        model,
        rules: rules || null,
        options: options || null,
        force,
    }).then((response) => ({
        success: Boolean(response.success),
        targetPromptIndex: response.targetPromptIndex ?? response.target_prompt_index,
        revertedFiles: response.revertedFiles ?? response.reverted_files ?? [],
        cleanFiles: response.cleanFiles ?? response.clean_files ?? [],
        conflicts: (response.conflicts || []).map((conflict: any) => ({
            path: conflict.path,
            conflictType: conflict.conflictType ?? conflict.conflict_type,
        })),
        error: response.error,
        mode: response.mode,
    } as GrokRewindResponse));

export const deleteGrokScheduledTask = (sessionId: string, taskId: string) =>
    invokeGrok<boolean>('grok_scheduled_task_delete', { sessionId, taskId });

export const cancelGrokPrompt = (sessionId: string) => invokeGrok<void>('grok_cancel', { sessionId });

export const respondGrokPermission = (sessionId: string, requestId: unknown, optionId?: string) =>
    invokeGrok<void>('grok_respond_permission', { sessionId, requestId, optionId: optionId || null });

export const respondGrokUserQuestion = (sessionId: string, requestId: unknown, response: Record<string, unknown>) =>
    invokeGrok<void>('grok_respond_user_question', { sessionId, requestId, response });

export const respondGrokPlanApproval = (sessionId: string, requestId: unknown, response: Record<string, unknown>) =>
    invokeGrok<void>('grok_respond_plan_approval', { sessionId, requestId, response });

export const startGrokLogin = (method: 'browser' | 'oauth' | 'device' = 'browser') =>
    invokeGrok<void>('grok_start_login', { method });

export const shutdownGrok = () => invokeGrok<void>('grok_shutdown');

export const chooseGrokWorkspace = async () => {
    assertDesktopRuntime();
    const { open } = await import('@tauri-apps/plugin-dialog');
    const selected = await open({
        directory: true,
        multiple: false,
        title: '选择本地工作区',
    });
    return typeof selected === 'string' ? selected : null;
};

export const chooseGrokPluginDirectory = async () => {
    assertDesktopRuntime();
    const { open } = await import('@tauri-apps/plugin-dialog');
    const selected = await open({
        directory: true,
        multiple: false,
        title: '选择本地插件目录',
    });
    return typeof selected === 'string' ? selected : null;
};

export const chooseGrokAttachments = async () => {
    assertDesktopRuntime();
    return invokeGrok<GrokPromptAttachmentSelection>('grok_pick_prompt_attachments');
};

export const subscribeGrokEvents = async (listener: (event: GrokBridgeEvent) => void) => {
    assertDesktopRuntime();
    const { listen } = await import('@tauri-apps/api/event');
    return listen<GrokBridgeEvent>('grok-event', (event) => listener(event.payload));
};
