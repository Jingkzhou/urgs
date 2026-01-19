import React, { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Sparkles, Database, Network, ShieldCheck, FileOutput, Code2, Zap, MessageSquare, X, ChevronRight, Bot, Send, BrainCircuit, User } from 'lucide-react';
import ReactMarkdown from 'react-markdown';

interface ArkAssistantPageProps {
    onBack?: () => void;
}

// ----------------------------------------------------------------------------
// 1. Simulated Chat Component
// ----------------------------------------------------------------------------
interface SimulatedChatProps {
    userQuestion: string;
    aiAnswer: string;
    agentColor: string;
    onComplete?: () => void;
}

const SimulatedChat = ({ userQuestion, aiAnswer, agentColor, onComplete }: SimulatedChatProps) => {
    const [messages, setMessages] = useState<Array<{ role: 'user' | 'ai', content: string }>>([]);
    const [isTyping, setIsTyping] = useState(false);
    const [thinkingStep, setThinkingStep] = useState<string | null>(null); // 'thinking' | 'analyzing' | 'generating'
    const colorMap = {
        emerald: 'text-emerald-500 bg-emerald-50 border-emerald-100',
        blue: 'text-blue-500 bg-blue-50 border-blue-100',
        violet: 'text-violet-500 bg-violet-50 border-violet-100',
        amber: 'text-amber-500 bg-amber-50 border-amber-100',
    };

    const containerRef = useRef<HTMLDivElement>(null);

    // Auto-scroll to bottom
    useEffect(() => {
        if (containerRef.current) {
            containerRef.current.scrollTop = containerRef.current.scrollHeight;
        }
    }, [messages, thinkingStep]);

    useEffect(() => {
        let isCancelled = false;

        const runSimulation = async () => {
            // 1. Initial Delay
            await new Promise(r => setTimeout(r, 800));
            if (isCancelled) return;

            // 2. User Typing
            setIsTyping(true);
            let currentUserText = "";
            for (let i = 0; i < userQuestion.length; i++) {
                if (isCancelled) return;
                currentUserText += userQuestion[i];
                // Update specific user message placeholder or just simplify strictly for this demo
                // Ideally we show the typing in the input box, then "send" it.
            }
            // For simplicity in this specific "playback" mode, we'll just "send" the message after a delay
            // simulating the user finishing typing.

            // Actually, let's show the user message appearing
            setMessages([{ role: 'user', content: userQuestion }]);
            setIsTyping(false); // input cleared

            // 3. Thinking Phase
            await new Promise(r => setTimeout(r, 600));
            if (isCancelled) return;
            setThinkingStep('thinking'); // "DeepSeek R1 is thinking..."

            await new Promise(r => setTimeout(r, 1500));
            if (isCancelled) return;
            setThinkingStep('analyzing'); // "Retrieving knowledge..."

            await new Promise(r => setTimeout(r, 1200));
            if (isCancelled) return;
            setThinkingStep('generating'); // Ready to stream

            // 4. AI Streaming Response
            await new Promise(r => setTimeout(r, 500));
            setThinkingStep(null); // Stop thinking visualization

            let currentAiText = "";
            const chunkSize = 3; // chars per tick
            for (let i = 0; i < aiAnswer.length; i += chunkSize) {
                if (isCancelled) return;
                currentAiText += aiAnswer.slice(i, i + chunkSize);
                setMessages([
                    { role: 'user', content: userQuestion },
                    { role: 'ai', content: currentAiText }
                ]);
                await new Promise(r => setTimeout(r, 15 + Math.random() * 20)); // Random typing speed
            }

            if (onComplete) onComplete();
        };

        runSimulation();

        return () => { isCancelled = true; };
    }, [userQuestion, aiAnswer]);

    return (
        <div className="flex flex-col h-full bg-white rounded-3xl shadow-sm border border-slate-200 overflow-hidden">
            {/* Chat History Area */}
            <div ref={containerRef} className="flex-1 overflow-y-auto p-6 space-y-6 bg-slate-50/50">
                {/* Empty State / Welcome */}
                {messages.length === 0 && (
                    <div className="h-full flex flex-col items-center justify-center text-slate-400 opacity-60">
                        <Bot className="w-12 h-12 mb-3" />
                        <p className="text-sm">等待提问...</p>
                    </div>
                )}

                {messages.map((msg, idx) => (
                    <div key={idx} className={`flex gap-4 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                        {msg.role === 'ai' && (
                            <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 bg-white border border-slate-100 shadow-sm text-indigo-500`}>
                                <Sparkles className="w-4 h-4" />
                            </div>
                        )}

                        <div className={`max-w-[80%] rounded-2xl p-4 text-sm leading-relaxed shadow-sm ${msg.role === 'user'
                            ? 'bg-[#2990FF] text-white rounded-br-none'
                            : 'bg-white border border-slate-100 text-slate-700 rounded-bl-none'
                            }`}>
                            {msg.role === 'ai' ? (
                                <div className="prose prose-sm prose-slate max-w-none">
                                    <ReactMarkdown>{msg.content}</ReactMarkdown>
                                </div>
                            ) : (
                                msg.content
                            )}
                        </div>

                        {msg.role === 'user' && (
                            <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center shrink-0">
                                <User className="w-4 h-4 text-slate-500" />
                            </div>
                        )}
                    </div>
                ))}

                {/* Thinking Indicator */}
                {thinkingStep && (
                    <div className="flex gap-4">
                        <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 bg-white border border-slate-100 shadow-sm text-indigo-500`}>
                            <Sparkles className="w-4 h-4 animate-spin-slow" />
                        </div>
                        <div className="bg-white border border-slate-100 rounded-2xl rounded-bl-none p-4 shadow-sm flex items-center gap-3">
                            <div className="flex space-x-1">
                                <div className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
                                <div className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
                                <div className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce"></div>
                            </div>
                            <span className="text-xs font-medium text-slate-500 animate-pulse">
                                {thinkingStep === 'thinking' && 'DeepSeekR1 思考中...'}
                                {thinkingStep === 'analyzing' && '检索监管知识库...'}
                                {thinkingStep === 'generating' && '正在生成回答...'}
                            </span>
                        </div>
                    </div>
                )}
            </div>

            {/* Input Area (Mock) */}
            <div className="p-4 bg-white border-t border-slate-100">
                <div className="relative">
                    <input
                        disabled
                        type="text"
                        placeholder={isTyping ? "正在输入..." : "对话演示中..."}
                        className="w-full pl-4 pr-12 py-3 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all"
                    />
                    <button className="absolute right-2 top-2 p-1.5 bg-indigo-500 text-white rounded-lg opacity-50 cursor-not-allowed">
                        <Send className="w-4 h-4" />
                    </button>
                </div>
            </div>
        </div>
    );
};

// ----------------------------------------------------------------------------
// 2. Main Page & Data
// ----------------------------------------------------------------------------

// Agent Definitions
const agents = [
    {
        id: 'business_reporting',
        title: '业务报送智能体',
        icon: FileOutput,
        color: 'emerald',
        desc: '1104/EAST 填报智能辅助',
        features: ['口径解释与推导', '校验规则智能查询', '报表项填报建议', '异常数据预警'],
        example: {
            user: 'G0102 报表中的"各项贷款"统计口径是什么？包含贴现吗？',
            ai: '根据 **《G01_资产负债项目统计表》** 填报说明：\n\n1. **统计口径**：各项贷款是指填报机构向非金融机构和个人发放的、以摊余成本计量的贷款。\n2. **包含内容**：\n   - 一般贷款\n   - 贸易融资\n   - **票据贴现** (需包含在内)\n   - 各项垫款\n\n**关联校验规则**：\n> [G0102_15] 各项贷款 >= 票据贴现 + 贸易融资\n\n建议您在取数时检查 `L_ACCT_LOAN` 表的 `LOAN_TYPE` 字段，确保贴现业务已纳入统计范围。'
        }
    },
    {
        id: 'data_dev',
        title: '监管数据研发智能体',
        icon: Code2,
        color: 'blue',
        desc: 'SQL 生成与代码审计',
        features: ['SQL 自动生成', '指标公式推导', '代码逻辑审计', '性能优化建议'],
        example: {
            user: '帮我生成一个 SQL：统计各分行 2024 年末的不良贷款余额。',
            ai: '已为您生成的 SQL 代码，基于 `L_ACCT_LOAN` (贷款分户账) 与 `S_ORG_INFO` (机构信息表)：\n\n```sql\nSELECT \n    t2.BRANCH_NAME AS 分行名称,\n    SUM(t1.LOAN_BAL) AS 不良贷款余额\nFROM L_ACCT_LOAN t1\nLEFT JOIN S_ORG_INFO t2 ON t1.ORG_NUM = t2.ORG_NUM\nWHERE \n    t1.DATA_DATE = \'2024-12-31\'\n    AND t1.FIVE_CLASS_CD IN (\'4\', \'5\') -- 4:可疑, 5:损失\nGROUP BY \n    t2.BRANCH_NAME;\n```\n\n**审计提示**：\n- 已过滤 `DATA_DATE` 确保时间准确。\n- 建议确认“次级类(3)”是否也需要纳入不良统计范围（通常不良包含次级、可疑、损失）。'
        }
    },
    {
        id: 'architecture',
        title: '架构分析智能体',
        icon: Network,
        color: 'violet',
        desc: '血缘查询与影响分析',
        features: ['字段血缘追溯', '上下游影响分析', '报表依赖链路', '变更影响评估'],
        example: {
            user: '如果修改了源表 T_CUST_INFO 的 CUST_TYPE 字段，会影响哪些下游报表？',
            ai: '正在进行全链路血缘影响分析...\n\n**分析结果**：\n修改 `T_CUST_INFO.CUST_TYPE` 将影响 **3** 张监管报表：\n\n1. **G01 资产负债表**\n   - 影响单元格：`[A, 15]` (对公存款)\n   - 路径：`T_CUST_INFO` -> `MID_DEPOSIT` -> `G01`\n\n2. **EAST 客户信息表**\n   - 影响字段：`KH_LX` (客户类型)\n\n3. **客户风险预警大宽表**\n\n**建议**：该字段处于核心链路，请在变更前同步通知 **风险管理部** 和 **计财部** 进行回归测试。'
        }
    },
    {
        id: 'data_governance',
        title: '数据治理智能体',
        icon: ShieldCheck,
        color: 'amber',
        desc: '数据质量与合规检查',
        features: ['数据质量检查', '值域合规校验', '异常模式识别', '治理规则推荐'],
        example: {
            user: '查询 EAST《对公信贷分户账》里的“五级分类”字段是来自哪个系统的哪张表？',
            ai: '经全链路血缘溯源分析，该字段 (FIVE_CLASS_CD) 的来源路径如下：\n\n1. **源业务系统**：信贷管理系统 (NGI)\n2. **源头物理表**：`T_LN_CON_INFO` (信贷合同主表)\n3. **源端字段**：`CLS_RESULT` (分类结果代码)\n\n**加工逻辑说明**：\n在数据抽取过程中进行了代码映射：\n> 源值 `N/A` (正常/关注) 映射为 EAST 标准值 `10/20`。\n\n点击 [查看血缘图谱] 可视化查看完整加工链路。'
        }
    }
];

