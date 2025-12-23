export interface ViewportState {
    x: number;
    y: number;
    zoom: number;
}

export interface NodeData {
    id: string;
    x: number;
    y: number;
    width: number;
    type: 'source' | 'transform' | 'aggregation' | 'result' | 'default';
    title: string;
    isCollapsed?: boolean;
    columns: {
        id: string;
        name: string;
    }[];
}

export interface LinkData {
    id: string;
    sourceNodeId: string;
    sourceColumnId: string;
    targetNodeId: string;
    targetColumnId: string;
}
