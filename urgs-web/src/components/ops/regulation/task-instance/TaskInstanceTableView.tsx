import React from 'react';
import { Tag } from 'antd';
import { CheckCircle2, Eye, Play, Search, Square } from 'lucide-react';
import Pagination from '@/components/common/Pagination';
import { QuartzTask, QuartzTaskStatus } from '../mockData';
import {
    batchActionClass,
    contextMenuItemClass,
    headerCellClass,
    instanceStatusMap,
    monoCellClass,
    tableCellClass,
} from './constants';
import { RowContextMenuState } from './types';

interface TaskInstanceTableViewProps {
    filteredInstances: QuartzTaskStatus[];
    pagedInstances: QuartzTaskStatus[];
    taskMap: Map<number, QuartzTask>;
    taskNameMap: Map<number, string>;
    taskSystemOptions: string[];
    searchKeyword: string;
    taskSystemFilter: string;
    dataDateFilter: string;
    createDateFilter: string;
    statusFilter: string;
    selectedInstanceIds: number[];
    allVisibleSelected: boolean;
    rowContextMenu: RowContextMenuState | null;
    rowContextMenuStyle?: React.CSSProperties;
    currentPage: number;
    pageSize: number;
    onSearchKeywordChange: (value: string) => void;
    onTaskSystemFilterChange: (value: string) => void;
    onDataDateFilterChange: (value: string) => void;
    onCreateDateFilterChange: (value: string) => void;
    onStatusFilterChange: (value: string) => void;
    onToggleSelectAllVisible: (checked: boolean) => void;
    onToggleSelectInstance: (instanceId: number, checked: boolean) => void;
    onBatchExecute: () => void;
    onBatchForceStop: () => void;
    onBatchForcePass: () => void;
    onClearSelectedInstances: () => void;
    onCloseRowContextMenu: () => void;
    onInvokeRowContextAction: (action: 'execute' | 'stop' | 'pass' | 'detail') => void;
    onOpenRowContextMenu: (instance: QuartzTaskStatus, event: React.MouseEvent<HTMLTableRowElement>) => void;
    onOpenInstanceDetail: (instance: QuartzTaskStatus) => void;
    onPageChange: (page: number, size: number) => void;
}

const TaskInstanceTableView: React.FC<TaskInstanceTableViewProps> = ({
    filteredInstances,
    pagedInstances,
    taskMap,
    taskNameMap,
    taskSystemOptions,
    searchKeyword,
    taskSystemFilter,
    dataDateFilter,
    createDateFilter,
    statusFilter,
    selectedInstanceIds,
    allVisibleSelected,
    rowContextMenu,
    rowContextMenuStyle,
    currentPage,
    pageSize,
    onSearchKeywordChange,
    onTaskSystemFilterChange,
    onDataDateFilterChange,
    onCreateDateFilterChange,
    onStatusFilterChange,
    onToggleSelectAllVisible,
    onToggleSelectInstance,
    onBatchExecute,
    onBatchForceStop,
    onBatchForcePass,
    onClearSelectedInstances,
    onCloseRowContextMenu,
    onInvokeRowContextAction,
    onOpenRowContextMenu,
    onOpenInstanceDetail,
    onPageChange,
}) => {
    return (
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
                                onChange={(event) => onSearchKeywordChange(event.target.value)}
                                placeholder="实例ID / 计划ID / 消息 / 主题 / 备注"
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                            />
                        </div>
                    </label>
                    <label className="space-y-1">
                        <div className="text-xs font-medium text-slate-500">系统主体</div>
                        <select
                            value={taskSystemFilter}
                            onChange={(event) => onTaskSystemFilterChange(event.target.value)}
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
                            onChange={(event) => onStatusFilterChange(event.target.value)}
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
                            onChange={(event) => onDataDateFilterChange(event.target.value)}
                            className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:bg-white"
                        />
                    </label>
                    <label className="space-y-1">
                        <div className="text-xs font-medium text-slate-500">创建日期</div>
                        <input
                            type="date"
                            value={createDateFilter}
                            onChange={(event) => onCreateDateFilterChange(event.target.value)}
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
                                onClick={onBatchExecute}
                                className={`${batchActionClass} border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100`}
                            >
                                <Play size={14} />
                                批量执行任务
                            </button>
                            <button
                                onClick={onBatchForceStop}
                                className={`${batchActionClass} border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100`}
                            >
                                <Square size={14} />
                                批量强制停止
                            </button>
                            <button
                                onClick={onBatchForcePass}
                                className={`${batchActionClass} border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100`}
                            >
                                <CheckCircle2 size={14} />
                                批量强制通过
                            </button>
                            <button
                                onClick={onClearSelectedInstances}
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
                        onClick={onCloseRowContextMenu}
                        onContextMenu={(event) => {
                            event.preventDefault();
                            onCloseRowContextMenu();
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
                            onClick={() => onInvokeRowContextAction('execute')}
                            disabled={rowContextMenu.instance.status === 2}
                            className={contextMenuItemClass}
                        >
                            <Play size={14} className="text-blue-600" />
                            执行任务
                        </button>
                        <button
                            onClick={() => onInvokeRowContextAction('stop')}
                            disabled={rowContextMenu.instance.status === 3 || rowContextMenu.instance.status === 4}
                            className={contextMenuItemClass}
                        >
                            <Square size={14} className="text-amber-600" />
                            强制停止
                        </button>
                        <button
                            onClick={() => onInvokeRowContextAction('pass')}
                            disabled={rowContextMenu.instance.status === 3}
                            className={contextMenuItemClass}
                        >
                            <CheckCircle2 size={14} className="text-emerald-600" />
                            强制通过
                        </button>
                        <button
                            onClick={() => onInvokeRowContextAction('detail')}
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
                                        onChange={(event) => onToggleSelectAllVisible(event.target.checked)}
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
                                        onClick={() => onOpenInstanceDetail(instance)}
                                        onContextMenu={(event) => onOpenRowContextMenu(instance, event)}
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
                                                    onToggleSelectInstance(instance.id, event.target.checked);
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
                    onChange={onPageChange}
                />
            </div>
        </div>
    );
};

export default TaskInstanceTableView;
