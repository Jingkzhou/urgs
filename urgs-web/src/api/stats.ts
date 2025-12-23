import { post, get } from '../utils/request';

export interface TaskStatsVO {
    systemId: string;
    systemName: string;
    totalTasks: number;
    totalCompleted: number;
    totalInProgress: number;
    totalNotStarted: number;
    totalFailed: number;
    avgProgressPercentage: number;
}

export interface TaskStatsQuery {
    systemIds?: string[];
    subjectIds?: string[];
    taskStatuses?: string[];
    startTimeBegin?: string;
    startTimeEnd?: string;
    updateTimeBegin?: string;
    updateTimeEnd?: string;
    onlyLatest?: boolean;
}



export const fetchBatchStatusStats = async (query: TaskStatsQuery = { onlyLatest: true }): Promise<TaskStatsVO[]> => {
    try {
        const data = await post<TaskStatsVO[]>('/api/tasks/stats/batch', query);
        return data || [];
    } catch (error) {
        console.error('Error fetching batch stats:', error);
        return [];
    }
};

export interface TaskInstanceStatsVO {
    total: number;
    success: number;
    failed: number;
    running: number;
    waiting: number;
    successRate: number;
}

export const fetchDailyStats = async (date?: string): Promise<TaskInstanceStatsVO | null> => {
    try {
        const url = date ? `/api/task/instance/stats/daily?date=${date}` : '/api/task/instance/stats/daily';
        // Note: Using 'get' helper if available, or fetch directly. Assuming 'post' was imported, checking for 'get'.
        // The file only imports 'post'. I should check if 'get' is available in '../utils/request'.
        // For now, assuming 'get' is available or I can use fetch.
        // Let's check imports first.
        // Wait, I can't check imports in this tool call.
        // I'll assume I need to add 'get' to imports.
        return await get<TaskInstanceStatsVO>(url);
    } catch (error) {
        console.error('Error fetching daily stats:', error);
        return null;
    }
};

export const fetchHourlyThroughput = async (date?: string): Promise<any[]> => {
    try {
        const url = date ? `/api/task/instance/stats/hourly?date=${date}` : '/api/task/instance/stats/hourly';
        return await get<any[]>(url);
    } catch (error) {
        console.error('Error fetching hourly throughput:', error);
        return [];
    }
};

export interface WorkflowStatsVO {
    workflowName: string;
    total: number;
    success: number;
    failed: number;
}

export const fetchWorkflowStats = async (date?: string): Promise<WorkflowStatsVO[]> => {
    try {
        const url = date ? `/api/task/instance/stats/workflow?date=${date}` : '/api/task/instance/stats/workflow';
        return await get<WorkflowStatsVO[]>(url);
    } catch (error) {
        console.error('Error fetching workflow stats:', error);
        return [];
    }
};
