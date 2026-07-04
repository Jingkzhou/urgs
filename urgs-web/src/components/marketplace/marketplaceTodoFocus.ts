export interface MarketplaceTodoFocus {
    type: string;
    title: string;
    count: number;
    targetTab: string;
    targetTaskId?: string;
    targetWorkId?: string;
    sequence: number;
}
