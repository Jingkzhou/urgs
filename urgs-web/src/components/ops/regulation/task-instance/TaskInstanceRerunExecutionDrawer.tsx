import React, { useMemo } from 'react';
import { Drawer } from 'antd';
import { Play, X } from 'lucide-react';
import { QuartzTaskStatus } from '../mockData';
import { detailSectionBodyClass, detailSectionClass, detailSectionHeaderClass, instanceStatusMap } from './constants';
import { DependencyInsightData, DependencyRelationType, DownstreamImpactMeta } from './types';

interface TaskInstanceRerunExecutionDrawerProps {
    open: boolean;
    sourceInstance: QuartzTaskStatus | null;
    dependencyPanelData: DependencyInsightData | null;
    selectedStatusIds: number[];
    executing: boolean;
    onClose: () => void;
    onSelectedStatusIdsChange: (nextIds: number[]) => void;
    onExecute: () => void;
}

interface RerunDependencyRow {
    item: DownstreamImpactMeta;
    level: number;
    routeKey: string;
}

const taskMetaPillClass = 'rounded border border-slate-200 bg-white px-2 py-0.5 text-[11px] text-slate-500';

const dependencyTypeMeta: Record<DependencyRelationType, { label: string; className: string }> = {
    DATA: { label: '数据依赖', className: 'border-blue-200 bg-blue-50 text-blue-700' },
    CONTROL: { label: '控制依赖', className: 'border-violet-200 bg-violet-50 text-violet-700' },
};

const canRerunInstance = (instance?: QuartzTaskStatus) =>
    !!instance?.id && (instance.status === 3 || instance.status === 4);

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
        return (
            <span className="inline-flex rounded border border-slate-200 bg-slate-50 px-2 py-1 text-xs font-semibold text-slate-500">
                {relation.status ?? '-'}
            </span>
        );
    }

    return (
        <span className={`inline-flex rounded border px-2 py-1 text-xs font-semibold leading-none ${mappedStatus.className}`}>
            {mappedStatus.label}
        </span>
    );
};

