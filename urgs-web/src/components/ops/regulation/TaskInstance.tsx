import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Modal, message } from 'antd';
import dayjs from 'dayjs';
import {
    QuartzMissedTaskApiModel,
    batchExecuteQuartzTaskStatus,
    batchForcePassQuartzTaskStatus,
    batchForceStopQuartzTaskStatus,
    queryQuartzMissedTasks,
    queryQuartzTaskLog,
    queryQuartzTasks,
    queryQuartzTaskStatus,
    triggerNowQuartzTask,
} from '@/api/ops';
import { QuartzTask, QuartzTaskExecutionLog, QuartzTaskStatus } from './mockData';
import TaskInstanceDetailDrawer from './task-instance/TaskInstanceDetailDrawer';
import TaskInstanceRerunExecutionDrawer from './task-instance/TaskInstanceRerunExecutionDrawer';
import TaskInstanceRerunOptionModal from './task-instance/TaskInstanceRerunOptionModal';
import TaskInstanceTableView from './task-instance/TaskInstanceTableView';
import { useExecutorPoolStats } from './task-instance/useExecutorPoolStats';
import {
    InstanceDetailTabKey,
    RowContextMenuState,
    TaskInstanceProps,
} from './task-instance/types';
import { normalizeLog, normalizeStatus, normalizeTask } from './task-instance/utils';
import { useDependencyInsightData } from './task-instance/useDependencyInsightData';

const normalizeDateKey = (value?: string | null) => {
    if (!value) return '';
    const normalized = value.trim().replaceAll('-', '');
    return normalized.length >= 8 ? normalized.slice(0, 8) : normalized;
};
const getDateTimeValue = (value?: string | null) => value ? dayjs(value).valueOf() : 0;
const BATCH_RERUN_CHUNK_SIZE = 20;
const TASK_INSTANCE_REFRESH_INTERVAL_MS = 3000;
const SUMMARY_STATS_ACTIVE_REFRESH_INTERVAL_MS = 3000;
const SUMMARY_STATS_HIDDEN_REFRESH_INTERVAL_MS = 30000;

const chunkArray = <T,>(items: T[], chunkSize: number) => {
    const chunks: T[][] = [];
    for (let index = 0; index < items.length; index += chunkSize) {
        chunks.push(items.slice(index, index + chunkSize));
    }
    return chunks;
};

