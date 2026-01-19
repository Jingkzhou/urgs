import React, { useState } from 'react';
import { ArrowLeft, Code2, X, Cpu, GitMerge, Zap, Database, Layers } from 'lucide-react';
import { ActiveLineageGraph } from '../shared/ActiveLineageGraph';

interface LineagePageProps {
    onBack?: () => void;
}

export const LineagePage = ({ onBack }: LineagePageProps) => {
    const [showSpecs, setShowSpecs] = useState(false);

    return (
        <div className="md:fixed inset-0 w-full h-full bg-slate-50 relative overflow-hidden font-sans">
            {/* Floating Back Button */}
            {onBack && (
                <button
                    onClick={onBack}
                    className="absolute top-6 left-6 z-50 p-2.5 bg-white/90 hover:bg-white backdrop-blur-md border border-slate-200/60 rounded-xl shadow-lg hover:shadow-xl transition-all text-slate-600 hover:text-slate-900 group"
                    title="返回生态全景"
                >
                    <ArrowLeft className="w-5 h-5 group-hover:-translate-x-0.5 transition-transform" />
                </button>
            )}

            {/* Tech Specs Toggle Button */}
            <button
                onClick={() => setShowSpecs(true)}
                className="absolute top-6 left-20 z-50 flex items-center gap-2 px-4 py-2.5 bg-white/90 hover:bg-white backdrop-blur-md border border-slate-200/60 rounded-xl shadow-lg hover:shadow-xl transition-all text-slate-600 hover:text-indigo-600 group"
            >
                <Code2 className="w-4 h-4" />
                <span className="text-xs font-bold">解析引擎架构</span>
            </button>

            {/* Fullscreen Graph Area */}
            <div className="absolute inset-0 w-full h-full bg-slate-50">
                <ActiveLineageGraph />
            </div>

            {/* Floating Info Cards (Bottom Overlay) */}
            <div className={`absolute bottom-8 left-0 right-0 z-40 px-8 pointer-events-none transition-opacity duration-300 ${showSpecs ? 'opacity-0' : 'opacity-100'}`}>
                <div className="max-w-5xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-4 pointer-events-auto">
                    <div className="p-4 bg-white/80 backdrop-blur-md border border-white/40 rounded-2xl shadow-lg hover:bg-white/90 transition-colors">
                        <div className="flex items-center gap-3 mb-1">
                            <div className="w-2 h-2 rounded-full bg-blue-500"></div>
                            <h5 className="font-bold text-slate-800 text-sm">字段级溯源</h5>
                        </div>
                        <p className="text-[11px] text-slate-600 leading-relaxed">基于 Neo4j 图存储实现报表指标到底层字段的穿透追踪。</p>
                    </div>
                    <div className="p-4 bg-white/80 backdrop-blur-md border border-white/40 rounded-2xl shadow-lg hover:bg-white/90 transition-colors">
                        <div className="flex items-center gap-3 mb-1">
                            <div className="w-2 h-2 rounded-full bg-emerald-500"></div>
                            <h5 className="font-bold text-slate-800 text-sm">资产自动更新</h5>
                        </div>
                        <p className="text-[11px] text-slate-600 leading-relaxed">定时同步物理模型，元数据与现实环境永远一致。</p>
                    </div>
                    <div className="p-4 bg-white/80 backdrop-blur-md border border-white/40 rounded-2xl shadow-lg hover:bg-white/90 transition-colors">
                        <div className="flex items-center gap-3 mb-1">
                            <div className="w-2 h-2 rounded-full bg-violet-500"></div>
                            <h5 className="font-bold text-slate-800 text-sm">代码值域管理</h5>
                        </div>
                        <p className="text-[11px] text-slate-600 leading-relaxed">维护业务标准的字典项，统一全行监管资产认知。</p>
                    </div>
                </div>
            </div>

            {/* Tech Specs Side Panel (Left Side) - Widened */}
            <div className={`fixed inset-y-0 left-0 z-[60] w-[640px] bg-white/95 backdrop-blur-xl shadow-2xl border-r border-slate-200 transform transition-transform duration-500 ease-out ${showSpecs ? 'translate-x-0' : '-translate-x-full'}`}>
                <div className="h-full overflow-y-auto p-8 relative">
                    <button
                        onClick={() => setShowSpecs(false)}
                        className="absolute top-6 right-6 p-2 hover:bg-slate-100 rounded-full transition-colors text-slate-400 hover:text-slate-600"
                    >
                        <X className="w-5 h-5" />
                    </button>

                    <div className="mb-8">
                        <div className="inline-flex items-center gap-2 px-3 py-1 bg-indigo-50 text-indigo-600 rounded-full text-[10px] font-bold uppercase tracking-wider mb-4 border border-indigo-100">
                            Core Engine v2.0
                        </div>
                        <h2 className="text-2xl font-bold text-slate-900 mb-2">SQL Lineage Engine</h2>
                        <p className="text-sm text-slate-500 leading-relaxed">
                            高性能、双引擎驱动的 SQL 血缘解析内核，支持复杂存储过程与方言自动探测。
                        </p>
                    </div>

                    <div className="space-y-8">
                        {/* Architecture Section */}
                        <div className="space-y-4">
                            <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                                <Layers className="w-4 h-4 text-indigo-500" />
                                双引擎架构 (Dual-Engine)
                            </h3>
                            <div className="bg-slate-50 rounded-2xl p-1 border border-slate-100">
                                <div className="grid grid-cols-2 gap-1 text-center">
                                    <div className="p-4 bg-white rounded-xl shadow-sm border border-slate-100">
                                        <div className="font-bold text-slate-800 text-sm mb-1">GSP</div>
                                        <div className="text-[10px] text-slate-400 uppercase tracking-wider">核心解析</div>
                                        <p className="text-[10px] text-slate-500 mt-2">基于 General SQL Parser，处理复杂语法与存储过程。</p>
                                    </div>
                                    <div className="p-4 bg-white rounded-xl shadow-sm border border-slate-100">
                                        <div className="font-bold text-slate-800 text-sm mb-1">SQLGlot</div>
                                        <div className="text-[10px] text-slate-400 uppercase tracking-wider">以及降级</div>
                                        <p className="text-[10px] text-slate-500 mt-2">轻量级方言探测，提供解析失败时的健壮性兜底。</p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Workflow Flow */}
                        <div className="space-y-4">
                            <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                                <GitMerge className="w-4 h-4 text-emerald-500" />
                                解析流水线
                            </h3>
                            <div className="relative pl-4 border-l-2 border-slate-100 space-y-6">
                                <div className="relative">
                                    <div className="absolute -left-[21px] top-1 w-3 h-3 rounded-full bg-slate-200 border-2 border-white box-content"></div>
                                    <h4 className="text-xs font-bold text-slate-800">1. 智能预处理</h4>
                                    <p className="text-[11px] text-slate-500 mt-1">自动拆分 10k+ 行超长 SQL，移除注释干扰。</p>
                                </div>
                                <div className="relative">
                                    <div className="absolute -left-[21px] top-1 w-3 h-3 rounded-full bg-blue-500 border-2 border-white box-content ring-4 ring-blue-50"></div>
                                    <h4 className="text-xs font-bold text-slate-800">2. 方言自探测 (Dialect Detection)</h4>
                                    <p className="text-[11px] text-slate-500 mt-1">识别 Oracle, Hive, MySQL 等特征，动态切换策略。</p>
                                </div>
                                <div className="relative">
                                    <div className="absolute -left-[21px] top-1 w-3 h-3 rounded-full bg-slate-200 border-2 border-white box-content"></div>
                                    <h4 className="text-xs font-bold text-slate-800">3. 抽象语法树 (AST) 构建</h4>
                                    <p className="text-[11px] text-slate-500 mt-1">提取 Table, Column 及转换逻辑，生成中间结构。</p>
                                </div>
                                <div className="relative">
                                    <div className="absolute -left-[21px] top-1 w-3 h-3 rounded-full bg-slate-200 border-2 border-white box-content"></div>
                                    <h4 className="text-xs font-bold text-slate-800">4. 图谱导出 (Graph Export)</h4>
                                    <p className="text-[11px] text-slate-500 mt-1">通过 Neo4j Exporter 将血缘关系入库，支持版本管理。</p>
                                </div>
                            </div>
                        </div>

                        {/* Tech Stack Tags */}
                        <div className="pt-6 border-t border-slate-100">
                            <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-3">Tech Stack</h3>
                            <div className="flex flex-wrap gap-2">
                                {['Python 3.12', 'ANTLR4', 'Neo4j', 'FastAPI', 'Docker', 'Redis'].map((tag, i) => (
                                    <span key={i} className="px-2.5 py-1 bg-slate-50 text-slate-600 rounded-md text-[10px] font-medium border border-slate-200">
                                        {tag}
                                    </span>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Backdrop for Side Panel */}
            {showSpecs && (
                <div
                    className="fixed inset-0 bg-black/5 z-[55] backdrop-blur-[1px] transition-opacity"
                    onClick={() => setShowSpecs(false)}
                />
            )}
        </div>
    );
};
