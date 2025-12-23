import React from 'react';
import { Button, Avatar, message } from 'antd';
import { ArrowLeft, Copy } from 'lucide-react';
import { GitCommit } from '@/api/version';
import { formatCommitTime } from '@/utils/dateUtils';

interface Props {
    commit: GitCommit;
    onBack: () => void;
}

const CommitDetail: React.FC<Props> = ({ commit, onBack }) => {

    return (
        <div className="bg-white min-h-screen">
            {/* Header */}
            <div className="border-b px-6 py-4 flex items-center justify-between sticky top-0 bg-white z-10">
                <div className="flex items-center gap-3">
                    <Button icon={<ArrowLeft size={16} />} onClick={onBack}>返回</Button>
                    <div>
                        <div className="font-bold text-lg mb-1">{commit.message}</div>
                        <div className="text-slate-500 text-xs flex items-center gap-2">
                            <Avatar size={16} src={commit.authorAvatar} style={{ backgroundColor: '#1890ff' }}>{commit.authorName?.charAt(0)}</Avatar>
                            <span className="font-medium">{commit.authorName}</span>
                            <span>提交于 {formatCommitTime(commit.committedAt)}</span>
                        </div>
                    </div>
                </div>
                <div className="flex items-center gap-2">
                    <span className="font-mono bg-slate-100 px-2 py-1 rounded text-xs text-slate-600">{commit.sha}</span>
                    <Button size="small" icon={<Copy size={12} />} onClick={() => {
                        navigator.clipboard.writeText(commit.fullSha || '');
                        message.success('已复制');
                    }} />
                    <Button size="small">浏览文件</Button>
                </div>
            </div>

            {/* Diff Content */}
            <div className="p-6 bg-slate-50 min-h-[calc(100vh-80px)]">
                <div className="max-w-5xl mx-auto space-y-4">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-lg font-bold m-0">{commit.diffs?.length || 0} 个文件发生变化</h3>
                    </div>
                    {commit.diffs?.map((diff, idx) => (
                        <div key={idx} className="bg-white border rounded-lg overflow-hidden shadow-sm">
                            <div className="px-4 py-2 bg-slate-50 border-b flex justify-between items-center">
                                <div className="flex items-center gap-2 font-mono text-sm">
                                    <span className={`px-1.5 py-0.5 rounded text-xs font-bold ${diff.newFile ? 'bg-green-100 text-green-600' :
                                        diff.deletedFile ? 'bg-red-100 text-red-600' :
                                            'bg-blue-100 text-blue-600'
                                        }`}>
                                        {diff.newFile ? 'NEW' : diff.deletedFile ? 'DEL' : 'MOD'}
                                    </span>
                                    <span className="text-slate-700">{diff.newPath || diff.oldPath}</span>
                                </div>
                                <div className="text-xs text-slate-500 flex gap-2">
                                    <span className="text-green-600">+{diff.additions}</span>
                                    <span className="text-red-600">-{diff.deletions}</span>
                                </div>
                            </div>
                            <div className="overflow-x-auto">
                                <pre className="text-xs font-mono p-4 m-0 bg-white">
                                    {diff.diff?.split('\n').map((line, i) => (
                                        <div key={i} className={`whitespace-pre-wrap ${line.startsWith('+') ? 'bg-green-50 text-green-700 block w-full px-1' :
                                            line.startsWith('-') ? 'bg-red-50 text-red-700 block w-full px-1' :
                                                line.startsWith('@@') ? 'bg-blue-50 text-blue-500 block w-full px-1 mt-2 mb-1 rounded' :
                                                    'text-slate-600 px-1'
                                            }`}>
                                            {line || ' '}
                                        </div>
                                    ))}
                                </pre>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default CommitDetail;
