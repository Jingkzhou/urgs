import React, { useEffect, useRef, useState } from 'react';
import { Drawer, Tabs, Tag, message } from 'antd';
import {
    Activity,
    AlertCircle,
    CalendarRange,
    CheckCircle2,
    Clock3,
    Copy,
    Download,
    GitBranch,
    Play,
    Sparkles,
    Square,
} from 'lucide-react';
import dayjs from 'dayjs';
import { streamSolutionGeneration } from '@/api/ops';
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
    DependencyInsightData,
    InstanceDetailTabKey,
} from './types';
import TaskInstanceDependencyPanel from './TaskInstanceDependencyPanel';

interface TaskInstanceDetailDrawerProps {
    selectedInstance: QuartzTaskStatus | null;
    selectedTask: QuartzTask | null;
    taskNameMap: Map<number, string>;
    instanceDetailTabKey: InstanceDetailTabKey;
    dependencyPanelData: DependencyInsightData | null;
    selectedInstanceLogs: QuartzTaskExecutionLog[];
    showImpactedOnly: boolean;
    onClose: () => void;
    onTabChange: (key: InstanceDetailTabKey) => void;
    onShowImpactedOnlyChange: (nextValue: boolean) => void;
    onLocateInstanceFromDependency: (instance: QuartzTaskStatus) => void;
    onExecuteInstance: (instance: QuartzTaskStatus) => void;
    onForceStopInstance: (instance: QuartzTaskStatus) => void;
    onForcePassInstance: (instance: QuartzTaskStatus) => void;
}

