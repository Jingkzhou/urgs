import React, { ReactNode } from 'react';
import { Tag } from 'antd';
import { CheckCircle, XCircle, Clock, FileText, AlertTriangle, HelpCircle } from 'lucide-react';

export interface StatusConfig {
    color: string;
    label: string;
    icon?: ReactNode;
}

interface StatusTagProps {
    status: string;
    text?: string;
    config?: Record<string, StatusConfig>;
    className?: string;
}

const defaultStatusConfig: Record<string, StatusConfig> = {
    active: { color: 'success', label: '启用', icon: <CheckCircle size={12} /> },
    enabled: { color: 'success', label: '启用', icon: <CheckCircle size={12} /> },
    inactive: { color: 'default', label: '禁用', icon: <XCircle size={12} /> },
    disabled: { color: 'default', label: '禁用', icon: <XCircle size={12} /> },
    draft: { color: 'default', label: '草稿', icon: <FileText size={12} /> },
    pending: { color: 'processing', label: '待处理', icon: <Clock size={12} /> },
    approved: { color: 'success', label: '已通过', icon: <CheckCircle size={12} /> },
    rejected: { color: 'error', label: '已拒绝', icon: <XCircle size={12} /> },
    error: { color: 'error', label: '错误', icon: <AlertTriangle size={12} /> },
};

const StatusTag: React.FC<StatusTagProps> = ({ status, text, config = defaultStatusConfig, className = '' }) => {
    const statusInfo = config[status] || { color: 'default', label: text || status, icon: <HelpCircle size={12} /> };

    // If explicit text is provided, use it, otherwise use the label from config
    const label = text || statusInfo.label;

    return (
        <Tag color={statusInfo.color} className={`flex items-center gap-1 w-fit ${className}`}>
            {statusInfo.icon}
            <span>{label}</span>
        </Tag>
    );
};

export default StatusTag;
