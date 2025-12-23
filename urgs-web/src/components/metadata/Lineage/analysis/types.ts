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

// 关系类型样式配置
export const RELATION_STYLES: Record<string, { color: string; highlightColor: string; strokeDasharray?: string; label: string }> = {
    DERIVES_TO: { color: '#1890ff', highlightColor: '#1890ff', label: '数据流' },
    FILTERS: { color: '#fa8c16', highlightColor: '#fa8c16', strokeDasharray: '5,5', label: '过滤' },
    JOINS: { color: '#52c41a', highlightColor: '#52c41a', strokeDasharray: '5,5', label: '关联' },
    GROUPS: { color: '#722ed1', highlightColor: '#722ed1', strokeDasharray: '2,2', label: '分组' },
    ORDERS: { color: '#8c8c8c', highlightColor: '#8c8c8c', strokeDasharray: '2,2', label: '排序' },
    CALLS: { color: '#eb2f96', highlightColor: '#eb2f96', strokeDasharray: '8,4', label: '调用' },
    REFERENCES: { color: '#13c2c2', highlightColor: '#13c2c2', strokeDasharray: '3,3', label: '引用' },
    CASE_WHEN: { color: '#fa541c', highlightColor: '#fa541c', strokeDasharray: '6,3,2,3', label: '条件' },
};

export interface LinkData {
    id: string;
    sourceNodeId: string;
    sourceColumnId: string;
    targetNodeId: string;
    targetColumnId: string;
    type?: string;  // 关系类型: DERIVES_TO, FILTERS, JOINS, GROUPS, ORDERS 等
    properties?: Record<string, any>;  // 关系属性 (version, sourceFile 等)
}