const colorMap: Record<string, { bg: string; border: string; text: string; light: string; hover: string }> = {
    emerald: { bg: 'bg-emerald-500', border: 'border-emerald-200', text: 'text-emerald-600', light: 'bg-emerald-50', hover: 'hover:border-emerald-300' },
    blue: { bg: 'bg-blue-500', border: 'border-blue-200', text: 'text-blue-600', light: 'bg-blue-50', hover: 'hover:border-blue-300' },
    violet: { bg: 'bg-violet-500', border: 'border-violet-200', text: 'text-violet-600', light: 'bg-violet-50', hover: 'hover:border-violet-300' },
    amber: { bg: 'bg-amber-500', border: 'border-amber-200', text: 'text-amber-600', light: 'bg-amber-50', hover: 'hover:border-amber-300' },
};

export const ArkAssistantPage = ({ onBack }: ArkAssistantPageProps) => {
    const [selectedAgent, setSelectedAgent] = useState<string | null>(null);
    const activeAgent = agents.find(a => a.id === selectedAgent);

    // Grid View
    const renderGrid = () => (
        <div className="max-w-6xl mx-auto space-y-10 animate-in fade-in duration-500">
            {/* Header */}
            <div className="text-center">
                <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-gradient-to-r from-indigo-50 to-violet-50 border border-indigo-100 rounded-full mb-6">
                    <Bot className="w-4 h-4 text-indigo-500" />
                    <span className="text-xs font-bold text-indigo-600 uppercase tracking-wider">Intelligent Agent Swarm</span>
                </div>
                <h1 className="text-4xl font-black text-slate-900 mb-4">Ark 智能体集群</h1>
                <p className="text-lg text-slate-500 max-w-2xl mx-auto">
                    基于 Qwen3 的智能体，将复杂监管业务转化为即问即答。
                </p>
            </div>

            {/* Tech Architecture Overview */}
            <div className="bg-white rounded-3xl p-8 shadow-sm border border-slate-100">
                <h2 className="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2">
                    <BrainCircuit className="w-5 h-5 text-indigo-500" />
                    核心技术架构
                </h2>
                <div className="grid grid-cols-4 gap-4">
                    <div className="text-center p-4 bg-slate-50 rounded-2xl border border-slate-100">
                        <div className="w-12 h-12 mx-auto mb-3 bg-gradient-to-br from-indigo-500 to-violet-500 rounded-xl flex items-center justify-center text-white">
                            <Sparkles className="w-6 h-6" />
                        </div>
                        <div className="font-bold text-slate-800 text-sm">DeepMind</div>
                        <div className="text-[10px] text-slate-400 mt-1">推理大模型</div>
                    </div>
                    <div className="text-center p-4 bg-slate-50 rounded-2xl border border-slate-100">
                        <div className="w-12 h-12 mx-auto mb-3 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-xl flex items-center justify-center text-white">
                            <Database className="w-6 h-6" />
                        </div>
                        <div className="font-bold text-slate-800 text-sm">RAG 检索</div>
                        <div className="text-[10px] text-slate-400 mt-1">向量+BM25 混合</div>
                    </div>
                    <div className="text-center p-4 bg-slate-50 rounded-2xl border border-slate-100">
                        <div className="w-12 h-12 mx-auto mb-3 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-xl flex items-center justify-center text-white">
                            <Zap className="w-6 h-6" />
                        </div>
                        <div className="font-bold text-slate-800 text-sm">Function Calling</div>
                        <div className="text-[10px] text-slate-400 mt-1">API 能力扩展</div>
                    </div>
                    <div className="text-center p-4 bg-slate-50 rounded-2xl border border-slate-100">
                        <div className="w-12 h-12 mx-auto mb-3 bg-gradient-to-br from-amber-500 to-orange-500 rounded-xl flex items-center justify-center text-white">
                            <MessageSquare className="w-6 h-6" />
                        </div>
                        <div className="font-bold text-slate-800 text-sm">SSE 流式</div>
                        <div className="text-[10px] text-slate-400 mt-1">实时响应交互</div>
                    </div>
                </div>
            </div>

            {/* Agent Cards Grid */}
            <div>
                <h2 className="text-lg font-bold text-slate-800 mb-6">专业智能体</h2>
                <div className="grid grid-cols-2 gap-6">
                    {agents.map((agent) => {
                        const colors = colorMap[agent.color];
                        const IconComponent = agent.icon;
                        return (
                            <button
                                key={agent.id}
                                onClick={() => setSelectedAgent(agent.id)}
                                className={`group text-left p-6 bg-white rounded-2xl border border-slate-100 transition-all duration-300 hover:shadow-xl hover:-translate-y-1 ${colors.hover}`}
                            >
                                <div className="flex items-start gap-4">
                                    <div className={`w-12 h-12 rounded-xl ${colors.light} ${colors.text} flex items-center justify-center shrink-0`}>
                                        <IconComponent className="w-6 h-6" />
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center justify-between mb-1">
                                            <h3 className="font-bold text-slate-900">{agent.title}</h3>
                                            <ChevronRight className="w-4 h-4 text-slate-300 group-hover:text-slate-500 group-hover:translate-x-0.5 transition-all" />
                                        </div>
                                        <p className="text-sm text-slate-500 mb-3">{agent.desc}</p>
                                        <div className="flex flex-wrap gap-1.5">
                                            {agent.features.slice(0, 3).map((f, i) => (
                                                <span key={i} className="px-2 py-0.5 bg-slate-50 text-slate-500 rounded text-[10px] font-medium">
                                                    {f}
                                                </span>
                                            ))}
                                        </div>
                                    </div>
                                </div>
                            </button>
                        );
                    })}
                </div>
            </div>
        </div>
    );

    // Chat View
    const renderChat = () => {
        if (!activeAgent) return null;
        const colors = colorMap[activeAgent.color];

        return (
            <div className="h-full flex flex-col animate-in slide-in-from-right duration-300">
                {/* Chat Header */}
                <div className="flex items-center gap-4 mb-6 shrink-0">
                    <button
                        onClick={() => setSelectedAgent(null)}
                        className="p-2 hover:bg-slate-100 rounded-full transition-colors text-slate-500"
                    >
                        <ArrowLeft className="w-5 h-5" />
                    </button>
                    <div className={`w-10 h-10 rounded-xl ${colors.light} ${colors.text} flex items-center justify-center`}>
                        <activeAgent.icon className="w-5 h-5" />
                    </div>
                    <div>
                        <h2 className="text-lg font-bold text-slate-900">{activeAgent.title}</h2>
                        <div className="flex items-center gap-2 text-xs text-slate-500">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                            Online | DeepSeek V3
                        </div>
                    </div>
                </div>

                {/* Chat Simulation Container */}
                <div className="flex-1 min-h-0">
                    <SimulatedChat
                        userQuestion={activeAgent.example.user}
                        aiAnswer={activeAgent.example.ai}
                        agentColor={activeAgent.color}
                    />
                </div>
            </div>
        );
    };

    return (
        <div className="w-full h-full bg-[#F5F5F7] text-slate-900 font-sans relative flex flex-col overflow-hidden">
            {/* Global Back Button (Only on Grid View) */}
            {!selectedAgent && onBack && (
                <button
                    onClick={onBack}
                    className="absolute top-6 left-6 z-50 p-2.5 bg-white/90 hover:bg-white backdrop-blur-md border border-slate-200/60 rounded-xl shadow-lg hover:shadow-xl transition-all text-slate-600 hover:text-slate-900 group"
                    title="返回生态全景"
                >
                    <ArrowLeft className="w-5 h-5 group-hover:-translate-x-0.5 transition-transform" />
                </button>
            )}

            <div className="flex-1 overflow-hidden p-8 pt-16">
                {selectedAgent ? renderChat() : renderGrid()}
            </div>
        </div>
    );
};
