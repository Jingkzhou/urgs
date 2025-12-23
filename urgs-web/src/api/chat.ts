import { v4 as uuidv4 } from 'uuid';
import { request, post, get, del } from '../utils/request';

export interface Message {
    id: string;
    role: 'user' | 'assistant';
    content: string;
    timestamp: number;
    sources?: Array<{ fileName: string; content: string; score: number }>;
}

export interface Session {
    id: string;
    title: string;
    messages: Message[];
    updatedAt: number;
    agentId?: number;
}

const API_BASE = '/api/ai';

// Helper to get current user from token or fall back
const getUserInfo = () => {
    try {
        const userStr = localStorage.getItem('user_info');
        if (userStr) {
            return JSON.parse(userStr);
        }
    } catch (e) { }
    return { id: '1' };
};

export const getSessions = async (): Promise<Session[]> => {
    try {
        const user = getUserInfo();
        const sessions = await get<any[]>(`${API_BASE}/chat/session`, {
            userId: user.id,
            _t: Date.now().toString()
        });
        if (!sessions) return [];
        return sessions.map((s: any) => ({
            id: s.id,
            title: s.title,
            messages: [],
            updatedAt: new Date(s.updateTime).getTime(),
            agentId: s.agentId
        }));
    } catch (e) {
        console.error('Failed to fetch sessions', e);
        return [];
    }
};

export const loadSessionMessages = async (sessionId: string): Promise<Message[]> => {
    try {
        const msgs = await get<any[]>(`${API_BASE}/chat/session/${sessionId}/messages`);
        if (!msgs) return [];
        return msgs.map((m: any) => ({
            id: m.id,
            role: m.role,
            content: m.content,
            timestamp: new Date(m.createTime).getTime()
        }));
    } catch (e) {
        console.error('Failed to fetch messages', e);
        return [];
    }
}

export const createSession = async (agentId?: number): Promise<Session> => {
    try {
        const user = getUserInfo();
        const payload: any = { userId: user.id, title: 'New Chat' };
        if (agentId) {
            payload.agentId = agentId;
        }
        const s = await post<any>(`${API_BASE}/chat/session`, payload);
        if (!s) throw new Error("Empty response");
        return {
            id: s.id,
            title: s.title,
            messages: [],
            updatedAt: Date.now(),
            agentId: s.agentId
        };
    } catch (e) {
        console.error("Create session failed", e);
        return { id: uuidv4(), title: 'Error Session', messages: [], updatedAt: Date.now() };
    }
};

export const deleteSession = async (id: string) => {
    const user = getUserInfo();
    await del(`${API_BASE}/chat/session/${id}`, { userId: user.id });
};

export const saveSession = (session: Session) => {
    // Optional
};

export const generateSessionTitle = async (sessionId: string): Promise<string> => {
    try {
        const response = await post<string>(`${API_BASE}/chat/session/${sessionId}/generate-title`, {});
        return response || 'New Chat';
    } catch (e) {
        console.error("Failed to generate title", e);
        return 'New Chat';
    }
};

export const updateSession = async (id: string, title: string) => {
    try {
        await request(`${API_BASE}/chat/session/${id}`, {
            method: 'PUT',
            body: JSON.stringify({ title })
        });
    } catch (e) {
        console.error("Failed to update session", e);
    }
};

export const getAgents = async (): Promise<any[]> => {
    try {
        const data = await get<any[]>('/api/ai/agent/list');
        if (!data) return [];
        return data.map(agent => ({
            ...agent,
            prompts: typeof agent.prompts === 'string' ? JSON.parse(agent.prompts) : agent.prompts
        }));
    } catch (e) {
        console.error('Failed to fetch agents', e);
        return [];
    }
};

export const getRoleAgents = async (roleId: number): Promise<number[]> => {
    try {
        const data = await get<number[]>(`/api/ai/agent/role/${roleId}`);
        return data || [];
    } catch (e) {
        console.error('Failed to fetch role agents', e);
        return [];
    }
};

