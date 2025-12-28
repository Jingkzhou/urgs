import { get, post, put, del } from '@/utils/request';

// ===== 监管系统 (SsoConfig) =====

export interface SsoConfig {
    id: number;
    name: string;
    protocol?: string;
    clientId?: string;
    callbackUrl?: string;
    algorithm?: string;
    network?: string;
    status?: string;
}

export const getSsoList = () =>
    get<SsoConfig[]>('/api/sys/system/list');

// ===== Git 仓库 API =====

export interface GitRepository {
    id?: number;
    ssoId: number;
    platform: 'gitee' | 'gitlab' | 'github';
    name: string;
    fullName?: string;
    cloneUrl: string;
    sshUrl?: string;
    defaultBranch?: string;
    accessToken?: string;
    webhookSecret?: string;
    webhookUrl?: string;
    enabled?: boolean;
    lastSyncedAt?: string;
    createdAt?: string;
    updatedAt?: string;
}

export const getGitRepositories = (params?: { ssoId?: number; platform?: string }) =>
    get<GitRepository[]>('/api/version/repos', params || {});

export const getGitRepository = (id: number) =>
    get<GitRepository>(`/api/version/repos/${id}`);

export const createGitRepository = (data: GitRepository) =>
    post<GitRepository>('/api/version/repos', data);

export const updateGitRepository = (id: number, data: GitRepository) =>
    put<GitRepository>(`/api/version/repos/${id}`, data);

export const deleteGitRepository = (id: number) =>
    del(`/api/version/repos/${id}`);

// ===== Git 浏览器 API =====

export interface GitFileEntry {
    name: string;
    path: string;
    type: 'file' | 'dir';
    size?: number;
    sha?: string;
    lastCommitMessage?: string;
    lastCommitDate?: string;
}

export interface GitBranch {
    name: string;
    isDefault?: boolean;
    isProtected?: boolean;
    commitSha?: string;
    lastCommitDate?: string;
    lastCommitAuthor?: string;
    lastCommitMessage?: string;
}

export interface GitTag {
    name: string;
    message?: string;
    commitSha?: string;
    commitMessage?: string;
    taggerName?: string;
    taggerDate?: string;
}

export interface GitCommit {
    sha: string;
    fullSha?: string;
    message: string;
    authorName: string;
    authorEmail?: string;
    authorAvatar?: string;
    committedAt: string;
    totalCommits?: number;
    diffs?: GitCommitDiff[];
}

export interface GitCommitDiff {
    oldPath: string;
    newPath: string;
    status: string;
    newFile?: boolean;
    renamedFile?: boolean;
    deletedFile?: boolean;
    additions?: number;
    deletions?: number;
    diff: string;
}

export const getRepoFileTree = (repoId: number, ref?: string, path?: string) =>
    get<GitFileEntry[]>(`/api/version/repos/${repoId}/tree`, { ref: ref || '', path: path || '' });

export const getRepoBranches = (repoId: number) =>
    get<GitBranch[]>(`/api/version/repos/${repoId}/branches`);

export const getRepoTags = (repoId: number) =>
    get<GitTag[]>(`/api/version/repos/${repoId}/tags`);

export const createRepoBranch = (repoId: number, name: string, ref: string) =>
    post<void>(`/api/version/repos/${repoId}/branches`, null, { params: { name, ref } });

export const deleteRepoBranch = (repoId: number, name: string) =>
    del<void>(`/api/version/repos/${repoId}/branches/${name}`);

export const createRepoTag = (repoId: number, name: string, ref: string, message?: string) =>
    post<void>(`/api/version/repos/${repoId}/tags`, null, { params: { name, ref, message } });

export const deleteRepoTag = (repoId: number, name: string) =>
    del<void>(`/api/version/repos/${repoId}/tags/${name}`);

export const getDownloadArchiveUrl = (repoId: number, ref: string) =>
    `/api/version/repos/${repoId}/archive?ref=${encodeURIComponent(ref)}`;

