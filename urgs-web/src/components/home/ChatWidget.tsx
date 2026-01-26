import React, { useState, useRef, useEffect } from 'react';
import { getAvatarUrl } from '../../utils/avatarUtils';
import { MessageCircle, X, Search, Plus, Minus } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import SessionList from '../im/SessionList';
import ChatWindow from '../im/ChatWindow';
import { imService } from '../../services/imService';
import { userService } from '../../services/userService';
import { WS_URL } from '../../config';
const ChatWidget: React.FC = () => {
    const [isOpen, setIsOpen] = useState(false);
    const [activeSessionId, setActiveSessionId] = useState<number | null>(null);
    const [sessions, setSessions] = useState<any[]>([]); // Should use Session interface
    const [messages, setMessages] = useState<Record<string, any[]>>({}); // keyed by conversationId

    const [currentUser, setCurrentUser] = useState<any>(null);

    // Sync user info from storage (including avatar)
    const syncUserFromStorage = () => {
        const storedUserStr = localStorage.getItem('auth_user');
        if (storedUserStr) {
            try {
                const storedUser = JSON.parse(storedUserStr);
                // Merge with existing currentUser to preserve other fields if any, or just overwrite
                setCurrentUser((prev: any) => ({ ...prev, ...storedUser }));
            } catch (e) {
                console.error("Failed to parse auth_user", e);
            }
        }
    };

    useEffect(() => {
        window.addEventListener('storage', syncUserFromStorage);
        // Initial sync
        syncUserFromStorage();
        return () => window.removeEventListener('storage', syncUserFromStorage);
    }, []);

    // Refresh sessions when opening the widget to get latest offline messages
    useEffect(() => {
        if (isOpen && currentUser) {
            fetchSessions();
        }
    }, [isOpen]);

    useEffect(() => {
        // Fetch real user info on init
        const initUser = async () => {
            // Try to get from local storage first if available in auth context, or fetch
            // For now, assume we fetch from backend who trusts the token
            try {
                const user = await imService.getMyInfo();
                setCurrentUser(user || { userId: -1, wxId: 'Guest' });
            } catch (e) {
                console.error("Failed to load user info", e);
            }
        };
        initUser();
    }, []);

    // New State for Modals
    const [showMenu, setShowMenu] = useState(false);
    const [showAddFriend, setShowAddFriend] = useState(false);
    const [showCreateGroup, setShowCreateGroup] = useState(false);
    const [showGroupDetails, setShowGroupDetails] = useState(false);
    const [showAddMember, setShowAddMember] = useState(false);
    const [isDeleteMode, setIsDeleteMode] = useState(false);
    const [groupMembers, setGroupMembers] = useState<any[]>([]);

    const handleShowGroupDetails = async () => {
        if (!activeSessionId) return;
        const session = sessions.find(s => s.id === activeSessionId);
        if (!session || session.type !== 'group') return; // Only groups

        setShowGroupDetails(true);
        setIsDeleteMode(false); // Reset delete mode
        try {
            const members = await imService.getGroupMembers(activeSessionId);
            setGroupMembers(members);
        } catch (e) {
            console.error("Failed to load group members", e);
        }
    }

    // Inputs
    const [friendIdInput, setFriendIdInput] = useState('');
    const [groupNameInput, setGroupNameInput] = useState('');
    const [groupMembersInput, setGroupMembersInput] = useState(''); // comma separated IDs for demo

    // User Selection State
    const [availableUsers, setAvailableUsers] = useState<any[]>([]);
    const [selectedUserIds, setSelectedUserIds] = useState<number[]>([]);
    const [searchTerm, setSearchTerm] = useState('');

    // State Refs for WebSocket access
    const sessionsRef = useRef(sessions);
    const groupMembersRef = useRef(groupMembers);
    const availableUsersRef = useRef(availableUsers);
    const activeSessionIdRef = useRef(activeSessionId);
    const isOpenRef = useRef(isOpen);

    useEffect(() => { sessionsRef.current = sessions; }, [sessions]);
    useEffect(() => { groupMembersRef.current = groupMembers; }, [groupMembers]);
    useEffect(() => { availableUsersRef.current = availableUsers; }, [availableUsers]);
    useEffect(() => { activeSessionIdRef.current = activeSessionId; }, [activeSessionId]);
    useEffect(() => { isOpenRef.current = isOpen; }, [isOpen]);

    // Clear unread when opening widget if active session exists
    useEffect(() => {
        if (isOpen && activeSessionId) {
            setSessions(prev => prev.map(s => {
                if (s.id === activeSessionId) {
                    return { ...s, unread: 0 };
                }
                return s;
            }));
            imService.clearUnread(activeSessionId).catch(e => console.error("Failed to clear unread", e));
        }
    }, [isOpen, activeSessionId]);

    // WebSocket Ref
    const ws = useRef<WebSocket | null>(null);

    const getConversationId = (uid1: number, uid2: number) => {
        return uid1 < uid2 ? uid1 + '_' + uid2 : uid2 + '_' + uid1;
    };

    useEffect(() => {
        if (!activeSessionId) return;
        const loadHistory = async () => {
            if (!currentUser || !currentUser.userId || !activeSessionId) return;
            const uid = Number(currentUser.userId);
            const sid = Number(activeSessionId);
            if (isNaN(uid) || isNaN(sid)) {
                console.error("Invalid IDs for history:", uid, sid);
                return;
            }

            const isGroup = sessions.find(s => s.id === sid)?.type === 'group';
            const convId = isGroup
                ? 'GROUP_' + sid
                : getConversationId(uid, sid);
            try {
                // Pre-fetch group members if it's a group
                let currentMembers: any[] = [];
                if (isGroup) {
                    try {
                        currentMembers = await imService.getGroupMembers(sid);
                        setGroupMembers(currentMembers);
                    } catch (e) {
                        console.error("Failed to load group members", e);
                    }
                }

                const history = await imService.getHistory(convId);
                // Transform to UI format with Member Name resolution
                const uiMessages = history.reverse().map(m => ({
                    id: m.id,
                    content: m.content,
                    senderId: m.senderId,
                    time: m.sendTime ? new Date(m.sendTime).toLocaleTimeString() : '',
                    isSelf: m.senderId === currentUser.userId,
                    type: m.msgType === 2 ? 'image' : 'text',
                    senderName: m.senderName || (m.senderId === currentUser.userId ? (currentUser.wxId || 'Me') : ('User ' + m.senderId)),
                    senderAvatar: m.senderAvatar || (m.senderId === currentUser.userId ? currentUser.avatarUrl : null)
                }));
                setMessages(prev => ({
                    ...prev,
                    [activeSessionId]: uiMessages
                }));
            } catch (e) {
                console.error("Failed to load history", e);
            }
        }
        loadHistory();
    }, [activeSessionId]);

    const fetchSessions = async () => {
        if (!currentUser || currentUser.userId === -1) return;
        try {
            const data = await imService.getSessions();

            // Helper to enrich data (Only for Avatar fallback or Group name if needed)
            const getMeta = (id: number, type: number) => {
                if (type === 2) return { name: '群聊', avatar: null };
                return { name: '', avatar: null }; // No hardcoding
            };

            const uiSessions = data.map(s => {
                const meta = getMeta(s.peerId, s.chatType);
                // Fallback to "User {ID}" to avoid "1" avatar, ensuring "U" or consistent letter
                const finalName = s.name || meta.name || ('User ' + s.peerId);
                return {
                    id: s.peerId,
                    name: finalName,
                    avatar: getAvatarUrl(s.avatar || meta.avatar, finalName),
                    message: s.lastMsgContent || '',
                    time: s.lastMsgTime ? new Date(s.lastMsgTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '',
                    unread: s.unreadCount,
                    type: (s.chatType === 1 ? (s.peerId === 103 ? 'bot' : 'person') : 'group') as any
                };
            });

            if (uiSessions.length > 0) {
                // Fix: Ensure active session is marked as read in the fetched list to avoid race condition
                // where fetchSessions overwrites the local clearUnread effect.
                if (activeSessionIdRef.current) {
                    const activeDetails = uiSessions.find(s => s.id === activeSessionIdRef.current);
                    if (activeDetails) {
                        activeDetails.unread = 0;
                    }
                }
                setSessions(uiSessions);
            }
        } catch (e) {
            console.error("Failed to fetch sessions", e);
        }
    };

    useEffect(() => {
        if (!currentUser || !currentUser.userId || currentUser.userId === -1) return;
        fetchSessions();

        // 2. Connect WebSocket
        if (currentUser.userId && currentUser.userId !== -1) {
            const socket = new WebSocket(WS_URL + '?userId=' + currentUser.userId);
            socket.onopen = () => console.log('IM WS Connected');
            socket.onmessage = (event) => {
                const msg = JSON.parse(event.data);
                console.log('Received:', msg);

                // 1. Update Messages State
                const isGroup = msg.groupId && msg.groupId > 0;
                const incomingMsg = {
                    id: msg.id || Date.now(),
                    content: msg.content,
                    senderId: msg.senderId,
                    time: msg.sendTime ? new Date(msg.sendTime).toLocaleTimeString() : new Date().toLocaleTimeString(),
                    isSelf: msg.senderId === currentUser.userId,
                    type: msg.msgType === 2 ? 'image' : 'text',
                    senderName: msg.senderName || (msg.senderId === currentUser.userId ? (currentUser.wxId || 'Me') : ('User ' + msg.senderId)),
                    senderAvatar: msg.senderAvatar || (msg.senderId === currentUser.userId ? currentUser.avatarUrl : null)
                };

                const conversationId = msg.conversationId || getConversationId(currentUser.userId, msg.senderId === currentUser.userId ? msg.receiverId : msg.senderId);

                // Determine peerId (Session ID)
                let peerId = isGroup ? msg.groupId : (msg.senderId === currentUser.userId ? msg.receiverId : msg.senderId);

                setMessages(prev => ({
                    ...prev,
                    [activeSessionId && getConversationId(currentUser.userId, activeSessionId) === conversationId ? activeSessionId : peerId]:
                        [...(prev[peerId] || []), incomingMsg]
                }));

                // Handle Session List Update
                setMessages((prev) => {
                    const currentList = prev[peerId] || [];
                    // Avoid duplicates if echoed
                    if (currentList.some((m: any) => m.id === incomingMsg.id)) return prev;
                    return {
                        ...prev,
                        [peerId]: [...currentList, incomingMsg]
                    };
                });

                // 2. Update Sessions List (Last Message & Unread)
                setSessions(prev => {
                    // Check if session exists
                    const existingSessionIndex = prev.findIndex(s => s.id === peerId);

                    if (existingSessionIndex === -1) {
                        // Session doesn't exist, reload sessions to fetch metadata (name, avatar)
                        // This handles the "New Group" or "New Friend" case dynamically
                        imService.getSessions().then(data => {
                            // Reuse fetchSessions logic or call it directly if available in scope
                            // Since fetchSessions is in scope:
                            fetchSessions();
                        });
                        return prev;
                    }

                    return prev.map(session => {
                        if (session.id === peerId) {
                            return {
                                ...session,
                                message: incomingMsg.type === 'image' ? '[Image]' : incomingMsg.content,
                                time: incomingMsg.time,
                                // Use Refs to check current state safely within closure
                                unread: (isOpenRef.current && activeSessionIdRef.current === peerId) ? 0 : ((session.unread || 0) + 1)
                            };
                        }
                        return session;
                    });
                });
            };
            ws.current = socket;

            return () => {
                socket.close();
            }
        }
    }, [currentUser]);

    const handleSendMessage = async (content: string, type: 'text' | 'image' = 'text') => {
        if (!activeSessionId) return;

        // Construct Message Object
        const session = sessions.find(s => s.id === activeSessionId);
        if (!session) return;

        const newMessage = {
            senderId: currentUser.userId,
            receiverId: session.id, // session.id is peerId from mapping
            groupId: session.type === 'group' ? session.id : undefined,
            content,
            msgType: type === 'image' ? 2 : 1,
            conversationId: getConversationId(currentUser.userId, session.id),
            type: type, // Frontend prop
            isSelf: true,
            time: new Date().toLocaleTimeString(),
            senderAvatar: currentUser.avatarUrl,
            senderName: currentUser.name || currentUser.wxId || 'Me' // Ensure name is present for avatar generation
        };

        // UI Optimistic Update
        setMessages(prev => ({
            ...prev,
            [activeSessionId]: [...(prev[activeSessionId] || []), { ...newMessage, id: Date.now() }]
        }));

        // Update Session List Preview locally
        setSessions(prev => prev.map(s => {
            if (s.id === activeSessionId) {
                return {
                    ...s,
                    message: type === 'image' ? '[Image]' : content,
                    time: newMessage.time
                };
            }
            return s;
        }));

        // Send to Backend (Sanitized Payload)
        const payload = {
            receiverId: session.id,
            groupId: session.type === 'group' ? session.id : undefined,
            content,
            msgType: type === 'image' ? 2 : 1,
            conversationId: getConversationId(currentUser.userId, session.id)
        };

        try {
            await imService.sendMessage(payload as any);
        } catch (e) {
            console.error('Send failed', e);
        }
    };

    const handleOpenAddFriend = async () => {
        setShowMenu(false);
        setSearchTerm('');
        try {
            // Initial load - maybe just 20 recent or empty? 
            // For now show all existing (performance warning later) or just empty
            const users = await imService.searchUsers('');
            // Filter out self
            setAvailableUsers(users.filter((u: any) => u.userId !== currentUser.userId));
            setAvailableUsers(users.filter((u: any) => u.userId !== currentUser.userId));
            setShowAddFriend(true);
        } catch (e) {
            alert('加载用户失败');
        }
    };

    const handleSearchUsers = async (term: string) => {
        setSearchTerm(term);
        try {
            const users = await imService.searchUsers(term);
            setAvailableUsers(users.filter((u: any) => u.userId !== currentUser.userId));
        } catch (e) {
            console.error(e);
        }
    };

    const handleAddFriend = async () => {
        if (selectedUserIds.length === 0) return;
        try {
            // Loop add
            for (const uid of selectedUserIds) {
                await imService.addFriend(uid, '新朋友');
            }

            setShowAddFriend(false);
            setSelectedUserIds([]);

            // Refresh sessions
            const newSessions = await imService.getSessions();
            // Re-map (duplicated logic, should refactor)
            const getMeta = (id: number, type: number) => {
                if (type === 2) return { name: 'Risk Dept Group', avatar: null };
                if (id === 102) return { name: 'Li Manager', avatar: null };
                if (id === 103) return { name: 'Smart Assistant', avatar: null };
                const u = availableUsers.find(u => u.userId === id) || { wxId: 'User ' + id };
                return { name: u.wxId || ('User ' + id), avatar: getAvatarUrl(u.avatarUrl, u.userId) };
            };

            const uiSessions = newSessions.map(s => {
                const meta = getMeta(s.peerId, s.chatType);
                return {
                    id: s.peerId,
                    name: s.name || meta.name,
                    avatar: s.avatar || meta.avatar,
                    message: s.lastMsgContent || '',
                    time: s.lastMsgTime ? new Date(s.lastMsgTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '',
                    unread: s.unreadCount,
                    type: (s.chatType === 1 ? (s.peerId === 103 ? 'bot' : 'person') : 'group') as any
                };
            });
            setSessions(uiSessions);

            setSessions(uiSessions);

        } catch (e) {
            alert('添加好友失败');
        }
    };

    const handleOpenCreateGroup = async () => {
        setShowMenu(false);
        setSearchTerm('');
        try {
            // Ideally fetch friends list instead of all users? 
            // For now reusing searchUsers('') to get everyone for demo
            const users = await imService.searchUsers('');
            setAvailableUsers(users.filter((u: any) => u.userId !== currentUser.userId));
            setShowCreateGroup(true);
        } catch (e) {
            console.error(e);
            alert('Failed to load users');
        }
    };

    const handleCreateGroup = async () => {
        if (selectedUserIds.length === 0) return;
        try {
            await imService.createGroup(groupNameInput, selectedUserIds);
            alert('群聊创建成功');
            setShowCreateGroup(false);
            fetchSessions(); // Refresh list
        } catch (e) {
            alert('Failed to create group');
        }
    };

    const handleAddMembers = async () => {
        if (!activeSessionId || selectedUserIds.length === 0) return;
        try {
            await imService.addGroupMembers(activeSessionId, selectedUserIds);
            alert('邀请成功');
            setShowAddMember(false);
            // Refresh members
            const members = await imService.getGroupMembers(activeSessionId);
            setGroupMembers(members);
            // Update ref
            groupMembersRef.current = members;
            fetchSessions();
        } catch (e) {
            alert('Failed to add members');
        }
    }




    const handleSelectSession = (sessionId: number) => {
        setActiveSessionId(sessionId);
        // Clear unread count locally
        setSessions(prev => prev.map(s => {
            if (s.id === sessionId) {
                return { ...s, unread: 0 };
            }
            return s;
        }));
        // Clear unread count on server
        imService.clearUnread(sessionId).catch(e => console.error("Failed to clear unread", e));
    };

    const activeSession = sessions.find(s => s.id === activeSessionId);

    const handleRemoveMemberSingle = async (memberId: number) => {
        if (!activeSessionId) return;
        if (!window.confirm('确定要移除该成员吗？')) return;
        try {
            await imService.removeGroupMembers(activeSessionId, [memberId]);
            // Optimistic update
            setGroupMembers(prev => prev.filter(m => m.userId !== memberId));
            groupMembersRef.current = groupMembersRef.current.filter(m => m.userId !== memberId);
            fetchSessions();
        } catch (e) {
            alert('移除失败 (只有群主可以移除成员)');
        }
    };

    const handleDeleteSession = async (sessionId: number) => {
        if (!window.confirm('确定要删除会话吗？')) return;

        try {
            await imService.deleteSession(sessionId);
            // Optimistic Remove
            setSessions(prev => prev.filter(s => s.id !== sessionId));
            if (activeSessionId === sessionId) {
                setActiveSessionId(null);
            }
        } catch (e) {
            console.error("Failed to delete session", e);
            alert("删除失败");
        }
    };

    const totalUnread = sessions.reduce((sum, s) => sum + (s.unread || 0), 0);

    return (
        <div className="fixed bottom-8 right-8 z-50 flex flex-col items-end print:hidden font-sans antialiased">
            {/* Chat Window */}
            <AnimatePresence>
                {isOpen && (
                    <motion.div
                        initial={{ opacity: 0, scale: 0.9, y: 30 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: 30 }}
                        transition={{ type: "spring", stiffness: 350, damping: 25 }}
                        className="mb-6 bg-white/65 backdrop-blur-3xl rounded-[2.5rem] shadow-[0_20px_60px_rgba(0,0,0,0.12)] border border-white/40 w-[950px] h-[min(700px,calc(100vh-140px))] flex overflow-hidden ring-1 ring-black/[0.03]"
                    >

                        {/* Sidebar */}
                        <div className="w-80 bg-slate-50/40 backdrop-blur-2xl border-r border-slate-200/50 flex flex-col flex-shrink-0">
                            {/* Header */}
                            <div className="h-20 px-6 flex items-center justify-between border-b border-slate-200/40 bg-white/30">
                                <div className="flex items-center gap-3">
                                    <div className="relative group/avatar">
                                        <div className="absolute -inset-1 bg-gradient-to-tr from-red-500 to-orange-400 rounded-full blur-sm opacity-0 group-hover/avatar:opacity-40 transition-opacity duration-500" />
                                        <img
                                            src={getAvatarUrl(currentUser?.avatarUrl, currentUser?.name || currentUser?.wxId || 'Me')}
                                            className="relative w-10 h-10 rounded-full object-cover ring-2 ring-white shadow-md transition-transform group-hover/avatar:scale-110 duration-500"
                                            alt="My Profile"
                                        />
                                        <div className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full shadow-sm animate-pulse"></div>
                                    </div>
                                    <div className="flex flex-col">
                                        <span className="font-black text-slate-900 text-[13px] tracking-tight">{currentUser?.name || currentUser?.wxId || '消息中心'}</span>
                                        <div className="flex items-center gap-1 mt-0.5">
                                            <span className="text-[9px] text-emerald-600 font-black uppercase tracking-widest">Active</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="relative">
                                    <button
                                        onClick={() => setShowMenu(!showMenu)}
                                        className="w-10 h-10 flex items-center justify-center bg-white/80 hover:bg-white rounded-2xl text-slate-600 transition-all duration-300 shadow-sm border border-slate-100/50 group"
                                    >
                                        <Plus size={20} strokeWidth={3} className="group-hover:rotate-90 transition-transform duration-500" />
                                    </button>

                                    {/* Backdrop */}
                                    {showMenu && (
                                        <div className="fixed inset-0 z-40" onClick={() => setShowMenu(false)} />
                                    )}

                                    {/* Dropdown Menu */}
                                    <AnimatePresence>
                                        {showMenu && (
                                            <motion.div
                                                initial={{ opacity: 0, y: -10 }}
                                                animate={{ opacity: 1, y: 0 }}
                                                exit={{ opacity: 0, y: -10 }}
                                                className="absolute right-0 top-10 w-48 bg-white/90 backdrop-blur-xl rounded-xl shadow-xl border border-white/50 py-1.5 z-50 ring-1 ring-black/5"
                                            >
                                                <button
                                                    className="w-full text-left px-4 py-2.5 hover:bg-slate-100/80 text-sm text-slate-700 font-medium transition-colors flex items-center gap-2"
                                                    onClick={handleOpenAddFriend}
                                                >
                                                    <div className="w-6 h-6 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600"><Plus size={14} /></div>
                                                    添加好友
                                                </button>
                                                <button
                                                    className="w-full text-left px-4 py-2.5 hover:bg-slate-100/80 text-sm text-slate-700 font-medium transition-colors flex items-center gap-2"
                                                    onClick={handleOpenCreateGroup}
                                                >
                                                    <div className="w-6 h-6 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600"><MessageCircle size={14} /></div>
                                                    发起群聊
                                                </button>
                                            </motion.div>
                                        )}
                                    </AnimatePresence>
                                </div>
                            </div>

                            {/* Search */}
                            <div className="px-6 py-5">
                                <div className="relative group">
                                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4 transition-all duration-300 group-focus-within:text-red-500 group-focus-within:scale-110" />
                                    <input
                                        type="text"
                                        placeholder="搜索联系人、群聊..."
                                        className="w-full pl-11 pr-4 py-3 bg-white/50 border border-slate-200/50 rounded-2xl text-[13px] font-bold placeholder-slate-400 focus:bg-white focus:ring-4 focus:ring-red-500/[0.04] focus:border-red-500/30 transition-all shadow-sm outline-none"
                                    />
                                </div>
                            </div>

                            <SessionList
                                sessions={sessions}
                                activeSessionId={activeSessionId || undefined}
                                onSelectSession={handleSelectSession}
                                onDeleteSession={handleDeleteSession}
                            />

                        </div>

                        {/* Main Chat Area */}
                        <div className="flex-1 bg-white/40 flex flex-col relative w-full">
                            {/* Global Close Button */}
                            <div className="absolute top-0 right-0 h-16 flex items-center pr-6 z-20">
                                <button
                                    onClick={() => {
                                        setIsOpen(false);
                                        setActiveSessionId(null);
                                    }}
                                    className="p-2 hover:bg-white/50 rounded-xl text-slate-500 hover:text-red-600 transition-colors"
                                    title="关闭"
                                >
                                    <X size={22} />
                                </button>
                            </div>

                            {activeSessionId && activeSession ? (
                                <ChatWindow
                                    key={activeSessionId}
                                    sessionName={activeSession.name}
                                    messages={messages[activeSessionId] || []}
                                    onSendMessage={handleSendMessage}
                                    onFileUpload={userService.uploadFile}
                                    onShowDetails={handleShowGroupDetails}
                                />
                            ) : (
                                <div className="flex-1 flex flex-col items-center justify-center text-center p-8 bg-slate-50/30">
                                    <div className="w-28 h-28 bg-gradient-to-tr from-red-50 to-orange-50 rounded-[2.5rem] flex items-center justify-center mb-10 shadow-inner border border-white group">
                                        <MessageCircle size={48} className="text-red-200 group-hover:scale-110 transition-transform duration-700" />
                                    </div>
                                    <h3 className="text-slate-900 font-black text-2xl mb-3 tracking-tighter uppercase italic">
                                        URGS <span className="text-red-600 underline decoration-red-200 underline-offset-8">Messenger</span>
                                    </h3>
                                    <p className="text-slate-400 text-[11px] max-w-[200px] leading-relaxed font-black uppercase tracking-widest text-center opacity-70">
                                        Select a conversation to start <br />
                                        <span className="text-[10px] mt-2 block opacity-40">Communication Center v2.0</span>
                                    </p>
                                </div>
                            )}
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>

            {/* Modals */}
            {/* Modals */}
            {showAddFriend && (
                <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[60] flex items-center justify-center p-4">
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        className="bg-white/90 backdrop-blur-2xl p-8 rounded-[2.5rem] w-full max-w-md shadow-2xl border border-white/50 flex flex-col"
                    >
                        <h3 className="text-xl font-black text-slate-900 mb-6 tracking-tight uppercase">添加好友</h3>
                        <div className="mb-4 relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
                            <input
                                className="w-full pl-9 pr-4 py-2 border rounded-lg text-sm"
                                placeholder="通过名称或ID搜索..."
                                value={searchTerm}
                                onChange={(e) => handleSearchUsers(e.target.value)}
                            />
                        </div>
                        <div className="flex-1 overflow-y-auto border rounded p-2 mb-4">
                            {availableUsers.map(u => (
                                <div key={u.userId} className="flex items-center gap-2 p-2 hover:bg-slate-50">
                                    <input
                                        type="checkbox"
                                        checked={selectedUserIds.includes(u.userId)}
                                        onChange={(e) => {
                                            if (e.target.checked) {
                                                setSelectedUserIds(prev => [...prev, u.userId]);
                                            } else {
                                                setSelectedUserIds(prev => prev.filter(id => id !== u.userId));
                                            }
                                        }}
                                    />
                                    <img src={getAvatarUrl(u.avatarUrl, u.userId)} className="w-8 h-8 rounded-full" />
                                    <span>{u.wxId} (ID: {u.userId})</span>
                                </div>
                            ))}
                        </div>
                        <div className="flex justify-end gap-2">
                            <button onClick={() => setShowAddFriend(false)} className="px-3 py-1 text-slate-500">取消</button>
                            <button onClick={handleAddFriend} className="px-3 py-1 bg-indigo-600 text-white rounded">添加</button>
                        </div>
                    </motion.div>
                </div>
            )}

            {showGroupDetails && (
                <div className="fixed inset-0 bg-black/50 z-[60] flex items-center justify-center">
                    <div className="bg-white p-6 rounded-lg w-96 shadow-xl max-h-[80vh] flex flex-col">
                        <div className="flex justify-between items-center mb-4">
                            <h3 className="font-bold">群聊详情</h3>
                            <button onClick={() => setShowGroupDetails(false)}><X size={20} className="text-slate-400 hover:text-slate-600" /></button>
                        </div>
                        <div className="flex-1 overflow-y-auto">
                            <h4 className="text-xs font-semibold text-slate-400 mb-3">成员 ({groupMembers.length})</h4>
                            <div className="grid grid-cols-5 gap-2">
                                <div
                                    className="flex flex-col items-center gap-1 cursor-pointer hover:bg-slate-50 p-1 rounded"
                                    onClick={() => {
                                        setShowAddMember(true);
                                        setSelectedUserIds([]);
                                    }}
                                >
                                    <div className="w-10 h-10 border-2 border-dashed border-slate-300 rounded-lg flex items-center justify-center text-slate-400">
                                        <Plus size={20} />
                                    </div>
                                    <span className="text-[10px] text-slate-500 truncate w-full text-center">添加</span>
                                </div>

                                <div
                                    className={`flex flex-col items-center gap-1 cursor-pointer p-1 rounded hover:bg-slate-50 ${isDeleteMode ? 'bg-red-50' : ''}`}
                                    onClick={() => setIsDeleteMode(!isDeleteMode)}
                                >
                                    <div className={`w-10 h-10 border-2 border-dashed rounded-lg flex items-center justify-center ${isDeleteMode ? 'border-red-400 text-red-500' : 'border-slate-300 text-slate-400'}`}>
                                        <Minus size={20} />
                                    </div>
                                    <span className={`text-[10px] truncate w-full text-center ${isDeleteMode ? 'text-red-500' : 'text-slate-500'}`}>
                                        {isDeleteMode ? '完成' : '移除'}
                                    </span>
                                </div>

                                {groupMembers.map(m => (
                                    <div key={m.userId} className="relative flex flex-col items-center gap-1 group/member">
                                        {isDeleteMode && m.userId !== currentUser.userId && (
                                            <button
                                                className="absolute -top-1 -right-1 z-10 bg-red-500 text-white rounded-full p-0.5 shadow-sm hover:bg-red-600"
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    handleRemoveMemberSingle(m.userId);
                                                }}
                                            >
                                                <Minus size={12} strokeWidth={3} />
                                            </button>
                                        )}
                                        <img
                                            src={getAvatarUrl(m.avatarUrl, m.userId)}
                                            className={`w-10 h-10 rounded-lg object-cover ${isDeleteMode ? 'opacity-90' : ''}`}
                                            alt={m.wxId}
                                        />
                                        <span className="text-[10px] text-slate-500 truncate w-full text-center">{m.wxId || ('用户 ' + m.userId)}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {showCreateGroup && (
                <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[60] flex items-center justify-center p-4">
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        className="bg-white/90 backdrop-blur-2xl p-8 rounded-[2.5rem] w-full max-w-md shadow-2xl border border-white/50 flex flex-col"
                    >
                        <h3 className="text-xl font-black text-slate-900 mb-6 tracking-tight uppercase">发起群聊</h3>
                        <div className="mb-6">
                            <label className="text-[10px] font-black text-slate-400 mb-2 block uppercase tracking-widest">群名称 (选填)</label>
                            <input
                                className="w-full bg-slate-50 border border-slate-100 p-4 rounded-2xl text-[13px] font-bold outline-none focus:bg-white focus:ring-4 focus:ring-red-500/[0.04] focus:border-red-500/30 transition-all shadow-inner"
                                placeholder="输入群组名称..."
                                value={groupNameInput}
                                onChange={e => setGroupNameInput(e.target.value)}
                            />
                        </div>

                        <div className="flex-1 overflow-y-auto border border-slate-100 bg-slate-50/50 rounded-[2rem] p-4 mb-6 min-h-[200px] shadow-inner">
                            <h4 className="text-[10px] font-black text-slate-400 mb-3 px-2 uppercase tracking-widest">选择联系人</h4>
                            {availableUsers.map(u => (
                                <div key={u.userId} className="flex items-center gap-3 p-3 hover:bg-white hover:shadow-sm rounded-2xl cursor-pointer transition-all duration-300 mb-1 group/user" onClick={() => {
                                    if (selectedUserIds.includes(u.userId)) {
                                        setSelectedUserIds(prev => prev.filter(id => id !== u.userId));
                                    } else {
                                        setSelectedUserIds(prev => [...prev, u.userId]);
                                    }
                                }}>
                                    <div className={`w-5 h-5 rounded-lg border-2 flex items-center justify-center transition-all duration-300 ${selectedUserIds.includes(u.userId) ? 'bg-emerald-500 border-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.3)]' : 'border-slate-200 bg-white group-hover/user:border-emerald-300'}`}>
                                        {selectedUserIds.includes(u.userId) && <div className="w-1.5 h-1.5 bg-white rounded-full" />}
                                    </div>
                                    <img src={getAvatarUrl(u.avatarUrl, u.userId)} className="w-9 h-9 rounded-full ring-2 ring-white shadow-sm" />
                                    <div className="flex flex-col">
                                        <span className="text-[13px] font-black text-slate-800">{u.wxId || ('用户 ' + u.userId)}</span>
                                        <span className="text-[9px] text-slate-400 font-black">ID: {u.userId}</span>
                                    </div>
                                </div>
                            ))}
                        </div>

                        <div className="flex justify-between items-center bg-slate-50 p-2 rounded-2xl border border-slate-100">
                            <button onClick={() => { setShowCreateGroup(false); setSelectedUserIds([]); }} className="px-6 py-2.5 text-[11px] font-black text-slate-400 uppercase tracking-widest hover:text-slate-600 transition-colors">取消</button>
                            <button
                                onClick={handleCreateGroup}
                                disabled={selectedUserIds.length === 0}
                                className={`px-8 py-2.5 text-[11px] font-black text-white rounded-xl transition-all duration-500 uppercase tracking-[0.2em] shadow-lg ${selectedUserIds.length > 0 ? 'bg-emerald-500 hover:bg-emerald-600 shadow-emerald-500/20' : 'bg-slate-300 cursor-not-allowed shadow-none'}`}
                            >
                                创建 ({selectedUserIds.length})
                            </button>
                        </div>
                    </motion.div>
                </div>
            )}

            {showAddMember && (
                <div className="fixed inset-0 bg-black/50 z-[60] flex items-center justify-center">
                    <div className="bg-white p-6 rounded-lg w-96 shadow-xl max-h-[80vh] flex flex-col">
                        <h3 className="font-bold mb-4">邀请好友</h3>
                        <div className="flex-1 overflow-y-auto border rounded p-2 mb-4">
                            <h4 className="text-xs font-semibold text-slate-400 mb-2 px-2">选择联系人</h4>
                            {availableUsers.map(u => (
                                <div key={u.userId} className="flex items-center gap-2 p-2 hover:bg-slate-50 cursor-pointer" onClick={() => {
                                    if (selectedUserIds.includes(u.userId)) {
                                        setSelectedUserIds(prev => prev.filter(id => id !== u.userId));
                                    } else {
                                        setSelectedUserIds(prev => [...prev, u.userId]);
                                    }
                                }}>
                                    <div className={`w-4 h-4 rounded border flex items-center justify-center ${selectedUserIds.includes(u.userId) ? 'bg-[#07C160] border-[#07C160]' : 'border-slate-300'}`}>
                                        {selectedUserIds.includes(u.userId) && <div className="w-2 h-2 bg-white rounded-full" />}
                                    </div>
                                    <img src={getAvatarUrl(u.avatarUrl, u.userId)} className="w-8 h-8 rounded-full" />
                                    <span>{u.wxId || ('用户 ' + u.userId)}</span>
                                </div>
                            ))}
                        </div>
                        <div className="flex justify-end gap-2">
                            <button onClick={() => { setShowAddMember(false); setSelectedUserIds([]); }} className="px-3 py-1 text-slate-500">取消</button>
                            <button
                                onClick={handleAddMembers}
                                disabled={selectedUserIds.length === 0}
                                className={`px-3 py-1 text-white rounded transition-colors ${selectedUserIds.length > 0 ? 'bg-[#07C160]' : 'border-slate-300 cursor-not-allowed'}`}
                            >
                                邀请 ({selectedUserIds.length})
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Floating Action Button */}
            <motion.button
                layout
                whileHover={{ scale: 1.08, rotate: isOpen ? -90 : 0 }}
                whileTap={{ scale: 0.92 }}
                onClick={() => {
                    const newState = !isOpen;
                    setIsOpen(newState);
                    if (!newState) setActiveSessionId(null);
                }}
                className={`
                    ${isOpen
                        ? 'bg-gradient-to-br from-slate-800 to-black shadow-slate-900/20'
                        : 'bg-gradient-to-br from-red-500 via-red-600 to-red-800 shadow-red-500/30'
                    }
                    ${!isOpen && totalUnread > 0 ? 'ring-4 ring-red-500/20' : ''}
                    text-white p-5 rounded-[1.8rem] shadow-[0_15px_30px_-5px_var(--tw-shadow-color)] hover:shadow-[0_20px_40px_-5px_var(--tw-shadow-color)]
                    transition-all duration-500 flex items-center justify-center relative group backdrop-blur-md z-50 border border-white/20
                `}
            >
                <div className="relative z-10">
                    {isOpen ? (
                        <X size={28} strokeWidth={3} className="text-white drop-shadow-md" />
                    ) : (
                        <div className="relative">
                            <MessageCircle size={28} fill="currentColor" className="text-white/30 drop-shadow-lg" strokeWidth={2} />
                            <MessageCircle size={28} className="absolute inset-0 text-white drop-shadow-md" strokeWidth={2.5} />
                        </div>
                    )}
                </div>
                <div className="absolute inset-0 bg-gradient-to-tr from-white/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-700 pointer-events-none" />
                <AnimatePresence>
                    {!isOpen && totalUnread > 0 && (
                        <motion.span
                            initial={{ scale: 0, y: 10 }}
                            animate={{ scale: 1, y: 0 }}
                            exit={{ scale: 0, y: 10 }}
                            className="absolute -top-1.5 -right-1.5 min-w-[22px] h-[22px] bg-red-500 text-white text-[11px] font-black flex items-center justify-center rounded-full border-[3px] border-white shadow-[0_4px_10px_rgba(239,68,68,0.4)] px-1"
                        >
                            {totalUnread}
                        </motion.span>
                    )}
                </AnimatePresence>
            </motion.button>
        </div>
    );
};

export default ChatWidget;
