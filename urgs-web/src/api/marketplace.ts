import { get, post, put, del } from '../utils/request';

// Definitions matching backend DTOs
export interface WorkCreateDTO {
    title: string;
    description?: string;
    background?: string;
    businessValue?: string;
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
    taskType?: string;
    difficulty?: string;
    requiredSkills?: string;
    acceptanceCriteria?: string;
    points?: number;
    estimatedHours?: number;
    assignMode?: string;
    assigneeId?: string;
    maxApplicants?: number;
    deadline?: string;
}

export interface Work {
    id: string;
    title: string;
    description: string;
    background?: string;
    businessValue?: string;
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
    taskType?: string;
    difficulty?: string;
    requiredSkills: string;
    acceptanceCriteria?: string;
    points: number;
    estimatedHours?: number;
    assignMode: string;
    status: string;
    assigneeId: string;
    maxApplicants: number;
    deadline: string;
    completionDescription?: string;
    deliverables?: string;
    actualHours?: number;
    impactScope?: string;
    delayReported?: boolean;
    delayReason?: string;
    qualityScore?: number;
    reviewComment?: string;
    reviewerId?: string;
    submittedAt?: string;
    reviewedAt?: string;
    reworkCount?: number;
    bonusPoints?: number;
    penaltyPoints?: number;
    finalPoints?: number;
    kpiPeriod?: string;
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

export interface TaskSubmissionDTO {
    completionDescription?: string;
    deliverables?: string;
    actualHours?: number;
    impactScope?: string;
    delayReported?: boolean;
    delayReason?: string;
}

export interface TaskReviewDTO {
    decision: 'APPROVE' | 'REJECT' | 'CANCEL' | 'TRANSFER';
    qualityScore?: number;
    reviewComment?: string;
    bonusPoints?: number;
    penaltyPoints?: number;
    transferAssigneeId?: string;
}

export interface KpiSummaryDTO {
    userId: string;
    userName: string;
    completedTaskCount: number;
    basePoints: number;
    finalPoints: number;
    onTimeRate: number;
    averageQualityScore: number;
    reworkCount: number;
    overdueCount: number;
    highPriorityTaskCount: number;
    activeTaskCount: number;
}

export interface KpiDetailDTO {
    taskId: string;
    taskTitle: string;
    workId: string;
    workTitle: string;
    requirementNumber?: string;
    assigneeId: string;
    assigneeName: string;
    basePoints: number;
    finalPoints: number;
    qualityScore?: number;
    reworkCount: number;
    onTime: boolean;
    actualHours?: number;
    reviewerId?: string;
    reviewComment?: string;
    reviewedAt?: string;
}

export interface TeamKpiDTO {
    totalWorks: number;
    completedWorks: number;
    inProgressTasks: number;
    overdueTasks: number;
    totalPointPool: number;
    settledPoints: number;
    rankings: KpiSummaryDTO[];
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
export const getPendingReviewTasks = (params: any) => get('/api/marketplace/tasks/review/pending', params);
export const getReviewHistoryTasks = (params: any) => get('/api/marketplace/tasks/review/history', params);
export const claimTask = (id: string) => post(`/api/marketplace/tasks/${id}/claim`);
export const releaseTask = (id: string) => put(`/api/marketplace/tasks/${id}/release`);
export const assignTask = (id: string, assigneeId: string) => put(`/api/marketplace/tasks/${id}/assign`, { assigneeId });
export const updateTaskStatus = (id: string, status: string) => put(`/api/marketplace/tasks/${id}/status`, { status });
export const submitTaskForReview = (id: string, data: TaskSubmissionDTO) => put(`/api/marketplace/tasks/${id}/submit`, data);
export const reviewTask = (id: string, data: TaskReviewDTO) => put(`/api/marketplace/tasks/${id}/review`, data);

export const applyForTask = (taskId: string, message: string) => post('/api/marketplace/applications/apply', { taskId, message });
export const approveApplication = (id: string) => put(`/api/marketplace/applications/${id}/approve`);
export const rejectApplication = (id: string) => put(`/api/marketplace/applications/${id}/reject`);
export const getTaskApplications = (taskId: string, params: any) => get(`/api/marketplace/applications/task/${taskId}`, params);

export const getKpiSummary = (params: any) => get('/api/marketplace/kpi/summary', params);
export const getKpiDetails = (params: any) => get('/api/marketplace/kpi/details', params);
export const getTeamKpi = (params: any) => get('/api/marketplace/kpi/team', params);
export const getKpiLeaderboard = (params: any) => get('/api/marketplace/kpi/leaderboard', params);
export const createTaskAppeal = (taskId: string, data: { reason?: string; expectedResult?: string }) => post(`/api/marketplace/appeals/task/${taskId}`, data);
export const resolveTaskAppeal = (id: string, data: { resolution?: string }) => put(`/api/marketplace/appeals/${id}/resolve`, data);
export const listTaskAppeals = (params: any) => get('/api/marketplace/appeals', params);
