import React from 'react';
import { Collapse, Drawer, Input } from 'antd';
import { Calendar, Clock3, Settings2 } from 'lucide-react';
import dayjs from 'dayjs';
import { QuartzTask } from './mockData';
import LazyMonacoEditor from './LazyMonacoEditor';
import {
    detailItemClass,
    detailMetaBadgeClass,
    detailSectionClass,
    describeCron,
    editorLanguageMap,
    parseNotificationContacts,
    statusMap,
} from './taskManagementUtils';

interface TaskDetailDrawerProps {
    selectedTask: QuartzTask | null;
    selectedTaskDetailTab: 'config' | 'dependency';
    selectedTaskDataDependencies: QuartzTask[];
    selectedTaskControlDependencies: QuartzTask[];
    selectedTaskDependencySummary: string;
    detailScriptEditorReady: boolean;
    onClose: () => void;
    onTabChange: (tab: 'config' | 'dependency') => void;
}

const dependencyTypeMeta = {
    DATA: {
        label: '数据依赖',
        description: '参与调度检查；重跑时沿数据依赖链路传播。',
        badgeClass: 'border-emerald-200 bg-emerald-50 text-emerald-700',
        dotClass: 'bg-emerald-500',
    },
    CONTROL: {
        label: '控制依赖',
        description: '参与调度检查；重跑时不沿控制依赖传播。',
        badgeClass: 'border-amber-200 bg-amber-50 text-amber-700',
        dotClass: 'bg-amber-500',
    },
} as const;

