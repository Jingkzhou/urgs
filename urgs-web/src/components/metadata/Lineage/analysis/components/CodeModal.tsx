import React, { useMemo } from 'react';
import { Modal, Tooltip, Button, message } from 'antd';
import { CopyOutlined, FileTextOutlined } from '@ant-design/icons';
import hljs from 'highlight.js/lib/core';
import sql from 'highlight.js/lib/languages/sql';
import 'highlight.js/styles/atom-one-dark.css';

// Register SQL language
hljs.registerLanguage('sql', sql);

interface CodeModalProps {
    visible: boolean;
    onClose: () => void;
    code: string;
    title?: string;
    searchTerm?: string;
    linkType?: string;
    sourceFile?: string;
}

const CodeModal: React.FC<CodeModalProps> = ({
    visible,
    onClose,
    code,
    title = '源码预览',
    searchTerm = '',
    linkType,
    sourceFile
}) => {
    // Escape regex characters
    const escapeRegExp = (string: string) => {
        return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    };

    const highlightedCode = useMemo(() => {
        if (!code) return '';

        // 1. Basic Syntax Highlighting
        let html = hljs.highlight(code, { language: 'sql' }).value;

        // 2. Search Term Highlighting (if exists)
        if (searchTerm.trim()) {
            const escapedTerm = escapeRegExp(searchTerm.trim());
            const regex = new RegExp(`(${escapedTerm})(?![^<]*>)`, 'gi');
            html = html.replace(regex, '<mark class="search-current" style="background: #fcd34d; color: #000; padding: 0 2px; border-radius: 2px;">$1</mark>');
        }

        return html;
    }, [code, searchTerm]);

    const handleCopy = () => {
        navigator.clipboard.writeText(code);
        message.success('代码已复制到剪贴板');
    };

    return (
        <Modal
            title={
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <FileTextOutlined />
                    <span>{title}</span>
                    {sourceFile && (
                        <span style={{ fontSize: 12, color: '#8c8c8c', fontWeight: 'normal', marginLeft: 8 }}>
                            源文件: {sourceFile.split('/').pop()}
                        </span>
                    )}
                </div>
            }
            open={visible}
            onCancel={onClose}
            footer={[
                <Button key="copy" icon={<CopyOutlined />} onClick={handleCopy}>
                    复制
                </Button>,
                <Button key="close" type="primary" onClick={onClose}>
                    关闭
                </Button>,
            ]}
            width={800}
            centered
            styles={{
                body: { padding: 0, backgroundColor: '#282c34', minHeight: 400, position: 'relative' }
            }}
        >
            <div style={{ padding: '20px', maxHeight: '60vh', overflow: 'auto' }}>
                <pre style={{ margin: 0 }}>
                    <code
                        className="hljs sql"
                        style={{ background: 'transparent', padding: 0, fontSize: '13px', lineHeight: '1.6', fontFamily: 'monospace' }}
                        dangerouslySetInnerHTML={{ __html: highlightedCode }}
                    />
                </pre>
            </div>
        </Modal>
    );
};

export default CodeModal;
