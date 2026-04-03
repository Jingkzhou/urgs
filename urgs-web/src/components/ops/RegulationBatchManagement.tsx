import React, { useEffect, useMemo, useState } from 'react';
import { Modal } from 'antd';
import { ClipboardList, DatabaseZap, ShieldCheck, TimerReset } from 'lucide-react';
import TaskManagement from './regulation/TaskManagement';
import TaskInstance from './regulation/TaskInstance';
import TaskExecutionLog from './regulation/TaskExecutionLog';
import { QuartzTask, quartzTaskExecutionLogsMock, quartzTaskStatusesMock, quartzTasksMock } from './regulation/mockData';
import { queryQuartzTaskStatus } from '@/api/ops';

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

    const [stats, setStats] = useState({
        waitingInstances: 0,
        runningInstances: 0,
        successInstances: 0,
        failedInstances: 0,
    });

    useEffect(() => {
        let canceled = false;
        const loadStats = async () => {
            try {
                const response = await queryQuartzTaskStatus({ pageNum: 1, pageSize: 2000 });
                if (!response?.success) return;
                const list = response.data?.list || [];
                if (canceled) return;
                setStats({
                    waitingInstances: list.filter(item => Number(item.status) === 0).length,
                    runningInstances: list.filter(item => Number(item.status) === 1).length,
                    successInstances: list.filter(item => Number(item.status) === 2).length,
                    failedInstances: list.filter(item => Number(item.status) === 3).length,
                });
            } catch {
                // ignore stats loading error in shell component
            }
        };
        loadStats();
        return () => {
            canceled = true;
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
                return <TaskInstance />;
            case 'task-management':
            default:
                return <TaskManagement onViewExecutionLog={handleOpenTaskLog} />;
        }
    };

    return (
        <div className="h-[calc(100vh-140px)] w-full bg-slate-50 rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col relative animate-fade-in">
            <div className="border-b border-slate-200 bg-[linear-gradient(180deg,rgba(255,255,255,0.98)_0%,rgba(248,250,252,0.94)_100%)] backdrop-blur px-5 py-3">
                <div className="space-y-3">
                    <div className="inline-flex rounded-2xl border border-slate-200/90 bg-white/90 p-1 shadow-[0_12px_32px_-28px_rgba(15,23,42,0.55)]">
                        {navItems.map(item => {
                            const isActive = activeView === item.id;
                            return (
                                <button
                                    key={item.id}
                                    onClick={() => handleSwitchView(item.id)}
                                    className={`inline-flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm transition-all ${isActive
                                        ? 'bg-red-50 text-red-700 shadow-[0_8px_20px_-18px_rgba(220,38,38,0.9)] font-semibold'
                                        : 'text-slate-500 hover:bg-slate-50 hover:text-slate-900'
                                        }`}
                                >
                                    <item.icon className={`h-3.5 w-3.5 ${isActive ? 'text-red-600' : 'text-slate-400'}`} />
                                    {item.label}
                                </button>
                            );
                        })}
                    </div>

                    <div className="flex flex-wrap gap-2">
                        <div className="min-w-[112px] rounded-full border border-slate-200/90 bg-white/90 px-3 py-2 shadow-[0_10px_24px_-24px_rgba(15,23,42,0.55)]">
                            <div className="flex items-center gap-1.5 text-[11px] font-medium text-slate-400">
                                <ClipboardList size={11} />
                                等待
                            </div>
                            <div className="mt-1 text-xl font-bold leading-none text-slate-800">{stats.waitingInstances}</div>
                        </div>
                        <div className="min-w-[112px] rounded-full border border-emerald-100 bg-emerald-50/85 px-3 py-2 shadow-[0_10px_24px_-24px_rgba(5,150,105,0.55)]">
                            <div className="flex items-center gap-1.5 text-[11px] font-medium text-emerald-600">
                                <ShieldCheck size={11} />
                                执行中
                            </div>
                            <div className="mt-1 text-xl font-bold leading-none text-emerald-700">{stats.runningInstances}</div>
                        </div>
                        <div className="min-w-[112px] rounded-full border border-blue-100 bg-blue-50/85 px-3 py-2 shadow-[0_10px_24px_-24px_rgba(37,99,235,0.55)]">
                            <div className="flex items-center gap-1.5 text-[11px] font-medium text-blue-600">
                                <DatabaseZap size={11} />
                                成功
                            </div>
                            <div className="mt-1 text-xl font-bold leading-none text-blue-700">{stats.successInstances}</div>
                        </div>
                        <div className="min-w-[112px] rounded-full border border-red-100 bg-red-50/85 px-3 py-2 shadow-[0_10px_24px_-24px_rgba(239,68,68,0.55)]">
                            <div className="flex items-center gap-1.5 text-[11px] font-medium text-red-600">
                                <TimerReset size={11} />
                                失败
                            </div>
                            <div className="mt-1 text-xl font-bold leading-none text-red-700">{stats.failedInstances}</div>
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
                destroyOnHidden
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
