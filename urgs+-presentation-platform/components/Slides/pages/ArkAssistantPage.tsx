import React from 'react';
import { Network, BookOpen } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';
import { SimulatedAIChat } from '../shared/SimulatedAIChat';

export const ArkAssistantPage = () => (
    <SlideLayout >
        <div className="grid md:grid-cols-2 gap-12 mt-4 items-center">
            <div className="anim-scale-in delay-200">
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
            <div className="space-y-6">
                <div className="mb-8">
                    <h2 className="text-3xl md:text-4xl font-bold text-slate-800 leading-tight">
                        Ark 助手：<br />
                        <span className="text-indigo-600">身边的监管专家</span>
                    </h2>
                </div>
                <div className="p-6 bg-white rounded-3xl shadow-sm border border-slate-100 anim-fade-up delay-700">
                    <h5 className="font-bold mb-2">降本增效：/ark 对话即检索</h5>
                    <p className="text-xs text-slate-500">大幅减少人工检索文档和排障的时间，提升 40% 以上响应速度。</p>
                </div>
                <div className="p-6 bg-white rounded-3xl shadow-sm border border-slate-100 anim-fade-up delay-900">
                    <h5 className="font-bold mb-2">知识沉淀：不再依赖“老师傅”</h5>
                    <p className="text-xs text-slate-500">组织经验通过 RAG 持续积累，知识不因人员流失而中断。</p>
                </div>
            </div>
        </div>
    </SlideLayout>
);
