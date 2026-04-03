import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Drawer, Tag, Tabs, message } from 'antd';
import { Activity, AlertCircle, ArrowDownCircle, ArrowUpCircle, CalendarRange, CheckCircle2, Clock3, Eye, GitBranch, Play, Search, Square } from 'lucide-react';
import dayjs from 'dayjs';
import { QuartzTask, QuartzTaskExecutionLog, QuartzTaskStatus } from './mockData';
import Pagination from '@/components/common/Pagination';
import {
    queryQuartzTaskLog,
    queryQuartzTasks,
    queryQuartzTaskStatus,
    QuartzTaskApiModel,
    QuartzTaskLogApiModel,
    QuartzTaskStatusApiModel
} from '@/api/ops';

interface DependencyRelationItem {
    taskId: number;
    taskName: string;
    taskSystem: string;
    theme: string;
    relatedInstance?: QuartzTaskStatus;
    missingTask?: boolean;
}

interface BlockingDependencyItem extends DependencyRelationItem {
    level: number;
}

interface DownstreamImpactNode extends DependencyRelationItem {
    level: number;
    impacted: boolean;
    children: DownstreamImpactNode[];
}

interface DependencyInsightData {
    selectedTask?: QuartzTask;
    blockingUpstream: BlockingDependencyItem[];
    downstreamTree: DownstreamImpactNode[];
    downstreamTotalCount: number;
    impactedDownstreamCount: number;
    failedUpstreamCount: number;
}

interface RowContextMenuState {
    x: number;
    y: number;
    instance: QuartzTaskStatus;
}

interface TaskInstanceStats {
    waitingInstances: number;
    runningInstances: number;
    successInstances: number;
    failedInstances: number;
}

interface TaskInstanceProps {
    onStatsChange?: (stats: TaskInstanceStats) => void;
}

const instanceStatusMap: Record<number, { label: string; className: string; color: string }> = {
    1: { label: '等待中', className: 'bg-slate-100 text-slate-600 border-slate-200', color: 'default' },
    2: { label: '执行中', className: 'bg-blue-50 text-blue-600 border-blue-200', color: 'processing' },
    3: { label: '成功', className: 'bg-emerald-50 text-emerald-600 border-emerald-200', color: 'success' },
    4: { label: '失败', className: 'bg-red-50 text-red-600 border-red-200', color: 'error' },
};

