import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { message } from 'antd';
import dayjs from 'dayjs';
import { batchExecuteQuartzTaskStatus, batchForcePassQuartzTaskStatus, batchForceStopQuartzTaskStatus, queryQuartzTaskLog, queryQuartzTasks, queryQuartzTaskStatus } from '@/api/ops';
import { QuartzTask, QuartzTaskExecutionLog, QuartzTaskStatus } from './mockData';
import TaskInstanceDetailDrawer from './task-instance/TaskInstanceDetailDrawer';
import TaskInstanceRerunExecutionDrawer from './task-instance/TaskInstanceRerunExecutionDrawer';
import TaskInstanceRerunOptionModal from './task-instance/TaskInstanceRerunOptionModal';
import TaskInstanceTableView from './task-instance/TaskInstanceTableView';
import {
    InstanceDetailTabKey,
    RowContextMenuState,
    TaskInstanceProps,
} from './task-instance/types';
import { normalizeLog, normalizeStatus, normalizeTask } from './task-instance/utils';
import { useDependencyInsightData } from './task-instance/useDependencyInsightData';

const normalizeDateKey = (value?: string | null) => value?.replaceAll('-', '') || '';
const BATCH_RERUN_CHUNK_SIZE = 20;

const chunkArray = <T,>(items: T[], chunkSize: number) => {
    const chunks: T[][] = [];
    for (let index = 0; index < items.length; index += chunkSize) {
        chunks.push(items.slice(index, index + chunkSize));
    }
    return chunks;
};

