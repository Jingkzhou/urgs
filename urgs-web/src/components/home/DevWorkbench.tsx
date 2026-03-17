import React from 'react';
import {
    Activity, Server, Database, Network, Cpu, Layers,
    Play, Clock, Zap, GitBranch, Box, Code,
    Terminal, Search, FileText, Settings, RefreshCw,
    Shield, ArrowUpRight, BarChart2
} from 'lucide-react';


// --- Shared VS Code / Tech Aesthetic Components ---

const GlassCard: React.FC<{ children: React.ReactNode; className?: string }> = React.memo(({ children, className = '' }) => (
    <div className={`bg-white/65 backdrop-blur-3xl border border-white/40 shadow-[0_20px_50px_-12px_rgba(0,0,0,0.08)] rounded-[2.5rem] overflow-hidden ${className}`}>
        {children}
    </div>
));

const SectionHeader: React.FC<{ icon: React.ReactNode; title: string; subtitle: string; color: string }> = React.memo(({ icon, title, subtitle, color }) => (
    <div className="flex items-center gap-4 mb-6">
        <div className={`p-3 rounded-2xl ${color} text-white shadow-[0_10px_20px_-5px_rgba(0,0,0,0.15)] ring-4 ring-white`}>
            {React.cloneElement(icon as React.ReactElement, { size: 20, strokeWidth: 2.5 } as any)}
        </div>
        <div>
            <h3 className="font-black text-slate-800 text-xl tracking-tighter leading-none italic uppercase">{title}</h3>
            <p className="text-[10px] text-slate-400 font-black uppercase tracking-[0.2em] mt-1.5 opacity-60">{subtitle}</p>
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
    <div className="flex items-center justify-between p-4 bg-slate-50/40 rounded-[1.5rem] hover:bg-white hover:shadow-xl hover:shadow-black/5 transition-all duration-500 group border border-transparent hover:border-slate-100/50">
        <div className="flex items-center gap-3">
            <div className="p-2.5 bg-white rounded-xl shadow-sm text-slate-400 group-hover:text-indigo-600 group-hover:scale-110 transition-all duration-500">
                {React.cloneElement(icon as React.ReactElement<any>, { size: 16, strokeWidth: 2.5 })}
            </div>
            <span className="text-[13px] font-black text-slate-600 uppercase tracking-tight">{label}</span>
        </div>
        <div className="text-right">
            <div className="font-black text-slate-900 text-lg tracking-tighter">{value}</div>
            <div className={`text-[9px] font-black uppercase tracking-widest ${trendUp ? 'text-emerald-500' : 'text-slate-400'}`}>
                {trend}
            </div>
        </div>
    </div>
));

const COMMIT_DATA = [12, 45, 30, 60, 25, 80, 45];

