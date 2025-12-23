export const TASK_VALIDATION_RULES: Record<string, { field: string; label: string; required?: boolean }[]> = {
    COMMON: [
        { field: 'label', label: '节点名称', required: true },
        { field: 'cronExpression', label: 'Cron 表达式', required: true }
    ],
    SHELL: [
        { field: 'rawScript', label: '脚本内容', required: true }
    ],
    SQL: [
        { field: 'datasourceType', label: '数据源类型', required: true },
        { field: 'datasourceId', label: '数据源实例', required: true },
        { field: 'sql', label: 'SQL 语句', required: true }
    ],
    PYTHON: [
        { field: 'rawScript', label: '脚本内容', required: true }
    ],
    HTTP: [
        { field: 'datasourceId', label: '数据源', required: true },
        { field: 'url', label: '请求地址', required: true },
        { field: 'httpMethod', label: '请求类型', required: true }
    ],
    DataX: [
        { field: 'sourceType', label: '源数据类型', required: true },
        { field: 'sourceId', label: '源数据实例', required: true },
        { field: 'targetType', label: '目标数据类型', required: true },
        { field: 'targetId', label: '目标数据实例', required: true }
    ],
    PROCEDURE: [
        { field: 'datasourceId', label: '数据源实例', required: true },
        { field: 'method', label: '方法', required: true }
    ],
    DEPENDENT: [
        { field: 'workflowId', label: '依赖工作流', required: true },
        { field: 'taskId', label: '依赖任务', required: true }
    ]
};
