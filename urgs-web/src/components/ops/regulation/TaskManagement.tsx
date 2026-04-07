import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { DatePicker, Form, Modal, message } from 'antd';
import dayjs from 'dayjs';
import zhCN from 'antd/es/date-picker/locale/zh_CN';
import { Search, Settings2, Plus } from 'lucide-react';
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
    const [startTaskLoading, setStartTaskLoading] = useState(false);
    const [dataSources, setDataSources] = useState<DataSourceOption[]>([]);
    const [dataSourceLoading, setDataSourceLoading] = useState(false);
    const [regulationSystems, setRegulationSystems] = useState<SsoConfig[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);

    const taskTypes = useMemo(() => [...supportedTaskTypes], []);

    const systems = useMemo(() => {
        const systemNames = new Set<string>();
        regulationSystems.forEach(system => {
            if (system.name?.trim()) systemNames.add(system.name.trim());
        });
        taskList.forEach(task => {
            if (task.task_system?.trim()) systemNames.add(task.task_system.trim());
        });
        if (editingTask?.task_system?.trim()) systemNames.add(editingTask.task_system.trim());
        return Array.from(systemNames);
    }, [editingTask?.task_system, regulationSystems, taskList]);

    const themes = useMemo(() => {
        const themeNames = new Set<string>();
        taskList.forEach(task => {
            if (task.theme?.trim()) themeNames.add(task.theme.trim());
        });
        if (editingTask?.theme?.trim()) themeNames.add(editingTask.theme.trim());
        return Array.from(themeNames);
    }, [editingTask?.theme, taskList]);

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
            if (!response?.success) throw new Error(response?.msg || '任务查询失败');
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
        if (!selectedTask?.id) return;

        let mounted = true;
        const timer = window.setTimeout(() => {
            if (mounted) setDetailScriptEditorReady(true);
        }, 80);

        const loadSelectedTaskDependencies = async () => {
            try {
                const response = await queryQuartzTaskDependencies(selectedTask.id);
                if (!mounted) return;
                if (!response?.success) { setSelectedTaskDependencies([]); return; }
                setSelectedTaskDependencies((response.data || []).map(normalizeQuartzTask));
            } catch {
                if (mounted) setSelectedTaskDependencies([]);
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
        if (selectedTaskDependencies.length === 0) return '无前置依赖';
        const labels = selectedTaskDependencies.slice(0, 2).map(task => task.task_name || `任务 ${task.id}`);
        return selectedTaskDependencies.length > 2
            ? `${labels.join('，')} 等 ${selectedTaskDependencies.length} 项`
            : labels.join('，');
    }, [selectedTaskDependencies]);

    // ===== 事件处理 =====

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
                exePath: normalizeScript(values.script),
                dependId: emptyToNull(values.depend_id),
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
            await loadTasks(currentPage, pageSize);
            message.success(editingTask ? `已更新任务 ${values.task_name}` : `已创建任务 ${values.task_name}`);
            closeTaskModal();
        } catch (error: any) {
            if (error?.errorFields) {
                const labels = error.errorFields.map((field: any) => field.errors?.[0]).filter(Boolean).join('、');
                message.error(labels ? `请检查表单：${labels}` : '请完善表单信息');
                return;
            }
            message.error(error?.message || '保存任务失败');
        }
    };

    const handleDeleteTask = async (task: QuartzTask) => {
        try {
            const response = await deleteQuartzTask(task.id);
            if (!response?.success) throw new Error(response?.msg || '删除任务失败');
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
            message.success(`任务 ${pendingStartTask.task_name} 已触发执行`);
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
            if (!response?.success) throw new Error(response?.msg || '恢复任务失败');
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

    return (
        <>
            <div className="space-y-4">
                {/* 顶部标题 + 筛选栏 */}
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
                                onClick={() => openTaskModal(null)}
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

                {/* 任务列表表格 */}
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

            {/* 立即开始 Modal */}
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
                confirmLoading={startTaskLoading}
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

            {/* 任务编辑 Modal */}
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

            {/* 任务详情 Drawer */}
            <TaskDetailDrawer
                selectedTask={selectedTask}
                selectedTaskDetailTab={selectedTaskDetailTab}
                selectedTaskDependencies={selectedTaskDependencies}
                selectedTaskDependencySummary={selectedTaskDependencySummary}
                detailScriptEditorReady={detailScriptEditorReady}
                onClose={() => setSelectedTask(null)}
                onTabChange={setSelectedTaskDetailTab}
            />
        </>
    );
};

export default TaskManagement;
