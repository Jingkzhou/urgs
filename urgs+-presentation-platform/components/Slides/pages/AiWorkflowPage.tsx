import React from 'react';
import { Zap, BookOpen, Bot } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const AiWorkflowPage = () => (
    <SlideLayout title="能力联动：智能工作流闭环">
        <div className="grid md:grid-cols-3 gap-8 mt-12">
            {[
                { title: "代码“翻译”器", desc: "利用 AI 将复杂的 SQL 代码翻译为自然语言描述，赋能业务理解。", icon: <Zap className="text-indigo-500" /> },
                { title: "故障自动转知识", desc: "问题解决后‘一键’总结为‘现象-原因-对策’存入知识库。", icon: <BookOpen className="text-teal-500" /> },
                { title: "场景 Agent 联动", desc: "1104 填报助手在填报页面自动弹出合规建议。", icon: <Bot className="text-amber-500" /> }
            ].map((card, i) => (
                <div key={i} className="bg-white p-8 rounded-3xl shadow-lg border border-slate-100 hover:shadow-xl transition-all anim-scale-in" style={{ animationDelay: `${(i + 2) * 200}ms` }}>
                    <div className="p-4 bg-slate-50 w-fit rounded-2xl mb-6 animate-float">{card.icon}</div>
                    <h4 className="text-xl font-bold text-slate-800 mb-4">{card.title}</h4>
                    <p className="text-slate-500 text-sm leading-relaxed">{card.desc}</p>
                </div>
            ))}
        </div>
    </SlideLayout>
);
