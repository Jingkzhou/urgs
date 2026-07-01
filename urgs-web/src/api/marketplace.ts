import { get, post, put, del } from '../utils/request';

// Definitions matching backend DTOs
export interface WorkCreateDTO {
    title: string;
    description?: string;
    priority?: string;
    deadline?: string;
    requirementNumber?: string;
    applicationDepartment?: string;
    applicantName?: string;
    owningSystem?: string;
    primarySystem?: boolean;
    primarySystemName?: string;
    projectType?: '变更类' | '仅配合';
    mainTask: WorkTaskCreateDTO;
    attachments?: any[];
    tasks?: WorkTaskCreateDTO[];
}

export interface WorkImportDTO {
    title: string;
    description: string;
    priority: 'P0' | 'P1' | 'P2' | 'P3';
    deadline?: string;
    requirementNumber?: string;
    applicationDepartment: string;
    applicantName: string;
    owningSystem: string;
    primarySystem: boolean;
    primarySystemName?: string;
    projectType: '变更类' | '仅配合';
}

export interface WorkImportResult {
    importedCount: number;
}

export interface WorkTaskCreateDTO {
    title: string;
    description?: string;
    taskType?: string;
    difficulty?: string;
    requiredSkills?: string;
    acceptanceCriteria?: string;
    points?: number;
    assignMode?: string;
    assigneeId?: string;
    maxApplicants?: number;
    deadline?: string;
    taskRole?: 'MAIN' | 'SUB';
    parentTaskId?: string;
    currentStage?: TaskStage;
    stageRiskReported?: boolean;
    stageRiskNote?: string;
    stageUpdatedAt?: string;
}

export type TaskStage = 'REQUIREMENT' | 'DEVELOPMENT' | 'TESTING' | 'LAUNCH';

export interface Work {
    id: string;
    title: string;
    description: string;
    priority: string;
    totalPoints: number;
    status: string;
    publisherId: string;
    deadline: string;
    requirementNumber?: string;
    applicationDepartment?: string;
    applicantName?: string;
    owningSystem?: string;
    primarySystem?: boolean;
    primarySystemName?: string;
    projectType?: string;
    attachments?: string;
    createTime: string;
    updateTime: string;
}

export interface WorkTask {
    id: string;
    workId: string;
    taskRole?: 'MAIN' | 'SUB';
    parentTaskId?: string;
    currentStage?: TaskStage;
    stageRiskReported?: boolean;
    stageRiskNote?: string;
    stageUpdatedAt?: string;
    title: string;
    description: string;
    taskType?: string;
    difficulty?: string;
    requiredSkills: string;
    acceptanceCriteria?: string;
    points: number;
    assignMode: string;
    status: string;
    assigneeId: string;
    maxApplicants: number;
    deadline: string;
    completionDescription?: string;
    deliverables?: string;
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
    taskTitle?: string;
    workId?: string;
    workTitle?: string;
    taskPoints?: number;
    applicantId: string;
    applicantName?: string;
    message: string;
    solution?: string;
    expectedCompletionTime?: string;
    status: string;
    reviewComment?: string;
    reviewedBy?: string;
    reviewedAt?: string;
    createTime: string;
    updateTime: string;
    completedTaskCount?: number;
    finalPoints?: number;
    onTimeRate?: number;
    averageQualityScore?: number;
    currentLoad?: number;
}

export interface TaskApplicationRequest {
    taskId: string;
    message: string;
    solution: string;
    expectedCompletionTime?: string;
}

export interface TaskSubmissionDTO {
    completionDescription?: string;
    deliverables?: string;
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

export interface MarketplacePointRule {
    id?: string;
    taskType: string;
    difficulty: string;
    suggestedPoints: number;
    description?: string;
    enabled?: boolean;
    createTime?: string;
    updateTime?: string;
}

export interface KpiSnapshot {
    id: string;
    period: string;
    userId: string;
    userName?: string;
    completedTaskCount: number;
    basePoints: number;
    finalPoints: number;
    onTimeRate: number;
    averageQualityScore: number;
    reworkCount: number;
    overdueCount: number;
    highPriorityTaskCount: number;
    activeTaskCount: number;
    status: string;
    generatedBy?: string;
    generatedAt?: string;
}

export interface MarketplaceTodo {
    type: string;
    title: string;
    description: string;
    count: number;
    targetTab: string;
    severity: 'info' | 'warning' | 'danger';
}

// APIs
export const createWork = (data: WorkCreateDTO) => post('/api/marketplace/works', data);
export const importWorks = (works: WorkImportDTO[]) =>
    post<WorkImportResult>('/api/marketplace/works/import', works);
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
export const advanceTaskStage = (id: string) => put(`/api/marketplace/tasks/${id}/stage/advance`);
export const reportTaskStageRisk = (id: string, data: { riskNote: string }) => put(`/api/marketplace/tasks/${id}/stage/risk`, data);
export const submitTaskForReview = (id: string, data: TaskSubmissionDTO) => put(`/api/marketplace/tasks/${id}/submit`, data);
export const reviewTask = (id: string, data: TaskReviewDTO) => put(`/api/marketplace/tasks/${id}/review`, data);

export const applyForTask = (data: TaskApplicationRequest) => post('/api/marketplace/applications/apply', data);
export const approveApplication = (id: string, data?: { reviewComment?: string }) => put(`/api/marketplace/applications/${id}/approve`, data || {});
export const rejectApplication = (id: string, data?: { reviewComment?: string }) => put(`/api/marketplace/applications/${id}/reject`, data || {});
export const withdrawApplication = (id: string) => put(`/api/marketplace/applications/${id}/withdraw`);
export const getTaskApplications = (taskId: string, params: any) => get(`/api/marketplace/applications/task/${taskId}`, params);
export const getMyTaskApplications = (params: any) => get('/api/marketplace/applications/my', params);

export const getKpiSummary = (params: any) => get('/api/marketplace/kpi/summary', params);
export const getKpiDetails = (params: any) => get('/api/marketplace/kpi/details', params);
export const getTeamKpi = (params: any) => get('/api/marketplace/kpi/team', params);
export const getKpiLeaderboard = (params: any) => get('/api/marketplace/kpi/leaderboard', params);
export const getKpiSnapshots = (params: any) => get('/api/marketplace/kpi/snapshots', params);
export const generateKpiSnapshot = (period: string) => post('/api/marketplace/kpi/snapshots/generate', undefined, { params: { period } });
export const createTaskAppeal = (taskId: string, data: { reason?: string; expectedResult?: string }) => post(`/api/marketplace/appeals/task/${taskId}`, data);
export const resolveTaskAppeal = (id: string, data: { resolution?: string }) => put(`/api/marketplace/appeals/${id}/resolve`, data);
export const listTaskAppeals = (params: any) => get('/api/marketplace/appeals', params);

export const listPointRules = (params?: any) => get('/api/marketplace/point-rules', params);
export const suggestPointRule = (params: { taskType: string; difficulty: string }) => get('/api/marketplace/point-rules/suggest', params);
export const createPointRule = (data: MarketplacePointRule) => post('/api/marketplace/point-rules', data);
export const updatePointRule = (id: string, data: MarketplacePointRule) => put(`/api/marketplace/point-rules/${id}`, data);
export const deletePointRule = (id: string) => del(`/api/marketplace/point-rules/${id}`);
export const getMarketplaceTodos = () => get('/api/marketplace/todos');
