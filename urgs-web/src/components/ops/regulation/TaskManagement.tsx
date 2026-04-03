import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { DatePicker, Drawer, Dropdown, Form, Modal, Tag, message } from 'antd';
import type { MenuProps } from 'antd';
import { Calendar, Clock3, FileCog, FileText, MoreHorizontal, PauseCircle, Play, PlayCircle, Plus, Search, Settings2, Trash2 } from 'lucide-react';
import dayjs from 'dayjs';
import zhCN from 'antd/es/date-picker/locale/zh_CN';
import { QuartzTask } from './mockData';
import LazyMonacoEditor from './LazyMonacoEditor';
import TaskEditorModal from './TaskEditorModal';
import Pagination from '@/components/common/Pagination';
import {
    deleteQuartzTask,
    getDatasourceConfig,
    pauseQuartzTask,
    queryQuartzTaskDependencies,
    queryQuartzTasks,
    QuartzTaskApiModel,
    resumeQuartzTask,
    saveOrUpdateQuartzTask
} from '@/api/ops';
import { getSsoList, SsoConfig } from '@/api/version';

interface TaskManagementProps {
    onViewExecutionLog?: (task: QuartzTask) => void;
}

interface TaskFormValues {
    task_name: string;
    task_type?: string;
    task_status: 0 | 1;
    task_system?: string;
    theme?: string;
    remark?: string;
    task_cron: string;
    offset?: number | null;
    depend_id?: string;
    period?: number | null;
    datasource_id?: number;
    script?: string;
    notification_completed?: string;
    notification_failed?: string;
}

interface DataSourceOption {
    id: number;
    name: string;
    typeName?: string;
    typeCode?: string;
    category?: string;
    status?: number;
    connectionInfo?: string;
}

const supportedTaskTypes = ['SQL', 'SHELL'] as const;
const editorLanguageMap: Record<string, string> = {
    SQL: 'sql',
    SHELL: 'shell',
};

