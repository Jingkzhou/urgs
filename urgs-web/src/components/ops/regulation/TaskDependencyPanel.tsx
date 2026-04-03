import React, { useEffect, useMemo, useState } from 'react';
import { Checkbox } from 'antd';
import { Search } from 'lucide-react';
import Pagination from '@/components/common/Pagination';
import { QuartzTask } from './mockData';

interface TaskDependencyPanelProps {
    taskList: QuartzTask[];
    editingTaskId?: number;
    selectedDependencyIds: string[];
    dependencyTaskDetails?: QuartzTask[];
    systems: string[];
    taskTypes: readonly string[];
    onChangeSelectedDependencyIds: (ids: string[]) => void;
}

const statusMap: Record<number, { label: string; className: string }> = {
    0: { label: '正常', className: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
    1: { label: '暂停', className: 'bg-amber-50 text-amber-600 border-amber-200' },
};

const TaskDependencyPanel: React.FC<TaskDependencyPanelProps> = ({
    taskList,
    editingTaskId,
    selectedDependencyIds,
    dependencyTaskDetails = [],
    systems,
    taskTypes,
    onChangeSelectedDependencyIds,
}) => {
    const [dependencyKeyword, setDependencyKeyword] = useState('');
    const [dependencySystemFilter, setDependencySystemFilter] = useState<string>('');
    const [dependencyTypeFilter, setDependencyTypeFilter] = useState<string>('');
    const [selectedDependencyKeyword, setSelectedDependencyKeyword] = useState('');
    const [leftCheckedIds, setLeftCheckedIds] = useState<string[]>([]);
    const [rightCheckedIds, setRightCheckedIds] = useState<string[]>([]);
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
            ].some(value => value?.toLowerCase().includes(dependencyKeyword.toLowerCase()));
            const matchesSystem = dependencySystemFilter === '' || task.task_system === dependencySystemFilter;
            const matchesType = dependencyTypeFilter === '' || task.task_type === dependencyTypeFilter;
            return matchesKeyword && matchesSystem && matchesType;
        });
    }, [availableDependencyTasks, dependencyKeyword, dependencySystemFilter, dependencyTypeFilter]);

    const candidateDependencyTasks = useMemo(() => {
        const selectedSet = new Set(selectedDependencyIds);
        return filteredDependencyTasks.filter(task => !selectedSet.has(String(task.id)));
    }, [filteredDependencyTasks, selectedDependencyIds]);

    const pagedCandidateDependencyTasks = useMemo(() => {
        const start = (candidatePage - 1) * candidatePageSize;
        return candidateDependencyTasks.slice(start, start + candidatePageSize);
    }, [candidateDependencyTasks, candidatePage, candidatePageSize]);

    const selectedDependencyTasks = useMemo(() => {
        const dependencyTaskMap = new Map(
            dependencyTaskDetails.map(task => [String(task.id), task])
        );

        return selectedDependencyIds.map(id => {
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
    }, [availableDependencyTasks, dependencyTaskDetails, selectedDependencyIds]);

    const filteredSelectedDependencyTasks = useMemo(() => {
        const keywordValue = selectedDependencyKeyword.trim().toLowerCase();
        if (!keywordValue) return selectedDependencyTasks;
        return selectedDependencyTasks.filter(task => [
            task.task_name,
            task.task_system,
            task.theme,
            task.remark,
            String(task.id),
        ].some(value => (value || '').toLowerCase().includes(keywordValue)));
    }, [selectedDependencyKeyword, selectedDependencyTasks]);

    useEffect(() => {
        setCandidatePage(1);
    }, [dependencyKeyword, dependencySystemFilter, dependencyTypeFilter]);

    useEffect(() => {
        const maxPage = Math.max(1, Math.ceil(candidateDependencyTasks.length / candidatePageSize));
        if (candidatePage > maxPage) {
            setCandidatePage(maxPage);
        }
    }, [candidateDependencyTasks.length, candidatePage, candidatePageSize]);

    useEffect(() => {
        const availableIdSet = new Set(availableDependencyTasks.map(task => String(task.id)));
        const selectedIdSet = new Set(selectedDependencyIds);
        setLeftCheckedIds(prev => prev.filter(id => availableIdSet.has(id) && !selectedIdSet.has(id)));
    }, [availableDependencyTasks, selectedDependencyIds]);

    useEffect(() => {
        const selectedIdSet = new Set(filteredSelectedDependencyTasks.map(task => String(task.id)));
        setRightCheckedIds(prev => prev.filter(id => selectedIdSet.has(id)));
    }, [filteredSelectedDependencyTasks]);

    const addCheckedDependencies = () => {
        if (leftCheckedIds.length === 0) return;
        onChangeSelectedDependencyIds(Array.from(new Set([...selectedDependencyIds, ...leftCheckedIds])));
        setLeftCheckedIds([]);
    };

    const removeCheckedDependencies = () => {
        if (rightCheckedIds.length === 0) return;
        onChangeSelectedDependencyIds(selectedDependencyIds.filter(id => !rightCheckedIds.includes(id)));
        setRightCheckedIds([]);
    };

    return (
        <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between gap-3">
                <div>
                    <div className="text-base font-semibold text-slate-900">依赖任务配置</div>
                    <div className="mt-1 text-xs text-slate-500">左侧勾选后添加到右侧，右侧勾选后移除依赖。</div>
                </div>
                <span className="rounded-full bg-red-50 px-3 py-1 text-xs font-semibold text-red-700">
                    已配置 {selectedDependencyIds.length} 项
                </span>
            </div>

            <div className="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-[1fr_130px_1fr]">
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
                                    placeholder="搜索名称 / 系统 / 主题"
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
                        {candidateDependencyTasks.length === 0 ? (
                            <div className="px-4 py-10 text-center text-xs text-slate-500">暂无可添加任务</div>
                        ) : pagedCandidateDependencyTasks.map(task => {
                            const taskId = String(task.id);
                            const checked = leftCheckedIds.includes(taskId);
                            const mappedStatus = statusMap[task.task_status] || statusMap[0];
                            return (
                                <label key={task.id} className={`flex cursor-pointer items-start gap-3 px-4 py-3 ${checked ? 'bg-red-50/60' : 'hover:bg-slate-50'}`}>
                                    <Checkbox checked={checked} onChange={(e) => setLeftCheckedIds(prev => e.target.checked ? Array.from(new Set([...prev, taskId])) : prev.filter(id => id !== taskId))} />
                                    <div className="min-w-0 flex-1">
                                        <div className="truncate text-sm font-semibold text-slate-800">{task.task_name}</div>
                                        <div className="mt-1 flex flex-wrap items-center gap-2 text-[11px] text-slate-500">
                                            <span className="font-mono">#{task.id}</span>
                                            <span>{task.task_system || '-'}</span>
                                            <span>{task.theme || '-'}</span>
                                            <span className={`rounded-full border px-1.5 py-0.5 ${mappedStatus.className}`}>{mappedStatus.label}</span>
                                        </div>
                                    </div>
                                </label>
                            );
                        })}
                    </div>
                    <div className="border-t border-slate-200 bg-white px-4 py-2">
                        <Pagination
                            current={candidatePage}
                            total={candidateDependencyTasks.length}
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
                        onClick={addCheckedDependencies}
                        disabled={leftCheckedIds.length === 0}
                        className="rounded-xl bg-red-600 px-3 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-red-700 disabled:cursor-not-allowed disabled:bg-slate-300"
                    >
                        添加到右侧 &gt;&gt;
                    </button>
                    <button
                        type="button"
                        onClick={removeCheckedDependencies}
                        disabled={rightCheckedIds.length === 0}
                        className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:text-slate-400"
                    >
                        &lt;&lt; 移除依赖
                    </button>
                    <button
                        type="button"
                        onClick={() => onChangeSelectedDependencyIds([])}
                        disabled={selectedDependencyIds.length === 0}
                        className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-500 transition hover:bg-slate-50 disabled:cursor-not-allowed"
                    >
                        清空依赖
                    </button>
                </div>

                <div className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-50/40">
                    <div className="border-b border-slate-200 bg-white px-4 py-3">
                        <div className="text-sm font-semibold text-slate-800">当前依赖列表</div>
                        <label className="relative mt-2 block">
                            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                            <input
                                value={selectedDependencyKeyword}
                                onChange={(event) => setSelectedDependencyKeyword(event.target.value)}
                                placeholder="搜索已添加依赖"
                                className="w-full rounded-lg border border-slate-200 bg-white py-2 pl-8 pr-3 text-xs text-slate-700 outline-none focus:border-red-300"
                            />
                        </label>
                    </div>
                    <div className="max-h-[420px] overflow-y-auto divide-y divide-slate-100">
                        {filteredSelectedDependencyTasks.length === 0 ? (
                            <div className="px-4 py-10 text-center text-xs text-slate-500">暂无依赖任务</div>
                        ) : filteredSelectedDependencyTasks.map(task => {
                            const taskId = String(task.id);
                            const checked = rightCheckedIds.includes(taskId);
                            const mappedStatus = statusMap[task.task_status] || statusMap[0];
                            return (
                                <label key={task.id} className={`flex cursor-pointer items-start gap-3 px-4 py-3 ${checked ? 'bg-blue-50/60' : 'hover:bg-slate-50'}`}>
                                    <Checkbox checked={checked} onChange={(e) => setRightCheckedIds(prev => e.target.checked ? Array.from(new Set([...prev, taskId])) : prev.filter(id => id !== taskId))} />
                                    <div className="min-w-0 flex-1">
                                        <div className="truncate text-sm font-semibold text-slate-800">{task.task_name}</div>
                                        <div className="mt-1 flex flex-wrap items-center gap-2 text-[11px] text-slate-500">
                                            <span className="font-mono">#{task.id}</span>
                                            <span>{task.task_system || '-'}</span>
                                            <span>{task.theme || '-'}</span>
                                            <span className={`rounded-full border px-1.5 py-0.5 ${mappedStatus.className}`}>{mappedStatus.label}</span>
                                        </div>
                                    </div>
                                </label>
                            );
                        })}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default TaskDependencyPanel;
