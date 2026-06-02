import React, { useEffect, useMemo, useState } from 'react';
import { Form, Input, InputNumber, Modal, Select } from 'antd';
import { Calendar, Clock3, Plus, Settings2, Trash2, SlidersHorizontal, Sparkles, Terminal, Database, User, ArrowRight } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { QuartzTask } from './mockData';
import LazyMonacoEditor from './LazyMonacoEditor';
import CronPicker from './CronPicker';
import TaskDependencyPanel from './TaskDependencyPanel';
import { queryQuartzTaskDependencies, QuartzTaskApiModel } from '@/api/ops';

const { TextArea } = Input;

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
    data_depend_id?: string;
    control_depend_id?: string;
    period?: number | null;
    datasource_id?: number;
    script?: string;
    notification_completed?: string;
    notification_failed?: string;
    notification_completed_list?: Array<{ name: string; custid: string }>;
    notification_failed_list?: Array<{ name: string; custid: string }>;
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

interface TaskEditorModalProps {
    open: boolean;
    editingTask: QuartzTask | null;
    form: any;
    taskList: QuartzTask[];
    taskTypes: readonly string[];
    systems: string[];
    datasourceOptions: DataSourceOption[];
    dataSourceLoading: boolean;
    editorLanguageMap: Record<string, string>;
    getInitialFormValues: (task?: QuartzTask | null) => TaskFormValues;
    describeCron: (cron?: string, offset?: number | null) => string;
    onCancel: () => void;
    onSubmit: () => void;
}

const modalCardClass = 'relative overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-sm hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all duration-300';

