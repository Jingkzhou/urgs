import type { LineageAnalysisRecordItem, LineageReviewTask } from '@/api/lineage';

export interface ReviewProgressSummary {
    totalTasks: number;
    terminalTasks: number;
    completedTasks: number;
    degradedTasks: number;
    totalIssues: number;
    pendingIssues: number;
    confirmedIssues: number;
    falsePositiveIssues: number;
    resolvedIssues: number;
    ignoredIssues: number;
    reviewedIssues: number;
    reviewRate: number;
    executionRate: number;
    totalStatements: number;
    coveredStatements: number;
    verifiedStatements: number;
    skippedStatements: number;
    failedStatementAudits: number;
    statementCoverageRate: number;
}

export interface TaskSourceMeta {
    text: string;
    tooltip: string;
}

export const formatDateTime = (value?: string) => {
    if (!value) {
        return '-';
    }
    return new Date(value).toLocaleString('zh-CN', { hour12: false });
};

export const buildRecordSummary = (record: LineageAnalysisRecordItem) => {
    const pathCount = record.paths?.length || 0;
    const pathPreview = pathCount === 0
        ? '未记录路径'
        : pathCount <= 2
            ? (record.paths || []).join('、')
            : `${record.paths?.slice(0, 2).join('、')} 等 ${pathCount} 个路径`;
    const sourceType = record.repoId ? 'Git 分析' : '上传导入';
    return {
        title: `${sourceType} · ${record.language || '未指定方言'}`,
        description: `版本 ${record.versionId || '-'} · ${pathPreview}`,
        meta: `创建于 ${formatDateTime(record.createTime)}`
    };
};

export const buildShardLabel = (task: LineageReviewTask) => {
    const raw = task.pathPrefix || '';
    if (!raw) {
        return task.systemKey && task.systemKey !== 'GLOBAL' ? task.systemKey : '全量分片';
    }

    if (!raw.includes('/')) {
        return task.systemKey && task.systemKey !== 'GLOBAL' ? task.systemKey : '根目录文件组';
    }

    return raw.split('/')[0] || raw;
};

export const isFileLikePath = (value?: string) => {
    if (!value) {
        return false;
    }
    return /\.[a-z0-9]+$/i.test(value);
};

export const buildTaskSourceMeta = (
    task: LineageReviewTask,
    records: LineageAnalysisRecordItem[]
): TaskSourceMeta => {
    const currentRecord = records.find(item => item.id === task.analysisRecordId);
    const paths = currentRecord?.paths || [];

    let matchedPaths = paths;
    if (task.pathPrefix) {
        matchedPaths = paths.filter(path => {
            if (task.pathPrefix && path.startsWith(task.pathPrefix)) {
                return true;
            }
            if (!task.pathPrefix.includes('/') && isFileLikePath(task.pathPrefix)) {
                return path === task.pathPrefix;
            }
            return false;
        });
    }

    if (!matchedPaths.length && task.pathPrefix) {
        matchedPaths = [task.pathPrefix];
    }

    const uniquePaths = Array.from(new Set(matchedPaths));
    if (!uniquePaths.length) {
        return {
            text: '未记录源码',
            tooltip: '当前任务没有关联到可展示的源码路径'
        };
    }

    if (uniquePaths.length === 1) {
        return {
            text: '1 个源码文件',
            tooltip: uniquePaths[0]
        };
    }

    return {
        text: `${uniquePaths.length} 个源码文件`,
        tooltip: uniquePaths.slice(0, 20).join('\n')
    };
};

export const getTaskIssueTotal = (task: LineageReviewTask) => (
    task.totalReviewIssueCount ?? task.issueCount ?? 0
);

export const getTaskReviewedTotal = (task: LineageReviewTask) => (
    task.reviewedIssueCount
        ?? ((task.confirmedIssueCount || 0)
            + (task.falsePositiveIssueCount || 0)
            + (task.resolvedIssueCount || 0)
            + (task.ignoredIssueCount || 0))
);

export const getTaskReviewRate = (task: LineageReviewTask) => {
    if (typeof task.reviewCompletionRate === 'number') {
        return task.reviewCompletionRate;
    }
    const total = getTaskIssueTotal(task);
    if (total <= 0) {
        return ['COMPLETED', 'DEGRADED', 'FAILED'].includes(task.status || '') ? 100 : 0;
    }
    return Math.round(getTaskReviewedTotal(task) * 100 / total);
};

