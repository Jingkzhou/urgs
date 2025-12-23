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
};
