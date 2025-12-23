import axios from 'axios';
import { get, post } from '@/utils/request';

const API_BASE = '/api/users';
const COMMON_API = '/api/common';

export interface User {
    id: string;
    empId: string;
    name: string;
    phone: string;
    email?: string;
    avatarUrl?: string; // New field
    roleName: string;
    roleId?: number; // Added for role association
    orgName: string;
}

export const userService = {
    // Check permissions
    getPermissions: async () => {
        return get<string[]>(`${API_BASE}/permissions`);
    },

    getProfile: async () => {
        return get<User>('/api/auth/profile');
    },

    searchUsers: async (keyword: string) => {
        return get<any[]>(`/api/im/users/search?keyword=${keyword}`);
    },

    // Upload File (Shared)
    uploadFile: async (file: File) => {
        const formData = new FormData();
        formData.append('file', file);
        const token = localStorage.getItem('auth_token');
        const response = await axios.post(`${COMMON_API}/upload`, formData, {
            headers: {
                'Content-Type': 'multipart/form-data',
                'Authorization': `Bearer ${token}`
            }
        });
        return response.data.url as string; // Common API returns { url: ... } or just string? Let's check CommonController.
        // CommonController returns map: { url: ..., name: ... }
        // Wait, ImFileController returned string?
        // Let's re-verify CommonController return type in next step if needed, assuming map based on code reading.
    },

    // Update Profile
    updateProfile: async (data: Partial<User>) => {
        return post<User>(`${API_BASE}/profile`, data);
    }
};
