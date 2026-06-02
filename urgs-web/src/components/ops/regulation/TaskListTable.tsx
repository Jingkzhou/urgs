import React from 'react';
import { Dropdown, Modal, Tag } from 'antd';
import type { MenuProps } from 'antd';
import { FileCog, FileText, PauseCircle, Play, PlayCircle, Trash2 } from 'lucide-react';
import dayjs from 'dayjs';
import { QuartzTask } from './mockData';
import { statusMap } from './taskManagementUtils';

interface TaskListTableProps {
    taskList: QuartzTask[];
    onSelectTask: (task: QuartzTask) => void;
    onEditTask: (task: QuartzTask) => void;
    onPauseTask: (task: QuartzTask) => void;
    onResumeTask: (task: QuartzTask) => void;
    onStartTask: (task: QuartzTask) => void;
    onViewExecutionLog: (task: QuartzTask) => void;
    onDeleteTask: (task: QuartzTask) => void;
}

const TaskListTable: React.FC<TaskListTableProps> = ({
    taskList,
    onSelectTask,
    onEditTask,
    onPauseTask,
    onResumeTask,
    onStartTask,
    onViewExecutionLog,
    onDeleteTask,
}) => {
    const getMoreMenuItems = (task: QuartzTask): MenuProps['items'] => [
        {
            key: `edit-${task.id}`,
            label: '编辑',
            icon: <FileCog size={14} />,
            onClick: ({ domEvent }) => {
                domEvent.stopPropagation();
                onEditTask(task);
            },
        },
        task.task_status === 0 ? {
            key: `pause-${task.id}`,
            label: '暂停任务',
            icon: <PauseCircle size={14} />,
            onClick: ({ domEvent }) => {
                domEvent.stopPropagation();
                onPauseTask(task);
            },
        } : {
            key: `resume-${task.id}`,
            label: '恢复任务',
            icon: <PlayCircle size={14} />,
            onClick: ({ domEvent }) => {
                domEvent.stopPropagation();
                onResumeTask(task);
            },
        },
        {
            type: 'divider',
        },
        {
            key: `start-${task.id}`,
            label: '立即开始',
            icon: <Play size={14} />,
            onClick: ({ domEvent }) => {
                domEvent.stopPropagation();
                onStartTask(task);
            },
        },
        {
            key: `log-${task.id}`,
            label: '执行日志',
            icon: <FileText size={14} />,
            onClick: ({ domEvent }) => {
                domEvent.stopPropagation();
                onViewExecutionLog(task);
            },
        },
        {
            type: 'divider',
        },
        {
            key: `delete-${task.id}`,
            label: '删除',
            icon: <Trash2 size={14} />,
            danger: true,
            onClick: ({ domEvent }) => {
                domEvent.stopPropagation();
                Modal.confirm({
                    title: '确认删除任务',
                    content: `删除后将无法恢复，确认删除任务"${task.task_name}"吗？`,
                    okText: '确认删除',
                    cancelText: '取消',
                    okButtonProps: { danger: true },
                    onOk: () => onDeleteTask(task),
                });
            },
        },
    ];

    return (
        <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
            <div className="overflow-x-auto">
                <table className="w-full min-w-[1100px] text-sm text-left">
                    <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500 border-b border-slate-200">
                        <tr>
                            <th className="px-4 py-3 font-semibold">任务名称</th>
                            <th className="px-4 py-3 font-semibold">任务类型</th>
                            <th className="px-4 py-3 font-semibold">Cron</th>
                            <th className="px-4 py-3 font-semibold">状态</th>
                            <th className="px-4 py-3 font-semibold">系统</th>
                            <th className="px-4 py-3 font-semibold">主题</th>
                            <th className="px-4 py-3 font-semibold">偏移量</th>
                            <th className="px-4 py-3 font-semibold">更新时间</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                        {taskList.length === 0 ? (
                            <tr>
                                <td colSpan={8} className="px-6 py-16 text-center text-slate-500">
                                    未找到符合条件的监管任务。
                                </td>
                            </tr>
                        ) : taskList.map(task => {
                            const mappedStatus = statusMap[task.task_status] || statusMap[0];
                            return (
                                <Dropdown
                                    key={task.id}
                                    menu={{ items: getMoreMenuItems(task) }}
                                    trigger={['contextMenu']}
                                >
                                    <tr
                                        onClick={() => onSelectTask(task)}
                                        className="cursor-pointer hover:bg-slate-50/80 transition-colors"
                                        title="右键查看操作菜单"
                                    >
                                        <td className="px-4 py-4">
                                            <div className="space-y-1 text-left">
                                                <div className="font-semibold text-slate-800">{task.task_name}</div>
                                                <div className="font-mono text-xs text-slate-500">#{task.id}</div>
                                            </div>
                                        </td>
                                        <td className="px-4 py-4">
                                            <Tag color="blue" className="m-0 border-0 bg-blue-50 text-blue-600">{task.task_type || '-'}</Tag>
                                        </td>
                                        <td className="px-4 py-4 font-mono text-xs text-slate-600">{task.task_cron}</td>
                                        <td className="px-4 py-4">
                                            <span className={`inline-flex rounded-full border px-2 py-1 text-xs font-semibold ${mappedStatus.className}`}>
                                                {mappedStatus.label}
                                            </span>
                                        </td>
                                        <td className="px-4 py-4 text-slate-600">{task.task_system || '-'}</td>
                                        <td className="px-4 py-4 text-slate-600">{task.theme || '-'}</td>
                                        <td className="px-4 py-4 text-slate-600">{task.offset ?? '-'}</td>
                                        <td className="px-4 py-4 font-mono text-xs text-slate-500">
                                            {dayjs(task.update_time).format('YYYY-MM-DD HH:mm:ss')}
                                        </td>
                                    </tr>
                                </Dropdown>
                            );
                        })}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default TaskListTable;
