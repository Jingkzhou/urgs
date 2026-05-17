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
