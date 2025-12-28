import React, { useState, useEffect, useMemo } from 'react';
import { Search, RotateCw, StopCircle, FileText, CheckCircle, X, RefreshCw, Terminal, Eye, EyeOff, Play, ArrowUpCircle, ArrowDownCircle, Boxes, ClipboardList, LayoutGrid, List, Activity, XCircle, Clock, ChevronUp, ChevronDown, Filter } from 'lucide-react';
import { message, DatePicker, Modal } from 'antd';
import dayjs from 'dayjs';
import Pagination from '../../common/Pagination';
import { get, post } from '../../../utils/request';
import { useTaskDependencies } from './hooks/useTaskDependencies';
import DependencyGraphModal from './modals/DependencyGraphModal';
import ScheduleStatsCard from './ScheduleStatsCard';
import InstanceCard from './InstanceCard';

interface TaskInstance {
    id: string;
    taskId: string;
    taskType: string;
    dataDate: string;
    status: string;
    retryCount: number;
    startTime: string;
    endTime: string;
    createTime: string;
    systemId: number;
}

interface Task {
    id: string;
    name: string;
    content: string;
}

interface Workflow {
    id: string;
    name: string;
    owner: string; // Add owner field
    content: string;
}

const TaskInstance: React.FC = () => {
    const [showLog, setShowLog] = useState(false);
    const [selectedInstance, setSelectedInstance] = useState<TaskInstance | null>(null);
    const [instances, setInstances] = useState<TaskInstance[]>([]);
    const [loading, setLoading] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [dataDateFilter, setDataDateFilter] = useState<string>('');
    const [executionDateFilter, setExecutionDateFilter] = useState<string>(dayjs().format('YYYY-MM-DD'));
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [selectedRowKeys, setSelectedRowKeys] = useState<string[]>([]);

    // New State
    const [workflowFilter, setWorkflowFilter] = useState('');
    const [systemFilter, setSystemFilter] = useState('');
    const [showIds, setShowIds] = useState(false);
    const [systems, setSystems] = useState<any[]>([]);
    const [listViewMode, setListViewMode] = useState<'list' | 'card'>('list');
    const [showStats, setShowStats] = useState(true);
    const [tasks, setTasks] = useState<Record<string, Task>>({});
    const [workflows, setWorkflows] = useState<Workflow[]>([]);
    const [taskToWorkflowMap, setTaskToWorkflowMap] = useState<Record<string, string>>({}); // taskId -> workflowName
    const [taskToWorkflowIdMap, setTaskToWorkflowIdMap] = useState<Record<string, string>>({}); // taskId -> workflowId
    const [taskToWorkflowOwnerMap, setTaskToWorkflowOwnerMap] = useState<Record<string, string>>({}); // taskId -> workflowOwner

    // Dependency Graph Hook
    const { dependencyGraph, setDependencyGraph, handleShowDependencies } = useTaskDependencies();

    // Fetch Metadata (Tasks & Workflows) for mapping
    useEffect(() => {
        const fetchMetadata = async () => {
            try {
                const [taskRes, workflowList, systemList] = await Promise.all([
                    get<any>('/api/task/list?size=10000'), // Fetch all tasks for mapping
                    get<Workflow[]>('/api/workflow/list'),
                    get<any[]>('/api/sys/system/list')
                ]);

                setSystems(systemList || []);

                const taskList = taskRes.records || [];

                // Map Tasks
                const taskMap: Record<string, Task> = {};
                (taskList || []).forEach((t: any) => taskMap[t.id] = t);
                setTasks(taskMap);

                // Map Workflows and Task->Workflow relationship
                setWorkflows(workflowList || []);
                const t2wName: Record<string, string> = {}; // taskId -> workflowName
                const t2wId: Record<string, string> = {}; // taskId -> workflowId
                const t2wOwner: Record<string, string> = {}; // taskId -> workflowOwner

                (workflowList || []).forEach(w => {
                    try {
                        const content = JSON.parse(w.content || '{}');
                        if (content.nodes && Array.isArray(content.nodes)) {
                            content.nodes.forEach((node: any) => {
                                // Assuming node.id or node.data.id corresponds to task.id
                                const taskId = node.data?.id || node.id;
                                t2wName[taskId] = w.name;
                                t2wId[taskId] = String(w.id); // Ensure ID is string for comparison
                                t2wOwner[taskId] = w.owner || '';
                            });
                        }
                    } catch (e) {
                        console.error('Error parsing workflow content', e);
                    }
                });
                setTaskToWorkflowMap(t2wName);
                setTaskToWorkflowIdMap(t2wId);
                setTaskToWorkflowOwnerMap(t2wOwner);

            } catch (error) {
                console.error('Error fetching metadata:', error);
            }
        };
        fetchMetadata();
    }, []);

    const fetchInstances = async () => {
        setLoading(true);
        try {
            const params: Record<string, string> = {};
            if (searchTerm) params['keyword'] = searchTerm;
            if (statusFilter) params['status'] = statusFilter;
            if (dataDateFilter) params['dataDate'] = dataDateFilter;
            if (executionDateFilter) params['executionDate'] = executionDateFilter;

            const data = await get<TaskInstance[]>('/api/task/instance/list', params);
            setInstances(data || []);
        } catch (error) {
            console.error('Error fetching task instances:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchInstances();
        setCurrentPage(1); // Reset to first page on filter change
        setSelectedRowKeys([]); // Reset selection
    }, [statusFilter, dataDateFilter, executionDateFilter]);

    // Filter instances client-side for Workflow (since API doesn't support it yet)
    const filteredInstances = useMemo(() => {
        let result = instances;
        if (workflowFilter) {
            result = result.filter(inst => {
                // Check if the task belongs to the selected workflow by ID
                return taskToWorkflowIdMap[inst.taskId] === workflowFilter;
            });
        }
        if (systemFilter) {
            result = result.filter(inst => String(inst.systemId) === systemFilter);
        }
        return result;
    }, [instances, workflowFilter, systemFilter, taskToWorkflowIdMap]);

    const paginatedInstances = useMemo(() => {
        const start = (currentPage - 1) * pageSize;
        return filteredInstances.slice(start, start + pageSize);
    }, [filteredInstances, currentPage, pageSize]);

    const handleSearch = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter') {
            fetchInstances();
        }
    };

    const [logContent, setLogContent] = useState('');
    const [logLoading, setLogLoading] = useState(false);

    const handleViewLog = async (instance: TaskInstance) => {
        setSelectedInstance(instance);
        setShowLog(true);
        setLogLoading(true);
        try {
            const response = await get<{ content: string }>(`/api/task/instance/log/${instance.id}`);
            setLogContent(response?.content || 'No log content available.');
        } catch (error) {
            console.error('Failed to fetch log', error);
            setLogContent('Failed to load log.');
        } finally {
            setLogLoading(false);
        }
    };

    // Rerun Modal State
    const [rerunModalVisible, setRerunModalVisible] = useState(false);
    const [rerunTargetInstance, setRerunTargetInstance] = useState<TaskInstance | null>(null);
    const [validationLoading, setValidationLoading] = useState(false);
    const [invalidDownstreamTasks, setInvalidDownstreamTasks] = useState<string[]>([]);
    const [batchValidationErrors, setBatchValidationErrors] = useState<Record<string, string[]>>({});

    // Force Success Modal State
    const [forceSuccessModalVisible, setForceSuccessModalVisible] = useState(false);
    const [forceSuccessTargetInstance, setForceSuccessTargetInstance] = useState<TaskInstance | null>(null);

    // Action Handlers
    const handleRerunClick = (instance: TaskInstance) => {
        setRerunTargetInstance(instance);
        setRerunModalVisible(true);
        setInvalidDownstreamTasks([]); // Reset
    };

    const handleBatchRerunClick = () => {
        if (selectedRowKeys.length === 0) return;
        setRerunTargetInstance(null); // Null means batch
        setRerunModalVisible(true);
        setInvalidDownstreamTasks([]);
        setBatchValidationErrors({});
    };

    const isSelectable = (inst: TaskInstance) => ['FAIL', 'SUCCESS', 'STOPPED', 'FORCE_SUCCESS'].includes(inst.status);

    const handleSelectAll = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.checked) {
            const selectableKeys = paginatedInstances.filter(isSelectable).map(inst => inst.id);
            setSelectedRowKeys(selectableKeys);
        } else {
            setSelectedRowKeys([]);
        }
    };

    const handleRowSelect = (id: string) => {
        setSelectedRowKeys(prev => {
            if (prev.includes(id)) {
                return prev.filter(k => k !== id);
            } else {
                return [...prev, id];
            }
        });
    };

    useEffect(() => {
        if (rerunModalVisible) {
            const validate = async () => {
                setValidationLoading(true);
                try {
                    if (rerunTargetInstance) {
                        // Single Validation
                        const invalidTasks = await get<string[]>(`/api/task/instance/validate-rerun/${rerunTargetInstance.id}`);
                        setInvalidDownstreamTasks(invalidTasks || []);
                    } else if (selectedRowKeys.length > 0) {
                        // Batch Validation
                        const errors = await post<Record<string, string[]>>('/api/task/instance/validate-rerun/batch', selectedRowKeys);
                        setBatchValidationErrors(errors || {});
                    }
                } catch (e) {
                    console.error('Validation failed', e);
                } finally {
                    setValidationLoading(false);
                }
            };
            validate();
        }
    }, [rerunModalVisible, rerunTargetInstance, selectedRowKeys]);

    const confirmRerun = async (withDownstream: boolean) => {
        if (withDownstream) {
            if (rerunTargetInstance && invalidDownstreamTasks.length > 0) return;
            if (!rerunTargetInstance && Object.keys(batchValidationErrors).length > 0) return;
        }

        try {
            if (rerunTargetInstance) {
                // Single Rerun
                const url = `/api/task/instance/rerun/${rerunTargetInstance.id}${withDownstream ? '?withDownstream=true' : ''}`;
                await post(url);
                message.success(`重跑请求已发送 (${withDownstream ? '包含下游' : '仅当前'})`);
            } else {
                // Batch Rerun
                const url = `/api/task/instance/rerun/batch${withDownstream ? '?withDownstream=true' : ''}`;
                await post(url, selectedRowKeys);
                message.success(`批量重跑请求已发送 (${selectedRowKeys.length} 个任务)`);
                setSelectedRowKeys([]);
            }
            fetchInstances();
        } catch (e) {
            console.error(e);
            message.error('重跑请求失败');
        } finally {
            setRerunModalVisible(false);
            setRerunTargetInstance(null);
        }
    };

    // Context Menu State
    const [contextMenu, setContextMenu] = useState<{ visible: boolean, x: number, y: number, node: any | null }>({ visible: false, x: 0, y: 0, node: null });

    const handleNodeContextMenu = (event: React.MouseEvent, node: any) => {
        event.preventDefault();
        // Calculate position relative to viewport
        setContextMenu({
            visible: true,
            x: event.clientX,
            y: event.clientY,
            node: node
        });
    };

    const closeContextMenu = () => {
        setContextMenu({ ...contextMenu, visible: false });
    };

    // Close context menu on click elsewhere
    useEffect(() => {
        const handleClick = () => closeContextMenu();
        window.addEventListener('click', handleClick);
        return () => window.removeEventListener('click', handleClick);
    }, [contextMenu]);

    const handleForceSuccess = (instance: TaskInstance) => {
        setForceSuccessTargetInstance(instance);
        setForceSuccessModalVisible(true);
    };

    const confirmForceSuccess = async () => {
        if (!forceSuccessTargetInstance) return;
        try {
            await post(`/api/task/instance/force-success/${forceSuccessTargetInstance.id}`);
            message.success('任务已强制置为成功');
            fetchInstances();
        } catch (e) {
            console.error(e);
            message.error('操作失败');
        } finally {
            setForceSuccessModalVisible(false);
            setForceSuccessTargetInstance(null);
        }
    };

    const handleStop = async (instance: TaskInstance) => {
        if (!confirm('确认停止该任务吗？')) return;
        try {
            await post(`/api/task/instance/stop/${instance.id}`);
            fetchInstances();
        } catch (e) { console.error(e); alert('操作失败'); }
    };



    const handleDependencyView = (instance: TaskInstance, type: 'upstream' | 'downstream') => {
        // Find the task definition for this instance
        const task = tasks[instance.taskId];
        if (task) {
            let taskWithContent = { ...task };
            try {
                const content = JSON.parse(task.content || '{}');
                taskWithContent = { ...task, ...content };
            } catch (e) {
                console.error('Error parsing task content', e);
            }
            handleShowDependencies(taskWithContent, type, instance);
        } else {
            alert('找不到对应的任务定义');
        }
    };

    // Compute stats
    const stats = useMemo(() => {
        const total = filteredInstances.length;
        const success = filteredInstances.filter(i => i.status === 'SUCCESS' || i.status === 'FORCE_SUCCESS').length;
        const failed = filteredInstances.filter(i => i.status === 'FAIL').length;
        const running = filteredInstances.filter(i => i.status === 'RUNNING').length;
        const waiting = filteredInstances.filter(i => i.status === 'WAITING' || i.status === 'PENDING').length;
        const successRate = total > 0 ? ((success / total) * 100).toFixed(1) : '0';
        return { total, success, failed, running, waiting, successRate };
    }, [filteredInstances]);

    return (
        <div className="h-full flex flex-col bg-slate-50/50 overflow-hidden relative">
            {/* Header & Statistics Section */}
            {showStats && (
                <div className="grid grid-cols-5 gap-6 mt-2 px-6 animate-in fade-in slide-in-from-top-2 duration-300">
                    <ScheduleStatsCard
                        title="实例总数"
                        value={stats.total}
                        icon={<ClipboardList />}
                        color="blue"
                    />
                    <ScheduleStatsCard
                        title="运行成功"
                        value={stats.success}
                        icon={<CheckCircle />}
                        color="green"
                        trendValue={`${stats.successRate}%`}
                        trend={Number(stats.successRate) >= 90 ? 'up' : Number(stats.successRate) >= 70 ? 'neutral' : 'down'}
                    />
                    <ScheduleStatsCard
                        title="执行中"
                        value={stats.running}
                        icon={<Activity />}
                        color="purple"
                    />
                    <ScheduleStatsCard
                        title="队列等待"
                        value={stats.waiting}
                        icon={<Clock />}
                        color="amber"
                    />
                    <ScheduleStatsCard
                        title="异常终止"
                        value={stats.failed}
                        icon={<XCircle />}
                        color="red"
                    />
                </div>
            )}

            {/* Toolbar */}
            <div className="px-6 py-4 bg-white/80 backdrop-blur-md border-b border-slate-200/60 flex flex-wrap gap-4 justify-between items-center sticky top-0 z-20">
                <div className="flex items-center gap-3">
                    <div className="relative group">
                        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-blue-500 transition-colors" />
                        <input
                            type="text"
                            placeholder="任务名称 / ID ..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            onKeyDown={handleSearch}
                            className="pl-10 pr-4 py-2.5 text-sm border border-slate-200/80 rounded-2xl focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-400 w-48 bg-slate-50/50 transition-all font-medium"
                        />
                    </div>

                    <div className="flex items-center gap-2 bg-slate-100/50 p-1 rounded-2xl border border-slate-200/60">
                        <select
                            value={workflowFilter}
                            onChange={(e) => setWorkflowFilter(e.target.value)}
                            className="bg-transparent px-3 py-1.5 text-sm text-slate-600 focus:outline-none font-medium min-w-[120px]"
                        >
                            <option value="">所有工作流</option>
                            {workflows.map(w => (
                                <option key={w.id} value={w.id}>{w.name}</option>
                            ))}
                        </select>
                        <div className="w-[1px] h-4 bg-slate-200" />
                        <select
                            value={systemFilter}
                            onChange={(e) => setSystemFilter(e.target.value)}
                            className="bg-transparent px-3 py-1.5 text-sm text-slate-600 focus:outline-none font-medium min-w-[120px]"
                        >
                            <option value="">所有系统</option>
                            {systems.map(s => (
                                <option key={s.id} value={s.id}>{s.name}</option>
                            ))}
                        </select>
                    </div>

                    <div className="flex items-center gap-2">
                        <DatePicker
                            placeholder="数据日期"
                            onChange={(date, dateString) => setDataDateFilter(typeof dateString === 'string' ? dateString : '')}
                            style={{ borderRadius: '14px', height: '42px', width: '130px' }}
                        />
                        <DatePicker
                            placeholder="执行日期"
                            value={executionDateFilter ? dayjs(executionDateFilter) : null}
                            onChange={(date, dateString) => setExecutionDateFilter(typeof dateString === 'string' ? dateString : '')}
                            style={{ borderRadius: '14px', height: '42px', width: '130px' }}
                            allowClear
                        />
                    </div>
                </div>

                <div className="flex items-center gap-4">
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

                    <div className="flex items-center gap-2 p-1 bg-slate-100/50 rounded-2xl">
                        <button
                            onClick={() => setShowIds(!showIds)}
                            className={`px-4 py-2 text-sm font-bold rounded-xl transition-all ${showIds ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}
                        >
                            ID 展示
                        </button>
                        <button
                            onClick={handleBatchRerunClick}
                            disabled={selectedRowKeys.length === 0}
                            className={`px-4 py-2 text-sm font-bold rounded-xl transition-all ${selectedRowKeys.length > 0 ? 'bg-indigo-600 text-white shadow-lg' : 'text-slate-300 pointer-events-none'}`}
                        >
                            批量重跑
                        </button>
                    </div>

                    <button
                        onClick={fetchInstances}
                        className="p-3 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-2xl transition-all"
                        title="刷新"
                    >
                        <RefreshCw size={20} className={loading ? 'animate-spin' : ''} />
                    </button>
                </div>
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
                        {!loading && paginatedInstances.length === 0 && (
                            <div className="col-span-full py-20 text-center text-slate-500">
                                暂无数据
                            </div>
                        )}
                        {!loading && paginatedInstances.map((inst) => (
                            <InstanceCard
                                key={inst.id}
                                instance={{
                                    ...inst,
                                    taskName: tasks[inst.taskId]?.name,
                                    systemName: systems.find(s => String(s.id) === String(inst.systemId))?.name,
                                    workflowName: taskToWorkflowMap[inst.taskId]
                                }}
                                onViewLog={handleViewLog}
                                onRerun={handleRerunClick}
                                onStop={handleStop}
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
                                        <input
                                            type="checkbox"
                                            onChange={handleSelectAll}
                                            checked={paginatedInstances.length > 0 && paginatedInstances.filter(isSelectable).length > 0 && paginatedInstances.filter(isSelectable).every(inst => selectedRowKeys.includes(inst.id))}
                                            className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                                        />
                                    </th>
                                    {showIds && <th className="px-6 py-3 font-medium whitespace-nowrap">实例ID</th>}
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">工作流</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">所属系统</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">任务名称</th>
                                    {showIds && <th className="px-6 py-3 font-medium whitespace-nowrap">任务ID</th>}
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">任务类型</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">数据日期</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">创建时间</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">开始时间</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">结束时间</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">状态</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap">重试</th>
                                    <th className="px-6 py-3 font-medium whitespace-nowrap text-right">操作</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {loading ? (
                                    <tr>
                                        <td colSpan={showIds ? 11 : 9} className="px-6 py-8 text-center text-slate-500">
                                            加载中...
                                        </td>
                                    </tr>
                                ) : filteredInstances.length === 0 ? (
                                    <tr>
                                        <td colSpan={showIds ? 11 : 9} className="px-6 py-8 text-center text-slate-500">
                                            暂无数据
                                        </td>
                                    </tr>
                                ) : (
                                    paginatedInstances.map((inst) => {
                                        // Resolve Workflow Name
                                        const wfName = taskToWorkflowMap[inst.taskId] || '-';

                                        return (
                                            <tr key={inst.id} className="hover:bg-slate-50 transition-colors group">
                                                <td className="px-6 py-4">
                                                    <input
                                                        type="checkbox"
                                                        checked={selectedRowKeys.includes(inst.id)}
                                                        onChange={() => handleRowSelect(inst.id)}
                                                        disabled={!isSelectable(inst)}
                                                        className="rounded border-slate-300 text-blue-600 focus:ring-blue-500 disabled:opacity-50"
                                                    />
                                                </td>
                                                {showIds && <td className="px-6 py-4 font-mono text-slate-500 text-xs">{inst.id}</td>}
                                                <td className="px-6 py-4 font-medium text-slate-700">
                                                    <div className="flex items-center gap-2">
                                                        <span className="truncate max-w-[150px]" title={wfName}>{wfName}</span>
                                                    </div>
                                                </td>
                                                <td className="px-6 py-4 text-slate-600">
                                                    {systems.find(s => String(s.id) === String(inst.systemId))?.name || '-'}
                                                </td>
                                                <td className="px-6 py-4 font-medium text-slate-700">
                                                    <span title={inst.taskId}>{tasks[inst.taskId]?.name || inst.taskId}</span>
                                                </td>
                                                {showIds && <td className="px-6 py-4 font-mono text-slate-500 text-xs">{inst.taskId}</td>}
                                                <td className="px-6 py-4 font-mono text-slate-500 text-xs">{inst.taskType}</td>
                                                <td className="px-6 py-4 font-mono text-slate-500 text-xs">{inst.dataDate}</td>
                                                <td className="px-6 py-4 font-mono text-slate-500 text-xs">{inst.createTime ? dayjs(inst.createTime).format('YYYY-MM-DD HH:mm:ss') : '-'}</td>
                                                <td className="px-6 py-4 font-mono text-slate-500 text-xs">
                                                    {['WAITING', 'PENDING'].includes(inst.status) ? '-' : (inst.startTime ? dayjs(inst.startTime).format('YYYY-MM-DD HH:mm:ss') : '-')}
                                                </td>
                                                <td className="px-6 py-4 font-mono text-slate-500 text-xs">
                                                    {['WAITING', 'PENDING'].includes(inst.status) ? '-' : (inst.endTime ? dayjs(inst.endTime).format('YYYY-MM-DD HH:mm:ss') : '-')}
                                                </td>
                                                <td className="px-6 py-4">
                                                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${inst.status === 'SUCCESS' ? 'bg-green-50 text-green-600 border border-green-200' :
                                                        inst.status === 'FORCE_SUCCESS' ? 'bg-purple-50 text-purple-600 border border-purple-200' :
                                                            inst.status === 'RUNNING' ? 'bg-blue-50 text-blue-600 border border-blue-200' :
                                                                inst.status === 'FAIL' ? 'bg-red-50 text-red-600 border border-red-200' :
                                                                    inst.status === 'WAITING' ? 'bg-cyan-50 text-cyan-600 border border-cyan-200 dashed' :
                                                                        inst.status === 'PENDING' ? 'bg-yellow-50 text-yellow-600 border border-yellow-200 dashed' :
                                                                            'bg-slate-50 text-slate-600 border border-slate-200'
                                                        }`}>
                                                        {inst.status === 'RUNNING' && <RotateCw size={10} className="mr-1 animate-spin" />}
                                                        {{
                                                            'WAITING': '等待下发',
                                                            'PENDING': '依赖等待',
                                                            'RUNNING': '运行中',
                                                            'SUCCESS': '成功',
                                                            'FORCE_SUCCESS': '强制成功',
                                                            'FAIL': '失败',
                                                            'STOPPED': '已停止'
                                                        }[inst.status] || inst.status}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4 text-slate-600">{inst.retryCount}</td>
                                                <td className="px-6 py-4 text-right whitespace-nowrap">
                                                    <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                        {/* Rerun: FAIL, SUCCESS, STOPPED, FORCE_SUCCESS */}
                                                        {['FAIL', 'SUCCESS', 'STOPPED', 'FORCE_SUCCESS'].includes(inst.status) && (
                                                            <button className="p-1 text-slate-400 hover:text-blue-600" title="重跑" onClick={() => handleRerunClick(inst)}>
                                                                <RotateCw size={16} />
                                                            </button>
                                                        )}

                                                        {/* Force Success: FAIL */}
                                                        {inst.status === 'FAIL' && (
                                                            <>
                                                                <button className="p-1 text-slate-400 hover:text-green-600" title="强制通过" onClick={() => handleForceSuccess(inst)}>
                                                                    <CheckCircle size={16} />
                                                                </button>


                                                            </>
                                                        )}

                                                        {/* Stop: RUNNING, WAITING, PENDING */}
                                                        {['RUNNING', 'WAITING', 'PENDING'].includes(inst.status) && (
                                                            <button className="p-1 text-slate-400 hover:text-red-600" title="强制停止" onClick={() => handleStop(inst)}>
                                                                <StopCircle size={16} />
                                                            </button>
                                                        )}

                                                        {/* Dependencies: Always */}
                                                        <button className="p-1 text-slate-400 hover:text-purple-600" title="查看依赖 (上游)" onClick={() => handleDependencyView(inst, 'upstream')}>
                                                            <ArrowUpCircle size={16} />
                                                        </button>
                                                        <button className="p-1 text-slate-400 hover:text-orange-600" title="查看被依赖 (下游)" onClick={() => handleDependencyView(inst, 'downstream')}>
                                                            <ArrowDownCircle size={16} />
                                                        </button>

                                                        <button className="p-1 text-slate-400 hover:text-slate-600" title="查看日志" onClick={() => handleViewLog(inst)}>
                                                            <FileText size={16} />
                                                        </button>
                                                    </div>
                                                </td>
                                            </tr>
                                        )
                                    })
                                )}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            <div className="p-4 border-t border-slate-200 bg-slate-50">
                <Pagination
                    current={currentPage}
                    total={filteredInstances.length}
                    pageSize={pageSize}
                    showSizeChanger
                    onChange={(page, size) => {
                        setCurrentPage(page);
                        setPageSize(size);
                    }}
                />
            </div>

            {/* Log Console Modal */}
            {
                showLog && (
                    <div className="absolute inset-0 z-[3000] flex items-center justify-center">
                        <div className="w-[800px] h-[600px] bg-slate-900 rounded-xl shadow-2xl flex flex-col overflow-hidden animate-scale-in">
                            <div className="flex items-center justify-between px-4 py-3 border-b border-slate-800 bg-slate-900">
                                <div className="flex items-center gap-2 text-slate-300">
                                    <Terminal size={18} />
                                    <span className="font-mono text-sm font-bold">Task Log: {selectedInstance?.id}</span>
                                </div>
                                <button onClick={() => setShowLog(false)} className="text-slate-500 hover:text-white transition-colors">
                                    <X size={20} />
                                </button>
                            </div>
                            <div className="flex-1 p-4 overflow-auto font-mono text-xs text-slate-300 space-y-1 whitespace-pre-wrap">
                                {logLoading ? (
                                    <div className="flex items-center justify-center h-full text-slate-500">
                                        <RotateCw className="animate-spin mr-2" /> Loading logs...
                                    </div>
                                ) : (
                                    logContent
                                )}
                            </div>
                        </div>
                    </div>
                )
            }

            {/* Rerun Options Modal */}
            {
                rerunModalVisible && (
                    <div className="absolute inset-0 z-[3000] flex items-center justify-center animate-fade-in">
                        <div className="bg-white rounded-xl shadow-2xl w-[400px] overflow-hidden animate-scale-in border border-slate-100">
                            <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                                <h3 className="font-semibold text-slate-800 flex items-center gap-2">
                                    <RotateCw size={18} className="text-blue-600" />
                                    确认重跑
                                </h3>
                                <button onClick={() => setRerunModalVisible(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                                    <X size={20} />
                                </button>
                            </div>
                            <div className="p-6">
                                <p className="text-slate-600 mb-6 text-sm">
                                    您正在请求重跑任务：
                                    <div className="mt-2 p-3 bg-slate-50 rounded border border-slate-100 font-medium text-slate-800">
                                        {rerunTargetInstance ? (
                                            <>
                                                <div className="text-xs text-slate-500 mb-1">工作流 / 任务</div>
                                                {taskToWorkflowMap[rerunTargetInstance.taskId] || '-'} / {tasks[rerunTargetInstance.taskId]?.name || rerunTargetInstance.taskId}
                                            </>
                                        ) : (
                                            <div className="text-center py-2">
                                                已选择 <span className="text-blue-600 font-bold">{selectedRowKeys.length}</span> 个任务进行批量重跑
                                            </div>
                                        )}
                                    </div>
                                    <div className="mt-4">请选择重跑模式：</div>
                                </p>
                                <div className="flex flex-col gap-3">
                                    <button
                                        onClick={() => confirmRerun(false)}
                                        className="flex items-center justify-between p-4 rounded-lg border border-slate-200 hover:border-blue-500 hover:bg-blue-50 transition-all group text-left"
                                    >
                                        <div>
                                            <div className="font-medium text-slate-700 group-hover:text-blue-700">仅重跑当前任务</div>
                                            <div className="text-xs text-slate-500 mt-1">只重新执行该实例，不影响下游任务。</div>
                                        </div>
                                        <RotateCw size={16} className="text-slate-300 group-hover:text-blue-500" />
                                    </button>
                                    <button
                                        onClick={() => confirmRerun(true)}
                                        disabled={validationLoading || (rerunTargetInstance ? invalidDownstreamTasks.length > 0 : Object.keys(batchValidationErrors).length > 0)}
                                        title={
                                            rerunTargetInstance
                                                ? (invalidDownstreamTasks.length > 0 ? `无法重跑：以下下游任务正在运行或等待中：${invalidDownstreamTasks.join(', ')}` : '')
                                                : (Object.keys(batchValidationErrors).length > 0 ? '部分任务的下游依赖不满足条件，请查看详情' : '')
                                        }
                                        className={`flex items-center justify-between p-4 rounded-lg border transition-all group text-left ${validationLoading || (rerunTargetInstance ? invalidDownstreamTasks.length > 0 : Object.keys(batchValidationErrors).length > 0)
                                            ? 'border-slate-100 bg-slate-50 cursor-not-allowed opacity-60'
                                            : 'border-slate-200 hover:border-purple-500 hover:bg-purple-50'
                                            }`}
                                    >
                                        <div>
                                            <div className={`font-medium ${validationLoading || (rerunTargetInstance ? invalidDownstreamTasks.length > 0 : Object.keys(batchValidationErrors).length > 0) ? 'text-slate-400' : 'text-slate-700 group-hover:text-purple-700'}`}>重跑及其下游依赖</div>
                                            <div className="text-xs text-slate-500 mt-1">
                                                {validationLoading ? '正在检查依赖状态...' :
                                                    (rerunTargetInstance ? invalidDownstreamTasks.length > 0 : Object.keys(batchValidationErrors).length > 0) ?
                                                        (rerunTargetInstance ? '下游存在未完成任务，无法重跑' :
                                                            <div className="text-red-500">
                                                                以下任务无法重跑（下游未完成）：
                                                                <ul className="list-disc pl-4 mt-1 space-y-1">
                                                                    {Object.entries(batchValidationErrors).map(([instId, errors]) => {
                                                                        const inst = instances.find(i => i.id === instId);
                                                                        const taskName = inst ? (tasks[inst.taskId]?.name || inst.taskId) : instId;
                                                                        return (
                                                                            <li key={instId}>
                                                                                <span className="font-medium">{taskName}</span>: {errors.join(', ')}
                                                                            </li>
                                                                        );
                                                                    })}
                                                                </ul>
                                                            </div>
                                                        ) :
                                                        '重新执行该实例，并级联重跑所有依赖它的后续任务。'}
                                            </div>
                                        </div>
                                        <Boxes size={16} className={`${validationLoading || (rerunTargetInstance ? invalidDownstreamTasks.length > 0 : Object.keys(batchValidationErrors).length > 0) ? 'text-slate-300' : 'text-slate-300 group-hover:text-purple-500'}`} />
                                    </button>
                                </div>
                            </div>
                            <div className="px-6 py-3 bg-slate-50 border-t border-slate-100 flex justify-end">
                                <button
                                    onClick={() => setRerunModalVisible(false)}
                                    className="px-4 py-2 text-sm text-slate-600 hover:text-slate-800 font-medium transition-colors"
                                >
                                    取消
                                </button>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* Force Success Modal */}
            {
                forceSuccessModalVisible && forceSuccessTargetInstance && (
                    <div className="absolute inset-0 z-[3000] flex items-center justify-center animate-fade-in">
                        <div className="bg-white rounded-xl shadow-2xl w-[400px] overflow-hidden animate-scale-in border border-slate-100">
                            <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-green-50/50">
                                <h3 className="font-semibold text-slate-800 flex items-center gap-2">
                                    <CheckCircle size={18} className="text-green-600" />
                                    确认强制成功
                                </h3>
                                <button onClick={() => setForceSuccessModalVisible(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                                    <X size={20} />
                                </button>
                            </div>
                            <div className="p-6">
                                <div className="flex items-start gap-3 mb-4">
                                    <div className="p-2 bg-green-100 rounded-full text-green-600 shrink-0">
                                        <CheckCircle size={24} />
                                    </div>
                                    <div>
                                        <h4 className="font-medium text-slate-800 mb-1">您确定要强制标记为成功吗？</h4>
                                        <p className="text-sm text-slate-500 leading-relaxed">
                                            这将忽略该任务的实际执行结果，直接将其状态修改为 <span className="font-mono text-green-600 font-medium">SUCCESS</span>。
                                            <br />
                                            <span className="text-xs text-orange-500 mt-1 inline-block">注意：这可能会触发下游依赖任务的执行。</span>
                                        </p>
                                    </div>
                                </div>

                                <div className="bg-slate-50 rounded border border-slate-100 p-3 text-sm">
                                    <div className="flex justify-between mb-1">
                                        <span className="text-slate-500">任务名称:</span>
                                        <span className="font-mono text-slate-700 font-medium">{tasks[forceSuccessTargetInstance.taskId]?.name || '-'}</span>
                                    </div>
                                    <div className="flex justify-between mb-1">
                                        <span className="text-slate-500">任务ID:</span>
                                        <span className="font-mono text-slate-700">{forceSuccessTargetInstance.taskId}</span>
                                    </div>
                                    <div className="flex justify-between">
                                        <span className="text-slate-500">数据日期:</span>
                                        <span className="font-mono text-slate-700">{forceSuccessTargetInstance.dataDate}</span>
                                    </div>
                                </div>
                            </div>
                            <div className="px-6 py-3 bg-slate-50 border-t border-slate-100 flex justify-end gap-3">
                                <button
                                    onClick={() => setForceSuccessModalVisible(false)}
                                    className="px-4 py-2 text-sm text-slate-600 hover:text-slate-800 font-medium transition-colors"
                                >
                                    取消
                                </button>
                                <button
                                    onClick={confirmForceSuccess}
                                    className="px-4 py-2 text-sm bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium transition-colors shadow-sm shadow-green-200"
                                >
                                    确认通过
                                </button>
                            </div>
                        </div>
                    </div>
                )
            }

            <DependencyGraphModal
                visible={dependencyGraph.visible}
                onCancel={() => setDependencyGraph({ ...dependencyGraph, visible: false })}
                nodes={dependencyGraph.nodes}
                edges={dependencyGraph.edges}
                onNodeContextMenu={handleNodeContextMenu}
                showStatus={true}
            />

            {/* Context Menu */}
            {
                contextMenu.visible && contextMenu.node && (
                    <div
                        className="fixed z-[2000] bg-white rounded-lg shadow-xl border border-slate-200 py-1 min-w-[160px] animate-scale-in"
                        style={{ left: contextMenu.x, top: contextMenu.y }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <div className="px-3 py-2 border-b border-slate-100 mb-1">
                            <div className="text-xs font-bold text-slate-700 truncate max-w-[140px]">{contextMenu.node.data.label}</div>
                            <div className="text-[10px] text-slate-400 font-mono">{contextMenu.node.id}</div>
                        </div>

                        {/* View Log */}
                        <button
                            onClick={() => {
                                // Construct a temporary instance object from node data
                                // Use instanceId if available (from dependency graph), otherwise fallback to node.id (which is taskId)
                                const instanceId = contextMenu.node.data.instanceId || contextMenu.node.id;
                                const instance = {
                                    ...contextMenu.node.data,
                                    id: instanceId,
                                    taskId: contextMenu.node.id
                                } as TaskInstance;
                                handleViewLog(instance);
                                closeContextMenu();
                            }}
                            className="w-full text-left px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 hover:text-blue-600 flex items-center gap-2 transition-colors"
                        >
                            <FileText size={14} /> 查看日志
                        </button>

                        {/* Rerun */}
                        {['FAIL', 'SUCCESS', 'STOPPED', 'FORCE_SUCCESS'].includes(contextMenu.node.data.status) && (
                            <button
                                onClick={() => {
                                    const instanceId = contextMenu.node.data.instanceId || contextMenu.node.id;
                                    const instance = {
                                        ...contextMenu.node.data,
                                        id: instanceId,
                                        taskId: contextMenu.node.id
                                    } as TaskInstance;
                                    handleRerunClick(instance);
                                    closeContextMenu();
                                }}
                                className="w-full text-left px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 hover:text-blue-600 flex items-center gap-2 transition-colors"
                            >
                                <RotateCw size={14} /> 重跑任务
                            </button>
                        )}

                        {/* Stop */}
                        {['RUNNING', 'WAITING', 'PENDING'].includes(contextMenu.node.data.status) && (
                            <button
                                onClick={() => {
                                    const instanceId = contextMenu.node.data.instanceId || contextMenu.node.id;
                                    const instance = {
                                        ...contextMenu.node.data,
                                        id: instanceId,
                                        taskId: contextMenu.node.id
                                    } as TaskInstance;
                                    handleStop(instance);
                                    closeContextMenu();
                                }}
                                className="w-full text-left px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 hover:text-red-600 flex items-center gap-2 transition-colors"
                            >
                                <StopCircle size={14} /> 停止任务
                            </button>
                        )}

                        {/* Force Success */}
                        {['FAIL'].includes(contextMenu.node.data.status) && (
                            <button
                                onClick={() => {
                                    const instanceId = contextMenu.node.data.instanceId || contextMenu.node.id;
                                    const instance = {
                                        ...contextMenu.node.data,
                                        id: instanceId,
                                        taskId: contextMenu.node.id
                                    } as TaskInstance;
                                    handleForceSuccess(instance);
                                    closeContextMenu();
                                }}
                                className="w-full text-left px-3 py-2 text-sm text-slate-600 hover:bg-slate-50 hover:text-green-600 flex items-center gap-2 transition-colors"
                            >
                                <CheckCircle size={14} /> 强制成功
                            </button>
                        )}
                    </div>
                )
            }
        </div >
    );
};

export default TaskInstance;
