import { get, post, put, del } from '../utils/request';

// Definitions matching backend DTOs
export interface WorkCreateDTO {
    title: string;
    description?: string;
    category?: string;
    priority?: string;
    deadline?: string;
    requirementNumber?: string;
    attachments?: any[];
    tasks?: WorkTaskCreateDTO[];
}

export interface WorkTaskCreateDTO {
    title: string;
    description?: string;
    requiredSkills?: string;
    points?: number;
    assignMode?: string;
    assigneeId?: string;
    maxApplicants?: number;
    deadline?: string;
}

export interface Work {
    id: string;
    title: string;
    description: string;
    category: string;
    priority: string;
    totalPoints: number;
    status: string;
    publisherId: string;
    deadline: string;
    requirementNumber?: string;
    attachments?: string;
    createTime: string;
    updateTime: string;
}

export interface WorkTask {
    id: string;
    workId: string;
    title: string;
    description: string;
    requiredSkills: string;
    points: number;
    assignMode: string;
    status: string;
    assigneeId: string;
    maxApplicants: number;
    deadline: string;
    sortOrder: number;
    createTime: string;
    updateTime: string;
}

export interface TaskMarketDTO extends WorkTask {
    workTitle: string;
    publisherName: string;
    publisherAvatar: string;
    applicationCount: number;
}

export interface TaskApplication {
    id: string;
    taskId: string;
    applicantId: string;
    message: string;
    status: string;
    createTime: string;
    updateTime: string;
}

// APIs
export const createWork = (data: WorkCreateDTO) => post('/api/marketplace/works', data);
export const listWorks = (params: any) => get('/api/marketplace/works', params);
export const getWorkDetail = (id: string) => get(`/api/marketplace/works/${id}`);
export const getWorkTasks = (workId: string) => get(`/api/marketplace/tasks/work/${workId}`);
export const addTaskToWork = (workId: string, data: WorkTaskCreateDTO) => post(`/api/marketplace/tasks/work/${workId}`, data);
export const publishWork = (id: string) => put(`/api/marketplace/works/${id}/publish`);
export const cancelWork = (id: string) => put(`/api/marketplace/works/${id}/cancel`);

export const getMarketTasks = (params: any) => get('/api/marketplace/tasks', params);
export const getTaskDetail = (id: string) => get(`/api/marketplace/tasks/${id}`);
export const getMyTasks = (params: any) => get('/api/marketplace/tasks/my', params);
export const claimTask = (id: string) => post(`/api/marketplace/tasks/${id}/claim`);
export const assignTask = (id: string, assigneeId: string) => put(`/api/marketplace/tasks/${id}/assign`, { assigneeId });
export const updateTaskStatus = (id: string, status: string) => put(`/api/marketplace/tasks/${id}/status`, { status });

export const applyForTask = (taskId: string, message: string) => post('/api/marketplace/applications/apply', { taskId, message });
export const approveApplication = (id: string) => put(`/api/marketplace/applications/${id}/approve`);
export const rejectApplication = (id: string) => put(`/api/marketplace/applications/${id}/reject`);
export const getTaskApplications = (taskId: string, params: any) => get(`/api/marketplace/applications/task/${taskId}`, params);
