import React, { useState, useEffect } from 'react';
import { Button, Tabs, Input, Avatar, Tag, Dropdown } from 'antd';
import { ArrowLeft, GitPullRequest, GitMerge, Check, X, Clock, MessageSquare, ChevronDown, MonitorCheck, ExternalLink } from 'lucide-react';
import PRStatusBadge, { PRStatus } from './components/PRStatusBadge';
import PRTimeline, { TimelineEvent } from './components/PRTimeline';
import PRDiffView from './components/PRDiffView';
import ReactMarkdown from 'react-markdown';
import { getPullRequest, GitPullRequest as APIGitPullRequest } from '@/api/version';

interface PullRequestDetailProps {
    repoId: number;
    prId: number;
    onBack: () => void;
}

const mockTimeline: TimelineEvent[] = [
    {
        id: '1',
        type: 'comment',
        user: { name: 'zhangsan', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhangsan' },
        time: '2 天前',
        content: 'There seems to be a conflict in `package.json`, please resolve it.',
    },
    {
        id: '2',
        type: 'commit',
        user: { name: 'lisi' },
        time: '1 天前',
        sha: 'a1b2c3d',
        content: 'fix: resolve merge conflicts',
    },
    {
        id: '3',
        type: 'review',
        user: { name: 'wangwu', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=wangwu' },
        time: '5 小时前',
        status: 'approved',
    }
];

const mockFiles = [
    { name: 'src/components/Login.tsx', status: 'modified' as const, additions: 24, deletions: 12, diff: '@@ -12,7 +12,7 @@\n- const Login = () => {\n+ const Login = ({ onLogin }) => {\n     const [user, setUser] = useState(null);\n...' },
    { name: 'src/utils/auth.ts', status: 'added' as const, additions: 45, deletions: 0, diff: '@@ -0,0 +1,45 @@\n+ export const checkAuth = () => {\n+     // ... implementation\n+ }' },
];

const PullRequestDetail: React.FC<PullRequestDetailProps> = ({ repoId, prId, onBack }) => {
    const [activeTab, setActiveTab] = useState('conversation');
    const [pr, setPr] = useState<APIGitPullRequest | null>(null);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        const fetchPR = async () => {
            setLoading(true);
            try {
                const res = await getPullRequest(repoId, prId);
                if (res) {
                    setPr(res);
                }
            } catch (error) {
                console.error(error);
            } finally {
                setLoading(false);
            }
        };
        fetchPR();
    }, [repoId, prId]);

    if (loading) return <div className="p-10 text-center">Loading...</div>;
    if (!pr) return <div className="p-10 text-center">Pull Request not found</div>;

    // Map status
    let status: PRStatus = 'open';
    const state = pr.state === 'opened' ? 'open' : pr.state;
    if (state === 'closed') status = 'closed';
    if (state === 'merged') status = 'merged';

    return (
        <div className="bg-white min-h-screen">
            {/* Header */}
            <div className="border-b border-slate-200 bg-slate-50/50 sticky top-0 z-10 backdrop-blur-sm">
                <div className="max-w-7xl mx-auto px-6 py-4">
                    <div className="mb-2">
                        <Button type="text" icon={<ArrowLeft size={16} />} onClick={onBack} size="small" className="text-slate-500 hover:text-slate-800 p-0">
                            返回列表
                        </Button>
                    </div>
                    <div className="flex justify-between items-start">
                        <div>
                            <div className="flex items-center gap-3 mb-2">
                                <h1 className="text-2xl font-semibold text-slate-900 m-0">{pr.title} <span className="text-slate-400 font-normal">#{pr.number}</span></h1>
                                <PRStatusBadge status={status} className="text-sm" />
                            </div>
                            <div className="flex items-center gap-2 text-slate-600 text-sm">
                                <span className="font-semibold text-slate-800">{pr.authorName}</span>
                                <span>想合并 commits 到 <span className="font-mono bg-slate-100 rounded px-1 text-slate-700">{pr.baseRef}</span></span>
                                <span>从 <span className="font-mono bg-slate-100 rounded px-1 text-slate-700">{pr.headRef}</span></span>
                            </div>
                        </div>
                        <div className="flex gap-2">
                            <Button>编辑</Button>
                            <Button danger>关闭 PR</Button>
                            <Button type="primary" className="bg-[#1a7f37] hover:bg-[#156d2e]" icon={<GitMerge size={16} />}>
                                合并 Pull Request
                            </Button>
                        </div>
                    </div>
                </div>

                {/* Tabs */}
                <div className="max-w-7xl mx-auto px-6">
                    <Tabs
                        activeKey={activeTab}
                        onChange={setActiveTab}
                        className="custom-tabs"
                        items={[
                            { label: '对话 (3)', key: 'conversation' },
                            { label: '提交 (2)', key: 'commits' },
                            { label: '文件变更 (5)', key: 'files' },
                        ]}
                    />
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-6 py-6 grid grid-cols-1 lg:grid-cols-4 gap-8">
                {/* Main Content */}
                <div className="lg:col-span-3">
                    {activeTab === 'conversation' && (
                        <div className="space-y-6">
                            {/* Description Box */}
                            <div className="border border-slate-200 rounded-lg bg-white overflow-hidden">
                                <div className="bg-slate-50 px-4 py-2 border-b border-slate-200 flex justify-between items-center">
                                    <div className="font-semibold text-slate-700 text-sm">描述</div>
                                    <Button type="text" size="small" className="text-slate-500">Edit</Button>
                                </div>
                                <div className="p-4 text-slate-800 prose prose-sm max-w-none">
                                    {/* Using description from PR */}
                                    <ReactMarkdown>{pr.body || 'No description provided.'}</ReactMarkdown>

                                </div>
                            </div>

                            {/* Timeline */}
                            <PRTimeline events={mockTimeline} />

                            {/* Comment Input */}
                            <div className="flex gap-4 mt-8 pt-6 border-t border-slate-200">
                                <Avatar size="large" className="mt-1">ME</Avatar>
                                <div className="flex-1">
                                    <div className="border border-slate-200 rounded-lg shadow-sm bg-white focus-within:ring-2 focus-within:ring-blue-100 focus-within:border-blue-400 transition-all overflow-hidden">
                                        <div className="bg-slate-50 border-b border-slate-200 px-2 py-1 flex gap-2 text-xs">
                                            <button className="px-2 py-1 font-medium text-slate-700 bg-white rounded shadow-sm">Write</button>
                                            <button className="px-2 py-1 text-slate-500 hover:bg-slate-100 rounded">Preview</button>
                                        </div>
                                        <Input.TextArea
                                            rows={4}
                                            placeholder="留下评论..."
                                            bordered={false}
                                            className="p-3"
                                        />
                                        <div className="flex justify-end p-2 bg-slate-50 border-t border-slate-200">
                                            <Button type="primary" className="bg-[#1a7f37]">Comment</Button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}

                    {activeTab === 'files' && (
                        <PRDiffView files={mockFiles} />
                    )}

                    {activeTab === 'commits' && (
                        <div className="border border-slate-200 rounded-lg overflow-hidden divide-y divide-slate-100">
                            {/* Mock Commits Table */}
                            {[1, 2].map(i => (
                                <div key={i} className="p-4 hover:bg-slate-50 flex justify-between items-center group">
                                    <div className="flex items-center gap-3">
                                        <GitPullRequest className="text-slate-400" size={16} />
                                        <div>
                                            <div className="font-medium text-slate-700">feat: update auth logic</div>
                                            <div className="text-xs text-slate-500">zhangsan committed 2 days ago</div>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2 font-mono text-sm text-slate-500">
                                        <span>a1b2c3d</span>
                                        <Button size="small" type="text" icon={<ExternalLink size={14} />} className="opacity-0 group-hover:opacity-100" />
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Sidebar */}
                <div className="space-y-6 text-sm">
                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            Reviewers
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">Edit</span>
                        </div>
                        <div className="flex items-center gap-2 mb-2">
                            <span className="w-2 h-2 rounded-full bg-orange-400"></span>
                            <span className="font-medium">wangwu</span>
                            <span className="text-slate-400 ml-auto flex items-center gap-1"><MonitorCheck size={12} /> Pending</span>
                        </div>
                    </div>

                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            Assignees
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">Edit</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <Avatar size={20}>ZS</Avatar>
                            <span>zhangsan</span>
                        </div>
                    </div>

                    <div className="pb-4 border-b border-slate-100">
                        <div className="text-slate-500 font-medium mb-2 flex justify-between items-center group">
                            Labels
                            <span className="text-blue-600 opacity-0 group-hover:opacity-100 cursor-pointer text-xs">Edit</span>
                        </div>
                        <div className="flex flex-wrap gap-1">
                            <Tag color="blue">backend</Tag>
                            <Tag color="cyan">feature</Tag>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default PullRequestDetail;
