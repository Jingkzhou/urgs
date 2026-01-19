import React from 'react';
import { Terminal, FileSearch, LineChart, Network } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const AssetPillarPage = () => (
    <SlideLayout title="能力三：资产管理与血缘图谱" subtitle="透视数据流动，打通最后一公里">
        <div className="flex flex-col md:flex-row items-center gap-16 mt-8">
            <div className="flex-1 space-y-8 anim-fade-right delay-200">
                <div className="grid grid-cols-1 gap-4">
                    {[
                        { title: "多方言 SQL 解析引擎", desc: "自研编译器级解析，适配 Hive, Spark, Oracle, MySQL等方言。", icon: <Terminal className="text-indigo-500" /> },
                        { title: "影响面精准分析", desc: "回答‘改了这个字段会影响哪个下游报表？’", icon: <FileSearch className="text-teal-500" /> },
                        { title: "全链路维护追踪", desc: "记录资产所有变更痕迹，满足合规审计需要。", icon: <LineChart className="text-rose-500" /> }
                    ].map((item, i) => (
                        <div key={i} className="flex gap-4 p-4 bg-white rounded-2xl border border-slate-50 shadow-sm">
                            <div className="shrink-0">{item.icon}</div>
                            <div>
                                <h5 className="font-bold text-slate-800">{item.title}</h5>
                                <p className="text-xs text-slate-500">{item.desc}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
            <div className="flex-1 relative anim-scale-in delay-500">
                <div className="w-80 h-80 bg-teal-600 rounded-full flex items-center justify-center text-white shadow-2xl animate-pulse">
                    <Network className="w-40 h-40" />
                </div>
            </div>
        </div>
    </SlideLayout>
);
