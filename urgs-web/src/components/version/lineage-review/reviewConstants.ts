export const statusColorMap: Record<string, string> = {
    PENDING: 'default',
    RUNNING: 'processing',
    COMPLETED: 'success',
    DEGRADED: 'warning',
    FAILED: 'error'
};

export const severityColorMap: Record<string, string> = {
    HIGH: 'red',
    MEDIUM: 'orange',
    LOW: 'blue'
};

export const reviewStatusColorMap: Record<string, string> = {
    PENDING: 'default',
    CONFIRMED: 'success',
    FALSE_POSITIVE: 'error',
    IGNORED: 'default',
    RESOLVED: 'processing'
};

export const issueTypeLabelMap: Record<string, string> = {
    MISSING_SOURCE: '缺少上游来源',
    WRONG_SOURCE: '上游来源错误',
    WRONG_TARGET: '下游目标错误',
    WRONG_RELATION_TYPE: '血缘关系类型错误',
    OVER_CONNECTED: '来源过度关联',
    RELATION_TYPE_MISMATCH: '关系类型不匹配',
    SPARSE_TABLE_LINEAGE: '表级血缘过少',
    AMBIGUOUS_MAPPING: '映射关系不明确',
    UNCERTAIN_MAPPING: '映射关系不确定',
    NEEDS_MANUAL_REVIEW: '需要人工复核',
    NO_ISSUE: '无问题'
};

export const severityLabelMap: Record<string, string> = {
    HIGH: '高',
    MEDIUM: '中',
    LOW: '低'
};

export const verdictLabelMap: Record<string, string> = {
    CONFIRMED: '确认存在问题',
    REJECTED: '判定无问题',
    NEEDS_REVIEW: '需要复核'
};

export const reviewStatusLabelMap: Record<string, string> = {
    PENDING: '待处理',
    CONFIRMED: '已确认',
    FALSE_POSITIVE: '误报',
    IGNORED: '已忽略',
    RESOLVED: '已处理'
};

export const ruleHitLabelMap: Record<string, string> = {
    NO_DIRECT_DERIVATION: '缺少直接派生关系',
    TOO_MANY_SOURCES: '来源数量过多',
    SAME_NAME_MULTI_TABLE: '同名字段多表匹配',
    TABLE_LEVEL_RELATION_SPARSE: '表级关系覆盖不足'
};

export const confirmedProblemTypeLabelMap: Record<string, string> = {
    SQL_STANDARD: 'SQL 书写规范',
    PARSER_BUG: '解析程序 BUG'
};

export const toDisplayLabel = (value: string | undefined, labelMap: Record<string, string>, fallback = '-') => {
    if (!value) {
        return fallback;
    }
    return labelMap[value] || value;
};
