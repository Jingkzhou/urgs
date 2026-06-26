import React from 'react';
import { Tag, Tooltip } from 'antd';
import { AlertTriangle, CheckCircle2, Eye, MoreHorizontal, Play, RefreshCw, RotateCcw, Search, Square } from 'lucide-react';
import Pagination from '@/components/common/Pagination';
import { QuartzTask, QuartzTaskStatus } from '../mockData';
import {
    batchActionClass,
    contextMenuItemClass,
    instanceStatusMap,
} from './constants';
import { RowContextMenuState, TaskInstanceStats } from './types';
import ExecutorPoolStatsPanel from './ExecutorPoolStatsPanel';
import type { ExecutorPoolStatsState } from './useExecutorPoolStats';

interface TaskInstanceTableViewProps {
    totalInstances: number;
    pagedInstances: QuartzTaskStatus[];
    selectedInstances: QuartzTaskStatus[];
    summaryStats: TaskInstanceStats;
    headerExtra?: React.ReactNode;
    executorPoolStatsState: ExecutorPoolStatsState;
    taskMap: Map<number, QuartzTask>;
    taskNameMap: Map<number, string>;
    taskSystemOptions: string[];
    searchKeyword: string;
    taskSystemFilter: string;
    themeFilter: string;
    remarkFilter: string;
    dataDateFilter: string;
    createDateFilter: string;
    statusFilter: string;
    selectedInstanceIds: number[];
    batchRerunExecuting: boolean;
    autoRefreshEnabled: boolean;
    allVisibleSelected: boolean;
    rowContextMenu: RowContextMenuState | null;
    rowContextMenuStyle?: React.CSSProperties;
    currentPage: number;
    pageSize: number;
    onSearchKeywordChange: (value: string) => void;
    onTaskSystemFilterChange: (value: string) => void;
    onThemeFilterChange: (value: string) => void;
    onRemarkFilterChange: (value: string) => void;
    onDataDateFilterChange: (value: string) => void;
    onCreateDateFilterChange: (value: string) => void;
    onStatusFilterChange: (value: string) => void;
    onSummaryStatusClick: (status: string) => void;
    onSearch: () => void;
    onResetFilters: () => void;
    onToggleSelectAllVisible: (checked: boolean) => void;
    onToggleSelectInstance: (instanceId: number, checked: boolean) => void;
    onBatchExecute: () => void;
    onBatchForceStop: () => void;
    onBatchForcePass: () => void;
    onAutoRefreshEnabledChange: (enabled: boolean) => void;
    onOpenMissedTasks: () => void;
    onClearSelectedInstances: () => void;
    onCloseRowContextMenu: () => void;
    onInvokeRowContextAction: (action: 'execute' | 'stop' | 'pass' | 'detail') => void;
    onOpenRowContextMenu: (instance: QuartzTaskStatus, event: React.MouseEvent<HTMLElement>) => void;
    onOpenInstanceDetail: (instance: QuartzTaskStatus) => void;
    onPageChange: (page: number, size: number) => void;
}

