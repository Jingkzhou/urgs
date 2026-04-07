import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { message } from 'antd';
import dayjs from 'dayjs';
import { batchExecuteQuartzTaskStatus, batchForcePassQuartzTaskStatus, batchForceStopQuartzTaskStatus, queryQuartzTaskLog, queryQuartzTasks, queryQuartzTaskStatus } from '@/api/ops';
import { QuartzTask, QuartzTaskExecutionLog, QuartzTaskStatus } from './mockData';
import { blockingStatusRank, incompleteInstanceStatuses } from './task-instance/constants';
import TaskInstanceDetailDrawer from './task-instance/TaskInstanceDetailDrawer';
import TaskInstanceTableView from './task-instance/TaskInstanceTableView';
import {
    BlockingDependencyItem,
    DependencyInsightData,
    DependencyRelationItem,
    DownstreamImpactMeta,
    InstanceDetailTabKey,
    RowContextMenuState,
    TaskInstanceProps,
} from './task-instance/types';
import {
    normalizeLog,
    normalizeStatus,
    normalizeTask,
    parseDependIds,
} from './task-instance/utils';

const TaskInstance: React.FC<TaskInstanceProps> = ({ onStatsChange }) => {
    const todayDate = dayjs().format('YYYY-MM-DD');
    const [taskList, setTaskList] = useState<QuartzTask[]>([]);
    const [instanceList, setInstanceList] = useState<QuartzTaskStatus[]>([]);
    const [logList, setLogList] = useState<QuartzTaskExecutionLog[]>([]);
    const [draftSearchKeyword, setDraftSearchKeyword] = useState('');
    const [draftTaskSystemFilter, setDraftTaskSystemFilter] = useState('');
    const [draftDataDateFilter, setDraftDataDateFilter] = useState('');
    const [draftCreateDateFilter, setDraftCreateDateFilter] = useState(todayDate);
    const [draftStatusFilter, setDraftStatusFilter] = useState<string>('');
    const [searchKeyword, setSearchKeyword] = useState('');
    const [taskSystemFilter, setTaskSystemFilter] = useState('');
    const [dataDateFilter, setDataDateFilter] = useState('');
    const [createDateFilter, setCreateDateFilter] = useState(todayDate);
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [selectedInstance, setSelectedInstance] = useState<QuartzTaskStatus | null>(null);
    const [selectedInstanceIds, setSelectedInstanceIds] = useState<number[]>([]);
    const [instanceDetailTabKey, setInstanceDetailTabKey] = useState<InstanceDetailTabKey>('overview');
    const [showImpactedOnly, setShowImpactedOnly] = useState(false);
    const [expandedImpactTaskIds, setExpandedImpactTaskIds] = useState<number[]>([]);
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

        const loadLogs = async (silent = false) => {
            try {
                const response = await queryQuartzTaskLog(taskId, 1, 200);
                if (!response?.success) {
                    throw new Error(response?.msg || '加载执行日志失败');
                }
                if (canceled) return;
                setLogList((response.data?.list || []).map(normalizeLog));
            } catch (error: any) {
                if (canceled) return;
                if (!silent) {
                    message.error(error?.message || '加载执行日志失败');
                }
            }
        };

        loadLogs();
        const timer = window.setInterval(() => {
            void loadLogs(true);
        }, 3000);

        return () => {
            canceled = true;
            window.clearInterval(timer);
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
    }, [currentPage, filteredInstances, pageSize]);

    useEffect(() => {
        setCurrentPage(1);
    }, [searchKeyword, taskSystemFilter, statusFilter, dataDateFilter, createDateFilter]);

    const handleSearch = useCallback(() => {
        setSearchKeyword(draftSearchKeyword.trim());
        setTaskSystemFilter(draftTaskSystemFilter);
        setDataDateFilter(draftDataDateFilter);
        setCreateDateFilter(draftCreateDateFilter);
        setStatusFilter(draftStatusFilter);
        setCurrentPage(1);
    }, [
        draftCreateDateFilter,
        draftDataDateFilter,
        draftSearchKeyword,
        draftStatusFilter,
        draftTaskSystemFilter,
    ]);

    const handleResetFilters = useCallback(() => {
        setDraftSearchKeyword('');
        setDraftTaskSystemFilter('');
        setDraftDataDateFilter('');
        setDraftCreateDateFilter(todayDate);
        setDraftStatusFilter('');
        setSearchKeyword('');
        setTaskSystemFilter('');
        setDataDateFilter('');
        setCreateDateFilter(todayDate);
        setStatusFilter('');
        setCurrentPage(1);
    }, [todayDate]);

    useEffect(() => {
        const totalPages = Math.max(1, Math.ceil(filteredInstances.length / pageSize));
        if (currentPage > totalPages) {
            setCurrentPage(totalPages);
        }
    }, [currentPage, filteredInstances.length, pageSize]);

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

        const downstreamMetaMap = new Map<number, DownstreamImpactMeta>();
        const downstreamDescendantIdSetMap = new Map<number, Set<number>>();

        const buildDownstreamMeta = (
            taskId: number,
            path: Set<number>
        ): DownstreamImpactMeta => {
            const cached = downstreamMetaMap.get(taskId);
            if (cached) {
                return cached;
            }

            const relation = toRelationItem(taskId);
            const directChildIds = (downstreamTaskIdMap.get(taskId) || []).filter(childTaskId => !path.has(childTaskId));
            const meta = {
                ...relation,
                impacted: relation.relatedInstance?.status !== 3,
                hasImpactedDescendant: false,
                directChildIds,
                descendantCount: 0,
            };
            downstreamMetaMap.set(taskId, meta);

            const descendantIdSet = new Set<number>();
            let hasImpactedDescendant = false;

            directChildIds.forEach(childTaskId => {
                const nextPath = new Set(path);
                nextPath.add(childTaskId);
                const childMeta = buildDownstreamMeta(childTaskId, nextPath);
                descendantIdSet.add(childTaskId);
                const childDescendantIdSet = downstreamDescendantIdSetMap.get(childTaskId);
                childDescendantIdSet?.forEach(descendantTaskId => {
                    descendantIdSet.add(descendantTaskId);
                });
                if (childMeta.impacted || childMeta.hasImpactedDescendant) {
                    hasImpactedDescendant = true;
                }
            });

            downstreamDescendantIdSetMap.set(taskId, descendantIdSet);
            meta.descendantCount = descendantIdSet.size;
            meta.hasImpactedDescendant = hasImpactedDescendant;
            return meta;
        };

        const downstreamRootTaskIds = downstreamTaskIdMap.get(selectedInstance.plan_id) || [];
        downstreamRootTaskIds.forEach(taskId => {
            buildDownstreamMeta(taskId, new Set([selectedInstance.plan_id, taskId]));
        });

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
            downstreamRootTaskIds,
            downstreamMetaMap,
            downstreamTotalCount: downstreamMetaMap.size,
            impactedDownstreamCount: Array.from(downstreamMetaMap.values()).filter(item => item.impacted).length,
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

    const markInstanceWaiting = (instance: QuartzTaskStatus) => {
        const now = dayjs().format('YYYY-MM-DD HH:mm:ss');
        return {
            ...instance,
            status: 1,
            begin_time: null,
            update_time: now,
            end_time: null,
            msg: '实例已批量重置为等待执行。',
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
        if (instance.status !== 3 && instance.status !== 4) {
            message.error('执行任务仅支持失败或已完成实例，请检查当前实例状态');
            return;
        }

        batchExecuteQuartzTaskStatus([instance.id])
            .then(async (response) => {
                if (!response?.success) {
                    throw new Error(response?.msg || '执行任务失败');
                }
                updateInstance(instance.id, markInstanceWaiting);
                setSelectedInstanceIds(prev => prev.filter(id => id !== instance.id));
                await loadInstances();
                message.success(`已执行实例 #${instance.id}`);
            })
            .catch((error: any) => {
                message.error(error?.message || '执行任务失败');
            });
    };

    const handleForceStopInstance = (instance: QuartzTaskStatus) => {
        if (instance.status !== 1 && instance.status !== 2) {
            message.error('强制停止仅支持等待中或执行中实例，请检查当前实例状态');
            return;
        }

        batchForceStopQuartzTaskStatus([instance.id])
            .then(async (response) => {
                if (!response?.success) {
                    throw new Error(response?.msg || '强制停止失败');
                }
                updateInstance(instance.id, markInstanceStopped);
                setSelectedInstanceIds(prev => prev.filter(id => id !== instance.id));
                await loadInstances();
                message.success(`已强制停止实例 #${instance.id}`);
            })
            .catch((error: any) => {
                message.error(error?.message || '强制停止失败');
            });
    };

    const handleForcePassInstance = (instance: QuartzTaskStatus) => {
        if (instance.status !== 4) {
            message.error('强制通过仅支持失败实例，请检查当前实例状态');
            return;
        }

        batchForcePassQuartzTaskStatus([instance.id])
            .then(async (response) => {
                if (!response?.success) {
                    throw new Error(response?.msg || '强制通过失败');
                }
                updateInstance(instance.id, markInstancePassed);
                setSelectedInstanceIds(prev => prev.filter(id => id !== instance.id));
                await loadInstances();
                message.success(`已强制通过实例 #${instance.id}`);
            })
            .catch((error: any) => {
                message.error(error?.message || '强制通过失败');
            });
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

    const handleOpenInstanceDetail = (
        instance: QuartzTaskStatus,
        tab: InstanceDetailTabKey = 'overview'
    ) => {
        setSelectedInstance(instance);
        setInstanceDetailTabKey(tab);
        setShowImpactedOnly(false);
        setExpandedImpactTaskIds([]);
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
    const selectedInstances = useMemo(
        () => instanceList.filter(instance => selectedInstanceIds.includes(instance.id)),
        [instanceList, selectedInstanceIds]
    );
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

    const handleBatchExecute = async () => {
        if (selectedInstanceIds.length === 0) return;

        const selectedInstances = instanceList.filter(instance => selectedInstanceIds.includes(instance.id));
        const invalidInstances = selectedInstances.filter(instance => instance.status !== 3 && instance.status !== 4);
        if (invalidInstances.length > 0) {
            message.error('批量执行仅支持失败或已完成实例，当前选择中包含非允许状态，请检查后重试');
            return;
        }

        try {
            const response = await batchExecuteQuartzTaskStatus(selectedInstanceIds);
            if (!response?.success) {
                throw new Error(response?.msg || '批量执行失败');
            }
            updateInstances(selectedInstanceIds, markInstanceWaiting);
            setSelectedInstanceIds([]);
            await loadInstances();
            message.success(`已批量执行 ${selectedInstances.length} 条实例`);
        } catch (error: any) {
            message.error(error?.message || '批量执行失败');
        }
    };

    const handleBatchForceStop = () => {
        if (selectedInstanceIds.length === 0) return;

        const selectedInstances = instanceList.filter(instance => selectedInstanceIds.includes(instance.id));
        const invalidInstances = selectedInstances.filter(instance => instance.status !== 1 && instance.status !== 2);
        if (invalidInstances.length > 0) {
            message.error('批量强制停止仅支持等待中或执行中实例，当前选择中包含非允许状态，请检查后重试');
            return;
        }

        batchForceStopQuartzTaskStatus(selectedInstanceIds)
            .then(async (response) => {
                if (!response?.success) {
                    throw new Error(response?.msg || '批量强制停止失败');
                }
                updateInstances(selectedInstanceIds, markInstanceStopped);
                setSelectedInstanceIds([]);
                await loadInstances();
                message.success(`已批量强制停止 ${selectedInstances.length} 条实例`);
            })
            .catch((error: any) => {
                message.error(error?.message || '批量强制停止失败');
            });
    };

    const handleBatchForcePass = () => {
        if (selectedInstanceIds.length === 0) return;

        const selectedInstances = instanceList.filter(instance => selectedInstanceIds.includes(instance.id));
        const invalidInstances = selectedInstances.filter(instance => instance.status !== 4);
        if (invalidInstances.length > 0) {
            message.error('批量强制通过仅支持失败实例，当前选择中包含非允许状态，请检查后重试');
            return;
        }

        batchForcePassQuartzTaskStatus(selectedInstanceIds)
            .then(async (response) => {
                if (!response?.success) {
                    throw new Error(response?.msg || '批量强制通过失败');
                }
                updateInstances(selectedInstanceIds, markInstancePassed);
                setSelectedInstanceIds([]);
                await loadInstances();
                message.success(`已批量强制通过 ${selectedInstances.length} 条实例`);
            })
            .catch((error: any) => {
                message.error(error?.message || '批量强制通过失败');
            });
    };

    const toggleImpactTaskExpanded = (taskId: number) => {
        setExpandedImpactTaskIds(prev =>
            prev.includes(taskId)
                ? prev.filter(id => id !== taskId)
                : [...prev, taskId]
        );
    };

    const selectedTask = selectedInstance ? taskMap.get(selectedInstance.plan_id) || null : null;

    const selectedInstanceLogs = useMemo(() => {
        if (!selectedInstance) return [] as QuartzTaskExecutionLog[];
        const exactLogs = logList.filter(log => log.instance_id === selectedInstance.id);
        if (exactLogs.length > 0) {
            return [...exactLogs].sort((a, b) => dayjs(a.create_time).valueOf() - dayjs(b.create_time).valueOf());
        }
        const sameDataLogs = logList.filter(log =>
            log.task_id === selectedInstance.plan_id
            && !!log.data_date
            && log.data_date === selectedInstance.data_date
        );
        if (sameDataLogs.length > 0) {
            return [...sameDataLogs].sort((a, b) => dayjs(a.create_time).valueOf() - dayjs(b.create_time).valueOf());
        }
        return logList
            .filter(log => log.task_id === selectedInstance.plan_id)
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
            <TaskInstanceTableView
                filteredInstances={filteredInstances}
                pagedInstances={pagedInstances}
                selectedInstances={selectedInstances}
                taskMap={taskMap}
                taskNameMap={taskNameMap}
                taskSystemOptions={taskSystemOptions}
                searchKeyword={draftSearchKeyword}
                taskSystemFilter={draftTaskSystemFilter}
                dataDateFilter={draftDataDateFilter}
                createDateFilter={draftCreateDateFilter}
                statusFilter={draftStatusFilter}
                selectedInstanceIds={selectedInstanceIds}
                allVisibleSelected={allVisibleSelected}
                rowContextMenu={rowContextMenu}
                rowContextMenuStyle={rowContextMenuStyle}
                currentPage={currentPage}
                pageSize={pageSize}
                onSearchKeywordChange={setDraftSearchKeyword}
                onTaskSystemFilterChange={setDraftTaskSystemFilter}
                onDataDateFilterChange={setDraftDataDateFilter}
                onCreateDateFilterChange={setDraftCreateDateFilter}
                onStatusFilterChange={setDraftStatusFilter}
                onSearch={handleSearch}
                onResetFilters={handleResetFilters}
                onToggleSelectAllVisible={toggleSelectAllVisible}
                onToggleSelectInstance={toggleSelectInstance}
                onBatchExecute={handleBatchExecute}
                onBatchForceStop={handleBatchForceStop}
                onBatchForcePass={handleBatchForcePass}
                onClearSelectedInstances={() => setSelectedInstanceIds([])}
                onCloseRowContextMenu={closeRowContextMenu}
                onInvokeRowContextAction={invokeRowContextAction}
                onOpenRowContextMenu={openRowContextMenu}
                onOpenInstanceDetail={handleOpenInstanceDetail}
                onPageChange={(page, size) => {
                    setCurrentPage(page);
                    setPageSize(size);
                }}
            />

            <TaskInstanceDetailDrawer
                selectedInstance={selectedInstance}
                selectedTask={selectedTask}
                taskNameMap={taskNameMap}
                instanceDetailTabKey={instanceDetailTabKey}
                dependencyPanelData={dependencyPanelData}
                selectedInstanceLogs={selectedInstanceLogs}
                showImpactedOnly={showImpactedOnly}
                expandedImpactTaskIds={expandedImpactTaskIds}
                onClose={() => setSelectedInstance(null)}
                onTabChange={setInstanceDetailTabKey}
                onShowImpactedOnlyChange={setShowImpactedOnly}
                onToggleImpactTaskExpanded={toggleImpactTaskExpanded}
                onLocateInstanceFromDependency={locateInstanceFromDependency}
            />
        </>
    );
};

export default TaskInstance;
