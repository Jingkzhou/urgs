import React from 'react';
import { Users, Code2, Network, ShieldCheck } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const RolesPage = () => (
    <SlideLayout title="URGS+: 赋能多元角色生态">
        <div className="grid md:grid-cols-2 gap-8 mt-8">
            {[
                { role: "业务人员 (Business)", value: "理解指标口径，监管填报助手，公告协同。", icon: <Users />, color: "bg-indigo-600" },
                { role: "研发运维 (Dev/Ops)", value: "全流程发布，风险事前阻断，故障探针。", icon: <Code2 />, color: "bg-rose-600" },
                { role: "资产经理 (Asset Mgr)", value: "管理数据资产，掌控全血缘，资产轨迹追踪。", icon: <Network />, color: "bg-teal-600" },
                { role: "管理员 (Admin)", value: "管控资源分配，管理场景 AI 智能体。", icon: <ShieldCheck />, color: "bg-slate-700" },
            ].map((p, i) => (
                <div key={i} className="bg-white p-8 rounded-3xl shadow-md border border-slate-100 flex items-center gap-6 group hover:border-indigo-300 transition-colors anim-fade-up" style={{ animationDelay: `${(i + 2) * 150}ms` }}>
                    <div className={`p-4 rounded-2xl text-white group-hover:scale-110 transition-transform ${p.color}`}>
                        {React.cloneElement(p.icon as React.ReactElement<{ className?: string }>, { className: "w-8 h-8" })}
                    </div>
                    <div>
                        <h4 className="text-2xl font-bold text-indigo-900">{p.role}</h4>
                        <p className="text-slate-600 mt-1 text-sm">{p.value}</p>
                    </div>
                </div>
            ))}
        </div>
    </SlideLayout>
);
