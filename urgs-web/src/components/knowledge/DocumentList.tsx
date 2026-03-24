import React from 'react';
import { Empty, Spin } from 'antd';
import ItemEntry from './ItemEntry';
import type { FolderTreeNode, KnowledgeDocument } from '../../api/knowledge';

interface DocumentListProps {
    folders: FolderTreeNode[];
    documents: KnowledgeDocument[];
    loading: boolean;
    isShared: boolean;
    permissions: { canSharedDelete: boolean; canSharedFolderDelete: boolean };
    selectionMode: boolean;
    selectedItems: Set<string>;
    onFolderEnter: (id: number) => void;
    onPreview: (doc: KnowledgeDocument) => void;
    onDelete: (id: number, type: 'folder' | 'doc') => void;
    onRename: (id: number, name: string) => void;
    onToggleFavorite: (e: React.MouseEvent, doc: KnowledgeDocument) => void;
    onCopyToPrivate: (id: number) => void;
    onDownloadDoc: (doc: KnowledgeDocument) => void;
    onDownloadFolder: (id: number, title: string) => void;
    onSelect: (key: string, e: React.MouseEvent) => void;
}

const DocumentList: React.FC<DocumentListProps> = ({
    folders, documents, loading, isShared, permissions,
    selectionMode, selectedItems,
    onFolderEnter, onPreview, onDelete, onRename, onToggleFavorite,
    onCopyToPrivate, onDownloadDoc, onDownloadFolder, onSelect,
}) => {
    const hasItems = folders.length > 0 || documents.length > 0;

    if (!hasItems && !loading) {
        return (
            <div className="h-full flex items-center justify-center py-20">
                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="这是一个空文件夹" />
            </div>
        );
    }

    return (
        <Spin spinning={loading}>
            {hasItems && (
                <div className="flex items-center px-4 py-2 border-b border-slate-200 bg-slate-50 text-[11px] font-bold text-slate-400 uppercase tracking-wider sticky top-0 z-10">
                    {selectionMode && <div className="w-10"></div>}
                    <div className="w-8"></div>
                    <div className="flex-1">名称</div>
                    <div className="w-32 text-center">类型</div>
                    <div className="w-44">最后修改</div>
                    <div className="w-24 text-right">大小</div>
                    <div className="w-10 ml-4"></div>
                </div>
            )}
            <div className="flex flex-col">
                {folders.map(f => (
                    <ItemEntry
                        key={`folder-${f.id}`}
                        type="folder"
                        title={f.name}
                        id={f.id}
                        layoutMode="list"
                        isShared={isShared}
                        permissions={permissions}
                        onEnter={() => onFolderEnter(f.id)}
                        onDelete={(id) => onDelete(id, 'folder')}
                        onRename={onRename}
                        onToggleFavorite={onToggleFavorite}
                        onCopyToPrivate={onCopyToPrivate}
                        onDownload={() => onDownloadFolder(f.id, f.name)}
                        selectionMode={selectionMode}
                        selected={selectedItems.has(`folder-${f.id}`)}
                        onSelect={(e) => onSelect(`folder-${f.id}`, e)}
                    />
                ))}
                {documents.map(d => (
                    <ItemEntry
                        key={`doc-${d.id}`}
                        type="doc"
                        title={d.title}
                        id={d.id}
                        doc={d}
                        layoutMode="list"
                        isShared={isShared}
                        permissions={permissions}
                        onEnter={() => onPreview(d)}
                        onPreview={onPreview}
                        onDelete={(id) => onDelete(id, 'doc')}
                        onRename={onRename}
                        onToggleFavorite={onToggleFavorite}
                        onCopyToPrivate={onCopyToPrivate}
                        onDownload={() => onDownloadDoc(d)}
                        selectionMode={selectionMode}
                        selected={selectedItems.has(`doc-${d.id}`)}
                        onSelect={(e) => onSelect(`doc-${d.id}`, e)}
                    />
                ))}
            </div>
        </Spin>
    );
};

export default DocumentList;
