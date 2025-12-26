import React, { useState, useEffect } from 'react';
import { getAvatarUrl } from '../../utils/avatarUtils';
import { Card, Tag, Button, Avatar, Divider, Input, message, List, Space, Mentions, Tooltip } from 'antd';
import { User, Clock, Calendar, MessageSquare, Reply, ArrowLeft, Download, Paperclip, Share2, Heart, MoreVertical, Megaphone, FileText } from 'lucide-react';
import { debounce } from 'lodash';

const { Option } = Mentions;

interface Comment {
    id: string;
    userId: string;
    userName?: string;
    userAvatar?: string;
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
    const [expandedComments, setExpandedComments] = useState<Set<string>>(new Set());
    const [mentionOptions, setMentionOptions] = useState<any[]>([]);
    const [mentionLoading, setMentionLoading] = useState(false);

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
        } catch (e) { }
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
                    parentId: parentId,
                    mentionedUserIds: Array.from(replyContent.matchAll(/@([^\s#]+)#([a-zA-Z0-9]+)/g)).map(m => m[2])
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

    const handleSearchUsers = debounce(async (search: string) => {
        if (!search) {
            setMentionOptions([]);
            return;
        }
        setMentionLoading(true);
        try {
            const res = await fetch(`/api/users?keyword=${search}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (res.ok) {
                const data = await res.json();
                setMentionOptions(data);
            }
        } catch (e) {
            console.error(e);
        } finally {
            setMentionLoading(false);
        }
    }, 500);

    const toggleExpand = (commentId: string) => {
        setExpandedComments(prev => {
            const next = new Set(prev);
            if (next.has(commentId)) next.delete(commentId);
            else next.add(commentId);
            return next;
        });
    };

    if (!detail) return <div className="flex items-center justify-center py-20"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-violet-600"></div></div>;

    const renderComments = (list: Comment[], level = 0) => {
        return list.map(item => (
            <div key={item.id} className={`group ${level > 0 ? 'mt-4 pl-4 border-l-2 border-slate-100' : 'mb-8 underline-offset-8'}`}>
                <div className="flex gap-4">
                    <img
                        src={getAvatarUrl(item.userAvatar, item.userName || item.userId)}
                        className="w-10 h-10 rounded-2xl object-cover border-2 border-white shadow-sm"
                        alt={item.userName || item.userId}
                    />
                    <div className="flex-1">
                        <div className="flex items-center justify-between mb-1">
                            <span className="font-bold text-slate-800 text-sm">{item.userName || item.userId}</span>
                            <span className="text-[10px] text-slate-400 font-mono">
                                {new Date(item.createTime).toLocaleString()}
                            </span>
                        </div>
                        <p className="text-slate-600 text-sm leading-relaxed mb-2 bg-slate-50/50 p-3 rounded-2xl group-hover:bg-slate-50 transition-colors">
                            {item.content}
                        </p>

                        <div className="flex items-center gap-4">
                            <button
                                className={`text-[11px] font-bold flex items-center gap-1 transition-colors ${replyTo === item.id ? 'text-violet-600' : 'text-slate-400 hover:text-slate-600'}`}
                                onClick={() => setReplyTo(replyTo === item.id ? null : item.id)}
                            >
                                <Reply size={12} /> 回复
                            </button>
                            <button className="text-[11px] font-bold text-slate-400 hover:text-red-500 flex items-center gap-1 transition-colors">
                                <Heart size={12} /> 赞同
                            </button>
                        </div>

                        {replyTo === item.id && (
                            <div className="mt-4 flex flex-col gap-2 animate-in slide-in-from-top-2 duration-200">
                                <Mentions
                                    rows={2}
                                    autoFocus
                                    value={replyContent}
                                    onChange={setReplyContent}
                                    onSearch={handleSearchUsers}
                                    loading={mentionLoading}
                                    placeholder={`回复 ${item.userName || item.userId}...`}
                                    className="rounded-xl border-slate-200 focus:border-violet-500 min-h-[60px]"
                                    prefix={['@']}
                                >
                                    {mentionOptions.map(user => (
                                        <Option key={user.id} value={user.name + '#' + user.empId + ' '}>
                                            {user.name}
                                        </Option>
                                    ))}
                                </Mentions>
                                <div className="flex justify-end gap-2">
                                    <Button size="small" onClick={() => setReplyTo(null)} type="text">取消</Button>
                                    <Button size="small" type="primary" className="bg-violet-600" onClick={() => handleComment(item.id)}>回复</Button>
                                </div>
                            </div>
                        )}

                        {item.children && item.children.length > 0 && (
                            <div className="mt-3">
                                {expandedComments.has(item.id) ? (
                                    renderComments(item.children, level + 1)
                                ) : (
                                    <button
                                        className="text-[11px] font-bold text-violet-600 bg-violet-50 px-3 py-1 rounded-full hover:bg-violet-100 transition-colors"
                                        onClick={() => toggleExpand(item.id)}
                                    >
                                        展开 {item.children.length} 条回复
                                    </button>
                                )}
                            </div>
                        )}

                        {expandedComments.has(item.id) && (
                            <button
                                className="mt-4 text-[11px] font-bold text-slate-300 hover:text-slate-500"
                                onClick={() => toggleExpand(item.id)}
                            >
                                收起回复
                            </button>
                        )}
                    </div>
                </div>
            </div>
        ));
    };

    return (
        <div className="max-w-[1000px] mx-auto space-y-8 animate-fade-in">
            {/* 浮动返回按钮 */}
            <div className="fixed top-24 left-8 hidden xl:block">
                <button
                    onClick={onBack}
                    className="w-12 h-12 bg-white rounded-full shadow-lg border border-slate-100 flex items-center justify-center text-slate-400 hover:text-violet-600 hover:scale-110 transition-all group"
                >
                    <ArrowLeft size={20} className="group-hover:-translate-x-1 transition-transform" />
                </button>
            </div>

            <div className="flex flex-col lg:flex-row gap-8">
                {/* 主内容卡片 */}
                <div className="flex-1 space-y-8">
                    <Card variant="borderless" className="shadow-xl shadow-slate-200/50 border border-slate-100 rounded-[2.5rem] overflow-hidden bg-white">
                        {/* 详情页头部 */}
                        <div className="p-8 lg:p-12 pb-0">
                            <div className="flex items-center gap-3 mb-6">
                                <span className={`px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border ${detail.type === 'urgent' ? 'bg-red-50 text-red-600 border-red-100' :
                                    detail.type === 'update' ? 'bg-amber-50 text-amber-600 border-amber-100' :
                                        'bg-violet-50 text-violet-600 border-violet-100'
                                    }`}>
                                    {detail.type || 'Announcement'}
                                </span>
                                <span className="text-slate-300">•</span>
                                <span className="text-slate-400 text-xs font-medium">{detail.category === 'Log' ? '更新日志' : '通知公告'}</span>
                            </div>

                            <h1 className="text-3xl lg:text-4xl font-black text-slate-800 mb-8 leading-tight">
                                {detail.title}
                            </h1>

                            <div className="flex flex-wrap items-center justify-between gap-6 pb-8 border-b border-slate-50">
                                <div className="flex items-center gap-4">
                                    <div className="flex items-center gap-3 bg-slate-50 px-4 py-2 rounded-2xl border border-slate-100">
                                        <img
                                            src={getAvatarUrl(undefined, detail.createBy)}
                                            className="w-8 h-8 rounded-xl shadow-sm"
                                        />
                                        <div>
                                            <p className="text-xs font-black text-slate-700 leading-none mb-1">{detail.createBy}</p>
                                            <p className="text-[10px] text-slate-400 font-medium italic">Author</p>
                                        </div>
                                    </div>
                                    <div className="flex flex-col gap-1">
                                        <div className="flex items-center gap-2 text-slate-400">
                                            <Calendar size={14} />
                                            <span className="text-xs font-mono">{new Date(detail.createTime).toLocaleDateString()}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-slate-400">
                                            <Clock size={14} />
                                            <span className="text-xs font-mono">{new Date(detail.createTime).toLocaleTimeString()}</span>
                                        </div>
                                    </div>
                                </div>

                                <div className="flex items-center gap-2">
                                    <Tooltip title="分享">
                                        <button className="p-2.5 text-slate-400 hover:text-violet-600 hover:bg-violet-50 rounded-xl transition-all"><Share2 size={18} /></button>
                                    </Tooltip>
                                    <Tooltip title="更多">
                                        <button className="p-2.5 text-slate-400 hover:bg-slate-50 rounded-xl transition-all"><MoreVertical size={18} /></button>
                                    </Tooltip>
                                </div>
                            </div>
                        </div>

                        {/* 公告正文 */}
                        <div className="p-8 lg:p-12 prose prose-slate max-w-none prose-headings:font-black prose-p:text-slate-600 prose-p:leading-relaxed prose-img:rounded-3xl prose-a:text-violet-600">
                            <div className="content-render" dangerouslySetInnerHTML={{ __html: detail.content }} />
                        </div>

                        {/* 附件区域 */}
                        {detail.attachments && (
                            <div className="px-8 lg:px-12 pb-12">
                                <div className="bg-slate-50 rounded-3xl p-6 border border-slate-100">
                                    <h3 className="text-slate-800 font-bold mb-4 flex items-center gap-2">
                                        <Paperclip size={18} className="text-violet-500" />
                                        <span>相关附件 ({(typeof detail.attachments === 'string' ? JSON.parse(detail.attachments) : detail.attachments)?.length || 0})</span>
                                    </h3>
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                                        {(typeof detail.attachments === 'string' ? JSON.parse(detail.attachments) : detail.attachments)?.map((file: any, idx: number) => (
                                            <a
                                                key={idx}
                                                href={file.url}
                                                target="_blank"
                                                className="flex items-center justify-between p-3 bg-white rounded-2xl border border-slate-200 hover:border-violet-300 hover:shadow-md transition-all group"
                                            >
                                                <div className="flex items-center gap-3 overflow-hidden">
                                                    <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center text-slate-400">
                                                        <FileText size={16} />
                                                    </div>
                                                    <span className="text-xs font-bold text-slate-600 truncate">{file.name}</span>
                                                </div>
                                                <Download size={14} className="text-slate-300 group-hover:text-violet-500" />
                                            </a>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        )}
                    </Card>

                    {/* 评论区 */}
                    <Card variant="borderless" className="shadow-xl shadow-slate-200/40 border border-slate-100 rounded-[2.5rem] bg-white overflow-hidden">
                        <div className="p-8">
                            <div className="flex items-center gap-3 mb-8">
                                <div className="w-10 h-10 bg-violet-600 rounded-2xl flex items-center justify-center shadow-lg shadow-violet-200">
                                    <MessageSquare className="text-white" size={20} />
                                </div>
                                <div>
                                    <h2 className="text-xl font-black text-slate-800">交流评论</h2>
                                    <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">Community Discussion</p>
                                </div>
                            </div>

                            <div className="mb-10 relative">
                                <div className="absolute -top-12 right-0">
                                    <span className="text-[10px] font-black text-slate-300 bg-slate-50 px-2 py-1 rounded-full">{comments.length} COMMENTS</span>
                                </div>
                                <Mentions
                                    rows={4}
                                    placeholder="不仅是回复，更是一次温暖的互动..."
                                    value={!replyTo ? replyContent : ''}
                                    onChange={(text) => { if (!replyTo) setReplyContent(text); }}
                                    onSearch={handleSearchUsers}
                                    loading={mentionLoading}
                                    disabled={!!replyTo}
                                    prefix={['@']}
                                    className="w-full rounded-[1.5rem] border-slate-200 p-4 focus:ring-4 focus:ring-violet-500/10 focus:border-violet-500 transition-all text-sm shadow-inner bg-slate-50/30"
                                >
                                    {mentionOptions.map(user => (
                                        <Option key={user.id} value={user.name + '#' + user.empId + ' '}>
                                            {user.name}
                                        </Option>
                                    ))}
                                </Mentions>
                                <div className="mt-4 flex justify-between items-center">
                                    <div className="flex gap-2">
                                        <button className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 hover:bg-slate-200 transition-colors">@</button>
                                        <button className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 hover:bg-slate-200 transition-colors">#</button>
                                    </div>
                                    <Button
                                        type="primary"
                                        onClick={() => handleComment(null)}
                                        disabled={!!replyTo || !replyContent.trim()}
                                        className="bg-violet-600 hover:bg-violet-700 h-10 px-6 rounded-xl font-bold shadow-lg shadow-violet-200"
                                    >
                                        发布评论
                                    </Button>
                                </div>
                            </div>

                            <Divider className="border-slate-50 mb-8" />

                            <div className="space-y-4">
                                {comments.length === 0 ? (
                                    <div className="text-center py-10">
                                        <p className="text-slate-300 text-sm italic">抢占沙发，开启第一条评论...</p>
                                    </div>
                                ) : (
                                    renderComments(comments)
                                )}
                            </div>
                        </div>
                    </Card>
                </div>

                {/* 侧边辅助栏 */}
                <div className="lg:w-72 space-y-6">
                    <Card variant="borderless" className="shadow-lg border border-slate-100 rounded-3xl bg-violet-600 text-white p-6 relative overflow-hidden group">
                        <Megaphone className="absolute -bottom-4 -right-4 w-24 h-24 text-white/10 group-hover:scale-110 transition-transform duration-700" />
                        <h4 className="text-sm font-black mb-2 uppercase tracking-widest opacity-60">公告提示</h4>
                        <p className="text-xs font-medium leading-relaxed opacity-90">请所有相关人员准时参加并认真阅读公告内容，如有疑问请在下方评论区留言或联系负责人。</p>
                    </Card>

                    <Card variant="borderless" className="shadow-lg border border-slate-100 rounded-3xl bg-white p-6">
                        <h4 className="text-xs font-black text-slate-400 mb-4 uppercase tracking-widest">系统标签</h4>
                        <div className="flex flex-wrap gap-2">
                            {(() => {
                                try {
                                    const sys = typeof detail.systems === 'string' ? JSON.parse(detail.systems) : detail.systems;
                                    return Array.isArray(sys) ? sys.map(s => (
                                        <span key={s} className="px-3 py-1 bg-slate-50 text-slate-500 rounded-xl text-[10px] font-bold border border-slate-100">{s}</span>
                                    )) : <span className="text-slate-400 text-xs italic">全系统可见</span>;
                                } catch (e) {
                                    return <span className="text-slate-400 text-xs italic">全系统可见</span>;
                                }
                            })()}
                        </div>
                    </Card>
                </div>
            </div>

            {/* 列表返回提示 */}
            <div className="text-center pb-10">
                <button
                    onClick={onBack}
                    className="inline-flex items-center gap-2 text-slate-400 hover:text-violet-600 font-bold text-sm transition-colors group"
                >
                    <ArrowLeft size={16} className="group-hover:-translate-x-1 transition-transform" />
                    返回公告列表
                </button>
            </div>
        </div>
    );
};

export default AnnouncementDetail;
