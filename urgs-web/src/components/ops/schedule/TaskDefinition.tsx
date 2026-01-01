import React, { useState, useEffect, useMemo } from 'react';
import { Search, Plus, Folder, FileCode, MoreVertical, Edit, Trash2, Play, Save, X, Link, GitFork, Calendar, LayoutGrid, List, FileText, Server, Activity, CheckCircle, ChevronUp, ChevronDown, CheckSquare, Square, PauseCircle, PlayCircle, Filter } from 'lucide-react';
import { message, Select, Modal, DatePicker, Checkbox } from 'antd';
import dayjs from 'dayjs';
import Pagination from '../../common/Pagination';
import TaskConfigForm from './TaskConfigForm';
import { useTaskDependencies } from './hooks/useTaskDependencies';
import DependencyGraphModal from './modals/DependencyGraphModal';
import ScheduleStatsCard from './ScheduleStatsCard';
import TaskCard from './TaskCard';

const TaskDefinition: React.FC = () => {
    const [viewMode, setViewMode] = useState<'list' | 'editor'>('list');
    const [selectedTask, setSelectedTask] = useState<any>(null);

    const [tasks, setTasks] = useState<any[]>([]);
    const [workflows, setWorkflows] = useState<any[]>([]);
    const [selectedWorkflows, setSelectedWorkflows] = useState<string[]>([]);
    const [searchText, setSearchText] = useState('');
    const [pagination, setPagination] = useState({ current: 1, pageSize: 10, total: 0 });
    const [loading, setLoading] = useState(false);
    const [selectedRowKeys, setSelectedRowKeys] = useState<string[]>([]);
    const [dispatchModalVisible, setDispatchModalVisible] = useState(false);
    const [dispatchTaskIds, setDispatchTaskIds] = useState<string[]>([]); // Track tasks to dispatch
    const [dispatchDate, setDispatchDate] = useState<dayjs.Dayjs | null>(dayjs());
    const [systems, setSystems] = useState<any[]>([]);
    const [listViewMode, setListViewMode] = useState<'list' | 'card'>('list');
    const [showStats, setShowStats] = useState(true);
    const [globalStats, setGlobalStats] = useState({ total: 0, enabled: 0, disabled: 0, systems: 0, workflows: 0 });
    const [targetWorkflowId, setTargetWorkflowId] = useState<string>('');
    const [statusFilter, setStatusFilter] = useState<number | ''>('');
    const [systemFilter, setSystemFilter] = useState<number | ''>('');


    const {
        dependencyGraph,
        setDependencyGraph,
        handleShowDependencies
    } = useTaskDependencies();

    // Compute stats
    const stats = useMemo(() => {
        const typeCount: Record<string, number> = {};
        tasks.forEach(t => {
            typeCount[t.type] = (typeCount[t.type] || 0) + 1;
        });
        return {
            total: tasks.length,
            enabled: tasks.filter(t => t.status !== 0).length,
            disabled: tasks.filter(t => t.status === 0).length,
            typeCount
        };
    }, [tasks]);


    const fetchTasks = async (page = pagination.current, size = pagination.pageSize) => {
        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const params = new URLSearchParams();
            params.append('page', page.toString());
            params.append('size', size.toString());
            if (searchText) params.append('keyword', searchText);
            if (selectedWorkflows.length > 0 && !selectedWorkflows.includes('ALL')) {
                params.append('workflowIds', selectedWorkflows.join(','));
            }
            if (statusFilter !== '') {
                params.append('status', statusFilter.toString());
            }
            if (systemFilter !== '') {
                params.append('systemId', systemFilter.toString());
            }

            const res = await fetch(`/api/task/list?${params.toString()}`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (res.ok) {
                const data = await res.json();

                let taskList = [];
                let total = 0;

                // Handle both Array (legacy/list) and Page object (pagination) responses
                if (Array.isArray(data)) {
                    taskList = data;
                    total = data.length;
                } else {
                    taskList = data.records || [];
                    total = data.total || 0;
                }

                // Map backend entity to frontend display format
                const mappedTasks = taskList.map((t: any) => ({
                    id: t.id,
                    name: t.name,
                    type: t.type,
                    systemId: t.systemId,
                    group: 'default', // Backend doesn't have group yet
                    status: t.status,
                    updateTime: t.updateTime,
                    ...JSON.parse(t.content || '{}') // Merge content
                }));
                setTasks(mappedTasks);
                setPagination(prev => ({ ...prev, current: page, pageSize: size, total }));
                setSelectedRowKeys([]); // Clear selection on refresh
            }
        } catch (error) {
            console.error('Failed to fetch tasks:', error);
            message.error('获取任务列表失败');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTasks(1, pagination.pageSize);
    }, [selectedWorkflows, statusFilter, systemFilter]);

    const fetchWorkflows = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/workflow/list', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (res.ok) {
                const data = await res.json();
                setWorkflows(data);
            }
        } catch (error) {
            console.error('Failed to fetch workflows:', error);
        }
    };

    const fetchSystems = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/sys/system/list', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (res.ok) {
                const data = await res.json();
                setSystems(data);
            }
        } catch (error) {
            console.error('Failed to fetch systems:', error);
        }
    };

    const fetchGlobalStats = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/task/global-stats', {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (res.ok) {
                const data = await res.json();
                setGlobalStats(data);
            }
        } catch (error) {
            console.error('Failed to fetch global stats:', error);
        }
    };

    useEffect(() => {
        fetchTasks();
        fetchWorkflows();
        fetchSystems();
        fetchGlobalStats();
    }, []);

    const handleWorkflowChange = (values: string[]) => {
        if (values.includes('ALL')) {
            if (!selectedWorkflows.includes('ALL')) {
                setSelectedWorkflows(['ALL']);
            } else {
                setSelectedWorkflows(values.filter(v => v !== 'ALL'));
            }
        } else {
            setSelectedWorkflows(values);
        }
    };

    const [allTasksOptions, setAllTasksOptions] = useState<{ label: string; value: string }[]>([]);

    const fetchAllTasksForSelect = async () => {
        try {
            const token = localStorage.getItem('auth_token');
            // Fetch a larger list for dropdown options. 
            // Ideally backend should provide a lightweight 'list all' or search API.
            const res = await fetch(`/api/task/list?page=1&size=1000`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (res.ok) {
                const data = await res.json();
                const list = Array.isArray(data) ? data : (data.records || []);
                const options = list.map((t: any) => ({ label: t.name, value: t.id }));
                setAllTasksOptions(options);
            }
        } catch (error) {
            console.error('Failed to fetch all tasks:', error);
        }
    };

    const computedAvailableTasks = useMemo(() => {
        let allowedTaskIds: Set<string> | null = null;
        let workflowIdForContext = targetWorkflowId;

        // If existing task and no explicit target workflow (which is normal for edit mode),
        // try to find the workflow it belongs to.
        if (selectedTask?.id && !workflowIdForContext) {
            const foundWf = workflows.find(w => {
                // Skip workflow filter check if 'ALL' was selected in list, just scan all
                try {
                    const c = JSON.parse(w.content || '{}');
                    return c.nodes?.some((n: any) => n.id === selectedTask.id);
                } catch { return false; }
            });
            if (foundWf) workflowIdForContext = foundWf.id;
        }

        if (workflowIdForContext) {
            const wf = workflows.find(w => String(w.id) === String(workflowIdForContext));
            if (wf) {
                try {
                    const c = JSON.parse(wf.content || '{}');
                    if (Array.isArray(c.nodes)) {
                        allowedTaskIds = new Set(c.nodes.map((n: any) => n.id));
                    }
                } catch (e) { }
            }
        }

        if (allowedTaskIds) {
            return allTasksOptions.filter(t =>
                t.value !== selectedTask?.id && allowedTaskIds?.has(t.value)
            );
        }

        // If creating new task and no workflow selected, allow no dependencies (must select WF first)
        if (!selectedTask?.id && !targetWorkflowId) {
            return [];
        }

        return allTasksOptions.filter(t => t.value !== selectedTask?.id);
    }, [allTasksOptions, selectedTask, targetWorkflowId, workflows]);

    const handleEditTask = (task: any) => {
        setSelectedTask(task);
        setViewMode('editor');
        fetchAllTasksForSelect();
    };

    const handleNewTask = () => {
        setSelectedTask(null);
        setViewMode('editor');

        // Auto-select workflow if strictly one is selected in filter (and not ALL)
        if (selectedWorkflows.length === 1 && selectedWorkflows[0] !== 'ALL') {
            setTargetWorkflowId(selectedWorkflows[0]);
        } else {
            setTargetWorkflowId('');
        }

        fetchAllTasksForSelect();
    };

    const handleBackToList = () => {
        setViewMode('list');
        setSelectedTask(null);
    };

    const handleTaskChange = (newData: any) => {
        setSelectedTask((prev: any) => ({ ...prev, ...newData }));
    };

    const handleSaveTask = async () => {
        // Validation: New tasks must have a workflow selected
        if (!selectedTask?.id && !targetWorkflowId) {
            message.error('新建任务必须选择所属工作流');
            return;
        }

        if (!selectedTask && !targetWorkflowId) return; // Should not happen given validation

        try {
            const token = localStorage.getItem('auth_token');
            const payload = {
                id: selectedTask?.id,
                name: selectedTask?.name || 'New Task',
                type: selectedTask?.type || 'SHELL',
                systemId: selectedTask?.systemId,
                content: JSON.stringify(selectedTask || {}),
                preTaskIds: selectedTask?.dependentTasks || [],
                status: selectedTask?.status
            };

            const response = await fetch('/api/task/save', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            if (response.ok) {
                const savedTaskId = await response.text();

                // If it's a new task, associate with workflow
                if (!selectedTask?.id && targetWorkflowId) {
                    try {
                        // 1. Get workflow details
                        const wfRes = await fetch(`/api/workflow/${targetWorkflowId}`, {
                            headers: { 'Authorization': `Bearer ${token}` }
                        });
                        if (wfRes.ok) {
                            const workflow = await wfRes.json();
                            // 2. Parse content
                            let content: any = {};
                            try {
                                content = JSON.parse(workflow.content || '{}');
                            } catch (e) { }
                            if (!content.nodes) content.nodes = [];

                            // 3. Add node if not exists
                            if (!content.nodes.some((n: any) => n.id === savedTaskId)) {
                                content.nodes.push({
                                    id: savedTaskId,
                                    label: payload.name,
                                    type: payload.type,
                                    x: 50 + (content.nodes.length * 20), // Simple offset
                                    y: 50 + (content.nodes.length * 20)
                                });

                                // 4. Save workflow
                                await fetch('/api/workflow/save', {
                                    method: 'POST',
                                    headers: {
                                        'Content-Type': 'application/json',
                                        'Authorization': `Bearer ${token}`
                                    },
                                    body: JSON.stringify({
                                        ...workflow,
                                        content: JSON.stringify(content)
                                    })
                                });
                                message.success(`任务保存成功，并已关联到 "${workflow.name}"`);
                            } else {
                                message.success('任务保存成功');
                            }
                        }
                    } catch (e) {
                        console.error('Failed to associate task with workflow', e);
                        message.warning('任务保存成功，但自动关联工作流失败');
                    }
                } else {
                    message.success('任务保存成功');
                }

                fetchTasks(); // Refresh list
                if (!selectedTask?.id) {
                    // Add slight delay or just go back
                    handleBackToList();
                }
            } else {
                message.error('保存失败');
            }
        } catch (error) {
            console.error('Save error:', error);
            message.error('保存出错');
        }
    };

    const handleDeleteTask = (task: any) => {
        Modal.confirm({
            title: '确认删除',
            content: `确定要删除任务 "${task.name}" 吗？`,
            okText: '确认',
            cancelText: '取消',
            onOk: async () => {
                try {
                    const token = localStorage.getItem('auth_token');
                    const res = await fetch(`/api/task/${task.id}`, {
                        method: 'DELETE',
                        headers: {
                            'Authorization': `Bearer ${token}`
                        }
                    });
                    if (res.ok) {
                        message.success('删除成功');
                        fetchTasks();
                    } else {
                        message.error('删除失败');
                    }
                } catch (error) {
                    console.error('Delete error:', error);
                    message.error('删除出错');
                }
            }
        });
    };

    const getWorkflowName = (taskId: string) => {
        const relatedWorkflows = workflows.filter(w => {
            try {
                const content = JSON.parse(w.content || '{}');
                return content.nodes?.some((n: any) => n.id === taskId);
            } catch (e) {
                return false;
            }
        });
        return relatedWorkflows.map(w => w.name).join(', ') || '-';
    };

    const handleBatchStatusUpdate = async (status: number) => {
        if (selectedRowKeys.length === 0) {
            message.warning('请先选择任务');
            return;
        }

        try {
            setLoading(true);
            const token = localStorage.getItem('auth_token');
            const res = await fetch('/api/task/batch-status', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ ids: selectedRowKeys, status })
            });

            if (res.ok) {
                message.success(status === 1 ? '批量启动成功' : '批量暂停成功');
                fetchTasks(); // Refresh list to see updated status
                setSelectedRowKeys([]);
            } else {
                message.error('操作失败');
            }
        } catch (error) {
            console.error('Batch update error:', error);
            message.error('操作出错');
        } finally {
            setLoading(false);
        }
    };

    const handleDispatch = (taskIds: string[]) => {
        if (taskIds.length === 0) {
            message.warning('请先选择任务');
            return;
        }
        setDispatchTaskIds(taskIds);
        setDispatchModalVisible(true);
    };

    const handleBatchDispatch = () => {
        handleDispatch(selectedRowKeys);
    };

    const handleDispatchConfirm = async () => {
        if (!dispatchDate) {
            message.error('请选择数据日期');
            return;
        }
        const dateStr = dispatchDate.format('YYYY-MM-DD');

        setLoading(true);
        try {
            const token = localStorage.getItem('auth_token');
            const errors: string[] = [];
            let successCount = 0;


            // Use dispatchTaskIds instead of selectedRowKeys
            const targets = dispatchTaskIds.length > 0 ? dispatchTaskIds : selectedRowKeys;

            for (const taskId of targets) {
                const taskName = tasks.find(t => t.id === taskId)?.name || taskId;
                const params = new URLSearchParams();
                params.append('taskId', taskId);
                params.append('dataDate', dateStr);

                const res = await fetch(`/api/task/instance/create?${params.toString()}`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                });

                if (!res.ok) {
                    const msg = await res.text();
                    errors.push(`${taskName}: ${msg}`);
                } else {
                    successCount++;
                }
            }

            if (errors.length > 0) {
                Modal.error({
                    title: '下发结果',
                    content: (
                        <div>
                            <p>成功: {successCount} 个</p>
                            <p className="text-red-500">失败: {errors.length} 个</p>
                            <div className="max-h-60 overflow-auto bg-slate-50 p-2 rounded mt-2 text-xs">
                                {errors.map((err, idx) => (
                                    <div key={idx} className="mb-1">{err}</div>
                                ))}
                            </div>
                        </div>
                    )
                });
            } else {
                message.success(`成功下发 ${successCount} 个任务`);
            }
            setDispatchModalVisible(false);
            setSelectedRowKeys([]);
            setDispatchTaskIds([]);
        } catch (error) {
            console.error(error);
            message.error('下发过程出错');
        } finally {
            setLoading(false);
        }
    };

    if (viewMode === 'editor') {
        return (
            <div className="h-full flex flex-col bg-white rounded-lg shadow-sm border border-slate-200">
                <div className="flex items-center justify-between px-4 py-2 border-b border-slate-200 bg-slate-50/50">
                    <div className="flex items-center gap-2">
                        <button onClick={handleBackToList} className="text-slate-500 hover:text-slate-700 text-sm">
                            &larr; 返回列表
                        </button>
                        <div className="h-4 w-px bg-slate-200 mx-2"></div>
                        <h2 className="font-bold text-slate-800">
                            {selectedTask ? `编辑任务: ${selectedTask.name}` : '新建任务'}
                        </h2>
                    </div>
                    <div className="flex gap-2 items-center">
                        <select
                            value={selectedTask?.type || 'SHELL'}
                            onChange={(e) => setSelectedTask((prev: any) => ({ ...prev, type: e.target.value }))}
                            className="px-3 py-1.5 text-sm border border-slate-200 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white"
                        >
                            <option value="SHELL">SHELL</option>
                            <option value="SQL">SQL</option>
                            <option value="PYTHON">PYTHON</option>
                            <option value="DATAX">DataX</option>
                            <option value="HTTP">HTTP</option>
                            <option value="PROCEDURE">PROCEDURE</option>
                            <option value="DEPENDENT">DEPENDENT</option>
                        </select>
                        {selectedTask?.id && (
                            <select
                                value={selectedTask?.systemId || ''}
                                onChange={(e) => setSelectedTask((prev: any) => ({ ...prev, systemId: e.target.value }))}
                                className="px-3 py-1.5 text-sm border border-slate-200 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white min-w-[120px]"
                            >
                                <option value="">选择系统</option>
                                {systems.map(s => (
                                    <option key={s.id} value={s.id}>{s.name}</option>
                                ))}
                            </select>
                        )}

                        {!selectedTask?.id && (
                            <div className="flex items-center gap-2 border-l border-slate-200 pl-2 ml-1">
                                <span className="text-xs text-slate-500 font-medium">所属工作流:</span>
                                <select
                                    value={targetWorkflowId}
                                    onChange={(e) => setTargetWorkflowId(e.target.value)}
                                    className="px-3 py-1.5 text-sm border border-slate-200 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500/20 bg-white min-w-[140px] text-slate-700"
                                    required
                                >
                                    <option value="" disabled>请选择工作流</option>
                                    {workflows.map(w => (
                                        <option key={w.id} value={w.id}>{w.name}</option>
                                    ))}
                                </select>
                            </div>
                        )}
                        <button
                            onClick={handleSaveTask}
                            className="flex items-center gap-2 px-3 py-1.5 bg-blue-600 text-white hover:bg-blue-700 rounded-md text-sm font-medium shadow-sm transition-colors"
                        >
                            <Save size={16} />
                            保存
                        </button>
                    </div>
                </div>
                <div className="flex-1 overflow-hidden">
                    <TaskConfigForm
                        data={selectedTask}
                        type={selectedTask?.type || 'SHELL'}
                        onChange={handleTaskChange}
                        availableTasks={computedAvailableTasks}
                    />
                </div>
            </div >
        );
    }




    return (
        <div className="h-full flex flex-col bg-slate-50/50 overflow-hidden">
            {/* Header & Statistics Section */}

            {showStats && (
                <div className="grid grid-cols-4 gap-6 mt-2 px-6 animate-in fade-in slide-in-from-top-2 duration-300">
                    <ScheduleStatsCard
                        title="任务总数"
                        value={globalStats.total}
                        icon={<FileText />}
                        color="blue"
                    />
                    <ScheduleStatsCard
                        title="活跃任务"
                        value={globalStats.enabled}
                        icon={<CheckCircle />}
                        color="green"
                    />
                    <ScheduleStatsCard
                        title="接入系统"
                        value={globalStats.systems}
                        icon={<Server />}
                        color="purple"
                    />
                    <ScheduleStatsCard
                        title="关联工作流"
                        value={globalStats.workflows}
                        icon={<Activity />}
                        color="amber"
                    />
                </div>
            )}
            {/* Toolbar */}
            <div className="px-6 py-4 bg-white/80 backdrop-blur-md border-b border-slate-200/60 flex justify-between items-center sticky top-0 z-20">
                <div className="flex items-center gap-4">
                    <div className="relative group">
                        <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-blue-500 transition-colors" />
                        <input
                            type="text"
                            placeholder="搜索任务..."
                            value={searchText}
                            onChange={(e) => setSearchText(e.target.value)}
                            onKeyDown={(e) => {
                                if (e.key === 'Enter') {
                                    fetchTasks(1, pagination.pageSize);
                                }
                            }}
                            className="pl-10 pr-4 py-2 text-xs border border-slate-200/80 rounded-xl focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-400 w-44 bg-slate-50/50 transition-all font-medium"
                        />
                    </div>

                    <Select
                        mode="multiple"
                        allowClear
                        style={{ width: 220 }}
                        placeholder="工作流筛选"
                        value={selectedWorkflows}
                        onChange={handleWorkflowChange}
                        options={[{ label: '全部', value: 'ALL' }, ...workflows.map(w => ({ label: w.name, value: w.id }))]}
                        maxTagCount="responsive"
                    />

                    <Select
                        style={{ width: 140 }}
                        placeholder="系统筛选"
                        allowClear
                        value={systemFilter}
                        onChange={(value) => setSystemFilter(value)}
                        options={[{ label: '全部系统', value: '' }, ...systems.map(s => ({ label: s.name, value: s.id }))]}
                    />

                    <Select
                        style={{ width: 120 }}
                        placeholder="状态筛选"
                        value={statusFilter}
                        onChange={(value) => setStatusFilter(value)}
                        options={[
                            { label: '全部状态', value: '' },
                            { label: '启用', value: 1 },
                            { label: '禁用', value: 0 }
                        ]}
                    />

                    <button
                        onClick={() => fetchTasks(1, pagination.pageSize)}
                        className="p-2.5 rounded-xl border border-slate-200/80 bg-white text-slate-500 hover:text-blue-600 hover:border-blue-200 transition-all"
                        title="查询"
                    >
                        <Search size={18} />
                    </button>
                </div>
                <div className="flex items-center gap-4">
                    {/* View Toggle */}
                    <div className="flex items-center bg-slate-100/80 rounded-xl p-1 border border-slate-200/50">
                        <button
                            onClick={() => setListViewMode('list')}
                            className={`p-2 rounded-lg transition-all ${listViewMode === 'list' ? 'bg-white shadow-sm text-blue-600' : 'text-slate-400 hover:text-slate-600'}`}
                            title="列表视图"
                        >
                            <List size={18} strokeWidth={2.5} />
                        </button>
                        <button
                            onClick={() => setListViewMode('card')}
                            className={`p-2 rounded-lg transition-all ${listViewMode === 'card' ? 'bg-white shadow-sm text-blue-600' : 'text-slate-400 hover:text-slate-600'}`}
                            title="卡片视图"
                        >
                            <LayoutGrid size={18} strokeWidth={2.5} />
                        </button>
                    </div>
                </div>

                {selectedRowKeys.length > 0 && (
                    <div className="flex items-center gap-2 animate-in fade-in slide-in-from-right-4 duration-300">
                        <button
                            onClick={() => handleBatchStatusUpdate(1)}
                            className="flex items-center gap-1.5 px-3 py-2 bg-emerald-50 text-emerald-600 hover:bg-emerald-100 hover:text-emerald-700 text-sm font-medium rounded-xl transition-colors border border-emerald-200/50"
                            title="批量启动"
                        >
                            <PlayCircle size={16} />
                            启动
                        </button>
                        <button
                            onClick={() => handleBatchStatusUpdate(0)}
                            className="flex items-center gap-1.5 px-3 py-2 bg-amber-50 text-amber-600 hover:bg-amber-100 hover:text-amber-700 text-sm font-medium rounded-xl transition-colors border border-amber-200/50"
                            title="批量暂停"
                        >
                            <PauseCircle size={16} />
                            暂停
                        </button>
                        <div className="w-px h-4 bg-slate-200 mx-1"></div>
                        <button
                            onClick={handleBatchDispatch}
                            className="flex items-center gap-1.5 px-3 py-2 bg-purple-50 text-purple-600 hover:bg-purple-100 hover:text-purple-700 text-sm font-medium rounded-xl transition-colors border border-purple-200/50"
                            title="批量执行"
                        >
                            <Calendar size={16} />
                            执行
                        </button>
                    </div>
                )}

                <button
                    onClick={handleNewTask}
                    className="flex items-center gap-2.5 px-5 py-2.5 bg-blue-50 text-blue-600 text-sm font-bold rounded-2xl hover:bg-blue-100 hover:text-blue-700 active:scale-95 transition-all border border-blue-200/50"
                >
                    <Plus size={16} strokeWidth={2.5} />
                    新建任务
                </button>
            </div>


            {/* Content Area */}
            <div className="flex-1 overflow-auto px-6 py-6">
                {listViewMode === 'card' ? (
                    /* Card Grid View */
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                        {loading && (
                            <div className="col-span-full py-20 text-center text-slate-500">
                                加载中...
                            </div>
                        )}
                        {!loading && tasks.length === 0 && (
                            <div className="col-span-full py-20 text-center text-slate-500">
                                暂无数据
                            </div>
                        )}
                        {!loading && tasks.map((task) => (
                            <TaskCard
                                key={task.id}
                                task={{
                                    ...task,
                                    systemName: systems.find(s => String(s.id) === String(task.systemId))?.name,
                                    workflowName: getWorkflowName(task.id),
                                    cronExpression: task.cronExpression
                                }}
                                onEdit={handleEditTask}
                                onShowDependencies={(id) => handleShowDependencies(tasks.find(t => t.id === id), 'upstream')}
                            />
                        ))}
                    </div>
                ) : (
                    /* Table List View */
                    <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
                        <table className="w-full text-sm text-left">
                            <thead className="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-100 sticky top-0 z-10">
                                <tr>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap w-10">
                                        <Checkbox
                                            checked={tasks.length > 0 && selectedRowKeys.length === tasks.length}
                                            indeterminate={selectedRowKeys.length > 0 && selectedRowKeys.length < tasks.length}
                                            onChange={(e) => {
                                                if (e.target.checked) {
                                                    setSelectedRowKeys(tasks.map(t => t.id));
                                                } else {
                                                    setSelectedRowKeys([]);
                                                }
                                            }}
                                        />
                                    </th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">ID</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">任务名称</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">所属工作流</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">所属系统</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">状态</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">类型</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">执行器组</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">更新时间</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap text-right">操作</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100 relative">
                                {loading && (
                                    <tr>
                                        <td colSpan={8} className="py-20 text-center text-slate-500">
                                            加载中...
                                        </td>
                                    </tr>
                                )}
                                {!loading && tasks.length === 0 && (
                                    <tr>
                                        <td colSpan={8} className="py-20 text-center text-slate-500">
                                            暂无数据
                                        </td>
                                    </tr>
                                )}
                                {!loading && tasks.map((task) => (
                                    <tr key={task.id} className={`transition-colors group ${selectedRowKeys.includes(task.id) ? 'bg-blue-50/50 hover:bg-blue-50' : 'hover:bg-slate-50'}`}>
                                        <td className="px-6 py-2">
                                            <Checkbox
                                                checked={selectedRowKeys.includes(task.id)}
                                                onChange={(e) => {
                                                    if (e.target.checked) {
                                                        setSelectedRowKeys(prev => [...prev, task.id]);
                                                    } else {
                                                        setSelectedRowKeys(prev => prev.filter(id => id !== task.id));
                                                    }
                                                }}
                                            />
                                        </td>
                                        <td className="px-6 py-2 font-mono text-slate-500 max-w-[150px] truncate" title={task.id}>{task.id}</td>
                                        <td className="px-6 py-2 font-medium text-slate-700 max-w-[200px] truncate" title={task.name}>{task.name}</td>
                                        <td className="px-6 py-2 text-slate-600 max-w-[150px]">
                                            <span className="inline-block max-w-full truncate px-2 py-0.5 rounded text-xs font-medium bg-blue-50 text-blue-700 border border-blue-100" title={getWorkflowName(task.id)}>
                                                {getWorkflowName(task.id)}
                                            </span>
                                        </td>
                                        <td className="px-6 py-2 text-slate-600 whitespace-nowrap">
                                            {systems.find(s => String(s.id) === String(task.systemId))?.name || '-'}
                                        </td>
                                        <td className="px-6 py-2">
                                            {task.status === 1 ? (
                                                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 border border-emerald-100/50">
                                                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                                                    启用
                                                </span>
                                            ) : (
                                                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-500 border border-slate-200/50">
                                                    <span className="w-1.5 h-1.5 rounded-full bg-slate-400"></span>
                                                    禁用
                                                </span>
                                            )}
                                        </td>
                                        <td className="px-6 py-2">
                                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-700 border border-slate-200">
                                                {task.type}
                                            </span>
                                        </td>
                                        <td className="px-6 py-2 text-slate-600">{task.group}</td>
                                        <td className="px-6 py-2 text-slate-500 text-xs">{task.updateTime}</td>
                                        <td className="px-6 py-2 text-right whitespace-nowrap">
                                            <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">

                                                <button className="p-1 text-slate-400 hover:text-blue-600" title="编辑" onClick={() => handleEditTask(task)}>
                                                    <Edit size={16} />
                                                </button>
                                                <button className="p-1 text-slate-400 hover:text-green-600" title="执行" onClick={() => handleDispatch([task.id])}>
                                                    <Play size={16} />
                                                </button>

                                                <button className="p-1 text-slate-400 hover:text-blue-600" title="查看依赖 (上游)" onClick={() => handleShowDependencies(task, 'upstream')}>
                                                    <Link size={16} />
                                                </button>
                                                <button className="p-1 text-slate-400 hover:text-purple-600" title="查看被依赖 (下游)" onClick={() => handleShowDependencies(task, 'downstream')}>
                                                    <GitFork size={16} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            <div className="p-4 border-t border-slate-200 bg-white">
                <Pagination
                    current={pagination.current}
                    total={pagination.total}
                    pageSize={pagination.pageSize}
                    onChange={(page, size) => fetchTasks(page, size)}
                    showSizeChanger
                />
            </div>

            <DependencyGraphModal
                visible={dependencyGraph.visible}
                onCancel={() => setDependencyGraph(prev => ({ ...prev, visible: false }))}
                nodes={dependencyGraph.nodes}
                edges={dependencyGraph.edges}
            />

            <Modal
                title="批量下发任务"
                open={dispatchModalVisible}
                onOk={handleDispatchConfirm}
                onCancel={() => setDispatchModalVisible(false)}
                confirmLoading={loading}
            >
                <div className="py-4">
                    <div className="mb-2 text-slate-600">请选择数据日期：</div>
                    <DatePicker
                        className="w-full"
                        value={dispatchDate}
                        onChange={setDispatchDate}
                        format="YYYY-MM-DD"
                    />
                    <div className="mt-4 text-sm text-slate-500">
                        已选择 {selectedRowKeys.length} 个任务。
                        <br />
                        注意：如果任务在该日期已存在实例，将不会重复创建。
                    </div>
                </div>
            </Modal>
        </div >
    );
};

export default TaskDefinition;
