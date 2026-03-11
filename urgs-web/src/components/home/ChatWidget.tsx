import React, { useState, useRef, useEffect } from 'react';
import { getAvatarUrl } from '../../utils/avatarUtils';
import { MessageCircle, X, Search, Plus, Minus, MoreHorizontal } from 'lucide-react';
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
                        initial={{ opacity: 0, scale: 0.96, y: 15 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.96, y: 15 }}
                        transition={{ duration: 0.2, ease: "easeOut" }}
                        className="mb-6 bg-white rounded-2xl shadow-[0_20px_60px_-15px_rgba(0,0,0,0.15)] border border-slate-200 w-[940px] h-[min(650px,calc(100vh-140px))] flex overflow-hidden ring-1 ring-black/[0.03]"
                    >

                            {/* 1. Left Navigation Bar (Slim) */}
                            <div className="w-[68px] bg-slate-900 border-r border-slate-800 flex flex-col items-center py-6 flex-shrink-0 z-10 rounded-l-2xl relative">
                                {/* Current User Avatar */}
                                <div className="relative mb-8 group cursor-pointer">
                                    <img
                                        src={getAvatarUrl(currentUser?.avatarUrl, currentUser?.name || currentUser?.wxId || 'Me')}
                                        className="w-10 h-10 rounded-xl object-cover ring-1 ring-white/10 group-hover:ring-white/30 transition-all"
                                        alt="My Profile"
                                    />
                                    <div className="absolute -bottom-1 -right-1 w-3 h-3 bg-emerald-500 border-2 border-slate-900 rounded-full"></div>
                                </div>

                                {/* Nav Icons */}
                                <div className="flex-1 flex flex-col gap-4 w-full px-2">
                                    <button className="w-full aspect-square flex items-center justify-center rounded-xl bg-white/10 text-white relative group">
                                        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-1/2 bg-white rounded-r"></div>
                                        <MessageCircle size={22} strokeWidth={2} />
                                    </button>
                                    <button 
                                        onClick={handleOpenAddFriend}
                                        className="w-full aspect-square flex items-center justify-center rounded-xl text-slate-400 hover:text-white hover:bg-white/5 transition-colors"
                                    >
                                        <Plus size={22} strokeWidth={2} />
                                    </button>
                                </div>

                                {/* Settings / Menu icon at bottom */}
                                <div className="mt-auto pt-4 border-t border-slate-800 w-full px-2">
                                    <div className="relative">
                                        <button
                                            onClick={() => setShowMenu(!showMenu)}
                                            className="w-full aspect-square flex items-center justify-center rounded-xl text-slate-400 hover:text-white hover:bg-white/5 transition-colors"
                                        >
                                            <MoreHorizontal size={22} strokeWidth={2} />
                                        </button>

                                        {/* Dropdown Menu */}
                                        <AnimatePresence>
                                            {showMenu && (
                                                <motion.div
                                                    initial={{ opacity: 0, y: 5, scale: 0.95 }}
                                                    animate={{ opacity: 1, y: 0, scale: 1 }}
                                                    exit={{ opacity: 0, y: 5, scale: 0.95 }}
                                                    transition={{ duration: 0.15 }}
                                                    className="absolute left-full bottom-0 ml-4 w-48 bg-white rounded-xl shadow-[0_8px_30px_rgb(0,0,0,0.12)] border border-slate-100 py-1.5 z-50 origin-bottom-left"
                                                >
                                                    <button
                                                        className="w-full text-left px-4 py-2 hover:bg-slate-50 text-[13px] text-slate-700 font-medium transition-colors flex items-center gap-2"
                                                        onClick={handleOpenAddFriend}
                                                    >
                                                        <Plus size={16} className="text-slate-400" />添加联系人
                                                    </button>
                                                    <button
                                                        className="w-full text-left px-4 py-2 hover:bg-slate-50 text-[13px] text-slate-700 font-medium transition-colors flex items-center gap-2"
                                                        onClick={handleOpenCreateGroup}
                                                    >
                                                        <MessageCircle size={16} className="text-slate-400" />发起群聊
                                                    </button>
                                                </motion.div>
                                            )}
                                        </AnimatePresence>
                                        
                                        {/* Backdrop */}
                                        {showMenu && (
                                            <div className="fixed inset-0 z-40" onClick={() => setShowMenu(false)} />
                                        )}
                                    </div>
                                </div>
                            </div>

                            {/* 2. Session List (Middle) */}
                            <div className="w-[280px] bg-slate-50/50 border-r border-slate-200 flex flex-col flex-shrink-0 z-10">
                                {/* Search */}
                                <div className="h-[68px] px-4 flex items-center border-b border-transparent">
                                    <div className="relative w-full group">
                                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-3.5 h-3.5" />
                                        <input
                                            type="text"
                                            placeholder="搜索..."
                                            className="w-full pl-9 pr-4 py-1.5 bg-slate-200/50 hover:bg-slate-200/80 border border-transparent rounded-md text-[13px] placeholder-slate-400 focus:bg-white focus:border-indigo-500/30 focus:ring-2 focus:ring-indigo-500/10 transition-all outline-none"
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

                            {/* 3. Main Chat Area (Right) */}
                            <div className="flex-1 bg-white flex flex-col relative w-full z-0 rounded-r-2xl overflow-hidden">
                                {/* Global Close Button (Float top right) */}
                                <div className="absolute top-0 right-0 h-[68px] flex items-center pr-4 z-20">
                                    <button
                                        onClick={() => {
                                            setIsOpen(false);
                                            setActiveSessionId(null);
                                        }}
                                        className="p-1.5 hover:bg-slate-100 rounded-md text-slate-400 hover:text-slate-600 transition-colors"
                                        title="关闭"
                                    >
                                        <X size={18} />
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
                                <div className="flex-1 flex flex-col items-center justify-center text-center p-8 bg-slate-50">
                                    <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mb-6 border border-slate-200">
                                        <MessageCircle size={32} strokeWidth={1.5} className="text-slate-300" />
                                    </div>
                                    <h3 className="text-slate-800 font-semibold text-lg mb-2 tracking-tight">
                                        URGS Messenger
                                    </h3>
                                    <p className="text-slate-400 text-[13px] max-w-[240px] leading-relaxed">
                                        Select a conversation from the sidebar to start messaging.
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
                        initial={{ opacity: 0, scale: 0.95, y: 10 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        className="bg-white p-6 rounded-xl w-full max-w-md shadow-2xl border border-slate-100 flex flex-col"
                    >
                        <h3 className="text-base font-semibold text-slate-900 mb-4">添加好友</h3>
                        <div className="mb-4 relative">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" />
                            <input
                                className="w-full pl-9 pr-4 py-2 border border-slate-200 rounded-md text-[13px] focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                                placeholder="通过名称或ID搜索..."
                                value={searchTerm}
                                onChange={(e) => handleSearchUsers(e.target.value)}
                            />
                        </div>
                        <div className="flex-1 overflow-y-auto border border-slate-100 rounded-md p-1 mb-6 max-h-[300px]">
                            {availableUsers.map(u => (
                                <div key={u.userId} className="flex items-center gap-3 p-2 hover:bg-slate-50 rounded cursor-pointer" onClick={() => {
                                    if (selectedUserIds.includes(u.userId)) {
                                        setSelectedUserIds(prev => prev.filter(id => id !== u.userId));
                                    } else {
                                        setSelectedUserIds(prev => [...prev, u.userId]);
                                    }
                                }}>
                                    <input
                                        type="checkbox"
                                        checked={selectedUserIds.includes(u.userId)}
                                        readOnly
                                        className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
                                    />
                                    <img src={getAvatarUrl(u.avatarUrl, u.userId)} className="w-8 h-8 rounded-full object-cover" />
                                    <span className="text-[13px] text-slate-700">{u.wxId} (ID: {u.userId})</span>
                                </div>
                            ))}
                            {availableUsers.length === 0 && <div className="text-center p-4 text-slate-400 text-sm">暂无结果</div>}
                        </div>
                        <div className="flex justify-end gap-3 font-medium">
                            <button onClick={() => setShowAddFriend(false)} className="px-4 py-1.5 text-sm text-slate-600 hover:bg-slate-50 rounded border border-transparent">取消</button>
                            <button onClick={handleAddFriend} className="px-4 py-1.5 text-sm bg-indigo-600 text-white rounded hover:bg-indigo-700 transition-colors shadow-sm">添加</button>
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
                                    </div>
                                ))}
                            </div>
                        </div>

                        <div className="flex justify-between items-center bg-slate-50 p-2 rounded-2xl border border-slate-100 mt-4">
                            <button onClick={() => { setShowGroupDetails(false); setSelectedUserIds([]); }} className="px-6 py-2.5 text-[11px] font-black text-slate-400 uppercase tracking-widest hover:text-slate-600 transition-colors">关闭</button>
                        </div>
                    </div>
                </div>
            )}

            {showAddMember && (
                <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[60] flex items-center justify-center p-4">
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, y: 10 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        className="bg-white p-6 rounded-xl w-full max-w-md shadow-2xl border border-slate-100 flex flex-col"
                    >
                        <h3 className="text-base font-semibold text-slate-900 mb-4">邀请好友</h3>
                        <div className="flex-1 overflow-y-auto border border-slate-100 rounded-md p-1 mb-6 max-h-[300px]">
                            <h4 className="text-[11px] font-semibold text-slate-400 mb-2 px-2 uppercase">选择联系人</h4>
                            {availableUsers.map(u => (
                                <div key={u.userId} className="flex items-center gap-3 p-2 hover:bg-slate-50 rounded cursor-pointer" onClick={() => {
                                    if (selectedUserIds.includes(u.userId)) {
                                        setSelectedUserIds(prev => prev.filter(id => id !== u.userId));
                                    } else {
                                        setSelectedUserIds(prev => [...prev, u.userId]);
                                    }
                                }}>
                                    <input
                                        type="checkbox"
                                        checked={selectedUserIds.includes(u.userId)}
                                        readOnly
                                        className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
                                    />
                                    <img src={getAvatarUrl(u.avatarUrl, u.userId)} className="w-8 h-8 rounded-full object-cover" alt={u.wxId} />
                                    <span className="text-[13px] text-slate-700">{u.wxId || ('用户 ' + u.userId)} (ID: {u.userId})</span>
                                </div>
                            ))}
                        </div>
                        <div className="flex justify-end gap-3 font-medium">
                            <button onClick={() => { setShowAddMember(false); setSelectedUserIds([]); }} className="px-4 py-1.5 text-sm text-slate-600 hover:bg-slate-50 rounded border border-transparent">取消</button>
                            <button
                                onClick={handleAddMembers}
                                disabled={selectedUserIds.length === 0}
                                className={`px-4 py-1.5 text-sm text-white rounded transition-colors shadow-sm ${selectedUserIds.length > 0 ? 'bg-indigo-600 hover:bg-indigo-700' : 'bg-slate-300 cursor-not-allowed border-transparent'}`}
                            >
                                邀请 ({selectedUserIds.length})
                            </button>
                        </div>
                    </motion.div>
                </div>
            )}

            {/* Floating Action Button */}
            <motion.button
                layout
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => {
                    const newState = !isOpen;
                    setIsOpen(newState);
                    if (!newState) setActiveSessionId(null);
                }}
                className={`
                    ${isOpen
                        ? 'bg-slate-800 hover:bg-slate-900 shadow-xl'
                        : 'bg-indigo-600 hover:bg-indigo-700 shadow-xl shadow-indigo-600/30'
                    }
                    ${!isOpen && totalUnread > 0 ? 'ring-4 ring-indigo-500/20' : ''}
                    text-white w-[56px] h-[56px] rounded-2xl flex items-center justify-center relative z-50 transition-colors duration-200
                `}
            >
                <div className="relative z-10 flex items-center justify-center w-full h-full">
                    {isOpen ? (
                        <X size={24} strokeWidth={2.5} className="text-white" />
                    ) : (
                        <MessageCircle size={24} className="text-white drop-shadow-md" strokeWidth={2.5} />
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
