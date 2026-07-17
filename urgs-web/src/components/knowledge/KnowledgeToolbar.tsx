import React from 'react';
import { Button, Input, Segmented, Space, Upload } from 'antd';
import type { UploadProps } from 'antd';
import {
    ArrowLeft,
    ArrowRight,
    CheckSquare,
    ChevronRight,
    FolderPlus,
    LayoutGrid,
    List as ListIcon,
    Search,
    Upload as UploadIcon,
    X,
} from 'lucide-react';

interface KnowledgeToolbarProps {
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
    selectionMode: boolean;
    onEnterSelectionMode: () => void;
    onExitSelectionMode: () => void;
    title: string;
    onMinimize: () => void;
    onClose: () => void;
    onToggleMaximize: () => void;
    isMaximized: boolean;
}

const KnowledgeToolbar: React.FC<KnowledgeToolbarProps> = ({
    selectedFolderId,
    breadcrumbs,
    onBreadcrumbClick,
    onBack,
    searchKeyword,
    onSearch,
    layoutMode,
    onLayoutChange,
    uploadProps,
    canUpload,
    canCreateFolder,
    onNewFolder,
    selectionMode,
    onEnterSelectionMode,
    onExitSelectionMode,
    title,
    onMinimize,
    onClose,
    onToggleMaximize,
    isMaximized,
}) => (
    <header className="knowledge-finder-toolbar" onDoubleClick={onToggleMaximize}>
        <div className="knowledge-window-controls" onDoubleClick={e => e.stopPropagation()}>
            <button type="button" className="knowledge-traffic-light knowledge-traffic-light--close" onClick={onClose} aria-label="关闭 Finder">
                <X size={8} />
            </button>
            <button type="button" className="knowledge-traffic-light knowledge-traffic-light--minimize" onClick={onMinimize} aria-label="最小化 Finder">
                <span />
            </button>
            <button
                type="button"
                className="knowledge-traffic-light knowledge-traffic-light--maximize"
                onClick={onToggleMaximize}
                aria-label={isMaximized ? '退出全屏' : '最大化 Finder'}
            >
                <span />
            </button>
        </div>

        <div className="knowledge-toolbar-navigation" onDoubleClick={e => e.stopPropagation()}>
            <Button
                type="text"
                size="small"
                icon={<ArrowLeft size={16} />}
                disabled={selectedFolderId === null}
                onClick={onBack}
                aria-label="返回上一级"
            />
            <Button type="text" size="small" icon={<ArrowRight size={16} />} disabled aria-label="前进" />
        </div>

        <div className="knowledge-toolbar-title" title={title}>
            <span>{title}</span>
            <small>{isMaximized ? '全屏浏览' : 'Finder'}</small>
        </div>

        <nav className="knowledge-breadcrumbs" aria-label="当前位置" onDoubleClick={e => e.stopPropagation()}>
            {breadcrumbs.map((breadcrumb, index) => (
                <React.Fragment key={`${breadcrumb.id ?? 'root'}-${index}`}>
                    {index > 0 && <ChevronRight size={12} />}
                    <button type="button" onClick={() => onBreadcrumbClick(breadcrumb.id)} title={breadcrumb.name}>
                        {breadcrumb.name}
                    </button>
                </React.Fragment>
            ))}
        </nav>

        <div className="knowledge-toolbar-actions" onDoubleClick={e => e.stopPropagation()}>
            <Input
                allowClear
                prefix={<Search size={13} />}
                placeholder="搜索"
                className="knowledge-search-input"
                value={searchKeyword}
                onChange={e => onSearch(e.target.value)}
            />
            <Space size={5}>
                {canUpload && (
                    <Upload {...uploadProps}>
                        <Button type="text" size="small" icon={<UploadIcon size={16} />} title="上传文件" aria-label="上传文件" />
                    </Upload>
                )}
                {canCreateFolder && (
                    <Button type="text" size="small" icon={<FolderPlus size={16} />} onClick={onNewFolder} title="新建文件夹" aria-label="新建文件夹" />
                )}
                {selectionMode ? (
                    <Button type="text" size="small" icon={<X size={15} />} onClick={onExitSelectionMode} title="取消选择" aria-label="取消选择" />
                ) : (
                    <Button type="text" size="small" icon={<CheckSquare size={15} />} onClick={onEnterSelectionMode} title="选择项目" aria-label="选择项目" />
                )}
                <Segmented
                    size="small"
                    value={layoutMode}
                    onChange={val => onLayoutChange(val as 'grid' | 'list')}
                    options={[
                        { value: 'grid', icon: <LayoutGrid size={13} />, title: '图标视图' },
                        { value: 'list', icon: <ListIcon size={13} />, title: '列表视图' },
                    ]}
                />
            </Space>
        </div>
    </header>
);

export default KnowledgeToolbar;