const statusMap: Record<number, { label: string; className: string }> = {
    0: { label: '正常', className: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
    1: { label: '暂停', className: 'bg-amber-50 text-amber-600 border-amber-200' },
};

const detailItemClass = 'rounded-xl border border-slate-200 bg-slate-50/70 px-4 py-3';
const detailSectionClass = 'rounded-2xl border border-slate-200 bg-white';
const detailMetaBadgeClass = 'inline-flex max-w-[160px] items-center rounded-lg border border-slate-200 bg-slate-50 px-2 py-1 text-[11px] leading-none text-slate-600';
const actionButtonClass = 'inline-flex items-center gap-1 rounded-lg border px-3 py-1.5 text-xs font-medium transition-colors';
const enabledActionClass = 'border-slate-200 text-slate-600 hover:bg-slate-50';
const primaryActionClass = 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50';
const emptyToNull = (value?: string) => {
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    return trimmed === '' ? null : trimmed;
};

const normalizeScript = (value?: string) => {
    if (typeof value !== 'string') return null;
    if (value.trim() === '') return null;
    return value.replace(/\r\n/g, '\n');
};

const weekLabelMap: Record<string, string> = {
    '1': '每周日',
    '2': '每周一',
    '3': '每周二',
    '4': '每周三',
    '5': '每周四',
    '6': '每周五',
    '7': '每周六',
};

const describeCron = (cron?: string, offset?: number | null) => {
    if (!cron) return '尚未设置运行时间';

    const parts = cron.trim().split(/\s+/);
    if (parts.length < 6) {
        return `按 Cron ${cron} 执行`;
    }

    const minute = parts[1];
    const hour = parts[2];
    const day = parts[3];
    const month = parts[4];
    const week = parts[5];

    let schedule = `按 Cron ${cron} 执行`;

    if (minute.startsWith('*/')) {
        schedule = `每 ${minute.replace('*/', '')} 分钟执行一次`;
    } else if (hour.startsWith('*/')) {
        schedule = `每 ${hour.replace('*/', '')} 小时在 ${minute.padStart(2, '0')} 分执行`;
    } else if (day === '*' && month === '*' && week === '?') {
        schedule = `每天 ${hour.padStart(2, '0')}:${minute.padStart(2, '0')} 执行`;
    } else if (day !== '*' && day !== '?' && month === '*') {
        schedule = `每月 ${day} 日 ${hour.padStart(2, '0')}:${minute.padStart(2, '0')} 执行`;
    } else if (week !== '*' && week !== '?') {
        schedule = `${weekLabelMap[week] || `每周 ${week}`} ${hour.padStart(2, '0')}:${minute.padStart(2, '0')} 执行`;
    }

    if (offset !== undefined && offset !== null && offset !== 0) {
        return `${schedule}，数据偏移 ${offset} 天`;
    }

    return schedule;
};

const describeDataSourceConnection = (params?: Record<string, any>, typeCode?: string) => {
    if (!params) return '连接信息待补充';

    const host = params.host ? String(params.host) : '';
    const port = params.port !== undefined && params.port !== null && params.port !== '' ? String(params.port) : '';
    const database = params.database ? String(params.database) : '';
    const serviceName = params.serviceName ? String(params.serviceName) : '';
    const rootPath = params.rootPath ? String(params.rootPath) : '';
    const endpoint = params.endpoint ? String(params.endpoint) : '';
    const jdbcUrl = params.jdbcUrl ? String(params.jdbcUrl) : '';
    const address = params.address ? String(params.address) : '';
    const defaultFS = params.defaultFS ? String(params.defaultFS) : '';
    const path = params.path ? String(params.path) : '';
    const masterAddresses = params.masterAddresses ? String(params.masterAddresses) : '';
    const zkQuorum = params.zkQuorum ? String(params.zkQuorum) : '';
    const url = params.url ? String(params.url) : '';

    if (jdbcUrl) return jdbcUrl;
    if (url) return url;
    if (endpoint) {
        const suffix = params.bucket || params.project || params.instanceName || params.method
            ? ` / ${[params.bucket, params.project, params.instanceName, params.method].filter(Boolean).join(' / ')}`
            : '';
        return `${endpoint}${suffix}`;
    }
    if (host) {
        const hostPort = port ? `${host}:${port}` : host;
        if (database) return `${hostPort}/${database}`;
        if (serviceName) return `${hostPort}/${serviceName}`;
        if (rootPath) return `${hostPort}${rootPath.startsWith('/') ? '' : '/'}${rootPath}`;
        return hostPort;
    }
    if (address) {
        return database ? `${address}/${database}` : address;
    }
    if (defaultFS) {
        return path ? `${defaultFS}${path}` : defaultFS;
    }
    if (masterAddresses) return masterAddresses;
    if (zkQuorum) return zkQuorum;
    if (path) return path;

    const preferredKeys = ['database', 'serviceName', 'bucket', 'project', 'instanceName', 'fileType', 'schema'];
    const summary = preferredKeys
        .map(key => params[key])
        .filter(Boolean)
        .map(value => String(value))
        .join(' / ');

    if (summary) return summary;
    return typeCode ? `${typeCode} 数据源` : '连接信息待补充';
};

const getInitialFormValues = (task?: QuartzTask | null): TaskFormValues => ({
    task_name: task?.task_name || '',
    task_type: task?.task_type || 'SHELL',
    task_status: task?.task_status ?? 0,
    task_system: task?.task_system || undefined,
    theme: task?.theme || undefined,
    remark: task?.remark || undefined,
    task_cron: task?.task_cron || '0 0 * * * ?',
    offset: task?.offset ?? null,
    depend_id: task?.depend_id || undefined,
    period: task?.period ?? null,
    datasource_id: task?.datasource_id ?? undefined,
    script: task?.script || undefined,
    notification_completed: task?.notification_completed || undefined,
    notification_failed: task?.notification_failed || undefined,
});

const toTaskTypeCode = (taskType?: string | null) => (taskType === 'SQL' ? 2 : 1);

const toTaskTypeLabel = (taskType?: number | null) => {
    if (taskType === 2) return 'SQL';
    if (taskType === 1) return 'SHELL';
    return 'SHELL';
};

const normalizeQuartzTask = (item: QuartzTaskApiModel): QuartzTask => {
    const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
    return {
        id: Number(item.id),
        task_name: item.taskName || '',
        task_bean: item.taskBean ?? null,
        task_params: item.taskParams ?? null,
        task_cron: item.taskCron || '',
        task_status: Number(item.taskStatus ?? 0) as 0 | 1,
        remark: item.remark ?? null,
        update_time: item.updateTime || now,
        create_time: item.createTime || now,
        task_type: toTaskTypeLabel(item.taskType),
        url: item.url ?? null,
        script: item.exePath ?? null,
        depend_id: item.dependId ?? null,
        username: item.username ?? null,
        password: item.password ?? null,
        driver: item.driver ?? null,
        datasource_id: null,
        datasource_name: null,
        period: item.period ?? null,
        task_system: item.taskSystem ?? null,
        theme: item.theme ?? null,
        offset: item.offset ?? null,
        data_date: item.dataDate ?? null,
        job_key: item.jobKey ?? null,
        notification_completed: item.notificationCompleted ?? null,
        notification_failed: item.notificationFailed ?? null,
    };
};

const TaskManagement: React.FC<TaskManagementProps> = ({ onViewExecutionLog }) => {
    const [taskList, setTaskList] = useState<QuartzTask[]>([]);
    const [taskTotal, setTaskTotal] = useState(0);
    const [form] = Form.useForm<TaskFormValues>();
    const [keyword, setKeyword] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [typeFilter, setTypeFilter] = useState<string>('');
    const [systemFilter, setSystemFilter] = useState<string>('');
    const [themeFilter, setThemeFilter] = useState<string>('');
    const [selectedTask, setSelectedTask] = useState<QuartzTask | null>(null);
    const [selectedTaskDetailTab, setSelectedTaskDetailTab] = useState<'config' | 'dependency'>('config');
    const [selectedTaskDependencies, setSelectedTaskDependencies] = useState<QuartzTask[]>([]);
    const [detailScriptEditorReady, setDetailScriptEditorReady] = useState(false);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingTask, setEditingTask] = useState<QuartzTask | null>(null);
    const [startTaskModalVisible, setStartTaskModalVisible] = useState(false);
    const [pendingStartTask, setPendingStartTask] = useState<QuartzTask | null>(null);
    const [startDataDate, setStartDataDate] = useState(dayjs().format('YYYY-MM-DD'));
    const [dataSources, setDataSources] = useState<DataSourceOption[]>([]);
    const [dataSourceLoading, setDataSourceLoading] = useState(false);
    const [regulationSystems, setRegulationSystems] = useState<SsoConfig[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);

    const taskTypes = useMemo(() => [...supportedTaskTypes], []);
    const systems = useMemo(() => {
        const systemNames = new Set<string>();
        regulationSystems.forEach(system => {
            if (system.name?.trim()) {
                systemNames.add(system.name.trim());
            }
        });
        taskList.forEach(task => {
            if (task.task_system?.trim()) {
                systemNames.add(task.task_system.trim());
            }
        });
        if (editingTask?.task_system?.trim()) {
            systemNames.add(editingTask.task_system.trim());
        }
        return Array.from(systemNames);
    }, [editingTask?.task_system, regulationSystems, taskList]);
    const themes = useMemo(
        () => {
            const themeNames = new Set<string>();
            taskList.forEach(task => {
                if (task.theme?.trim()) {
                    themeNames.add(task.theme.trim());
                }
            });
            if (editingTask?.theme?.trim()) {
                themeNames.add(editingTask.theme.trim());
            }
            return Array.from(themeNames);
        },
        [editingTask?.theme, taskList]
    );

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
                if (mounted) {
                    setDataSourceLoading(false);
                }
            }
        };

        fetchRegulationSystems();
        fetchDataSources();

        return () => {
            mounted = false;
        };
    }, []);

    const buildTaskQueryParams = useCallback((pageNum: number, size: number) => ({
        pageNum,
        pageSize: size,
        taskName: emptyToNull(keyword) || undefined,
        taskStatus: statusFilter === '' ? undefined : Number(statusFilter),
        taskType: typeFilter ? toTaskTypeCode(typeFilter) : undefined,
        taskSystem: systemFilter || undefined,
        theme: themeFilter || undefined,
    }), [keyword, statusFilter, systemFilter, themeFilter, typeFilter]);

    const loadTasks = useCallback(async (pageNum = currentPage, size = pageSize) => {
        try {
            const response = await queryQuartzTasks(buildTaskQueryParams(pageNum, size));
            if (!response?.success) {
                throw new Error(response?.msg || '任务查询失败');
            }
            const list = (response.data?.list || []).map(normalizeQuartzTask);
            setTaskList(list);
            setTaskTotal(Number(response.data?.total || 0));
        } catch (error: any) {
            message.error(error?.message || '加载任务失败');
        }
    }, [buildTaskQueryParams, currentPage, pageSize]);

    useEffect(() => {
        loadTasks(currentPage, pageSize);
    }, [currentPage, loadTasks, pageSize]);

    useEffect(() => {
        setCurrentPage(1);
    }, [keyword, statusFilter, systemFilter, themeFilter, typeFilter]);

    useEffect(() => {
        setSelectedTaskDetailTab('config');
        setSelectedTaskDependencies([]);
        setDetailScriptEditorReady(false);

        if (!selectedTask?.id) {
            return;
        }

        let mounted = true;

        const timer = window.setTimeout(() => {
            if (mounted) {
                setDetailScriptEditorReady(true);
            }
        }, 80);

        const loadSelectedTaskDependencies = async () => {
            try {
                const response = await queryQuartzTaskDependencies(selectedTask.id);
                if (!mounted) {
                    return;
                }
                if (!response?.success) {
                    setSelectedTaskDependencies([]);
                    return;
                }
                setSelectedTaskDependencies((response.data || []).map(normalizeQuartzTask));
            } catch (error) {
                if (mounted) {
                    setSelectedTaskDependencies([]);
                }
            }
        };

        loadSelectedTaskDependencies();

        return () => {
            mounted = false;
            window.clearTimeout(timer);
        };
    }, [selectedTask?.id]);

    const fallbackDataSources = useMemo(() => {
        return taskList.reduce<DataSourceOption[]>((acc, task) => {
            if (!task.datasource_name) return acc;
            const nextId = task.datasource_id ?? -(acc.length + 1);
            if (acc.some(item => item.id === nextId || item.name === task.datasource_name)) {
                return acc;
            }
            acc.push({
                id: nextId,
                name: task.datasource_name,
                connectionInfo: task.url || '连接信息待补充',
            });
            return acc;
        }, []);
    }, [taskList]);

    const datasourceOptions = useMemo(() => {
        return dataSources.length > 0 ? dataSources : fallbackDataSources;
    }, [dataSources, fallbackDataSources]);

    const selectedTaskDependencySummary = useMemo(() => {
        if (selectedTaskDependencies.length === 0) {
            return '无前置依赖';
        }
        const labels = selectedTaskDependencies.slice(0, 2).map(task => task.task_name || `任务 ${task.id}`);
        return selectedTaskDependencies.length > 2
            ? `${labels.join('，')} 等 ${selectedTaskDependencies.length} 项`
            : labels.join('，');
    }, [selectedTaskDependencies]);

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
            const values = await form.validateFields();
            const payload = {
                id: editingTask?.id,
                taskName: values.task_name.trim(),
                taskBean: editingTask?.task_bean ?? null,
                taskParams: editingTask?.task_params ?? null,
                taskCron: values.task_cron.trim(),
                taskStatus: values.task_status,
                remark: emptyToNull(values.remark),
                taskType: toTaskTypeCode(values.task_type),
                url: editingTask?.url ?? null,
                exePath: normalizeScript(values.script),
                dependId: emptyToNull(values.depend_id),
                username: editingTask?.username ?? null,
                password: editingTask?.password ?? null,
                driver: editingTask?.driver ?? null,
                period: values.period ?? null,
                taskSystem: emptyToNull(values.task_system || undefined),
                theme: emptyToNull(values.theme || undefined),
                offset: values.offset ?? 0,
                notificationCompleted: emptyToNull(values.notification_completed),
                notificationFailed: emptyToNull(values.notification_failed),
            };
            const response = await saveOrUpdateQuartzTask(payload);
            if (!response?.success) {
                throw new Error(response?.msg || '保存任务失败');
            }
            await loadTasks(currentPage, pageSize);
            message.success(editingTask ? `已更新任务 ${values.task_name}` : `已创建任务 ${values.task_name}`);
            closeTaskModal();
        } catch (error: any) {
            if (error?.errorFields) {
                const labels = error.errorFields
                    .map((field: any) => field.errors?.[0])
                    .filter(Boolean)
                    .join('、');
                message.error(labels ? `请检查表单：${labels}` : '请完善表单信息');
                return;
            }
            message.error(error?.message || '保存任务失败');
        }
    };

    const handleEditTask = (task: QuartzTask) => {
        openTaskModal(task);
    };

    const handleDeleteTask = async (task: QuartzTask) => {
        try {
            const response = await deleteQuartzTask(task.id);
            if (!response?.success) {
                throw new Error(response?.msg || '删除任务失败');
            }
            await loadTasks(currentPage, pageSize);
            setSelectedTask(prev => prev?.id === task.id ? null : prev);
            message.success(`已删除任务 ${task.task_name}`);
        } catch (error: any) {
            message.error(error?.message || '删除任务失败');
        }
    };

    const handleStartTask = (task: QuartzTask) => {
        setPendingStartTask(task);
        setStartDataDate(dayjs().format('YYYY-MM-DD'));
        setStartTaskModalVisible(true);
    };

    const handleConfirmStartTask = () => {
        if (!pendingStartTask || !startDataDate) {
            message.error('请选择数据日期');
            return;
        }
        message.info('当前后端未开放立即执行接口，请在执行器侧手工下发或补充 API');
        setStartTaskModalVisible(false);
        setPendingStartTask(null);
    };

    const handlePauseTask = async (task: QuartzTask) => {
        if (task.task_status === 1) return;
        try {
            const response = await pauseQuartzTask(task.id);
            if (!response?.success) {
                throw new Error(response?.msg || '暂停任务失败');
            }
            await loadTasks(currentPage, pageSize);
            message.success(`已暂停任务 ${task.task_name}`);
        } catch (error: any) {
            message.error(error?.message || '暂停任务失败');
        }
    };

    const handleResumeTask = async (task: QuartzTask) => {
        if (task.task_status === 0) return;
        try {
            const response = await resumeQuartzTask(task.id);
            if (!response?.success) {
                throw new Error(response?.msg || '恢复任务失败');
            }
            await loadTasks(currentPage, pageSize);
            message.success(`已恢复任务 ${task.task_name}`);
        } catch (error: any) {
            message.error(error?.message || '恢复任务失败');
        }
    };

    const handleViewExecutionLog = (task: QuartzTask) => {
        if (onViewExecutionLog) {
            onViewExecutionLog(task);
            return;
        }
        message.info(`前端稿占位：查看任务 ${task.task_name} 的执行日志`);
    };

    const handleCreateTask = () => {
        openTaskModal(null);
    };

    const getMoreMenuItems = (task: QuartzTask): MenuProps['items'] => [
        {
            key: `start-${task.id}`,
            label: '立即开始',
            icon: <Play size={14} />,
            onClick: () => handleStartTask(task),
        },
        {
            key: `log-${task.id}`,
            label: '执行日志',
            icon: <FileText size={14} />,
            onClick: () => handleViewExecutionLog(task),
        },
        {
            type: 'divider',
        },
        {
            key: `delete-${task.id}`,
            label: '删除',
            icon: <Trash2 size={14} />,
            danger: true,
            onClick: () => handleDeleteTask(task),
        },
    ];

    return (
        <>
            <div className="space-y-4">
                <div className="bg-white rounded-2xl border border-slate-200 p-5">
                    <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                        <div>
                            <div className="text-lg font-bold text-slate-800">任务管理</div>
                            <div className="text-sm text-slate-500 mt-1">
                                围绕 `t_quartz_task` 展示监管批量任务定义、依赖关系和运行配置。
                            </div>
                        </div>
                        <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500">
                            <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5">
                                <Settings2 size={14} />
                                共 {taskTotal} 条任务
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-3 py-1.5 text-emerald-700">
                                正常 {taskList.filter(task => task.task_status === 0).length}
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-3 py-1.5 text-amber-700">
                                暂停 {taskList.filter(task => task.task_status === 1).length}
                            </span>
                            <button
                                onClick={handleCreateTask}
                                className="inline-flex items-center gap-1.5 rounded-xl bg-red-600 px-3.5 py-2 text-xs font-semibold text-white transition-colors hover:bg-red-700"
                            >
                                <Plus size={14} />
                                新建任务
                            </button>
                        </div>
                    </div>

                    <div className="mt-5 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-5 gap-3">
                        <label className="relative">
                            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                            <input
                                value={keyword}
                                onChange={(event) => setKeyword(event.target.value)}
                                placeholder="搜索任务名称 / 备注"
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </label>
                        <select
                            value={statusFilter}
                            onChange={(event) => setStatusFilter(event.target.value)}
                            className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                        >
                            <option value="">全部状态</option>
                            <option value="0">正常</option>
                            <option value="1">暂停</option>
                        </select>
                        <select
                            value={typeFilter}
                            onChange={(event) => setTypeFilter(event.target.value)}
                            className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                        >
                            <option value="">全部任务类型</option>
                            {taskTypes.map(type => (
                                <option key={type} value={type}>{type}</option>
                            ))}
                        </select>
                        <select
                            value={systemFilter}
                            onChange={(event) => setSystemFilter(event.target.value)}
                            className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                        >
                            <option value="">全部系统</option>
                            {systems.map(system => (
                                <option key={system} value={system}>{system}</option>
                            ))}
                        </select>
                        <select
                            value={themeFilter}
                            onChange={(event) => setThemeFilter(event.target.value)}
                            className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                        >
                            <option value="">全部主题</option>
                            {themes.map(theme => (
                                <option key={theme} value={theme}>{theme}</option>
                            ))}
                        </select>
                    </div>
                </div>

                <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full min-w-[1240px] text-sm text-left">
                            <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500 border-b border-slate-200">
                                <tr>
                                    <th className="px-4 py-3 font-semibold">任务名称</th>
                                    <th className="px-4 py-3 font-semibold">任务类型</th>
                                    <th className="px-4 py-3 font-semibold">Cron</th>
                                    <th className="px-4 py-3 font-semibold">状态</th>
                                    <th className="px-4 py-3 font-semibold">系统</th>
                                    <th className="px-4 py-3 font-semibold">主题</th>
                                    <th className="px-4 py-3 font-semibold">偏移量</th>
                                    <th className="px-4 py-3 font-semibold">更新时间</th>
                                    <th className="px-4 py-3 font-semibold text-right">操作</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {taskList.length === 0 ? (
                                    <tr>
                                        <td colSpan={9} className="px-6 py-16 text-center text-slate-500">
                                            未找到符合条件的监管任务。
                                        </td>
                                    </tr>
                                ) : taskList.map(task => {
                                    const mappedStatus = statusMap[task.task_status] || statusMap[0];

                                    return (
                                        <tr
                                            key={task.id}
                                            onClick={() => setSelectedTask(task)}
                                            className="cursor-pointer hover:bg-red-50/30"
                                        >
                                            <td className="px-4 py-4">
                                                <div className="space-y-1 text-left">
                                                    <div className="font-semibold text-slate-800">
                                                        {task.task_name}
                                                    </div>
                                                    <div className="font-mono text-xs text-slate-500">#{task.id}</div>
                                                </div>
                                            </td>
                                            <td className="px-4 py-4">
                                                <Tag color="blue" className="m-0 border-0 bg-blue-50 text-blue-600">{task.task_type || '-'}</Tag>
                                            </td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-600">{task.task_cron}</td>
                                            <td className="px-4 py-4">
                                                <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${mappedStatus.className}`}>
                                                    {mappedStatus.label}
                                                </span>
                                            </td>
                                            <td className="px-4 py-4 text-slate-600">{task.task_system || '-'}</td>
                                            <td className="px-4 py-4 text-slate-600">{task.theme || '-'}</td>
                                            <td className="px-4 py-4 text-slate-600">{task.offset ?? '-'}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-500">
                                                {dayjs(task.update_time).format('YYYY-MM-DD HH:mm:ss')}
                                            </td>
                                            <td className="px-4 py-4">
                                                <div className="flex items-center justify-end gap-2">
                                                    <button
                                                        onClick={(event) => {
                                                            event.stopPropagation();
                                                            handleEditTask(task);
                                                        }}
                                                        className={`${actionButtonClass} ${primaryActionClass} hover:border-blue-200 hover:bg-blue-50 hover:text-blue-600`}
                                                    >
                                                        <FileCog size={14} />
                                                        编辑
                                                    </button>
                                                    {task.task_status === 0 ? (
                                                        <button
                                                            onClick={(event) => {
                                                                event.stopPropagation();
                                                                handlePauseTask(task);
                                                            }}
                                                            className={`${actionButtonClass} ${primaryActionClass} hover:border-amber-200 hover:bg-amber-50 hover:text-amber-700`}
                                                        >
                                                            <PauseCircle size={14} />
                                                            暂停任务
                                                        </button>
                                                    ) : (
                                                        <button
                                                            onClick={(event) => {
                                                                event.stopPropagation();
                                                                handleResumeTask(task);
                                                            }}
                                                            className={`${actionButtonClass} ${primaryActionClass} hover:border-cyan-200 hover:bg-cyan-50 hover:text-cyan-700`}
                                                        >
                                                            <PlayCircle size={14} />
                                                            恢复任务
                                                        </button>
                                                    )}
                                                    <Dropdown
                                                        menu={{ items: getMoreMenuItems(task) }}
                                                        trigger={['click']}
                                                        placement="bottomRight"
                                                    >
                                                        <button
                                                            onClick={(event) => {
                                                                event.preventDefault();
                                                                event.stopPropagation();
                                                            }}
                                                            className={`${actionButtonClass} ${enabledActionClass} px-2.5 hover:border-slate-300 hover:bg-slate-50 hover:text-slate-700`}
                                                            aria-label="更多操作"
                                                        >
                                                            <MoreHorizontal size={16} />
                                                        </button>
                                                    </Dropdown>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                </div>
                <div className="px-5">
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

            <Modal
                title={pendingStartTask ? `立即开始 · ${pendingStartTask.task_name}` : '立即开始'}
                open={startTaskModalVisible}
                onCancel={() => {
                    setStartTaskModalVisible(false);
                    setPendingStartTask(null);
                }}
                onOk={handleConfirmStartTask}
                okText="确认执行"
                cancelText="取消"
                destroyOnHidden
            >
                <div className="space-y-4 py-2">
                    <div className="text-sm text-slate-500">
                        为当前任务选择本次立即执行的数据日期。
                    </div>
                    <div>
                        <div className="mb-2 text-sm font-medium text-slate-700">数据日期</div>
                        <DatePicker
                            value={startDataDate ? dayjs(startDataDate) : null}
                            onChange={(value) => setStartDataDate(value ? value.format('YYYY-MM-DD') : '')}
                            locale={zhCN}
                            className="w-full"
                            allowClear={false}
                        />
                    </div>
                </div>
            </Modal>

            <TaskEditorModal
                open={modalVisible}
                editingTask={editingTask}
                form={form}
                taskList={taskList}
                taskTypes={taskTypes}
                systems={systems}
                themes={themes}
                datasourceOptions={datasourceOptions}
                dataSourceLoading={dataSourceLoading}
                editorLanguageMap={editorLanguageMap}
                getInitialFormValues={getInitialFormValues}
                describeCron={describeCron}
                onCancel={closeTaskModal}
                onSubmit={handleSaveTask}
            />

            <Drawer
                title={selectedTask ? `任务详情 · ${selectedTask.task_name}` : '任务详情'}
                placement="right"
                size={620}
                onClose={() => setSelectedTask(null)}
                open={!!selectedTask}
                destroyOnHidden
            >
                {selectedTask && (
                    <div className="space-y-5">
                        <div className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
                            <div className="flex items-start justify-between gap-3">
                                <div className="min-w-0">
                                    <div className="truncate text-base font-semibold text-slate-800">
                                        {selectedTask.task_name}
                                    </div>
                                    <div className="mt-2 flex flex-wrap items-center gap-1.5">
                                        <span className={`${detailMetaBadgeClass} max-w-none font-mono text-slate-500`}>
                                            #{selectedTask.id}
                                        </span>
                                        <span className={detailMetaBadgeClass} title={selectedTask.task_system || '-'}>
                                            <span className="mr-1 text-slate-400">系统</span>
                                            <span className="truncate">{selectedTask.task_system || '-'}</span>
                                        </span>
                                        <span className={detailMetaBadgeClass} title={selectedTask.theme || '-'}>
                                            <span className="mr-1 text-slate-400">主题</span>
                                            <span className="truncate">{selectedTask.theme || '-'}</span>
                                        </span>
                                        <span className={detailMetaBadgeClass} title={selectedTask.task_type || '-'}>
                                            <span className="mr-1 text-slate-400">类型</span>
                                            <span className="truncate">{selectedTask.task_type || '-'}</span>
                                        </span>
                                    </div>
                                </div>
                                <span className={`shrink-0 rounded-full border px-2 py-1 text-xs font-semibold ${statusMap[selectedTask.task_status]?.className || statusMap[0].className}`}>
                                    {statusMap[selectedTask.task_status]?.label || statusMap[0].label}
                                </span>
                            </div>
                            <div className="mt-3 text-xs text-slate-500">
                                {describeCron(selectedTask.task_cron, selectedTask.offset ?? 0)}
                            </div>
                        </div>

                        <div className="rounded-2xl border border-slate-200 bg-white p-1.5">
                            <div className="grid grid-cols-2 gap-1">
                                <button
                                    type="button"
                                    onClick={() => setSelectedTaskDetailTab('config')}
                                    className={`rounded-xl px-3 py-2 text-sm font-semibold transition ${selectedTaskDetailTab === 'config' ? 'bg-red-50 text-red-700' : 'text-slate-500 hover:bg-slate-50'}`}
                                >
                                    任务配置
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setSelectedTaskDetailTab('dependency')}
                                    className={`rounded-xl px-3 py-2 text-sm font-semibold transition ${selectedTaskDetailTab === 'dependency' ? 'bg-blue-50 text-blue-700' : 'text-slate-500 hover:bg-slate-50'}`}
                                >
                                    依赖任务
                                </button>
                            </div>
                        </div>

                        {selectedTaskDetailTab === 'config' ? (
                            <>
                                <section className={detailSectionClass}>
                                    <div className="border-b border-slate-100 px-5 py-4">
                                        <div className="text-base font-semibold text-slate-900">任务核心</div>
                                        <div className="mt-1 text-sm text-slate-500">基础身份、归属范围和备注信息。</div>
                                    </div>
                                    <div className="grid grid-cols-2 gap-3 p-5">
                                        <div className={`col-span-2 ${detailItemClass}`}>
                                            <div className="text-xs text-slate-400">任务名称</div>
                                            <div className="mt-1 font-semibold text-slate-800">{selectedTask.task_name || '-'}</div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">任务ID</div>
                                            <div className="mt-1 font-mono text-xs text-slate-700">#{selectedTask.id}</div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">任务状态</div>
                                            <div className="mt-1">
                                                <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${statusMap[selectedTask.task_status]?.className || statusMap[0].className}`}>
                                                    {statusMap[selectedTask.task_status]?.label || statusMap[0].label}
                                                </span>
                                            </div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">任务类型</div>
                                            <div className="mt-1 text-slate-700">{selectedTask.task_type || '-'}</div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">所属系统</div>
                                            <div className="mt-1 text-slate-700">{selectedTask.task_system || '-'}</div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">任务主题</div>
                                            <div className="mt-1 text-slate-700">{selectedTask.theme || '-'}</div>
                                        </div>
                                        <div className={`col-span-2 ${detailItemClass}`}>
                                            <div className="text-xs text-slate-400">任务备注</div>
                                            <div className="mt-1 whitespace-pre-wrap text-slate-700">{selectedTask.remark || '-'}</div>
                                        </div>
                                    </div>
                                </section>

                                <section className={detailSectionClass}>
                                    <div className="border-b border-slate-100 px-5 py-4">
                                        <div className="flex items-center gap-2 text-base font-semibold text-slate-900">
                                            <Clock3 size={17} className="text-red-500" />
                                            运行节奏
                                        </div>
                                        <div className="mt-1 text-sm text-slate-500">调度表达式、数据偏移、失败轮询和依赖概览。</div>
                                    </div>
                                    <div className="grid grid-cols-2 gap-3 p-5">
                                        <div className={`col-span-2 ${detailItemClass}`}>
                                            <div className="text-xs text-slate-400">Cron 表达式</div>
                                            <div className="mt-1 break-all font-mono text-xs text-slate-700">{selectedTask.task_cron || '-'}</div>
                                            <div className="mt-2 text-xs text-slate-500">
                                                {describeCron(selectedTask.task_cron, selectedTask.offset ?? 0)}
                                            </div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">数据偏移</div>
                                            <div className="mt-1 text-slate-700">{selectedTask.offset ?? 0}</div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">失败轮询间隔</div>
                                            <div className="mt-1 text-slate-700">{selectedTask.period ? `${selectedTask.period} ms` : '-'}</div>
                                        </div>
                                        <div className={`col-span-2 ${detailItemClass}`}>
                                            <div className="text-xs text-slate-400">依赖任务概览</div>
                                            <div className="mt-1 text-slate-700">{selectedTaskDependencySummary}</div>
                                        </div>
                                    </div>
                                </section>

                                <section className={detailSectionClass}>
                                    <div className="border-b border-slate-100 px-5 py-4">
                                        <div className="flex items-center gap-2 text-base font-semibold text-slate-900">
                                            <Settings2 size={17} className="text-blue-500" />
                                            执行资源
                                        </div>
                                        <div className="mt-1 text-sm text-slate-500">脚本内容和数据源绑定信息。</div>
                                    </div>
                                    <div className="space-y-3 p-5">
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">数据源</div>
                                            <div className="mt-1 text-slate-700">{selectedTask.datasource_name || '-'}</div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">执行脚本</div>
                                            {selectedTask.script ? (
                                                detailScriptEditorReady ? (
                                                    <div className="mt-2 overflow-hidden rounded-xl border border-slate-200">
                                                        <LazyMonacoEditor
                                                            loadingFallback={
                                                                <div className="mt-2 flex h-[220px] items-center justify-center rounded-xl border border-dashed border-slate-200 bg-white text-sm text-slate-400">
                                                                    脚本内容加载中...
                                                                </div>
                                                            }
                                                            height="220px"
                                                            language={editorLanguageMap[selectedTask.task_type || 'SHELL'] || 'shell'}
                                                            value={selectedTask.script}
                                                            theme="vs-dark"
                                                            options={{
                                                                readOnly: true,
                                                                minimap: { enabled: false },
                                                                scrollBeyondLastLine: false,
                                                                lineNumbers: 'on',
                                                                folding: true,
                                                                fontSize: 12,
                                                                wordWrap: 'on',
                                                                padding: { top: 10, bottom: 10 },
                                                            }}
                                                        />
                                                    </div>
                                                ) : (
                                                    <div className="mt-2 flex h-[220px] items-center justify-center rounded-xl border border-dashed border-slate-200 bg-white text-sm text-slate-400">
                                                        脚本内容加载中...
                                                    </div>
                                                )
                                            ) : (
                                                <div className="mt-2 text-sm text-slate-500">暂无脚本内容</div>
                                            )}
                                        </div>
                                    </div>
                                </section>

                                <section className={detailSectionClass}>
                                    <div className="border-b border-slate-100 px-5 py-4">
                                        <div className="flex items-center gap-2 text-base font-semibold text-slate-900">
                                            <Calendar size={17} className="text-emerald-500" />
                                            通知与托底
                                        </div>
                                        <div className="mt-1 text-sm text-slate-500">通知人、创建更新时间和补充说明。</div>
                                    </div>
                                    <div className="space-y-3 p-5">
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">完成时通知</div>
                                            <div className="mt-1 break-all text-slate-700">{selectedTask.notification_completed || '-'}</div>
                                        </div>
                                        <div className={detailItemClass}>
                                            <div className="text-xs text-slate-400">失败时通知</div>
                                            <div className="mt-1 break-all text-slate-700">{selectedTask.notification_failed || '-'}</div>
                                        </div>
                                        <div className="grid grid-cols-2 gap-3">
                                            <div className={detailItemClass}>
                                                <div className="text-xs text-slate-400">创建时间</div>
                                                <div className="mt-1 font-mono text-xs text-slate-700">
                                                    {dayjs(selectedTask.create_time).format('YYYY-MM-DD HH:mm:ss')}
                                                </div>
                                            </div>
                                            <div className={detailItemClass}>
                                                <div className="text-xs text-slate-400">更新时间</div>
                                                <div className="mt-1 font-mono text-xs text-slate-700">
                                                    {dayjs(selectedTask.update_time).format('YYYY-MM-DD HH:mm:ss')}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </section>
                            </>
                        ) : (
                            <section className={detailSectionClass}>
                                <div className="flex items-center justify-between gap-3 border-b border-slate-100 px-5 py-4">
                                    <div>
                                        <div className="text-base font-semibold text-slate-900">依赖任务</div>
                                        <div className="mt-1 text-sm text-slate-500">只读查看当前任务的前置依赖链路。</div>
                                    </div>
                                    <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
                                        {selectedTaskDependencies.length} 项
                                    </span>
                                </div>
                                <div className="divide-y divide-slate-100">
                                    {selectedTaskDependencies.length === 0 ? (
                                        <div className="px-5 py-12 text-center text-sm text-slate-500">
                                            暂无依赖任务
                                        </div>
                                    ) : (
                                        selectedTaskDependencies.map(task => {
                                            const mappedStatus = statusMap[task.task_status] || statusMap[0];
                                            return (
                                                <div key={task.id} className="px-5 py-4">
                                                    <div className="flex items-start justify-between gap-3">
                                                        <div className="min-w-0 truncate text-sm font-semibold leading-6 text-slate-800" title={task.task_name}>
                                                            {task.task_name}
                                                        </div>
                                                        <span className={`shrink-0 rounded-full border px-2 py-1 text-[11px] font-semibold leading-none ${mappedStatus.className}`}>
                                                            {mappedStatus.label}
                                                        </span>
                                                    </div>
                                                    <div className="mt-2 flex flex-wrap items-center gap-1.5">
                                                        <span className={`${detailMetaBadgeClass} max-w-none font-mono text-slate-500`}>
                                                            #{task.id}
                                                        </span>
                                                        <span className={detailMetaBadgeClass} title={task.task_system || '-'}>
                                                            <span className="mr-1 text-slate-400">系统</span>
                                                            <span className="truncate">{task.task_system || '-'}</span>
                                                        </span>
                                                        <span className={detailMetaBadgeClass} title={task.theme || '-'}>
                                                            <span className="mr-1 text-slate-400">主题</span>
                                                            <span className="truncate">{task.theme || '-'}</span>
                                                        </span>
                                                        <span className={detailMetaBadgeClass} title={task.task_type || '-'}>
                                                            <span className="mr-1 text-slate-400">类型</span>
                                                            <span className="truncate">{task.task_type || '-'}</span>
                                                        </span>
                                                    </div>
                                                </div>
                                            );
                                        })
                                    )}
                                </div>
                            </section>
                        )}
                    </div>
                )}
            </Drawer>
        </>
    );
};

export default TaskManagement;
