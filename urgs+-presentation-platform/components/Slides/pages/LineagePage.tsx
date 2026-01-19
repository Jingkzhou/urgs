import React from 'react';
import { ArrowLeft } from 'lucide-react';
import { ActiveLineageGraph } from '../shared/ActiveLineageGraph';

interface LineagePageProps {
    onBack?: () => void;
}

export const LineagePage = ({ onBack }: LineagePageProps) => {
    return (
        <div className="md:fixed inset-0 w-full h-full bg-slate-50 relative overflow-hidden">
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

            {/* Fullscreen Graph Area */}
            <div className="absolute inset-0 w-full h-full bg-slate-50">
                <ActiveLineageGraph />
            </div>

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
    );
};
