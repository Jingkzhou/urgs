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
                                unread: (isOpenRef.current && activeSessionIdRef.current === peerId) ? 0 : (session.unread + 1)
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
                        initial={{ opacity: 0, scale: 0.9, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: 20 }}
                        transition={{ type: "spring", stiffness: 300, damping: 30 }}
                        className="mb-6 bg-white/85 backdrop-blur-2xl rounded-2xl shadow-2xl border border-white/50 w-[950px] h-[700px] flex overflow-hidden ring-1 ring-black/5"
                    >

                        {/* Sidebar */}
                        <div className="w-80 bg-slate-50/50 backdrop-blur-md border-r border-slate-200/60 flex flex-col flex-shrink-0">
                            {/* Header */}
                            <div className="h-16 px-5 flex items-center justify-between border-b border-slate-200/60 bg-gradient-to-r from-slate-50/50 to-white/50">
                                <div className="flex items-center gap-3">
                                    <div className="relative">
                                        <img
                                            src={getAvatarUrl(currentUser?.avatarUrl, currentUser?.name || currentUser?.wxId || 'Me')}
                                            className="w-9 h-9 rounded-full object-cover ring-2 ring-white shadow-sm"
                                            alt="My Profile"
                                        />
                                        <div className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-500 border-2 border-white rounded-full"></div>
                                    </div>
                                    <div className="flex flex-col">
                                        <span className="font-bold text-slate-800 text-sm tracking-tight">{currentUser?.name || currentUser?.wxId || '消息'}</span>
                                        <span className="text-[10px] text-slate-500 font-medium">在线</span>
                                    </div>
                                </div>
                                <div className="relative">
                                    <button
                                        onClick={() => setShowMenu(!showMenu)}
                                        className="w-8 h-8 flex items-center justify-center hover:bg-slate-200/80 rounded-full text-slate-600 transition-colors"
                                    >
                                        <Plus size={18} strokeWidth={2.5} />
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
                            <div className="p-4">
                                <div className="relative group">
                                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4 transition-colors group-focus-within:text-indigo-500" />
                                    <input
                                        type="text"
                                        placeholder="搜索联系人、群组"
                                        className="w-full pl-9 pr-4 py-2.5 bg-white/60 border border-slate-200/60 rounded-xl text-sm placeholder-slate-400 focus:bg-white focus:ring-2 focus:ring-indigo-500/10 focus:border-indigo-500/50 transition-all shadow-sm"
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
                                    <div className="w-24 h-24 bg-gradient-to-tr from-indigo-50 to-purple-50 rounded-3xl flex items-center justify-center mb-6 shadow-sm border border-white">
                                        <MessageCircle size={40} className="text-indigo-200" />
                                    </div>
                                    <h3 className="text-slate-600 font-semibold text-lg mb-2">欢迎使用 URGS 消息</h3>
                                    <p className="text-slate-400 text-sm max-w-xs leading-relaxed">选择左侧会话开始聊天，或点击 <span className="inline-flex items-center justify-center w-5 h-5 bg-slate-200 rounded-full text-xs text-slate-500 mx-1"><Plus size={10} /></span> 发起新的对话</p>
                                </div>
                            )}
                        </div>

                    </motion.div>
                )}
            </AnimatePresence>

            {/* Modals */}
            {
                showAddFriend && (
                    <div className="fixed inset-0 bg-black/50 z-[60] flex items-center justify-center">
                        <div className="bg-white p-6 rounded-lg w-96 shadow-xl max-h-[80vh] flex flex-col">
                            <h3 className="font-bold mb-4">添加好友</h3>
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
                        </div>
                    </div>
                )
            }

            {/* Group Details Modal */}
            {
                showGroupDetails && (
                    <div className="fixed inset-0 bg-black/50 z-[60] flex items-center justify-center">
                        <div className="bg-white p-6 rounded-lg w-96 shadow-xl max-h-[80vh] flex flex-col">
                            <div className="flex justify-between items-center mb-4">
                                <h3 className="font-bold">群聊详情</h3>
                                <button onClick={() => setShowGroupDetails(false)}><X size={20} className="text-slate-400 hover:text-slate-600" /></button>
                            </div>
                            <div className="flex-1 overflow-y-auto">
                                <h4 className="text-xs font-semibold text-slate-400 mb-3">成员 ({groupMembers.length})</h4>
                                <div className="grid grid-cols-5 gap-2">
                                    {/* Add Button */}
                                    <div
                                        className="flex flex-col items-center gap-1 cursor-pointer hover:bg-slate-50 p-1 rounded"
                                        onClick={() => {
                                            setShowAddMember(true);
                                            setSelectedUserIds([]); // Reset selection
                                        }}
                                    >
                                        <div className="w-10 h-10 border-2 border-dashed border-slate-300 rounded-lg flex items-center justify-center text-slate-400">
                                            <Plus size={20} />
                                        </div>
                                        <span className="text-[10px] text-slate-500 truncate w-full text-center">添加</span>
                                    </div>

                                    {/* Remove Button */}
                                    <div
                                        className={`flex flex-col items-center gap-1 cursor-pointer p-1 rounded hover:bg-slate-50 ${isDeleteMode ? 'bg-red-50' : ''}`}
                                        onClick={() => {
                                            setIsDeleteMode(!isDeleteMode);
                                        }}
                                    >
                                        <div className={`w-10 h-10 border-2 border-dashed rounded-lg flex items-center justify-center ${isDeleteMode ? 'border-red-400 text-red-500' : 'border-slate-300 text-slate-400'}`}>
                                            <Minus size={20} />
                                        </div>
                                        <span className={`text-[10px] truncate w-full text-center ${isDeleteMode ? 'text-red-500' : 'text-slate-500'}`}>
                                            {isDeleteMode ? '完成' : '移除'}
                                        </span>
                                    </div>
                                    {/* Members */}
                                    {groupMembers.map(m => (
                                        <div key={m.userId} className="relative flex flex-col items-center gap-1 group/member">
                                            {isDeleteMode && m.userId !== currentUser.userId && (
                                                <button
                                                    className="absolute -top-1 -right-1 z-10 bg-red-500 text-white rounded-full p-0.5 shadow-sm hover:bg-red-600 transition-colors animate-in zoom-in duration-200"
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
                                                className={`w-10 h-10 rounded-lg object-cover transition-all ${isDeleteMode ? 'shake-animation opacity-90' : ''}`}
                                                alt={m.wxId}
                                            />
                                            <span className="text-[10px] text-slate-500 truncate w-full text-center">{m.wxId || ('用户 ' + m.userId)}</span>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* Existing Modals */}
            {
                showCreateGroup && (
                    <div className="fixed inset-0 bg-black/50 z-[60] flex items-center justify-center">
                        <div className="bg-white p-6 rounded-lg w-96 shadow-xl max-h-[80vh] flex flex-col">
                            <h3 className="font-bold mb-4">发起群聊</h3>
                            <div className="mb-4">
                                <label className="text-xs text-slate-500 mb-1 block">群名称 (选填)</label>
                                <input
                                    className="w-full border p-2 rounded text-sm"
                                    placeholder="例如：项目组"
                                    value={groupNameInput}
                                    onChange={e => setGroupNameInput(e.target.value)}
                                />
                            </div>

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
                                <button onClick={() => { setShowCreateGroup(false); setSelectedUserIds([]); }} className="px-3 py-1 text-slate-500">取消</button>
                                <button
                                    onClick={handleCreateGroup}
                                    disabled={selectedUserIds.length === 0}
                                    className={`px-3 py-1 text-white rounded transition-colors ${selectedUserIds.length > 0 ? 'bg-[#07C160]' : 'bg-slate-300 cursor-not-allowed'}`}
                                >
                                    创建 ({selectedUserIds.length})
                                </button>
                            </div>
                        </div>
                    </div>
                )
            }
            {/* Add Member Modal */}
            {
                showAddMember && (
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
                )
            }

            {/* Floating Action Button */}
            <motion.button
                layout
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => setIsOpen(!isOpen)}
                className={`
                    ${isOpen ? 'bg-gradient-to-r from-red-500 to-red-600' : 'bg-gradient-to-r from-indigo-500 to-purple-600'} 
                    ${!isOpen && totalUnread > 0 ? 'animate-pulse ring-4 ring-red-400/50' : ''}
                    text-white p-4 rounded-full shadow-xl shadow-indigo-500/30 hover:shadow-2xl hover:shadow-indigo-500/40 
                    transition-all duration-300 flex items-center justify-center relative group backdrop-blur-sm z-50
                `}
            >
                <div className="relative z-10">
                    {isOpen ? <X size={26} /> : <MessageCircle size={26} fill="currentColor" className="text-white/20" strokeWidth={1.5} />}
                    {!isOpen && <MessageCircle size={26} className="absolute inset-0 text-white" strokeWidth={2} />}
                </div>

                {/* Unread Indicator */}
                <AnimatePresence>
                    {!isOpen && totalUnread > 0 && (
                        <motion.span
                            initial={{ scale: 0 }}
                            animate={{ scale: 1 }}
                            exit={{ scale: 0 }}
                            className="absolute -top-1 -right-1 min-w-[18px] h-[18px] bg-red-500 text-white text-[10px] font-bold flex items-center justify-center rounded-full border-2 border-white px-1 shadow-sm"
                        >
                            {totalUnread}
                        </motion.span>
                    )}
                </AnimatePresence>
            </motion.button>
        </div >
    );
};

export default ChatWidget;
