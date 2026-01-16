import axios from 'axios';
import { get, post } from '@/utils/request';

// Interfaces matching Backend Entities
export interface ImUser {
    userId: number;
    wxId: string;
    avatarUrl: string;
    signature: string;
}

export interface ImMessage {
    id?: number;
    conversationId?: string;
    senderId: number;
    receiverId?: number;
    groupId?: number;
    msgType: number; // 1: Text
    content: string;
    sendTime?: string;
    senderName?: string;
    senderAvatar?: string;
}

export interface ImSession {
    id: number;
    peerId: number;
    chatType: number; // 1: Private, 2: Group
    name: string; // aggregated from User/Group
    avatar: string;
    lastMsgContent: string;
    lastMsgTime: string;
    unreadCount: number;
}

const API_BASE = '/api/im';

export const imService = {
    // Session List
    getSessions: async () => { // Removed userId param
        const response = await get<ImSession[]>(`${API_BASE}/sessions`);
        return response;
    },

    getUsers: async () => {
        const response = await get<ImUser[]>(`${API_BASE}/users`);
        return response;
    },

    getMyInfo: async () => {
        const response = await get<ImUser>(`${API_BASE}/user/me`);
        return response;
    },

    searchUsers: (keyword: string) => get<ImUser[]>(`/api/im/users/search?keyword=${keyword}`),

    // Chat History
    getHistory: async (conversationId: string, limit = 20) => {
        // userId injected by interceptor
        const response = await get<ImMessage[]>(`${API_BASE}/chat/history`, {
            conversationId, limit: limit.toString()
        });
        return response;
    },

    // Send Message
    sendMessage: async (message: ImMessage) => {
        // senderId handled by backend
        const response = await post(`${API_BASE}/chat/send`, message);
        return response;
    },

    // Friend & Group
    addFriend: async (friendId: number, remark: string) => { // Removed userId
        const response = await post(`${API_BASE}/friend/add?friendId=${friendId}&remark=${remark}`);
        return response;
    },

    // Groups
    createGroup: async (name: string, userIds: number[]) => {
        return post<any>(`${API_BASE}/group/create`, { name, members: userIds });
    },

    getGroupMembers: async (groupId: number) => {
        return get<ImUser[]>(`${API_BASE}/group/${groupId}/members`);
    },

    // Session
    clearUnread: async (peerId: number) => {
        return post<any>(`${API_BASE}/session/${peerId}/read`, {});
    },

    deleteSession: async (peerId: number) => {
        // DELETE request
        return axios.delete(`${API_BASE}/session/${peerId}`, {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
    },

    addGroupMembers: async (groupId: number, memberIds: number[]) => {
        const response = await axios.post(`${API_BASE}/group/addMembers`, { groupId, memberIds }, {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
        return response.data; // "success"
    },

    removeGroupMembers: async (groupId: number, memberIds: number[]) => {
        const response = await axios.post(`${API_BASE}/group/kick`, { groupId, memberIds }, {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('auth_token')}` }
        });
        return response.data;
    }
};
