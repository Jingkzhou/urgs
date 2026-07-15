export interface ChangePasswordRequest {
    oldPassword: string;
    newPassword: string;
}

export const changePassword = async (data: ChangePasswordRequest) => {
    const token = typeof localStorage !== 'undefined' ? localStorage.getItem('auth_token') : null;
    if (!token) throw new Error("No auth token");

    const res = await fetch('/api/users/change-password', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    });

    if (!res.ok) {
        const text = await res.text();
        throw new Error(text || "Unknown error");
    }
    return true;
}

export interface UserDTO {
    id: string | number;
    name: string;
    namePinyin?: string;
    namePinyinInitials?: string;
    orgName: string;
    empId: string;
    roleName: string;
    avatarUrl?: string;
}

export interface UserGitIdentity {
    id?: number;
    userId?: number;
    platform?: string;
    gitUsername?: string;
    gitEmail?: string;
    gitUserId?: string;
    enabled?: boolean;
}

export const searchUsers = async (keyword: string = ''): Promise<UserDTO[]> => {
    const token = typeof localStorage !== 'undefined' ? localStorage.getItem('auth_token') : null;
    const url = keyword ? `/api/users?keyword=${encodeURIComponent(keyword)}` : '/api/users';

    // Some routes might not require auth, but if they do, we pass it
    const headers: Record<string, string> = {
        'Content-Type': 'application/json'
    };
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const res = await fetch(url, { headers });
    if (!res.ok) {
        throw new Error("Failed to fetch users");
    }
    return res.json();
};

export const getUserGitIdentity = async (
    userId: string | number,
    platform: string = 'GITLAB'
): Promise<UserGitIdentity | null> => {
    const token = typeof localStorage !== 'undefined' ? localStorage.getItem('auth_token') : null;
    const headers: Record<string, string> = {
        'Content-Type': 'application/json'
    };
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const res = await fetch(`/api/users/${userId}/git-identity?platform=${encodeURIComponent(platform)}`, { headers });
    if (res.status === 204 || res.status === 404) {
        return null;
    }
    if (!res.ok) {
        throw new Error("Failed to fetch user git identity");
    }
    return res.json();
};
