import React from 'react';
import { Sparkles } from 'lucide-react';
import { SlideLayout } from '../layout/SlideLayout';

export const ArchitecturePage = () => (
    <SlideLayout title="URGS+ 技术架构体系">
        <div className="space-y-4 max-w-5xl mx-auto relative group">
            {/* Scanning Line Effect */}
            <div className="absolute top-0 left-0 w-full h-[2px] bg-gradient-to-r from-transparent via-cyan-400 to-transparent z-20 opacity-0 group-hover:opacity-100 animate-[moveVertical_3s_ease-in-out_infinite] pointer-events-none shadow-[0_0_15px_rgba(34,211,238,0.8)]"></div>

            {[
                { layer: "前端展现", tech: "React 19 + Ant Design 6.0", desc: "ReactFlow (DAG) 可视化编排，Monaco Editor 代码编辑器。", color: "bg-gradient-to-r from-blue-500 to-blue-600" },
                { layer: "核心服务", tech: "Spring Boot 3.2 + MyBatis Plus", desc: "Quartz 任务调度，Flyway 版本管理，EasyExcel 数据处理。", color: "bg-gradient-to-r from-indigo-500 to-indigo-600" },
                { layer: "智能增强", tech: "FastAPI + LangChain + ChromaDB", desc: "RapidOCR 文档解析，Sentence-Transformers 向量化，Ragas 评估。", color: "bg-gradient-to-r from-amber-500 to-orange-500", highlight: true },
                { layer: "存储底座", tech: "Neo4j + MySQL + MinIO", desc: "Neo4j 图谱存储，MySQL 业务数据，MinIO 非结构化存储。", color: "bg-gradient-to-r from-slate-700 to-slate-800" },
            ].map((row, idx) => (
                <div key={idx} className={`flex rounded-xl overflow-hidden border border-slate-200 shadow-sm anim-fade-right hover:shadow-lg transition-all duration-300 relative ${row.highlight ? 'ring-2 ring-amber-400 ring-offset-2 scale-[1.02]' : 'hover:scale-[1.01]'}`} style={{ animationDelay: `${idx * 150}ms` }}>
                    {/* Glass overlay on hover */}
                    <div className="absolute inset-0 bg-white opacity-0 hover:opacity-10 transition-opacity z-10 pointer-events-none"></div>

                    <div className={`${row.color} text-white w-48 flex items-center justify-center font-bold px-4 text-center shrink-0 shadow-inner`}>
                        {row.layer}
                    </div>
                    <div className="flex-1 bg-white p-6 relative">
                        <div className="absolute top-0 left-0 w-1 h-full bg-gradient-to-b from-transparent via-slate-200 to-transparent opacity-50"></div>
                        <div className="text-xl font-bold text-slate-800 mb-1 flex justify-between">
                            {row.tech}
                            {row.highlight && <Sparkles className="w-5 h-5 text-amber-500 animate-pulse" />}
                        </div>
                        <div className="text-slate-500">{row.desc}</div>
                    </div>
                </div>
            ))}
            <style>{`
        @keyframes moveVertical {
            0% { top: 0; opacity: 0; }
            10% { opacity: 1; }
            90% { opacity: 1; }
            100% { top: 100%; opacity: 0; }
        }
      `}</style>
        </div>
    </SlideLayout>
);
