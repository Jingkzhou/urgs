import React, { useEffect, useMemo, useState } from 'react';
import { Drawer, Empty, Spin, Tag } from 'antd';
import {
    AlertTriangle,
    Award,
    Building2,
    CalendarDays,
    CheckCircle2,
    ChevronDown,
    CircleUserRound,
    Layers3,
    Network,
    Target,
} from 'lucide-react';
import { getTaskDetail, getWorkTasks, TaskMarketDTO, WorkTask } from '../../api/marketplace';
import { getSystemList } from '../../api/ops';
import { searchUsers } from '../../api/user';
import { getTaskStageLabel, getTaskStatusLabel, getWorkStatusLabel } from './marketplaceLabels';
import TaskAuditTrail from './TaskAuditTrail';
import TaskVersionMergeRequests from './TaskVersionMergeRequests';

interface ReviewTaskDetailDrawerProps {
    taskId: string | null;
    isOpen: boolean;
    onClose: () => void;
}

interface TaskRelationCardProps {
    item: WorkTask;
    currentTaskId: string;
    assigneeLabels: Record<string, string>;
    systemLabels: Record<string, string>;
}

const formatDateTime = (value?: string) => {
    if (!value) return '-';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
};

const renderSystems = (systemIds: number[] | undefined, systemLabels: Record<string, string>) => {
    if (!systemIds?.length) return '未配置参与系统';
    return systemIds.map(id => systemLabels[String(id)] || `系统 ${id}`).join('、');
};

const TaskRelationCard: React.FC<TaskRelationCardProps> = ({
    item,
    currentTaskId,
    assigneeLabels,
    systemLabels,
}) => {
    const isCurrent = item.id === currentTaskId;
    const isMain = item.taskRole === 'MAIN';
    return (
        <div className={`rounded-xl border p-3.5 ${
            isCurrent ? 'border-blue-300 bg-blue-50/70 shadow-sm' : 'border-slate-200 bg-white'
        }`}>
            <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                    <div className="mb-1.5 flex flex-wrap items-center gap-1.5">
                        <span className={`rounded px-2 py-0.5 text-[11px] font-bold ${
                            isMain ? 'bg-indigo-100 text-indigo-700' : 'bg-slate-100 text-slate-600'
                        }`}>
                            {isMain ? '主任务' : '子任务'}
                        </span>
                        {isCurrent && <span className="rounded bg-blue-600 px-2 py-0.5 text-[11px] font-bold text-white">当前审核</span>}
                        <span className="rounded bg-white px-2 py-0.5 text-[11px] font-bold text-slate-500">
                            {getTaskStatusLabel(item.status)}
                        </span>
                    </div>
                    <div className="truncate text-sm font-bold text-slate-800">{item.title}</div>
                    <div className="mt-1 line-clamp-2 text-xs leading-5 text-slate-500">
                        {item.description || '暂无任务说明'}
                    </div>
                </div>
                <div className="shrink-0 text-right text-xs">
                    <div className="font-bold text-slate-700">{assigneeLabels[item.assigneeId] || item.assigneeId || '未分配'}</div>
                    <div className="mt-1 text-slate-400">{formatDateTime(item.deadline)}</div>
                </div>
            </div>
            <div className="mt-2.5 flex items-center gap-1.5 border-t border-slate-100 pt-2 text-xs text-slate-500">
                <Network size={13} className="shrink-0 text-blue-500" />
                <span className="truncate">{renderSystems(item.involvedSystemIds, systemLabels)}</span>
            </div>
        </div>
    );
};

