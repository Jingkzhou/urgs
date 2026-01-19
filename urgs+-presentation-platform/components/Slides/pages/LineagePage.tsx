import React, { useState, useEffect } from 'react';
import { ArrowLeft, Code2, X, Cpu, GitMerge, Zap, Database, Layers, Play, Loader2, CheckCircle2, FileCode } from 'lucide-react';
import { ActiveLineageGraph } from '../shared/ActiveLineageGraph';
import { SlideLayout } from '../layout/SlideLayout';

interface LineagePageProps {
    onBack?: () => void;
}

export const LineagePage = ({ onBack }: LineagePageProps) => {
    const [viewState, setViewState] = useState<'input' | 'processing' | 'result'>('input');
    const [processingStep, setProcessingStep] = useState(0);

    const handleAnalyze = () => {
        setViewState('processing');
        // Simulate processing steps
        let step = 0;
        const interval = setInterval(() => {
            step++;
            setProcessingStep(step);
            if (step >= 3) {
                clearInterval(interval);
                setTimeout(() => setViewState('result'), 800);
            }
        }, 800);
    };

    const handleReset = () => {
        setViewState('input');
        setProcessingStep(0);
    };

    const sampleSQL = `-- Complex PL/SQL Procedure Analysis
CREATE OR REPLACE PROCEDURE SP_CALC_ASSET_LIABILITY AS
BEGIN
  -- 1. Split Data Stream: Main Flow (Middle)
  INSERT INTO YBT_DATACORE.TM_L_ACCT_OBS_TEMP
  SELECT 
    t1.SECURITY_AMT,
    t1.ACCOUNT_ID
  FROM SMTMODS.L_ACCT_OBS_LOAN t1;

  -- 2. Split Data Stream: Branch Top (T_6_11)
  INSERT INTO YBT_DATACORE.T_6_11 (F110001)
  SELECT t1.SECURITY_AMT
  FROM SMTMODS.L_ACCT_OBS_LOAN t1
  WHERE t1.TYPE = 'TOP';

  -- 3. Split Data Stream: Branch Bottom (T_6_12)
  INSERT INTO YBT_DATACORE.T_6_12 (F120007)
  SELECT t1.SECURITY_AMT
  FROM SMTMODS.L_ACCT_OBS_LOAN t1
  WHERE t1.TYPE = 'BOT';

  -- 4. Transform: Middle Stream Filtering
  INSERT INTO YBT_DATACORE.TM_L_ACCT_OBS_SX
  SELECT 
    SECURITY_AMT * 1.05,
    ACCOUNT_ID
  FROM YBT_DATACORE.TM_L_ACCT_OBS_TEMP
  WHERE SECURITY_AMT > 1000000;

  -- 5. Final Report: Aggregation
  INSERT INTO YBT_DATACORE.T_8_13 (R130004)
  SELECT sum(SECURITY_AMT)
  FROM YBT_DATACORE.TM_L_ACCT_OBS_SX;
END;`;

    return (
        <div className="md:fixed inset-0 w-full h-full bg-slate-50 relative overflow-hidden font-sans flex flex-row">
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



            {/* Left Panel: Content Area (Switchable) */}
            <div className="flex-1 relative h-full bg-slate-50 flex flex-col">

                {/* View 1: SQL Editor Input */}
                {viewState === 'input' && (
                    <div className="flex-1 p-8 flex flex-col animate-fade-in">
                        <div className="flex items-center justify-between mb-4">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-indigo-100 rounded-lg">
                                    <Code2 className="w-5 h-5 text-indigo-600" />
                                </div>
                                <div>
                                    <h3 className="text-xl font-bold text-slate-800">SQL Script Analysis</h3>
                                    <p className="text-sm text-slate-500">Paste your PL/SQL or complex query to extract lineage.</p>
                                </div>
                            </div>
                        </div>

                        <div className="flex-1 bg-slate-900 rounded-xl overflow-hidden shadow-2xl border border-slate-700 font-mono text-sm relative group">
                            <div className="absolute top-0 left-0 right-0 h-8 bg-slate-800 flex items-center px-4 gap-2 border-b border-slate-700">
                                <div className="w-3 h-3 rounded-full bg-red-500 opacity-50"></div>
                                <div className="w-3 h-3 rounded-full bg-yellow-500 opacity-50"></div>
                                <div className="w-3 h-3 rounded-full bg-green-500 opacity-50"></div>
                                <span className="ml-2 text-xs text-slate-400">analysis_script.sql</span>
                            </div>
                            {/* Scrollable Container */}
                            <div className="w-full h-full pt-8 overflow-auto">
                                <HighlightedSQL code={sampleSQL} />
                            </div>
                            <div className="absolute bottom-6 right-6">
                                <button
                                    onClick={handleAnalyze}
                                    className="flex items-center gap-2 px-6 py-3 bg-indigo-600 hover:bg-indigo-500 text-white rounded-full font-bold shadow-lg hover:shadow-indigo-500/30 transition-all transform hover:scale-105 active:scale-95"
                                >
                                    <Play className="w-4 h-4 fill-current" />
                                    Start Analysis
                                </button>
                            </div>
                        </div>
                    </div>
                )}

                {/* View 2: Processing State */}
                {viewState === 'processing' && (
                    <div className="flex-1 flex flex-col items-center justify-center animate-fade-in">
                        <div className="relative w-32 h-32 mb-8">
                            <div className="absolute inset-0 border-4 border-indigo-100 rounded-full"></div>
                            <div className="absolute inset-0 border-4 border-indigo-500 rounded-full border-t-transparent animate-spin"></div>
                            <Cpu className="absolute inset-0 m-auto w-10 h-10 text-indigo-500 animate-pulse" />
                        </div>
                        <h3 className="text-2xl font-bold text-slate-800 mb-6">Analyzing Lineage...</h3>
                        <div className="space-y-4 w-64">
                            <ProcessingItem step={1} current={processingStep} label="Parsing Dialect (PL/SQL)" />
                            <ProcessingItem step={2} current={processingStep} label="Building AST & Data Flow" />
                            <ProcessingItem step={3} current={processingStep} label="Generating Graph Topology" />
                        </div>
                    </div>
                )}

                {/* View 3: Result Graph */}
                {viewState === 'result' && (
                    <div className="absolute inset-0 w-full h-full bg-slate-50 animate-fade-in">
                        <ActiveLineageGraph />

                        {/* Floating "New Analysis" Button */}
                        <button
                            onClick={handleReset}
                            className="absolute top-6 right-6 z-50 px-4 py-2 bg-white/90 backdrop-blur border border-slate-200 shadow-sm hover:shadow-md rounded-lg text-xs font-bold text-slate-600 flex items-center gap-2 hover:text-indigo-600 transition-all"
                        >
                            <FileCode className="w-4 h-4" />
                            New Analysis
                        </button>

                        {/* Floating Info Cards (Bottom Overlay) */}
                        <div className="absolute bottom-8 left-0 right-0 z-40 px-8 pointer-events-none">
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
                    </div>
                )}
            </div>


            {/* Right Panel: Tech Specs (Fixed) */}
            <div className="w-[480px] h-full bg-white/95 backdrop-blur-xl border-l border-slate-200 shadow-2xl z-50 overflow-y-auto">
                <div className="p-8 h-full">

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

        </div>
    );
};