const TaskInstance: React.FC<TaskInstanceProps> = ({ onStatsChange, initialFilters }) => {
    const todayDate = dayjs().format('YYYY-MM-DD');
    const initialKeyword = initialFilters?.keyword?.trim() || '';
    const initialTaskSystem = initialFilters?.taskSystem || '';
    const initialTheme = initialFilters?.theme?.trim() || '';
    const initialRemark = initialFilters?.remark?.trim() || '';
    const initialDataDate = initialFilters?.dataDate || '';
    const initialCreateDate = initialFilters?.createDate ?? todayDate;
    const initialStatus = initialFilters?.status || '';
    const [taskList, setTaskList] = useState<QuartzTask[]>([]);
    const [instanceList, setInstanceList] = useState<QuartzTaskStatus[]>([]);
    const [summaryStats, setSummaryStats] = useState({
        totalInstances: 0,
        waitingInstances: 0,
        runningInstances: 0,
        successInstances: 0,
        failedInstances: 0,
    });
    const executorPoolStatsState = useExecutorPoolStats();
    const [logList, setLogList] = useState<QuartzTaskExecutionLog[]>([]);
    const [draftSearchKeyword, setDraftSearchKeyword] = useState(initialKeyword);
    const [draftTaskSystemFilter, setDraftTaskSystemFilter] = useState(initialTaskSystem);
    const [draftThemeFilter, setDraftThemeFilter] = useState(initialTheme);
    const [draftRemarkFilter, setDraftRemarkFilter] = useState(initialRemark);
    const [draftDataDateFilter, setDraftDataDateFilter] = useState(initialDataDate);
    const [draftCreateDateFilter, setDraftCreateDateFilter] = useState(initialCreateDate);
    const [draftStatusFilter, setDraftStatusFilter] = useState<string>(initialStatus);
    const [searchKeyword, setSearchKeyword] = useState(initialKeyword);
    const [taskSystemFilter, setTaskSystemFilter] = useState(initialTaskSystem);
    const [themeFilter, setThemeFilter] = useState(initialTheme);
    const [remarkFilter, setRemarkFilter] = useState(initialRemark);
    const [dataDateFilter, setDataDateFilter] = useState(initialDataDate);
    const [createDateFilter, setCreateDateFilter] = useState(initialCreateDate);
    const [statusFilter, setStatusFilter] = useState<string>(initialStatus);
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
    const [missedModalVisible, setMissedModalVisible] = useState(false);
    const [missedStartDate, setMissedStartDate] = useState(todayDate);
    const [missedEndDate, setMissedEndDate] = useState(todayDate);
    const [missedTaskSystem, setMissedTaskSystem] = useState('');
    const [missedTheme, setMissedTheme] = useState('');
    const [missedTasks, setMissedTasks] = useState<QuartzMissedTaskApiModel[]>([]);
    const [missedLoading, setMissedLoading] = useState(false);
    const [triggeringMissedKey, setTriggeringMissedKey] = useState<string | null>(null);
    const summaryStatsRefreshInFlightRef = useRef(false);

    const buildInstanceQueryParams = useCallback((filters?: {
        createDate?: string;
        dataDate?: string;
        status?: string;
        taskSystem?: string;
        theme?: string;
        remark?: string;
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
            theme: (nextFilters.theme ?? themeFilter.trim()) || undefined,
            remark: (nextFilters.remark ?? remarkFilter.trim()) || undefined,
            taskName: (nextFilters.keyword ?? searchKeyword.trim()) || undefined,
        };
    }, [createDateFilter, dataDateFilter, remarkFilter, searchKeyword, statusFilter, taskSystemFilter, themeFilter]);

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
        theme?: string;
        remark?: string;
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
        theme?: string;
        remark?: string;
        keyword?: string;
    }, options?: { silent?: boolean }) => {
        const mergedInstances = await queryAllInstances(filters, options);
        if (mergedInstances) {
            setInstanceList(mergedInstances);
        }
    }, [queryAllInstances]);

    const loadTodaySummaryStats = useCallback(async (options?: { silent?: boolean }) => {
        const todayInstances = await queryAllInstances({
            createDate: todayDate,
            dataDate: '',
            status: '',
            taskSystem: '',
            theme: '',
            remark: '',
            keyword: '',
        }, options);
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
        }, TASK_INSTANCE_REFRESH_INTERVAL_MS);
        return () => {
            window.clearInterval(timer);
        };
    }, [batchRerunExecuting, loadInstances]);

    useEffect(() => {
        loadTodaySummaryStats();
    }, [loadTodaySummaryStats]);

    useEffect(() => {
        let disposed = false;
        let timer: number | undefined;

        const scheduleNextRefresh = () => {
            const delay = document.visibilityState === 'hidden'
                ? SUMMARY_STATS_HIDDEN_REFRESH_INTERVAL_MS
                : SUMMARY_STATS_ACTIVE_REFRESH_INTERVAL_MS;
            timer = window.setTimeout(refreshStats, delay);
        };

        const refreshStats = async () => {
            if (disposed) return;
            if (batchRerunExecuting || summaryStatsRefreshInFlightRef.current) {
                scheduleNextRefresh();
                return;
            }

            summaryStatsRefreshInFlightRef.current = true;
            try {
                await loadTodaySummaryStats({ silent: true });
            } finally {
                summaryStatsRefreshInFlightRef.current = false;
                if (!disposed) {
                    scheduleNextRefresh();
                }
            }
        };

        scheduleNextRefresh();
        return () => {
            disposed = true;
            if (timer !== undefined) {
                window.clearTimeout(timer);
            }
        };
    }, [batchRerunExecuting, loadTodaySummaryStats]);

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
                const response = await queryQuartzTaskStatus({ statusId: instanceId, pageNum: 1, pageSize: 1 });
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
                instance.msg || '',
            ].some(item => item.toLowerCase().includes(keyword));
            const matchesTaskSystem = !taskSystemFilter || (task?.task_system || '') === taskSystemFilter;
            const matchesTheme = !themeFilter || (task?.theme || '').toLowerCase().includes(themeFilter.toLowerCase());
            const matchesRemark = !remarkFilter || (task?.remark || '').toLowerCase().includes(remarkFilter.toLowerCase());
            const matchesDataDate = !dataDateFilter || normalizeDateKey(instance.data_date) === normalizeDateKey(dataDateFilter);
            const matchesUpdateDate = !createDateFilter || normalizeDateKey(instance.update_time) === normalizeDateKey(createDateFilter);
            const matchesStatus = statusFilter === '' || String(instance.status ?? '') === statusFilter;

            return matchesKeyword && matchesTaskSystem && matchesTheme && matchesRemark && matchesDataDate && matchesUpdateDate && matchesStatus;
        }).sort((left, right) => {
            const updateTimeDiff = getDateTimeValue(right.update_time) - getDateTimeValue(left.update_time);
            if (updateTimeDiff !== 0) {
                return updateTimeDiff;
            }
            return right.id - left.id;
        });
    }, [createDateFilter, dataDateFilter, instanceList, remarkFilter, searchKeyword, statusFilter, taskMap, taskSystemFilter, themeFilter]);

    const pagedInstances = useMemo(() => {
        const start = (currentPage - 1) * pageSize;
        return filteredInstances.slice(start, start + pageSize);
    }, [currentPage, filteredInstances, pageSize]);

    useEffect(() => {
        setCurrentPage(1);
    }, [searchKeyword, taskSystemFilter, themeFilter, remarkFilter, statusFilter, dataDateFilter, createDateFilter]);

    const handleSearch = useCallback(() => {
        const nextKeyword = draftSearchKeyword.trim();
        const nextTheme = draftThemeFilter.trim();
        const nextRemark = draftRemarkFilter.trim();
        setSearchKeyword(nextKeyword);
        setTaskSystemFilter(draftTaskSystemFilter);
        setThemeFilter(nextTheme);
        setRemarkFilter(nextRemark);
        setDataDateFilter(draftDataDateFilter);
        setCreateDateFilter(draftCreateDateFilter);
        setStatusFilter(draftStatusFilter);
        setCurrentPage(1);
        void loadInstances({
            keyword: nextKeyword,
            taskSystem: draftTaskSystemFilter,
            theme: nextTheme,
            remark: nextRemark,
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
        draftThemeFilter,
        draftRemarkFilter,
        loadInstances,
    ]);

    const handleSummaryStatusClick = useCallback((nextStatus: string) => {
        const nextKeyword = draftSearchKeyword.trim();
        const nextTheme = draftThemeFilter.trim();
        const nextRemark = draftRemarkFilter.trim();
        setDraftStatusFilter(nextStatus);
        setSearchKeyword(nextKeyword);
        setTaskSystemFilter(draftTaskSystemFilter);
        setThemeFilter(nextTheme);
        setRemarkFilter(nextRemark);
        setDataDateFilter(draftDataDateFilter);
        setCreateDateFilter(draftCreateDateFilter);
        setStatusFilter(nextStatus);
        setCurrentPage(1);
        void loadInstances({
            keyword: nextKeyword,
            taskSystem: draftTaskSystemFilter,
            theme: nextTheme,
            remark: nextRemark,
            dataDate: draftDataDateFilter,
            createDate: draftCreateDateFilter,
            status: nextStatus,
        });
    }, [
        draftCreateDateFilter,
        draftDataDateFilter,
        draftSearchKeyword,
        draftTaskSystemFilter,
        draftThemeFilter,
        draftRemarkFilter,
        loadInstances,
    ]);

    const handleResetFilters = useCallback(() => {
        setDraftSearchKeyword('');
        setDraftTaskSystemFilter('');
        setDraftThemeFilter('');
        setDraftRemarkFilter('');
        setDraftDataDateFilter('');
        setDraftCreateDateFilter(todayDate);
        setDraftStatusFilter('');
        setSearchKeyword('');
        setTaskSystemFilter('');
        setThemeFilter('');
        setRemarkFilter('');
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
        enabled: instanceDetailTabKey === 'dependency',
    });
    const rerunExecutionDependencyData = useDependencyInsightData({
        selectedInstance: rerunExecutionInstance,
        taskList,
        instanceList,
        taskMap,
        enabled: !!rerunExecutionInstance,
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

    const openRowContextMenu = (instance: QuartzTaskStatus, event: React.MouseEvent<HTMLElement>) => {
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

    const handleOpenMissedTasks = () => {
        setMissedStartDate(dataDateFilter || todayDate);
        setMissedEndDate(dataDateFilter || todayDate);
        setMissedTaskSystem(taskSystemFilter);
        setMissedTheme(themeFilter);
        setMissedModalVisible(true);
    };

    const handleQueryMissedTasks = async () => {
        if (!missedStartDate || !missedEndDate) {
            message.error('请选择未下发检查日期范围');
            return;
        }
        setMissedLoading(true);
        try {
            const response = await queryQuartzMissedTasks({
                pageNum: 1,
                pageSize: 500,
                startDate: missedStartDate.replaceAll('-', ''),
                endDate: missedEndDate.replaceAll('-', ''),
                taskSystem: missedTaskSystem || undefined,
                theme: missedTheme.trim() || undefined,
            });
            if (!response?.success) {
                throw new Error(response?.msg || '查询未下发任务失败');
            }
            setMissedTasks(response.data?.list || []);
        } catch (error: any) {
            message.error(error?.message || '查询未下发任务失败');
        } finally {
            setMissedLoading(false);
        }
    };

    const handleTriggerMissedTask = async (task: QuartzMissedTaskApiModel) => {
        const key = `${task.taskId}_${task.expectedDate}`;
        setTriggeringMissedKey(key);
        try {
            const response = await triggerNowQuartzTask(task.taskId, task.expectedDate);
            if (!response?.success) {
                throw new Error(response?.msg || '补发任务失败');
            }
            setMissedTasks(prev => prev.filter(item => `${item.taskId}_${item.expectedDate}` !== key));
            await loadInstances();
            await loadTodaySummaryStats();
            message.success(`已补发任务 ${task.taskName || task.taskId} / ${task.expectedDate}`);
        } catch (error: any) {
            message.error(error?.message || '补发任务失败');
        } finally {
            setTriggeringMissedKey(null);
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
                executorPoolStatsState={executorPoolStatsState}
                taskMap={taskMap}
                taskNameMap={taskNameMap}
                taskSystemOptions={taskSystemOptions}
                searchKeyword={draftSearchKeyword}
                taskSystemFilter={draftTaskSystemFilter}
                themeFilter={draftThemeFilter}
                remarkFilter={draftRemarkFilter}
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
                onThemeFilterChange={setDraftThemeFilter}
                onRemarkFilterChange={setDraftRemarkFilter}
                onDataDateFilterChange={setDraftDataDateFilter}
                onCreateDateFilterChange={setDraftCreateDateFilter}
                onStatusFilterChange={setDraftStatusFilter}
                onSummaryStatusClick={handleSummaryStatusClick}
                onSearch={handleSearch}
                onResetFilters={handleResetFilters}
                onToggleSelectAllVisible={toggleSelectAllVisible}
                onToggleSelectInstance={toggleSelectInstance}
                onBatchExecute={handleBatchExecute}
                onBatchForceStop={handleBatchForceStop}
                onBatchForcePass={handleBatchForcePass}
                onOpenMissedTasks={handleOpenMissedTasks}
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
                onExecuteInstance={handleExecuteInstance}
                onForceStopInstance={handleForceStopInstance}
                onForcePassInstance={handleForcePassInstance}
            />

            <Modal
                title="未下发任务检查"
                open={missedModalVisible}
                width={980}
                footer={null}
                onCancel={() => setMissedModalVisible(false)}
                destroyOnHidden
            >
                <div className="space-y-4">
                    <div className="grid grid-cols-1 gap-3 md:grid-cols-5">
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">开始日期</div>
                            <input
                                type="date"
                                value={missedStartDate}
                                onChange={(event) => setMissedStartDate(event.target.value)}
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </label>
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">结束日期</div>
                            <input
                                type="date"
                                value={missedEndDate}
                                onChange={(event) => setMissedEndDate(event.target.value)}
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </label>
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">系统主体</div>
                            <select
                                value={missedTaskSystem}
                                onChange={(event) => setMissedTaskSystem(event.target.value)}
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            >
                                <option value="">全部系统</option>
                                {taskSystemOptions.map(item => (
                                    <option key={item} value={item}>{item}</option>
                                ))}
                            </select>
                        </label>
                        <label className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">主题</div>
                            <input
                                value={missedTheme}
                                onChange={(event) => setMissedTheme(event.target.value)}
                                placeholder="搜索主题"
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </label>
                        <div className="space-y-1">
                            <div className="text-xs font-medium text-slate-500">操作</div>
                            <button
                                type="button"
                                onClick={handleQueryMissedTasks}
                                disabled={missedLoading}
                                className="inline-flex h-[42px] w-full items-center justify-center rounded-xl bg-red-600 px-3 text-sm font-semibold text-white transition-colors hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                {missedLoading ? '检查中...' : '开始检查'}
                            </button>
                        </div>
                    </div>

                    <div className="overflow-hidden rounded-xl border border-slate-200">
                        <div className="overflow-x-auto">
                            <table className="w-full min-w-[860px] table-fixed text-left text-sm">
                                <colgroup>
                                    <col style={{ width: 90 }} />
                                    <col style={{ width: 180 }} />
                                    <col style={{ width: 120 }} />
                                    <col style={{ width: 120 }} />
                                    <col style={{ width: 110 }} />
                                    <col style={{ width: 150 }} />
                                    <col style={{ width: 100 }} />
                                </colgroup>
                                <thead className="border-b border-slate-200 bg-slate-50 text-xs font-semibold text-slate-500">
                                    <tr>
                                        <th className="px-4 py-3">任务ID</th>
                                        <th className="px-4 py-3">任务名称</th>
                                        <th className="px-4 py-3">系统</th>
                                        <th className="px-4 py-3">主题</th>
                                        <th className="px-4 py-3">数据日期</th>
                                        <th className="px-4 py-3">上次成功</th>
                                        <th className="px-4 py-3">操作</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {missedTasks.length === 0 ? (
                                        <tr>
                                            <td colSpan={7} className="px-4 py-10 text-center text-slate-500">
                                                暂无未下发任务。
                                            </td>
                                        </tr>
                                    ) : missedTasks.map(task => {
                                        const key = `${task.taskId}_${task.expectedDate}`;
                                        return (
                                            <tr key={key} className="hover:bg-slate-50">
                                                <td className="px-4 py-3 font-mono text-xs text-slate-600">{task.taskId}</td>
                                                <td className="px-4 py-3 font-medium text-slate-800">{task.taskName || '-'}</td>
                                                <td className="px-4 py-3 text-slate-600">{task.taskSystem || '-'}</td>
                                                <td className="px-4 py-3 text-slate-600">{task.theme || '-'}</td>
                                                <td className="px-4 py-3 font-mono text-xs text-slate-600">{task.expectedDate}</td>
                                                <td className="px-4 py-3 text-xs text-slate-500">
                                                    {task.lastSuccessDate || '-'}
                                                    {task.lastSuccessTime ? ` / ${task.lastSuccessTime}` : ''}
                                                </td>
                                                <td className="px-4 py-3">
                                                    <button
                                                        type="button"
                                                        onClick={() => handleTriggerMissedTask(task)}
                                                        disabled={triggeringMissedKey === key}
                                                        className="rounded-lg border border-blue-200 bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700 transition-colors hover:bg-blue-100 disabled:cursor-not-allowed disabled:opacity-50"
                                                    >
                                                        {triggeringMissedKey === key ? '补发中' : '补发'}
                                                    </button>
                                                </td>
                                            </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </Modal>
        </>
    );
};

export default TaskInstance;
