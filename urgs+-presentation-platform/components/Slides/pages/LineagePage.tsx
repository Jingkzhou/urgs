import React from 'react';
import { SlideLayout } from '../layout/SlideLayout';
import { ActiveLineageGraph } from '../shared/ActiveLineageGraph';

export const LineagePage = () => (
    <SlideLayout title="血缘可视化：一眼洞穿监管生命周期">
        <div className="w-full max-w-5xl mx-auto space-y-12">
            <div className="bg-white rounded-[3rem] p-8 shadow-2xl border border-slate-100 min-h-[500px] relative overflow-hidden anim-scale-in">
                <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-indigo-500 to-transparent opacity-30"></div>
                <ActiveLineageGraph />
            </div>
            <div className="grid md:grid-cols-3 gap-6">
                <div className="p-6 bg-indigo-900 text-white rounded-2xl shadow-xl">
                    <h5 className="font-bold mb-2">字段级溯源</h5>
                    <p className="text-[10px] opacity-70">基于 Neo4j 图存储实现报表指标到底层字段的穿透追踪。</p>
                </div>
                <div className="p-6 bg-slate-100 rounded-2xl">
                    <h5 className="font-bold mb-2">资产自动更新</h5>
                    <p className="text-[10px] text-slate-500">定时同步物理模型，元数据与现实环境永远一致。</p>
                </div>
                <div className="p-6 bg-slate-100 rounded-2xl">
                    <h5 className="font-bold mb-2">代码值域管理</h5>
                    <p className="text-[10px] text-slate-500">维护业务标准的字典项，统一全行监管资产认知。</p>
                </div>
            </div>
        </div>
    </SlideLayout>
);
