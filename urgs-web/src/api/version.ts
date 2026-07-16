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
    webhookSecret?: string;
    webhookUrl?: string;
    enabled?: boolean;
    lastSyncedAt?: string;
    createdAt?: string;
    updatedAt?: string;
    pendingPrCount?: number;
}

export const getGitRepositories = (params?: { ssoId?: number; platform?: string }) =>
    get<GitRepository[]>('/api/version/repos', params || {});

export const getManagedGitRepositories = () =>
    get<GitRepository[]>('/api/version/repos/management');

export const getRepoPrCounts = () =>
    get<Record<string, number>>('/api/version/repos/pr-counts');

export const getManagedRepoPrCounts = () =>
    get<Record<string, number>>('/api/version/repos/management/pr-counts');

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

export const downloadRepoFile = (repoId: number, path: string, ref?: string) =>
    get<Blob>(`/api/version/repos/${repoId}/file/download`, { path, ref: ref || '' }, { isBlob: true });

export interface GitFileSaveRequest {
    path: string;
    branch: string;
    contentBase64: string;
    commitMessage: string;
    fileSha?: string;
    overwrite: boolean;
}

export const saveRepoFile = (repoId: number, data: GitFileSaveRequest) =>
    put<void>(`/api/version/repos/${repoId}/file`, data);

export const getRepoCommits = (repoId: number, params?: { ref?: string; page?: number; perPage?: number }) =>
    get<GitCommit[]>(`/api/version/repos/${repoId}/commits`, params || {});

export const getRepoCompareCommits = (repoId: number, fromRef: string, toRef: string) =>
    get<GitCommit[]>(`/api/version/repos/${repoId}/compare/commits`, { fromRef, toRef });

export const getRepoCommitDetail = (repoId: number, sha: string) =>
    get<GitCommit>(`/api/version/repos/${repoId}/commits/${sha}`);

// ===== Git Pull Request API =====

export interface GitPullRequest {
    id: string;
    number: number;
    title: string;
    state: string; // open, closed, merged, locked
    body: string;
    htmlUrl: string;

    headRef: string; // source branch
    headSha: string;
    baseRef: string; // target branch
    baseSha: string;

    authorName: string;
    authorAvatar?: string;

    createdAt: string;
    updatedAt: string;
    closedAt?: string;
    mergedAt?: string;

    comments?: number;
    commits?: number;
    additions?: number;
    deletions?: number;
    changedFiles?: number;

    labels?: {
        name: string;
        color?: string;
        description?: string;
    }[];

    reviewers?: {
        id: number | string;
        name: string;
        avatar?: string;
        status?: string; // e.g., 'pending', 'approved'
    }[];

    assignees?: {
        id: number | string;
        name: string;
        avatar?: string;
    }[];
}

export const getPullRequests = (repoId: number, params?: { state?: string; page?: number; perPage?: number }) =>
    get<GitPullRequest[]>(`/api/version/repos/${repoId}/pulls`, params || {});

export const getPullRequest = (repoId: number, number: number) =>
    get<GitPullRequest>(`/api/version/repos/${repoId}/pulls/${number}`);

export const createPullRequest = (repoId: number, data: { title: string; body?: string; head: string; base: string }) =>
    post<void>(`/api/version/repos/${repoId}/pulls`, data);

export const getPullRequestCommits = (repoId: number, number: number) =>
    get<GitCommit[]>(`/api/version/repos/${repoId}/pulls/${number}/commits`);

export const getPullRequestFiles = (repoId: number, number: number) =>
    get<GitCommitDiff[]>(`/api/version/repos/${repoId}/pulls/${number}/files`);

export const mergePullRequest = (repoId: number, number: number, mergeMethod: string = 'merge') =>
    put<void>(`/api/version/repos/${repoId}/pulls/${number}/merge`, { mergeMethod });

export const closePullRequest = (repoId: number, number: number) =>
    put<void>(`/api/version/repos/${repoId}/pulls/${number}/close`, {});

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

export const createPipeline = (data: Pipeline) =>
    post<Pipeline>('/api/version/pipelines', data);

export const updatePipeline = (id: number, data: Pipeline) =>
    put<Pipeline>(`/api/version/pipelines/${id}`, data);

export const deletePipeline = (id: number) =>
    del(`/api/version/pipelines/${id}`);

export const getPipelineRuns = (pipelineId: number) =>
    get<PipelineRun[]>(`/api/version/pipelines/${pipelineId}/runs`);

export const triggerPipeline = (pipelineId: number, params?: { branch?: string; triggerType?: string }) =>
    post<PipelineRun>(`/api/version/pipelines/${pipelineId}/trigger`, params || {});

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
    status: 'pending' | 'deploying' | 'success' | 'failed' | 'rollback' | 'blocked';
    deployedBy?: number;
    deployedAt?: string;
    rollbackTo?: number;
    logs?: string;
    remark?: string;
    packageId?: number; // 关联版本包ID
    createdAt?: string;
}

