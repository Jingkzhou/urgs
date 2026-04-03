import React, { useMemo } from 'react';
import { Tag } from 'antd';
import { AlertCircle, ArrowDownCircle, ArrowUpCircle, CheckCircle2 } from 'lucide-react';
import { QuartzTaskStatus } from '../mockData';
import {
    detailSectionBodyClass,
    detailSectionClass,
    detailSectionHeaderClass,
    instanceStatusMap,
} from './constants';
import { BlockingDependencyItem, DependencyInsightData } from './types';

interface TaskInstanceDependencyPanelProps {
    selectedInstance: QuartzTaskStatus;
    dependencyPanelData: DependencyInsightData;
    showImpactedOnly: boolean;
    expandedImpactTaskIds: number[];
    onShowImpactedOnlyChange: (nextValue: boolean) => void;
    onToggleImpactTaskExpanded: (taskId: number) => void;
    onLocateInstanceFromDependency: (instance: QuartzTaskStatus) => void;
}

const TaskInstanceDependencyPanel: React.FC<TaskInstanceDependencyPanelProps> = ({
    selectedInstance,
    dependencyPanelData,
    showImpactedOnly,
    expandedImpactTaskIds,
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
                                    <span className="rounded-lg border border-white/80 bg-white/70 px-2 py-1">数据日期 {item.relatedInstance?.data_date || selectedInstance.data_date || '-'}</span>
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
                const item = dependencyPanelData.downstreamMetaMap.get(taskId);
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
                    const item = dependencyPanelData.downstreamMetaMap.get(taskId);
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
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">数据日期 {item.relatedInstance?.data_date || selectedInstance.data_date || '-'}</span>
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
    );
};

export default TaskInstanceDependencyPanel;
