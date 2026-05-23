import React, { useEffect, useMemo, useState } from 'react';
import { Tag } from 'antd';
import {
    AlertCircle,
    ArrowDownCircle,
    ArrowUpCircle,
    CheckCircle2,
    ChevronDown,
    ChevronRight,
    Eye,
    EyeOff,
    GitBranch,
    List,
    Search,
    X,
} from 'lucide-react';
import { QuartzTaskStatus } from '../mockData';
import {
    detailSectionBodyClass,
    detailSectionClass,
    detailSectionHeaderClass,
    instanceStatusMap,
} from './constants';
import { BlockingDependencyItem, DependencyInsightData, DependencyRelationType, DownstreamImpactMeta } from './types';

interface TaskInstanceDependencyPanelProps {
    selectedInstance: QuartzTaskStatus;
    dependencyPanelData: DependencyInsightData;
    showImpactedOnly: boolean;
    onShowImpactedOnlyChange: (nextValue: boolean) => void;
    onLocateInstanceFromDependency: (instance: QuartzTaskStatus) => void;
}

type ImpactStatusFilter = 'all' | '1' | '2' | '3' | '4' | 'missing';

interface ImpactTraversalRow {
    item: DownstreamImpactMeta;
    level: number;
    routeKey: string;
}

const statusFilterOptions: Array<{ value: ImpactStatusFilter; label: string }> = [
    { value: 'all', label: '全部状态' },
    { value: '1', label: '等待中' },
    { value: '2', label: '执行中' },
    { value: '3', label: '成功' },
    { value: '4', label: '失败' },
    { value: 'missing', label: '暂无实例' },
];

const taskMetaPillClass = 'rounded border border-slate-200 bg-white px-2 py-0.5 text-[11px] text-slate-500';

const dependencyTypeMeta: Record<DependencyRelationType, { label: string; className: string }> = {
    DATA: { label: '数据依赖', className: 'border-blue-200 bg-blue-50 text-blue-700' },
    CONTROL: { label: '控制依赖', className: 'border-violet-200 bg-violet-50 text-violet-700' },
};

