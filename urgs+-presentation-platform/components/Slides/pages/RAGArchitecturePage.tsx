import React from 'react';
import { SlideLayout } from '../layout/SlideLayout';
import { Database, FileText, Search, Zap, Layers, Cpu, ArrowRight, GitMerge, Filter, BrainCircuit, ScanLine } from 'lucide-react';

export const RAGArchitecturePage = () => {
    return (
        <SlideLayout title="URGS 高性能 RAG 系统技术架构设计与实现">
            <div className="flex flex-col h-full gap-4 relative overflow-hidden">
                {/* Background Decor */}
                <div className="absolute top-0 right-0 w-96 h-96 bg-blue-500/5 rounded-full blur-3xl -z-10 animate-pulse"></div>

                {/* 1. Core Objectives - As a top bar */}
                <div className="grid grid-cols-3 gap-6 mb-2">
                    {[
                        { icon: <Search className="w-5 h-5 text-cyan-400" />, title: "精准度 (Precision)", desc: "逻辑增强 + 多路检索，解决复杂逻辑不足" },
                        { icon: <ShieldCheckIcon className="w-5 h-5 text-emerald-400" />, title: "可靠性 (Reliability)", desc: "引用溯源 (Citations)，减少模型幻觉" },
                        { icon: <Zap className="w-5 h-5 text-amber-400" />, title: "高效性 (Efficiency)", desc: "异步流水线 + 分级索引，大规模快速检索" }
                    ].map((item, idx) => (
                        <div key={idx} className="bg-slate-800/50 backdrop-blur-sm border border-slate-700/50 rounded-lg p-3 flex items-start gap-3 shadow-lg hover:border-indigo-500/50 transition-all group">
                            <div className="p-2 bg-slate-900 rounded-md group-hover:bg-slate-800 transition-colors">{item.icon}</div>
                            <div>
                                <div className="font-bold text-slate-100 text-sm">{item.title}</div>
                                <div className="text-xs text-slate-400 mt-0.5">{item.desc}</div>
                            </div>
                        </div>
                    ))}
                </div>

                <div className="grid grid-cols-12 gap-6 flex-1 min-h-0">
                    {/* 2. Ingestion Pipeline (Left) */}
                    <div className="col-span-5 flex flex-col gap-3 relative">
                        <SectionTitle icon={<Layers className="w-4 h-4" />} title="智能化向量化流水线 (Ingestion Pipeline)" />

                        <div className="flex-1 bg-slate-900/40 border border-slate-700/50 rounded-xl p-4 relative overflow-hidden group">
                            {/* Scanning line for ingestion */}
                            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-cyan-500 to-transparent opacity-20 group-hover:top-full transition-all duration-[3s] ease-linear"></div>

                            <div className="space-y-4">
                                {/* Step 1: Parsing */}
                                <PipelineStep
                                    step="01"
                                    title="多模态解析 & 质量治理"
                                    items={[
                                        "Unstructured + LangChain (PDF/Office/SQL)",
                                        "RapidOCR: 自动识别扫描件/图片",
                                        "LLM 语义清洗: 降噪、纠错、补全语义"
                                    ]}
                                    color="text-blue-400"
                                />
                                <ArrowDown />
                                {/* Step 2: Parent-Child */}
                                <PipelineStep
                                    step="02"
                                    title="父子文档架构 (Parent-Child)"
                                    items={[
                                        "RecursiveCharacterTextSplitter",
                                        "子文档 (Child): ~400 chars (检索粒度)",
                                        "父文档 (Parent): 完整段落 (生成上下文)"
                                    ]}
                                    color="text-indigo-400"
                                />
                                <ArrowDown />
                                {/* Step 3: Multi-Vector */}
                                <PipelineStep
                                    step="03"
                                    title="多维特征增强 (Multi-Vector)"
                                    items={[
                                        "语义索引 (_semantic): 基础含义",
                                        "逻辑核索引 (_logic): Q-to-Q 匹配",
                                        "摘要索引 (_summary): 全局概括"
                                    ]}
                                    color="text-purple-400"
                                />
                            </div>
                        </div>
                    </div>

                    {/* 3. Retrieval Strategy (Right) */}
                    <div className="col-span-7 flex flex-col gap-3 relative">
                        <SectionTitle icon={<BrainCircuit className="w-4 h-4" />} title="深度优化检索策略 (Retrieval Strategy)" />

                        <div className="flex-1 bg-slate-900/40 border border-slate-700/50 rounded-xl p-0 relative flex flex-col overflow-hidden">
                            {/* Funnel Visual */}
                            <div className="flex-1 p-5 flex flex-col items-center justify-center relative">

                                {/* Lay 1: 4-Way Search */}
                                <div className="w-full flex justify-between gap-2 mb-2">
                                    {["语义路 (Dense)", "关键词 (BM25)", "逻辑路 (Logic)", "摘要路 (Summary)"].map((t, i) => (
                                        <div key={i} className="flex-1 bg-slate-800 border border-slate-600 rounded px-2 py-2 text-center text-xs font-mono text-slate-300 shadow-md">
                                            {t}
                                        </div>
                                    ))}
                                </div>

                                {/* Funnel Body */}
                                <div className="w-full max-w-[80%] h-24 bg-gradient-to-b from-slate-800/80 to-indigo-900/50 clip-path-funnel backdrop-blur-sm border-x border-slate-600/30 flex items-center justify-center text-center relative my-1">
                                    <div className="text-xs font-bold text-slate-200 z-10">
                                        自适应加权合并 (Adaptive Weighting)<br /> <span className="text-[10px] text-slate-400 font-normal">0.6 Semantic + 0.4 Keyword</span>
                                    </div>
                                    {/* Flow particles */}
                                    <div className="absolute inset-0 overflow-hidden opacity-30">
                                        <div className="absolute top-0 left-1/4 w-0.5 h-full bg-blue-400/50 animate-rain"></div>
                                        <div className="absolute top-0 left-3/4 w-0.5 h-full bg-blue-400/50 animate-rain delay-700"></div>
                                    </div>
                                </div>

                                <ArrowDown small />

                                {/* Lay 3: Rerank */}
                                <div className="w-full max-w-[60%] bg-gradient-to-r from-amber-900/40 to-orange-900/40 border border-amber-700/50 rounded-lg p-3 text-center shadow-[0_0_15px_rgba(245,158,11,0.2)] anim-pulse-slow">
                                    <div className="text-sm font-bold text-amber-100 flex items-center justify-center gap-2">
                                        <ScanLine className="w-4 h-4" /> 深度重排 (Cross-Encoder)
                                    </div>
                                    <div className="text-[10px] text-amber-200/70 mt-1">Full-Attention 二次校准</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* 4. Tech Stack Footer */}
                <div className="bg-slate-900/60 border border-slate-800 rounded-lg p-3 flex justify-between items-center px-6">
                    <span className="text-xs font-bold text-slate-500 uppercase tracking-wider mr-4">Powering Technology</span>
                    <div className="flex gap-6 items-center flex-1 justify-end">
                        {["LangChain (Orchestration)", "Unstructured (ETL)", "RapidOCR (Vision)", "ChromaDB (Vector)", "Sentence-Transformers (Bi-Encoder)", "Shelve (Persistence)"].map((tech, i) => (
                            <div key={i} className="flex items-center gap-1.5 text-xs text-slate-300 bg-slate-800/50 px-2 py-1 rounded border border-slate-700/50">
                                <div className="w-1.5 h-1.5 rounded-full bg-cyan-500"></div>
                                {tech}
                            </div>
                        ))}
                    </div>
                </div>

                <style>{`
                    .clip-path-funnel {
                        clip-path: polygon(0% 0%, 100% 0%, 85% 100%, 15% 100%);
                    }
                    @keyframes rain {
                        0% { transform: translateY(-100%); opacity: 0; }
                        50% { opacity: 1; }
                        100% { transform: translateY(100%); opacity: 0; }
                    }
                    .animate-rain { animation: rain 2s linear infinite; }
                    .anim-pulse-slow { animation: pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite; }
                `}</style>
            </div>
        </SlideLayout>
    );
};

