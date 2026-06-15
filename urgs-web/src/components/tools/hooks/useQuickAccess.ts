import { useCallback, useEffect, useState } from 'react';
import type { OnlineDocument, OnlineDocumentPage } from '../../../api/onlineDocs';
import { listOnlineDocuments } from '../../../api/onlineDocs';

export interface UseQuickAccessReturn {
    recentDocs: OnlineDocument[];
    loadRecentDocs: () => Promise<void>;
}

export function useQuickAccess(depChangeToken: number): UseQuickAccessReturn {
    const [recentDocs, setRecentDocs] = useState<OnlineDocument[]>([]);

    const loadRecentDocs = useCallback(async () => {
        try {
            const result: OnlineDocumentPage<OnlineDocument> = await listOnlineDocuments({ page: 1, size: 4 });
            setRecentDocs(result.records || []);
        } catch {
            // 快速访问加载失败不阻塞用户操作
        }
    }, []);

    // 首次加载
    useEffect(() => {
        loadRecentDocs();
    }, [loadRecentDocs]);

    // 依赖变化时刷新（用数字 token 避免引用不稳定导致的重复请求）
    useEffect(() => {
        loadRecentDocs();
    }, [depChangeToken, loadRecentDocs]);

    return { recentDocs, loadRecentDocs };
}