export const downloadRepoArchive = (repoId: number, ref: string) =>
    get<Blob>(`/api/version/repos/${repoId}/archive`, { ref }, { isBlob: true });

export const getRepoLatestCommit = (repoId: number, ref?: string) =>
    get<GitCommit>(`/api/version/repos/${repoId}/commits/latest`, { ref: ref || '' });

export interface GitFileContent {
    name: string;
    path: string;
    size: number;
    content: string;
    encoding?: string;
    sha?: string;
    language?: string;
}

export const getRepoFileContent = (repoId: number, path: string, ref?: string) =>
    get<GitFileContent>(`/api/version/repos/${repoId}/file`, { path, ref: ref || '' });

export const getRepoCommits = (repoId: number, params?: { ref?: string; page?: number; perPage?: number }) =>
    get<GitCommit[]>(`/api/version/repos/${repoId}/commits`, params || {});

export const getRepoCommitDetail = (repoId: number, sha: string) =>
    get<GitCommit>(`/api/version/repos/${repoId}/commits/${sha}`);

// ===== GitLab Sync API =====

export interface GitProjectVO {
    id: string;
    name: string;
    pathWithNamespace: string;
    description?: string;
    webUrl: string;
    cloneUrl: string;
    sshUrl: string;
    defaultBranch: string;
    visibility: string;
    lastActivityAt?: string;
}

export interface GitImportRequest {
    systemId: number;
    projects: GitProjectVO[];
}

export const syncGitLabProjects = () =>
    get<GitProjectVO[]>('/api/version/repos/sync');

export const importGitRepositories = (data: GitImportRequest) =>
    post<void>('/api/version/repos/import', data);

// ===== 概览 API =====

export interface VersionOverviewData {
    totalApps: number;
    totalRepos: number;
    platforms: string[];
}

export const getVersionOverview = () =>
    get<VersionOverviewData>('/api/version/overview');

// ===== 流水线 API =====

export interface Pipeline {
    id?: number;
    name: string;
    ssoId: number;
    repoId?: number;
    stages?: string;  // JSON string
    triggerType?: 'manual' | 'webhook' | 'schedule';
    enabled?: boolean;
    createdAt?: string;
    updatedAt?: string;
}

export interface PipelineRun {
    id?: number;
    pipelineId: number;
    runNumber: number;
    triggerType?: string;
    branch?: string;
    commitId?: string;
    status: 'pending' | 'running' | 'success' | 'failed' | 'cancelled';
    startedAt?: string;
    finishedAt?: string;
    logs?: string;
    createdAt?: string;
}

export const getPipelines = (params?: { ssoId?: number; repoId?: number }) =>
    get<Pipeline[]>('/api/version/pipelines', params || {});

export const getPipeline = (id: number) =>
    get<Pipeline>(`/api/version/pipelines/${id}`);

export const createPipeline = (data: Pipeline) =>
    post<Pipeline>('/api/version/pipelines', data);

export const updatePipeline = (id: number, data: Pipeline) =>
    put<Pipeline>(`/api/version/pipelines/${id}`, data);

export const deletePipeline = (id: number) =>
    del(`/api/version/pipelines/${id}`);

export const getPipelineRuns = (pipelineId: number) =>
    get<PipelineRun[]>(`/api/version/pipelines/${pipelineId}/runs`);

export const getPipelineRun = (runId: number) =>
    get<PipelineRun>(`/api/version/pipelines/runs/${runId}`);

export const triggerPipeline = (pipelineId: number, params?: { branch?: string; triggerType?: string }) =>
    post<PipelineRun>(`/api/version/pipelines/${pipelineId}/trigger`, params || {});

export const cancelPipelineRun = (runId: number) =>
    post<void>(`/api/version/pipelines/runs/${runId}/cancel`, {});

// ===== 部署管理 API =====

export interface DeployEnvironment {
    id?: number;
    name: string;
    code: string;
    ssoId: number;
    deployUrl?: string;
    deployType?: 'ssh' | 'docker' | 'k8s';
    config?: string;
    sortOrder?: number;
    createdAt?: string;
    updatedAt?: string;
}

