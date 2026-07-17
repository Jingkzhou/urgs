import React, { useEffect, useMemo, useState } from 'react';
import {
    BatteryMedium,
    Cloud,
    Command,
    Files,
    Folder,
    FolderPlus,
    HardDrive,
    Search,
    Star,
    Tags,
    Upload,
    Users,
    Wifi,
} from 'lucide-react';
import type { KnowledgeTag } from '../../api/knowledge';

interface MacMenuBarProps {
    itemCount: number;
}

export const MacMenuBar: React.FC<MacMenuBarProps> = ({ itemCount }) => {
    const [now, setNow] = useState(() => new Date());

    useEffect(() => {
        const timer = window.setInterval(() => setNow(new Date()), 30_000);
        return () => window.clearInterval(timer);
    }, []);

    const dateLabel = useMemo(() => {
        const weekday = new Intl.DateTimeFormat('zh-CN', { weekday: 'short' }).format(now);
        const date = `${now.getMonth() + 1}月${now.getDate()}日 ${weekday}`;
        const time = new Intl.DateTimeFormat('zh-CN', {
            hour: '2-digit',
            minute: '2-digit',
            hour12: false,
        }).format(now);
        return `${date} ${time}`;
    }, [now]);

    return (
        <div className="knowledge-menu-bar" aria-label="知识中心菜单栏">
            <div className="knowledge-menu-left">
                <Command size={15} strokeWidth={2.4} />
                <strong>知识中心</strong>
                <span>文件</span>
                <span>编辑</span>
                <span>显示</span>
                <span>前往</span>
                <span>窗口</span>
                <span>帮助</span>
            </div>
            <div className="knowledge-menu-right">
                <span className="knowledge-menu-count">{itemCount} 个项目</span>
                <BatteryMedium size={17} />
                <Wifi size={15} />
                <Search size={14} />
                <time dateTime={now.toISOString()}>{dateLabel}</time>
            </div>
        </div>
    );
};

interface DesktopShortcutsProps {
    onOpenPrivate: () => void;
    onOpenShared: () => void;
}

export const DesktopShortcuts: React.FC<DesktopShortcutsProps> = ({ onOpenPrivate, onOpenShared }) => (
    <div className="knowledge-desktop-shortcuts" aria-label="桌面快捷方式">
        <button type="button" onClick={onOpenPrivate}>
            <span className="knowledge-desktop-disk knowledge-desktop-disk--private">
                <HardDrive size={28} />
            </span>
            <span>我的空间</span>
        </button>
        <button type="button" onClick={onOpenShared}>
            <span className="knowledge-desktop-disk knowledge-desktop-disk--shared">
                <Cloud size={30} />
            </span>
            <span>共享空间</span>
        </button>
    </div>
);

interface KnowledgeSidebarProps {
    scope: 'private' | 'shared';
    viewMode: 'browse' | 'favorites';
    filterTagId: number | null;
    tags: KnowledgeTag[];
    itemCount: number;
    onScopeChange: (scope: 'private' | 'shared') => void;
    onViewModeChange: (mode: 'browse' | 'favorites') => void;
    onFilterTag: (id: number | null) => void;
    onOpenTagManager: () => void;
}