export const getTaskExecutionRate = (task: LineageReviewTask) => {
    if (typeof task.executionProgressRate === 'number') {
        return task.executionProgressRate;
    }
    const total = task.objectCount || 0;
    const processed = task.processedCount || 0;
    if (total <= 0) {
        return ['COMPLETED', 'DEGRADED', 'FAILED'].includes(task.status || '') ? 100 : 0;
    }
    return Math.min(100, Math.round(processed * 100 / total));
};

export const calculateReviewProgressSummary = (tasks: LineageReviewTask[]): ReviewProgressSummary => {
    const totalTasks = tasks.length;
    const terminalTasks = tasks.filter(item => ['COMPLETED', 'DEGRADED', 'FAILED'].includes(item.status || '')).length;
    const completedTasks = tasks.filter(item => item.status === 'COMPLETED').length;
    const degradedTasks = tasks.filter(item => item.status === 'DEGRADED').length;
    const totalIssues = tasks.reduce((sum, item) => sum + getTaskIssueTotal(item), 0);
    const pendingIssues = tasks.reduce((sum, item) => sum + (item.pendingIssueCount || 0), 0);
    const confirmedIssues = tasks.reduce((sum, item) => sum + (item.confirmedIssueCount || 0), 0);
    const falsePositiveIssues = tasks.reduce((sum, item) => sum + (item.falsePositiveIssueCount || 0), 0);
    const resolvedIssues = tasks.reduce((sum, item) => sum + (item.resolvedIssueCount || 0), 0);
    const ignoredIssues = tasks.reduce((sum, item) => sum + (item.ignoredIssueCount || 0), 0);
    const reviewedIssues = tasks.reduce((sum, item) => sum + getTaskReviewedTotal(item), 0);
    const reviewRate = totalIssues > 0 ? Math.round(reviewedIssues * 100 / totalIssues) : (terminalTasks === totalTasks && totalTasks > 0 ? 100 : 0);
    const executionRate = totalTasks > 0
        ? Math.round(tasks.reduce((sum, item) => sum + getTaskExecutionRate(item), 0) / totalTasks)
        : 0;
    const aiTasks = tasks.filter(item => (item.tokenBudget || 0) > 0);
    const totalStatements = aiTasks.reduce((sum, item) => sum + (item.objectCount || 0), 0);
    const coveredStatements = aiTasks.reduce((sum, item) => sum + (item.screenedStatementCount || 0), 0);
    const verifiedStatements = aiTasks.reduce((sum, item) => sum + (item.verifiedStatementCount || 0), 0);
    const skippedStatements = aiTasks.reduce((sum, item) => sum + (item.skippedStatementCount || 0), 0);
    const failedStatementAudits = aiTasks.reduce((sum, item) => sum + (item.failedStatementAuditCount || 0), 0);
    const statementCoverageRate = totalStatements > 0
        ? Math.min(100, Math.round(coveredStatements * 100 / totalStatements))
        : 0;

    return {
        totalTasks,
        terminalTasks,
        completedTasks,
        degradedTasks,
        totalIssues,
        pendingIssues,
        confirmedIssues,
        falsePositiveIssues,
        resolvedIssues,
        ignoredIssues,
        reviewedIssues,
        reviewRate,
        executionRate,
        totalStatements,
        coveredStatements,
        verifiedStatements,
        skippedStatements,
        failedStatementAudits,
        statementCoverageRate
    };
};

export const resolveReviewStatus = (record: LineageAnalysisRecordItem, relatedTasks: LineageReviewTask[]) => {
    if (!relatedTasks.length) {
        return {
            text: record.status === 'SUCCESS' ? '未校验' : '待分析完成',
            color: record.status === 'SUCCESS' ? 'default' : 'warning'
        };
    }

    const statuses = relatedTasks.map(task => task.status || 'PENDING');
    const summary = calculateReviewProgressSummary(relatedTasks);
    if (statuses.some(status => status === 'RUNNING')) {
        return { text: '执行中', color: 'processing' };
    }
    if (statuses.some(status => status === 'FAILED')) {
        return { text: '执行失败', color: 'error' };
    }
    if (summary.totalIssues > 0 && summary.pendingIssues > 0) {
        return { text: '待确认', color: 'warning' };
    }
    if (statuses.some(status => status === 'DEGRADED')) {
        return { text: '已校验/降级', color: 'warning' };
    }
    if (summary.totalIssues > 0 && summary.pendingIssues === 0) {
        return { text: '已校验', color: 'success' };
    }
    if (statuses.every(status => status === 'COMPLETED')) {
        return { text: '已完成', color: 'success' };
    }
    return { text: '待执行', color: 'default' };
};
