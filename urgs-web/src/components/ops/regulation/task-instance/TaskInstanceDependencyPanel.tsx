import React, { useEffect, useMemo, useState } from 'react';
import { Tag } from 'antd';
import {
    AlertCircle,
    ArrowDownCircle,
    ArrowUpCircle,
    CheckCircle2,
    ChevronDown,
    ChevronLeft,
    ChevronRight,
    Eye,
    EyeOff,
    GitBranch,
    List,
    Search,
    X,
} from 'lucide-react';
import {
    QuartzDependencyImpactItemApiModel,
    QuartzDependencyImpactPageApiModel,
    queryQuartzBlockingPaths,
    queryQuartzDependencyImpact,
} from '@/api/ops';
import { QuartzTaskStatus } from '../mockData';
import {
    detailSectionBodyClass,
    detailSectionClass,
    detailSectionHeaderClass,
    instanceStatusMap,
} from './constants';
import {
    BlockingDependencyItem,
    DependencyInsightData,
    DependencyRelationItem,
    DependencyRelationType,
    DownstreamImpactMeta,
} from './types';

interface TaskInstanceDependencyPanelProps {
    selectedInstance: QuartzTaskStatus;
    dependencyPanelData: DependencyInsightData;
    showImpactedOnly: boolean;
    onShowImpactedOnlyChange: (nextValue: boolean) => void;
    onLocateInstanceFromDependency: (instance: QuartzTaskStatus) => void;
}

type ImpactStatusFilter = 'all' | '1' | '2' | '3' | '4' | 'missing';
type BlockingStatusFilter = 'all' | '1' | '2' | '4' | 'missing';

interface ImpactTraversalRow {
    item: DownstreamImpactMeta;
    level: number;
    routeKey: string;
}

interface LoadedBlockingPaths {
    paths: DependencyRelationItem[][];
    pageNum: number;
    pages: number;
    total: number;
    loading: boolean;
}

const impactPageSizeOptions = [20, 50, 100];
const emptyImpactPage: QuartzDependencyImpactPageApiModel = {
    pageNum: 1,
    pageSize: 50,
    total: 0,
    pages: 0,
    list: [],
    maxLevel: 0,
    waitingCount: 0,
    runningCount: 0,
    successCount: 0,
    failedCount: 0,
    missingCount: 0,
    impactedCount: 0,
};

const statusFilterOptions: Array<{ value: ImpactStatusFilter; label: string }> = [
    { value: 'all', label: '全部状态' },
    { value: '1', label: '等待中' },
    { value: '2', label: '执行中' },
    { value: '3', label: '成功' },
    { value: '4', label: '失败' },
    { value: 'missing', label: '暂无实例' },
];

