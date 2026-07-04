import React, { useState, useEffect } from 'react';
import * as XLSX from 'xlsx';
import { Modal, Pagination, Progress } from 'antd';
import { appendTaskRiskTracking, AssetMaintenanceRecord, listWorks, publishWork, cancelWork, batchDeleteWorks, reopenTask, updateTaskStatus, Work, WorkTask, getWorkTasks } from '../../api/marketplace';
import { BarChart3, CalendarDays, CheckCircle2, ChevronDown, ChevronRight, Circle, Clock3, Download, Edit3, LayoutList, ListTodo, PauseCircle, Plus, Play, PlayCircle, Search, Trash2, Upload, Users, XCircle } from 'lucide-react';
import CreateWorkDrawer from './CreateWorkDrawer';
import ImportWorkModal from './ImportWorkModal';
import WorkDetailDrawer from './WorkDetailDrawer';
import WorkStatistics from './WorkStatistics';
import { getTaskStageLabel, getTaskStatusLabel, getWorkStatusLabel } from './marketplaceLabels';
import { searchUsers, UserDTO } from '../../api/user';

interface WorkTaskSummary {
    taskCount: number;
}

interface WorkRiskEntry {
    taskId: string;
    taskTitle: string;
    stage?: string;
    reporter: string;
    reportedAt: string;
    content: string;
}

