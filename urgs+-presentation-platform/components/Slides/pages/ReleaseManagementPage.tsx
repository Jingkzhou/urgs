import React from 'react';
import { SlideLayout } from '../layout/SlideLayout';
import { RiskGauge } from '../shared/RiskGauge';
import { ArrowLeft } from 'lucide-react';

interface ReleaseManagementPageProps {
    onBack?: () => void;
}

export const ReleaseManagementPage = ({ onBack }: ReleaseManagementPageProps) => (
    <div className="relative w-full h-full p-8 md:p-16 flex flex-col">
        {onBack && (
            <button
                onClick={onBack}
                className="absolute top-6 left-6 z-50 p-2.5 bg-white/90 hover:bg-white backdrop-blur-md border border-slate-200/60 rounded-xl shadow-lg hover:shadow-xl transition-all text-slate-600 hover:text-slate-900 group"
                title="返回"
            >
                <ArrowLeft className="w-5 h-5 group-hover:-translate-x-0.5 transition-transform" />
            </button>
        )}
        <SlideLayout title="能力四：风险防控与版本管理">
            <div className="grid lg:grid-cols-2 gap-12 items-center w-full">
                <div className="anim-scale-in delay-200">
                    <RiskGauge />
                </div>
                <div className="space-y-6 anim-fade-right delay-400">
                    <h4 className="text-2xl font-bold text-slate-800">变更事前阻断 (Pre-Check)</h4>
                    <div className="space-y-4">
                        <div className="p-4 bg-white rounded-xl border-l-4 border-rose-500 shadow-sm">
                            <p className="text-sm font-bold text-slate-800">“我能感知每一个表字段的影响面”</p>
                            <p className="text-xs text-slate-500 mt-1">当基础表修改时，血缘图谱自动报警，阻断高风险代码上线，强制二级审批。</p>
                        </div>
                        <div className="p-4 bg-white rounded-xl border-l-4 border-indigo-500 shadow-sm">
                            <p className="text-sm font-bold text-slate-800">AI 智查报告</p>
                            <p className="text-xs text-slate-500 mt-1">自动化走查 SQL 规范、索引建议及合规性，输出风险证据图。</p>
                        </div>
                        <div className="p-4 bg-white rounded-xl border-l-4 border-teal-500 shadow-sm">
                            <p className="text-sm font-bold text-slate-800">全流程灰度</p>
                            <p className="text-xs text-slate-500 mt-1">多环境一键部署，支持自动记录发布台账与一键回滚。</p>
                        </div>
                    </div>
                </div>
            </div>
        </SlideLayout>
    </div>
);
