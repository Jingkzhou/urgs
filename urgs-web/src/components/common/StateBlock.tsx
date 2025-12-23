import React, { ReactNode } from 'react';
import { Loader2, Inbox, AlertTriangle } from 'lucide-react';

interface StateBlockProps {
    type: 'loading' | 'empty' | 'error';
    message?: string;
    description?: string;
    icon?: ReactNode;
    className?: string;
    height?: string | number;
}

const StateBlock: React.FC<StateBlockProps> = ({
    type,
    message,
    description,
    icon,
    className = '',
    height = '400px'
}) => {
    const getDefaultContent = () => {
        switch (type) {
            case 'loading':
                return {
                    icon: <Loader2 className="w-8 h-8 text-blue-500 animate-spin" />,
                    message: '正在加载...',
                    bg: 'bg-white'
                };
            case 'empty':
                return {
                    icon: <Inbox className="w-10 h-10 text-slate-300" />,
                    message: '暂无数据',
                    bg: 'bg-slate-50'
                };
            case 'error':
                return {
                    icon: <AlertTriangle className="w-10 h-10 text-amber-500" />,
                    message: '加载失败',
                    bg: 'bg-red-50'
                };
        }
    };

    const config = getDefaultContent();
    const displayIcon = icon || config.icon;
    const displayMessage = message || config.message;

    return (
        <div
            className={`flex flex-col items-center justify-center rounded-lg border border-slate-200 ${config.bg} ${className}`}
            style={{ height }}
        >
            <div className="mb-3">{displayIcon}</div>
            <h3 className="text-slate-600 font-medium">{displayMessage}</h3>
            {description && <p className="text-slate-400 text-sm mt-1">{description}</p>}
        </div>
    );
};

export default StateBlock;
