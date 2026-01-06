import React, { useState, useEffect, useMemo } from 'react';
import { Search, RotateCw, StopCircle, FileText, CheckCircle, X, RefreshCw, Terminal, Eye, EyeOff, Play, ArrowUpCircle, ArrowDownCircle, Boxes, ClipboardList, LayoutGrid, List, Activity, XCircle, Clock, ChevronUp, ChevronDown, Filter } from 'lucide-react';
import { message, DatePicker, Modal, Drawer, Tag, Divider, Empty, Badge } from 'antd';
import dayjs from 'dayjs';
import 'dayjs/locale/zh-cn';
import zhCN from 'antd/es/date-picker/locale/zh_CN';
dayjs.locale('zh-cn');
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
    owner: string;
    content: string;
}

// Sub-component for Detailed View
const InstanceDetailDrawer: React.FC<{
    visible: boolean;
    onClose: () => void;
    instance: TaskInstance | null;
    task?: Task;
    workflowName?: string;
    systemName?: string;
    onViewLog: (inst: TaskInstance) => void;
}> = ({ visible, onClose, instance, task, workflowName, systemName, onViewLog }) => {
    if (!instance) return null;

    const statusMap: Record<string, { color: string, label: string }> = {
        'SUCCESS': { color: '#10b981', label: '成功' },
        'FORCE_SUCCESS': { color: '#8b5cf6', label: '强制成功' },
        'RUNNING': { color: '#3b82f6', label: '运行中' },
        'FAIL': { color: '#ef4444', label: '失败' },
        'WAITING': { color: '#06b6d4', label: '等待下发' },
        'PENDING': { color: '#f59e0b', label: '依赖等待' },
        'STOPPED': { color: '#64748b', label: '已停止' }
    };

    const s = statusMap[instance.status] || { color: '#94a3b8', label: instance.status };

    return (
        <Drawer
            title={
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center text-blue-600">
                        <Activity size={20} />
                    </div>
                    <div>
                        <div className="text-base font-bold text-slate-800">{task?.name || '任务详情'}</div>
                        <div className="text-xs text-slate-400 font-mono">#{instance.id}</div>
                    </div>
                </div>
            }
            placement="right"
            onClose={onClose}
            open={visible}
            width={560}
            closeIcon={<X size={20} className="text-slate-400 hover:text-slate-600" />}
            headerStyle={{ borderBottom: '1px solid #f1f5f9', padding: '20px 24px' }}
            styles={{ body: { padding: '0' } }}
        >
            <div className="h-full flex flex-col bg-slate-50/30">
                <div className="p-6 space-y-6">
                    {/* Status Banner */}
                    <div className="bg-white rounded-2xl p-5 border border-slate-200/60 shadow-sm flex items-center justify-between">
                        <div className="flex items-center gap-4">
                            <div className="relative">
                                <div className="w-12 h-12 rounded-full flex items-center justify-center opacity-20" style={{ backgroundColor: s.color }}></div>
                                <div className="absolute inset-0 flex items-center justify-center" style={{ color: s.color }}>
                                    {instance.status === 'RUNNING' ? <RotateCw size={24} className="animate-spin" /> :
                                        instance.status === 'SUCCESS' || instance.status === 'FORCE_SUCCESS' ? <CheckCircle size={24} /> : <Activity size={24} />}
                                </div>
                            </div>
                            <div>
                                <div className="text-xs text-slate-400 font-medium uppercase tracking-wider mb-0.5">当前状态</div>
                                <div className="text-lg font-bold" style={{ color: s.color }}>{s.label}</div>
                            </div>
                        </div>
                        <button
                            onClick={() => onViewLog(instance)}
                            className="px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-xl hover:bg-blue-700 hover:shadow-lg hover:shadow-blue-00 transition-all flex items-center gap-2 group"
                        >
                            <FileText size={16} className="group-hover:scale-110 transition-transform" />
                            查看执行日志
                        </button>
                    </div>

                    {/* Info Grid */}
                    <div className="grid grid-cols-2 gap-4">
                        <div className="bg-white rounded-2xl p-4 border border-slate-200/60">
                            <div className="text-xs text-slate-400 mb-1 flex items-center gap-1.5">
                                <Clock size={12} /> 数据日期
                            </div>
                            <div className="text-sm font-semibold text-slate-700">{instance.dataDate}</div>
                        </div>
                        <div className="bg-white rounded-2xl p-4 border border-slate-200/60">
                            <div className="text-xs text-slate-400 mb-1 flex items-center gap-1.5">
                                <Terminal size={12} /> 任务类型
                            </div>
                            <div className="text-sm font-semibold text-slate-700">{instance.taskType}</div>
                        </div>
                        <div className="bg-white rounded-2xl p-4 border border-slate-200/60">
                            <div className="text-xs text-slate-400 mb-1 flex items-center gap-1.5">
                                <Boxes size={12} /> 所属系统
                            </div>
                            <div className="text-sm font-semibold text-slate-700">{systemName || '-'}</div>
                        </div>
                        <div className="bg-white rounded-2xl p-4 border border-slate-200/60">
                            <div className="text-xs text-slate-400 mb-1 flex items-center gap-1.5">
                                <LayoutGrid size={12} /> 关联工作流
                            </div>
                            <div className="text-sm font-semibold text-slate-700 truncate">{workflowName || '-'}</div>
                        </div>
                    </div>

                    {/* Timeline / Times */}
                    <div className="bg-white rounded-2xl overflow-hidden border border-slate-200/60 shadow-sm">
                        <div className="px-5 py-3 border-b border-slate-100 bg-slate-50/50 text-xs font-bold text-slate-500 uppercase tracking-tight flex items-center gap-2">
                            <Clock size={14} /> 时间线记录
                        </div>
                        <div className="p-5 space-y-4">
                            <div className="flex justify-between items-center">
                                <span className="text-sm text-slate-500">创建时间</span>
                                <span className="text-sm font-mono text-slate-700">{instance.createTime ? dayjs(instance.createTime).format('YYYY-MM-DD HH:mm:ss') : '-'}</span>
                            </div>
                            <div className="flex justify-between items-center">
                                <span className="text-sm text-slate-500">开始时间</span>
                                <span className="text-sm font-mono text-slate-700">{instance.startTime ? dayjs(instance.startTime).format('YYYY-MM-DD HH:mm:ss') : '-'}</span>
                            </div>
                            <div className="flex justify-between items-center">
                                <span className="text-sm text-slate-500">结束时间</span>
                                <span className="text-sm font-mono text-slate-700">{instance.endTime ? dayjs(instance.endTime).format('YYYY-MM-DD HH:mm:ss') : '-'}</span>
                            </div>
                            <Divider className="my-2" />
                            <div className="flex justify-between items-center">
                                <span className="text-sm text-slate-500">重试次数</span>
                                <Badge count={instance.retryCount} overflowCount={99} style={{ backgroundColor: instance.retryCount > 0 ? '#ef4444' : '#94a3b8' }} />
                            </div>
                        </div>
                    </div>

                    {/* Task Content Preview */}
                    {task?.content && (
                        <div className="bg-white rounded-2xl p-5 border border-slate-200/80 overflow-hidden shadow-sm">
                            <div className="text-xs text-slate-400 font-bold mb-3 flex items-center justify-between">
                                <span className="flex items-center gap-2"><Terminal size={14} className="text-blue-500" /> 任务内容定义</span>
                                <span className="px-2 py-0.5 bg-slate-50 text-slate-400 rounded text-[10px] border border-slate-100 uppercase tracking-widest">json</span>
                            </div>
                            <pre className="text-[12px] text-slate-600 font-mono overflow-auto max-h-[200px] scrollbar-hide p-4 bg-slate-50/50 rounded-xl border border-slate-100/50">
                                {JSON.stringify(JSON.parse(task.content), null, 2)}
                            </pre>
                        </div>
                    )}
                </div>
            </div>
        </Drawer>
    );
};

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

    // Detail Drawer State
    const [isDetailOpen, setIsDetailOpen] = useState(false);
    const [detailInstance, setDetailInstance] = useState<TaskInstance | null>(null);

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
            <div className="px-6 py-3 bg-white/90 backdrop-blur-xl border-b border-slate-200/50 flex flex-nowrap gap-3 justify-between items-center sticky top-0 z-20 overflow-x-auto no-scrollbar">
                <div className="flex items-center gap-3">
                    <div className="relative group flex-shrink-0">
                        <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-blue-500 transition-colors" />
                        <input
                            type="text"
                            placeholder="搜索任务..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            onKeyDown={handleSearch}
                            className="pl-10 pr-4 py-2 text-xs border border-slate-200/80 rounded-xl focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-400 w-44 bg-slate-50/50 transition-all font-medium"
                        />
                    </div>

                    <div className="flex items-center gap-1 bg-slate-100/50 p-1 rounded-xl border border-slate-200/60 flex-shrink-0">
                        <select
                            value={workflowFilter}
                            onChange={(e) => setWorkflowFilter(e.target.value)}
                            className="bg-transparent pl-3 pr-1 py-1 text-xs text-slate-600 focus:outline-none font-bold max-w-[100px] cursor-pointer"
                        >
                            <option value="">所有工作流</option>
                            {workflows.map(w => (
                                <option key={w.id} value={w.id}>{w.name}</option>
                            ))}
                        </select>
                        <div className="w-[1px] h-3 bg-slate-300/50" />
                        <select
                            value={systemFilter}
                            onChange={(e) => setSystemFilter(e.target.value)}
                            className="bg-transparent px-2 py-1 text-xs text-slate-600 focus:outline-none font-bold max-w-[100px] cursor-pointer"
                        >
                            <option value="">所有系统</option>
                            {systems.map(s => (
                                <option key={s.id} value={s.id}>{s.name}</option>
                            ))}
                        </select>
                        <div className="w-[1px] h-3 bg-slate-300/50" />
                        <select
                            value={statusFilter}
                            onChange={(e) => setStatusFilter(e.target.value)}
                            className="bg-transparent pl-1 pr-3 py-1 text-xs text-slate-600 focus:outline-none font-bold max-w-[90px] cursor-pointer"
                        >
                            <option value="">所有状态</option>
                            <option value="SUCCESS">成功</option>
                            <option value="FAIL">失败</option>
                            <option value="RUNNING">运行中</option>
                            <option value="WAITING">等待下发</option>
                            <option value="PENDING">依赖等待</option>
                            <option value="STOPPED">已停止</option>
                        </select>
                    </div>

                    <div className="flex items-center gap-1 flex-shrink-0">
                        <DatePicker
                            placeholder="数据日期"
                            size="small"
                            locale={zhCN}
                            onChange={(date, dateString) => setDataDateFilter(typeof dateString === 'string' ? dateString : '')}
                            style={{ borderRadius: '10px', height: '36px', width: '130px', fontSize: '12px' }}
                        />
                        <DatePicker
                            placeholder="执行日期"
                            size="small"
                            locale={zhCN}
                            value={executionDateFilter ? dayjs(executionDateFilter) : null}
                            onChange={(date, dateString) => setExecutionDateFilter(typeof dateString === 'string' ? dateString : '')}
                            style={{ borderRadius: '10px', height: '36px', width: '130px', fontSize: '12px' }}
                            allowClear
                        />
                    </div>
                </div>

                <div className="flex items-center gap-2 flex-shrink-0">
                    <div className="flex items-center bg-slate-100/80 rounded-xl p-0.5 border border-slate-200/50">
                        <button
                            onClick={() => setListViewMode('list')}
                            className={`p-1.5 rounded-lg transition-all ${listViewMode === 'list' ? 'bg-white shadow-sm text-blue-600' : 'text-slate-400 hover:text-slate-600'}`}
                            title="列表视图"
                        >
                            <List size={16} strokeWidth={2.5} />
                        </button>
                        <button
                            onClick={() => setListViewMode('card')}
                            className={`p-1.5 rounded-lg transition-all ${listViewMode === 'card' ? 'bg-white shadow-sm text-blue-600' : 'text-slate-400 hover:text-slate-600'}`}
                            title="卡片视图"
                        >
                            <LayoutGrid size={16} strokeWidth={2.5} />
                        </button>
                    </div>

                    <div className="flex items-center gap-1 p-1 bg-slate-100/50 rounded-xl">
                        <button
                            onClick={() => setShowIds(!showIds)}
                            className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all ${showIds ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}
                        >
                            ID 展示
                        </button>
                        <button
                            onClick={handleBatchRerunClick}
                            disabled={selectedRowKeys.length === 0}
                            className={`px-3 py-1.5 text-xs font-bold rounded-lg transition-all ${selectedRowKeys.length > 0 ? 'bg-blue-600 text-white shadow-md shadow-blue-200' : 'bg-slate-200 text-slate-400 pointer-events-none'}`}
                        >
                            批量重跑
                        </button>
                    </div>

                    <button
                        onClick={fetchInstances}
                        className="p-2 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-all"
                        title="刷新数据"
                    >
                        <RefreshCw size={16} strokeWidth={2.5} className={loading ? 'animate-spin' : ''} />
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
                                onShowDetail={(inst) => {
                                    setDetailInstance(inst);
                                    setIsDetailOpen(true);
                                }}
                            />
                        ))}
                    </div>
                ) : (
                    /* Table List View */
                    <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
                        <table className="w-full text-sm text-left table-fixed">
                            <thead className="text-xs text-slate-500 uppercase bg-slate-50 border-b border-slate-100 sticky top-0 z-10">
                                <tr>
                                    <th className="px-4 py-3 font-medium w-10">
                                        <input
                                            type="checkbox"
                                            onChange={handleSelectAll}
                                            checked={paginatedInstances.length > 0 && paginatedInstances.filter(isSelectable).length > 0 && paginatedInstances.filter(isSelectable).every(inst => selectedRowKeys.includes(inst.id))}
                                            className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                                        />
                                    </th>
                                    {showIds && <th className="px-4 py-3 font-medium w-20">实例ID</th>}
                                    <th className="px-4 py-3 font-medium w-40">来源 / 系统</th>
                                    <th className="px-4 py-3 font-medium w-64">任务名称</th>
                                    {showIds && <th className="px-4 py-3 font-medium w-20">任务ID</th>}
                                    <th className="px-4 py-3 font-medium w-24">数据日期</th>
                                    <th className="px-4 py-3 font-medium w-44">执行时间线</th>
                                    <th className="px-4 py-3 font-medium w-20 text-center">状态</th>
                                    <th className="px-4 py-3 font-medium w-16 text-center">重试</th>
                                    <th className="px-4 py-3 font-medium w-24 text-right pr-6">操作</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {loading ? (
                                    <tr>
                                        <td colSpan={showIds ? 14 : 12} className="px-6 py-8 text-center text-slate-500">
                                            加载中...
                                        </td>
                                    </tr>
                                ) : filteredInstances.length === 0 ? (
                                    <tr>
                                        <td colSpan={showIds ? 14 : 12} className="px-6 py-8 text-center text-slate-500">
                                            暂无数据
                                        </td>
                                    </tr>
                                ) : (
                                    paginatedInstances.map((inst) => {
                                        const wfName = taskToWorkflowMap[inst.taskId] || '-';
                                        const systemName = systems.find(s => String(s.id) === String(inst.systemId))?.name || '-';

                                        return (
                                            <tr
                                                key={inst.id}
                                                className="hover:bg-blue-50/40 transition-all cursor-pointer group active:bg-blue-50/60 border-b border-slate-50 last:border-0"
                                                onClick={() => {
                                                    setDetailInstance(inst);
                                                    setIsDetailOpen(true);
                                                }}
                                            >
                                                <td className="px-4 py-3" onClick={(e) => e.stopPropagation()}>
                                                    <input
                                                        type="checkbox"
                                                        checked={selectedRowKeys.includes(inst.id)}
                                                        onChange={() => handleRowSelect(inst.id)}
                                                        disabled={!isSelectable(inst)}
                                                        className="rounded border-slate-300 text-blue-600 focus:ring-blue-500 disabled:opacity-50 w-4 h-4"
                                                    />
                                                </td>
                                                {showIds && <td className="px-4 py-3 font-mono text-slate-500 text-[10px] truncate" title={inst.id}>{inst.id}</td>}
                                                <td className="px-4 py-3">
                                                    <div className="flex flex-col gap-0.5 overflow-hidden">
                                                        <span className="text-xs font-semibold text-slate-700 truncate" title={wfName}>{wfName}</span>
                                                        <span className="text-[10px] text-slate-400 truncate" title={systemName}>{systemName}</span>
                                                    </div>
                                                </td>
                                                <td className="px-4 py-3">
                                                    <div className="flex items-center gap-1.5 overflow-hidden">
                                                        <Tag className="flex-shrink-0 text-[10px] px-1 py-0 leading-tight bg-slate-100 text-slate-500 border-none">{inst.taskType}</Tag>
                                                        <span className="font-medium text-slate-700 truncate text-xs" title={tasks[inst.taskId]?.name || inst.taskId}>
                                                            {tasks[inst.taskId]?.name || inst.taskId}
                                                        </span>
                                                    </div>
                                                </td>
                                                {showIds && <td className="px-4 py-3 font-mono text-slate-500 text-[10px] truncate" title={inst.taskId}>{inst.taskId}</td>}
                                                <td className="px-4 py-3 font-mono text-slate-500 text-[10px]">{inst.dataDate}</td>
                                                <td className="px-4 py-3">
                                                    <div className="flex flex-col gap-0.5 text-[10px] text-slate-500 font-mono">
                                                        <div className="flex items-center gap-2">
                                                            <span className="px-1 bg-slate-50 text-slate-400 rounded text-[8px] scale-90">CREATE</span>
                                                            <span>{inst.createTime ? dayjs(inst.createTime).format('MM-DD HH:mm:ss') : '-'}</span>
                                                        </div>
                                                        <div className="flex items-center gap-2">
                                                            <span className="px-1 bg-blue-50 text-blue-400 rounded text-[8px] scale-90">START</span>
                                                            <span>{inst.startTime ? dayjs(inst.startTime).format('MM-DD HH:mm:ss') : '-'}</span>
                                                        </div>
                                                        <div className="flex items-center gap-2">
                                                            <span className="px-1 bg-slate-100 text-slate-400 rounded text-[8px] scale-90">END</span>
                                                            <span>{inst.endTime ? dayjs(inst.endTime).format('MM-DD HH:mm:ss') : '-'}</span>
                                                        </div>
                                                    </div>
                                                </td>
                                                <td className="px-4 py-3 text-center">
                                                    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold border ${inst.status === 'SUCCESS' ? 'bg-emerald-50 text-emerald-600 border-emerald-200' :
                                                        inst.status === 'RUNNING' ? 'bg-blue-50 text-blue-600 border-blue-200' :
                                                            inst.status === 'FAIL' ? 'bg-red-50 text-red-600 border-red-200 transition-all group-hover:bg-red-600 group-hover:text-white' :
                                                                inst.status === 'STOPPED' ? 'bg-slate-100 text-slate-600 border-slate-200' :
                                                                    'bg-amber-50 text-amber-600 border-amber-200'}`}>
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
                                                <td className="px-4 py-3 text-center">
                                                    <Badge count={inst.retryCount} size="small" style={{ backgroundColor: inst.retryCount > 0 ? '#ef4444' : '#e2e8f0', color: inst.retryCount > 0 ? '#fff' : '#64748b', fontSize: '10px' }} />
                                                </td>
                                                <td className="px-4 py-3 text-right pr-6" onClick={(e) => e.stopPropagation()}>
                                                    <div className="flex justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                        <button onClick={() => handleViewLog(inst)} className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="查看日志">
                                                            <FileText size={14} />
                                                        </button>
                                                        {['FAIL', 'SUCCESS', 'STOPPED', 'FORCE_SUCCESS'].includes(inst.status) && (
                                                            <button onClick={() => handleRerunClick(inst)} className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors" title="重跑">
                                                                <RotateCw size={14} />
                                                            </button>
                                                        )}
                                                        {inst.status === 'FAIL' && (
                                                            <button onClick={() => handleForceSuccess(inst)} className="p-1.5 text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="置为成功">
                                                                <CheckCircle size={14} />
                                                            </button>
                                                        )}
                                                        {['RUNNING', 'WAITING', 'PENDING'].includes(inst.status) && (
                                                            <button onClick={() => handleStop(inst)} className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" title="停止">
                                                                <StopCircle size={14} />
                                                            </button>
                                                        )}
                                                    </div>
                                                </td>
                                            </tr>
                                        );
                                    })
                                )}
                            </tbody>
                        </table>
                    </div>
                )}
                {listViewMode === 'list' && filteredInstances.length > 0 && (
                    <div className="mt-4 px-2">
                        <Pagination
                            total={filteredInstances.length}
                            current={currentPage}
                            pageSize={pageSize}
                            onChange={(page, size) => {
                                setCurrentPage(page);
                                setPageSize(size);
                            }}
                            showSizeChanger={true}
                        />
                    </div>
                )}
            </div>



            {/* Detail Drawer */}
            <InstanceDetailDrawer
                visible={isDetailOpen}
                onClose={() => setIsDetailOpen(false)}
                instance={detailInstance}
                task={detailInstance ? tasks[detailInstance.taskId] : undefined}
                systemName={detailInstance ? systems.find(s => String(s.id) === String(detailInstance.systemId))?.name : undefined}
                workflowName={detailInstance ? taskToWorkflowMap[detailInstance.taskId] : undefined}
                onViewLog={handleViewLog}
            />

            {/* Log Console Modal */}
            {
                showLog && (
                    <div className="absolute inset-0 z-[3000] flex items-center justify-center bg-slate-200/20 backdrop-blur-sm">
                        <div className="w-[850px] h-[650px] bg-white rounded-3xl shadow-2xl border border-slate-200/60 flex flex-col overflow-hidden animate-scale-in">
                            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50/50">
                                <div className="flex items-center gap-3 text-slate-700">
                                    <div className="p-2 bg-blue-50 rounded-lg text-blue-600">
                                        <Terminal size={18} />
                                    </div>
                                    <div>
                                        <div className="font-bold text-sm">任务执行日志</div>
                                        <div className="text-[10px] text-slate-400 font-mono tracking-tighter">INSTANCE ID: {selectedInstance?.id}</div>
                                    </div>
                                </div>
                                <button onClick={() => setShowLog(false)} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 text-slate-400 hover:text-slate-600 transition-all">
                                    <X size={20} />
                                </button>
                            </div>
                            <div className="flex-1 p-6 overflow-auto font-mono text-[12px] text-slate-600 space-y-1 whitespace-pre-wrap bg-slate-50/30">
                                {logLoading ? (
                                    <div className="flex flex-col items-center justify-center h-full text-slate-400 gap-3">
                                        <RotateCw className="animate-spin" size={24} />
                                        <span className="text-sm font-medium">正在获取运行日志...</span>
                                    </div>
                                ) : (
                                    <LogViewer content={logContent} />
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

// Internal Log Viewer Component
const LogViewer: React.FC<{ content: string }> = ({ content }) => {
    const scrollRef = React.useRef<HTMLDivElement>(null);

    // Auto-scroll to bottom
    React.useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [content]);

    // Parse Logs into Sessions
    const { sessions } = React.useMemo(() => {
        if (!content) return { sessions: [] };

        const lines = content.split('\n');
        const parsedSessions: { title: string, lines: string[], status?: 'SUCCESS' | 'FAIL' | 'RUNNING' }[] = [];
        let currentSession: { title: string, lines: string[], status?: 'SUCCESS' | 'FAIL' | 'RUNNING' } | null = null;
        let buffer: string[] = [];

        lines.forEach(line => {
            // Detect Start of a new session
            if (line.includes('Executing task instance:')) {
                // Save previous buffer to previous session
                if (currentSession) {
                    currentSession.lines = [...currentSession.lines, ...buffer];
                    parsedSessions.push(currentSession);
                } else if (buffer.length > 0) {
                    // Logs occurring before the first explicit start
                    parsedSessions.push({ title: 'System Init / Context', lines: [...buffer], status: 'RUNNING' });
                }

                // Start new session
                currentSession = {
                    title: line,
                    lines: [],
                    status: 'RUNNING' // Default
                };
                buffer = [];
            } else if (line.includes('completed successfully')) {
                if (currentSession) currentSession.status = 'SUCCESS';
                buffer.push(line);
            } else if (line.includes('failed')) {
                if (currentSession) currentSession.status = 'FAIL';
                buffer.push(line);
            } else {
                buffer.push(line);
            }
        });

        // Push final session
        if (currentSession) {
            currentSession.lines = [...currentSession.lines, ...buffer];
            parsedSessions.push(currentSession);
        } else if (buffer.length > 0) {
            parsedSessions.push({ title: 'System Log', lines: buffer });
        }

        return { sessions: parsedSessions };
    }, [content]);

    return (
        <div className="h-full bg-[#1e1e1e] text-slate-300 font-mono text-[12px] p-4 overflow-auto scrollbar-thin scrollbar-thumb-slate-700 scrollbar-track-transparent" ref={scrollRef}>
            {sessions.length === 0 && <div className="text-slate-500 italic">Console is ready. Waiting for logs...</div>}

            {sessions.map((session, sIdx) => (
                <div key={sIdx} className="mb-6 last:mb-0 animate-in fade-in slide-in-from-bottom-2 duration-500">
                    {/* Session Header */}
                    <div className={`flex items-center gap-2 px-3 py-2 rounded-lg mb-2 border-l-4 ${session.status === 'SUCCESS' ? 'bg-emerald-500/10 border-emerald-500 text-emerald-400' :
                        session.status === 'FAIL' ? 'bg-red-500/10 border-red-500 text-red-400' :
                            'bg-blue-500/10 border-blue-500 text-blue-400'
                        }`}>
                        <div className="font-bold flex-1 truncate">{session.title.replace(/.*Executing task instance: \d+/, 'Start Execution')}</div>
                        <div className="text-[10px] opacity-70 uppercase tracking-wider">{session.status || 'INFO'}</div>
                    </div>

                    {/* Log Lines */}
                    <div className="space-y-0.5 pl-2">
                        {session.lines.map((line, lIdx) => {
                            // Simple Highlighting
                            const isError = line.toLowerCase().includes('error') || line.toLowerCase().includes('exception') || line.toLowerCase().includes('fail');
                            const isWarn = line.toLowerCase().includes('warn');

                            // Extract Timestamp if present (Simple ISO-like check or HH:mm:ss)
                            const timeMatch = line.match(/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:\d{2})/) || line.match(/(\d{2}:\d{2}:\d{2}\.\d{3})/);
                            const timestamp = timeMatch ? timeMatch[0] : '';
                            const rest = timestamp ? line.replace(timestamp, '') : line;

                            return (
                                <div key={lIdx} className={`flex items-start gap-3 hover:bg-white/5 px-2 rounded ${isError ? 'text-red-400' : isWarn ? 'text-amber-400' : ''}`}>
                                    {timestamp && <span className="text-slate-500 shrink-0 select-none w-[150px] text-[10px] pt-0.5 font-mono opacity-60">{dayjs(timestamp).format('HH:mm:ss.SSS')}</span>}
                                    <div className="break-all whitespace-pre-wrap flex-1 leading-relaxed opacity-90">
                                        {rest}
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            ))}

            {/* End of Log Marker */}
            <div className="mt-8 flex items-center gap-2 text-slate-600 justify-center text-[10px] opacity-50">
                <div className="w-16 h-[1px] bg-slate-700"></div>
                <span>END OF LOG</span>
                <div className="w-16 h-[1px] bg-slate-700"></div>
            </div>
        </div>
    );
};

export default TaskInstance;
