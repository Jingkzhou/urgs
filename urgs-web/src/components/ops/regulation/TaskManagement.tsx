import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { DatePicker, Form, Modal, message } from 'antd';
import dayjs from 'dayjs';
import zhCN from 'antd/es/date-picker/locale/zh_CN';
import { RefreshCw, Search, Plus, Clock3, SlidersHorizontal, Sparkles } from 'lucide-react';
import { motion } from 'framer-motion';
import { QuartzTask } from './mockData';
import TaskEditorModal from './TaskEditorModal';
import TaskListTable from './TaskListTable';
import TaskDetailDrawer from './TaskDetailDrawer';
import Pagination from '@/components/common/Pagination';
import {
    deleteQuartzTask,
    getDatasourceConfig,
    pauseQuartzTask,
    queryQuartzTaskDependencies,
    queryQuartzTasks,
    resumeQuartzTask,
    saveOrUpdateQuartzTask,
    triggerNowQuartzTask,
} from '@/api/ops';
import { getSsoList, SsoConfig } from '@/api/version';
import {
    DataSourceOption,
    NotificationContact,
    TaskFormValues,
    describeCron,
    describeDataSourceConnection,
    editorLanguageMap,
    emptyToNull,
    getInitialFormValues,
    normalizeQuartzTask,
    normalizeScript,
    serializeNotificationContacts,
    supportedTaskTypes,
    toTaskTypeCode,
} from './taskManagementUtils';

interface TaskManagementProps {
    onViewExecutionLog?: (task: QuartzTask) => void;
}

