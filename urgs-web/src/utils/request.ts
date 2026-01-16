export interface RequestOptions extends RequestInit {
    params?: Record<string, string | number | boolean | undefined | null>;
    isBlob?: boolean;
}

export const request = async <T = any>(url: string, options: RequestOptions = {}): Promise<T> => {
    const token = localStorage.getItem('auth_token');

    const headers = new Headers(options.headers);
    if (token) {
        headers.set('Authorization', `Bearer ${token}`);
    }

    // Default to JSON content type if body is present and not FormData
    if (options.body && !(options.body instanceof FormData) && !headers.has('Content-Type')) {
        headers.set('Content-Type', 'application/json');
    }

    let fetchUrl = url;
    if (options.params) {
        const params = new URLSearchParams();
        Object.entries(options.params).forEach(([key, value]) => {
            if (value !== undefined && value !== null) {
                params.append(key, String(value));
            }
        });
        fetchUrl = `${url}?${params.toString()}`;
    }

    const response = await fetch(fetchUrl, {
        ...options,
        headers,
    });

    if (response.status === 401) {
        // Handle 401 Unauthorized - Centralized logout logic
        localStorage.removeItem('auth_token');
        localStorage.removeItem('auth_user');
        localStorage.removeItem('user_permissions');
        // Use hash-friendly redirect or just reload to trigger App's re-render
        window.location.href = '/';
        throw new Error('Unauthorized');
    }

    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText || `Request failed with status ${response.status}`);
    }

    // Return null for 204 No Content
    if (response.status === 204) {
        return null as T;
    }

    if (options.isBlob) {
        return await response.blob() as unknown as T;
    }

    try {
        return await response.json();
    } catch (e) {
        // Fallback for non-JSON responses
        return null as T;
    }
};

export const get = <T = any>(url: string, params?: RequestOptions['params'], options?: RequestOptions) => {
    return request<T>(url, { ...options, method: 'GET', params });
};

export const post = <T = any>(url: string, data?: any, options?: RequestOptions) => {
    const isFormData = data instanceof FormData;
    return request<T>(url, {
        ...options,
        method: 'POST',
        body: isFormData ? data : JSON.stringify(data)
    });
};

export const put = <T = any>(url: string, data?: any, options?: RequestOptions) => {
    const isFormData = data instanceof FormData;
    return request<T>(url, {
        ...options,
        method: 'PUT',
        body: isFormData ? data : JSON.stringify(data)
    });
};

export const del = <T = any>(url: string, params?: RequestOptions['params'], options?: RequestOptions) => {
    return request<T>(url, { ...options, method: 'DELETE', params });
};
