import React from 'react';
import { Boxes, ShieldAlert, LineChart } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const ChallengePage = () => (
    <SlideLayout title="监管运营的阵痛" subtitle="协同壁垒、隐蔽风险与知识断层">
        <div className="grid md:grid-cols-3 gap-8 mt-4">
            {[
                {
                    icon: <Boxes className="w-16 h-16 text-slate-400 group-hover:text-indigo-400 transition-colors" />,
                    title: "业务与技术协同断层",
                    items: ["业务人员理解不了取数逻辑", "研发对报表口径变动不敏感", "缺乏统一的工作入口与公告协同"]
                },
                {
                    icon: <ShieldAlert className="w-16 h-16 text-amber-500 group-hover:text-amber-400 transition-colors" />,
                    title: "无法感知的变更风险",
                    items: ["底层表改动导致报表大面积失效", "缺乏事前阻断，故障往往在线上爆发", "血缘不透明，影响评估全靠‘猜’"]
                },
                {
                    icon: <LineChart className="w-16 h-16 text-indigo-500 group-hover:text-indigo-400 transition-colors" />,
                    title: "沉没的组织运维成本",
                    items: ["重复问题频繁排查，专家依赖度高", "经验散落在聊天记录，没有知识沉淀", "交付流程繁琐，自动化程度低"]
                }
            ].map((card, idx) => (
                <div
                    key={idx}
                    className={`group bg-white p-8 rounded-3xl shadow-xl border border-slate-100 flex flex-col items-center text-center hover:shadow-2xl hover:bg-slate-50 transition-all duration-300 anim-fade-up`}
                    style={{ animationDelay: `${(idx + 2) * 150}ms` }}
                >
                    <div className="mb-6 animate-float" style={{ animationDelay: `${idx * 200}ms` }}>{card.icon}</div>
                    <h3 className="text-2xl font-bold text-slate-800 mb-6 group-hover:scale-105 transition-transform">{card.title}</h3>
                    <ul className="text-left space-y-4 text-slate-600">
                        {card.items.map((item, i) => (
                            <li key={i} className="flex gap-3 anim-fade-right group-hover:translate-x-1 transition-transform" style={{ animationDelay: `${(idx + 2) * 150 + (i * 100)}ms` }}>
                                <span className="w-1.5 h-1.5 rounded-full bg-slate-300 mt-2.5 flex-shrink-0 group-hover:bg-indigo-400 transition-colors"></span>
                                <span className="text-lg leading-snug">{item}</span>
                            </li>
                        ))}
                    </ul>
                </div>
            ))}
        </div>
    </SlideLayout>
);
