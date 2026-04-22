import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { message, Modal } from 'antd';
import {
    clearLineageDatabase,
    getLineageEngineLogs,
    getLineageEngineStatus,
    restartLineageEngine,
    startLineageEngine,
    stopLineageEngine,
} from '@/api/lineage';
import type { LineageEngineStartParams } from '@/api/lineage';
import { hasPermission } from '@/utils/permission';

type EngineStatus = 'running' | 'stopped' | 'starting';
type EngineAction = 'start' | 'stop' | 'restart' | 'clear' | null;

interface EngineMeta {
    lastStartedAt?: string;
    lastStoppedAt?: string;
    pid?: number;
    versionStatus?: {
        consistent: boolean;
        message: string;
        lastAnalysisTime: string;
        lastCommitSha: string;
        currentCommitSha: string;
    };
}

interface EngineStatusResponse {
    status?: EngineStatus;
    lastStartedAt?: string;
    lastStoppedAt?: string;
    pid?: number;
    recordId?: string;
    versionStatus?: EngineMeta['versionStatus'];
}

interface EngineLogsResponse {
    lines?: string[];
}

const sanitizeStartParams = (params: LineageEngineStartParams) => {
    if (params.sourceType === 'upload') {
        return {
            sourceType: params.sourceType,
            user: params.user,
            language: params.language,
            fileCount: params.files.length,
            fileNames: params.files.map(file => file.name),
            fileSizes: params.files.map(file => file.size),
        };
    }

    return {
        sourceType: params.sourceType,
        repoId: params.repoId,
        ref: params.ref,
        user: params.user,
        language: params.language,
        pathCount: params.paths.length,
        paths: params.paths,
    };
};

const formatError = (error: unknown) => error;

