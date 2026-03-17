import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Sparkles, Database, Network, ShieldCheck, FileOutput, Code2, Zap, MessageSquare, X, ChevronRight, Bot, Send, BrainCircuit, User, Cpu, Activity, Server, Layers, Terminal } from 'lucide-react';
import ReactMarkdown from 'react-markdown';

interface ArkAssistantPageProps {
    onBack?: () => void;
}

// ----------------------------------------------------------------------------
// Data Definitions
// ----------------------------------------------------------------------------

const agents = [
    {
        id: 'business_reporting',
        title: '业务报送智能体',
        id_code: 'AGENT-01',
        icon: FileOutput,
        color: 'emerald',
        desc: '1104/EAST 填报智能辅助',
        features: ['口径解释', '规则查询', '填报建议'],
        example: {
            user: 'G0102 报表中的"各项贷款"统计口径是什么？包含贴现吗？',
            ai: '根据 **《G01_资产负债项目统计表》** 填报说明：\n\n1. **统计口径**：各项贷款是指填报机构向非金融机构和个人发放的、以摊余成本计量的贷款。\n2. **包含内容**：\n   - 一般贷款\n   - 贸易融资\n   - **票据贴现** (需包含在内)\n   - 各项垫款\n\n**关联校验规则**：\n> [G0102_15] 各项贷款 >= 票据贴现 + 贸易融资\n\n建议您在取数时检查 `L_ACCT_LOAN` 表的 `LOAN_TYPE` 字段，确保贴现业务已纳入统计范围。'
        },
        position: 'top-left'
    },
    {
        id: 'data_dev',
        title: '监管数据研发',
        id_code: 'AGENT-02',
        icon: Code2,
        color: 'blue',
        desc: 'SQL 生成与代码审计',
        features: ['SQL 生成', '公式推导', '代码审计'],
        example: {
            user: '帮我生成一个 SQL：统计各分行 2024 年末的不良贷款余额。',
            ai: '已为您生成的 SQL 代码，基于 `L_ACCT_LOAN` (贷款分户账) 与 `S_ORG_INFO` (机构信息表)：\n\n```sql\nSELECT \n    t2.BRANCH_NAME AS 分行名称,\n    SUM(t1.LOAN_BAL) AS 不良贷款余额\nFROM L_ACCT_LOAN t1\nLEFT JOIN S_ORG_INFO t2 ON t1.ORG_NUM = t2.ORG_NUM\nWHERE \n    t1.DATA_DATE = \'2024-12-31\'\n    AND t1.FIVE_CLASS_CD IN (\'4\', \'5\') -- 4:可疑, 5:损失\nGROUP BY \n    t2.BRANCH_NAME;\n```\n\n**审计提示**：\n- 已过滤 `DATA_DATE` 确保时间准确。\n- 建议确认“次级类(3)”是否也需要纳入不良统计范围（通常不良包含次级、可疑、损失）。'
        },
        position: 'top-right'
    },
    {
        id: 'architecture',
        title: '架构分析智能体',
        id_code: 'AGENT-03',
        icon: Network,
        color: 'violet',
        desc: '血缘查询与影响分析',
        features: ['血缘追溯', '影响分析', '链路依赖'],
        example: {
            user: '如果修改了源表 T_CUST_INFO 的 CUST_TYPE 字段，会影响哪些下游报表？',
            ai: `🔄 **全链路血缘影响分析报告** (Full-Link Lineage Impact Analysis)

---

### **1. 变更摘要 (Change Summary)**
*   **变更对象**: \`T_CUST_INFO.CUST_TYPE\` (核心客户类型)
*   **变更性质**: 基础元数据变更
*   **影响评级**: 🔴 **High (L1)** - 涉及监管合规与核心风控

### **2. 详细影响清单 (Impact Details)**

#### **A. 监管报送域 (Regulatory Reporting)**
1.  **G01_资产负债项目统计表**
    *   **受影指标**: \`[A, 15]\` (各项存款-对公) / \`[B, 07]\` (同业存放)
    *   **规则依赖**: 客户类型决定存款科目归属 (1104 校验规则 G01_R_05)
    *   **计算路径**: \`T_CUST_INFO\` → \`ODS_MASTER_CUST\` → \`DW_F_DEPOSIT\` → \`RPT_G01\`

2.  **EAST 4.0 监管标准化数据**
    *   **受影表**: \`T_KH_XX\` (客户信息表)
    *   **受影字段**: \`KH_LX\` (客户类型代码)
    *   **合规风险**: 变更后代码若不在标准枚举值 (10/20) 范围内，将触发 EAST 检核失败。

#### **B. 风险管理域 (Risk Management)**
1.  **集团客户统一授信视图**
    *   **业务影响**: 此时更改可能导致“集团关联关系”识别失效，造成统一授信额度计算偏差。

### **3. 建议行动 (Action Items)**
*   📢 **同步通知**: 计财部 (监管组), 风险管理部 (模型组)
*   🧪 **回归测试**: 建议执行 \`TEST_SUITE_G01_CORE\` 测试集。
*   📜 **制度遵从**: 该字段属于《全行标准数据元》，变更需经数据治理委员会审批。`
        },
        position: 'bottom-left'
    },
    {
        id: 'data_governance',
        title: '数据治理智能体',
        id_code: 'AGENT-04',
        icon: ShieldCheck,
        color: 'amber',
        desc: '数据质量与合规检查',
        features: ['质量检查', '值域校验', '异常识别'],
        example: {
            user: '查询 EAST《对公信贷分户账》里的“五级分类”字段是来自哪个系统的哪张表？',
            ai: '经全链路血缘溯源分析，该字段 (FIVE_CLASS_CD) 的来源路径如下：\n\n1. **源业务系统**：信贷管理系统 (NGI)\n2. **源头物理表**：`T_LN_CON_INFO` (信贷合同主表)\n3. **源端字段**：`CLS_RESULT` (分类结果代码)\n\n**加工逻辑说明**：\n在数据抽取过程中进行了代码映射：\n> 源值 `N/A` (正常/关注) 映射为 EAST 标准值 `10/20`。\n\n点击 [查看血缘图谱] 可视化查看完整加工链路。'
        },
        position: 'bottom-right'
    }
];

