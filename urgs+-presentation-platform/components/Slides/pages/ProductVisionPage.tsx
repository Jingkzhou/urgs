import React, { useEffect, useRef, useState } from 'react';
import { ArrowRight, Zap, Target, Layers, Users, ShieldAlert, BookOpen, CheckCircle2, Bot, Network, GitBranch } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

// Simple Intersection Observer Hook for scroll animations
const useOnScreen = (options: IntersectionObserverInit) => {
    const ref = useRef<HTMLDivElement>(null);
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        const observer = new IntersectionObserver(([entry]) => {
            if (entry.isIntersecting) {
                setIsVisible(true);
                observer.disconnect(); // Trigger only once
            }
        }, options);

        if (ref.current) {
            observer.observe(ref.current);
        }

        return () => {
            if (ref.current) observer.unobserve(ref.current);
        };
    }, [ref, options]);

    return [ref, isVisible] as const;
};

const FadeInSection = ({ children, delay = 0 }: { children: React.ReactNode, delay?: number }) => {
    const [ref, isVisible] = useOnScreen({ threshold: 0.1 });
    return (
        <div
            ref={ref}
            className={`transition-all duration-1000 ease-out transform ${isVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'}`}
            style={{ transitionDelay: `${delay}ms` }}
        >
            {children}
        </div>
    );
};