const TaskDetailDrawer: React.FC<TaskDetailDrawerProps> = ({
    selectedTask,
    selectedTaskDetailTab,
    selectedTaskDataDependencies,
    selectedTaskControlDependencies,
    selectedTaskDependencySummary,
    detailScriptEditorReady,
    onClose,
    onTabChange,
}) => {
    const dependencyTotal = selectedTaskDataDependencies.length + selectedTaskControlDependencies.length;
    const [dependencySearchKeyword, setDependencySearchKeyword] = React.useState('');

    React.useEffect(() => {
        setDependencySearchKeyword('');
    }, [selectedTask?.id]);

    const normalizedDependencySearchKeyword = dependencySearchKeyword.trim().toLowerCase();

    const filterDependencyTasks = React.useCallback((dependencies: QuartzTask[]) => {
        if (!normalizedDependencySearchKeyword) return dependencies;
        return dependencies.filter(task => {
            const searchableText = [
                task.id,
                task.task_name,
                task.task_system,
                task.theme,
                task.task_type,
                task.job_key,
            ].filter(value => value !== undefined && value !== null)
                .join(' ')
                .toLowerCase();
            return searchableText.includes(normalizedDependencySearchKeyword);
        });
    }, [normalizedDependencySearchKeyword]);

    const filteredDataDependencies = React.useMemo(
        () => filterDependencyTasks(selectedTaskDataDependencies),
        [filterDependencyTasks, selectedTaskDataDependencies]
    );
    const filteredControlDependencies = React.useMemo(
        () => filterDependencyTasks(selectedTaskControlDependencies),
        [filterDependencyTasks, selectedTaskControlDependencies]
    );
    const filteredDependencyTotal = filteredDataDependencies.length + filteredControlDependencies.length;
    const hasDependencySearchKeyword = normalizedDependencySearchKeyword.length > 0;

    const renderNotificationContacts = (value?: string | null) => {
        const contacts = parseNotificationContacts(value);
        if (contacts.length === 0) {
            return <div className="mt-1 text-slate-500">-</div>;
        }
        return (
            <div className="mt-2 space-y-2">
                {contacts.map((contact, index) => (
                    <div
                        key={`${contact.custid || 'custid'}-${contact.name || 'name'}-${index}`}
                        className="flex flex-wrap items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs text-slate-700"
                    >
                        <span className="inline-flex rounded bg-slate-100 px-2 py-0.5 font-medium text-slate-700">
                            {contact.name || '-'}
                        </span>
                        <span className="font-mono text-slate-500">{contact.custid || '-'}</span>
                    </div>
                ))}
            </div>
        );
    };

    const renderDependencyGroup = (
        dependencyType: keyof typeof dependencyTypeMeta,
        dependencies: QuartzTask[],
        totalCount: number
    ) => {
        const meta = dependencyTypeMeta[dependencyType];
        return (
            <Collapse
                defaultActiveKey={[]}
                expandIconPosition="end"
                className="overflow-hidden rounded-xl border border-slate-200 bg-white"
                items={[
                    {
                        key: dependencyType,
                        label: (
                            <div className="flex items-start justify-between gap-3 pr-3">
                                <div className="min-w-0">
                                    <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                        <span className={`h-2 w-2 rounded-full ${meta.dotClass}`} />
                                        {meta.label}
                                    </div>
                                    <div className="mt-1 text-xs text-slate-500">{meta.description}</div>
                                </div>
                                <span className={`shrink-0 rounded-full border px-2 py-1 text-xs font-semibold ${meta.badgeClass}`}>
                                    {hasDependencySearchKeyword ? `${dependencies.length}/${totalCount} 项` : `${totalCount} 项`}
                                </span>
                            </div>
                        ),
                        children: (
                            <div className="divide-y divide-slate-100">
                                {dependencies.length === 0 ? (
                                    <div className="px-4 py-8 text-center text-sm text-slate-500">
                                        {hasDependencySearchKeyword ? '暂无匹配任务' : `暂无${meta.label}`}
                                    </div>
                                ) : (
                                    dependencies.map(task => {
                                        const mappedStatus = statusMap[task.task_status] || statusMap[0];
                                        return (
                                            <div key={`${dependencyType}-${task.id}`} className="px-4 py-4">
                                                <div className="flex items-start justify-between gap-3">
                                                    <div className="min-w-0 truncate text-sm font-semibold leading-6 text-slate-800" title={task.task_name}>
                                                        {task.task_name}
                                                    </div>
                                                    <div className="flex shrink-0 items-center gap-1.5">
                                                        <span className={`rounded-full border px-2 py-1 text-[11px] font-semibold leading-none ${meta.badgeClass}`}>
                                                            {meta.label}
                                                        </span>
                                                        <span className={`rounded-full border px-2 py-1 text-[11px] font-semibold leading-none ${mappedStatus.className}`}>
                                                            {mappedStatus.label}
                                                        </span>
                                                    </div>
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
                        ),
                    },
                ]}
            />
        );
    };

    return (
        <Drawer
            title={selectedTask ? `任务详情 · ${selectedTask.task_name}` : '任务详情'}
            placement="right"
            size={620}
            onClose={onClose}
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
                                onClick={() => onTabChange('config')}
                                className={`rounded-xl px-3 py-2 text-sm font-semibold transition ${selectedTaskDetailTab === 'config' ? 'bg-red-50 text-red-700' : 'text-slate-500 hover:bg-slate-50'}`}
                            >
                                任务配置
                            </button>
                            <button
                                type="button"
                                onClick={() => onTabChange('dependency')}
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
                                        <div className="text-xs text-slate-400">执行资源</div>
                                        <div className="mt-1 text-slate-700">
                                            {selectedTask.datasource_pool_name || selectedTask.datasource_name || '-'}
                                        </div>
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
                                        {renderNotificationContacts(selectedTask.notification_completed)}
                                    </div>
                                    <div className={detailItemClass}>
                                        <div className="text-xs text-slate-400">失败时通知</div>
                                        {renderNotificationContacts(selectedTask.notification_failed)}
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
                                    <div className="mt-1 text-sm text-slate-500">只读查看当前任务的数据依赖与控制依赖前置链路。</div>
                                </div>
                                <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
                                    {hasDependencySearchKeyword ? `匹配 ${filteredDependencyTotal}/${dependencyTotal} 项` : `${dependencyTotal} 项`}
                                </span>
                            </div>
                            <div className="space-y-4 p-5">
                                {dependencyTotal === 0 ? (
                                    <div className="rounded-xl border border-dashed border-slate-200 px-5 py-12 text-center text-sm text-slate-500">
                                        暂无依赖任务
                                    </div>
                                ) : (
                                    <>
                                        <Input
                                            allowClear
                                            value={dependencySearchKeyword}
                                            onChange={event => setDependencySearchKeyword(event.target.value)}
                                            placeholder="搜索任务名称、ID、系统、主题、类型"
                                        />
                                        {renderDependencyGroup('DATA', filteredDataDependencies, selectedTaskDataDependencies.length)}
                                        {renderDependencyGroup('CONTROL', filteredControlDependencies, selectedTaskControlDependencies.length)}
                                    </>
                                )}
                            </div>
                        </section>
                    )}
                </div>
            )}
        </Drawer>
    );
};

export default TaskDetailDrawer;
