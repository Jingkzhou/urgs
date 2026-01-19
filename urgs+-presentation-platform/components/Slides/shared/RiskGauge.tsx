import React, { useState, useEffect } from 'react';
import { ShieldAlert } from 'lucide-react';

export const RiskGauge = () => {
    const [score, setScore] = useState(0);
    const [status, setStatus] = useState<'idle' | 'scanning' | 'done'>('idle');

    useEffect(() => {
        if (status === 'scanning') {
            let current = 0;
            const interval = setInterval(() => {
                current += Math.random() * 15;
                if (current >= 45) {
                    setScore(45);
                    setStatus('done');
                    clearInterval(interval);
                } else {
                    setScore(Math.round(current));
                }
            }, 150);
            return () => clearInterval(interval);
        }
    }, [status]);

    return (
        <div className="bg-slate-900 rounded-3xl p-8 text-white flex flex-col items-center gap-6 shadow-2xl relative overflow-hidden group">
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-indigo-500 to-transparent opacity-50 group-hover:opacity-100 transition-opacity" />

            <div className="relative w-32 h-32 flex items-center justify-center">
                <svg className="w-full h-full transform -rotate-90">
                    <circle cx="64" cy="64" r="58" stroke="currentColor" strokeWidth="8" fill="transparent" className="text-slate-800" />
                    <circle
                        cx="64" cy="64" r="58"
                        stroke="currentColor" strokeWidth="8" fill="transparent"
                        strokeDasharray={364.4}
                        strokeDashoffset={364.4 - (364.4 * score) / 100}
                        className={`transition-all duration-500 ease-out ${score > 90 ? 'text-green-500' : 'text-rose-500'}`}
                    />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <span className="text-3xl font-black">{score}%</span>
                    <span className="text-[8px] uppercase tracking-widest text-slate-400 font-bold">合规审计指数</span>
                </div>
            </div>

            <div className="text-center">
                {status === 'idle' && <h5 className="text-lg font-bold">预发布合规 AI 智查</h5>}
                {status === 'scanning' && <h5 className="text-lg font-bold animate-pulse text-indigo-400">分析 SQL 变更对监管报表影响...</h5>}
                {status === 'done' && (
                    <div className="space-y-2 text-left bg-rose-900/40 p-3 rounded-xl border border-rose-500/30 animate-pulse">
                        <h5 className="text-sm font-bold text-rose-400 flex items-center gap-2 mb-1">
                            <ShieldAlert className="w-4 h-4 animate-bounce" /> 阻断：发现 2 个高危风险
                        </h5>
                        <ul className="text-[10px] text-rose-200 space-y-1 list-disc pl-4">
                            <li>字段 <code>LOAN_ACCT_BAL</code> 被删除，直接影响 G01 报表取数。</li>
                            <li>缺少 <code>WHERE</code> 过滤条件，导致统计范围异常扩大。</li>
                        </ul>
                    </div>
                )}
            </div>

            <button
                onClick={() => { setScore(0); setStatus('scanning'); }}
                disabled={status === 'scanning'}
                className={`px-6 py-2 rounded-full text-sm font-bold transition-all ${status === 'scanning' ? 'bg-slate-800 text-slate-500' : 'bg-indigo-600 hover:bg-indigo-500 shadow-lg shadow-indigo-900/20'}`}
            >
                {status === 'done' ? '重新扫描' : '启动发布前审计'}
            </button>
        </div>
    );
};
