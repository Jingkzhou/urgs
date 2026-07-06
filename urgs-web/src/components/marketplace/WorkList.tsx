import React, { useState, useEffect } from 'react';
import * as XLSX from 'xlsx';
import { Tooltip, Pagination } from 'antd';
import { listWorks, publishWork, cancelWork, batchDeleteWorks, updateTaskStatus, Work, WorkTask, getWorkTasks } from '../../api/marketplace';
import { BarChart3, CalendarDays, Download, Edit3, LayoutList, ListTodo, PauseCircle, Plus, Play, PlayCircle, Search, Trash2, Upload, XCircle } from 'lucide-react';
import CreateWorkDrawer from './CreateWorkDrawer';
import ImportWorkModal from './ImportWorkModal';
import WorkDetailDrawer from './WorkDetailDrawer';
import WorkStatistics from './WorkStatistics';
import { getTaskStageLabel, getTaskStatusLabel, getWorkStatusLabel } from './marketplaceLabels';
import { searchUsers, UserDTO } from '../../api/user';
import { MarketplaceTodoFocus } from './marketplaceTodoFocus';

interface WorkTaskSummary {
    taskCount: number;
}

const downloadCollapsedOutlineWorkbook = (
    workbook: XLSX.WorkBook,
    collapsedRowNumbers: number[],
    fileName: string
) => {
    const workbookData = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const archive = XLSX.CFB.read(new Uint8Array(workbookData), { type: 'buffer' });
    const sheetIndex = archive.FullPaths.findIndex((path: string) =>
        path.endsWith('xl/worksheets/sheet1.xml')
    );

    if (sheetIndex < 0) {
        throw new Error('未找到导出工作表');
    }

    const sheetFile = archive.FileIndex[sheetIndex];
    let sheetXml = new TextDecoder().decode(sheetFile.content);

    collapsedRowNumbers.forEach(rowNumber => {
        const rowPattern = new RegExp(`(<row\\b(?=[^>]*\\br="${rowNumber}"(?:\\s|>))[^>]*)(>)`);
        sheetXml = sheetXml.replace(rowPattern, '$1 collapsed="1"$2');
    });

    sheetFile.content = new TextEncoder().encode(sheetXml);
    sheetFile.size = sheetFile.content.length;

    const output = XLSX.CFB.write(archive, {
        fileType: 'zip',
        type: 'array',
        compression: true,
    });
    const blob = new Blob([output], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });
    const downloadUrl = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = downloadUrl;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(downloadUrl), 0);
};

interface WorkListProps {
    todoFocus?: MarketplaceTodoFocus | null;
}

interface WorkDetailFocus {
    taskId?: string;
    mode?: 'applications';
    key?: number;
}