const colorMap: Record<string, { bg: string; border: string; text: string; light: string; hover: string, icon_bg: string, ring: string }> = {
    emerald: { bg: 'bg-white', border: 'border-emerald-100', text: 'text-emerald-600', light: 'bg-emerald-50', hover: 'hover:border-emerald-300 hover:shadow-emerald-500/10', icon_bg: 'bg-emerald-50', ring: 'ring-emerald-500/20' },
    blue: { bg: 'bg-white', border: 'border-blue-100', text: 'text-blue-600', light: 'bg-blue-50', hover: 'hover:border-blue-300 hover:shadow-blue-500/10', icon_bg: 'bg-blue-50', ring: 'ring-blue-500/20' },
    violet: { bg: 'bg-white', border: 'border-violet-100', text: 'text-violet-600', light: 'bg-violet-50', hover: 'hover:border-violet-300 hover:shadow-violet-500/10', icon_bg: 'bg-violet-50', ring: 'ring-violet-500/20' },
    amber: { bg: 'bg-white', border: 'border-amber-100', text: 'text-amber-600', light: 'bg-amber-50', hover: 'hover:border-amber-300 hover:shadow-amber-500/10', icon_bg: 'bg-amber-50', ring: 'ring-amber-500/20' },
};

// ----------------------------------------------------------------------------
// Components
// ----------------------------------------------------------------------------