const blockingStatusFilterOptions: Array<{ value: BlockingStatusFilter; label: string }> = [
    { value: 'all', label: '全部' },
    { value: '4', label: '失败' },
    { value: '2', label: '执行中' },
    { value: '1', label: '等待中' },
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
    const [impactPage, setImpactPage] = useState(1);
    const [impactPageSize, setImpactPageSize] = useState(50);
    const [impactLoading, setImpactLoading] = useState(false);
    const [impactPageData, setImpactPageData] = useState<QuartzDependencyImpactPageApiModel>(emptyImpactPage);
    const [showBlockingDetail, setShowBlockingDetail] = useState(false);
    const [showImpactDetail, setShowImpactDetail] = useState(false);
    const [blockingStatusFilter, setBlockingStatusFilter] = useState<BlockingStatusFilter>('all');
    const [expandedBlockingRootIds, setExpandedBlockingRootIds] = useState<Set<number>>(new Set());
    const [loadedBlockingPaths, setLoadedBlockingPaths] = useState<Record<number, LoadedBlockingPaths>>({});
    const normalizedImpactKeyword = impactKeyword.trim().toLowerCase();

    useEffect(() => {
        setShowBlockingDetail(false);
        setShowImpactDetail(false);
        setBlockingStatusFilter('all');
        setExpandedBlockingRootIds(new Set());
        setLoadedBlockingPaths({});
        setImpactPage(1);
    }, [selectedInstance.id]);

    const impactStats = {
        maxLevel: impactPageData.maxLevel || 0,
        waitingCount: impactPageData.waitingCount || 0,
        runningCount: impactPageData.runningCount || 0,
        successCount: impactPageData.successCount || 0,
        failedCount: impactPageData.failedCount || 0,
        missingCount: impactPageData.missingCount || 0,
        impactedCount: impactPageData.impactedCount || 0,
    };

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

    useEffect(() => {
        setImpactPage(1);
    }, [normalizedImpactKeyword, impactStatusFilter, showImpactedOnly, selectedInstance.id]);

    useEffect(() => {
        let canceled = false;
        const loadImpactPage = async () => {
            setImpactLoading(true);
            try {
                const response = await queryQuartzDependencyImpact({
                    statusId: selectedInstance.id,
                    planId: selectedInstance.plan_id,
                    dataDate: selectedInstance.data_date,
                    keyword: normalizedImpactKeyword || undefined,
                    status: impactStatusFilter === 'all' ? undefined : impactStatusFilter,
                    impactedOnly: showImpactedOnly,
                    pageNum: impactPage,
                    pageSize: impactPageSize,
                });
                if (canceled) return;
                if (response?.success) {
                    setImpactPageData(response.data || emptyImpactPage);
                } else {
                    console.warn(response?.msg || '加载依赖影响失败');
                    setImpactPageData(emptyImpactPage);
                }
            } catch (error) {
                if (!canceled) {
                    console.warn(error);
                    setImpactPageData(emptyImpactPage);
                }
            } finally {
                if (!canceled) {
                    setImpactLoading(false);
                }
            }
        };

        void loadImpactPage();
        return () => {
            canceled = true;
        };
    }, [
        impactPage,
        impactPageSize,
        impactStatusFilter,
        normalizedImpactKeyword,
        selectedInstance.data_date,
        selectedInstance.id,
        selectedInstance.plan_id,
        showImpactedOnly,
    ]);

    const impactTotalPages = Math.max(1, Number(impactPageData.pages || 1));

    useEffect(() => {
        setImpactPage(prev => Math.min(prev, impactTotalPages));
    }, [impactTotalPages]);

    const normalizeImpactRow = (item: QuartzDependencyImpactItemApiModel): ImpactTraversalRow => {
        const relatedInstance = item.statusId
            ? {
                id: Number(item.statusId),
                plan_id: Number(item.taskId),
                data_date: item.dataDate || selectedInstance.data_date,
                status: item.status ?? null,
                begin_time: item.beginTime || null,
                update_time: item.updateTime || null,
                end_time: item.endTime || null,
                msg: item.msg || null,
                create_time: item.createTime || '',
                create_date: (item.createTime || selectedInstance.data_date || '').slice(0, 10).replaceAll('-', ''),
            }
            : undefined;

        return {
            item: {
                taskId: Number(item.taskId),
                taskName: item.taskName || `任务 #${item.taskId}`,
                taskSystem: item.taskSystem || '-',
                theme: item.theme || '-',
                relatedInstance,
                missingTask: !!item.missingTask,
                dependencyTypes: (item.dependencyTypes || ['DATA'])
                    .filter((type): type is 'DATA' | 'CONTROL' => type === 'DATA' || type === 'CONTROL'),
                impacted: !!item.impacted,
                hasImpactedDescendant: !!item.hasImpactedDescendant,
                directChildIds: [],
                directChildCount: item.directChildCount || 0,
                descendantCount: item.descendantCount || 0,
            },
            level: item.level || 1,
            routeKey: `${selectedInstance.plan_id}>${item.taskId}`,
        };
    };

    const pagedImpactRows = useMemo(
        () => (impactPageData.list || []).map(normalizeImpactRow),
        [impactPageData.list, selectedInstance.data_date, selectedInstance.plan_id]
    );

    const impactTotal = Number(impactPageData.total || 0);
    const impactStartIndex = impactTotal === 0 ? 0 : (impactPage - 1) * impactPageSize + 1;
    const impactEndIndex = Math.min(impactPage * impactPageSize, impactTotal);

    const hasImpactFilterValue = normalizedImpactKeyword.length > 0 || impactStatusFilter !== 'all';
    const selectedStatusLabel = instanceStatusMap[selectedInstance.status ?? -1]?.label || '未知状态';
    const isWaitingInstance = selectedInstance.status === 1;

    const normalizeBlockingPathNode = (item: QuartzDependencyImpactItemApiModel): DependencyRelationItem => {
        const relatedInstance = item.statusId
            ? {
                id: Number(item.statusId),
                plan_id: Number(item.taskId),
                data_date: item.dataDate || selectedInstance.data_date,
                status: item.status ?? null,
                begin_time: item.beginTime || null,
                update_time: item.updateTime || null,
                end_time: item.endTime || null,
                msg: item.msg || null,
                create_time: item.createTime || '',
                create_date: (item.createTime || selectedInstance.data_date || '').slice(0, 10).replaceAll('-', ''),
            }
            : undefined;
        return {
            taskId: Number(item.taskId),
            taskName: item.taskName || `任务 #${item.taskId}`,
            taskSystem: item.taskSystem || '-',
            theme: item.theme || '-',
            relatedInstance,
            missingTask: !!item.missingTask,
            dependencyTypes: (item.dependencyTypes || [])
                .filter((type): type is DependencyRelationType => type === 'DATA' || type === 'CONTROL'),
        };
    };

    const loadBlockingPathPage = async (item: BlockingDependencyItem, pageNum: number) => {
        setLoadedBlockingPaths(previous => ({
            ...previous,
            [item.taskId]: {
                paths: previous[item.taskId]?.paths || item.paths,
                pageNum: previous[item.taskId]?.pageNum || 0,
                pages: previous[item.taskId]?.pages || 1,
                total: previous[item.taskId]?.total || item.pathCount,
                loading: true,
            },
        }));
        try {
            const response = await queryQuartzBlockingPaths({
                statusId: selectedInstance.id,
                planId: selectedInstance.plan_id,
                dataDate: selectedInstance.data_date,
                rootTaskId: item.taskId,
                pageNum,
                pageSize: 20,
            });
            if (!response?.success) {
                throw new Error(response?.msg || '加载阻塞路径失败');
            }
            const data = response.data;
            const incomingPaths = (data?.list || []).map(path => path.map(normalizeBlockingPathNode));
            setLoadedBlockingPaths(previous => ({
                ...previous,
                [item.taskId]: {
                    paths: pageNum === 1
                        ? incomingPaths
                        : [...(previous[item.taskId]?.paths || []), ...incomingPaths],
                    pageNum: Number(data?.pageNum || pageNum),
                    pages: Math.max(1, Number(data?.pages || 1)),
                    total: Number(data?.total || item.pathCount),
                    loading: false,
                },
            }));
        } catch (error) {
            console.warn(error);
            setLoadedBlockingPaths(previous => ({
                ...previous,
                [item.taskId]: {
                    paths: previous[item.taskId]?.paths || item.paths,
                    pageNum: previous[item.taskId]?.pageNum || 0,
                    pages: previous[item.taskId]?.pages || 1,
                    total: previous[item.taskId]?.total || item.pathCount,
                    loading: false,
                },
            }));
        }
    };

    const renderBlockingDependencyList = (items: BlockingDependencyItem[]) => {
        if (!isWaitingInstance) {
            return (
                <div className="rounded-lg border border-slate-200 bg-slate-50/80 px-4 py-5 text-center">
                    <CheckCircle2 size={24} className="mx-auto text-slate-500" />
                    <div className="mt-2 text-sm font-semibold text-slate-700">当前实例已是{selectedStatusLabel}</div>
                    <div className="mt-1 text-xs text-slate-500">
                        调度阻塞只对等待中实例生效；如上游正在重跑，请以数据重跑影响范围判断下游是否需要补跑。
                    </div>
                </div>
            );
        }

        if (items.length === 0) {
            return (
                <div className="rounded-lg border border-emerald-100 bg-emerald-50/70 px-4 py-5 text-center">
                    <CheckCircle2 size={24} className="mx-auto text-emerald-500" />
                    <div className="mt-2 text-sm font-semibold text-emerald-700">前置任务已完成</div>
                    <div className="mt-1 text-xs text-emerald-600">当前实例没有未结束的上游阻塞点。</div>
                </div>
            );
        }

        const filteredItems = items.filter(item => {
            if (blockingStatusFilter === 'all') return true;
            if (blockingStatusFilter === 'missing') return !item.relatedInstance;
            return String(item.relatedInstance?.status) === blockingStatusFilter;
        });

        return (
            <div className="space-y-3">
                <div className="flex flex-wrap items-center gap-2">
                    {blockingStatusFilterOptions.map(option => (
                        <button
                            key={option.value}
                            type="button"
                            onClick={() => setBlockingStatusFilter(option.value)}
                            className={`rounded border px-2.5 py-1 text-xs font-semibold transition ${
                                blockingStatusFilter === option.value
                                    ? 'border-amber-200 bg-amber-50 text-amber-700'
                                    : 'border-slate-200 bg-white text-slate-500 hover:bg-slate-50'
                            }`}
                        >
                            {option.label}
                        </button>
                    ))}
                </div>

                {filteredItems.length === 0 ? (
                    <div className="rounded-lg border border-slate-200 bg-slate-50 px-4 py-5 text-center text-xs text-slate-500">
                        当前筛选条件下没有根因
                    </div>
                ) : (
                    <div className="max-h-[480px] space-y-2 overflow-y-auto pr-1">
                        {filteredItems.map(item => {
                            const expanded = expandedBlockingRootIds.has(item.taskId);
                            const loadedPaths = loadedBlockingPaths[item.taskId];
                            const visiblePaths = expanded
                                ? loadedPaths?.paths || item.paths
                                : item.paths.slice(0, 1);
                            return (
                                <div key={item.taskId} className="rounded-lg border border-slate-200 bg-white">
                                    <div className="flex gap-3 px-4 py-3">
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
                                                <span className={taskMetaPillClass}>最深 L{item.level}</span>
                                                <span className={taskMetaPillClass}>{item.pathCount} 条阻塞路径</span>
                                                {item.missingTask && (
                                                    <span className="rounded border border-amber-200 bg-amber-50 px-2 py-0.5 text-[11px] font-medium text-amber-700">
                                                        未纳入清单
                                                    </span>
                                                )}
                                                {renderDependencyTypeTags(item.dependencyTypes)}
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

                                    <div className="space-y-2 border-t border-slate-100 bg-slate-50/70 px-4 py-3">
                                        {visiblePaths.map((path, pathIndex) => (
                                            <div key={path.map(node => node.taskId).join('>')} className="flex flex-wrap items-center gap-1.5">
                                                <span className="text-[11px] font-semibold text-slate-400">路径 {pathIndex + 1}</span>
                                                <span className="rounded border border-slate-200 bg-white px-2 py-1 text-xs font-semibold text-slate-700">
                                                    当前任务
                                                </span>
                                                {path.map(node => (
                                                    <React.Fragment key={node.taskId}>
                                                        <ChevronLeft size={13} className="shrink-0 text-slate-300" />
                                                        <button
                                                            type="button"
                                                            onClick={() => node.relatedInstance && onLocateInstanceFromDependency(node.relatedInstance)}
                                                            disabled={!node.relatedInstance}
                                                            className={`max-w-[220px] truncate rounded border px-2 py-1 text-xs font-medium transition ${
                                                                node.taskId === item.taskId
                                                                    ? 'border-amber-200 bg-amber-50 text-amber-700'
                                                                    : 'border-slate-200 bg-white text-slate-600 hover:border-amber-200 hover:text-amber-700'
                                                            } disabled:cursor-default`}
                                                            title={`${node.taskName} #${node.taskId}`}
                                                        >
                                                            {node.taskName}
                                                        </button>
                                                    </React.Fragment>
                                                ))}
                                            </div>
                                        ))}
                                        {item.pathCount > 1 && (
                                            <button
                                                type="button"
                                                onClick={() => {
                                                    setExpandedBlockingRootIds(previous => {
                                                        const next = new Set(previous);
                                                        if (next.has(item.taskId)) {
                                                            next.delete(item.taskId);
                                                        } else {
                                                            next.add(item.taskId);
                                                        }
                                                        return next;
                                                    });
                                                    if (!expanded && !loadedPaths) {
                                                        void loadBlockingPathPage(item, 1);
                                                    }
                                                }}
                                                className="inline-flex items-center gap-1 text-xs font-semibold text-amber-700 hover:text-amber-800"
                                            >
                                                {expanded ? <ChevronDown size={13} /> : <ChevronRight size={13} />}
                                                {expanded ? '收起其他路径' : `查看全部 ${item.pathCount} 条路径`}
                                            </button>
                                        )}
                                        {expanded && loadedPaths?.loading && (
                                            <div className="text-xs text-slate-400">正在加载路径...</div>
                                        )}
                                        {expanded && loadedPaths && !loadedPaths.loading && loadedPaths.pageNum < loadedPaths.pages && (
                                            <button
                                                type="button"
                                                onClick={() => void loadBlockingPathPage(item, loadedPaths.pageNum + 1)}
                                                className="inline-flex items-center gap-1 rounded border border-slate-200 bg-white px-2.5 py-1 text-xs font-semibold text-slate-600 hover:border-amber-200 hover:text-amber-700"
                                            >
                                                加载更多（已显示 {loadedPaths.paths.length}/{loadedPaths.total}）
                                            </button>
                                        )}
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
        );
    };

    const renderImpactRow = (row: ImpactTraversalRow, index: number) => {
        const { item, level, routeKey } = row;
        const mappedStatus = instanceStatusMap[item.relatedInstance?.status ?? -1];
        const isLast = index === pagedImpactRows.length - 1;

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
                                <span className={taskMetaPillClass}>直接 {item.directChildCount ?? item.directChildIds.length}</span>
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
                                阻塞根因
                            </div>
                            <div className="mt-1 text-xl font-bold text-amber-700">{dependencyPanelData.blockingUpstream.length}</div>
                        </div>
                        <div className="rounded-lg border border-red-100 bg-red-50 px-3 py-2">
                            <div className="flex items-center gap-1.5 text-[11px] font-semibold text-red-700">
                                <AlertCircle size={13} />
                                失败根因
                            </div>
                            <div className="mt-1 text-xl font-bold text-red-700">{dependencyPanelData.failedUpstreamCount}</div>
                        </div>
                        <div className="rounded-lg border border-blue-100 bg-blue-50 px-3 py-2">
                            <div className="flex items-center gap-1.5 text-[11px] font-semibold text-blue-700">
                                <ArrowDownCircle size={13} />
                                数据影响
                            </div>
                            <div className="mt-1 text-xl font-bold text-blue-700">{impactStats.impactedCount}</div>
                        </div>
                    </div>
                </div>
            </section>

            {(dependencyPanelData.graphTruncated || dependencyPanelData.instanceDataTruncated) && (
                <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-xs text-amber-700">
                    当前依赖链路或同日实例数量较大，页面已启用保护性截断：
                    {dependencyPanelData.graphTruncated && ' 依赖图仅展示前 800 个节点。'}
                    {dependencyPanelData.instanceDataTruncated && ` 同日实例已加载 ${dependencyPanelData.loadedDateInstanceCount || 0}/${dependencyPanelData.totalDateInstanceCount || 0} 条。`}
                    如需完整链路，建议增加后端按当前任务分页查询依赖接口。
                </div>
            )}

            <section className={detailSectionClass}>
                <div className={`${detailSectionHeaderClass} flex items-start justify-between gap-3`}>
                    <div className="min-w-0">
                        <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                            <ArrowUpCircle size={16} className="text-amber-500" />
                            调度阻塞原因
                        </div>
                        <div className="mt-1 text-xs text-slate-500">
                            {!isWaitingInstance
                                ? `当前实例已是${selectedStatusLabel}`
                                : dependencyPanelData.blockingUpstream.length > 0
                                ? `${dependencyPanelData.blockingUpstream.length} 个根因 · ${dependencyPanelData.blockingNodeCount} 个阻塞节点 · 最深 L${dependencyPanelData.maxBlockingLevel}`
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
                                仅沿数据依赖传播，当前匹配 {impactTotal} 个下游节点，最深 L{impactStats.maxLevel || 0}
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
                                        setImpactPage(1);
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
                            <div className="flex flex-col gap-2 border-b border-slate-100 bg-slate-50 px-4 py-2 text-xs text-slate-500 md:flex-row md:items-center md:justify-between">
                                <div className="min-w-0">
                                    展示 {impactStartIndex}-{impactEndIndex} / {impactTotal} 项
                                </div>
                                <div className="flex flex-wrap items-center gap-2">
                                    <select
                                        value={impactPageSize}
                                        onChange={event => {
                                            setImpactPageSize(Number(event.target.value));
                                            setImpactPage(1);
                                        }}
                                        className="h-7 rounded border border-slate-200 bg-white px-2 text-xs text-slate-600 outline-none"
                                        aria-label="每页展示数量"
                                    >
                                        {impactPageSizeOptions.map(size => (
                                            <option key={size} value={size}>
                                                每页 {size}
                                            </option>
                                        ))}
                                    </select>
                                    <button
                                        type="button"
                                        onClick={() => setImpactPage(prev => Math.max(1, prev - 1))}
                                        disabled={impactPage <= 1}
                                        className="inline-flex h-7 w-7 items-center justify-center rounded border border-slate-200 bg-white text-slate-500 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-45"
                                        aria-label="上一页"
                                        title="上一页"
                                    >
                                        <ChevronLeft size={14} />
                                    </button>
                                    <span className="font-mono text-slate-500">
                                        {impactPage}/{impactTotalPages}
                                    </span>
                                    <button
                                        type="button"
                                        onClick={() => setImpactPage(prev => Math.min(impactTotalPages, prev + 1))}
                                        disabled={impactPage >= impactTotalPages}
                                        className="inline-flex h-7 w-7 items-center justify-center rounded border border-slate-200 bg-white text-slate-500 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-45"
                                        aria-label="下一页"
                                        title="下一页"
                                    >
                                        <ChevronRight size={14} />
                                    </button>
                                    <div className="font-mono">
                                        {selectedInstance.data_date || '-'}
                                    </div>
                                </div>
                            </div>
                            {impactTotal > 0 ? (
                                <div className="max-h-[520px] overflow-y-auto">
                                    {impactLoading ? (
                                        <div className="px-4 py-10 text-center text-sm text-slate-500">
                                            加载依赖影响中...
                                        </div>
                                    ) : (
                                        pagedImpactRows.map(renderImpactRow)
                                    )}
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