const WorkList: React.FC<WorkListProps> = ({ todoFocus }) => {
    const [works, setWorks] = useState<Work[]>([]);
    const [taskSummaries, setTaskSummaries] = useState<Record<string, WorkTaskSummary>>({});
    const [workTasks, setWorkTasks] = useState<Record<string, WorkTask[]>>({});
    const [loading, setLoading] = useState(false);
    const [isDrawerOpen, setIsDrawerOpen] = useState(false);
    const [editingWorkId, setEditingWorkId] = useState<string | null>(null);
    const [isImportOpen, setIsImportOpen] = useState(false);
    const [selectedWorkId, setSelectedWorkId] = useState<string | null>(null);
    const [workDetailFocus, setWorkDetailFocus] = useState<WorkDetailFocus | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);
    const [selectedWorkIds, setSelectedWorkIds] = useState<string[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(20);
    const [total, setTotal] = useState(0);
    const [assigneeLabels, setAssigneeLabels] = useState<Record<string, string>>({});
    const [keyword, setKeyword] = useState('');
    const [queryKeyword, setQueryKeyword] = useState('');
    const [statusFilter, setStatusFilter] = useState('');
    const [deadlineRange, setDeadlineRange] = useState({ startDate: '', endDate: '' });
    const [activeView, setActiveView] = useState<'list' | 'statistics'>('list');

    const fetchWorks = async (page = currentPage, size = pageSize) => {
        setLoading(true);
        try {
            const res = await listWorks({
                current: page,
                size,
                keyword: queryKeyword || undefined,
                status: statusFilter || undefined,
                deadlineStart: deadlineRange.startDate ? `${deadlineRange.startDate}T00:00:00` : undefined,
                deadlineEnd: deadlineRange.endDate ? `${deadlineRange.endDate}T23:59:59` : undefined,
            });
            if (res?.records) {
                if (res.records.length === 0 && page > 1 && res.total > 0) {
                    const prevPage = page - 1;
                    setCurrentPage(prevPage);
                    await fetchWorks(prevPage, size);
                    return;
                }
                setWorks(res.records);
                setTotal(res.total || 0);
                const currentWorkIds = new Set(res.records.map((work: Work) => work.id));
                setSelectedWorkIds(prev => prev.filter(id => currentWorkIds.has(id)));
                const entries = await Promise.all(
                    res.records.map(async (work: Work) => {
                        const tasks = await getWorkTasks(work.id);
                        return [work.id, tasks || []] as const;
                    })
                );
                const taskMap = Object.fromEntries(entries);
                setWorkTasks(taskMap);
                setTaskSummaries(Object.fromEntries(entries.map(([workId, tasks]) => [workId, buildTaskSummary(tasks)])));
                await resolveAssigneeLabels(entries.flatMap(([, tasks]) => tasks));
            }
        } catch (error) {
            console.error('Failed to fetch works', error);
        } finally {
            setLoading(false);
        }
    };

    const buildTaskSummary = (tasks: WorkTask[]): WorkTaskSummary => {
        return {
            taskCount: tasks.filter(task => task.taskRole !== 'MAIN').length,
        };
    };

    const formatUserLabel = (user: UserDTO) => user.name;

    const resolveAssigneeLabels = async (tasks: WorkTask[]) => {
        const assigneeIds = Array.from(new Set(
            tasks
                .map(task => task.assigneeId)
                .filter((id): id is string => Boolean(id))
        ));
        if (assigneeIds.length === 0) {
            setAssigneeLabels({});
            return;
        }

        const entries = await Promise.all(assigneeIds.map(async (assigneeId) => {
            try {
                const users = await searchUsers(assigneeId);
                const matchedUser = users.find(user => user.id.toString() === assigneeId) || users[0];
                return [assigneeId, matchedUser ? formatUserLabel(matchedUser) : assigneeId] as const;
            } catch (error) {
                return [assigneeId, assigneeId] as const;
            }
        }));
        setAssigneeLabels(Object.fromEntries(entries));
    };

    useEffect(() => {
        fetchWorks(currentPage, pageSize);
    }, [currentPage, pageSize, queryKeyword, statusFilter, deadlineRange.startDate, deadlineRange.endDate]);

    useEffect(() => {
        if (!todoFocus || todoFocus.targetTab !== 'publish') return;

        setActiveView('list');
        setStatusFilter('');
        setDeadlineRange({ startDate: '', endDate: '' });
        setCurrentPage(1);

        if (todoFocus.targetWorkId) {
            setWorkDetailFocus({
                taskId: todoFocus.targetTaskId,
                mode: todoFocus.type === 'APPLICATION' ? 'applications' : undefined,
                key: todoFocus.sequence,
            });
            setSelectedWorkId(todoFocus.targetWorkId);
            setIsDetailOpen(true);
        }
    }, [todoFocus?.sequence]);

    const handleSearch = () => {
        const nextKeyword = keyword.trim();
        setCurrentPage(1);
        setQueryKeyword(nextKeyword);
        if (currentPage === 1 && nextKeyword === queryKeyword) {
            fetchWorks(1, pageSize);
        }
    };

    const handlePublish = async (id: string) => {
        if (!window.confirm("确认要发布该工作到市场吗？发布后不能撤回。")) return;
        try {
            await publishWork(id);
            alert("发布成功");
            fetchWorks(currentPage, pageSize);
        } catch (error) {
            alert("发布失败");
        }
    };

    const handleCancel = async (id: string) => {
        if (!window.confirm("确定要取消该工作吗？")) return;
        try {
            await cancelWork(id);
            alert("取消成功");
            fetchWorks(currentPage, pageSize);
        } catch (error) {
            alert("取消失败");
        }
    };

    const handleBatchDelete = async () => {
        if (selectedWorkIds.length === 0) return;
        const selectedWorks = works.filter(work => selectedWorkIds.includes(work.id));
        const selectedTaskCount = selectedWorks.reduce(
            (total, work) => total + (workTasks[work.id]?.length ?? 0),
            0
        );
        if (!window.confirm(`确定要删除选中的 ${selectedWorkIds.length} 个工作吗？将同时删除其下 ${selectedTaskCount} 个主/子任务。`)) return;
        try {
            await batchDeleteWorks(selectedWorkIds);
            alert("删除成功");
            setSelectedWorkIds([]);
            fetchWorks(currentPage, pageSize);
        } catch (error) {
            alert("删除失败");
        }
    };

    const normalizeTaskStatus = (status?: string) => status?.trim().toUpperCase();

    const isClosedTaskStatus = (status?: string) => {
        return ['COMPLETED', 'CANCELLED', 'WAITING_REVIEW'].includes(normalizeTaskStatus(status) || '');
    };

    const getWorkToggleTasks = (work: Work) => {
        const targetStatus = work.status === 'PAUSED' ? 'IN_PROGRESS' : 'PAUSED';
        return (workTasks[work.id] || []).filter(task => {
            const status = normalizeTaskStatus(task.status);
            if (!status || isClosedTaskStatus(status) || status === targetStatus) return false;
            return work.status === 'PAUSED' ? status === 'PAUSED' : true;
        });
    };

    const handleToggleWorkPaused = async (work: Work) => {
        const paused = work.status === 'PAUSED';
        const nextStatus = paused ? 'IN_PROGRESS' : 'PAUSED';
        const actionText = paused ? '继续' : '暂停';
        const targetTasks = getWorkToggleTasks(work);
        if (targetTasks.length === 0) {
            alert(`没有可${actionText}的任务`);
            return;
        }
        if (!window.confirm(`确定要${actionText}工作「${work.title}」下 ${targetTasks.length} 个任务吗？`)) return;
        try {
            await Promise.all(targetTasks.map(task => updateTaskStatus(task.id, nextStatus)));
            await fetchWorks(currentPage, pageSize);
        } catch (error) {
            alert(`${actionText}工作失败`);
        }
    };

    const toggleSelected = (workId: string) => {
        setSelectedWorkIds(prev => prev.includes(workId)
            ? prev.filter(id => id !== workId)
            : [...prev, workId]);
    };

    const toggleSelectAll = () => {
        if (selectedWorkIds.length === works.length) {
            setSelectedWorkIds([]);
            return;
        }
        setSelectedWorkIds(works.map(work => work.id));
    };

    const statusClass = (status?: string) => {
        if (status === 'COMPLETED') return 'bg-green-100 text-green-700';
        if (status === 'ACTIVE' || status === 'IN_PROGRESS' || status === 'READY') return 'bg-blue-100 text-blue-700';
        if (status === 'PAUSED') return 'bg-amber-100 text-amber-700';
        if (status === 'ACCEPTANCE' || status === 'WAITING_REVIEW') return 'bg-orange-100 text-orange-700';
        if (status === 'REWORK') return 'bg-red-100 text-red-700';
        if (status === 'DRAFT' || status === 'PUBLISHED') return 'bg-slate-100 text-slate-600';
        return 'bg-red-100 text-red-600';
    };

    const formatDateTime = (value?: string) => {
        return value ? new Date(value).toLocaleString() : '';
    };

    const formatDate = (value?: string) => {
        return value ? new Date(value).toLocaleDateString() : '';
    };

    const renderValue = (value?: string | number | boolean | null) => {
        if (value === null || value === undefined || value === '') return '-';
        if (typeof value === 'boolean') return value ? '是' : '否';
        return value;
    };

    const getPrimarySystemText = (work: Work) => {
        if (work.primarySystem === undefined) return '-';
        if (work.primarySystem) return '是';
        return work.primarySystemName ? `否 / ${work.primarySystemName}` : '否';
    };

    const isIssueTrackingTask = (task: WorkTask) => {
        const taskType = (task.taskType || '').trim();
        return taskType === '问题跟踪' || taskType === '问题追踪';
    };

    const getOrderedTasks = (workId: string) => {
        return [...(workTasks[workId] || [])].sort((a, b) => {
            if (a.taskRole === b.taskRole) return 0;
            return a.taskRole === 'MAIN' ? -1 : 1;
        });
    };

    const getMainTask = (workId: string) => {
        return (workTasks[workId] || []).find(task => task.taskRole === 'MAIN');
    };

    const renderAssignee = (assigneeId?: string) => {
        if (!assigneeId) return '-';
        return assigneeLabels[assigneeId] || assigneeId;
    };

    const renderWorkAssignees = (workId: string) => {
        const tasks = workTasks[workId] || [];
        const mainTask = tasks.find(task => task.taskRole === 'MAIN');
        const subAssigneeIds = Array.from(new Set(
            tasks
                .filter(task =>
                    task.taskRole !== 'MAIN'
                    && task.assigneeId
                    && task.assigneeId !== mainTask?.assigneeId
                )
                .map(task => task.assigneeId)
        ));

        return (
            <div className="flex flex-wrap items-center gap-1.5">
                <span className="inline-flex items-center rounded bg-red-50 px-2 py-0.5 text-xs font-bold text-red-600">
                    {renderAssignee(mainTask?.assigneeId)}
                </span>
                {subAssigneeIds.map(assigneeId => (
                    <span
                        key={assigneeId}
                        className="inline-flex items-center rounded bg-blue-50 px-2 py-0.5 text-xs font-bold text-blue-700"
                    >
                        {renderAssignee(assigneeId)}
                    </span>
                ))}
            </div>
        );
    };

    const exportWorks = () => {
        const rows: Record<string, string | number>[] = [];
        const outlineRows: XLSX.RowInfo[] = [{ hpt: 24 }];
        const collapsedRowNumbers: number[] = [];

        works.forEach(work => {
            const baseInfo = {
                工作名称: work.title,
                需求编号: work.requirementNumber || '',
                申请部门: work.applicationDepartment || '',
                申请人: work.applicantName || '',
                主任务负责人: renderAssignee(getMainTask(work.id)?.assigneeId),
                归属系统: work.owningSystem || '',
                项目类型: work.projectType || '',
                优先级: work.priority || '',
                截止日期: formatDate(work.deadline),
                创建时间: formatDateTime(work.createTime),
                '主系统/是否主系统': getPrimarySystemText(work),
            };

            rows.push({
                层级: '一级-工作',
                ...baseInfo,
                工作状态: getWorkStatusLabel(work.status),
                工作积分: work.totalPoints ?? 0,
                工作内容: work.description || '',
                任务角色: '',
                任务名称: '',
                任务状态: '',
                任务阶段: '',
                任务积分: '',
                任务截止日期: '',
                任务创建时间: '',
                风险报备: '',
                任务描述: '',
            });
            outlineRows.push({ level: 0, hpt: 22 });

            const orderedTasks = getOrderedTasks(work.id);
            if (orderedTasks.length > 0) {
                collapsedRowNumbers.push(rows.length + 1);
            }
            orderedTasks.forEach((task, index) => {
                rows.push({
                    层级: `${index === orderedTasks.length - 1 ? '└─' : '├─'} ${task.taskRole === 'MAIN' ? '主任务' : '子任务'}`,
                    ...baseInfo,
                    工作状态: getWorkStatusLabel(work.status),
                    工作积分: work.totalPoints ?? 0,
                    工作内容: work.description || '',
                    任务角色: task.taskRole === 'MAIN' ? '主任务' : '子任务',
                    任务名称: task.title,
                    任务状态: getTaskStatusLabel(task.status),
                    任务阶段: isIssueTrackingTask(task) ? '不适用' : getTaskStageLabel(task.currentStage),
                    任务积分: task.points ?? 0,
                    任务截止日期: formatDate(task.deadline),
                    任务创建时间: formatDateTime(task.createTime),
                    风险报备: task.stageRiskReported ? (task.stageRiskNote || '已报备') : '',
                    任务描述: task.description || '',
                });
                outlineRows.push({ level: 1, hidden: true });
            });
        });

        const worksheet = XLSX.utils.json_to_sheet(rows);
        worksheet['!rows'] = outlineRows;
        worksheet['!outline'] = { above: true };
        worksheet['!cols'] = [
            { wch: 12 },
            { wch: 28 },
            { wch: 16 },
            { wch: 16 },
            { wch: 12 },
            { wch: 18 },
            { wch: 12 },
            { wch: 10 },
            { wch: 20 },
            { wch: 20 },
            { wch: 18 },
            { wch: 12 },
            { wch: 12 },
            { wch: 30 },
            { wch: 12 },
            { wch: 28 },
            { wch: 12 },
            { wch: 14 },
            { wch: 10 },
            { wch: 20 },
            { wch: 20 },
            { wch: 24 },
            { wch: 40 },
        ];
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, '我发布的工作');
        downloadCollapsedOutlineWorkbook(
            workbook,
            collapsedRowNumbers,
            `我发布的工作_${new Date().toISOString().slice(0, 10)}.xlsx`
        );
    };

    return (
        <div className="relative flex h-full flex-col overflow-y-auto p-6">
            <div className="mb-5 flex flex-wrap items-start justify-between gap-4">
                <div>
                    <h2 className="text-xl font-bold text-slate-900">我发布的工作</h2>
                    <p className="mt-1 text-sm text-slate-500">
                        {activeView === 'list'
                            ? '统一查看工作信息、任务进度和风险记录'
                            : '汇总指定时间段的工作进展、任务现状和风险'}
                    </p>
                </div>
                {activeView === 'list' && (
                    <div className="flex flex-wrap items-center justify-end gap-2">
                    <div className="flex items-center overflow-hidden rounded-lg border border-slate-200 bg-white transition-colors focus-within:border-blue-400 focus-within:ring-2 focus-within:ring-blue-50">
                        <input
                            value={keyword}
                            onChange={event => setKeyword(event.target.value)}
                            onKeyDown={event => {
                                if (event.key === 'Enter') handleSearch();
                            }}
                            placeholder="名称、需求编号、部门、申请人、系统"
                            className="w-80 border-0 px-3 py-2 text-sm outline-none"
                        />
                        {queryKeyword && (
                            <button
                                type="button"
                                onClick={() => {
                                    setKeyword('');
                                    setCurrentPage(1);
                                    setQueryKeyword('');
                                }}
                                className="p-2 text-slate-400 hover:text-slate-700"
                                title="清空查询"
                            >
                                <XCircle size={16} />
                            </button>
                        )}
                        <button
                            type="button"
                            onClick={handleSearch}
                            className="border-l border-slate-200 p-2 text-slate-600 hover:bg-slate-50"
                            title="查询"
                        >
                            <Search size={17} />
                        </button>
                    </div>
                    {selectedWorkIds.length > 0 && (
                        <button
                            onClick={handleBatchDelete}
                            className="flex items-center gap-2 rounded-lg bg-red-600 px-3 py-2 text-sm font-bold text-white transition-colors hover:bg-red-500"
                        >
                            <Trash2 size={16} />批量删除({selectedWorkIds.length})
                        </button>
                    )}
                    <button
                        onClick={() => setIsImportOpen(true)}
                        className="flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-bold text-slate-700 transition-colors hover:bg-slate-50"
                    >
                        <Upload size={16} />导入
                    </button>
                    <button
                        onClick={exportWorks}
                        disabled={works.length === 0}
                        className="flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-bold text-slate-700 transition-colors hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        <Download size={16} />导出
                    </button>
                    <button
                        onClick={() => {
                            setEditingWorkId(null);
                            setIsDrawerOpen(true);
                        }}
                        className="flex items-center gap-2 rounded-lg bg-slate-900 px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-slate-800"
                    >
                        <Plus size={16} />新建工作
                    </button>
                    </div>
                )}
            </div>

            <div className="mb-4 flex items-center gap-1 border-b border-slate-200">
                <button
                    type="button"
                    onClick={() => setActiveView('list')}
                    className={`relative inline-flex items-center gap-2 px-4 py-2.5 text-sm font-bold transition-colors ${
                        activeView === 'list' ? 'text-blue-600' : 'text-slate-500 hover:text-slate-800'
                    }`}
                >
                    <LayoutList size={16} />
                    工作列表
                    {activeView === 'list' && <span className="absolute inset-x-2 bottom-0 h-0.5 rounded-full bg-blue-600" />}
                </button>
                <button
                    type="button"
                    onClick={() => setActiveView('statistics')}
                    className={`relative inline-flex items-center gap-2 px-4 py-2.5 text-sm font-bold transition-colors ${
                        activeView === 'statistics' ? 'text-blue-600' : 'text-slate-500 hover:text-slate-800'
                    }`}
                >
                    <BarChart3 size={16} />
                    工作统计
                    {activeView === 'statistics' && <span className="absolute inset-x-2 bottom-0 h-0.5 rounded-full bg-blue-600" />}
                </button>
            </div>

            {activeView === 'statistics' ? (
                <WorkStatistics />
            ) : (
                <>
                    <div className="mb-4 flex flex-wrap items-center gap-3 rounded-xl border border-slate-100 bg-slate-50 px-4 py-3">
                <span className="text-sm font-bold text-slate-700">工作筛选</span>
                <select
                    value={statusFilter}
                    onChange={event => {
                        setStatusFilter(event.target.value);
                        setCurrentPage(1);
                    }}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700 outline-none focus:border-blue-400"
                >
                    <option value="">全部状态</option>
                    <option value="DRAFT">草稿</option>
                    <option value="PUBLISHED">已发布</option>
                    <option value="ACTIVE">进行中</option>
                    <option value="PAUSED">已暂停</option>
                    <option value="ACCEPTANCE">待验收</option>
                    <option value="COMPLETED">已完成</option>
                    <option value="CANCELLED">已取消</option>
                </select>
                <span className="text-sm text-slate-500">截止日期</span>
                <input
                    type="date"
                    value={deadlineRange.startDate}
                    max={deadlineRange.endDate || undefined}
                    onChange={event => {
                        setDeadlineRange(prev => ({ ...prev, startDate: event.target.value }));
                        setCurrentPage(1);
                    }}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700"
                />
                <span className="text-sm text-slate-400">至</span>
                <input
                    type="date"
                    value={deadlineRange.endDate}
                    min={deadlineRange.startDate || undefined}
                    onChange={event => {
                        setDeadlineRange(prev => ({ ...prev, endDate: event.target.value }));
                        setCurrentPage(1);
                    }}
                    className="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700"
                />
                {(statusFilter || deadlineRange.startDate || deadlineRange.endDate) && (
                    <button
                        type="button"
                        onClick={() => {
                            setStatusFilter('');
                            setDeadlineRange({ startDate: '', endDate: '' });
                            setCurrentPage(1);
                        }}
                        className="rounded-lg px-3 py-1.5 text-sm font-bold text-blue-600 transition-colors hover:bg-blue-50"
                    >
                        清除筛选
                    </button>
                )}
                    </div>

                    <CreateWorkDrawer
                isOpen={isDrawerOpen}
                editWorkId={editingWorkId}
                onClose={() => {
                    setIsDrawerOpen(false);
                    setEditingWorkId(null);
                }}
                onSuccess={() => {
                    const targetPage = editingWorkId ? currentPage : 1;
                    setIsDrawerOpen(false);
                    setEditingWorkId(null);
                    setCurrentPage(targetPage);
                    fetchWorks(targetPage, pageSize);
                }}
                    />

                    <ImportWorkModal
                isOpen={isImportOpen}
                onClose={() => setIsImportOpen(false)}
                onSuccess={() => {
                    setIsImportOpen(false);
                    setCurrentPage(1);
                    fetchWorks(1, pageSize);
                }}
                    />

                    {loading ? (
                <div className="rounded-xl border border-slate-200 py-16 text-center text-sm text-slate-400">加载中...</div>
            ) : works.length === 0 ? (
                <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50 py-16 text-center text-sm text-slate-400">
                    暂无工作，可通过右上角新建或导入。
                </div>
            ) : (
                <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-sm">
                    <div className="min-w-[1170px]">
                        <div className="grid grid-cols-[72px_minmax(220px,1.5fr)_minmax(130px,.85fr)_minmax(150px,1fr)_minmax(140px,1fr)_104px_112px_160px] gap-3 border-b border-slate-200 bg-slate-50 px-4 py-2.5 text-xs font-bold text-slate-500">
                            <div className="flex items-center gap-2">
                                <input
                                    type="checkbox"
                                    checked={works.length > 0 && selectedWorkIds.length === works.length}
                                    onChange={toggleSelectAll}
                                    className="h-4 w-4 rounded border-slate-300"
                                    aria-label="全选工作"
                                />
                                <span>{selectedWorkIds.length || ''}</span>
                            </div>
                            <span>工作 / 需求编号</span>
                            <span>申请信息</span>
                            <span>执行人</span>
                            <span>系统 / 项目</span>
                            <span>优先级 / 状态</span>
                            <span>截止 / 任务</span>
                            <span>操作</span>
                        </div>
                        {works.map(work => (
                                <div key={work.id} className="group/work border-b border-slate-100 last:border-b-0">
                                    <div className="relative grid grid-cols-[72px_minmax(220px,1.5fr)_minmax(130px,.85fr)_minmax(150px,1fr)_minmax(140px,1fr)_104px_112px_160px] items-center gap-3 px-4 py-3.5 text-sm transition-all duration-200 hover:bg-white hover:shadow-[inset_3px_0_0_#60a5fa,0_8px_18px_rgba(15,23,42,0.06)]">
                                        <span className="pointer-events-none absolute inset-x-4 bottom-0 h-px bg-gradient-to-r from-transparent via-slate-100 to-transparent opacity-0 transition-opacity group-hover/work:opacity-100" />
                                        <div className="flex items-center gap-2">
                                            <input
                                                type="checkbox"
                                                checked={selectedWorkIds.includes(work.id)}
                                                onChange={() => toggleSelected(work.id)}
                                                className="h-4 w-4 rounded border-slate-300"
                                                aria-label={`选择工作 ${work.title}`}
                                            />
                                        </div>
                                        <Tooltip title={
                                            <div className="max-w-[420px] space-y-2 text-xs leading-5 text-slate-600">
                                                <div>
                                                    <div className="text-sm font-bold leading-6 text-slate-900">{work.title}</div>
                                                    <div className="mt-0.5 text-[11px] font-medium text-slate-400">需求编号：{renderValue(work.requirementNumber)}</div>
                                                </div>
                                                {work.description && (
                                                    <div className="border-t border-slate-100 pt-2">
                                                        <div className="mb-1 text-[11px] font-bold text-slate-400">工作描述</div>
                                                        <pre className="max-h-48 overflow-auto whitespace-pre-wrap rounded-md bg-slate-50 px-2.5 py-2 text-left text-xs leading-5 text-slate-700">{work.description}</pre>
                                                    </div>
                                                )}
                                            </div>
                                        } placement="rightTop" color="#ffffff" mouseEnterDelay={0.25} overlayInnerStyle={{ boxShadow: '0 14px 34px rgba(15, 23, 42, 0.16)', border: '1px solid #e2e8f0' }}>
                                            <div className="min-w-0">
                                                <button
                                                    onClick={() => {
                                                        setWorkDetailFocus(null);
                                                        setSelectedWorkId(work.id);
                                                        setIsDetailOpen(true);
                                                    }}
                                                    className="block max-w-full truncate text-left font-bold text-slate-900 transition-colors hover:text-red-600"
                                                >
                                                    {work.title}
                                                </button>
                                                <div className="mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs text-slate-400">
                                                    <span className="font-medium text-slate-500">{renderValue(work.requirementNumber)}</span>
                                                    <span>积分 {work.totalPoints ?? 0}</span>
                                                    <span>{formatDateTime(work.createTime)}</span>
                                                </div>
                                            </div>
                                        </Tooltip>
                                        <div className="min-w-0">
                                            <div className="truncate font-medium text-slate-700">{renderValue(work.applicationDepartment)}</div>
                                            <div className="mt-1 truncate text-xs text-slate-400">{renderValue(work.applicantName)}</div>
                                        </div>
                                        <div className="min-w-0">{renderWorkAssignees(work.id)}</div>
                                        <div className="min-w-0">
                                            <div className="truncate font-medium text-slate-700">{renderValue(work.owningSystem)}</div>
                                            <div className="mt-1 flex items-center gap-2 text-xs">
                                                <span className="truncate text-blue-700">{renderValue(work.projectType)}</span>
                                                <span className="text-slate-400">主系统 {getPrimarySystemText(work)}</span>
                                            </div>
                                        </div>
                                        <div className="space-y-1.5">
                                            <div className="font-bold text-red-500">{renderValue(work.priority)}</div>
                                            <span className={`inline-flex w-fit rounded px-2 py-0.5 text-xs font-bold ${statusClass(work.status)}`}>
                                                {getWorkStatusLabel(work.status)}
                                            </span>
                                        </div>
                                        <div className="space-y-1.5 text-xs">
                                            <div className="flex items-center gap-1.5 text-slate-600">
                                                <CalendarDays size={13} className="text-slate-400" />
                                                {renderValue(formatDate(work.deadline))}
                                            </div>
                                            <div className="flex items-center gap-1.5 text-slate-500">
                                                <ListTodo size={13} />
                                                {taskSummaries[work.id]?.taskCount ?? 0} 个子任务
                                            </div>
                                        </div>
                                        <div className="flex justify-end">
                                            <div className="inline-flex items-center gap-1 rounded-full border border-slate-200 bg-white/95 px-2 py-1 opacity-100 shadow-sm backdrop-blur transition-all duration-200 lg:translate-x-2 lg:opacity-0 lg:group-hover/work:translate-x-0 lg:group-hover/work:opacity-100 lg:group-focus-within/work:translate-x-0 lg:group-focus-within/work:opacity-100">
                                                <button
                                                    onClick={() => {
                                                        setEditingWorkId(work.id);
                                                        setIsDrawerOpen(true);
                                                    }}
                                                    className="inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-bold text-blue-600 transition-colors hover:bg-blue-50 hover:text-blue-800"
                                                    title="修改工作"
                                                >
                                                    <Edit3 size={13} />编辑
                                                </button>
                                                {work.status === 'DRAFT' && (
                                                <button
                                                    onClick={() => handlePublish(work.id)}
                                                    className="inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-bold text-green-600 transition-colors hover:bg-green-50 hover:text-green-800"
                                                    title="发布到市场"
                                                >
                                                    <Play size={13} />发布
                                                </button>
                                                )}
                                                {(work.status === 'DRAFT' || work.status === 'PUBLISHED') && (
                                                <button
                                                    onClick={() => handleCancel(work.id)}
                                                    className="inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-bold text-red-500 transition-colors hover:bg-red-50 hover:text-red-700"
                                                    title="取消工作"
                                                >
                                                    <XCircle size={13} />取消
                                                </button>
                                                )}
                                                {['ACTIVE', 'PAUSED'].includes(work.status) && (
                                                <button
                                                    onClick={() => handleToggleWorkPaused(work)}
                                                    className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-bold transition-colors ${
                                                        work.status === 'PAUSED'
                                                            ? 'text-green-600 hover:bg-green-50 hover:text-green-800'
                                                            : 'text-amber-600 hover:bg-amber-50 hover:text-amber-800'
                                                    }`}
                                                    title={work.status === 'PAUSED' ? '继续工作' : '暂停工作'}
                                                >
                                                    {work.status === 'PAUSED' ? <PlayCircle size={13} /> : <PauseCircle size={13} />}
                                                    {work.status === 'PAUSED' ? '继续' : '暂停'}
                                                </button>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                    </div>
                    <div className="flex items-center justify-between border-t border-slate-100 bg-white px-4 py-3">
                        <span className="text-xs text-slate-400">
                            当前页 {works.length} 个工作{selectedWorkIds.length > 0 ? `，已选择 ${selectedWorkIds.length} 个` : ''}
                        </span>
                        <Pagination
                            current={currentPage}
                            pageSize={pageSize}
                            total={total}
                            showSizeChanger
                            showTotal={(count) => `共 ${count} 个工作`}
                            onChange={(page, size) => {
                                setCurrentPage(page);
                                setPageSize(size);
                            }}
                        />
                    </div>
                </div>
                    )}
                </>
            )}

            <WorkDetailDrawer
                workId={selectedWorkId}
                isOpen={isDetailOpen}
                onClose={() => {
                    setIsDetailOpen(false);
                    setWorkDetailFocus(null);
                }}
                focusTaskId={workDetailFocus?.taskId}
                focusMode={workDetailFocus?.mode}
                focusKey={workDetailFocus?.key}
            />
        </div>
    );
};

export default WorkList;
