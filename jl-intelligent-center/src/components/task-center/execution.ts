import type { GrokExecutionSettings } from './types';

const appendLines = (arguments_: string[], flag: string, value: string) => {
    for (const line of value.split('\n').map((item) => item.trim()).filter(Boolean)) {
        arguments_.push(flag, line);
    }
};

const appendValue = (arguments_: string[], flag: string, value?: string | number) => {
    if (value !== '' && value != null && value !== 0) arguments_.push(flag, String(value));
};

export const buildGrokHeadlessArguments = (
    settings: GrokExecutionSettings,
    model: string,
    prompt: string,
    sessionRules: string,
) => {
    const arguments_: string[] = [];
    appendValue(arguments_, '--model', model);
    appendValue(arguments_, '--reasoning-effort', settings.reasoningEffort);
    appendValue(arguments_, '--permission-mode', settings.permissionMode);
    appendValue(arguments_, '--sandbox', settings.sandboxProfile);
    appendValue(arguments_, '--max-turns', settings.maxTurns);
    appendValue(arguments_, '--agent', settings.agentName);
    appendValue(arguments_, '--agents', settings.inlineAgentsJson);
    appendLines(arguments_, '--allow', settings.allowRules);
    appendLines(arguments_, '--deny', settings.denyRules);
    appendValue(arguments_, '--tools', settings.allowedTools);
    appendValue(arguments_, '--disallowed-tools', settings.disallowedTools);
    appendValue(arguments_, '--rules', [sessionRules, settings.additionalRules].filter(Boolean).join('\n\n'));
    appendValue(arguments_, '--system-prompt-override', settings.systemPromptOverride);
    appendValue(arguments_, '--json-schema', settings.jsonSchema);
    appendValue(arguments_, '--output-format', settings.outputFormat);
    appendValue(arguments_, '--debug-file', settings.debugFile);
    appendValue(arguments_, '--leader-socket', settings.leaderSocket);
    if (settings.noPlan) arguments_.push('--no-plan');
    if (settings.noSubagents) arguments_.push('--no-subagents');
    if (settings.disableWebSearch) arguments_.push('--disable-web-search');
    if (settings.memoryMode === 'disabled') arguments_.push('--no-memory');
    if (settings.memoryMode === 'experimental') arguments_.push('--experimental-memory');
    if (settings.verbatim) arguments_.push('--verbatim');
    if (settings.permissionMode === 'bypassPermissions') arguments_.push('--always-approve');
    if (settings.debug) arguments_.push('--debug');

    if (settings.sessionMode === 'continue') arguments_.push('--continue');
    if (settings.sessionMode === 'resume') {
        arguments_.push('--resume');
        if (settings.resumeSessionId.trim()) arguments_.push(settings.resumeSessionId.trim());
    }
    if (settings.forkSession) arguments_.push('--fork-session');
    if (settings.restoreCode) arguments_.push('--restore-code');
    appendValue(arguments_, '--session-id', settings.newSessionId);
    if (settings.useWorktree) {
        arguments_.push('--worktree');
        if (settings.worktreeName.trim()) arguments_.push(settings.worktreeName.trim());
        appendValue(arguments_, '--worktree-ref', settings.worktreeRef);
    }

    if (settings.promptMode === 'file') {
        if (!settings.promptFile.trim()) throw new Error('请选择或填写 Prompt 文件路径');
        arguments_.push('--prompt-file', settings.promptFile.trim());
    } else if (settings.promptMode === 'json') {
        if (!settings.promptJson.trim()) throw new Error('请填写 Prompt JSON 内容块');
        arguments_.push('--prompt-json', settings.promptJson.trim());
    } else {
        arguments_.push('--single', prompt);
    }
    return arguments_;
};

export const extractGrokHeadlessText = (stdout: string, outputFormat: GrokExecutionSettings['outputFormat']) => {
    if (outputFormat === 'plain') return stdout.trim();
    if (outputFormat === 'json') {
        try {
            const parsed = JSON.parse(stdout);
            return parsed.text || parsed.message || JSON.stringify(parsed, null, 2);
        } catch {
            return stdout.trim();
        }
    }
    const lines = stdout.split('\n').map((line) => line.trim()).filter(Boolean);
    const texts: string[] = [];
    for (const line of lines) {
        try {
            const parsed = JSON.parse(line);
            const text = parsed.type === 'text' ? parsed.data : parsed.text || parsed.delta || parsed.message?.content || parsed.content?.text;
            if (text) texts.push(String(text));
        } catch {
            texts.push(line);
        }
    }
    return texts.join('').trim() || stdout.trim();
};

export const extractGrokHeadlessSessionId = (stdout: string, outputFormat: GrokExecutionSettings['outputFormat']) => {
    if (outputFormat === 'plain') return undefined;
    if (outputFormat === 'json') {
        try {
            return JSON.parse(stdout).sessionId as string | undefined;
        } catch {
            return undefined;
        }
    }
    for (const line of stdout.split('\n').reverse()) {
        try {
            const sessionId = JSON.parse(line).sessionId;
            if (typeof sessionId === 'string' && sessionId) return sessionId;
        } catch {
            // Streaming output can contain non-JSON diagnostic lines.
        }
    }
    return undefined;
};
