import React from 'react';
import {
    Input,
    Button,
    Space,
    Upload,
    Segmented,
    Breadcrumb,
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
} from 'lucide-react';

interface KnowledgeToolbarProps {
    scope: 'private' | 'shared';
    onScopeChange: (val: 'private' | 'shared') => void;
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
    // Phase 3: 选择模式
    selectionMode: boolean;
    onEnterSelectionMode: () => void;
    onExitSelectionMode: () => void;
}

const KnowledgeToolbar: React.FC<KnowledgeToolbarProps> = ({
    scope, onScopeChange, selectedFolderId, breadcrumbs, onBreadcrumbClick, onBack,
    searchKeyword, onSearch, layoutMode, onLayoutChange,
    uploadProps, canUpload, canCreateFolder, onNewFolder,
    selectionMode, onEnterSelectionMode, onExitSelectionMode,
}) => {
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
                <div className="w-px h-6 bg-slate-200"></div>
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
            </div>

            <div className="flex items-center gap-2">
                <Input
                    prefix={<Search size={14} className="text-slate-400" />}
                    placeholder="搜索文件..."
                    className="w-48 sm:w-64 rounded-full bg-slate-100 border-none px-4"
                    value={searchKeyword}
                    onChange={e => onSearch(e.target.value)}
                />
                <Space size={8} className="ml-2">
                    {canUpload && (
                        <Upload {...uploadProps}>
                            <Button type="primary" icon={<UploadIcon size={18} />} className="bg-emerald-600 hover:bg-emerald-700 border-none">
                                上传文件
                            </Button>
                        </Upload>
                    )}
                    {canCreateFolder && (
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
