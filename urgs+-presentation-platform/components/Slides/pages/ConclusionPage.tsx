import React, { useState } from 'react';
import { Sparkles } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';
import { AIJourneyOverlay } from '../shared/AIJourneyOverlay';

export const ConclusionPage = () => {

    const [showAIJourney, setShowAIJourney] = useState(false);

    return (
        <SlideLayout title="开启智能监管新范式" subtitle="构建韧性、敏捷、智慧的运营平台">
            <div className="grid md:grid-cols-3 gap-8 mt-12 mb-16">
                {[
                    { title: "极致效率", items: ["发布流水线，辅助生成代码", "AI 知识检索与智能问答", "监管发文解读"] },
                    { title: "极致稳健", items: ["图谱驱动事前风险阻断", "全量血缘覆盖审计"] },
                    { title: "极致智慧", items: ["RAG 引擎沉淀经验", "多场景 Agent 伴随"] }
                ].map((card, i) => (
                    <div key={i} className="bg-white p-10 rounded-[3rem] shadow-xl border-b-8 border-indigo-600 flex flex-col items-center text-center anim-scale-in" style={{ animationDelay: `${(i + 2) * 200}ms` }}>
                        <h4 className="text-2xl font-bold text-slate-800 mb-8">{card.title}</h4>
                        <ul className="space-y-4 text-slate-500 text-lg">
                            {card.items.map((item, j) => (
                                <li key={j} className="flex gap-2 anim-fade-right" style={{ animationDelay: `${(i + 2) * 200 + (j * 150)}ms` }}>
                                    <span className="text-indigo-600 font-bold">•</span>
                                    {item}
                                </li>
                            ))}
                        </ul>
                    </div>
                ))}
            </div>
            <div className="text-center anim-scale-in delay-1000">
                <button
                    onClick={() => setShowAIJourney(true)}
                    className="group inline-flex items-center gap-4 px-12 py-6 bg-indigo-600 text-white rounded-full text-3xl font-bold shadow-2xl shadow-indigo-200 hover:scale-105 hover:bg-indigo-500 transition-all cursor-pointer animate-float"
                >
                    <Sparkles className="w-8 h-8 animate-pulse text-amber-300" />
                    立即开启 URGS+ 智能之旅
                </button>
            </div>

            {showAIJourney && <AIJourneyOverlay onClose={() => setShowAIJourney(false)} />}
        </SlideLayout>
    );
};
