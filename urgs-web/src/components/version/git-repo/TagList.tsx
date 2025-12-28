import React, { useState, useEffect, useMemo } from 'react';
import { Input, Button, Tag, Space, message, Modal, Select } from 'antd';
import { Search, Tag as TagIcon, Clock, Download, Trash2, ArrowLeft, Plus, Hash, Type, FileText } from 'lucide-react';
import { GitTag, getRepoTags, createRepoTag, getRepoBranches, deleteRepoTag, downloadRepoArchive } from '@/api/version';
import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';

interface Props {
    repoId: number;
    onBack?: () => void;
}

const TagList: React.FC<Props> = ({ repoId, onBack }) => {
    const [tags, setTags] = useState<GitTag[]>([]);
    const [branches, setBranches] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [searchText, setSearchText] = useState('');

    // Create Tag State
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
    const [newTagName, setNewTagName] = useState('');
    const [targetRef, setTargetRef] = useState('');
    const [tagMessage, setTagMessage] = useState('');
    const [createLoading, setCreateLoading] = useState(false);

    // 操作处理函数
    const handleDownload = async (tag: GitTag) => {
        const hide = message.loading(`正在下载 ${tag.name}...`, 0);
        try {
            const blob = await downloadRepoArchive(repoId, tag.name);
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = `${tag.name}.zip`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            window.URL.revokeObjectURL(url);

            hide();
            message.success(`已开始下载 ${tag.name}`);
        } catch (error) {
            hide();
            message.error(`下载失败: ${error instanceof Error ? error.message : '未知错误'}`);
        }
    };

    const handleCreateRelease = (tag: GitTag) => {
        message.info(`正在创建发行版 ${tag.name}...`);
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
                    await deleteRepoTag(repoId, tag.name);
                    message.success(`标签 ${tag.name} 已删除`);
                    fetchTags();
                } catch (error) {
                    message.error('删除标签失败: ' + (error instanceof Error ? error.message : '未知错误'));
                }
            },
        });
    };

    const handleCreateTag = async () => {
        if (!newTagName.trim()) {
            message.warning('请输入标签名称');
            return;
        }
        if (!targetRef) {
            message.warning('请选择目标分支或提交');
            return;
        }

        setCreateLoading(true);
        try {
            await createRepoTag(repoId, newTagName, targetRef, tagMessage);
            message.success('标签创建成功');
            setIsCreateModalOpen(false);
            setNewTagName('');
            setTagMessage('');
            fetchTags();
        } catch (error) {
            console.error('Failed to create tag', error);
            message.error('创建标签失败: ' + (error instanceof Error ? error.message : '未知错误'));
        } finally {
            setCreateLoading(false);
        }
    };

    useEffect(() => {
        fetchTags();
        fetchBranches();
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

    const fetchBranches = async () => {
        try {
            const data = await getRepoBranches(repoId);
            setBranches(data || []);
            if (data && data.length > 0) {
                const defaultB = data.find(item => item.isDefault) || data[0];
                setTargetRef(defaultB.name);
            }
        } catch (error) {
            console.error('Failed to fetch branches', error);
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
        <div key={tag.name} className="flex items-center justify-between py-4 px-6 border-b border-slate-100 hover:bg-slate-50 group transition-all duration-200">
            <div className="flex items-center gap-4">
                <div className="w-10 h-10 rounded-full bg-cyan-50 flex items-center justify-center text-cyan-500 group-hover:bg-cyan-100 transition-colors">
                    <TagIcon size={20} />
                </div>
                <div>
                    <div className="flex items-center gap-2">
                        <span className="font-bold text-slate-800 text-base">{tag.name}</span>
                        {tag.commitSha && (
                            <span className="text-[10px] font-mono bg-slate-100 text-slate-500 px-1.5 py-0.5 rounded border border-slate-200">
                                {tag.commitSha.substring(0, 7)}
                            </span>
                        )}
                    </div>
                    {(tag.taggerDate || tag.taggerName) && (
                        <div className="flex items-center gap-3 text-xs text-slate-400 mt-1">
                            <span className="flex items-center gap-1">
                                <Clock size={12} />
                                {tag.taggerDate ? formatDistanceToNow(new Date(tag.taggerDate), { addSuffix: true, locale: zhCN }) : '未知时间'}
                            </span>
                            {tag.taggerName && (
                                <span className="flex items-center gap-1">
                                    <div className="w-4 h-4 rounded-full bg-slate-200" />
                                    {tag.taggerName}
                                </span>
                            )}
                        </div>
                    )}
                </div>
            </div>

            <div className="flex items-center gap-6">
                {tag.message && (
                    <span className="text-sm text-slate-500 italic max-w-xs truncate hidden md:block">
                        "{tag.message}"
                    </span>
                )}

                <Space size="middle" className="opacity-0 group-hover:opacity-100 transition-all transform translate-x-2 group-hover:translate-x-0">
                    <Button type="text" size="small" icon={<Download size={14} />} onClick={() => handleDownload(tag)} className="text-slate-400 hover:text-cyan-600">下载</Button>
                    <Button type="text" size="small" icon={<FileText size={14} />} onClick={() => handleCreateRelease(tag)} className="text-slate-400 hover:text-cyan-600">发行版</Button>
                    <Button type="text" size="small" icon={<Trash2 size={14} />} danger onClick={() => handleDelete(tag)}>删除</Button>
                </Space>
            </div>
        </div>
    );

    return (
        <div className="bg-white min-h-screen">
            {/* Header - Advanced HUD style */}
            <div className="border-b px-8 py-5 flex items-center justify-between sticky top-0 bg-white/80 backdrop-blur-md z-10 mb-6">
                <div className="flex items-center gap-4">
                    <Button
                        type="text"
                        icon={<ArrowLeft size={18} />}
                        onClick={onBack}
                        className="hover:bg-slate-100 rounded-full w-10 h-10 flex items-center justify-center p-0"
                    />
                    <div>
                        <h2 className="text-xl font-black text-slate-900 m-0 tracking-tight flex items-center gap-2">
                            <TagIcon size={24} className="text-cyan-500" />
                            TAGS
                        </h2>
                        <span className="text-[10px] text-slate-400 uppercase font-bold tracking-widest leading-none">
                            Repository Asset Management
                        </span>
                    </div>
                </div>

                <div className="flex items-center gap-3">
                    <div className="px-3 py-1 bg-slate-50 rounded-full border border-slate-100 text-xs text-slate-500 font-medium">
                        Total {tags.length}
                    </div>
                    <Button
                        onClick={() => fetchTags()}
                        icon={<Clock size={16} />}
                        className="border-slate-200 hover:text-cyan-600"
                    >
                        刷新
                    </Button>
                    <Button
                        type="primary"
                        className="bg-cyan-600 hover:bg-cyan-700 border-none shadow-lg shadow-cyan-100 flex items-center gap-2 h-10 px-6 font-bold"
                        icon={<Plus size={18} />}
                        onClick={() => setIsCreateModalOpen(true)}
                    >
                        创建标签
                    </Button>
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-8">
                {/* Search Bar - Minimalist Focus */}
                <div className="mb-8">
                    <div className="relative group max-w-md">
                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                            <Search size={18} className="text-slate-400 group-focus-within:text-cyan-500 transition-colors" />
                        </div>
                        <input
                            type="text"
                            placeholder="搜索版本标签..."
                            className="block w-full pl-11 pr-4 py-3 bg-slate-50 border border-slate-200 rounded-2xl text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-cyan-500/20 focus:border-cyan-500 focus:bg-white transition-all shadow-sm"
                            value={searchText}
                            onChange={e => setSearchText(e.target.value)}
                        />
                        {searchText && (
                            <button
                                onClick={() => setSearchText('')}
                                className="absolute inset-y-0 right-0 pr-4 flex items-center text-slate-400 hover:text-slate-600"
                            >
                                <span className="text-xs font-bold bg-slate-200/50 hover:bg-slate-200 px-1.5 py-0.5 rounded transition-colors uppercase">Clear</span>
                            </button>
                        )}
                    </div>
                </div>

                {/* Content Area */}
                <div className="bg-white border border-slate-200 rounded-[24px] overflow-hidden shadow-sm shadow-slate-100/50 flex flex-col mb-12">
                    <div className="px-6 py-4 bg-slate-50/50 border-b border-slate-100 flex justify-between items-center">
                        <h3 className="text-xs font-black text-slate-400 uppercase tracking-widest m-0">All Versions</h3>
                        <div className="h-1 w-12 bg-cyan-200 rounded-full" />
                    </div>

                    {loading ? (
                        <div className="py-24 text-center">
                            <div className="animate-spin inline-block w-8 h-8 border-[3px] border-current border-t-transparent text-cyan-500 rounded-full" role="status">
                                <span className="sr-only">加载中...</span>
                            </div>
                            <p className="mt-4 text-sm text-slate-400 font-medium">唤取星海中的标签数据...</p>
                        </div>
                    ) : filteredTags.length > 0 ? (
                        <div className="divide-y divide-slate-50">
                            {filteredTags.map(renderTagItem)}
                        </div>
                    ) : (
                        <div className="py-32 text-center flex flex-col items-center">
                            <div className="w-16 h-16 bg-slate-50 rounded-3xl flex items-center justify-center text-slate-200 mb-4 border border-slate-100">
                                <TagIcon size={32} />
                            </div>
                            <h4 className="text-slate-800 font-bold m-0">未发现标签</h4>
                            <p className="text-slate-400 text-sm mt-1 max-w-[200px]">当前搜索条件下没有找到任何匹配的版本记录</p>
                        </div>
                    )}
                </div>

                {/* Create Modal - SKILL based Premium UI */}
                <Modal
                    title={null}
                    open={isCreateModalOpen}
                    onCancel={() => setIsCreateModalOpen(false)}
                    footer={null}
                    closeIcon={null}
                    width={500}
                    centered
                >
                    <div className="bg-white rounded-3xl overflow-hidden">
                        <div className="bg-slate-900 p-8 text-white relative overflow-hidden">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-cyan-500/20 blur-3xl rounded-full translate-x-10 -translate-y-10" />
                            <div className="absolute bottom-0 left-0 w-24 h-24 bg-blue-500/10 blur-2xl rounded-full -translate-x-10 translate-y-10" />

                            <TagIcon size={40} className="text-cyan-400 mb-4 relative z-10" />
                            <h2 className="text-2xl font-black m-0 relative z-10 uppercase tracking-tight">Create New Tag</h2>
                            <p className="text-slate-400 text-sm mt-1 mb-0 relative z-10">
                                锁定当前提交点，建立永久的版本航标
                            </p>
                        </div>

                        <div className="p-8 space-y-6 bg-white">
                            <div>
                                <label className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2">
                                    <Type size={12} className="text-cyan-500" /> Tag Name
                                </label>
                                <input
                                    type="text"
                                    placeholder="例如: v1.0.0-stable"
                                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-cyan-500/20 focus:border-cyan-500 focus:bg-white transition-all hover:border-slate-300"
                                    value={newTagName}
                                    onChange={e => setNewTagName(e.target.value)}
                                />
                            </div>

                            <div className="flex gap-4">
                                <div className="flex-1">
                                    <label className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2">
                                        <Hash size={12} className="text-cyan-500" /> Target Reference
                                    </label>
                                    <Select
                                        className="w-full h-12 custom-premium-select-fix"
                                        placeholder="选择分支或输入SHA"
                                        value={targetRef}
                                        onChange={setTargetRef}
                                        options={branches.map(b => ({ label: b.name, value: b.name }))}
                                        showSearch
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="flex items-center gap-2 text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2">
                                    <FileText size={12} className="text-cyan-500" /> Annotation Message
                                </label>
                                <textarea
                                    placeholder="输入该版本的发布描述 (可选)..."
                                    rows={3}
                                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-cyan-500/20 focus:border-cyan-500 focus:bg-white transition-all hover:border-slate-300 resize-none"
                                    value={tagMessage}
                                    onChange={e => setTagMessage(e.target.value)}
                                />
                            </div>

                            <div className="flex gap-4 pt-4">
                                <Button
                                    className="flex-1 h-12 rounded-xl text-slate-600 font-bold hover:bg-slate-100 border-none bg-slate-50"
                                    onClick={() => setIsCreateModalOpen(false)}
                                >
                                    Cancel
                                </Button>
                                <Button
                                    type="primary"
                                    loading={createLoading}
                                    className="flex-[2] h-12 rounded-xl bg-slate-900 border-none shadow-xl shadow-slate-200 font-bold text-white hover:bg-black"
                                    onClick={handleCreateTag}
                                >
                                    DEPLOY TAG
                                </Button>
                            </div>
                        </div>
                    </div>
                </Modal>
            </div>

            <style dangerouslySetInnerHTML={{
                __html: `
                .premium-modal-wrap .ant-modal-content {
                    padding: 0 !important;
                    background: transparent !important;
                    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25) !important;
                }
                .custom-premium-select-fix.ant-select .ant-select-selector {
                    border-radius: 12px !important;
                    border: 1px solid #e2e8f0 !important;
                    background-color: #f8fafc !important;
                    height: 48px !important;
                    padding-top: 8px !important;
                }
                .custom-premium-select-fix.ant-select-focused .ant-select-selector {
                    border-color: #0891b2 !important;
                    background-color: #fff !important;
                    box-shadow: 0 0 0 4px rgba(8, 145, 178, 0.1) !important;
                }
            ` }} />
        </div>
    );
};

export default TagList;
