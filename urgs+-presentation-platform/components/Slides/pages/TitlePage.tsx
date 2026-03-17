import React from 'react';
import { Bot, ChevronRight } from 'lucide-react';

export const TitlePage = () => (
    <div className="relative w-screen h-screen overflow-hidden bg-slate-50 flex flex-col items-center justify-center text-center perspective-grid selection:bg-indigo-100">

        {/* Background - Elegant Light Abstract */}
        <div className="absolute inset-0 z-0 bg-slate-50">
            {/* Soft Gradients */}
            <div className="absolute top-[-20%] right-[-10%] w-[800px] h-[800px] bg-indigo-100/50 rounded-full blur-3xl opacity-60 animate-pulse duration-[8000ms]"></div>
            <div className="absolute bottom-[-20%] left-[-10%] w-[600px] h-[600px] bg-teal-100/50 rounded-full blur-3xl opacity-60 animate-pulse duration-[6000ms] delay-1000"></div>

            {/* Subtle Grid */}
            <div className="absolute inset-0 opacity-[0.03]"
                style={{ backgroundImage: 'linear-gradient(#4f46e5 1px, transparent 1px), linear-gradient(to right, #4f46e5 1px, transparent 1px)', backgroundSize: '40px 40px' }}>
            </div>
        </div>

        {/* Floating Elements (Glassmorphism) */}
        <div className="absolute top-32 left-10 hidden md:block anim-fade-right">
            <div className="glass-card px-4 py-3 rounded-xl flex flex-col gap-1 border border-white/50 shadow-lg shadow-indigo-100/50">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">System Status</span>
                <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse"></div>
                    <span className="text-xs font-bold text-slate-600">Online / Stable</span>
                </div>
            </div>
        </div>

        <div className="absolute bottom-32 right-10 hidden md:block anim-fade-right delay-200">
            <div className="glass-card px-4 py-3 rounded-xl flex flex-col gap-1 border border-white/50 shadow-lg shadow-teal-100/50 text-right">
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">AI Core</span>
                <div className="flex items-center gap-2 justify-end">
                    <span className="text-xs font-bold text-slate-600">RAG Engine Active</span>
                    <Bot className="w-3 h-3 text-indigo-500" />
                </div>
            </div>
        </div>

        {/* Central Visual */}
        <div className="relative z-10 mb-12 scale-110 md:scale-125">
            <div className="relative w-48 h-48 flex items-center justify-center">
                {/* Spinning Rings - Light Theme */}
                <div className="absolute inset-0 border border-indigo-200 rounded-full animate-spin-slow"></div>
                <div className="absolute inset-4 border border-teal-200 rounded-full animate-spin-reverse-slower border-dashed"></div>
                <div className="absolute inset-0 bg-white/40 backdrop-blur-sm rounded-full shadow-2xl shadow-indigo-200/50"></div>

                {/* Center Icon */}
                <div className="relative z-20 bg-white p-5 rounded-full border border-white shadow-[0_10px_40px_rgba(79,70,229,0.15)] animate-float">
                    <div className="bg-gradient-to-br from-indigo-500 to-indigo-600 p-4 rounded-full text-white">
                        <Bot className="w-12 h-12" />
                    </div>
                </div>

                {/* Orbiting DOT */}
                <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                    <div className="w-3 h-3 bg-indigo-500 rounded-full shadow-lg shadow-indigo-300 animate-bounce"></div>
                </div>
            </div>
        </div>

        {/* Main Title Group */}
        <div className="relative z-20 space-y-4">
            <h1 className="text-7xl md:text-9xl font-black text-slate-900 tracking-tighter relative inline-block">
                URGS<span className="text-indigo-600">+</span>
                {/* Subtle reflection/shadow */}
                <span className="absolute -bottom-4 left-0 w-full h-8 bg-gradient-to-t from-white via-white/50 to-transparent blur-[2px] transform scale-y-[-0.3] opacity-20 origin-bottom pointer-events-none select-none">URGS+</span>
            </h1>

            <div className="h-1.5 w-24 mx-auto bg-gradient-to-r from-indigo-500 to-teal-400 rounded-full mt-2 mb-8 shadow-sm"></div>

            <h2 className="text-3xl md:text-5xl font-extrabold text-slate-800 mb-6 anim-fade-up leading-tight" style={{ animationDelay: '0.2s' }}>
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-indigo-500">智能</span>监管运营新范式
            </h2>

            <p className="text-lg md:text-xl text-slate-500 max-w-2xl mx-auto font-medium leading-relaxed anim-fade-up" style={{ animationDelay: '0.4s' }}>
                一体化 · 智能化 · 可视化
                <span className="block text-sm font-normal text-slate-400 mt-2">Enterprise Resource Governance System Plus</span>
            </p>
        </div>

        {/* CTA Button */}
        <div className="mt-16 z-20 anim-scale-in" style={{ animationDelay: '0.6s' }}>
            <button className="group relative px-8 py-3 bg-white border border-indigo-100 rounded-full overflow-hidden transition-all hover:border-indigo-200 hover:shadow-xl hover:shadow-indigo-100/50 hover:-translate-y-1">
                <span className="relative flex items-center gap-2 text-indigo-900 font-bold text-sm tracking-wide group-hover:gap-3 transition-all">
                    INITIALIZE SYSTEM <ChevronRight className="w-4 h-4 text-indigo-500" />
                </span>
            </button>
        </div>

    </div>
);