// Simulated Chat (Optimized for Modal/Overlay)
const SimulatedChat = ({ userQuestion, aiAnswer, agentColor, onComplete }: any) => {
    // ... (Keep existing logic, just styling tweaks if needed)
    // Minimizing repetition for brevity, using same logic as previous version
    const [messages, setMessages] = useState<Array<{ role: 'user' | 'ai', content: string }>>([]);
    const [thinkingStep, setThinkingStep] = useState<string | null>(null);
    const containerRef = useRef<HTMLDivElement>(null);

    // Simple mock runner
    useEffect(() => {
        let isCancelled = false;
        const run = async () => {
            await new Promise(r => setTimeout(r, 500));
            if (isCancelled) return;
            setMessages([{ role: 'user', content: userQuestion }]);

            await new Promise(r => setTimeout(r, 600));
            if (isCancelled) return;
            setThinkingStep('thinking');

            await new Promise(r => setTimeout(r, 1200));
            if (isCancelled) return;
            setThinkingStep(null);

            // Stream simple
            let text = "";
            for (let i = 0; i < aiAnswer.length; i += 2) {
                if (isCancelled) return;
                text += aiAnswer.slice(i, i + 2);
                setMessages([{ role: 'user', content: userQuestion }, { role: 'ai', content: text }]);
                await new Promise(r => setTimeout(r, 10));
            }
        };
        run();
        return () => { isCancelled = true; };
    }, [userQuestion, aiAnswer]);

    useEffect(() => {
        if (containerRef.current) containerRef.current.scrollTop = containerRef.current.scrollHeight;
    }, [messages]);

    const theme = colorMap[agentColor];

    return (
        <div className="flex flex-col h-full bg-slate-50 relative overflow-hidden">
            <div ref={containerRef} className="flex-1 overflow-y-auto p-6 space-y-6">
                {messages.map((msg, i) => (
                    <div key={i} className={`flex gap-3 ${msg.role === 'user' ? 'justify-end' : ''}`}>
                        {msg.role === 'ai' && <div className={`w-8 h-8 rounded-full bg-white border border-slate-200 flex items-center justify-center shrink-0 shadow-sm ${theme.text}`}><Sparkles className="w-4 h-4" /></div>}
                        <div className={`p-4 rounded-2xl max-w-[85%] text-sm leading-relaxed shadow-sm ${msg.role === 'user' ? 'bg-slate-900 text-white rounded-br-none' : 'bg-white border border-slate-200 text-slate-700 rounded-bl-none'}`}>
                            {msg.role === 'ai' ? <ReactMarkdown>{msg.content}</ReactMarkdown> : msg.content}
                        </div>
                    </div>
                ))}
                {thinkingStep && (
                    <div className="flex gap-3 items-center text-xs text-slate-400 ml-12 animate-pulse">
                        <Activity className="w-3 h-3" />
                        <span>思考中...</span>
                    </div>
                )}
            </div>
        </div>
    );
};


// ----------------------------------------------------------------------------
// Main Page: Neural Hub Layout
// ----------------------------------------------------------------------------

