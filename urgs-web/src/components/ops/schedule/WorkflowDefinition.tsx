import React, { useState } from 'react';
import dayjs from 'dayjs';
import { Search, Plus, Play, Edit, Trash2, MoreHorizontal, Power, Copy, Clock, History, Maximize2, Minimize2, Upload, Download } from 'lucide-react';
import { Modal, Form, Input, message, Select } from 'antd';
import Pagination from '../../common/Pagination';
import WorkflowCanvas from '../WorkflowCanvas';

import { TASK_VALIDATION_RULES } from './TaskValidationRules';

const WorkflowDefinition: React.FC = () => {
    const [viewMode, setViewMode] = useState<'list' | 'canvas'>('list');
    const [editingWorkflow, setEditingWorkflow] = useState<any>(null);
    const [isMaximized, setIsMaximized] = useState(false);

    // Save Modal State
    const [isSaveModalOpen, setIsSaveModalOpen] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [form] = Form.useForm();

    // Mock Data State
    const [workflows, setWorkflows] = useState<any[]>([]);

    // Track current canvas state
    const [currentNodes, setCurrentNodes] = useState<any[]>([]);
    const [currentEdges, setCurrentEdges] = useState<any[]>([]);

    const handleNewWorkflow = () => {
        setEditingWorkflow(null);
        setViewMode('canvas');
        setIsMaximized(true);
    };

    const handleEditWorkflow = async (wf: any) => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch(`/api/workflow/${wf.realId}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });

            if (res.ok) {
                const fullWorkflow = await res.json();
                // Ensure we use the hydrated content from backend
                setEditingWorkflow({
                    ...fullWorkflow,
                    id: `WF_${String(fullWorkflow.id).padStart(3, '0')}`,
                    realId: fullWorkflow.id
                });
                setViewMode('canvas');
                setIsMaximized(true);
            } else {
                message.error('获取工作流详情失败');
            }
        } catch (error) {
            console.error('Failed to fetch workflow details:', error);
            message.error('获取工作流详情出错');
        }
    };

    const handleBackToList = () => {
        setViewMode('list');
        setEditingWorkflow(null);
        setIsMaximized(false);
    };

    const validateWorkflow = () => {
        const errors: string[] = [];
        currentNodes.forEach(node => {
            const data = node.data || {};
            const name = data.label || data.name || '未命名节点';
            const type = data.taskType || 'SHELL';

            const formatError = (msg: string) => `[${name}]: ${msg}`;

            // 1. Common Rules
            TASK_VALIDATION_RULES.COMMON.forEach(rule => {
                // Skip cronExpression validation for DEPENDENT nodes as it will be auto-populated
                if (type === 'DEPENDENT' && rule.field === 'cronExpression') return;

                if (rule.required && (!data[rule.field] || !String(data[rule.field]).trim())) {
                    // Special handling for label/name fallback
                    if (rule.field === 'label' && (data.label || data.name)) return;
                    errors.push(formatError(`缺少${rule.label}`));
                }
            });

            // 2. Type Specific Rules
            const typeRules = TASK_VALIDATION_RULES[type] || [];
            typeRules.forEach(rule => {
                if (rule.required && (!data[rule.field] || !String(data[rule.field]).trim())) {
                    errors.push(formatError(`缺少${rule.label}`));
                }
            });
        });
        return errors;
    };

    const handleSaveClick = () => {
        // Validate before opening modal
        const errors = validateWorkflow();
        if (errors.length > 0) {
            Modal.error({
                title: '工作流配置校验失败',
                content: (
                    <div className="max-h-[300px] overflow-y-auto">
                        <p className="mb-2 text-slate-600">请修正以下错误后重试：</p>
                        <ul className="list-disc pl-5 space-y-1 text-red-600 text-sm">
                            {errors.map((err, idx) => <li key={idx}>{err}</li>)}
                        </ul>
                    </div>
                ),
                width: 500
            });
            return;
        }

        if (editingWorkflow) {
            form.setFieldsValue({
                name: editingWorkflow.name,
                owner: editingWorkflow.owner,
                description: editingWorkflow.description,
                cron: editingWorkflow.cron || '0 0 2 * * ?'
            });
        } else {
            form.resetFields();
            form.setFieldValue('cron', '0 0 2 * * ?');
        }
        setIsSaveModalOpen(true);
    };

    // Fetch Workflows
    React.useEffect(() => {
        fetchWorkflows();
    }, []);

    const fetchWorkflows = () => {
        const token = localStorage.getItem('auth_token');
        fetch('/api/workflow/list', {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        })
            .then(res => {
                if (res.status === 401) {
                    message.error('登录已过期，请重新登录');
                    // Optional: Redirect to login
                    return [];
                }
                return res.json();
            })
            .then(data => {
                if (!Array.isArray(data)) return;
                // Map backend data to frontend format if needed
                const mapped = data.map((w: any) => ({
                    ...w,
                    id: `WF_${String(w.id).padStart(3, '0')}`, // Display ID
                    realId: w.id
                }));
                setWorkflows(mapped);
            })
            .catch(err => console.error('Failed to fetch workflows:', err));
    };

    const handleDeleteWorkflow = (wf: any) => {
        Modal.confirm({
            title: '确认删除',
            content: `确定要删除工作流 "${wf.name}" 吗？`,
            okText: '确认',
            cancelText: '取消',
            onOk: async () => {
                try {
                    const token = localStorage.getItem('auth_token');
                    const res = await fetch(`/api/workflow/${wf.realId}`, {
                        method: 'DELETE',
                        headers: {
                            'Authorization': `Bearer ${token}`
                        }
                    });
                    if (res.ok) {
                        const text = await res.text();
                        if (text === 'Success') {
                            message.success('删除成功');
                            fetchWorkflows();
                        } else {
                            message.error('删除失败: ' + text);
                        }
                    } else {
                        message.error('删除请求失败');
                    }
                } catch (error) {
                    console.error('Delete error:', error);
                    message.error('删除出错');
                }
            }
        });
    };

    const fileInputRef = React.useRef<HTMLInputElement>(null);

    const handleImportClick = () => {
        fileInputRef.current?.click();
    };

    const handleImportWorkflow = (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const content = e.target?.result as string;
                const data = JSON.parse(content);

                let nodes: any[] = [];
                let edges: any[] = [];

                // Strategy 1: Direct React Flow structure (nodes & edges)
                if (data.nodes && Array.isArray(data.nodes)) {
                    nodes = data.nodes;
                    edges = data.edges || [];
                }
                // Strategy 2: Simplified Task List (tasks & dependencies)
                else if (data.tasks && Array.isArray(data.tasks)) {
                    // Convert tasks to nodes
                    nodes = data.tasks.map((task: any, index: number) => ({
                        id: task.id || crypto.randomUUID(),
                        type: 'taskNode',
                        position: { x: 0, y: 0 }, // Position will be handled by auto-layout in Canvas
                        data: {
                            ...task.content, // Flatten content to meet validation rules (e.g. rawScript, sql)
                            ...task,
                            label: task.name, // Ensure label exists
                            taskType: task.type || 'SHELL',
                            id: task.id || crypto.randomUUID(), // Ensure internal ID
                            cronExpression: task.cron, // Map cron to cronExpression
                            description: task.description || '', // Map description
                            offset: task.offset || 0 // Map offset
                        }
                    }));

                    // Convert dependencies to edges and populate dependentTasks
                    if (data.dependencies && Array.isArray(data.dependencies)) {
                        edges = data.dependencies.map((dep: any) => {
                            // Find source and target nodes by name or ID
                            const sourceNode = nodes.find(n => n.data.name === dep.from || n.id === dep.from);
                            const targetNode = nodes.find(n => n.data.name === dep.to || n.id === dep.to);

                            if (sourceNode && targetNode) {
                                // Populate dependentTasks for target node
                                if (!targetNode.data.dependentTasks) {
                                    targetNode.data.dependentTasks = [];
                                }
                                if (!targetNode.data.dependentTasks.includes(sourceNode.id)) {
                                    targetNode.data.dependentTasks.push(sourceNode.id);
                                }

                                return {
                                    id: `e${sourceNode.id}-${targetNode.id}`,
                                    source: sourceNode.id,
                                    target: targetNode.id,
                                    type: 'smoothstep',
                                    style: { stroke: '#94a3b8' }
                                };
                            }
                            return null;
                        }).filter(Boolean);
                    }
                } else {
                    message.error('无法识别的文件格式，请包含 nodes/edges 或 tasks/dependencies');
                    return;
                }

                // Check if workflow exists
                const existingWorkflow = workflows.find(w => w.name === (data.name || 'Imported Workflow'));

                if (existingWorkflow) {
                    message.warning(`检测到已存在同名工作流 "${existingWorkflow.name}"，保存时将覆盖原有配置。`);
                    setEditingWorkflow({
                        ...existingWorkflow,
                        description: data.description || existingWorkflow.description,
                        owner: data.owner || existingWorkflow.owner,
                        cron: data.cron || existingWorkflow.cron,
                        content: JSON.stringify({ nodes, edges })
                    });
                } else {
                    setEditingWorkflow({
                        name: data.name || 'Imported Workflow',
                        description: data.description || '',
                        owner: data.owner || '',
                        cron: data.cron || '0 0 2 * * ?',
                        content: JSON.stringify({ nodes, edges })
                    });
                    message.success('导入成功，请检查布局并保存');
                }

                setViewMode('canvas');
                setIsMaximized(true);

            } catch (error) {
                console.error('Import error:', error);
                message.error('文件解析失败');
            }
        };
        reader.readAsText(file);
        // Reset input
        event.target.value = '';
    };

    const handleDownloadTemplate = () => {
        const template = {
            _comment: "URGS工作流导入模板。请修改name, owner, cron等字段。tasks定义任务节点，dependencies定义连线关系。",
            name: "示例工作流_全类型覆盖",
            owner: "Admin",
            description: "包含所有任务类型示例，并演示了'一个任务依赖多个任务'的汇聚场景。",
            cron: "0 0 2 * * ?",
            _cron_comment: "工作流整体调度时间 (Cron表达式)",
            tasks: [
                {
                    _comment: "SHELL任务: 执行Linux Shell脚本",
                    name: "01_初始化_Shell",
                    type: "SHELL",
                    cron: "0 0 1 * * ?",
                    offset: 0,
                    description: "初始化环境并打印开始时间",
                    content: {
                        rawScript: "echo 'Workflow started...'\ndate"
                    }
                },
                {
                    _comment: "DATAX任务: 执行DataX数据同步作业",
                    name: "02_数据同步_DataX",
                    type: "DATAX",
                    cron: "0 10 1 * * ?",
                    offset: 0,
                    description: "从MySQL同步数据到目标库",
                    content: {
                        sourceType: "MYSQL",
                        sourceId: "1",
                        targetType: "MYSQL",
                        targetId: "2",
                        json: "{ \"job\": { \"content\": [...] } }"
                    }
                },
                {
                    _comment: "PROCEDURE任务: 调用数据库存储过程",
                    name: "03_存储过程_Procedure",
                    type: "PROCEDURE",
                    cron: "0 30 1 * * ?",
                    offset: 0,
                    description: "执行日终结算存储过程",
                    content: {
                        datasourceId: "1",
                        method: "p_daily_calc",
                        params: "2023-01-01"
                    }
                },
                {
                    _comment: "SQL任务: 执行SQL查询或DML语句",
                    name: "04_数据分析_SQL",
                    type: "SQL",
                    cron: "0 0 2 * * ?",
                    offset: 0,
                    description: "统计已完成订单数量",
                    content: {
                        datasourceType: "MYSQL",
                        datasourceId: "1",
                        sql: "SELECT count(*) FROM orders WHERE status = 'COMPLETED'"
                    }
                },
                {
                    _comment: "PYTHON任务: 执行Python脚本",
                    name: "05_算法模型_Python",
                    type: "PYTHON",
                    cron: "0 0 2 * * ?",
                    offset: 0,
                    description: "运行机器学习预测模型",
                    content: {
                        rawScript: "print('Running ML model...')\n# import sklearn"
                    }
                },
                {
                    _comment: "DEPENDENT任务: 依赖外部工作流或其他任务状态",
                    name: "06_外部依赖_Dependent",
                    type: "DEPENDENT",
                    cron: "0 0 1 * * ?",
                    offset: 0,
                    description: "等待外部前置任务完成",
                    content: {
                        workflowId: "WF_001",
                        taskId: "TASK_001",
                        dependType: "ALL_SUCCESS"
                    }
                },
                {
                    _comment: "HTTP任务: 发送HTTP请求(Webhook)",
                    name: "07_汇总通知_HTTP",
                    type: "HTTP",
                    cron: "0 30 2 * * ?",
                    offset: 0,
                    description: "发送工作流完成通知",
                    content: {
                        datasourceId: "1",
                        url: "https://api.example.com/workflow/done",
                        httpMethod: "POST",
                        body: "{\"status\": \"all_done\"}"
                    }
                }
            ],
            dependencies: [
                { _comment: "串行: 01 -> 02", from: "01_初始化_Shell", to: "02_数据同步_DataX" },
                { _comment: "串行: 02 -> 03", from: "02_数据同步_DataX", to: "03_存储过程_Procedure" },

                { _comment: "分支: 03 -> 04", from: "03_存储过程_Procedure", to: "04_数据分析_SQL" },
                { _comment: "分支: 03 -> 05", from: "03_存储过程_Procedure", to: "05_算法模型_Python" },

                { _comment: "独立分支: 01 -> 06", from: "01_初始化_Shell", to: "06_外部依赖_Dependent" },

                { _comment: "汇聚: 04 -> 07", from: "04_数据分析_SQL", to: "07_汇总通知_HTTP" },
                { _comment: "汇聚: 05 -> 07", from: "05_算法模型_Python", to: "07_汇总通知_HTTP" },
                { _comment: "汇聚: 06 -> 07", from: "06_外部依赖_Dependent", to: "07_汇总通知_HTTP" }
            ]
        };

        const blob = new Blob([JSON.stringify(template, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'workflow_import_template.json';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    };

    const handleSaveConfirm = async () => {
        try {
            setIsSaving(true);
            const values = await form.validateFields();
            const token = localStorage.getItem('auth_token');



            // 1. Save all tasks first (2-Pass Strategy)
            const savedNodes = [];
            const idMapping: Record<string, string> = {}; // Map old ID -> new ID
            const originalDependentTasksMap = new Map<string, string[]>(); // Store original deps for 2nd pass

            // Pass 1: Save tasks to get IDs (ignoring dependencies for now to avoid foreign key errors or bad references)
            for (const node of currentNodes) {
                if (node.data) {
                    // Auto-populate DEPENDENT node configuration
                    if (node.data.taskType === 'DEPENDENT' && node.data.taskId) {
                        try {
                            const targetRes = await fetch(`/api/task/list?keyword=${node.data.taskId}&size=1`, {
                                headers: { 'Authorization': `Bearer ${token}` }
                            });
                            if (targetRes.ok) {
                                const targetData = await targetRes.json();
                                const targetTask = Array.isArray(targetData) ? targetData[0] : (targetData.records && targetData.records[0]);

                                if (targetTask) {
                                    const targetContent = JSON.parse(targetTask.content || '{}');
                                    // Update node data with target task's cron and offset
                                    node.data.cronExpression = targetTask.cronExpression || targetContent.cronExpression;
                                    node.data.offset = targetContent.offset || 0;
                                    // Also update content if needed
                                    if (!node.data.content) node.data.content = {};
                                    // Ensure these fields are in data root as well for consistency
                                }
                            }
                        } catch (e) {
                            console.warn('Failed to auto-populate dependent task info:', e);
                        }
                    }

                    // Store original dependencies
                    originalDependentTasksMap.set(node.id, node.data.dependentTasks || []);

                    const taskPayload = {
                        id: node.data.id, // Pass ID if it exists (for update)
                        name: node.data.name || node.data.label || 'Task',
                        type: node.data.taskType || 'SHELL',
                        status: node.data.runFlag === 'FORBIDDEN' ? 0 : 1,
                        cronExpression: node.data.cronExpression,
                        content: JSON.stringify(node.data),
                        preTaskIds: [] // Pass 1: Send empty dependencies
                    };

                    const taskRes = await fetch('/api/task/save', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${token}`
                        },
                        body: JSON.stringify(taskPayload)
                    });

                    if (!taskRes.ok) {
                        throw new Error(`Failed to save task (Pass 1): ${node.data.label}`);
                    }

                    const savedTaskId = await taskRes.text(); // Backend returns String ID
                    idMapping[node.id] = savedTaskId; // Record mapping

                    savedNodes.push({
                        ...node,
                        id: savedTaskId,
                        data: { ...node.data, id: savedTaskId }
                    });
                } else {
                    savedNodes.push(node);
                    idMapping[node.id] = node.id;
                }
            }

            // Pass 2: Update tasks with correct dependencies
            // Now that we have all new IDs in idMapping, we can resolve dependencies.
            for (const node of savedNodes) {
                if (node.data) {
                    // Retrieve original dependencies using the OLD node ID (which we need to track)
                    // Wait, savedNodes has NEW IDs. We need to find the old ID or use index?
                    // Better: Iterate original currentNodes again? No, savedNodes order matches currentNodes.

                    // Let's find the original node ID. 
                    // Actually, we can just iterate currentNodes again, and look up the new ID from idMapping.
                    const originalNode = currentNodes.find(n => idMapping[n.id] === node.id);
                    if (!originalNode) continue;

                    const originalDeps = originalDependentTasksMap.get(originalNode.id) || [];

                    // Map dependencies to new IDs
                    const newDeps = originalDeps.map(depId => idMapping[depId] || depId);

                    // Update node data in memory
                    node.data.dependentTasks = newDeps;

                    // Send update to backend
                    const taskPayload = {
                        id: node.id, // Use the NEW ID obtained in Pass 1
                        name: node.data.name || node.data.label || 'Task',
                        type: node.data.taskType || 'SHELL',
                        status: node.data.runFlag === 'FORBIDDEN' ? 0 : 1,
                        cronExpression: node.data.cronExpression,
                        content: JSON.stringify(node.data), // Update content with new dependentTasks
                        preTaskIds: newDeps // Pass 2: Send correct dependencies
                    };

                    const taskRes = await fetch('/api/task/save', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${token}`
                        },
                        body: JSON.stringify(taskPayload)
                    });

                    if (!taskRes.ok) {
                        throw new Error(`Failed to save task (Pass 2): ${node.data.label}`);
                    }
                }
            }

            // Update edges with new IDs
            const savedEdges = currentEdges.map(edge => ({
                ...edge,
                source: idMapping[edge.source] || edge.source,
                target: idMapping[edge.target] || edge.target,
                id: `e${idMapping[edge.source] || edge.source}-${idMapping[edge.target] || edge.target}`
            }));

            // Update dependentTasks in savedNodes to use new IDs (for consistency in next load)
            // Update dependentTasks in savedNodes to use new IDs (already done in Pass 2 loop, but double check for memory state)
            // The loop above updated node.data.dependentTasks in place for savedNodes objects.

            // 2. Prepare Workflow Payload
            const payload = {
                workflowId: editingWorkflow ? editingWorkflow.realId : null,
                name: values.name,
                owner: values.owner,
                description: values.description,
                content: JSON.stringify({ nodes: savedNodes, edges: savedEdges }), // Save graph state with new IDs
                cron: values.cron, // Use from form
                nodes: savedNodes.map(n => n.id),
                edges: savedEdges.map(e => ({ source: e.source, target: e.target }))
            };

            const res = await fetch('/api/workflow/save', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token} `
                },
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                const text = await res.text();
                if (text === 'Success') {
                    message.success('工作流及任务保存成功');
                    fetchWorkflows(); // Refresh list
                    setIsSaveModalOpen(false);
                } else {
                    message.error('保存失败: ' + text);
                }
            } else {
                message.error('网络错误');
            }
        } catch (error: any) {
            console.error('Save failed:', error);
            message.error(error.message || '保存出错');
        } finally {
            setIsSaving(false);
        }
    };

    if (viewMode === 'canvas') {
        return (
            <div className={`flex flex - col bg - white transition - all duration - 300 ${isMaximized ? 'fixed inset-0 z-50 h-screen' : 'h-full'} `}>
                <div className="flex items-center justify-between px-4 py-2 bg-white border-b border-slate-200">
                    <div className="flex items-center gap-2">
                        <button
                            onClick={handleBackToList}
                            disabled={isSaving}
                            className={`text-slate-500 hover:text-slate-700 text-sm ${isSaving ? 'opacity-50 cursor-not-allowed' : ''}`}
                        >
                            &larr; 返回
                        </button>
                        <div className="h-4 w-px bg-slate-200 mx-2"></div>
                        <h2 className="font-bold text-slate-800">
                            {editingWorkflow ? `编辑工作流: ${editingWorkflow.name} ` : '新建工作流'}
                        </h2>
                    </div>
                    <div className="flex items-center gap-2">
                        <button
                            onClick={handleSaveClick}
                            className={`px-3 py-1.5 bg-blue-600 text-white hover:bg-blue-700 rounded text-sm font-medium shadow-sm transition-colors ${isSaving ? 'opacity-50 cursor-not-allowed' : ''}`}
                            disabled={isSaving}
                        >
                            {isSaving ? '保存中...' : '保存'}
                        </button>
                    </div>
                </div>
                <div className="flex-1 overflow-hidden">
                    <WorkflowCanvas
                        initialNodes={editingWorkflow ? (editingWorkflow.content ? JSON.parse(editingWorkflow.content).nodes : []) : []}
                        initialEdges={editingWorkflow ? (editingWorkflow.content ? JSON.parse(editingWorkflow.content).edges : []) : []}
                        onChange={(nodes, edges) => {
                            setCurrentNodes(nodes);
                            setCurrentEdges(edges);
                        }}
                    />
                </div>

                <Modal
                    title={editingWorkflow ? "保存工作流配置" : "新建工作流"}
                    open={isSaveModalOpen}
                    onOk={handleSaveConfirm}
                    confirmLoading={isSaving}
                    onCancel={() => !isSaving && setIsSaveModalOpen(false)}
                    okText="保存"
                    cancelText="取消"
                >
                    <Form form={form} layout="vertical">
                        <Form.Item
                            name="name"
                            label="工作流名称"
                            rules={[{ required: true, message: '请输入工作流名称' }]}
                        >
                            <Input placeholder="请输入工作流名称" />
                        </Form.Item>
                        <Form.Item
                            name="owner"
                            label="负责人"
                            rules={[{ required: true, message: '请输入负责人' }]}
                        >
                            <Input placeholder="请输入负责人姓名" />
                        </Form.Item>

                        <Form.Item
                            name="description"
                            label="描述"
                        >
                            <Input.TextArea rows={4} placeholder="请输入工作流描述" />
                        </Form.Item>
                    </Form>
                </Modal>
            </div>
        );
    }

    return (
        <div className="h-full flex flex-col bg-white rounded-lg shadow-sm border border-slate-200">
            {/* Toolbar */}
            <div className="p-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            type="text"
                            placeholder="搜索工作流名称/ID..."
                            className="pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 w-64"
                        />
                    </div>
                    <select className="px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/20 text-slate-600">
                        <option value="">所有项目</option>
                        <option value="p1">Project A</option>
                    </select>

                </div>
                <div className="flex gap-2">

                    <button
                        onClick={handleNewWorkflow}
                        className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-bold rounded-lg transition-colors shadow-sm"
                    >
                        <Plus size={16} />
                        新建工作流
                    </button>
                    <button
                        onClick={handleDownloadTemplate}
                        className="flex items-center gap-2 px-4 py-2 bg-white text-slate-600 border border-slate-200 hover:bg-slate-50 hover:text-blue-600 text-sm font-medium rounded-lg transition-colors shadow-sm"
                    >
                        <Download size={16} />
                        下载模板
                    </button>
                    <button
                        onClick={handleImportClick}
                        className="flex items-center gap-2 px-4 py-2 bg-white text-slate-600 border border-slate-200 hover:bg-slate-50 hover:text-blue-600 text-sm font-medium rounded-lg transition-colors shadow-sm"
                    >
                        <Upload size={16} />
                        导入
                    </button>
                    <input
                        type="file"
                        ref={fileInputRef}
                        onChange={handleImportWorkflow}
                        className="hidden"
                        accept=".json"
                    />
                </div>
            </div>

            {/* Table */}
            <div className="flex-1 overflow-auto">
                <table className="w-full text-sm text-left">
                    <thead className="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-100 sticky top-0 z-10">
                        <tr>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">ID</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">工作流名称</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">负责人</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">描述</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">创建时间</th>
                            <th className="px-6 py-3 font-medium whitespace-nowrap">修改时间</th>

                            <th className="px-6 py-3 font-medium whitespace-nowrap text-right">操作</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                        {workflows.map((wf) => (
                            <tr key={wf.id} className="hover:bg-slate-50 transition-colors group">
                                <td className="px-6 py-4 font-mono text-slate-500">{wf.id}</td>
                                <td className="px-6 py-4 font-medium text-blue-600 hover:underline cursor-pointer" onClick={() => handleEditWorkflow(wf)}>
                                    {wf.name}
                                </td>
                                <td className="px-6 py-4 text-slate-600">
                                    <div className="flex items-center gap-2">
                                        <div className="w-6 h-6 rounded-full bg-slate-200 flex items-center justify-center text-xs text-slate-500">
                                            {wf.owner[0]}
                                        </div>
                                        {wf.owner}
                                    </div>
                                </td>
                                <td className="px-6 py-4 text-slate-600">{wf.description}</td>
                                <td className="px-6 py-4 text-slate-500 text-xs whitespace-nowrap">
                                    {wf.createTime ? dayjs(wf.createTime).format('YYYY-MM-DD HH:mm:ss') : '-'}
                                </td>
                                <td className="px-6 py-4 text-slate-500 text-xs whitespace-nowrap">
                                    {wf.updateTime ? dayjs(wf.updateTime).format('YYYY-MM-DD HH:mm:ss') : '-'}
                                </td>
                                <td className="px-6 py-4 text-right whitespace-nowrap">
                                    <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                        <button className="p-1 text-slate-400 hover:text-blue-600" title="编辑" onClick={() => handleEditWorkflow(wf)}>
                                            <Edit size={16} />
                                        </button>
                                        <button className="p-1 text-slate-400 hover:text-green-600" title="运行一次">
                                            <Play size={16} />
                                        </button>
                                        <button className="p-1 text-slate-400 hover:text-red-600" title="删除" onClick={() => handleDeleteWorkflow(wf)}>
                                            <Trash2 size={16} />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            <div className="p-4 border-t border-slate-200 bg-slate-50">
                <Pagination current={1} total={20} pageSize={10} onChange={() => { }} />
            </div>
        </div>
    );
};

export default WorkflowDefinition;
