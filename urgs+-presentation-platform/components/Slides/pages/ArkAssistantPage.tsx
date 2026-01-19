import React from 'react';
import { Network, BookOpen, ArrowLeft } from 'lucide-react';
import { SimulatedAIChat } from '../shared/SimulatedAIChat';

interface ArkAssistantPageProps {
    onBack?: () => void;
}

export const ArkAssistantPage = ({ onBack }: ArkAssistantPageProps) => (
    <div className="w-full h-full bg-[#F5F5F7] text-slate-900 font-sans relative flex flex-col overflow-hidden">
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

        {/* Main Content Scroll Area */}
        <div className="flex-1 overflow-y-auto overflow-x-hidden flex items-center justify-center">
            <div className="w-full max-w-7xl mx-auto px-6 py-12">
                <div className="grid md:grid-cols-2 gap-16 items-center">
                    {/* Left: Interactive Chat Simulation */}
                    <div className="anim-scale-in delay-200 order-2 md:order-1">
                        <SimulatedAIChat scenario={[
                            { role: 'user', content: 'G0102 五级分类是怎么算出来的？' },
                            {
                                role: 'ai',
                                content: 'AI 解析：基于“贷款分户账”(L_ACCT_LOAN)，根据贷款五级分类映射 G0102 报表项。指标口径为汇率折算后的贷款余额合计，并剔除了委托贷款账户、核销及已转让资产。',
                                extra: (
                                    <div className="space-y-4">
                                        <div className="p-3 bg-white rounded-lg border border-slate-100 text-[10px] font-mono whitespace-pre-wrap max-h-48 overflow-y-auto shadow-inner">
                                            {`SELECT ORG_NUM AS ORG_NUM,
CASE
WHEN LOAN_GRADE_CD = '1' OR LOAN_GRADE_CD IS NULL THEN 'G01_2_1.1.C'
WHEN LOAN_GRADE_CD = '2' THEN 'G01_2_1.2.C'
WHEN LOAN_GRADE_CD = '3' THEN 'G01_2_1.3.C'
WHEN LOAN_GRADE_CD = '4' THEN 'G01_2_1.4.C'
WHEN LOAN_GRADE_CD = '5' THEN 'G01_2_1.5.C'
END AS ITEM_NUM,
sum(NVL(LOAN_ACCT_BAL * u.ccy_rate, 0)) AS ITEM_VAL
FROM SMTMODS.L_ACCT_LOAN A
LEFT JOIN SMTMODS.L_PUBL_RATE U
ON U.CCY_DATE = TO_DATE(I_DATADATE, 'YYYYMMDD')
AND U.BASIC_CCY = a.CURR_CD
AND U.DATA_DATE = I_DATADATE
WHERE A.ACCT_TYP NOT LIKE '90%'
AND A.DATA_DATE = I_DATADATE
AND A.LOAN_STOCKEN_DATE IS NULL
GROUP BY a.org_num, a.LOAN_GRADE_CD`}
                                        </div>
                                        <div className="p-3 bg-white rounded-lg border border-slate-100 text-xs">
                                            <div className="font-bold text-slate-400 mb-2 uppercase text-[9px]">数据依据</div>
                                            <div className="flex flex-col gap-1.5">
                                                <div className="flex items-center gap-2 text-indigo-600 text-[10px]">
                                                    <Network className="w-3 h-3" /> 表关系血缘图谱
                                                </div>
                                                <div className="flex items-center gap-2 text-indigo-600 text-[10px]">
                                                    <BookOpen className="w-3 h-3" /> 监管手册 v4.2 知识库
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                )
                            }
                        ]} />
                    </div>

                    {/* Right: Feature Descriptions */}
                    <div className="space-y-8 order-1 md:order-2">
                        <div className="mb-8">
                            <div className="inline-flex items-center justify-center gap-2 mb-6 px-3 py-1 bg-white border border-slate-200 rounded-full shadow-sm">
                                <span className="text-xs font-bold text-indigo-600 tracking-wider uppercase">Intelligent Agent Swarm</span>
                            </div>
                            <h2 className="text-4xl md:text-5xl font-black text-slate-900 leading-tight mb-6">
                                Ark 助手<br />
                                <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-blue-500">身边的监管专家</span>
                            </h2>
                            <p className="text-lg text-slate-500 leading-relaxed max-w-md">
                                基于大模型的智能体集群，全天候响应业务咨询，将复杂的监管规则转化为即问即答的领域知识。
                            </p>
                        </div>

                        <div className="space-y-4">
                            <div className="p-6 bg-white rounded-3xl shadow-[0_2px_12px_rgba(0,0,0,0.04)] border border-slate-100 hover:shadow-[0_4px_20px_rgba(0,0,0,0.06)] transition-all duration-300">
                                <h5 className="font-bold text-slate-800 mb-2 flex items-center gap-2">
                                    <div className="w-2 h-2 rounded-full bg-indigo-500"></div>
                                    降本增效：/ark 对话即检索
                                </h5>
                                <p className="text-sm text-slate-500 leading-relaxed pl-4">大幅减少人工检索文档和排障的时间，提升 40% 以上响应速度。</p>
                            </div>
                            <div className="p-6 bg-white rounded-3xl shadow-[0_2px_12px_rgba(0,0,0,0.04)] border border-slate-100 hover:shadow-[0_4px_20px_rgba(0,0,0,0.06)] transition-all duration-300">
                                <h5 className="font-bold text-slate-800 mb-2 flex items-center gap-2">
                                    <div className="w-2 h-2 rounded-full bg-blue-500"></div>
                                    知识沉淀：不再依赖“老师傅”
                                </h5>
                                <p className="text-sm text-slate-500 leading-relaxed pl-4">组织经验通过 RAG 持续积累，知识不因人员流失而中断。</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
);
