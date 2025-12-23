import React, { useState } from 'react';
import { Timer, AlertTriangle, Activity } from 'lucide-react';
import Auth from './Auth';
import ScheduleManagement from './ops/ScheduleManagement';
import IssueTracking from './ops/IssueTracking';

type SubModule = 'schedule' | 'issue';

const OpsManagement: React.FC = () => {
    const [activeModule, setActiveModule] = useState<SubModule>('schedule');
    const [initialIssueData, setInitialIssueData] = useState<any>(null);

    const handleTurnToIssue = (task: any) => {
        setInitialIssueData({
            title: `[调度异常] ${task.name} 任务执行失败`,
            relatedTaskId: task.id,
            description: `任务 ${task.name} (${task.id}) 在 ${task.lastRun} 执行失败。\n工作流: ${task.workflow}\nCron: ${task.cron}`,
            system: 'DolphinScheduler' // Or derive from workflow
        });
        setActiveModule('issue');
    };

    const tabs = [
        { id: 'schedule', label: '调度管理', icon: Timer, permission: 'ops:schedule' },
        { id: 'issue', label: '生产问题登记', icon: AlertTriangle, permission: 'ops:issue' },
    ];

    return (
        <div className="space-y-6 animate-fade-in">
            {/* Header & Navigation */}
            <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200 flex flex-col sm:flex-row justify-between items-center gap-4">
                <div>
                    <h2 className="text-2xl font-bold text-slate-800 flex items-center gap-2">
                        <Activity className="text-red-600" />
                        运维管理
                    </h2>
                    <p className="text-slate-500 mt-1">系统稳定性保障：调度监控与生产问题闭环</p>
                </div>

                {/* Module Tabs */}
                <div className="flex gap-1 bg-slate-100 p-1 rounded-lg">
                    {tabs.map(tab => (
                        <Auth key={tab.id} code={tab.permission}>
                            <button
                                onClick={() => setActiveModule(tab.id as SubModule)}
                                className={`
                                    flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-all
                                    ${activeModule === tab.id
                                        ? 'bg-white text-red-600 shadow-sm'
                                        : 'text-slate-500 hover:text-slate-700 hover:bg-slate-200/50'}
                                `}
                            >
                                <tab.icon size={16} />
                                {tab.label}
                            </button>
                        </Auth>
                    ))}
                </div>
            </div>

            {/* Module Content */}
            <div className="min-h-[500px]">
                {activeModule === 'schedule' && (
                    <Auth code="ops:schedule">
                        <ScheduleManagement onTurnToIssue={handleTurnToIssue} />
                    </Auth>
                )}
                {activeModule === 'issue' && (
                    <Auth code="ops:issue">
                        <IssueTracking initialData={initialIssueData} />
                    </Auth>
                )}
            </div>
        </div>
    );
};

export default OpsManagement;
