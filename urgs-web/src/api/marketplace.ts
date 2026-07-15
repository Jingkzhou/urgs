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
    id?: string;
    title: string;
    description?: string;
    taskType?: string;
    difficulty?: string;
    involvedSystemIds?: number[];
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

export type TaskStage = 'TEST_SUBMISSION_COMPLETED' | 'QUALITY_ACCEPTANCE_COMPLETED' | 'ASSET_REVIEW' | 'LAUNCH';

export interface TaskAuditLogDTO {
    id: string;
    taskId: string;
    operatorId?: string;
    operatorName?: string;
    action: string;
    detail?: string;
    createTime: string;
}

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
    involvedSystemIds?: number[];
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
    assetMaintenanceSnapshot?: string;
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
    auditLogs?: TaskAuditLogDTO[];
    assetMaintenanceRecords?: AssetMaintenanceRecord[];
    assetMaintenanceSnapshotFinalized?: boolean;
}

export interface TaskMarketDTO extends WorkTask {
    workTitle: string;
    workDescription?: string;
    workPriority?: string;
    workTotalPoints?: number;
    workStatus?: string;
    workPublisherId?: string;
    workDeadline?: string;
    requirementNumber?: string;
    applicationDepartment?: string;
    applicantName?: string;
    owningSystem?: string;
    primarySystem?: boolean;
    primarySystemName?: string;
    projectType?: string;
    attachments?: string;
    workCreateTime?: string;
    workUpdateTime?: string;
    publisherName: string;
    publisherAvatar: string;
    assigneeName?: string;
    applicationCount: number;
    versionChangeSnapshots?: TaskVersionChangeSnapshot[];
}