const taskDefinitionStatusMap: Record<number, { label: string; className: string }> = {
    0: { label: '正常', className: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
    1: { label: '暂停', className: 'bg-amber-50 text-amber-600 border-amber-200' },
};

const detailItemClass = 'rounded-xl border border-slate-200 bg-slate-50/70 px-4 py-3';
const detailSectionClass = 'rounded-2xl border border-slate-200 bg-white shadow-sm';
const detailSectionHeaderClass = 'border-b border-slate-100 px-5 py-4';
const detailSectionBodyClass = 'space-y-4 p-5';
const headerCellClass = 'px-4 py-3 font-semibold whitespace-nowrap';
const tableCellClass = 'px-4 py-3 align-middle';
const monoCellClass = `${tableCellClass} font-mono text-xs text-slate-600`;
const batchActionClass = 'inline-flex h-9 items-center gap-1.5 rounded-xl border px-3.5 text-xs font-semibold shadow-sm transition-all duration-200 hover:-translate-y-0.5 hover:shadow';
const relationCardClass = 'rounded-2xl border border-slate-200 bg-white p-4 shadow-sm';
const contextMenuItemClass = 'flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm transition-colors hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-45';
const incompleteInstanceStatuses = new Set([1, 2, 4]);
const blockingStatusRank: Record<number, number> = {
    4: 0,
    2: 1,
    1: 2,
};

const parseDependIds = (dependId?: string | null): number[] => {
    if (!dependId) return [];
    return dependId
        .split(',')
        .map(item => Number(item.trim()))
        .filter(id => Number.isInteger(id));
};

const formatDuration = (durationMs?: number | null) => {
    if (durationMs === undefined || durationMs === null) return '-';
    if (durationMs < 1000) return `${durationMs} ms`;
    const seconds = Math.floor(durationMs / 1000);
    if (seconds < 60) return `${seconds} 秒`;
    const minutes = Math.floor(seconds / 60);
    const remainSeconds = seconds % 60;
    return remainSeconds === 0 ? `${minutes} 分钟` : `${minutes} 分 ${remainSeconds} 秒`;
};

const toTaskTypeLabel = (taskType?: number | null) => {
    if (taskType === 2) return 'SQL';
    if (taskType === 1) return 'SHELL';
    return 'SHELL';
};

const normalizeTask = (item: QuartzTaskApiModel): QuartzTask => {
    const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
    return {
        id: Number(item.id),
        task_name: item.taskName || '',
        task_bean: item.taskBean ?? null,
        task_params: item.taskParams ?? null,
        task_cron: item.taskCron || '',
        task_status: Number(item.taskStatus ?? 0) as 0 | 1,
        remark: item.remark ?? null,
        update_time: item.updateTime || now,
        create_time: item.createTime || now,
        task_type: toTaskTypeLabel(item.taskType),
        url: item.url ?? null,
        script: item.exePath ?? null,
        depend_id: item.dependId ?? null,
        username: item.username ?? null,
        password: item.password ?? null,
        driver: item.driver ?? null,
        datasource_id: null,
        datasource_name: null,
        period: item.period ?? null,
        task_system: item.taskSystem ?? null,
        theme: item.theme ?? null,
        offset: item.offset ?? null,
        data_date: item.dataDate ?? null,
        job_key: item.jobKey ?? null,
        notification_completed: item.notificationCompleted ?? null,
        notification_failed: item.notificationFailed ?? null,
    };
};

const normalizeStatus = (item: QuartzTaskStatusApiModel): QuartzTaskStatus => {
    const createTime = item.createTime || dayjs().format('YYYY-MM-DD HH:mm:ss');
    return {
        id: Number(item.id),
        plan_id: Number(item.planId),
        data_date: item.dataDate || '',
        status: item.status === null || item.status === undefined ? null : Number(item.status),
        begin_time: item.beginTime || null,
        update_time: item.updateTime || null,
        end_time: item.endTime || null,
        msg: item.msg || null,
        create_time: createTime,
        create_date: dayjs(createTime).format('YYYYMMDD'),
    };
};

const normalizeLog = (item: QuartzTaskLogApiModel): QuartzTaskExecutionLog => {
    const processStatus = Number(item.processStatus ?? 0);
    const mappedStatus = processStatus === 3 ? 3 : processStatus === 4 ? 4 : 1;
    return {
        id: Number(item.id),
        task_id: Number(item.taskId),
        instance_id: null,
        data_date: null,
        status: (mappedStatus as 0 | 1 | 2 | 3),
        trigger_type: '定时触发',
        begin_time: null,
        end_time: null,
        duration_ms: item.processDuration ?? null,
        summary: item.taskName || null,
        content: item.processLog || '',
        create_time: item.createTime || dayjs().format('YYYY-MM-DD HH:mm:ss'),
    };
};

const TaskInstance: React.FC<TaskInstanceProps> = ({ onStatsChange }) => {
    const todayDate = dayjs().format('YYYY-MM-DD');
    const [taskList, setTaskList] = useState<QuartzTask[]>([]);
    const [instanceList, setInstanceList] = useState<QuartzTaskStatus[]>([]);
    const [logList, setLogList] = useState<QuartzTaskExecutionLog[]>([]);
    const [searchKeyword, setSearchKeyword] = useState('');
    const [taskSystemFilter, setTaskSystemFilter] = useState('');
    const [dataDateFilter, setDataDateFilter] = useState('');
    const [createDateFilter, setCreateDateFilter] = useState(todayDate);
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [selectedInstance, setSelectedInstance] = useState<QuartzTaskStatus | null>(null);
    const [selectedInstanceIds, setSelectedInstanceIds] = useState<number[]>([]);
    const [instanceDetailTabKey, setInstanceDetailTabKey] = useState<'overview' | 'task' | 'schedule' | 'dependency' | 'execution' | 'runtimeLog' | 'notify'>('overview');
    const [showImpactedOnly, setShowImpactedOnly] = useState(false);
    const [rowContextMenu, setRowContextMenu] = useState<RowContextMenuState | null>(null);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);

    const loadTasks = useCallback(async () => {
        try {
            const pageSize = 500;
            const firstResponse = await queryQuartzTasks({ pageNum: 1, pageSize });
            if (!firstResponse?.success) {
                throw new Error(firstResponse?.msg || '加载任务失败');
            }
            const totalPages = Number(firstResponse.data?.pages || 1);
            const mergedTasks = [...(firstResponse.data?.list || []).map(normalizeTask)];

            if (totalPages > 1) {
                const restResponses = await Promise.all(
                    Array.from({ length: totalPages - 1 }, (_, index) =>
                        queryQuartzTasks({ pageNum: index + 2, pageSize })
                    )
                );
                restResponses.forEach(response => {
                    if (response?.success) {
                        mergedTasks.push(...(response.data?.list || []).map(normalizeTask));
                    }
                });
            }

            setTaskList(mergedTasks);
        } catch (error: any) {
            message.error(error?.message || '加载任务失败');
        }
    }, []);

    const loadInstances = useCallback(async () => {
        try {
            const pageSize = 500;
            const beginDate = createDateFilter ? createDateFilter.replaceAll('-', '') : undefined;
            const firstResponse = await queryQuartzTaskStatus({ pageNum: 1, pageSize, beginDate });
            if (!firstResponse?.success) {
                throw new Error(firstResponse?.msg || '加载实例失败');
            }

            const totalPages = Number(firstResponse.data?.pages || 1);
            const mergedInstances = [...(firstResponse.data?.list || []).map(normalizeStatus)];

            if (totalPages > 1) {
                const restResponses = await Promise.all(
                    Array.from({ length: totalPages - 1 }, (_, index) =>
                        queryQuartzTaskStatus({ pageNum: index + 2, pageSize, beginDate })
                    )
                );
                restResponses.forEach(response => {
                    if (response?.success) {
                        mergedInstances.push(...(response.data?.list || []).map(normalizeStatus));
                    }
                });
            }

            setInstanceList(mergedInstances);
        } catch (error: any) {
            message.error(error?.message || '加载实例失败');
        }
    }, [createDateFilter]);

    useEffect(() => {
        loadTasks();
    }, [loadTasks]);

    useEffect(() => {
        loadInstances();
    }, [loadInstances]);

    useEffect(() => {
        const taskId = selectedInstance?.plan_id;
        if (!taskId) {
            return;
        }
        let canceled = false;
        const loadLogs = async () => {
            try {
                const response = await queryQuartzTaskLog(taskId, 1, 200);
                if (!response?.success) {
                    throw new Error(response?.msg || '加载执行日志失败');
                }
                if (canceled) return;
                const mapped = (response.data?.list || []).map(normalizeLog);
                setLogList(mapped);
            } catch (error: any) {
                if (canceled) return;
                message.error(error?.message || '加载执行日志失败');
            }
        };
        loadLogs();
        return () => {
            canceled = true;
        };
    }, [selectedInstance?.plan_id]);

    const taskNameMap = useMemo(
        () => new Map(taskList.map(task => [task.id, task.task_name])),
        [taskList]
    );
    const taskMap = useMemo(
        () => new Map(taskList.map(task => [task.id, task])),
        [taskList]
    );
    const taskSystemOptions = useMemo(
        () => Array.from(new Set(taskList.map(task => task.task_system).filter(Boolean))).sort((a, b) => a.localeCompare(b, 'zh-Hans-CN')),
        [taskList]
    );

    const filteredInstances = useMemo(() => {
        return instanceList.filter(instance => {
            const task = taskMap.get(instance.plan_id);
            const keyword = searchKeyword.trim().toLowerCase();
            const matchesKeyword = !keyword || [
                String(instance.id),
                String(instance.plan_id),
                task?.task_name || '',
                task?.task_system || '',
                task?.theme || '',
                task?.remark || '',
                instance.msg || '',
            ].some(item => item.toLowerCase().includes(keyword));
            const matchesTaskSystem = !taskSystemFilter || (task?.task_system || '') === taskSystemFilter;
            const matchesDataDate = !dataDateFilter || instance.data_date === dataDateFilter;
            const matchesCreateDate = !createDateFilter || instance.create_date === createDateFilter.replaceAll('-', '');
            const matchesStatus = statusFilter === '' || String(instance.status ?? '') === statusFilter;

            return matchesKeyword && matchesTaskSystem && matchesDataDate && matchesCreateDate && matchesStatus;
        });
    }, [createDateFilter, dataDateFilter, instanceList, searchKeyword, statusFilter, taskMap, taskSystemFilter]);

    useEffect(() => {
        onStatsChange?.({
            waitingInstances: filteredInstances.filter(instance => instance.status === 1).length,
            runningInstances: filteredInstances.filter(instance => instance.status === 2).length,
            successInstances: filteredInstances.filter(instance => instance.status === 3).length,
            failedInstances: filteredInstances.filter(instance => instance.status === 4).length,
        });
    }, [filteredInstances, onStatsChange]);

    const pagedInstances = useMemo(() => {
        const start = (currentPage - 1) * pageSize;
        return filteredInstances.slice(start, start + pageSize);
    }, [filteredInstances, currentPage, pageSize]);

    useEffect(() => {
        setCurrentPage(1);
    }, [searchKeyword, taskSystemFilter, statusFilter, dataDateFilter, createDateFilter]);

    useEffect(() => {
        const totalPages = Math.max(1, Math.ceil(filteredInstances.length / pageSize));
        if (currentPage > totalPages) {
            setCurrentPage(totalPages);
        }
    }, [filteredInstances.length, pageSize, currentPage]);

    const instanceByPlanDate = useMemo(() => {
        const map = new Map<string, QuartzTaskStatus>();
        instanceList.forEach(instance => {
            const key = `${instance.plan_id}_${instance.data_date}`;
            const existing = map.get(key);
            if (!existing) {
                map.set(key, instance);
                return;
            }
            const existingTime = dayjs(existing.update_time || existing.create_time).valueOf();
            const incomingTime = dayjs(instance.update_time || instance.create_time).valueOf();
            if (incomingTime >= existingTime) {
                map.set(key, instance);
            }
        });
        return map;
    }, [instanceList]);

    const latestInstanceByPlan = useMemo(() => {
        const map = new Map<number, QuartzTaskStatus>();
        instanceList.forEach(instance => {
            const existing = map.get(instance.plan_id);
            if (!existing) {
                map.set(instance.plan_id, instance);
                return;
            }
            const existingTime = dayjs(existing.update_time || existing.create_time).valueOf();
            const incomingTime = dayjs(instance.update_time || instance.create_time).valueOf();
            if (incomingTime >= existingTime) {
                map.set(instance.plan_id, instance);
            }
        });
        return map;
    }, [instanceList]);

    const upstreamTaskIdMap = useMemo(() => {
        const map = new Map<number, number[]>();
        taskList.forEach(task => {
            map.set(task.id, parseDependIds(task.depend_id));
        });
        return map;
    }, [taskList]);

    const downstreamTaskIdMap = useMemo(() => {
        const map = new Map<number, number[]>();
        taskList.forEach(task => {
            parseDependIds(task.depend_id).forEach(preTaskId => {
                const next = map.get(preTaskId) || [];
                next.push(task.id);
                map.set(preTaskId, next);
            });
        });
        return map;
    }, [taskList]);

    const dependencyPanelData = useMemo<DependencyInsightData | null>(() => {
        if (!selectedInstance) return null;

        const selectedTask = taskMap.get(selectedInstance.plan_id);
        const pickRelatedInstance = (taskId: number) => {
            return instanceByPlanDate.get(`${taskId}_${selectedInstance.data_date}`) || latestInstanceByPlan.get(taskId);
        };

        const toRelationItem = (taskId: number): DependencyRelationItem => {
            const relationTask = taskMap.get(taskId);
            return {
                taskId,
                taskName: relationTask?.task_name || `任务 #${taskId}`,
                taskSystem: relationTask?.task_system || '-',
                theme: relationTask?.theme || '-',
                relatedInstance: pickRelatedInstance(taskId),
                missingTask: !relationTask,
            };
        };

        const blockingUpstreamMap = new Map<number, BlockingDependencyItem>();
        const upstreamQueue = (upstreamTaskIdMap.get(selectedInstance.plan_id) || []).map(taskId => ({ taskId, level: 1 }));
        const visitedUpstreamIds = new Set<number>();
        while (upstreamQueue.length > 0) {
            const current = upstreamQueue.shift();
            if (!current || visitedUpstreamIds.has(current.taskId)) {
                continue;
            }
            visitedUpstreamIds.add(current.taskId);

            const relation = toRelationItem(current.taskId);
            const status = relation.relatedInstance?.status;
            if (!status || incompleteInstanceStatuses.has(status)) {
                blockingUpstreamMap.set(current.taskId, {
                    ...relation,
                    level: current.level,
                });
            }

            (upstreamTaskIdMap.get(current.taskId) || []).forEach(nextTaskId => {
                if (!visitedUpstreamIds.has(nextTaskId)) {
                    upstreamQueue.push({ taskId: nextTaskId, level: current.level + 1 });
                }
            });
        }

        let downstreamTotalCount = 0;
        let impactedDownstreamCount = 0;
        const buildDownstreamTree = (taskId: number, level: number, path: Set<number>): DownstreamImpactNode[] => {
            return (downstreamTaskIdMap.get(taskId) || []).flatMap(childTaskId => {
                if (path.has(childTaskId)) {
                    return [];
                }
                downstreamTotalCount += 1;
                const relation = toRelationItem(childTaskId);
                const impacted = relation.relatedInstance?.status !== 3;
                if (impacted) {
                    impactedDownstreamCount += 1;
                }
                const nextPath = new Set(path);
                nextPath.add(childTaskId);
                return [{
                    ...relation,
                    level,
                    impacted,
                    children: buildDownstreamTree(childTaskId, level + 1, nextPath),
                }];
            });
        };

        const blockingUpstream = Array.from(blockingUpstreamMap.values()).sort((a, b) => {
            const aStatus = a.relatedInstance?.status ?? 99;
            const bStatus = b.relatedInstance?.status ?? 99;
            const rankDiff = (blockingStatusRank[aStatus] ?? 99) - (blockingStatusRank[bStatus] ?? 99);
            if (rankDiff !== 0) {
                return rankDiff;
            }
            return a.level - b.level;
        });

        return {
            selectedTask,
            blockingUpstream,
            downstreamTree: buildDownstreamTree(selectedInstance.plan_id, 1, new Set([selectedInstance.plan_id])),
            downstreamTotalCount,
            impactedDownstreamCount,
            failedUpstreamCount: blockingUpstream.filter(item => item.relatedInstance?.status === 4).length,
        };
    }, [downstreamTaskIdMap, instanceByPlanDate, latestInstanceByPlan, selectedInstance, taskMap, upstreamTaskIdMap]);

    const updateInstance = (instanceId: number, updater: (instance: QuartzTaskStatus) => QuartzTaskStatus) => {
        setInstanceList(prev => prev.map(instance => instance.id === instanceId ? updater(instance) : instance));
        setSelectedInstance(prev => prev && prev.id === instanceId ? updater(prev) : prev);
    };

    const updateInstances = (instanceIds: number[], updater: (instance: QuartzTaskStatus) => QuartzTaskStatus) => {
        const targetSet = new Set(instanceIds);
        setInstanceList(prev => prev.map(instance => targetSet.has(instance.id) ? updater(instance) : instance));
        setSelectedInstance(prev => prev && targetSet.has(prev.id) ? updater(prev) : prev);
    };

    const markInstanceRunning = (instance: QuartzTaskStatus) => {
        const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
        return {
            ...instance,
            status: 2,
            begin_time: instance.begin_time || now,
            update_time: now,
            end_time: null,
            msg: '实例已手工触发执行。',
        };
    };

    const markInstanceStopped = (instance: QuartzTaskStatus) => {
        const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
        return {
            ...instance,
            status: 4,
            begin_time: instance.begin_time || now,
            update_time: now,
            end_time: now,
            msg: '实例已被强制停止。',
        };
    };

    const markInstancePassed = (instance: QuartzTaskStatus) => {
        const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
        return {
            ...instance,
            status: 3,
            begin_time: instance.begin_time || now,
            update_time: now,
            end_time: now,
            msg: '实例已被强制通过。',
        };
    };

    const handleExecuteInstance = (instance: QuartzTaskStatus) => {
        updateInstance(instance.id, markInstanceRunning);
        message.success(`已执行实例 #${instance.id}`);
    };

    const handleForceStopInstance = (instance: QuartzTaskStatus) => {
        updateInstance(instance.id, markInstanceStopped);
        message.success(`已强制停止实例 #${instance.id}`);
    };

    const handleForcePassInstance = (instance: QuartzTaskStatus) => {
        updateInstance(instance.id, markInstancePassed);
        message.success(`已强制通过实例 #${instance.id}`);
    };

    const closeRowContextMenu = () => {
        setRowContextMenu(null);
    };

    const openRowContextMenu = (instance: QuartzTaskStatus, event: React.MouseEvent<HTMLTableRowElement>) => {
        event.preventDefault();
        setRowContextMenu({
            x: event.clientX,
            y: event.clientY,
            instance,
        });
    };

    const handleOpenInstanceDetail = (instance: QuartzTaskStatus, tab: typeof instanceDetailTabKey = 'overview') => {
        setSelectedInstance(instance);
        setInstanceDetailTabKey(tab);
        setShowImpactedOnly(false);
    };

    const locateInstanceFromDependency = (instance: QuartzTaskStatus) => {
        setSelectedInstance(instance);
        setInstanceDetailTabKey('overview');
    };

    useEffect(() => {
        if (!rowContextMenu) return;

        const handleEscape = (event: KeyboardEvent) => {
            if (event.key === 'Escape') {
                closeRowContextMenu();
            }
        };

        window.addEventListener('keydown', handleEscape);
        return () => {
            window.removeEventListener('keydown', handleEscape);
        };
    }, [rowContextMenu]);

    const visibleInstanceIds = useMemo(() => pagedInstances.map(instance => instance.id), [pagedInstances]);
    const allVisibleSelected = visibleInstanceIds.length > 0 && visibleInstanceIds.every(id => selectedInstanceIds.includes(id));

    const toggleSelectAllVisible = (checked: boolean) => {
        if (checked) {
            setSelectedInstanceIds(prev => Array.from(new Set([...prev, ...visibleInstanceIds])));
            return;
        }
        setSelectedInstanceIds(prev => prev.filter(id => !visibleInstanceIds.includes(id)));
    };

    const toggleSelectInstance = (instanceId: number, checked: boolean) => {
        setSelectedInstanceIds(prev => checked
            ? Array.from(new Set([...prev, instanceId]))
            : prev.filter(id => id !== instanceId));
    };

    const handleBatchExecute = () => {
        if (selectedInstanceIds.length === 0) return;
        updateInstances(selectedInstanceIds, markInstanceRunning);
        message.success(`已批量执行 ${selectedInstanceIds.length} 条实例`);
    };

    const handleBatchForceStop = () => {
        if (selectedInstanceIds.length === 0) return;
        updateInstances(selectedInstanceIds, markInstanceStopped);
        message.success(`已批量强制停止 ${selectedInstanceIds.length} 条实例`);
    };

    const handleBatchForcePass = () => {
        if (selectedInstanceIds.length === 0) return;
        updateInstances(selectedInstanceIds, markInstancePassed);
        message.success(`已批量强制通过 ${selectedInstanceIds.length} 条实例`);
    };

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
                                    onClick={() => item.relatedInstance && locateInstanceFromDependency(item.relatedInstance)}
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

    const nodeHasImpact = (node: DownstreamImpactNode): boolean =>
        node.impacted || node.children.some(child => nodeHasImpact(child));

    const renderDownstreamImpactTree = (items: DownstreamImpactNode[], emptyText: string) => {
        const visibleItems = showImpactedOnly
            ? items.filter(item => nodeHasImpact(item))
            : items;

        if (visibleItems.length === 0) {
            return (
                <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50/60 px-4 py-12 text-center text-sm text-slate-500">
                    {emptyText}
                </div>
            );
        }

        return (
            <div className="space-y-3">
                {visibleItems.map(item => {
                    const mappedStatus = instanceStatusMap[item.relatedInstance?.status ?? -1];
                    return (
                        <div key={`${item.taskId}-${item.level}`} className="space-y-3">
                            <div
                                className={`rounded-2xl border p-4 shadow-sm ${
                                    item.impacted
                                        ? 'border-blue-200 bg-blue-50/60'
                                        : 'border-slate-200 bg-white'
                                }`}
                                style={{ marginLeft: Math.min((item.level - 1) * 18, 72) }}
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
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">层级 L{item.level}</span>
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">系统 {item.taskSystem}</span>
                                            <span className="rounded-lg border border-slate-200 bg-white/70 px-2 py-1">主题 {item.theme}</span>
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
                                            onClick={() => item.relatedInstance && locateInstanceFromDependency(item.relatedInstance)}
                                            disabled={!item.relatedInstance}
                                            className="inline-flex items-center rounded-lg border border-slate-200 bg-white px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-600 disabled:cursor-not-allowed disabled:border-slate-200 disabled:bg-slate-100 disabled:text-slate-400"
                                        >
                                            查看实例
                                        </button>
                                    </div>
                                </div>
                            </div>
                            {item.children.length > 0 && renderDownstreamImpactTree(item.children, emptyText)}
                        </div>
                    );
                })}
            </div>
        );
    };

    const selectedTask = selectedInstance ? taskMap.get(selectedInstance.plan_id) : null;
    const selectedInstanceLogs = useMemo(() => {
        if (!selectedInstance) return [] as QuartzTaskExecutionLog[];
        const exactLogs = logList.filter(log => log.instance_id === selectedInstance.id);
        if (exactLogs.length > 0) {
            return [...exactLogs].sort((a, b) => dayjs(a.create_time).valueOf() - dayjs(b.create_time).valueOf());
        }
        return logList
            .filter(log => log.task_id === selectedInstance.plan_id && log.data_date === selectedInstance.data_date)
            .sort((a, b) => dayjs(a.create_time).valueOf() - dayjs(b.create_time).valueOf());
    }, [logList, selectedInstance]);
    const rowContextMenuStyle = rowContextMenu ? {
        left: Math.max(12, Math.min(rowContextMenu.x, (typeof window !== 'undefined' ? window.innerWidth : rowContextMenu.x) - 244)),
        top: Math.max(12, Math.min(rowContextMenu.y, (typeof window !== 'undefined' ? window.innerHeight : rowContextMenu.y) - 208)),
    } : undefined;

    const invokeRowContextAction = (action: 'execute' | 'stop' | 'pass' | 'detail') => {
        if (!rowContextMenu) return;
        const { instance } = rowContextMenu;
        closeRowContextMenu();

        if (action === 'execute') {
            handleExecuteInstance(instance);
            return;
        }
        if (action === 'stop') {
            handleForceStopInstance(instance);
            return;
        }
        if (action === 'pass') {
            handleForcePassInstance(instance);
            return;
        }
        handleOpenInstanceDetail(instance);
    };

    return (
        <>
            <div className="space-y-4">
                <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
                    <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                        <div>
                            <div className="text-lg font-bold text-slate-800">任务实例</div>
                            <div className="text-sm text-slate-500 mt-1">
                                围绕 `t_quartz_task_status` 跟踪批量实例状态、时间线和失败信息。
                            </div>
                        </div>
                        <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500">
                            <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5">
                                实例 {filteredInstances.length}
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-3 py-1.5 text-blue-700">
                                执行中 {filteredInstances.filter(instance => instance.status === 2).length}
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-red-50 px-3 py-1.5 text-red-700">
                                失败 {filteredInstances.filter(instance => instance.status === 4).length}
                            </span>
                        </div>
                    </div>

                    <div className="mt-5 grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-6">
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">搜索条件</div>
                            <div className="relative">
                                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                                <input
                                    value={searchKeyword}
                                    onChange={(event) => setSearchKeyword(event.target.value)}
                                    placeholder="实例ID / 计划ID / 消息 / 主题 / 备注"
                                    className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                                />
                            </div>
                        </label>
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">系统主体</div>
                            <select
                                value={taskSystemFilter}
                                onChange={(event) => setTaskSystemFilter(event.target.value)}
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            >
                                <option value="">全部系统</option>
                                {taskSystemOptions.map(item => (
                                    <option key={item} value={item}>
                                        {item}
                                    </option>
                                ))}
                            </select>
                        </label>
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">状态</div>
                            <select
                                value={statusFilter}
                                onChange={(event) => setStatusFilter(event.target.value)}
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            >
                                <option value="">全部状态</option>
                                <option value="1">等待中</option>
                                <option value="2">执行中</option>
                                <option value="3">成功</option>
                                <option value="4">失败</option>
                            </select>
                        </label>
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">数据日期</div>
                            <input
                                type="date"
                                value={dataDateFilter}
                                onChange={(event) => setDataDateFilter(event.target.value)}
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </label>
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">创建日期</div>
                            <input
                                type="date"
                                value={createDateFilter}
                                onChange={(event) => setCreateDateFilter(event.target.value)}
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </label>
                    </div>

                    {selectedInstanceIds.length > 0 && (
                        <div className="mt-4 flex flex-col gap-3 rounded-2xl border border-red-100 bg-gradient-to-r from-red-50/80 via-white to-red-50/60 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
                            <div className="text-sm font-medium text-slate-700">
                                已选择 <span className="font-bold text-red-600">{selectedInstanceIds.length}</span> 条实例
                            </div>
                            <div className="flex flex-wrap items-center gap-2">
                                <button
                                    onClick={handleBatchExecute}
                                    className={`${batchActionClass} border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100`}
                                >
                                    <Play size={14} />
                                    批量执行任务
                                </button>
                                <button
                                    onClick={handleBatchForceStop}
                                    className={`${batchActionClass} border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100`}
                                >
                                    <Square size={14} />
                                    批量强制停止
                                </button>
                                <button
                                    onClick={handleBatchForcePass}
                                    className={`${batchActionClass} border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100`}
                                >
                                    <CheckCircle2 size={14} />
                                    批量强制通过
                                </button>
                                <button
                                    onClick={() => setSelectedInstanceIds([])}
                                    className={`${batchActionClass} border-slate-200 bg-white text-slate-600 hover:bg-slate-50`}
                                >
                                    清空选择
                                </button>
                            </div>
                        </div>
                    )}
                </div>

                {rowContextMenu && (
                    <>
                        <div
                            className="fixed inset-0 z-40"
                            onClick={closeRowContextMenu}
                            onContextMenu={(event) => {
                                event.preventDefault();
                                closeRowContextMenu();
                            }}
                        />
                        <div
                            className="fixed z-50 w-60 overflow-hidden rounded-2xl border border-slate-200 bg-white p-2 shadow-[0_18px_50px_rgba(15,23,42,0.18)]"
                            style={rowContextMenuStyle}
                            onClick={(event) => event.stopPropagation()}
                            onContextMenu={(event) => event.preventDefault()}
                        >
                            <div className="px-3 py-2">
                                <div className="text-xs font-semibold text-slate-500">实例 #{rowContextMenu.instance.id}</div>
                                <div className="mt-1 truncate text-sm font-medium text-slate-800">
                                    {taskNameMap.get(rowContextMenu.instance.plan_id) || '任务详情'}
                                </div>
                            </div>
                            <div className="my-1 h-px bg-slate-100" />
                            <button
                                onClick={() => invokeRowContextAction('execute')}
                                disabled={rowContextMenu.instance.status === 2}
                                className={contextMenuItemClass}
                            >
                                <Play size={14} className="text-blue-600" />
                                执行任务
                            </button>
                            <button
                                onClick={() => invokeRowContextAction('stop')}
                                disabled={rowContextMenu.instance.status === 3 || rowContextMenu.instance.status === 4}
                                className={contextMenuItemClass}
                            >
                                <Square size={14} className="text-amber-600" />
                                强制停止
                            </button>
                            <button
                                onClick={() => invokeRowContextAction('pass')}
                                disabled={rowContextMenu.instance.status === 3}
                                className={contextMenuItemClass}
                            >
                                <CheckCircle2 size={14} className="text-emerald-600" />
                                强制通过
                            </button>
                            <button
                                onClick={() => invokeRowContextAction('detail')}
                                className={contextMenuItemClass}
                            >
                                <Eye size={14} className="text-slate-600" />
                                查看详情
                            </button>
                        </div>
                    </>
                )}

                <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full min-w-[1692px] table-fixed text-sm text-left">
                            <colgroup>
                                <col style={{ width: 56 }} />
                                <col style={{ width: 96 }} />
                                <col style={{ width: 180 }} />
                                <col style={{ width: 110 }} />
                                <col style={{ width: 110 }} />
                                <col style={{ width: 112 }} />
                                <col style={{ width: 96 }} />
                                <col style={{ width: 168 }} />
                                <col style={{ width: 168 }} />
                                <col style={{ width: 168 }} />
                                <col style={{ width: 168 }} />
                                <col style={{ width: 260 }} />
                            </colgroup>
                            <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500 border-b border-slate-200">
                                <tr>
                                    <th className={headerCellClass}>
                                        <input
                                            type="checkbox"
                                            checked={allVisibleSelected}
                                            onChange={(event) => toggleSelectAllVisible(event.target.checked)}
                                            className="h-4 w-4 rounded border-slate-300 text-red-600 focus:ring-red-500"
                                        />
                                    </th>
                                    <th className={headerCellClass}>计划ID</th>
                                    <th className={headerCellClass}>任务名称</th>
                                    <th className={headerCellClass}>系统</th>
                                    <th className={headerCellClass}>主题</th>
                                    <th className={headerCellClass}>数据日期</th>
                                    <th className={headerCellClass}>状态</th>
                                    <th className={headerCellClass}>开始时间</th>
                                    <th className={headerCellClass}>更新时间</th>
                                    <th className={headerCellClass}>结束时间</th>
                                    <th className={headerCellClass}>创建时间</th>
                                    <th className={headerCellClass}>消息摘要</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {filteredInstances.length === 0 ? (
                                    <tr>
                                        <td colSpan={12} className="px-6 py-16 text-center text-slate-500">
                                            未找到符合条件的任务实例。
                                        </td>
                                    </tr>
                                ) : pagedInstances.map(instance => {
                                    const mappedStatus = instanceStatusMap[instance.status ?? -1];
                                    const taskName = taskNameMap.get(instance.plan_id) || '-';
                                    const task = taskMap.get(instance.plan_id);

                                    return (
                                        <tr
                                            key={instance.id}
                                            onClick={() => handleOpenInstanceDetail(instance)}
                                            onContextMenu={(event) => openRowContextMenu(instance, event)}
                                            className="h-14 cursor-pointer hover:bg-slate-50/80 transition-colors"
                                            title="点击整行查看详情"
                                        >
                                            <td className={tableCellClass}>
                                                <input
                                                    type="checkbox"
                                                    checked={selectedInstanceIds.includes(instance.id)}
                                                    onClick={(event) => event.stopPropagation()}
                                                    onChange={(event) => {
                                                        event.stopPropagation();
                                                        toggleSelectInstance(instance.id, event.target.checked);
                                                    }}
                                                    className="h-4 w-4 rounded border-slate-300 text-red-600 focus:ring-red-500"
                                                />
                                            </td>
                                            <td className={monoCellClass}>
                                                <div className="truncate">{instance.plan_id}</div>
                                            </td>
                                            <td className={tableCellClass}>
                                                <div className="truncate font-semibold text-slate-800" title={taskName}>
                                                    {taskName}
                                                </div>
                                            </td>
                                            <td className={tableCellClass}>
                                                <div className="truncate text-slate-700" title={task?.task_system || '-'}>
                                                    {task?.task_system || '-'}
                                                </div>
                                            </td>
                                            <td className={tableCellClass}>
                                                <div className="truncate text-slate-700" title={task?.theme || '-'}>
                                                    {task?.theme || '-'}
                                                </div>
                                            </td>
                                            <td className={monoCellClass}>
                                                <div className="truncate">{instance.data_date}</div>
                                            </td>
                                            <td className={tableCellClass}>
                                                {mappedStatus ? (
                                                    <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold leading-none ${mappedStatus.className}`}>
                                                        {mappedStatus.label}
                                                    </span>
                                                ) : (
                                                    <Tag className="m-0">{instance.status ?? '-'}</Tag>
                                                )}
                                            </td>
                                            <td className={`${monoCellClass} text-slate-500`}>
                                                <div className="truncate">{instance.begin_time || '-'}</div>
                                            </td>
                                            <td className={`${monoCellClass} text-slate-500`}>
                                                <div className="truncate">{instance.update_time || '-'}</div>
                                            </td>
                                            <td className={`${monoCellClass} text-slate-500`}>
                                                <div className="truncate">{instance.end_time || '-'}</div>
                                            </td>
                                            <td className={`${monoCellClass} text-slate-500`}>
                                                <div className="truncate">{instance.create_time}</div>
                                            </td>
                                            <td className={`${tableCellClass} text-slate-600`}>
                                                <div className="truncate" title={instance.msg || '-'}>
                                                    {instance.msg || '-'}
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                </div>
                <div className="px-5">
                    <Pagination
                        current={currentPage}
                        total={filteredInstances.length}
                        pageSize={pageSize}
                        showSizeChanger
                        onChange={(page, size) => {
                            setCurrentPage(page);
                            setPageSize(size);
                        }}
                    />
                </div>
            </div>

            <Drawer
                title={selectedInstance ? `实例详情 · #${selectedInstance.id}` : '实例详情'}
                placement="right"
                size={920}
                onClose={() => setSelectedInstance(null)}
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
                            onChange={(key) => setInstanceDetailTabKey(key as typeof instanceDetailTabKey)}
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
                                                    <div className="text-sm font-semibold text-slate-800">任务基础</div>
                                                    <div className="mt-1 text-xs text-slate-500">任务本身的归属、主题和状态定义。</div>
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
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">执行器 Bean</div>
                                                            <div className="mt-1 text-slate-700">{selectedTask?.task_bean || '-'}</div>
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
                                                    <div className="text-sm font-semibold text-slate-800">任务标识</div>
                                                    <div className="mt-1 text-xs text-slate-500">用于定位和串联任务的内部字段。</div>
                                                </div>
                                                <div className={detailSectionBodyClass}>
                                                    <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">任务Bean</div>
                                                            <div className="mt-1 font-mono text-xs text-slate-700 break-all">{selectedTask?.task_bean || '-'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">Job Key</div>
                                                            <div className="mt-1 font-mono text-xs text-slate-700 break-all">{selectedTask?.job_key || '-'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">依赖任务</div>
                                                            <div className="mt-1 font-mono text-xs text-slate-700 break-all">{selectedTask?.depend_id || '无'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">任务参数</div>
                                                            <div className="mt-1 font-mono text-xs text-slate-700 break-all">{selectedTask?.task_params || '-'}</div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </section>
                                        </div>
                                    ),
                                },
                                {
                                    key: 'schedule',
                                    label: '调度依赖',
                                    children: (
                                        <div className="space-y-4">
                                            <section className={detailSectionClass}>
                                                <div className={detailSectionHeaderClass}>
                                                    <div className="text-sm font-semibold text-slate-800">调度配置</div>
                                                    <div className="mt-1 text-xs text-slate-500">任务何时触发，依赖如何串联，统一放在这里看。</div>
                                                </div>
                                                <div className={detailSectionBodyClass}>
                                                    <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">Cron 表达式</div>
                                                            <div className="mt-1 font-mono text-xs text-slate-700 break-all">{selectedTask?.task_cron || '-'}</div>
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
                                                            <div className="text-xs text-slate-400">默认数据日期</div>
                                                            <div className="mt-1 text-slate-700">{selectedTask?.data_date || '-'}</div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </section>

                                            <section className={detailSectionClass}>
                                                <div className={detailSectionHeaderClass}>
                                                    <div className="text-sm font-semibold text-slate-800">依赖关系</div>
                                                    <div className="mt-1 text-xs text-slate-500">与其它任务之间的前后置关系。</div>
                                                </div>
                                                <div className={detailSectionBodyClass}>
                                                    <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">前置依赖</div>
                                                            <div className="mt-1 text-slate-700 break-all">{selectedTask?.depend_id || '无'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">创建时间</div>
                                                            <div className="mt-1 text-slate-700">{selectedTask?.create_time || '-'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">更新时间</div>
                                                            <div className="mt-1 text-slate-700">{selectedTask?.update_time || '-'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">当前状态</div>
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
                                                    <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
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
                                                        onClick={() => setShowImpactedOnly(prev => !prev)}
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
                                                        dependencyPanelData.downstreamTree,
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
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">连接地址</div>
                                                            <div className="mt-1 font-mono text-xs text-slate-700 break-all">{selectedTask?.url || '-'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">驱动类</div>
                                                            <div className="mt-1 font-mono text-xs text-slate-700 break-all">{selectedTask?.driver || '-'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">账号</div>
                                                            <div className="mt-1 text-slate-700">{selectedTask?.username || '-'}</div>
                                                        </div>
                                                        <div className={detailItemClass}>
                                                            <div className="text-xs text-slate-400">密码</div>
                                                            <div className="mt-1 text-slate-700">{selectedTask?.password || '-'}</div>
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
                                                        <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50/60 px-4 py-10 text-center text-sm text-slate-500">
                                                            当前实例暂无执行日志。
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
        </>
    );
};

export default TaskInstance;