const TaskManagement: React.FC<TaskManagementProps> = ({ onViewExecutionLog }) => {
    const [taskList, setTaskList] = useState<QuartzTask[]>([]);
    const [dependencyCandidateTaskList, setDependencyCandidateTaskList] = useState<QuartzTask[]>([]);
    const [taskTotal, setTaskTotal] = useState(0);
    const [taskStatusSummary, setTaskStatusSummary] = useState({ normal: 0, paused: 0 });
    const [form] = Form.useForm<TaskFormValues>();
    const [keyword, setKeyword] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [typeFilter, setTypeFilter] = useState<string>('');
    const [systemFilter, setSystemFilter] = useState<string>('');
    const [themeFilter, setThemeFilter] = useState<string>('');
    const [remarkFilter, setRemarkFilter] = useState<string>('');
    const [selectedTask, setSelectedTask] = useState<QuartzTask | null>(null);
    const [selectedTaskDetailTab, setSelectedTaskDetailTab] = useState<'config' | 'dependency'>('config');
    const [selectedTaskDataDependencies, setSelectedTaskDataDependencies] = useState<QuartzTask[]>([]);
    const [selectedTaskControlDependencies, setSelectedTaskControlDependencies] = useState<QuartzTask[]>([]);
    const [detailScriptEditorReady, setDetailScriptEditorReady] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingTask, setEditingTask] = useState<QuartzTask | null>(null);
    const [startTaskModalVisible, setStartTaskModalVisible] = useState(false);
    const [pendingStartTask, setPendingStartTask] = useState<QuartzTask | null>(null);
    const [startDataDate, setStartDataDate] = useState(dayjs().format('YYYY-MM-DD'));
    const [startTaskLoading, setStartTaskLoading] = useState(false);
    const [dataSources, setDataSources] = useState<DataSourceOption[]>([]);
    const [dataSourceLoading, setDataSourceLoading] = useState(false);
    const [regulationSystems, setRegulationSystems] = useState<SsoConfig[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [refreshing, setRefreshing] = useState(false);
    const mountedRef = useRef(true);

    useEffect(() => {
        mountedRef.current = true;
        return () => { mountedRef.current = false; };
    }, []);

    const taskTypes = useMemo(() => [...supportedTaskTypes], []);

    const systems = useMemo(() => {
        const systemNames = new Set<string>();
        regulationSystems.forEach(system => {
            if (system.name?.trim()) systemNames.add(system.name.trim());
        });
        dependencyCandidateTaskList.forEach(task => {
            if (task.task_system?.trim()) systemNames.add(task.task_system.trim());
        });
        taskList.forEach(task => {
            if (task.task_system?.trim()) systemNames.add(task.task_system.trim());
        });
        if (editingTask?.task_system?.trim()) systemNames.add(editingTask.task_system.trim());
        return Array.from(systemNames);
    }, [dependencyCandidateTaskList, editingTask?.task_system, regulationSystems, taskList]);

    useEffect(() => {
        let mounted = true;

        const fetchRegulationSystems = async () => {
            try {
                const list = await getSsoList();
                if (!mounted) return;
                setRegulationSystems(Array.isArray(list) ? list : []);
            } catch (error) {
                if (!mounted) return;
                console.error('Failed to fetch regulation systems:', error);
                message.error('加载监管系统列表失败');
            }
        };

        const fetchDataSources = async () => {
            setDataSourceLoading(true);
            try {
                const list = await getDatasourceConfig();
                if (!mounted) return;
                const normalized = Array.isArray(list) ? list.map((item: any) => ({
                    id: Number(item.id),
                    name: item.name,
                    typeName: item.typeName,
                    typeCode: item.typeCode,
                    category: item.category,
                    status: item.status,
                    connectionInfo: describeDataSourceConnection(item.connectionParams, item.typeCode),
                })).filter((item: DataSourceOption) => Number.isFinite(item.id) && !!item.name) : [];
                setDataSources(normalized);
            } catch (error) {
                if (!mounted) return;
                console.error('Failed to fetch data sources:', error);
                message.error('加载系统管理数据源失败');
            } finally {
                if (mounted) setDataSourceLoading(false);
            }
        };

        fetchRegulationSystems();
        fetchDataSources();
        return () => { mounted = false; };
    }, []);

    const buildTaskQueryParams = useCallback((pageNum: number, size: number) => {
        const normalizedKeyword = emptyToNull(keyword);
        const keywordTaskId = normalizedKeyword && /^\d+$/.test(normalizedKeyword) ? Number(normalizedKeyword) : undefined;

        return {
            pageNum,
            pageSize: size,
            id: keywordTaskId,
            taskName: keywordTaskId === undefined ? normalizedKeyword || undefined : undefined,
            taskStatus: statusFilter === '' ? undefined : Number(statusFilter),
            taskType: typeFilter ? toTaskTypeCode(typeFilter) : undefined,
            taskSystem: systemFilter || undefined,
            theme: themeFilter || undefined,
            remark: emptyToNull(remarkFilter) || undefined,
        };
    }, [keyword, remarkFilter, statusFilter, systemFilter, themeFilter, typeFilter]);

    const loadTasks = useCallback(async (pageNum = currentPage, size = pageSize) => {
        try {
            const response = await queryQuartzTasks(buildTaskQueryParams(pageNum, size));
            if (!mountedRef.current) return;
            if (!response?.success) throw new Error(response?.msg || '任务查询失败');
            const list = (response.data?.list || []).map(normalizeQuartzTask);
            setTaskList(list);
            setTaskTotal(Number(response.data?.total || 0));
        } catch (error: any) {
            if (mountedRef.current) message.error(error?.message || '加载任务失败');
        }
    }, [buildTaskQueryParams, currentPage, pageSize]);

    const loadDependencyCandidateTasks = useCallback(async () => {
        let lastError: Error | null = null;
        const candidatePageSize = 500;

        try {
            const firstResponse = await queryQuartzTasks({ pageNum: 1, pageSize: candidatePageSize });
            if (!mountedRef.current) return;
            if (!firstResponse?.success) {
                lastError = new Error(firstResponse?.msg || '依赖候选任务查询失败');
                return;
            }

            const allTasks = [...(firstResponse.data?.list || []).map(normalizeQuartzTask)];
            const totalPages = Number(firstResponse.data?.pages || 1);

            if (totalPages > 1) {
                const restResponses = await Promise.all(
                    Array.from({ length: totalPages - 1 }, (_, index) =>
                        queryQuartzTasks({ pageNum: index + 2, pageSize: candidatePageSize })
                    )
                );

                restResponses.forEach(response => {
                    if (response?.success) {
                        allTasks.push(...(response.data?.list || []).map(normalizeQuartzTask));
                    } else if (!lastError) {
                        lastError = new Error(response?.msg || '依赖候选任务查询失败');
                    }
                });
            }

            if (!mountedRef.current) return;
            setDependencyCandidateTaskList(allTasks);
        } catch (err: any) {
            lastError = err;
        } finally {
            if (mountedRef.current && lastError) {
                message.warning('依赖候选任务加载不完整，部分功能可能受限');
            }
        }
    }, []);

    const loadTaskStatusSummary = useCallback(async () => {
        try {
            const summaryPageSize = 500;
            // 统计面板应展示全局数据，不受当前筛选条件影响
            const unfilteredParams = { pageNum: 1, pageSize: summaryPageSize };
            const firstResponse = await queryQuartzTasks(unfilteredParams);
            if (!mountedRef.current) return;
            if (!firstResponse?.success) throw new Error(firstResponse?.msg || '任务统计查询失败');

            const allTasks = [...(firstResponse.data?.list || []).map(normalizeQuartzTask)];
            const totalPages = Number(firstResponse.data?.pages || 1);

            if (totalPages > 1) {
                const restResponses = await Promise.all(
                    Array.from({ length: totalPages - 1 }, (_, index) =>
                        queryQuartzTasks({ pageNum: index + 2, pageSize: summaryPageSize })
                    )
                );

                restResponses.forEach(response => {
                    if (response?.success) {
                        allTasks.push(...(response.data?.list || []).map(normalizeQuartzTask));
                    }
                });
            }

            if (!mountedRef.current) return;
            setTaskStatusSummary({
                normal: allTasks.filter(task => task.task_status === 0).length,
                paused: allTasks.filter(task => task.task_status === 1).length,
            });
        } catch (error: any) {
            if (mountedRef.current) {
                message.error(error?.message || '加载任务统计失败');
                setTaskStatusSummary({ normal: 0, paused: 0 });
            }
        }
    }, []);

    useEffect(() => {
        loadTasks(currentPage, pageSize);
    }, [currentPage, loadTasks, pageSize]);

    useEffect(() => {
        loadDependencyCandidateTasks();
    }, [loadDependencyCandidateTasks]);

    useEffect(() => {
        loadTaskStatusSummary();
    }, [loadTaskStatusSummary]);

    useEffect(() => {
        setCurrentPage(1);
    }, [keyword, remarkFilter, statusFilter, systemFilter, themeFilter, typeFilter]);

    useEffect(() => {
        setSelectedTaskDetailTab('config');
        setSelectedTaskDataDependencies([]);
        setSelectedTaskControlDependencies([]);
        setDetailScriptEditorReady(false);
        if (!selectedTask?.id) return;

        let mounted = true;
        const timer = window.setTimeout(() => {
            if (mounted) setDetailScriptEditorReady(true);
        }, 80);

        const loadSelectedTaskDependencies = async () => {
            try {
                const [dataResponse, controlResponse] = await Promise.all([
                    queryQuartzTaskDependencies(selectedTask.id, 'DATA'),
                    queryQuartzTaskDependencies(selectedTask.id, 'CONTROL'),
                ]);
                if (!mounted) return;
                setSelectedTaskDataDependencies(dataResponse?.success ? (dataResponse.data || []).map(normalizeQuartzTask) : []);
                setSelectedTaskControlDependencies(controlResponse?.success ? (controlResponse.data || []).map(normalizeQuartzTask) : []);
            } catch {
                if (mounted) {
                    setSelectedTaskDataDependencies([]);
                    setSelectedTaskControlDependencies([]);
                }
            }
        };

        loadSelectedTaskDependencies();
        return () => { mounted = false; window.clearTimeout(timer); };
    }, [selectedTask?.id]);

    const fallbackDataSources = useMemo(() => {
        return taskList.reduce<DataSourceOption[]>((acc, task) => {
            if (!task.datasource_name) return acc;
            const nextId = task.datasource_id ?? -(acc.length + 1);
            if (acc.some(item => item.id === nextId || item.name === task.datasource_name)) return acc;
            acc.push({ id: nextId, name: task.datasource_name, connectionInfo: '连接信息由数据源配置动态加载' });
            return acc;
        }, []);
    }, [taskList]);

    const datasourceOptions = useMemo(() => {
        return dataSources.length > 0 ? dataSources : fallbackDataSources;
    }, [dataSources, fallbackDataSources]);

    const selectedTaskDependencySummary = useMemo(() => {
        const dataCount = selectedTaskDataDependencies.length;
        const controlCount = selectedTaskControlDependencies.length;
        if (dataCount === 0 && controlCount === 0) return '无前置依赖';
        return `数据依赖 ${dataCount} 项，控制依赖 ${controlCount} 项`;
    }, [selectedTaskControlDependencies.length, selectedTaskDataDependencies.length]);

    // ===== 事件处理 =====

    const handleRefreshTasks = async () => {
        if (refreshing) return;
        setRefreshing(true);
        try {
            await Promise.all([
                loadTasks(currentPage, pageSize),
                loadDependencyCandidateTasks(),
                loadTaskStatusSummary(),
            ]);
            message.success('任务列表及统计数据已刷新');
        } finally {
            setRefreshing(false);
        }
    };

    const openTaskModal = (task?: QuartzTask | null) => {
        setEditingTask(task || null);
        form.resetFields();
        form.setFieldsValue(getInitialFormValues(task));
        setModalVisible(true);
    };

    const closeTaskModal = () => {
        setModalVisible(false);
        setEditingTask(null);
        form.resetFields();
    };

    const handleSaveTask = async () => {
        try {
            const validatedValues = await form.validateFields();
            const values = {
                ...getInitialFormValues(editingTask),
                ...form.getFieldsValue(true),
                ...validatedValues,
            };
            const taskName = typeof values.task_name === 'string' ? values.task_name.trim() : '';
            const taskCron = typeof values.task_cron === 'string' ? values.task_cron.trim() : '';

            if (!taskName) {
                message.error('请填写任务名称');
                return;
            }
            if (!taskCron) {
                message.error('请选择 Cron 表达式');
                return;
            }

            const payload = {
                id: editingTask?.id,
                taskName,
                taskBean: editingTask?.task_bean ?? null,
                taskParams: editingTask?.task_params ?? null,
                taskCron,
                taskStatus: values.task_status,
                remark: emptyToNull(values.remark),
                taskType: toTaskTypeCode(values.task_type),
                exePath: normalizeScript(values.script),
                // 注意：dependId 和 dataDependId 传相同值，由后端决定使用哪个字段
                dependId: emptyToNull(values.data_depend_id || values.depend_id),
                dataDependId: emptyToNull(values.data_depend_id || values.depend_id),
                controlDependId: emptyToNull(values.control_depend_id),
                datasourceId: values.datasource_id ?? null,
                period: values.period ?? null,
                taskSystem: emptyToNull(values.task_system || undefined),
                theme: emptyToNull(values.theme || undefined),
                offset: values.offset ?? 0,
                notificationCompleted: serializeNotificationContacts(values.notification_completed_list as NotificationContact[] | undefined),
                notificationFailed: serializeNotificationContacts(values.notification_failed_list as NotificationContact[] | undefined),
            };
            const response = await saveOrUpdateQuartzTask(payload);
            if (!response?.success) throw new Error(response?.msg || '保存任务失败');
            await Promise.all([
                loadTasks(currentPage, pageSize),
                loadDependencyCandidateTasks(),
                loadTaskStatusSummary(),
            ]);
            message.success(editingTask ? `已成功保存任务 ${taskName} 修改` : `已成功创建新任务 ${taskName}`);
            closeTaskModal();
        } catch (error: any) {
            if (error?.errorFields) {
                const labels = error.errorFields.map((field: any) => field.errors?.[0]).filter(Boolean).join('、');
                message.error(labels ? `请检查必填项：${labels}` : '请完善表单配置信息');
                return;
            }
            message.error(error?.message || '保存任务失败');
        }
    };

    const handleDeleteTask = async (task: QuartzTask) => {
        try {
            const response = await deleteQuartzTask(task.id);
            if (!response?.success) throw new Error(response?.msg || '删除任务失败');
            await Promise.all([
                loadTasks(currentPage, pageSize),
                loadDependencyCandidateTasks(),
                loadTaskStatusSummary(),
            ]);
            setSelectedTask(prev => prev?.id === task.id ? null : prev);
            message.success(`已删除监管任务 ${task.task_name}`);
        } catch (error: any) {
            message.error(error?.message || '删除任务失败');
        }
    };

    const handleStartTask = (task: QuartzTask) => {
        setPendingStartTask(task);
        setStartDataDate(dayjs().format('YYYY-MM-DD'));
        setStartTaskModalVisible(true);
    };

    const handleConfirmStartTask = async () => {
        if (!pendingStartTask || !startDataDate) {
            message.error('请选择数据日期');
            return;
        }
        setStartTaskLoading(true);
        try {
            const dataDateFormatted = startDataDate.replace(/-/g, '');
            const response = await triggerNowQuartzTask(pendingStartTask.id, dataDateFormatted);
            if (!response?.success) throw new Error(response?.msg || '立即执行失败');
            message.success(`任务 ${pendingStartTask.task_name} 已成功触发手动执行`);
            setStartTaskModalVisible(false);
            setPendingStartTask(null);
        } catch (error: any) {
            message.error(error?.message || '立即执行失败');
        } finally {
            setStartTaskLoading(false);
        }
    };

    const handlePauseTask = async (task: QuartzTask) => {
        if (task.task_status === 1) return;
        try {
            const response = await pauseQuartzTask(task.id);
            if (!response?.success) throw new Error(response?.msg || '暂停任务失败');
            await Promise.all([
                loadTasks(currentPage, pageSize),
                loadDependencyCandidateTasks(),
                loadTaskStatusSummary(),
            ]);
            message.success(`已暂停调度任务 ${task.task_name}`);
        } catch (error: any) {
            message.error(error?.message || '暂停任务失败');
        }
    };

    const handleResumeTask = async (task: QuartzTask) => {
        if (task.task_status === 0) return;
        try {
            const response = await resumeQuartzTask(task.id);
            if (!response?.success) throw new Error(response?.msg || '恢复任务失败');
            await Promise.all([
                loadTasks(currentPage, pageSize),
                loadDependencyCandidateTasks(),
                loadTaskStatusSummary(),
            ]);
            message.success(`已激活恢复调度任务 ${task.task_name}`);
        } catch (error: any) {
            message.error(error?.message || '恢复任务失败');
        }
    };

    const handleViewExecutionLog = (task: QuartzTask) => {
        if (onViewExecutionLog) {
            onViewExecutionLog(task);
            return;
        }
        message.info(`查看任务 ${task.task_name} 的执行日志`);
    };

    return (
        <>
            <div className="flex h-full min-h-0 flex-col gap-3">
                {/* Dashboard Main Panel Header card */}
                <div className="relative overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm transition-all duration-300">
                    <div className="flex flex-col gap-3 border-b border-slate-100 px-4 py-2.5 lg:flex-row lg:items-center lg:justify-between">
                        <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                            <h1 className="flex items-center gap-2 text-base font-bold tracking-tight text-slate-800">
                                <Sparkles className="h-4 w-4 text-red-500" />
                                任务管理控制台
                            </h1>
                            <span className="text-xs font-medium text-slate-500">
                                周期定义、拓扑依赖与告警通知
                            </span>
                        </div>

                        {/* High-fidelity Statistics Metric Chips and Action Button Container */}
                        <div className="flex flex-wrap items-center gap-2 text-xs">
                            {/* Metric 1 */}
                            <div className="inline-flex h-8 items-center gap-1.5 rounded-lg border border-slate-200 bg-slate-50 px-2.5 font-semibold text-slate-700">
                                <SlidersHorizontal size={13} className="text-slate-400" />
                                <span>总任务</span>
                                <span className="font-mono">{taskTotal}</span>
                            </div>
                            {/* Metric 2 */}
                            <div className="inline-flex h-8 items-center gap-1.5 rounded-lg border border-emerald-100 bg-emerald-50 px-2.5 font-semibold text-emerald-700">
                                <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                                <span>正常</span>
                                <span className="font-mono">{taskStatusSummary.normal}</span>
                            </div>
                            {/* Metric 3 */}
                            <div className="inline-flex h-8 items-center gap-1.5 rounded-lg border border-amber-100 bg-amber-50 px-2.5 font-semibold text-amber-700">
                                <span className="h-1.5 w-1.5 rounded-full bg-amber-500" />
                                <span>暂停</span>
                                <span className="font-mono">{taskStatusSummary.paused}</span>
                            </div>

                        </div>
                    </div>

                    {/* SaaS Control Grid Filter Bar */}
                    <div className="overflow-x-auto px-4 py-2.5">
                        <div className="flex min-w-[1320px] items-end gap-2">
                            <label className="w-[240px] shrink-0 space-y-1">
                                <div className="text-[11px] font-medium text-slate-500">搜索条件</div>
                                <div className="relative">
                                    <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                                <input
                                    value={keyword}
                                    onChange={(event) => setKeyword(event.target.value)}
                                    placeholder="搜索任务ID / 名称"
                                        className="h-8 w-full rounded-lg border border-slate-200 bg-white pl-8 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:ring-2 focus:ring-red-100"
                                />
                                </div>
                            </label>
                            <label className="w-[150px] shrink-0 space-y-1">
                                <div className="text-[11px] font-medium text-slate-500">任务状态</div>
                                <select
                                    value={statusFilter}
                                    onChange={(event) => setStatusFilter(event.target.value)}
                                    className="h-8 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:ring-2 focus:ring-red-100"
                                >
                                    <option value="">全部任务状态</option>
                                    <option value="0">正常</option>
                                    <option value="1">暂停</option>
                                </select>
                            </label>
                            <label className="w-[160px] shrink-0 space-y-1">
                                <div className="text-[11px] font-medium text-slate-500">任务类型</div>
                                <select
                                    value={typeFilter}
                                    onChange={(event) => setTypeFilter(event.target.value)}
                                    className="h-8 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:ring-2 focus:ring-red-100"
                                >
                                    <option value="">全部任务类型</option>
                                    {taskTypes.map(type => (
                                        <option key={type} value={type}>{type}</option>
                                    ))}
                                </select>
                            </label>
                            <label className="w-[180px] shrink-0 space-y-1">
                                <div className="text-[11px] font-medium text-slate-500">所属系统</div>
                                <select
                                    value={systemFilter}
                                    onChange={(event) => setSystemFilter(event.target.value)}
                                    className="h-8 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:ring-2 focus:ring-red-100"
                                >
                                    <option value="">全部所属系统</option>
                                    {systems.map(system => (
                                        <option key={system} value={system}>{system}</option>
                                    ))}
                                </select>
                            </label>
                            <label className="w-[170px] shrink-0 space-y-1">
                                <div className="text-[11px] font-medium text-slate-500">主题</div>
                                <div className="relative">
                                    <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                                <input
                                    value={themeFilter}
                                    onChange={(event) => setThemeFilter(event.target.value)}
                                    placeholder="搜索主题"
                                        className="h-8 w-full rounded-lg border border-slate-200 bg-white pl-8 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:ring-2 focus:ring-red-100"
                                />
                                </div>
                            </label>
                            <label className="w-[170px] shrink-0 space-y-1">
                                <div className="text-[11px] font-medium text-slate-500">备注</div>
                                <div className="relative">
                                    <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                                <input
                                    value={remarkFilter}
                                    onChange={(event) => setRemarkFilter(event.target.value)}
                                    placeholder="搜索备注"
                                        className="h-8 w-full rounded-lg border border-slate-200 bg-white pl-8 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:ring-2 focus:ring-red-100"
                                />
                                </div>
                            </label>
                            <div className="w-[190px] shrink-0 space-y-1">
                                <div className="text-[11px] font-medium text-slate-500">操作</div>
                                <div className="flex gap-1.5">
                                    <motion.button
                                        whileHover={{ scale: 1.02 }}
                                        whileTap={{ scale: 0.98 }}
                                        onClick={handleRefreshTasks}
                                        disabled={refreshing}
                                        className="inline-flex h-8 flex-1 items-center justify-center gap-1 rounded-lg border border-slate-200 bg-white px-2 text-xs font-bold text-slate-600 shadow-sm transition-all duration-200 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                                    >
                                        <RefreshCw size={13} className={`${refreshing ? 'animate-spin' : ''} text-slate-400`} />
                                        刷新
                                    </motion.button>
                                    <motion.button
                                        whileHover={{ scale: 1.02, y: -1 }}
                                        whileTap={{ scale: 0.98 }}
                                        onClick={() => openTaskModal(null)}
                                        className="inline-flex h-8 flex-1 items-center justify-center gap-1 rounded-lg border border-slate-200 bg-white px-2 text-xs font-bold text-slate-600 shadow-sm transition-all duration-200 hover:bg-slate-50"
                                    >
                                        <Plus size={13} />
                                        新建
                                    </motion.button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* 任务列表表格 - Beautiful container backdrop wrapper */}
                <div className="min-h-0 flex-1 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
                    <TaskListTable
                        taskList={taskList}
                        onSelectTask={setSelectedTask}
                        onEditTask={(task) => openTaskModal(task)}
                        onPauseTask={handlePauseTask}
                        onResumeTask={handleResumeTask}
                        onStartTask={handleStartTask}
                        onViewExecutionLog={handleViewExecutionLog}
                        onDeleteTask={handleDeleteTask}
                    />
                </div>

                <div className="px-5 py-4 flex justify-end">
                    <Pagination
                        current={currentPage}
                        total={taskTotal}
                        pageSize={pageSize}
                        showSizeChanger
                        onChange={(page, size) => {
                            setCurrentPage(page);
                            setPageSize(size);
                        }}
                    />
                </div>
            </div>

            {/* 立即开始 Modal - Premium overlapping style */}
            <Modal
                title={null}
                open={startTaskModalVisible}
                onCancel={() => {
                    setStartTaskModalVisible(false);
                    setPendingStartTask(null);
                }}
                onOk={handleConfirmStartTask}
                confirmLoading={startTaskLoading}
                destroyOnHidden
                className="premium-task-modal"
                styles={{ body: { padding: 0 }, footer: { padding: '16px 24px', borderTop: '1px solid #f1f5f9' } }}
                footer={
                    <div className="flex items-center justify-end gap-3">
                        <button
                            type="button"
                            onClick={() => {
                                setStartTaskModalVisible(false);
                                setPendingStartTask(null);
                            }}
                            className="rounded-xl border border-slate-200 bg-white px-5 py-2.5 text-xs font-bold text-slate-600 transition-all duration-200 hover:bg-slate-50 active:scale-95"
                        >
                            取消
                        </button>
                        <button
                            type="button"
                            onClick={handleConfirmStartTask}
                            disabled={startTaskLoading}
                            className="rounded-xl bg-gradient-to-r from-red-600 to-red-700 px-5.5 py-2.5 text-xs font-bold text-white shadow-md shadow-red-600/10 transition-all duration-200 hover:from-red-500 hover:to-red-600 hover:shadow-lg hover:shadow-red-500/20 active:scale-95 disabled:opacity-50"
                        >
                            {startTaskLoading ? '执行中...' : '确认执行'}
                        </button>
                    </div>
                }
            >
                <div className="p-6">
                    <div className="flex items-center gap-3 border-b border-slate-100 pb-4 mb-4">
                        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-red-50 text-red-500">
                            <Clock3 size={18} />
                        </div>
                        <div>
                            <h3 className="text-base font-bold text-slate-800">立即触发监管任务</h3>
                            <p className="mt-0.5 text-xs text-slate-400 font-medium truncate max-w-[340px]">
                                {pendingStartTask?.task_name || '任务运行配置'}
                            </p>
                        </div>
                    </div>
                    <div className="space-y-4">
                        <div className="rounded-xl bg-slate-50 px-4 py-3 text-xs text-slate-500 border border-slate-100 leading-relaxed font-medium">
                            立即执行将手动触发该定时任务。系统会为选中的“数据日期”生成运行实例并进入调度系统。请确保已核验其前置依赖。
                        </div>
                        <div>
                            <label className="block mb-2 text-slate-600 font-semibold text-xs uppercase tracking-wider">
                                选择数据日期 (Data Date)
                            </label>
                            <DatePicker
                                value={startDataDate ? dayjs(startDataDate) : null}
                                onChange={(value) => setStartDataDate(value ? value.format('YYYY-MM-DD') : '')}
                                locale={zhCN}
                                className="w-full h-10 rounded-xl bg-slate-50/50 border-slate-200 hover:border-slate-300 focus:border-slate-400 focus:bg-white text-sm"
                                allowClear={false}
                                disabledDate={(current) => current && current > dayjs().endOf('day')}
                            />
                        </div>
                    </div>
                </div>
            </Modal>

            {/* 任务编辑 Modal */}
            <TaskEditorModal
                open={modalVisible}
                editingTask={editingTask}
                form={form}
                taskList={dependencyCandidateTaskList.length > 0 ? dependencyCandidateTaskList : taskList}
                taskTypes={taskTypes}
                systems={systems}
                datasourceOptions={datasourceOptions}
                dataSourceLoading={dataSourceLoading}
                editorLanguageMap={editorLanguageMap}
                getInitialFormValues={getInitialFormValues}
                describeCron={describeCron}
                onCancel={closeTaskModal}
                onSubmit={handleSaveTask}
            />

            {/* 任务详情 Drawer */}
            <TaskDetailDrawer
                selectedTask={selectedTask}
                selectedTaskDetailTab={selectedTaskDetailTab}
                selectedTaskDataDependencies={selectedTaskDataDependencies}
                selectedTaskControlDependencies={selectedTaskControlDependencies}
                selectedTaskDependencySummary={selectedTaskDependencySummary}
                detailScriptEditorReady={detailScriptEditorReady}
                onClose={() => setSelectedTask(null)}
                onTabChange={setSelectedTaskDetailTab}
            />
        </>
    );
};

export default TaskManagement;
