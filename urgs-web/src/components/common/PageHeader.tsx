import React, { ReactNode } from 'react';
import { AdaptiveToolbar } from './adaptive';

interface PageHeaderProps {
    title: string;
    icon?: React.ElementType;
    extra?: ReactNode;
    className?: string;
}

const PageHeader: React.FC<PageHeaderProps> = ({ title, icon: Icon, extra, className = '' }) => {
    return (
        <AdaptiveToolbar
            className={className}
            leading={<div className="flex min-w-0 items-center gap-2">
                {Icon && <Icon className="w-6 h-6 text-slate-600" />}
                <h2 className="truncate text-xl font-bold text-slate-800" title={title}>{title}</h2>
            </div>}
            actions={extra}
        />
    );
};

export default PageHeader;