export const KnowledgeSidebar: React.FC<KnowledgeSidebarProps> = ({
    scope,
    viewMode,
    filterTagId,
    tags,
    itemCount,
    onScopeChange,
    onViewModeChange,
    onFilterTag,
    onOpenTagManager,
}) => {
    const isBrowse = viewMode === 'browse';

    return (
        <aside className="knowledge-finder-sidebar" aria-label="Finder 侧边栏">
            <div className="knowledge-sidebar-group">
                <p>个人收藏</p>
                <button
                    type="button"
                    className={scope === 'private' && isBrowse && !filterTagId ? 'is-active' : ''}
                    onClick={() => {
                        onScopeChange('private');
                        onViewModeChange('browse');
                        onFilterTag(null);
                    }}
                >
                    <Files size={16} className="text-blue-500" />
                    <span>我的空间</span>
                </button>
                <button
                    type="button"
                    className={viewMode === 'favorites' ? 'is-active' : ''}
                    onClick={() => onViewModeChange('favorites')}
                >
                    <Star size={16} className="fill-amber-400 text-amber-500" />
                    <span>收藏</span>
                </button>
            </div>

            <div className="knowledge-sidebar-group">
                <p>位置</p>
                <button
                    type="button"
                    className={scope === 'shared' && isBrowse ? 'is-active' : ''}
                    onClick={() => {
                        onScopeChange('shared');
                        onViewModeChange('browse');
                        onFilterTag(null);
                    }}
                >
                    <Users size={16} className="text-violet-500" />
                    <span>共享空间</span>
                </button>
                <button
                    type="button"
                    onClick={() => {
                        onScopeChange('private');
                        onViewModeChange('browse');
                    }}
                >
                    <HardDrive size={16} className="text-slate-500" />
                    <span>知识磁盘</span>
                </button>
            </div>

            <div className="knowledge-sidebar-group knowledge-sidebar-tags">
                <div className="knowledge-sidebar-heading">
                    <p>标签</p>
                    <button type="button" onClick={onOpenTagManager} title="管理标签">
                        <Tags size={13} />
                    </button>
                </div>
                {tags.length === 0 ? (
                    <span className="knowledge-sidebar-empty">还没有标签</span>
                ) : (
                    tags.slice(0, 8).map(tag => (
                        <button
                            type="button"
                            key={tag.id}
                            className={filterTagId === tag.id ? 'is-active' : ''}
                            onClick={() => {
                                onViewModeChange('browse');
                                onFilterTag(filterTagId === tag.id ? null : tag.id);
                            }}
                        >
                            <span className="knowledge-tag-dot" style={{ backgroundColor: tag.color }} />
                            <span title={tag.name}>{tag.name}</span>
                        </button>
                    ))
                )}
            </div>

            <div className="knowledge-sidebar-summary">
                <div>
                    <span className="knowledge-summary-led" />
                    知识磁盘已连接
                </div>
                <span>{itemCount} 个可见项目</span>
            </div>
        </aside>
    );
};

interface KnowledgeDockProps {
    minimized: boolean;
    canUpload: boolean;
    canCreateFolder: boolean;
    onFinder: () => void;
    onUpload: () => void;
    onNewFolder: () => void;
    onOpenPrivate: () => void;
    onOpenShared: () => void;
    onOpenFavorites: () => void;
    onOpenTags: () => void;
}

export const KnowledgeDock: React.FC<KnowledgeDockProps> = ({
    minimized,
    canUpload,
    canCreateFolder,
    onFinder,
    onUpload,
    onNewFolder,
    onOpenPrivate,
    onOpenShared,
    onOpenFavorites,
    onOpenTags,
}) => (
    <nav className="knowledge-dock" aria-label="知识中心 Dock">
        <button type="button" className="knowledge-dock-item" onClick={onFinder} data-tooltip={minimized ? '打开 Finder' : 'Finder'}>
            <span className="knowledge-dock-icon knowledge-dock-icon--finder">
                <span className="knowledge-finder-face"><i /><b /></span>
            </span>
            {!minimized && <span className="knowledge-dock-running" />}
        </button>
        <button type="button" className="knowledge-dock-item" onClick={onOpenPrivate} data-tooltip="我的空间">
            <span className="knowledge-dock-icon knowledge-dock-icon--files"><Files size={24} /></span>
        </button>
        <button type="button" className="knowledge-dock-item" onClick={onOpenShared} data-tooltip="共享空间">
            <span className="knowledge-dock-icon knowledge-dock-icon--shared"><Users size={24} /></span>
        </button>
        <span className="knowledge-dock-divider" />
        {canUpload && (
            <button type="button" className="knowledge-dock-item" onClick={onUpload} data-tooltip="上传文件">
                <span className="knowledge-dock-icon knowledge-dock-icon--upload"><Upload size={24} /></span>
            </button>
        )}
        {canCreateFolder && (
            <button type="button" className="knowledge-dock-item" onClick={onNewFolder} data-tooltip="新建文件夹">
                <span className="knowledge-dock-icon knowledge-dock-icon--folder"><FolderPlus size={24} /></span>
            </button>
        )}
        <button type="button" className="knowledge-dock-item" onClick={onOpenFavorites} data-tooltip="收藏">
            <span className="knowledge-dock-icon knowledge-dock-icon--favorite"><Star size={24} /></span>
        </button>
        <button type="button" className="knowledge-dock-item" onClick={onOpenTags} data-tooltip="标签">
            <span className="knowledge-dock-icon knowledge-dock-icon--tags"><Tags size={24} /></span>
        </button>
        <span className="knowledge-dock-divider" />
        <span className="knowledge-dock-item knowledge-dock-item--decorative" data-tooltip="知识磁盘">
            <span className="knowledge-dock-icon knowledge-dock-icon--disk"><Folder size={25} /></span>
        </span>
    </nav>
);
