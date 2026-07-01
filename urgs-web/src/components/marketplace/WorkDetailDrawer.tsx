import React, { useEffect, useState } from 'react';
import { Drawer, Tag, Space, Divider, Typography, Spin, Empty } from 'antd';
import {
    addTaskToWork,
    approveApplication,
    getTaskApplications,
    getWorkDetail,
    getWorkTasks,
    listPointRules,
    MarketplacePointRule,
    rejectApplication,
    TaskApplication,
    Work,
    WorkTask,
} from '../../api/marketplace';
import { Award, CheckCircle2, Clock, Paperclip, Plus, Users, XCircle } from 'lucide-react';
import { getTaskStageLabel, getTaskStatusLabel, getWorkStatusLabel } from './marketplaceLabels';
import { searchUsers, UserDTO } from '../../api/user';

const { Title, Paragraph, Text } = Typography;

const applicationStatusLabel: Record<string, string> = {
    PENDING: '待审批',
    ACCEPTED: '已中标',
    REJECTED: '未中标',
    WITHDRAWN: '已撤回',
};

const applicationStatusColor: Record<string, string> = {
    PENDING: 'orange',
    ACCEPTED: 'green',
    REJECTED: 'default',
    WITHDRAWN: 'default',
};

interface WorkDetailDrawerProps {
    workId: string | null;
    isOpen: boolean;
    onClose: () => void;
}

