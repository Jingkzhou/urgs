import { useState, useCallback } from 'react';

const STORAGE_KEY = 'sql_console_favorites';

export interface SqlFavorite {
    id: string;
    name: string;
    sql: string;
    dataSourceId: string;
    createdAt: number;
}

export function useSqlFavorites() {
    const [favorites, setFavorites] = useState<SqlFavorite[]>(() => {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            return raw ? JSON.parse(raw) : [];
        } catch {
            return [];
        }
    });

    const save = (list: SqlFavorite[]) => {
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
        } catch { /* ignore quota errors */ }
    };

    const addFavorite = useCallback((name: string, sql: string, dataSourceId: string) => {
        setFavorites(prev => {
            const newFav: SqlFavorite = {
                id: crypto.randomUUID(),
                name,
                sql,
                dataSourceId,
                createdAt: Date.now(),
            };
            const updated = [newFav, ...prev];
            save(updated);
            return updated;
        });
    }, []);

    const removeFavorite = useCallback((id: string) => {
        setFavorites(prev => {
            const updated = prev.filter(f => f.id !== id);
            save(updated);
            return updated;
        });
    }, []);

    return { favorites, addFavorite, removeFavorite };
}
