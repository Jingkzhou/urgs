import React from 'react';
import { Bot } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const AiPillarPage = () => (
    <SlideLayout title="能力一：AI 原生增强" subtitle="Ark 智能体赋能全场景">
        <div className="flex flex-col md:flex-row items-center gap-16 mt-8">
            <div className="flex-1 space-y-6 anim-fade-right delay-200">
                <div className="p-6 bg-amber-50 rounded-2xl border border-amber-100">
                    <h5 className="font-bold text-amber-900 mb-2 flex items-center gap-2">
                        <Bot className="w-5 h-5" /> Ark 助手 (RAG & Agent)
                    </h5>
                    <p className="text-xs text-amber-800/80 leading-relaxed">
                        支持 BM25 + 语义向量混合检索。通过对话获取精准上下文建议，绑定专属知识库。
                    </p>
                </div>
                <div className="p-6 bg-slate-50 rounded-2xl border border-slate-200">
                    <h5 className="font-bold text-slate-800 mb-2">多场景化智能体</h5>
                    <div className="flex gap-2 mt-3">
                        <span className="text-[10px] px-2 py-1 bg-white rounded border">1104 填报 Agent</span>
                        <span className="text-[10px] px-2 py-1 bg-white rounded border">调度故障 Agent</span>
                        <span className="text-[10px] px-2 py-1 bg-white rounded border">发布合规 Agent</span>
                    </div>
                </div>
            </div>
            <div className="flex-1 anim-scale-in delay-500">
                <div className="w-80 h-80 bg-gradient-to-br from-amber-400 to-orange-500 rounded-full flex items-center justify-center text-white shadow-2xl animate-pulse">
                    <Bot className="w-40 h-40" />
                </div>
            </div>
        </div>
    </SlideLayout>
);
