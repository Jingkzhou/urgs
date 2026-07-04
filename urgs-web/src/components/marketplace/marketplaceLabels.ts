export const workStatusLabelMap: Record<string, string> = {
    DRAFT: '草稿',
    PUBLISHED: '已发布',
    ACTIVE: '进行中',
    PAUSED: '已暂停',
    ACCEPTANCE: '待验收',
    COMPLETED: '已完成',
    CANCELLED: '已取消',
};

export const taskStatusLabelMap: Record<string, string> = {
    OPEN: '待承接',
    READY: '待开始',
    IN_PROGRESS: '处理中',
    PAUSED: '已暂停',
    WAITING_REVIEW: '待审核',
    COMPLETED: '已完成',
    REWORK: '退回修改',
    CANCELLED: '已取消',
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
    ASSET_REVIEW: '资产同步审核',
    LAUNCH: '上线',
};

export const getTaskStageLabel = (stage?: string) => {
    if (!stage) return '需求';
    return taskStageLabelMap[stage] || stage;
};
