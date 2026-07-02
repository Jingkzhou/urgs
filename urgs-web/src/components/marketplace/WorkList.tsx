import React, { useState, useEffect } from 'react';
import * as XLSX from 'xlsx';
import { Modal, Pagination, Tooltip } from 'antd';
import { appendTaskRiskTracking, AssetMaintenanceRecord, listWorks, publishWork, cancelWork, batchDeleteWorks, updateTaskStatus, Work, WorkTask, getWorkTasks } from '../../api/marketplace';
import { ChevronDown, ChevronRight, Download, Edit3, ListTodo, PauseCircle, Plus, Play, PlayCircle, Trash2, Upload, XCircle } from 'lucide-react';
import CreateWorkDrawer from './CreateWorkDrawer';
import ImportWorkModal from './ImportWorkModal';
import WorkDetailDrawer from './WorkDetailDrawer';
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

    const fetchWorks = async (page = currentPage, size = pageSize) => {
        setLoading(true);
        try {
            const res = await listWorks({ current: page, size });
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
    }, [currentPage, pageSize]);

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
        return ['COMPLETED', 'CANCELLED', 'REJECTED', 'ASSET_REVIEW', 'REVIEW'].includes(normalizeTaskStatus(status) || '');
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
        if (status === 'IN_PROGRESS' || status === 'ASSIGNED') return 'bg-blue-100 text-blue-700';
        if (status === 'PAUSED') return 'bg-amber-100 text-amber-700';
        if (status === 'ASSET_REVIEW') return 'bg-cyan-100 text-cyan-700';
        if (status === 'REVIEW') return 'bg-orange-100 text-orange-700';
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

    const getRiskSummary = (task: WorkTask) => {
        if (!task.stageRiskReported && !task.stageRiskNote) return '-';
        return '已报备';
    };

    const isIssueTrackingTask = (task: WorkTask) => {
        const taskType = (task.taskType || '').trim();
        return taskType === '问题跟踪' || taskType === '问题追踪';
    };

    const renderRiskSummary = (task: WorkTask) => {
        const summary = getRiskSummary(task);
        if (!task.stageRiskNote) {
            return <span className={task.stageRiskReported ? 'text-amber-700 font-bold truncate' : 'text-slate-400'}>{summary}</span>;
        }

        return (
            <Tooltip
                title={<span className="whitespace-pre-wrap">{task.stageRiskNote}</span>}
                placement="topLeft"
                overlayStyle={{ maxWidth: 520 }}
                destroyTooltipOnHide
            >
                <span className="text-amber-700 font-bold truncate cursor-help">{summary}</span>
            </Tooltip>
        );
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
            <div className="bg-amber-50/60 border border-amber-100 rounded-lg px-4 py-3 mb-3">
                <div className="flex items-center gap-2 mb-2">
                    <div className="text-xs font-bold text-amber-800">任务风险及跟踪记录</div>
                    <button
                        type="button"
                        onClick={() => {
                            const firstTask = getOrderedTasks(workId)[0];
                            setTrackingWorkId(workId);
                            setTrackingTaskId(firstTask?.id || '');
                            setTrackingNote('');
                        }}
                        className="inline-flex items-center gap-1 rounded bg-amber-600 px-2 py-1 text-[11px] font-bold text-white hover:bg-amber-700"
                    >
                        <Plus size={12} /> 追加
                    </button>
                    <span className="text-[11px] font-bold text-amber-700 bg-white/70 border border-amber-100 rounded px-2 py-0.5">
                        {riskEntries.length} 条
                    </span>
                </div>
                {riskEntries.length === 0 ? (
                    <div className="text-xs text-amber-700/70">暂无风险及跟踪记录</div>
                ) : (
                    <div className="space-y-2">
                    {riskEntries.map((entry, index) => (
                        <div key={`${entry.taskId}-${index}`} className="bg-white/80 border border-amber-100 rounded px-3 py-2 text-xs">
                            <div className="flex flex-wrap items-center gap-2 mb-1">
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

    return (
        <div className="h-full flex flex-col p-6 overflow-y-auto relative">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold text-slate-800">我发布的工作</h2>
                <div className="flex items-center gap-2">
                    {selectedWorkIds.length > 0 && (
                        <button
                            onClick={handleBatchDelete}
                            className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-500 transition-colors text-sm font-bold"
                        >
                            <Trash2 size={16} />批量删除({selectedWorkIds.length})
                        </button>
                    )}
                    <button
                        onClick={() => setIsImportOpen(true)}
                        className="flex items-center gap-2 px-4 py-2 bg-white text-slate-700 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors text-sm font-bold"
                    >
                        <Upload size={16} />导入
                    </button>
                    <button
                        onClick={exportWorks}
                        disabled={works.length === 0}
                        className="flex items-center gap-2 px-4 py-2 bg-white text-slate-700 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors text-sm font-bold disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        <Download size={16} />导出
                    </button>
                    <button
                        onClick={() => {
                            setEditingWorkId(null);
                            setIsDrawerOpen(true);
                        }}
                        className="flex items-center gap-2 px-4 py-2 bg-slate-800 text-white rounded-lg hover:bg-slate-700 transition-colors text-sm font-bold"
                    >
                        <Plus size={16} />新建工作
                    </button>
                </div>
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
                <div className="text-center py-10 text-slate-400">加载中...</div>
            ) : works.length === 0 ? (
                <div className="text-center py-10 text-slate-400 bg-slate-50 rounded-2xl border border-dashed border-slate-200">
                    暂无工作，可通过右上角新建或导入。
                </div>
            ) : (
                <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-x-auto">
                    <div className="min-w-[1940px]">
                        <div className="grid grid-cols-[44px_44px_minmax(220px,1.4fr)_190px_120px_110px_220px_140px_110px_90px_150px_150px_150px_100px_90px_100px] gap-3 px-4 py-3 bg-slate-50 border-b border-slate-200 text-xs font-bold text-slate-500">
                            <input
                                type="checkbox"
                                checked={works.length > 0 && selectedWorkIds.length === works.length}
                                onChange={toggleSelectAll}
                                className="h-4 w-4 rounded border-slate-300"
                                aria-label="全选工作"
                            />
                            <span></span>
                            <span>工作名称</span>
                            <span>需求编号</span>
                            <span>申请部门</span>
                            <span>申请人</span>
                            <span>负责人</span>
                            <span>归属系统</span>
                            <span>项目类型</span>
                            <span>优先级</span>
                            <span>截止日期</span>
                            <span>创建时间</span>
                            <span>主系统</span>
                            <span>状态</span>
                            <span>子任务</span>
                            <span>操作</span>
                        </div>
                    {works.map(work => (
                        <div key={work.id} className="border-b border-slate-100 last:border-b-0">
                            <div className="grid grid-cols-[44px_44px_minmax(220px,1.4fr)_190px_120px_110px_220px_140px_110px_90px_150px_150px_150px_100px_90px_100px] gap-3 px-4 py-4 items-center text-sm">
                                <input
                                    type="checkbox"
                                    checked={selectedWorkIds.includes(work.id)}
                                    onChange={() => toggleSelected(work.id)}
                                    className="h-4 w-4 rounded border-slate-300"
                                    aria-label={`选择工作 ${work.title}`}
                                />
                                <button
                                    onClick={() => toggleExpanded(work.id)}
                                    className="h-8 w-8 inline-flex items-center justify-center rounded-lg text-slate-500 hover:bg-slate-100"
                                    title={expandedWorkIds[work.id] ? '收起任务' : '展开任务'}
                                >
                                    {expandedWorkIds[work.id] ? <ChevronDown size={17} /> : <ChevronRight size={17} />}
                                </button>
                                <div className="min-w-0">
                                    <button
                                        onClick={() => {
                                            setSelectedWorkId(work.id);
                                            setIsDetailOpen(true);
                                        }}
                                        className="font-bold text-slate-800 hover:text-red-600 transition-colors truncate block max-w-full text-left"
                                    >
                                        {work.title}
                                    </button>
                                    <div className="flex flex-wrap items-center gap-2 mt-1 text-xs text-slate-400">
                                        <span>积分: {work.totalPoints ?? 0}</span>
                                    </div>
                                </div>
                                <span className="text-slate-600 whitespace-normal break-all">{renderValue(work.requirementNumber)}</span>
                                <span className="text-slate-600 truncate">{renderValue(work.applicationDepartment)}</span>
                                <span className="text-slate-600 truncate">{renderValue(work.applicantName)}</span>
                                {renderWorkAssignees(work.id)}
                                <span className="text-slate-600 truncate">{renderValue(work.owningSystem)}</span>
                                <span className="text-blue-700 truncate">{renderValue(work.projectType)}</span>
                                <span className="font-bold text-red-500">{renderValue(work.priority)}</span>
                                <span className="text-slate-500 truncate">{renderValue(formatDate(work.deadline))}</span>
                                <span className="text-slate-500 truncate">{renderValue(formatDateTime(work.createTime))}</span>
                                <span className="text-slate-600 truncate">{getPrimarySystemText(work)}</span>
                                <span className={`w-fit px-2 py-0.5 rounded text-xs font-bold ${statusClass(work.status)}`}>
                                    {getWorkStatusLabel(work.status)}
                                </span>
                                <span className="inline-flex items-center gap-1.5 text-slate-600">
                                    <ListTodo size={13} /> {taskSummaries[work.id]?.taskCount ?? 0}
                                </span>
                                <div className="flex items-center gap-2">
                                    <button
                                        onClick={() => {
                                            setEditingWorkId(work.id);
                                            setIsDrawerOpen(true);
                                        }}
                                        className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                        title="修改工作"
                                    >
                                        <Edit3 size={18} />
                                    </button>
                                    {work.status === 'DRAFT' && (
                                        <button
                                            onClick={() => handlePublish(work.id)}
                                            className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                                            title="发布到市场"
                                        >
                                            <Play size={18} />
                                        </button>
                                    )}
                                    {(work.status === 'DRAFT' || work.status === 'PUBLISHED') && (
                                        <button
                                            onClick={() => handleCancel(work.id)}
                                            className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                            title="取消工作"
                                        >
                                            <XCircle size={18} />
                                        </button>
                                    )}
                                </div>
                            </div>

                            {expandedWorkIds[work.id] && (
                                <div className="ml-[88px] bg-slate-50/70 border-t border-l-2 border-slate-200 px-4 py-3">
                                    <div className="bg-white border border-slate-100 rounded-lg px-4 py-3 mb-3">
                                        <div className="text-xs font-bold text-slate-500 mb-3">工作内容</div>
                                        <div className="grid grid-cols-2 xl:grid-cols-4 gap-x-6 gap-y-2 text-xs">
                                            <div><span className="text-slate-400">优先级：</span><span className="font-medium text-slate-700">{renderValue(work.priority)}</span></div>
                                            <div><span className="text-slate-400">需求编号：</span><span className="font-medium text-slate-700">{renderValue(work.requirementNumber)}</span></div>
                                            <div><span className="text-slate-400">截止日期：</span><span className="font-medium text-slate-700">{renderValue(formatDate(work.deadline))}</span></div>
                                            <div><span className="text-slate-400">申请部门：</span><span className="font-medium text-slate-700">{renderValue(work.applicationDepartment)}</span></div>
                                            <div><span className="text-slate-400">申请人：</span><span className="font-medium text-slate-700">{renderValue(work.applicantName)}</span></div>
                                            <div><span className="text-slate-400">主任务负责人：</span><span className="font-medium text-slate-700">{renderAssignee(getMainTask(work.id)?.assigneeId)}</span></div>
                                            <div><span className="text-slate-400">归属系统：</span><span className="font-medium text-slate-700">{renderValue(work.owningSystem)}</span></div>
                                            <div><span className="text-slate-400">主系统：</span><span className="font-medium text-slate-700">{getPrimarySystemText(work)}</span></div>
                                            <div><span className="text-slate-400">项目类型：</span><span className="font-medium text-slate-700">{renderValue(work.projectType)}</span></div>
                                            <div><span className="text-slate-400">创建时间：</span><span className="font-medium text-slate-700">{renderValue(formatDateTime(work.createTime))}</span></div>
                                            <div className="col-span-2 xl:col-span-4">
                                                <span className="text-slate-400">详细描述：</span>
                                                <span className="font-medium text-slate-700 whitespace-pre-wrap">{renderValue(work.description)}</span>
                                            </div>
                                        </div>
                                        {renderAssetChanges(getOrderedTasks(work.id), true)}
                                    </div>
                                    {renderWorkRiskSummary(work.id)}
                                    <div className="flex items-center gap-2 mb-2 text-xs font-bold text-slate-500">
                                        <span className="h-2 w-2 rounded-full bg-slate-400"></span>
                                        <span>二级任务菜单</span>
                                    </div>
                                    <div className="grid grid-cols-[88px_minmax(220px,1.5fr)_100px_100px_90px_120px_90px] gap-3 px-3 py-2 text-xs font-bold text-slate-400">
                                        <span>层级</span>
                                        <span>任务名称</span>
                                        <span>状态</span>
                                        <span>阶段</span>
                                        <span>积分</span>
                                        <span>风险</span>
                                        <span>操作</span>
                                    </div>
                                    {getOrderedTasks(work.id).map(task => (
                                        <div key={task.id} className="relative bg-white border border-slate-100 rounded-lg mb-2 last:mb-0 px-3 py-2">
                                            <div className="grid grid-cols-[88px_minmax(220px,1.5fr)_100px_100px_90px_120px_90px] gap-3 items-center text-xs">
                                                <span className="absolute -left-[17px] top-5 h-px w-4 bg-slate-200"></span>
                                                <span className={`w-fit px-2 py-0.5 rounded font-bold ${task.taskRole === 'MAIN' ? 'bg-red-50 text-red-600' : 'bg-slate-100 text-slate-600'}`}>
                                                    {task.taskRole === 'MAIN' ? '主任务' : '子任务'}
                                                </span>
                                                <div className="min-w-0">
                                                    <div className="font-bold text-slate-700 truncate">{task.title}</div>
                                                    {task.description && <div className="text-slate-400 truncate mt-0.5">{task.description}</div>}
                                                </div>
                                                <span className={`w-fit px-2 py-0.5 rounded font-bold ${statusClass(task.status)}`}>
                                                    {getTaskStatusLabel(task.status)}
                                                </span>
                                                <span className="text-blue-700 font-bold">
                                                    {isIssueTrackingTask(task) ? '不适用' : getTaskStageLabel(task.currentStage)}
                                                </span>
                                                <span className="font-bold text-orange-600">{task.points ?? 0}</span>
                                                {renderRiskSummary(task)}
                                                {isClosedTaskStatus(task.status) ? (
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
                                            {renderAssetChanges([task], false)}
                                        </div>
                                    ))}
                                    {(workTasks[work.id] || []).length === 0 && (
                                        <div className="text-center py-4 text-xs text-slate-400">暂无任务</div>
                                    )}
                                </div>
                            )}
                        </div>
                    ))}
                    </div>
                    <div className="border-t border-slate-100 bg-white px-4 py-3 flex justify-end">
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
                width={920}
                destroyOnHidden
            >
                <div className="max-h-[65vh] overflow-auto rounded-md border border-slate-200">
                    <table className="w-full min-w-[820px] text-xs">
                        <thead className="sticky top-0 bg-slate-50 text-slate-500">
                            <tr>
                                <th className="px-3 py-2 text-left">所属任务</th>
                                <th className="px-3 py-2 text-left">变更类型</th>
                                <th className="px-3 py-2 text-left">表/字段</th>
                                <th className="px-3 py-2 text-left">操作人</th>
                                <th className="px-3 py-2 text-left">时间</th>
                                <th className="px-3 py-2 text-left">说明</th>
                            </tr>
                        </thead>
                        <tbody>
                            {assetChangeDetails.map(({ task, record }, index) => (
                                <tr key={`${task.id}-${record.id || index}`} className="border-t border-slate-100 align-top">
                                    <td className="px-3 py-2 min-w-[150px]">
                                        <div className="font-bold text-slate-700">{task.title}</div>
                                        <div className="mt-1 text-slate-400">{task.taskRole === 'MAIN' ? '主任务' : '子任务'}</div>
                                    </td>
                                    <td className="px-3 py-2 font-bold text-cyan-700">{record.modType || '-'}</td>
                                    <td className="px-3 py-2 min-w-[160px]">
                                        <div>{record.tableCnName || record.tableName || '-'}</div>
                                        {(record.fieldCnName || record.fieldName) && (
                                            <div className="mt-1 text-slate-400">{record.fieldCnName || record.fieldName}</div>
                                        )}
                                    </td>
                                    <td className="px-3 py-2">{record.operator || '-'}</td>
                                    <td className="px-3 py-2 min-w-[150px]">{record.time ? formatDateTime(record.time) : '-'}</td>
                                    <td className="px-3 py-2 min-w-[200px] whitespace-pre-wrap">{record.description || '-'}</td>
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