export const updateRoleAgents = async (roleId: number, agentIds: number[]): Promise<void> => {
    try {
        await post(`/api/ai/agent/role/${roleId}`, { agentIds });
    } catch (e) {
        console.error('Failed to update role agents', e);
        throw e;
    }
};

export const streamChatResponse = async (
    userMessage: string,
    onChunk: (chunk: string) => void,
    onComplete: () => void,
    signal?: AbortSignal,
    sessionId?: string,
    onMetrics?: (metrics: { used: number, limit: number }) => void,
    onSources?: (sources: any[]) => void
) => {
    try {
        const token = localStorage.getItem('auth_token');
        const headers: HeadersInit = {
            'Content-Type': 'application/json',
        };
        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        const response = await fetch(`${API_BASE}/chat/stream`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                userPrompt: userMessage,
                sessionId: sessionId
            }),
            signal
        });

        let hasCompleted = false;
        const safeOnComplete = () => {
            if (!hasCompleted) {
                hasCompleted = true;
                onComplete();
            }
        };

        if (!response.ok) {
            throw new Error('Network response was not ok: ' + response.statusText);
        }

        const reader = response.body?.getReader();
        const decoder = new TextDecoder();
        let buffer = '';

        if (reader) {
            while (true) {
                const { done, value } = await reader.read();
                if (done) {
                    if (buffer.trim()) {
                        processLines(buffer, onChunk, safeOnComplete, onMetrics, undefined, onSources);
                    }
                    safeOnComplete();
                    break;
                }

                const chunk = decoder.decode(value, { stream: true });
                buffer += chunk;

                const lines = buffer.split('\n');
                buffer = lines.pop() || '';

                for (const line of lines) {
                    processLine(line, onChunk, safeOnComplete, onMetrics, undefined, onSources);
                }
            }
        }
    } catch (error: any) {
        if (error.name === 'AbortError') {
            console.log('Request aborted');
        } else {
            console.error('Stream error:', error);
        }
    }
};

const processLines = (text: string, onChunk: (c: string) => void, onComplete: () => void, onMetrics?: (m: any) => void, onStatus?: (s: string) => void, onSources?: (s: any[]) => void) => {
    const lines = text.split('\n');
    for (const line of lines) {
        processLine(line, onChunk, onComplete, onMetrics, onStatus, onSources);
    }
};

const processLine = (line: string, onChunk: (c: string) => void, onComplete: () => void, onMetrics?: (m: any) => void, onStatus?: (s: string) => void, onSources?: (s: any[]) => void) => {
    if (!line.trim()) return;

    // Handle SSE event type
    if (line.startsWith('event:')) {
        const eventType = line.slice(6).trim();
        if (eventType === 'done') {
            onComplete();
        }
        return;
    }

    let data = '';
    if (line.startsWith('data:')) {
        data = line.slice(5).trim();
    } else if (line.trim().startsWith('{')) {
        data = line.trim();
    }

    if (!data) return;

    if (data === '[DONE]') {
        onComplete();
        return;
    }

    if (data === 'compressing') {
        if (onStatus) onStatus('compressing');
        return;
    }

    try {
        const parsed = JSON.parse(data);
        if (parsed.status === 'compressing') {
            if (onStatus) onStatus('compressing');
        } else if (parsed.content) {
            onChunk(parsed.content);
        } else if (parsed.used !== undefined && parsed.limit !== undefined) {
            // Handle metrics
            if (onMetrics) onMetrics(parsed);
        } else if (Array.isArray(parsed)) {
            // Handle sources
            if (onSources) onSources(parsed);
        } else if (parsed.error) {
            console.error("Stream reported error:", parsed.error);
        }
    } catch (e) {
        // Not JSON, assume plain text chunk if not special commands
        // However, usually we expect JSON for content to differentiate from other types.
        // If we want to support plain text streaming, we'd add it here.
        // For now, let's assume content always comes as JSON { content: "..." }
        // or ensure backend sends it that way.
    }
};
