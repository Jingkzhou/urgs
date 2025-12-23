import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Modal, Button, Spin, message, List, Empty, Popconfirm, Tooltip, Dropdown, MenuProps } from 'antd';
import {
    FileTextOutlined,
    DownloadOutlined,
    DeleteOutlined,
    PlusOutlined,
    CheckCircleOutlined,
    LoadingOutlined,
    ExclamationCircleOutlined,
    RobotOutlined,
    HistoryOutlined
} from '@ant-design/icons';
import {
    getGenerateReportUrl,
    getReportHistory,
    deleteReport,
    getExportPdfUrl,
    LineageReport
} from '@/api/lineage';

interface LineageReportModalProps {
    visible: boolean;
    tableName: string;
    columnName: string;
    onClose: () => void;
}

const LineageReportModal: React.FC<LineageReportModalProps> = ({
    visible,
    tableName,
    columnName,
    onClose
}) => {
    const [generating, setGenerating] = useState(false);
    const [content, setContent] = useState('');
    const [reportId, setReportId] = useState<number | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [history, setHistory] = useState<LineageReport[]>([]);
    const [historyLoading, setHistoryLoading] = useState(false);
    const [selectedHistoryId, setSelectedHistoryId] = useState<number | null>(null);
    const eventSourceRef = useRef<EventSource | null>(null);
    const contentRef = useRef<HTMLDivElement>(null);

    // 加载历史报告
    const loadHistory = useCallback(async () => {
        if (!tableName) return;
        setHistoryLoading(true);
        try {
            const res = await getReportHistory(tableName, columnName);
            setHistory(res || []);
        } catch (e) {
            console.error('Failed to load history', e);
        } finally {
            setHistoryLoading(false);
        }
    }, [tableName, columnName]);

    // 生成报告
    const handleGenerate = useCallback(() => {
        if (!tableName || !columnName) {
            message.warning('请先选择一个字段');
            return;
        }

        if (eventSourceRef.current) {
            eventSourceRef.current.close();
        }

        setGenerating(true);
        setContent('');
        setReportId(null);
        setError(null);
        setSelectedHistoryId(null);

        const url = getGenerateReportUrl(tableName, columnName);
        const eventSource = new EventSource(url);
        eventSourceRef.current = eventSource;

        eventSource.onmessage = (event) => {
            try {
                const data = JSON.parse(event.data);

                if (data.content) {
                    setContent(prev => prev + data.content);
                    if (contentRef.current) {
                        contentRef.current.scrollTop = contentRef.current.scrollHeight;
                    }
                }

                if (data.done) {
                    setGenerating(false);
                    setReportId(data.reportId);
                    eventSource.close();
                    message.success('报告生成完成');
                    loadHistory();
                }

                if (data.error) {
                    setError(data.error);
                    setGenerating(false);
                    eventSource.close();
                }
            } catch (e) {
                if (event.data === '[DONE]') {
                    setGenerating(false);
                    eventSource.close();
                }
            }
        };

        eventSource.onerror = () => {
            if (generating) {
                setError('连接中断，请重试');
                setGenerating(false);
            }
            eventSource.close();
        };
    }, [tableName, columnName, generating, loadHistory]);

    // 查看历史报告
    const handleViewHistory = (report: LineageReport) => {
        setContent(report.reportContent);
        setReportId(report.id || null);
        setSelectedHistoryId(report.id || null);
        setError(null);
    };

    // 删除历史报告
    const handleDeleteHistory = async (id: number, e: React.MouseEvent) => {
        e.stopPropagation();
        try {
            await deleteReport(id);
            message.success('删除成功');
            if (selectedHistoryId === id) {
                setContent('');
                setReportId(null);
                setSelectedHistoryId(null);
            }
            loadHistory();
        } catch (e) {
            message.error('删除失败');
        }
    };

    // 导出 Markdown
    const handleExportMarkdown = () => {
        if (!content) return;

        try {
            const blob = new Blob([content], { type: 'text/markdown;charset=utf-8' });
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = `LineageReport_${tableName}_${columnName}_${new Date().toISOString().slice(0, 10)}.md`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
            message.success('Markdown 导出成功');
        } catch (e) {
            message.error('导出失败');
            console.error(e);
        }
    };

    // 导出菜单
    const exportItems: MenuProps['items'] = [
        {
            key: 'pdf',
            label: '导出 PDF',
            onClick: () => reportId && window.open(getExportPdfUrl(reportId), '_blank'),
        },
        {
            key: 'md',
            label: '导出 Markdown',
            onClick: handleExportMarkdown,
        }
    ];

    // 新建空白
    const handleNewReport = () => {
        setContent('');
        setReportId(null);
        setSelectedHistoryId(null);
        setError(null);
    };

    useEffect(() => {
        return () => {
            if (eventSourceRef.current) {
                eventSourceRef.current.close();
            }
        };
    }, []);

    useEffect(() => {
        if (visible) {
            loadHistory();
        }
    }, [visible, loadHistory]);

    // Markdown 渲染
    const renderMarkdown = (text: string) => {
        if (!text) return null;
        const lines = text.split('\n');
        const elements: React.ReactNode[] = [];
        let inCodeBlock = false;
        let codeContent = '';

        lines.forEach((line, index) => {
            if (line.startsWith('```')) {
                if (inCodeBlock) {
                    elements.push(
                        <pre key={`code-${index}`} className="bg-slate-800 text-slate-100 p-4 rounded-xl my-3 overflow-x-auto text-sm">
                            <code>{codeContent}</code>
                        </pre>
                    );
                    codeContent = '';
                    inCodeBlock = false;
                } else {
                    inCodeBlock = true;
                }
                return;
            }

            if (inCodeBlock) {
                codeContent += line + '\n';
                return;
            }

            if (line.startsWith('# ')) {
                elements.push(<h1 key={index} className="text-2xl font-bold mt-6 mb-3 bg-gradient-to-r from-purple-600 via-pink-500 to-orange-400 bg-clip-text text-transparent">{line.slice(2)}</h1>);
            } else if (line.startsWith('## ')) {
                elements.push(<h2 key={index} className="text-xl font-semibold mt-5 mb-2 text-slate-700 border-b border-slate-200 pb-2">{line.slice(3)}</h2>);
            } else if (line.startsWith('### ')) {
                elements.push(<h3 key={index} className="text-lg font-medium mt-4 mb-2 text-slate-600">{line.slice(4)}</h3>);
            } else if (line.startsWith('- ') || line.startsWith('* ')) {
                elements.push(<li key={index} className="ml-4 my-1 text-slate-600 list-disc">{renderInline(line.slice(2))}</li>);
            } else if (/^\d+\.\s/.test(line)) {
                elements.push(<li key={index} className="ml-4 my-1 text-slate-600 list-decimal">{renderInline(line.replace(/^\d+\.\s/, ''))}</li>);
            } else if (line.startsWith('> ')) {
                elements.push(<blockquote key={index} className="border-l-4 border-purple-400 bg-purple-50 pl-4 py-2 my-2 text-slate-600 italic">{renderInline(line.slice(2))}</blockquote>);
            } else if (line.trim()) {
                elements.push(<p key={index} className="my-2 text-slate-600 leading-relaxed">{renderInline(line)}</p>);
            }
        });

        return elements;
    };

    const renderInline = (text: string): React.ReactNode => {
        let result = text
            .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
            .replace(/`([^`]+)`/g, '<code class="bg-purple-100 px-1.5 py-0.5 rounded text-sm text-purple-700">$1</code>');
        return <span dangerouslySetInnerHTML={{ __html: result }} />;
    };

    return (
        <Modal
            title={null}
            open={visible}
            onCancel={onClose}
            width={1100}
            footer={null}
            styles={{ body: { padding: 0 }, content: { borderRadius: 16, overflow: 'hidden' } }}
            centered
        >
            <div className="flex h-[600px]">
                {/* 左侧历史 */}
                <div className="w-64 bg-gradient-to-b from-slate-50 to-slate-100 border-r border-slate-200 flex flex-col">
                    {/* 头部 */}
                    <div className="p-4 border-b border-slate-200">
                        <div className="flex items-center gap-2 mb-3">
                            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 via-pink-500 to-orange-400 flex items-center justify-center">
                                <RobotOutlined className="text-white text-lg" />
                            </div>
                            <span className="font-semibold text-slate-700">AI 血缘分析</span>
                        </div>
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            className="w-full"
                            onClick={handleNewReport}
                            style={{
                                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                                border: 'none',
                                borderRadius: 8
                            }}
                        >
                            新建分析
                        </Button>
                    </div>

                    {/* 历史列表 */}
                    <div className="flex-1 overflow-y-auto p-2">
                        <div className="text-xs text-slate-400 px-2 py-1 flex items-center gap-1">
                            <HistoryOutlined /> 历史记录
                        </div>
                        {historyLoading ? (
                            <div className="flex justify-center py-8"><Spin /></div>
                        ) : history.length === 0 ? (
                            <div className="text-center py-8 text-slate-400 text-sm">暂无历史</div>
                        ) : (
                            <List
                                size="small"
                                dataSource={history}
                                renderItem={(item) => (
                                    <div
                                        className={`p-2 rounded-lg cursor-pointer mb-1 transition-all ${selectedHistoryId === item.id
                                            ? 'bg-gradient-to-r from-purple-100 to-pink-100 border border-purple-200'
                                            : 'hover:bg-white hover:shadow-sm'
                                            }`}
                                        onClick={() => handleViewHistory(item)}
                                    >
                                        <div className="flex items-center justify-between">
                                            <div className="flex-1 min-w-0">
                                                <div className="text-sm font-medium text-slate-700 truncate">
                                                    {item.columnName}
                                                </div>
                                                <div className="text-xs text-slate-400 truncate">
                                                    {item.createTime?.slice(0, 16)}
                                                </div>
                                            </div>
                                            <Popconfirm
                                                title="删除此报告？"
                                                onConfirm={(e) => item.id && handleDeleteHistory(item.id, e as any)}
                                                onCancel={(e) => e?.stopPropagation()}
                                            >
                                                <Button
                                                    type="text"
                                                    size="small"
                                                    icon={<DeleteOutlined />}
                                                    className="text-slate-400 hover:text-red-500"
                                                    onClick={(e) => e.stopPropagation()}
                                                />
                                            </Popconfirm>
                                        </div>
                                    </div>
                                )}
                            />
                        )}
                    </div>
                </div>

                {/* 右侧内容 */}
                <div className="flex-1 flex flex-col bg-white">
                    {/* 头部信息 */}
                    <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <span className="text-slate-400 text-sm">分析目标:</span>
                            <span className="font-medium text-slate-700">{tableName}</span>
                            <span className="text-slate-300">.</span>
                            <span className="font-medium bg-gradient-to-r from-purple-600 to-pink-500 bg-clip-text text-transparent">
                                {columnName}
                            </span>
                            {reportId && (
                                <span className="flex items-center gap-1 text-green-500 text-sm">
                                    <CheckCircleOutlined /> 已保存
                                </span>
                            )}
                        </div>
                        <div className="flex gap-2">
                            {reportId && (
                                <Dropdown menu={{ items: exportItems }} placement="bottomRight">
                                    <Tooltip title="导出">
                                        <Button
                                            type="text"
                                            icon={<DownloadOutlined />}
                                        />
                                    </Tooltip>
                                </Dropdown>
                            )}
                        </div>
                    </div>

                    {/* 内容区 */}
                    <div
                        ref={contentRef}
                        className="flex-1 overflow-y-auto p-6"
                    >
                        {/* 空白状态 */}
                        {!generating && !content && !error && (
                            <div className="h-full flex flex-col items-center justify-center">
                                <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-purple-500 via-pink-500 to-orange-400 flex items-center justify-center mb-6 shadow-lg shadow-purple-200">
                                    <RobotOutlined className="text-white text-4xl" />
                                </div>
                                <h3 className="text-xl font-semibold bg-gradient-to-r from-purple-600 via-pink-500 to-orange-400 bg-clip-text text-transparent mb-2">
                                    AI 血缘影响分析
                                </h3>
                                <p className="text-slate-400 mb-6 text-center max-w-md">
                                    点击下方按钮，AI 将分析 <strong>{columnName}</strong> 字段的上下游血缘关系，生成专业的影响评估报告
                                </p>
                                <Button
                                    type="primary"
                                    size="large"
                                    icon={<RobotOutlined />}
                                    onClick={handleGenerate}
                                    loading={generating}
                                    style={{
                                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%)',
                                        border: 'none',
                                        borderRadius: 12,
                                        height: 48,
                                        paddingInline: 32,
                                        fontSize: 16,
                                        boxShadow: '0 8px 24px rgba(102, 126, 234, 0.35)'
                                    }}
                                >
                                    开始分析
                                </Button>
                            </div>
                        )}

                        {/* 生成中 */}
                        {generating && !content && (
                            <div className="h-full flex flex-col items-center justify-center">
                                <div className="relative">
                                    <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-purple-500 via-pink-500 to-orange-400 flex items-center justify-center animate-pulse">
                                        <RobotOutlined className="text-white text-3xl" />
                                    </div>
                                    <div className="absolute -bottom-1 -right-1 w-6 h-6 bg-white rounded-full flex items-center justify-center shadow">
                                        <LoadingOutlined className="text-purple-500" />
                                    </div>
                                </div>
                                <p className="text-slate-500 mt-4">AI 正在分析血缘数据...</p>
                            </div>
                        )}

                        {/* 错误 */}
                        {error && (
                            <div className="h-full flex flex-col items-center justify-center">
                                <ExclamationCircleOutlined className="text-5xl text-red-400 mb-4" />
                                <p className="text-red-500 mb-4">{error}</p>
                                <Button type="primary" onClick={handleGenerate}>重试</Button>
                            </div>
                        )}

                        {/* 报告内容 */}
                        {content && (
                            <div className="prose max-w-none">
                                {renderMarkdown(content)}
                                {generating && (
                                    <span className="inline-block w-2 h-5 bg-gradient-to-b from-purple-500 to-pink-500 rounded animate-pulse ml-1" />
                                )}
                            </div>
                        )}
                    </div>

                    {/* 底部 */}
                    {content && !generating && (
                        <div className="px-6 py-3 border-t border-slate-100 flex justify-end gap-2">
                            <Button
                                icon={<RobotOutlined />}
                                onClick={handleGenerate}
                                style={{
                                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                                    border: 'none',
                                    color: 'white',
                                    borderRadius: 8
                                }}
                            >
                                重新生成
                            </Button>
                            <Button onClick={onClose}>关闭</Button>
                        </div>
                    )}
                </div>
            </div>
        </Modal>
    );
};

export default LineageReportModal;
