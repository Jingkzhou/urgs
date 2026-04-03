import React, { useEffect, useMemo, useState } from 'react';
import { AutoComplete, Checkbox, DatePicker, Drawer, Dropdown, Form, Input, InputNumber, Modal, Popover, Select, Tag, message } from 'antd';
import type { MenuProps } from 'antd';
import { Calendar, ChevronDown, Clock3, FileCog, FileText, MoreHorizontal, PauseCircle, Play, PlayCircle, Plus, Search, Settings2, Trash2 } from 'lucide-react';
import dayjs from 'dayjs';
import zhCN from 'antd/es/date-picker/locale/zh_CN';
import Editor from '@monaco-editor/react';
import { QuartzTask } from './mockData';
import CronPicker from '../schedule/forms/components/CronPicker';
import { getDatasourceConfig } from '@/api/ops';

const { TextArea } = Input;

interface TaskManagementProps {
    tasks: QuartzTask[];
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
const actionButtonClass = 'inline-flex items-center gap-1 rounded-lg border px-3 py-1.5 text-xs font-medium transition';
const enabledActionClass = 'border-slate-200 text-slate-600 hover:bg-slate-50';
const primaryActionClass = 'border-slate-200 bg-white text-slate-700 shadow-sm hover:-translate-y-0.5 hover:shadow-md';
const modalCardClass = 'rounded-2xl border border-slate-200 bg-white shadow-sm';

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

const compactValue = (value?: string | number | null, fallback: string = '待补充') => {
    if (value === undefined || value === null) return fallback;
    const normalized = String(value).trim();
    return normalized === '' ? fallback : normalized;
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

const summarizeScript = (script?: string | null, taskType?: string | null) => {
    if (!script || script.trim() === '') {
        return taskType === 'SQL' ? '待编写 SQL 脚本' : '待编写 Shell 脚本';
    }

    const firstMeaningfulLine = script
        .split('\n')
        .map(line => line.trim())
        .find(line => line.length > 0);

    if (!firstMeaningfulLine) {
        return taskType === 'SQL' ? '待编写 SQL 脚本' : '待编写 Shell 脚本';
    }

    return firstMeaningfulLine.length > 56 ? `${firstMeaningfulLine.slice(0, 56)}...` : firstMeaningfulLine;
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

const TaskManagement: React.FC<TaskManagementProps> = ({ tasks, onViewExecutionLog }) => {
    const [taskList, setTaskList] = useState<QuartzTask[]>(tasks);
    const [form] = Form.useForm<TaskFormValues>();
    const watchedFormValues = Form.useWatch([], form) as Partial<TaskFormValues> | undefined;
    const [keyword, setKeyword] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [typeFilter, setTypeFilter] = useState<string>('');
    const [systemFilter, setSystemFilter] = useState<string>('');
    const [themeFilter, setThemeFilter] = useState<string>('');
    const [selectedTask, setSelectedTask] = useState<QuartzTask | null>(null);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingTask, setEditingTask] = useState<QuartzTask | null>(null);
    const [startTaskModalVisible, setStartTaskModalVisible] = useState(false);
    const [pendingStartTask, setPendingStartTask] = useState<QuartzTask | null>(null);
    const [startDataDate, setStartDataDate] = useState(dayjs().format('YYYY-MM-DD'));
    const [dataSources, setDataSources] = useState<DataSourceOption[]>([]);
    const [dataSourceLoading, setDataSourceLoading] = useState(false);
    const [dependencySelectorOpen, setDependencySelectorOpen] = useState(false);
    const [dependencyKeyword, setDependencyKeyword] = useState('');
    const [dependencySystemFilter, setDependencySystemFilter] = useState<string>('');
    const [dependencyTypeFilter, setDependencyTypeFilter] = useState<string>('');

    const taskTypes = useMemo(() => [...supportedTaskTypes], []);
    const systems = useMemo(
        () => Array.from(new Set(taskList.map(task => task.task_system).filter(Boolean))) as string[],
        [taskList]
    );
    const themes = useMemo(
        () => Array.from(new Set(taskList.map(task => task.theme).filter(Boolean))) as string[],
        [taskList]
    );

    useEffect(() => {
        let mounted = true;

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

        fetchDataSources();

        return () => {
            mounted = false;
        };
    }, []);

    const filteredTasks = useMemo(() => {
        return taskList.filter(task => {
            const matchesKeyword = !keyword || [
                task.task_name,
                task.remark,
            ].some(value => value?.toLowerCase().includes(keyword.toLowerCase()));
            const matchesStatus = statusFilter === '' || String(task.task_status) === statusFilter;
            const matchesType = !typeFilter || task.task_type === typeFilter;
            const matchesSystem = !systemFilter || task.task_system === systemFilter;
            const matchesTheme = !themeFilter || task.theme === themeFilter;

            return matchesKeyword && matchesStatus && matchesType && matchesSystem && matchesTheme;
        });
    }, [keyword, statusFilter, systemFilter, taskList, themeFilter, typeFilter]);

    const nextTaskId = useMemo(() => {
        return taskList.reduce((max, task) => Math.max(max, task.id), 0) + 1;
    }, [taskList]);

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

    const selectedDependencyIds = useMemo(() => {
        const raw = watchedFormValues?.depend_id;
        if (!raw) return [] as string[];
        return raw
            .split(',')
            .map(item => item.trim())
            .filter(Boolean);
    }, [watchedFormValues?.depend_id]);

    const availableDependencyTasks = useMemo(() => {
        return taskList.filter(task => task.id !== editingTask?.id);
    }, [taskList, editingTask?.id]);

    const filteredDependencyTasks = useMemo(() => {
        return availableDependencyTasks.filter(task => {
            const matchesKeyword = !dependencyKeyword || [
                task.task_name,
                task.task_system,
                task.theme,
                task.remark,
            ].some(value => value?.toLowerCase().includes(dependencyKeyword.toLowerCase()));
            const matchesSystem = dependencySystemFilter === '' || task.task_system === dependencySystemFilter;
            const matchesType = dependencyTypeFilter === '' || task.task_type === dependencyTypeFilter;
            return matchesKeyword && matchesSystem && matchesType;
        });
    }, [availableDependencyTasks, dependencyKeyword, dependencySystemFilter, dependencyTypeFilter]);

    const updateTask = (taskId: number, updater: (task: QuartzTask) => QuartzTask) => {
        setTaskList(prev => prev.map(task => task.id === taskId ? updater(task) : task));
        setSelectedTask(prev => prev && prev.id === taskId ? updater(prev) : prev);
    };

    const openTaskModal = (task?: QuartzTask | null) => {
        setEditingTask(task || null);
        setDependencySelectorOpen(false);
        setDependencyKeyword('');
        setDependencySystemFilter('');
        setDependencyTypeFilter('');
        form.resetFields();
        form.setFieldsValue(getInitialFormValues(task));
        setModalVisible(true);
    };

    const closeTaskModal = () => {
        setModalVisible(false);
        setEditingTask(null);
        setDependencySelectorOpen(false);
        setDependencyKeyword('');
        setDependencySystemFilter('');
        setDependencyTypeFilter('');
        form.resetFields();
    };

    const updateDependencySelection = (ids: string[]) => {
        form.setFieldValue('depend_id', ids.length > 0 ? ids.join(',') : undefined);
    };

    const toggleDependencyTask = (taskId: string, checked: boolean) => {
        const nextIds = checked
            ? Array.from(new Set([...selectedDependencyIds, taskId]))
            : selectedDependencyIds.filter(id => id !== taskId);
        updateDependencySelection(nextIds);
    };

    const handleSaveTask = async () => {
        try {
            const values = await form.validateFields();
            const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
            const selectedDataSource = datasourceOptions.find(item => item.id === values.datasource_id);
            const payload: QuartzTask = {
                id: editingTask?.id ?? nextTaskId,
                task_name: values.task_name.trim(),
                task_bean: editingTask?.task_bean ?? null,
                task_params: editingTask?.task_params ?? null,
                task_cron: values.task_cron.trim(),
                task_status: values.task_status,
                remark: emptyToNull(values.remark),
                update_time: now,
                create_time: editingTask?.create_time ?? now,
                task_type: emptyToNull(values.task_type || undefined),
                url: editingTask?.url ?? null,
                script: normalizeScript(values.script),
                depend_id: emptyToNull(values.depend_id),
                username: editingTask?.username ?? null,
                password: editingTask?.password ?? null,
                driver: editingTask?.driver ?? null,
                datasource_id: values.datasource_id ?? null,
                datasource_name: selectedDataSource?.name ?? editingTask?.datasource_name ?? null,
                period: values.period ?? null,
                task_system: emptyToNull(values.task_system || undefined),
                theme: emptyToNull(values.theme || undefined),
                offset: values.offset ?? null,
                data_date: editingTask?.data_date ?? null,
                job_key: editingTask?.job_key ?? null,
                notification_completed: emptyToNull(values.notification_completed),
                notification_failed: emptyToNull(values.notification_failed),
            };

            if (editingTask) {
                setTaskList(prev => prev.map(task => task.id === editingTask.id ? payload : task));
                setSelectedTask(prev => prev?.id === editingTask.id ? payload : prev);
                message.success(`已更新任务 ${payload.task_name}`);
            } else {
                setTaskList(prev => [payload, ...prev]);
                message.success(`已创建任务 ${payload.task_name}`);
            }

            closeTaskModal();
        } catch (error: any) {
            if (error?.errorFields) {
                const labels = error.errorFields
                    .map((field: any) => field.errors?.[0])
                    .filter(Boolean)
                    .join('、');
                message.error(labels ? `请检查表单：${labels}` : '请完善表单信息');
            }
        }
    };

    const handleEditTask = (task: QuartzTask) => {
        openTaskModal(task);
    };

    const handleDeleteTask = (task: QuartzTask) => {
        setTaskList(prev => prev.filter(item => item.id !== task.id));
        setSelectedTask(prev => prev?.id === task.id ? null : prev);
        message.success(`已删除任务 ${task.task_name}`);
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

        message.success(`前端稿占位：已触发任务 ${pendingStartTask.task_name} 在 ${startDataDate} 立即开始`);
        setStartTaskModalVisible(false);
        setPendingStartTask(null);
    };

    const handlePauseTask = (task: QuartzTask) => {
        if (task.task_status === 1) return;
        updateTask(task.id, current => ({
            ...current,
            task_status: 1,
            update_time: dayjs().format('YYYY-MM-DD HH:mm:ss'),
        }));
        message.success(`已暂停任务 ${task.task_name}`);
    };

    const handleResumeTask = (task: QuartzTask) => {
        if (task.task_status === 0) return;
        updateTask(task.id, current => ({
            ...current,
            task_status: 0,
            update_time: dayjs().format('YYYY-MM-DD HH:mm:ss'),
        }));
        message.success(`已恢复任务 ${task.task_name}`);
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

    const portrait = useMemo(() => {
        const current = watchedFormValues || {};
        const currentDataSource = datasourceOptions.find(item => item.id === current.datasource_id);
        const resolvedTaskType = current.task_type || editingTask?.task_type || 'SHELL';
        const executionSegments = [
            `脚本 ${summarizeScript(current.script ?? editingTask?.script, resolvedTaskType)}`,
            currentDataSource?.name || editingTask?.datasource_name ? `数据源 ${currentDataSource?.name || editingTask?.datasource_name}` : null,
        ].filter(Boolean);

        return {
            taskName: compactValue(current.task_name, editingTask ? editingTask.task_name : '未命名任务'),
            system: compactValue(current.task_system, '未绑定系统'),
            theme: compactValue(current.theme, '未设置主题'),
            taskType: compactValue(current.task_type, '未定义类型'),
            schedule: describeCron(current.task_cron || editingTask?.task_cron, current.offset ?? editingTask?.offset ?? 0),
            dependency: current.depend_id ? `依赖 ${current.depend_id}` : '独立执行',
            execution: executionSegments.length > 0 ? executionSegments.join(' · ') : '待配置脚本或数据源',
            notify: current.notification_failed || current.notification_completed ? '已配置通知策略' : '暂未配置通知',
        };
    }, [watchedFormValues, editingTask, datasourceOptions]);

    const dependencySummary = useMemo(() => {
        if (selectedDependencyIds.length === 0) {
            return '请选择依赖任务';
        }

        const labels = selectedDependencyIds
            .map(id => availableDependencyTasks.find(item => String(item.id) === id)?.task_name || `任务 ${id}`)
            .slice(0, 2);

        if (selectedDependencyIds.length <= 2) {
            return labels.join('，');
        }

        return `${labels.join('，')} 等 ${selectedDependencyIds.length} 项`;
    }, [availableDependencyTasks, selectedDependencyIds]);

    const dependencySelectorContent = (
        <div className="w-[760px] max-w-[calc(100vw-120px)] space-y-3">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <div className="text-sm font-semibold text-slate-800">依赖任务列表</div>
                    <div className="mt-1 text-xs text-slate-500">按名称、系统、类型筛选后勾选前置任务。</div>
                </div>
                <div className="flex items-center gap-2">
                    <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700">
                        已选 {selectedDependencyIds.length} 项
                    </span>
                    {selectedDependencyIds.length > 0 && (
                        <button
                            type="button"
                            onClick={() => updateDependencySelection([])}
                            className="rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-semibold text-slate-500 transition hover:bg-slate-50"
                        >
                            清空
                        </button>
                    )}
                </div>
            </div>

            <div className="grid grid-cols-1 gap-3 xl:grid-cols-[1.2fr_0.8fr_0.8fr]">
                <label className="relative">
                    <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                        value={dependencyKeyword}
                        onChange={(event) => setDependencyKeyword(event.target.value)}
                        placeholder="搜索任务名称 / 系统 / 主题"
                        className="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-9 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300"
                    />
                </label>
                <select
                    value={dependencySystemFilter}
                    onChange={(event) => setDependencySystemFilter(event.target.value)}
                    className="rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300"
                >
                    <option value="">全部系统</option>
                    {systems.map(system => (
                        <option key={system} value={system}>{system}</option>
                    ))}
                </select>
                <select
                    value={dependencyTypeFilter}
                    onChange={(event) => setDependencyTypeFilter(event.target.value)}
                    className="rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300"
                >
                    <option value="">全部类型</option>
                    {taskTypes.map(type => (
                        <option key={type} value={type}>{type}</option>
                    ))}
                </select>
            </div>

            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
                <div className="grid grid-cols-[52px_minmax(0,1.3fr)_minmax(0,0.9fr)_110px_180px] items-center gap-3 border-b border-slate-100 bg-slate-50 px-4 py-3 text-[11px] font-bold uppercase tracking-[0.18em] text-slate-400">
                    <span>勾选</span>
                    <span>任务名称</span>
                    <span>系统 / 主题</span>
                    <span>状态</span>
                    <span>Cron</span>
                </div>
                <div className="max-h-72 overflow-y-auto divide-y divide-slate-100">
                    {filteredDependencyTasks.length === 0 ? (
                        <div className="px-4 py-10 text-center text-sm text-slate-500">
                            当前筛选条件下没有可选任务
                        </div>
                    ) : filteredDependencyTasks.map(task => {
                        const taskId = String(task.id);
                        const checked = selectedDependencyIds.includes(taskId);
                        const mappedStatus = statusMap[task.task_status] || statusMap[0];

                        return (
                            <label
                                key={task.id}
                                className={`grid cursor-pointer grid-cols-[52px_minmax(0,1.3fr)_minmax(0,0.9fr)_110px_180px] items-center gap-3 px-4 py-3 transition ${checked ? 'bg-red-50/50' : 'hover:bg-slate-50'}`}
                            >
                                <Checkbox
                                    checked={checked}
                                    onChange={(event) => toggleDependencyTask(taskId, event.target.checked)}
                                />
                                <div className="min-w-0">
                                    <div className="truncate text-sm font-semibold text-slate-800">{task.task_name}</div>
                                    <div className="mt-1 text-xs text-slate-400">#{task.id}</div>
                                </div>
                                <div className="min-w-0">
                                    <div className="truncate text-sm text-slate-700">{task.task_system || '-'}</div>
                                    <div className="mt-1 truncate text-xs text-slate-400">{task.theme || '未设置主题'}</div>
                                </div>
                                <div>
                                    <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${mappedStatus.className}`}>
                                        {mappedStatus.label}
                                    </span>
                                </div>
                                <div className="truncate font-mono text-xs text-slate-500">
                                    {task.task_cron}
                                </div>
                            </label>
                        );
                    })}
                </div>
            </div>
        </div>
    );

    return (
        <>
            <div className="space-y-4">
                <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
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
                                共 {filteredTasks.length} 条任务
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-3 py-1.5 text-emerald-700">
                                正常 {filteredTasks.filter(task => task.task_status === 0).length}
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-3 py-1.5 text-amber-700">
                                暂停 {filteredTasks.filter(task => task.task_status === 1).length}
                            </span>
                            <button
                                onClick={handleCreateTask}
                                className="inline-flex items-center gap-1.5 rounded-xl bg-red-600 px-3.5 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-red-700 hover:-translate-y-0.5 hover:shadow-md"
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

                <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
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
                                {filteredTasks.length === 0 ? (
                                    <tr>
                                        <td colSpan={9} className="px-6 py-16 text-center text-slate-500">
                                            未找到符合条件的监管任务。
                                        </td>
                                    </tr>
                                ) : filteredTasks.map(task => {
                                    const mappedStatus = statusMap[task.task_status] || statusMap[0];

                                    return (
                                        <tr key={task.id} className="hover:bg-red-50/30 transition-colors">
                                            <td className="px-4 py-4">
                                                <button
                                                    onClick={() => setSelectedTask(task)}
                                                    className="space-y-1 text-left group"
                                                >
                                                    <div className="font-semibold text-slate-800 group-hover:text-red-600 transition-colors">
                                                        {task.task_name}
                                                    </div>
                                                    <div className="text-xs text-slate-500 font-mono">#{task.id}</div>
                                                </button>
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
                                                        onClick={() => handleEditTask(task)}
                                                        className={`${actionButtonClass} ${primaryActionClass} hover:border-blue-200 hover:bg-blue-50 hover:text-blue-600`}
                                                    >
                                                        <FileCog size={14} />
                                                        编辑
                                                    </button>
                                                    {task.task_status === 0 ? (
                                                        <button
                                                            onClick={() => handlePauseTask(task)}
                                                            className={`${actionButtonClass} ${primaryActionClass} hover:border-amber-200 hover:bg-amber-50 hover:text-amber-700`}
                                                        >
                                                            <PauseCircle size={14} />
                                                            暂停任务
                                                        </button>
                                                    ) : (
                                                        <button
                                                            onClick={() => handleResumeTask(task)}
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
                                                            onClick={(event) => event.preventDefault()}
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

            <Modal
                title={null}
                open={modalVisible}
                width={1120}
                onOk={handleSaveTask}
                onCancel={closeTaskModal}
                destroyOnHidden
                styles={{ body: { padding: 0 }, footer: { padding: '18px 24px' } }}
                footer={
                    <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                        <div className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-left">
                            <div className="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">
                                当前状态
                            </div>
                            <div className="mt-1 text-sm font-semibold text-slate-700">
                                {editingTask ? '编辑已有监管任务' : '待创建新的监管任务'}
                            </div>
                            <div className="mt-1 text-xs text-slate-500">
                                {portrait.schedule}
                            </div>
                        </div>
                        <div className="flex items-center justify-end gap-3">
                            <button
                                onClick={closeTaskModal}
                                className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
                            >
                                取消
                            </button>
                            <button
                                onClick={handleSaveTask}
                                className="rounded-xl bg-red-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-red-700 hover:shadow-md"
                            >
                                {editingTask ? '保存修改' : '创建任务'}
                            </button>
                        </div>
                    </div>
                }
            >
                <Form
                    form={form}
                    layout="vertical"
                    initialValues={getInitialFormValues(editingTask)}
                    className="p-6"
                >
                    <div className="space-y-6">
                        <div className="overflow-hidden rounded-[28px] border border-slate-200 bg-[radial-gradient(circle_at_top_left,_rgba(239,68,68,0.18),_transparent_30%),linear-gradient(135deg,#fff7f7_0%,#ffffff_48%,#f8fafc_100%)] shadow-sm">
                            <div className="grid gap-6 px-6 py-6 lg:grid-cols-[1.3fr_0.9fr]">
                                <div>
                                    <div className="inline-flex items-center gap-2 rounded-full bg-white/80 px-3 py-1 text-[11px] font-bold uppercase tracking-[0.2em] text-red-500 shadow-sm">
                                        <FileCog size={14} />
                                        Task Portrait
                                    </div>
                                    <div className="mt-4 text-2xl font-bold text-slate-900">
                                        {editingTask ? '编辑监管任务' : '新建监管任务'}
                                    </div>
                                    <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
                                        不是把字段填满，而是先把任务画像搭出来。先明确任务属于哪个系统、承担什么主题、按什么节奏触发，再补齐执行和通知细节。
                                    </p>
                                    <div className="mt-5 flex flex-wrap gap-2">
                                        <span className="rounded-full bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm">
                                            {portrait.system}
                                        </span>
                                        <span className="rounded-full bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm">
                                            {portrait.theme}
                                        </span>
                                        <span className="rounded-full bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 shadow-sm">
                                            {portrait.taskType}
                                        </span>
                                    </div>
                                </div>
                                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
                                    <div className="rounded-2xl border border-white/70 bg-white/90 p-4 shadow-sm backdrop-blur">
                                        <div className="text-[11px] font-bold uppercase tracking-[0.2em] text-slate-400">任务画像</div>
                                        <div className="mt-2 text-lg font-semibold text-slate-800">{portrait.taskName}</div>
                                        <div className="mt-2 text-sm text-slate-600">{portrait.schedule}</div>
                                    </div>
                                    <div className="rounded-2xl border border-white/70 bg-white/90 p-4 shadow-sm backdrop-blur">
                                        <div className="text-[11px] font-bold uppercase tracking-[0.2em] text-slate-400">运行保障</div>
                                        <div className="mt-2 text-sm text-slate-700">{portrait.execution}</div>
                                        <div className="mt-1 text-sm text-slate-500">{portrait.dependency}</div>
                                        <div className="mt-1 text-sm text-slate-500">{portrait.notify}</div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 gap-6 xl:grid-cols-[1.08fr_0.92fr]">
                            <div className="space-y-6">
                                <section className={modalCardClass}>
                                    <div className="border-b border-slate-100 px-5 py-4">
                                        <div className="text-base font-semibold text-slate-900">任务核心</div>
                                        <div className="mt-1 text-sm text-slate-500">
                                            先定义任务是什么，为谁服务，属于哪个系统和主题。
                                        </div>
                                    </div>
                                    <div className="grid grid-cols-1 gap-4 p-5 md:grid-cols-2">
                                        <Form.Item
                                            name="task_name"
                                            label="任务名称"
                                            rules={[{ required: true, message: '请填写任务名称' }]}
                                            className="md:col-span-2"
                                        >
                                            <Input
                                                placeholder="例如：监管报送日切任务"
                                                className="h-11 rounded-xl text-base"
                                            />
                                        </Form.Item>
                                        <Form.Item
                                            name="task_type"
                                            label="任务类型"
                                            rules={[{ required: true, message: '请选择任务类型' }]}
                                        >
                                            <Select
                                                placeholder="请选择任务类型"
                                                options={taskTypes.map(type => ({ label: type, value: type }))}
                                            />
                                        </Form.Item>
                                        <Form.Item
                                            name="task_status"
                                            label="初始状态"
                                            rules={[{ required: true, message: '请选择任务状态' }]}
                                        >
                                            <Select
                                                options={[
                                                    { label: '正常', value: 0 },
                                                    { label: '暂停', value: 1 },
                                                ]}
                                            />
                                        </Form.Item>
                                        <Form.Item name="task_system" label="所属系统">
                                            <AutoComplete
                                                options={systems.map(system => ({ value: system }))}
                                                placeholder="例如：监管报送平台"
                                                filterOption={(inputValue, option) =>
                                                    (option?.value ?? '').toUpperCase().includes(inputValue.toUpperCase())
                                                }
                                            />
                                        </Form.Item>
                                        <Form.Item name="theme" label="任务主题">
                                            <AutoComplete
                                                options={themes.map(theme => ({ value: theme }))}
                                                placeholder="例如：日报 / 月报 / 回执"
                                                filterOption={(inputValue, option) =>
                                                    (option?.value ?? '').toUpperCase().includes(inputValue.toUpperCase())
                                                }
                                            />
                                        </Form.Item>
                                        <Form.Item name="remark" label="任务备注" className="md:col-span-2">
                                            <TextArea
                                                rows={4}
                                                placeholder="用自然语言说明这个任务解决什么问题，什么时候需要关注它。"
                                            />
                                        </Form.Item>
                                    </div>
                                </section>

                                <section className={modalCardClass}>
                                    <div className="border-b border-slate-100 px-5 py-4">
                                        <div className="flex items-center gap-2 text-base font-semibold text-slate-900">
                                            <Clock3 size={17} className="text-red-500" />
                                            运行节奏
                                        </div>
                                        <div className="mt-1 text-sm text-slate-500">
                                            这里决定任务何时触发、是否依赖前置任务，以及失败后多久轮询。
                                        </div>
                                    </div>
                                    <div className="space-y-4 p-5">
                                        <div className="rounded-2xl border border-slate-200 bg-slate-50/70 p-4">
                                            <div className="mb-2 text-xs font-bold uppercase tracking-[0.18em] text-slate-400">
                                                调度面板
                                            </div>
                                            <Form.Item label="Cron 表达式" required className="mb-0">
                                                <Form.Item
                                                    noStyle
                                                    shouldUpdate={(prevValues, currentValues) =>
                                                        prevValues.task_cron !== currentValues.task_cron || prevValues.offset !== currentValues.offset
                                                    }
                                                >
                                                    {() => (
                                                        <CronPicker
                                                            value={form.getFieldValue('task_cron') || '0 0 * * * ?'}
                                                            onChange={(value) => form.setFieldValue('task_cron', value)}
                                                            offset={form.getFieldValue('offset') ?? 0}
                                                            onOffsetChange={(value) => form.setFieldValue('offset', value)}
                                                        />
                                                    )}
                                                </Form.Item>
                                                <Form.Item
                                                    name="task_cron"
                                                    hidden
                                                    rules={[{ required: true, message: '请选择 Cron 表达式' }]}
                                                >
                                                    <Input />
                                                </Form.Item>
                                                <Form.Item name="offset" hidden>
                                                    <InputNumber />
                                                </Form.Item>
                                            </Form.Item>
                                        </div>
                                        <div className="grid grid-cols-1 gap-4 md:grid-cols-[1.3fr_0.7fr]">
                                            <Form.Item label="依赖任务" className="mb-0">
                                                <Popover
                                                    content={dependencySelectorContent}
                                                    trigger="click"
                                                    placement="bottomLeft"
                                                    open={dependencySelectorOpen}
                                                    onOpenChange={setDependencySelectorOpen}
                                                >
                                                    <button
                                                        type="button"
                                                        className="flex min-h-[46px] w-full items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-left transition hover:border-red-200 hover:bg-red-50/30"
                                                    >
                                                        <div className="min-w-0">
                                                            <div className={`truncate text-sm font-medium ${selectedDependencyIds.length > 0 ? 'text-slate-800' : 'text-slate-400'}`}>
                                                                {dependencySummary}
                                                            </div>
                                                            <div className="mt-1 text-xs text-slate-400">
                                                                {selectedDependencyIds.length > 0 ? `已关联 ${selectedDependencyIds.length} 个前置任务` : '点击选择前置任务'}
                                                            </div>
                                                        </div>
                                                        <ChevronDown
                                                            size={16}
                                                            className={`shrink-0 text-slate-400 transition-transform ${dependencySelectorOpen ? 'rotate-180' : ''}`}
                                                        />
                                                    </button>
                                                </Popover>
                                                <Form.Item name="depend_id" hidden>
                                                    <Input />
                                                </Form.Item>
                                            </Form.Item>
                                            <Form.Item name="period" label="失败轮询间隔">
                                                <InputNumber className="w-full" min={0} placeholder="例如：300000" />
                                            </Form.Item>
                                        </div>
                                    </div>
                                </section>
                            </div>

                            <div className="space-y-6">
                                <section className={modalCardClass}>
                                    <div className="border-b border-slate-100 px-5 py-4">
                                        <div className="flex items-center gap-2 text-base font-semibold text-slate-900">
                                            <Settings2 size={17} className="text-blue-500" />
                                            执行资源
                                        </div>
                                        <div className="mt-1 text-sm text-slate-500">
                                            任务真正运行依赖的脚本内容和系统管理中的数据源，在这里统一绑定。
                                        </div>
                                    </div>
                                    <div className="space-y-4 p-5">
                                        <Form.Item
                                            name="script"
                                            label="脚本"
                                            rules={[{ required: true, message: '请填写脚本内容' }]}
                                            getValueFromEvent={(value) => value ?? ''}
                                        >
                                            <Editor
                                                height="260px"
                                                language={editorLanguageMap[watchedFormValues?.task_type || editingTask?.task_type || 'SHELL'] || 'shell'}
                                                theme="vs"
                                                options={{
                                                    minimap: { enabled: false },
                                                    scrollBeyondLastLine: false,
                                                    automaticLayout: true,
                                                    fontSize: 13,
                                                    wordWrap: 'on',
                                                    tabSize: 2,
                                                    padding: { top: 12, bottom: 12 },
                                                }}
                                            />
                                        </Form.Item>
                                        <Form.Item name="datasource_id" label="数据源">
                                            <Select
                                                showSearch
                                                allowClear
                                                loading={dataSourceLoading}
                                                placeholder="请选择系统管理中的数据源"
                                                optionFilterProp="label"
                                                options={datasourceOptions.map(item => ({
                                                    value: item.id,
                                                    label: item.name,
                                                    typeName: item.typeName,
                                                    typeCode: item.typeCode,
                                                    category: item.category,
                                                    connectionInfo: item.connectionInfo,
                                                    searchLabel: [item.name, item.typeName, item.category, item.typeCode, item.connectionInfo].filter(Boolean).join(' '),
                                                }))}
                                                filterOption={(input, option) =>
                                                    (option?.searchLabel ?? option?.label ?? '')
                                                        .toString()
                                                        .toLowerCase()
                                                        .includes(input.toLowerCase())
                                                }
                                                optionRender={(option) => (
                                                    <div className="flex items-center justify-between gap-3">
                                                        <div className="min-w-0">
                                                            <div className="truncate text-sm font-medium text-slate-800">{option.data.label}</div>
                                                            <div className="mt-1 truncate text-xs text-slate-400">
                                                                {option.data.connectionInfo || [option.data.typeName, option.data.category, option.data.typeCode].filter(Boolean).join(' · ') || '连接信息待补充'}
                                                            </div>
                                                        </div>
                                                    </div>
                                                )}
                                                notFoundContent={dataSourceLoading ? '数据源加载中...' : '系统管理中暂无可用数据源'}
                                            />
                                        </Form.Item>
                                    </div>
                                </section>

                                <section className={modalCardClass}>
                                    <div className="border-b border-slate-100 px-5 py-4">
                                        <div className="flex items-center gap-2 text-base font-semibold text-slate-900">
                                            <Calendar size={17} className="text-emerald-500" />
                                            通知与托底
                                        </div>
                                        <div className="mt-1 text-sm text-slate-500">
                                            任务跑完之后要通知谁，失败的时候要先叫醒谁，这里一次配好。
                                        </div>
                                    </div>
                                    <div className="space-y-4 p-5">
                                        <Form.Item name="notification_completed" label="完成时通知">
                                            <TextArea rows={3} placeholder="多个通知对象使用英文逗号分隔" />
                                        </Form.Item>
                                        <Form.Item name="notification_failed" label="失败时通知">
                                            <TextArea rows={3} placeholder="多个通知对象使用英文逗号分隔" />
                                        </Form.Item>
                                    </div>
                                </section>
                            </div>
                        </div>
                    </div>
                </Form>
            </Modal>

            <Drawer
                title={selectedTask ? `任务详情 · ${selectedTask.task_name}` : '任务详情'}
                placement="right"
                size={620}
                onClose={() => setSelectedTask(null)}
                open={!!selectedTask}
            >
                {selectedTask && (
                    <div className="space-y-5">
                        <div className="grid grid-cols-2 gap-3">
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">任务名称</div>
                                <div className="mt-1 font-semibold text-slate-800">{selectedTask.task_name}</div>
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">任务状态</div>
                                <div className="mt-1">
                                    <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${statusMap[selectedTask.task_status].className}`}>
                                        {statusMap[selectedTask.task_status].label}
                                    </span>
                                </div>
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">任务类型</div>
                                <div className="mt-1 text-slate-700">{selectedTask.task_type || '-'}</div>
                            </div>
                        </div>

                        <section>
                            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-800">
                                <Clock3 size={16} className="text-red-500" />
                                调度配置
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">Cron 表达式</div>
                                    <div className="mt-1 font-mono text-xs text-slate-700 break-all">{selectedTask.task_cron}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">轮询间隔</div>
                                    <div className="mt-1 text-slate-700">{selectedTask.period ? `${selectedTask.period} ms` : '-'}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">偏移量</div>
                                    <div className="mt-1 text-slate-700">{selectedTask.offset ?? '-'}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">依赖任务</div>
                                    <div className="mt-1 text-slate-700 break-all">{selectedTask.depend_id || '无'}</div>
                                </div>
                                <div className={`col-span-2 ${detailItemClass}`}>
                                    <div className="text-xs text-slate-400">执行脚本</div>
                                    {selectedTask.script ? (
                                        <div className="mt-2 overflow-hidden rounded-xl border border-slate-200">
                                            <Editor
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
                                        <div className="mt-2 text-sm text-slate-500">暂无脚本内容</div>
                                    )}
                                </div>
                            </div>
                        </section>

                        <section>
                            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-800">
                                <Settings2 size={16} className="text-blue-500" />
                                执行资源
                            </div>
                            <div className="space-y-3">
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">数据源</div>
                                    <div className="mt-1 text-slate-700">{selectedTask.datasource_name || '-'}</div>
                                </div>
                            </div>
                        </section>

                        <section>
                            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-800">
                                <Calendar size={16} className="text-emerald-500" />
                                业务属性
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">所属系统</div>
                                    <div className="mt-1 text-slate-700">{selectedTask.task_system || '-'}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">主题</div>
                                    <div className="mt-1 text-slate-700">{selectedTask.theme || '-'}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">创建时间</div>
                                    <div className="mt-1 font-mono text-xs text-slate-700">{dayjs(selectedTask.create_time).format('YYYY-MM-DD HH:mm:ss')}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">更新时间</div>
                                    <div className="mt-1 font-mono text-xs text-slate-700">{dayjs(selectedTask.update_time).format('YYYY-MM-DD HH:mm:ss')}</div>
                                </div>
                            </div>
                        </section>

                        <section>
                            <div className="mb-3 text-sm font-semibold text-slate-800">通知策略</div>
                            <div className="space-y-3">
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">完成时通知</div>
                                    <div className="mt-1 text-slate-700 break-all">{selectedTask.notification_completed || '-'}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">失败时通知</div>
                                    <div className="mt-1 text-slate-700 break-all">{selectedTask.notification_failed || '-'}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">备注</div>
                                    <div className="mt-1 text-slate-700 whitespace-pre-wrap">{selectedTask.remark || '-'}</div>
                                </div>
                            </div>
                        </section>
                    </div>
                )}
            </Drawer>
        </>
    );
};

export default TaskManagement;
