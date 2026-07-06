import React, { useEffect, useRef, useState } from 'react';
import { Drawer, Tag, Space, Divider, Typography, Spin, Empty, Modal, Progress } from 'antd';
import {
    addTaskToWork,
    appendTaskRiskTracking,
    approveApplication,
    AssetMaintenanceRecord,
    getTaskDetail,
    getTaskApplications,
    getWorkDetail,
    getWorkTasks,
    listAssetMaintenanceRecords,
    listPointRules,
    MarketplacePointRule,
    rejectApplication,
    TaskApplication,
    Work,
    WorkTask,
} from '../../api/marketplace';
import { Award, CheckCircle2, ChevronDown, ChevronUp, Clock, Eye, Paperclip, Plus, Users, XCircle } from 'lucide-react';
import { getTaskStageLabel, getTaskStatusLabel, getWorkStatusLabel } from './marketplaceLabels';
import { searchUsers, UserDTO } from '../../api/user';
import UserSelect from './UserSelect';
import TaskAuditTrail from './TaskAuditTrail';
import AssetObjectDetailLink from './AssetObjectDetailLink';

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
    focusTaskId?: string;
    focusMode?: 'applications';
    focusKey?: number;
}

const WorkDetailDrawer: React.FC<WorkDetailDrawerProps> = ({ workId, isOpen, onClose, focusTaskId, focusMode, focusKey }) => {
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
    const [assigneeNames, setAssigneeNames] = useState<Record<string, string>>({});
    const [detailTask, setDetailTask] = useState<WorkTask | null>(null);
    const [workAssetRecords, setWorkAssetRecords] = useState<AssetMaintenanceRecord[]>([]);
    const [assetSummaryExpanded, setAssetSummaryExpanded] = useState(false);
    const [trackingOpen, setTrackingOpen] = useState(false);
    const [trackingTaskId, setTrackingTaskId] = useState('');
    const [trackingNote, setTrackingNote] = useState('');
    const [trackingSubmitting, setTrackingSubmitting] = useState(false);
    const appliedFocusKeyRef = useRef<number | undefined>(undefined);

    // New task form fields
    const [newTask, setNewTask] = useState({
        title: '',
        description: '',
        taskType: '开发',
        difficulty: '简单',
        points: 5,
        assignMode: 'ASSIGN' as string,
        assigneeId: '',
        requiredSkills: '',
        deadline: '',
    });

    useEffect(() => {
        if (isOpen && workId) {
            setAssetSummaryExpanded(false);
            fetchDetail(workId);
        } else if (!isOpen) {
            setWork(null);
            setTasks([]);
            setWorkAssetRecords([]);
            setAssigneeNames({});
            setAssetSummaryExpanded(false);
            setTrackingOpen(false);
            setTrackingTaskId('');
            setTrackingNote('');
            setTrackingSubmitting(false);
        }
    }, [isOpen, workId]);

    useEffect(() => {
        if (!isOpen) return;
        listPointRules({ enabled: true })
            .then(res => setPointRules(res || []))
            .catch(error => console.error('Failed to fetch point rules', error));
    }, [isOpen]);

    const taskTypes = Array.from(new Set(['开发', '测试', '数据', '文档', '问题跟踪', ...pointRules.map(rule => rule.taskType).filter(Boolean)]));
    const difficulties = Array.from(new Set(['简单', '中等', '复杂', ...pointRules.map(rule => rule.difficulty).filter(Boolean)]));
    const suggestedRule = pointRules.find(rule =>
        rule.enabled !== false && rule.taskType === newTask.taskType && rule.difficulty === newTask.difficulty
    );

    useEffect(() => {
        if (suggestedRule) {
            setNewTask(prev => ({ ...prev, points: suggestedRule.suggestedPoints }));
        }
    }, [newTask.taskType, newTask.difficulty, suggestedRule?.suggestedPoints]);

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
            loadWorkAssetRecords(workRes.requirementNumber);
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
            setAssigneeNames({});
            return;
        }

        const entries = await Promise.all(assigneeIds.map(async (assigneeId) => {
            try {
                const users = await searchUsers(assigneeId);
                const matchedUser = users.find(user => user.id.toString() === assigneeId) || users[0];
                return {
                    assigneeId,
                    label: matchedUser ? formatUserLabel(matchedUser) : assigneeId,
                    name: matchedUser?.name || '',
                };
            } catch (error) {
                return { assigneeId, label: assigneeId, name: '' };
            }
        }));
        setAssigneeLabels(Object.fromEntries(entries.map(entry => [entry.assigneeId, entry.label])));
        setAssigneeNames(Object.fromEntries(entries.map(entry => [entry.assigneeId, entry.name])));
    };

    const renderAssignee = (assigneeId?: string) => {
        if (!assigneeId) return '';
        return assigneeLabels[assigneeId] || assigneeId;
    };

    const loadWorkAssetRecords = async (requirementNumber?: string) => {
        const reqId = (requirementNumber || '').trim();
        if (!reqId) {
            setWorkAssetRecords([]);
            return;
        }
        try {
            let response = await listAssetMaintenanceRecords({ reqId, page: 1, size: 100 });
            let records = response?.records || [];
            if ((response?.total || 0) > records.length) {
                response = await listAssetMaintenanceRecords({ reqId, page: 1, size: response.total });
                records = response?.records || [];
            }
            setWorkAssetRecords(records.filter(record => {
                const recordReqId = (record.reqId || '').trim();
                return recordReqId.includes(reqId);
            }));
        } catch (error) {
            console.error('Failed to fetch work asset maintenance records', error);
            setWorkAssetRecords([]);
        }
    };

    const getTaskAssetRecords = (task: WorkTask) => {
        let records: AssetMaintenanceRecord[];
        if (task.assetMaintenanceSnapshot) {
            try {
                const snapshotRecords = JSON.parse(task.assetMaintenanceSnapshot);
                records = Array.isArray(snapshotRecords) ? snapshotRecords as AssetMaintenanceRecord[] : [];
            } catch {
                return [];
            }
        } else {
            records = workAssetRecords;
        }
        const assigneeName = assigneeNames[task.assigneeId]?.trim().toLowerCase();
        if (!assigneeName) return [];
        return records.filter(record => record.operator?.trim().toLowerCase() === assigneeName);
    };

    const getTaskAssetRecordCount = (task: WorkTask) => getTaskAssetRecords(task).length;

    const openTrackingModal = () => {
        const firstTask = tasks.find(task => task.status !== 'CANCELLED');
        setTrackingTaskId(firstTask?.id || '');
        setTrackingNote('');
        setTrackingOpen(true);
    };

    const closeTrackingModal = () => {
        setTrackingOpen(false);
        setTrackingTaskId('');
        setTrackingNote('');
        setTrackingSubmitting(false);
    };

    const submitTrackingNote = async () => {
        if (!trackingTaskId || !trackingNote.trim() || !workId) return;
        setTrackingSubmitting(true);
        try {
            await appendTaskRiskTracking(trackingTaskId, { trackingNote: trackingNote.trim() });
            closeTrackingModal();
            await fetchDetail(workId);
        } catch (error) {
            alert('追加跟踪记录失败');
            setTrackingSubmitting(false);
        }
    };

    const openTaskDetail = async (task: WorkTask) => {
        setDetailTask(task);
        try {
            const detail = await getTaskDetail(task.id);
            setDetailTask(detail);
        } catch (error) {
            console.error('Failed to fetch task audit detail', error);
        }
    };

    const handleAddTask = async () => {
        if (!newTask.title.trim() || !newTask.description.trim()) return;
        if (newTask.assignMode === 'ASSIGN' && !newTask.assigneeId) return;
        setSubmitting(true);
        try {
            await addTaskToWork(workId!, newTask as any);
            setTasks(prev => [...prev, null!] as any); // Will be refreshed by fetchDetail
            await fetchDetail(workId!);
            setNewTask({ title: '', description: '', taskType: '开发', difficulty: '简单', points: 5, assignMode: 'ASSIGN', assigneeId: '', requiredSkills: '', deadline: '' });
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

    useEffect(() => {
        if (!isOpen) {
            appliedFocusKeyRef.current = undefined;
            return;
        }
        if (!focusKey || appliedFocusKeyRef.current === focusKey) return;
        if (focusMode !== 'applications' || !focusTaskId || tasks.length === 0) return;

        const targetTask = tasks.find(task => task.id === focusTaskId);
        if (!targetTask) return;

        appliedFocusKeyRef.current = focusKey;
        openBidDrawer(targetTask);
    }, [focusKey, focusMode, focusTaskId, isOpen, tasks]);

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
            ASSIGN: '直接分派',
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
        if (status === 'READY' || status === 'IN_PROGRESS') return 'blue';
        if (status === 'PAUSED') return 'warning';
        if (status === 'WAITING_REVIEW') return 'orange';
        if (status === 'COMPLETED') return 'cyan';
        if (status === 'REWORK' || status === 'CANCELLED') return 'red';
        return 'default';
    };

    const getWorkStatusColor = (status: string) => {
        if (status === 'COMPLETED') return 'green';
        if (status === 'ACTIVE') return 'blue';
        if (status === 'ACCEPTANCE') return 'orange';
        if (status === 'PAUSED') return 'warning';
        if (status === 'CANCELLED') return 'red';
        if (status === 'PUBLISHED') return 'cyan';
        return 'default';
    };

    const isIssueTrackingTask = (task?: WorkTask | null) => {
        const taskType = (task?.taskType || '').trim();
        return taskType === '问题跟踪' || taskType === '问题追踪';
    };

    const getModTypeLabel = (modType?: string) => {
        if (modType === 'CREATE') return '新增资产';
        if (modType === 'UPDATE') return '修改调整';
        if (modType === 'DELETE') return '删除资产';
        return modType || '-';
    };

    const formatDateTime = (value?: string) => value ? new Date(value).toLocaleString() : '-';
    const renderDetailValue = (value?: string | number | null) => value === undefined || value === null || value === '' ? '-' : value;

    const mainTask = tasks.find(task => task.taskRole === 'MAIN');
    const subTasks = tasks.filter(task => task.taskRole !== 'MAIN');
    const completedTaskCount = tasks.filter(task => task.status === 'COMPLETED').length;
    const activeTaskCount = tasks.filter(task =>
        ['IN_PROGRESS', 'WAITING_REVIEW', 'REWORK'].includes(task.status)
    ).length;
    const pausedTaskCount = tasks.filter(task => task.status === 'PAUSED').length;
    const closedTaskCount = tasks.filter(task => task.status === 'CANCELLED').length;
    const pendingTaskCount = Math.max(tasks.length - completedTaskCount - activeTaskCount - pausedTaskCount - closedTaskCount, 0);
    const progressBase = Math.max(tasks.length - closedTaskCount, 0);
    const taskProgress = progressBase === 0 ? 0 : Math.round((completedTaskCount / progressBase) * 100);
    const riskTasks = tasks.filter(task => task.stageRiskReported || task.stageRiskNote);
    const participantNames = Array.from(new Set(
        tasks
            .map(task => renderAssignee(task.assigneeId))
            .filter(Boolean)
    ));
    const snapshotAssetRecords = tasks.flatMap(task => task.assetMaintenanceSnapshot
        ? getTaskAssetRecords(task)
        : []);
    const matchedWorkAssetRecords = workAssetRecords.filter(record => tasks.some(task => {
        const assigneeName = assigneeNames[task.assigneeId]?.trim().toLowerCase();
        return assigneeName && record.operator?.trim().toLowerCase() === assigneeName;
    }));
    const workSummaryRecordMap = new Map<string, AssetMaintenanceRecord>();
    (matchedWorkAssetRecords.length > 0 ? matchedWorkAssetRecords : snapshotAssetRecords).forEach((record, index) => {
        const key = record.id || [
            record.systemCode || '',
            record.tableName || record.tableCnName || '',
            record.fieldName || record.fieldCnName || '',
            record.modType || '',
            record.time || '',
            record.description || '',
            index,
        ].join('|');
        workSummaryRecordMap.set(key, record);
    });
    const workSummaryRecords = Array.from(workSummaryRecordMap.values());
    const associatedAssetCount = new Set(workSummaryRecords.map(record => [
        record.systemCode || '',
        record.tableName || record.tableCnName || '',
        record.fieldName || record.fieldCnName || '',
    ].join('|'))).size;
    const createdAssetCount = workSummaryRecords.filter(record => record.modType === 'CREATE').length;
    const updatedAssetCount = workSummaryRecords.filter(record => record.modType === 'UPDATE').length;
    const deletedAssetCount = workSummaryRecords.filter(record => record.modType === 'DELETE').length;
    const involvedSystems = Array.from(new Set(
        workSummaryRecords
            .map(record => record.systemCode)
            .filter((value): value is string => Boolean(value))
    ));
    const involvedPeople = Array.from(new Set(
        workSummaryRecords
            .map(record => record.operator)
            .filter((value): value is string => Boolean(value))
    ));

    return (
        <Modal
            title="工作详情"
            open={isOpen}
            onCancel={onClose}
            footer={null}
            width="100vw"
            style={{ top: 0, paddingBottom: 0 }}
            className="!max-w-none [&_.ant-modal-content]:h-screen [&_.ant-modal-content]:rounded-none"
            styles={{
                body: { height: 'calc(100vh - 55px)', overflowY: 'auto', padding: 24 },
            }}
            destroyOnHidden
        >
            {loading ? (
                <div className="flex justify-center items-center h-64">
                    <Spin size="large" description="加载中..." />
                </div>
            ) : work ? (
                <div className="mx-auto flex max-w-[1500px] flex-col gap-6">
                    <header>
                        <Space className="mb-2">
                            <Tag color={getWorkStatusColor(work.status)}>
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
                            {participantNames.length > 0 && (
                                <Tag color="purple">参与人: {participantNames.join('、')}</Tag>
                            )}
                        </div>
                    </header>

                    <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_460px]">
                        <div className="flex items-center justify-around rounded-xl bg-slate-50 p-4">
                            <div className="text-center">
                                <div className="mb-1 text-xs text-slate-400">总积分</div>
                                <div className="text-xl font-black text-slate-800">{work.totalPoints}</div>
                            </div>
                            <Divider orientation="vertical" className="h-10 border-slate-200" />
                            <div className="text-center">
                                <div className="mb-1 text-xs text-slate-400">任务总数</div>
                                <div className="font-bold text-slate-800">{tasks.length}</div>
                            </div>
                            <Divider orientation="vertical" className="h-10 border-slate-200" />
                            <div className="text-center">
                                <div className="mb-1 text-xs text-slate-400">截止日期</div>
                                <div className="font-bold text-slate-800">{work.deadline ? new Date(work.deadline).toLocaleDateString() : '无期限'}</div>
                            </div>
                        </div>
                        <div className="rounded-xl border border-slate-200 bg-white px-4 py-3">
                            <div className="mb-2 flex items-center justify-between">
                                <span className="text-sm font-bold text-slate-800">任务进度</span>
                                <span className="text-xs text-slate-400">
                                    已完成 {completedTaskCount} / {progressBase}
                                </span>
                            </div>
                            <Progress percent={taskProgress} size="small" strokeColor="#2563eb" trailColor="#e2e8f0" />
                            <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-500">
                                <span>进行中 {activeTaskCount}</span>
                                <span>待开始 {pendingTaskCount}</span>
                                <span>暂停中 {pausedTaskCount}</span>
                                {closedTaskCount > 0 && <span>已关闭 {closedTaskCount}</span>}
                            </div>
                        </div>
                    </div>

                    <section>
                        <Title level={5}>工作描述</Title>
                        <Paragraph className="text-slate-600 whitespace-pre-wrap bg-slate-50/50 p-4 rounded-xl border border-slate-100">
                            {work.description || '暂无详细描述'}
                        </Paragraph>
                    </section>

                    <section className="overflow-hidden rounded-xl border border-slate-200 bg-white">
                        <button
                            type="button"
                            onClick={() => setAssetSummaryExpanded(expanded => !expanded)}
                            className="flex w-full items-center justify-between gap-4 px-4 py-3 text-left hover:bg-slate-50"
                        >
                            <div>
                                <Title level={5} className="!mb-0">工作资产变更汇总</Title>
                                <div className="mt-1 text-xs text-slate-400">
                                    {work.requirementNumber ? `需求编号 ${work.requirementNumber} + 任务承接人` : '按工作任务汇总'}
                                </div>
                            </div>
                            <div className="flex shrink-0 items-center gap-3">
                                <span className="rounded bg-cyan-50 px-2.5 py-1 text-xs font-bold text-cyan-700">
                                    {workSummaryRecords.length} 条变更
                                </span>
                                <span className="inline-flex items-center gap-1 text-xs font-bold text-slate-500">
                                    {assetSummaryExpanded ? '收起详情' : '展开详情'}
                                    {assetSummaryExpanded ? <ChevronUp size={15} /> : <ChevronDown size={15} />}
                                </span>
                            </div>
                        </button>

                        <div className="border-t border-slate-100 bg-slate-50/70 px-4 py-3">
                            <div className="flex flex-wrap gap-2 text-xs">
                                <span className="rounded bg-blue-50 px-2 py-1 font-bold text-blue-700">关联资产 {associatedAssetCount}</span>
                                <span className="rounded bg-green-50 px-2 py-1 font-bold text-green-700">新增 {createdAssetCount}</span>
                                <span className="rounded bg-orange-50 px-2 py-1 font-bold text-orange-700">修改 {updatedAssetCount}</span>
                                <span className="rounded bg-red-50 px-2 py-1 font-bold text-red-700">删除 {deletedAssetCount}</span>
                            </div>
                            <div className="mt-2 grid gap-2 text-xs text-slate-500 md:grid-cols-2">
                                <div className="truncate">
                                    <span className="font-bold text-slate-600">涉及系统：</span>
                                    {involvedSystems.length > 0 ? involvedSystems.join('、') : '暂无'}
                                </div>
                                <div className="truncate">
                                    <span className="font-bold text-slate-600">涉及人员：</span>
                                    {involvedPeople.length > 0 ? involvedPeople.join('、') : '暂无'}
                                </div>
                            </div>
                        </div>

                        {assetSummaryExpanded && (
                            <div className="space-y-4 border-t border-slate-200 p-4">
                                <div className="overflow-hidden rounded-lg border border-slate-200">
                                    <div className="border-b border-slate-200 bg-slate-50 px-4 py-2 text-sm font-bold text-slate-700">
                                        各任务汇总
                                    </div>
                                    <div className="overflow-x-auto">
                                        <table className="w-full min-w-[720px] text-xs">
                                            <thead className="bg-white text-slate-400">
                                                <tr>
                                                    <th className="px-4 py-2 text-left">任务</th>
                                                    <th className="px-4 py-2 text-left">状态 / 阶段</th>
                                                    <th className="px-4 py-2 text-left">资产变更记录</th>
                                                    <th className="px-4 py-2 text-left">数据口径</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {tasks.map(task => (
                                                    <tr key={task.id} className="border-t border-slate-100">
                                                        <td className="px-4 py-2.5">
                                                            <div className="font-bold text-slate-700">{task.title}</div>
                                                            <div className="mt-0.5 text-slate-400">
                                                                {task.taskRole === 'MAIN' ? '主任务' : '子任务'}
                                                            </div>
                                                        </td>
                                                        <td className="px-4 py-2.5 text-slate-600">
                                                            {getTaskStatusLabel(task.status)}
                                                            {!isIssueTrackingTask(task) ? ` / ${getTaskStageLabel(task.currentStage)}` : ''}
                                                        </td>
                                                        <td className="px-4 py-2.5 font-bold text-cyan-700">
                                                            {getTaskAssetRecordCount(task)} 条
                                                        </td>
                                                        <td className="px-4 py-2.5 text-slate-500">
                                                            {task.assetMaintenanceSnapshot ? '审核固化快照' : '需求编号 + 承接人实时匹配'}
                                                        </td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                </div>

                                {workSummaryRecords.length === 0 ? (
                                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="当前工作暂无资产变更记录" />
                                ) : (
                                    <div className="overflow-x-auto rounded-lg border border-slate-200">
                                        <table className="w-full min-w-[900px] text-xs">
                                            <thead className="bg-slate-50 text-slate-500">
                                                <tr>
                                                    <th className="px-3 py-2 text-left">变更类型</th>
                                                    <th className="px-3 py-2 text-left">资产对象</th>
                                                    <th className="px-3 py-2 text-left">系统</th>
                                                    <th className="px-3 py-2 text-left">操作信息</th>
                                                    <th className="px-3 py-2 text-left">变更说明</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {workSummaryRecords.map((record, index) => (
                                                    <tr key={record.id || `${record.reqId || 'asset'}-${index}`} className="border-t border-slate-100 align-top">
                                                        <td className="whitespace-nowrap px-3 py-3 font-bold text-cyan-700">
                                                            {getModTypeLabel(record.modType)}
                                                        </td>
                                                        <td className="min-w-[220px] px-3 py-3">
                                                            <AssetObjectDetailLink record={record} className="hover:bg-blue-50/60">
                                                                <div className="font-bold text-slate-700">
                                                                    {record.tableCnName || record.tableName || '-'}
                                                                </div>
                                                                <div className="mt-1 font-mono text-slate-400">{record.tableName || '-'}</div>
                                                                {(record.fieldName || record.fieldCnName) && (
                                                                    <div className="mt-1 text-slate-500">
                                                                        字段：{record.fieldCnName || record.fieldName}
                                                                        {record.fieldName && record.fieldCnName ? ` (${record.fieldName})` : ''}
                                                                    </div>
                                                                )}
                                                            </AssetObjectDetailLink>
                                                        </td>
                                                        <td className="px-3 py-3 text-slate-600">{record.systemCode || '-'}</td>
                                                        <td className="min-w-[150px] px-3 py-3 text-slate-600">
                                                            <div>{record.operator || '-'}</div>
                                                            <div className="mt-1 text-slate-400">{formatDateTime(record.time)}</div>
                                                        </td>
                                                        <td className="min-w-[260px] whitespace-pre-wrap px-3 py-3 text-slate-600">
                                                            {record.description || '-'}
                                                        </td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                )}
                            </div>
                        )}
                    </section>

                    {work.attachments && (
                        <section>
                            <Title level={5}>附件资料</Title>
                            {renderAttachments(work.attachments as any)}
                        </section>
                    )}

                    <Divider className="my-0" />

                    <section>
                        <div className="mb-3 flex flex-wrap items-center justify-between gap-3">
                            <div className="flex items-center gap-2">
                                <Title level={5} className="!mb-0">任务风险及跟踪记录</Title>
                                <span className="text-xs text-slate-400">{riskTasks.length} 条</span>
                            </div>
                            <button
                                type="button"
                                onClick={openTrackingModal}
                                disabled={!tasks.some(task => task.status !== 'CANCELLED')}
                                className="inline-flex items-center gap-1.5 rounded-md border border-amber-200 bg-amber-50 px-2.5 py-1.5 text-xs font-bold text-amber-700 transition-colors hover:bg-amber-100 disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                <Plus size={12} /> 追加
                            </button>
                        </div>
                        {riskTasks.length === 0 ? (
                            <div className="rounded-md bg-slate-50 px-3 py-3 text-xs text-slate-400">暂无风险及跟踪记录</div>
                        ) : (
                            <div className="divide-y divide-slate-100 rounded-lg border border-slate-200 bg-white">
                                {riskTasks.map(task => (
                                    <div key={task.id} className="px-4 py-3 text-xs">
                                        <div className="mb-1 flex flex-wrap items-center gap-2">
                                            <span className="font-bold text-slate-800">{task.title}</span>
                                            {!isIssueTrackingTask(task) && (
                                                <Tag color="blue" className="text-xs">{getTaskStageLabel(task.currentStage)}</Tag>
                                            )}
                                            <span className="text-slate-500">负责人：{renderAssignee(task.assigneeId) || '-'}</span>
                                        </div>
                                        <div className="whitespace-pre-wrap break-words leading-5 text-slate-600">
                                            {task.stageRiskNote || '已报备'}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </section>

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
                                                <button
                                                    type="button"
                                                    onClick={() => openTaskDetail(mainTask)}
                                                    className="text-sm font-bold text-slate-800 hover:text-red-600 truncate text-left"
                                                >
                                                    {mainTask.title}
                                                </button>
                                                <Tag color={getAssignModeColor(mainTask.assignMode)} className="text-xs">{getAssignModeLabel(mainTask.assignMode)}</Tag>
                                                <Tag color={getStatusColor(mainTask.status)} className="text-xs">{getTaskStatusLabel(mainTask.status)}</Tag>
                                                {!isIssueTrackingTask(mainTask) && (
                                                    <Tag color="blue" className="text-xs">{getTaskStageLabel(mainTask.currentStage)}</Tag>
                                                )}
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
                                                <button
                                                    type="button"
                                                    onClick={() => openTaskDetail(mainTask)}
                                                    className="inline-flex items-center gap-1 rounded bg-blue-50 px-2 py-1 font-bold text-blue-700 hover:bg-blue-100"
                                                >
                                                    <Eye size={12} />
                                                    对应资产变更记录 {getTaskAssetRecordCount(mainTask)} 条
                                                    <span className="font-normal text-blue-500">点击查看</span>
                                                </button>
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
                                                                <button
                                                                    type="button"
                                                                    onClick={() => openTaskDetail(task)}
                                                                    className="text-sm font-bold text-slate-800 hover:text-red-600 truncate text-left"
                                                                >
                                                                    {task.title}
                                                                </button>
                                                                <Tag color={getAssignModeColor(task.assignMode)} className="text-xs">{getAssignModeLabel(task.assignMode)}</Tag>
                                                                <Tag color={getStatusColor(task.status)} className="text-xs">{getTaskStatusLabel(task.status)}</Tag>
                                                                {!isIssueTrackingTask(task) && (
                                                                    <Tag color="blue" className="text-xs">{getTaskStageLabel(task.currentStage)}</Tag>
                                                                )}
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
                                                                <button
                                                                    type="button"
                                                                    onClick={() => openTaskDetail(task)}
                                                                    className="inline-flex items-center gap-1 rounded bg-blue-50 px-2 py-1 font-bold text-blue-700 hover:bg-blue-100"
                                                                >
                                                                    <Eye size={12} />
                                                                    对应资产变更记录 {getTaskAssetRecordCount(task)} 条
                                                                    <span className="font-normal text-blue-500">点击查看</span>
                                                                </button>
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
                                                    onChange={e => setNewTask(prev => ({
                                                        ...prev,
                                                        assignMode: e.target.value,
                                                        assigneeId: e.target.value === 'ASSIGN' ? prev.assigneeId : '',
                                                    }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none bg-white"
                                                >
                                                    <option value="ASSIGN">直接分派</option>
                                                    <option value="OPEN">公开认领</option>
                                                    <option value="COMPETE">竞争上岗</option>
                                                </select>
                                                <input
                                                    type="number"
                                                    value={newTask.points}
                                                    onChange={e => setNewTask(prev => ({ ...prev, points: parseInt(e.target.value) || 0 }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none"
                                                    placeholder={suggestedRule ? `建议 ${suggestedRule.suggestedPoints}` : '积分'}
                                                />
                                            </div>
                                        </div>
                                        {newTask.assignMode === 'ASSIGN' && (
                                            <label className="block">
                                                <span className="mb-1 block text-[11px] font-bold text-slate-500">负责人 *</span>
                                                <UserSelect
                                                    value={newTask.assigneeId}
                                                    onChange={assigneeId => setNewTask(prev => ({ ...prev, assigneeId }))}
                                                />
                                            </label>
                                        )}
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
                                            <label className="block">
                                                <span className="block text-[11px] font-bold text-slate-500 mb-1">截止日期</span>
                                                <input
                                                    type="datetime-local"
                                                    value={newTask.deadline}
                                                    onChange={e => setNewTask(prev => ({ ...prev, deadline: e.target.value }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none"
                                                />
                                            </label>
                                        </div>
                                        <div className="flex justify-end gap-2">
                                            <button
                                                onClick={() => { setAddingTask(false); setNewTask({ title: '', description: '', taskType: '开发', difficulty: '简单', points: 5, assignMode: 'ASSIGN', assigneeId: '', requiredSkills: '', deadline: '' }); }}
                                                className="px-4 py-1.5 text-sm font-medium text-slate-600 bg-white hover:bg-slate-100 rounded-lg transition-colors"
                                            >
                                                取消
                                            </button>
                                            <button
                                                onClick={handleAddTask}
                                                disabled={
                                                    submitting
                                                    || !newTask.title.trim()
                                                    || !newTask.description.trim()
                                                    || (newTask.assignMode === 'ASSIGN' && !newTask.assigneeId)
                                                }
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

            <Modal
                title="追加任务风险跟踪记录"
                open={trackingOpen}
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
                            {tasks
                                .filter(task => task.status !== 'CANCELLED')
                                .map(task => (
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

            <Drawer
                title={detailTask ? `任务信息：${detailTask.title}` : '任务信息'}
                placement="right"
                onClose={() => setDetailTask(null)}
                open={!!detailTask}
                width={760}
                destroyOnHidden
            >
                {detailTask && (
                    <div className="space-y-5">
                        <section className="grid grid-cols-2 gap-3 text-sm">
                            {[
                                ['任务名称', detailTask.title],
                                ['任务层级', detailTask.taskRole === 'MAIN' ? '主任务' : '子任务'],
                                ['任务状态', getTaskStatusLabel(detailTask.status)],
                                ['当前阶段', isIssueTrackingTask(detailTask) ? '不适用' : getTaskStageLabel(detailTask.currentStage)],
                                ['任务类型', detailTask.taskType],
                                ['难度', detailTask.difficulty],
                                ['分派方式', getAssignModeLabel(detailTask.assignMode)],
                                ['负责人', renderAssignee(detailTask.assigneeId)],
                                ['积分', detailTask.points],
                                ['最终积分', detailTask.finalPoints],
                                ['预计工时', detailTask.estimatedHours],
                                ['实际工时', detailTask.actualHours],
                                ['截止时间', formatDateTime(detailTask.deadline)],
                                ['提交时间', formatDateTime(detailTask.submittedAt)],
                                ['审核时间', formatDateTime(detailTask.reviewedAt)],
                                ['质量评分', detailTask.qualityScore],
                                ['返工次数', detailTask.reworkCount],
                                ['奖励积分', detailTask.bonusPoints],
                                ['扣减积分', detailTask.penaltyPoints],
                                ['创建时间', formatDateTime(detailTask.createTime)],
                                ['更新时间', formatDateTime(detailTask.updateTime)],
                            ].map(([label, value]) => (
                                <div key={label as string} className="rounded-md border border-slate-100 bg-slate-50 px-3 py-2">
                                    <div className="text-xs text-slate-400">{label}</div>
                                    <div className="mt-1 text-slate-700 break-words">{renderDetailValue(value)}</div>
                                </div>
                            ))}
                        </section>

                        {[
                            ['任务描述', detailTask.description],
                            ['所需技能', detailTask.requiredSkills],
                            ['验收标准', detailTask.acceptanceCriteria],
                            ['完成说明', detailTask.completionDescription],
                            ['交付物', detailTask.deliverables],
                            ['影响范围', detailTask.impactScope],
                            ['延迟原因', detailTask.delayReason],
                            ['阶段风险记录', detailTask.stageRiskNote],
                            ['审核意见', detailTask.reviewComment],
                        ].map(([label, value]) => (
                            <section key={label} className="rounded-md border border-slate-200">
                                <div className="border-b border-slate-100 px-4 py-2 text-sm font-bold text-slate-700">{label}</div>
                                <div className="px-4 py-3 text-sm text-slate-600 whitespace-pre-wrap">{renderDetailValue(value)}</div>
                            </section>
                        ))}

                        <TaskAuditTrail task={detailTask} />
                    </div>
                )}
            </Drawer>

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
        </Modal>
    );
};

export default WorkDetailDrawer;
