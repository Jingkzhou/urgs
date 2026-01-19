import React, { useState, useEffect } from 'react';
import { LayoutDashboard, Database, Menu, ArrowRight, ShieldCheck, Sparkles, Network, GitBranch } from 'lucide-react';
import { ActiveLineageGraph } from './ActiveLineageGraph';

export const SQLParsingAnimationDemo = () => {
    const [phase, setPhase] = useState<'sql-input' | 'ast-parsing' | 'table-deps' | 'field-deps' | 'lineage-graph'>('sql-input');
    const [sqlText, setSqlText] = useState('');
    const fullSql = `INSERT INTO YBT_DATACORE.T_G01_LOAN_SUMMARY
SELECT 
    ORG_NUM,
    SUM(LOAN_ACCT_BAL * CCY_RATE) AS TOTAL_BAL,
    LOAN_GRADE_CD
FROM SMTMODS.L_ACCT_LOAN A
LEFT JOIN SMTMODS.L_PUBL_RATE B ON A.CURR_CD = B.BASIC_CCY
WHERE A.DATA_DATE = '20241215'
GROUP BY ORG_NUM, LOAN_GRADE_CD`;

    useEffect(() => {
        if (phase === 'sql-input') {
            let i = 0;
            const timer = setInterval(() => {
                setSqlText(fullSql.slice(0, i));
                i++;
                if (i > fullSql.length) clearInterval(timer);
            }, 10);
            return () => clearInterval(timer);
        }
    }, [phase]);

    const phases = [
        { id: 'sql-input', label: '① SQL 代码提交' },
        { id: 'ast-parsing', label: '② AST 语法解析' },
        { id: 'table-deps', label: '③ 表级依赖提取' },
        { id: 'field-deps', label: '④ 字段级依赖提取' },
        { id: 'lineage-graph', label: '⑤ 血缘图谱生成' },
    ];

    const renderContent = () => {
        switch (phase) {
            case 'sql-input':
                return (
                    <div className="bg-slate-900 rounded-xl p-6 font-mono text-sm leading-relaxed text-indigo-300 shadow-inner h-[300px] overflow-y-auto animate-in fade-in duration-500">
                        <div className="flex items-center gap-2 mb-4 border-b border-slate-700 pb-2">
                            <div className="flex gap-1.5">
                                <div className="w-2.5 h-2.5 rounded-full bg-rose-500"></div>
                                <div className="w-2.5 h-2.5 rounded-full bg-amber-500"></div>
                                <div className="w-2.5 h-2.5 rounded-full bg-emerald-500"></div>
                            </div>
                            <span className="text-slate-500 text-xs">risk_audit.sql</span>
                        </div>
                        <pre className="whitespace-pre-wrap">
                            {sqlText}
                            <span className="inline-block w-1.5 h-4 bg-indigo-500 ml-1 animate-pulse"></span>
                        </pre>
                    </div>
                );
            case 'ast-parsing':
                return (
                    <div className="bg-white rounded-xl border border-slate-200 p-8 h-[300px] flex items-center justify-center animate-in zoom-in-95 duration-500">
                        <div className="space-y-4 w-full max-w-md">
                            <div className="p-3 bg-indigo-50 rounded-lg border border-indigo-100 flex items-center gap-3 anim-fade-up">
                                <LayoutDashboard className="w-5 h-5 text-indigo-600" />
                                <span className="text-sm font-bold text-indigo-900">InsertStatement [INSERT INTO]</span>
                            </div>
                            <div className="ml-8 space-y-3">
                                <div className="p-2 bg-slate-50 rounded-lg border border-slate-200 flex items-center gap-3 anim-fade-up delay-100">
                                    <Database className="w-4 h-4 text-slate-400" />
                                    <span className="text-xs font-mono">Target: T_G01_LOAN_SUMMARY</span>
                                </div>
                                <div className="p-3 bg-teal-50 rounded-lg border border-teal-100 flex items-center gap-3 anim-fade-up delay-200">
                                    <Menu className="w-4 h-4 text-teal-600" />
                                    <span className="text-xs font-bold text-teal-900">SelectBody [SELECT]</span>
                                </div>
                                <div className="ml-8 space-y-2">
                                    <div className="p-2 bg-white rounded border border-slate-100 shadow-sm text-[10px] anim-fade-up delay-300">Columns: ORG_NUM, TOTAL_BAL...</div>
                                    <div className="p-2 bg-white rounded border border-slate-100 shadow-sm text-[10px] anim-fade-up delay-400">From: L_ACCT_LOAN, L_PUBL_RATE</div>
                                </div>
                            </div>
                        </div>
                    </div>
                );
            case 'table-deps':
                return (
                    <div className="bg-slate-50 rounded-xl border border-slate-200 p-8 h-[300px] flex items-center justify-center gap-12 relative animate-in slide-in-from-bottom-4 duration-500">
                        <div className="flex flex-col gap-4 items-center anim-fade-right">
                            <div className="p-4 bg-white rounded-xl shadow-md border border-slate-200 w-48 transition-all hover:scale-105">
                                <div className="text-[10px] text-slate-400 uppercase font-bold mb-1">Source Table 1</div>
                                <div className="text-xs font-bold font-mono">L_ACCT_LOAN</div>
                            </div>
                            <div className="p-4 bg-white rounded-xl shadow-md border border-slate-200 w-48 transition-all hover:scale-105">
                                <div className="text-[10px] text-slate-400 uppercase font-bold mb-1">Source Table 2</div>
                                <div className="text-xs font-bold font-mono">L_PUBL_RATE</div>
                            </div>
                        </div>

                        <div className="anim-scale-in delay-300">
                            <ArrowRight className="w-8 h-8 text-indigo-400 animate-pulse" />
                        </div>

                        <div className="flex flex-col items-center anim-fade-left">
                            <div className="p-6 bg-indigo-600 rounded-2xl shadow-xl shadow-indigo-100 border border-indigo-500 w-56 transform rotate-2">
                                <div className="text-[10px] text-white/70 uppercase font-bold mb-1">Target Asset</div>
                                <div className="text-sm font-bold text-white font-mono">T_G01_LOAN_SUMMARY</div>
                            </div>
                        </div>
                        {/* Background scanner */}
                        <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-transparent via-cyan-400/30 to-transparent animate-[scan_3s_linear_infinite]"></div>
                    </div>
                );
            case 'field-deps':
                return (
                    <div className="bg-white rounded-xl border border-slate-200 p-8 h-[300px] relative overflow-hidden animate-in zoom-in-105 duration-700">
                        <div className="flex justify-between items-center h-full max-w-2xl mx-auto">
                            <div className="space-y-4">
                                {['ORG_NUM', 'LOAN_ACCT_BAL', 'CCY_RATE'].map((f, i) => (
                                    <div key={i} id={`src-${f}`} className="p-2 bg-slate-50 rounded border border-slate-200 text-xs font-mono w-40 flex justify-between items-center anim-fade-right" style={{ animationDelay: `${i * 100}ms` }}>
                                        {f} <div className="w-1.5 h-1.5 rounded-full bg-slate-300"></div>
                                    </div>
                                ))}
                            </div>

                            <div className="space-y-6">
                                {['ORG_NUM', 'TOTAL_BAL'].map((f, i) => (
                                    <div key={i} id={`dest-${f}`} className="p-2 bg-indigo-50 rounded border border-indigo-100 text-xs font-mono w-48 flex items-center gap-3 anim-fade-left" style={{ animationDelay: `${500 + i * 100}ms` }}>
                                        <div className="w-1.5 h-1.5 rounded-full bg-indigo-400"></div> {f}
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Simple lines imitation */}
                        <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-50">
                            <path d="M 170 115 C 250 115, 300 110, 410 120" stroke="#818cf8" strokeWidth="2" fill="none" className="anim-draw-line" />
                            <path d="M 170 155 C 250 155, 300 150, 410 160" stroke="#818cf8" strokeWidth="2" fill="none" strokeDasharray="5,2" className="anim-draw-line delay-200" />
                            <path d="M 170 195 C 250 195, 300 150, 410 160" stroke="#818cf8" strokeWidth="2" fill="none" className="anim-draw-line delay-400" />
                        </svg>
                    </div>
                );
            case 'lineage-graph':
                return (
                    <div className="bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200 p-4 h-[300px] overflow-hidden animate-in fade-in duration-1000">
                        <ActiveLineageGraph />
                        <div className="absolute inset-0 pointer-events-none bg-gradient-to-t from-white/80 via-transparent to-transparent"></div>
                        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 bg-white/90 backdrop-blur px-6 py-3 rounded-full shadow-lg border border-indigo-100 flex items-center gap-4 anim-fade-up">
                            <ShieldCheck className="w-5 h-5 text-emerald-500" />
                            <span className="text-sm font-bold text-slate-800">解析完成：已成功入库 Neo4j 血缘图谱</span>
                            <button
                                onClick={() => setPhase('sql-input')}
                                className="text-xs text-indigo-600 hover:underline font-bold"
                            >
                                重放过程
                            </button>
                        </div>
                    </div>
                );
        }
    };

    return (
        <div className="w-full max-w-4xl mx-auto space-y-8">
            {/* Navigation Buttons */}
            <div className="flex flex-wrap justify-center gap-3">
                {phases.map((p) => (
                    <button
                        key={p.id}
                        onClick={() => setPhase(p.id as any)}
                        className={`px-4 py-2 rounded-full text-xs font-bold transition-all ${phase === p.id
                            ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-200 scale-105'
                            : 'bg-white text-slate-500 border border-slate-200 hover:border-indigo-300'
                            }`}
                    >
                        {p.label}
                    </button>
                ))}
            </div>

            <div className="relative group">
                {/* Decorative elements */}
                <div className="absolute -inset-4 bg-gradient-to-tr from-indigo-50 to-slate-50 rounded-[2rem] -z-10 group-hover:bg-indigo-100/30 transition-colors"></div>
                {renderContent()}
            </div>

            {/* Logic Summary */}
            <div className="grid md:grid-cols-3 gap-6">
                <div className="bg-white/50 p-4 rounded-xl border border-white/80 backdrop-blur-sm">
                    <h5 className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-2">
                        <Sparkles className="w-3 h-3" /> 解析引擎
                    </h5>
                    <p className="text-xs text-slate-600">自研编译器架构，适配 10+ 种 SQL 方言</p>
                </div>
                <div className="bg-white/50 p-4 rounded-xl border border-white/80 backdrop-blur-sm">
                    <h5 className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-2">
                        <Network className="w-3 h-3" /> 依赖粒度
                    </h5>
                    <p className="text-xs text-slate-600">下钻至字段级(Column-level)精准追踪</p>
                </div>
                <div className="bg-white/50 p-4 rounded-xl border border-white/80 backdrop-blur-sm">
                    <h5 className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-2">
                        <GitBranch className="w-3 h-3" /> 存储架构
                    </h5>
                    <p className="text-xs text-slate-600">原生图数据库存储，支持深度溯源查询</p>
                </div>
            </div>

            <style>{`
        @keyframes scan {
          0% { transform: translateY(-100%); }
          100% { transform: translateY(300px); }
        }
        .anim-draw-line {
          stroke-dasharray: 1000;
          stroke-dashoffset: 1000;
          animation: draw-line 2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        @keyframes draw-line {
          to { stroke-dashoffset: 0; }
        }
      `}</style>
        </div>
    );
};
