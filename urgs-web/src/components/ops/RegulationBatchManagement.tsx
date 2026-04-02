import React, { useMemo, useState } from 'react';
import { Modal } from 'antd';
import { Activity, ClipboardList, DatabaseZap, ShieldCheck, TimerReset } from 'lucide-react';
import dayjs from 'dayjs';
import TaskManagement from './regulation/TaskManagement';
import TaskInstance from './regulation/TaskInstance';
import TaskExecutionLog from './regulation/TaskExecutionLog';
import { QuartzTask, quartzTaskExecutionLogsMock, quartzTaskStatusesMock, quartzTasksMock } from './regulation/mockData';

type RegulationView = 'task-management' | 'task-instance';

const navItems = [
    { id: 'task-management' as RegulationView, label: '任务管理', icon: ClipboardList },
    { id: 'task-instance' as RegulationView, label: '任务实例', icon: TimerReset },
];

const RegulationBatchManagement: React.FC = () => {
    const [activeView, setActiveView] = useState<RegulationView>('task-management');
    const [executionLogVisible, setExecutionLogVisible] = useState(false);
    const [selectedLogTask, setSelectedLogTask] = useState<{ id: number | null; name: string | null }>({
        id: null,
        name: null,
    });

    const stats = useMemo(() => {
        const today = dayjs().format('YYYY-MM-DD');
        const todayBatch = dayjs().format('YYYYMMDD');

        return {
            totalTasks: quartzTasksMock.length,
            enabledTasks: quartzTasksMock.filter(task => task.task_status === 0).length,
            todayInstances: quartzTaskStatusesMock.filter(instance => instance.data_date === today || instance.create_date === todayBatch).length,
            failedInstances: quartzTaskStatusesMock.filter(instance => instance.status === 3).length,
        };
    }, []);

    const handleOpenTaskLog = (task: QuartzTask) => {
        setSelectedLogTask({ id: task.id, name: task.task_name });
        setExecutionLogVisible(true);
    };

    const handleSwitchView = (view: RegulationView) => {
        setActiveView(view);
    };

    const handleCloseTaskLog = () => {
        setExecutionLogVisible(false);
        setSelectedLogTask({ id: null, name: null });
    };

    const renderContent = () => {
        switch (activeView) {
            case 'task-instance':
                return <TaskInstance tasks={quartzTasksMock} instances={quartzTaskStatusesMock} />;
            case 'task-management':
            default:
                return <TaskManagement tasks={quartzTasksMock} onViewExecutionLog={handleOpenTaskLog} />;
        }
    };

    return (
        <div className="h-[calc(100vh-140px)] w-full bg-slate-50 rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col relative animate-fade-in">
            <div className="border-b border-slate-200 bg-[linear-gradient(180deg,rgba(255,255,255,0.96)_0%,rgba(248,250,252,0.94)_100%)] backdrop-blur px-5 py-4">
                <div className="space-y-4">
                    <div className="flex flex-wrap gap-2">
                        {navItems.map(item => {
                            const isActive = activeView === item.id;
                            return (
                                <button
                                    key={item.id}
                                    onClick={() => handleSwitchView(item.id)}
                                    className={`inline-flex items-center gap-1.5 rounded-full px-3.5 py-2 text-sm transition-all ${isActive
                                        ? 'bg-red-50 text-red-700 border border-red-100 shadow-[0_8px_24px_-18px_rgba(220,38,38,0.7)] font-semibold'
                                        : 'bg-white/90 text-slate-600 hover:bg-slate-50 hover:text-slate-900 border border-slate-200/80'
                                        }`}
                                >
                                    <item.icon className={`w-3.5 h-3.5 ${isActive ? 'text-red-600' : 'text-slate-400'}`} />
                                    {item.label}
                                </button>
                            );
                        })}
                    </div>

                    <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
                        <div className="min-w-0">
                            <div className="flex items-center gap-2 text-slate-800">
                                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-red-50 ring-1 ring-red-100">
                                    <Activity size={16} className="text-red-600" />
                                </div>
                                <h2 className="text-xl font-bold tracking-tight">监管批量</h2>
                            </div>
                            <p className="mt-1.5 max-w-2xl text-sm text-slate-500">
                                面向监管批处理链路的任务定义与实例跟踪前端稿，字段按 `t_quartz_task` 和 `t_quartz_task_status` 映射。
                            </p>
                        </div>

                        <div className="flex flex-wrap gap-2.5 xl:justify-end">
                            <div className="min-w-[128px] rounded-full border border-slate-200/90 bg-white/90 px-3.5 py-2.5 shadow-[0_10px_30px_-24px_rgba(15,23,42,0.45)]">
                                <div className="flex items-center gap-1.5 text-[11px] font-medium text-slate-400">
                                    <ClipboardList size={12} />
                                    任务总数
                                </div>
                                <div className="mt-1 text-2xl font-bold leading-none text-slate-800">{stats.totalTasks}</div>
                            </div>
                            <div className="min-w-[128px] rounded-full border border-emerald-100 bg-emerald-50/85 px-3.5 py-2.5 shadow-[0_10px_30px_-24px_rgba(5,150,105,0.5)]">
                                <div className="flex items-center gap-1.5 text-[11px] font-medium text-emerald-600">
                                    <ShieldCheck size={12} />
                                    正常任务
                                </div>
                                <div className="mt-1 text-2xl font-bold leading-none text-emerald-700">{stats.enabledTasks}</div>
                            </div>
                            <div className="min-w-[128px] rounded-full border border-blue-100 bg-blue-50/85 px-3.5 py-2.5 shadow-[0_10px_30px_-24px_rgba(37,99,235,0.5)]">
                                <div className="flex items-center gap-1.5 text-[11px] font-medium text-blue-600">
                                    <DatabaseZap size={12} />
                                    当日实例
                                </div>
                                <div className="mt-1 text-2xl font-bold leading-none text-blue-700">{stats.todayInstances}</div>
                            </div>
                            <div className="min-w-[128px] rounded-full border border-red-100 bg-red-50/85 px-3.5 py-2.5 shadow-[0_10px_30px_-24px_rgba(239,68,68,0.5)]">
                                <div className="flex items-center gap-1.5 text-[11px] font-medium text-red-600">
                                    <TimerReset size={12} />
                                    失败实例
                                </div>
                                <div className="mt-1 text-2xl font-bold leading-none text-red-700">{stats.failedInstances}</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="flex-1 overflow-auto p-4">
                {renderContent()}
            </div>

            <Modal
                title={selectedLogTask.name ? `执行日志 · ${selectedLogTask.name}` : '执行日志'}
                open={executionLogVisible}
                onCancel={handleCloseTaskLog}
                footer={null}
                width={1280}
                destroyOnClose
                styles={{ body: { padding: 16 } }}
            >
                <TaskExecutionLog
                    tasks={quartzTasksMock}
                    logs={quartzTaskExecutionLogsMock}
                    lockTaskId={selectedLogTask.id}
                    lockTaskName={selectedLogTask.name}
                    embedded
                />
            </Modal>
        </div>
    );
};

export default RegulationBatchManagement;