export const ProductVisionPage = () => {
    return (
        <div className="w-full h-full bg-slate-50 overflow-y-auto overflow-x-hidden relative scroll-smooth selection:bg-indigo-100">
            {/* Background Decoration */}
            <div className="fixed inset-0 pointer-events-none">
                <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-indigo-100/40 rounded-full blur-3xl opacity-50 mix-blend-multiply"></div>
                <div className="absolute bottom-0 left-0 w-[600px] h-[600px] bg-teal-100/40 rounded-full blur-3xl opacity-50 mix-blend-multiply"></div>
                <div className="absolute inset-0 opacity-[0.02] bg-[url('https://grainy-gradients.vercel.app/noise.svg')]"></div>
            </div>

            <div className="max-w-7xl mx-auto px-6 py-20 relative z-10">

                {/* 1. Hero Section */}
                <FadeInSection>
                    <div className="text-center mb-32">
                        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white border border-indigo-100 shadow-sm mb-8 animate-fade-in-up">
                            <span className="w-2 h-2 rounded-full bg-indigo-500 animate-pulse"></span>
                            <span className="text-xs font-bold text-indigo-900 tracking-wider uppercase">Product Vision</span>
                        </div>
                        <h1 className="text-6xl md:text-8xl font-black text-slate-900 tracking-tight mb-8 leading-tight">
                            URGS<span className="text-indigo-600">+</span> Vision
                        </h1>
                        <p className="text-2xl md:text-3xl font-light text-slate-500 max-w-3xl mx-auto">
                            重塑监管运营的 <span className="font-semibold text-indigo-600">智能范式</span>
                        </p>
                    </div>
                </FadeInSection>

                {/* 2. Timeline Story: The Problems */}
                <div className="mb-40 relative">
                    <div className="absolute left-1/2 top-0 bottom-0 w-px bg-gradient-to-b from-transparent via-slate-300 to-transparent -translate-x-1/2 md:block hidden"></div>

                    <div className="space-y-24">
                        {/* Timeline Item 1: Synergy Gap (Original) */}
                        <FadeInSection delay={100}>
                            <div className="flex flex-col md:flex-row items-center justify-center gap-8 md:gap-16">
                                <div className="md:w-1/2 flex justify-end">
                                    <div className="bg-white p-8 rounded-3xl shadow-xl shadow-slate-200/50 border border-slate-100 max-w-lg w-full group hover:border-amber-100 transition-all">
                                        <div className="w-12 h-12 bg-amber-50 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                                            <Users className="w-6 h-6 text-amber-500" />
                                        </div>
                                        <h3 className="text-xl font-bold text-slate-800 mb-3">协同断层</h3>
                                        <p className="text-slate-500 leading-relaxed">业务语言与技术代码的 "巴别塔"，导致需求理解偏差与反复沟通成本。</p>
                                    </div>
                                </div>
                                <div className="relative z-10 hidden md:flex items-center justify-center w-12 h-12 rounded-full bg-white border-4 border-slate-100 shadow-lg">
                                    <div className="w-4 h-4 rounded-full bg-slate-300"></div>
                                </div>
                                <div className="md:w-1/2 opacity-50 text-9xl font-black text-slate-100 select-none hidden md:block">01</div>
                            </div>
                        </FadeInSection>

                        {/* Timeline Item 2: Code Quality (New) */}
                        <FadeInSection delay={150}>
                            <div className="flex flex-col md:flex-row-reverse items-center justify-center gap-8 md:gap-16">
                                <div className="md:w-1/2 flex justify-start">
                                    <div className="bg-white p-8 rounded-3xl shadow-xl shadow-slate-200/50 border border-slate-100 max-w-lg w-full group hover:border-indigo-100 transition-all">
                                        <div className="w-12 h-12 bg-indigo-50 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                                            <CheckCircle2 className="w-6 h-6 text-indigo-500" />
                                        </div>
                                        <h3 className="text-xl font-bold text-slate-800 mb-3">代码质量参差</h3>
                                        <p className="text-slate-500 leading-relaxed">缺乏统一的开发规范与质量门禁，技术债日益累积，系统维护成本高昂。</p>
                                    </div>
                                </div>
                                <div className="relative z-10 hidden md:flex items-center justify-center w-12 h-12 rounded-full bg-white border-4 border-slate-100 shadow-lg">
                                    <div className="w-4 h-4 rounded-full bg-slate-300"></div>
                                </div>
                                <div className="md:w-1/2 opacity-50 text-9xl font-black text-slate-100 select-none text-right hidden md:block">02</div>
                            </div>
                        </FadeInSection>

                        {/* Timeline Item 3: Hidden Risks (Original) */}
                        <FadeInSection delay={200}>
                            <div className="flex flex-col md:flex-row items-center justify-center gap-8 md:gap-16">
                                <div className="md:w-1/2 flex justify-end">
                                    <div className="bg-white p-8 rounded-3xl shadow-xl shadow-slate-200/50 border border-slate-100 max-w-lg w-full group hover:border-red-100 transition-all">
                                        <div className="w-12 h-12 bg-red-50 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                                            <ShieldAlert className="w-6 h-6 text-red-500" />
                                        </div>
                                        <h3 className="text-xl font-bold text-slate-800 mb-3">风险隐蔽</h3>
                                        <p className="text-slate-500 leading-relaxed">底层模型变更如蝴蝶效应般影响上层报表，人工评估难以覆盖全链路影响。</p>
                                    </div>
                                </div>
                                <div className="relative z-10 hidden md:flex items-center justify-center w-12 h-12 rounded-full bg-white border-4 border-slate-100 shadow-lg">
                                    <div className="w-4 h-4 rounded-full bg-slate-300"></div>
                                </div>
                                <div className="md:w-1/2 opacity-50 text-9xl font-black text-slate-100 select-none hidden md:block">03</div>
                            </div>
                        </FadeInSection>

                        {/* Timeline Item 4: Launch Risk (New) */}
                        <FadeInSection delay={250}>
                            <div className="flex flex-col md:flex-row-reverse items-center justify-center gap-8 md:gap-16">
                                <div className="md:w-1/2 flex justify-start">
                                    <div className="bg-white p-8 rounded-3xl shadow-xl shadow-slate-200/50 border border-slate-100 max-w-lg w-full group hover:border-rose-100 transition-all">
                                        <div className="w-12 h-12 bg-rose-50 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                                            <Target className="w-6 h-6 text-rose-500" />
                                        </div>
                                        <h3 className="text-xl font-bold text-slate-800 mb-3">上线风险盲区</h3>
                                        <p className="text-slate-500 leading-relaxed">代码变更的影响面主要靠人工评估，难以覆盖全链路，导致上线故障频发。</p>
                                    </div>
                                </div>
                                <div className="relative z-10 hidden md:flex items-center justify-center w-12 h-12 rounded-full bg-white border-4 border-slate-100 shadow-lg">
                                    <div className="w-4 h-4 rounded-full bg-slate-300"></div>
                                </div>
                                <div className="md:w-1/2 opacity-50 text-9xl font-black text-slate-100 select-none text-right hidden md:block">04</div>
                            </div>
                        </FadeInSection>

                        {/* Timeline Item 5: Knowledge Islands (Original) */}
                        <FadeInSection delay={300}>
                            <div className="flex flex-col md:flex-row items-center justify-center gap-8 md:gap-16">
                                <div className="md:w-1/2 flex justify-end">
                                    <div className="bg-white p-8 rounded-3xl shadow-xl shadow-slate-200/50 border border-slate-100 max-w-lg w-full group hover:border-teal-100 transition-all">
                                        <div className="w-12 h-12 bg-teal-50 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                                            <BookOpen className="w-6 h-6 text-teal-500" />
                                        </div>
                                        <h3 className="text-xl font-bold text-slate-800 mb-3">知识孤岛</h3>
                                        <p className="text-slate-500 leading-relaxed">宝贵的排障经验散落在聊天记录中，不仅无法复用，更随人员流动而流失。</p>
                                    </div>
                                </div>
                                <div className="relative z-10 hidden md:flex items-center justify-center w-12 h-12 rounded-full bg-white border-4 border-slate-100 shadow-lg">
                                    <div className="w-4 h-4 rounded-full bg-slate-300"></div>
                                </div>
                                <div className="md:w-1/2 opacity-50 text-9xl font-black text-slate-100 select-none hidden md:block">05</div>
                            </div>
                        </FadeInSection>

                        {/* Timeline Item 6: Dev Ability (New) */}
                        <FadeInSection delay={350}>
                            <div className="flex flex-col md:flex-row-reverse items-center justify-center gap-8 md:gap-16">
                                <div className="md:w-1/2 flex justify-start">
                                    <div className="bg-white p-8 rounded-3xl shadow-xl shadow-slate-200/50 border border-slate-100 max-w-lg w-full group hover:border-violet-100 transition-all">
                                        <div className="w-12 h-12 bg-violet-50 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                                            <Users className="w-6 h-6 text-violet-500" />
                                        </div>
                                        <h3 className="text-xl font-bold text-slate-800 mb-3">人员能力瓶颈</h3>
                                        <p className="text-slate-500 leading-relaxed">系统复杂度高，过度依赖少数专家经验，新人上手慢，研发效率难以突破。</p>
                                    </div>
                                </div>
                                <div className="relative z-10 hidden md:flex items-center justify-center w-12 h-12 rounded-full bg-white border-4 border-slate-100 shadow-lg">
                                    <div className="w-4 h-4 rounded-full bg-slate-300"></div>
                                </div>
                                <div className="md:w-1/2 opacity-50 text-9xl font-black text-slate-100 select-none text-right hidden md:block">06</div>
                            </div>
                        </FadeInSection>
                    </div>
                </div>

                {/* 3. Solution -> Value Visual */}
                <FadeInSection>
                    <div className="bg-white rounded-[40px] shadow-2xl shadow-indigo-200/40 border border-indigo-50 p-12 md:p-20 relative overflow-hidden mb-32">
                        <div className="absolute top-0 w-full h-1 bg-gradient-to-r from-indigo-500 via-teal-400 to-indigo-500 opacity-20"></div>

                        <div className="text-center mb-16">
                            <h2 className="text-4xl font-bold text-slate-900 mb-4">从困局到破局</h2>
                            <p className="text-slate-500 max-w-2xl mx-auto">以技术、智能、流程为三大引擎，重构监管运营价值链</p>
                        </div>

                        <div className="flex flex-wrap justify-center gap-x-12 gap-y-16 relative z-10">
                            {/* Card 1: Automated Lineage */}
                            <div className="w-full md:w-[30%] flex flex-col items-center text-center group">
                                <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-indigo-200 mb-6 group-hover:-translate-y-2 transition-transform duration-500">
                                    <Network className="w-8 h-8 text-white" />
                                </div>
                                <h3 className="text-lg font-bold text-slate-800 mb-2">自动化血缘</h3>
                                <p className="text-sm text-slate-500 mb-6 px-4">SQL 解析与全链路追踪</p>
                                <ArrowRight className="w-5 h-5 text-indigo-200 mb-6 rotate-90 md:rotate-0" />
                                <div className="px-6 py-3 bg-indigo-50 rounded-xl border border-indigo-100">
                                    <span className="text-indigo-700 font-bold whitespace-nowrap">秒级排障定位</span>
                                </div>
                            </div>

                            {/* Card 2: RAG + Agent */}
                            <div className="w-full md:w-[30%] flex flex-col items-center text-center group">
                                <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-teal-400 to-emerald-500 flex items-center justify-center shadow-lg shadow-teal-200 mb-6 group-hover:-translate-y-2 transition-transform duration-500">
                                    <Bot className="w-8 h-8 text-white" />
                                </div>
                                <h3 className="text-lg font-bold text-slate-800 mb-2">RAG + Agent</h3>
                                <p className="text-sm text-slate-500 mb-6 px-4">知识融合与智能问答</p>
                                <ArrowRight className="w-5 h-5 text-teal-200 mb-6 rotate-90 md:rotate-0" />
                                <div className="px-6 py-3 bg-teal-50 rounded-xl border border-teal-100">
                                    <span className="text-teal-700 font-bold whitespace-nowrap">7x24h 专家响应</span>
                                </div>
                            </div>

                            {/* Card 3: Version Control */}
                            <div className="w-full md:w-[30%] flex flex-col items-center text-center group">
                                <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center shadow-lg shadow-orange-200 mb-6 group-hover:-translate-y-2 transition-transform duration-500">
                                    <GitBranch className="w-8 h-8 text-white" />
                                </div>
                                <h3 className="text-lg font-bold text-slate-800 mb-2">版本闭环</h3>
                                <p className="text-sm text-slate-500 mb-6 px-4">需求到发布全流程管控</p>
                                <ArrowRight className="w-5 h-5 text-orange-200 mb-6 rotate-90 md:rotate-0" />
                                <div className="px-6 py-3 bg-orange-50 rounded-xl border border-orange-100">
                                    <span className="text-orange-700 font-bold whitespace-nowrap">100% 可追溯</span>
                                </div>
                            </div>

                            {/* Card 4: AI Code Smart Check (New) */}
                            <div className="w-full md:w-[30%] flex flex-col items-center text-center group">
                                <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center shadow-lg shadow-violet-200 mb-6 group-hover:-translate-y-2 transition-transform duration-500">
                                    <CheckCircle2 className="w-8 h-8 text-white" />
                                </div>
                                <h3 className="text-lg font-bold text-slate-800 mb-2">AI 代码智查</h3>
                                <p className="text-sm text-slate-500 mb-6 px-4">开发规范与质量智能扫描</p>
                                <ArrowRight className="w-5 h-5 text-violet-200 mb-6 rotate-90 md:rotate-0" />
                                <div className="px-6 py-3 bg-violet-50 rounded-xl border border-violet-100">
                                    <span className="text-violet-700 font-bold whitespace-nowrap">代码隐患 100% 识别</span>
                                </div>
                            </div>

                            {/* Card 5: Intelligent Risk Assessment (New) */}
                            <div className="w-full md:w-[30%] flex flex-col items-center text-center group">
                                <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-rose-500 to-pink-600 flex items-center justify-center shadow-lg shadow-rose-200 mb-6 group-hover:-translate-y-2 transition-transform duration-500">
                                    <ShieldAlert className="w-8 h-8 text-white" />
                                </div>
                                <h3 className="text-lg font-bold text-slate-800 mb-2">上线风险智能评估</h3>
                                <p className="text-sm text-slate-500 mb-6 px-4">变更影响面精准预测</p>
                                <ArrowRight className="w-5 h-5 text-rose-200 mb-6 rotate-90 md:rotate-0" />
                                <div className="px-6 py-3 bg-rose-50 rounded-xl border border-rose-100">
                                    <span className="text-rose-700 font-bold whitespace-nowrap">变更零故障</span>
                                </div>
                            </div>
                        </div>

                        {/* Connecting Lines (SVG Decoration) */}
                        <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-30 md:block hidden" xmlns="http://www.w3.org/2000/svg">
                            <path d="M 200 150 Q 300 150 400 150" fill="none" stroke="currentColor" className="text-indigo-200" strokeWidth="2" strokeDasharray="4 4" />
                            <path d="M 600 150 Q 700 150 800 150" fill="none" stroke="currentColor" className="text-teal-200" strokeWidth="2" strokeDasharray="4 4" />
                        </svg>
                    </div>
                </FadeInSection>

                {/* 4. Future Vision */}
                <FadeInSection>
                    <div className="text-center pb-32">
                        <h2 className="text-3xl font-bold text-slate-900 mb-10">我们的愿景</h2>
                        <div className="inline-block relative">
                            <div className="absolute -inset-1 bg-gradient-to-r from-indigo-500 via-purple-500 to-rose-500 rounded-2xl opacity-20 blur-lg"></div>
                            <div className="relative bg-white/80 backdrop-blur-sm px-12 py-10 rounded-2xl border border-slate-100 shadow-xl">
                                <p className="text-2xl md:text-4xl font-black text-slate-800 mb-6 leading-tight">
                                    构建 <span className="text-indigo-600">代码智能</span> 与 <span className="text-rose-600">主动防御</span> 的<br className="hidden md:block" />新一代监管底座
                                </p>
                                <div className="flex items-center justify-center gap-4 text-slate-500 font-medium text-sm md:text-base tracking-widest uppercase">
                                    <span>让研发更高效</span>
                                    <span className="text-slate-300">•</span>
                                    <span>让上线更安全</span>
                                    <span className="text-slate-300">•</span>
                                    <span>让运营更智慧</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </FadeInSection>

            </div>
        </div>
    );
};
