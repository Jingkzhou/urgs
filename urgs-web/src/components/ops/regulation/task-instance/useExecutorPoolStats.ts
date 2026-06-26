import { useEffect, useRef, useState } from 'react';
import { getExecutorPoolStats } from '@/api/ops';
import type { ExecutorPoolStats } from '@/api/ops';

const LIVE_POLL_INTERVAL_MS = 5000;
const STALE_RETRY_INTERVAL_MS = 15000;
const UNAVAILABLE_RETRY_INTERVAL_MS = 30000;
const HIDDEN_POLL_INTERVAL_MS = 60000;

export type ExecutorPoolStatsStatus = 'loading' | 'live' | 'stale' | 'unavailable';

export interface ExecutorPoolStatsState {
    stats: ExecutorPoolStats | null;
    status: ExecutorPoolStatsStatus;
    lastUpdatedAt: number | null;
    error: string | null;
}

const initialState: ExecutorPoolStatsState = {
    stats: null,
    status: 'loading',
    lastUpdatedAt: null,
    error: null,
};

export const useExecutorPoolStats = (): ExecutorPoolStatsState => {
    const [state, setState] = useState<ExecutorPoolStatsState>(initialState);
    const hasStatsRef = useRef(false);

    useEffect(() => {
        let disposed = false;
        let timer: number | undefined;

        const scheduleNextPoll = (nextStatus: ExecutorPoolStatsStatus) => {
            if (disposed) return;
            const delay = document.visibilityState === 'hidden'
                ? HIDDEN_POLL_INTERVAL_MS
                : nextStatus === 'live'
                    ? LIVE_POLL_INTERVAL_MS
                    : nextStatus === 'stale'
                        ? STALE_RETRY_INTERVAL_MS
                        : UNAVAILABLE_RETRY_INTERVAL_MS;
            timer = window.setTimeout(poll, delay);
        };

        const poll = async () => {
            let nextStatus: ExecutorPoolStatsStatus = 'unavailable';
            try {
                const response = await getExecutorPoolStats();
                if (!response?.success || !response.data) {
                    throw new Error(response?.msg || '执行器线程池指标不可用');
                }
                nextStatus = 'live';
                if (!disposed) {
                    hasStatsRef.current = true;
                    setState({
                        stats: response.data,
                        status: nextStatus,
                        lastUpdatedAt: Date.now(),
                        error: null,
                    });
                }
            } catch (error: any) {
                if (!disposed) {
                    nextStatus = hasStatsRef.current ? 'stale' : nextStatus;
                    setState(previous => ({
                        ...previous,
                        status: nextStatus,
                        error: error?.message || '执行器线程池指标不可用',
                    }));
                }
            } finally {
                scheduleNextPoll(nextStatus);
            }
        };

        void poll();
        return () => {
            disposed = true;
            if (timer !== undefined) {
                window.clearTimeout(timer);
            }
        };
    }, []);

    return state;
};
