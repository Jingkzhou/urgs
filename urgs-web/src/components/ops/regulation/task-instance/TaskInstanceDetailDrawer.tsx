import React, { useMemo } from 'react';
import { Drawer, Tabs, Tag } from 'antd';
import {
    Activity,
    AlertCircle,
    ArrowDownCircle,
    ArrowUpCircle,
    CalendarRange,
    CheckCircle2,
    Clock3,
    GitBranch,
} from 'lucide-react';
import dayjs from 'dayjs';
import { QuartzTask, QuartzTaskExecutionLog, QuartzTaskStatus } from '../mockData';
import {
    detailItemClass,
    detailSectionBodyClass,
    detailSectionClass,
    detailSectionHeaderClass,
    instanceStatusMap,
    taskDefinitionStatusMap,
} from './constants';
import { formatDuration } from './utils';
import {
    BlockingDependencyItem,
    DependencyInsightData,
    InstanceDetailTabKey,
} from './types';

interface TaskInstanceDetailDrawerProps {
    selectedInstance: QuartzTaskStatus | null;
    selectedTask: QuartzTask | null;
    taskNameMap: Map<number, string>;
    instanceDetailTabKey: InstanceDetailTabKey;
    dependencyPanelData: DependencyInsightData | null;
    selectedInstanceLogs: QuartzTaskExecutionLog[];
    showImpactedOnly: boolean;
    expandedImpactTaskIds: number[];
    onClose: () => void;
    onTabChange: (key: InstanceDetailTabKey) => void;
    onShowImpactedOnlyChange: (nextValue: boolean) => void;
    onToggleImpactTaskExpanded: (taskId: number) => void;
    onLocateInstanceFromDependency: (instance: QuartzTaskStatus) => void;
}