export interface Deployment {
    id?: number;
    ssoId: number;
    envId: number;
    strategyId?: number;
    pipelineRunId?: number;
    version?: string;
    artifactUrl?: string;
    status: 'pending' | 'deploying' | 'success' | 'failed' | 'rollback';
    deployedBy?: number;
    deployedAt?: string;
    rollbackTo?: number;
    logs?: string;
    remark?: string;
    createdAt?: string;
}

// 环境管理
export const getDeployEnvironments = (ssoId?: number) =>
    get<DeployEnvironment[]>('/api/version/deploy/environments', ssoId ? { ssoId } : {});

export const getDeployEnvironment = (id: number) =>
    get<DeployEnvironment>(`/api/version/deploy/environments/${id}`);

export const createDeployEnvironment = (data: DeployEnvironment) =>
    post<DeployEnvironment>('/api/version/deploy/environments', data);

export const updateDeployEnvironment = (id: number, data: DeployEnvironment) =>
    put<DeployEnvironment>(`/api/version/deploy/environments/${id}`, data);

export const deleteDeployEnvironment = (id: number) =>
    del(`/api/version/deploy/environments/${id}`);

// 部署记录
export const getDeployments = (params?: { ssoId?: number; envId?: number }) =>
    get<Deployment[]>('/api/version/deploy/deployments', params || {});

export const getDeployment = (id: number) =>
    get<Deployment>(`/api/version/deploy/deployments/${id}`);

export const executeDeploy = (data: { ssoId: number; envId: number; version: string; artifactUrl?: string }) =>
    post<Deployment>('/api/version/deploy/execute', data);

export const rollbackDeploy = (deploymentId: number) =>
    post<Deployment>(`/api/version/deploy/deployments/${deploymentId}/rollback`, {});

// ===== 发布台账 API =====