export const ArkAssistantPage = ({ onBack }: ArkAssistantPageProps) => {
    const [selectedAgent, setSelectedAgent] = useState<string | null>(null);
    const activeAgent = agents.find(a => a.id === selectedAgent);

    // SVG Connection Lines
    // Coordinates based on a central hub at 50% 50% and nodes spaced out
    // Using percentages to be responsive
    const renderConnections = () => (
        <svg className="absolute inset-0 w-full h-full pointer-events-none z-0">
            <defs>
                <linearGradient id="lineGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#CBD5E1" stopOpacity="0.2" />
                    <stop offset="50%" stopColor="#6366F1" stopOpacity="0.4" />
                    <stop offset="100%" stopColor="#CBD5E1" stopOpacity="0.2" />
                </linearGradient>
            </defs>
            {/* Top Left Line */}
            <path d="M 50% 50% L 25% 25%" stroke="url(#lineGradient)" strokeWidth="1.5" strokeDasharray="4 4" className="animate-pulse" />
            <circle cx="37.5%" cy="37.5%" r="2" fill="#6366F1" className="animate-ping-slow" />

            {/* Top Right Line */}
            <path d="M 50% 50% L 75% 25%" stroke="url(#lineGradient)" strokeWidth="1.5" strokeDasharray="4 4" className="animate-pulse delay-75" />
            <circle cx="62.5%" cy="37.5%" r="2" fill="#6366F1" className="animate-ping-slow delay-300" />

            {/* Bottom Left Line */}
            <path d="M 50% 50% L 25% 75%" stroke="url(#lineGradient)" strokeWidth="1.5" strokeDasharray="4 4" className="animate-pulse delay-150" />
            <circle cx="37.5%" cy="62.5%" r="2" fill="#6366F1" className="animate-ping-slow delay-500" />

            {/* Bottom Right Line */}
            <path d="M 50% 50% L 75% 75%" stroke="url(#lineGradient)" strokeWidth="1.5" strokeDasharray="4 4" className="animate-pulse delay-200" />
            <circle cx="62.5%" cy="62.5%" r="2" fill="#6366F1" className="animate-ping-slow delay-100" />
        </svg>
    );

    const renderHubView = () => (
        <div className="relative w-full h-full flex flex-col justify-between overflow-hidden bg-[#FAFAFA]">
            {/* Back & Title */}
            <div className="absolute top-6 left-6 z-20 flex items-center gap-4">
                {onBack && (
                    <button onClick={onBack} className="p-2.5 bg-white border border-slate-200 rounded-xl hover:shadow-md transition-all text-slate-500 hover:text-slate-800">
                        <ArrowLeft className="w-5 h-5" />
                    </button>
                )}
                <div>
                    <h1 className="text-xl font-bold text-slate-800 tracking-tight">Ark 智能体集群</h1>
                    <p className="text-xs text-slate-500 font-mono">已连接 • v3.8.2</p>
                </div>
            </div>

            {/* Main Interactive Area */}
            <div className="relative flex-1 w-full h-full flex items-center justify-center">

                {renderConnections()}

                {/* Central Hub (The "Brain") */}
                <div className="relative z-10 w-48 h-48 flex items-center justify-center group cursor-default">
                    {/* Pulsing Rings */}
                    <div className="absolute inset-0 rounded-full bg-indigo-50 animate-ping opacity-20 duration-3000"></div>
                    <div className="absolute inset-4 rounded-full bg-white shadow-xl ring-1 ring-slate-100 flex flex-col items-center justify-center text-center p-4 z-10 transition-transform duration-500 group-hover:scale-105">
                        <div className="w-12 h-12 bg-indigo-100 text-indigo-600 rounded-xl flex items-center justify-center mb-2 shadow-inner">
                            <BrainCircuit className="w-6 h-6" />
                        </div>
                        <h2 className="font-bold text-slate-800 text-sm">Qwen3 核心</h2>
                        <span className="text-[10px] text-slate-400 font-mono mt-1 px-2 py-0.5 bg-slate-50 rounded-full">空闲 / 就绪</span>
                    </div>
                </div>

                {/* Satellite Agents */}
                {agents.map((agent, idx) => {
                    const colors = colorMap[agent.color];
                    // Positioning classes based on quadrant
                    const posClasses = {
                        'top-left': 'top-[15%] left-[15%] md:top-[20%] md:left-[20%]',
                        'top-right': 'top-[15%] right-[15%] md:top-[20%] md:right-[20%]',
                        'bottom-left': 'bottom-[15%] left-[15%] md:bottom-[20%] md:left-[20%]',
                        'bottom-right': 'bottom-[15%] right-[15%] md:bottom-[20%] md:right-[20%]',
                    };
                    const pos = posClasses[agent.position as keyof typeof posClasses] || '';

                    return (
                        <div
                            key={agent.id}
                            className={`absolute ${pos} z-20 w-72 transition-all duration-500 hover:z-30`}
                        >
                            <button
                                onClick={() => setSelectedAgent(agent.id)}
                                className={`w-full text-left bg-white/90 backdrop-blur-md rounded-2xl p-5 shadow-lg border-2 border-transparent ${colors.hover} hover:-translate-y-2 transition-all group`}
                            >
                                <div className="flex items-center gap-4 mb-3">
                                    <div className={`w-10 h-10 rounded-xl ${colors.icon_bg} ${colors.text} flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform`}>
                                        <agent.icon className="w-5 h-5" />
                                    </div>
                                    <div className="flex-1">
                                        <h3 className="font-bold text-slate-800 text-sm group-hover:text-indigo-600 transition-colors">{agent.title}</h3>
                                        <p className="text-[10px] text-slate-400 font-mono">{agent.id_code}</p>
                                    </div>
                                </div>
                                <p className="text-xs text-slate-500 leading-relaxed mb-3 line-clamp-2">{agent.desc}</p>
                                <div className="flex items-center justify-between border-t border-slate-50 pt-3">
                                    <div className="flex gap-1.5">
                                        {agent.features.slice(0, 2).map((f, i) => (
                                            <span key={i} className="text-[9px] px-1.5 py-0.5 bg-slate-50 text-slate-500 rounded border border-slate-100">{f}</span>
                                        ))}
                                    </div>
                                    <ChevronRight className={`w-4 h-4 text-slate-300 group-hover:translate-x-1 transition-transform`} />
                                </div>
                            </button>
                        </div>
                    );
                })}

            </div>

            {/* Bottom Status Bar */}
            <div className="h-16 bg-white border-t border-slate-100 flex items-center px-8 justify-between relative z-20 shadow-sm">
                <div className="flex items-center gap-6">
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                        <Server className="w-4 h-4 text-slate-400" />
                        <span className="font-mono">RAG: 已启用 (ChromaDB)</span>
                    </div>
                    <div className="w-px h-4 bg-slate-200"></div>
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                        <Zap className="w-4 h-4 text-slate-400" />
                        <span className="font-mono">网络延迟: 48ms</span>
                    </div>
                </div>
                <div className="flex gap-2">
                    {[1, 2, 3].map(i => (
                        <div key={i} className="w-1.5 h-1.5 rounded-full bg-slate-200 animate-pulse" style={{ animationDelay: `${i * 0.2}s` }}></div>
                    ))}
                </div>
            </div>
        </div>
    );

    const renderChatModal = () => {
        if (!activeAgent) return null;
        const colors = colorMap[activeAgent.color];

        return (
            <div className="absolute inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/10 backdrop-blur-sm animate-in fade-in duration-300">
                <div className="w-full max-w-4xl h-[85%] bg-white rounded-3xl shadow-2xl overflow-hidden flex flex-col ring-1 ring-slate-200 animate-in slide-in-from-bottom-10 duration-500">
                    {/* Modal Header */}
                    <div className="h-16 border-b border-slate-100 flex items-center justify-between px-6 bg-slate-50/50">
                        <div className="flex items-center gap-3">
                            <div className={`w-8 h-8 rounded-lg ${colors.icon_bg} ${colors.text} flex items-center justify-center`}>
                                <activeAgent.icon className="w-4 h-4" />
                            </div>
                            <div>
                                <h3 className="font-bold text-slate-800">{activeAgent.title}</h3>
                                <p className="text-[10px] text-slate-500 font-mono">会话 ID: {Math.random().toString(36).substr(2, 9).toUpperCase()}</p>
                            </div>
                        </div>
                        <button onClick={() => setSelectedAgent(null)} className="p-2 hover:bg-slate-200 rounded-full transition-colors">
                            <X className="w-5 h-5 text-slate-400" />
                        </button>
                    </div>

                    {/* Chat Area */}
                    <div className="flex-1 min-h-0 bg-white">
                        <SimulatedChat
                            userQuestion={activeAgent.example.user}
                            aiAnswer={activeAgent.example.ai}
                            agentColor={activeAgent.color}
                        />
                    </div>

                    {/* Input Area */}
                    <div className="p-4 bg-white border-t border-slate-100">
                        <div className="bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 flex items-center gap-3 text-slate-400 text-sm">
                            <Terminal className="w-4 h-4" />
                            <span>对话演示模式...</span>
                        </div>
                    </div>
                </div>
            </div>
        );
    };

    return (
        <div className="w-full h-full relative font-sans overflow-hidden">
            {selectedAgent && renderChatModal()}
            {renderHubView()}
        </div>
    );
};