const TaskInstanceDetailDrawer: React.FC<TaskInstanceDetailDrawerProps> = ({
    selectedInstance,
    selectedTask,
    taskNameMap,
    instanceDetailTabKey,
    dependencyPanelData,
    selectedInstanceLogs,
    showImpactedOnly,
    expandedImpactTaskIds,
    onClose,
    onTabChange,
    onShowImpactedOnlyChange,
    onToggleImpactTaskExpanded,
    onLocateInstanceFromDependency,
}) => {
    const expandedImpactTaskIdSet = useMemo(() => new Set(expandedImpactTaskIds), [expandedImpactTaskIds]);

    const renderRelationStatus = (relation?: QuartzTaskStatus) => {
        if (!relation) {
            return (
                <span className="inline-flex rounded-full border border-slate-200 bg-slate-50 px-2 py-1 text-xs font-semibold text-slate-500">
                    暂无实例
                </span>
            );
        }
        const mappedStatus = instanceStatusMap[relation.status ?? -1];
        if (!mappedStatus) {
            return <Tag className="m-0">{relation.status ?? '-'}</Tag>;
        }
        return (
            <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold leading-none ${mappedStatus.className}`}>
                {mappedStatus.label}
            </span>
        );
    };

    const renderBlockingDependencyList = (items: BlockingDependencyItem[]) => {
        if (items.length === 0) {
            return (
                <div className="rounded-2xl border border-emerald-100 bg-emerald-50/60 px-4 py-12 text-center">
                    <CheckCircle2 size={30} className="mx-auto text-emerald-500" />
                    <div className="mt-3 text-sm font-semibold text-emerald-700">前置任务已全部完成</div>
                    <div className="mt-1 text-xs text-emerald-600">当前实例没有未结束的上游阻塞点。</div>
                </div>
            );
        }

        return (
            <div className="space-y-3">
                {items.map(item => (
                    <div
                        key={item.taskId}
                        className={`rounded-2xl border p-4 shadow-sm ${
                            item.relatedInstance?.status === 4
                                ? 'border-red-200 bg-red-50/60'
                                : item.relatedInstance?.status === 2
                                  ? 'border-blue-200 bg-blue-50/60'
                                  : 'border-amber-200 bg-amber-50/60'
                        }`}
                    >
                        <div className="flex items-start justify-between gap-4">
                            <div className="min-w-0 flex-1">
                                <div className="flex flex-wrap items-center gap-2">
                                    <div className="truncate text-sm font-semibold text-slate-800" title={item.taskName}>
                                        {item.taskName}
                                    </div>
                                    <span className="rounded-md bg-slate-100 px-2 py-0.5 font-mono text-[11px] text-slate-500">
                                        #{item.taskId}
                                    </span>
                                    {item.missingTask && (
                                        <span className="rounded-full border border-amber-200 bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700">
                                            未纳入当前任务清单
                                        </span>
                                    )}
                                </div>
                                <div className="mt-2 flex flex-wrap items-center gap-1.5 text-[11px] text-slate-500">
                                    <span className="rounded-lg border border-white/80 bg-white/70 px-2 py-1">层级 L{item.level}</span>
                                    <span className="rounded-lg border border-white/80 bg-white/70 px-2 py-1">系统 {item.taskSystem}</span>
                                    <span className="rounded-lg border border-white/80 bg-white/70 px-2 py-1">主题 {item.theme}</span>
                                    <span className="rounded-lg border border-white/80 bg-white/70 px-2 py-1">数据日期 {item.relatedInstance?.data_date || selectedInstance?.data_date || '-'}</span>
                                </div>
                                <div className="mt-2 text-xs text-slate-500">
                                    开始 {item.relatedInstance?.begin_time || '-'} · 更新 {item.relatedInstance?.update_time || item.relatedInstance?.create_time || '-'}
                                </div>
                                {item.relatedInstance?.msg && (
                                    <div
                                        className={`mt-3 rounded-xl border px-3 py-2 text-xs ${
                                            item.relatedInstance.status === 4
                                                ? 'border-red-200 bg-white/80 text-red-700'
                                                : 'border-white/80 bg-white/70 text-slate-600'
                                        }`}
                                        title={item.relatedInstance.msg || ''}
                                    >
                                        {item.relatedInstance.msg}
                                    </div>
                                )}
                            </div>
                            <div className="flex shrink-0 flex-col items-end gap-2">
                                {renderRelationStatus(item.relatedInstance)}
                                <button
                                    onClick={() => item.relatedInstance && onLocateInstanceFromDependency(item.relatedInstance)}
                                    disabled={!item.relatedInstance}
                                    className="inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600 disabled:cursor-not-allowed disabled:border-slate-200 disabled:bg-slate-100 disabled:text-slate-400"
                                >
                                    查看实例
                                </button>
                            </div>
                        </div>
                    </div>
                ))}
            </div>
        );
    };

    const renderDownstreamImpactTree = (taskIds: number[], level: number, emptyText: string): React.ReactNode => {
        const visibleItems = showImpactedOnly
            ? taskIds.filter(taskId => {
                const item = dependencyPanelData?.downstreamMetaMap.get(taskId);
                return item?.impacted || item?.hasImpactedDescendant;
            })
            : taskIds;

        if (visibleItems.length === 0) {
            return (
                <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50/60 px-4 py-12 text-center text-sm text-slate-500">
                    {emptyText}
                </div>
            );
        }

        return (
            <div className="space-y-3">
                {visibleItems.map(taskId => {
                    const item = dependencyPanelData?.downstreamMetaMap.get(taskId);
                    if (!item) {
                        return null;
                    }
                    const mappedStatus = instanceStatusMap[item.relatedInstance?.status ?? -1];
                    const hasChildren = item.directChildIds.length > 0;
                    const expanded = expandedImpactTaskIdSet.has(item.taskId);

                    return (
                        <div key={`${item.taskId}-${level}`} className="space-y-3">
                            <div
                                className={`rounded-2xl border p-4 shadow-sm ${
                                    item.impacted
                                        ? 'border-blue-200 bg-blue-50/60'
                                        : 'border-slate-200 bg-white'
                                }`}
                                style={{ marginLeft: Math.min((level - 1) * 18, 72) }}
                            >
                                <div className="flex items-start justify-between gap-4">
                                    <div className="min-w-0 flex-1">
                                        <div className="flex flex-wrap items-center gap-2">
                                            <div className="truncate text-sm font-semibold text-slate-800" title={item.taskName}>
                                                {item.taskName}
                                            </div>
                                            <span className="rounded-md bg-slate-100 px-2 py-0.5 font-mono text-[11px] text-slate-500">
                                                #{item.taskId}
                                            </span>
                                            <span className={`rounded-full px-2 py-0.5 text-[11px] font-semibold ${item.impacted ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-500'}`}>
                                                {item.impacted ? '会受本次重跑影响' : '当前已稳定'}
                                            </span>
                                        </div>
                                        <div className="mt-2 flex flex-wrap items-center gap-1.5 text-[11px] text-slate-500">
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">层级 L{level}</span>
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">系统 {item.taskSystem}</span>
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">主题 {item.theme}</span>
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">直接下游 {item.directChildIds.length}</span>
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">累计影响 {item.descendantCount}</span>
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">数据日期 {item.relatedInstance?.data_date || selectedInstance?.data_date || '-'}</span>
                                        </div>
                                        {item.relatedInstance?.msg && (
                                            <div className="mt-2 truncate text-xs text-slate-500" title={item.relatedInstance.msg || ''}>
                                                {item.relatedInstance.msg}
                                            </div>
                                        )}
                                    </div>
                                    <div className="flex shrink-0 flex-col items-end gap-2">
                                        {mappedStatus ? (
                                            <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold leading-none ${mappedStatus.className}`}>
                                                {mappedStatus.label}
                                            </span>
                                        ) : (
                                            renderRelationStatus(item.relatedInstance)
                                        )}
                                        <button
                                            onClick={() => item.relatedInstance && onLocateInstanceFromDependency(item.relatedInstance)}
                                            disabled={!item.relatedInstance}
                                            className="inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-600 disabled:cursor-not-allowed disabled:border-slate-200 disabled:bg-slate-100 disabled:text-slate-400"
                                        >
                                            查看实例
                                        </button>
                                        {hasChildren && (
                                            <button
                                                type="button"
                                                onClick={() => onToggleImpactTaskExpanded(item.taskId)}
                                                className="inline-flex items-center rounded-lg border border-blue-200 bg-white px-2.5 py-1 text-xs font-semibold text-blue-600 transition hover:bg-blue-50"
                                            >
                                                {expanded ? '收起下游' : `展开下游 ${item.directChildIds.length}`}
                                            </button>
                                        )}
                                    </div>
                                </div>
                            </div>
                            {hasChildren && expanded && renderDownstreamImpactTree(item.directChildIds, level + 1, emptyText)}
                        </div>
                    );
                })}
            </div>
        );
    };

    return (
        <Drawer
            title={selectedInstance ? `实例详情 · #${selectedInstance.id}` : '实例详情'}
            placement="right"
            size={920}
            onClose={onClose}
            open={!!selectedInstance}
        >
            {selectedInstance && (
                <div className="space-y-4">
                    <div className="rounded-2xl border border-slate-200 bg-gradient-to-r from-slate-50 via-white to-red-50/50 p-4">
                        <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
                            <div className="min-w-0">
                                <div className="text-sm font-semibold text-slate-800">
                                    {selectedTask?.task_name || taskNameMap.get(selectedInstance.plan_id) || '-'}
                                </div>
                                <div className="mt-1 font-mono text-xs text-slate-500">
                                    实例 #{selectedInstance.id} · 计划 #{selectedInstance.plan_id} · 数据日期 {selectedInstance.data_date}
                                </div>
                            </div>
                            <div className="flex flex-wrap items-center gap-2 text-xs">
                                <span className="inline-flex items-center rounded-full bg-slate-100 px-3 py-1 text-slate-600">
                                    实例状态 {instanceStatusMap[selectedInstance.status ?? -1]?.label || selectedInstance.status || '-'}
                                </span>
                                <span className="inline-flex items-center rounded-full bg-blue-50 px-3 py-1 text-blue-700">
                                    {selectedTask?.task_system || '-'}
                                </span>
                                <span className="inline-flex items-center rounded-full bg-emerald-50 px-3 py-1 text-emerald-700">
                                    {selectedTask?.theme || '-'}
                                </span>
                            </div>
                        </div>
                    </div>

                    <Tabs
                        activeKey={instanceDetailTabKey}
                        onChange={(key) => onTabChange(key as InstanceDetailTabKey)}
                        items={[
                            {
                                key: 'overview',
                                label: '实例总览',
                                children: (
                                    <div className="space-y-4">
                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                                    <CalendarRange size={16} className="text-emerald-500" />
                                                    实例信息
                                                </div>
                                                <div className="mt-1 text-xs text-slate-500">展示本次运行实例的身份、状态和关键时间点。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">实例ID</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.id}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">计划ID</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.plan_id}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">数据日期</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.data_date}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">当前状态</div>
                                                        <div className="mt-1">
                                                            {instanceStatusMap[selectedInstance.status ?? -1] ? (
                                                                <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${instanceStatusMap[selectedInstance.status ?? -1].className}`}>
                                                                    {instanceStatusMap[selectedInstance.status ?? -1].label}
                                                                </span>
                                                            ) : (
                                                                <Tag className="m-0">{selectedInstance.status ?? '-'}</Tag>
                                                            )}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </section>

                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                                    <Clock3 size={16} className="text-blue-500" />
                                                    执行时间线
                                                </div>
                                                <div className="mt-1 text-xs text-slate-500">按时间顺序查看实例从创建到结束的执行轨迹。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">创建时间</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">
                                                            {dayjs(selectedInstance.create_time).format('YYYY-MM-DD HH:mm:ss')}
                                                        </div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">开始时间</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.begin_time || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">更新时间</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.update_time || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">结束时间</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.end_time || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">创建批次</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.create_date}</div>
                                                    </div>
                                                </div>
                                            </div>
                                        </section>

                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                                    <AlertCircle size={16} className="text-red-500" />
                                                    执行消息
                                                </div>
                                                <div className="mt-1 text-xs text-slate-500">只保留最关键的执行反馈，方便快速定位异常。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className={detailItemClass}>
                                                    <div className="text-xs text-slate-400">消息内容</div>
                                                    <div className="mt-1 whitespace-pre-wrap text-slate-700">{selectedInstance.msg || '无消息'}</div>
                                                </div>
                                            </div>
                                        </section>
                                    </div>
                                ),
                            },
                            {
                                key: 'task',
                                label: '任务信息',
                                children: (
                                    <div className="space-y-4">
                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="text-sm font-semibold text-slate-800">任务概览</div>
                                                <div className="mt-1 text-xs text-slate-500">先看关键身份与状态，再看调度与追踪字段。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="rounded-2xl border border-slate-200 bg-gradient-to-r from-slate-50 via-white to-blue-50/50 px-4 py-4">
                                                    <div className="flex flex-wrap items-center gap-2">
                                                        <span className="rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-semibold text-slate-700">
                                                            {selectedTask?.task_type || '-'}
                                                        </span>
                                                        <span className="rounded-full border border-blue-200 bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
                                                            {selectedTask?.task_system || '-'}
                                                        </span>
                                                        <span className="rounded-full border border-emerald-200 bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
                                                            {selectedTask?.theme || '-'}
                                                        </span>
                                                        <span className="rounded-full border border-slate-200 bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                                                            {selectedTask ? (taskDefinitionStatusMap[selectedTask.task_status]?.label || taskDefinitionStatusMap[0].label) : '-'}
                                                        </span>
                                                    </div>
                                                    <div className="mt-3 text-base font-semibold text-slate-800">
                                                        {selectedTask?.task_name || '-'}
                                                    </div>
                                                    <div className="mt-2 text-xs text-slate-500">
                                                        计划 ID #{selectedInstance.plan_id}
                                                    </div>
                                                </div>
                                            </div>
                                        </section>

                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="text-sm font-semibold text-slate-800">基础信息</div>
                                                <div className="mt-1 text-xs text-slate-500">任务基础字段与描述信息。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">任务名称</div>
                                                        <div className="mt-1 font-semibold text-slate-800">{selectedTask?.task_name || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">任务状态</div>
                                                        <div className="mt-1">
                                                            {selectedTask ? (
                                                                <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${taskDefinitionStatusMap[selectedTask.task_status]?.className || taskDefinitionStatusMap[0].className}`}>
                                                                    {taskDefinitionStatusMap[selectedTask.task_status]?.label || taskDefinitionStatusMap[0].label}
                                                                </span>
                                                            ) : (
                                                                '-'
                                                            )}
                                                        </div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">任务类型</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.task_type || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">所属系统</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.task_system || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">任务主题</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.theme || '-'}</div>
                                                    </div>
                                                </div>
                                                <div className={detailItemClass}>
                                                    <div className="text-xs text-slate-400">任务备注</div>
                                                    <div className="mt-1 whitespace-pre-wrap text-slate-700">{selectedTask?.remark || '-'}</div>
                                                </div>
                                            </div>
                                        </section>

                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="text-sm font-semibold text-slate-800">调度配置</div>
                                                <div className="mt-1 text-xs text-slate-500">执行节奏、偏移和数据日期。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">Cron 表达式</div>
                                                        <div className="mt-1 break-all font-mono text-xs text-slate-700">{selectedTask?.task_cron || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">轮询间隔</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.period ? `${selectedTask.period} ms` : '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">偏移量</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.offset ?? '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">数据日期</div>
                                                        <div className="mt-1 text-slate-700">{selectedInstance?.data_date || selectedTask?.data_date || '-'}</div>
                                                    </div>
                                                </div>
                                            </div>
                                        </section>

                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="text-sm font-semibold text-slate-800">任务追踪</div>
                                                <div className="mt-1 text-xs text-slate-500">依赖链路、参数与时间戳。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">依赖任务</div>
                                                        <div className="mt-1 break-all font-mono text-xs text-slate-700">{selectedTask?.depend_id || '无'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">任务参数</div>
                                                        <div className="mt-1 break-all font-mono text-xs text-slate-700">{selectedTask?.task_params || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">创建时间</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.create_time || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">更新时间</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.update_time || '-'}</div>
                                                    </div>
                                                </div>
                                            </div>
                                        </section>
                                    </div>
                                ),
                            },
                            {
                                key: 'dependency',
                                label: (
                                    <span className="inline-flex items-center gap-1.5">
                                        <GitBranch size={14} />
                                        任务依赖
                                    </span>
                                ),
                                children: dependencyPanelData ? (
                                    <div className="space-y-4">
                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="text-sm font-semibold text-slate-800">依赖诊断总览</div>
                                                <div className="mt-1 text-xs text-slate-500">
                                                    聚焦两个问题：当前实例为什么没完成，以及重跑当前实例会影响哪些下游任务。
                                                </div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="grid grid-cols-3 gap-3">
                                                    <div className="rounded-2xl border border-amber-100 bg-amber-50/70 px-4 py-3">
                                                        <div className="flex items-center gap-2 text-xs font-semibold text-amber-700">
                                                            <ArrowUpCircle size={14} />
                                                            阻塞上游
                                                        </div>
                                                        <div className="mt-2 text-2xl font-bold text-amber-700">
                                                            {dependencyPanelData.blockingUpstream.length}
                                                        </div>
                                                    </div>
                                                    <div className="rounded-2xl border border-red-100 bg-red-50/70 px-4 py-3">
                                                        <div className="flex items-center gap-2 text-xs font-semibold text-red-700">
                                                            <AlertCircle size={14} />
                                                            失败上游
                                                        </div>
                                                        <div className="mt-2 text-2xl font-bold text-red-700">
                                                            {dependencyPanelData.failedUpstreamCount}
                                                        </div>
                                                    </div>
                                                    <div className="rounded-2xl border border-blue-100 bg-blue-50/70 px-4 py-3">
                                                        <div className="flex items-center gap-2 text-xs font-semibold text-blue-700">
                                                            <ArrowDownCircle size={14} />
                                                            受影响下游
                                                        </div>
                                                        <div className="mt-2 text-2xl font-bold text-blue-700">
                                                            {dependencyPanelData.impactedDownstreamCount}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </section>

                                        <section className={detailSectionClass}>
                                            <div className={`${detailSectionHeaderClass} flex items-start justify-between gap-3`}>
                                                <div>
                                                    <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                                        <ArrowUpCircle size={16} className="text-amber-500" />
                                                        阻塞原因
                                                    </div>
                                                    <div className="mt-1 text-xs text-slate-500">
                                                        只展示当前实例未完成的上游任务，优先把失败和执行中的节点排在前面。
                                                    </div>
                                                </div>
                                                {renderRelationStatus(selectedInstance)}
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                {renderBlockingDependencyList(dependencyPanelData.blockingUpstream)}
                                            </div>
                                        </section>

                                        <section className={detailSectionClass}>
                                            <div className={`${detailSectionHeaderClass} flex items-start justify-between gap-3`}>
                                                <div>
                                                    <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                                        <ArrowDownCircle size={16} className="text-blue-500" />
                                                        重跑影响范围
                                                    </div>
                                                    <div className="mt-1 text-xs text-slate-500">
                                                        按下游层级展示传播路径，高亮标记会被本次重跑影响的任务。
                                                    </div>
                                                </div>
                                                <button
                                                    type="button"
                                                    onClick={() => onShowImpactedOnlyChange(!showImpactedOnly)}
                                                    className={`shrink-0 rounded-xl border px-3 py-2 text-xs font-semibold transition ${
                                                        showImpactedOnly
                                                            ? 'border-blue-200 bg-blue-50 text-blue-700'
                                                            : 'border-slate-200 bg-white text-slate-500 hover:bg-slate-50'
                                                    }`}
                                                >
                                                    {showImpactedOnly ? '显示全部下游' : '只看受影响任务'}
                                                </button>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                {renderDownstreamImpactTree(
                                                    dependencyPanelData.downstreamRootTaskIds,
                                                    1,
                                                    showImpactedOnly ? '当前没有会被重跑影响的下游任务。' : '当前任务暂时没有下游依赖。'
                                                )}
                                            </div>
                                        </section>
                                    </div>
                                ) : (
                                    <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50/60 px-4 py-12 text-center text-sm text-slate-500">
                                        暂无任务依赖信息。
                                    </div>
                                ),
                            },
                            {
                                key: 'execution',
                                label: '执行资源',
                                children: (
                                    <div className="space-y-4">
                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="text-sm font-semibold text-slate-800">执行资源</div>
                                                <div className="mt-1 text-xs text-slate-500">脚本和连接信息是任务真正执行的基础。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">数据源名称</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.datasource_name || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">数据源ID</div>
                                                        <div className="mt-1 font-mono text-xs text-slate-700">{selectedTask?.datasource_id ?? '-'}</div>
                                                    </div>
                                                    <div className={`md:col-span-2 ${detailItemClass}`}>
                                                        <div className="text-xs text-slate-400">连接说明</div>
                                                        <div className="mt-1 text-slate-700">执行时按数据源ID动态加载连接配置，不再从任务表读取连接串、账号、密码和驱动。</div>
                                                    </div>
                                                </div>
                                            </div>
                                        </section>

                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="text-sm font-semibold text-slate-800">执行脚本</div>
                                                <div className="mt-1 text-xs text-slate-500">这里直接展示脚本原文，便于排查执行路径和参数替换。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                {selectedTask?.script ? (
                                                    <div className="overflow-hidden rounded-xl border border-slate-200 bg-slate-950">
                                                        <div className="flex items-center justify-between border-b border-slate-800/80 px-4 py-2 text-[11px] uppercase tracking-[0.18em] text-slate-400">
                                                            <span>{selectedTask.task_type || 'SCRIPT'}</span>
                                                            <span>只读查看</span>
                                                        </div>
                                                        <pre className="max-h-[260px] overflow-auto p-4 font-mono text-xs leading-6 text-slate-100 whitespace-pre-wrap">
                                                            {selectedTask.script}
                                                        </pre>
                                                    </div>
                                                ) : (
                                                    <div className="text-sm text-slate-500">暂无脚本内容</div>
                                                )}
                                            </div>
                                        </section>
                                    </div>
                                ),
                            },
                            {
                                key: 'runtimeLog',
                                label: '执行日志',
                                children: (
                                    <div className="space-y-4">
                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                                    <Activity size={16} className="text-red-500" />
                                                    后台执行日志
                                                </div>
                                                <div className="mt-1 text-xs text-slate-500">按当前实例展示后台执行记录与逐步日志内容。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                {selectedInstanceLogs.length === 0 ? (
                                                    <div className="space-y-3">
                                                        <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50/60 px-4 py-8 text-center text-sm text-slate-500">
                                                            当前实例暂无执行日志。
                                                        </div>
                                                        {selectedInstance?.msg && (
                                                            <div className="rounded-2xl border border-red-200 bg-red-50/70 px-4 py-3">
                                                                <div className="text-xs font-semibold text-red-600">实例错误信息</div>
                                                                <div className="mt-1 whitespace-pre-wrap text-sm text-red-700">{selectedInstance.msg}</div>
                                                            </div>
                                                        )}
                                                    </div>
                                                ) : (
                                                    <div className="space-y-4">
                                                        {selectedInstanceLogs.map(log => {
                                                            const mappedStatus = instanceStatusMap[log.status] || instanceStatusMap[1];
                                                            const stepLines = log.content
                                                                .split('\n')
                                                                .map(item => item.trim())
                                                                .filter(Boolean);

                                                            return (
                                                                <div key={log.id} className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
                                                                    <div className="flex flex-col gap-2 border-b border-slate-100 bg-slate-50/70 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
                                                                        <div className="text-sm font-semibold text-slate-800">
                                                                            日志 #{log.id}
                                                                        </div>
                                                                        <div className="flex flex-wrap items-center gap-2 text-xs">
                                                                            <span className={`inline-flex rounded-full border px-2 py-1 font-semibold ${mappedStatus.className}`}>
                                                                                {mappedStatus.label}
                                                                            </span>
                                                                            <span className="inline-flex rounded-full bg-blue-50 px-2 py-1 text-blue-700">
                                                                                {log.trigger_type}
                                                                            </span>
                                                                            <span className="inline-flex rounded-full bg-slate-100 px-2 py-1 text-slate-600">
                                                                                耗时 {formatDuration(log.duration_ms)}
                                                                            </span>
                                                                            <span className="inline-flex rounded-full bg-slate-100 px-2 py-1 text-slate-600">
                                                                                {log.begin_time || log.create_time}
                                                                            </span>
                                                                        </div>
                                                                    </div>
                                                                    <div className="space-y-3 p-4">
                                                                        <div className={detailItemClass}>
                                                                            <div className="text-xs text-slate-400">执行摘要</div>
                                                                            <div className="mt-1 text-sm text-slate-700">{log.summary || '-'}</div>
                                                                        </div>
                                                                        <div className={detailItemClass}>
                                                                            <div className="mb-2 text-xs text-slate-400">逐步日志</div>
                                                                            <div className="overflow-hidden rounded-lg border border-slate-200 bg-slate-950/95">
                                                                                <div className="max-h-[280px] overflow-auto p-3 font-mono text-xs text-slate-100">
                                                                                    {stepLines.length === 0 ? (
                                                                                        <div className="text-slate-400">无日志明细</div>
                                                                                    ) : (
                                                                                        <div className="space-y-1.5">
                                                                                            {stepLines.map((line, index) => (
                                                                                                <div key={`${log.id}-${index}`} className="flex items-start gap-2">
                                                                                                    <span className="mt-0.5 shrink-0 text-[10px] text-slate-400">{String(index + 1).padStart(2, '0')}</span>
                                                                                                    <span className="leading-5 text-slate-100">{line}</span>
                                                                                                </div>
                                                                                            ))}
                                                                                        </div>
                                                                                    )}
                                                                                </div>
                                                                            </div>
                                                                        </div>
                                                                    </div>
                                                                </div>
                                                            );
                                                        })}
                                                    </div>
                                                )}
                                            </div>
                                        </section>
                                    </div>
                                ),
                            },
                            {
                                key: 'notify',
                                label: '通知配置',
                                children: (
                                    <div className="space-y-4">
                                        <section className={detailSectionClass}>
                                            <div className={detailSectionHeaderClass}>
                                                <div className="text-sm font-semibold text-slate-800">通知对象</div>
                                                <div className="mt-1 text-xs text-slate-500">完成和失败分别通知谁，避免运行结束后再手工补发消息。</div>
                                            </div>
                                            <div className={detailSectionBodyClass}>
                                                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">完成时通知</div>
                                                        <div className="mt-1 whitespace-pre-wrap text-slate-700">{selectedTask?.notification_completed || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">失败时通知</div>
                                                        <div className="mt-1 whitespace-pre-wrap text-slate-700">{selectedTask?.notification_failed || '-'}</div>
                                                    </div>
                                                </div>
                                            </div>
                                        </section>
                                    </div>
                                ),
                            },
                        ]}
                    />
                </div>
            )}
        </Drawer>
    );
};

export default TaskInstanceDetailDrawer;
