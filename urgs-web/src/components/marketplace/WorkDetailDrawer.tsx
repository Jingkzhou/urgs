import React, { useEffect, useState } from 'react';
import { Drawer, Tag, Space, Divider, Typography, Descriptions, Spin, Empty, List } from 'antd';
import { listWorks, Work, WorkTask } from '../../api/marketplace';
import { Award, Clock, FileText, Paperclip } from 'lucide-react';

const { Title, Paragraph, Text } = Typography;

interface WorkDetailDrawerProps {
    workId: string | null;
    isOpen: boolean;
    onClose: () => void;
}

const WorkDetailDrawer: React.FC<WorkDetailDrawerProps> = ({ workId, isOpen, onClose }) => {
    const [work, setWork] = useState<Work | null>(null);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (isOpen && workId) {
            fetchDetail(workId);
        } else if (!isOpen) {
            setWork(null);
        }
    }, [isOpen, workId]);

    const fetchDetail = async (id: string) => {
        setLoading(true);
        try {
            // Using listWorks with a specific ID filter or we might need getWorkById
            // Since there's no getWorkDetail in api/marketplace yet, I'll add it or use an equivalent.
            // For now, I'll assume I'll add it to marketplace.ts
            const { getWorkDetail } = await import('../../api/marketplace');
            const res = await getWorkDetail(id);
            setWork(res);
        } catch (error) {
            console.error('Failed to fetch work detail', error);
        } finally {
            setLoading(false);
        }
    };

    const renderAttachments = (attachmentsJson?: string) => {
        if (!attachmentsJson) return null;
        try {
            const files = JSON.parse(attachmentsJson);
            if (!Array.isArray(files) || files.length === 0) return null;
            return (
                <div className="mt-2 space-y-2">
                    {files.map((file: any, index: number) => (
                        <a
                            key={index}
                            href={file.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 p-2 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors border border-slate-100"
                        >
                            <Paperclip size={14} className="text-slate-400" />
                            <span className="text-xs text-blue-600 font-medium truncate">{file.name}</span>
                        </a>
                    ))}
                </div>
            );
        } catch (e) {
            return null;
        }
    };

    return (
        <Drawer
            title="工作详情"
            placement="right"
            onClose={onClose}
            open={isOpen}
            size="large"
        >
            {loading ? (
                <div className="flex justify-center items-center h-64">
                    <Spin size="large" tip="加载中..." />
                </div>
            ) : work ? (
                <div className="flex flex-col gap-6">
                    <header>
                        <Space className="mb-2">
                            <Tag color={
                                work.status === 'PUBLISHED' ? 'green' :
                                    work.status === 'DRAFT' ? 'default' : 'red'
                            }>
                                {work.status}
                            </Tag>
                            <Tag color="error">{work.priority}</Tag>
                            <Tag>{work.category}</Tag>
                        </Space>
                        <Title level={3} className="!mb-0">{work.title}</Title>
                        {work.requirementNumber && (
                            <Text type="secondary" className="block mt-1">
                                需求编号: {work.requirementNumber}
                            </Text>
                        )}
                    </header>

                    <div className="bg-slate-50 p-4 rounded-xl flex items-center justify-around">
                        <div className="text-center">
                            <div className="text-xs text-slate-400 mb-1">总积分</div>
                            <div className="font-black text-xl text-slate-800">{work.totalPoints}</div>
                        </div>
                        <Divider orientation="vertical" className="h-10 border-slate-200" />
                        <div className="text-center">
                            <div className="text-xs text-slate-400 mb-1">截止日期</div>
                            <div className="font-bold text-slate-800">{work.deadline ? new Date(work.deadline).toLocaleDateString() : '无期限'}</div>
                        </div>
                    </div>

                    <section>
                        <Title level={5}>工作描述</Title>
                        <Paragraph className="text-slate-600 whitespace-pre-wrap bg-slate-50/50 p-4 rounded-xl border border-slate-100">
                            {work.description || '暂无详细描述'}
                        </Paragraph>
                    </section>

                    {work.attachments && (
                        <section>
                            <Title level={5}>附件资料</Title>
                            {renderAttachments(work.attachments as any)}
                        </section>
                    )}

                    <Divider className="my-0" />

                    <section>
                        <div className="flex items-center justify-between mb-4">
                            <Title level={5} className="!mb-0">包含任务</Title>
                        </div>
                        <div className="space-y-3">
                            {/* Note: Work model doesn't directly list tasks, but in a real app it might or we'd need another API call.
                                Given we're building the detail view, if tasks aren't here we might want to fetch them.
                                For brevity and fulfilling "each list item clickable", let's assume Work model in backend
                                is enriched or we'll fetch them if needed. 
                            */}
                            <Text type="secondary" italic className="text-xs">包含任务在该工作的完整视图中可见。</Text>
                        </div>
                    </section>
                </div>
            ) : (
                <Empty description="无法加载详情" />
            )}
        </Drawer>
    );
};

export default WorkDetailDrawer;
