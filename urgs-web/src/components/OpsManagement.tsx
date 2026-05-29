import React, { useState } from 'react';
import { AlertTriangle, Activity, Server, ShieldCheck } from 'lucide-react';
import Auth from './Auth';
import IssueTracking from './ops/IssueTracking';
import InfrastructureManagement from './ops/InfrastructureManagement';
import RegulationBatchManagement from './ops/RegulationBatchManagement';

type SubModule = 'issue' | 'infra' | 'regulation';

const OPS_REGULATION_NAV_KEY = 'ops_regulation_nav';

const OpsManagement: React.FC = () => {
    const [activeModule, setActiveModule] = useState<SubModule>('regulation');

    React.useEffect(() => {
        const navData = sessionStorage.getItem(OPS_REGULATION_NAV_KEY);
        if (!navData) return;

        try {
            const { module } = JSON.parse(navData);
            if (module === 'regulation') {
                setActiveModule('regulation');
            }
        } catch (e) {
            // ignore invalid data
        }
    }, []);

    const tabs = [
        { id: 'infra', label: '基础设施管理', icon: Server, permission: 'ops:infra:view' },
        { id: 'regulation', label: '监管批量', icon: ShieldCheck, permission: 'ops:regulation:view' },
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
                {activeModule === 'infra' && (
                    <Auth code="ops:infra:view">
                        <InfrastructureManagement />
                    </Auth>
                )}
                {activeModule === 'regulation' && (
                    <Auth code="ops:regulation:view">
                        <RegulationBatchManagement />
                    </Auth>
                )}
                {activeModule === 'issue' && (
                    <Auth code="ops:issue">
                        <IssueTracking initialData={null} />
                    </Auth>
                )}
            </div>
        </div>
    );
};

export default OpsManagement;
