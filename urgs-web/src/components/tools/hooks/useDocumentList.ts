import { useCallback, useEffect, useMemo, useState } from 'react';
import { message } from 'antd';
import type { OnlineDocument, OnlineDocumentPage } from '../../../api/onlineDocs';
import {
    listOnlineDocuments,
    listFavoriteDocuments,
    listSpaceDocuments,
    toggleFavorite,
} from '../../../api/onlineDocs';

const PAGE_SIZE = 12;

export type TabKey = 'recent' | 'space' | 'favorite';
export type SpaceType = 'personal' | 'shared' | 'all';

export interface UseDocumentListReturn {
    documents: OnlineDocument[];
    keyword: string;
    page: number;
    total: number;
    loading: boolean;
    activeTab: TabKey;
    activeSpaceType: SpaceType;
    filterType: string;
    setKeyword: (value: string) => void;
    setPage: (page: number) => void;
    setActiveTab: (tab: TabKey) => void;
    setActiveSpaceType: (type: SpaceType) => void;
    setFilterType: (type: string) => void;
    loadDocuments: () => Promise<void>;
    handleSearch: (value: string) => void;
    handleToggleFavorite: (doc: OnlineDocument) => Promise<void>;
    supportedCount: number;
}

export function useDocumentList(): UseDocumentListReturn {
    const [documents, setDocuments] = useState<OnlineDocument[]>([]);
    const [keyword, setKeyword] = useState('');
    const [page, setPage] = useState(1);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(false);
    const [activeTab, setActiveTabState] = useState<TabKey>('recent');
    const [activeSpaceType, setActiveSpaceType] = useState<SpaceType>('all');
    const [filterType, setFilterType] = useState<string>('all');

    const loadDocuments = useCallback(async () => {
        setLoading(true);
        try {
            const baseParams = {
                keyword: keyword || undefined,
                fileType: filterType === 'all' ? undefined : filterType,
                page,
                size: PAGE_SIZE,
            };
            const result: OnlineDocumentPage<OnlineDocument> = await (() => {
                switch (activeTab) {
                    case 'recent':
                        return listOnlineDocuments(baseParams);
                    case 'favorite':
                        return listFavoriteDocuments(baseParams);
                    case 'space':
                        return listSpaceDocuments({ ...baseParams, spaceType: activeSpaceType });
                }
            })();
            setDocuments(result.records || []);
            setTotal(result.total || 0);
        } catch {
            message.error('在线文档加载失败');
        } finally {
            setLoading(false);
        }
    }, [keyword, page, activeTab, filterType, activeSpaceType]);

    useEffect(() => {
        loadDocuments();
    }, [loadDocuments]);

    const setActiveTab = useCallback((tab: TabKey) => {
        setActiveTabState(tab);
        setPage(1);
        setFilterType('all');
        if (tab === 'space') {
            setActiveSpaceType('all');
        }
    }, []);

    const handleSearch = useCallback((value: string) => {
        setKeyword(value.trim());
        setPage(1);
        setFilterType('all');
    }, []);

    const handleToggleFavorite = useCallback(async (doc: OnlineDocument) => {
        const willFavorite = !doc.favorite;
        try {
            await toggleFavorite(doc.id);
            setDocuments(docs => docs.map(d => d.id === doc.id ? { ...d, favorite: willFavorite } : d));
            message.success(willFavorite ? '已收藏' : '已取消收藏');
            if (activeTab === 'favorite' && !willFavorite && total > 1) {
                setDocuments(docs => docs.filter(d => d.id !== doc.id));
                setTotal(prev => prev - 1);
            }
        } catch {
            message.error('操作失败');
        }
    }, [activeTab, total]);

    const supportedCount = useMemo(
        () => documents.filter(doc => {
            const ext = doc.fileName?.split('.').pop()?.toLowerCase() || '';
            return ['docx', 'xlsx', 'pptx'].includes(ext);
        }).length,
        [documents],
    );

    return {
        documents,
        keyword,
        page,
        total,
        loading,
        activeTab,
        activeSpaceType,
        filterType,
        setKeyword,
        setPage,
        setActiveTab,
        setActiveSpaceType,
        setFilterType,
        loadDocuments,
        handleSearch,
        handleToggleFavorite,
        supportedCount,
    };
}
