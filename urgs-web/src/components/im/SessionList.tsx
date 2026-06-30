import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { MoreHorizontal, Trash2 } from 'lucide-react';
import { getAvatarUrl } from '../../utils/avatarUtils';

interface Session {
    key: string;
    id: number;
    peerId: number;
    chatType: number;
    name: string;
    avatar: string | null;
    message: string;
    time: string;
    unread: number;
    type: 'person' | 'group' | 'bot';
}

interface SessionListProps {
    sessions: Session[];
    activeSessionKey?: string;
    onSelectSession: (key: string) => void;
    onDeleteSession: (key: string) => void;
}

const SessionList: React.FC<SessionListProps> = ({ sessions, activeSessionKey, onSelectSession, onDeleteSession }) => {
    const [contextMenu, setContextMenu] = useState<{ x: number, y: number, sessionKey: string } | null>(null);
    const contextMenuRef = useRef<HTMLDivElement>(null);

    const handleContextMenu = (e: React.MouseEvent, sessionKey: string) => {
        e.preventDefault();
        setContextMenu({
            x: e.clientX,
            y: e.clientY,
            sessionKey
        });
    };

    const handleDelete = () => {
        if (contextMenu) {
            onDeleteSession(contextMenu.sessionKey);
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
                    key={session.key}
                    onClick={() => onSelectSession(session.key)}
                    onContextMenu={(e) => handleContextMenu(e, session.key)}
                    className={`px-4 py-3 cursor-pointer transition-colors flex gap-3 group border-l-2 ${activeSessionKey === session.key ? 'bg-white border-indigo-600' : 'border-transparent hover:bg-slate-100/50'}`}
                >
                    <div className="relative">
                        {session.avatar ? (
                            <img src={getAvatarUrl(session.avatar, session.name || session.key)} className="w-10 h-10 rounded-lg object-cover" alt={session.name} />
                        ) : (
                            <div className="w-10 h-10 rounded-lg bg-slate-200 flex items-center justify-center text-slate-500">
                                <MoreHorizontal size={20} />
                            </div>
                        )}
                        {session.unread > 0 && (
                            <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full text-[9px] font-bold text-white flex items-center justify-center ring-2 ring-white shadow-sm">
                                {session.unread}
                            </span>
                        )}
                    </div>
                    <div className="flex-1 min-w-0 flex flex-col justify-center">
                        <div className="flex justify-between items-baseline mb-0.5">
                            <h4 className={`font-medium text-[13px] truncate ${activeSessionKey === session.key ? 'text-indigo-600 font-semibold' : 'text-slate-800'}`} title={session.name}>{session.name}</h4>
                            <span className="text-[11px] text-slate-400 whitespace-nowrap ml-2">{session.time}</span>
                        </div>
                        <div className="flex justify-between items-center">
                            <p className={`text-[12px] truncate flex-1 ${session.unread > 0 ? 'text-slate-700 font-medium' : 'text-slate-500'}`}>
                                {session.message}
                            </p>
                        </div>
                    </div>
                </div>
            ))}

            {/* Context Menu - Portaled to body */}
            {contextMenu && createPortal(
                <div
                    ref={contextMenuRef}
                    className="fixed bg-white shadow-xl border border-slate-100 rounded-lg z-[9999] py-1 w-32 animate-in fade-in duration-200"
                    style={{ top: contextMenu.y, left: contextMenu.x }}
                    onClick={(e) => e.stopPropagation()}
                >
                    <button
                        onClick={handleDelete}
                        className="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                    >
                        <Trash2 size={14} />
                        <span>删除会话</span>
                    </button>
                </div>,
                document.body
            )}
        </div>
    );
};

export default SessionList;
