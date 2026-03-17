import React from 'react';
import { ShieldAlert, Zap, Cpu, Boxes, ArrowRight, Compass, Sparkles, Map, Target } from 'lucide-react';

export const TableOfContentsPage = ({ onNavigate }: { onNavigate: (index: number) => void }) => (
    <div className="relative w-screen h-screen overflow-hidden bg-slate-50 flex flex-col items-center justify-center text-slate-800">
        {/* Clean, light background with subtle pattern */}
        <div className="absolute inset-0 bg-slate-50 z-0"></div>
        <div className="absolute inset-0 z-0 opacity-[0.03]"
            style={{ backgroundImage: 'radial-gradient(circle at 50% 50%, #4f46e5 1px, transparent 1px)', backgroundSize: '32px 32px' }}>
        </div>

        {/* Decoration Blobs */}
        <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-indigo-100/40 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>
        <div className="absolute bottom-0 left-0 w-[600px] h-[600px] bg-teal-100/40 rounded-full blur-3xl translate-y-1/2 -translate-x-1/2"></div>

        <div className="relative z-10 w-full max-w-7xl px-8 h-full flex flex-col pt-16 md:pt-20">
            <div className="text-center mb-12 space-y-4">
                <div className="inline-flex items-center gap-2 px-3 py-1 bg-white border border-slate-200 rounded-full shadow-sm mb-2">
                    <Map className="w-3 h-3 text-indigo-500" />
                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">导航导览</span>
                </div>
                <h2 className="text-4xl md:text-6xl font-black tracking-tight text-slate-900">
                    演示大纲
                </h2>
                <p className="text-slate-500 text-lg max-w-2xl mx-auto font-light">
                    开启您的 <span className="font-semibold text-indigo-600">监管报送一体化系统 (URGS)</span> 探索之旅
                </p>
            </div>

            {/* Featured Grid Layout (1 Large Left, 2 Right) */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 max-w-6xl mx-auto w-full h-[500px]">

                {/* 1. Merged Module: Vision & Challenges (Span 7) */}
                <div
                    onClick={() => onNavigate(2)} // Navigate to ProductVisionPage (Index 2)
                    className="lg:col-span-7 h-full group relative bg-gradient-to-br from-indigo-50 to-white p-10 rounded-[32px] border border-indigo-100 hover:border-indigo-300 transition-all duration-300 cursor-pointer flex flex-col shadow-xl shadow-indigo-100/50 hover:shadow-indigo-200/50 hover:-translate-y-1 overflow-hidden"
                >
                    <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-100/50 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 group-hover:bg-indigo-200/50 transition-colors"></div>

                    <div className="flex justify-between items-start z-10 mb-8">
                        <div className="text-indigo-600 p-4 bg-white rounded-2xl shadow-sm border border-white group-hover:scale-110 transition-transform duration-500">
                            <Target className="w-8 h-8" />
                        </div>
                        <span className="text-5xl font-black text-slate-200/80 group-hover:text-slate-200 transition-colors select-none">01</span>
                    </div>

                    <div className="z-10 mt-auto space-y-4">
                        <div className="space-y-1">
                            <h3 className="text-3xl font-black text-slate-900 leading-tight">愿景与挑战</h3>
                            <p className="text-sm font-bold text-indigo-500 uppercase tracking-widest">Vision & Strategy</p>
                        </div>
                        <p className="text-slate-600 text-lg leading-relaxed max-w-lg">
                            智能监管运营的新范式与核心价值主张，直击协同断层与痛点。
                        </p>
                    </div>

                    <div className="absolute bottom-10 right-10 w-12 h-12 rounded-full bg-white shadow-sm border border-slate-100 flex items-center justify-center opacity-0 group-hover:opacity-100 translate-x-4 group-hover:translate-x-0 transition-all duration-300">
                        <ArrowRight className="w-5 h-5 text-indigo-600" />
                    </div>
                </div>

                {/* Right Column (Span 5) */}
                <div className="lg:col-span-5 h-full flex flex-col gap-6">

                    {/* 2. Architecture */}
                    <div
                        onClick={() => onNavigate(4)} // Index 4: Architecture
                        className="flex-1 group relative bg-gradient-to-br from-slate-50 to-white p-8 rounded-[32px] border border-slate-200 hover:border-slate-400 transition-all duration-300 cursor-pointer flex flex-col justify-between shadow-lg shadow-slate-200/50 hover:shadow-slate-300/50 hover:-translate-y-1 overflow-hidden"
                    >
                        <div className="flex justify-between items-start z-10">
                            <div className="text-slate-700 p-3 bg-white rounded-xl shadow-sm border border-white group-hover:scale-110 transition-transform">
                                <Cpu className="w-6 h-6" />
                            </div>
                            <span className="text-3xl font-black text-slate-200/80 group-hover:text-slate-200 transition-colors select-none">02</span>
                        </div>
                        <div className="z-10">
                            <h3 className="text-xl font-bold text-slate-800">技术架构</h3>
                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Architecture</p>
                            <p className="text-slate-500 text-sm">基于 AI Agent 的分层架构设计</p>
                        </div>
                    </div>

                    {/* 3. Core Capabilities */}
                    <div
                        onClick={() => onNavigate(5)} // Index 5: VisionPage (Ecosystem)
                        className="flex-1 group relative bg-gradient-to-br from-teal-50 to-white p-8 rounded-[32px] border border-teal-100 hover:border-teal-300 transition-all duration-300 cursor-pointer flex flex-col justify-between shadow-lg shadow-teal-100/50 hover:shadow-teal-200/50 hover:-translate-y-1 overflow-hidden"
                    >
                        <div className="flex justify-between items-start z-10">
                            <div className="text-teal-600 p-3 bg-white rounded-xl shadow-sm border border-white group-hover:scale-110 transition-transform">
                                <Boxes className="w-6 h-6" />
                            </div>
                            <span className="text-3xl font-black text-slate-200/80 group-hover:text-slate-200 transition-colors select-none">03</span>
                        </div>
                        <div className="z-10">
                            <h3 className="text-xl font-bold text-slate-800">核心能力</h3>
                            <p className="text-[10px] font-bold text-teal-500 uppercase tracking-widest mb-2">Capabilities</p>
                            <p className="text-slate-500 text-sm">血缘、AI、资产与协同四大支柱</p>
                        </div>
                    </div>

                </div>
            </div>

            {/* Footer */}
            <div className="mt-12 text-center">
                <div className="inline-flex items-center gap-2 text-slate-400 text-xs font-medium">
                    <Sparkles className="w-3 h-3 text-indigo-400" />
                    <span>Powered by URGS+ Intelligent Engine</span>
                </div>
            </div>
        </div>
    </div>
);
