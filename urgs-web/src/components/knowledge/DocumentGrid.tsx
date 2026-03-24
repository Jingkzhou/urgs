import React from 'react';
import { Empty, Spin } from 'antd';
import ItemEntry from './ItemEntry';
import type { FolderTreeNode, KnowledgeDocument } from '../../api/knowledge';

interface DocumentGridProps {
    folders: FolderTreeNode[];
    documents: KnowledgeDocument[];
    loading: boolean;
    isShared: boolean;
    permissions: { canSharedDelete: boolean; canSharedFolderDelete: boolean };
    selectionMode: boolean;
    selectedItems: Set<string>;
    emptyText?: string;
    onFolderEnter: (id: number) => void;
    onPreview: (doc: KnowledgeDocument) => void;
    onDelete: (id: number, type: 'folder' | 'doc') => void;
    onRename: (id: number, name: string) => void;
    onToggleFavorite: (doc: KnowledgeDocument) => void;
    onCopyToPrivate: (id: number) => void;
    onDownloadDoc: (doc: KnowledgeDocument) => void;
    onDownloadFolder: (id: number, title: string) => void;
    onSelect: (key: string, e: React.MouseEvent) => void;
    onTagDocument?: (doc: KnowledgeDocument) => void;
}

const DocumentGrid: React.FC<DocumentGridProps> = ({
    folders, documents, loading, isShared, permissions,
    selectionMode, selectedItems, emptyText,
    onFolderEnter, onPreview, onDelete, onRename, onToggleFavorite,
    onCopyToPrivate, onDownloadDoc, onDownloadFolder, onSelect, onTagDocument,
}) => {
    if (folders.length === 0 && documents.length === 0 && !loading) {
        return (
            <div className="h-full flex items-center justify-center py-20">
                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={emptyText || "这是一个空文件夹"} />
            </div>
        );
    }

    return (
        <Spin spinning={loading}>
            <div className="flex flex-wrap gap-4 content-start">
                {folders.map(f => (
                    <ItemEntry
                        key={`folder-${f.id}`}
                        type="folder"
                        title={f.name}
                        id={f.id}
                        layoutMode="grid"
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
                        layoutMode="grid"
                        isShared={isShared}
                        permissions={permissions}
                        onEnter={() => onPreview(d)}
                        onPreview={onPreview}
                        onDelete={(id) => onDelete(id, 'doc')}
                        onRename={onRename}
                        onToggleFavorite={onToggleFavorite}
                        onCopyToPrivate={onCopyToPrivate}
                        onDownload={() => onDownloadDoc(d)}
                        onTagDocument={onTagDocument}
                        selectionMode={selectionMode}
                        selected={selectedItems.has(`doc-${d.id}`)}
                        onSelect={(e) => onSelect(`doc-${d.id}`, e)}
                    />
                ))}
            </div>
        </Spin>
    );
};

export default DocumentGrid;
