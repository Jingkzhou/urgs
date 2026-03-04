import { request } from '../utils/request';

// Definitions matching backend DTOs
export interface WorkCreateDTO {
    title: string;
    description?: string;
    category?: string;
    priority?: string;
    deadline?: string;
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
export const createWork = (data: WorkCreateDTO) => request.post('/api/marketplace/works', data);
export const listWorks = (params: any) => request.get('/api/marketplace/works', { params });
export const publishWork = (id: string) => request.put(`/api/marketplace/works/${id}/publish`);
export const cancelWork = (id: string) => request.put(`/api/marketplace/works/${id}/cancel`);

export const getMarketTasks = (params: any) => request.get('/api/marketplace/tasks', { params });
export const getMyTasks = (params: any) => request.get('/api/marketplace/tasks/my', { params });
export const claimTask = (id: string) => request.post(`/api/marketplace/tasks/${id}/claim`);
export const assignTask = (id: string, assigneeId: string) => request.put(`/api/marketplace/tasks/${id}/assign`, { assigneeId });
export const updateTaskStatus = (id: string, status: string) => request.put(`/api/marketplace/tasks/${id}/status`, { status });

export const applyForTask = (taskId: string, message: string) => request.post('/api/marketplace/applications/apply', { taskId, message });
export const approveApplication = (id: string) => request.put(`/api/marketplace/applications/${id}/approve`);
export const rejectApplication = (id: string) => request.put(`/api/marketplace/applications/${id}/reject`);
export const getTaskApplications = (taskId: string, params: any) => request.get(`/api/marketplace/applications/task/${taskId}`, { params });
