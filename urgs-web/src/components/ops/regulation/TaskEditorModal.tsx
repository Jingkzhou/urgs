import React, { useEffect, useMemo, useState } from 'react';
import { Form, Input, InputNumber, Modal, Select } from 'antd';
import { Calendar, Clock3, Plus, Settings2, Trash2 } from 'lucide-react';
import { QuartzTask } from './mockData';
import LazyMonacoEditor from './LazyMonacoEditor';
import CronPicker from '../schedule/forms/components/CronPicker';
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

const modalCardClass = 'rounded-2xl border border-slate-200 bg-white';

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
            return '请选择依赖任务';
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
            taskName: watchedTaskName?.trim() || editingTask?.task_name || '未命名任务',
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
            width={1120}
            onOk={onSubmit}
            onCancel={onCancel}
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
                            onClick={onCancel}
                            className="rounded-xl border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50"
                        >
                            取消
                        </button>
                        <button
                            onClick={onSubmit}
                            className="rounded-xl bg-red-600 px-5 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-red-700"
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
                    <div className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
                        <div className="text-sm font-semibold text-slate-800">
                            {editingTask ? `编辑监管任务 · ${portrait.taskName}` : '新建监管任务'}
                        </div>
                        <div className="mt-1 text-xs text-slate-500">{portrait.schedule}</div>
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

                    <div className="rounded-2xl border border-slate-200 bg-white p-1.5">
                        <div className="grid grid-cols-2 gap-1">
                            <button
                                type="button"
                                onClick={() => setModalTab('config')}
                                className={`rounded-xl px-3 py-2 text-sm font-semibold transition ${modalTab === 'config' ? 'bg-red-50 text-red-700' : 'text-slate-500 hover:bg-slate-50'}`}
                            >
                                任务配置
                            </button>
                            <button
                                type="button"
                                onClick={() => setModalTab('dependency')}
                                className={`rounded-xl px-3 py-2 text-sm font-semibold transition ${modalTab === 'dependency' ? 'bg-blue-50 text-blue-700' : 'text-slate-500 hover:bg-slate-50'}`}
                            >
                                依赖任务
                            </button>
                        </div>
                    </div>

                    {modalTab === 'config' ? (
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
                                            <Select
                                                showSearch
                                                allowClear
                                                options={systems.map(system => ({ label: system, value: system }))}
                                                placeholder="请选择所属系统"
                                                optionFilterProp="label"
                                            />
                                        </Form.Item>
                                        <Form.Item name="theme" label="任务主题">
                                            <Input placeholder="例如：日报 / 月报 / 回执" />
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
                                                <div className="rounded-xl border border-slate-200 bg-white px-4 py-2.5">
                                                    <div className={`truncate text-sm font-medium ${selectedDependencyIds.length > 0 ? 'text-slate-800' : 'text-slate-400'}`}>
                                                        {dependencySummary}
                                                    </div>
                                                    <div className="mt-1 flex items-center justify-between text-xs text-slate-400">
                                                        <span>{selectedDependencyIds.length > 0 ? `已关联 ${selectedDependencyIds.length} 个前置任务` : '切换到“依赖任务”页签配置'}</span>
                                                        <button
                                                            type="button"
                                                            onClick={() => setModalTab('dependency')}
                                                            className="rounded-md border border-red-200 bg-red-50 px-2 py-0.5 font-semibold text-red-600 transition hover:bg-red-100"
                                                        >
                                                            去配置
                                                        </button>
                                                    </div>
                                                </div>
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
                                            hidden
                                            rules={[{ required: true, message: '请填写脚本内容' }]}
                                        >
                                            <Input.TextArea />
                                        </Form.Item>
                                        <div>
                                            <div className="mb-2 text-sm text-slate-700">脚本</div>
                                            {scriptEditorReady ? (
                                                <LazyMonacoEditor
                                                    loadingFallback={
                                                        <div className="flex h-[260px] items-center justify-center rounded-xl border border-dashed border-slate-200 bg-slate-50 text-sm text-slate-400">
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
                                                <div className="flex h-[260px] items-center justify-center rounded-xl border border-dashed border-slate-200 bg-slate-50 text-sm text-slate-400">
                                                    脚本编辑器加载中...
                                                </div>
                                            )}
                                        </div>
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
                                        <Form.Item label="完成时通知" className="mb-0">
                                            <Form.List name="notification_completed_list">
                                                {(fields, { add, remove }) => (
                                                    <div className="space-y-3">
                                                        {fields.length === 0 ? (
                                                            <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-500">
                                                                暂无通知对象，可点击“新增通知对象”添加。
                                                            </div>
                                                        ) : fields.map((field) => (
                                                            <div key={field.key} className="grid grid-cols-1 gap-2 md:grid-cols-[1fr_1fr_auto]">
                                                                <Form.Item
                                                                    name={[field.name, 'name']}
                                                                    className="mb-0"
                                                                    rules={[{ required: true, message: '请输入姓名' }]}
                                                                >
                                                                    <Input placeholder="姓名，如：胡滨" />
                                                                </Form.Item>
                                                                <Form.Item
                                                                    name={[field.name, 'custid']}
                                                                    className="mb-0"
                                                                    rules={[{ required: true, message: '请输入客户号' }]}
                                                                >
                                                                    <Input placeholder="客户号，如：1001642473" />
                                                                </Form.Item>
                                                                <button
                                                                    type="button"
                                                                    onClick={() => remove(field.name)}
                                                                    className="inline-flex h-10 items-center justify-center gap-1 rounded-xl border border-red-200 bg-red-50 px-3 text-sm font-medium text-red-600 transition hover:bg-red-100"
                                                                >
                                                                    <Trash2 size={14} />
                                                                    删除
                                                                </button>
                                                            </div>
                                                        ))}
                                                        <button
                                                            type="button"
                                                            onClick={() => add({ name: '', custid: '' })}
                                                            className="inline-flex items-center gap-1 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
                                                        >
                                                            <Plus size={14} />
                                                            新增通知对象
                                                        </button>
                                                    </div>
                                                )}
                                            </Form.List>
                                        </Form.Item>
                                        <Form.Item label="失败时通知" className="mb-0">
                                            <Form.List name="notification_failed_list">
                                                {(fields, { add, remove }) => (
                                                    <div className="space-y-3">
                                                        {fields.length === 0 ? (
                                                            <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-500">
                                                                暂无通知对象，可点击“新增通知对象”添加。
                                                            </div>
                                                        ) : fields.map((field) => (
                                                            <div key={field.key} className="grid grid-cols-1 gap-2 md:grid-cols-[1fr_1fr_auto]">
                                                                <Form.Item
                                                                    name={[field.name, 'name']}
                                                                    className="mb-0"
                                                                    rules={[{ required: true, message: '请输入姓名' }]}
                                                                >
                                                                    <Input placeholder="姓名，如：胡滨" />
                                                                </Form.Item>
                                                                <Form.Item
                                                                    name={[field.name, 'custid']}
                                                                    className="mb-0"
                                                                    rules={[{ required: true, message: '请输入客户号' }]}
                                                                >
                                                                    <Input placeholder="客户号，如：1001642473" />
                                                                </Form.Item>
                                                                <button
                                                                    type="button"
                                                                    onClick={() => remove(field.name)}
                                                                    className="inline-flex h-10 items-center justify-center gap-1 rounded-xl border border-red-200 bg-red-50 px-3 text-sm font-medium text-red-600 transition hover:bg-red-100"
                                                                >
                                                                    <Trash2 size={14} />
                                                                    删除
                                                                </button>
                                                            </div>
                                                        ))}
                                                        <button
                                                            type="button"
                                                            onClick={() => add({ name: '', custid: '' })}
                                                            className="inline-flex items-center gap-1 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
                                                        >
                                                            <Plus size={14} />
                                                            新增通知对象
                                                        </button>
                                                    </div>
                                                )}
                                            </Form.List>
                                        </Form.Item>
                                    </div>
                                </section>
                            </div>
                        </div>
                    ) : (
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
                    )}
                </div>
            </Form>
        </Modal>
    );
};

export default TaskEditorModal;
