import React, { useState } from 'react';
import { GitBranch, FileCode, Network, Database, BookOpen, Bot, LayoutDashboard, Lightbulb, ClipboardList, Code2, Zap, CheckCircle2, Terminal, X, ChevronRight } from 'lucide-react';

interface AgentEcosystemFlowProps {
    onNavigate?: (index: number) => void;
}

export const AgentEcosystemFlow = ({ onNavigate }: AgentEcosystemFlowProps) => {
    const [activeNode, setActiveNode] = useState<number | null>(null);
    const [selectedNode, setSelectedNode] = useState<number | null>(null);

    const nodes = [
        // 技术驱动闭环
        {
            id: 1, title: "版本管理", icon: <GitBranch className="w-5 h-5" />, x: 100, y: 100, color: "bg-slate-600", desc: "Git 代码提交触发自动化流程",
            detail: {
                features: ["应用系统库管理", "Git 仓库多元配置", "CI/CD 流水线编排", "发布版本台账", "一键回滚发布"],
                goals: ["统一管理全行20+监管系统代码", "实现标准化、自动化的发布流程", "确保生产环境版本安全可追溯"],
                techStack: ["GitLab", "Jenkins", "Docker", "Kubernetes", "Shell"]
            }
        },
        {
            id: 2, title: "SQL解析", icon: <FileCode className="w-5 h-5" />, x: 350, y: 100, color: "bg-indigo-600", desc: "自动提取表级/字段级依赖",
            detail: {
                features: ["智能代码 Diff 分析", "SQL 语法树解析", "代码规范自动审计", "变更风险预评估"],
                goals: ["自动识别业务逻辑变更", "降低人工代码审查遗漏风险", "为血缘构建提供精准输入"],
                techStack: ["ANTLR4", "Python", "AST Parser", "JSQLParser", "正则引擎"]
            }
        },
        {
            id: 3, title: "血缘图谱", icon: <Network className="w-5 h-5" />, x: 600, y: 100, color: "bg-blue-600", desc: "构建全链路数据影响面",
            detail: {
                features: ["字段级血缘溯源", "上下游影响分析", "血缘引擎管理与重启", "图谱可视化展示"],
                goals: ["秒级定位指标数据来源", "精准评估变更对下游报表的影响", "提升数据排障效率"],
                techStack: ["Neo4j", "Cypher", "D3.js", "GraphQL", "Redis"]
            }
        },
        {
            id: 4, title: "资产管理", icon: <Database className="w-5 h-5" />, x: 850, y: 100, color: "bg-cyan-600", desc: "关联监管指标与业务元数据",
            detail: {
                features: ["物理模型同步", "监管与代码资产维护", "报表与字段定义管理", "数据字典统一管理"],
                goals: ["实现监管业务语言与技术语言的映射", "确保元数据与生产环境实时一致", "沉淀核心数据资产"],
                techStack: ["MySQL", "JDBC", "MyBatis", "元数据API", "定时任务"]
            }
        },

        // 知识沉淀
        {
            id: 5, title: "知识库", icon: <BookOpen className="w-5 h-5" />, x: 850, y: 260, color: "bg-teal-600", desc: "RAG 向量化存储规则与发文",
            detail: {
                features: ["文档与文件夹管理", "多维标签体系", "非结构化文档解析", "知识切片与向量化"],
                goals: ["构建监管领域的私有知识大脑", "将离散文档转化为可检索智慧", "支撑智能体精准问答"],
                techStack: ["Milvus", "LangChain", "BGE Embedding", "FastAPI", "Unstructured"]
            }
        },

        // 智能服务
        {
            id: 6, title: "智能体群", icon: <Bot className="w-5 h-5" />, x: 600, y: 260, color: "bg-amber-500", desc: "多场景专业 Agent 实时辅助",
            detail: {
                features: ["Agent 创建与编排", "API 能力挂载管理", "1104/EAST 填报助手", "合规审计机器人"],
                goals: ["将专家经验固化为数字员工", "7x24小时响应业务咨询", "自动化执行重复性合规检查"],
                techStack: ["DeepSeek", "RAG", "Function Calling", "Prompt Engineering", "SSE"]
            }
        },
        {
            id: 7, title: "业务报送", icon: <LayoutDashboard className="w-5 h-5" />, x: 350, y: 260, color: "bg-rose-500", desc: "1104/EAST 数据填报工作台",
            detail: {
                features: ["统一数据填报入口", "批量监控与状态总览", "报表数据校验", "异常数据预警"],
                goals: ["提升报送数据准确性与及时性", "降低业务人员操作门槛", "实现报送全流程可视可控"],
                techStack: ["React", "Ant Design", "ECharts", "WebSocket", "Excel.js"]
            }
        },

        // 业务反馈闭环
        {
            id: 8, title: "业务提需", icon: <Lightbulb className="w-5 h-5" />, x: 350, y: 420, color: "bg-orange-500", desc: "发现口径差异或新规要求",
            detail: {
                features: ["生产问题在线登记", "口径疑问快速提交", "新规需求结构化录入"],
                goals: ["打通业务与技术的沟通壁垒", "快速响应监管新规变化", "实现需求全生命周期管理"],
                techStack: ["表单引擎", "工作流", "消息通知", "钉钉集成"]
            }
        },
        {
            id: 9, title: "需求评审", icon: <ClipboardList className="w-5 h-5" />, x: 100, y: 420, color: "bg-violet-500", desc: "技术方案与可行性分析",
            detail: {
                features: ["需求可行性分析", "技术方案自动生成", "工时预估参考", "变更影响面确认"],
                goals: ["辅助技术团队快速制定方案", "确保需求理解一致性", "规避潜在技术风险"],
                techStack: ["AI 辅助", "血缘分析API", "知识库检索", "模板引擎"]
            }
        },
        {
            id: 10, title: "研发开发", icon: <Code2 className="w-5 h-5" />, x: 100, y: 260, color: "bg-purple-600", desc: "代码实现与测试",
            detail: {
                features: ["研发工作台", "API 开发与调试", "错误日志分析", "流水线运行监控"],
                goals: ["提升开发与测试效率", "保障代码交付质量", "闭环响应业务提出的新需求"],
                techStack: ["Spring Boot", "Vue 3", "PostgreSQL", "Redis", "RabbitMQ"]
            }
        },
    ];

    const connections = [
        // 技术流
        { from: 1, to: 2 }, { from: 2, to: 3 }, { from: 3, to: 4 }, { from: 4, to: 5 },
        // 服务流
        { from: 5, to: 6 }, { from: 6, to: 7 },
        // 反馈流
        { from: 7, to: 8, dashed: true, label: "发现问题" },
        { from: 8, to: 9, dashed: true },
        { from: 9, to: 10, dashed: true },
        { from: 10, to: 1, dashed: true, label: "发布" }
    ];

    const handleNodeClick = (id: number) => {
        setSelectedNode(selectedNode === id ? null : id);
    };

    return (
        <div className="relative w-full h-full bg-gradient-to-br from-slate-50 via-white to-slate-100 rounded-3xl border border-slate-200 p-8 overflow-hidden flex">
            {/* 科技感背景装饰 - 浅色版 */}
            <div className="absolute inset-0 pointer-events-none overflow-hidden">
                {/* 网格背景 */}
                <div className="absolute inset-0 opacity-[0.03]"
                    style={{ backgroundImage: 'linear-gradient(#4f46e5 1px, transparent 1px), linear-gradient(to right, #4f46e5 1px, transparent 1px)', backgroundSize: '40px 40px' }}>
                </div>
                {/* 辉光效果 */}
                <div className="absolute top-[20%] left-[30%] w-[400px] h-[400px] bg-indigo-500/5 rounded-full blur-[100px] animate-pulse"></div>
                <div className="absolute bottom-[20%] right-[30%] w-[300px] h-[300px] bg-cyan-500/5 rounded-full blur-[80px] animate-pulse" style={{ animationDelay: '1s' }}></div>
            </div>

            {/* 浮动顶部标题栏 */}
            <div className="absolute top-6 left-8 right-8 z-30 flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-cyan-500 flex items-center justify-center shadow-lg shadow-indigo-500/20">
                        <Bot className="w-5 h-5 text-white" />
                    </div>
                    <div>
                        <h2 className="text-xl font-black text-slate-900 tracking-tight">URGS+ 智能体生态闭环</h2>
                        <p className="text-xs text-slate-500 font-mono uppercase tracking-wider">AI Agent Ecosystem · Closed-Loop Architecture</p>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <div className="px-3 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 text-[10px] font-mono uppercase flex items-center gap-2">
                        <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
                        System Active
                    </div>
                </div>
            </div>

            {/* 流程图区域 */}
            <div className={`relative transition-all duration-500 ease-in-out ${selectedNode ? 'w-2/3' : 'w-full'} pt-16`}>
                {/* 动态连接线 SVG */}
                <svg className="absolute inset-0 w-full h-full pointer-events-none">
                    <defs>
                        <linearGradient id="lineGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" stopColor="#818cf8" />
                            <stop offset="100%" stopColor="#22d3ee" />
                        </linearGradient>
                        <linearGradient id="feedbackGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                            <stop offset="0%" stopColor="#f97316" />
                            <stop offset="100%" stopColor="#fb923c" />
                        </linearGradient>
                        <filter id="glow-line" x="-50%" y="-50%" width="200%" height="200%">
                            <feGaussianBlur stdDeviation="3" result="coloredBlur" />
                            <feMerge>
                                <feMergeNode in="coloredBlur" />
                                <feMergeNode in="SourceGraphic" />
                            </feMerge>
                        </filter>
                        <filter id="particle-glow">
                            <feGaussianBlur stdDeviation="2" result="blur" />
                            <feMerge>
                                <feMergeNode in="blur" />
                                <feMergeNode in="SourceGraphic" />
                            </feMerge>
                        </filter>
                        <marker id="arrowhead-tech" markerWidth="8" markerHeight="6" refX="24" refY="3" orient="auto">
                            <polygon points="0 0, 8 3, 0 6" fill="#818cf8" />
                        </marker>
                        <marker id="arrowhead-feedback" markerWidth="8" markerHeight="6" refX="24" refY="3" orient="auto">
                            <polygon points="0 0, 8 3, 0 6" fill="#f97316" />
                        </marker>
                    </defs>
                    {connections.map((conn, i) => {
                        const startNode = nodes.find(n => n.id === conn.from)!;
                        const endNode = nodes.find(n => n.id === conn.to)!;
                        const isFeedback = conn.dashed;

                        // 计算起点和终点
                        const x1 = startNode.x + 32;
                        const y1 = startNode.y + 32;
                        const x2 = endNode.x + 32;
                        const y2 = endNode.y + 32;

                        // 计算贝塞尔曲线控制点
                        const dx = x2 - x1;
                        const dy = y2 - y1;
                        const midX = (x1 + x2) / 2;
                        const midY = (y1 + y2) / 2;

                        // 根据连接方向计算控制点偏移
                        let cx, cy;
                        if (Math.abs(dx) > Math.abs(dy)) {
                            // 水平为主的连接 - 控制点垂直偏移
                            cx = midX;
                            cy = midY - Math.abs(dx) * 0.15;
                        } else {
                            // 垂直为主的连接 - 控制点水平偏移
                            cx = midX + Math.abs(dy) * 0.2;
                            cy = midY;
                        }

                        // 构建贝塞尔曲线路径
                        const pathD = `M ${x1},${y1} Q ${cx},${cy} ${x2},${y2}`;

                        return (
                            <g key={i}>
                                <path
                                    d={pathD}
                                    fill="none"
                                    stroke={isFeedback ? "url(#feedbackGradient)" : "url(#lineGradient)"}
                                    strokeWidth="2"
                                    strokeDasharray={isFeedback ? "6,4" : ""}
                                    strokeOpacity="0.7"
                                    markerEnd={isFeedback ? "url(#arrowhead-feedback)" : "url(#arrowhead-tech)"}
                                    filter="url(#glow-line)"
                                />
                                {conn.label && (
                                    <text
                                        x={cx}
                                        y={cy + 15}
                                        fill="#64748b"
                                        fontSize="10"
                                        textAnchor="middle"
                                        fontFamily="monospace"
                                        className="uppercase"
                                    >
                                        {conn.label}
                                    </text>
                                )}
                                {/* 发光粒子 - 沿曲线路径移动 */}
                                <circle r="5" fill={isFeedback ? "#fb923c" : "#818cf8"} filter="url(#particle-glow)">
                                    <animateMotion
                                        dur={isFeedback ? "4s" : "2.5s"}
                                        repeatCount="indefinite"
                                        path={pathD}
                                    />
                                </circle>
                                <circle r="3" fill="#fff">
                                    <animateMotion
                                        dur={isFeedback ? "4s" : "2.5s"}
                                        repeatCount="indefinite"
                                        path={pathD}
                                    />
                                </circle>
                            </g>
                        );
                    })}
                </svg>

                {/* 节点渲染 - 科技风格 */}
                {nodes.map((node, idx) => (
                    <div
                        key={node.id}
                        className={`absolute flex flex-col items-center gap-3 cursor-pointer transition-all duration-300 group ${activeNode === node.id || selectedNode === node.id ? 'scale-110 z-20' : 'z-10'} ${selectedNode && selectedNode !== node.id ? 'opacity-30' : 'opacity-100'}`}
                        style={{ left: node.x, top: node.y, animationDelay: `${idx * 100}ms` }}
                        onMouseEnter={() => setActiveNode(node.id)}
                        onMouseLeave={() => setActiveNode(null)}
                        onClick={() => handleNodeClick(node.id)}
                    >
                        {/* 节点容器 - 六边形发光风格 */}
                        <div className="relative">
                            {/* 外围光环 */}
                            <div className={`absolute -inset-2 rounded-2xl bg-gradient-to-b ${node.color.replace('bg-', 'from-')}/30 to-transparent blur-lg opacity-0 group-hover:opacity-100 transition-opacity duration-500`}></div>

                            {/* 主节点 */}
                            <div
                                className={`relative w-16 h-16 ${node.color} text-white flex items-center justify-center shadow-lg transition-all duration-300 group-hover:shadow-2xl`}
                                style={{ clipPath: 'polygon(10% 0%, 90% 0%, 100% 50%, 90% 100%, 10% 100%, 0% 50%)' }}
                            >
                                {/* 内部光效 */}
                                <div className="absolute inset-0 bg-gradient-to-t from-transparent via-white/10 to-white/20 pointer-events-none"></div>
                                {/* 图标 */}
                                <div className="relative z-10">
                                    {React.cloneElement(node.icon as React.ReactElement, { className: "w-6 h-6" })}
                                </div>
                            </div>

                            {/* 能量指示器 */}
                            <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-8 h-1 rounded-full bg-slate-200 overflow-hidden">
                                <div className={`h-full ${node.color} animate-pulse`} style={{ width: '100%' }}></div>
                            </div>

                            {/* 选中指示器 */}
                            {selectedNode === node.id && (
                                <div className="absolute -inset-3 rounded-2xl border-2 border-cyan-400/50 animate-pulse"></div>
                            )}
                        </div>

                        {/* 标签 */}
                        <span className="text-[10px] font-mono font-bold text-slate-600 bg-white/90 px-3 py-1 rounded-full backdrop-blur-sm border border-slate-200 uppercase tracking-wider group-hover:text-indigo-600 group-hover:border-indigo-300 transition-colors shadow-sm">
                            {node.title}
                        </span>

                        {/* 悬浮简要提示 (未选中时显示) */}
                        {!selectedNode && (
                            <div className={`absolute top-24 w-52 bg-white/95 backdrop-blur-md p-4 rounded-xl shadow-2xl border border-slate-200 text-xs transition-all duration-300 pointer-events-none ${activeNode === node.id ? 'opacity-100 translate-y-0' : 'opacity-0 -translate-y-2'}`}>
                                <div className="flex items-center gap-2 mb-2">
                                    <div className={`w-2 h-2 rounded-full ${node.color} animate-pulse`}></div>
                                    <span className="font-mono font-bold text-slate-800 uppercase tracking-wide">{node.title}</span>
                                </div>
                                <p className="text-slate-600 leading-relaxed">{node.desc}</p>
                                <div className="mt-3 pt-2 border-t border-slate-200 text-indigo-600 font-mono text-[9px]">
                                    CLICK FOR DETAILS →
                                </div>
                            </div>
                        )}
                    </div>
                ))}
            </div>

            {/* Modal 弹窗 */}
            {selectedNode && (() => {
                const detailNode = nodes.find(n => n.id === selectedNode)!;
                const themeColor = detailNode.color.replace('bg-', 'text-').split('-')[1] || 'indigo';

                return (
                    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-8 animate-in fade-in duration-300">
                        {/* 极简霜冻遮罩 */}
                        <div
                            className="absolute inset-0 bg-slate-50/80 backdrop-blur-md transition-opacity"
                            onClick={() => setSelectedNode(null)}
                        />

                        <div className="relative bg-white/90 w-full max-w-5xl max-h-[90vh] overflow-y-auto rounded-[2rem] shadow-2xl flex flex-col md:flex-row overflow-hidden animate-in slide-in-from-bottom-4 duration-500 border border-white/50 ring-1 ring-slate-200/50">

                            {/* Close Button - Floating */}
                            <button
                                onClick={() => setSelectedNode(null)}
                                className="absolute top-6 right-6 z-50 p-2 rounded-full bg-slate-100 hover:bg-slate-200 text-slate-400 hover:text-slate-600 transition-all hover:rotate-90"
                            >
                                <X className="w-5 h-5" />
                            </button>

                            {/* Left Identity Column */}
                            <div className="relative md:w-2/5 p-10 flex flex-col justify-between overflow-hidden bg-gradient-to-br from-slate-50 to-white border-r border-slate-100">
                                <div className="absolute inset-0 opacity-[0.03] pointer-events-none"
                                    style={{ backgroundImage: 'radial-gradient(#64748b 1px, transparent 1px)', backgroundSize: '20px 20px' }}>
                                </div>
                                <div className={`absolute top-0 left-0 w-full h-1 bg-${themeColor}-500 shadow-[0_0_15px_rgba(var(--${themeColor}-500),0.5)]`}></div>

                                <div className="relative z-10">
                                    <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-[10px] font-mono text-slate-500 mb-8 tracking-widest uppercase animate-in slide-in-from-left-4 fade-in duration-700">
                                        ID: {String(detailNode.id).padStart(3, '0')} // SYSTEM_NODE
                                    </div>

                                    <div className="relative mb-8 group animate-in zoom-in-50 duration-700 delay-100 fill-mode-backwards">
                                        <div className={`active-node-icon w-20 h-20 rounded-2xl bg-white border border-slate-200 flex items-center justify-center shadow-lg shadow-slate-200/50 group-hover:scale-105 transition-transform duration-500`}>
                                            {React.cloneElement(detailNode.icon as React.ReactElement, { className: `w-10 h-10 text-${themeColor}-600` })}
                                        </div>
                                        <div className={`absolute -inset-4 rounded-3xl bg-${themeColor}-400/20 blur-xl opacity-0 group-hover:opacity-100 animate-pulse transition-opacity duration-700`}></div>
                                    </div>

                                    <h3 className="text-3xl font-black text-slate-900 tracking-tight mb-4 relative animate-in slide-in-from-bottom-2 fade-in duration-700 delay-200 fill-mode-backwards">
                                        {detailNode.title}
                                        <span className={`absolute -bottom-2 left-0 w-12 h-1 bg-${themeColor}-500 rounded-full`}></span>
                                    </h3>

                                    <p className="text-slate-500 text-sm leading-relaxed font-medium animate-in slide-in-from-bottom-2 fade-in duration-700 delay-300 fill-mode-backwards">
                                        {detailNode.desc}
                                    </p>
                                </div>

                                <div className="relative z-10 mt-12 animate-in fade-in duration-1000 delay-500 fill-mode-backwards">
                                    <div className="text-[10px] font-bold text-slate-300 uppercase tracking-widest mb-2">System Status</div>
                                    <div className="flex items-center gap-2 text-emerald-600 bg-emerald-50/50 px-3 py-2 rounded-lg border border-emerald-100/50 w-fit">
                                        <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
                                        <span className="text-xs font-bold">ONLINE / ACTIVE</span>
                                    </div>

                                    {/* Link for Node 5 (Knowledge Base) */}
                                    {detailNode.id === 5 && onNavigate && (
                                        <button
                                            onClick={() => onNavigate(5)}
                                            className="mt-4 w-full flex items-center justify-center gap-2 bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold py-3 px-4 rounded-xl transition-all shadow-lg hover:shadow-teal-500/30 group/btn"
                                        >
                                            <BookOpen className="w-4 h-4" />
                                            <span>查看技术架构详情</span>
                                            <ChevronRight className="w-3 h-3 group-hover/btn:translate-x-1 transition-transform" />
                                        </button>
                                    )}
                                </div>
                            </div>

                            {/* Right Content Column */}
                            <div className="flex-1 p-10 bg-white relative">
                                <div className={`absolute top-0 right-0 w-[300px] h-[300px] bg-${themeColor}-500/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 pointer-events-none animate-pulse duration-[5000ms]`}></div>

                                <div className="space-y-10 relative z-10">
                                    <div className="anim-fade-up delay-100">
                                        <h4 className="text-xs font-bold text-slate-400 uppercase tracking-[0.2em] mb-6 flex items-center gap-2">
                                            <Zap className="w-4 h-4 text-slate-300" /> Key Capabilities
                                        </h4>
                                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                            {detailNode.detail.features.map((feat, idx) => (
                                                <div
                                                    key={idx}
                                                    className="group relative p-4 rounded-xl bg-slate-50/50 border border-slate-100 hover:border-slate-300 transition-all duration-300 hover:bg-white hover:shadow-lg hover:shadow-slate-200/50 anim-scale-in fill-mode-backwards"
                                                    style={{ animationDelay: `${150 + idx * 100}ms` }}
                                                >
                                                    <div className={`absolute top-0 left-0 w-0.5 h-0 bg-${themeColor}-500 group-hover:h-full transition-all duration-300`}></div>
                                                    <div className="flex items-start gap-3">
                                                        <span className="text-[10px] font-mono text-slate-400 mt-1">0{idx + 1}</span>
                                                        <p className="text-sm font-semibold text-slate-700 group-hover:text-slate-900">{feat}</p>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    <div className="anim-fade-up delay-300">
                                        <h4 className="text-xs font-bold text-slate-400 uppercase tracking-[0.2em] mb-6 flex items-center gap-2">
                                            <CheckCircle2 className="w-4 h-4 text-slate-300" /> Strategic Objectives
                                        </h4>
                                        <div className="flex flex-col gap-3">
                                            {detailNode.detail.goals.map((goal, idx) => (
                                                <div
                                                    key={idx}
                                                    className="flex items-center gap-4 group anim-fade-right fill-mode-backwards"
                                                    style={{ animationDelay: `${400 + idx * 100}ms` }}
                                                >
                                                    <div className={`w-8 h-8 rounded-full bg-${themeColor}-50 text-${themeColor}-600 flex items-center justify-center shrink-0 border border-${themeColor}-100 group-hover:scale-110 transition-transform`}>
                                                        <CheckCircle2 className="w-4 h-4" />
                                                    </div>
                                                    <div className="flex-1 border-b border-slate-100 py-3 group-hover:border-slate-200 transition-colors">
                                                        <span className="text-sm font-medium text-slate-600 group-hover:text-slate-900 transition-colors">{goal}</span>
                                                    </div>
                                                    <ChevronRight className="w-4 h-4 text-slate-300 opacity-0 group-hover:opacity-100 transition-all -translate-x-2 group-hover:translate-x-0" />
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                    {detailNode.detail.techStack && (
                                        <div className="anim-fade-up delay-400">
                                            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
                                                <Terminal className="w-4 h-4 text-slate-300" /> Technology Stack
                                            </h4>
                                            <div className="flex flex-wrap gap-2">
                                                {detailNode.detail.techStack.map((tech, idx) => (
                                                    <span
                                                        key={idx}
                                                        className={`px-3 py-1.5 rounded-lg text-xs font-mono font-bold bg-${themeColor}-50 text-${themeColor}-700 border border-${themeColor}-100 anim-scale-in fill-mode-backwards`}
                                                        style={{ animationDelay: `${600 + idx * 80}ms` }}
                                                    >
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

            <div className={`absolute bottom-4 right-4 flex gap-4 transition-all duration-300 ${selectedNode ? 'translate-y-20 opacity-0' : 'translate-y-0 opacity-100'}`}>
                {[
                    { name: "1104 填报 Agent", color: "bg-rose-100 text-rose-600" },
                    { name: "血缘分析 Agent", color: "bg-blue-100 text-blue-600" },
                    { name: "合规审计 Agent", color: "bg-violet-100 text-violet-600" },
                ].map((agent, i) => (
                    <div key={i} className={`px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-2 ${agent.color} border border-transparent shadow-sm`}>
                        <Bot className="w-3 h-3" />
                        {agent.name}
                    </div>
                ))}
            </div>
            <style>{`
        @keyframes scan {
          0% { transform: translateY(-100%); }
          100% { transform: translateY(100vh); }
        }
      `}</style>
        </div>
    );
};
