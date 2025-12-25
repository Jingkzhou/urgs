import React from 'react';
import {
    Activity, Server, Database, Network, Cpu, Layers,
    Play, Clock, Zap, GitBranch, Box, Code,
    Terminal, Search, FileText, Settings, RefreshCw,
    Shield, ArrowUpRight, BarChart2
} from 'lucide-react';


// --- Shared VS Code / Tech Aesthetic Components ---

const GlassCard: React.FC<{ children: React.ReactNode; className?: string }> = React.memo(({ children, className = '' }) => (
    <div className={`bg-white/70 backdrop-blur-2xl border border-white/40 shadow-xl shadow-black/5 rounded-3xl overflow-hidden ${className}`}>
        {children}
    </div>
));

// ... (Keeping imports and setups)

const SectionHeader: React.FC<{ icon: React.ReactNode; title: string; subtitle: string; color: string }> = React.memo(({ icon, title, subtitle, color }) => (
    <div className="flex items-center gap-3 mb-5">
        <div className={`p-2.5 rounded-xl ${color} text-white shadow-lg shadow-black/5`}>
            {React.cloneElement(icon as React.ReactElement, { size: 18, strokeWidth: 2.5 } as any)}
        </div>
        <div>
            <h3 className="font-bold text-slate-800 text-lg tracking-tight leading-none">{title}</h3>
            <p className="text-[11px] text-slate-400 font-semibold uppercase tracking-wider mt-1">{subtitle}</p>
        </div>
    </div>
));

const ExecutorNode: React.FC<{ name: string; cpu: number; mem: number; tasks: number; status: 'active' | 'busy' | 'idle' }> = React.memo(({ name, cpu, mem, tasks, status }) => {
    const isBusy = status === 'busy';
    return (
        <div className="relative group">
            <div className="relative bg-white border border-slate-100 p-4 rounded-xl hover:translate-y-[-2px] transition-transform">
                <div className="flex justify-between items-center mb-3">
                    <div className="flex items-center gap-2">
                        <Server size={14} className={isBusy ? 'text-orange-500' : 'text-blue-500'} />
                        <span className="font-bold text-sm text-slate-700">{name}</span>
                    </div>
                    <div className={`w-2 h-2 rounded-full ${isBusy ? 'bg-orange-500 animate-ping' : 'bg-green-500'}`}></div>
                </div>
                <div className="space-y-2">
                    <div className="flex justify-between text-xs text-slate-500">
                        <span>CPU 使用率</span>
                        <span className="font-mono font-bold text-slate-700">{cpu}%</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                        <div className={`h-full rounded-full ${isBusy ? 'bg-orange-500' : 'bg-blue-500'}`} style={{ width: `${cpu}%` }}></div>
                    </div>
                    <div className="flex justify-between text-xs text-slate-500">
                        <span>任务队列</span>
                        <span className="font-mono font-bold text-slate-700">{tasks}</span>
                    </div>
                </div>
            </div>
        </div>
    );
});




// --- Module 1: Executor Cluster (The Engine) ---

const GitStatRow: React.FC<{ label: string; value: string; trend: string; trendUp: boolean; icon: React.ReactNode }> = React.memo(({ label, value, trend, trendUp, icon }) => (
    <div className="flex items-center justify-between p-3 bg-slate-50/50 rounded-xl hover:bg-slate-50 transition-colors group">
        <div className="flex items-center gap-3">
            <div className="p-2 bg-white rounded-lg shadow-sm text-slate-500 group-hover:text-indigo-600 transition-colors">
                {React.cloneElement(icon as React.ReactElement<any>, { size: 16 })}
            </div>
            <span className="text-sm font-medium text-slate-600">{label}</span>
        </div>
        <div className="text-right">
            <div className="font-bold text-slate-800">{value}</div>
            <div className={`text-[10px] font-bold ${trendUp ? 'text-green-600' : 'text-slate-400'}`}>
                {trend}
            </div>
        </div>
    </div>
));

const COMMIT_DATA = [12, 45, 30, 60, 25, 80, 45];

