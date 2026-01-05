import React, { useState, useEffect } from 'react';
import { Button, Input, Select, Form, message, Alert } from 'antd';
import { ArrowLeft, GitMerge, ArrowRight, Info } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { getRepoBranches, createPullRequest } from '@/api/version';

interface CreatePullRequestProps {
    repoId: number;
    onCancel: () => void;
    onSuccess: (id: number) => void;
}

const CreatePullRequest: React.FC<CreatePullRequestProps> = ({ repoId, onCancel, onSuccess }) => {
    const [baseBranch, setBaseBranch] = useState('main');
    const [compareBranch, setCompareBranch] = useState('');
    const [branches, setBranches] = useState<{ label: string; value: string }[]>([]);
    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');
    const [loading, setLoading] = useState(false);

    // Mock branches loading
    useEffect(() => {
        getRepoBranches(repoId).then(res => {
            if (res) {
                setBranches(res.map(b => ({ label: b.name, value: b.name })));
                if (res.length > 1) {
                    setCompareBranch(res[1].name); // Default to second branch if available
                }
            }
        });
    }, [repoId]);

    const handleCreate = async (isDraft: boolean) => {
        if (!title) {
            message.error('请输入标题');
            return;
        }
        setLoading(true);
        try {
            await createPullRequest(repoId, {
                title,
                body: description,
                head: compareBranch,
                base: baseBranch
            });
            message.success('Pull Request 创建成功');
            onSuccess(0); // ID not returned by void API or use 0 to trigger reload list
        } catch (error) {
            console.error(error);
            message.error('创建失败');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="max-w-5xl mx-auto py-6 px-4">
            <div className="mb-6">
                <Button type="text" icon={<ArrowLeft size={16} />} onClick={onCancel} className="mb-2 pl-0 hover:bg-transparent hover:text-blue-600">
                    返回列表
                </Button>
                <h1 className="text-2xl font-semibold text-slate-800">创建一个新的 Pull Request</h1>
                <p className="text-slate-500">选择分支以进行比较和合并。</p>
            </div>

            {/* Branch Selector */}
            <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 mb-8 flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <GitMerge className="text-slate-400" size={20} />
                    <div className="flex items-center gap-2">
                        <span className="text-sm text-slate-500">base:</span>
                        <Select
                            value={baseBranch}
                            onChange={setBaseBranch}
                            options={branches}
                            className="w-48"
                            showSearch
                        />
                    </div>
                    <ArrowLeft className="text-slate-400" size={16} />
                    <div className="flex items-center gap-2">
                        <span className="text-sm text-slate-500">compare:</span>
                        <Select
                            value={compareBranch}
                            onChange={setCompareBranch}
                            options={branches}
                            className="w-48"
                            showSearch
                        />
                    </div>
                </div>

                {compareBranch && baseBranch !== compareBranch ? (
                    <div className="flex items-center gap-2 text-green-600 text-sm font-medium">
                        <Info size={16} />
                        ✓ 可自动合并
                    </div>
                ) : (
                    <div className="text-slate-400 text-sm">选择不同的分支以继续</div>
                )}
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                {/* Main Form */}
                <div className="md:col-span-3 space-y-6">
                    <div className="space-y-2">
                        <label className="block text-sm font-medium text-slate-700">标题 <span className="text-red-500">*</span></label>
                        <Input
                            placeholder="简短描述您的更改"
                            size="large"
                            value={title}
                            onChange={e => setTitle(e.target.value)}
                        />
                    </div>

                    <div className="space-y-2">
                        <label className="block text-sm font-medium text-slate-700">描述 (Markdown)</label>
                        <div className="border border-slate-200 rounded-lg overflow-hidden">
                            <div className="bg-slate-50 px-2 py-1 border-b border-slate-200 text-xs text-slate-500 flex gap-2">
                                <span className="px-2 py-1 bg-white rounded shadow-sm font-medium text-slate-700">Write</span>
                                <span className="px-2 py-1 cursor-pointer hover:bg-slate-100 rounded">Preview</span>
                            </div>
                            <Input.TextArea
                                rows={10}
                                placeholder="详细描述您的更改..."
                                bordered={false}
                                className="p-4"
                                value={description}
                                onChange={e => setDescription(e.target.value)}
                            />
                            <div className="bg-white border-t border-slate-100 p-2 text-xs text-slate-400 text-right">
                                支持 Markdown 语法
                            </div>
                        </div>
                    </div>

                    <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                        {/* Split button logic could go here, for draft vs create */}
                        <Button onClick={() => handleCreate(true)}>创建为草稿</Button>
                        <Button type="primary" onClick={() => handleCreate(false)} loading={loading} className="bg-[#1a7f37] hover:bg-[#156d2e]">
                            创建 Pull Request
                        </Button>
                    </div>
                </div>

                {/* Sidebar */}
                <div className="space-y-6">
                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-sm font-medium text-slate-700 mb-2">审核人 (Reviewers)</div>
                        <Select placeholder="选择审核人" mode="multiple" className="w-full" />
                        <div className="mt-2 text-xs text-slate-500">
                            暂无建议的审核人
                        </div>
                    </div>

                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-sm font-medium text-slate-700 mb-2">指派给 (Assignees)</div>
                        <Select placeholder="指派给自己" className="w-full" />
                    </div>

                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-sm font-medium text-slate-700 mb-2">标签 (Labels)</div>
                        <Select placeholder="添加标签" mode="multiple" className="w-full" />
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CreatePullRequest;
