import React, { useState, useEffect, useMemo } from 'react';
import { Input, Button, Tag, Space, message, Modal } from 'antd';
import { Search, Tag as TagIcon, Clock, Download, Trash2, ArrowLeft } from 'lucide-react';
import { GitTag, getRepoTags } from '@/api/version';
import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';

interface Props {
    repoId: number;
    onBack?: () => void;
}

const TagList: React.FC<Props> = ({ repoId, onBack }) => {
    const [tags, setTags] = useState<GitTag[]>([]);
    const [loading, setLoading] = useState(false);
    const [searchText, setSearchText] = useState('');

    // 操作处理函数
    const handleDownload = (tag: GitTag) => {
        message.info(`正在下载标签 ${tag.name} 的源代码...`);
        // TODO: 实现下载逻辑
    };

    const handleCreateRelease = (tag: GitTag) => {
        message.info(`正在创建发行版 ${tag.name}...`);
        // TODO: 实现创建发行版逻辑
    };

    const handleDelete = (tag: GitTag) => {
        Modal.confirm({
            title: '确认删除',
            content: `确定要删除标签 "${tag.name}" 吗？此操作不可恢复。`,
            okText: '删除',
            okType: 'danger',
            cancelText: '取消',
            onOk: async () => {
                try {
                    // TODO: 实现删除API调用
                    message.success(`标签 ${tag.name} 已删除`);
                    fetchTags(); // 刷新列表
                } catch (error) {
                    message.error('删除标签失败');
                }
            },
        });
    };

    useEffect(() => {
        fetchTags();
    }, [repoId]);

    const fetchTags = async () => {
        setLoading(true);
        try {
            const data = await getRepoTags(repoId);
            setTags(data || []);
        } catch (error) {
            console.error('Failed to fetch tags', error);
            message.error('获取标签列表失败');
        } finally {
            setLoading(false);
        }
    };

    // Filter Logic
    const filteredTags = useMemo(() => {
        if (!searchText) return tags;
        const lower = searchText.toLowerCase();
        return tags.filter(t => t.name.toLowerCase().includes(lower));
    }, [tags, searchText]);

    // Render Items
    const renderTagItem = (tag: GitTag) => (
        <div key={tag.name} className="flex items-center justify-between py-3 px-4 border-b border-slate-100 hover:bg-slate-50 group transition-colors">
            <div className="flex items-center gap-3">
                <TagIcon size={16} className="text-slate-400" />
                <div>
                    <div className="flex items-center gap-2">
                        <span className="font-medium text-slate-700">{tag.name}</span>
                    </div>
                    {(tag.taggerDate || tag.taggerName) && (
                        <div className="flex items-center gap-2 text-xs text-slate-500 mt-0.5">
                            {tag.taggerName && (
                                <>
                                    <span className="font-medium text-slate-600">{tag.taggerName}</span>
                                    <span>创建于</span>
                                </>
                            )}
                            {tag.taggerDate && (
                                <span>{formatDistanceToNow(new Date(tag.taggerDate), { addSuffix: true, locale: zhCN })}</span>
                            )}
                        </div>
                    )}
                </div>
            </div>

            <div className="flex items-center gap-4">
                {/* 标签信息（悬停显示） */}
                <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    {tag.message && (
                        <span className="text-xs text-slate-400 truncate max-w-xs">{tag.message}</span>
                    )}
                    {tag.commitSha && (
                        <Tag className="text-[10px] bg-slate-100 text-slate-500 border-slate-200 font-mono">
                            {tag.commitSha.substring(0, 7)}
                        </Tag>
                    )}
                </div>

                {/* 操作按钮 */}
                <Space size="middle" className="opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                        onClick={() => handleDownload(tag)}
                        className="text-cyan-500 hover:text-cyan-600 text-sm font-medium transition-colors bg-transparent border-none cursor-pointer"
                    >
                        下载
                    </button>
                    <button
                        onClick={() => handleCreateRelease(tag)}
                        className="text-cyan-500 hover:text-cyan-600 text-sm font-medium transition-colors bg-transparent border-none cursor-pointer"
                    >
                        创建发行版
                    </button>
                    <button
                        onClick={() => handleDelete(tag)}
                        className="text-cyan-500 hover:text-cyan-600 text-sm font-medium transition-colors bg-transparent border-none cursor-pointer"
                    >
                        删除
                    </button>
                </Space>
            </div>
        </div>
    );

    return (
        <div className="bg-white min-h-screen">
            {/* Header */}
            <div className="border-b px-6 py-4 flex items-center justify-between sticky top-0 bg-white z-10 mb-4">
                <div className="flex items-center gap-3">
                    <Button
                        icon={<ArrowLeft size={16} />}
                        onClick={onBack}
                        className="flex items-center"
                    >
                        返回
                    </Button>
                    <h2 className="text-lg font-bold m-0 flex items-center gap-2">
                        <TagIcon size={20} className="text-cyan-500" />
                        标签列表 ({tags.length})
                    </h2>
                </div>
                <div className="flex items-center gap-2">
                    <Button onClick={() => fetchTags()} icon={<Clock size={14} />}>刷新</Button>
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-6">
                {/* Filter Bar */}
                <div className="flex flex-col gap-4 mb-6">
                    <div className="flex justify-between items-center">
                        <div className="flex items-center gap-3 flex-1">
                            <Input
                                prefix={<Search size={14} className="text-slate-400" />}
                                placeholder="输入标签名以搜索标签"
                                className="w-64"
                                value={searchText}
                                onChange={e => setSearchText(e.target.value)}
                            />
                            <Button type="link" onClick={() => setSearchText('')}>清空</Button>
                        </div>
                        <Space>
                            <Button onClick={() => fetchTags()} icon={<Clock size={14} />}>刷新</Button>
                        </Space>
                    </div>
                </div>

                {/* Content */}
                {loading ? (
                    <div className="py-20 text-center">加载中...</div>
                ) : (
                    <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
                        <div className="px-4 py-2 bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-500 uppercase flex justify-between items-center">
                            <span>全部标签</span>
                            <span className="text-slate-400 normal-case font-normal text-xs">{filteredTags.length} 个标签</span>
                        </div>
                        {filteredTags.length > 0 ? (
                            filteredTags.map(renderTagItem)
                        ) : (
                            <div className="p-8 text-center text-slate-400">未找到标签</div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
};

export default TagList;
