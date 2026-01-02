import React, { useState } from 'react';
import { Button, Input, Select, Avatar, message } from 'antd';
import {
    GitPullRequest,
    ArrowLeft,
    GitBranch,
    ChevronDown,
    Settings,
    User,
    Tag,
    Milestone,
    ArrowRight
} from 'lucide-react';
import { GitBranch as GitBranchType } from '@/api/version';

const { TextArea } = Input;
const { Option } = Select;

interface Props {
    repoId: number;
    branches: GitBranchType[];
    onBack: () => void;
    onSubmit?: (data: any) => void;
}

const CreatePullRequest: React.FC<Props> = ({ repoId, branches, onBack, onSubmit }) => {
    const [baseBranch, setBaseBranch] = useState('main');
    const [compareBranch, setCompareBranch] = useState('');
    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = () => {
        if (!compareBranch) {
            message.error('请选择对比分支');
            return;
        }
        if (!title) {
            message.error('请输入标题');
            return;
        }

        setLoading(true);
        // Mock submission
        setTimeout(() => {
            setLoading(false);
            message.success('Pull Request 创建成功 (Mock)');
            if (onSubmit) {
                onSubmit({ baseBranch, compareBranch, title, description });
            } else {
                onBack();
            }
        }, 1000);
    };

    const branchOptions = branches.length > 0 ? branches : [
        { name: 'main' },
        { name: 'develop' },
        { name: 'feat/new-auth' },
        { name: 'fix/login-bug' }
    ] as GitBranchType[];

    // Sidebar items
    const SidebarItem = ({ title, icon, value }: { title: string, icon: React.ReactNode, value: React.ReactNode }) => (
        <div className="border-b border-slate-100 py-4 first:pt-0">
            <div className="flex items-center justify-between text-xs font-semibold text-slate-500 mb-2 cursor-pointer hover:text-blue-600 group">
                <span className="flex items-center gap-1">
                    {title}
                </span>
                <Settings size={12} className="opacity-0 group-hover:opacity-100 transition-opacity" />
            </div>
            <div className="text-sm text-slate-700">
                {value || <span className="text-slate-400">无</span>}
            </div>
        </div>
    );

    return (
        <div className="min-h-screen bg-white">
            {/* Header */}
            <div className="border-b border-slate-200 bg-[#f6f8fa] px-4 py-4 md:px-8">
                <div className="max-w-5xl mx-auto">
                    <div className="flex items-center gap-3 mb-4">
                        <Button
                            type="text"
                            icon={<ArrowLeft size={16} />}
                            onClick={onBack}
                            className="text-slate-500 hover:text-slate-700 -ml-2"
                        />
                        <h1 className="text-xl font-normal text-slate-900 m-0">比较变更</h1>
                    </div>
                    <div className="text-sm text-slate-600 mb-4">
                        选择两个分支以查看可用的提交、更改、文件等。
                    </div>

                    {/* Branch Selector Bar */}
                    <div className="flex items-center gap-3 bg-white p-3 rounded-md border border-slate-200 shadow-sm mb-2">
                        <div className="flex items-center gap-2">
                            <GitBranch size={16} className="text-slate-400" />
                            <Select
                                value={baseBranch}
                                onChange={setBaseBranch}
                                bordered={false}
                                className="font-mono text-sm w-40 hover:bg-slate-50 rounded"
                                dropdownStyle={{ minWidth: 200 }}
                            >
                                <Option value="base" disabled className="text-slate-400 text-xs">base: <span className="text-slate-900 font-semibold">{baseBranch}</span></Option>
                                {branchOptions.map(b => (
                                    <Option key={b.name} value={b.name}>{b.name}</Option>
                                ))}
                            </Select>
                        </div>
                        <ArrowLeft size={16} className="text-slate-400 rotate-180" />
                        <div className="flex items-center gap-2">
                            <GitBranch size={16} className="text-slate-400" />
                            <Select
                                value={compareBranch}
                                onChange={setCompareBranch}
                                placeholder="选择分支..."
                                bordered={false}
                                className="font-mono text-sm w-48 hover:bg-slate-50 rounded"
                                dropdownStyle={{ minWidth: 200 }}
                            >
                                <Option value="compare" disabled className="text-slate-400 text-xs">compare: <span className="text-slate-900 font-semibold">{compareBranch || '...'}</span></Option>
                                {branchOptions.map(b => (
                                    <Option key={b.name} value={b.name}>{b.name}</Option>
                                ))}
                            </Select>
                        </div>
                    </div>
                    {compareBranch && (
                        <div className="flex items-center gap-2 text-xs text-[#1a7f37] px-1">
                            <i className="ri-check-line"></i> 可合并。这些分支可以自动合并。
                        </div>
                    )}
                </div>
            </div>

            {/* Main Content */}
            <div className="max-w-5xl mx-auto px-4 md:px-8 py-8">
                <div className="flex flex-col md:flex-row gap-8">
                    {/* Form Column */}
                    <div className="flex-1">
                        <div className="border border-slate-200 rounded-lg bg-white shadow-sm">
                            <div className="p-4 border-b border-slate-200 bg-white rounded-t-lg">
                                <Input
                                    placeholder="标题"
                                    size="large"
                                    className="text-lg font-semibold border-slate-300 mb-4"
                                    value={title}
                                    onChange={e => setTitle(e.target.value)}
                                />
                                <div className="relative">
                                    <div className="mb-2 bg-[#f6f8fa] border-b border-slate-200 -mx-4 -mt-4 px-4 py-2 text-xs font-semibold text-slate-600 flex gap-4">
                                        <span className="py-2 px-1 border-b-2 border-[#fd8c73] cursor-pointer text-slate-900">Write</span>
                                        <span className="py-2 px-1 cursor-pointer hover:text-slate-900">Preview</span>
                                    </div>
                                    <TextArea
                                        placeholder="留下评论"
                                        rows={8}
                                        className="font-mono text-sm mb-2"
                                        value={description}
                                        onChange={e => setDescription(e.target.value)}
                                        style={{ minHeight: 200 }}
                                    />
                                    <div className="text-xs text-slate-400 text-right">
                                        支持 Markdown
                                    </div>
                                </div>
                            </div>
                            <div className="p-4 bg-white rounded-b-lg flex justify-end items-center gap-4">
                                <Button onClick={onBack} className="text-slate-600">取消</Button>
                                <Button
                                    type="primary"
                                    onClick={handleSubmit}
                                    loading={loading}
                                    className="bg-[#1f883d] hover:bg-[#1a7f37] border-none font-bold h-8"
                                >
                                    创建 Pull Request
                                </Button>
                            </div>
                        </div>
                    </div>

                    {/* Sidebar Column */}
                    <div className="w-full md:w-64 flex-shrink-0">
                        <SidebarItem
                            title="审查人"
                            icon={<User size={14} />}
                            value={<span className="text-slate-500 italic">暂无审查人 - <span className="text-blue-600 cursor-pointer not-italic hover:underline">建议</span></span>}
                        />
                        <SidebarItem
                            title="指派给"
                            icon={<User size={14} />}
                            value={
                                <div className="flex items-center gap-2 cursor-pointer hover:text-blue-600">
                                    <span className="text-slate-500">指派给自己</span>
                                </div>
                            }
                        />
                        <SidebarItem
                            title="标签"
                            icon={<Tag size={14} />}
                            value={<span className="text-slate-500">无</span>}
                        />
                        <SidebarItem
                            title="项目"
                            icon={<Settings size={14} />}
                            value={<span className="text-slate-500">无</span>}
                        />
                        <SidebarItem
                            title="里程碑"
                            icon={<Milestone size={14} />}
                            value={<span className="text-slate-500">无里程碑</span>}
                        />
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CreatePullRequest;