const HighlightedSQL = ({ code }: { code: string }) => {
    // Basic SQL Syntax Highlighting
    const lines = code.split('\n');

    return (
        <div className="font-mono text-sm leading-6 p-6 whitespace-pre">
            {lines.map((line, i) => {
                const trimmed = line.trim();
                if (trimmed.startsWith('--')) {
                    return <div key={i} className="text-slate-500 italic">{line}</div>;
                }

                // Process mixed line
                const parts = line.split(/(\s+|[(),;])/); // Split by separators but keep them
                return (
                    <div key={i}>
                        {parts.map((part, j) => {
                            if (part.match(/^(CREATE|OR|REPLACE|PROCEDURE|AS|BEGIN|END|INSERT|INTO|SELECT|FROM|WHERE|AND|SUM|GROUP|BY|ORDER|LEFT|JOIN|ON|IS|NOT|NULL|CASE|WHEN|THEN|ELSE)$/i)) {
                                return <span key={j} className="text-purple-400 font-bold">{part}</span>;
                            }
                            if (part.match(/^(SMTMODS|YBT_DATACORE|TM_L_ACCT_OBS_TEMP|L_ACCT_OBS_LOAN|T_6_11|T_6_12|TM_L_ACCT_OBS_SX|T_8_13)(\..*)?$/)) {
                                // Handle Table.Column patterns roughly
                                return <span key={j} className="text-blue-400">{part}</span>;
                            }
                            if (part.startsWith('\'')) {
                                return <span key={j} className="text-green-400">{part}</span>;
                            }
                            if (part.startsWith(':')) {
                                return <span key={j} className="text-orange-400">{part}</span>;
                            }
                            // Default
                            return <span key={j} className="text-slate-300">{part}</span>;
                        })}
                    </div>
                );
            })}
        </div>
    );
};

const ProcessingItem = ({ step, current, label }: { step: number, current: number, label: string }) => {
    const isCompleted = current > step;
    const isCurrent = current === step;

    return (
        <div className={`flex items-center gap-3 transition-all duration-300 ${isCurrent ? 'opacity-100 scale-105' : 'opacity-60'}`}>
            <div className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold border ${isCompleted ? 'bg-green-500 border-green-500 text-white' :
                isCurrent ? 'bg-indigo-100 border-indigo-500 text-indigo-600' : 'bg-slate-100 border-slate-300 text-slate-400'
                }`}>
                {isCompleted ? <CheckCircle2 className="w-3 h-3" /> : step}
            </div>
            <span className={`text-sm font-medium ${isCurrent ? 'text-indigo-600' : 'text-slate-500'}`}>{label}</span>
        </div>
    )
};
