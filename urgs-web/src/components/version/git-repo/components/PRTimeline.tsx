import React from 'react';
import { Avatar } from 'antd';
import { User, GitCommit, MessageSquare, CheckCircle, GitMerge } from 'lucide-react';

export interface TimelineEvent {
    id: string;
    type: 'comment' | 'commit' | 'review' | 'merge';
    user: {
        name: string;
        avatar?: string;
    };
    content?: string;
    time: string;
    sha?: string;
    status?: 'approved' | 'changes_requested' | 'commented';
}

interface PRTimelineProps {
    events: TimelineEvent[];
}

const PRTimeline: React.FC<PRTimelineProps> = ({ events }) => {
    return (
        <div className="space-y-6 relative ml-4">
            {/* Vertical Line */}
            <div className="absolute left-4 top-0 bottom-0 w-px bg-slate-200 -z-10" />

            {events.map((event) => (
                <div key={event.id} className="relative">
                    {/* Event Item */}
                    <div className="flex gap-4">
                        {/* Icon/Avatar */}
                        <div className="flex-shrink-0 bg-white">
                            {event.type === 'commit' ? (
                                <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center border border-slate-200 text-slate-500">
                                    <GitCommit size={14} />
                                </div>
                            ) : event.type === 'merge' ? (
                                <div className="w-8 h-8 rounded-full bg-purple-100 flex items-center justify-center border border-purple-200 text-purple-600">
                                    <GitMerge size={14} />
                                </div>
                            ) : (
                                <Avatar
                                    src={event.user.avatar}
                                    icon={<User size={14} />}
                                    className="border border-slate-200"
                                />
                            )}
                        </div>

                        {/* Content */}
                        <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 mb-1">
                                <span className="font-semibold text-slate-700 text-sm">{event.user.name}</span>
                                <span className="text-slate-500 text-sm">
                                    {event.type === 'commit' && '提交了代码'}
                                    {event.type === 'comment' && '发表了评论'}
                                    {event.type === 'review' && '审核了代码'}
                                    {event.type === 'merge' && '合并了拉取请求'}
                                </span>
                                <span className="text-slate-400 text-xs">{event.time}</span>
                            </div>

                            {/* Detailed Content */}
                            {event.type === 'comment' && (
                                <div className="bg-white border border-slate-200 rounded-lg p-3 text-sm text-slate-700 shadow-sm relative arrow-left">
                                    {event.content}
                                </div>
                            )}

                            {event.type === 'commit' && (
                                <div className="flex items-center gap-2 text-sm text-slate-600 font-mono bg-slate-50 px-2 py-1 rounded inline-block border border-slate-200">
                                    <GitCommit size={12} className="text-slate-400" />
                                    <span>{event.sha?.substring(0, 7)}</span>
                                    <span className="text-slate-500">- {event.content}</span>
                                </div>
                            )}

                            {event.type === 'review' && (
                                <div className="flex items-center gap-2 text-sm">
                                    {event.status === 'approved' && (
                                        <span className="text-green-600 flex items-center gap-1 font-medium">
                                            <CheckCircle size={14} /> 批准了更改
                                        </span>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            ))}
        </div>
    );
};

export default PRTimeline;
