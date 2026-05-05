import React, { useEffect, useState } from 'react';
import { Drawer, Tag, Space, Divider, Typography, Spin, Empty } from 'antd';
import { getWorkDetail, getWorkTasks, addTaskToWork, Work, WorkTask } from '../../api/marketplace';
import { Plus, Trash2, Award, Clock, Paperclip } from 'lucide-react';
import { getTaskStatusLabel, getWorkStatusLabel } from './marketplaceLabels';

const { Title, Paragraph, Text } = Typography;

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

    // New task form fields
    const [newTask, setNewTask] = useState({
        title: '',
        description: '',
        points: 5,
        estimatedHours: 0,
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

    const fetchDetail = async (id: string) => {
        setLoading(true);
        try {
            const [workRes, tasksRes] = await Promise.all([
                getWorkDetail(id),
                getWorkTasks(id),
            ]);
            setWork(workRes);
            setTasks(tasksRes || []);
        } catch (error) {
            console.error('Failed to fetch work detail', error);
        } finally {
            setLoading(false);
        }
    };

    const handleAddTask = async () => {
        if (!newTask.title.trim() || !newTask.description.trim()) return;
        setSubmitting(true);
        try {
            await addTaskToWork(workId!, newTask as any);
            setTasks(prev => [...prev, null!] as any); // Will be refreshed by fetchDetail
            await fetchDetail(workId!);
            setNewTask({ title: '', description: '', points: 5, estimatedHours: 0, assignMode: 'OPEN', requiredSkills: '', deadline: '' });
            setAddingTask(false);
        } catch (error) {
            console.error('Failed to add task', error);
        } finally {
            setSubmitting(false);
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

    const totalEstimatedHours = tasks.reduce((sum, task) => sum + (task.estimatedHours ?? task.actualHours ?? 0), 0);

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
                    <Spin size="large" tip="加载中..." />
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
                            <Tag>{work.category}</Tag>
                        </Space>
                        <Title level={3} className="!mb-0">{work.title}</Title>
                        {work.requirementNumber && (
                            <Text type="secondary" className="block mt-1">
                                需求编号: {work.requirementNumber}
                            </Text>
                        )}
                    </header>

                    <div className="bg-slate-50 p-4 rounded-xl flex items-center justify-around">
                        <div className="text-center">
                            <div className="text-xs text-slate-400 mb-1">总积分</div>
                            <div className="font-black text-xl text-slate-800">{work.totalPoints}</div>
                        </div>
                        <Divider orientation="vertical" className="h-10 border-slate-200" />
                        <div className="text-center">
                            <div className="text-xs text-slate-400 mb-1">任务数</div>
                            <div className="font-bold text-slate-800">{tasks.length}</div>
                        </div>
                        <Divider orientation="vertical" className="h-10 border-slate-200" />
                        <div className="text-center">
                            <div className="text-xs text-slate-400 mb-1">汇总工时</div>
                            <div className="font-bold text-slate-800">{totalEstimatedHours} 小时</div>
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

                    <section>
                        <div className="flex items-center justify-between mb-4">
                            <Title level={5} className="!mb-0">包含任务 ({tasks.length})</Title>
                            {work.status !== 'COMPLETED' && work.status !== 'CANCELLED' && (
                                <button
                                    onClick={() => setAddingTask(true)}
                                    className="flex items-center gap-1.5 text-sm font-medium text-red-600 hover:text-red-700 hover:bg-red-50 px-3 py-1.5 rounded-md transition-colors"
                                >
                                    <Plus size={16} /> 添加任务
                                </button>
                            )}
                        </div>

                        {tasks.length === 0 && !addingTask ? (
                            <div className="text-center py-8 text-slate-400 bg-slate-50 rounded-xl border border-dashed border-slate-200">
                                暂无任务，点击右上角添加第一个任务吧。
                            </div>
                        ) : (
                            <div className="space-y-3">
                                {tasks.map((task, index) => (
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
                                                            </div>
                                                            <div className="flex items-center gap-4 text-xs text-slate-500 flex-wrap">
                                                                <span className="flex items-center gap-1">
                                                                    <Award size={12} /> {task.points} 积分
                                                                </span>
                                                                <span className="flex items-center gap-1">
                                                                    <Clock size={12} /> {task.estimatedHours ?? task.actualHours ?? 0} 小时
                                                                </span>
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
                                            <div className="grid grid-cols-3 gap-2">
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
                                                    placeholder="积分"
                                                />
                                                <input
                                                    type="number"
                                                    value={newTask.estimatedHours}
                                                    onChange={e => setNewTask(prev => ({ ...prev, estimatedHours: parseInt(e.target.value) || 0 }))}
                                                    className="w-full px-3 py-1.5 border border-slate-200 rounded-lg text-sm focus:ring-1 focus:ring-red-500 outline-none"
                                                    placeholder="预计工时"
                                                />
                                            </div>
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
                                                onClick={() => { setAddingTask(false); setNewTask({ title: '', description: '', points: 5, estimatedHours: 0, assignMode: 'OPEN', requiredSkills: '', deadline: '' }); }}
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
        </Drawer>
    );
};

export default WorkDetailDrawer;
