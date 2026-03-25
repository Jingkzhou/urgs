import { useState, useEffect, useRef, useCallback } from 'react';

export interface StreamLogEntry {
    id: string;
    timestamp: string;
    level: string;
    message: string;
    source: string;
}

interface UseDockerLogStreamOptions {
    maxBufferSize?: number;
    enabled?: boolean;
}

interface UseDockerLogStreamReturn {
    logs: StreamLogEntry[];
    isConnected: boolean;
    connectionState: 'connected' | 'connecting' | 'disconnected';
    error: string | null;
    reconnect: () => void;
    clearLogs: () => void;
    subscribe: (containerId: string) => void;
    unsubscribe: (containerId: string) => void;
}

export function useDockerLogStream(
    containerIds: string[],
    options: UseDockerLogStreamOptions = {}
): UseDockerLogStreamReturn {
    const { maxBufferSize = 5000, enabled = true } = options;

    const [logs, setLogs] = useState<StreamLogEntry[]>([]);
    const [connectionState, setConnectionState] = useState<'connected' | 'connecting' | 'disconnected'>('disconnected');
    const [error, setError] = useState<string | null>(null);

    const wsRef = useRef<WebSocket | null>(null);
    const retryCountRef = useRef(0);
    const retryTimerRef = useRef<ReturnType<typeof setTimeout>>();
    const heartbeatTimerRef = useRef<ReturnType<typeof setInterval>>();
    const containerIdsRef = useRef(containerIds);

    const MAX_RETRIES = 5;
    const HEARTBEAT_INTERVAL = 30000;

    containerIdsRef.current = containerIds;

    const clearLogs = useCallback(() => {
        setLogs([]);
    }, []);

    const connect = useCallback(() => {
        if (wsRef.current?.readyState === WebSocket.OPEN || wsRef.current?.readyState === WebSocket.CONNECTING) {
            return;
        }

        const ids = containerIdsRef.current;
        if (!ids || ids.length === 0) return;

        setConnectionState('connecting');
        setError(null);

        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const host = window.location.host;
        const url = `${protocol}//${host}/ws/docker/logs?containerIds=${ids.join(',')}`;

        const ws = new WebSocket(url);
        wsRef.current = ws;

        ws.onopen = () => {
            setConnectionState('connected');
            setError(null);
            retryCountRef.current = 0;

            // Start heartbeat
            heartbeatTimerRef.current = setInterval(() => {
                if (ws.readyState === WebSocket.OPEN) {
                    ws.send('ping');
                }
            }, HEARTBEAT_INTERVAL);
        };

        ws.onmessage = (event) => {
            const data = event.data;
            if (data === 'pong') return;

            try {
                const logEntry: StreamLogEntry = JSON.parse(data);
                setLogs(prev => {
                    const next = [...prev, logEntry];
                    return next.length > maxBufferSize ? next.slice(next.length - maxBufferSize) : next;
                });
            } catch (e) {
                // ignore non-JSON messages
            }
        };

        ws.onerror = () => {
            setError('WebSocket connection error');
        };

        ws.onclose = (event) => {
            setConnectionState('disconnected');
            if (heartbeatTimerRef.current) {
                clearInterval(heartbeatTimerRef.current);
            }

            // Auto reconnect with exponential backoff
            if (retryCountRef.current < MAX_RETRIES && enabled) {
                const delay = Math.min(1000 * Math.pow(2, retryCountRef.current), 16000);
                retryCountRef.current++;
                setConnectionState('connecting');
                retryTimerRef.current = setTimeout(() => {
                    connect();
                }, delay);
            } else if (retryCountRef.current >= MAX_RETRIES) {
                setError('Max reconnection attempts reached');
            }
        };
    }, [enabled, maxBufferSize]);

    const disconnect = useCallback(() => {
        retryCountRef.current = MAX_RETRIES; // prevent auto-reconnect
        if (retryTimerRef.current) {
            clearTimeout(retryTimerRef.current);
        }
        if (heartbeatTimerRef.current) {
            clearInterval(heartbeatTimerRef.current);
        }
        if (wsRef.current) {
            wsRef.current.close();
            wsRef.current = null;
        }
        setConnectionState('disconnected');
    }, []);

    const reconnect = useCallback(() => {
        disconnect();
        retryCountRef.current = 0;
        setTimeout(() => connect(), 100);
    }, [connect, disconnect]);

    const subscribe = useCallback((containerId: string) => {
        if (wsRef.current?.readyState === WebSocket.OPEN) {
            wsRef.current.send(JSON.stringify({ action: 'subscribe', containerId }));
        }
    }, []);

    const unsubscribe = useCallback((containerId: string) => {
        if (wsRef.current?.readyState === WebSocket.OPEN) {
            wsRef.current.send(JSON.stringify({ action: 'unsubscribe', containerId }));
        }
    }, []);

    // Connect when containerIds change
    useEffect(() => {
        if (!enabled || containerIds.length === 0) {
            disconnect();
            return;
        }

        // Reconnect with new container IDs
        disconnect();
        retryCountRef.current = 0;
        const timer = setTimeout(() => connect(), 100);
        return () => clearTimeout(timer);
    }, [containerIds.join(','), enabled]);

    // Cleanup on unmount
    useEffect(() => {
        return () => {
            retryCountRef.current = MAX_RETRIES;
            if (retryTimerRef.current) clearTimeout(retryTimerRef.current);
            if (heartbeatTimerRef.current) clearInterval(heartbeatTimerRef.current);
            if (wsRef.current) {
                wsRef.current.close();
                wsRef.current = null;
            }
        };
    }, []);

    return {
        logs,
        isConnected: connectionState === 'connected',
        connectionState,
        error,
        reconnect,
        clearLogs,
        subscribe,
        unsubscribe,
    };
}
