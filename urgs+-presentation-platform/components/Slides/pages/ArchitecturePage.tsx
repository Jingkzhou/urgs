import React from 'react';
import { Sparkles, Layout, Server, Network, Bot, Cpu, Database, Globe, Zap, ArrowDown, ArrowUp, Share2, HardDrive } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const ArchitecturePage = () => (
    <SlideLayout title="URGS+ 微服务架构全景">
        <div className="w-full h-[750px] relative flex flex-col items-center justify-start pt-2">

            {/* Background Effects */}
            <div className="absolute inset-0 pointer-events-none overflow-hidden">
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] bg-indigo-500/5 rounded-full blur-3xl animate-pulse"></div>
                <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-slate-50 via-slate-100 to-slate-200 opacity-50 -z-10"></div>
            </div>

            {/* Connecting Lines (SVG Layer) */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none z-0" xmlns="http://www.w3.org/2000/svg">
                {/* Center to Top (Web to API) - Short line */}
                <path d="M 640 145 L 640 160" stroke="url(#gradBlue)" strokeWidth="2" strokeDasharray="4 4" className="animate-[dash_1s_linear_infinite]" />

                {/* API to Engines */}
                {/* Left: API Left-Bottom to Lineage Top */}
                <path d="M 580 280 L 400 370" stroke="url(#gradCyan)" strokeWidth="2" strokeDasharray="4 4" className="animate-[dash_1.5s_linear_infinite]" />
                {/* Middle: API Bottom to RAG Top */}
                <path d="M 640 320 L 640 370" stroke="url(#gradAmber)" strokeWidth="2" strokeDasharray="4 4" className="animate-[dash_1.2s_linear_infinite]" />
                {/* Right: API Right-Bottom to Executor Top */}
                <path d="M 700 280 L 880 370" stroke="url(#gradRose)" strokeWidth="2" strokeDasharray="4 4" className="animate-[dash_1.5s_linear_infinite]" />

                {/* Engines to Databases Connections */}
                {/* Left: Lineage to Neo4j */}
                <path d="M 400 480 L 400 520" stroke="url(#gradCyan)" strokeWidth="2" strokeDasharray="4 4" className="animate-[dash_1s_linear_infinite]" />
                {/* Middle: RAG to ChromaDB */}
                <path d="M 640 480 L 640 520" stroke="url(#gradAmber)" strokeWidth="2" strokeDasharray="4 4" className="animate-[dash_1s_linear_infinite]" />
                {/* Right: Executor to MySQL */}
                <path d="M 880 480 L 880 520" stroke="url(#gradRose)" strokeWidth="2" strokeDasharray="4 4" className="animate-[dash_1s_linear_infinite]" />

                <defs>
                    <linearGradient id="gradBlue" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" stopColor="#6366f1" stopOpacity="0" />
                        <stop offset="50%" stopColor="#6366f1" stopOpacity="1" />
                        <stop offset="100%" stopColor="#6366f1" stopOpacity="0" />
                    </linearGradient>
                    <linearGradient id="gradCyan" x1="100%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" stopColor="#06b6d4" stopOpacity="0" />
                        <stop offset="50%" stopColor="#06b6d4" stopOpacity="1" />
                        <stop offset="100%" stopColor="#06b6d4" stopOpacity="0" />
                    </linearGradient>
                    <linearGradient id="gradAmber" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" stopColor="#f59e0b" stopOpacity="0" />
                        <stop offset="50%" stopColor="#f59e0b" stopOpacity="1" />
                        <stop offset="100%" stopColor="#f59e0b" stopOpacity="0" />
                    </linearGradient>
                    <linearGradient id="gradRose" x1="0%" y1="0%" x2="100%" y2="100%">
                        <stop offset="0%" stopColor="#f43f5e" stopOpacity="0" />
                        <stop offset="50%" stopColor="#f43f5e" stopOpacity="1" />
                        <stop offset="100%" stopColor="#f43f5e" stopOpacity="0" />
                    </linearGradient>
                </defs>
            </svg>

            {/* 1. Top Layer: Frontend */}
            <div className="relative z-10 animate-fade-down" style={{ animationDelay: '0ms' }}>
                <div className="group bg-white/90 backdrop-blur-md border border-indigo-100 p-4 rounded-2xl shadow-xl shadow-indigo-100/50 flex flex-col items-center w-64 hover:scale-105 transition-all cursor-default relative overflow-hidden">
                    <div className="absolute top-0 w-full h-1 bg-gradient-to-r from-blue-400 to-indigo-500"></div>
                    <div className="p-3 bg-indigo-50 rounded-xl mb-3 group-hover:bg-indigo-100 transition-colors">
                        <Layout className="w-8 h-8 text-indigo-600" />
                    </div>
                    <h3 className="text-lg font-black text-slate-800">urgs-web</h3>
                    <p className="text-xs font-bold text-indigo-500 mb-2">Web 交互体验</p>
                    <div className="flex flex-wrap justify-center gap-1 mt-1">
                        <span className="px-1.5 py-0.5 bg-indigo-50 text-indigo-600 text-[9px] rounded border border-indigo-100">React 19</span>
                        <span className="px-1.5 py-0.5 bg-indigo-50 text-indigo-600 text-[9px] rounded border border-indigo-100">TypeScript 5.3</span>
                        <span className="px-1.5 py-0.5 bg-indigo-50 text-indigo-600 text-[9px] rounded border border-indigo-100">Vite</span>
                        <span className="px-1.5 py-0.5 bg-indigo-50 text-indigo-600 text-[9px] rounded border border-indigo-100">AntD 6.0</span>
                        <span className="px-1.5 py-0.5 bg-indigo-50 text-indigo-600 text-[9px] rounded border border-indigo-100">Zustand</span>
                    </div>
                </div>
            </div>

            {/* 2. Center Layer: API Gateway */}
            <div className="relative z-10 my-4 animate-zoom-in" style={{ animationDelay: '200ms' }}>
                <div className="group bg-white border-2 border-indigo-500 p-4 rounded-full shadow-[0_0_40px_rgba(99,102,241,0.3)] flex flex-col items-center w-40 h-40 justify-center hover:shadow-[0_0_60px_rgba(99,102,241,0.5)] transition-all cursor-default relative">
                    <div className="absolute inset-0 rounded-full border border-indigo-100 animate-[spin_10s_linear_infinite]"></div>
                    <div className="absolute -inset-2 rounded-full border border-dashed border-indigo-200 animate-[spin_20s_linear_infinite_reverse]"></div>

                    <Server className="w-8 h-8 text-indigo-600 mb-1" />
                    <h3 className="text-lg font-black text-slate-900">urgs-api</h3>
                    <p className="text-xs font-bold text-indigo-500 uppercase tracking-widest scale-90">API 网关</p>
                    <p className="text-[9px] text-slate-400 mt-0.5">Spring Boot 3.2</p>
                    <div className="flex flex-wrap justify-center gap-0.5 mt-1 max-w-[140px]">
                        <span className="px-1 py-0.5 bg-slate-50 text-slate-500 text-[8px] rounded border border-slate-100">Java 21</span>
                        <span className="px-1 py-0.5 bg-slate-50 text-slate-500 text-[8px] rounded border border-slate-100">Gateway</span>
                        <span className="px-1 py-0.5 bg-slate-50 text-slate-500 text-[8px] rounded border border-slate-100">Nacos</span>
                        <span className="px-1 py-0.5 bg-slate-50 text-slate-500 text-[8px] rounded border border-slate-100">Netty</span>
                    </div>
                </div>
            </div>

            {/* 3. Bottom Layer: Engines */}
            <div className="grid grid-cols-3 gap-8 w-full max-w-5xl px-4 relative z-10">

                {/* Engine 1: Lineage */}
                <div className="animate-fade-up" style={{ animationDelay: '400ms' }}>
                    <div className="group bg-white/90 backdrop-blur-md border border-cyan-100 p-5 rounded-2xl shadow-xl shadow-cyan-100/50 flex items-start gap-4 hover:-translate-y-1 transition-all cursor-default h-full">
                        <div className="p-3 bg-cyan-50 rounded-xl group-hover:bg-cyan-100 transition-colors shrink-0">
                            <Network className="w-6 h-6 text-cyan-600" />
                        </div>
                        <div>
                            <h3 className="text-base font-bold text-slate-800">sql-lineage-engine</h3>
                            <p className="text-[10px] font-bold text-cyan-500 uppercase mb-2">血缘分析引擎</p>
                            <p className="text-xs text-slate-500 leading-relaxed mb-2">
                                GSP + SQLGlot 双引擎驱动，支持多方言自适应解析与 Neo4j 图谱构建。
                            </p>
                            <div className="flex flex-wrap gap-1">
                                <span className="px-1.5 py-0.5 bg-cyan-50 text-cyan-600 text-[9px] rounded border border-cyan-100">Python 3.11</span>
                                <span className="px-1.5 py-0.5 bg-cyan-50 text-cyan-600 text-[9px] rounded border border-cyan-100">Antlr4</span>
                                <span className="px-1.5 py-0.5 bg-cyan-50 text-cyan-600 text-[9px] rounded border border-cyan-100">NetworkX</span>
                                <span className="px-1.5 py-0.5 bg-cyan-50 text-cyan-600 text-[9px] rounded border border-cyan-100">FastAPI</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Engine 2: RAG */}
                <div className="animate-fade-up" style={{ animationDelay: '500ms' }}>
                    <div className="group bg-amber-50/50 backdrop-blur-md border border-amber-200 p-5 rounded-2xl shadow-xl shadow-amber-100/50 flex items-start gap-4 hover:-translate-y-1 transition-all cursor-default h-full ring-1 ring-amber-100">
                        <div className="p-3 bg-white rounded-xl shadow-sm shrink-0">
                            <Bot className="w-6 h-6 text-amber-500 animate-pulse" />
                        </div>
                        <div>
                            <h3 className="text-base font-bold text-slate-800 flex items-center gap-2">
                                urgs-rag
                                <span className="px-1.5 py-0.5 bg-amber-100 text-amber-600 text-[8px] rounded font-bold">AI 核心</span>
                            </h3>
                            <p className="text-[10px] font-bold text-amber-500 uppercase mb-2">RAG索引</p>
                            <p className="text-xs text-slate-500 leading-relaxed mb-2">
                                向量检索与大模型推理。
                            </p>
                            <div className="flex flex-wrap gap-1">
                                <span className="px-1.5 py-0.5 bg-amber-50 text-amber-600 text-[9px] rounded border border-amber-100">Python 3.11</span>
                                <span className="px-1.5 py-0.5 bg-amber-50 text-amber-600 text-[9px] rounded border border-amber-100">LangChain</span>
                                <span className="px-1.5 py-0.5 bg-amber-50 text-amber-600 text-[9px] rounded border border-amber-100">HuggingFace</span>
                                <span className="px-1.5 py-0.5 bg-amber-50 text-amber-600 text-[9px] rounded border border-amber-100">OpenAI API</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Engine 3: Executor */}
                <div className="animate-fade-up" style={{ animationDelay: '600ms' }}>
                    <div className="group bg-white/90 backdrop-blur-md border border-rose-100 p-5 rounded-2xl shadow-xl shadow-rose-100/50 flex items-start gap-4 hover:-translate-y-1 transition-all cursor-default h-full">
                        <div className="p-3 bg-rose-50 rounded-xl group-hover:bg-rose-100 transition-colors shrink-0">
                            <Cpu className="w-6 h-6 text-rose-600" />
                        </div>
                        <div>
                            <h3 className="text-base font-bold text-slate-800">urgs-executor</h3>
                            <p className="text-[10px] font-bold text-rose-500 uppercase mb-2">分布式调度</p>
                            <p className="text-xs text-slate-500 leading-relaxed mb-2">
                                分布式任务调度与执行引擎。
                            </p>
                            <div className="flex flex-wrap gap-1">
                                <span className="px-1.5 py-0.5 bg-rose-50 text-rose-600 text-[9px] rounded border border-rose-100">Java 21</span>
                                <span className="px-1.5 py-0.5 bg-rose-50 text-rose-600 text-[9px] rounded border border-rose-100">Spring Batch</span>
                                <span className="px-1.5 py-0.5 bg-rose-50 text-rose-600 text-[9px] rounded border border-rose-100">Quartz</span>
                                <span className="px-1.5 py-0.5 bg-rose-50 text-rose-600 text-[9px] rounded border border-rose-100">Redis</span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            {/* 4. Bottom Layer: Data Storage */}
            <div className="grid grid-cols-3 gap-6 w-full max-w-5xl px-4 relative z-10 mt-6">

                {/* DB 1: Neo4j */}
                <div className="animate-fade-up" style={{ animationDelay: '700ms' }}>
                    <div className="group bg-slate-50/80 backdrop-blur-md border border-slate-200 p-4 rounded-xl shadow-lg flex items-center gap-3 hover:scale-105 transition-all cursor-default">
                        <div className="p-2.5 bg-white rounded-lg shadow-sm shrink-0 border border-slate-100">
                            <Share2 className="w-5 h-5 text-cyan-600" />
                        </div>
                        <div>
                            <h3 className="text-sm font-bold text-slate-800">Neo4j</h3>
                            <p className="text-[10px] font-medium text-slate-500 mb-1">图数据库 (Graph)</p>
                            <div className="flex flex-wrap gap-1">
                                <span className="px-1.5 py-0.5 bg-slate-100 text-slate-500 text-[8px] rounded">Cypher</span>
                                <span className="px-1.5 py-0.5 bg-slate-100 text-slate-500 text-[8px] rounded">Bolt</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* DB 2: ChromaDB */}
                <div className="animate-fade-up" style={{ animationDelay: '800ms' }}>
                    <div className="group bg-slate-50/80 backdrop-blur-md border border-slate-200 p-4 rounded-xl shadow-lg flex items-center gap-3 hover:scale-105 transition-all cursor-default">
                        <div className="p-2.5 bg-white rounded-lg shadow-sm shrink-0 border border-slate-100">
                            <Database className="w-5 h-5 text-amber-600" />
                        </div>
                        <div>
                            <h3 className="text-sm font-bold text-slate-800">ChromaDB</h3>
                            <p className="text-[10px] font-medium text-slate-500 mb-1">向量数据库 (Vector)</p>
                            <div className="flex flex-wrap gap-1">
                                <span className="px-1.5 py-0.5 bg-slate-100 text-slate-500 text-[8px] rounded">HNSW</span>
                                <span className="px-1.5 py-0.5 bg-slate-100 text-slate-500 text-[8px] rounded">SBERT</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* DB 3: MySQL */}
                <div className="animate-fade-up" style={{ animationDelay: '900ms' }}>
                    <div className="group bg-slate-50/80 backdrop-blur-md border border-slate-200 p-4 rounded-xl shadow-lg flex items-center gap-3 hover:scale-105 transition-all cursor-default">
                        <div className="p-2.5 bg-white rounded-lg shadow-sm shrink-0 border border-slate-100">
                            <HardDrive className="w-5 h-5 text-rose-600" />
                        </div>
                        <div>
                            <h3 className="text-sm font-bold text-slate-800">MySQL</h3>
                            <p className="text-[10px] font-medium text-slate-500 mb-1">关系型数据库 (RDBMS)</p>
                            <div className="flex flex-wrap gap-1">
                                <span className="px-1.5 py-0.5 bg-slate-100 text-slate-500 text-[8px] rounded">InnoDB</span>
                                <span className="px-1.5 py-0.5 bg-slate-100 text-slate-500 text-[8px] rounded">MVCC</span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <style>{`
                @keyframes dash {
                    to { stroke-dashoffset: -24; }
                }
            `}</style>
        </div>
    </SlideLayout>
);