const WorkDetailDrawer: React.FC<WorkDetailDrawerProps> = ({ workId, isOpen, onClose }) => {
    const [work, setWork] = useState<Work | null>(null);
    const [tasks, setTasks] = useState<WorkTask[]>([]);
    const [loading, setLoading] = useState(false);
    const [addingTask, setAddingTask] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [pointRules, setPointRules] = useState<MarketplacePointRule[]>([]);
    const [bidTask, setBidTask] = useState<WorkTask | null>(null);
    const [applications, setApplications] = useState<TaskApplication[]>([]);
    const [applicationLoading, setApplicationLoading] = useState(false);
    const [assigneeLabels, setAssigneeLabels] = useState<Record<string, string>>({});

    // New task form fields
    const [newTask, setNewTask] = useState({
        title: '',
        description: '',
        taskType: '开发',
        difficulty: '简单',
        points: 5,
        assignMode: 'OPEN' as string,
        requiredSkills: '',
        deadline: '',
    });

    useEffect(() => {
        if (isOpen && workId) {
            fetchDetail(workId);
        } else if (!isOpen) {
            setWork(null);
            setTasks([]);
        }
    }, [isOpen, workId]);

    useEffect(() => {
        if (!isOpen) return;
        listPointRules({ enabled: true })
            .then(res => setPointRules(res || []))
            .catch(error => console.error('Failed to fetch point rules', error));
    }, [isOpen]);

    const taskTypes = Array.from(new Set(['开发', '测试', '数据', '文档', ...pointRules.map(rule => rule.taskType).filter(Boolean)]));
    const difficulties = Array.from(new Set(['简单', '中等', '复杂', ...pointRules.map(rule => rule.difficulty).filter(Boolean)]));
    const suggestedRule = pointRules.find(rule =>
        rule.enabled !== false && rule.taskType === newTask.taskType && rule.difficulty === newTask.difficulty
    );

    const fetchDetail = async (id: string) => {
        setLoading(true);
        try {
            const [workRes, tasksRes] = await Promise.all([
                getWorkDetail(id),
                getWorkTasks(id),
            ]);
            setWork(workRes);
            const nextTasks = tasksRes || [];
            setTasks(nextTasks);
            resolveAssigneeLabels(nextTasks);
        } catch (error) {
            console.error('Failed to fetch work detail', error);
        } finally {
            setLoading(false);
        }
    };

    const formatUserLabel = (user: UserDTO) => `${user.empId || '无工号'} - ${user.name}`;

    const resolveAssigneeLabels = async (nextTasks: WorkTask[]) => {
        const assigneeIds = Array.from(new Set(
            nextTasks
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

    const renderAssignee = (assigneeId?: string) => {
        if (!assigneeId) return '';
        return assigneeLabels[assigneeId] || assigneeId;
    };

    const handleAddTask = async () => {
        if (!newTask.title.trim() || !newTask.description.trim()) return;
        setSubmitting(true);
        try {
            await addTaskToWork(workId!, newTask as any);
            setTasks(prev => [...prev, null!] as any); // Will be refreshed by fetchDetail
            await fetchDetail(workId!);
            setNewTask({ title: '', description: '', taskType: '开发', difficulty: '简单', points: 5, assignMode: 'OPEN', requiredSkills: '', deadline: '' });
            setAddingTask(false);
        } catch (error) {
            console.error('Failed to add task', error);
        } finally {
            setSubmitting(false);
        }
    };

    const openBidDrawer = async (task: WorkTask) => {
        setBidTask(task);
        setApplications([]);
        setApplicationLoading(true);
        try {
            const res = await getTaskApplications(task.id, { current: 1, size: 100 });
            setApplications(res?.records || []);
        } catch (error) {
            console.error('Failed to fetch applications', error);
            alert('加载竞标申请失败');
        } finally {
            setApplicationLoading(false);
        }
    };

    const refreshBidApplications = async () => {
        if (!bidTask) return;
        setApplicationLoading(true);
        try {
            const res = await getTaskApplications(bidTask.id, { current: 1, size: 100 });
            setApplications(res?.records || []);
            if (workId) {
                await fetchDetail(workId);
            }
        } catch (error) {
            console.error('Failed to refresh applications', error);
        } finally {
            setApplicationLoading(false);
        }
    };

    const handleApproveApplication = async (application: TaskApplication) => {
        const comment = window.prompt('审批意见（可选）', '综合匹配度最高，同意承接');
        if (comment === null) return;
        try {
            await approveApplication(application.id, { reviewComment: comment });
            await refreshBidApplications();
        } catch (error) {
            console.error('Failed to approve application', error);
            alert('通过竞标失败，申请可能已被处理');
        }
    };

    const handleRejectApplication = async (application: TaskApplication) => {
        const comment = window.prompt('请填写驳回原因', '与当前任务要求或排期不匹配');
        if (comment === null) return;
        if (!comment.trim()) {
            alert('驳回竞标需要填写原因');
            return;
        }
        try {
            await rejectApplication(application.id, { reviewComment: comment.trim() });
            await refreshBidApplications();
        } catch (error) {
            console.error('Failed to reject application', error);
            alert('驳回竞标失败，申请可能已被处理');
        }
    };

    const renderAttachments = (attachmentsJson?: string) => {
        if (!attachmentsJson) return null;
        try {
            const files = JSON.parse(attachmentsJson);
            if (!Array.isArray(files) || files.length === 0) return null;
            return (
                <div className="mt-2 space-y-2">
                    {files.map((file: any, index: number) => (
                        <a
                            key={index}
                            href={file.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 p-2 bg-slate-50 rounded-lg hover:bg-slate-100 transition-colors border border-slate-100"
                        >
                            <Paperclip size={14} className="text-slate-400" />
                            <span className="text-xs text-blue-600 font-medium truncate">{file.name}</span>
                        </a>
                    ))}
                </div>
            );
        } catch (e) {
            return null;
        }
    };

    const getAssignModeLabel = (mode: string) => {
        const map: Record<string, string> = {
            OPEN: '公开认领',
            ASSIGN: '指定委派',
            COMPETE: '竞争上岗',
        };
        return map[mode] || mode;
    };

    const getAssignModeColor = (mode: string) => {
        const map: Record<string, string> = {
            OPEN: 'green',
            ASSIGN: 'blue',
            COMPETE: 'orange',
        };
        return map[mode] || 'default';
    };

    const getStatusColor = (status: string) => {
        if (status === 'OPEN') return 'green';
        if (status === 'APPLIED') return 'orange';
        if (status === 'ASSIGNED' || status === 'IN_PROGRESS') return 'blue';
        if (status === 'COMPLETED') return 'cyan';
        if (status === 'REJECTED' || status === 'CANCELLED') return 'red';
        return 'default';
    };

    const mainTask = tasks.find(task => task.taskRole === 'MAIN');
    const subTasks = tasks.filter(task => task.taskRole !== 'MAIN');

    return (
        <Drawer
            title="工作详情"
            placement="right"
            onClose={onClose}
            open={isOpen}
            size="large"
        >
            {loading ? (
                <div className="flex justify-center items-center h-64">
                    <Spin size="large" description="加载中..." />
                </div>
            ) : work ? (
                <div className="flex flex-col gap-6">
                    <header>
                        <Space className="mb-2">
                            <Tag color={
                                work.status === 'PUBLISHED' ? 'green' :
                                    work.status === 'DRAFT' ? 'default' : 'red'
                            }>
                                {getWorkStatusLabel(work.status)}
                            </Tag>
                            <Tag color="error">{work.priority}</Tag>
                        </Space>
                        <Title level={3} className="!mb-0">{work.title}</Title>
                        {work.requirementNumber && (
                            <Text type="secondary" className="block mt-1">
                                需求编号: {work.requirementNumber}
                            </Text>
                        )}
                        <div className="flex flex-wrap gap-2 mt-3">
                            {work.applicationDepartment && <Tag>申请部门: {work.applicationDepartment}</Tag>}
                            {work.applicantName && <Tag>申请人: {work.applicantName}</Tag>}
                            {work.owningSystem && <Tag>归属系统: {work.owningSystem}</Tag>}
                            {work.projectType && <Tag color="blue">{work.projectType}</Tag>}
                            {work.primarySystem !== undefined && (
                                <Tag color={work.primarySystem ? 'green' : 'orange'}>
                                    {work.primarySystem ? '主系统' : `非主系统${work.primarySystemName ? ` / 主系统: ${work.primarySystemName}` : ''}`}
                                </Tag>
                            )}
                        </div>
                    </header>

                    <div className="bg-slate-50 p-4 rounded-xl flex items-center justify-around">
                        <div className="text-center">
                            <div className="text-xs text-slate-400 mb-1">总积分</div>
                            <div className="font-black text-xl text-slate-800">{work.totalPoints}</div>
                        </div>
                        <Divider orientation="vertical" className="h-10 border-slate-200" />
                        <div className="text-center">
                            <div className="text-xs text-slate-400 mb-1">子任务数</div>
                            <div className="font-bold text-slate-800">{subTasks.length}</div>
                        </div>
                        <Divider orientation="vertical" className="h-10 border-slate-200" />
                        <div className="text-center">
                            <div className="text-xs text-slate-400 mb-1">截止日期</div>
                            <div className="font-bold text-slate-800">{work.deadline ? new Date(work.deadline).toLocaleDateString() : '无期限'}</div>
                        </div>
                    </div>

                    <section>
                        <Title level={5}>工作描述</Title>
                        <Paragraph className="text-slate-600 whitespace-pre-wrap bg-slate-50/50 p-4 rounded-xl border border-slate-100">
                            {work.description || '暂无详细描述'}
                        </Paragraph>
                    </section>

                    {work.attachments && (
                        <section>
                            <Title level={5}>附件资料</Title>
                            {renderAttachments(work.attachments as any)}
                        </section>
                    )}

                    <Divider className="my-0" />

                    {mainTask && (
                        <section>
                            <Title level={5}>主任务</Title>
                            <div className="bg-red-50/40 rounded-xl border border-red-100 shadow-sm relative overflow-hidden">
                                <div className="absolute top-0 left-0 w-1 h-full bg-red-400" />
                                <div className="p-4 pl-3">
                                    <div className="flex items-start justify-between gap-3">
                                        <div className="min-w-0">
                                            <div className="flex items-center gap-2 mb-1 flex-wrap">
                                                <Tag color="red" className="text-xs">主任务</Tag>
                                                <span className="text-sm font-bold text-slate-800 truncate">{mainTask.title}</span>
                                                <Tag color={getAssignModeColor(mainTask.assignMode)} className="text-xs">{getAssignModeLabel(mainTask.assignMode)}</Tag>
                                                <Tag color={getStatusColor(mainTask.status)} className="text-xs">{getTaskStatusLabel(mainTask.status)}</Tag>
                                                <Tag color="blue" className="text-xs">{getTaskStageLabel(mainTask.currentStage)}</Tag>
                                                {mainTask.stageRiskReported && <Tag color="warning" className="text-xs">已报备风险</Tag>}
                                            </div>
                                            <div className="flex items-center gap-4 text-xs text-slate-500 flex-wrap">
                                                <span className="flex items-center gap-1">
                                                    <Award size={12} /> {mainTask.points} 积分
                                                </span>
                                                {mainTask.assigneeId && <span>负责人: {renderAssignee(mainTask.assigneeId)}</span>}
                                                {mainTask.deadline && (
                                                    <span className="flex items-center gap-1">
                                                        <Clock size={12} /> {new Date(mainTask.deadline).toLocaleDateString()}
                                                    </span>
                                                )}
                                            </div>
                                            {mainTask.description && (
                                                <p className="text-xs text-slate-500 mt-2 line-clamp-2">{mainTask.description}</p>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </section>
                    )}

                    <section>
                        <div className="flex items-center justify-between mb-4">
                            <Title level={5} className="!mb-0">子任务 ({subTasks.length})</Title>
                            {work.status !== 'COMPLETED' && work.status !== 'CANCELLED' && (
                                <button
                                    onClick={() => setAddingTask(true)}
                                    className="flex items-center gap-1.5 text-sm font-medium text-red-600 hover:text-red-700 hover:bg-red-50 px-3 py-1.5 rounded-md transition-colors"
                                >
                                    <Plus size={16} /> 添加任务
                                </button>
                            )}
                        </div>

                        {subTasks.length === 0 && !addingTask ? (
                            <div className="text-center py-8 text-slate-400 bg-slate-50 rounded-xl border border-dashed border-slate-200">
                                暂无子任务，点击右上角添加第一个子任务吧。
                            </div>
                        ) : (
                            <div className="space-y-3">
                                {subTasks.map((task, index) => (
                                    task && (
                                        <div key={task.id} className="bg-white rounded-xl border border-slate-200 shadow-sm relative group overflow-hidden">
                                            <div className="absolute top-0 left-0 w-1 h-full bg-slate-200 group-hover:bg-red-400 transition-colors" />
                                            <div className="p-4 pl-3">
                                                <div className="flex items-start justify-between gap-3">
                                                    <div className="flex items-start gap-3 flex-1 min-w-0">
                                                        <span className="bg-slate-100 text-slate-500 w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold shrink-0 mt-0.5">
                                                            {index + 1}
                                                        </span>
                                                        <div className="flex-1 min-w-0">
                                                            <div className="flex items-center gap-2 mb-1 flex-wrap">
                                                                <span className="text-sm font-bold text-slate-800 truncate">{task.title}</span>
                                                                <Tag color={getAssignModeColor(task.assignMode)} className="text-xs">{getAssignModeLabel(task.assignMode)}</Tag>
                                                                <Tag color={getStatusColor(task.status)} className="text-xs">{getTaskStatusLabel(task.status)}</Tag>
                                                                <Tag color="blue" className="text-xs">{getTaskStageLabel(task.currentStage)}</Tag>
                                                                {task.stageRiskReported && <Tag color="warning" className="text-xs">已报备风险</Tag>}
                                                            </div>
                                                            <div className="flex items-center gap-4 text-xs text-slate-500 flex-wrap">
                                                                <span className="flex items-center gap-1">
                                                                    <Award size={12} /> {task.points} 积分
                                                                </span>
                                                                {task.taskType && (
                                                                    <span>{task.taskType}{task.difficulty ? `/${task.difficulty}` : ''}</span>
                                                                )}
                                                                {task.deadline && (
                                                                    <span className="flex items-center gap-1">
                                                                        <Clock size={12} /> {new Date(task.deadline).toLocaleDateString()}
                                                                    </span>
                                                                )}
                                                                {task.requiredSkills && (
                                                                    <span className="truncate max-w-[200px]">技能: {task.requiredSkills}</span>
                                                                )}
                                                            </div>
                                                        </div>
                                                    </div>
                                                    {task.assignMode === 'COMPETE' && (
                                                        <button
                                                            onClick={() => openBidDrawer(task)}
                                                            className="shrink-0 inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold text-amber-700 bg-amber-50 hover:bg-amber-100 rounded-lg"
                                                        >
                                                            <Users size={13} /> 管理竞标
                                                        </button>
                                                    )}
                                                </div>
                                                {task.description && (
                                                    <p className="text-xs text-slate-500 mt-2 ml-9 line-clamp-2">{task.description}</p>
                                                )}
                                            </div>
                                        </div>
                                    )
                                ))}

                                {addingTask && (
                                    <div className="bg-slate-50 rounded-xl border border-dashed border-slate-300 p-4 space-y-3">
                                        <div className="grid grid-cols-2 gap-3">
                                            <div>
                                                <input
                                                    value={newTask.title}
                                                    onChange={e => setNewTask(prev => ({ ...prev, title: e.target.value }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 focus:border-red-500 outline-none"
                                                    placeholder="任务标题 *"
                                                />
                                            </div>
                                            <div className="grid grid-cols-2 gap-2">
                                                <select
                                                    value={newTask.taskType}
                                                    onChange={e => setNewTask(prev => ({ ...prev, taskType: e.target.value }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none bg-white"
                                                >
                                                    {taskTypes.map(type => <option value={type} key={type}>{type}</option>)}
                                                </select>
                                                <select
                                                    value={newTask.difficulty}
                                                    onChange={e => setNewTask(prev => ({ ...prev, difficulty: e.target.value }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none bg-white"
                                                >
                                                    {difficulties.map(item => <option value={item} key={item}>{item}</option>)}
                                                </select>
                                                <select
                                                    value={newTask.assignMode}
                                                    onChange={e => setNewTask(prev => ({ ...prev, assignMode: e.target.value }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none bg-white"
                                                >
                                                    <option value="OPEN">公开认领</option>
                                                    <option value="COMPETE">竞争上岗</option>
                                                    <option value="ASSIGN">指定委派</option>
                                                </select>
                                                <input
                                                    type="number"
                                                    value={newTask.points}
                                                    onChange={e => setNewTask(prev => ({ ...prev, points: parseInt(e.target.value) || 0 }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none"
                                                    placeholder={suggestedRule ? `建议 ${suggestedRule.suggestedPoints}` : '积分'}
                                                />
                                            </div>
                                            {suggestedRule && (
                                                <button
                                                    type="button"
                                                    onClick={() => setNewTask(prev => ({ ...prev, points: suggestedRule.suggestedPoints }))}
                                                    className="text-xs font-bold text-red-600 hover:text-red-700"
                                                >
                                                    套用 {newTask.taskType}/{newTask.difficulty} 建议积分 {suggestedRule.suggestedPoints}
                                                </button>
                                            )}
                                        </div>
                                        <textarea
                                            value={newTask.description}
                                            onChange={e => setNewTask(prev => ({ ...prev, description: e.target.value }))}
                                            rows={2}
                                            className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none resize-none"
                                            placeholder="任务描述 *"
                                        />
                                        <div className="grid grid-cols-2 gap-3">
                                            <input
                                                value={newTask.requiredSkills}
                                                onChange={e => setNewTask(prev => ({ ...prev, requiredSkills: e.target.value }))}
                                                className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none"
                                                placeholder="技能要求（可选）"
                                            />
                                            <input
                                                type="date"
                                                value={newTask.deadline}
                                                onChange={e => setNewTask(prev => ({ ...prev, deadline: e.target.value }))}
                                                className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none"
                                            />
                                        </div>
                                        <div className="flex justify-end gap-2">
                                            <button
                                                onClick={() => { setAddingTask(false); setNewTask({ title: '', description: '', taskType: '开发', difficulty: '简单', points: 5, assignMode: 'OPEN', requiredSkills: '', deadline: '' }); }}
                                                className="px-4 py-1.5 text-sm font-medium text-slate-600 bg-white hover:bg-slate-100 rounded-lg transition-colors"
                                            >
                                                取消
                                            </button>
                                            <button
                                                onClick={handleAddTask}
                                                disabled={submitting || !newTask.title.trim() || !newTask.description.trim()}
                                                className="px-4 py-1.5 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                            >
                                                {submitting ? '添加中...' : '确认添加'}
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}
                    </section>
                </div>
            ) : (
                <Empty description="无法加载详情" />
            )}

            <Drawer
                title={bidTask ? `竞标审批：${bidTask.title}` : '竞标审批'}
                placement="right"
                onClose={() => setBidTask(null)}
                open={!!bidTask}
                width={620}
            >
                {applicationLoading ? (
                    <div className="h-40 flex items-center justify-center text-slate-400">加载竞标申请...</div>
                ) : applications.length === 0 ? (
                    <Empty description="暂无竞标申请" />
                ) : (
                    <div className="space-y-4">
                        {applications.map(application => (
                            <div key={application.id} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                                <div className="flex items-start justify-between gap-3 mb-3">
                                    <div className="min-w-0">
                                        <div className="flex items-center gap-2 flex-wrap">
                                            <span className="font-black text-slate-800">{application.applicantName || application.applicantId}</span>
                                            <Tag color={applicationStatusColor[application.status] || 'default'}>
                                                {applicationStatusLabel[application.status] || application.status}
                                            </Tag>
                                        </div>
                                        <div className="text-xs text-slate-500 mt-1">
                                            当前负载 {application.currentLoad || 0} · 历史完成 {application.completedTaskCount || 0} ·
                                            质量 {application.averageQualityScore || 0} · 准时 {application.onTimeRate || 0}% ·
                                            累计积分 {application.finalPoints || 0}
                                        </div>
                                    </div>
                                    {application.status === 'PENDING' && (
                                        <div className="flex gap-2 shrink-0">
                                            <button
                                                onClick={() => handleApproveApplication(application)}
                                                className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-green-700 bg-green-50 hover:bg-green-100 rounded-lg"
                                            >
                                                <CheckCircle2 size={13} /> 通过
                                            </button>
                                            <button
                                                onClick={() => handleRejectApplication(application)}
                                                className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-red-700 bg-red-50 hover:bg-red-100 rounded-lg"
                                            >
                                                <XCircle size={13} /> 驳回
                                            </button>
                                        </div>
                                    )}
                                </div>

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">申请理由</div>
                                        <div className="text-slate-500 whitespace-pre-wrap">{application.message || '-'}</div>
                                    </div>
                                    <div className="bg-slate-50 rounded-lg p-3">
                                        <div className="font-bold text-slate-700 mb-1">预计完成时间</div>
                                        <div className="text-slate-500">
                                            {application.expectedCompletionTime ? new Date(application.expectedCompletionTime).toLocaleString() : '-'}
                                        </div>
                                    </div>
                                </div>

                                <div className="bg-slate-50 rounded-lg p-3 mt-3 text-xs">
                                    <div className="font-bold text-slate-700 mb-1">实施方案</div>
                                    <div className="text-slate-500 whitespace-pre-wrap">{application.solution || '-'}</div>
                                </div>

                                {application.reviewComment && (
                                    <div className="bg-amber-50 rounded-lg p-3 mt-3 text-xs text-amber-700">
                                        审批意见：{application.reviewComment}
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                )}
            </Drawer>
        </Drawer>
    );
};

export default WorkDetailDrawer;
