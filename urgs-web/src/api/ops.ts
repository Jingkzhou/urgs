import { get, post, put, del } from '@/utils/request';

// ===== Infrastructure Asset API =====

export interface InfrastructureUser {
    id?: number;
    username: string;
    password?: string;
    description?: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface InfrastructureAsset {
    id?: number;
    hostname: string;
    internalIp: string;
    externalIp?: string;
    osType?: string;
    osVersion?: string;
    cpu?: string;
    memory?: string;
    disk?: string;
    hardwareModel?: string;
    role?: string;
    appSystemId?: number;
    envId?: number;
    envType?: string;
    users?: InfrastructureUser[];
    status: 'active' | 'maintenance' | 'offline';
    description?: string;
    createdAt?: string;
    updatedAt?: string;
}

export const getInfrastructureAssets = (params?: { appSystemId?: number; envId?: number; envType?: string }) =>
    get<InfrastructureAsset[]>('/api/ops/infrastructure', params || {});

export const createInfrastructureAsset = (data: InfrastructureAsset) =>
    post<InfrastructureAsset>('/api/ops/infrastructure', data);

export const updateInfrastructureAsset = (id: number, data: InfrastructureAsset) =>
    put<InfrastructureAsset>(`/api/ops/infrastructure/${id}`, data);

export const deleteInfrastructureAsset = (id: number) =>
    del(`/api/ops/infrastructure/${id}`);

export const exportInfrastructureAssets = () =>
    get<Blob>('/api/ops/infrastructure/export', undefined, { isBlob: true });

export const importInfrastructureAssets = (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return post<void>('/api/ops/infrastructure/import', formData);
};

// ===== Issue Tracking API =====

export interface Issue {
    id?: string;
    title: string;
    description: string;
    system: string;
    solution: string;
    occurTime: string;
    reporter: string;
    resolveTime: string;
    handler: string;
    issueType: '批量任务处理' | '报送支持' | '数据查询';
    status: '新建' | '处理中' | '完成' | '遗留';
    workHours: number;
}

export const getIssueList = (params: any) =>
    get<any>('/api/issue/list', params);

export const saveIssue = (data: Partial<Issue>) =>
    post<void>('/api/issue/save', data);

export const deleteIssue = (id: string) =>
    del(`/api/issue/${id}`);

export const exportIssues = (params: any) =>
    get<Blob>('/api/issue/export', params, { isBlob: true });

export const importIssues = (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return post<void>('/api/issue/import', formData);
};

export const streamSolutionGeneration = async (
    params: { systemPrompt: string; userPrompt: string },
    onChunk: (content: string) => void,
    onDone: () => void,
    onError: (error: string) => void
) => {
    try {
        const token = localStorage.getItem('auth_token');
        const response = await fetch('/api/ai/chat/stream', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(params)
        });

        if (!response.ok) {
            throw new Error('Failed to start generation');
        }

        const reader = response.body?.getReader();
        const decoder = new TextDecoder();

        if (!reader) return;

        let buffer = '';
        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value, { stream: true });
            buffer += chunk;
            const lines = buffer.split('\n');
            buffer = lines.pop() || '';

            for (const line of lines) {
                const trimmedLine = line.trim();
                if (!trimmedLine) continue;
                if (trimmedLine.startsWith('data:')) {
                    const dataStr = trimmedLine.replace(/^data:\s?/, '').trim();
                    if (dataStr === '[DONE]') {
                        onDone();
                        break;
                    }
                    try {
                        const parsed = JSON.parse(dataStr);
                        if (parsed.content) {
                            onChunk(parsed.content);
                        } else if (parsed.error) {
                            onError(parsed.error);
                        }
                    } catch (e) {
                        console.error('JSON parse error', e);
                    }
                }
            }
        }
    } catch (error: any) {
        console.error('Generation failed:', error);
        onError(error.message || 'Generation failed');
    }
};

// ===== User Management API =====

export interface User {
    id: number;
    empId: string;
    name: string;
    orgName: string;
}

export const searchUsers = (keyword: string) =>
    get<User[]>('/api/users', { keyword });

// ===== System API =====

export const getSystemList = () =>
    get<any[]>('/api/sys/system/list');

// ===== Task Scheduling API =====

export interface Task {
    id?: string;
    name: string;
    type: string;
    systemId: number | string;
    content: string;
    preTaskIds?: string[];
    cronExpression?: string;
    group?: string;
    status?: number;
    updateTime?: string;
}

export const getTaskList = (params: any) =>
    get<any>('/api/task/list', params);

export const saveTask = (data: Partial<Task>) =>
    post<string>('/api/task/save', data);

export const deleteTask = (id: string) =>
    del(`/api/task/${id}`);

export const batchUpdateTaskStatus = (ids: string[], status: number) =>
    post<string>('/api/task/batch-status', { ids, status });

export const getGlobalStats = () =>
    get<any>('/api/task/global-stats');

export const createTaskInstance = (taskId: string, dataDate: string) =>
    post<void>(`/api/task/instance/create`, null, { params: { taskId, dataDate } });

// ===== Task Instance API =====

export interface TaskInstance {
    id: string;
    taskId: string;
    taskType: string;
    dataDate: string;
    status: string;
    retryCount: number;
    startTime: string;
    endTime: string;
    createTime: string;
    systemId: number;
}

export const getTaskInstances = (params: any) =>
    get<TaskInstance[]>('/api/task/instance/list', params);

export const getTaskInstanceLog = (id: string) =>
    get<{ content: string }>(`/api/task/instance/log/${id}`);

export const rerunTaskInstance = (id: string, withDownstream: boolean = false) =>
    post<void>(`/api/task/instance/rerun/${id}`, null, { params: { withDownstream } });

export const batchRerunTaskInstances = (ids: string[], withDownstream: boolean = false) =>
    post<void>(`/api/task/instance/rerun/batch`, ids, { params: { withDownstream } });

export const stopTaskInstance = (id: string) =>
    post<void>(`/api/task/instance/stop/${id}`);

export const forceSuccessTaskInstance = (id: string) =>
    post<void>(`/api/task/instance/force-success/${id}`);

export const validateRerun = (id: string) =>
    get<string[]>(`/api/task/instance/validate-rerun/${id}`);

export const batchValidateRerun = (ids: string[]) =>
    post<Record<string, string[]>>('/api/task/instance/validate-rerun/batch', ids);

// ===== Workflow Management API =====

export interface Workflow {
    id?: string;
    realId?: number;
    name: string;
    owner: string;
    description?: string;
    content?: string;
    cron?: string;
    systemId?: number;
    nodes?: string[];
    edges?: { source: string; target: string }[];
}

export const getWorkflowList = () =>
    get<Workflow[]>('/api/workflow/list');

export const getWorkflowDetails = (id: number | string) =>
    get<Workflow>(`/api/workflow/${id}`);

export const saveWorkflow = (data: Partial<Workflow>) =>
    post<string>('/api/workflow/save', data);

export const deleteWorkflow = (id: number | string) =>
    del(`/api/workflow/${id}`);

// ===== Datasource API (Used in Forms) =====
export const getDatasourceMeta = () =>
    get<any>('/api/datasource/meta');

export const getDatasourceConfig = () =>
    get<any>('/api/datasource/config');
