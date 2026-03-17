import React, { useState, useEffect } from 'react';
import { ArrowLeft, CheckCircle2, AlertTriangle, Shield, Zap, Search, Code, Bug, FileCode, Check, Loader2 } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

interface AICodeSmartCheckPageProps {
    onBack?: () => void;
}

export const AICodeSmartCheckPage = ({ onBack }: AICodeSmartCheckPageProps) => {
    const [scanning, setScanning] = useState(true);
    const [progress, setProgress] = useState(0);
    const [showReport, setShowReport] = useState(false);

    // Mock Code Content
    const codeSnippet = `
function calculateRisk(transaction) {
  // TODO: Add validation
  if (transaction.amount > 1000000) {
    return 'HIGH';
  }
  // Potential SQL Injection vulnerability here
  // db.execute("SELECT * FROM users WHERE id = " + transaction.userId);
  return 'LOW';
}
`.trim();

    useEffect(() => {
        if (scanning) {
            const interval = setInterval(() => {
                setProgress(prev => {
                    if (prev >= 100) {
                        clearInterval(interval);
                        setScanning(false);
                        setShowReport(true);
                        return 100;
                    }
                    return prev + 2;
                });
            }, 50);
            return () => clearInterval(interval);
        }
    }, [scanning]);

    return (
        <div className="relative w-full h-full bg-slate-50 flex flex-col overflow-hidden">
            {onBack && (
                <button
                    onClick={onBack}
                    className="absolute top-6 left-6 z-50 p-2.5 bg-white/90 hover:bg-white backdrop-blur-md border border-slate-200/60 rounded-xl shadow-lg hover:shadow-xl transition-all text-slate-600 hover:text-slate-900 group"
                    title="返回"
                >
                    <ArrowLeft className="w-5 h-5 group-hover:-translate-x-0.5 transition-transform" />
                </button>
            )}

            <SlideLayout title="AI 代码智查">
                <div className="flex flex-col lg:flex-row gap-8 h-full p-4 md:p-8">

                    {/* Left: Code Scanning Area */}
                    <div className="flex-1 relative bg-slate-900 rounded-3xl overflow-hidden shadow-2xl border border-slate-800 flex flex-col">
                        <div className="flex items-center justify-between px-6 py-4 bg-slate-950 border-b border-slate-800">
                            <div className="flex gap-2">
                                <div className="w-3 h-3 rounded-full bg-red-500/80" />
                                <div className="w-3 h-3 rounded-full bg-yellow-500/80" />
                                <div className="w-3 h-3 rounded-full bg-green-500/80" />
                            </div>
                            <div className="text-xs font-mono text-slate-500 flex items-center gap-2">
                                <FileCode className="w-3 h-3" />
                                risk_assessment.js
                            </div>
                        </div>

                        <div className="relative flex-1 p-6 font-mono text-sm text-slate-300 overflow-hidden">
                            <pre className="relative z-10">
                                {codeSnippet.split('\n').map((line, i) => (
                                    <div key={i} className="flex">
                                        <span className="w-8 text-slate-700 text-right mr-4 select-none">{i + 1}</span>
                                        <span className={`${line.includes('SQL Injection') ? 'text-yellow-400' : ''}`}>
                                            {line}
                                        </span>
                                    </div>
                                ))}
                            </pre>

                            {/* Scanning Effect */}
                            {scanning && (
                                <div
                                    className="absolute inset-x-0 h-1 bg-gradient-to-r from-transparent via-cyan-400 to-transparent opacity-70 z-20 shadow-[0_0_15px_rgba(34,211,238,0.5)]"
                                    style={{
                                        top: `${(progress % 100)}%`,
                                        transition: 'top 0.1s linear'
                                    }}
                                />
                            )}
                            {scanning && (
                                <div className="absolute inset-0 bg-cyan-500/5 z-0 pointer-events-none animate-pulse" />
                            )}
                        </div>

                        {/* Status Bar */}
                        <div className="px-6 py-3 bg-slate-950 border-t border-slate-800 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                {scanning ? (
                                    <>
                                        <Loader2 className="w-4 h-4 text-cyan-400 animate-spin" />
                                        <span className="text-xs text-cyan-400 font-bold tracking-wider">正在扫描... {progress}%</span>
                                    </>
                                ) : (
                                    <>
                                        <Check className="w-4 h-4 text-emerald-400" />
                                        <span className="text-xs text-emerald-400 font-bold tracking-wider">扫描完成</span>
                                    </>
                                )}
                            </div>
                            <div className="font-mono text-[10px] text-slate-600">ID: A-9482-X2</div>
                        </div>
                    </div>

                    {/* Right: Analysis Report */}
                    <div className="w-full lg:w-96 flex flex-col gap-4">
                        <div className={`transition-all duration-500 delay-100 ${showReport ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'}`}>
                            <div className="p-6 bg-white rounded-2xl shadow-xl shadow-slate-200 border border-slate-100 relative overflow-hidden">
                                <div className="absolute top-0 right-0 w-32 h-32 bg-rose-100 rounded-full blur-3xl -mr-16 -mt-16 opacity-50"></div>
                                <div className="relative z-10">
                                    <div className="flex items-center gap-3 mb-4">
                                        <div className="w-10 h-10 rounded-xl bg-rose-50 text-rose-500 flex items-center justify-center">
                                            <Shield className="w-5 h-5" />
                                        </div>
                                        <div>
                                            <div className="text-xs font-bold text-slate-500 uppercase tracking-wider">安全评分</div>
                                            <div className="text-2xl font-black text-rose-500">85/100</div>
                                        </div>
                                    </div>
                                    <p className="text-xs text-slate-500 font-medium">检测到 2 个高危漏洞和 1 个代码异味。</p>
                                </div>
                            </div>
                        </div>

                        <div className={`transition-all duration-500 delay-200 flex-1 flex flex-col gap-3 ${showReport ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'}`}>
                            <h3 className="text-sm font-black text-slate-400 uppercase tracking-wider ml-1 mt-2">检测到的问题</h3>

                            {/* Issue Card 1 */}
                            <div className="group p-4 bg-white rounded-xl shadow-sm border border-slate-200 hover:border-amber-400 hover:shadow-md transition-all cursor-pointer">
                                <div className="flex items-start gap-3">
                                    <AlertTriangle className="w-5 h-5 text-amber-500 shrink-0 mt-0.5" />
                                    <div>
                                        <h4 className="text-sm font-bold text-slate-800 mb-1">潜在 SQL 注入风险</h4>
                                        <p className="text-xs text-slate-500 leading-relaxed">第 7 行检测到原始 SQL 拼接。</p>
                                        <div className="mt-3 flex gap-2">
                                            <button className="px-3 py-1.5 bg-amber-50 text-amber-700 text-[10px] font-bold rounded-lg hover:bg-amber-100 transition-colors">应用修复</button>
                                            <button className="px-3 py-1.5 bg-slate-50 text-slate-600 text-[10px] font-bold rounded-lg hover:bg-slate-100 transition-colors">忽略</button>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {/* Issue Card 2 */}
                            <div className="group p-4 bg-white rounded-xl shadow-sm border border-slate-200 hover:border-blue-400 hover:shadow-md transition-all cursor-pointer">
                                <div className="flex items-start gap-3">
                                    <Bug className="w-5 h-5 text-blue-500 shrink-0 mt-0.5" />
                                    <div>
                                        <h4 className="text-sm font-bold text-slate-800 mb-1">缺少参数校验</h4>
                                        <p className="text-xs text-slate-500 leading-relaxed">输入参数 'transaction' 缺少 Schema 校验。</p>
                                        <div className="mt-3 flex gap-2">
                                            <button className="px-3 py-1.5 bg-blue-50 text-blue-700 text-[10px] font-bold rounded-lg hover:bg-blue-100 transition-colors">添加校验</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </SlideLayout>
        </div>
    );
};
