import React, { useEffect, useMemo, useState } from 'react';
import { Drawer } from 'antd';
import { Activity, ArrowLeft, Clock3, FileText, Search } from 'lucide-react';
import dayjs from 'dayjs';
import { QuartzTask, QuartzTaskExecutionLog } from './mockData';

interface TaskExecutionLogProps {
    tasks: QuartzTask[];
    logs: QuartzTaskExecutionLog[];
    initialTaskId?: number | null;
    initialTaskName?: string | null;
    lockTaskId?: number | null;
    lockTaskName?: string | null;
    embedded?: boolean;
    onBack?: () => void;
}

const statusMap: Record<number, { label: string; className: string }> = {
    0: { label: '等待中', className: 'bg-slate-100 text-slate-600 border-slate-200' },
    1: { label: '运行中', className: 'bg-blue-50 text-blue-600 border-blue-200' },
    2: { label: '成功', className: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
    3: { label: '失败', className: 'bg-red-50 text-red-600 border-red-200' },
};

const detailItemClass = 'rounded-xl border border-slate-200 bg-slate-50/70 px-4 py-3';

const formatDuration = (durationMs?: number | null) => {
    if (durationMs === undefined || durationMs === null) return '-';
    if (durationMs < 1000) return `${durationMs} ms`;
    const seconds = Math.floor(durationMs / 1000);
    if (seconds < 60) return `${seconds} 秒`;
    const minutes = Math.floor(seconds / 60);
    const remainSeconds = seconds % 60;
    return remainSeconds === 0 ? `${minutes} 分钟` : `${minutes} 分 ${remainSeconds} 秒`;
};

const TaskExecutionLog: React.FC<TaskExecutionLogProps> = ({
    tasks,
    logs,
    initialTaskId,
    initialTaskName,
    lockTaskId,
    lockTaskName,
    embedded = false,
    onBack,
}) => {
    const [taskFilter, setTaskFilter] = useState<string>(lockTaskId ? String(lockTaskId) : initialTaskId ? String(initialTaskId) : '');
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [dateFilter, setDateFilter] = useState('');
    const [keyword, setKeyword] = useState('');
    const [selectedLog, setSelectedLog] = useState<QuartzTaskExecutionLog | null>(null);
    const lockedTaskFilter = lockTaskId ? String(lockTaskId) : '';

    useEffect(() => {
        setTaskFilter(lockedTaskFilter || (initialTaskId ? String(initialTaskId) : ''));
    }, [initialTaskId, lockedTaskFilter]);

    const taskNameMap = useMemo(
        () => new Map(tasks.map(task => [task.id, task.task_name])),
        [tasks]
    );

    const currentTaskName = useMemo(() => {
        if (!taskFilter) return null;
        return taskNameMap.get(Number(taskFilter)) || lockTaskName || initialTaskName || `任务 ${taskFilter}`;
    }, [initialTaskName, lockTaskName, taskFilter, taskNameMap]);

    const filteredLogs = useMemo(() => {
        return logs.filter(log => {
            const matchesTask = taskFilter === '' || String(log.task_id) === taskFilter;
            const matchesStatus = statusFilter === '' || String(log.status) === statusFilter;
            const matchesDate = !dateFilter || log.data_date === dateFilter;
            const lowerKeyword = keyword.trim().toLowerCase();
            const matchesKeyword = !lowerKeyword || [
                taskNameMap.get(log.task_id),
                log.summary,
                log.content,
                log.trigger_type,
                log.instance_id ? String(log.instance_id) : '',
            ].some(value => value?.toLowerCase().includes(lowerKeyword));
            return matchesTask && matchesStatus && matchesDate && matchesKeyword;
        });
    }, [dateFilter, keyword, logs, statusFilter, taskFilter, taskNameMap]);

    return (
        <>
            <div className="space-y-4">
                <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-5">
                    <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                        <div>
                            <div className="flex items-center gap-3">
                                {onBack && !embedded && (
                                    <button
                                        onClick={onBack}
                                        className="inline-flex items-center gap-1 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600"
                                    >
                                        <ArrowLeft size={14} />
                                        返回任务管理
                                    </button>
                                )}
                                <div className="text-lg font-bold text-slate-800">执行日志</div>
                            </div>
                            <div className="text-sm text-slate-500 mt-1">
                                查看批量任务每次执行的记录摘要、耗时和完整日志文本。
                            </div>
                        </div>
                        <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500">
                            <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5">
                                日志 {filteredLogs.length}
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-3 py-1.5 text-emerald-700">
                                成功 {filteredLogs.filter(log => log.status === 2).length}
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-red-50 px-3 py-1.5 text-red-700">
                                失败 {filteredLogs.filter(log => log.status === 3).length}
                            </span>
                            {currentTaskName && !lockedTaskFilter && (
                                <button
                                    onClick={() => setTaskFilter('')}
                                    className="inline-flex items-center gap-1 rounded-full border border-red-200 bg-red-50 px-3 py-1.5 text-red-700 transition hover:bg-red-100"
                                >
                                    当前任务：{currentTaskName}
                                </button>
                            )}
                        </div>
                    </div>

                    <div className="mt-5 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3">
                        <label className="relative">
                            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                            <input
                                value={keyword}
                                onChange={(event) => setKeyword(event.target.value)}
                                placeholder="搜索任务名 / 实例ID / 日志内容"
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </label>
                        {lockedTaskFilter ? (
                            <div className="rounded-xl border border-red-100 bg-red-50 px-3 py-2.5 text-sm font-medium text-red-700">
                                当前任务：{currentTaskName}
                            </div>
                        ) : (
                            <select
                                value={taskFilter}
                                onChange={(event) => setTaskFilter(event.target.value)}
                                className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            >
                                <option value="">全部任务</option>
                                {tasks.map(task => (
                                    <option key={task.id} value={task.id}>{task.task_name}</option>
                                ))}
                            </select>
                        )}
                        <input
                            type="date"
                            value={dateFilter}
                            onChange={(event) => setDateFilter(event.target.value)}
                            className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                        />
                        <select
                            value={statusFilter}
                            onChange={(event) => setStatusFilter(event.target.value)}
                            className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                        >
                            <option value="">全部状态</option>
                            <option value="0">等待中</option>
                            <option value="1">运行中</option>
                            <option value="2">成功</option>
                            <option value="3">失败</option>
                        </select>
                    </div>
                </div>

                <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full min-w-[1320px] text-sm text-left">
                            <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500 border-b border-slate-200">
                                <tr>
                                    <th className="px-4 py-3 font-semibold">日志ID</th>
                                    <th className="px-4 py-3 font-semibold">任务名称</th>
                                    <th className="px-4 py-3 font-semibold">实例ID</th>
                                    <th className="px-4 py-3 font-semibold">数据日期</th>
                                    <th className="px-4 py-3 font-semibold">状态</th>
                                    <th className="px-4 py-3 font-semibold">触发方式</th>
                                    <th className="px-4 py-3 font-semibold">开始时间</th>
                                    <th className="px-4 py-3 font-semibold">结束时间</th>
                                    <th className="px-4 py-3 font-semibold">耗时</th>
                                    <th className="px-4 py-3 font-semibold">日志摘要</th>
                                    <th className="px-4 py-3 font-semibold text-right">操作</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {filteredLogs.length === 0 ? (
                                    <tr>
                                        <td colSpan={11} className="px-6 py-16 text-center text-slate-500">
                                            当前条件下没有执行日志记录。
                                        </td>
                                    </tr>
                                ) : filteredLogs.map(log => {
                                    const mappedStatus = statusMap[log.status];
                                    return (
                                        <tr key={log.id} className="hover:bg-red-50/30 transition-colors">
                                            <td className="px-4 py-4 font-mono text-xs text-slate-600">{log.id}</td>
                                            <td className="px-4 py-4">
                                                <div className="font-semibold text-slate-800">{taskNameMap.get(log.task_id) || initialTaskName || '-'}</div>
                                                <div className="mt-1 font-mono text-xs text-slate-400">#{log.task_id}</div>
                                            </td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-600">{log.instance_id ?? '-'}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-600">{log.data_date || '-'}</td>
                                            <td className="px-4 py-4">
                                                <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${mappedStatus.className}`}>
                                                    {mappedStatus.label}
                                                </span>
                                            </td>
                                            <td className="px-4 py-4 text-slate-600">{log.trigger_type}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-500">{log.begin_time || '-'}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-500">{log.end_time || '-'}</td>
                                            <td className="px-4 py-4 text-slate-600">{formatDuration(log.duration_ms)}</td>
                                            <td className="px-4 py-4 text-slate-600">
                                                <div className="max-w-[320px] truncate" title={log.summary || '-'}>
                                                    {log.summary || '-'}
                                                </div>
                                            </td>
                                            <td className="px-4 py-4 text-right">
                                                <button
                                                    onClick={() => setSelectedLog(log)}
                                                    className="inline-flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600"
                                                >
                                                    <FileText size={14} />
                                                    查看日志
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

            <Drawer
                title={selectedLog ? `执行日志 · #${selectedLog.id}` : '执行日志'}
                placement="right"
                size={700}
                onClose={() => setSelectedLog(null)}
                open={!!selectedLog}
            >
                {selectedLog && (
                    <div className="space-y-5">
                        <div className="grid grid-cols-2 gap-3">
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">任务名称</div>
                                <div className="mt-1 font-semibold text-slate-800">{taskNameMap.get(selectedLog.task_id) || initialTaskName || '-'}</div>
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">实例ID</div>
                                <div className="mt-1 font-mono text-xs text-slate-700">{selectedLog.instance_id ?? '-'}</div>
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">当前状态</div>
                                <div className="mt-1">
                                    <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${statusMap[selectedLog.status].className}`}>
                                        {statusMap[selectedLog.status].label}
                                    </span>
                                </div>
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">触发方式</div>
                                <div className="mt-1 text-slate-700">{selectedLog.trigger_type}</div>
                            </div>
                        </div>

                        <section>
                            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-800">
                                <Clock3 size={16} className="text-blue-500" />
                                执行概览
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">开始时间</div>
                                    <div className="mt-1 font-mono text-xs text-slate-700">{selectedLog.begin_time || '-'}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">结束时间</div>
                                    <div className="mt-1 font-mono text-xs text-slate-700">{selectedLog.end_time || '-'}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">耗时</div>
                                    <div className="mt-1 text-slate-700">{formatDuration(selectedLog.duration_ms)}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">数据日期</div>
                                    <div className="mt-1 font-mono text-xs text-slate-700">{selectedLog.data_date || '-'}</div>
                                </div>
                                <div className={`col-span-2 ${detailItemClass}`}>
                                    <div className="text-xs text-slate-400">摘要</div>
                                    <div className="mt-1 text-slate-700">{selectedLog.summary || '-'}</div>
                                </div>
                            </div>
                        </section>

                        <section>
                            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-800">
                                <Activity size={16} className="text-red-500" />
                                完整日志
                            </div>
                            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-950">
                                <div className="flex items-center justify-between border-b border-slate-800 px-4 py-3 text-xs text-slate-400">
                                    <span>创建时间</span>
                                    <span className="font-mono">{dayjs(selectedLog.create_time).format('YYYY-MM-DD HH:mm:ss')}</span>
                                </div>
                                <pre className="max-h-[420px] overflow-auto px-4 py-4 text-xs leading-6 text-slate-100 whitespace-pre-wrap">
                                    {selectedLog.content}
                                </pre>
                            </div>
                        </section>
                    </div>
                )}
            </Drawer>
        </>
    );
};

export default TaskExecutionLog;