const TaskInstanceDependencyPanel: React.FC<TaskInstanceDependencyPanelProps> = ({
    selectedInstance,
    dependencyPanelData,
    showImpactedOnly,
    onShowImpactedOnlyChange,
    onLocateInstanceFromDependency,
}) => {
    const [impactKeyword, setImpactKeyword] = useState('');
    const [impactStatusFilter, setImpactStatusFilter] = useState<ImpactStatusFilter>('all');
    const [showBlockingDetail, setShowBlockingDetail] = useState(false);
    const [showImpactDetail, setShowImpactDetail] = useState(false);
    const normalizedImpactKeyword = impactKeyword.trim().toLowerCase();

    useEffect(() => {
        setShowBlockingDetail(false);
        setShowImpactDetail(false);
    }, [selectedInstance.id]);

    const downstreamItems = useMemo(
        () => Array.from(dependencyPanelData.downstreamMetaMap.values()),
        [dependencyPanelData.downstreamMetaMap]
    );

    const impactStats = useMemo(() => {
        const maxLevelByTaskId = new Map<number, number>();
        const collectLevel = (taskIds: number[], level: number, path: Set<number>) => {
            taskIds.forEach(taskId => {
                if (path.has(taskId)) {
                    return;
                }
                const item = dependencyPanelData.downstreamMetaMap.get(taskId);
                if (!item) {
                    return;
                }
                maxLevelByTaskId.set(taskId, Math.max(maxLevelByTaskId.get(taskId) || 0, level));
                collectLevel(item.directChildIds, level + 1, new Set([...path, taskId]));
            });
        };

        collectLevel(dependencyPanelData.downstreamRootTaskIds, 1, new Set([selectedInstance.plan_id]));

        return {
            maxLevel: Math.max(0, ...Array.from(maxLevelByTaskId.values())),
            waitingCount: downstreamItems.filter(item => item.relatedInstance?.status === 1).length,
            runningCount: downstreamItems.filter(item => item.relatedInstance?.status === 2).length,
            successCount: downstreamItems.filter(item => item.relatedInstance?.status === 3).length,
            failedCount: downstreamItems.filter(item => item.relatedInstance?.status === 4).length,
            missingCount: downstreamItems.filter(item => !item.relatedInstance).length,
        };
    }, [dependencyPanelData.downstreamMetaMap, dependencyPanelData.downstreamRootTaskIds, downstreamItems, selectedInstance.plan_id]);

    const impactTraversalRows = useMemo<ImpactTraversalRow[]>(() => {
        const rows: ImpactTraversalRow[] = [];

        const walk = (taskIds: number[], level: number, ancestors: number[], path: Set<number>) => {
            taskIds.forEach(taskId => {
                if (path.has(taskId)) {
                    return;
                }
                const item = dependencyPanelData.downstreamMetaMap.get(taskId);
                if (!item) {
                    return;
                }

                const route = [...ancestors, taskId];
                rows.push({
                    item,
                    level,
                    routeKey: route.join('>'),
                });
                walk(item.directChildIds, level + 1, route, new Set([...path, taskId]));
            });
        };

        walk(dependencyPanelData.downstreamRootTaskIds, 1, [selectedInstance.plan_id], new Set([selectedInstance.plan_id]));
        return rows;
    }, [dependencyPanelData.downstreamMetaMap, dependencyPanelData.downstreamRootTaskIds, selectedInstance.plan_id]);

    const impactFlatRows = useMemo<ImpactTraversalRow[]>(() => {
        const rowByTaskId = new Map<number, ImpactTraversalRow>();
        impactTraversalRows.forEach(row => {
            const existing = rowByTaskId.get(row.item.taskId);
            if (!existing || row.level < existing.level) {
                rowByTaskId.set(row.item.taskId, row);
            }
        });
        return Array.from(rowByTaskId.values()).sort((a, b) => {
            if (a.level !== b.level) {
                return a.level - b.level;
            }
            return a.item.taskId - b.item.taskId;
        });
    }, [impactTraversalRows]);

    const renderRelationStatus = (relation?: QuartzTaskStatus) => {
        if (!relation) {
            return (
                <span className="inline-flex rounded border border-slate-200 bg-slate-50 px-2 py-1 text-xs font-semibold text-slate-500">
                    暂无实例
                </span>
            );
        }

        const mappedStatus = instanceStatusMap[relation.status ?? -1];
        if (!mappedStatus) {
            return <Tag className="m-0">{relation.status ?? '-'}</Tag>;
        }

        return (
            <span className={`inline-flex rounded border px-2 py-1 text-xs font-semibold leading-none ${mappedStatus.className}`}>
                {mappedStatus.label}
            </span>
        );
    };

    const renderDependencyTypeTags = (dependencyTypes: DependencyRelationType[]) => (
        <>
            {dependencyTypes.map(type => {
                const meta = dependencyTypeMeta[type];
                return (
                    <span
                        key={type}
                        className={`rounded border px-2 py-0.5 text-[11px] font-semibold ${meta.className}`}
                    >
                        {meta.label}
                    </span>
                );
            })}
        </>
    );

    const matchesImpactKeyword = (item: DownstreamImpactMeta) => {
        if (!normalizedImpactKeyword) {
            return true;
        }
        return [
            String(item.taskId),
            item.taskName,
            item.taskSystem,
            item.theme,
            item.relatedInstance?.msg || '',
        ].some(value => value.toLowerCase().includes(normalizedImpactKeyword));
    };

    const matchesImpactStatus = (item: DownstreamImpactMeta) => {
        if (impactStatusFilter === 'all') {
            return true;
        }
        if (impactStatusFilter === 'missing') {
            return !item.relatedInstance;
        }
        return String(item.relatedInstance?.status) === impactStatusFilter;
    };

    const matchesImpactFocus = (item: DownstreamImpactMeta) =>
        !showImpactedOnly || item.impacted || item.hasImpactedDescendant;

    const visibleImpactRows = useMemo(() => {
        return impactFlatRows.filter(row =>
            matchesImpactFocus(row.item) && matchesImpactKeyword(row.item) && matchesImpactStatus(row.item)
        );
    }, [
        impactFlatRows,
        impactStatusFilter,
        normalizedImpactKeyword,
        showImpactedOnly,
    ]);

    const hasImpactFilterValue = normalizedImpactKeyword.length > 0 || impactStatusFilter !== 'all';

    const renderBlockingDependencyList = (items: BlockingDependencyItem[]) => {
        if (items.length === 0) {
            return (
                <div className="rounded-lg border border-emerald-100 bg-emerald-50/70 px-4 py-5 text-center">
                    <CheckCircle2 size={24} className="mx-auto text-emerald-500" />
                    <div className="mt-2 text-sm font-semibold text-emerald-700">前置任务已完成</div>
                    <div className="mt-1 text-xs text-emerald-600">当前实例没有未结束的上游阻塞点。</div>
                </div>
            );
        }

        return (
            <div className="max-h-72 overflow-y-auto rounded-lg border border-slate-200 bg-white">
                {items.map((item, index) => (
                    <div
                        key={item.taskId}
                        className={`flex gap-3 border-slate-100 px-4 py-3 ${index > 0 ? 'border-t' : ''}`}
                    >
                        <div className={`mt-1 h-2.5 w-2.5 shrink-0 rounded-full ${
                            item.relatedInstance?.status === 4
                                ? 'bg-red-500'
                                : item.relatedInstance?.status === 2
                                  ? 'bg-blue-500'
                                  : 'bg-amber-500'
                        }`} />
                        <div className="min-w-0 flex-1">
                            <div className="flex min-w-0 flex-wrap items-center gap-2">
                                <div className="min-w-0 truncate text-sm font-semibold text-slate-800" title={item.taskName}>
                                    {item.taskName}
                                </div>
                                <span className="rounded bg-slate-100 px-2 py-0.5 font-mono text-[11px] text-slate-500">
                                    #{item.taskId}
                                </span>
                                {item.missingTask && (
                                    <span className="rounded border border-amber-200 bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700">
                                        未纳入清单
                                    </span>
                                )}
                                {renderDependencyTypeTags(item.dependencyTypes)}
                            </div>
                            <div className="mt-2 flex flex-wrap items-center gap-1.5">
                                <span className={taskMetaPillClass}>L{item.level}</span>
                                <span className={taskMetaPillClass}>{item.taskSystem}</span>
                                <span className={taskMetaPillClass}>{item.theme}</span>
                                <span className={taskMetaPillClass}>{item.relatedInstance?.data_date || selectedInstance.data_date || '-'}</span>
                            </div>
                            {item.relatedInstance?.msg && (
                                <div className="mt-2 truncate text-xs text-slate-500" title={item.relatedInstance.msg || ''}>
                                    {item.relatedInstance.msg}
                                </div>
                            )}
                        </div>
                        <div className="flex shrink-0 flex-col items-end gap-2">
                            {renderRelationStatus(item.relatedInstance)}
                            <button
                                type="button"
                                onClick={() => item.relatedInstance && onLocateInstanceFromDependency(item.relatedInstance)}
                                disabled={!item.relatedInstance}
                                className="rounded border border-slate-200 bg-white px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
                            >
                                查看实例
                            </button>
                        </div>
                    </div>
                ))}
            </div>
        );
    };

    const renderImpactRow = (row: ImpactTraversalRow, index: number) => {
        const { item, level, routeKey } = row;
        const mappedStatus = instanceStatusMap[item.relatedInstance?.status ?? -1];
        const isLast = index === visibleImpactRows.length - 1;

        return (
            <div
                key={`${routeKey}-${index}`}
                className={`grid grid-cols-[minmax(0,1fr)_auto] gap-3 border-slate-100 px-4 py-3 transition ${
                    isLast ? '' : 'border-b'
                } ${item.impacted ? 'bg-blue-50/55' : 'bg-white hover:bg-slate-50/70'}`}
            >
                <div className="min-w-0">
                    <div className="flex min-w-0 items-start gap-2">
                        <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-blue-400" />
                        <div className="min-w-0 flex-1">
                            <div className="flex min-w-0 items-center gap-2">
                                <span className="shrink-0 rounded bg-slate-100 px-1.5 py-0.5 text-[11px] font-semibold text-slate-500">
                                    L{level}
                                </span>
                                <span className="min-w-0 truncate text-sm font-semibold text-slate-800" title={item.taskName}>
                                    {item.taskName}
                                </span>
                                <span className="shrink-0 rounded bg-slate-100 px-2 py-0.5 font-mono text-[11px] text-slate-500">
                                    #{item.taskId}
                                </span>
                            </div>
                            <div className="mt-2 flex flex-wrap items-center gap-1.5">
                                <span className={taskMetaPillClass}>{item.taskSystem}</span>
                                <span className={taskMetaPillClass}>{item.theme}</span>
                                <span className={taskMetaPillClass}>直接 {item.directChildIds.length}</span>
                                <span className={taskMetaPillClass}>累计 {item.descendantCount}</span>
                                {renderDependencyTypeTags(item.dependencyTypes)}
                                {item.missingTask && (
                                    <span className="rounded border border-amber-200 bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700">
                                        未纳入清单
                                    </span>
                                )}
                                {item.impacted ? (
                                    <span className="rounded border border-blue-200 bg-blue-100 px-2 py-0.5 text-[11px] font-semibold text-blue-700">
                                        会受影响
                                    </span>
                                ) : item.hasImpactedDescendant ? (
                                    <span className="rounded border border-indigo-200 bg-indigo-50 px-2 py-0.5 text-[11px] font-semibold text-indigo-700">
                                        下游受影响
                                    </span>
                                ) : (
                                    <span className="rounded border border-slate-200 bg-slate-50 px-2 py-0.5 text-[11px] font-semibold text-slate-500">
                                        已稳定
                                    </span>
                                )}
                            </div>
                            {item.relatedInstance?.msg && (
                                <div className="mt-2 truncate text-xs text-slate-500" title={item.relatedInstance.msg || ''}>
                                    {item.relatedInstance.msg}
                                </div>
                            )}
                        </div>
                    </div>
                </div>
                <div className="flex shrink-0 flex-col items-end gap-2">
                    {mappedStatus ? (
                        <span className={`inline-flex rounded border px-2 py-1 text-xs font-semibold leading-none ${mappedStatus.className}`}>
                            {mappedStatus.label}
                        </span>
                    ) : (
                        renderRelationStatus(item.relatedInstance)
                    )}
                    <button
                        type="button"
                        onClick={() => item.relatedInstance && onLocateInstanceFromDependency(item.relatedInstance)}
                        disabled={!item.relatedInstance}
                        className="rounded border border-slate-200 bg-white px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-600 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
                    >
                        查看实例
                    </button>
                </div>
            </div>
        );
    };

    return (
        <div className="space-y-4">
            <section className={detailSectionClass}>
                <div className={`${detailSectionHeaderClass} flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between`}>
                    <div className="min-w-0">
                        <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                            <GitBranch size={16} className="text-slate-500" />
                            依赖诊断
                        </div>
                        <div className="mt-1 truncate text-xs text-slate-500">
                            {dependencyPanelData.selectedTask?.task_name || `任务 #${selectedInstance.plan_id}`}
                        </div>
                    </div>
                    <div className="grid grid-cols-3 gap-2 sm:min-w-[360px]">
                        <div className="rounded-lg border border-amber-100 bg-amber-50 px-3 py-2">
                            <div className="flex items-center gap-1.5 text-[11px] font-semibold text-amber-700">
                                <ArrowUpCircle size={13} />
                                调度阻塞
                            </div>
                            <div className="mt-1 text-xl font-bold text-amber-700">{dependencyPanelData.blockingUpstream.length}</div>
                        </div>
                        <div className="rounded-lg border border-red-100 bg-red-50 px-3 py-2">
                            <div className="flex items-center gap-1.5 text-[11px] font-semibold text-red-700">
                                <AlertCircle size={13} />
                                失败
                            </div>
                            <div className="mt-1 text-xl font-bold text-red-700">{dependencyPanelData.failedUpstreamCount}</div>
                        </div>
                        <div className="rounded-lg border border-blue-100 bg-blue-50 px-3 py-2">
                            <div className="flex items-center gap-1.5 text-[11px] font-semibold text-blue-700">
                                <ArrowDownCircle size={13} />
                                数据影响
                            </div>
                            <div className="mt-1 text-xl font-bold text-blue-700">{dependencyPanelData.impactedDownstreamCount}</div>
                        </div>
                    </div>
                </div>
            </section>

            <section className={detailSectionClass}>
                <div className={`${detailSectionHeaderClass} flex items-start justify-between gap-3`}>
                    <div className="min-w-0">
                        <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                            <ArrowUpCircle size={16} className="text-amber-500" />
                            调度阻塞原因
                        </div>
                        <div className="mt-1 text-xs text-slate-500">
                            {dependencyPanelData.blockingUpstream.length > 0
                                ? `${dependencyPanelData.blockingUpstream.length} 个上游节点需要处理`
                                : '上游依赖正常'}
                        </div>
                    </div>
                    <div className="flex shrink-0 items-center gap-2">
                        {renderRelationStatus(selectedInstance)}
                        <button
                            type="button"
                            onClick={() => setShowBlockingDetail(prev => !prev)}
                            className="inline-flex h-8 w-8 items-center justify-center rounded border border-slate-200 bg-white text-slate-500 transition hover:bg-slate-50"
                            aria-label={showBlockingDetail ? '隐藏阻塞原因' : '显示阻塞原因'}
                            title={showBlockingDetail ? '隐藏' : '显示'}
                        >
                            {showBlockingDetail ? <ChevronDown size={15} /> : <ChevronRight size={15} />}
                        </button>
                    </div>
                </div>
                {showBlockingDetail && (
                    <div className={detailSectionBodyClass}>
                        {renderBlockingDependencyList(dependencyPanelData.blockingUpstream)}
                    </div>
                )}
            </section>

            <section className={detailSectionClass}>
                <div className={`${detailSectionHeaderClass} space-y-3`}>
                    <div className="flex flex-col gap-3 xl:flex-row xl:items-start xl:justify-between">
                        <div className="min-w-0">
                            <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                            <List size={16} className="text-blue-500" />
                                数据重跑影响范围
                            </div>
                            <div className="mt-1 text-xs text-slate-500">
                                仅沿数据依赖传播，共 {dependencyPanelData.downstreamTotalCount} 个下游节点，最深 L{impactStats.maxLevel || 0}
                            </div>
                        </div>
                        <div className="flex flex-wrap items-center gap-2">
                            <button
                                type="button"
                                onClick={() => setShowImpactDetail(prev => !prev)}
                                className="inline-flex h-8 items-center gap-1.5 rounded border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-600 transition hover:bg-slate-50"
                                aria-label={showImpactDetail ? '收起影响列表' : '展开影响列表'}
                            >
                                {showImpactDetail ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                            </button>
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-2 md:grid-cols-5">
                        <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
                            <div className="text-[11px] text-slate-400">等待</div>
                            <div className="mt-1 text-sm font-bold text-slate-700">{impactStats.waitingCount}</div>
                        </div>
                        <div className="rounded-lg border border-blue-100 bg-blue-50/60 px-3 py-2">
                            <div className="text-[11px] text-blue-500">执行中</div>
                            <div className="mt-1 text-sm font-bold text-blue-700">{impactStats.runningCount}</div>
                        </div>
                        <div className="rounded-lg border border-emerald-100 bg-emerald-50/60 px-3 py-2">
                            <div className="text-[11px] text-emerald-500">成功</div>
                            <div className="mt-1 text-sm font-bold text-emerald-700">{impactStats.successCount}</div>
                        </div>
                        <div className="rounded-lg border border-red-100 bg-red-50/60 px-3 py-2">
                            <div className="text-[11px] text-red-500">失败</div>
                            <div className="mt-1 text-sm font-bold text-red-700">{impactStats.failedCount}</div>
                        </div>
                        <div className="rounded-lg border border-amber-100 bg-amber-50/60 px-3 py-2">
                            <div className="text-[11px] text-amber-500">暂无实例</div>
                            <div className="mt-1 text-sm font-bold text-amber-700">{impactStats.missingCount}</div>
                        </div>
                    </div>

                    {showImpactDetail && (
                        <div className="space-y-3">
                            <div className="flex flex-wrap items-center gap-2">
                                <button
                                    type="button"
                                    onClick={() => onShowImpactedOnlyChange(!showImpactedOnly)}
                                    className={`inline-flex h-8 items-center gap-1.5 rounded border px-3 text-xs font-semibold transition ${
                                        showImpactedOnly
                                            ? 'border-blue-200 bg-blue-50 text-blue-700'
                                            : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                                    }`}
                                >
                                    {showImpactedOnly ? <Eye size={14} /> : <EyeOff size={14} />}
                                    {showImpactedOnly ? '显示全部' : '只看影响'}
                                </button>
                            </div>

                            <div className="grid gap-2 lg:grid-cols-[minmax(0,1fr)_160px_auto]">
                                <label className="relative block">
                                    <Search size={15} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                                    <input
                                        value={impactKeyword}
                                        onChange={event => setImpactKeyword(event.target.value)}
                                        placeholder="搜索任务、系统、主题、ID"
                                        className="h-9 w-full rounded border border-slate-200 bg-white pl-9 pr-9 text-sm text-slate-700 outline-none transition focus:border-blue-300 focus:ring-2 focus:ring-blue-100"
                                    />
                                    {impactKeyword && (
                                        <button
                                            type="button"
                                            onClick={() => setImpactKeyword('')}
                                            className="absolute right-2 top-1/2 inline-flex h-6 w-6 -translate-y-1/2 items-center justify-center rounded text-slate-400 transition hover:bg-slate-100 hover:text-slate-600"
                                            aria-label="清空搜索"
                                            title="清空搜索"
                                        >
                                            <X size={14} />
                                        </button>
                                    )}
                                </label>
                                <select
                                    value={impactStatusFilter}
                                    onChange={event => setImpactStatusFilter(event.target.value as ImpactStatusFilter)}
                                    className="h-9 rounded border border-slate-200 bg-white px-3 text-sm text-slate-700 outline-none transition focus:border-blue-300 focus:ring-2 focus:ring-blue-100"
                                >
                                    {statusFilterOptions.map(option => (
                                        <option key={option.value} value={option.value}>
                                            {option.label}
                                        </option>
                                    ))}
                                </select>
                                <button
                                    type="button"
                                    onClick={() => {
                                        setImpactKeyword('');
                                        setImpactStatusFilter('all');
                                    }}
                                    disabled={!hasImpactFilterValue}
                                    className="inline-flex h-9 items-center justify-center gap-1.5 rounded border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-45"
                                >
                                    <X size={14} />
                                    清空
                                </button>
                            </div>
                        </div>
                    )}
                </div>

                {showImpactDetail && (
                    <div className="p-5 pt-0">
                        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
                            <div className="flex items-center justify-between border-b border-slate-100 bg-slate-50 px-4 py-2 text-xs text-slate-500">
                                <div>
                                    展示 {visibleImpactRows.length} / {impactFlatRows.length} 项
                                </div>
                                <div className="font-mono">
                                    {selectedInstance.data_date || '-'}
                                </div>
                            </div>
                            {visibleImpactRows.length > 0 ? (
                                <div className="max-h-[520px] overflow-y-auto">
                                    {visibleImpactRows.map(renderImpactRow)}
                                </div>
                            ) : (
                                <div className="px-4 py-12 text-center text-sm text-slate-500">
                                    {hasImpactFilterValue
                                        ? '没有匹配的下游任务。'
                                        : showImpactedOnly
                                          ? '当前没有会被重跑影响的下游任务。'
                                          : '当前任务暂时没有下游依赖。'}
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </section>
        </div>
    );
};

export default TaskInstanceDependencyPanel;
