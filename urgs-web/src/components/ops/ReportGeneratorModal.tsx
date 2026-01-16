import React, { useState, useEffect } from 'react';
import { Modal, Button, message, Spin, Card, Tabs } from 'antd';
import { Sparkles, Copy, RefreshCw, FileText, PieChart as PieIcon, BarChart as BarChartIcon, TrendingUp } from 'lucide-react';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, Legend } from 'recharts';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import remarkBreaks from 'remark-breaks';

const STATUS_COLORS = ['#3b82f6', '#f59e0b', '#22c55e', '#ef4444'];

interface ReportGeneratorModalProps {
    open: boolean;
    onCancel: () => void;
    data: any; // The stats data
}

const ReportGeneratorModal: React.FC<ReportGeneratorModalProps> = ({ open, onCancel, data }) => {
    const [loading, setLoading] = useState(false);
    const [report, setReport] = useState('');
    const [isStreaming, setIsStreaming] = useState(false);
    const endRef = React.useRef<HTMLDivElement>(null);

    // Auto-scroll to bottom when report updates
    useEffect(() => {
        if (isStreaming) {
            endRef.current?.scrollIntoView({ behavior: 'smooth' });
        }
    }, [report, isStreaming]);

    const generateReport = async () => {
        if (!data) return;

        setLoading(true);
        setReport(''); // Clear previous report
        setIsStreaming(true);

        try {
            const token = localStorage.getItem('auth_token');
            const response = await fetch('/api/ai/chat/stream', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    systemPrompt: "你是一个专业的运维经理。请根据提供的数据生成一份格式清晰的运维工作报告。使用 Markdown 格式（标题、列表、加粗）。报告应包含：1. 概览 2. 关键指标趋势 3. 问题分布分析 4. 改进建议。",
                    userPrompt: `以下是当前的运维统计数据：\n${JSON.stringify(data, null, 2)}`
                })
            });

            if (!response.ok) {
                throw new Error('Failed to start generation');
            }

            // Set loading to false once stream starts
            setLoading(false);

            const reader = response.body?.getReader();
            const decoder = new TextDecoder();

            if (!reader) return;

            let buffer = '';

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                const chunk = decoder.decode(value, { stream: true });
                buffer += chunk;

                const lines = buffer.split('\n');
                // Keep the last line in buffer if it's potentially incomplete
                // (SSE events end with double newline, but we split by single newline here)
                // Actually simpler: process all complete lines (ending in \n), keep remainder.

                buffer = lines.pop() || '';

                for (const line of lines) {
                    const trimmedLine = line.trim();
                    if (!trimmedLine) continue;

                    if (trimmedLine.startsWith('data:')) {
                        // Handle "data: " or "data:"
                        const dataStr = trimmedLine.replace(/^data:\s?/, '').trim();
                        if (dataStr === '[DONE]') break;

                        try {
                            const parsed = JSON.parse(dataStr);
                            if (parsed.content) {
                                setReport(prev => prev + parsed.content);
                            } else if (parsed.error) {
                                message.error('生成出错: ' + parsed.error);
                            }
                        } catch (e) {
                            console.error('JSON parse error', e);
                        }
                    }
                }
            }

        } catch (error) {
            console.error('Generation failed:', error);
            message.error('生成失败，请重试');
            setLoading(false);
        } finally {
            setIsStreaming(false);
            setLoading(false);
        }
    };

    // Auto generate when opened if empty
    useEffect(() => {
        if (open && !report) {
            generateReport();
        }
    }, [open]);

    const handleCopy = () => {
        navigator.clipboard.writeText(report);
        message.success('已复制到剪贴板');
    };

    return (
        <Modal
            title={
                <div className="flex items-center gap-2">
                    <Sparkles className="w-5 h-5 text-purple-600" />
                    <span className="font-bold">AI 智能工作报告</span>
                </div>
            }
            open={open}
            onCancel={onCancel}
            width={800}
            footer={[
                <Button key="close" onClick={onCancel}>关闭</Button>,
                <Button
                    key="copy"
                    icon={<Copy size={16} />}
                    onClick={handleCopy}
                    disabled={!report}
                >
                    复制报告
                </Button>,
                <Button
                    key="regenerate"
                    type="primary"
                    icon={<RefreshCw size={16} />}
                    onClick={generateReport}
                    loading={loading || isStreaming}
                >
                    重新生成
                </Button>
            ]}
        >
            <div className="min-h-[400px] max-h-[60vh] overflow-y-auto">
                {loading && !report ? (
                    <div className="flex flex-col items-center justify-center h-full py-12 space-y-4">
                        <div className="relative">
                            <div className="absolute inset-0 bg-purple-200 rounded-full animate-ping opacity-75"></div>
                            <div className="relative bg-purple-100 p-4 rounded-full">
                                <Sparkles className="w-8 h-8 text-purple-600 animate-pulse" />
                            </div>
                        </div>
                        <p className="text-slate-500 font-medium">AI 正在分析数据并撰写报告...</p>
                    </div>
                ) : (
                    <div className="space-y-6">
                        {/* 关键图表快照 */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

                            <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                                <h4 className="text-xs font-semibold text-slate-500 mb-2 flex items-center gap-1">
                                    <TrendingUp size={12} /> 问题趋势
                                </h4>
                                <ResponsiveContainer width="100%" height={150}>
                                    <LineChart data={data?.trend}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis dataKey="period" tick={{ fontSize: 10 }} />
                                        <YAxis tick={{ fontSize: 10 }} />
                                        <Tooltip />
                                        <Line type="monotone" dataKey="count" stroke="#3b82f6" strokeWidth={2} dot={false} />
                                    </LineChart>
                                </ResponsiveContainer>
                            </div>

                            <div className="bg-slate-50 rounded-lg p-3 border border-slate-100">
                                <h4 className="text-xs font-semibold text-slate-500 mb-2 flex items-center gap-1">
                                    <PieIcon size={12} /> 处理人工时统计
                                </h4>
                                <ResponsiveContainer width="100%" height={150}>
                                    <BarChart data={data?.handlerStats} layout="vertical">
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis type="number" tick={{ fontSize: 10 }} />
                                        <YAxis dataKey="handler" type="category" tick={{ fontSize: 10 }} width={40} />
                                        <Tooltip />
                                        <Legend wrapperStyle={{ fontSize: '10px' }} />
                                        <Bar dataKey="issueCount" name="问题数" fill="#22c55e" radius={[0, 4, 4, 0]} barSize={15} />
                                        <Bar dataKey="totalWorkHours" name="工时" fill="#f59e0b" radius={[0, 4, 4, 0]} barSize={15} />
                                    </BarChart>
                                </ResponsiveContainer>
                            </div>

                            <div className="bg-slate-50 rounded-lg p-3 border border-slate-100 col-span-1 md:col-span-2">
                                <h4 className="text-xs font-semibold text-slate-500 mb-2 flex items-center gap-1">
                                    <BarChartIcon size={12} /> 归属系统分布
                                </h4>
                                <ResponsiveContainer width="100%" height={150}>
                                    <BarChart data={data?.systemStats}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis dataKey="name" tick={{ fontSize: 10 }} />
                                        <YAxis tick={{ fontSize: 10 }} />
                                        <Tooltip />
                                        <Bar dataKey="value" fill="#ec4899" radius={[4, 4, 0, 0]} />
                                    </BarChart>
                                </ResponsiveContainer>
                            </div>
                        </div>

                        <div className="prose prose-slate max-w-none border-t pt-4">
                            <ReactMarkdown remarkPlugins={[remarkGfm, remarkBreaks]}>
                                {report}
                            </ReactMarkdown>
                            {isStreaming && (
                                <span className="inline-block w-2 h-4 bg-purple-500 animate-pulse ml-1 align-middle"></span>
                            )}
                            <div ref={endRef} />
                        </div>
                    </div>
                )}
            </div>
        </Modal>
    );
};

export default ReportGeneratorModal;
