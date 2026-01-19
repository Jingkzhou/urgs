import React from 'react';
import { Bot, Zap, ShieldCheck, ArrowRight, X } from 'lucide-react';

export const AIJourneyOverlay = ({ onClose }: { onClose: () => void }) => {
    return (
        <div className="fixed inset-0 z-[100] bg-slate-950 flex flex-col items-center justify-center overflow-hidden animate-in fade-in duration-500">
            <div className="absolute inset-0 opacity-20 pointer-events-none">
                <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
                    <defs>
                        <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                            <path d="M 40 0 L 0 0 0 40" fill="none" stroke="white" strokeWidth="0.5" />
                        </pattern>
                    </defs>
                    <rect width="100%" height="100%" fill="url(#grid)" />
                </svg>
            </div>

            <div className="absolute inset-0 flex items-center justify-center">
                <div className="relative w-full h-full max-w-4xl max-h-4xl opacity-30">
                    {[...Array(12)].map((_, i) => (
                        <div
                            key={i}
                            className="absolute bg-indigo-500 rounded-full blur-xl animate-pulse"
                            style={{
                                width: Math.random() * 200 + 100 + 'px',
                                height: Math.random() * 200 + 100 + 'px',
                                left: Math.random() * 80 + 10 + '%',
                                top: Math.random() * 80 + 10 + '%',
                                animationDuration: Math.random() * 3 + 2 + 's',
                                animationDelay: i * 0.5 + 's'
                            }}
                        />
                    ))}
                </div>
            </div>

            <div className="relative z-10 flex flex-col items-center text-center px-6">
                <div className="relative mb-12">
                    <div className="w-48 h-48 bg-indigo-600 rounded-full flex items-center justify-center shadow-[0_0_80px_rgba(79,70,229,0.5)] animate-bounce-slow">
                        <Bot className="w-24 h-24 text-white" />
                    </div>
                    <div className="absolute -inset-4 border-2 border-indigo-400 rounded-full border-dashed animate-[spin_10s_linear_infinite]" />
                    <div className="absolute -inset-8 border border-indigo-500/30 rounded-full animate-[spin_20s_linear_infinite_reverse]" />
                </div>

                <h3 className="text-5xl md:text-7xl font-black text-white mb-6 tracking-tight">
                    URGS<span className="text-indigo-500">+</span> <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-teal-400">方舟引擎已启动</span>
                </h3>

                <p className="text-xl md:text-2xl text-slate-400 max-w-2xl mb-12 font-light leading-relaxed">
                    正在初始化智能监管大脑，构建全链路数据血缘图谱，<br />重塑您的企业数字化合规运营范式。
                </p>

                <div className="flex gap-4">
                    <div className="flex items-center gap-2 px-6 py-3 bg-white/5 border border-white/10 rounded-full text-slate-300 text-sm font-medium">
                        <Zap className="w-4 h-4 text-amber-400" /> RAG 混合检索就绪
                    </div>
                    <div className="flex items-center gap-2 px-6 py-3 bg-white/5 border border-white/10 rounded-full text-slate-300 text-sm font-medium">
                        <ShieldCheck className="w-4 h-4 text-teal-400" /> 合规 Agent 在线
                    </div>
                </div>

                <button
                    onClick={() => window.open((import.meta as any).env.VITE_DASHBOARD_URL || 'http://localhost:3000', '_blank')}
                    className="mt-16 group flex items-center gap-3 px-8 py-4 bg-white text-indigo-900 rounded-full text-lg font-bold hover:bg-indigo-50 transition-all shadow-xl"
                >
                    进入智能驾驶舱 <ArrowRight className="group-hover:translate-x-1 transition-transform" />
                </button>
            </div>

            <button onClick={onClose} className="absolute top-10 right-10 p-3 text-slate-500 hover:text-white transition-colors">
                <X className="w-8 h-8" />
            </button>

            <style>{`
        @keyframes bounce-slow {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-20px); }
        }
        .animate-bounce-slow {
          animation: bounce-slow 4s ease-in-out infinite;
        }
      `}</style>
        </div>
    );
};