export interface ReleaseRecord {
    id?: number;
    ssoId: number;
    title: string;
    version?: string;
    releaseType?: 'feature' | 'bugfix' | 'hotfix';
    description?: string;
    changeList?: string;
    deploymentId?: number;
    status: 'draft' | 'pending' | 'approved' | 'rejected' | 'released';
    createdBy?: number;
    approvedBy?: number;
    approvedAt?: string;
    releasedAt?: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface ApprovalRecord {
    id?: number;
    releaseId: number;
    approverId?: number;
    approverName?: string;
    action: 'approve' | 'reject';
    comment?: string;
    createdAt?: string;
}

export const getReleaseRecords = (params?: { ssoId?: number; status?: string }) =>
    get<ReleaseRecord[]>('/api/version/releases', params || {});

export const getReleaseRecord = (id: number) =>
    get<ReleaseRecord>(`/api/version/releases/${id}`);

export const createReleaseRecord = (data: ReleaseRecord) =>
    post<ReleaseRecord>('/api/version/releases', data);

export const updateReleaseRecord = (id: number, data: ReleaseRecord) =>
    put<ReleaseRecord>(`/api/version/releases/${id}`, data);

export const deleteReleaseRecord = (id: number) =>
    del(`/api/version/releases/${id}`);

// 审批流程
export const submitForApproval = (releaseId: number) =>
    post<ReleaseRecord>(`/api/version/releases/${releaseId}/submit`, {});

export const approveRelease = (releaseId: number, data: { approverId?: number; approverName?: string; comment?: string }) =>
    post<ReleaseRecord>(`/api/version/releases/${releaseId}/approve`, data);

export const rejectRelease = (releaseId: number, data: { approverId?: number; approverName?: string; comment?: string }) =>
    post<ReleaseRecord>(`/api/version/releases/${releaseId}/reject`, data);

export const markAsReleased = (releaseId: number, deploymentId?: number) =>
    post<ReleaseRecord>(`/api/version/releases/${releaseId}/release`, { deploymentId });

export const getApprovalHistory = (releaseId: number) =>
    get<ApprovalRecord[]>(`/api/version/releases/${releaseId}/approvals`);

export const formatReleaseDescription = (description: string) =>
    post<string>('/api/version/releases/ai/format-description', { description });

// ===== 发布策略 API =====

export interface ReleaseStrategy {
    id?: number;
    name: string;
    type: 'full' | 'canary' | 'gray' | 'blue_green';
    trafficPercent?: number;
    config?: string;
    description?: string;
    createdAt?: string;
}

export const getReleaseStrategies = () =>
    get<ReleaseStrategy[]>('/api/version/strategies');

export const getReleaseStrategy = (id: number) =>
    get<ReleaseStrategy>(`/api/version/strategies/${id}`);

export const createReleaseStrategy = (data: ReleaseStrategy) =>
    post<ReleaseStrategy>('/api/version/strategies', data);

export const updateReleaseStrategy = (id: number, data: ReleaseStrategy) =>
    put<ReleaseStrategy>(`/api/version/strategies/${id}`, data);

export const deleteReleaseStrategy = (id: number) =>
    del(`/api/version/strategies/${id}`);

// ===== AI Code Review API =====

export interface AICodeReview {
    id: number;
    repoId: number;
    commitSha: string;
    branch: string;
    developerEmail?: string;
    developerId?: number;
    score?: number;
    summary?: string;
    content?: string;
    status: 'PENDING' | 'COMPLETED' | 'FAILED';
    createdAt?: string;
    updatedAt?: string;
}

export const triggerAICodeReview = (data: { repoId: number; commitSha: string; branch?: string; email?: string }) =>
    post<AICodeReview>('/api/version/audit/trigger', null, { params: data });

export const getAICodeReviews = (params?: { repoId?: number; developerId?: number }) =>
    get<AICodeReview[]>('/api/version/audit/list', params || {});

export const getAICodeReviewDetail = (id: number) =>
    get<AICodeReview>(`/api/version/audit/${id}`);

export const getAICodeReviewByCommit = (commitSha: string) =>
    get<AICodeReview>(`/api/version/audit/commit/${commitSha}`);


// ===== Developer KPI API =====

export interface DeveloperKpiVO {
    userId: number;
    name: string;
    email: string;
    gitlabUsername: string;
    totalCommits: number;
    totalReviews: number;
    averageCodeScore: number;
    activeDays: number;
    bugCount: number;
}

export const getDeveloperKpis = (systemId?: number) =>
    get<DeveloperKpiVO[]>('/api/version/stats/kpi', systemId ? { systemId } : {});

export const getQualityTrend = (userId?: number) =>
    get<any>('/api/version/stats/quality-trend', userId ? { userId } : {});

export const getOverviewStats = () =>
    get<any>('/api/version/stats/overview');

export const getAppVersionMatrix = (systemId: string) =>
    get<any[]>(`/api/version/app/${systemId}/matrix`);

export const getAppActiveBranches = (systemId: string) =>
    get<any[]>(`/api/version/app/${systemId}/branches`);

// ===== Infrastructure Asset API =====

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
    role?: string;
    appSystemId?: number;
    envId?: number;
    envType?: string;
    status: 'active' | 'maintenance' | 'offline';
    description?: string;
    createdAt?: string;
    updatedAt?: string;
}

export const getInfrastructureAssets = (params?: { appSystemId?: number; envId?: number; envType?: string }) =>
    get<InfrastructureAsset[]>('/api/version/infrastructure', params || {});

export const createInfrastructureAsset = (data: InfrastructureAsset) =>
    post<InfrastructureAsset>('/api/version/infrastructure', data);

export const updateInfrastructureAsset = (id: number, data: InfrastructureAsset) =>
    put<InfrastructureAsset>(`/api/version/infrastructure/${id}`, data);

export const deleteInfrastructureAsset = (id: number) =>
    del(`/api/version/infrastructure/${id}`);

export const exportInfrastructureAssets = () =>
    get<Blob>('/api/version/infrastructure/export', undefined, { isBlob: true });

export const importInfrastructureAssets = (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return post<void>('/api/version/infrastructure/import', formData);
};

