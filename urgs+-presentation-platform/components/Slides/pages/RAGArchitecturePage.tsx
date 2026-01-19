import React from 'react';
import { SlideLayout } from '../layout/SlideLayout';
import { Database, FileText, Search, Zap, Layers, Cpu, ArrowRight, GitMerge, Filter, BrainCircuit, ScanLine, ArrowLeft, CheckCircle2 } from 'lucide-react';

interface RAGArchitecturePageProps {
    onBack?: () => void;
}

export const RAGArchitecturePage = ({ onBack }: RAGArchitecturePageProps) => {
    return (
        <div className="w-full h-full bg-[#F5F5F7] text-slate-900 font-sans relative flex flex-col overflow-hidden">
            {/* 1. Top Navigation Bar (Fixed/Sticky behavior visual) */}
            <div className="flex-none px-6 py-4 bg-white/80 backdrop-blur-md border-b border-slate-200 z-50 flex items-center justify-between sticky top-0">
                <div className="flex items-center gap-4">
                    {onBack && (
                        <button
                            onClick={onBack}
                            className="group flex items-center gap-2 px-3 py-1.5 bg-white hover:bg-slate-50 border border-slate-200 rounded-lg shadow-sm hover:shadow transition-all text-slate-600 hover:text-slate-900"
                        >
                            <ArrowLeft className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
                            <span className="text-sm font-medium">返回</span>
                        </button>
                    )}
                    <h1 className="text-xl font-semibold text-slate-900 tracking-tight">URGS RAG 架构</h1>
                </div>
                <div className="text-sm text-slate-500 font-medium">高性能检索生成系统</div>
            </div>

            {/* 2. Main Content Area */}
            <div className="flex-1 overflow-y-auto overflow-x-hidden">
                <div className="max-w-7xl mx-auto px-6 py-8 space-y-8">

                    {/* Header Section */}
                    <div className="text-center mb-10">
                        <h2 className="text-3xl font-bold text-slate-900 mb-3">智能时代的知识大脑</h2>
                        <p className="text-lg text-slate-500 max-w-2xl mx-auto">
                            基于多路混合检索与父子文档架构，打造精准、可靠的监管知识问答引擎。
                        </p>
                    </div>

                    {/* Core Objectives Cards */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <FeatureCard
                            icon={<Search className="w-6 h-6 text-blue-500" />}
                            title="精准度 (Precision)"
                            desc="逻辑增强 + 多路检索，解决复杂逻辑不足"
                        />
                        <FeatureCard
                            icon={<CheckCircle2 className="w-6 h-6 text-green-500" />}
                            title="可靠性 (Reliability)"
                            desc="精确引用溯源 (Citations)，大幅减少幻觉"
                        />
                        <FeatureCard
                            icon={<Zap className="w-6 h-6 text-amber-500" />}
                            title="高效性 (Efficiency)"
                            desc="异步流水线 + 分级索引，亿级数据毫秒响应"
                        />
                    </div>

                    {/* Main Architecture Flow */}
                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                        {/* Left: Ingestion Pipeline (5 cols) */}
                        <div className="lg:col-span-5 flex flex-col">
                            <div className="mb-4 flex items-center gap-2">
                                <div className="p-1.5 bg-blue-100 text-blue-600 rounded-lg"><Layers className="w-5 h-5" /></div>
                                <h3 className="text-lg font-semibold text-slate-800">智能化向量化流水线</h3>
                            </div>

                            <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-200 flex-1 relative overflow-hidden group">
                                <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-blue-400 to-indigo-500 opacity-0 group-hover:opacity-100 transition-opacity"></div>
                                <div className="space-y-6 relative z-10">
                                    <PipelineStep
                                        num="01"
                                        title="多模态解析 & 清洗"
                                        detail="Unstructured 解析 PDF/Word，RapidOCR 识别图片，LLM 语义降噪"
                                        color="blue"
                                    />
                                    <div className="flex justify-center opacity-20"><ArrowRight className="rotate-90 text-slate-400" /></div>
                                    <PipelineStep
                                        num="02"
                                        title="父子文档切分 (Parent-Child)"
                                        detail="子文档 (400 chars) 用于精准检索，父文档提供完整上下文"
                                        color="indigo"
                                    />
                                    <div className="flex justify-center opacity-20"><ArrowRight className="rotate-90 text-slate-400" /></div>
                                    <PipelineStep
                                        num="03"
                                        title="多维特征索引"
                                        detail="生成语义向量、逻辑核索引 (Q-to-Q)、全篇摘要索引"
                                        color="violet"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Right: Retrieval Strategy (7 cols) */}
                        <div className="lg:col-span-7 flex flex-col">
                            <div className="mb-4 flex items-center gap-2">
                                <div className="p-1.5 bg-indigo-100 text-indigo-600 rounded-lg"><BrainCircuit className="w-5 h-5" /></div>
                                <h3 className="text-lg font-semibold text-slate-800">深度优化检索策略</h3>
                            </div>

                            <div className="bg-white rounded-3xl p-8 shadow-sm border border-slate-200 flex-1 flex flex-col items-center relative overflow-hidden">
                                {/* Visual Funnel Representation */}
                                <div className="w-full flex justify-between gap-3 mb-6">
                                    {['语义检索', '关键词检索', '逻辑检索', '摘要检索'].map((t, i) => (
                                        <div key={i} className="flex-1 py-3 text-center bg-slate-50 border border-slate-100 rounded-xl text-xs font-semibold text-slate-600 shadow-sm">
                                            {t}
                                        </div>
                                    ))}
                                </div>

                                {/* Merge Layer */}
                                <div className="w-4/5 h-20 bg-gradient-to-b from-slate-100 to-white border-x border-b border-slate-200 rounded-b-3xl flex items-center justify-center mb-6 relative shadow-inner">
                                    <div className="text-center">
                                        <div className="text-sm font-bold text-slate-700">自适应加权合并 (Adaptive Weighting)</div>
                                        <div className="text-[10px] text-slate-400 mt-1">Weight: 0.6 Semantic / 0.4 Keyword</div>
                                    </div>
                                    {/* Flow lines */}
                                    <div className="absolute top-0 left-1/4 h-full w-[1px] bg-slate-200/50"></div>
                                    <div className="absolute top-0 right-1/4 h-full w-[1px] bg-slate-200/50"></div>
                                </div>

                                <ArrowRight className="rotate-90 text-slate-300 w-5 h-5 mb-6" />

                                {/* Rerank Layer */}
                                <div className="w-3/5 bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-100 rounded-2xl p-4 text-center shadow-sm">
                                    <div className="flex items-center justify-center gap-2 text-amber-900 font-bold text-sm">
                                        <ScanLine className="w-4 h-4" /> 深度重排 (Cross-Encoder)
                                    </div>
                                    <div className="text-xs text-amber-700/70 mt-1">全注意力机制 (Full-Attention) 二次精排</div>
                                </div>

                                <div className="mt-8 pt-6 border-t border-slate-100 w-full">
                                    <div className="flex flex-wrap gap-2 justify-center">
                                        {["LangChain", "ChromaDB", "BGE-M3", "RapidOCR", "FastAPI"].map((tag, i) => (
                                            <span key={i} className="px-3 py-1 bg-slate-50 text-slate-500 rounded-full text-xs font-medium border border-slate-100">
                                                {tag}
                                            </span>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Visual Footer Spacer */}
                <div className="h-12 w-full"></div>
            </div>
        </div>
    );
};

// Helper Components
const FeatureCard = ({ icon, title, desc }: { icon: React.ReactNode, title: string, desc: string }) => (
    <div className="bg-white p-6 rounded-2xl shadow-[0_2px_8px_rgba(0,0,0,0.04)] border border-slate-100 hover:shadow-[0_4px_12px_rgba(0,0,0,0.06)] hover:-translate-y-0.5 transition-all duration-300">
        <div className="mb-4 bg-slate-50 w-12 h-12 rounded-xl flex items-center justify-center border border-slate-100">
            {icon}
        </div>
        <h3 className="font-bold text-slate-900 mb-2">{title}</h3>
        <p className="text-sm text-slate-500 leading-relaxed">{desc}</p>
    </div>
);

const PipelineStep = ({ num, title, detail, color }: { num: string, title: string, detail: string, color: string }) => {
    const colorMap: Record<string, string> = {
        blue: "text-blue-500 bg-blue-50",
        indigo: "text-indigo-500 bg-indigo-50",
        violet: "text-violet-500 bg-violet-50"
    };

    return (
        <div className="flex gap-4 items-start group p-3 hover:bg-slate-50 rounded-xl transition-colors">
            <div className={`text-lg font-bold ${colorMap[color]} w-10 h-10 rounded-lg flex items-center justify-center shrink-0`}>
                {num}
            </div>
            <div>
                <h4 className="font-bold text-slate-800 text-sm mb-1">{title}</h4>
                <p className="text-xs text-slate-500 leading-relaxed">{detail}</p>
            </div>
        </div>
    );
};