export interface VersionPackage {
    id: number;
    repoId: number;
    ssoId: number;
    version: string;
    gitRef: string;
    commitSha: string;
    previousGitRef?: string;
    previousCommitSha?: string;
    requirementNumber?: string;
    packageName?: string;
    packageUrl?: string;
    packageSize?: number;
    description?: string;
    deployScript?: string;
    rollbackScript?: string;
    status: string;
    createdBy?: number;
    deployedBy?: number;
    deployedAt?: string;
    envId?: number;
    specPath?: string;
    packageType?: string;
    gateStatus?: string;
    gateSummary?: string;
    changedFiles?: string;
    buildLog?: string;
    deployCommand?: string;
    rollbackCommand?: string;
    backupStatus?: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface ProductionPackageRequest {
    repoId: number;
    ssoId: number;
    gitRef: string;
    previousGitRef: string;
    requirementNumber: string;
    description?: string;
    createdBy?: number;
    envId?: number;
}

export interface ProductionPackageGateItem {
    key: string;
    label: string;
    status: 'passed' | 'failed' | string;
    message?: string;
}

export interface ProductionPackageChangeSummary {
    sqlFiles: string[];
    procedureFiles: string[];
    backupFiles: string[];
    rollbackFiles: string[];
    otherFiles: string[];
}

export interface ProductionPackageDatabaseSpec {
    dbType?: string;
    jdbcUrl?: string;
    schema?: string;
    host?: string;
    port?: number;
    database?: string;
    dsn?: string;
    driverDir?: string;
    driverJar?: string;
    jdbcDriverClass?: string;
}

export interface ProductionPackageGateResult {
    repoId: number;
    gitRef: string;
    previousGitRef: string;
    requirementNumber?: string;
    packageType?: string;
    specPath?: string;
    status: 'passed' | 'failed' | string;
    summary?: string;
    deployCommand?: string;
    rollbackCommand?: string;
    database?: ProductionPackageDatabaseSpec;
    gates: ProductionPackageGateItem[];
    includedFiles: string[];
    backupTables?: string[];
    changeSummary: ProductionPackageChangeSummary;
}

export interface ProductionPackageBuildResult {
    packageId: number;
    packageName: string;
    packageSize: number;
    deployCommand: string;
    rollbackCommand: string;
    gateResult: ProductionPackageGateResult;
}

// 环境管理
export const getDeployEnvironments = (ssoId?: number) =>
    get<DeployEnvironment[]>('/api/version/deploy/environments', ssoId ? { ssoId } : {});

// 部署记录

export const recordOfflineDeploymentResult = (data: {
    ssoId: number;
    envId?: number;
    packageId: number;
    status: 'success' | 'failed' | 'blocked';
    deployedBy?: number;
    logs?: string;
    remark?: string;
}) => post<Deployment>('/api/version/deploy/deployments/offline-result', data);

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
    post<void>('/api/version/audit/trigger', null, { params: data });

export const getAICodeReviews = (params?: { repoId?: number; developerId?: number }) =>
    get<AICodeReview[]>('/api/version/audit/list', params || {});

export const getAICodeReviewDetail = (id: number) =>
    get<AICodeReview>(`/api/version/audit/${id}`);

export const getAICodeReviewByCommit = (commitSha: string) =>
    get<AICodeReview>(`/api/version/audit/commit/${commitSha}`);

export interface AICodeReviewAskRequest {
    question: string;
    issueTitle?: string;
    issueSeverity?: string;
}

export interface AICodeReviewAskResponse {
    reviewId: number;
    answer: string;
    generatedAt?: string;
}

export const askAICodeReview = (reviewId: number, data: AICodeReviewAskRequest) =>
    post<AICodeReviewAskResponse>(`/api/version/audit/${reviewId}/ask`, data);

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

export const getOverviewStats = () =>
    get<any>('/api/version/stats/overview');

// ========== 版本包管理 ==========

/**
 * 获取版本包列表
 */
export const getVersionPackages = (ssoId: number) =>
    get<VersionPackage[]>('/api/version/deploy/packages', { ssoId });

/**
 * 创建版本包
 */

/**
 * 下载部署安装包
 */
export const downloadVersionPackage = (packageId: number) =>
    get<Blob>(`/api/version/deploy/packages/${packageId}/download`, {}, { isBlob: true });

export const gateCheckProductionPackage = (params: ProductionPackageRequest) =>
    post<ProductionPackageGateResult>('/api/version/deploy/packages/gate-check', params);

export const buildProductionPackage = (params: ProductionPackageRequest) =>
    post<ProductionPackageBuildResult>('/api/version/deploy/packages/production', params);

export const downloadProductionPackage = (packageId: number) =>
    get<Blob>(`/api/version/deploy/packages/${packageId}/production-download`, {}, { isBlob: true });

export const deleteVersionPackage = (packageId: number) =>
    del<void>(`/api/version/deploy/packages/${packageId}`);

/**
 * 回填版本包部署状态
 */

/**
 * 关联版本包执行部署 (记录)
 */