const TaskInstance: React.FC<TaskInstanceProps> = ({ onStatsChange }) => {
    const todayDate = dayjs().format('YYYY-MM-DD');
    const [taskList, setTaskList] = useState<QuartzTask[]>([]);
    const [instanceList, setInstanceList] = useState<QuartzTaskStatus[]>([]);
    const [summaryStats, setSummaryStats] = useState({
        totalInstances: 0,
        waitingInstances: 0,
        runningInstances: 0,
        successInstances: 0,
        failedInstances: 0,
    });
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
    const [rerunOptionInstance, setRerunOptionInstance] = useState<QuartzTaskStatus | null>(null);
    const [rerunExecutionInstance, setRerunExecutionInstance] = useState<QuartzTaskStatus | null>(null);
    const [selectedDependencyRerunStatusIds, setSelectedDependencyRerunStatusIds] = useState<number[]>([]);
    const [dependencyRerunExecuting, setDependencyRerunExecuting] = useState(false);
    const [batchRerunExecuting, setBatchRerunExecuting] = useState(false);
    const [rowContextMenu, setRowContextMenu] = useState<RowContextMenuState | null>(null);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);

    const buildInstanceQueryParams = useCallback((filters?: {
        createDate?: string;
        dataDate?: string;
        status?: string;
        taskSystem?: string;
        keyword?: string;
    }) => {
        const nextFilters = filters || {};
        return {
            pageNum: 1,
            pageSize: 500,
            beginDate: (nextFilters.createDate ?? createDateFilter)?.replaceAll('-', '') || undefined,
            dataDate: (nextFilters.dataDate ?? dataDateFilter)?.replaceAll('-', '') || undefined,
            status: (nextFilters.status ?? statusFilter) || undefined,
            taskSystem: (nextFilters.taskSystem ?? taskSystemFilter) || undefined,
            taskName: (nextFilters.keyword ?? searchKeyword.trim()) || undefined,
        };
    }, [createDateFilter, dataDateFilter, searchKeyword, statusFilter, taskSystemFilter]);

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

    const queryAllInstances = useCallback(async (filters?: {
        createDate?: string;
        dataDate?: string;
        status?: string;
        taskSystem?: string;
        keyword?: string;
    }, options?: { silent?: boolean }) => {
        try {
            const queryParams = buildInstanceQueryParams(filters);
            const firstResponse = await queryQuartzTaskStatus(queryParams);
            if (!firstResponse?.success) {
                throw new Error(firstResponse?.msg || '加载实例失败');
            }

            const totalPages = Number(firstResponse.data?.pages || 1);
            const mergedInstances = [...(firstResponse.data?.list || []).map(normalizeStatus)];

            if (totalPages > 1) {
                const restResponses = await Promise.all(
                    Array.from({ length: totalPages - 1 }, (_, index) =>
                        queryQuartzTaskStatus({ ...queryParams, pageNum: index + 2 })
                    )
                );
                restResponses.forEach(response => {
                    if (response?.success) {
                        mergedInstances.push(...(response.data?.list || []).map(normalizeStatus));
                    }
                });
            }

            return mergedInstances;
        } catch (error: any) {
            if (!options?.silent) {
                message.error(error?.message || '加载实例失败');
            }
            return null;
        }
    }, [buildInstanceQueryParams]);

    const buildStats = useCallback((instances: QuartzTaskStatus[]) => ({
        totalInstances: instances.length,
        waitingInstances: instances.filter(instance => instance.status === 1).length,
        runningInstances: instances.filter(instance => instance.status === 2).length,
        successInstances: instances.filter(instance => instance.status === 3).length,
        failedInstances: instances.filter(instance => instance.status === 4).length,
    }), []);

    const loadInstances = useCallback(async (filters?: {
        createDate?: string;
        dataDate?: string;
        status?: string;
        taskSystem?: string;
        keyword?: string;
    }, options?: { silent?: boolean }) => {
        const mergedInstances = await queryAllInstances(filters, options);
        if (mergedInstances) {
            setInstanceList(mergedInstances);
        }
    }, [queryAllInstances]);

    const loadTodaySummaryStats = useCallback(async () => {
        const todayInstances = await queryAllInstances({
            createDate: todayDate,
            dataDate: '',
            status: '',
            taskSystem: '',
            keyword: '',
        });
        if (todayInstances) {
            const nextStats = buildStats(todayInstances);
            setSummaryStats(nextStats);
            onStatsChange?.(nextStats);
        }
    }, [buildStats, onStatsChange, queryAllInstances, todayDate]);

    useEffect(() => {
        loadTasks();
    }, [loadTasks]);

    useEffect(() => {
        loadInstances();
    }, [loadInstances]);

    useEffect(() => {
        const timer = window.setInterval(() => {
            if (batchRerunExecuting) {
                return;
            }
            void loadInstances(undefined, { silent: true });
        }, 3000);
        return () => {
            window.clearInterval(timer);
        };
    }, [batchRerunExecuting, loadInstances]);

    useEffect(() => {
        loadTodaySummaryStats();
    }, [loadTodaySummaryStats]);

    useEffect(() => {
        const taskId = selectedInstance?.plan_id;
        const instanceId = selectedInstance?.id;
        if (!taskId || !instanceId) {
            return;
        }

        let canceled = false;

        const mergeSelectedInstance = (nextInstance: QuartzTaskStatus) => {
            setInstanceList(prev => {
                const exists = prev.some(instance => instance.id === nextInstance.id);
                return exists
                    ? prev.map(instance => instance.id === nextInstance.id ? nextInstance : instance)
                    : [nextInstance, ...prev];
            });
            setSelectedInstance(prev => prev?.id === nextInstance.id ? nextInstance : prev);
        };

        const loadSelectedInstanceStatus = async () => {
            try {
                const response = await queryQuartzTaskStatus({ id: instanceId, pageNum: 1, pageSize: 1 });
                if (!response?.success) {
                    throw new Error(response?.msg || '刷新实例状态失败');
                }
                if (canceled) return;
                const nextInstance = response.data?.list?.[0];
                if (nextInstance) {
                    mergeSelectedInstance(normalizeStatus(nextInstance));
                }
            } catch (error: any) {
                if (!canceled) {
                    console.warn(error?.message || '刷新实例状态失败');
                }
            }
        };

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
        void loadSelectedInstanceStatus();
        const timer = window.setInterval(() => {
            void loadLogs(true);
            void loadSelectedInstanceStatus();
        }, 3000);

        return () => {
            canceled = true;
            window.clearInterval(timer);
        };
    }, [selectedInstance?.id, selectedInstance?.plan_id]);

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
            const matchesDataDate = !dataDateFilter || normalizeDateKey(instance.data_date) === normalizeDateKey(dataDateFilter);
            const matchesCreateDate = !createDateFilter || instance.create_date === createDateFilter.replaceAll('-', '');
            const matchesStatus = statusFilter === '' || String(instance.status ?? '') === statusFilter;

            return matchesKeyword && matchesTaskSystem && matchesDataDate && matchesCreateDate && matchesStatus;
        });
    }, [createDateFilter, dataDateFilter, instanceList, searchKeyword, statusFilter, taskMap, taskSystemFilter]);

    const pagedInstances = useMemo(() => {
        const start = (currentPage - 1) * pageSize;
        return filteredInstances.slice(start, start + pageSize);
    }, [currentPage, filteredInstances, pageSize]);

    useEffect(() => {
        setCurrentPage(1);
    }, [searchKeyword, taskSystemFilter, statusFilter, dataDateFilter, createDateFilter]);

    const handleSearch = useCallback(() => {
        const nextKeyword = draftSearchKeyword.trim();
        setSearchKeyword(nextKeyword);
        setTaskSystemFilter(draftTaskSystemFilter);
        setDataDateFilter(draftDataDateFilter);
        setCreateDateFilter(draftCreateDateFilter);
        setStatusFilter(draftStatusFilter);
        setCurrentPage(1);
        void loadInstances({
            keyword: nextKeyword,
            taskSystem: draftTaskSystemFilter,
            dataDate: draftDataDateFilter,
            createDate: draftCreateDateFilter,
            status: draftStatusFilter,
        });
    }, [
        draftCreateDateFilter,
        draftDataDateFilter,
        draftSearchKeyword,
        draftStatusFilter,
        draftTaskSystemFilter,
        loadInstances,
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

    const dependencyPanelData = useDependencyInsightData({
        selectedInstance,
        taskList,
        instanceList,
        taskMap,
    });
    const rerunExecutionDependencyData = useDependencyInsightData({
        selectedInstance: rerunExecutionInstance,
        taskList,
        instanceList,
        taskMap,
    });

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
            msg: '实例已重置为等待执行。',
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

    const executeCurrentNodeRerun = async (
        statusIds: number[],
        fallbackSuccessMessage: string,
        fallbackErrorMessage: string,
        options?: { refresh?: boolean; silentSuccess?: boolean }
    ) => {
        try {
            const response = await batchExecuteQuartzTaskStatus(statusIds, false);
            if (!response?.success) {
                throw new Error(response?.msg || fallbackErrorMessage);
            }
            updateInstances(statusIds, markInstanceWaiting);
            setSelectedInstanceIds(prev => prev.filter(id => !statusIds.includes(id)));
            if (options?.refresh !== false) {
                await loadInstances();
                await loadTodaySummaryStats();
            }
            if (!options?.silentSuccess) {
                message.success(response?.data || fallbackSuccessMessage);
            }
            return true;
        } catch (error: any) {
            message.error(error?.message || fallbackErrorMessage);
            return false;
        }
    };

    const handleExecuteInstance = (instance: QuartzTaskStatus) => {
        if (instance.status !== 3 && instance.status !== 4) {
            message.error('执行任务仅支持失败或已完成实例，请检查当前实例状态');
            return;
        }

        setRerunOptionInstance(instance);
    };

    const handleExecuteCurrentInstance = async (instance: QuartzTaskStatus) => {
        setRerunOptionInstance(null);
        await executeCurrentNodeRerun(
            [instance.id],
            `已重跑当前节点实例 #${instance.id}`,
            '执行任务失败'
        );
    };

    const handleOpenDependencyRerunList = (instance: QuartzTaskStatus) => {
        setRerunOptionInstance(null);
        setRerunExecutionInstance(instance);
        setSelectedDependencyRerunStatusIds([]);
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
                setSelectedInstanceIds(prev => prev.filter(id => id !== instance.id));
                await loadInstances();
                await loadTodaySummaryStats();
                message.success(response?.data || `已强制停止实例 #${instance.id}`);
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
                await loadTodaySummaryStats();
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
        if (selectedInstanceIds.length === 0 || batchRerunExecuting) return;

        const targetIds = [...selectedInstanceIds];
        const selectedInstances = instanceList.filter(instance => targetIds.includes(instance.id));
        const invalidInstances = selectedInstances.filter(instance => instance.status !== 3 && instance.status !== 4);
        if (invalidInstances.length > 0) {
            message.error('批量执行仅支持失败或已完成实例，当前选择中包含非允许状态，请检查后重试');
            return;
        }

        setBatchRerunExecuting(true);
        const chunks = chunkArray(targetIds, BATCH_RERUN_CHUNK_SIZE);
        let executedCount = 0;
        try {
            for (let index = 0; index < chunks.length; index += 1) {
                const chunk = chunks[index];
                const executed = await executeCurrentNodeRerun(
                    chunk,
                    `批量重跑进度 ${Math.min(executedCount + chunk.length, targetIds.length)}/${targetIds.length}`,
                    `批量执行失败（第 ${index + 1}/${chunks.length} 批）`,
                    { refresh: false, silentSuccess: true }
                );
                if (!executed) {
                    break;
                }
                executedCount += chunk.length;
            }

            await loadInstances();
            await loadTodaySummaryStats();

            if (executedCount === targetIds.length) {
                setSelectedInstanceIds([]);
                message.success(`已分批重跑当前节点 ${executedCount} 条实例`);
            } else if (executedCount > 0) {
                setSelectedInstanceIds(prev => prev.filter(id => !targetIds.slice(0, executedCount).includes(id)));
                message.warning(`已重跑 ${executedCount}/${targetIds.length} 条实例，剩余实例未提交成功`);
            }
        } finally {
            setBatchRerunExecuting(false);
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
                setSelectedInstanceIds([]);
                await loadInstances();
                await loadTodaySummaryStats();
                message.success(response?.data || `已批量强制停止 ${selectedInstances.length} 条实例`);
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
                await loadTodaySummaryStats();
                message.success(`已批量强制通过 ${selectedInstances.length} 条实例`);
            })
            .catch((error: any) => {
                message.error(error?.message || '批量强制通过失败');
            });
    };

    const handleExecuteSelectedDependencyRerun = async () => {
        if (!rerunExecutionInstance) return;

        const statusIds = Array.from(new Set([rerunExecutionInstance.id, ...selectedDependencyRerunStatusIds]));
        setDependencyRerunExecuting(true);
        try {
            const executed = await executeCurrentNodeRerun(
                statusIds,
                `已重跑当前任务及选中下游 ${statusIds.length} 条实例`,
                '重跑当前任务及选中下游失败'
            );
            if (executed) {
                setSelectedDependencyRerunStatusIds([]);
                setRerunExecutionInstance(null);
            }
        } finally {
            setDependencyRerunExecuting(false);
        }
    };

    const selectedTask = selectedInstance ? taskMap.get(selectedInstance.plan_id) || null : null;

    useEffect(() => {
        if (!selectedInstance) return;
        const latestInstance = instanceList.find(instance => instance.id === selectedInstance.id);
        if (latestInstance && latestInstance !== selectedInstance) {
            setSelectedInstance(latestInstance);
        }
    }, [instanceList, selectedInstance]);

    const selectedInstanceLogs = useMemo(() => {
        const sortByCreateTimeDesc = (a: QuartzTaskExecutionLog, b: QuartzTaskExecutionLog) =>
            dayjs(b.create_time).valueOf() - dayjs(a.create_time).valueOf();
        if (!selectedInstance) return [] as QuartzTaskExecutionLog[];
        const exactLogs = logList.filter(log => log.instance_id === selectedInstance.id);
        if (exactLogs.length > 0) {
            return [...exactLogs].sort(sortByCreateTimeDesc);
        }
        const sameDataLogs = logList.filter(log =>
            log.task_id === selectedInstance.plan_id
            && !!log.data_date
            && log.data_date === selectedInstance.data_date
        );
        if (sameDataLogs.length > 0) {
            return [...sameDataLogs].sort(sortByCreateTimeDesc);
        }
        return logList
            .filter(log => log.task_id === selectedInstance.plan_id)
            .sort(sortByCreateTimeDesc);
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
                summaryStats={summaryStats}
                taskMap={taskMap}
                taskNameMap={taskNameMap}
                taskSystemOptions={taskSystemOptions}
                searchKeyword={draftSearchKeyword}
                taskSystemFilter={draftTaskSystemFilter}
                dataDateFilter={draftDataDateFilter}
                createDateFilter={draftCreateDateFilter}
                statusFilter={draftStatusFilter}
                selectedInstanceIds={selectedInstanceIds}
                batchRerunExecuting={batchRerunExecuting}
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

            <TaskInstanceRerunOptionModal
                instance={rerunOptionInstance}
                taskName={rerunOptionInstance ? taskNameMap.get(rerunOptionInstance.plan_id) || '' : ''}
                onClose={() => setRerunOptionInstance(null)}
                onExecuteCurrent={handleExecuteCurrentInstance}
                onOpenDependencyList={handleOpenDependencyRerunList}
            />

            <TaskInstanceRerunExecutionDrawer
                open={!!rerunExecutionInstance}
                sourceInstance={rerunExecutionInstance}
                dependencyPanelData={rerunExecutionDependencyData}
                selectedStatusIds={selectedDependencyRerunStatusIds}
                executing={dependencyRerunExecuting}
                onClose={() => {
                    setRerunExecutionInstance(null);
                    setSelectedDependencyRerunStatusIds([]);
                }}
                onSelectedStatusIdsChange={setSelectedDependencyRerunStatusIds}
                onExecute={handleExecuteSelectedDependencyRerun}
            />

            <TaskInstanceDetailDrawer
                selectedInstance={selectedInstance}
                selectedTask={selectedTask}
                taskNameMap={taskNameMap}
                instanceDetailTabKey={instanceDetailTabKey}
                dependencyPanelData={dependencyPanelData}
                selectedInstanceLogs={selectedInstanceLogs}
                showImpactedOnly={showImpactedOnly}
                onClose={() => setSelectedInstance(null)}
                onTabChange={setInstanceDetailTabKey}
                onShowImpactedOnlyChange={setShowImpactedOnly}
                onLocateInstanceFromDependency={locateInstanceFromDependency}
            />
        </>
    );
};

export default TaskInstance;