const TaskInstanceDetailDrawer: React.FC<TaskInstanceDetailDrawerProps> = ({
    selectedInstance,
    selectedTask,
    taskNameMap,
    instanceDetailTabKey,
    dependencyPanelData,
    selectedInstanceLogs,
    showImpactedOnly,
    onClose,
    onTabChange,
    onShowImpactedOnlyChange,
    onLocateInstanceFromDependency,
    onExecuteInstance,
    onForceStopInstance,
    onForcePassInstance,
}) => {
    const [explainingLogId, setExplainingLogId] = useState<number | null>(null);
    const [logAiExplanations, setLogAiExplanations] = useState<Record<number, string>>({});
    const logScrollRefs = useRef(new Map<number, HTMLDivElement | null>());
    const shouldFollowLogTailRef = useRef(true);

    const isLogScrolledToTail = (element: HTMLDivElement) =>
        element.scrollHeight - element.scrollTop - element.clientHeight < 24;

    const scrollLogToTail = (element: HTMLDivElement | null) => {
        if (!element) return;
        element.scrollTop = element.scrollHeight;
    };

    const getTaskName = () => selectedTask?.task_name || taskNameMap.get(selectedInstance?.plan_id || 0) || '-';

    const normalizeFilenamePart = (value: string | number | null | undefined) =>
        String(value ?? 'unknown')
            .trim()
            .replace(/[\\/:*?"<>|]/g, '_')
            .replace(/\s+/g, '_') || 'unknown';

    const buildLogText = (log: QuartzTaskExecutionLog) => {
        const mappedStatus = instanceStatusMap[log.status] || instanceStatusMap[1];
        return [
            `日志 #${log.id}`,
            `任务名称: ${getTaskName()}`,
            `实例ID: ${selectedInstance?.id ?? '-'}`,
            `计划ID: ${selectedInstance?.plan_id ?? log.task_id ?? '-'}`,
            `数据日期: ${selectedInstance?.data_date || log.data_date || '-'}`,
            `触发类型: ${log.trigger_type || '-'}`,
            `状态: ${mappedStatus?.label || log.status || '-'}`,
            `开始时间: ${log.begin_time || '-'}`,
            `结束时间: ${log.end_time || '-'}`,
            `耗时: ${formatDuration(log.duration_ms)}`,
            `创建时间: ${log.create_time || '-'}`,
            '',
            '执行摘要:',
            log.summary || '-',
            '',
            '逐步日志:',
            log.content || '无日志明细',
        ].join('\n');
    };

    const buildAllLogsText = () => {
        if (selectedInstanceLogs.length === 0) {
            return selectedInstance?.msg || '';
        }
        return selectedInstanceLogs.map(buildLogText).join('\n\n---\n\n');
    };

    const copyText = async (text: string, successMessage: string) => {
        if (!text.trim()) {
            message.warning('暂无可复制日志');
            return;
        }
        try {
            if (navigator.clipboard?.writeText) {
                await navigator.clipboard.writeText(text);
            } else {
                const textarea = document.createElement('textarea');
                textarea.value = text;
                textarea.setAttribute('readonly', 'true');
                textarea.style.position = 'fixed';
                textarea.style.opacity = '0';
                document.body.appendChild(textarea);
                textarea.select();
                document.execCommand('copy');
                document.body.removeChild(textarea);
            }
            message.success(successMessage);
        } catch {
            message.error('复制日志失败');
        }
    };

    const downloadText = (text: string, filename: string) => {
        if (!text.trim()) {
            message.warning('暂无可下载日志');
            return;
        }
        const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    };

    const buildLogFilename = (log?: QuartzTaskExecutionLog) => {
        const taskName = normalizeFilenamePart(getTaskName());
        const instanceId = normalizeFilenamePart(selectedInstance?.id);
        const dataDate = normalizeFilenamePart(selectedInstance?.data_date || log?.data_date);
        const logId = log ? `_log_${normalizeFilenamePart(log.id)}` : '';
        return `task_instance_${instanceId}_${taskName}_${dataDate}${logId}.log`;
    };

    const buildLogExplanationPrompt = (log: QuartzTaskExecutionLog) => {
        const logText = buildLogText(log);
        const scriptText = selectedTask?.script?.trim();
        const taskContext = [
            `任务名称: ${getTaskName()}`,
            `任务类型: ${selectedTask?.task_type || '-'}`,
            `任务 Bean: ${selectedTask?.task_bean || '-'}`,
            `任务参数: ${selectedTask?.task_params || '-'}`,
            `执行资源: ${selectedTask?.datasource_pool_name || selectedTask?.datasource_name || selectedTask?.datasource_id || '-'}`,
            `实例消息: ${selectedInstance?.msg || '-'}`,
            scriptText ? `执行脚本:\n${scriptText.slice(0, 4000)}` : '执行脚本: -',
        ].join('\n');

        return [
            '请解释这次批量任务执行报错的原因。',
            '要求:',
            '1. 先给出最可能的根因。',
            '2. 用日志证据说明判断依据。',
            '3. 给出下一步排查或修复动作。',
            '4. 如果日志不足以判断，明确说明还缺什么信息。',
            '',
            '任务上下文:',
            taskContext,
            '',
            '执行日志:',
            logText.slice(-12000),
        ].join('\n');
    };

    const handleExplainLogError = async (log: QuartzTaskExecutionLog) => {
        const prompt = buildLogExplanationPrompt(log).trim();
        if (!prompt) {
            message.warning('暂无可解释的日志内容');
            return;
        }

        setExplainingLogId(log.id);
        setLogAiExplanations(prev => ({ ...prev, [log.id]: '' }));

        try {
            await streamSolutionGeneration(
                {
                    systemPrompt: '你是资深批量运维和数据任务排障工程师。请基于任务上下文和执行日志解释当前报错原因，回答使用简洁中文，避免泛泛而谈。',
                    userPrompt: prompt,
                },
                (content) => {
                    setLogAiExplanations(prev => ({
                        ...prev,
                        [log.id]: `${prev[log.id] || ''}${content}`,
                    }));
                },
                () => {
                    message.success(`日志 #${log.id} 解释已生成`);
                },
                (error) => {
                    message.error(`AI 解释失败：${error}`);
                }
            );
        } finally {
            setExplainingLogId(null);
        }
    };

    useEffect(() => {
        if (!selectedInstance || instanceDetailTabKey !== 'runtimeLog' || !shouldFollowLogTailRef.current) {
            return;
        }
        window.requestAnimationFrame(() => {
            selectedInstanceLogs.forEach(log => scrollLogToTail(logScrollRefs.current.get(log.id) || null));
        });
    }, [instanceDetailTabKey, selectedInstance, selectedInstanceLogs]);

    useEffect(() => {
        if (!selectedInstance || instanceDetailTabKey !== 'runtimeLog') {
            return;
        }
        shouldFollowLogTailRef.current = true;
        window.requestAnimationFrame(() => {
            selectedInstanceLogs.forEach(log => scrollLogToTail(logScrollRefs.current.get(log.id) || null));
        });
    }, [instanceDetailTabKey, selectedInstance?.id]);

    useEffect(() => {
        setExplainingLogId(null);
        setLogAiExplanations({});
    }, [selectedInstance?.id]);

    const allLogsText = buildAllLogsText();
    const hasLogExportText = allLogsText.trim().length > 0;
    const canExecuteInstance = selectedInstance?.status === 3 || selectedInstance?.status === 4;
    const canForceStopInstance = selectedInstance?.status === 1 || selectedInstance?.status === 2;
    const canForcePassInstance = selectedInstance?.status === 4;
    const actionButtonClass = 'inline-flex h-8 items-center gap-1.5 rounded-lg border px-2.5 text-xs font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50';

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
                            <div className="flex flex-col items-start gap-2 lg:items-end">
                                <div className="flex flex-wrap items-center gap-2">
                                    <button
                                        type="button"
                                        onClick={() => onExecuteInstance(selectedInstance)}
                                        disabled={!canExecuteInstance}
                                        className={`${actionButtonClass} border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100 disabled:hover:bg-blue-50`}
                                    >
                                        <Play size={14} />
                                        重新跑批
                                    </button>
                                    <button
                                        type="button"
                                        onClick={() => onForceStopInstance(selectedInstance)}
                                        disabled={!canForceStopInstance}
                                        className={`${actionButtonClass} border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100 disabled:hover:bg-amber-50`}
                                    >
                                        <Square size={14} />
                                        强制停止
                                    </button>
                                    <button
                                        type="button"
                                        onClick={() => onForcePassInstance(selectedInstance)}
                                        disabled={!canForcePassInstance}
                                        className={`${actionButtonClass} border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 disabled:hover:bg-emerald-50`}
                                    >
                                        <CheckCircle2 size={14} />
                                        强制通过
                                    </button>
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
                                    <TaskInstanceDependencyPanel
                                        selectedInstance={selectedInstance}
                                        dependencyPanelData={dependencyPanelData}
                                        showImpactedOnly={showImpactedOnly}
                                        onShowImpactedOnlyChange={onShowImpactedOnlyChange}
                                        onLocateInstanceFromDependency={onLocateInstanceFromDependency}
                                    />
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
                                                        <div className="text-xs text-slate-400">绑定数据池/数据源</div>
                                                        <div className="mt-1 text-slate-700">{selectedTask?.datasource_pool_name || selectedTask?.datasource_name || '-'}</div>
                                                    </div>
                                                    <div className={detailItemClass}>
                                                        <div className="text-xs text-slate-400">实际执行数据源</div>
                                                        <div className="mt-1 text-slate-700">{selectedInstance.execute_datasource_name || selectedInstance.execute_datasource_id || '-'}</div>
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
                                            <div className={`${detailSectionHeaderClass} flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between`}>
                                                <div className="min-w-0">
                                                    <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                                                        <Activity size={16} className="text-red-500" />
                                                        后台执行日志
                                                    </div>
                                                    <div className="mt-1 text-xs text-slate-500">按当前实例展示后台执行记录与逐步日志内容。</div>
                                                </div>
                                                <div className="flex shrink-0 flex-wrap items-center gap-2">
                                                    <button
                                                        type="button"
                                                        onClick={() => copyText(allLogsText, '全部日志已复制')}
                                                        disabled={!hasLogExportText}
                                                        className="inline-flex h-8 items-center gap-1.5 rounded border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
                                                    >
                                                        <Copy size={14} />
                                                        复制全部
                                                    </button>
                                                    <button
                                                        type="button"
                                                        onClick={() => downloadText(allLogsText, buildLogFilename())}
                                                        disabled={!hasLogExportText}
                                                        className="inline-flex h-8 items-center gap-1.5 rounded border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-600 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-600 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
                                                    >
                                                        <Download size={14} />
                                                        下载全部
                                                    </button>
                                                </div>
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
                                                                            <button
                                                                                type="button"
                                                                                onClick={() => copyText(buildLogText(log), `日志 #${log.id} 已复制`)}
                                                                                className="inline-flex h-7 items-center gap-1 rounded border border-slate-200 bg-white px-2 font-semibold text-slate-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600"
                                                                            >
                                                                                <Copy size={13} />
                                                                                复制
                                                                            </button>
                                                                            <button
                                                                                type="button"
                                                                                onClick={() => downloadText(buildLogText(log), buildLogFilename(log))}
                                                                                className="inline-flex h-7 items-center gap-1 rounded border border-slate-200 bg-white px-2 font-semibold text-slate-600 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-600"
                                                                            >
                                                                                <Download size={13} />
                                                                                下载
                                                                            </button>
                                                                            <button
                                                                                type="button"
                                                                                onClick={() => handleExplainLogError(log)}
                                                                                disabled={explainingLogId !== null}
                                                                                className="inline-flex h-7 items-center gap-1 rounded border border-purple-200 bg-purple-50 px-2 font-semibold text-purple-700 transition hover:bg-purple-100 disabled:cursor-not-allowed disabled:opacity-60 disabled:hover:bg-purple-50"
                                                                            >
                                                                                <Sparkles size={13} />
                                                                                {explainingLogId === log.id ? '解释中...' : 'AI 解释'}
                                                                            </button>
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
                                                                                <div
                                                                                    ref={(element) => {
                                                                                        logScrollRefs.current.set(log.id, element);
                                                                                    }}
                                                                                    onScroll={(event) => {
                                                                                        shouldFollowLogTailRef.current = isLogScrolledToTail(event.currentTarget);
                                                                                    }}
                                                                                    className="max-h-[280px] overflow-auto p-3 font-mono text-xs text-slate-100"
                                                                                >
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
                                                                        {(logAiExplanations[log.id] || explainingLogId === log.id) && (
                                                                            <div className="rounded-xl border border-purple-100 bg-purple-50/70 p-3">
                                                                                <div className="flex items-center gap-2 text-xs font-semibold text-purple-700">
                                                                                    <Sparkles size={14} />
                                                                                    AI 报错解释
                                                                                </div>
                                                                                <div className="mt-2 whitespace-pre-wrap text-sm leading-6 text-slate-700">
                                                                                    {logAiExplanations[log.id] || '正在分析日志...'}
                                                                                </div>
                                                                            </div>
                                                                        )}
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
