import React, { useState, useEffect } from 'react';
import { Button, Select, Spin, Avatar, message } from 'antd';
import { ArrowLeft, GitBranch, Copy, Code } from 'lucide-react';
import { GitCommit, GitBranch as GitBranchType, getRepoCommits } from '@/api/version';
import { formatCommitTime } from '@/utils/dateUtils';

const { Option } = Select;

interface Props {
    repoId: number;
    currentRef: string;
    branches: GitBranchType[];
    onRefChange: (ref: string) => void;
    onCommitClick: (sha: string) => void;
    onBack: () => void;
}

const CommitList: React.FC<Props> = ({ repoId, currentRef, branches, onRefChange, onCommitClick, onBack }) => {
    const [commits, setCommits] = useState<GitCommit[]>([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (repoId) {
            setLoading(true);
            getRepoCommits(repoId, { ref: currentRef })
                .then(data => setCommits(data || []))
                .catch(err => {
                    console.error('Failed to load commits', err);
                    message.error('获取提交记录失败');
                })
                .finally(() => setLoading(false));
        }
    }, [repoId, currentRef]);

    return (
        <div className="bg-white min-h-screen">
            {/* Header */}
            <div className="border-b px-6 py-4 flex items-center justify-between sticky top-0 bg-white z-10">
                <div className="flex items-center gap-3">
                    <Button icon={<ArrowLeft size={16} />} onClick={onBack}>返回</Button>
                    <h2 className="text-lg font-bold m-0">提交记录 ({commits.length})</h2>
                </div>
                <div className="flex items-center gap-3">
                    <Select value={currentRef} onChange={onRefChange} style={{ width: 140 }}>
                        {branches.map(b => (
                            <Option key={b.name} value={b.name}><GitBranch size={12} className="mr-1 inline" />{b.name}</Option>
                        ))}
                    </Select>
                </div>
            </div>

            <Spin spinning={loading}>
                <div className="p-6 max-w-4xl mx-auto">
                    <div className="relative border-l-2 border-slate-200 ml-4 space-y-8 pb-10">
                        {commits.map((commit) => (
                            <div key={commit.sha} className="relative pl-8">
                                {/* Timeline dot */}
                                <div className="absolute -left-[9px] top-1 w-4 h-4 rounded-full bg-white border-2 border-slate-300"></div>

                                <div className="bg-white border rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer group" onClick={() => onCommitClick(commit.sha)}>
                                    <div className="flex justify-between items-start mb-2">
                                        <div className="font-medium text-slate-800 text-base">{commit.message}</div>
                                        <div className="flex items-center gap-2">
                                            <span className="font-mono text-xs bg-slate-100 px-2 py-1 rounded text-slate-500 group-hover:bg-blue-50 group-hover:text-blue-600 transition-colors">
                                                {commit.sha}
                                            </span>
                                            <Button size="small" type="text" icon={<Copy size={12} />} onClick={(e) => {
                                                e.stopPropagation();
                                                navigator.clipboard.writeText(commit.sha);
                                                message.success('已复制');
                                            }} />
                                            <Button size="small" type="text" icon={<Code size={14} />} />
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-3 text-sm text-slate-500">
                                        <Avatar size={20} src={commit.authorAvatar} style={{ backgroundColor: '#f56a00' }}>
                                            {commit.authorName?.charAt(0).toUpperCase()}
                                        </Avatar>
                                        <span className="font-medium text-slate-700">{commit.authorName}</span>
                                        <span>提交于 {formatCommitTime(commit.committedAt)}</span>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </Spin>
        </div>
    );
};

export default CommitList;
