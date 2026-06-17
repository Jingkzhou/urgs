import React, { useEffect, useState } from 'react';
import { Modal, message } from 'antd';
import { ClipboardList, TimerReset } from 'lucide-react';
import TaskManagement from './regulation/TaskManagement';
import TaskInstance from './regulation/TaskInstance';
import TaskExecutionLog from './regulation/TaskExecutionLog';
import { queryQuartzTaskLog, queryQuartzTasks } from '@/api/ops';
import { QuartzTask, QuartzTaskExecutionLog } from './regulation/mockData';
import { normalizeLog, normalizeTask } from './regulation/task-instance/utils';
import { TaskInstanceInitialFilters } from './regulation/task-instance/types';

type RegulationView = 'task-management' | 'task-instance';

const OPS_REGULATION_NAV_KEY = 'ops_regulation_nav';

const navItems = [
    { id: 'task-instance' as RegulationView, label: '任务实例', icon: TimerReset },
    { id: 'task-management' as RegulationView, label: '任务管理', icon: ClipboardList },
];

const RegulationBatchManagement: React.FC = () => {
    const [activeView, setActiveView] = useState<RegulationView>('task-instance');
    const [initialTaskInstanceFilters, setInitialTaskInstanceFilters] = useState<TaskInstanceInitialFilters | undefined>();
    const [executionLogVisible, setExecutionLogVisible] = useState(false);
    const [tasks, setTasks] = useState<QuartzTask[]>([]);
    const [logs, setLogs] = useState<QuartzTaskExecutionLog[]>([]);
    const [selectedLogTask, setSelectedLogTask] = useState<{ id: number | null; name: string | null }>({
        id: null,
        name: null,
    });

    useEffect(() => {
        const navData = sessionStorage.getItem(OPS_REGULATION_NAV_KEY);
        if (!navData) return;

        try {
            const { view, filters } = JSON.parse(navData);
            if (view === 'task-instance') {
                setActiveView('task-instance');
                setInitialTaskInstanceFilters(filters || undefined);
            }
        } catch (e) {
            // ignore invalid data
        } finally {
            sessionStorage.removeItem(OPS_REGULATION_NAV_KEY);
        }
    }, []);

    useEffect(() => {
        let cancelled = false;

        const loadTasks = async () => {
            try {
                const response = await queryQuartzTasks({ pageNum: 1, pageSize: 500 });
                if (!response?.success) {
                    throw new Error(response?.msg || '加载任务失败');
                }
                if (cancelled) return;
                setTasks((response.data?.list || []).map(normalizeTask));
            } catch (error: any) {
                if (!cancelled) {
                    message.error(error?.message || '加载任务失败');
                }
            }
        };

        void loadTasks();
        return () => {
            cancelled = true;
        };
    }, []);

    useEffect(() => {
        if (!executionLogVisible || !selectedLogTask.id) {
            setLogs([]);
            return;
        }

        let cancelled = false;

        const loadLogs = async () => {
            try {
                const response = await queryQuartzTaskLog(selectedLogTask.id!, 1, 200);
                if (!response?.success) {
                    throw new Error(response?.msg || '加载执行日志失败');
                }
                if (cancelled) return;
                setLogs((response.data?.list || []).map(normalizeLog));
            } catch (error: any) {
                if (!cancelled) {
                    setLogs([]);
                    message.error(error?.message || '加载执行日志失败');
                }
            }
        };

        void loadLogs();
        return () => {
            cancelled = true;
        };
    }, [executionLogVisible, selectedLogTask.id]);

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
                return <TaskInstance initialFilters={initialTaskInstanceFilters} />;
            case 'task-management':
            default:
                return <TaskManagement onViewExecutionLog={handleOpenTaskLog} />;
        }
    };

    return (
        <div className="h-[calc(100vh-112px)] w-full bg-slate-50 rounded-lg shadow-sm border border-slate-200 overflow-hidden flex flex-col relative animate-fade-in">
            <div className="border-b border-slate-200 bg-[linear-gradient(180deg,rgba(255,255,255,0.98)_0%,rgba(248,250,252,0.94)_100%)] backdrop-blur px-3 py-2">
                <div>
                    <div className="inline-flex rounded-lg border border-slate-200/90 bg-white/90 p-0.5 shadow-[0_12px_32px_-28px_rgba(15,23,42,0.55)]">
                        {navItems.map(item => {
                            const isActive = activeView === item.id;
                            return (
                                <button
                                    key={item.id}
                                    onClick={() => handleSwitchView(item.id)}
                                    className={`inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-sm transition-all ${isActive
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
                </div>
            </div>

            <div className="flex-1 overflow-auto p-3">
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
                    tasks={tasks}
                    logs={logs}
                    lockTaskId={selectedLogTask.id}
                    lockTaskName={selectedLogTask.name}
                    embedded
                />
            </Modal>
        </div>
    );
};

export default RegulationBatchManagement;
