import React, { useState, useEffect } from 'react';
import {
    Search, Plus, PenTool, Image, Grid, Globe, Database, Sparkles, Folder, MessageSquare,
    MoreHorizontal, Trash2, Pencil, Check, X, Menu, Settings, History
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Session, getSessions, createSession, deleteSession, saveSession } from '../../api/chat';

interface SidebarProps {
    currentSessionId: string | null;
    onSessionSelect: (id: string, agentId?: number) => void;
    onNewChat: () => void;
    refreshTrigger?: number;
}

const Sidebar: React.FC<SidebarProps> = ({ currentSessionId, onSessionSelect, onNewChat, refreshTrigger }) => {
    const [sessions, setSessions] = useState<Session[]>([]);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [editTitle, setEditTitle] = useState('');
    const [isCollapsed, setIsCollapsed] = useState(false);

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
            const { updateSession } = require('../../api/chat');
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
            initial={false}
            animate={{ width: isCollapsed ? 88 : 300 }}
            className="flex-shrink-0 bg-white flex flex-col h-full font-sans transition-all duration-500 relative border-r border-slate-100 z-[50]"
        >
            {/* Header: Logo & Interaction */}
            <div className="p-6 pb-2">
                <div className="flex items-center justify-between mb-8 overflow-hidden">
                    <AnimatePresence mode="wait">
                        {!isCollapsed && (
                            <motion.div
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                exit={{ opacity: 0, x: -10 }}
                                className="flex items-center gap-2"
                            >
                                <div className="w-8 h-8 bg-red-600 rounded-xl flex items-center justify-center shadow-lg shadow-red-500/20">
                                    <Sparkles size={16} className="text-white" strokeWidth={2.5} />
                                </div>
                                <span className="text-lg font-black tracking-tighter italic text-slate-800 uppercase">Ark / 方舟</span>
                            </motion.div>
                        )}
                    </AnimatePresence>
                    <button
                        onClick={() => setIsCollapsed(!isCollapsed)}
                        className={`p-2.5 bg-slate-100/50 hover:bg-white rounded-xl transition-all text-slate-400 hover:text-red-500 border border-transparent hover:border-slate-100 shadow-sm ${isCollapsed ? 'mx-auto' : ''}`}
                    >
                        <Menu size={18} strokeWidth={2.5} />
                    </button>
                </div>

                <button
                    onClick={() => onNewChat()}
                    className={`group relative overflow-hidden flex items-center justify-start gap-3 bg-[#f0f4f9] text-slate-700 rounded-xl transition-all duration-300 hover:bg-[#e3e8ef] active:scale-95 ${isCollapsed ? 'w-12 h-12 mx-auto justify-center' : 'w-full px-5 py-3.5'}`}
                >
                    <Plus size={20} className="text-slate-600" />
                    <AnimatePresence>
                        {!isCollapsed && (
                            <motion.span
                                initial={{ opacity: 0, width: 0 }}
                                animate={{ opacity: 1, width: 'auto' }}
                                exit={{ opacity: 0, width: 0 }}
                                className="font-medium text-[14px] whitespace-nowrap"
                            >
                                新建对话
                            </motion.span>
                        )}
                    </AnimatePresence>
                </button>
            </div>

            {/* Chat History Section */}
            <div className={`px-4 flex-1 overflow-y-auto custom-scrollbar pt-10 scroll-smooth`}>
                <AnimatePresence mode="wait">
                    {!isCollapsed && (
                        <motion.h3
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            className="text-[9px] font-black text-slate-400/70 uppercase tracking-[0.3em] mb-6 px-4"
                        >
                            最近操作
                        </motion.h3>
                    )}
                </AnimatePresence>

                <div className="space-y-2">
                    {sessions.map(session => (
                        <motion.div
                            key={session.id}
                            layout
                            onClick={() => onSessionSelect(session.id, session.agentId)}
                            className={`group flex items-center gap-3 px-5 py-2.5 rounded-full transition-all cursor-pointer relative overflow-hidden
                                ${currentSessionId === session.id
                                    ? 'bg-[#d3e3fd] text-[#041e49]'
                                    : 'hover:bg-[#f0f4f9] text-[#1f1f1f]'
                                }`
                            }
                        >
                            <div className="flex-shrink-0 relative z-10">
                                <MessageSquare size={16} strokeWidth={2} className={currentSessionId === session.id ? 'text-[#041e49]' : 'text-slate-500'} />
                            </div>

                            {!isCollapsed && (
                                <div className="flex-1 min-w-0 relative z-10">
                                    {editingId === session.id ? (
                                        <div className="flex items-center gap-1" onClick={e => e.stopPropagation()}>
                                            <input
                                                type="text"
                                                value={editTitle}
                                                onChange={(e) => setEditTitle(e.target.value)}
                                                className="w-full bg-slate-50 border-2 border-red-500/30 rounded-lg px-2 py-1 text-xs outline-none focus:border-red-500/50"
                                                autoFocus
                                            />
                                            <button onClick={saveEdit} className="text-red-600 p-1 hover:bg-red-50 rounded-lg transition-colors"><Check size={14} strokeWidth={3} /></button>
                                        </div>
                                    ) : (
                                        <div className="flex items-center justify-between">
                                            <span className={`truncate text-[14px] ${currentSessionId === session.id ? 'font-medium' : 'font-normal'}`}>
                                                {session.title}
                                            </span>
                                            <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-all">
                                                <button onClick={(e) => startEdit(e, session)} className="p-1.5 hover:bg-black/5 rounded-full transition-colors text-slate-500"><Pencil size={12} /></button>
                                                <button onClick={(e) => handleDelete(e, session.id)} className="p-1.5 hover:bg-black/5 rounded-full transition-colors text-slate-500"><Trash2 size={12} /></button>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            )}
                        </motion.div>
                    ))}
                </div>
            </div>

            {/* Bottom Menu - Premium Utilities */}
            <div className={`p-6 border-t border-slate-200/30 space-y-2`}>
                <button className="w-full flex items-center justify-center gap-4 px-4 py-3 text-slate-400 hover:text-slate-800 hover:bg-white/80 rounded-[1.25rem] transition-all group overflow-hidden">
                    <History size={18} strokeWidth={2.5} className="group-hover:rotate-[-10deg] transition-transform" />
                    {!isCollapsed && <span className="flex-1 text-left text-[11px] font-black uppercase tracking-widest">分析流</span>}
                </button>
                <button className="w-full flex items-center justify-center gap-4 px-4 py-3 text-slate-400 hover:text-slate-800 hover:bg-white/80 rounded-[1.25rem] transition-all group overflow-hidden">
                    <Settings size={18} strokeWidth={2.5} className="group-hover:rotate-[20deg] transition-transform" />
                    {!isCollapsed && <span className="flex-1 text-left text-[11px] font-black uppercase tracking-widest">操作核心</span>}
                </button>
            </div>
        </motion.aside>
    );
};

// Helper Item with refined typography
export const NavItem = ({ icon, label, active }: { icon: React.ReactNode, label: string, active?: boolean }) => (
    <button className={`w-full flex items-center gap-4 px-4 py-3 rounded-2xl transition-all group
        ${active ? 'bg-white shadow-lg shadow-black/[0.03] text-slate-900' : 'text-slate-400 hover:text-slate-700 hover:bg-white/60'}
    `}>
        <div className={`transition-colors ${active ? 'text-red-600' : 'group-hover:text-red-500'}`}>
            {icon}
        </div>
        <span className={`text-[12px] font-black uppercase tracking-wider truncate`}>{label}</span>
    </button>
);

export default Sidebar;