export const useLineageEngineController = () => {
    const [showLogModal, setShowLogModal] = useState(false);
    const [showStartModal, setShowStartModal] = useState(false);
    const [engineStatus, setEngineStatus] = useState<EngineStatus>('stopped');
    const [engineActionLoading, setEngineActionLoading] = useState<EngineAction>(null);
    const [engineLogs, setEngineLogs] = useState<string[]>([]);
    const [engineLogsLoading, setEngineLogsLoading] = useState(false);
    const [engineLogRecordId, setEngineLogRecordId] = useState<string>();
    const [engineMeta, setEngineMeta] = useState<EngineMeta>({});
    const [autoRefresh, setAutoRefresh] = useState(true);

    const latestLogFetchTokenRef = useRef(0);
    const operationSequenceRef = useRef(0);
    const previousStatusRef = useRef<EngineStatus>('stopped');
    const previousRecordIdRef = useRef<string>();

    const canViewEngineStatus = hasPermission('metadata:lineage:engine:logs');
    const canStartEngine = hasPermission('metadata:lineage:engine:start');
    const canRestartEngine = hasPermission('metadata:lineage:engine:restart');
    const canStopEngine = hasPermission('metadata:lineage:engine:stop');
    const canViewEngineLogs = hasPermission('metadata:lineage:engine:logs');

    const engineStatusMeta = useMemo(() => ({
        running: { badge: 'success' as const, label: '运行中' },
        stopped: { badge: 'default' as const, label: '未启动' },
        starting: { badge: 'processing' as const, label: '启动中' },
    }), []);

    const engineStatusInfo = engineStatusMeta[engineStatus];

    const createOperationId = useCallback((action: string) => {
        operationSequenceRef.current += 1;
        return `${action}-${Date.now()}-${operationSequenceRef.current}`;
    }, []);

    const logInfo = useCallback((_event: string, _detail?: Record<string, unknown>) => {}, []);

    const logWarn = useCallback((_event: string, _detail?: Record<string, unknown>) => {}, []);

    const logError = useCallback((_event: string, _detail?: Record<string, unknown>) => {}, []);

    const fetchEngineStatus = useCallback(async (trigger: string = 'manual') => {
        if (!canViewEngineStatus) {
            logWarn('skip_status_fetch_no_permission', { trigger });
            return undefined;
        }

        const operationId = createOperationId(`status:${trigger}`);
        const startedAt = performance.now();
        logInfo('status_fetch_started', {
            operationId,
            trigger,
            currentStatus: engineStatus,
            currentRecordId: engineLogRecordId,
            showLogModal,
            autoRefresh,
        });

        try {
            const res = await getLineageEngineStatus() as EngineStatusResponse;
            const nextStatus = res?.status;
            const nextRecordId = typeof res?.recordId === 'string' ? res.recordId : undefined;

            if (nextStatus && nextStatus !== previousStatusRef.current) {
                logWarn('status_transition_detected', {
                    operationId,
                    from: previousStatusRef.current,
                    to: nextStatus,
                    pid: res?.pid,
                    recordId: nextRecordId,
                });
                previousStatusRef.current = nextStatus;
                setEngineStatus(nextStatus);
            } else if (nextStatus) {
                setEngineStatus(nextStatus);
            }

            if (nextRecordId !== previousRecordIdRef.current) {
                logWarn('record_id_changed', {
                    operationId,
                    from: previousRecordIdRef.current,
                    to: nextRecordId,
                });
                previousRecordIdRef.current = nextRecordId;
            }

            setEngineMeta({
                lastStartedAt: res?.lastStartedAt,
                lastStoppedAt: res?.lastStoppedAt,
                pid: res?.pid,
                versionStatus: res?.versionStatus,
            });
            setEngineLogRecordId(nextRecordId);

            logInfo('status_fetch_succeeded', {
                operationId,
                trigger,
                durationMs: Math.round(performance.now() - startedAt),
                status: nextStatus,
                recordId: nextRecordId,
                pid: res?.pid,
                lastStartedAt: res?.lastStartedAt,
                lastStoppedAt: res?.lastStoppedAt,
                versionConsistent: res?.versionStatus?.consistent,
                versionMessage: res?.versionStatus?.message,
            });

            return res;
        } catch (error) {
            logError('status_fetch_failed', {
                operationId,
                trigger,
                durationMs: Math.round(performance.now() - startedAt),
                error: formatError(error),
            });
            message.error('获取引擎状态失败');
            return undefined;
        }
    }, [
        autoRefresh,
        canViewEngineStatus,
        createOperationId,
        engineLogRecordId,
        engineStatus,
        logError,
        logInfo,
        logWarn,
        showLogModal,
    ]);

    const fetchEngineLogs = useCallback(async (silent: boolean = false, preferredRecordId?: string, trigger: string = 'manual') => {
        if (!canViewEngineLogs) {
            logWarn('skip_log_fetch_no_permission', { trigger, silent });
            if (!silent) {
                message.error('无权限查看日志');
            }
            return;
        }

        const operationId = createOperationId(`logs:${trigger}`);
        const startedAt = performance.now();
        const fetchToken = ++latestLogFetchTokenRef.current;
        if (!silent) {
            setEngineLogsLoading(true);
        }

        logInfo('log_fetch_started', {
            operationId,
            trigger,
            silent,
            fetchToken,
            preferredRecordId,
            currentRecordId: engineLogRecordId,
            existingLineCount: engineLogs.length,
        });

        try {
            let targetRecordId = preferredRecordId ?? engineLogRecordId;
            let res = await getLineageEngineLogs(200, targetRecordId) as EngineLogsResponse;
            let lines = Array.isArray(res?.lines) ? res.lines : [];

            if (lines.length === 0 && !targetRecordId) {
                logWarn('log_fetch_empty_without_record_id', {
                    operationId,
                    fetchToken,
                    trigger,
                });

                const statusRes = await getLineageEngineStatus().catch(statusError => {
                    logError('log_fetch_fallback_status_failed', {
                        operationId,
                        trigger,
                        fetchToken,
                        error: formatError(statusError),
                    });
                    return undefined;
                }) as EngineStatusResponse | undefined;

                const statusRecordId = typeof statusRes?.recordId === 'string' ? statusRes.recordId : undefined;
                if (statusRecordId) {
                    targetRecordId = statusRecordId;
                    previousRecordIdRef.current = statusRecordId;
                    setEngineLogRecordId(statusRecordId);
                    logWarn('log_fetch_retry_with_status_record_id', {
                        operationId,
                        trigger,
                        fetchToken,
                        retryRecordId: statusRecordId,
                    });
                    res = await getLineageEngineLogs(200, statusRecordId) as EngineLogsResponse;
                    lines = Array.isArray(res?.lines) ? res.lines : [];
                }
            }

            if (fetchToken !== latestLogFetchTokenRef.current) {
                logWarn('log_fetch_discarded_outdated_response', {
                    operationId,
                    trigger,
                    fetchToken,
                    latestFetchToken: latestLogFetchTokenRef.current,
                });
                return;
            }

            setEngineLogs(lines);
            logInfo('log_fetch_succeeded', {
                operationId,
                trigger,
                fetchToken,
                durationMs: Math.round(performance.now() - startedAt),
                lineCount: lines.length,
                recordId: targetRecordId,
                previewFirstLine: lines[0],
                previewLastLine: lines[lines.length - 1],
            });
        } catch (error) {
            logError('log_fetch_failed', {
                operationId,
                trigger,
                fetchToken,
                durationMs: Math.round(performance.now() - startedAt),
                preferredRecordId,
                currentRecordId: engineLogRecordId,
                error: formatError(error),
            });
            if (!silent) {
                message.error('获取日志失败');
            }
        } finally {
            if (!silent) {
                setEngineLogsLoading(false);
            }
        }
    }, [
        canViewEngineLogs,
        createOperationId,
        engineLogRecordId,
        engineLogs.length,
        logError,
        logInfo,
        logWarn,
    ]);

    useEffect(() => {
        if (!canViewEngineStatus) {
            return;
        }

        logInfo('status_polling_started', { intervalMs: 15000 });
        fetchEngineStatus('initial');
        const timer = window.setInterval(() => {
            fetchEngineStatus('polling');
        }, 15000);

        return () => {
            window.clearInterval(timer);
            logInfo('status_polling_stopped', { intervalMs: 15000 });
        };
    }, [canViewEngineStatus, fetchEngineStatus, logInfo]);

    useEffect(() => {
        if (!(showLogModal && autoRefresh)) {
            return;
        }

        logInfo('log_auto_refresh_started', {
            intervalMs: 3000,
            recordId: engineLogRecordId,
        });
        const timer = window.setInterval(() => {
            fetchEngineLogs(true, engineLogRecordId, 'auto_refresh');
        }, 3000);

        return () => {
            clearInterval(timer);
            logInfo('log_auto_refresh_stopped', {
                intervalMs: 3000,
                recordId: engineLogRecordId,
            });
        };
    }, [autoRefresh, engineLogRecordId, fetchEngineLogs, logInfo, showLogModal]);

    const handleStartEngine = useCallback(() => {
        if (!canStartEngine) {
            logWarn('start_engine_denied_no_permission');
            message.error('无权限启动引擎');
            return;
        }

        logInfo('start_modal_opened', {
            currentStatus: engineStatus,
            recordId: engineLogRecordId,
        });
        setShowStartModal(true);
    }, [canStartEngine, engineLogRecordId, engineStatus, logInfo, logWarn]);

    const handleConfirmStartEngine = useCallback(async (params: LineageEngineStartParams) => {
        const operationId = createOperationId('start');
        const startedAt = performance.now();
        setEngineActionLoading('start');
        setEngineStatus('starting');

        logWarn('engine_start_requested', {
            operationId,
            params: sanitizeStartParams(params),
            previousStatus: previousStatusRef.current,
            previousRecordId: previousRecordIdRef.current,
        });

        try {
            const res = await startLineageEngine(params) as {
                success?: boolean;
                message?: string;
                recordId?: string;
            };

            logInfo('engine_start_response_received', {
                operationId,
                durationMs: Math.round(performance.now() - startedAt),
                success: res?.success,
                message: res?.message,
                recordId: res?.recordId,
            });

            if (res?.success === false) {
                message.error(res.message || '引擎启动失败');
                return;
            }

            const startRecordId = typeof res?.recordId === 'string' ? res.recordId : undefined;
            previousRecordIdRef.current = startRecordId;
            setEngineLogRecordId(startRecordId);
            message.success('解析引擎启动指令已下发');
            setShowStartModal(false);

            await fetchEngineStatus('after_start');
            await fetchEngineLogs(false, startRecordId, 'after_start');
        } catch (error) {
            logError('engine_start_failed', {
                operationId,
                durationMs: Math.round(performance.now() - startedAt),
                error: formatError(error),
            });
            message.error('启动引擎出错');
        } finally {
            setEngineActionLoading(null);
        }
    }, [createOperationId, fetchEngineLogs, fetchEngineStatus, logError, logInfo, logWarn]);

    const handleRestartEngine = useCallback(async () => {
        if (!canRestartEngine) {
            logWarn('restart_engine_denied_no_permission');
            message.error('无权限重启引擎');
            return;
        }

        const operationId = createOperationId('restart');
        const startedAt = performance.now();
        setEngineActionLoading('restart');
        setEngineStatus('starting');

        logWarn('engine_restart_requested', {
            operationId,
            previousStatus: previousStatusRef.current,
            currentRecordId: engineLogRecordId,
        });

        try {
            const res = await restartLineageEngine() as {
                success?: boolean;
                message?: string;
            };

            logInfo('engine_restart_response_received', {
                operationId,
                durationMs: Math.round(performance.now() - startedAt),
                success: res?.success,
                message: res?.message,
            });

            if (res?.success === false) {
                message.error(res.message || '引擎重启失败');
            } else if (res?.message) {
                message.success(res.message);
            } else {
                message.success('引擎重启中');
            }

            await fetchEngineStatus('after_restart');
        } catch (error) {
            logError('engine_restart_failed', {
                operationId,
                durationMs: Math.round(performance.now() - startedAt),
                error: formatError(error),
            });
            message.error('引擎重启失败');
            await fetchEngineStatus('restart_failed_recovery');
        } finally {
            setEngineActionLoading(null);
        }
    }, [canRestartEngine, createOperationId, engineLogRecordId, fetchEngineStatus, logError, logInfo, logWarn]);

    const handleStopEngine = useCallback(async () => {
        if (!canStopEngine) {
            logWarn('stop_engine_denied_no_permission');
            message.error('无权限停止引擎');
            return;
        }

        const operationId = createOperationId('stop');
        const startedAt = performance.now();
        setEngineActionLoading('stop');

        logWarn('engine_stop_requested', {
            operationId,
            previousStatus: previousStatusRef.current,
            currentRecordId: engineLogRecordId,
        });

        try {
            const res = await stopLineageEngine() as {
                success?: boolean;
                message?: string;
            };

            logInfo('engine_stop_response_received', {
                operationId,
                durationMs: Math.round(performance.now() - startedAt),
                success: res?.success,
                message: res?.message,
            });

            if (res?.success === false) {
                message.error(res.message || '引擎停止失败');
            } else if (res?.message) {
                message.success(res.message);
            } else {
                message.success('引擎已停止');
            }

            await fetchEngineStatus('after_stop');
        } catch (error) {
            logError('engine_stop_failed', {
                operationId,
                durationMs: Math.round(performance.now() - startedAt),
                error: formatError(error),
            });
            message.error('引擎停止失败');
            await fetchEngineStatus('stop_failed_recovery');
        } finally {
            setEngineActionLoading(null);
        }
    }, [canStopEngine, createOperationId, engineLogRecordId, fetchEngineStatus, logError, logInfo, logWarn]);

    const handleOpenLogs = useCallback(async () => {
        if (!canViewEngineLogs) {
            logWarn('open_logs_denied_no_permission');
            message.error('无权限查看日志');
            return;
        }

        logInfo('log_modal_opened', {
            currentRecordId: engineLogRecordId,
            currentStatus: engineStatus,
        });
        setShowLogModal(true);
        const statusRes = await fetchEngineStatus('open_logs');
        const statusRecordId = typeof statusRes?.recordId === 'string' ? statusRes.recordId : undefined;
        await fetchEngineLogs(false, statusRecordId, 'open_logs');
    }, [canViewEngineLogs, engineLogRecordId, engineStatus, fetchEngineLogs, fetchEngineStatus, logInfo, logWarn]);

    const handleCloseLogs = useCallback(() => {
        logInfo('log_modal_closed', {
            currentRecordId: engineLogRecordId,
            cachedLineCount: engineLogs.length,
        });
        setShowLogModal(false);
    }, [engineLogRecordId, engineLogs.length, logInfo]);

    const handleClearDatabase = useCallback(() => {
        Modal.confirm({
            title: '确认清空数据库',
            content: '此操作将删除 Neo4j 中的所有血缘数据，且不可恢复。确定要继续吗？',
            okText: '确认清空',
            okType: 'danger',
            cancelText: '取消',
            onOk: async () => {
                const operationId = createOperationId('clear');
                const startedAt = performance.now();
                setEngineActionLoading('clear');
                logWarn('engine_clear_database_requested', {
                    operationId,
                    currentStatus: engineStatus,
                    currentRecordId: engineLogRecordId,
                });

                try {
                    const res = await clearLineageDatabase() as {
                        success?: boolean;
                        message?: string;
                    };

                    logInfo('engine_clear_database_response_received', {
                        operationId,
                        durationMs: Math.round(performance.now() - startedAt),
                        success: res?.success,
                        message: res?.message,
                    });

                    if (res?.success === false) {
                        message.error(res.message || '清空失败');
                    } else {
                        message.success(res?.message || '数据库已清空');
                    }
                } catch (error) {
                    logError('engine_clear_database_failed', {
                        operationId,
                        durationMs: Math.round(performance.now() - startedAt),
                        error: formatError(error),
                    });
                    message.error('清空数据库失败');
                } finally {
                    setEngineActionLoading(null);
                }
            },
        });
    }, [createOperationId, engineLogRecordId, engineStatus, logError, logInfo, logWarn]);

    return {
        autoRefresh,
        canRestartEngine,
        canStartEngine,
        canStopEngine,
        canViewEngineLogs,
        canViewEngineStatus,
        engineActionLoading,
        engineLogRecordId,
        engineLogs,
        engineLogsLoading,
        engineMeta,
        engineStatus,
        engineStatusInfo,
        fetchEngineLogs,
        handleClearDatabase,
        handleCloseLogs,
        handleConfirmStartEngine,
        handleOpenLogs,
        handleRestartEngine,
        handleStartEngine,
        handleStopEngine,
        setAutoRefresh,
        setShowStartModal,
        showLogModal,
        showStartModal,
    };
};

export type UseLineageEngineControllerResult = ReturnType<typeof useLineageEngineController>;
