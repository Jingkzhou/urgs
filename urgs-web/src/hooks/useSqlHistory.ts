import { useState, useCallback } from 'react';

const STORAGE_KEY = 'sql_console_history';
const MAX_HISTORY = 50;

export interface SqlHistoryEntry {
    sql: string;
    dataSourceId: string;
    timestamp: number;
}

export function useSqlHistory() {
    const [history, setHistory] = useState<SqlHistoryEntry[]>(() => {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            return raw ? JSON.parse(raw) : [];
        } catch {
            return [];
        }
    });

    const addEntry = useCallback((sql: string, dataSourceId: string) => {
        setHistory(prev => {
            // 去重：如果相同 SQL 已存在，移到顶部
            const filtered = prev.filter(e => e.sql !== sql);
            const newHistory = [
                { sql, dataSourceId, timestamp: Date.now() },
                ...filtered,
            ].slice(0, MAX_HISTORY);

            try {
                localStorage.setItem(STORAGE_KEY, JSON.stringify(newHistory));
            } catch { /* ignore quota errors */ }

            return newHistory;
        });
    }, []);

    const clearHistory = useCallback(() => {
        setHistory([]);
        localStorage.removeItem(STORAGE_KEY);
    }, []);

    return { history, addEntry, clearHistory };
}
