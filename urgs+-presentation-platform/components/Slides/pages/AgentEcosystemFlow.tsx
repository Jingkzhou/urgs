import React, { useState, useRef, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { GitBranch, FileCode, Network, Database, BookOpen, Bot, LayoutDashboard, Lightbulb, ClipboardList, Code2, Zap, CheckCircle2, Terminal, X, ChevronRight, Activity, Cpu, Sparkles, ArrowLeft } from 'lucide-react';
import { ActiveLineageGraph } from '../shared/ActiveLineageGraph';
import { RAGArchitecturePage } from './RAGArchitecturePage';
import { LineagePage } from './LineagePage';
import { ArkAssistantPage } from './ArkAssistantPage';

interface AgentEcosystemFlowProps {
    onNavigate?: (index: number) => void;
}

interface NodePosition {
    x: number;
    y: number;
}

export const AgentEcosystemFlow = ({ onNavigate }: AgentEcosystemFlowProps) => {
    const [activeNode, setActiveNode] = useState<number | null>(null);
    const [selectedNode, setSelectedNode] = useState<number | null>(null);

    // Drag state
    const [nodePositions, setNodePositions] = useState<Record<number, NodePosition>>({});
    const [draggingNode, setDraggingNode] = useState<number | null>(null);
    const dragOffset = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
    const containerRef = useRef<HTMLDivElement>(null);

    // Tooltip state
    const [hoveredConnection, setHoveredConnection] = useState<number | null>(null);
    const [tooltipPos, setTooltipPos] = useState<{ x: number; y: number }>({ x: 0, y: 0 });

    // Lineage Modal state
    const [showLineageModal, setShowLineageModal] = useState(false);

    // RAG Modal state
    const [showRAGModal, setShowRAGModal] = useState(false);

    // Ark Assistant Modal state
    const [showArkModal, setShowArkModal] = useState(false);

    // 专业配色方案：
    // Governance（治理层）- 蓝色 (blue): 版本管理、解析与血缘、资产管理、研发开发、监管批量调度
    // Knowledge（知识层）- 紫色 (violet): 知识库、智能体群、生产问题登记
    // Business（业务层）- 翠绿 (emerald): 业务报送、业务提需、需求评审

    const nodes = [
        // Governance Layer (Blue) - 技术驱动闭环
        {
            id: 1, title: "版本管理", icon: <GitBranch className="w-5 h-5" />, x: 140, y: 180, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-blue-400 border-blue-500 bg-blue-950/50", desc: "Git 代码提交触发自动化流程",
            detail: {
                features: ["应用系统库管理", "Git 仓库多元配置", "CI/CD 流水线编排", "发布版本台账", "一键回滚发布"],
                goals: ["统一管理全行20+监管系统代码", "实现标准化、自动化的发布流程", "确保生产环境版本安全可追溯"],
                techStack: ["GitLab", "Jenkins", "Docker", "Kubernetes", "Shell"]
            }
        },
        {
            id: 2, title: "解析与血缘", icon: <Network className="w-5 h-5" />, x: 500, y: 180, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-blue-400 border-blue-500 bg-blue-950/50", desc: "SQL解析与全链路血缘构建",
            detail: {
                features: ["智能代码 Diff 分析", "SQL 语法树解析", "字段级血缘溯源", "上下游影响分析"],
                goals: ["自动识别业务逻辑变更", "构建精准数据血缘图谱", "支持秒级数据排障"],
                techStack: ["ANTLR4", "Python", "Neo4j", "Cypher", "D3.js"]
            }
        },
        {
            id: 4, title: "资产管理", icon: <Database className="w-5 h-5" />, x: 860, y: 180, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-blue-400 border-blue-500 bg-blue-950/50", desc: "关联监管指标与业务元数据",
            detail: {
                features: ["物理模型同步", "监管与代码资产维护", "报表与字段定义管理", "数据字典统一管理"],
                goals: ["实现监管业务语言与技术语言的映射", "确保元数据与生产环境实时一致", "沉淀核心数据资产"],
                techStack: ["MySQL", "JDBC", "MyBatis", "元数据API", "定时任务"]
            }
        },

        // Knowledge Layer (Violet) - 知识沉淀
        {
            id: 5, title: "知识库", icon: <BookOpen className="w-5 h-5" />, x: 860, y: 380, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-violet-400 border-violet-500 bg-violet-950/50", desc: "RAG 向量化存储规则与发文",
            detail: {
                features: ["文档与文件夹管理", "多维标签体系", "非结构化文档解析", "知识切片与向量化"],
                goals: ["构建监管领域的私有知识大脑", "将离散文档转化为可检索智慧", "支撑智能体精准问答"],
                techStack: ["Milvus", "LangChain", "BGE Embedding", "FastAPI", "Unstructured"]
            }
        },

        // Knowledge Layer (Violet) - 智能服务
        {
            id: 6, title: "智能体群", icon: <Bot className="w-5 h-5" />, x: 860, y: 580, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-violet-400 border-violet-500 bg-violet-950/50", desc: "多场景专业 Agent 实时辅助",
            detail: {
                features: ["Agent 创建与编排", "API 能力挂载管理", "1104/EAST 填报助手", "合规审计机器人"],
                goals: ["将专家经验固化为数字员工", "7x24小时响应业务咨询", "自动化执行重复性合规检查"],
                techStack: ["DeepSeek", "RAG", "Function Calling", "Prompt Engineering", "SSE"]
            }
        },

        // Business Layer (Emerald) - 业务操作
        {
            id: 7, title: "业务报送", icon: <LayoutDashboard className="w-5 h-5" />, x: 620, y: 580, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-emerald-400 border-emerald-500 bg-emerald-950/50", desc: "1104/EAST 数据填报工作台",
            detail: {
                features: ["统一数据填报入口", "批量监控与状态总览", "报表数据校验", "异常数据预警"],
                goals: ["提升报送数据准确性与及时性", "降低业务人员操作门槛", "实现报送全流程可视可控"],
                techStack: ["React", "Ant Design", "ECharts", "WebSocket", "Excel.js"]
            }
        },

        // Business Layer (Emerald) - 业务反馈闭环
        {
            id: 8, title: "业务提需", icon: <Lightbulb className="w-5 h-5" />, x: 380, y: 580, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-emerald-400 border-emerald-500 bg-emerald-950/50", desc: "发现口径差异或新规要求",
            detail: {
                features: ["生产问题在线登记", "口径疑问快速提交", "新规需求结构化录入"],
                goals: ["打通业务与技术的沟通壁垒", "快速响应监管新规变化", "实现需求全生命周期管理"],
                techStack: ["表单引擎", "工作流", "消息通知", "钉钉集成"]
            }
        },
        {
            id: 9, title: "需求评审", icon: <ClipboardList className="w-5 h-5" />, x: 140, y: 580, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-emerald-400 border-emerald-500 bg-emerald-950/50", desc: "技术方案与可行性分析",
            detail: {
                features: ["需求可行性分析", "技术方案自动生成", "工时预估参考", "变更影响面确认"],
                goals: ["辅助技术团队快速制定方案", "确保需求理解一致性", "规避潜在技术风险"],
                techStack: ["AI 辅助", "血缘分析API", "知识库检索", "模板引擎"]
            }
        },

        // Governance Layer (Blue) - 研发
        {
            id: 10, title: "研发开发", icon: <Code2 className="w-5 h-5" />, x: 140, y: 380, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-blue-400 border-blue-500 bg-blue-950/50", desc: "代码实现与测试",
            detail: {
                features: ["研发工作台", "API 开发与调试", "错误日志分析", "流水线运行监控"],
                goals: ["提升开发与测试效率", "保障代码交付质量", "闭环响应业务提出的新需求"],
                techStack: ["Spring Boot", "Vue 3", "PostgreSQL", "Redis", "RabbitMQ"]
            }
        },

        // Knowledge Layer (Violet) - 问题沉淀
        {
            id: 11, title: "生产问题登记", icon: <ClipboardList className="w-5 h-5" />, x: 1100, y: 380, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-violet-400 border-violet-500 bg-violet-950/50", desc: "生产问题与FAQ沉淀",
            detail: {
                features: ["生产问题工单登记", "解决方案结构化录入", "自动转化为知识库条目"],
                goals: ["实现运维经验的资产化", "丰富知识库实战案例", "降低重复问题排查成本"],
                techStack: ["React", "Ant Design", "Flowable", "Elasticsearch"]
            }
        },

        // Governance Layer (Blue) - 批量调度
        {
            id: 12, title: "监管批量调度", icon: <Activity className="w-5 h-5" />, x: 1100, y: 180, color: "text-slate-400 border-slate-600 bg-slate-900/80", activeColor: "text-blue-400 border-blue-500 bg-blue-950/50", desc: "自动化跑批与监控",
            detail: {
                features: ["批量任务编排", "依赖关系管理", "执行状态监控", "异常自动告警"],
                goals: ["确保监管数据按时产出", "自动化处理任务依赖", "实时监控批量作业状态"],
                techStack: ["XXL-JOB", "Python", "Shell", "Prometheus"]
            }
        },
    ];

    // Qwen3 中心节点 (AI Core)
    const qwen3Node = {
        id: 100,
        title: "Qwen3",
        icon: <Sparkles className="w-6 h-6" />,
        x: 500,
        y: 380,
        desc: "通义千问大模型 · 智能核心",
        isAICore: true
    };

    // AI 连接 (从 Qwen3 到使用 AI 的模块)
    const aiConnections = [
        { from: 100, to: 2, tooltip: "AI 辅助代码规范审计与风险预评估" },
        { from: 100, to: 5, tooltip: "LLM 驱动知识问答与语义向量检索" },
        { from: 100, to: 6, tooltip: "Agent 核心推理引擎与 Function Calling" },
        { from: 100, to: 9, tooltip: "AI 自动生成技术方案与工时预估" },
        { from: 100, to: 1, tooltip: "代码智能走查，和上线风险扫描" },
    ];

    const connections = [
        // 技术流
        { from: 1, to: 2 }, { from: 2, to: 4, label: "血缘提取" }, { from: 4, to: 5 },
        // 服务流
        { from: 5, to: 6 }, { from: 6, to: 7 },
        { from: 11, to: 5, dashed: true, label: "FAQ 沉淀" },
        { from: 12, to: 11, dashed: true, label: "报错直转" }, // New connection: Batch Error -> Issue
        // 反馈流
        { from: 7, to: 8, dashed: true, label: "问题提单" },
        { from: 8, to: 9, dashed: true },
        { from: 9, to: 10, dashed: true },
        { from: 10, to: 1, dashed: true, label: "自动部署" }
    ];

    // 获取节点位置 (支持拖拽后的位置)
    const getNodePos = useCallback((id: number) => {
        if (id === 100) {
            return nodePositions[100] || { x: qwen3Node.x, y: qwen3Node.y };
        }
        const node = nodes.find(n => n.id === id);
        if (!node) return { x: 0, y: 0 };
        return nodePositions[id] || { x: node.x, y: node.y };
    }, [nodePositions, nodes]);

    // 拖拽处理
    const handleDragStart = useCallback((id: number, e: React.MouseEvent) => {
        if (selectedNode) return; // 模态框打开时不允许拖拽
        e.preventDefault();
        const pos = getNodePos(id);
        dragOffset.current = { x: e.clientX - pos.x, y: e.clientY - pos.y };
        setDraggingNode(id);
    }, [getNodePos, selectedNode]);

    const handleDrag = useCallback((e: React.MouseEvent) => {
        if (draggingNode === null || !containerRef.current) return;
        const rect = containerRef.current.getBoundingClientRect();
        const newX = Math.max(0, Math.min(e.clientX - dragOffset.current.x, rect.width - 80));
        const newY = Math.max(60, Math.min(e.clientY - dragOffset.current.y, rect.height - 100));
        setNodePositions(prev => ({ ...prev, [draggingNode]: { x: newX, y: newY } }));
    }, [draggingNode]);

    const handleDragEnd = useCallback(() => {
        setDraggingNode(null);
    }, []);

    const handleNodeClick = (id: number) => {
        if (draggingNode !== null) return;
        // 节点2（解析与血缘）直接打开血缘可视化模态
        if (id === 2) {
            setShowLineageModal(true);
            return;
        }
        // 节点5（知识库）直接打开RAG架构模态
        if (id === 5) {
            setShowRAGModal(true);
            return;
        }
        // 节点6（智能体群）直接打开Ark助手模态
        if (id === 6) {
            setShowArkModal(true);
            return;
        }
        setSelectedNode(selectedNode === id ? null : id);
    };

    return (
        <div
            ref={containerRef}
            className="relative w-full h-full bg-slate-50 overflow-hidden flex font-sans selection:bg-indigo-500/30"
            onMouseMove={handleDrag}
            onMouseUp={handleDragEnd}
            onMouseLeave={handleDragEnd}
        >
            {/* Clean Future Background */}
            <div className="absolute inset-0 pointer-events-none overflow-hidden">
                {/* Grid */}
                <div className="absolute inset-0 opacity-[0.03]"
                    style={{
                        backgroundImage: `linear-gradient(#4f46e5 1px, transparent 1px),
                                        linear-gradient(to right, #4f46e5 1px, transparent 1px)`,
                        backgroundSize: '40px 40px'
                    }}>
                </div>

                {/* Subtle Light Beams */}
                <div className="absolute inset-0 bg-gradient-to-b from-white via-white/0 to-white/80 h-full w-full"></div>

                {/* Glow Orbs - Muted for Light Mode */}
                <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-indigo-200/40 rounded-full blur-[100px] mix-blend-multiply animate-pulse"></div>
                <div className="absolute bottom-0 left-0 w-[600px] h-[600px] bg-cyan-200/40 rounded-full blur-[100px] mix-blend-multiply animate-pulse" style={{ animationDelay: '2s' }}></div>
            </div>

            {/* Header HUD - Light */}
            {!showRAGModal && !showLineageModal && (
                <div className="absolute top-6 left-8 right-8 z-30 flex items-center justify-between pointer-events-none">
                    <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-2xl bg-white border border-slate-200 flex items-center justify-center shadow-xl shadow-indigo-100 relative overflow-hidden group">
                            <div className="absolute inset-0 bg-indigo-50/50"></div>
                            <Bot className="w-6 h-6 text-indigo-600 relative z-10" />
                        </div>
                        <div>
                            <h2 className="text-2xl font-black text-slate-900 tracking-tight flex items-center gap-2">
                                URGS<span className="text-indigo-600">+</span>
                                <span className="text-xs font-mono font-medium text-slate-500 px-2 py-0.5 border border-slate-200 rounded-full bg-white">v2.4.0</span>
                            </h2>
                            <p className="text-[10px] text-slate-500 font-mono uppercase tracking-[0.2em] font-bold">Autonomous Agent System • Active</p>
                        </div>
                    </div>

                </div>
            )}

            {/* Diagram Area */}
            <div className={`relative w-full h-full transition-all duration-700 ease-[cubic-bezier(0.25,1,0.5,1)] ${selectedNode ? 'scale-90 opacity-40 blur-sm translate-x-[-10%]' : 'scale-100 opacity-100'}`}>
                <svg className="absolute inset-0 w-full h-full overflow-visible" style={{ pointerEvents: 'none' }}>
                    <defs>
                        <linearGradient id="cyberLine" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" stopColor="#818cf8" />
                            <stop offset="50%" stopColor="#22d3ee" />
                            <stop offset="100%" stopColor="#818cf8" />
                        </linearGradient>
                        <linearGradient id="cyberLineDashe" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" stopColor="#fb923c" />
                            <stop offset="50%" stopColor="#f87171" />
                            <stop offset="100%" stopColor="#fb923c" />
                        </linearGradient>
                        <linearGradient id="aiLine" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" stopColor="#a855f7" />
                            <stop offset="50%" stopColor="#ec4899" />
                            <stop offset="100%" stopColor="#a855f7" />
                        </linearGradient>
                        <filter id="soft-glow" x="-50%" y="-50%" width="200%" height="200%">
                            <feGaussianBlur stdDeviation="2" result="coloredBlur" />
                            <feMerge>
                                <feMergeNode in="coloredBlur" />
                                <feMergeNode in="SourceGraphic" />
                            </feMerge>
                        </filter>
                    </defs>
                    {connections.map((conn, i) => {
                        const startPos = getNodePos(conn.from);
                        const endPos = getNodePos(conn.to);
                        const isFeedback = conn.dashed;

                        const x1 = startPos.x + 32;
                        const y1 = startPos.y + 32;
                        const x2 = endPos.x + 32;
                        const y2 = endPos.y + 32;

                        const dx = x2 - x1;
                        const dy = y2 - y1;
                        const midX = (x1 + x2) / 2;
                        const midY = (y1 + y2) / 2;

                        // Calculate center point for label (middle of the line)
                        // For straight lines, path is simply M start L end
                        const pathD = `M ${x1},${y1} L ${x2},${y2}`;

                        // Center point for label
                        const cx = midX;
                        const cy = midY;

                        return (
                            <g key={i}>
                                {/* Base line */}
                                <path
                                    d={pathD}
                                    fill="none"
                                    stroke={isFeedback ? "#fb923c" : "#6366f1"}
                                    strokeWidth="2"
                                    strokeOpacity="0.1"
                                />
                                {/* Active Line */}
                                <path
                                    d={pathD}
                                    fill="none"
                                    stroke={isFeedback ? "url(#cyberLineDashe)" : "url(#cyberLine)"}
                                    strokeWidth="2"
                                    strokeDasharray={isFeedback ? "4,4" : ""}
                                    className="animate-[pulse_3s_ease-in-out_infinite]"
                                />
                                {/* Label background */}
                                {conn.label && (
                                    <rect
                                        x={cx - 22}
                                        y={cy + 5}
                                        width="44"
                                        height="16"
                                        rx="4"
                                        fill="white"
                                        stroke={isFeedback ? "#fed7aa" : "#c7d2fe"}
                                        strokeWidth="1"
                                        className="shadow-sm"
                                    />
                                )}
                                {conn.label && (
                                    <text
                                        x={cx}
                                        y={cy + 16}
                                        fill={isFeedback ? "#f97316" : "#6366f1"}
                                        fontSize="9"
                                        textAnchor="middle"
                                        fontFamily="monospace"
                                        className="uppercase tracking-wider font-bold"
                                    >
                                        {conn.label}
                                    </text>
                                )}
                            </g>
                        );
                    })}

                    {/* AI Connections (Qwen3 -> Modules) */}
                    {aiConnections.map((conn, i) => {
                        const startPos = getNodePos(conn.from);
                        const endPos = getNodePos(conn.to);

                        const x1 = startPos.x + 40;
                        const y1 = startPos.y + 40;
                        const x2 = endPos.x + 32;
                        const y2 = endPos.y + 32;

                        const midX = (x1 + x2) / 2;
                        const midY = (y1 + y2) / 2;
                        const pathD = `M ${x1},${y1} L ${x2},${y2}`;

                        return (
                            <g key={`ai-${i}`}>
                                {/* Base glow */}
                                <path d={pathD} fill="none" stroke="#a855f7" strokeWidth="4" strokeOpacity="0.1" />
                                {/* Main line */}
                                <path d={pathD} fill="none" stroke="url(#aiLine)" strokeWidth="2" strokeDasharray="6,3" className="animate-[pulse_2s_ease-in-out_infinite]" />
                                {/* Hover hitbox */}
                                <path
                                    d={pathD}
                                    fill="none"
                                    stroke="transparent"
                                    strokeWidth="16"
                                    style={{ pointerEvents: 'stroke', cursor: 'pointer' }}
                                    onMouseEnter={(e) => { setHoveredConnection(i); setTooltipPos({ x: e.clientX, y: e.clientY }); }}
                                    onMouseMove={(e) => setTooltipPos({ x: e.clientX, y: e.clientY })}
                                    onMouseLeave={() => setHoveredConnection(null)}
                                />
                            </g>
                        );
                    })}
                </svg>

                {/* Tailwind JIT 需要完整静态类名 - 颜色映射 */}
                {nodes.map((node, idx) => {
                    const isActive = activeNode === node.id;
                    const isSelected = selectedNode === node.id;
                    const pos = getNodePos(node.id);
                    const colorMatch = node.activeColor.match(/text-([a-z]+)-400/);
                    const colorName = colorMatch ? colorMatch[1] : 'blue';

                    // 静态颜色类名映射（Tailwind JIT 必须使用完整类名）
                    const colorStyles: Record<string, { bg: string; shadow: string; text: string; bgLabel: string; shadowLabel: string }> = {
                        blue: {
                            bg: 'bg-blue-500',
                            shadow: 'shadow-xl shadow-blue-500/30',
                            text: 'text-blue-600',
                            bgLabel: 'bg-blue-600',
                            shadowLabel: 'shadow-lg shadow-blue-500/30'
                        },
                        violet: {
                            bg: 'bg-violet-500',
                            shadow: 'shadow-xl shadow-violet-500/30',
                            text: 'text-violet-600',
                            bgLabel: 'bg-violet-600',
                            shadowLabel: 'shadow-lg shadow-violet-500/30'
                        },
                        emerald: {
                            bg: 'bg-emerald-500',
                            shadow: 'shadow-xl shadow-emerald-500/30',
                            text: 'text-emerald-600',
                            bgLabel: 'bg-emerald-600',
                            shadowLabel: 'shadow-lg shadow-emerald-500/30'
                        }
                    };

                    const styles = colorStyles[colorName] || colorStyles.blue;

                    return (
                        <div
                            key={node.id}
                            className={`absolute flex flex-col items-center cursor-grab group z-10 transition-all ${draggingNode === node.id ? 'cursor-grabbing z-50' : ''} ${isSelected ? 'scale-110' : ''}`}
                            style={{ left: pos.x, top: pos.y, transition: draggingNode === node.id ? 'none' : 'all 0.3s' }}
                            onMouseDown={(e) => handleDragStart(node.id, e)}
                            onMouseEnter={() => !draggingNode && setActiveNode(node.id)}
                            onMouseLeave={() => setActiveNode(null)}
                            onClick={() => handleNodeClick(node.id)}
                        >
                            <div className="relative w-16 h-16 flex items-center justify-center">
                                <div className={`absolute inset-0 transition-all duration-300 rounded-2xl rotate-45 group-hover:rotate-0
                                    ${isActive || isSelected
                                        ? `${styles.bg} ${styles.shadow} scale-110`
                                        : 'bg-white shadow-lg shadow-slate-200 border border-slate-100'}`}
                                ></div>
                                <div className="relative z-10">
                                    {React.cloneElement(node.icon as React.ReactElement, {
                                        className: `w-7 h-7 transition-all duration-300 ${isActive || isSelected ? 'text-white' : styles.text}`
                                    })}
                                </div>
                                <div className={`absolute -top-1 -right-1 w-3 h-3 rounded-full border-2 border-white ${isActive || isSelected ? 'bg-emerald-400' : 'bg-slate-300'} transition-colors shadow-sm`}></div>
                            </div>
                            <div className={`mt-5 px-4 py-1.5 rounded-full backdrop-blur-md transition-all duration-300 font-bold text-[11px] shadow-sm tracking-wide
                                ${isActive || isSelected
                                    ? `${styles.bgLabel} text-white ${styles.shadowLabel}`
                                    : 'bg-white/90 text-slate-600 border border-slate-200'}`}
                            >
                                {node.title}
                            </div>
                        </div>
                    );
                })}

                {/* Qwen3 Central AI Node */}
                {(() => {
                    const pos = getNodePos(100);
                    const isActive = activeNode === 100;
                    return (
                        <div
                            className={`absolute flex flex-col items-center cursor-grab group z-20 ${draggingNode === 100 ? 'cursor-grabbing z-50' : ''}`}
                            style={{ left: pos.x, top: pos.y, transition: draggingNode === 100 ? 'none' : 'all 0.3s' }}
                            onMouseDown={(e) => handleDragStart(100, e)}
                            onMouseEnter={() => !draggingNode && setActiveNode(100)}
                            onMouseLeave={() => setActiveNode(null)}
                        >
                            <div className="relative w-20 h-20 flex items-center justify-center">
                                {/* Pulsing rings */}
                                <div className="absolute inset-0 rounded-full bg-gradient-to-br from-violet-500 to-pink-500 opacity-20 animate-ping"></div>
                                <div className="absolute inset-1 rounded-full bg-gradient-to-br from-violet-500 to-pink-500 opacity-30 animate-pulse"></div>
                                {/* Main orb */}
                                <div className={`absolute inset-2 rounded-full bg-gradient-to-br from-violet-600 to-pink-600 shadow-xl shadow-violet-500/50 transition-transform ${isActive ? 'scale-110' : ''}`}></div>
                                <Sparkles className="w-8 h-8 text-white relative z-10" />
                            </div>
                            <div className={`mt-4 px-5 py-2 rounded-full font-black text-xs tracking-wider transition-all
                                ${isActive ? 'bg-gradient-to-r from-violet-600 to-pink-600 text-white shadow-lg shadow-violet-500/40' : 'bg-white text-violet-700 border border-violet-200 shadow-md'}`}>
                                {qwen3Node.title}
                            </div>
                            <div className="text-[9px] text-violet-500/80 font-mono mt-1 uppercase tracking-widest">{qwen3Node.desc}</div>
                        </div>
                    );
                })()}

                {/* AI Connection Tooltip */}
                {hoveredConnection !== null && (
                    <div
                        className="fixed z-[100] pointer-events-none px-4 py-2.5 bg-white/95 backdrop-blur-md border border-violet-200 rounded-xl shadow-xl shadow-violet-500/10 max-w-xs"
                        style={{ left: tooltipPos.x + 15, top: tooltipPos.y - 10 }}
                    >
                        <div className="flex items-center gap-2 text-xs font-bold text-violet-700">
                            <Sparkles className="w-3.5 h-3.5 text-pink-500" />
                            AI 使用场景
                        </div>
                        <p className="text-sm text-slate-600 mt-1">{aiConnections[hoveredConnection].tooltip}</p>
                    </div>
                )}
            </div>

            {/* Frost Glass Modal */}
            {selectedNode && (() => {
                const detailNode = nodes.find(n => n.id === selectedNode)!;
                const activeClasses = detailNode.activeColor.split(' ');
                const themeClass = activeClasses.find(c => c.startsWith('text-'));
                const themeColor = themeClass ? themeClass.split('-')[1] : 'indigo';

                return (
                    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 lg:p-12 animate-in fade-in duration-200">
                        <div className="absolute inset-0 bg-slate-200/40 backdrop-blur-sm transition-opacity" onClick={() => setSelectedNode(null)}></div>

                        {/* Modal Window */}
                        <div className="relative w-full max-w-6xl max-h-[85vh] bg-white rounded-3xl shadow-2xl shadow-slate-200/50 overflow-hidden flex flex-col md:flex-row group ring-1 ring-slate-100 animate-in slide-in-from-bottom-5 duration-500">

                            {/* Close Button */}
                            <button
                                onClick={() => setSelectedNode(null)}
                                className="absolute top-6 right-6 z-50 p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-50 rounded-full transition-all"
                            >
                                <X className="w-6 h-6" />
                            </button>

                            {/* Left: Identity Column */}
                            <div className="w-full md:w-1/3 bg-slate-50/80 p-10 flex flex-col relative overflow-hidden border-r border-slate-100">
                                <div className={`absolute top-0 left-0 w-full h-1 bg-${themeColor}-500`}></div>
                                <div className={`absolute -bottom-20 -left-20 w-64 h-64 bg-${themeColor}-100/50 rounded-full blur-[60px]`}></div>

                                <div className="z-10">
                                    <div className="font-mono text-[10px] font-bold text-slate-400 mb-8 flex items-center gap-2 uppercase tracking-widest">
                                        <Activity className="w-3 h-3 text-slate-300" />
                                        System Node • {String(detailNode.id).padStart(3, '0')}
                                    </div>

                                    <div className="mb-8 relative">
                                        <div className={`w-20 h-20 flex items-center justify-center rounded-2xl bg-white shadow-xl shadow-slate-200/60 relative overflow-hidden group-hover:scale-105 transition-transform duration-500`}>
                                            <div className={`absolute inset-0 bg-${themeColor}-50 opacity-0 group-hover:opacity-100 transition-opacity`}></div>
                                            {React.cloneElement(detailNode.icon as React.ReactElement, { className: `w-10 h-10 text-${themeColor}-600 relative z-10` })}
                                        </div>
                                    </div>

                                    <h2 className="text-3xl font-black text-slate-900 mb-3 tracking-tight">{detailNode.title}</h2>
                                    <p className="text-slate-500 text-sm font-medium leading-relaxed mb-8">{detailNode.desc}</p>

                                    <div className="mt-auto space-y-4">
                                        <div className="p-4 bg-white rounded-xl border border-slate-100 shadow-sm flex items-center gap-3">
                                            <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.4)] animate-pulse"></div>
                                            <div className="flex-1">
                                                <div className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Status</div>
                                                <div className="text-xs text-emerald-700 font-bold">OPERATIONAL</div>
                                            </div>
                                        </div>

                                        {/* Link for Node 5 (Knowledge Base) */}
                                        {detailNode.id === 5 && onNavigate && (
                                            <button
                                                onClick={() => onNavigate(5)}
                                                className="w-full group relative overflow-hidden pl-5 pr-4 py-3.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl transition-all shadow-lg hover:shadow-xl hover:-translate-y-0.5"
                                            >
                                                <div className="relative flex items-center justify-between z-10">
                                                    <span className="text-xs font-bold uppercase tracking-wider">Access RAG View</span>
                                                    <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                                                </div>
                                                <div className="absolute inset-0 bg-gradient-to-r from-teal-500 to-indigo-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                                            </button>
                                        )}
                                    </div>
                                </div>
                            </div>

                            {/* Right: Content */}
                            <div className="flex-1 p-10 overflow-y-auto relative bg-white">
                                <div className="absolute top-0 right-0 p-10 opacity-10">
                                    <div className={`text-[120px] font-black tracking-tighter text-${themeColor}-900 leading-none select-none`}>
                                        {String(detailNode.id).padStart(2, '0')}
                                    </div>
                                </div>

                                <div className="relative z-10 space-y-10">
                                    {/* Features */}
                                    <div>
                                        <h4 className="flex items-center gap-2 text-xs font-black text-slate-400 uppercase tracking-[0.2em] mb-5">
                                            <Zap className="w-3 h-3 text-amber-500" /> Core Functions
                                        </h4>
                                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                            {detailNode.detail.features.map((feat, idx) => (
                                                <div key={idx} className="bg-slate-50 border border-slate-100 p-4 rounded-xl hover:border-indigo-100 hover:shadow-md hover:shadow-indigo-500/5 transition-all group">
                                                    <div className="flex items-start gap-3">
                                                        <span className={`text-[10px] font-mono text-slate-400 mt-1 font-bold`}>0{idx + 1}</span>
                                                        <span className="text-sm font-semibold text-slate-700 group-hover:text-slate-900 transition-colors">{feat}</span>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    {/* Goals */}
                                    <div>
                                        <h4 className="flex items-center gap-2 text-xs font-black text-slate-400 uppercase tracking-[0.2em] mb-5">
                                            <CheckCircle2 className="w-3 h-3 text-emerald-500" /> Strategic Objectives
                                        </h4>
                                        <div className="space-y-2">
                                            {detailNode.detail.goals.map((goal, idx) => (
                                                <div key={idx} className="flex items-center gap-4 p-3 rounded-xl hover:bg-slate-50 transition-colors">
                                                    <div className={`w-8 h-8 rounded-full bg-${themeColor}-50 text-${themeColor}-600 flex items-center justify-center shrink-0`}>
                                                        <CheckCircle2 className="w-4 h-4" />
                                                    </div>
                                                    <span className="text-sm font-medium text-slate-600">{goal}</span>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    {/* Tech Stack */}
                                    {detailNode.detail.techStack && (
                                        <div>
                                            <h4 className="flex items-center gap-2 text-xs font-black text-slate-400 uppercase tracking-[0.2em] mb-5">
                                                <Terminal className="w-3 h-3 text-slate-900" /> Tech Stack
                                            </h4>
                                            <div className="flex flex-wrap gap-2">
                                                {detailNode.detail.techStack.map((tech, idx) => (
                                                    <span key={idx} className={`px-2.5 py-1.5 rounded-lg text-xs font-bold border bg-white border-slate-200 text-slate-600 shadow-sm transition-transform hover:-translate-y-0.5`}>
                                                        {tech}
                                                    </span>
                                                ))}
                                            </div>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>
                );
            })()}

            {/* Lineage Fullscreen Modal - Portal to Body for True Fullscreen */}
            {showLineageModal && createPortal(
                <div className="fixed inset-0 z-[9999] bg-slate-50 animate-in fade-in duration-300">
                    <LineagePage onBack={() => setShowLineageModal(false)} />
                </div>,
                document.body
            )}

            {/* RAG Architecture Fullscreen Modal - Portal to Body */}
            {showRAGModal && createPortal(
                <div className="fixed inset-0 z-[9999] bg-[#F5F5F7] animate-in fade-in duration-300 overflow-auto">
                    <RAGArchitecturePage onBack={() => setShowRAGModal(false)} />
                </div>,
                document.body
            )}

            {/* Ark Assistant Fullscreen Modal - Portal to Body */}
            {showArkModal && createPortal(
                <div className="fixed inset-0 z-[9999] bg-[#F5F5F7] animate-in fade-in duration-300 overflow-auto">
                    <ArkAssistantPage onBack={() => setShowArkModal(false)} />
                </div>,
                document.body
            )}
        </div>
    );
};
