import React from 'react';
import { Bot, Workflow, Network, ShieldCheck } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const PillarsPage = () => (
    <SlideLayout title="URGS+ 的四大核心能力">
        <div className="grid md:grid-cols-4 gap-6 mt-12 perspective-1000">
            {[
                { icon: <Bot />, title: "AI 赋能", desc: "RAG 助手与经验自动沉淀", color: "text-amber-500", border: "border-amber-200", shadow: "shadow-amber-100" },
                { icon: <Workflow />, title: "一体化协同", desc: "流程自动化与公告管理", color: "text-rose-500", border: "border-rose-200", shadow: "shadow-rose-100" },
                { icon: <Network />, title: "资产管理", desc: "图谱化血缘、监管指标、监管集市管理", color: "text-teal-500", border: "border-teal-200", shadow: "shadow-teal-100" },
                { icon: <ShieldCheck />, title: "风险防控与版本管理", desc: "变更事前阻断与 AI 审计", color: "text-indigo-500", border: "border-indigo-200", shadow: "shadow-indigo-100" },
            ].map((p, idx) => (
                <div
                    key={idx}
                    className={`bg-white p-8 rounded-3xl shadow-lg border-t-4 ${p.border} flex flex-col items-center text-center anim-scale-in group hover:-translate-y-3 hover:shadow-2xl hover:bg-gradient-to-b hover:from-white hover:to-slate-50 transition-all duration-500`}
                    style={{ animationDelay: `${idx * 150}ms` }}
                >
                    <div className={`mb-6 animate-float ${p.color} bg-slate-50 p-4 rounded-full group-hover:bg-white group-hover:shadow-md transition-all`}>{React.cloneElement(p.icon as React.ReactElement<{ className?: string }>, { className: "w-10 h-10" })}</div>
                    <h3 className="text-xl font-bold text-slate-800 mb-2 group-hover:text-black transition-colors">{p.title}</h3>
                    <p className="text-sm text-slate-500 leading-snug">{p.desc}</p>
                </div>
            ))}
        </div>
    </SlideLayout>
);