const TaskEditorModal: React.FC<TaskEditorModalProps> = ({
    open,
    editingTask,
    form,
    taskList,
    taskTypes,
    systems,
    datasourceOptions,
    dataSourceLoading,
    editorLanguageMap,
    getInitialFormValues,
    describeCron,
    onCancel,
    onSubmit,
}) => {
    const [modalTab, setModalTab] = useState<'config' | 'dependency'>('config');
    const [dependencyTasks, setDependencyTasks] = useState<QuartzTask[]>([]);
    const [scriptEditorReady, setScriptEditorReady] = useState(false);
    const watchedTaskName = Form.useWatch('task_name', form) as string | undefined;
    const watchedTaskCron = Form.useWatch('task_cron', form) as string | undefined;
    const watchedOffset = Form.useWatch('offset', form) as number | null | undefined;
    const watchedDependId = Form.useWatch('depend_id', form) as string | undefined;
    const watchedDataDependId = Form.useWatch('data_depend_id', form) as string | undefined;
    const watchedControlDependId = Form.useWatch('control_depend_id', form) as string | undefined;
    const watchedTaskType = Form.useWatch('task_type', form) as string | undefined;
    const watchedScript = Form.useWatch('script', form) as string | undefined;

    useEffect(() => {
        setModalTab('config');
    }, [open, editingTask?.id]);

    useEffect(() => {
        if (!open || scriptEditorReady) {
            return;
        }

        const timer = window.setTimeout(() => {
            setScriptEditorReady(true);
        }, 60);

        return () => {
            window.clearTimeout(timer);
        };
    }, [open, scriptEditorReady]);

    useEffect(() => {
        let mounted = true;

        const loadDependencyTasks = async () => {
            if (!open || !editingTask?.id) {
                setDependencyTasks([]);
                return;
            }

            try {
                const [dataResponse, controlResponse] = await Promise.all([
                    queryQuartzTaskDependencies(editingTask.id, 'DATA'),
                    queryQuartzTaskDependencies(editingTask.id, 'CONTROL'),
                ]);
                if (!mounted) return;
                if (!dataResponse?.success && !controlResponse?.success) {
                    setDependencyTasks([]);
                    return;
                }
                const dependencyMap = new Map<number, QuartzTaskApiModel>();
                [...(dataResponse?.data || []), ...(controlResponse?.data || [])].forEach(item => {
                    if (item.id !== undefined && item.id !== null) {
                        dependencyMap.set(Number(item.id), item);
                    }
                });
                setDependencyTasks(Array.from(dependencyMap.values()).map((item: QuartzTaskApiModel) => {
                    const datasourceId = item.datasourceId === null || item.datasourceId === undefined
                        ? null
                        : Number(item.datasourceId);
                    return {
                        id: Number(item.id),
                        task_name: item.taskName || '',
                        task_bean: item.taskBean ?? null,
                        task_params: item.taskParams ?? null,
                        task_cron: item.taskCron || '',
                        task_status: Number(item.taskStatus ?? 0) as 0 | 1,
                        remark: item.remark ?? null,
                        update_time: item.updateTime || '',
                        create_time: item.createTime || '',
                        task_type: item.taskType === 2 ? 'SQL' : 'SHELL',
                        script: item.exePath ?? null,
                        depend_id: item.dependId ?? null,
                        datasource_id: Number.isFinite(datasourceId) ? datasourceId : null,
                        datasource_name: item.datasourceName ?? null,
                        period: item.period ?? null,
                        task_system: item.taskSystem ?? null,
                        theme: item.theme ?? null,
                        offset: item.offset ?? null,
                        data_date: item.dataDate ?? null,
                        job_key: item.jobKey ?? null,
                        notification_completed: item.notificationCompleted ?? null,
                        notification_failed: item.notificationFailed ?? null,
                    };
                }));
            } catch (error) {
                if (mounted) {
                    setDependencyTasks([]);
                }
            }
        };

        loadDependencyTasks();

        return () => {
            mounted = false;
        };
    }, [open, editingTask?.id]);

    const selectedDependencyIds = useMemo(() => {
        const raw = watchedDataDependId || watchedDependId;
        if (!raw) return [] as string[];
        return raw
            .split(',')
            .map(item => item.trim())
            .filter(Boolean);
    }, [watchedDataDependId, watchedDependId]);

    const selectedControlDependencyIds = useMemo(() => {
        const raw = watchedControlDependId;
        if (!raw) return [] as string[];
        return raw
            .split(',')
            .map(item => item.trim())
            .filter(Boolean);
    }, [watchedControlDependId]);

    const dependencyTaskNameMap = useMemo(() => {
        const taskNameMap = new Map<string, string>();
        taskList.forEach(task => {
            if (task.id === editingTask?.id) {
                return;
            }
            taskNameMap.set(String(task.id), task.task_name);
        });
        dependencyTasks.forEach(task => {
            taskNameMap.set(String(task.id), task.task_name);
        });
        return taskNameMap;
    }, [dependencyTasks, editingTask?.id, taskList]);

    const dependencySummary = useMemo(() => {
        if (selectedDependencyIds.length === 0) {
            return '暂无前置依赖任务';
        }

        const labels = selectedDependencyIds
            .map(id => dependencyTaskNameMap.get(id) || `任务 ${id}`)
            .slice(0, 2);

        if (selectedDependencyIds.length <= 2) {
            return labels.join('，');
        }

        return `${labels.join('，')} 等 ${selectedDependencyIds.length} 项`;
    }, [dependencyTaskNameMap, selectedDependencyIds]);

    const portrait = useMemo(() => {
        return {
            taskName: watchedTaskName?.trim() || editingTask?.task_name || '未命名监管任务',
            schedule: describeCron(
                watchedTaskCron || editingTask?.task_cron,
                watchedOffset ?? editingTask?.offset ?? 0
            ),
        };
    }, [describeCron, editingTask, watchedOffset, watchedTaskCron, watchedTaskName]);

    const updateDependencySelection = (ids: string[]) => {
        const value = ids.length > 0 ? ids.join(',') : undefined;
        form.setFieldValue('data_depend_id', value);
        form.setFieldValue('depend_id', value);
    };

    const updateControlDependencySelection = (ids: string[]) => {
        form.setFieldValue('control_depend_id', ids.length > 0 ? ids.join(',') : undefined);
    };

    return (
        <Modal
            title={null}
            open={open}
            width={1160}
            onOk={onSubmit}
            onCancel={onCancel}
            destroyOnHidden
            styles={{ body: { padding: 0 }, footer: { padding: '20px 28px', borderTop: '1px solid #f1f5f9' } }}
            className="premium-task-modal"
            footer={
                <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex items-center gap-3 rounded-2xl border border-slate-100 bg-slate-50/50 px-4 py-2.5 text-left">
                        <span className={`inline-flex h-2.5 w-2.5 rounded-full ${editingTask ? 'bg-blue-500 animate-pulse' : 'bg-emerald-500 animate-pulse'}`} />
                        <div>
                            <div className="text-xs font-bold uppercase tracking-[0.1em] text-slate-400">
                                监管任务配置状态
                            </div>
                            <div className="mt-0.5 text-sm font-semibold text-slate-700">
                                {editingTask ? `正在修改已存在的监管任务 (${editingTask.id})` : '正在配置全新监管任务数据'}
                            </div>
                        </div>
                    </div>
                    <div className="flex items-center justify-end gap-3">
                        <button
                            type="button"
                            onClick={onCancel}
                            className="rounded-xl border border-slate-200 bg-white px-5 py-2.5 text-sm font-semibold text-slate-600 transition-all duration-200 hover:bg-slate-50 active:scale-95"
                        >
                            取消
                        </button>
                        <button
                            type="button"
                            onClick={onSubmit}
                            className="rounded-xl bg-gradient-to-r from-red-600 to-red-700 px-6 py-2.5 text-sm font-semibold text-white shadow-md shadow-red-600/10 transition-all duration-200 hover:from-red-500 hover:to-red-600 hover:shadow-lg hover:shadow-red-500/20 active:scale-95"
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
                className="p-6 md:p-8"
            >
                <div className="space-y-6">
                    {/* Header Banner - Premium Gradient with Glassmorphism Accent */}
                    <div className="relative overflow-hidden rounded-2xl border border-slate-800 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-950 p-6 text-white shadow-xl shadow-slate-950/20">
                        {/* Gradient lights decoration */}
                        <div className="absolute -right-16 -top-16 h-36 w-36 rounded-full bg-red-500/15 blur-3xl" />
                        <div className="absolute -left-16 -bottom-16 h-36 w-36 rounded-full bg-blue-500/15 blur-3xl" />

                        <div className="relative flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                            <div className="flex items-center gap-4">
                                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-white/10 backdrop-blur-md border border-white/15 shadow-inner">
                                    <SlidersHorizontal className="h-6 w-6 text-red-400 animate-spin-slow" style={{ animationDuration: '8s' }} />
                                </div>
                                <div>
                                    <div className="flex flex-wrap items-center gap-2">
                                        <h2 className="text-lg font-bold tracking-wide text-white">
                                            {editingTask ? '编辑任务' : '新建任务'}
                                        </h2>
                                        <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-semibold backdrop-blur-md border ${
                                            editingTask
                                                ? 'bg-blue-500/10 border-blue-500/20 text-blue-300'
                                                : 'bg-emerald-500/10 border-emerald-500/20 text-emerald-300'
                                        }`}>
                                            <span className={`h-1.5 w-1.5 rounded-full ${editingTask ? 'bg-blue-400 animate-pulse' : 'bg-emerald-400 animate-pulse'}`} />
                                            {editingTask ? `TASK ID: ${editingTask.id}` : 'NEW MODE'}
                                        </span>
                                    </div>
                                    <p className="mt-1 text-sm text-slate-300 font-medium tracking-wide">
                                        {portrait.taskName}
                                    </p>
                                </div>
                            </div>

                            <div className="flex items-center gap-2 rounded-xl bg-white/5 backdrop-blur-sm border border-white/5 px-3.5 py-2 text-slate-200">
                                <Clock3 className="h-4 w-4 text-red-400" />
                                <span className="text-xs font-bold uppercase tracking-wider text-slate-400">
                                    运行频率:
                                </span>
                                <span className="text-xs font-semibold text-slate-200">
                                    {portrait.schedule || '暂无调度配置'}
                                </span>
                            </div>
                        </div>
                    </div>

                    <Form.Item name="depend_id" hidden>
                        <Input />
                    </Form.Item>
                    <Form.Item name="data_depend_id" hidden>
                        <Input />
                    </Form.Item>
                    <Form.Item name="control_depend_id" hidden>
                        <Input />
                    </Form.Item>

                    {/* Navigation Tab - Premium Capsule Segmented Control */}
                    <div className="relative rounded-2xl border border-slate-200/80 bg-slate-50/70 p-1.5">
                        <div className="relative flex gap-1">
                            <button
                                type="button"
                                onClick={() => setModalTab('config')}
                                className={`relative z-10 flex flex-1 items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-semibold transition-colors duration-300 ${
                                    modalTab === 'config' ? 'text-red-700' : 'text-slate-500 hover:text-slate-800'
                                }`}
                            >
                                {modalTab === 'config' && (
                                    <motion.div
                                        layoutId="activeTabIndicator"
                                        className="absolute inset-0 rounded-xl bg-white shadow-sm border border-slate-200/50"
                                        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                                    />
                                )}
                                <span className="relative z-20 flex items-center justify-center gap-2">
                                    <Settings2 className={`h-4 w-4 transition-colors ${modalTab === 'config' ? 'text-red-500' : 'text-slate-400'}`} />
                                    任务核心配置
                                </span>
                            </button>

                            <button
                                type="button"
                                onClick={() => setModalTab('dependency')}
                                className={`relative z-10 flex flex-1 items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-semibold transition-colors duration-300 ${
                                    modalTab === 'dependency' ? 'text-blue-700' : 'text-slate-500 hover:text-slate-800'
                                }`}
                            >
                                {modalTab === 'dependency' && (
                                    <motion.div
                                        layoutId="activeTabIndicator"
                                        className="absolute inset-0 rounded-xl bg-white shadow-sm border border-slate-200/50"
                                        transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                                    />
                                )}
                                <span className="relative z-20 flex items-center justify-center gap-2">
                                    <Terminal className={`h-4 w-4 transition-colors ${modalTab === 'dependency' ? 'text-blue-500' : 'text-slate-400'}`} />
                                    依赖关联任务
                                </span>
                            </button>
                        </div>
                    </div>

                    {modalTab === 'config' ? (
                        <div className="grid grid-cols-1 gap-6 xl:grid-cols-[1.08fr_0.92fr]">
                            {/* Left Column */}
                            <div className="space-y-6">
                                {/* Card 1: 任务核心 */}
                                <section className={`${modalCardClass} border-l-4 border-l-rose-500`}>
                                    <div className="border-b border-slate-100 px-5 py-4 bg-slate-50/20">
                                        <div className="flex items-center gap-2.5">
                                            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-rose-50 text-rose-500">
                                                <Sparkles size={15} />
                                            </div>
                                            <div>
                                                <h3 className="text-base font-bold text-slate-800">任务核心</h3>
                                                <p className="mt-0.5 text-xs text-slate-400">定义任务主体、所属系统与业务场景</p>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="grid grid-cols-1 gap-4 p-5 md:grid-cols-2">
                                        <Form.Item
                                            name="task_name"
                                            label={<span className="text-slate-600 font-semibold text-xs">任务名称</span>}
                                            rules={[{ required: true, message: '请填写任务名称' }]}
                                            className="md:col-span-2"
                                        >
                                            <Input
                                                placeholder="例如：监管报送日切任务"
                                                className="h-10 rounded-xl bg-slate-50/50 border-slate-200 hover:border-slate-300 focus:border-slate-400 focus:bg-white text-sm"
                                            />
                                        </Form.Item>
                                        <Form.Item
                                            name="task_type"
                                            label={<span className="text-slate-600 font-semibold text-xs">任务类型</span>}
                                            rules={[{ required: true, message: '请选择任务类型' }]}
                                        >
                                            <Select
                                                placeholder="请选择任务类型"
                                                className="premium-select"
                                                options={taskTypes.map(type => ({ label: type, value: type }))}
                                            />
                                        </Form.Item>
                                        <Form.Item
                                            name="task_status"
                                            label={<span className="text-slate-600 font-semibold text-xs">初始状态</span>}
                                            rules={[{ required: true, message: '请选择任务状态' }]}
                                        >
                                            <Select
                                                className="premium-select"
                                                options={[
                                                    { label: '正常', value: 0 },
                                                    { label: '暂停', value: 1 },
                                                ]}
                                            />
                                        </Form.Item>
                                        <Form.Item
                                            name="task_system"
                                            label={<span className="text-slate-600 font-semibold text-xs">所属系统</span>}
                                        >
                                            <Select
                                                showSearch
                                                allowClear
                                                className="premium-select"
                                                options={systems.map(system => ({ label: system, value: system }))}
                                                placeholder="请选择所属系统"
                                                optionFilterProp="label"
                                            />
                                        </Form.Item>
                                        <Form.Item
                                            name="theme"
                                            label={<span className="text-slate-600 font-semibold text-xs">任务主题</span>}
                                        >
                                            <Input
                                                placeholder="例如：日报 / 月报 / 回执"
                                                className="h-10 rounded-xl bg-slate-50/50 border-slate-200 hover:border-slate-300 focus:border-slate-400 focus:bg-white text-sm"
                                            />
                                        </Form.Item>
                                        <Form.Item
                                            name="remark"
                                            label={<span className="text-slate-600 font-semibold text-xs">任务备注说明</span>}
                                            className="md:col-span-2"
                                        >
                                            <TextArea
                                                rows={4}
                                                placeholder="用简洁自然语言说明这个监管任务具体解决什么业务问题，什么时候需要额外关注它。"
                                                className="rounded-xl bg-slate-50/50 border-slate-200 hover:border-slate-300 focus:border-slate-400 focus:bg-white text-sm"
                                            />
                                        </Form.Item>
                                    </div>
                                </section>

                                {/* Card 2: 运行节奏 */}
                                <section className={`${modalCardClass} border-l-4 border-l-blue-500`}>
                                    <div className="border-b border-slate-100 px-5 py-4 bg-slate-50/20">
                                        <div className="flex items-center gap-2.5">
                                            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-blue-50 text-blue-500">
                                                <Clock3 size={15} />
                                            </div>
                                            <div>
                                                <h3 className="text-base font-bold text-slate-800">运行节奏</h3>
                                                <p className="mt-0.5 text-xs text-slate-400">规划任务何时触发、是否依赖及重试策略</p>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="space-y-5 p-5">
                                        {/* Premium Cron Dashboard Grid */}
                                        <div className="rounded-2xl border border-slate-200/60 bg-slate-50/30 p-4">
                                            <div className="mb-3 text-[10px] font-bold uppercase tracking-[0.15em] text-slate-400 flex items-center gap-1.5">
                                                <span className="h-1.5 w-1.5 rounded-full bg-blue-400 animate-pulse" />
                                                调度时序面板
                                            </div>
                                            <Form.Item label={null} required className="mb-0">
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
                                            <Form.Item
                                                label={<span className="text-slate-600 font-semibold text-xs">依赖任务概览</span>}
                                                className="mb-0"
                                            >
                                                <div className="flex flex-col justify-between rounded-xl border border-slate-200/80 bg-slate-50/20 px-4 py-3 hover:border-slate-300 transition-all duration-200 min-h-[72px]">
                                                    <div className={`truncate text-sm font-semibold ${selectedDependencyIds.length > 0 ? 'text-slate-800' : 'text-slate-400'}`}>
                                                        {dependencySummary}
                                                    </div>
                                                    <div className="mt-2 flex items-center justify-between text-xs text-slate-400">
                                                        <span className="flex items-center gap-1">
                                                            <Database size={11} className="text-slate-400" />
                                                            {selectedDependencyIds.length > 0 ? `已关联 ${selectedDependencyIds.length} 个前置依赖` : '当前尚未配置任何前置依赖'}
                                                        </span>
                                                        <button
                                                            type="button"
                                                            onClick={() => setModalTab('dependency')}
                                                            className="flex items-center gap-1 rounded-lg border border-blue-200 bg-blue-50/80 px-2.5 py-1 text-[11px] font-bold text-blue-600 transition-all duration-200 hover:bg-blue-100 hover:border-blue-300 active:scale-95"
                                                        >
                                                            前往配置
                                                            <ArrowRight size={10} />
                                                        </button>
                                                    </div>
                                                </div>
                                            </Form.Item>
                                            <Form.Item
                                                name="period"
                                                label={<span className="text-slate-600 font-semibold text-xs">失败轮询间隔 (ms)</span>}
                                            >
                                                <InputNumber
                                                    className="w-full h-10 premium-input-number"
                                                    min={0}
                                                    placeholder="例如：300000"
                                                />
                                            </Form.Item>
                                        </div>
                                    </div>
                                </section>
                            </div>

                            {/* Right Column */}
                            <div className="space-y-6">
                                {/* Card 3: 执行资源 */}
                                <section className={`${modalCardClass} border-l-4 border-l-violet-500`}>
                                    <div className="border-b border-slate-100 px-5 py-4 bg-slate-50/20">
                                        <div className="flex items-center gap-2.5">
                                            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-violet-50 text-violet-500">
                                                <Settings2 size={15} />
                                            </div>
                                            <div>
                                                <h3 className="text-base font-bold text-slate-800">执行资源</h3>
                                                <p className="mt-0.5 text-xs text-slate-400">绑定业务执行脚本与底层对应的数据源</p>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="space-y-4 p-5">
                                        <Form.Item
                                            name="script"
                                            hidden
                                            rules={[{ required: true, message: '请填写脚本内容' }]}
                                        >
                                            <Input.TextArea />
                                        </Form.Item>
                                        <div>
                                            <div className="mb-2 text-slate-600 font-semibold text-xs flex items-center justify-between">
                                                <span>执行脚本编辑器</span>
                                                <span className="text-[10px] text-slate-400 font-mono">VS CODE STYLE</span>
                                            </div>
                                            {/* IDE Editor Shell Frame */}
                                            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-900 shadow-md">
                                                {/* Header Mockup */}
                                                <div className="flex items-center justify-between bg-slate-950/90 px-4 py-2 text-xs border-b border-slate-800">
                                                    <div className="flex items-center gap-1.5">
                                                        <span className="h-2.5 w-2.5 rounded-full bg-rose-500/80" />
                                                        <span className="h-2.5 w-2.5 rounded-full bg-amber-500/80" />
                                                        <span className="h-2.5 w-2.5 rounded-full bg-emerald-500/80" />
                                                        <span className="ml-2 font-mono text-[10px] tracking-wider text-slate-500 flex items-center gap-1">
                                                            <Terminal className="h-3 w-3 text-slate-600" />
                                                            {watchedTaskType === 'SQL' ? 'task_script.sql' : 'task_script.sh'}
                                                        </span>
                                                    </div>
                                                    <div className="font-mono text-[9px] font-bold text-violet-400 bg-violet-500/10 px-2 py-0.5 rounded border border-violet-500/20 uppercase tracking-wider">
                                                        {watchedTaskType || editingTask?.task_type || 'SHELL'}
                                                    </div>
                                                </div>
                                                {/* Body */}
                                                <div className="relative p-1 bg-white">
                                                    {scriptEditorReady ? (
                                                        <LazyMonacoEditor
                                                            loadingFallback={
                                                                <div className="flex h-[260px] items-center justify-center bg-slate-900 text-sm text-slate-400 font-mono">
                                                                    脚本编辑器加载中...
                                                                </div>
                                                            }
                                                            height="260px"
                                                            value={watchedScript || ''}
                                                            language={editorLanguageMap[watchedTaskType || editingTask?.task_type || 'SHELL'] || 'shell'}
                                                            theme="vs"
                                                            onChange={(value) => form.setFieldValue('script', value ?? '')}
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
                                                    ) : (
                                                        <div className="flex h-[260px] items-center justify-center bg-slate-900 text-sm text-slate-400 font-mono">
                                                            脚本编辑器加载中...
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                        <Form.Item
                                            name="datasource_id"
                                            label={<span className="text-slate-600 font-semibold text-xs">执行数据源</span>}
                                        >
                                            <Select
                                                showSearch
                                                allowClear
                                                loading={dataSourceLoading}
                                                className="premium-select"
                                                placeholder="请选择系统管理中的对应数据源"
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
                                                    <div className="flex items-center justify-between gap-3 py-1">
                                                        <div className="min-w-0">
                                                            <div className="truncate text-sm font-semibold text-slate-800">{option.data.label}</div>
                                                            <div className="mt-0.5 truncate text-[11px] text-slate-400 font-mono">
                                                                {option.data.connectionInfo || [option.data.typeName, option.data.category, option.data.typeCode].filter(Boolean).join(' · ') || '暂无可用连接信息'}
                                                            </div>
                                                        </div>
                                                    </div>
                                                )}
                                                notFoundContent={dataSourceLoading ? '数据源装载中...' : '系统管理中未查找到任何可用数据源'}
                                            />
                                        </Form.Item>
                                    </div>
                                </section>

                                {/* Card 4: 通知与托底 */}
                                <section className={`${modalCardClass} border-l-4 border-l-emerald-500`}>
                                    <div className="border-b border-slate-100 px-5 py-4 bg-slate-50/20">
                                        <div className="flex items-center gap-2.5">
                                            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-emerald-50 text-emerald-500">
                                                <Calendar size={15} />
                                            </div>
                                            <div>
                                                <h3 className="text-base font-bold text-slate-800">通知与托底</h3>
                                                <p className="mt-0.5 text-xs text-slate-400">配置任务完成或异常状态的触达人员</p>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="space-y-5 p-5">
                                        {/* 完成时通知 */}
                                        <Form.Item
                                            label={<span className="text-slate-600 font-semibold text-xs">执行成功时通知对象</span>}
                                            className="mb-0"
                                        >
                                            <Form.List name="notification_completed_list">
                                                {(fields, { add, remove }) => (
                                                    <div className="space-y-3">
                                                        <AnimatePresence mode="popLayout">
                                                            {fields.length === 0 ? (
                                                                <motion.div
                                                                    initial={{ opacity: 0 }}
                                                                    animate={{ opacity: 1 }}
                                                                    exit={{ opacity: 0 }}
                                                                    className="rounded-xl border border-dashed border-slate-200 bg-slate-50/50 px-4 py-3 text-xs text-slate-400 text-center"
                                                                >
                                                                    暂无配置通知对象，请点击下方按钮新增。
                                                                </motion.div>
                                                            ) : (
                                                                fields.map((field) => (
                                                                    <motion.div
                                                                        key={field.key}
                                                                        initial={{ opacity: 0, y: 12, scale: 0.96 }}
                                                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                                                        exit={{ opacity: 0, y: -12, scale: 0.96, transition: { duration: 0.15 } }}
                                                                        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                                                                        className="group relative flex flex-col gap-2 rounded-xl border border-slate-200 bg-slate-50/30 p-2.5 hover:border-slate-300 hover:bg-slate-50 transition-all duration-300 sm:flex-row sm:items-center"
                                                                    >
                                                                        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-slate-200/50 text-slate-400 shadow-inner group-hover:bg-slate-200 group-hover:text-slate-600 transition-colors">
                                                                            <User size={13} />
                                                                        </div>
                                                                        <div className="grid flex-1 grid-cols-1 gap-2 sm:grid-cols-2">
                                                                            <Form.Item
                                                                                name={[field.name, 'name']}
                                                                                className="mb-0"
                                                                                rules={[{ required: true, message: '姓名' }]}
                                                                            >
                                                                                <Input
                                                                                    placeholder="通知姓名 (例如：胡滨)"
                                                                                    variant="borderless"
                                                                                    className="h-8 px-2.5 rounded-lg bg-white border border-slate-200/80 focus:border-slate-400 focus:bg-white text-xs font-semibold text-slate-700"
                                                                                />
                                                                            </Form.Item>
                                                                            <Form.Item
                                                                                name={[field.name, 'custid']}
                                                                                className="mb-0"
                                                                                rules={[{ required: true, message: '客户号' }]}
                                                                            >
                                                                                <Input
                                                                                    placeholder="客户号 (例如：1001642)"
                                                                                    variant="borderless"
                                                                                    className="h-8 px-2.5 rounded-lg bg-white border border-slate-200/80 focus:border-slate-400 focus:bg-white text-xs font-mono text-slate-600"
                                                                                />
                                                                            </Form.Item>
                                                                        </div>
                                                                        <button
                                                                            type="button"
                                                                            onClick={() => remove(field.name)}
                                                                            className="flex h-8 w-8 items-center justify-center rounded-lg border border-red-100 bg-red-50 text-red-500 opacity-0 group-hover:opacity-100 hover:bg-red-500 hover:text-white transition-all duration-200 self-end sm:self-auto shrink-0 shadow-sm"
                                                                            title="删除此通知人"
                                                                        >
                                                                            <Trash2 size={13} />
                                                                        </button>
                                                                    </motion.div>
                                                                ))
                                                            )}
                                                        </AnimatePresence>
                                                        <motion.button
                                                            whileHover={{ scale: 1.01 }}
                                                            whileTap={{ scale: 0.99 }}
                                                            type="button"
                                                            onClick={() => add({ name: '', custid: '' })}
                                                            className="flex w-full items-center justify-center gap-1.5 rounded-xl border border-dashed border-slate-300 bg-white hover:border-slate-400 py-2 text-xs font-semibold text-slate-600 transition-colors shadow-sm hover:bg-slate-50/50"
                                                        >
                                                            <Plus size={13} className="text-slate-400" />
                                                            新增通知对象
                                                        </motion.button>
                                                    </div>
                                                )}
                                            </Form.List>
                                        </Form.Item>

                                        {/* 失败时通知 */}
                                        <Form.Item
                                            label={<span className="text-slate-600 font-semibold text-xs">执行失败时通知对象</span>}
                                            className="mb-0"
                                        >
                                            <Form.List name="notification_failed_list">
                                                {(fields, { add, remove }) => (
                                                    <div className="space-y-3">
                                                        <AnimatePresence mode="popLayout">
                                                            {fields.length === 0 ? (
                                                                <motion.div
                                                                    initial={{ opacity: 0 }}
                                                                    animate={{ opacity: 1 }}
                                                                    exit={{ opacity: 0 }}
                                                                    className="rounded-xl border border-dashed border-slate-200 bg-slate-50/50 px-4 py-3 text-xs text-slate-400 text-center"
                                                                >
                                                                    暂无配置通知对象，请点击下方按钮新增。
                                                                </motion.div>
                                                            ) : (
                                                                fields.map((field) => (
                                                                    <motion.div
                                                                        key={field.key}
                                                                        initial={{ opacity: 0, y: 12, scale: 0.96 }}
                                                                        animate={{ opacity: 1, y: 0, scale: 1 }}
                                                                        exit={{ opacity: 0, y: -12, scale: 0.96, transition: { duration: 0.15 } }}
                                                                        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                                                                        className="group relative flex flex-col gap-2 rounded-xl border border-slate-200 bg-slate-50/30 p-2.5 hover:border-slate-300 hover:bg-slate-50 transition-all duration-300 sm:flex-row sm:items-center"
                                                                    >
                                                                        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-slate-200/50 text-slate-400 shadow-inner group-hover:bg-slate-200 group-hover:text-slate-600 transition-colors">
                                                                            <User size={13} />
                                                                        </div>
                                                                        <div className="grid flex-1 grid-cols-1 gap-2 sm:grid-cols-2">
                                                                            <Form.Item
                                                                                name={[field.name, 'name']}
                                                                                className="mb-0"
                                                                                rules={[{ required: true, message: '姓名' }]}
                                                                            >
                                                                                <Input
                                                                                    placeholder="通知姓名 (例如：胡滨)"
                                                                                    variant="borderless"
                                                                                    className="h-8 px-2.5 rounded-lg bg-white border border-slate-200/80 focus:border-slate-400 focus:bg-white text-xs font-semibold text-slate-700"
                                                                                />
                                                                            </Form.Item>
                                                                            <Form.Item
                                                                                name={[field.name, 'custid']}
                                                                                className="mb-0"
                                                                                rules={[{ required: true, message: '客户号' }]}
                                                                            >
                                                                                <Input
                                                                                    placeholder="客户号 (例如：1001642)"
                                                                                    variant="borderless"
                                                                                    className="h-8 px-2.5 rounded-lg bg-white border border-slate-200/80 focus:border-slate-400 focus:bg-white text-xs font-mono text-slate-600"
                                                                                />
                                                                            </Form.Item>
                                                                        </div>
                                                                        <button
                                                                            type="button"
                                                                            onClick={() => remove(field.name)}
                                                                            className="flex h-8 w-8 items-center justify-center rounded-lg border border-red-100 bg-red-50 text-red-500 opacity-0 group-hover:opacity-100 hover:bg-red-500 hover:text-white transition-all duration-200 self-end sm:self-auto shrink-0 shadow-sm"
                                                                            title="删除此通知人"
                                                                        >
                                                                            <Trash2 size={13} />
                                                                        </button>
                                                                    </motion.div>
                                                                ))
                                                            )}
                                                        </AnimatePresence>
                                                        <motion.button
                                                            whileHover={{ scale: 1.01 }}
                                                            whileTap={{ scale: 0.99 }}
                                                            type="button"
                                                            onClick={() => add({ name: '', custid: '' })}
                                                            className="flex w-full items-center justify-center gap-1.5 rounded-xl border border-dashed border-slate-300 bg-white hover:border-slate-400 py-2 text-xs font-semibold text-slate-600 transition-colors shadow-sm hover:bg-slate-50/50"
                                                        >
                                                            <Plus size={13} className="text-slate-400" />
                                                            新增通知对象
                                                        </motion.button>
                                                    </div>
                                                )}
                                            </Form.List>
                                        </Form.Item>
                                    </div>
                                </section>
                            </div>
                        </div>
                    ) : (
                        <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm">
                            <TaskDependencyPanel
                                taskList={taskList}
                                editingTaskId={editingTask?.id}
                                selectedDependencyIds={selectedDependencyIds}
                                selectedControlDependencyIds={selectedControlDependencyIds}
                                dependencyTaskDetails={dependencyTasks}
                                systems={systems}
                                taskTypes={taskTypes}
                                onChangeSelectedDependencyIds={updateDependencySelection}
                                onChangeSelectedControlDependencyIds={updateControlDependencySelection}
                            />
                        </div>
                    )}
                </div>
            </Form>
        </Modal>
    );
};

export default TaskEditorModal;