export interface TaskVersionChangeSnapshot {
    id: number;
    taskId: string;
    workId?: string;
    requirementNumber?: string;
    assigneeId?: string;
    reviewerId?: string;
    repoId?: number;
    repoName?: string;
    prNumber?: number;
    prTitle?: string;
    prUrl?: string;
    sourceBranch?: string;
    targetBranch?: string;
    state?: string;
    merged?: boolean;
    mergedAt?: string;
    matchSource?: string;
    commitCount?: number;
    fileCount?: number;
    additions?: number;
    deletions?: number;
    snapshotJson?: string;
    createdAt?: string;
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

export interface TaskReviewDTO {
    decision: 'APPROVE' | 'REJECT' | 'CANCEL' | 'TRANSFER';
    qualityScore?: number;
    reviewComment?: string;
    bonusPoints?: number;
    penaltyPoints?: number;
    transferAssigneeId?: string;
}

export interface TaskReviewHistoryDTO {
    id: string;
    taskId: string;
    taskTitle: string;
    taskStatus?: string;
    workId?: string;
    workTitle?: string;
    requirementNumber?: string;
    reviewType: 'ASSET_REVIEW' | 'ACCEPTANCE';
    decision: 'APPROVE' | 'REJECT' | 'CANCEL' | 'TRANSFER' | string;
    action: string;
    detail?: string;
    reviewerId?: string;
    reviewerName?: string;
    reviewedAt: string;
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
    pausedTaskCount: number;
}

export interface TeamKpiDTO {
    totalWorks: number;
    completedWorks: number;
    inProgressTasks: number;
    pausedTasks: number;
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
    targetTaskId?: string;
    targetWorkId?: string;
}

export interface WorkStatisticsGroupCount {
    name: string;
    value: number;
}

export interface WorkStatisticsTrendItem {
    date: string;
    createdWorkCount: number;
    completedWorkCount: number;
}

export interface WorkStatisticsAssigneeWorkload {
    assigneeId: string;
    totalCount: number;
    completedCount: number;
    activeCount: number;
    pausedCount: number;
    overdueCount: number;
}

export interface WorkStatisticsSystemTask {
    systemName: string;
    requirementCount: number;
    totalTaskCount: number;
    completedTaskCount: number;
    overdueTaskCount: number;
    completionRate: number;
}

export interface WorkStatisticsAttentionItem {
    workId: string;
    workTitle: string;
    taskId: string;
    taskTitle: string;
    taskRole?: 'MAIN' | 'SUB';
    assigneeId?: string;
    status: string;
    deadline?: string;
    overdue: boolean;
    attentionType?: 'TEST_SUBMISSION' | 'QUALITY_ACCEPTANCE';
    attentionMessage?: string;
    remainingWorkdays?: number;
}

export interface WorkCalendarTask {
    workId: string;
    workTitle: string;
    taskId: string;
    taskTitle: string;
    assigneeId?: string;
    status: string;
    deadline: string;
}

export interface WorkStatistics {
    startDate: string;
    endDate: string;
    totalWorks: number;
    completedWorks: number;
    totalTasks: number;
    completedTasks: number;
    activeTasks: number;
    overdueTasks: number;
    riskTasks: number;
    completionRate: number;
    workStatusDistribution: WorkStatisticsGroupCount[];
    taskStatusDistribution: WorkStatisticsGroupCount[];
    systemTaskStats: WorkStatisticsSystemTask[];
    workTrend: WorkStatisticsTrendItem[];
    assigneeWorkloads: WorkStatisticsAssigneeWorkload[];
    attentionItems: WorkStatisticsAttentionItem[];
}

export interface AssetMaintenanceRecord {
    id?: string;
    tableName?: string;
    tableCnName?: string;
    modType?: string;
    fieldName?: string;
    fieldCnName?: string;
    time?: string;
    plannedDate?: string;
    operator?: string;
    reqId?: string;
    reqName?: string;
    description?: string;
    script?: string;
    systemCode?: string;
    assetType?: string;
}

export interface ModelTableAsset {
    id: string;
    name: string;
    cnName?: string;
    owner?: string;
    dataSourceId?: number;
    subjectCode?: string;
    subjectName?: string;
    theme?: string;
    businessScope?: string;
    freq?: string;
    version?: string;
    retentionTime?: string;
    remark?: string;
    createTime?: string;
    updateTime?: string;
}

export interface ModelFieldAsset {
    id: string;
    tableId: string;
    name: string;
    cnName?: string;
    type?: string;
    isPk?: boolean;
    nullable?: boolean;
    domain?: string;
    remark?: string;
    sortOrder?: number;
    createTime?: string;
    updateTime?: string;
}

export interface PageResponse<T> {
    records: T[];
    total?: number;
    current?: number;
    size?: number;
}

// APIs
export const createWork = (data: WorkCreateDTO) => post('/api/marketplace/works', data);
export const updateWork = (id: string, data: WorkCreateDTO) => put(`/api/marketplace/works/${id}`, data);
export const importWorks = (works: WorkImportDTO[]) =>
    post<WorkImportResult>('/api/marketplace/works/import', works);
export const listWorks = (params: {
    current: number;
    size: number;
    keyword?: string;
    status?: string;
    deadlineStart?: string;
    deadlineEnd?: string;
}) =>
    get('/api/marketplace/works', params);
export const getWorkStatistics = (params: { startDate: string; endDate: string }) =>
    get<WorkStatistics>('/api/marketplace/works/statistics', params);
export const getIncompleteWorkCalendarTasks = (params: { startDate: string; endDate: string }) =>
    get<WorkCalendarTask[]>('/api/marketplace/works/calendar-tasks', params);
export const getWorkDetail = (id: string) => get<Work>(`/api/marketplace/works/${id}`);
export const getWorkTasks = (workId: string) => get(`/api/marketplace/tasks/work/${workId}`);
export const addTaskToWork = (workId: string, data: WorkTaskCreateDTO) => post(`/api/marketplace/tasks/work/${workId}`, data);
export const publishWork = (id: string) => put(`/api/marketplace/works/${id}/publish`);
export const cancelWork = (id: string) => put(`/api/marketplace/works/${id}/cancel`);
export const pauseWork = (id: string) => put(`/api/marketplace/works/${id}/pause`);
export const resumeWork = (id: string) => put(`/api/marketplace/works/${id}/resume`);
export const batchDeleteWorks = (ids: string[]) => post<{ deletedCount: number }>('/api/marketplace/works/batch-delete', { ids });

export const getMarketTasks = (params: any) => get('/api/marketplace/tasks', params);
export const getTaskDetail = (id: string) => get<TaskMarketDTO>(`/api/marketplace/tasks/${id}`);
export const getMyTasks = (params: {
    current: number;
    size: number;
    archived?: boolean;
    status?: string;
    overdue?: boolean;
    deadlineStart?: string;
    deadlineEnd?: string;
}) =>
    get<PageResponse<TaskMarketDTO>>('/api/marketplace/tasks/my', params);
export const getAssigneeTasks = (userId: string, params: {
    current: number;
    size: number;
    status?: string;
    deadlineStart?: string;
    deadlineEnd?: string;
}) =>
    get<PageResponse<TaskMarketDTO>>(`/api/marketplace/tasks/assignee/${encodeURIComponent(userId)}`, params);
export const getPendingReviewTasks = (params: any) => get<PageResponse<TaskMarketDTO>>('/api/marketplace/tasks/review/pending', params);
export const getReviewHistoryTasks = (params: any) => get<PageResponse<TaskReviewHistoryDTO>>('/api/marketplace/tasks/review/history', params);
export const claimTask = (id: string) => post(`/api/marketplace/tasks/${id}/claim`);
export const releaseTask = (id: string) => put(`/api/marketplace/tasks/${id}/release`);
export const reopenTask = (id: string) => put(`/api/marketplace/tasks/${id}/reopen`);
export const advanceTaskStage = (id: string, data?: { assetReviewNote?: string }) =>
    put(`/api/marketplace/tasks/${id}/stage/advance`, data);
export const reportTaskStageRisk = (id: string, data: { riskNote: string }) => put(`/api/marketplace/tasks/${id}/stage/risk`, data);
export const appendTaskRiskTracking = (id: string, data: { trackingNote: string }) =>
    put(`/api/marketplace/tasks/${id}/stage/risk/tracking`, data);
export const reviewTask = (id: string, data: TaskReviewDTO) => put(`/api/marketplace/tasks/${id}/review`, data);

export const applyForTask = (data: TaskApplicationRequest) => post('/api/marketplace/applications/apply', data);
export const approveApplication = (id: string, data?: { reviewComment?: string }) => put(`/api/marketplace/applications/${id}/approve`, data || {});
export const rejectApplication = (id: string, data?: { reviewComment?: string }) => put(`/api/marketplace/applications/${id}/reject`, data || {});
export const withdrawApplication = (id: string) => put(`/api/marketplace/applications/${id}/withdraw`);
export const getTaskApplications = (taskId: string, params: any) => get(`/api/marketplace/applications/task/${taskId}`, params);
export const getMyTaskApplications = (params: any) => get('/api/marketplace/applications/my', params);

export const getKpiSummary = (params: { userId?: string; startDate?: string; endDate?: string }) =>
    get<KpiSummaryDTO>('/api/marketplace/kpi/summary', params);
export const getTeamKpi = (params: { startDate?: string; endDate?: string }) =>
    get<TeamKpiDTO>('/api/marketplace/kpi/team', params);
export const getKpiSnapshots = (params: { period?: string }) =>
    get<KpiSnapshot[]>('/api/marketplace/kpi/snapshots', params);
export const generateKpiSnapshot = (period: string) =>
    post<KpiSnapshot[]>('/api/marketplace/kpi/snapshots/generate', undefined, { params: { period } });
export const createTaskAppeal = (taskId: string, data: { reason?: string; expectedResult?: string }) => post(`/api/marketplace/appeals/task/${taskId}`, data);

export const listPointRules = (params?: any) => get('/api/marketplace/point-rules', params);
export const createPointRule = (data: MarketplacePointRule) => post('/api/marketplace/point-rules', data);
export const updatePointRule = (id: string, data: MarketplacePointRule) => put(`/api/marketplace/point-rules/${id}`, data);
export const deletePointRule = (id: string) => del(`/api/marketplace/point-rules/${id}`);
export const getMarketplaceTodos = () => get('/api/marketplace/todos');
export const listAssetMaintenanceRecords = (params: {
    reqId?: string;
    page?: number;
    size?: number;
}) => get<PageResponse<AssetMaintenanceRecord>>('/api/metadata/maintenance-record', params);

export const listRegAssetTables = (params: {
    keyword?: string;
    systemCode?: string;
    page?: number;
    size?: number;
}) => get<PageResponse<any>>('/api/reg/table/list', params);

export const getRegAssetTable = (id: number | string) => get<any>(`/api/reg/table/${id}`);

export const listRegAssetElements = (params: {
    tableId: number | string;
    keyword?: string;
    page?: number;
    size?: number;
}) => get<PageResponse<any>>('/api/reg/element/list', params);

export const listModelAssetTables = (params: {
    keyword?: string;
    page?: number;
    size?: number;
}) => get<PageResponse<ModelTableAsset>>('/api/metadata/model-table', params);

export const listModelAssetFields = (tableId: string) =>
    get<ModelFieldAsset[]>('/api/metadata/model-field', { tableId });
