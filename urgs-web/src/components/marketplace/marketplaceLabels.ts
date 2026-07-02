export const workStatusLabelMap: Record<string, string> = {
    DRAFT: '草稿',
    PUBLISHED: '已发布',
    ASSIGNED: '已承接',
    IN_PROGRESS: '进行中',
    PAUSED: '已暂停',
    REVIEW: '待验收',
    COMPLETED: '已完成',
    REJECTED: '退回修改',
    CANCELLED: '已取消',
};

export const taskStatusLabelMap: Record<string, string> = {
    OPEN: '可领取',
    APPLIED: '竞标中',
    ASSIGNED: '已承接',
    IN_PROGRESS: '进行中',
    PAUSED: '已暂停',
    REVIEW: '待验收',
    COMPLETED: '已完成',
    REJECTED: '退回修改',
    CANCELLED: '已取消',
    OVERDUE: '已逾期',
};

export const getWorkStatusLabel = (status?: string) => {
    if (!status) return '-';
    return workStatusLabelMap[status] || status;
};

export const getTaskStatusLabel = (status?: string) => {
    if (!status) return '-';
    return taskStatusLabelMap[status] || status;
};

export const taskStageLabelMap: Record<string, string> = {
    REQUIREMENT: '需求',
    DEVELOPMENT: '开发',
    TESTING: '测试',
    LAUNCH: '上线',
};

export const getTaskStageLabel = (stage?: string) => {
    if (!stage) return '需求';
    return taskStageLabelMap[stage] || stage;
};
