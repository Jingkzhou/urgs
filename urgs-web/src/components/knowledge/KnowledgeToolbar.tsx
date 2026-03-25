import React from 'react';
import {
    Input,
    Button,
    Space,
    Upload,
    Segmented,
    Breadcrumb,
    Popover,
} from 'antd';
import type { UploadProps } from 'antd';
import {
    Search,
    Upload as UploadIcon,
    FolderPlus,
    ArrowLeft,
    LayoutGrid,
    List as ListIcon,
    Users,
    Lock,
    CheckSquare,
    X,
    Star,
    Tags,
} from 'lucide-react';
import type { KnowledgeTag } from '../../api/knowledge';

interface KnowledgeToolbarProps {
    scope: 'private' | 'shared';
    viewMode: 'browse' | 'favorites';
    onScopeChange: (val: 'private' | 'shared') => void;
    onViewModeChange: (val: 'browse' | 'favorites') => void;
    selectedFolderId: number | null;
    breadcrumbs: Array<{ id: number | null; name: string }>;
    onBreadcrumbClick: (id: number | null) => void;
    onBack: () => void;
    searchKeyword: string;
    onSearch: (val: string) => void;
    layoutMode: 'grid' | 'list';
    onLayoutChange: (val: 'grid' | 'list') => void;
    uploadProps: UploadProps;
    canUpload: boolean;
    canCreateFolder: boolean;
    onNewFolder: () => void;
    tags: KnowledgeTag[];
    filterTagId: number | null;
    onFilterTag: (id: number | null) => void;
    selectionMode: boolean;
    onEnterSelectionMode: () => void;
    onExitSelectionMode: () => void;
}

const KnowledgeToolbar: React.FC<KnowledgeToolbarProps> = ({
    scope, viewMode, onScopeChange, onViewModeChange,
    selectedFolderId, breadcrumbs, onBreadcrumbClick, onBack,
    searchKeyword, onSearch, layoutMode, onLayoutChange,
    uploadProps, canUpload, canCreateFolder, onNewFolder,
    tags, filterTagId, onFilterTag,
    selectionMode, onEnterSelectionMode, onExitSelectionMode,
}) => {
    const isFavoritesView = viewMode === 'favorites';

    return (
        <header className="h-14 bg-white border-b border-slate-200 flex items-center px-4 justify-between flex-shrink-0">
            <div className="flex items-center gap-4">
                <Segmented
                    value={scope}
                    onChange={val => onScopeChange(val as 'private' | 'shared')}
                    options={[
                        { value: 'private', icon: <Lock size={12} />, label: '我的空间' },
                        { value: 'shared', icon: <Users size={12} />, label: '共享空间' },
                    ]}
                />

                {/* 收藏夹按钮 */}
                <button
                    onClick={() => onViewModeChange(isFavoritesView ? 'browse' : 'favorites')}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-all
                        ${isFavoritesView
                            ? 'bg-amber-50 text-amber-600 border border-amber-200'
                            : 'text-slate-500 hover:bg-slate-100 hover:text-amber-500'
                        }
                    `}
                    title="收藏夹"
                >
                    <Star size={14} className={isFavoritesView ? 'fill-amber-500' : ''} />
                    收藏
                </button>

                {/* 标签筛选 */}
                {tags.length > 0 && (
                    <Popover
                        content={
                            <div className="w-48 py-1">
                                <div
                                    className={`px-3 py-1.5 cursor-pointer rounded text-sm transition-colors
                                        ${!filterTagId ? 'bg-blue-50 text-blue-600 font-medium' : 'text-slate-600 hover:bg-slate-50'}`}
                                    onClick={() => onFilterTag(null)}
                                >
                                    全部文件
                                </div>
                                <div className="h-px bg-slate-100 my-1" />
                                {tags.map(t => (
                                    <div
                                        key={t.id}
                                        className={`flex items-center gap-2 px-3 py-1.5 cursor-pointer rounded text-sm transition-colors
                                            ${filterTagId === t.id ? 'bg-blue-50 text-blue-600 font-medium' : 'text-slate-600 hover:bg-slate-50'}`}
                                        onClick={() => onFilterTag(filterTagId === t.id ? null : t.id)}
                                    >
                                        <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: t.color }} />
                                        {t.name}
                                    </div>
                                ))}
                            </div>
                        }
                        trigger="click"
                        placement="bottomLeft"
                    >
                        <button
                            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-all
                                ${filterTagId
                                    ? 'bg-blue-50 text-blue-600 border border-blue-200'
                                    : 'text-slate-500 hover:bg-slate-100 hover:text-blue-500'
                                }
                            `}
                            title="按标签筛选"
                        >
                            <Tags size={14} />
                            {filterTagId ? tags.find(t => t.id === filterTagId)?.name || '标签' : '标签'}
                        </button>
                    </Popover>
                )}

                <div className="w-px h-6 bg-slate-200"></div>

                {/* 收藏夹模式下显示标题，普通模式显示面包屑 */}
                {isFavoritesView ? (
                    <span className="text-sm font-medium text-amber-600 flex items-center gap-1.5">
                        <Star size={14} className="fill-amber-500 text-amber-500" />
                        我的收藏
                    </span>
                ) : (
                    <>
                        <Button
                            icon={<ArrowLeft size={16} />}
                            disabled={selectedFolderId === null}
                            onClick={onBack}
                            type="text"
                            className="hover:bg-slate-100"
                        />
                        <Breadcrumb
                            className="text-sm font-medium"
                            items={breadcrumbs.map((b) => ({
                                title: b.name,
                                onClick: () => onBreadcrumbClick(b.id),
                                className: "cursor-pointer hover:text-blue-600 transition-colors"
                            }))}
                        />
                    </>
                )}
            </div>

            <div className="flex items-center gap-2">
                <Input
                    prefix={<Search size={14} className="text-slate-400" />}
                    placeholder={isFavoritesView ? "搜索收藏..." : "搜索文件..."}
                    className="w-48 sm:w-64 rounded-full bg-slate-100 border-none px-4"
                    value={searchKeyword}
                    onChange={e => onSearch(e.target.value)}
                />
                <Space size={8} className="ml-2">
                    {!isFavoritesView && canUpload && (
                        <Upload {...uploadProps}>
                            <Button type="primary" icon={<UploadIcon size={18} />} className="bg-emerald-600 hover:bg-emerald-700 border-none">
                                上传文件
                            </Button>
                        </Upload>
                    )}
                    {!isFavoritesView && canCreateFolder && (
                        <Button icon={<FolderPlus size={18} />} onClick={onNewFolder}>
                            新建文件夹
                        </Button>
                    )}
                    <div className="w-px h-6 bg-slate-200 mx-1"></div>
                    {selectionMode ? (
                        <Button
                            icon={<X size={16} />}
                            onClick={onExitSelectionMode}
                            className="text-slate-500 hover:text-red-500"
                        >
                            取消选择
                        </Button>
                    ) : (
                        <Button
                            icon={<CheckSquare size={16} />}
                            onClick={onEnterSelectionMode}
                            type="text"
                            className="text-slate-500 hover:text-blue-600"
                        >
                            选择
                        </Button>
                    )}
                    <Segmented
                        value={layoutMode}
                        onChange={val => onLayoutChange(val as 'grid' | 'list')}
                        options={[
                            { value: 'grid', icon: <LayoutGrid size={14} /> },
                            { value: 'list', icon: <ListIcon size={14} /> },
                        ]}
                    />
                </Space>
            </div>
        </header>
    );
};

export default KnowledgeToolbar;
