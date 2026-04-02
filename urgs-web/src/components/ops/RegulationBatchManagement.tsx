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
        <div className="h-[calc(100vh-140px)] w-full bg-slate-50 rounded-xl shadow-sm border border-slate-200 overflow-hidden flex relative animate-fade-in">
            <aside className="w-52 border-r border-slate-200 bg-white flex flex-col shrink-0">
                <div className="px-4 py-4 border-b border-slate-200 bg-slate-50/70">
                    <h2 className="text-sm font-bold text-slate-800 flex items-center gap-2">
                        <ShieldCheck className="w-4 h-4 text-red-600" />
                        监管批量
                    </h2>
                    <p className="mt-1 text-xs text-slate-500">监管任务、实例状态与失败消息总览</p>
                </div>
                <div className="p-2.5 space-y-1">
                    {navItems.map(item => {
                        const isActive = activeView === item.id;
                        return (
                            <button
                                key={item.id}
                                onClick={() => handleSwitchView(item.id)}
                                className={`w-full flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition-all ${isActive
                                    ? 'bg-red-50 text-red-700 border border-red-100 shadow-sm font-semibold'
                                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900 border border-transparent'
                                    }`}
                            >
                                <item.icon className={`w-4 h-4 ${isActive ? 'text-red-600' : 'text-slate-400'}`} />
                                {item.label}
                            </button>
                        );
                    })}
                </div>
            </aside>

            <main className="flex-1 overflow-hidden flex flex-col bg-slate-50">
                <div className="border-b border-slate-200 bg-white/90 backdrop-blur px-6 py-5">
                    <div className="flex flex-col xl:flex-row xl:items-start xl:justify-between gap-5">
                        <div>
                            <div className="flex items-center gap-2 text-slate-800">
                                <Activity size={20} className="text-red-600" />
                                <h2 className="text-2xl font-bold">监管批量</h2>
                            </div>
                            <p className="mt-2 text-sm text-slate-500">
                                面向监管批处理链路的任务定义与实例跟踪前端稿，字段按 `t_quartz_task` 和 `t_quartz_task_status` 映射。
                            </p>
                        </div>

                        <div className="grid grid-cols-2 xl:grid-cols-4 gap-3 min-w-0 xl:min-w-[620px]">
                            <div className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
                                <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-slate-400">
                                    <ClipboardList size={14} />
                                    任务总数
                                </div>
                                <div className="mt-3 text-2xl font-bold text-slate-800">{stats.totalTasks}</div>
                            </div>
                            <div className="rounded-2xl border border-emerald-100 bg-emerald-50 px-4 py-4">
                                <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-emerald-500">
                                    <ShieldCheck size={14} />
                                    正常任务
                                </div>
                                <div className="mt-3 text-2xl font-bold text-emerald-700">{stats.enabledTasks}</div>
                            </div>
                            <div className="rounded-2xl border border-blue-100 bg-blue-50 px-4 py-4">
                                <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-blue-500">
                                    <DatabaseZap size={14} />
                                    当日实例
                                </div>
                                <div className="mt-3 text-2xl font-bold text-blue-700">{stats.todayInstances}</div>
                            </div>
                            <div className="rounded-2xl border border-red-100 bg-red-50 px-4 py-4">
                                <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-red-500">
                                    <TimerReset size={14} />
                                    失败实例
                                </div>
                                <div className="mt-3 text-2xl font-bold text-red-700">{stats.failedInstances}</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="flex-1 overflow-auto p-4">
                    {renderContent()}
                </div>
            </main>

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
