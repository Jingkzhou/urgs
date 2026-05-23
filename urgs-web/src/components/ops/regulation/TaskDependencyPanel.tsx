import React, { useEffect, useMemo, useState } from 'react';
import { Checkbox } from 'antd';
import { Database, GitBranch, Search, ShieldCheck } from 'lucide-react';
import Pagination from '@/components/common/Pagination';
import { QuartzTask } from './mockData';

interface TaskDependencyPanelProps {
    taskList: QuartzTask[];
    editingTaskId?: number;
    selectedDependencyIds: string[];
    selectedControlDependencyIds: string[];
    dependencyTaskDetails?: QuartzTask[];
    systems: string[];
    taskTypes: readonly string[];
    onChangeSelectedDependencyIds: (ids: string[]) => void;
    onChangeSelectedControlDependencyIds: (ids: string[]) => void;
}

const statusMap: Record<number, { label: string; className: string }> = {
    0: { label: '正常', className: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
    1: { label: '暂停', className: 'bg-amber-50 text-amber-600 border-amber-200' },
};

const metaBadgeClass = 'inline-flex max-w-[140px] items-center rounded-lg border border-slate-200 bg-slate-50 px-2 py-1 text-[11px] leading-none text-slate-600';

const TaskDependencyPanel: React.FC<TaskDependencyPanelProps> = ({
    taskList,
    editingTaskId,
    selectedDependencyIds,
    selectedControlDependencyIds,
    dependencyTaskDetails = [],
    systems,
    taskTypes,
    onChangeSelectedDependencyIds,
    onChangeSelectedControlDependencyIds,
}) => {
    const [dependencyKeyword, setDependencyKeyword] = useState('');
    const [dependencySystemFilter, setDependencySystemFilter] = useState<string>('');
    const [dependencyTypeFilter, setDependencyTypeFilter] = useState<string>('');
    const [selectedDependencyKeyword, setSelectedDependencyKeyword] = useState('');
    const [leftCheckedIds, setLeftCheckedIds] = useState<string[]>([]);
    const [dataCheckedIds, setDataCheckedIds] = useState<string[]>([]);
    const [controlCheckedIds, setControlCheckedIds] = useState<string[]>([]);
    const [candidatePage, setCandidatePage] = useState(1);
    const [candidatePageSize, setCandidatePageSize] = useState(10);

    const availableDependencyTasks = useMemo(() => {
        return taskList.filter(task => task.id !== editingTaskId);
    }, [taskList, editingTaskId]);

    const filteredDependencyTasks = useMemo(() => {
        return availableDependencyTasks.filter(task => {
            const matchesKeyword = !dependencyKeyword || [
                task.task_name,
                task.task_system,
                task.theme,
                task.remark,
                String(task.id),
            ].some(value => value?.toLowerCase().includes(dependencyKeyword.toLowerCase()));
            const matchesSystem = dependencySystemFilter === '' || task.task_system === dependencySystemFilter;
            const matchesType = dependencyTypeFilter === '' || task.task_type === dependencyTypeFilter;
            return matchesKeyword && matchesSystem && matchesType;
        });
    }, [availableDependencyTasks, dependencyKeyword, dependencySystemFilter, dependencyTypeFilter]);

    const pagedCandidateDependencyTasks = useMemo(() => {
        const start = (candidatePage - 1) * candidatePageSize;
        return filteredDependencyTasks.slice(start, start + candidatePageSize);
    }, [filteredDependencyTasks, candidatePage, candidatePageSize]);

    const buildSelectedTasks = (ids: string[]) => {
        const dependencyTaskMap = new Map(dependencyTaskDetails.map(task => [String(task.id), task]));

        return ids.map(id => {
            const remoteTask = dependencyTaskMap.get(id);
            if (remoteTask) return remoteTask;

            const task = availableDependencyTasks.find(item => String(item.id) === id);
            if (task) return task;

            return {
                id: Number(id),
                task_name: `任务 ${id}`,
                task_status: 1 as 0 | 1,
                task_cron: '-',
                update_time: '',
                create_time: '',
                task_type: null,
                task_system: null,
                theme: null,
                datasource_id: null,
                datasource_name: null,
            } as QuartzTask;
        });
    };

    const selectedDataDependencyTasks = useMemo(
        () => buildSelectedTasks(selectedDependencyIds),
        [availableDependencyTasks, dependencyTaskDetails, selectedDependencyIds]
    );
    const selectedControlDependencyTasks = useMemo(
        () => buildSelectedTasks(selectedControlDependencyIds),
        [availableDependencyTasks, dependencyTaskDetails, selectedControlDependencyIds]
    );

    const filterSelectedTasks = (tasks: QuartzTask[]) => {
        const keywordValue = selectedDependencyKeyword.trim().toLowerCase();
        if (!keywordValue) return tasks;
        return tasks.filter(task => [
            task.task_name,
            task.task_system,
            task.theme,
            task.remark,
            String(task.id),
        ].some(value => (value || '').toLowerCase().includes(keywordValue)));
    };

    const filteredSelectedDataDependencyTasks = useMemo(
        () => filterSelectedTasks(selectedDataDependencyTasks),
        [selectedDependencyKeyword, selectedDataDependencyTasks]
    );
    const filteredSelectedControlDependencyTasks = useMemo(
        () => filterSelectedTasks(selectedControlDependencyTasks),
        [selectedDependencyKeyword, selectedControlDependencyTasks]
    );

    useEffect(() => {
        setCandidatePage(1);
    }, [dependencyKeyword, dependencySystemFilter, dependencyTypeFilter]);

    useEffect(() => {
        const maxPage = Math.max(1, Math.ceil(filteredDependencyTasks.length / candidatePageSize));
        if (candidatePage > maxPage) {
            setCandidatePage(maxPage);
        }
    }, [filteredDependencyTasks.length, candidatePage, candidatePageSize]);

    useEffect(() => {
        const availableIdSet = new Set(availableDependencyTasks.map(task => String(task.id)));
        setLeftCheckedIds(prev => prev.filter(id => availableIdSet.has(id)));
    }, [availableDependencyTasks]);

    useEffect(() => {
        const dataIdSet = new Set(filteredSelectedDataDependencyTasks.map(task => String(task.id)));
        setDataCheckedIds(prev => prev.filter(id => dataIdSet.has(id)));
    }, [filteredSelectedDataDependencyTasks]);

    useEffect(() => {
        const controlIdSet = new Set(filteredSelectedControlDependencyTasks.map(task => String(task.id)));
        setControlCheckedIds(prev => prev.filter(id => controlIdSet.has(id)));
    }, [filteredSelectedControlDependencyTasks]);

    const addCheckedDependencies = (target: 'DATA' | 'CONTROL') => {
        if (leftCheckedIds.length === 0) return;
        if (target === 'DATA') {
            onChangeSelectedDependencyIds(Array.from(new Set([...selectedDependencyIds, ...leftCheckedIds])));
        } else {
            onChangeSelectedControlDependencyIds(Array.from(new Set([...selectedControlDependencyIds, ...leftCheckedIds])));
        }
        setLeftCheckedIds([]);
    };

    const renderTaskOption = (
        task: QuartzTask,
        checked: boolean,
        highlightClass: string,
        onCheckedChange: (checked: boolean) => void,
        relationBadges?: React.ReactNode
    ) => {
        const mappedStatus = statusMap[task.task_status] || statusMap[0];

        return (
            <label
                key={task.id}
                className={`flex cursor-pointer items-start gap-3 px-4 py-4 transition-colors ${checked ? highlightClass : 'hover:bg-slate-50'}`}
            >
                <Checkbox
                    checked={checked}
                    onChange={(event) => onCheckedChange(event.target.checked)}
                    className="mt-0.5"
                />
                <div className="min-w-0 flex-1">
                    <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0 truncate text-sm font-semibold leading-6 text-slate-800" title={task.task_name}>
                            {task.task_name}
                        </div>
                        <span className={`shrink-0 rounded-full border px-2 py-1 text-[11px] font-semibold leading-none ${mappedStatus.className}`}>
                            {mappedStatus.label}
                        </span>
                    </div>

                    <div className="mt-2 flex flex-wrap items-center gap-1.5">
                        <span className={`${metaBadgeClass} max-w-none font-mono text-slate-500`}>
                            #{task.id}
                        </span>
                        <span className={metaBadgeClass} title={task.task_system || '-'}>
                            <span className="mr-1 text-slate-400">系统</span>
                            <span className="truncate">{task.task_system || '-'}</span>
                        </span>
                        <span className={metaBadgeClass} title={task.theme || '-'}>
                            <span className="mr-1 text-slate-400">主题</span>
                            <span className="truncate">{task.theme || '-'}</span>
                        </span>
                        <span className={metaBadgeClass} title={task.task_type || '-'}>
                            <span className="mr-1 text-slate-400">类型</span>
                            <span className="truncate">{task.task_type || '-'}</span>
                        </span>
                        {relationBadges}
                    </div>
                </div>
            </label>
        );
    };

    const renderSelectedSection = (
        title: string,
        description: string,
        tasks: QuartzTask[],
        selectedIds: string[],
        checkedIds: string[],
        highlightClass: string,
        onCheckedChange: React.Dispatch<React.SetStateAction<string[]>>,
        onChangeSelectedIds: (ids: string[]) => void,
        icon: React.ReactNode
    ) => (
        <section className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-50/40">
            <div className="border-b border-slate-200 bg-white px-4 py-3">
                <div className="flex items-center justify-between gap-3">
                    <div>
                        <div className="flex items-center gap-2 text-sm font-semibold text-slate-800">
                            {icon}
                            {title}
                        </div>
                        <div className="mt-1 text-xs text-slate-500">{description}</div>
                    </div>
                    <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                        {selectedIds.length} 项
                    </span>
                </div>
            </div>
            <div className="max-h-[250px] overflow-y-auto divide-y divide-slate-100">
                {tasks.length === 0 ? (
                    <div className="px-4 py-8 text-center text-xs text-slate-500">暂无依赖任务</div>
                ) : tasks.map(task => {
                    const taskId = String(task.id);
                    const checked = checkedIds.includes(taskId);
                    return renderTaskOption(
                        task,
                        checked,
                        highlightClass,
                        (nextChecked) => onCheckedChange(prev => (
                            nextChecked
                                ? Array.from(new Set([...prev, taskId]))
                                : prev.filter(id => id !== taskId)
                        ))
                    );
                })}
            </div>
            <div className="flex items-center justify-between gap-2 border-t border-slate-200 bg-white px-4 py-2">
                <button
                    type="button"
                    onClick={() => {
                        onChangeSelectedIds(selectedIds.filter(id => !checkedIds.includes(id)));
                        onCheckedChange([]);
                    }}
                    disabled={checkedIds.length === 0}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:text-slate-300"
                >
                    移除勾选
                </button>
                <button
                    type="button"
                    onClick={() => {
                        onChangeSelectedIds([]);
                        onCheckedChange([]);
                    }}
                    disabled={selectedIds.length === 0}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-500 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:text-slate-300"
                >
                    清空
                </button>
            </div>
        </section>
    );

    const selectedDataSet = useMemo(() => new Set(selectedDependencyIds), [selectedDependencyIds]);
    const selectedControlSet = useMemo(() => new Set(selectedControlDependencyIds), [selectedControlDependencyIds]);

    return (
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between gap-3">
                <div>
                    <div className="text-base font-semibold text-slate-900">依赖任务配置</div>
                    <div className="mt-1 text-xs text-slate-500">
                        数据依赖参与调度并用于重跑影响传播；控制依赖只参与调度放行，不进入数据重跑链路。
                    </div>
                </div>
                <div className="flex flex-wrap items-center justify-end gap-2">
                    <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
                        数据 {selectedDependencyIds.length} 项
                    </span>
                    <span className="rounded-full bg-violet-50 px-3 py-1 text-xs font-semibold text-violet-700">
                        控制 {selectedControlDependencyIds.length} 项
                    </span>
                </div>
            </div>

            <div className="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-[1fr_160px_1fr]">
                <div className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-50/40">
                    <div className="border-b border-slate-200 bg-white px-4 py-3">
                        <div className="flex items-center justify-between gap-2">
                            <div className="text-sm font-semibold text-slate-800">可选任务池</div>
                            <div className="flex items-center gap-2">
                                <span className="text-xs text-slate-500">已勾选 {leftCheckedIds.length} 项</span>
                                <button
                                    type="button"
                                    onClick={() => setLeftCheckedIds([])}
                                    disabled={leftCheckedIds.length === 0}
                                    className="text-xs font-semibold text-red-600 disabled:cursor-not-allowed disabled:text-slate-300"
                                >
                                    清空勾选
                                </button>
                            </div>
                        </div>
                        <div className="mt-2 grid grid-cols-1 gap-2">
                            <label className="relative">
                                <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                                <input
                                    value={dependencyKeyword}
                                    onChange={(event) => setDependencyKeyword(event.target.value)}
                                    placeholder="搜索名称 / 系统 / 主题 / ID"
                                    className="w-full rounded-lg border border-slate-200 bg-white py-2 pl-8 pr-3 text-xs text-slate-700 outline-none focus:border-red-300"
                                />
                            </label>
                            <div className="grid grid-cols-2 gap-2">
                                <select
                                    value={dependencySystemFilter}
                                    onChange={(event) => setDependencySystemFilter(event.target.value)}
                                    className="rounded-lg border border-slate-200 bg-white px-2 py-2 text-xs text-slate-700 outline-none focus:border-red-300"
                                >
                                    <option value="">全部系统</option>
                                    {systems.map(system => <option key={system} value={system}>{system}</option>)}
                                </select>
                                <select
                                    value={dependencyTypeFilter}
                                    onChange={(event) => setDependencyTypeFilter(event.target.value)}
                                    className="rounded-lg border border-slate-200 bg-white px-2 py-2 text-xs text-slate-700 outline-none focus:border-red-300"
                                >
                                    <option value="">全部类型</option>
                                    {taskTypes.map(type => <option key={type} value={type}>{type}</option>)}
                                </select>
                            </div>
                        </div>
                    </div>
                    <div className="max-h-[420px] overflow-y-auto divide-y divide-slate-100">
                        {filteredDependencyTasks.length === 0 ? (
                            <div className="px-4 py-10 text-center text-xs text-slate-500">暂无可添加任务</div>
                        ) : pagedCandidateDependencyTasks.map(task => {
                            const taskId = String(task.id);
                            const checked = leftCheckedIds.includes(taskId);
                            const badges = (
                                <>
                                    {selectedDataSet.has(taskId) && (
                                        <span className="rounded border border-blue-200 bg-blue-50 px-2 py-0.5 text-[11px] font-semibold text-blue-700">
                                            已是数据
                                        </span>
                                    )}
                                    {selectedControlSet.has(taskId) && (
                                        <span className="rounded border border-violet-200 bg-violet-50 px-2 py-0.5 text-[11px] font-semibold text-violet-700">
                                            已是控制
                                        </span>
                                    )}
                                </>
                            );
                            return renderTaskOption(
                                task,
                                checked,
                                'bg-red-50/70',
                                (nextChecked) => setLeftCheckedIds(prev => (
                                    nextChecked
                                        ? Array.from(new Set([...prev, taskId]))
                                        : prev.filter(id => id !== taskId)
                                )),
                                badges
                            );
                        })}
                    </div>
                    <div className="border-t border-slate-200 bg-white px-4 py-2">
                        <Pagination
                            current={candidatePage}
                            total={filteredDependencyTasks.length}
                            pageSize={candidatePageSize}
                            onChange={(page, pageSize) => {
                                setCandidatePage(page);
                                setCandidatePageSize(pageSize);
                            }}
                            showSizeChanger
                            pageSizeOptions={[10, 20, 50]}
                            className="py-2"
                        />
                    </div>
                </div>

                <div className="flex flex-col items-stretch justify-center gap-2">
                    <button
                        type="button"
                        onClick={() => addCheckedDependencies('DATA')}
                        disabled={leftCheckedIds.length === 0}
                        className="rounded-xl bg-blue-600 px-3 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:bg-slate-300"
                    >
                        添加为数据依赖
                    </button>
                    <button
                        type="button"
                        onClick={() => addCheckedDependencies('CONTROL')}
                        disabled={leftCheckedIds.length === 0}
                        className="rounded-xl bg-violet-600 px-3 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-violet-700 disabled:cursor-not-allowed disabled:bg-slate-300"
                    >
                        添加为控制依赖
                    </button>
                </div>

                <div className="space-y-4">
                    <label className="relative block">
                        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            value={selectedDependencyKeyword}
                            onChange={(event) => setSelectedDependencyKeyword(event.target.value)}
                            placeholder="搜索已添加依赖"
                            className="w-full rounded-lg border border-slate-200 bg-white py-2 pl-8 pr-3 text-xs text-slate-700 outline-none focus:border-red-300"
                        />
                    </label>
                    {renderSelectedSection(
                        '数据依赖',
                        '参与调度放行，并沿此关系传播重跑影响。',
                        filteredSelectedDataDependencyTasks,
                        selectedDependencyIds,
                        dataCheckedIds,
                        'bg-blue-50/70',
                        setDataCheckedIds,
                        onChangeSelectedDependencyIds,
                        <Database size={15} className="text-blue-500" />
                    )}
                    {renderSelectedSection(
                        '控制依赖',
                        '只参与调度放行，不参与数据重跑影响传播。',
                        filteredSelectedControlDependencyTasks,
                        selectedControlDependencyIds,
                        controlCheckedIds,
                        'bg-violet-50/70',
                        setControlCheckedIds,
                        onChangeSelectedControlDependencyIds,
                        <ShieldCheck size={15} className="text-violet-500" />
                    )}
                    <div className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-500">
                        <div className="flex items-center gap-1.5 font-semibold text-slate-600">
                            <GitBranch size={14} />
                            调度规则
                        </div>
                        <div className="mt-1">
                            正常调度会同时检查数据依赖和控制依赖；补偿重跑只沿数据依赖寻找需要重置的下游。
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default TaskDependencyPanel;
