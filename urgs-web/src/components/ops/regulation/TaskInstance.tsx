import React, { useMemo, useState } from 'react';
import { Drawer, Tag } from 'antd';
import { AlertCircle, CalendarRange, Clock3, Eye, Search } from 'lucide-react';
import dayjs from 'dayjs';
import { QuartzTask, QuartzTaskStatus } from './mockData';

interface TaskInstanceProps {
    tasks: QuartzTask[];
    instances: QuartzTaskStatus[];
}

const statusMap: Record<number, { label: string; className: string; color: string }> = {
    0: { label: '等待中', className: 'bg-slate-100 text-slate-600 border-slate-200', color: 'default' },
    1: { label: '运行中', className: 'bg-blue-50 text-blue-600 border-blue-200', color: 'processing' },
    2: { label: '成功', className: 'bg-emerald-50 text-emerald-600 border-emerald-200', color: 'success' },
    3: { label: '失败', className: 'bg-red-50 text-red-600 border-red-200', color: 'error' },
};

const detailItemClass = 'rounded-xl border border-slate-200 bg-slate-50/70 px-4 py-3';

const TaskInstance: React.FC<TaskInstanceProps> = ({ tasks, instances }) => {
    const [planIdKeyword, setPlanIdKeyword] = useState('');
    const [dataDateFilter, setDataDateFilter] = useState('');
    const [createDateFilter, setCreateDateFilter] = useState('');
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [selectedInstance, setSelectedInstance] = useState<QuartzTaskStatus | null>(null);

    const taskNameMap = useMemo(
        () => new Map(tasks.map(task => [task.id, task.task_name])),
        [tasks]
    );

    const filteredInstances = useMemo(() => {
        return instances.filter(instance => {
            const matchesPlanId = !planIdKeyword || String(instance.plan_id).includes(planIdKeyword.trim());
            const matchesDataDate = !dataDateFilter || instance.data_date === dataDateFilter;
            const matchesCreateDate = !createDateFilter || instance.create_date === createDateFilter.replaceAll('-', '');
            const matchesStatus = statusFilter === '' || String(instance.status ?? '') === statusFilter;

            return matchesPlanId && matchesDataDate && matchesCreateDate && matchesStatus;
        });
    }, [createDateFilter, dataDateFilter, instances, planIdKeyword, statusFilter]);

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
                                运行中 {filteredInstances.filter(instance => instance.status === 1).length}
                            </span>
                            <span className="inline-flex items-center gap-1 rounded-full bg-red-50 px-3 py-1.5 text-red-700">
                                失败 {filteredInstances.filter(instance => instance.status === 3).length}
                            </span>
                        </div>
                    </div>

                    <div className="mt-5 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-3">
                        <label className="relative">
                            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                            <input
                                value={planIdKeyword}
                                onChange={(event) => setPlanIdKeyword(event.target.value)}
                                placeholder="搜索计划 ID"
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </label>
                        <input
                            type="date"
                            value={dataDateFilter}
                            onChange={(event) => setDataDateFilter(event.target.value)}
                            className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                        />
                        <input
                            type="date"
                            value={createDateFilter}
                            onChange={(event) => setCreateDateFilter(event.target.value)}
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
                        <table className="w-full min-w-[1280px] text-sm text-left">
                            <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500 border-b border-slate-200">
                                <tr>
                                    <th className="px-4 py-3 font-semibold">实例ID</th>
                                    <th className="px-4 py-3 font-semibold">计划ID</th>
                                    <th className="px-4 py-3 font-semibold">任务名称</th>
                                    <th className="px-4 py-3 font-semibold">数据日期</th>
                                    <th className="px-4 py-3 font-semibold">状态</th>
                                    <th className="px-4 py-3 font-semibold">开始时间</th>
                                    <th className="px-4 py-3 font-semibold">更新时间</th>
                                    <th className="px-4 py-3 font-semibold">结束时间</th>
                                    <th className="px-4 py-3 font-semibold">创建时间</th>
                                    <th className="px-4 py-3 font-semibold">创建批次</th>
                                    <th className="px-4 py-3 font-semibold">消息摘要</th>
                                    <th className="px-4 py-3 font-semibold text-right">操作</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {filteredInstances.length === 0 ? (
                                    <tr>
                                        <td colSpan={12} className="px-6 py-16 text-center text-slate-500">
                                            未找到符合条件的任务实例。
                                        </td>
                                    </tr>
                                ) : filteredInstances.map(instance => {
                                    const mappedStatus = statusMap[instance.status ?? -1];
                                    const taskName = taskNameMap.get(instance.plan_id) || '-';

                                    return (
                                        <tr key={instance.id} className="hover:bg-red-50/30 transition-colors">
                                            <td className="px-4 py-4 font-mono text-xs text-slate-600">{instance.id}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-600">{instance.plan_id}</td>
                                            <td className="px-4 py-4">
                                                <div className="font-semibold text-slate-800">{taskName}</div>
                                            </td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-600">{instance.data_date}</td>
                                            <td className="px-4 py-4">
                                                {mappedStatus ? (
                                                    <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${mappedStatus.className}`}>
                                                        {mappedStatus.label}
                                                    </span>
                                                ) : (
                                                    <Tag className="m-0">{instance.status ?? '-'}</Tag>
                                                )}
                                            </td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-500">{instance.begin_time || '-'}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-500">{instance.update_time || '-'}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-500">{instance.end_time || '-'}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-500">{instance.create_time}</td>
                                            <td className="px-4 py-4 font-mono text-xs text-slate-500">{instance.create_date}</td>
                                            <td className="px-4 py-4 text-slate-600">
                                                <div className="max-w-[280px] truncate" title={instance.msg || '-'}>
                                                    {instance.msg || '-'}
                                                </div>
                                            </td>
                                            <td className="px-4 py-4 text-right">
                                                <button
                                                    onClick={() => setSelectedInstance(instance)}
                                                    className="inline-flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 transition hover:border-red-200 hover:bg-red-50 hover:text-red-600"
                                                >
                                                    <Eye size={14} />
                                                    查看详情
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
                title={selectedInstance ? `实例详情 · #${selectedInstance.id}` : '实例详情'}
                placement="right"
                width={620}
                onClose={() => setSelectedInstance(null)}
                open={!!selectedInstance}
            >
                {selectedInstance && (
                    <div className="space-y-5">
                        <div className="grid grid-cols-2 gap-3">
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">计划ID</div>
                                <div className="mt-1 font-semibold text-slate-800">{selectedInstance.plan_id}</div>
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">任务名称</div>
                                <div className="mt-1 text-slate-700">{taskNameMap.get(selectedInstance.plan_id) || '-'}</div>
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">数据日期</div>
                                <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.data_date}</div>
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">当前状态</div>
                                <div className="mt-1">
                                    {statusMap[selectedInstance.status ?? -1] ? (
                                        <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${statusMap[selectedInstance.status ?? -1].className}`}>
                                            {statusMap[selectedInstance.status ?? -1].label}
                                        </span>
                                    ) : (
                                        <Tag className="m-0">{selectedInstance.status ?? '-'}</Tag>
                                    )}
                                </div>
                            </div>
                        </div>

                        <section>
                            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-800">
                                <Clock3 size={16} className="text-blue-500" />
                                执行时间线
                            </div>
                            <div className="space-y-3">
                                <div className={detailItemClass}>
                                    <div className="flex items-center justify-between text-sm">
                                        <span className="text-slate-500">创建时间</span>
                                        <span className="font-mono text-xs text-slate-700">
                                            {dayjs(selectedInstance.create_time).format('YYYY-MM-DD HH:mm:ss')}
                                        </span>
                                    </div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="flex items-center justify-between text-sm">
                                        <span className="text-slate-500">开始时间</span>
                                        <span className="font-mono text-xs text-slate-700">{selectedInstance.begin_time || '-'}</span>
                                    </div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="flex items-center justify-between text-sm">
                                        <span className="text-slate-500">更新时间</span>
                                        <span className="font-mono text-xs text-slate-700">{selectedInstance.update_time || '-'}</span>
                                    </div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="flex items-center justify-between text-sm">
                                        <span className="text-slate-500">结束时间</span>
                                        <span className="font-mono text-xs text-slate-700">{selectedInstance.end_time || '-'}</span>
                                    </div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="flex items-center justify-between text-sm">
                                        <span className="text-slate-500">创建批次</span>
                                        <span className="font-mono text-xs text-slate-700">{selectedInstance.create_date}</span>
                                    </div>
                                </div>
                            </div>
                        </section>

                        <section>
                            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-800">
                                <AlertCircle size={16} className="text-red-500" />
                                执行消息
                            </div>
                            <div className={detailItemClass}>
                                <div className="text-xs text-slate-400">消息内容</div>
                                <div className="mt-1 whitespace-pre-wrap text-slate-700">{selectedInstance.msg || '无消息'}</div>
                            </div>
                        </section>

                        <section>
                            <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-800">
                                <CalendarRange size={16} className="text-emerald-500" />
                                实例标识
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">实例ID</div>
                                    <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.id}</div>
                                </div>
                                <div className={detailItemClass}>
                                    <div className="text-xs text-slate-400">计划ID</div>
                                    <div className="mt-1 font-mono text-xs text-slate-700">{selectedInstance.plan_id}</div>
                                </div>
                            </div>
                        </section>
                    </div>
                )}
            </Drawer>
        </>
    );
};

export default TaskInstance;
