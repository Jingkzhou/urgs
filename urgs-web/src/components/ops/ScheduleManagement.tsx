import React, { useState } from 'react';
import {
    Folder, GitBranch, Layers, FileStack, ListChecks, FileText, Database, Activity, ChevronRight, Home
} from 'lucide-react';
import WorkflowDefinition from './schedule/WorkflowDefinition';
import TaskDefinition from './schedule/TaskDefinition';
import TaskInstance from './schedule/TaskInstance';

// --- Navigation Data ---
const navSections = [
    {
        title: '工作流管理',
        items: [
            { id: 'workflow-definition', label: '工作流定义', icon: Layers, path: ['调度管理', '工作流管理', '工作流定义'] },
        ],
    },
    {
        title: '任务管理',
        items: [
            { id: 'task-definition', label: '任务定义', icon: FileText, path: ['调度管理', '任务管理', '任务定义'] },
            { id: 'task-instance', label: '任务实例', icon: ListChecks, path: ['调度管理', '任务管理', '任务实例'] },
        ],
    },
];

interface ScheduleManagementProps {
    onTurnToIssue?: (task: any) => void;
}

const ScheduleManagement: React.FC<ScheduleManagementProps> = ({ onTurnToIssue }) => {
    const [activeView, setActiveView] = useState('workflow-definition');

    const activeNav = navSections.flatMap(s => s.items).find(i => i.id === activeView);
    const breadcrumbs = activeNav?.path || ['调度管理'];

    const renderContent = () => {
        switch (activeView) {
            case 'workflow-definition':
                return <WorkflowDefinition />;
            case 'task-definition':
                return <TaskDefinition />;
            case 'task-instance':
                return <TaskInstance />;
            default:
                return <WorkflowDefinition />;
        }
    };

    return (
        <div className="h-[calc(100vh-140px)] w-full bg-slate-50 rounded-xl shadow-sm border border-slate-200 overflow-hidden flex relative animate-fade-in">

            {/* Left Sidebar: Navigation */}
            <aside className="w-60 border-r border-slate-200 bg-white flex flex-col z-10 shrink-0">
                <div className="px-5 py-4 border-b border-slate-200 bg-slate-50/50">
                    <h2 className="text-sm font-bold text-slate-800 flex items-center gap-2">
                        <Activity className="w-4 h-4 text-red-600" />
                        调度中心
                    </h2>
                </div>
                <div className="flex-1 overflow-y-auto py-4 px-3 space-y-6">
                    {navSections.map((section, idx) => (
                        <div key={idx}>
                            {section.title && (
                                <div className="px-3 mb-2 text-xs font-bold text-slate-400 uppercase tracking-wider">
                                    {section.title}
                                </div>
                            )}
                            <div className="space-y-1">
                                {section.items.map((item, itemIdx) => (
                                    <button
                                        key={itemIdx}
                                        onClick={() => setActiveView(item.id)}
                                        className={`w-full flex items-center gap-3 px-3 py-2.5 text-sm rounded-lg transition-all duration-200 ${activeView === item.id
                                            ? 'bg-red-50 text-red-700 font-medium shadow-sm border border-red-100'
                                            : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                                            }`}
                                    >
                                        <item.icon className={`w-4 h-4 ${activeView === item.id ? 'text-red-600' : 'text-slate-400'}`} />
                                        {item.label}
                                    </button>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            </aside>

            {/* Main Content Area */}
            <main className="flex-1 flex flex-col overflow-hidden relative bg-slate-50">
                {/* Header / Breadcrumbs */}
                <div className="h-12 border-b border-slate-200 bg-white px-6 flex items-center justify-between shrink-0">
                    <div className="flex items-center gap-2 text-sm text-slate-500">
                        <Home size={14} className="text-slate-400" />
                        {breadcrumbs.map((crumb, index) => (
                            <React.Fragment key={index}>
                                <ChevronRight size={14} className="text-slate-300" />
                                <span className={index === breadcrumbs.length - 1 ? 'font-medium text-slate-800' : ''}>
                                    {crumb}
                                </span>
                            </React.Fragment>
                        ))}
                    </div>

                </div>

                {/* Content */}
                <div className="flex-1 overflow-hidden p-4">
                    {renderContent()}
                </div>
            </main>
        </div>
    );
};

export default ScheduleManagement;