const TaskInstanceRerunExecutionDrawer: React.FC<TaskInstanceRerunExecutionDrawerProps> = ({
    open,
    sourceInstance,
    dependencyPanelData,
    selectedStatusIds,
    executing,
    onClose,
    onSelectedStatusIdsChange,
    onExecute,
}) => {
    const selectedStatusIdSet = useMemo(() => new Set(selectedStatusIds), [selectedStatusIds]);

    const downstreamRows = useMemo<RerunDependencyRow[]>(() => {
        if (!sourceInstance || !dependencyPanelData) {
            return [];
        }

        const rows: RerunDependencyRow[] = [];
        const walk = (taskIds: number[], level: number, ancestors: number[], path: Set<number>) => {
            taskIds.forEach(taskId => {
                if (path.has(taskId)) {
                    return;
                }
                const item = dependencyPanelData.allDownstreamMetaMap.get(taskId);
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

        walk(dependencyPanelData.allDownstreamRootTaskIds, 1, [sourceInstance.plan_id], new Set([sourceInstance.plan_id]));

        const rowByTaskId = new Map<number, RerunDependencyRow>();
        rows.forEach(row => {
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
    }, [dependencyPanelData, sourceInstance]);

    const rerunnableRows = useMemo(
        () => downstreamRows.filter(row => canRerunInstance(row.item.relatedInstance)),
        [downstreamRows]
    );

    const selectedRunnableCount = useMemo(
        () => rerunnableRows.filter(row => selectedStatusIdSet.has(row.item.relatedInstance?.id || -1)).length,
        [rerunnableRows, selectedStatusIdSet]
    );

    const toggleStatusId = (statusId: number, checked: boolean) => {
        const nextIds = checked
            ? Array.from(new Set([...selectedStatusIds, statusId]))
            : selectedStatusIds.filter(id => id !== statusId);
        onSelectedStatusIdsChange(nextIds);
    };

    const selectAllRerunnable = () => {
        onSelectedStatusIdsChange(rerunnableRows
            .map(row => row.item.relatedInstance?.id)
            .filter((id): id is number => typeof id === 'number'));
    };

    return (
        <Drawer
            title="依赖重跑执行"
            placement="right"
            size={860}
            open={open}
            onClose={onClose}
            destroyOnHidden
        >
            {sourceInstance && dependencyPanelData ? (
                <div className="space-y-4">
                    <section className={detailSectionClass}>
                        <div className={`${detailSectionHeaderClass} flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between`}>
                            <div className="min-w-0">
                                <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                    <Play size={16} className="text-blue-500" />
                                    当前任务重跑后需要一起重跑的下游任务
                                </div>
                                <div className="mt-1 text-xs text-slate-500">
                                    源任务：{dependencyPanelData.selectedTask?.task_name || `任务 #${sourceInstance.plan_id}`}；这里只列下游依赖，不包含当前任务本身。
                                </div>
                            </div>
                            <div className="flex shrink-0 flex-wrap items-center gap-2">
                                <span className="rounded border border-slate-200 bg-white px-2.5 py-1 text-xs font-semibold text-slate-600">
                                    已选 {selectedRunnableCount} / 可选 {rerunnableRows.length}
                                </span>
                                <button
                                    type="button"
                                    onClick={selectAllRerunnable}
                                    disabled={rerunnableRows.length === 0 || executing}
                                    className="inline-flex h-8 items-center gap-1.5 rounded border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    全选可重跑
                                </button>
                                <button
                                    type="button"
                                    onClick={() => onSelectedStatusIdsChange([])}
                                    disabled={selectedStatusIds.length === 0 || executing}
                                    className="inline-flex h-8 items-center gap-1.5 rounded border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    <X size={14} />
                                    清空
                                </button>
                                <button
                                    type="button"
                                    onClick={onExecute}
                                    disabled={selectedRunnableCount === 0 || executing}
                                    className="inline-flex h-8 items-center gap-1.5 rounded border border-blue-200 bg-blue-50 px-3 text-xs font-semibold text-blue-700 transition hover:bg-blue-100 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-blue-50"
                                >
                                    <Play size={14} />
                                    {executing ? '重跑中...' : '重跑选中下游'}
                                </button>
                            </div>
                        </div>
                        <div className={detailSectionBodyClass}>
                            <div className="rounded-lg border border-blue-100 bg-blue-50/60 px-4 py-3 text-xs leading-5 text-blue-700">
                                这个页面用于回答当前任务重跑后哪些下游任务需要一起重跑。实际执行只提交你勾选的下游实例，且不会再次向下传播。
                            </div>
                        </div>
                    </section>

                    <section className={detailSectionClass}>
                        <div className={detailSectionHeaderClass}>
                            <div className="text-sm font-semibold text-slate-800">下游依赖清单</div>
                            <div className="mt-1 text-xs text-slate-500">
                                共 {downstreamRows.length} 个下游节点，按数据依赖和控制依赖合并去重后平铺展示。
                            </div>
                        </div>
                        <div className={detailSectionBodyClass}>
                            {downstreamRows.length === 0 ? (
                                <div className="rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-10 text-center text-sm text-slate-500">
                                    当前任务没有下游依赖。
                                </div>
                            ) : (
                                <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
                                    <div className="flex items-center justify-between border-b border-slate-100 bg-slate-50 px-4 py-2 text-xs text-slate-500">
                                        <span>展示 {downstreamRows.length} 个下游节点</span>
                                        <span className="font-mono">{sourceInstance.data_date || '-'}</span>
                                    </div>
                                    <div className="max-h-[560px] overflow-y-auto">
                                        {downstreamRows.map((row, index) => {
                                            const { item, level, routeKey } = row;
                                            const statusId = item.relatedInstance?.id;
                                            const canSelect = canRerunInstance(item.relatedInstance);
                                            const checked = !!statusId && selectedStatusIdSet.has(statusId);
                                            const isLast = index === downstreamRows.length - 1;
                                            return (
                                                <div
                                                    key={`${routeKey}-${item.taskId}`}
                                                    className={`grid grid-cols-[auto_minmax(0,1fr)_auto] items-start gap-3 border-slate-100 px-4 py-3 ${
                                                        isLast ? '' : 'border-b'
                                                    } ${checked ? 'bg-blue-50/45' : 'bg-white hover:bg-slate-50/70'}`}
                                                >
                                                    <input
                                                        type="checkbox"
                                                        checked={checked}
                                                        disabled={!statusId || !canSelect || executing}
                                                        onChange={event => statusId && toggleStatusId(statusId, event.target.checked)}
                                                        className="mt-1 h-4 w-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-40"
                                                        aria-label={`选择重跑 ${item.taskName}`}
                                                    />
                                                    <div className="min-w-0">
                                                        <div className="flex min-w-0 flex-wrap items-center gap-2">
                                                            <span className="rounded bg-slate-100 px-1.5 py-0.5 text-[11px] font-semibold text-slate-500">
                                                                L{level}
                                                            </span>
                                                            <span className="min-w-0 truncate text-sm font-semibold text-slate-800" title={item.taskName}>
                                                                {item.taskName}
                                                            </span>
                                                            <span className="shrink-0 rounded bg-slate-100 px-2 py-0.5 font-mono text-[11px] text-slate-500">
                                                                #{item.taskId}
                                                            </span>
                                                            {renderDependencyTypeTags(item.dependencyTypes)}
                                                        </div>
                                                        <div className="mt-2 flex flex-wrap items-center gap-1.5">
                                                            <span className={taskMetaPillClass}>{item.taskSystem}</span>
                                                            <span className={taskMetaPillClass}>{item.theme}</span>
                                                            <span className={taskMetaPillClass}>直接 {item.directChildIds.length}</span>
                                                            <span className={taskMetaPillClass}>累计 {item.descendantCount}</span>
                                                            <span className={taskMetaPillClass}>{item.relatedInstance?.data_date || sourceInstance.data_date || '-'}</span>
                                                            {!item.relatedInstance && (
                                                                <span className="rounded border border-amber-200 bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700">
                                                                    暂无实例
                                                                </span>
                                                            )}
                                                            {item.relatedInstance && !canSelect && (
                                                                <span className="rounded border border-slate-200 bg-slate-50 px-2 py-0.5 text-[11px] font-medium text-slate-500">
                                                                    当前状态不可重跑
                                                                </span>
                                                            )}
                                                            {item.missingTask && (
                                                                <span className="rounded border border-amber-200 bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700">
                                                                    未纳入清单
                                                                </span>
                                                            )}
                                                        </div>
                                                    </div>
                                                    <div className="flex shrink-0 flex-col items-end gap-2">
                                                        {renderRelationStatus(item.relatedInstance)}
                                                    </div>
                                                </div>
                                            );
                                        })}
                                    </div>
                                </div>
                            )}
                        </div>
                    </section>
                </div>
            ) : (
                <div className="rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-10 text-center text-sm text-slate-500">
                    暂无可展示的依赖重跑清单。
                </div>
            )}
        </Drawer>
    );
};

export default TaskInstanceRerunExecutionDrawer;
