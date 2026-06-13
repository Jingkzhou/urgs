import { useEffect, useState } from 'react';
import { getExecutorPoolStats } from '@/api/ops';
import type { ExecutorPoolStats } from '@/api/ops';

const POLL_INTERVAL_MS = 3000;

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

    useEffect(() => {
        let disposed = false;
        let timer: number | undefined;

        const poll = async () => {
            try {
                const response = await getExecutorPoolStats();
                if (!response?.success || !response.data) {
                    throw new Error(response?.msg || '执行器线程池指标不可用');
                }
                if (!disposed) {
                    setState({
                        stats: response.data,
                        status: 'live',
                        lastUpdatedAt: Date.now(),
                        error: null,
                    });
                }
            } catch (error: any) {
                if (!disposed) {
                    setState(previous => ({
                        ...previous,
                        status: previous.stats ? 'stale' : 'unavailable',
                        error: error?.message || '执行器线程池指标不可用',
                    }));
                }
            } finally {
                if (!disposed) {
                    timer = window.setTimeout(poll, POLL_INTERVAL_MS);
                }
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