// Sub-components for cleaner code
const SectionTitle = ({ icon, title }: { icon: React.ReactNode, title: string }) => (
    <div className="flex items-center gap-2 text-slate-200 border-b border-slate-700/50 pb-2">
        <div className="p-1.5 bg-indigo-500/20 rounded text-indigo-400">{icon}</div>
        <h3 className="font-bold text-sm tracking-wide">{title}</h3>
    </div>
);

const PipelineStep = ({ step, title, items, color }: { step: string, title: string, items: string[], color: string }) => (
    <div className="flex gap-3 items-start group/step hover:bg-white/5 p-2 rounded transition-colors cursor-default">
        <div className={`text-xl font-black opacity-30 ${color} font-mono`}>{step}</div>
        <div>
            <div className={`font-bold text-sm text-slate-200 mb-1 group-hover/step:text-white transition-colors`}>{title}</div>
            <ul className="space-y-1">
                {items.map((it, i) => (
                    <li key={i} className="text-[11px] text-slate-400 pl-2 border-l border-slate-700 flex items-center gap-2">
                        {it.includes(":") ? (
                            <>
                                <span className="font-semibold text-slate-300">{it.split(":")[0]}</span>
                                <span className="opacity-70">{it.split(":")[1]}</span>
                            </>
                        ) : it}
                    </li>
                ))}
            </ul>
        </div>
    </div>
);

const ArrowDown = ({ small }: { small?: boolean }) => (
    <div className={`flex justify-center opacity-30 ${small ? 'my-1' : ''}`}>
        <ArrowRight className={`rotate-90 text-slate-500 ${small ? 'w-3 h-3' : 'w-4 h-4'}`} />
    </div>
);

const ShieldCheckIcon = (props: any) => (
    <svg
        {...props}
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
    >
        <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z" />
        <path d="m9 12 2 2 4-4" />
    </svg>
)
