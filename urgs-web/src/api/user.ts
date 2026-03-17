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
    orgName: string;
    empId: string;
    roleName: string;
    avatarUrl?: string;
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