const ReviewTaskDetailDrawer: React.FC<ReviewTaskDetailDrawerProps> = ({ taskId, isOpen, onClose }) => {
    const [task, setTask] = useState<TaskMarketDTO | null>(null);
    const [relatedTasks, setRelatedTasks] = useState<WorkTask[]>([]);
    const [assigneeLabels, setAssigneeLabels] = useState<Record<string, string>>({});
    const [systemLabels, setSystemLabels] = useState<Record<string, string>>({});
    const [loading, setLoading] = useState(false);
    const [loadError, setLoadError] = useState('');

    useEffect(() => {
        if (!isOpen || !taskId) {
            setTask(null);
            setRelatedTasks([]);
            setLoadError('');
            return;
        }

        let cancelled = false;
        const fetchDetail = async () => {
            setLoading(true);
            setLoadError('');
            try {
                const detail = await getTaskDetail(taskId);
                if (cancelled) return;
                setTask(detail);

                const [taskResult, systemResult] = await Promise.allSettled([
                    getWorkTasks(detail.workId),
                    getSystemList({ showAll: true }),
                ]);
                if (cancelled) return;

                const workTasks = taskResult.status === 'fulfilled' ? taskResult.value || [] : [];
                setRelatedTasks(workTasks);
                setSystemLabels(systemResult.status === 'fulfilled'
                    ? Object.fromEntries((systemResult.value || []).map(system => [String(system.id), system.name]))
                    : {});

                const assigneeIds = Array.from(new Set([
                    detail.assigneeId,
                    ...workTasks.map(item => item.assigneeId),
                ].filter((id): id is string => Boolean(id))));
                const users = await Promise.all(assigneeIds.map(async assigneeId => {
                    if (assigneeId === detail.assigneeId && detail.assigneeName) {
                        return [assigneeId, detail.assigneeName] as const;
                    }
                    try {
                        const matches = await searchUsers(assigneeId);
                        const matched = matches.find(user => String(user.id) === assigneeId) || matches[0];
                        return [assigneeId, matched?.name || assigneeId] as const;
                    } catch {
                        return [assigneeId, assigneeId] as const;
                    }
                }));
                if (!cancelled) setAssigneeLabels(Object.fromEntries(users));
            } catch (error) {
                console.error('Failed to fetch review task detail', error);
                if (!cancelled) {
                    setTask(null);
                    setLoadError('任务详情加载失败，请稍后重试');
                }
            } finally {
                if (!cancelled) setLoading(false);
            }
        };

        fetchDetail();
        return () => {
            cancelled = true;
        };
    }, [isOpen, taskId]);

    const mainTask = useMemo(() => relatedTasks.find(item => item.taskRole === 'MAIN'), [relatedTasks]);
    const subTasks = useMemo(
        () => relatedTasks.filter(item => item.taskRole !== 'MAIN'),
        [relatedTasks]
    );

    const taskRoleLabel = task?.taskRole === 'MAIN' ? '主任务' : '子任务';
    const taskAssignee = task ? (task.assigneeName || assigneeLabels[task.assigneeId] || task.assigneeId || '未分配') : '-';
    const isIssueTrackingTask = ['问题跟踪', '问题追踪'].includes((task?.taskType || '').trim());

    return (
        <Drawer
            title="审核任务详情"
            placement="right"
            onClose={onClose}
            open={isOpen}
            width={920}
        >
            {loading ? (
                <div className="flex h-64 items-center justify-center">
                    <Spin size="large" description="加载中..." />
                </div>
            ) : !task ? (
                <Empty description={loadError || '无法加载任务详情'} />
            ) : (
                <div className="space-y-5 pb-4">
                    <header className="rounded-2xl border border-blue-100 bg-gradient-to-br from-blue-50 via-white to-slate-50 p-5">
                        <div className="mb-3 flex flex-wrap items-center gap-2">
                            <Tag color={task.taskRole === 'MAIN' ? 'purple' : 'blue'}>{taskRoleLabel}</Tag>
                            <Tag color={task.status === 'COMPLETED' ? 'green' : 'orange'}>{getTaskStatusLabel(task.status)}</Tag>
                            {!isIssueTrackingTask && <Tag color="cyan">{getTaskStageLabel(task.currentStage, task.status)}</Tag>}
                            {task.stageRiskReported && <Tag color="warning">已报备风险</Tag>}
                        </div>
                        <h2 className="text-xl font-bold text-slate-900">{task.title}</h2>
                        <div className="mt-3 rounded-xl bg-white/80 px-4 py-3 text-sm leading-6 text-slate-600 shadow-sm">
                            <div className="mb-1 flex items-center gap-2 text-xs font-bold text-blue-700">
                                <Target size={14} /> 这个任务要做什么
                            </div>
                            <div className="whitespace-pre-wrap">{task.description || '暂无任务说明'}</div>
                        </div>
                    </header>

                    <section className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
                        <div className="rounded-xl border border-slate-200 bg-white p-4">
                            <div className="flex items-center gap-2 text-xs text-slate-400"><CircleUserRound size={15} /> 任务负责人</div>
                            <div className="mt-2 font-bold text-slate-800">{taskAssignee}</div>
                            <div className="mt-1 text-xs text-slate-400">{task.assignMode === 'COMPETE' ? '竞标承接' : '指定/直接承接'}</div>
                        </div>
                        <div className="rounded-xl border border-slate-200 bg-white p-4">
                            <div className="flex items-center gap-2 text-xs text-slate-400"><Network size={15} /> 参与系统</div>
                            <div className="mt-2 text-sm font-bold leading-5 text-slate-800">{renderSystems(task.involvedSystemIds, systemLabels)}</div>
                        </div>
                        <div className="rounded-xl border border-slate-200 bg-white p-4">
                            <div className="flex items-center gap-2 text-xs text-slate-400"><CalendarDays size={15} /> 任务时间</div>
                            <div className="mt-2 text-sm font-bold text-slate-800">截止 {formatDateTime(task.deadline)}</div>
                            <div className="mt-1 text-xs text-slate-400">提交 {formatDateTime(task.submittedAt)}</div>
                        </div>
                        <div className="rounded-xl border border-slate-200 bg-white p-4">
                            <div className="flex items-center gap-2 text-xs text-slate-400"><Award size={15} /> 任务量级</div>
                            <div className="mt-2 font-bold text-slate-800">{task.points || 0} 积分</div>
                            <div className="mt-1 text-xs text-slate-400">{task.taskType || '未分类'} / {task.difficulty || '未定难度'}</div>
                        </div>
                    </section>

                    <section className="rounded-2xl border border-slate-200 bg-white p-5">
                        <div className="mb-4 flex items-center justify-between gap-3">
                            <div>
                                <div className="flex items-center gap-2 text-sm font-bold text-slate-800"><Layers3 size={16} className="text-indigo-600" /> 主子任务关系</div>
                                <div className="mt-1 text-xs text-slate-400">明确当前审核任务在整体工作中的位置与责任边界</div>
                            </div>
                            <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-bold text-slate-600">1 主任务 / {subTasks.length} 子任务</span>
                        </div>
                        <div className="space-y-3">
                            {mainTask && (
                                <TaskRelationCard
                                    item={mainTask}
                                    currentTaskId={task.id}
                                    assigneeLabels={assigneeLabels}
                                    systemLabels={systemLabels}
                                />
                            )}
                            {subTasks.length > 0 && (
                                <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
                                    {subTasks.map(item => (
                                        <TaskRelationCard
                                            key={item.id}
                                            item={item}
                                            currentTaskId={task.id}
                                            assigneeLabels={assigneeLabels}
                                            systemLabels={systemLabels}
                                        />
                                    ))}
                                </div>
                            )}
                            {!mainTask && subTasks.length === 0 && <div className="text-sm text-slate-400">暂无主子任务关系数据</div>}
                        </div>
                    </section>

                    <section className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                        <div className="rounded-2xl border border-slate-200 bg-white p-5">
                            <div className="mb-3 flex items-center gap-2 text-sm font-bold text-slate-800"><CheckCircle2 size={16} className="text-emerald-600" /> 验收目标</div>
                            <div className="whitespace-pre-wrap text-sm leading-6 text-slate-600">{task.acceptanceCriteria || '暂无验收标准'}</div>
                        </div>
                        <div className="rounded-2xl border border-slate-200 bg-white p-5">
                            <div className="mb-3 flex items-center gap-2 text-sm font-bold text-slate-800"><Target size={16} className="text-blue-600" /> 完成与交付</div>
                            <div className="space-y-3 text-sm leading-6 text-slate-600">
                                <div><span className="font-bold text-slate-700">完成说明：</span><span className="whitespace-pre-wrap">{task.completionDescription || '-'}</span></div>
                                <div><span className="font-bold text-slate-700">交付物：</span><span className="break-all whitespace-pre-wrap">{task.deliverables || '-'}</span></div>
                                {task.impactScope && <div><span className="font-bold text-slate-700">影响范围：</span>{task.impactScope}</div>}
                            </div>
                        </div>
                    </section>

                    {(task.stageRiskReported || task.stageRiskNote || task.delayReported || task.delayReason) && (
                        <section className="rounded-2xl border border-amber-200 bg-amber-50/60 p-5">
                            <div className="mb-3 flex items-center gap-2 text-sm font-bold text-amber-800"><AlertTriangle size={16} /> 风险与延期</div>
                            <div className="space-y-2 text-sm leading-6 text-amber-900">
                                {(task.stageRiskReported || task.stageRiskNote) && <div className="whitespace-pre-wrap">阶段风险：{task.stageRiskNote || '已报备'}</div>}
                                {(task.delayReported || task.delayReason) && <div className="whitespace-pre-wrap">延期情况：{task.delayReported ? '已报备' : '未报备'}{task.delayReason ? `，${task.delayReason}` : ''}</div>}
                            </div>
                        </section>
                    )}

                    <TaskVersionMergeRequests
                        requirementNumber={task.requirementNumber}
                        assigneeId={task.assigneeId}
                        snapshots={task.versionChangeSnapshots}
                    />

                    <TaskAuditTrail task={task} />

                    <details className="group rounded-2xl border border-slate-200 bg-slate-50/70">
                        <summary className="flex cursor-pointer list-none items-center justify-between gap-3 px-5 py-4">
                            <div>
                                <div className="flex items-center gap-2 text-sm font-bold text-slate-700"><Building2 size={16} /> 所属需求（补充信息）</div>
                                <div className="mt-1 text-xs text-slate-400">{task.workTitle || '未关联需求'}{task.requirementNumber ? ` · ${task.requirementNumber}` : ''}</div>
                            </div>
                            <ChevronDown size={17} className="text-slate-400 transition-transform group-open:rotate-180" />
                        </summary>
                        <div className="grid grid-cols-1 gap-3 border-t border-slate-200 px-5 py-4 text-sm md:grid-cols-2">
                            <div><span className="text-slate-400">需求状态：</span>{getWorkStatusLabel(task.workStatus)}</div>
                            <div><span className="text-slate-400">申请部门 / 申请人：</span>{task.applicationDepartment || '-'} / {task.applicantName || '-'}</div>
                            <div><span className="text-slate-400">归属系统：</span>{task.owningSystem || '-'}</div>
                            <div><span className="text-slate-400">项目类型 / 优先级：</span>{task.projectType || '-'} / {task.workPriority || '-'}</div>
                            <div><span className="text-slate-400">需求截止：</span>{formatDateTime(task.workDeadline)}</div>
                            <div><span className="text-slate-400">需求创建：</span>{formatDateTime(task.workCreateTime)}</div>
                            <div className="md:col-span-2"><span className="text-slate-400">需求描述：</span><span className="whitespace-pre-wrap">{task.workDescription || '-'}</span></div>
                        </div>
                    </details>
                </div>
            )}
        </Drawer>
    );
};

export default ReviewTaskDetailDrawer;