const GitStatsPanel: React.FC = React.memo(() => {
    return (
        <GlassCard className="p-8 h-full border-none relative overflow-hidden group/git">
            {/* Background Accent */}
            <div className="absolute -top-24 -right-24 w-64 h-64 bg-indigo-50/50 rounded-full blur-3xl group-hover/git:bg-indigo-100/50 transition-colors duration-1000"></div>

            <SectionHeader
                icon={<GitBranch />}
                title="代码仓库"
                subtitle="Repositories"
                color="bg-gradient-to-br from-slate-800 to-black"
            />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                <div className="p-6 bg-gradient-to-br from-indigo-500 via-indigo-600 to-violet-700 rounded-[2rem] text-white shadow-[0_20px_40px_-10px_rgba(79,70,229,0.3)] relative overflow-hidden group/hero">
                    <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(255,255,255,0.2),transparent)] opacity-0 group-hover/hero:opacity-100 transition-opacity duration-700"></div>
                    <div className="relative z-10">
                        <div className="flex items-center gap-2 text-white/70 text-[10px] font-black uppercase tracking-[0.2em] mb-2">
                            <Zap size={14} fill="currentColor" /> Total Commits
                        </div>
                        <div className="text-4xl font-black tracking-tighter italic mb-1">2,485</div>
                        <div className="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest text-white/90 bg-white/10 w-fit px-3 py-1 rounded-full backdrop-blur-md border border-white/10">
                            <Activity size={12} strokeWidth={3} /> +124 this week
                        </div>
                    </div>
                    <GitBranch className="absolute -bottom-4 -right-4 w-32 h-32 text-white/10 -rotate-12" />
                </div>

                <div className="grid grid-cols-1 gap-3">
                    <GitStatRow label="Active Branches" value="18" trend="+3 New" trendUp={true} icon={<GitBranch />} />
                    <GitStatRow label="Merge Requests" value="5" trend="2 Pending" trendUp={false} icon={<RefreshCw />} />
                </div>
            </div>

            <div className="pt-6 border-t border-slate-100/50 relative z-10">
                <div className="flex justify-between items-center mb-5">
                    <span className="text-[11px] font-black text-slate-800 uppercase tracking-[0.15em] flex items-center gap-2">
                        <Code size={16} strokeWidth={3} className="text-indigo-500" /> Commit Activity
                    </span>
                    <span className="text-[9px] font-black text-slate-400 bg-slate-50 px-3 py-1.5 rounded-full uppercase tracking-widest shadow-inner border border-slate-100/50">Last 7 Days</span>
                </div>
                <div className="flex gap-2 h-14 items-end px-1">
                    {COMMIT_DATA.map((h, i) => (
                        <div key={i} className="flex-1 group relative">
                            <div
                                className="w-full bg-slate-100 group-hover:bg-gradient-to-t group-hover:from-indigo-600 group-hover:to-violet-500 rounded-full transition-all duration-500 relative cursor-pointer"
                                style={{ height: `${h}%` }}
                            >
                                <div className="absolute inset-0 bg-white/20 opacity-0 group-hover:opacity-100 transition-opacity rounded-full"></div>
                            </div>
                            <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-2 py-1 bg-slate-900 text-white text-[9px] font-black rounded-lg opacity-0 group-hover:opacity-100 transition-all duration-300 pointer-events-none shadow-xl scale-90 group-hover:scale-100">
                                {h} COMMITS
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
        <GlassCard className="p-8 h-full border-none relative overflow-hidden group/lineage">
            <div className="absolute top-0 right-0 w-40 h-40 bg-blue-400/10 rounded-full blur-[80px] group-hover/lineage:bg-blue-400/20 transition-colors duration-1000"></div>

            <SectionHeader
                icon={<Network />}
                title="血缘解析"
                subtitle="Lineage Engine"
                color="bg-gradient-to-br from-blue-500 to-indigo-600"
            />

            <div className="relative h-44 flex items-center justify-center mb-6">
                {/* Abstract Interactive Visual */}
                <div className="absolute inset-0 flex items-center justify-center">
                    <div className="w-36 h-36 border border-blue-100/30 rounded-full animate-[spin_10s_linear_infinite]"></div>
                    <div className="w-24 h-24 border border-blue-200/20 rounded-full absolute animate-[spin_6s_linear_infinite_reverse]"></div>
                    <div className="w-48 h-48 border border-blue-50/10 rounded-full absolute"></div>
                </div>

                <div className="relative z-10 grid grid-cols-3 gap-8 text-center">
                    <div className="flex flex-col items-center group/node">
                        <div className="w-12 h-12 bg-orange-50/80 text-orange-600 rounded-2xl flex items-center justify-center mb-2 font-black text-[10px] border border-orange-100 shadow-sm group-hover/node:scale-110 group-hover/node:bg-orange-100 transition-all duration-500 uppercase italic">Hive</div>
                        <span className="text-[9px] text-slate-400 font-black uppercase tracking-widest">98% UP</span>
                    </div>
                    <div className="flex flex-col items-center mt-[-15px] group/node">
                        <div className="w-14 h-14 bg-indigo-50/80 text-indigo-600 rounded-[1.25rem] flex items-center justify-center mb-2 font-black text-[10px] border border-indigo-100 shadow-md group-hover/node:scale-110 group-hover/node:bg-indigo-100 transition-all duration-500 uppercase italic ring-4 ring-white">Main</div>
                        <span className="text-[9px] text-slate-500 font-black uppercase tracking-widest">Engine V2</span>
                    </div>
                    <div className="flex flex-col items-center group/node">
                        <div className="w-12 h-12 bg-red-50/80 text-red-600 rounded-2xl flex items-center justify-center mb-2 font-black text-[10px] border border-red-100 shadow-sm group-hover/node:scale-110 group-hover/node:bg-red-100 transition-all duration-500 uppercase italic">Oracle</div>
                        <span className="text-[9px] text-slate-400 font-black uppercase tracking-widest">92% UP</span>
                    </div>
                </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
                <div className="bg-slate-50/50 backdrop-blur-md rounded-2xl p-4 border border-white/40 shadow-inner group/stat">
                    <div className="text-[9px] font-black text-slate-400 mb-1 uppercase tracking-[0.2em]">Analyzed Tables</div>
                    <div className="text-2xl font-black text-slate-800 tracking-tighter italic group-hover/stat:text-blue-600 transition-colors">14,205</div>
                </div>
                <div className="bg-slate-50/50 backdrop-blur-md rounded-2xl p-4 border border-white/40 shadow-inner group/stat">
                    <div className="text-[9px] font-black text-slate-400 mb-1 uppercase tracking-[0.2em]">Relations</div>
                    <div className="text-2xl font-black text-slate-800 tracking-tighter italic group-hover/stat:text-indigo-600 transition-colors">82,190</div>
                </div>
            </div>
        </GlassCard>
    );
});

const RagStatusCard: React.FC = React.memo(() => {
    return (
        <GlassCard className="p-8 h-full border-none relative overflow-hidden group/rag flex flex-col">
            {/* Ambient Background Blob */}
            <div className="absolute -top-20 -right-20 w-72 h-72 bg-purple-200/20 rounded-full blur-[80px] group-hover/rag:bg-purple-200/40 transition-colors duration-1000"></div>

            <SectionHeader
                icon={<Box />}
                title="RAG 知识库"
                subtitle="Knowledge Base"
                color="bg-gradient-to-br from-purple-500 to-fuchsia-700"
            />

            <div className="flex-1 space-y-5 relative z-10 mt-2">
                <div className="flex items-center gap-4 p-5 rounded-[2rem] bg-white/40 border border-white shadow-xl shadow-black/[0.02]">
                    <span className="relative flex h-3 w-3">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-3 w-3 bg-emerald-500 shadow-[0_0_10px_rgba(16,185,129,0.5)]"></span>
                    </span>
                    <div className="flex-1">
                        <div className="text-[9px] text-slate-400 font-black uppercase tracking-[0.2em] mb-0.5">Index Status</div>
                        <div className="text-[13px] font-black text-slate-800 uppercase tracking-tight">System Healthy</div>
                    </div>
                    <div className="text-right">
                        <div className="text-[9px] text-slate-400 font-black uppercase tracking-[0.2em] mb-0.5">Docs Count</div>
                        <div className="text-lg font-black text-slate-900 tracking-tighter italic">2,850</div>
                    </div>
                </div>

                <div className="space-y-3 pt-2">
                    <div className="flex justify-between text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">
                        <span>Embedding Queue</span>
                        <span className="text-purple-600 animate-pulse">Processing...</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden p-0.5 shadow-inner border border-slate-200/30">
                        <div className="h-full bg-gradient-to-r from-purple-500 to-fuchsia-500 rounded-full w-2/3 shadow-[0_0_15px_rgba(168,85,247,0.4)]"></div>
                    </div>
                </div>
            </div>

            <button className="mt-8 w-full py-4 rounded-[1.5rem] bg-slate-900 text-white hover:bg-black transition-all duration-500 text-[11px] font-black uppercase tracking-[0.25em] border border-white/10 flex items-center justify-center gap-3 group/btn shadow-xl shadow-slate-900/10 active:scale-95">
                <Search size={16} strokeWidth={3} className="group-hover/btn:scale-110 group-hover/btn:rotate-12 transition-all duration-500 text-purple-400" />
                <span>知识测试</span>
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
        <GlassCard className="col-span-1 lg:col-span-2 p-8 border-none relative overflow-hidden group/tasks">
            <div className="flex justify-between items-center mb-8 relative z-10">
                <SectionHeader
                    icon={<Terminal />}
                    title="任务实例"
                    subtitle="Execution Instances"
                    color="bg-slate-900"
                />
                <div className="flex gap-2">
                    <button className="p-3 bg-slate-50 hover:bg-slate-100 rounded-2xl text-slate-400 hover:text-slate-600 transition-all duration-300 shadow-inner border border-slate-100/50 group/refresh">
                        <RefreshCw size={18} className="group-hover/refresh:rotate-180 transition-transform duration-700" />
                    </button>
                </div>
            </div>

            <div className="overflow-x-auto relative z-10">
                <table className="w-full text-left border-separate border-spacing-y-3">
                    <thead>
                        <tr className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">
                            <th className="pb-2 pl-6">Mission / Name</th>
                            <th className="pb-2">Engine</th>
                            <th className="pb-2">Node ID</th>
                            <th className="pb-2">Status</th>
                            <th className="pb-2 text-right pr-6">Management</th>
                        </tr>
                    </thead>
                    <tbody className="text-[13px]">
                        {TASKS_DATA.map((task, i) => (
                            <tr key={i} className="group/row transition-all duration-500">
                                <td className="py-4 pl-6 bg-slate-50/50 group-hover/row:bg-white rounded-l-[1.5rem] border-y border-l border-transparent group-hover/row:border-slate-100 transition-all font-black text-slate-800">
                                    <div className="flex items-center gap-3">
                                        <div className={`w-2.5 h-2.5 rounded-full bg-${task.color}-500 shadow-[0_0_10px_rgba(var(--tw-color-${task.color}-500),0.5)] animate-pulse`}></div>
                                        {task.name}
                                    </div>
                                </td>
                                <td className="py-4 bg-slate-50/50 group-hover/row:bg-white border-y border-transparent group-hover/row:border-slate-100 transition-all font-black text-slate-500 uppercase tracking-tighter italic">{task.type}</td>
                                <td className="py-4 bg-slate-50/50 group-hover/row:bg-white border-y border-transparent group-hover/row:border-slate-100 transition-all font-black text-slate-400 font-mono text-xs">{task.exec}</td>
                                <td className="py-4 bg-slate-50/50 group-hover/row:bg-white border-y border-transparent group-hover/row:border-slate-100 transition-all">
                                    <span className={`text-[10px] font-black uppercase tracking-widest px-3 py-1.5 rounded-full bg-${task.color}-50 text-${task.color}-600 border border-${task.color}-100/50 shadow-sm`}>
                                        {task.status === 'Running' ? 'Executing' : task.status === 'Success' ? 'Complete' : 'Failure'}
                                    </span>
                                </td>
                                <td className="py-4 bg-slate-50/50 group-hover/row:bg-white rounded-r-[1.5rem] border-y border-r border-transparent group-hover/row:border-slate-100 transition-all text-right pr-6">
                                    <button className="text-[11px] font-black text-indigo-600 hover:text-indigo-800 uppercase tracking-widest bg-white group-hover/row:bg-indigo-50 px-3 py-1.5 rounded-xl border border-indigo-100/50 transition-all active:scale-95 shadow-sm">Logs</button>
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
        <div className="animate-fade-in-up space-y-10 p-4 max-w-[1600px] mx-auto">
            {/* Top Row: System Core (Executor + RAG) */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 h-auto">
                <div className="lg:col-span-2">
                    <GitStatsPanel />
                </div>
                <div className="lg:col-span-1">
                    <RagStatusCard />
                </div>
            </div>

            {/* Bottom Row: Metadata Parsing & Personal Work */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-1">
                    <LineageEngineCard />
                </div>
                <MyTasksList />
            </div>
        </div>
    );
};

export default DevWorkbench;
