import React, { useState, useEffect } from 'react';
import {
    MessageSquare, Trash2, Pencil, Check, SquarePen
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Session, getSessions, deleteSession, updateSession } from '../../api/chat';

interface SidebarProps {
    currentSessionId: string | null;
    onSessionSelect: (id: string, agentId?: number) => void;
    onNewChat: () => void;
    refreshTrigger?: number;
    isCollapsed: boolean;
}

const Sidebar: React.FC<SidebarProps> = ({ currentSessionId, onSessionSelect, onNewChat, refreshTrigger, isCollapsed }) => {
    const [sessions, setSessions] = useState<Session[]>([]);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [editTitle, setEditTitle] = useState('');

    const loadSessions = async () => {
        try {
            const s = await getSessions();
            setSessions(s);
        } catch (e) {
            console.error("Sidebar: loadSessions failed", e);
        }
    };

    useEffect(() => {
        loadSessions();
    }, []);

    useEffect(() => {
        loadSessions();
    }, [currentSessionId, refreshTrigger]);

    const handleDelete = async (e: React.MouseEvent, id: string) => {
        e.stopPropagation();
        if (window.confirm('确定要删除这段对话吗？')) {
            setSessions(prev => prev.filter(s => s.id !== id));
            await deleteSession(id);
            await loadSessions();
            if (id === currentSessionId) {
                onNewChat();
            }
        }
    };

    const startEdit = (e: React.MouseEvent, session: Session) => {
        e.stopPropagation();
        setEditingId(session.id);
        setEditTitle(session.title);
    };

    const saveEdit = async (e: React.MouseEvent) => {
        e.stopPropagation();
        if (editingId && editTitle.trim()) {
            await updateSession(editingId, editTitle);
            await loadSessions();
            setEditingId(null);
        }
    };

    const cancelEdit = (e: React.MouseEvent) => {
        e.stopPropagation();
        setEditingId(null);
    };

    return (
        <motion.aside
            initial={{ width: 0, opacity: 0 }}
            animate={{ width: isCollapsed ? 64 : 300, opacity: 1 }}
            exit={{ width: 0, opacity: 0 }}
            transition={{ duration: 0.22, ease: "easeInOut" }}
            className="absolute inset-y-0 left-0 z-[40] flex h-full flex-shrink-0 flex-col overflow-hidden border-r border-slate-200 bg-[#f9f9f9] font-sans shadow-xl md:relative md:inset-auto md:shadow-none"
        >
            <div className={`${isCollapsed ? 'px-2 pt-3' : 'px-4 pt-3'}`}>
                <button
                    onClick={() => onNewChat()}
                    className={`group relative flex items-center justify-start gap-3 overflow-hidden rounded-lg bg-white text-slate-700 transition-all duration-200 hover:bg-[#f0f0f0] active:scale-95 ${isCollapsed ? 'mx-auto h-10 w-10 justify-center' : 'w-full px-3 py-2.5'}`}
                    title="新建对话"
                >
                    <SquarePen size={17} />
                    <AnimatePresence>
                        {!isCollapsed && (
                            <motion.span
                                initial={{ opacity: 0, width: 0 }}
                                animate={{ opacity: 1, width: 'auto' }}
                                exit={{ opacity: 0, width: 0 }}
                                className="whitespace-nowrap text-sm font-medium"
                            >
                                新建对话
                            </motion.span>
                        )}
                    </AnimatePresence>
                </button>
            </div>

            {/* Chat History Section */}
            <div className={`${isCollapsed ? 'px-2 pt-6' : 'px-3 pt-7'} custom-scrollbar flex-1 overflow-y-auto scroll-smooth`}>
                <AnimatePresence mode="wait">
                    {!isCollapsed && (
                        <motion.h3
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            className="mb-3 px-2 text-xs font-medium text-slate-500"
                        >
                            最近对话
                        </motion.h3>
                    )}
                </AnimatePresence>

                <div className="space-y-1">
                    {sessions.map(session => (
                        <motion.div
                            key={session.id}
                            layout
                            onClick={() => onSessionSelect(session.id, session.agentId)}
                            title={isCollapsed ? session.title : undefined}
                            className={`group relative flex cursor-pointer items-center gap-3 overflow-hidden rounded-lg transition-colors
                                ${isCollapsed ? 'mx-auto h-10 w-10 justify-center px-0 py-0' : 'px-3 py-2.5'}
                                ${currentSessionId === session.id
                                    ? 'bg-[#ececec] text-[#0d0d0d]'
                                    : 'text-[#1f1f1f] hover:bg-[#f0f0f0]'
                                }`
                            }
                        >
                            {isCollapsed && (
                                <div className="relative z-10 flex-shrink-0">
                                    <MessageSquare size={16} strokeWidth={2} className={currentSessionId === session.id ? 'text-[#0d0d0d]' : 'text-slate-500'} />
                                </div>
                            )}

                            {!isCollapsed && (
                                <div className="relative z-10 min-w-0 flex-1">
                                    {editingId === session.id ? (
                                        <div className="flex items-center gap-1" onClick={e => e.stopPropagation()}>
                                            <input
                                                type="text"
                                                value={editTitle}
                                                onChange={(e) => setEditTitle(e.target.value)}
                                                className="w-full rounded-lg border border-slate-300 bg-white px-2 py-1 text-xs outline-none focus:border-slate-500"
                                                autoFocus
                                            />
                                            <button onClick={saveEdit} className="rounded-lg p-1 text-slate-700 transition-colors hover:bg-white"><Check size={14} strokeWidth={3} /></button>
                                        </div>
                                    ) : (
                                        <div className="flex items-center justify-between">
                                            <span className={`truncate text-sm ${currentSessionId === session.id ? 'font-medium' : 'font-normal'}`}>
                                                {session.title}
                                            </span>
                                            <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-all">
                                                <button onClick={(e) => startEdit(e, session)} className="rounded-md p-1.5 text-slate-500 transition-colors hover:bg-black/5"><Pencil size={12} /></button>
                                                <button onClick={(e) => handleDelete(e, session.id)} className="rounded-md p-1.5 text-slate-500 transition-colors hover:bg-black/5"><Trash2 size={12} /></button>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </div>

        </motion.aside>
    );
};

// Helper Item with refined typography
export const NavItem = ({ icon, label, active }: { icon: React.ReactNode, label: string, active?: boolean }) => (
    <button className={`group flex w-full items-center gap-4 rounded-lg px-4 py-3 transition-all
        ${active ? 'bg-white shadow-lg shadow-black/[0.03] text-slate-900' : 'text-slate-400 hover:text-slate-700 hover:bg-white/60'}
    `}>
        <div className={`transition-colors ${active ? 'text-red-600' : 'group-hover:text-red-500'}`}>
            {icon}
        </div>
        <span className={`text-[12px] font-black uppercase tracking-wider truncate`}>{label}</span>
    </button>
);

export default Sidebar;
