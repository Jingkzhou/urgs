import React, { useEffect, useState } from 'react';
import { Drawer, Button, Tag, Space, Divider, Typography, Descriptions, Spin, Empty } from 'antd';
import { getTaskDetail, TaskMarketDTO, claimTask } from '../../api/marketplace';
import { Award, Clock, Users, Building2, User } from 'lucide-react';

const { Title, Paragraph, Text } = Typography;

interface TaskDetailDrawerProps {
    taskId: string | null;
    isOpen: boolean;
    onClose: () => void;
    onClaimSuccess?: () => void;
}

const TaskDetailDrawer: React.FC<TaskDetailDrawerProps> = ({ taskId, isOpen, onClose, onClaimSuccess }) => {
    const [task, setTask] = useState<TaskMarketDTO | null>(null);
    const [loading, setLoading] = useState(false);
    const [claiming, setClaiming] = useState(false);

    useEffect(() => {
        if (isOpen && taskId) {
            fetchDetail(taskId);
        } else if (!isOpen) {
            setTask(null);
        }
    }, [isOpen, taskId]);

    const fetchDetail = async (id: string) => {
        setLoading(true);
        try {
            const res = await getTaskDetail(id);
            setTask(res as any);
        } catch (error) {
            console.error('Failed to fetch task detail', error);
        } finally {
            setLoading(false);
        }
    };

    const handleClaim = async () => {
        if (!task || !window.confirm("确定要领取该任务吗？")) return;
        setClaiming(true);
        try {
            await claimTask(task.id);
            alert("领取成功");
            onClaimSuccess?.();
            onClose();
        } catch (error) {
            console.error('Failed to claim task', error);
            alert("领取失败");
        } finally {
            setClaiming(false);
        }
    };

    return (
        <Drawer
            title="任务详情"
            placement="right"
            onClose={onClose}
            open={isOpen}
            width={600}
            extra={
                <Space>
                    <Button onClick={onClose}>关闭</Button>
                    {task?.status === 'OPEN' && task?.assignMode === 'OPEN' && (
                        <Button type="primary" danger onClick={handleClaim} loading={claiming}>
                            立即领取
                        </Button>
                    )}
                </Space>
            }
        >
            {loading ? (
                <div className="flex justify-center items-center h-64">
                    <Spin size="large" tip="加载中..." />
                </div>
            ) : task ? (
                <div className="flex flex-col gap-6">
                    <header>
                        <Space className="mb-2">
                            <Tag color={task.assignMode === 'OPEN' ? 'blue' : 'orange'}>
                                {task.assignMode === 'OPEN' ? '直接领取' : '竞争竞标'}
                            </Tag>
                            <Tag color={
                                task.status === 'OPEN' ? 'green' :
                                    task.status === 'COMPLETED' ? 'blue' : 'default'
                            }>
                                {task.status}
                            </Tag>
                        </Space>
                        <Title level={3} className="!mb-0">{task.title}</Title>
                    </header>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="bg-slate-50 p-4 rounded-xl flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center text-orange-600">
                                <Award size={20} />
                            </div>
                            <div>
                                <div className="text-xs text-slate-400">奖励积分</div>
                                <div className="font-bold text-slate-800">{task.points} 积分</div>
                            </div>
                        </div>
                        <div className="bg-slate-50 p-4 rounded-xl flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600">
                                <Clock size={20} />
                            </div>
                            <div>
                                <div className="text-xs text-slate-400">截止日期</div>
                                <div className="font-bold text-slate-800">{task.deadline ? new Date(task.deadline).toLocaleDateString() : '无期限'}</div>
                            </div>
                        </div>
                    </div>

                    <Divider className="my-0" />

                    <section>
                        <Title level={5}>任务描述</Title>
                        <Paragraph className="text-slate-600 whitespace-pre-wrap">
                            {task.description || '暂无描述信息'}
                        </Paragraph>
                    </section>

                    <section>
                        <Title level={5}>技能要求</Title>
                        <div className="flex flex-wrap gap-2">
                            {task.requiredSkills ? task.requiredSkills.split(',').map(skill => (
                                <Tag key={skill} className="rounded-full px-3">{skill}</Tag>
                            )) : <Text type="secondary">无特殊技能要求</Text>}
                        </div>
                    </section>

                    <Divider className="my-0" />

                    <Descriptions column={1} size="small" className="bg-slate-50 p-4 rounded-xl">
                        <Descriptions.Item label={<Space><Building2 size={14} /> 所属工作</Space>}>
                            <span className="font-medium">{task.workTitle || '未指定'}</span>
                        </Descriptions.Item>
                        <Descriptions.Item label={<Space><User size={14} /> 发布人</Space>}>
                            <Space>
                                <img src={task.publisherAvatar || 'https://api.dicebear.com/7.x/avataaars/svg?seed=' + task.publisherName} alt="" className="w-5 h-5 rounded-full" />
                                <span className="font-medium">{task.publisherName}</span>
                            </Space>
                        </Descriptions.Item>
                        {task.assignMode === 'COMPETE' && (
                            <Descriptions.Item label={<Space><Users size={14} /> 申请情况</Space>}>
                                <span className="font-medium text-red-600">{task.applicationCount}</span> / {task.maxApplicants || '不限'} 人申请
                            </Descriptions.Item>
                        )}
                    </Descriptions>

                    {task.assignMode === 'COMPETE' && (
                        <div className="bg-red-50 p-4 rounded-xl border border-red-100">
                            <Text type="danger" className="text-xs">
                                * 此任务为竞标模式，申请后需等待发布人审核完成后方可开始。
                            </Text>
                        </div>
                    )}
                </div>
            ) : (
                <Empty description="无法加载任务详情" />
            )}
        </Drawer>
    );
};

export default TaskDetailDrawer;
