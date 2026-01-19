import React from 'react';
import { Users, Code2 } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';
import { InteractiveBarChart } from '../shared/InteractiveBarChart';

export const DashboardPage = () => (
    <SlideLayout title="角色化工作台：千人千面的协同驾驶舱">
        <div className="grid lg:grid-cols-2 gap-12 w-full max-w-6xl mx-auto items-center">
            <div className="space-y-8">
                <div className="anim-fade-right delay-200">
                    <div className="grid grid-cols-1 gap-4">
                        <div className="bg-teal-50 p-6 rounded-2xl border border-teal-100 anim-fade-up delay-500 hover:shadow-lg hover:border-teal-300 transition-all cursor-default">
                            <h5 className="font-bold text-teal-900 mb-2 flex items-center gap-2">
                                <Users className="w-5 h-5" /> 业务/填报：直观理解
                            </h5>
                            <ul className="text-xs text-teal-700/80 space-y-2 list-disc pl-4">
                                <li>监管系统入口聚合与报送进度看板</li>
                                <li>AI 指标口径“自然语言”翻译视图</li>
                                <li>版本变更公告与数据治理质量预警</li>
                            </ul>
                        </div>
                        <div className="bg-indigo-50 p-6 rounded-2xl border border-indigo-100 anim-fade-up delay-400 hover:shadow-lg hover:border-indigo-300 transition-all cursor-default">
                            <h5 className="font-bold text-indigo-900 mb-2 flex items-center gap-2">
                                <Code2 className="w-5 h-5" /> 研发/运维：极致交付
                            </h5>
                            <ul className="text-xs text-indigo-700/80 space-y-2 list-disc pl-4">
                                <li>流水线监控 (构建/部署/回滚一键操作)</li>
                                <li>错误日志分析与系统 API 健康探针</li>
                                <li>自动化发布记录生成的智查报告</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
            <div className="anim-scale-in delay-300">
                <InteractiveBarChart />
            </div>
        </div>
    </SlideLayout>
);
