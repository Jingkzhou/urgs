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
            animate={{ width: isCollapsed ? 76 : 280 }}
            className="flex-shrink-0 bg-[#f0f4f9] flex flex-col h-full font-sans transition-all duration-300 relative border-r border-slate-200/40"
        >
            {/* Collapse Toggle */}
            <div className="p-4 flex items-center justify-between">
                {!isCollapsed && (
                    <button className="p-2 hover:bg-slate-200 rounded-full transition-colors text-slate-600">
                        <Menu size={20} />
                    </button>
                )}
                <button
                    onClick={() => onNewChat()}
                    className={`flex items-center justify-center gap-3 bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white rounded-2xl transition-all duration-300 shadow-md hover:shadow-lg hover:shadow-blue-500/25 ${isCollapsed ? 'w-12 h-12' : 'px-4 py-3 min-w-[120px]'}`}
                >
                    <Plus size={24} strokeWidth={2} />
                    {!isCollapsed && <span className="font-bold text-sm">新对话</span>}
                </button>
            </div>

            {/* Chat History Section */}
            <div className={`px-3 flex-1 overflow-y-auto custom-scrollbar pt-6 ${isCollapsed ? 'items-center' : ''}`}>
                {!isCollapsed && <h3 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-4 px-4">最近</h3>}
                <div className="space-y-1">
                    {sessions.map(session => (
                        <div
                            key={session.id}
                            onClick={() => onSessionSelect(session.id, session.agentId)}
                            className={`group flex items-center gap-3 px-4 py-2.5 rounded-2xl text-sm transition-all cursor-pointer relative
                                ${currentSessionId === session.id
                                    ? 'bg-[#d3e3fd] text-[#041e49] font-bold'
                                    : 'text-slate-600 hover:bg-[#e1e5ea]'
                                }`
                            }
                        >
                            <div className="flex-shrink-0">
                                <MessageSquare size={18} className={`${currentSessionId === session.id ? 'text-blue-700' : 'text-slate-400'}`} />
                            </div>

                            {!isCollapsed && (
                                <>
                                    {editingId === session.id ? (
                                        <div className="flex items-center flex-1 min-w-0 gap-1" onClick={e => e.stopPropagation()}>
                                            <input
                                                type="text"
                                                value={editTitle}
                                                onChange={(e) => setEditTitle(e.target.value)}
                                                className="w-full bg-white border-2 border-blue-400 rounded-lg px-2 py-0.5 text-xs outline-none"
                                                autoFocus
                                            />
                                            <button onClick={saveEdit} className="text-green-600 p-1"><Check size={14} /></button>
                                        </div>
                                    ) : (
                                        <>
                                            <span className="truncate flex-1 py-0.5 tracking-tight">{session.title}</span>
                                            <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                <button onClick={(e) => startEdit(e, session)} className="p-1 hover:text-blue-700 rounded-md transition-colors"><Pencil size={12} /></button>
                                                <button onClick={(e) => handleDelete(e, session.id)} className="p-1 hover:text-red-600 rounded-md transition-colors"><Trash2 size={12} /></button>
                                            </div>
                                        </>
                                    )}
                                </>
                            )}
                        </div>
                    ))}
                </div>
            </div>

            {/* Bottom Menu */}
            <div className="p-4 border-t border-slate-200/40">
                <div className="space-y-1">
                    <button className="w-full flex items-center gap-3 px-4 py-2.5 text-slate-600 hover:bg-[#e1e5ea] rounded-2xl transition-colors text-left group">
                        <History size={18} className="text-slate-400 group-hover:text-blue-600 transition-colors" />
                        {!isCollapsed && <span className="text-sm font-bold">对话详情</span>}
                    </button>
                    <button className="w-full flex items-center gap-3 px-4 py-2.5 text-slate-600 hover:bg-[#e1e5ea] rounded-2xl transition-colors text-left group">
                        <Settings size={18} className="text-slate-400 group-hover:text-blue-600 transition-colors" />
                        {!isCollapsed && <span className="text-sm font-bold">设置</span>}
                    </button>
                </div>
            </div>
        </motion.aside>
    );
};

// Helper Components
const NavItem = ({ icon, label, beta }: { icon: React.ReactNode, label: string, beta?: boolean }) => (
    <button className={`w-full flex items-center gap-3 px-3 py-[7px] text-slate-600 hover:bg-slate-100/80 rounded-lg transition-colors text-left group`}>
        <div className={`text-slate-500 group-hover:text-slate-800 transition-colors`}>
            {icon}
        </div>
        <span className={`text-sm truncate flex-1 font-medium`}>{label}</span>
        {beta && (
            <span className="w-1.5 h-1.5 rounded-full bg-slate-200 mr-1"></span>
        )}
    </button>
);

export default Sidebar;
