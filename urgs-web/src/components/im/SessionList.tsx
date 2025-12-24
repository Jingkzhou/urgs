import React, { useState, useEffect, useRef } from 'react';
import { MoreHorizontal, Trash2 } from 'lucide-react';
import { getAvatarUrl } from '../../utils/avatarUtils';

interface Session {
    id: number;
    name: string;
    avatar: string | null;
    message: string;
    time: string;
    unread: number;
    type: 'person' | 'group' | 'bot';
}

interface SessionListProps {
    sessions: Session[];
    activeSessionId?: number;
    onSelectSession: (id: number) => void;
    onDeleteSession: (id: number) => void;
}

const SessionList: React.FC<SessionListProps> = ({ sessions, activeSessionId, onSelectSession, onDeleteSession }) => {
    const [contextMenu, setContextMenu] = useState<{ x: number, y: number, sessionId: number } | null>(null);
    const contextMenuRef = useRef<HTMLDivElement>(null);

    const handleContextMenu = (e: React.MouseEvent, sessionId: number) => {
        e.preventDefault();
        setContextMenu({
            x: e.clientX,
            y: e.clientY,
            sessionId
        });
    };

    const handleDelete = () => {
        if (contextMenu) {
            onDeleteSession(contextMenu.sessionId);
            setContextMenu(null);
        }
    };

    // Close menu when clicking outside
    useEffect(() => {
        const handleClick = (e: MouseEvent) => {
            if (contextMenuRef.current && !contextMenuRef.current.contains(e.target as Node)) {
                setContextMenu(null);
            }
        };
        document.addEventListener('click', handleClick);
        return () => document.removeEventListener('click', handleClick);
    }, []);

    return (
        <div className="flex-1 overflow-y-auto relative">
            {sessions.map(session => (
                <div
                    key={session.id}
                    onClick={() => onSelectSession(session.id)}
                    onContextMenu={(e) => handleContextMenu(e, session.id)}
                    className={`px-4 py-3 cursor-pointer transition-colors flex gap-3 group ${activeSessionId === session.id ? 'bg-indigo-50' : 'hover:bg-slate-100'}`}
                >
                    <div className="relative">
                        {session.avatar ? (
                            <img src={getAvatarUrl(session.avatar, session.id)} className="w-10 h-10 rounded-lg object-cover" alt={session.name} />
                        ) : (
                            <div className="w-10 h-10 rounded-lg bg-slate-200 flex items-center justify-center text-slate-500">
                                <MoreHorizontal size={20} />
                            </div>
                        )}
                        {session.unread > 0 && (
                            <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full text-[10px] text-white flex items-center justify-center border-2 border-slate-50">
                                {session.unread}
                            </span>
                        )}
                    </div>
                    <div className="flex-1 min-w-0">
                        <div className="flex justify-between items-baseline mb-0.5">
                            <h4 className={`font-medium text-sm truncate ${activeSessionId === session.id ? 'text-indigo-600' : 'text-slate-800'}`}>{session.name}</h4>
                        </div>
                        <div className="flex justify-between items-center">
                            <p className={`text-xs truncate flex-1 mr-2 ${session.unread > 0 ? 'text-slate-800 font-medium' : 'text-slate-500'}`}>
                                {session.message}
                            </p>
                            <span className="text-xs text-slate-400 whitespace-nowrap">{session.time}</span>
                        </div>
                    </div>
                </div>
            ))}

            {/* Context Menu */}
            {contextMenu && (
                <div
                    ref={contextMenuRef}
                    className="fixed bg-white shadow-xl border border-slate-100 rounded-lg z-[100] py-1 w-32 animate-in fade-in duration-200"
                    style={{ top: contextMenu.y, left: contextMenu.x }}
                >
                    <button
                        onClick={handleDelete}
                        className="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                    >
                        <Trash2 size={14} />
                        <span>删除会话</span>
                    </button>
                </div>
            )}
        </div>
    );
};

export default SessionList;
