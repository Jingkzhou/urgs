import React from 'react';
import { SlideLayout } from '../layout/SlideLayout';
import { SimulatedAIChat } from '../shared/SimulatedAIChat';

export const AIExperiencePage = () => (
    <SlideLayout title="AI 原生问答体验" subtitle="自然语言驱动的监管资产探索">
        <div className="flex flex-col lg:flex-row items-center justify-center gap-12 w-full mt-4">
            <div className="flex-1 space-y-8 anim-fade-right delay-200 max-w-xl">
                <div className="space-y-4">
                    <h4 className="text-3xl font-bold text-slate-800 leading-tight">
                        像聊天一样<br />
                        <span className="text-indigo-600">掌控监管合规</span>
                    </h4>
                    <p className="text-slate-500 text-lg leading-relaxed">
                        无需编写 SQL，无需翻阅厚重的手册。通过 Ark Agent，直接对话生产环境元数据。
                    </p>
                </div>

                <div className="grid grid-cols-1 gap-4">
                    {[
                        { title: "跨域知识检索", desc: "混合语义检索，打通监管规章与技术资产。", color: "text-amber-500" },
                        { title: "自动代码解析", desc: "实时将 OLAP 逻辑降维展示。", color: "text-indigo-500" },
                        { title: "预测性建议", desc: "根据历史数据，自动推送可能的操作风险点。", color: "text-teal-500" }
                    ].map((item, i) => (
                        <div key={i} className="flex gap-4 p-5 bg-white rounded-2xl border border-slate-100 shadow-sm hover:shadow-md transition-shadow">
                            <div className={`shrink-0 w-1 p-0.5 rounded-full ${item.color.replace('text', 'bg')}`}></div>
                            <div>
                                <h5 className="font-bold text-slate-800 text-sm">{item.title}</h5>
                                <p className="text-xs text-slate-500 mt-1">{item.desc}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            <div className="flex-1 flex justify-center items-center anim-scale-in delay-500">
                <SimulatedAIChat scenario={[
                    { role: 'user', content: 'URGS+，请分析 2024 年第四季度监管报表中的数据异常。' },
                    { role: 'ai', content: '正在扫描 Q4 监管报送集群... 发现 G0102 报表与底层 A 类模型存在 3.2% 的金额偏差。可能原因：12月15日的 SQL 变更移除了部分抵押物过滤逻辑。建议回溯血缘图谱或运行 AI 发布审计。' }
                ]} />
            </div>
        </div>
    </SlideLayout>
);
