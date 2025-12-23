import React, { useState, useEffect } from 'react';
import { Card, Tag, Button, Avatar, Divider, Input, message, List, Space } from 'antd';
import { User, Clock, Calendar, MessageSquare, Reply, ArrowLeft } from 'lucide-react';

interface Comment {
    id: string;
    userId: string;
    content: string;
    createTime: string;
    parentId?: string;
    children?: Comment[];
}

interface AnnouncementDetailProps {
    id: string;
    onBack: () => void;
}

const AnnouncementDetail: React.FC<AnnouncementDetailProps> = ({ id, onBack }) => {
    const [detail, setDetail] = useState<any>(null);
    const [comments, setComments] = useState<Comment[]>([]);
    const [loading, setLoading] = useState(false);
    const [replyContent, setReplyContent] = useState('');
    const [replyTo, setReplyTo] = useState<string | null>(null);

    const currentUser = JSON.parse(localStorage.getItem('auth_user') || '{}');
    const token = localStorage.getItem('auth_token');

    useEffect(() => {
        fetchDetail();
        fetchComments();
        markAsRead();
    }, [id]);

    const fetchDetail = async () => {
        try {
            const res = await fetch(`/api/announcement/${id}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setDetail(data);
            }
        } catch (e) {
            message.error('加载详情失败');
        }
    };

    const fetchComments = async () => {
        try {
            const res = await fetch(`/api/announcement/${id}/comments`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                // Build tree
                const map: any = {};
                const tree: Comment[] = [];
                data.forEach((c: Comment) => {
                    map[c.id] = { ...c, children: [] };
                });
                data.forEach((c: Comment) => {
                    if (c.parentId && map[c.parentId]) {
                        map[c.parentId].children.push(map[c.id]);
                    } else {
                        tree.push(map[c.id]);
                    }
                });
                setComments(tree);
            }
        } catch (e) {
            console.error(e);
        }
    };

    const markAsRead = async () => {
        try {
            await fetch(`/api/announcement/${id}/read`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'X-User-Id': encodeURIComponent(currentUser.empId || 'admin')
                }
            });
        } catch (e) {
            // ignore
        }
    };

    const handleComment = async (parentId: string | null = null) => {
        if (!replyContent.trim()) return;

        try {
            const res = await fetch(`/api/announcement/${id}/comments`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                    'X-User-Id': encodeURIComponent(currentUser.empId || 'admin')
                },
                body: JSON.stringify({
                    content: replyContent,
                    parentId: parentId
                })
            });

            if (res.ok) {
                message.success('评论成功');
                setReplyContent('');
                setReplyTo(null);
                fetchComments();
            } else {
                message.error('评论失败');
            }
        } catch (e) {
            message.error('评论出错');
        }
    };

    if (!detail) return <div>Loading...</div>;

    const renderComments = (list: Comment[], level = 0) => {
        return list.map(item => (
            <div key={item.id} className={`mb-4 ${level > 0 ? 'ml-8' : ''}`}>
                <div className="flex gap-3">
                    <Avatar style={{ backgroundColor: '#f56a00' }}>{item.userId?.[0] || 'U'}</Avatar>
                    <div className="flex-1">
                        <div className="bg-slate-50 p-3 rounded-lg">
                            <div className="flex justify-between items-center mb-1">
                                <span className="font-medium text-slate-700">{item.userId}</span>
                                <span className="text-xs text-slate-400">
                                    {new Date(item.createTime).toLocaleString()}
                                </span>
                            </div>
                            <p className="text-slate-600 mb-2">{item.content}</p>
                            <Button
                                type="link"
                                size="small"
                                className="p-0 h-auto text-slate-400 hover:text-blue-600"
                                onClick={() => setReplyTo(replyTo === item.id ? null : item.id)}
                            >
                                <Reply className="w-3 h-3 mr-1 inline" />回复
                            </Button>
                        </div>

                        {replyTo === item.id && (
                            <div className="mt-2 flex gap-2">
                                <Input.TextArea
                                    rows={2}
                                    value={replyContent}
                                    onChange={e => setReplyContent(e.target.value)}
                                    placeholder={`回复 ${item.userId}...`}
                                />
                                <Button type="primary" onClick={() => handleComment(item.id)}>发送</Button>
                            </div>
                        )}

                        {item.children && item.children.length > 0 && (
                            <div className="mt-3">
                                {renderComments(item.children, level + 1)}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        ));
    };

    return (
        <div className="space-y-4">
            <Button icon={<ArrowLeft size={16} />} onClick={onBack}>返回列表</Button>

            <Card bordered={false} className="shadow-sm">
                <div className="mb-6">
                    <h1 className="text-2xl font-bold text-slate-800 mb-4">{detail.title}</h1>
                    <div className="flex items-center gap-4 text-slate-500 text-sm">
                        <span className="flex items-center gap-1">
                            <User size={14} /> {detail.createBy}
                        </span>
                        <span className="flex items-center gap-1">
                            <Clock size={14} /> {new Date(detail.createTime).toLocaleString()}
                        </span>
                        <Tag color="blue">{detail.type}</Tag>
                    </div>
                </div>

                <div className="prose max-w-none" dangerouslySetInnerHTML={{ __html: detail.content }} />

                {detail.attachments && (
                    <div className="mt-8 pt-4 border-t border-slate-100">
                        <h3 className="font-medium mb-2">附件</h3>
                        {/* Attachment handling if needed */}
                    </div>
                )}
            </Card>

            <Card bordered={false} title={<><MessageSquare className="inline mr-2 my-auto" size={18} /> 评论区</>} className="shadow-sm">
                <div className="mb-6">
                    <Input.TextArea
                        rows={3}
                        placeholder="写下你的评论..."
                        value={!replyTo ? replyContent : ''}
                        onChange={e => {
                            if (!replyTo) setReplyContent(e.target.value);
                        }}
                        disabled={!!replyTo}
                    />
                    <div className="mt-2 text-right">
                        <Button type="primary" onClick={() => handleComment(null)} disabled={!!replyTo}>发布评论</Button>
                    </div>
                </div>

                <div className="space-y-6">
                    {renderComments(comments)}
                </div>
            </Card>
        </div>
    );
};

export default AnnouncementDetail;