interface TaskAssetChange {
    task: WorkTask;
    record: AssetMaintenanceRecord;
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

const WorkList: React.FC = () => {
    const [works, setWorks] = useState<Work[]>([]);
    const [taskSummaries, setTaskSummaries] = useState<Record<string, WorkTaskSummary>>({});
    const [workTasks, setWorkTasks] = useState<Record<string, WorkTask[]>>({});
    const [expandedWorkIds, setExpandedWorkIds] = useState<Record<string, boolean>>({});
    const [loading, setLoading] = useState(false);
    const [isDrawerOpen, setIsDrawerOpen] = useState(false);
    const [editingWorkId, setEditingWorkId] = useState<string | null>(null);
    const [isImportOpen, setIsImportOpen] = useState(false);
    const [selectedWorkId, setSelectedWorkId] = useState<string | null>(null);
    const [isDetailOpen, setIsDetailOpen] = useState(false);
    const [selectedWorkIds, setSelectedWorkIds] = useState<string[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(20);
    const [total, setTotal] = useState(0);
    const [assigneeLabels, setAssigneeLabels] = useState<Record<string, string>>({});
    const [assetChangeTitle, setAssetChangeTitle] = useState('');
    const [assetChangeDetails, setAssetChangeDetails] = useState<TaskAssetChange[]>([]);
    const [trackingWorkId, setTrackingWorkId] = useState<string | null>(null);
    const [trackingTaskId, setTrackingTaskId] = useState('');
    const [trackingNote, setTrackingNote] = useState('');
    const [trackingSubmitting, setTrackingSubmitting] = useState(false);
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

    const isPausedTask = (task: WorkTask) => normalizeTaskStatus(task.status) === 'PAUSED';

    const isClosedTaskStatus = (status?: string) => {
        return ['COMPLETED', 'CANCELLED', 'WAITING_REVIEW'].includes(normalizeTaskStatus(status) || '');
    };

    const handleToggleTaskPaused = async (task: WorkTask) => {
        const paused = isPausedTask(task);
        const nextStatus = paused ? 'IN_PROGRESS' : 'PAUSED';
        const actionText = paused ? '继续' : '暂停';
        if (!window.confirm(`确定要${actionText}任务「${task.title}」吗？`)) return;
        try {
            await updateTaskStatus(task.id, nextStatus);
            await fetchWorks(currentPage, pageSize);
        } catch (error) {
            alert(`${actionText}任务失败`);
        }
    };

    const handleReopenTask = async (task: WorkTask) => {
        if (!window.confirm(`确定要重新开启任务「${task.title}」吗？`)) return;
        try {
            await reopenTask(task.id);
            await fetchWorks(currentPage, pageSize);
        } catch (error) {
            alert('重新开启任务失败，所属工作可能已取消');
        }
    };

    const toggleExpanded = (workId: string) => {
        setExpandedWorkIds(prev => ({ ...prev, [workId]: !prev[workId] }));
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

    const getTaskProgressSummary = (workId: string) => {
        const tasks = workTasks[workId] || [];
        const completedCount = tasks.filter(task => normalizeTaskStatus(task.status) === 'COMPLETED').length;
        const activeCount = tasks.filter(task =>
            ['IN_PROGRESS', 'WAITING_REVIEW', 'REWORK'].includes(normalizeTaskStatus(task.status) || '')
        ).length;
        const pausedCount = tasks.filter(task => normalizeTaskStatus(task.status) === 'PAUSED').length;
        const closedCount = tasks.filter(task =>
            normalizeTaskStatus(task.status) === 'CANCELLED'
        ).length;
        const pendingCount = Math.max(tasks.length - completedCount - activeCount - pausedCount - closedCount, 0);
        const progressBase = Math.max(tasks.length - closedCount, 0);

        return {
            totalCount: tasks.length,
            completedCount,
            activeCount,
            pausedCount,
            closedCount,
            pendingCount,
            percent: progressBase === 0 ? 0 : Math.round((completedCount / progressBase) * 100),
        };
    };

    const getTaskAssetChanges = (task: WorkTask): AssetMaintenanceRecord[] => {
        if (!task.assetMaintenanceSnapshot) return [];
        try {
            const records = JSON.parse(task.assetMaintenanceSnapshot);
            return Array.isArray(records) ? records : [];
        } catch {
            return [];
        }
    };

    const renderAssetChanges = (tasks: WorkTask[], showTaskName: boolean) => {
        const changes = tasks.flatMap(task =>
            getTaskAssetChanges(task).map(record => ({ task, record }))
        );

        return (
            <div className="mt-3 border-t border-slate-100 pt-3">
                <button
                    type="button"
                    disabled={changes.length === 0}
                    onClick={() => {
                        setAssetChangeTitle(showTaskName ? '工作资产变更记录' : `${tasks[0]?.title || '任务'} · 资产变更记录`);
                        setAssetChangeDetails(changes);
                    }}
                    className="inline-flex items-center gap-2 text-xs font-bold text-slate-600 transition-colors enabled:hover:text-cyan-700 disabled:cursor-default disabled:text-slate-400"
                >
                    <span>对应资产变更记录</span>
                    <span className="rounded bg-cyan-50 px-1.5 py-0.5 text-cyan-700">{changes.length} 条</span>
                    {changes.length > 0 && <span className="font-normal text-slate-400">点击查看</span>}
                </button>
            </div>
        );
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

    const parseRiskEntry = (line: string, task: WorkTask): WorkRiskEntry => {
        const trimmedLine = line.trim();
        const timeMatch = trimmedLine.match(/^\[([^\]]+)\]\s*(.*)$/);
        const fallbackReporter = renderAssignee(task.assigneeId);
        if (!timeMatch) {
            return {
                taskId: task.id,
                taskTitle: task.title,
                stage: task.currentStage,
                reporter: fallbackReporter,
                reportedAt: task.stageUpdatedAt ? formatDateTime(task.stageUpdatedAt) : '-',
                content: trimmedLine,
            };
        }

        const [, reportedAt, rawRest] = timeMatch;
        const stageMatch = rawRest.match(/^\[([^\]]+)\]\s*(.*)$/);
        const stage = stageMatch ? stageMatch[1] : task.currentStage;
        const rest = stageMatch ? stageMatch[2] : rawRest;
        const reporterMatch = rest.match(/^([^:：]{1,40})[:：]\s*(.*)$/);
        return {
            taskId: task.id,
            taskTitle: task.title,
            stage,
            reporter: reporterMatch ? reporterMatch[1] : fallbackReporter,
            reportedAt,
            content: reporterMatch ? reporterMatch[2] : rest,
        };
    };

    const getWorkRiskEntries = (workId: string): WorkRiskEntry[] => {
        return getOrderedTasks(workId).flatMap(task => {
            if (!task.stageRiskReported && !task.stageRiskNote) return [];
            if (!task.stageRiskNote) {
                return [{
                    taskId: task.id,
                    taskTitle: task.title,
                    stage: task.currentStage,
                    reporter: renderAssignee(task.assigneeId),
                    reportedAt: task.stageUpdatedAt ? formatDateTime(task.stageUpdatedAt) : '-',
                    content: '已报备',
                }];
            }
            return task.stageRiskNote
                .split(/\n+/)
                .map(line => line.trim())
                .filter(Boolean)
                .map(line => parseRiskEntry(line, task));
        });
    };

    const renderWorkRiskSummary = (workId: string) => {
        const riskEntries = getWorkRiskEntries(workId);

        return (
            <div className="border-t border-slate-200 pt-4">
                <div className="mb-3 flex flex-wrap items-center justify-between gap-3">
                    <div className="flex items-center gap-2">
                        <div className="text-sm font-bold text-slate-800">任务风险及跟踪记录</div>
                        <span className="text-xs text-slate-400">{riskEntries.length} 条</span>
                    </div>
                    <button
                        type="button"
                        onClick={() => {
                            const firstTask = getOrderedTasks(workId)[0];
                            setTrackingWorkId(workId);
                            setTrackingTaskId(firstTask?.id || '');
                            setTrackingNote('');
                        }}
                        className="inline-flex items-center gap-1.5 rounded-md border border-amber-200 bg-amber-50 px-2.5 py-1.5 text-xs font-bold text-amber-700 transition-colors hover:bg-amber-100"
                    >
                        <Plus size={12} /> 追加
                    </button>
                </div>
                {riskEntries.length === 0 ? (
                    <div className="rounded-md bg-slate-50 px-3 py-2.5 text-xs text-slate-400">暂无风险及跟踪记录</div>
                ) : (
                    <div className="divide-y divide-slate-100 rounded-md border border-slate-200 bg-white">
                    {riskEntries.map((entry, index) => (
                        <div key={`${entry.taskId}-${index}`} className="px-3 py-2.5 text-xs">
                            <div className="mb-1 flex flex-wrap items-center gap-2">
                                <span className="font-bold text-slate-800 truncate max-w-[360px]">{entry.taskTitle}</span>
                                {entry.stage && (
                                    <>
                                        <span className="text-slate-400">|</span>
                                        <span className="text-blue-700">阶段：{getTaskStageLabel(entry.stage as WorkTask['currentStage'])}</span>
                                    </>
                                )}
                                <span className="text-slate-400">|</span>
                                <span className="text-slate-600">报备人：{entry.reporter}</span>
                                <span className="text-slate-400">|</span>
                                <span className="text-slate-500">时间：{entry.reportedAt}</span>
                            </div>
                            <div className="text-slate-700 whitespace-pre-wrap break-words">{entry.content || '-'}</div>
                        </div>
                    ))}
                    </div>
                )}
            </div>
        );
    };

    const closeTrackingModal = () => {
        setTrackingWorkId(null);
        setTrackingTaskId('');
        setTrackingNote('');
        setTrackingSubmitting(false);
    };

    const submitTrackingNote = async () => {
        if (!trackingTaskId || !trackingNote.trim()) return;
        setTrackingSubmitting(true);
        try {
            await appendTaskRiskTracking(trackingTaskId, { trackingNote: trackingNote.trim() });
            closeTrackingModal();
            await fetchWorks(currentPage, pageSize);
        } catch (error) {
            alert('追加跟踪记录失败');
            setTrackingSubmitting(false);
        }
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

    const renderTaskSection = (title: string, tasks: WorkTask[]) => (
        <section>
            <div className="mb-2 flex items-center gap-2">
                {title === '主任务' ? (
                    <CheckCircle2 size={15} className="text-red-500" />
                ) : (
                    <Circle size={14} className="text-slate-400" />
                )}
                <h4 className="text-sm font-bold text-slate-800">{title}</h4>
                <span className="text-xs text-slate-400">{tasks.length}</span>
            </div>
            {tasks.length === 0 ? (
                <div className="rounded-md bg-slate-50 px-3 py-3 text-center text-xs text-slate-400">暂无{title}</div>
            ) : (
                <div className="overflow-x-auto rounded-lg border border-slate-200">
                    <div className="min-w-[900px]">
                        <div className="grid grid-cols-[minmax(280px,1.7fr)_100px_110px_130px_120px_70px_90px] gap-3 bg-slate-50 px-4 py-2 text-xs font-bold text-slate-500">
                            <span>任务名称</span>
                            <span>状态</span>
                            <span>当前阶段</span>
                            <span>负责人</span>
                            <span>截止日期</span>
                            <span>积分</span>
                            <span>操作</span>
                        </div>
                        <div className="divide-y divide-slate-100 bg-white">
                            {tasks.map(task => (
                                <div key={task.id} className="px-4 py-3">
                                    <div className="grid grid-cols-[minmax(280px,1.7fr)_100px_110px_130px_120px_70px_90px] items-start gap-3 text-xs">
                                        <div className="min-w-0">
                                            <div className="flex items-center gap-2">
                                                <span className={`shrink-0 rounded px-1.5 py-0.5 text-[11px] font-bold ${
                                                    task.taskRole === 'MAIN'
                                                        ? 'bg-red-50 text-red-600'
                                                        : 'bg-slate-100 text-slate-600'
                                                }`}>
                                                    {task.taskRole === 'MAIN' ? '主任务' : '子任务'}
                                                </span>
                                                <span className="truncate font-bold text-slate-800">{task.title}</span>
                                            </div>
                                            {task.description && (
                                                <div className="mt-1 line-clamp-2 leading-5 text-slate-500">{task.description}</div>
                                            )}
                                            {renderAssetChanges([task], false)}
                                        </div>
                                        <span className={`w-fit rounded px-2 py-0.5 font-bold ${statusClass(task.status)}`}>
                                            {getTaskStatusLabel(task.status)}
                                        </span>
                                        <span className="font-bold text-blue-700">
                                            {isIssueTrackingTask(task) ? '不适用' : getTaskStageLabel(task.currentStage)}
                                        </span>
                                        <span className="truncate text-slate-600">{renderAssignee(task.assigneeId)}</span>
                                        <span className="text-slate-500">{renderValue(formatDate(task.deadline))}</span>
                                        <span className="font-bold text-orange-600">{task.points ?? 0}</span>
                                        {normalizeTaskStatus(task.status) === 'CANCELLED' ? (
                                            <button
                                                onClick={() => handleReopenTask(task)}
                                                className="inline-flex w-fit items-center rounded bg-green-50 px-2 py-1 font-bold text-green-700 transition-colors hover:bg-green-100"
                                            >
                                                重新开启
                                            </button>
                                        ) : isClosedTaskStatus(task.status) ? (
                                            <span className="text-slate-300">-</span>
                                        ) : (
                                            <button
                                                onClick={() => handleToggleTaskPaused(task)}
                                                className={`inline-flex w-fit items-center gap-1 rounded px-2 py-1 font-bold transition-colors ${
                                                    isPausedTask(task)
                                                        ? 'bg-green-50 text-green-700 hover:bg-green-100'
                                                        : 'bg-amber-50 text-amber-700 hover:bg-amber-100'
                                                }`}
                                                title={isPausedTask(task) ? '继续任务' : '暂停任务'}
                                            >
                                                {isPausedTask(task) ? <PlayCircle size={13} /> : <PauseCircle size={13} />}
                                                {isPausedTask(task) ? '继续' : '暂停'}
                                            </button>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            )}
        </section>
    );

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
                        <div className="grid grid-cols-[72px_minmax(220px,1.5fr)_minmax(130px,.85fr)_minmax(150px,1fr)_minmax(140px,1fr)_104px_112px_128px] gap-3 border-b border-slate-200 bg-slate-50 px-4 py-2.5 text-xs font-bold text-slate-500">
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
                        {works.map(work => {
                            const taskProgress = getTaskProgressSummary(work.id);
                            const orderedTasks = getOrderedTasks(work.id);
                            const mainTasks = orderedTasks.filter(task => task.taskRole === 'MAIN');
                            const subTasks = orderedTasks.filter(task => task.taskRole !== 'MAIN');

                            return (
                                <div key={work.id} className="border-b border-slate-100 last:border-b-0">
                                    <div className={`grid grid-cols-[72px_minmax(220px,1.5fr)_minmax(130px,.85fr)_minmax(150px,1fr)_minmax(140px,1fr)_104px_112px_128px] items-center gap-3 px-4 py-3.5 text-sm transition-colors ${
                                        expandedWorkIds[work.id] ? 'bg-blue-50/30' : 'hover:bg-slate-50/70'
                                    }`}>
                                        <div className="flex items-center gap-2">
                                            <input
                                                type="checkbox"
                                                checked={selectedWorkIds.includes(work.id)}
                                                onChange={() => toggleSelected(work.id)}
                                                className="h-4 w-4 rounded border-slate-300"
                                                aria-label={`选择工作 ${work.title}`}
                                            />
                                            <button
                                                onClick={() => toggleExpanded(work.id)}
                                                className="inline-flex h-8 w-8 items-center justify-center rounded-md text-slate-500 transition-colors hover:bg-white hover:text-slate-800"
                                                title={expandedWorkIds[work.id] ? '收起任务' : '展开任务'}
                                            >
                                                {expandedWorkIds[work.id] ? <ChevronDown size={17} /> : <ChevronRight size={17} />}
                                            </button>
                                        </div>
                                        <div className="min-w-0">
                                            <button
                                                onClick={() => {
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
                                        <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
                                            <button
                                                onClick={() => {
                                                    setEditingWorkId(work.id);
                                                    setIsDrawerOpen(true);
                                                }}
                                                className="inline-flex items-center gap-1 py-1 text-xs font-bold text-blue-600 transition-colors hover:text-blue-800"
                                                title="修改工作"
                                            >
                                                <Edit3 size={14} />编辑
                                            </button>
                                            {work.status === 'DRAFT' && (
                                                <button
                                                    onClick={() => handlePublish(work.id)}
                                                    className="inline-flex items-center gap-1 py-1 text-xs font-bold text-green-600 transition-colors hover:text-green-800"
                                                    title="发布到市场"
                                                >
                                                    <Play size={14} />发布
                                                </button>
                                            )}
                                            {(work.status === 'DRAFT' || work.status === 'PUBLISHED') && (
                                                <button
                                                    onClick={() => handleCancel(work.id)}
                                                    className="inline-flex items-center gap-1 py-1 text-xs font-bold text-red-500 transition-colors hover:text-red-700"
                                                    title="取消工作"
                                                >
                                                    <XCircle size={14} />取消
                                                </button>
                                            )}
                                        </div>
                                    </div>

                                    {expandedWorkIds[work.id] && (
                                        <div className="border-t border-slate-200 bg-slate-50/60 px-5 py-5">
                                            <div className="mb-5 grid grid-cols-[minmax(0,1.45fr)_minmax(360px,.9fr)] overflow-hidden rounded-lg border border-slate-200 bg-white">
                                                <section className="p-5">
                                                    <h3 className="text-sm font-bold text-slate-900">工作内容</h3>
                                                    <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-slate-600">
                                                        {renderValue(work.description)}
                                                    </p>
                                                    <dl className="mt-4 grid grid-cols-2 gap-x-8 gap-y-3 border-t border-slate-100 pt-4 text-xs xl:grid-cols-3">
                                                        <div>
                                                            <dt className="text-slate-400">申请部门</dt>
                                                            <dd className="mt-1 font-medium text-slate-700">{renderValue(work.applicationDepartment)}</dd>
                                                        </div>
                                                        <div>
                                                            <dt className="text-slate-400">申请人</dt>
                                                            <dd className="mt-1 font-medium text-slate-700">{renderValue(work.applicantName)}</dd>
                                                        </div>
                                                        <div>
                                                            <dt className="text-slate-400">主任务负责人</dt>
                                                            <dd className="mt-1 font-medium text-slate-700">{renderAssignee(getMainTask(work.id)?.assigneeId)}</dd>
                                                        </div>
                                                        <div>
                                                            <dt className="text-slate-400">归属系统</dt>
                                                            <dd className="mt-1 font-medium text-slate-700">{renderValue(work.owningSystem)}</dd>
                                                        </div>
                                                        <div>
                                                            <dt className="text-slate-400">项目类型</dt>
                                                            <dd className="mt-1 font-medium text-slate-700">{renderValue(work.projectType)}</dd>
                                                        </div>
                                                        <div>
                                                            <dt className="text-slate-400">主系统</dt>
                                                            <dd className="mt-1 font-medium text-slate-700">{getPrimarySystemText(work)}</dd>
                                                        </div>
                                                    </dl>
                                                    {renderAssetChanges(orderedTasks, true)}
                                                </section>
                                                <section className="border-l border-slate-200 bg-slate-50/40 p-5">
                                                    <div className="flex items-center justify-between gap-3">
                                                        <h3 className="text-sm font-bold text-slate-900">任务进度</h3>
                                                        <span className="text-xs text-slate-400">{taskProgress.totalCount} 个任务</span>
                                                    </div>
                                                    <div className="mt-4 flex items-center gap-3">
                                                        <Progress
                                                            percent={taskProgress.percent}
                                                            size="small"
                                                            strokeColor="#2563eb"
                                                            trailColor="#e2e8f0"
                                                        />
                                                    </div>
                                                    <div className="mt-4 grid grid-cols-4 gap-3 text-center">
                                                        <div>
                                                            <div className="text-lg font-bold text-green-600">{taskProgress.completedCount}</div>
                                                            <div className="mt-0.5 text-[11px] text-slate-400">已完成</div>
                                                        </div>
                                                        <div>
                                                            <div className="text-lg font-bold text-blue-600">{taskProgress.activeCount}</div>
                                                            <div className="mt-0.5 text-[11px] text-slate-400">进行中</div>
                                                        </div>
                                                        <div>
                                                            <div className="text-lg font-bold text-slate-600">{taskProgress.pendingCount}</div>
                                                            <div className="mt-0.5 text-[11px] text-slate-400">待开始</div>
                                                        </div>
                                                        <div>
                                                            <div className="text-lg font-bold text-amber-600">{taskProgress.pausedCount}</div>
                                                            <div className="mt-0.5 text-[11px] text-slate-400">暂停中</div>
                                                        </div>
                                                    </div>
                                                    <div className="mt-5 space-y-3 border-t border-slate-200 pt-4 text-xs">
                                                        <div className="flex items-center justify-between gap-4">
                                                            <span className="inline-flex items-center gap-1.5 text-slate-400"><Clock3 size={13} />创建时间</span>
                                                            <span className="font-medium text-slate-700">{renderValue(formatDateTime(work.createTime))}</span>
                                                        </div>
                                                        <div className="flex items-center justify-between gap-4">
                                                            <span className="inline-flex items-center gap-1.5 text-slate-400"><CalendarDays size={13} />截止日期</span>
                                                            <span className="font-medium text-slate-700">{renderValue(formatDate(work.deadline))}</span>
                                                        </div>
                                                        <div className="flex items-center justify-between gap-4">
                                                            <span className="inline-flex items-center gap-1.5 text-slate-400"><Users size={13} />执行人</span>
                                                            <span className="font-medium text-slate-700">{orderedTasks.filter(task => task.assigneeId).length} 个任务已分配</span>
                                                        </div>
                                                        {taskProgress.closedCount > 0 && (
                                                            <div className="flex items-center justify-between gap-4">
                                                                <span className="text-slate-400">已关闭任务</span>
                                                                <span className="font-medium text-slate-700">{taskProgress.closedCount}</span>
                                                            </div>
                                                        )}
                                                    </div>
                                                </section>
                                            </div>

                                            <div className="space-y-5">
                                                {renderWorkRiskSummary(work.id)}
                                                {renderTaskSection('主任务', mainTasks)}
                                                {renderTaskSection('子任务', subTasks)}
                                            </div>
                                        </div>
                                    )}
                                </div>
                            );
                        })}
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
                onClose={() => setIsDetailOpen(false)}
            />

            <Modal
                title={assetChangeTitle || '资产变更记录'}
                open={assetChangeDetails.length > 0}
                onCancel={() => {
                    setAssetChangeTitle('');
                    setAssetChangeDetails([]);
                }}
                footer={null}
                width={1040}
                destroyOnHidden
            >
                <div className="mb-3 flex items-center justify-between rounded-md bg-slate-50 px-3 py-2 text-xs">
                    <span className="text-slate-500">共 {assetChangeDetails.length} 条变更记录</span>
                    <span className="text-slate-400">按任务汇总展示</span>
                </div>
                <div className="max-h-[65vh] overflow-auto rounded-md border border-slate-200">
                    <table className="w-full min-w-[900px] table-fixed text-xs">
                        <thead className="sticky top-0 z-10 bg-slate-50 text-slate-500 shadow-[0_1px_0_0_#e2e8f0]">
                            <tr>
                                <th className="w-[18%] px-3 py-2.5 text-left">所属任务</th>
                                <th className="w-[11%] px-3 py-2.5 text-left">所属系统</th>
                                <th className="w-[10%] px-3 py-2.5 text-left">变更类型</th>
                                <th className="w-[20%] px-3 py-2.5 text-left">表 / 字段</th>
                                <th className="w-[17%] px-3 py-2.5 text-left">变更信息</th>
                                <th className="w-[24%] px-3 py-2.5 text-left">说明</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {assetChangeDetails.map(({ task, record }, index) => (
                                <tr key={`${task.id}-${record.id || index}`} className="align-top transition-colors hover:bg-cyan-50/30">
                                    <td className="px-3 py-2.5">
                                        <div className="break-words font-bold text-slate-700">{task.title}</div>
                                        <div className="mt-1 text-slate-400">{task.taskRole === 'MAIN' ? '主任务' : '子任务'}</div>
                                    </td>
                                    <td className="break-words px-3 py-2.5 text-slate-600">{record.systemCode || '-'}</td>
                                    <td className="px-3 py-2.5 font-bold text-cyan-700">{record.modType || '-'}</td>
                                    <td className="px-3 py-2.5">
                                        <div className="break-words text-slate-700">{record.tableCnName || record.tableName || '-'}</div>
                                        {(record.fieldCnName || record.fieldName) && (
                                            <div className="mt-1 break-words text-slate-400">{record.fieldCnName || record.fieldName}</div>
                                        )}
                                    </td>
                                    <td className="px-3 py-2.5">
                                        <div className="text-slate-700">{record.operator || '-'}</div>
                                        <div className="mt-1 text-slate-400">{record.time ? formatDateTime(record.time) : '-'}</div>
                                    </td>
                                    <td className="whitespace-pre-wrap break-words px-3 py-2.5 leading-5 text-slate-600">{record.description || '-'}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </Modal>

            <Modal
                title="追加任务风险跟踪记录"
                open={!!trackingWorkId}
                onCancel={closeTrackingModal}
                onOk={submitTrackingNote}
                okText="追加"
                cancelText="取消"
                confirmLoading={trackingSubmitting}
                okButtonProps={{ disabled: !trackingTaskId || !trackingNote.trim() }}
                destroyOnHidden
            >
                <div className="space-y-4 pt-2">
                    <label className="block">
                        <span className="mb-1.5 block text-xs font-bold text-slate-600">对应任务</span>
                        <select
                            value={trackingTaskId}
                            onChange={event => setTrackingTaskId(event.target.value)}
                            className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-amber-500"
                        >
                            {(trackingWorkId ? getOrderedTasks(trackingWorkId) : []).map(task => (
                                <option key={task.id} value={task.id}>
                                    {task.taskRole === 'MAIN' ? '主任务' : '子任务'} · {task.title}
                                </option>
                            ))}
                        </select>
                    </label>
                    <label className="block">
                        <span className="mb-1.5 block text-xs font-bold text-slate-600">跟踪内容</span>
                        <textarea
                            value={trackingNote}
                            onChange={event => setTrackingNote(event.target.value)}
                            rows={4}
                            maxLength={1000}
                            placeholder="填写风险处理进展、协调结果或后续安排"
                            className="w-full resize-none rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-amber-500"
                        />
                    </label>
                </div>
            </Modal>
        </div>
    );
};

export default WorkList;
