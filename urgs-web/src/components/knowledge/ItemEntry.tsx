import React from 'react';
import { Dropdown, message } from 'antd';
import { Folder, Star, Lock } from 'lucide-react';
import type { KnowledgeDocument } from '../../api/knowledge';
import { getFileIcon } from '../../utils/fileIcons';

export interface ItemEntryProps {
    type: 'folder' | 'doc';
    title: string;
    id: number;
    doc?: KnowledgeDocument;
    layoutMode: 'grid' | 'list';
    isShared: boolean;
    permissions: { canSharedDelete: boolean; canSharedFolderDelete: boolean };
    onEnter: () => void;
    onPreview?: (doc: KnowledgeDocument) => void;
    onDelete: (id: number) => void;
    onRename: (id: number, name: string) => void;
    onToggleFavorite: (e: React.MouseEvent, doc: KnowledgeDocument) => void;
    onCopyToPrivate: (id: number) => void;
    onDownload: () => void;
    // Phase 3: 批量选择
    selected?: boolean;
    selectionMode?: boolean;
    onSelect?: (e: React.MouseEvent) => void;
}

const ItemEntry: React.FC<ItemEntryProps> = ({
    type, title, id, doc, layoutMode, isShared, permissions,
    onEnter, onPreview, onDelete, onRename, onToggleFavorite, onCopyToPrivate, onDownload,
    selected, selectionMode, onSelect,
}) => {
    const isDoc = type === 'doc';
    const isGrid = layoutMode === 'grid';
    const isFavorite = doc?.isFavorite === 1;

    const handleClick = (e: React.MouseEvent) => {
        if (selectionMode && onSelect) {
            e.preventDefault();
            e.stopPropagation();
            onSelect(e);
            return;
        }
        // 单击文档 → 预览
        if (isDoc && doc && onPreview) {
            onPreview(doc);
        }
    };

    const handleDoubleClick = () => {
        if (selectionMode) return;
        onEnter();
    };

    // 构建右键菜单
    const menuItems: any[] = [
        { key: 'open', label: '打开', onClick: onEnter },
        { key: 'download', label: isDoc ? '下载' : '打包下载', onClick: onDownload },
    ];

    if (isShared && isDoc) {
        menuItems.push({
            key: 'copyToPrivate',
            label: '添加到我的空间',
            icon: <Lock size={14} />,
            onClick: () => onCopyToPrivate(id),
        });
    }

    if (!isShared) {
        menuItems.push({
            key: 'edit',
            label: '重命名',
            onClick: () => {
                if (!isDoc) {
                    onRename(id, title);
                } else {
                    message.info('暂不支持重命名附件');
                }
            }
        });
        if (isDoc && doc) {
            menuItems.push({
                key: 'favorite',
                label: isFavorite ? '取消收藏' : '添加收藏',
                onClick: (e: any) => onToggleFavorite(e, doc),
            });
        }
    }

    const canDelete = isShared
        ? (isDoc ? permissions.canSharedDelete : permissions.canSharedFolderDelete)
        : true;
    if (canDelete) {
        menuItems.push({
            key: 'delete',
            label: '删除',
            danger: true,
            onClick: () => onDelete(id),
        });
    }

    // ---- Grid 视图 ----
    if (isGrid) {
        return (
            <Dropdown menu={{ items: menuItems }} trigger={['contextMenu']}>
                <div
                    className={`flex flex-col items-center p-2 rounded-lg cursor-pointer transition-all hover:bg-slate-200 group relative
                        ${selected ? 'ring-2 ring-blue-500 bg-blue-50/50' : ''}
                    `}
                    style={{ width: 100, height: 110 }}
                    onClick={handleClick}
                    onDoubleClick={handleDoubleClick}
                    onContextMenu={(e) => e.stopPropagation()}
                >
                    {/* 选择模式复选框 */}
                    {selectionMode && (
                        <div
                            className={`absolute top-1 left-1 w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all z-10
                                ${selected
                                    ? 'bg-blue-500 border-blue-500 text-white'
                                    : 'bg-white/80 border-slate-300 group-hover:border-blue-400'
                                }
                            `}
                        >
                            {selected && (
                                <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                                    <path d="M2 6L5 9L10 3" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                                </svg>
                            )}
                        </div>
                    )}

                    <div className="mb-2 relative">
                        {isDoc ? (
                            <div className="w-14 h-14 bg-white rounded-xl flex items-center justify-center text-slate-500 shadow-sm border border-slate-100 group-hover:shadow-md transition-shadow">
                                {getFileIcon(doc?.fileName || title, 32)}
                            </div>
                        ) : (
                            <div className="w-14 h-14 bg-amber-50 rounded-xl flex items-center justify-center text-amber-500 shadow-sm border border-amber-100 group-hover:shadow-md transition-shadow">
                                <Folder size={32} className="fill-amber-500/20" />
                            </div>
                        )}
                        {isFavorite && (
                            <div className="absolute -top-1 -right-1 bg-white rounded-full shadow-sm">
                                <Star size={14} className="text-amber-500 fill-amber-500" />
                            </div>
                        )}
                    </div>
                    <span className="text-xs text-center line-clamp-2 px-1 break-all text-slate-700 font-medium group-hover:text-slate-900 leading-tight">
                        {title}
                    </span>
                </div>
            </Dropdown>
        );
    }

    // ---- List 视图 ----
    return (
        <Dropdown menu={{ items: menuItems }} trigger={['contextMenu']}>
            <div
                className={`flex items-center px-4 py-2 hover:bg-blue-50 cursor-pointer border-b border-slate-100 group text-sm
                    ${selected ? 'bg-blue-50' : ''}
                `}
                onClick={handleClick}
                onDoubleClick={handleDoubleClick}
                onContextMenu={(e) => e.stopPropagation()}
            >
                {/* 选择模式复选框 */}
                {selectionMode && (
                    <div className="w-10 flex-shrink-0 flex items-center justify-center">
                        <div
                            className={`w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all
                                ${selected
                                    ? 'bg-blue-500 border-blue-500 text-white'
                                    : 'bg-white border-slate-300 group-hover:border-blue-400'
                                }
                            `}
                        >
                            {selected && (
                                <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                                    <path d="M2 6L5 9L10 3" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                                </svg>
                            )}
                        </div>
                    </div>
                )}
                <div className="w-8 flex-shrink-0 flex items-center justify-center">
                    {isDoc ? (
                        getFileIcon(doc?.fileName || title, 18)
                    ) : (
                        <Folder size={18} className="text-amber-400 fill-amber-400" />
                    )}
                </div>
                <div className="flex-1 truncate font-medium text-slate-700 group-hover:text-blue-600 mr-4">
                    {title}
                </div>
                <div className="w-32 text-slate-400 text-xs text-center">
                    {isDoc ? '附件' : '文件夹'}
                </div>
                <div className="w-44 text-slate-400 text-xs">
                    {isDoc && doc ? new Date(doc.updateTime).toLocaleString() : '-'}
                </div>
                <div className="w-24 text-slate-400 text-xs text-right">
                    {isDoc && doc?.fileSize ? `${(doc.fileSize / 1024).toFixed(1)} KB` : '-'}
                </div>
                <div className="w-10 flex justify-end ml-4">
                    {isFavorite && <Star size={14} className="text-amber-500 fill-amber-500" />}
                </div>
            </div>
        </Dropdown>
    );
};

export default ItemEntry;
