import React, { CSSProperties, HTMLAttributes, ReactNode } from 'react';

type PageScrollMode = 'shell' | 'page' | 'none';

type AdaptiveStyle = CSSProperties & {
    '--urgs-page-max-width'?: string;
    '--urgs-sidebar-width'?: string;
};

const joinClassNames = (...values: Array<string | undefined | false>) => values.filter(Boolean).join(' ');

export const PageViewport: React.FC<HTMLAttributes<HTMLDivElement>> = ({ className, ...props }) => (
    <div
        {...props}
        className={joinClassNames('urgs-page-viewport', className)}
        data-urgs-page-viewport="true"
    />
);

interface AdaptivePageProps extends HTMLAttributes<HTMLDivElement> {
    maxWidth?: string;
    scroll?: PageScrollMode;
}

export const AdaptivePage: React.FC<AdaptivePageProps> = ({
    className,
    maxWidth = '1600px',
    scroll = 'shell',
    style,
    ...props
}) => (
    <div
        {...props}
        className={joinClassNames('urgs-adaptive-page', className)}
        data-page-scroll={scroll}
        style={{ ...style, '--urgs-page-max-width': maxWidth } as AdaptiveStyle}
    />
);

interface AdaptiveToolbarProps extends HTMLAttributes<HTMLElement> {
    leading?: ReactNode;
    actions?: ReactNode;
}

export const AdaptiveToolbar: React.FC<AdaptiveToolbarProps> = ({
    actions,
    children,
    className,
    leading,
    ...props
}) => (
    <header {...props} className={joinClassNames('urgs-adaptive-toolbar', className)}>
        {leading && <div className="urgs-adaptive-toolbar__leading">{leading}</div>}
        {children && <div className="urgs-adaptive-toolbar__content">{children}</div>}
        {actions && <div className="urgs-adaptive-toolbar__actions">{actions}</div>}
    </header>
);

interface AdaptiveSplitLayoutProps extends HTMLAttributes<HTMLDivElement> {
    sidebar: ReactNode;
    sidebarWidth?: string;
}

export const AdaptiveSplitLayout: React.FC<AdaptiveSplitLayoutProps> = ({
    children,
    className,
    sidebar,
    sidebarWidth = '280px',
    style,
    ...props
}) => (
    <div
        {...props}
        className={joinClassNames('urgs-adaptive-split', className)}
        style={{ ...style, '--urgs-sidebar-width': sidebarWidth } as AdaptiveStyle}
    >
        <aside className="urgs-adaptive-split__sidebar">{sidebar}</aside>
        <div className="urgs-adaptive-split__content">{children}</div>
    </div>
);

interface AdaptiveDataRegionProps extends HTMLAttributes<HTMLDivElement> {
    label?: string;
}

export const AdaptiveDataRegion: React.FC<AdaptiveDataRegionProps> = ({
    className,
    label = '可滚动的数据区域',
    tabIndex = 0,
    ...props
}) => (
    <div
        {...props}
        aria-label={label}
        className={joinClassNames('urgs-adaptive-data-region', className)}
        role="region"
        tabIndex={tabIndex}
    />
);

