import React from 'react';
import { ShieldAlert, Zap, Cpu, Boxes, Bot, LayoutDashboard, Network, ShieldCheck, Users, ChevronRight } from 'lucide-react';

export const TableOfContentsPage = ({ onNavigate }: { onNavigate: (index: number) => void }) => (
    <div className="relative w-screen h-screen overflow-hidden bg-slate-50 flex flex-col items-center justify-center text-slate-800">
        {/* Clean, light background with subtle pattern */}
        <div className="absolute inset-0 bg-slate-50 z-0"></div>
        <div className="absolute inset-0 z-0 opacity-[0.03]"
            style={{ backgroundImage: 'radial-gradient(circle at 50% 50%, #4f46e5 1px, transparent 1px)', backgroundSize: '24px 24px' }}>
        </div>

        {/* Decoration Blobs */}
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-indigo-100/40 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>
        <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-teal-100/40 rounded-full blur-3xl translate-y-1/2 -translate-x-1/2"></div>

        <div className="relative z-10 w-full max-w-7xl px-8 h-full flex flex-col pt-16 md:pt-24">
            <div className="text-center mb-12 space-y-3">
                <h2 className="text-4xl md:text-5xl font-black tracking-tight text-slate-900">
                    SYSTEM MODULES
                </h2>
                <p className="text-slate-400 text-sm font-bold uppercase tracking-[0.2em]">
                    Select Activation Node
                </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {[
                    { id: "01", title: "背景与挑战", sub: "Operational Pain Points", index: 2, color: "text-rose-500", bg: "bg-rose-50 hover:bg-rose-100", border: "border-rose-100 hover:border-rose-200", icon: <ShieldAlert className="w-8 h-8" /> },
                    { id: "02", title: "产品愿景", sub: "Core Vision & Philosophy", index: 3, color: "text-indigo-500", bg: "bg-indigo-50 hover:bg-indigo-100", border: "border-indigo-100 hover:border-indigo-200", icon: <Zap className="w-8 h-8" /> },
                    { id: "03", title: "技术架构", sub: "System Architecture", index: 4, color: "text-slate-600", bg: "bg-slate-50 hover:bg-slate-100", border: "border-slate-200 hover:border-slate-300", icon: <Cpu className="w-8 h-8" /> },
                    { id: "04", title: "四大支柱", sub: "Core Capability Matrix", index: 5, color: "text-teal-600", bg: "bg-teal-50 hover:bg-teal-100", border: "border-teal-100 hover:border-teal-200", icon: <Boxes className="w-8 h-8" /> },
                    { id: "05", title: "AI 赋能", sub: "RAG & Agent System", index: 6, color: "text-amber-500", bg: "bg-amber-50 hover:bg-amber-100", border: "border-amber-100 hover:border-amber-200", icon: <Bot className="w-8 h-8" /> },
                    { id: "06", title: "自动化协同", sub: "Automation & Cockpit", index: 9, color: "text-indigo-600", bg: "bg-indigo-50 hover:bg-indigo-100", border: "border-indigo-100 hover:border-indigo-200", icon: <LayoutDashboard className="w-8 h-8" /> },
                    { id: "07", title: "资产管理", sub: "Data Assets & Lineage", index: 11, color: "text-cyan-600", bg: "bg-cyan-50 hover:bg-cyan-100", border: "border-cyan-100 hover:border-cyan-200", icon: <Network className="w-8 h-8" /> },
                    { id: "08", title: "风险防控", sub: "Risk Control & Versioning", index: 13, color: "text-blue-600", bg: "bg-blue-50 hover:bg-blue-100", border: "border-blue-100 hover:border-blue-200", icon: <ShieldCheck className="w-8 h-8" /> },
                    { id: "09", title: "生态价值", sub: "Ecosystem Value", index: 14, color: "text-violet-600", bg: "bg-violet-50 hover:bg-violet-100", border: "border-violet-100 hover:border-violet-200", icon: <Users className="w-8 h-8" /> },
                ].map((item, idx) => (
                    <div
                        key={idx}
                        onClick={() => onNavigate(item.index)}
                        className={`group relative ${item.bg} p-6 rounded-2xl border ${item.border} transition-all duration-300 cursor-pointer flex items-center gap-6 anim-fade-up shadow-sm hover:shadow-xl hover:-translate-y-1 overflow-hidden`}
                        style={{ animationDelay: `${idx * 50}ms` }}
                    >
                        {/* Icon Box */}
                        <div className={`${item.color} p-3 bg-white rounded-xl shadow-sm border border-white group-hover:scale-110 transition-transform duration-300`}>
                            {item.icon}
                        </div>

                        <div className="flex-1 z-10">
                            <div className="flex justify-between items-center mb-1">
                                <h3 className={`text-lg font-bold text-slate-800 transition-colors tracking-tight`}>{item.title}</h3>
                                <span className="text-[10px] font-bold opacity-40 text-slate-500 bg-white px-1.5 py-0.5 rounded-full shadow-sm">{item.id}</span>
                            </div>
                            <p className="text-xs font-semibold text-slate-400 uppercase tracking-tight truncate">{item.sub}</p>
                        </div>

                        <ChevronRight className={`w-5 h-5 text-slate-300 group-hover:text-slate-500 group-hover:translate-x-1 transition-all`} />
                    </div>
                ))}
            </div>
        </div>
    </div>
);
