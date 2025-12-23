import React, { ReactNode } from 'react';

interface PageHeaderProps {
    title: string;
    icon?: React.ElementType;
    extra?: ReactNode;
    className?: string;
}

const PageHeader: React.FC<PageHeaderProps> = ({ title, icon: Icon, extra, className = '' }) => {
    return (
        <div className={`flex justify-between items-center ${className}`}>
            <div className="flex items-center gap-2">
                {Icon && <Icon className="w-6 h-6 text-slate-600" />}
                <h2 className="text-xl font-bold text-slate-800">{title}</h2>
            </div>
            {extra && <div className="flex gap-2">{extra}</div>}
        </div>
    );
};

export default PageHeader;