const TaskInstanceTableView: React.FC<TaskInstanceTableViewProps> = ({
    totalInstances,
    pagedInstances,
    selectedInstances,
    summaryStats,
    headerExtra,
    executorPoolStatsState,
    taskMap,
    taskNameMap,
    taskSystemOptions,
    searchKeyword,
    taskSystemFilter,
    themeFilter,
    remarkFilter,
    dataDateFilter,
    createDateFilter,
    statusFilter,
    selectedInstanceIds,
    batchRerunExecuting,
    autoRefreshEnabled,
    allVisibleSelected,
    rowContextMenu,
    rowContextMenuStyle,
    currentPage,
    pageSize,
    onSearchKeywordChange,
    onTaskSystemFilterChange,
    onThemeFilterChange,
    onRemarkFilterChange,
    onDataDateFilterChange,
    onCreateDateFilterChange,
    onStatusFilterChange,
    onSummaryStatusClick,
    onSearch,
    onResetFilters,
    onToggleSelectAllVisible,
    onToggleSelectInstance,
    onBatchExecute,
    onBatchForceStop,
    onBatchForcePass,
    onAutoRefreshEnabledChange,
    onOpenMissedTasks,
    onClearSelectedInstances,
    onCloseRowContextMenu,
    onInvokeRowContextAction,
    onOpenRowContextMenu,
    onOpenInstanceDetail,
    onPageChange,
}) => {
    const canBatchExecute = selectedInstances.length > 0 && selectedInstances.some(instance => instance.status === 3 || instance.status === 4);
    const canBatchForceStop = selectedInstances.length > 0 && selectedInstances.some(instance => instance.status === 1 || instance.status === 2);
    const canBatchForcePass = selectedInstances.length > 0 && selectedInstances.some(instance => instance.status === 4);
    const fieldClass = 'h-8 w-full rounded-lg border border-slate-200 bg-white px-3 text-sm text-slate-700 outline-none transition focus:border-red-300 focus:ring-2 focus:ring-red-100';
    const labelClass = 'space-y-1';
    const labelTextClass = 'text-[11px] font-medium text-slate-500';
    const compactHeaderCellClass = 'px-3 py-2.5 font-semibold whitespace-nowrap';
    const compactTableCellClass = 'px-3 py-2.5 align-middle';
    const compactMonoCellClass = `${compactTableCellClass} font-mono text-xs text-slate-600`;
    const statusPills = [
        {
            status: '',
            label: '全部',
            count: summaryStats.totalInstances,
            className: statusFilter === '' ? 'border-slate-300 bg-slate-100 text-slate-800' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50',
        },
        {
            status: '1',
            label: '等待',
            count: summaryStats.waitingInstances,
            className: statusFilter === '1' ? 'border-slate-300 bg-slate-100 text-slate-800' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50',
        },
        {
            status: '2',
            label: '执行中',
            count: summaryStats.runningInstances,
            className: statusFilter === '2' ? 'border-blue-200 bg-blue-50 text-blue-700' : 'border-blue-100 bg-white text-blue-600 hover:bg-blue-50',
        },
        {
            status: '3',
            label: '成功',
            count: summaryStats.successInstances,
            className: statusFilter === '3' ? 'border-emerald-200 bg-emerald-50 text-emerald-700' : 'border-emerald-100 bg-white text-emerald-600 hover:bg-emerald-50',
        },
        {
            status: '4',
            label: '失败',
            count: summaryStats.failedInstances,
            className: statusFilter === '4' ? 'border-red-200 bg-red-50 text-red-700' : 'border-red-100 bg-white text-red-600 hover:bg-red-50',
        },
    ];

    return (
        <div className="flex h-full min-h-0 flex-col gap-3">
            <div className="rounded-lg border border-slate-200 bg-white shadow-sm">
                <div className="flex flex-col gap-2 border-b border-slate-100 px-4 py-2.5 lg:flex-row lg:items-center lg:justify-between">
                    <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                        <div className="text-base font-bold text-slate-800">任务实例</div>
                        <div className="text-xs text-slate-500">点击行查看详情，右键或更多按钮打开实例操作。</div>
                    </div>
                    <div className="flex flex-wrap items-center gap-2">
                        {headerExtra}
                        <div className="flex flex-wrap items-center gap-1.5">
                            {statusPills.map(item => (
                                <button
                                    key={item.status || 'all'}
                                    type="button"
                                    onClick={() => onSummaryStatusClick(item.status)}
                                    className={`inline-flex h-8 items-center gap-1 rounded-lg border px-2.5 text-xs font-semibold transition-colors ${item.className}`}
                                >
                                    <span>{item.label}</span>
                                    <span className="font-mono">{item.count}</span>
                                </button>
                            ))}
                        </div>
                        <button
                            type="button"
                            onClick={() => onAutoRefreshEnabledChange(!autoRefreshEnabled)}
                            className={`inline-flex h-8 items-center gap-1.5 rounded-lg border px-2.5 text-xs font-semibold transition-colors ${
                                autoRefreshEnabled
                                    ? 'border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100'
                                    : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                            }`}
                        >
                            <RefreshCw size={13} />
                            实时刷新
                        </button>
                        <button
                            type="button"
                            onClick={onOpenMissedTasks}
                            className="inline-flex h-8 items-center gap-1.5 rounded-lg border border-amber-200 bg-amber-50 px-2.5 text-xs font-semibold text-amber-700 transition-colors hover:bg-amber-100"
                        >
                            <AlertTriangle size={13} />
                            未下发检查
                        </button>
                    </div>
                </div>

                <div className="overflow-x-auto px-4 py-2.5">
                    <div className="flex min-w-[1280px] items-end gap-2">
                        <label className={`${labelClass} w-[300px] shrink-0`}>
                            <div className={labelTextClass}>搜索条件</div>
                            <div className="relative">
                                <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                                <input
                                    value={searchKeyword}
                                    onChange={(event) => onSearchKeywordChange(event.target.value)}
                                    onKeyDown={(event) => {
                                        if (event.key === 'Enter') {
                                            onSearch();
                                        }
                                    }}
                                    placeholder="实例 / 计划 / 任务 / 消息"
                                    className={`${fieldClass} pl-9`}
                                />
                            </div>
                        </label>
                        <label className={`${labelClass} w-[180px] shrink-0`}>
                            <div className={labelTextClass}>系统主体</div>
                            <select
                                value={taskSystemFilter}
                                onChange={(event) => onTaskSystemFilterChange(event.target.value)}
                                className={fieldClass}
                            >
                                <option value="">全部系统</option>
                                {taskSystemOptions.map(item => (
                                    <option key={item} value={item}>
                                        {item}
                                    </option>
                                ))}
                            </select>
                        </label>
                        <label className={`${labelClass} w-[160px] shrink-0`}>
                            <div className={labelTextClass}>主题</div>
                            <input
                                value={themeFilter}
                                onChange={(event) => onThemeFilterChange(event.target.value)}
                                onKeyDown={(event) => {
                                    if (event.key === 'Enter') {
                                        onSearch();
                                    }
                                }}
                                placeholder="搜索主题"
                                className={fieldClass}
                            />
                        </label>
                        <label className={`${labelClass} w-[160px] shrink-0`}>
                            <div className={labelTextClass}>备注</div>
                            <input
                                value={remarkFilter}
                                onChange={(event) => onRemarkFilterChange(event.target.value)}
                                onKeyDown={(event) => {
                                    if (event.key === 'Enter') {
                                        onSearch();
                                    }
                                }}
                                placeholder="搜索备注"
                                className={fieldClass}
                            />
                        </label>
                        <label className={`${labelClass} w-[150px] shrink-0`}>
                            <div className={labelTextClass}>状态</div>
                            <select
                                value={statusFilter}
                                onChange={(event) => onStatusFilterChange(event.target.value)}
                                className={fieldClass}
                            >
                                <option value="">全部状态</option>
                                <option value="1">等待中</option>
                                <option value="2">执行中</option>
                                <option value="3">成功</option>
                                <option value="4">失败</option>
                            </select>
                        </label>
                        <label className={`${labelClass} w-[150px] shrink-0`}>
                            <div className={labelTextClass}>数据日期</div>
                            <input
                                type="date"
                                value={dataDateFilter}
                                onChange={(event) => onDataDateFilterChange(event.target.value)}
                                onKeyDown={(event) => {
                                    if (event.key === 'Enter') {
                                        onSearch();
                                    }
                                }}
                                className={fieldClass}
                            />
                        </label>
                        <label className={`${labelClass} w-[150px] shrink-0`}>
                            <div className={labelTextClass}>更新日期</div>
                            <input
                                type="date"
                                value={createDateFilter}
                                onChange={(event) => onCreateDateFilterChange(event.target.value)}
                                onKeyDown={(event) => {
                                    if (event.key === 'Enter') {
                                        onSearch();
                                    }
                                }}
                                className={fieldClass}
                            />
                        </label>
                        <div className={`${labelClass} w-[140px] shrink-0`}>
                            <div className={labelTextClass}>操作</div>
                            <div className="flex gap-1.5">
                                <button
                                    onClick={onSearch}
                                    className="inline-flex h-8 flex-1 items-center justify-center gap-1 rounded-lg bg-red-600 px-2 text-sm font-semibold text-white transition-colors hover:bg-red-700"
                                >
                                    <Search size={14} />
                                    查询
                                </button>
                                <button
                                    onClick={onResetFilters}
                                    className="inline-flex h-8 flex-1 items-center justify-center gap-1 rounded-lg border border-slate-200 bg-white px-2 text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-50"
                                >
                                    <RotateCcw size={14} />
                                    重置
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="flex flex-wrap items-center gap-x-3 gap-y-1 border-t border-slate-100 px-4 py-2">
                    <span className="shrink-0 text-xs font-semibold text-slate-600">执行器线程池指标</span>
                    <ExecutorPoolStatsPanel
                        state={executorPoolStatsState}
                        waitingInstances={summaryStats.waitingInstances}
                    />
                </div>

                {selectedInstanceIds.length > 0 && (
                    <div className="flex flex-col gap-3 border-t border-red-100 bg-red-50/60 px-4 py-3 lg:flex-row lg:items-center lg:justify-between">
                        <div className="text-sm font-medium text-slate-700">
                            已选择 <span className="font-bold text-red-600">{selectedInstanceIds.length}</span> 条实例
                        </div>
                        <div className="flex flex-wrap items-center gap-2">
                            <button
                                onClick={onBatchExecute}
                                disabled={!canBatchExecute || batchRerunExecuting}
                                className={`${batchActionClass} border-blue-200 bg-blue-50 text-blue-700 hover:bg-blue-100 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-blue-50`}
                            >
                                <Play size={14} />
                                {batchRerunExecuting ? '批量重跑中...' : '批量重跑当前节点'}
                            </button>
                            <button
                                onClick={onBatchForceStop}
                                disabled={!canBatchForceStop}
                                className={`${batchActionClass} border-amber-200 bg-amber-50 text-amber-700 hover:bg-amber-100 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-amber-50`}
                            >
                                <Square size={14} />
                                批量强制停止
                            </button>
                            <button
                                onClick={onBatchForcePass}
                                disabled={!canBatchForcePass}
                                className={`${batchActionClass} border-emerald-200 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-emerald-50`}
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
                            disabled={rowContextMenu.instance.status !== 3 && rowContextMenu.instance.status !== 4}
                            className={contextMenuItemClass}
                        >
                            <Play size={14} className="text-blue-600" />
                            重跑数据
                        </button>
                        <button
                            onClick={() => onInvokeRowContextAction('stop')}
                            disabled={rowContextMenu.instance.status !== 1 && rowContextMenu.instance.status !== 2}
                            className={contextMenuItemClass}
                        >
                            <Square size={14} className="text-amber-600" />
                            强制停止
                        </button>
                        <button
                            onClick={() => onInvokeRowContextAction('pass')}
                            disabled={rowContextMenu.instance.status !== 4}
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

            <div className="flex min-h-0 flex-1 flex-col overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
                <div className="flex flex-col gap-1.5 border-b border-slate-100 px-4 py-2.5 md:flex-row md:items-center md:justify-between">
                    <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
                        <div className="text-sm font-bold text-slate-800">实例列表</div>
                        <div className="text-xs text-slate-500">当前筛选 {totalInstances} 条，展示第 {currentPage} 页。</div>
                    </div>
                    <div className="text-xs text-slate-500">
                        {selectedInstanceIds.length > 0 ? `已选择 ${selectedInstanceIds.length} 条` : '可多选后批量重跑、停止或强制通过'}
                    </div>
                </div>
                <div className="min-h-0 flex-1 overflow-auto">
                    <table className="w-full min-w-[1516px] table-fixed text-left text-sm">
                        <colgroup>
                            <col style={{ width: 76 }} />
                            <col style={{ width: 84 }} />
                            <col style={{ width: 196 }} />
                            <col style={{ width: 128 }} />
                            <col style={{ width: 128 }} />
                            <col style={{ width: 104 }} />
                            <col style={{ width: 88 }} />
                            <col style={{ width: 140 }} />
                            <col style={{ width: 140 }} />
                            <col style={{ width: 140 }} />
                            <col style={{ width: 140 }} />
                            <col style={{ width: 252 }} />
                        </colgroup>
                        <thead className="sticky top-0 z-10 border-b border-slate-200 bg-slate-50 text-xs text-slate-500 shadow-[0_1px_0_rgba(226,232,240,0.9)]">
                            <tr>
                                <th className={compactHeaderCellClass}>
                                    <input
                                        type="checkbox"
                                        aria-label="选择当前页可见任务实例"
                                        checked={allVisibleSelected}
                                        onChange={(event) => onToggleSelectAllVisible(event.target.checked)}
                                        className="h-4 w-4 rounded border-slate-300 text-red-600 focus:ring-red-500"
                                    />
                                </th>
                                <th className={compactHeaderCellClass}>计划ID</th>
                                <th className={compactHeaderCellClass}>任务名称</th>
                                <th className={compactHeaderCellClass}>系统</th>
                                <th className={compactHeaderCellClass}>主题</th>
                                <th className={compactHeaderCellClass}>数据日期</th>
                                <th className={compactHeaderCellClass}>状态</th>
                                <th className={compactHeaderCellClass}>开始时间</th>
                                <th className={compactHeaderCellClass}>更新时间</th>
                                <th className={compactHeaderCellClass}>结束时间</th>
                                <th className={compactHeaderCellClass}>创建时间</th>
                                <th className={compactHeaderCellClass}>消息摘要</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {pagedInstances.length === 0 ? (
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
                                        className="h-12 cursor-pointer transition-colors hover:bg-red-50/30"
                                        title="点击整行查看详情"
                                    >
                                        <td className={compactTableCellClass}>
                                            <div className="flex items-center gap-2">
                                                <input
                                                    type="checkbox"
                                                    aria-label={`选择实例 #${instance.id}`}
                                                    checked={selectedInstanceIds.includes(instance.id)}
                                                    onClick={(event) => event.stopPropagation()}
                                                    onChange={(event) => {
                                                        event.stopPropagation();
                                                        onToggleSelectInstance(instance.id, event.target.checked);
                                                    }}
                                                    className="h-4 w-4 rounded border-slate-300 text-red-600 focus:ring-red-500"
                                                />
                                                <button
                                                    type="button"
                                                    aria-label={`打开实例 #${instance.id} 操作菜单`}
                                                    onClick={(event) => {
                                                        event.stopPropagation();
                                                        onOpenRowContextMenu(instance, event);
                                                    }}
                                                    className="inline-flex h-7 w-7 items-center justify-center rounded-md text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-700 focus:outline-none focus:ring-2 focus:ring-red-200"
                                                >
                                                    <MoreHorizontal size={15} />
                                                </button>
                                            </div>
                                        </td>
                                        <td className={compactMonoCellClass}>
                                            <div className="truncate">{instance.plan_id}</div>
                                        </td>
                                        <td className={compactTableCellClass}>
                                            <Tooltip placement="topLeft" title={taskName}>
                                                <div className="truncate font-semibold text-slate-800">
                                                    {taskName}
                                                </div>
                                            </Tooltip>
                                        </td>
                                        <td className={compactTableCellClass}>
                                            <Tooltip placement="topLeft" title={task?.task_system || '-'}>
                                                <div className="truncate text-slate-700">
                                                    {task?.task_system || '-'}
                                                </div>
                                            </Tooltip>
                                        </td>
                                        <td className={compactTableCellClass}>
                                            <Tooltip placement="topLeft" title={task?.theme || '-'}>
                                                <div className="truncate text-slate-700">
                                                    {task?.theme || '-'}
                                                </div>
                                            </Tooltip>
                                        </td>
                                        <td className={compactMonoCellClass}>
                                            <div className="truncate">{instance.data_date}</div>
                                        </td>
                                        <td className={compactTableCellClass}>
                                            {mappedStatus ? (
                                                <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold leading-none ${mappedStatus.className}`}>
                                                    {mappedStatus.label}
                                                </span>
                                            ) : (
                                                <Tag className="m-0">{instance.status ?? '-'}</Tag>
                                            )}
                                        </td>
                                        <td className={`${compactMonoCellClass} text-slate-500`}>
                                            <div className="truncate">{instance.begin_time || '-'}</div>
                                        </td>
                                        <td className={`${compactMonoCellClass} text-slate-500`}>
                                            <div className="truncate">{instance.update_time || '-'}</div>
                                        </td>
                                        <td className={`${compactMonoCellClass} text-slate-500`}>
                                            <div className="truncate">{instance.end_time || '-'}</div>
                                        </td>
                                        <td className={`${compactMonoCellClass} text-slate-500`}>
                                            <div className="truncate">{instance.create_time}</div>
                                        </td>
                                        <td className={`${compactTableCellClass} text-slate-600`}>
                                            <Tooltip placement="topLeft" title={instance.msg || '-'}>
                                                <div className="truncate">
                                                    {instance.msg || '-'}
                                                </div>
                                            </Tooltip>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
                <div className="border-t border-slate-100 px-4 py-3">
                    <Pagination
                        current={currentPage}
                        total={totalInstances}
                        pageSize={pageSize}
                        showSizeChanger
                        onChange={onPageChange}
                    />
                </div>
            </div>
        </div>
    );
};

export default TaskInstanceTableView;
