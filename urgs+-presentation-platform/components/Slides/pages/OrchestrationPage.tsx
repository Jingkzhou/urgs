import React from 'react';
import { Calendar, Workflow, Activity } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const OrchestrationPage = () => (
    <SlideLayout title="能力二：自动化运维与协同" subtitle="降低成本，沉淀智慧">
        <div className="flex flex-col md:flex-row gap-12 mt-8">
            <div className="flex-1 space-y-6 anim-fade-right delay-200">
                <div className="p-6 bg-white rounded-2xl border border-slate-100 shadow-sm transition-all hover:bg-rose-50 hover:border-rose-200 hover:shadow-lg group">
                    <div className="flex items-center gap-3 mb-4 text-rose-500 font-bold group-hover:scale-105 transition-transform">
                        <Calendar className="w-6 h-6" /> 监管日历与业务看板
                    </div>
                    <p className="text-slate-600 text-sm leading-relaxed">
                        以日历视图聚合展示“1104 报送”等强关联节点。系统自动联动报送系统状态，通过高亮超期提醒，确保关键窗口零延误。
                    </p>
                </div>
                <div className="p-6 bg-white rounded-2xl border border-slate-100 shadow-sm transition-all hover:bg-indigo-50 hover:border-indigo-200 hover:shadow-lg group">
                    <div className="flex items-center gap-3 mb-4 text-indigo-500 font-bold group-hover:scale-105 transition-transform">
                        <Workflow className="w-6 h-6" /> 可视化任务调度
                    </div>
                    <p className="text-slate-600 text-sm leading-relaxed">
                        负责复杂工作流编排与执行器状态刷新，监控核心取数任务生命周期。
                    </p>
                </div>
            </div>
            <div className="flex-1 anim-scale-in delay-500">
                <div className="bg-slate-900 rounded-3xl p-8 text-white h-full relative group overflow-hidden shadow-2xl">
                    {/* Background decoration */}
                    <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-500/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>

                    {/* Scan line for chart area */}
                    <div className="absolute top-1/2 left-0 w-full h-1 bg-gradient-to-r from-transparent via-white/10 to-transparent animate-[moveHorizontal_4s_linear_infinite] pointer-events-none"></div>

                    <h4 className="text-lg font-bold mb-8 flex items-center gap-2 relative z-10">
                        <Activity className="w-5 h-5 text-indigo-400 animate-pulse" />
                        监管批量作业监控
                    </h4>

                    {/* Bar Chart Area */}
                    <div className="relative z-10 flex items-end justify-between h-48 px-6 pb-6 border-b border-white/10">
                        {[
                            {
                                label: '1104 报送',
                                val: 82,
                                color: 'bg-emerald-400',
                                delay: '0ms',
                                details: [
                                    { l: '月报一批', v: '100% (已完成)' },
                                    { l: '月报二批', v: '100% (已完成)' },
                                    { l: '季报一批', v: '45% (计算中)' }
                                ]
                            },
                            { label: '大集中', val: 100, color: 'bg-indigo-400', delay: '150ms', details: [{ l: '状态', v: '已完成' }] },
                            { label: '金融基础', val: 80, color: 'bg-blue-400', delay: '300ms', details: [{ l: '状态', v: '校验中' }] },
                            { label: 'EAST', val: 0, color: 'bg-slate-600', delay: '450ms', details: [{ l: '状态', v: '未开始' }] },
                        ].map((item, i) => (
                            <div key={i} className="flex flex-col items-center gap-2 group/bar w-1/4">
                                <div className="relative w-full flex justify-center items-end h-32">
                                    {/* Tooltip */}
                                    <div className="absolute bottom-full mb-2 opacity-0 group-hover/bar:opacity-100 transition-all duration-300 translate-y-2 group-hover/bar:translate-y-0 text-xs bg-slate-800/90 backdrop-blur px-3 py-2 rounded-lg border border-white/20 whitespace-nowrap z-20 shadow-xl pointer-events-none">
                                        <div className="font-bold mb-1 border-b border-white/10 pb-1">{item.label}</div>
                                        {item.details.map((d, idx) => (
                                            <div key={idx} className="flex justify-between gap-4 text-slate-300">
                                                <span>{d.l}</span>
                                                <span className="font-mono text-white">{d.v}</span>
                                            </div>
                                        ))}
                                    </div>
                                    {/* Bar */}
                                    <div
                                        className={`w-4 md:w-8 rounded-t-lg transition-all duration-1000 ease-out ${item.color} shadow-[0_0_15px_rgba(255,255,255,0.3)] relative overflow-hidden`}
                                        style={{ height: `${item.val}%`, animation: `grow-y 1s ease-out ${item.delay} backwards` }}
                                    >
                                        {/* Shine effect */}
                                        <div className="absolute inset-0 bg-gradient-to-tr from-transparent via-white/20 to-transparent translate-y-full hover:translate-y-[-200%] transition-transform duration-1000"></div>
                                    </div>
                                </div>
                                <div className="text-[10px] md:text-sm font-medium text-slate-300 text-center truncate w-full">
                                    {item.label}
                                </div>
                            </div>
                        ))}
                    </div>

                    <div className="mt-6 flex justify-between items-center relative z-10">
                        <div className="flex gap-4">
                            <div className="flex items-center gap-2 text-xs text-slate-400">
                                <div className="w-2 h-2 rounded-full bg-emerald-400"></div> 已完成
                            </div>
                            <div className="flex items-center gap-2 text-xs text-slate-400">
                                <div className="w-2 h-2 rounded-full bg-amber-400 animate-pulse"></div> 计算中
                            </div>
                        </div>
                        <div className="text-right">
                            <div className="text-[10px] text-slate-500 uppercase tracking-wider">Total Progress</div>
                            <div className="text-xl font-mono font-bold text-white">85.4%</div>
                        </div>
                    </div>

                    <style>{`
            @keyframes grow-y {
                from { height: 0; opacity: 0; }
            }
             @keyframes moveHorizontal {
                0% { left: -100%; }
                100% { left: 100%; }
             }
          `}</style>
                </div>
            </div>
        </div>
    </SlideLayout>
);