const GitStatsPanel: React.FC = React.memo(() => {
    return (
        <GlassCard className="p-6 h-full border-none ring-1 ring-black/5">
            <SectionHeader
                icon={<GitBranch />}
                title="代码仓库"
                subtitle="Repositories"
                color="bg-black"
            />

            <div className="grid grid-cols-2 gap-4 mb-6">
                <div className="p-4 bg-gradient-to-br from-violet-500 to-indigo-600 rounded-2xl text-white shadow-md shadow-violet-200 relative overflow-hidden">
                    <div className="relative z-10">
                        <div className="flex items-center gap-2 text-white/80 text-xs font-bold uppercase tracking-wider mb-1">
                            <GitBranch size={14} /> Total Commits
                        </div>
                        <div className="text-3xl font-black tracking-tight">2,485</div>
                        <div className="mt-2 flex items-center gap-1 text-xs text-white/90 bg-white/20 w-fit px-2 py-0.5 rounded-full">
                            <Activity size={12} /> +124 this week
                        </div>
                    </div>
                </div>

                <div className="space-y-2">
                    <GitStatRow label="Active Branches" value="18" trend="+3 New" trendUp={true} icon={<GitBranch />} />
                    <GitStatRow label="Merge Requests" value="5" trend="2 Pending" trendUp={false} icon={<RefreshCw />} />
                </div>
            </div>

            <div className="pt-4 border-t border-slate-100">
                <div className="flex justify-between items-center mb-4">
                    <span className="text-sm font-bold text-slate-700 flex items-center gap-2">
                        <Code size={16} className="text-slate-400" /> 代码提交趋势 (Commit Activity)
                    </span>
                    <span className="text-[10px] font-mono text-slate-400 bg-slate-50 px-2 py-1 rounded">Last 7 Days</span>
                </div>
                <div className="flex gap-1 h-12 items-end">
                    {COMMIT_DATA.map((h, i) => (
                        <div key={i} className="flex-1 bg-violet-100 hover:bg-violet-500 transition-all rounded-md group relative" style={{ height: `${h}%` }}>
                            <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-1.5 py-0.5 bg-slate-800 text-white text-[10px] rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                                {h} commits
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </GlassCard>
    );
});

// --- Module 2: Governance & Lineage (The Brain) ---

const LineageEngineCard: React.FC = React.memo(() => {
    return (
        <GlassCard className="p-6 h-full border-none ring-1 ring-black/5">
            <SectionHeader
                icon={<Network />}
                title="血缘解析"
                subtitle="Lineage Engine"
                color="bg-blue-500"
            />

            <div className="relative h-40 flex items-center justify-center mb-4">
                {/* Abstract Radar Visual */}
                <div className="absolute inset-0 flex items-center justify-center">
                    <div className="w-32 h-32 border border-slate-100 rounded-full"></div>
                    <div className="w-20 h-20 border border-slate-200 rounded-full absolute"></div>
                </div>
                <div className="relative z-10 grid grid-cols-3 gap-6 text-center">
                    <div className="flex flex-col items-center">
                        <div className="w-10 h-10 bg-orange-50 text-orange-600 rounded-full flex items-center justify-center mb-1 font-bold text-xs border border-orange-100">Hive</div>
                        <span className="text-[10px] text-slate-400">98% 成功率</span>
                    </div>
                    <div className="flex flex-col items-center mt-[-20px]">
                        <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mb-1 font-bold text-xs border border-blue-100 shadow-md">Main</div>
                        <span className="text-[10px] text-slate-400">核心引擎 V2.0</span>
                    </div>
                    <div className="flex flex-col items-center">
                        <div className="w-10 h-10 bg-red-50 text-red-600 rounded-full flex items-center justify-center mb-1 font-bold text-xs border border-red-100">Oracle</div>
                        <span className="text-[10px] text-slate-400">92% 成功率</span>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-2 gap-3 mt-auto">
                <div className="bg-slate-50 rounded-lg p-3">
                    <div className="text-xs text-slate-400 mb-1">已解析表</div>
                    <div className="text-xl font-bold text-slate-700">14,205</div>
                </div>
                <div className="bg-slate-50 rounded-lg p-3">
                    <div className="text-xs text-slate-400 mb-1">血缘关系数</div>
                    <div className="text-xl font-bold text-slate-700">82,190</div>
                </div>
            </div>
        </GlassCard>
    );
});

const RagStatusCard: React.FC = React.memo(() => {
    return (
        <GlassCard className="p-6 h-full border-none ring-1 ring-black/5 relative overflow-hidden group">
            {/* Ambient Background Blob */}
            <div className="absolute -top-20 -right-20 w-64 h-64 bg-purple-200/30 rounded-full blur-3xl group-hover:bg-purple-200/40 transition-colors duration-700"></div>

            <SectionHeader
                icon={<Box />}
                title="RAG 知识库"
                subtitle="Knowledge Base"
                color="bg-purple-500"
            />

            <div className="flex-1 space-y-4 relative z-10 mt-2">
                <div className="flex items-center gap-3 p-4 rounded-2xl bg-slate-50 border border-slate-100/50">
                    <span className="relative flex h-2.5 w-2.5">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-green-500"></span>
                    </span>
                    <div className="flex-1">
                        <div className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Index Status</div>
                        <div className="text-sm font-bold text-slate-700">Healthy</div>
                    </div>
                    <div className="text-right">
                        <div className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Docs</div>
                        <div className="text-md font-black text-slate-800">2,850</div>
                    </div>
                </div>

                <div className="space-y-2 pt-2">
                    <div className="flex justify-between text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                        <span>Embedding Queue</span>
                        <span className="text-purple-500">Processing</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                        <div className="h-full bg-purple-500 rounded-full w-2/3 animate-pulse"></div>
                    </div>
                </div>
            </div>

            <button className="mt-6 w-full py-3 rounded-xl bg-slate-50 hover:bg-slate-100 text-slate-600 hover:text-purple-600 transition-all text-xs font-bold border border-slate-200/50 flex items-center justify-center gap-2 group/btn">
                <Search size={14} className="group-hover/btn:scale-110 transition-transform" />
                <span>知识检索测试</span>
            </button>
        </GlassCard>
    );
});


// --- Module 3: My Workbench (The Work) ---

const TASKS_DATA = [
    { name: 't_data_sync_daily', type: 'DataX', exec: 'Executor-02', status: 'Running', color: 'blue' },
    { name: 'calc_risk_model_v2', type: 'Python', exec: 'Executor-04', status: 'Success', color: 'green' },
    { name: 'tmp_check_balance', type: 'SQL', exec: 'Executor-01', status: 'Failed', color: 'red' },
];

const MyTasksList: React.FC = React.memo(() => {
    return (
        <GlassCard className="col-span-1 lg:col-span-2 p-6 border-none ring-1 ring-black/5">
            <div className="flex justify-between items-center mb-6">
                <SectionHeader
                    icon={<Terminal />}
                    title="任务实例"
                    subtitle="Execution Instances"
                    color="bg-slate-700"
                />
                <div className="flex gap-2">
                    <button className="p-2 hover:bg-slate-100 rounded-full text-slate-400 hover:text-slate-600 transition-colors">
                        <RefreshCw size={16} />
                    </button>
                </div>
            </div>

            <div className="overflow-x-auto">
                <table className="w-full text-left">
                    <thead>
                        <tr className="border-b border-slate-100 text-xs font-bold text-slate-400 uppercase tracking-wider">
                            <th className="pb-3 pl-2">任务名称</th>
                            <th className="pb-3">类型</th>
                            <th className="pb-3">执行器</th>
                            <th className="pb-3">状态</th>
                            <th className="pb-3 text-right pr-2">操作</th>
                        </tr>
                    </thead>
                    <tbody className="text-sm">
                        {TASKS_DATA.map((task, i) => (
                            <tr key={i} className="group hover:bg-slate-50 transition-colors">
                                <td className="py-3 pl-2 font-medium text-slate-700 flex items-center gap-2">
                                    <div className={`w-1.5 h-1.5 rounded-full bg-${task.color}-500`}></div>
                                    {task.name}
                                </td>
                                <td className="py-3 text-slate-500">{task.type}</td>
                                <td className="py-3 text-slate-500 font-mono text-xs">{task.exec}</td>
                                <td className="py-3">
                                    <span className={`text-xs font-bold px-2 py-0.5 rounded-full bg-${task.color}-50 text-${task.color}-600`}>
                                        {task.status === 'Running' ? '运行中' : task.status === 'Success' ? '成功' : '失败'}
                                    </span>
                                </td>
                                <td className="py-3 text-right pr-2">
                                    <button className="text-xs font-medium text-blue-600 hover:underline">日志</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </GlassCard>
    );
});

// --- Main Component ---

const DevWorkbench: React.FC = () => {
    return (
        <div className="animate-fade-in-up space-y-8 p-2">

            {/* Header Area */}
            <div className="flex items-center justify-between mb-2">
                <div>
                    <h2 className="text-3xl font-black text-slate-900 tracking-tight">研发控制台</h2>
                    <p className="text-sm text-slate-500 font-medium mt-1">Unified Resource Governance System</p>
                </div>
                <div className="flex gap-3">
                    <button className="px-5 py-2.5 bg-white/80 backdrop-blur-md border border-white/50 rounded-full text-sm font-bold text-slate-700 hover:bg-white hover:shadow-lg transition-all flex items-center gap-2">
                        <Play size={16} className="text-blue-500" /> <span className="pt-0.5">新建作业</span>
                    </button>
                    <button className="px-5 py-2.5 bg-black text-white rounded-full text-sm font-bold hover:scale-105 hover:shadow-xl hover:shadow-black/20 transition-all flex items-center gap-2">
                        <Zap size={16} className="text-yellow-400" /> <span className="pt-0.5">快速调试</span>
                    </button>
                </div>
            </div>

            {/* Top Row: System Core (Executor + RAG) */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-auto lg:h-[320px]">
                <div className="lg:col-span-2 h-full">
                    <GitStatsPanel />
                </div>
                <div className="lg:col-span-1 h-full">
                    <RagStatusCard />
                </div>
            </div>

            {/* Bottom Row: Metadata Parsing & Personal Work */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-1">
                    <LineageEngineCard />
                </div>
                <MyTasksList />
            </div>
        </div>
    );
};

export default DevWorkbench;
