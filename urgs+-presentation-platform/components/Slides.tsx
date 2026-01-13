
import React, { useState, useEffect } from 'react';
import {
  ShieldAlert,
  Workflow,
  Database,
  Bot,
  LineChart,
  Search,
  Zap,
  UserCircle2,
  Code2,
  Cpu,
  Boxes,
  LayoutDashboard,
  CloudUpload,
  Network,
  Users,
  ShieldCheck,
  ChevronRight,
  PieChart,
  ArrowRight,
  CheckCircle2,
  AlertCircle,
  X,
  FileSearch,
  Calendar,
  Terminal,
  Activity,
  BookOpen,
  Sparkles
} from 'lucide-react';

// --- Interactive Sub-Components ---

const AIJourneyOverlay = ({ onClose }: { onClose: () => void }) => {
  return (
    <div className="fixed inset-0 z-[100] bg-slate-950 flex flex-col items-center justify-center overflow-hidden animate-in fade-in duration-500">
      <div className="absolute inset-0 opacity-20 pointer-events-none">
        <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
              <path d="M 40 0 L 0 0 0 40" fill="none" stroke="white" strokeWidth="0.5" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#grid)" />
        </svg>
      </div>

      <div className="absolute inset-0 flex items-center justify-center">
        <div className="relative w-full h-full max-w-4xl max-h-4xl opacity-30">
          {[...Array(12)].map((_, i) => (
            <div
              key={i}
              className="absolute bg-indigo-500 rounded-full blur-xl animate-pulse"
              style={{
                width: Math.random() * 200 + 100 + 'px',
                height: Math.random() * 200 + 100 + 'px',
                left: Math.random() * 80 + 10 + '%',
                top: Math.random() * 80 + 10 + '%',
                animationDuration: Math.random() * 3 + 2 + 's',
                animationDelay: i * 0.5 + 's'
              }}
            />
          ))}
        </div>
      </div>

      <div className="relative z-10 flex flex-col items-center text-center px-6">
        <div className="relative mb-12">
          <div className="w-48 h-48 bg-indigo-600 rounded-full flex items-center justify-center shadow-[0_0_80px_rgba(79,70,229,0.5)] animate-bounce-slow">
            <Bot className="w-24 h-24 text-white" />
          </div>
          <div className="absolute -inset-4 border-2 border-indigo-400 rounded-full border-dashed animate-[spin_10s_linear_infinite]" />
          <div className="absolute -inset-8 border border-indigo-500/30 rounded-full animate-[spin_20s_linear_infinite_reverse]" />
        </div>

        <h3 className="text-5xl md:text-7xl font-black text-white mb-6 tracking-tight">
          URGS<span className="text-indigo-500">+</span> <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-teal-400">方舟引擎已启动</span>
        </h3>

        <p className="text-xl md:text-2xl text-slate-400 max-w-2xl mb-12 font-light leading-relaxed">
          正在初始化智能监管大脑，构建全链路数据血缘图谱，<br />重塑您的企业数字化合规运营范式。
        </p>

        <div className="flex gap-4">
          <div className="flex items-center gap-2 px-6 py-3 bg-white/5 border border-white/10 rounded-full text-slate-300 text-sm font-medium">
            <Zap className="w-4 h-4 text-amber-400" /> RAG 混合检索就绪
          </div>
          <div className="flex items-center gap-2 px-6 py-3 bg-white/5 border border-white/10 rounded-full text-slate-300 text-sm font-medium">
            <ShieldCheck className="w-4 h-4 text-teal-400" /> 合规 Agent 在线
          </div>
        </div>

        <button
          onClick={() => window.open(import.meta.env.VITE_DASHBOARD_URL || 'http://localhost:3000', '_blank')}
          className="mt-16 group flex items-center gap-3 px-8 py-4 bg-white text-indigo-900 rounded-full text-lg font-bold hover:bg-indigo-50 transition-all shadow-xl"
        >
          进入智能驾驶舱 <ArrowRight className="group-hover:translate-x-1 transition-transform" />
        </button>
      </div>

      <button onClick={onClose} className="absolute top-10 right-10 p-3 text-slate-500 hover:text-white transition-colors">
        <X className="w-8 h-8" />
      </button>

      <style>{`
        @keyframes bounce-slow {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-20px); }
        }
        .animate-bounce-slow {
          animation: bounce-slow 4s ease-in-out infinite;
        }
      `}</style>
    </div>
  );
};

const InteractiveBarChart = () => {
  const [data, setData] = useState([
    { label: '交付效率', value: 65, color: 'bg-indigo-500', icon: <Zap className="w-3 h-3" /> },
    { label: '合规覆盖率', value: 85, color: 'bg-teal-500', icon: <ShieldCheck className="w-3 h-3" /> },
    { label: '变更风险降幅', value: 45, color: 'bg-rose-500', icon: <ShieldAlert className="w-3 h-3" /> },
    { label: '知识转化率', value: 40, color: 'bg-amber-500', icon: <BookOpen className="w-3 h-3" /> },
  ]);

  const handleInteraction = (index: number, e: React.MouseEvent | React.TouchEvent) => {
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const clientX = 'touches' in e ? e.touches[0].clientX : (e as React.MouseEvent).clientX;
    const percent = Math.round(((clientX - rect.left) / rect.width) * 100);
    const nextData = [...data];
    nextData[index].value = Math.min(100, Math.max(0, percent));
    setData(nextData);
  };

  return (
    <div className="flex flex-col gap-5 w-full bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
      <div className="flex justify-between items-center mb-2">
        <h4 className="text-sm font-bold text-slate-800 uppercase tracking-wider">效能指标模拟</h4>
        <div className="text-[10px] text-slate-400 bg-slate-50 px-2 py-1 rounded">实时模拟 URGS+ 赋能增益</div>
      </div>
      {data.map((item, i) => (
        <div key={i} className="space-y-2 group">
          <div className="flex justify-between text-xs font-bold text-slate-500 group-hover:text-slate-800 transition-colors">
            <div className="flex items-center gap-1.5">
              {item.icon}
              <span>{item.label}</span>
            </div>
            <span className="font-mono">{item.value}%</span>
          </div>
          <div
            className="h-3 bg-slate-100 rounded-full overflow-hidden cursor-pointer relative"
            onMouseDown={(e) => handleInteraction(i, e)}
            onTouchStart={(e) => handleInteraction(i, e)}
          >
            <div
              className={`h-full ${item.color} transition-all duration-500 ease-out shadow-sm`}
              style={{ width: `${item.value}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  );
};

const ActiveLineageGraph = () => {
  const [hoveredNode, setHoveredNode] = useState<string | null>(null);

  // Data structure based on the user's uploaded image
  const nodes = [
    { id: 'root', label: 'SMTMODS.L_ACCT_OBS_LOAN', field: 'SECURITY_AMT', x: 50, y: 180, type: 'table' },
    { id: 'l1_top', label: 'YBT_DATACORE.T_6_11', field: 'F110001', x: 350, y: 80, type: 'table' },
    { id: 'l1_mid', label: 'YBT_DATACORE.TM_L_ACCT_OBS_TEMP', field: 'SECURITY_AMT', x: 350, y: 180, type: 'table' },
    { id: 'l1_bot', label: 'YBT_DATACORE.T_6_12', field: 'F120007', x: 350, y: 280, type: 'table' },
    { id: 'l2_mid', label: 'YBT_DATACORE.TM_L_ACCT_OBS_SX', field: 'SECURITY_AMT', x: 650, y: 180, type: 'table' },
    { id: 'l3_mid', label: 'YBT_DATACORE.T_8_13', field: 'R130004', x: 920, y: 180, type: 'table' },
  ];

  const connections = [
    { from: 'root', to: 'l1_top', type: 'dataflow' },
    { from: 'root', to: 'l1_mid', type: 'dataflow' },
    { from: 'root', to: 'l1_bot', type: 'dataflow' },
    { from: 'l1_mid', to: 'l2_mid', type: 'dataflow' },
    { from: 'l2_mid', to: 'l3_mid', type: 'filter' }, // Representing the dashed/colored line
  ];

  const legend = [
    { label: '数据流', color: '#3b82f6', dashed: false },
    { label: '过滤', color: '#f97316', dashed: true },
    { label: '关联', color: '#84cc16', dashed: true },
    { label: '条件', color: '#ef4444', dashed: true },
  ];

  return (
    <div className="relative w-full h-[400px] bg-slate-50/50 rounded-xl border border-slate-200 overflow-hidden font-sans select-none">
      {/* Grid Background */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-30">
        <defs>
          <pattern id="dot-grid" width="20" height="20" patternUnits="userSpaceOnUse">
            <circle cx="2" cy="2" r="1" fill="#cbd5e1" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#dot-grid)" />
      </svg>

      {/* Main Graph */}
      <svg className="w-full h-full" viewBox="0 0 1100 400">
        {/* Connections */}
        {connections.map((conn, i) => {
          const from = nodes.find(n => n.id === conn.from)!;
          const to = nodes.find(n => n.id === conn.to)!;

          // Calculate precise connection points (right side of from, left side of to)
          const startX = from.x + 200; // Node width is approx 200
          const startY = from.y + 30;  // Mid-height of node (approx 60 height)
          const endX = to.x;
          const endY = to.y + 30;

          const controlPoint1X = startX + (endX - startX) / 2;
          const controlPoint1Y = startY;
          const controlPoint2X = endX - (endX - startX) / 2;
          const controlPoint2Y = endY;

          const pathFn = `M ${startX} ${startY} C ${controlPoint1X} ${controlPoint1Y}, ${controlPoint2X} ${controlPoint2Y}, ${endX} ${endY}`;
          const isFilter = conn.type === 'filter';

          return (
            <g key={i}>
              <path
                d={pathFn}
                fill="none"
                stroke={isFilter ? '#f97316' : '#3b82f6'}
                strokeWidth="2"
                strokeDasharray={isFilter ? "5,3" : "none"}
                className="opacity-80 drop-shadow-sm"
              />
              {/* Animated flow particle */}
              <circle r="4" fill={isFilter ? '#f97316' : '#3b82f6'} filter="url(#glow)">
                <animateMotion
                  dur="1.5s"
                  repeatCount="indefinite"
                  path={pathFn}
                  begin={`${i * 0.5}s`}
                />
              </circle>
            </g>
          );
        })}
        <defs>
          <filter id="glow">
            <feGaussianBlur stdDeviation="2.5" result="coloredBlur" />
            <feMerge>
              <feMergeNode in="coloredBlur" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        {/* Nodes */}
        {nodes.map((node) => (
          <foreignObject x={node.x} y={node.y} width="200" height="80" key={node.id}>
            <div
              className={`w-[200px] bg-white rounded-lg border shadow-sm transition-all duration-300 hover:shadow-md hover:scale-105 cursor-pointer ${hoveredNode === node.id ? 'border-indigo-500 ring-2 ring-indigo-100' : 'border-slate-300'}`}
              onMouseEnter={() => setHoveredNode(node.id)}
              onMouseLeave={() => setHoveredNode(null)}
            >
              <div className="flex items-center gap-2 px-3 py-2 bg-slate-50 border-b border-slate-100 rounded-t-lg">
                <Database className="w-3 h-3 text-indigo-500" />
                <span className="text-[10px] font-bold text-slate-700 truncate" title={node.label}>{node.label}</span>
              </div>
              <div className="px-3 py-2">
                <div className="flex items-center gap-1.5 text-[10px] text-slate-500">
                  <div className="w-1 h-1 rounded-full bg-slate-400"></div>
                  {node.field}
                </div>
              </div>
            </div>
          </foreignObject>
        ))}
      </svg>

      {/* Legend */}
      <div className="absolute top-4 right-4 bg-white p-4 rounded-xl shadow-lg border border-slate-100 w-32">
        <h6 className="text-xs font-bold text-slate-800 mb-3">关系类型</h6>
        <div className="space-y-2">
          {legend.map((item, i) => (
            <div key={i} className="flex items-center gap-2 text-[10px] text-slate-600">
              <div
                className="w-4 h-0.5"
                style={{
                  backgroundColor: item.dashed ? 'transparent' : item.color,
                  borderTop: item.dashed ? `2px dashed ${item.color}` : 'none'
                }}
              />
              <span>{item.label}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const RiskGauge = () => {
  const [score, setScore] = useState(0);
  const [status, setStatus] = useState<'idle' | 'scanning' | 'done'>('idle');

  useEffect(() => {
    if (status === 'scanning') {
      let current = 0;
      const interval = setInterval(() => {
        current += Math.random() * 15;
        if (current >= 45) {
          setScore(45);
          setStatus('done');
          clearInterval(interval);
        } else {
          setScore(Math.round(current));
        }
      }, 150);
      return () => clearInterval(interval);
    }
  }, [status]);

  return (
    <div className="bg-slate-900 rounded-3xl p-8 text-white flex flex-col items-center gap-6 shadow-2xl relative overflow-hidden group">
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-indigo-500 to-transparent opacity-50 group-hover:opacity-100 transition-opacity" />

      <div className="relative w-32 h-32 flex items-center justify-center">
        <svg className="w-full h-full transform -rotate-90">
          <circle cx="64" cy="64" r="58" stroke="currentColor" strokeWidth="8" fill="transparent" className="text-slate-800" />
          <circle
            cx="64" cy="64" r="58"
            stroke="currentColor" strokeWidth="8" fill="transparent"
            strokeDasharray={364.4}
            strokeDashoffset={364.4 - (364.4 * score) / 100}
            className={`transition-all duration-500 ease-out ${score > 90 ? 'text-green-500' : 'text-rose-500'}`}
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-3xl font-black">{score}%</span>
          <span className="text-[8px] uppercase tracking-widest text-slate-400 font-bold">合规审计指数</span>
        </div>
      </div>

      <div className="text-center">
        {status === 'idle' && <h5 className="text-lg font-bold">预发布合规 AI 智查</h5>}
        {status === 'scanning' && <h5 className="text-lg font-bold animate-pulse text-indigo-400">分析 SQL 变更对监管报表影响...</h5>}
        {status === 'done' && (
          <div className="space-y-2 text-left bg-rose-900/40 p-3 rounded-xl border border-rose-500/30 animate-pulse">
            <h5 className="text-sm font-bold text-rose-400 flex items-center gap-2 mb-1">
              <ShieldAlert className="w-4 h-4 animate-bounce" /> 阻断：发现 2 个高危风险
            </h5>
            <ul className="text-[10px] text-rose-200 space-y-1 list-disc pl-4">
              <li>字段 <code>LOAN_ACCT_BAL</code> 被删除，直接影响 G01 报表取数。</li>
              <li>缺少 <code>WHERE</code> 过滤条件，导致统计范围异常扩大。</li>
            </ul>
          </div>
        )}
      </div>

      <button
        onClick={() => { setScore(0); setStatus('scanning'); }}
        disabled={status === 'scanning'}
        className={`px-6 py-2 rounded-full text-sm font-bold transition-all ${status === 'scanning' ? 'bg-slate-800 text-slate-500' : 'bg-indigo-600 hover:bg-indigo-500 shadow-lg shadow-indigo-900/20'}`}
      >
        {status === 'done' ? '重新扫描' : '启动发布前审计'}
      </button>
    </div>
  );
};

// --- Common Slide Layout Component ---

const SlideLayout: React.FC<{ children: React.ReactNode, title?: string, subtitle?: string }> = ({ children, title, subtitle }) => (
  <div className="w-full h-full flex flex-col items-center justify-center">
    {title && (
      <div className="mb-12 text-center w-full">
        <h2 className="text-4xl md:text-5xl font-bold text-slate-900 tracking-tight mb-4 anim-fade-up">{title}</h2>
        {subtitle && <p className="text-xl md:text-2xl text-slate-500 font-light anim-fade-up delay-100">{subtitle}</p>}
      </div>
    )}
    <div className="w-full flex-1 flex flex-col justify-center">
      {children}
    </div>
  </div>
);

// --- Individual Slides ---

export const TitlePage = () => (
  <div className="text-center relative">
    <div className="absolute -top-32 -left-32 w-96 h-96 bg-indigo-50 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-pulse"></div>
    <div className="absolute -bottom-32 -right-32 w-96 h-96 bg-blue-50 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-pulse delay-700"></div>
    <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-gradient-radial from-indigo-100/20 to-transparent opacity-50 blur-3xl -z-10 animate-pulse duration-[5000ms]"></div>

    <h1 className="text-8xl font-black text-indigo-900 mb-8 tracking-tighter anim-scale-in">
      监管一体化系统
      <span className="inline-block hover:scale-110 transition-transform duration-300 transform origin-bottom-left cursor-default">（URGS）</span>
      <span className="text-indigo-500 font-light inline-block animate-bounce delay-1000">+</span>
    </h1>
    <h2 className="text-5xl md:text-6xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-slate-800 via-indigo-900 to-slate-800 mb-6 leading-tight anim-fade-up delay-200">
      重塑智能时代的监管运营
    </h2>
    <p className="text-2xl md:text-3xl text-slate-500 max-w-3xl mx-auto font-light leading-relaxed anim-fade-up delay-300">
      一体化、智能化、可视化的新一代协同办公与智能化监管资产管理平台
    </p>
    <div className="mt-12 flex justify-center gap-4 anim-scale-in delay-500">
      <div className="h-1 w-32 bg-gradient-to-r from-indigo-600 to-teal-400 rounded-full shadow-lg shadow-indigo-200"></div>
    </div>
  </div>
);

export const TableOfContentsPage = ({ onNavigate }: { onNavigate: (index: number) => void }) => (
  <SlideLayout title="目录" subtitle="URGS+ 智能监管平台介绍概览">
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mt-8 max-w-6xl mx-auto">
      {[
        { id: "01", title: "背景与挑战", sub: "监管运营的痛点", index: 2, color: "bg-rose-500", shadow: "shadow-rose-200", icon: <ShieldAlert className="w-6 h-6 text-white" /> },
        { id: "02", title: "产品愿景", sub: "URGS+ 核心设计理念", index: 3, color: "bg-indigo-500", shadow: "shadow-indigo-200", icon: <Zap className="w-6 h-6 text-white" /> },
        { id: "03", title: "技术架构", sub: "全链路技术体系", index: 4, color: "bg-slate-700", shadow: "shadow-slate-400", icon: <Cpu className="w-6 h-6 text-white" /> },
        { id: "04", title: "四大支柱", sub: "核心能力矩阵", index: 5, color: "bg-teal-500", shadow: "shadow-teal-200", icon: <Boxes className="w-6 h-6 text-white" /> },
        { id: "05", title: "AI 赋能", sub: "RAG & Agent 体系", index: 6, color: "bg-amber-500", shadow: "shadow-amber-200", icon: <Bot className="w-6 h-6 text-white" /> },
        { id: "06", title: "自动化协同", sub: "调度与驾驶舱", index: 9, color: "bg-indigo-500", shadow: "shadow-indigo-200", icon: <LayoutDashboard className="w-6 h-6 text-white" /> },
        { id: "07", title: "资产管理", sub: "血缘图谱与元数据", index: 11, color: "bg-cyan-600", shadow: "shadow-cyan-200", icon: <Network className="w-6 h-6 text-white" /> },
        { id: "08", title: "风险防控与版本管理", sub: "变更事前阻断", index: 13, color: "bg-blue-500", shadow: "shadow-blue-200", icon: <ShieldCheck className="w-6 h-6 text-white" /> },
        { id: "09", title: "生态价值", sub: "多角色协同效益", index: 14, color: "bg-violet-600", shadow: "shadow-violet-200", icon: <Users className="w-6 h-6 text-white" /> },
      ].map((item, idx) => (
        <div
          key={idx}
          onClick={() => onNavigate(item.index)}
          className="group bg-white rounded-2xl p-6 shadow-sm border border-slate-100 hover:shadow-xl hover:shadow-indigo-100 hover:-translate-y-2 transition-all duration-300 cursor-pointer flex items-start gap-4 anim-fade-up"
          style={{ animationDelay: `${idx * 100}ms` }}
        >
          <div className={`${item.color} w-12 h-12 rounded-xl flex items-center justify-center shrink-0 shadow-lg ${item.shadow} group-hover:scale-110 transition-transform duration-300 group-hover:rotate-6`}>
            {item.icon}
          </div>
          <div>
            <div className="text-xs font-bold text-slate-400 mb-1 group-hover:text-indigo-400 transition-colors">{item.id}</div>
            <h3 className="text-xl font-bold text-slate-800 mb-1 group-hover:text-indigo-600 transition-colors">{item.title}</h3>
            <p className="text-sm text-slate-500 group-hover:text-slate-600">{item.sub}</p>
          </div>
        </div>
      ))}
    </div>
  </SlideLayout>
);

export const ChallengePage = () => (
  <SlideLayout title="监管运营的阵痛" subtitle="协同壁垒、隐蔽风险与知识断层">
    <div className="grid md:grid-cols-3 gap-8 mt-4">
      {[
        {
          icon: <Boxes className="w-16 h-16 text-slate-400 group-hover:text-indigo-400 transition-colors" />,
          title: "业务与技术协同断层",
          items: ["业务人员理解不了取数逻辑", "研发对报表口径变动不敏感", "缺乏统一的工作入口与公告协同"]
        },
        {
          icon: <ShieldAlert className="w-16 h-16 text-amber-500 group-hover:text-amber-400 transition-colors" />,
          title: "无法感知的变更风险",
          items: ["底层表改动导致报表大面积失效", "缺乏事前阻断，故障往往在线上爆发", "血缘不透明，影响评估全靠‘猜’"]
        },
        {
          icon: <LineChart className="w-16 h-16 text-indigo-500 group-hover:text-indigo-400 transition-colors" />,
          title: "沉没的组织运维成本",
          items: ["重复问题频繁排查，专家依赖度高", "经验散落在聊天记录，没有知识沉淀", "交付流程繁琐，自动化程度低"]
        }
      ].map((card, idx) => (
        <div
          key={idx}
          className={`group bg-white p-8 rounded-3xl shadow-xl border border-slate-100 flex flex-col items-center text-center hover:shadow-2xl hover:bg-slate-50 transition-all duration-300 anim-fade-up`}
          style={{ animationDelay: `${(idx + 2) * 150}ms` }}
        >
          <div className="mb-6 animate-float" style={{ animationDelay: `${idx * 200}ms` }}>{card.icon}</div>
          <h3 className="text-2xl font-bold text-slate-800 mb-6 group-hover:scale-105 transition-transform">{card.title}</h3>
          <ul className="text-left space-y-4 text-slate-600">
            {card.items.map((item, i) => (
              <li key={i} className="flex gap-3 anim-fade-right group-hover:translate-x-1 transition-transform" style={{ animationDelay: `${(idx + 2) * 150 + (i * 100)}ms` }}>
                <span className="w-1.5 h-1.5 rounded-full bg-slate-300 mt-2.5 flex-shrink-0 group-hover:bg-indigo-400 transition-colors"></span>
                <span className="text-lg leading-snug">{item}</span>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  </SlideLayout>
);

export const VisionPage = () => (
  <SlideLayout title="URGS+：构建统一中枢" subtitle="从流程割裂到智能协同">
    <div className="relative flex flex-col items-center justify-center py-12">
      {/* Animated Connection Lines */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none z-0 overflow-visible">
        <defs>
          <linearGradient id="lineGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#e2e8f0" stopOpacity="0" />
            <stop offset="50%" stopColor="#6366f1" stopOpacity="0.5" />
            <stop offset="100%" stopColor="#e2e8f0" stopOpacity="0" />
          </linearGradient>
        </defs>
        {/* Top Left Connection */}
        <path d="M 300 150 Q 500 250 500 300" fill="none" stroke="url(#lineGrad)" strokeWidth="2" className="animate-pulse" />
        {/* Top Right Connection */}
        <path d="M 700 150 Q 500 250 500 300" fill="none" stroke="url(#lineGrad)" strokeWidth="2" className="animate-pulse delay-700" />
        {/* Bottom Left Connection */}
        <path d="M 300 450 Q 500 350 500 300" fill="none" stroke="url(#lineGrad)" strokeWidth="2" className="animate-pulse delay-300" />
        {/* Bottom Right Connection */}
        <path d="M 700 450 Q 500 350 500 300" fill="none" stroke="url(#lineGrad)" strokeWidth="2" className="animate-pulse delay-500" />
      </svg>

      <div className="relative z-10 w-64 h-64 bg-indigo-600 rounded-full flex flex-col items-center justify-center text-white shadow-2xl shadow-indigo-200 anim-scale-in delay-200 group cursor-pointer hover:scale-105 transition-transform duration-500">
        <div className="absolute inset-0 rounded-full border-2 border-indigo-400 animate-[spin_8s_linear_infinite] border-dashed opacity-50 group-hover:opacity-100 transition-opacity"></div>
        <div className="absolute inset-2 rounded-full border border-indigo-300 animate-[spin_12s_linear_infinite_reverse] opacity-30"></div>
        <h3 className="text-4xl font-bold tracking-tighter relative">URGS+</h3>
        <p className="text-xl opacity-80 mt-1 relative">智能监管大脑</p>
      </div>

      <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
        <div className="w-full max-w-5xl grid grid-cols-2 gap-y-32">
          {/* Left Side */}
          <div className="flex flex-col gap-12 pr-48">
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4 anim-fade-right delay-300 hover:shadow-md hover:border-indigo-300 transition-all cursor-crosshair backdrop-blur-sm bg-opacity-90">
              <Users className="w-8 h-8 text-indigo-500" />
              <span className="text-lg font-bold">业务团队 (Business)</span>
            </div>
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-4 anim-fade-right delay-400 hover:shadow-md hover:border-indigo-300 transition-all cursor-crosshair backdrop-blur-sm bg-opacity-90">
              <Code2 className="w-8 h-8 text-indigo-500" />
              <span className="text-lg font-bold">研发团队 (Dev)</span>
            </div>
          </div>
          {/* Right Side */}
          <div className="flex flex-col gap-12 pl-48 items-end">
            <div className="bg-green-50 p-4 rounded-xl border border-green-100 shadow-sm flex items-center gap-4 anim-fade-up delay-300 hover:shadow-md hover:scale-105 transition-all">
              <Zap className="w-8 h-8 text-green-600" />
              <span className="text-lg font-bold">交付提速 (Agility)</span>
            </div>
            <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 shadow-sm flex items-center gap-4 anim-fade-up delay-400 hover:shadow-md hover:scale-105 transition-all">
              <ShieldCheck className="w-8 h-8 text-blue-600" />
              <span className="text-lg font-bold">极致合规 (Compliance)</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div className="mt-8 text-center max-w-3xl mx-auto text-xl text-slate-500 anim-fade-up delay-700">
      URGS+ 不仅仅是工具，更是组织智慧的数字容器。
    </div>
  </SlideLayout>
);

export const ArchitecturePage = () => (
  <SlideLayout title="URGS+ 技术架构体系">
    <div className="space-y-4 max-w-5xl mx-auto relative group">
      {/* Scanning Line Effect */}
      <div className="absolute top-0 left-0 w-full h-[2px] bg-gradient-to-r from-transparent via-cyan-400 to-transparent z-20 opacity-0 group-hover:opacity-100 animate-[moveVertical_3s_ease-in-out_infinite] pointer-events-none shadow-[0_0_15px_rgba(34,211,238,0.8)]"></div>

      {[
        { layer: "前端展现", tech: "角色化驾驶舱 (Role-Based Workbench)", desc: "为业务与技术人员定制的专属协同视图。", color: "bg-gradient-to-r from-blue-500 to-blue-600" },
        { layer: "核心服务", tech: "微服务编排 + 任务引擎 (Task Engine)", desc: "承载自动化版本管理、调度与监管日历。", color: "bg-gradient-to-r from-indigo-500 to-indigo-600" },
        { layer: "智能增强", tech: "Ark AI Agent (RAG + SQL Parser)", desc: "QWen3，BM25+语义检索，Agent 场景化服务。", color: "bg-gradient-to-r from-amber-500 to-orange-500", highlight: true },
        { layer: "存储底座", tech: "Neo4j 图数据库 + 向量索引 (FAISS/MILVUS)", desc: "管理全链路血缘图谱与非结构化知识库。", color: "bg-gradient-to-r from-slate-700 to-slate-800" },
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

export const PillarsPage = () => (
  <SlideLayout title="URGS+ 的四大核心能力">
    <div className="grid md:grid-cols-4 gap-6 mt-12 perspective-1000">
      {[
        { icon: <Bot />, title: "AI 赋能", desc: "RAG 助手与经验自动沉淀", color: "text-amber-500", border: "border-amber-200", shadow: "shadow-amber-100" },
        { icon: <Workflow />, title: "一体化协同", desc: "流程自动化与公告管理", color: "text-rose-500", border: "border-rose-200", shadow: "shadow-rose-100" },
        { icon: <Network />, title: "资产管理", desc: "图谱化血缘、监管指标、监管集市管理", color: "text-teal-500", border: "border-teal-200", shadow: "shadow-teal-100" },
        { icon: <ShieldCheck />, title: "风险防控与版本管理", desc: "变更事前阻断与 AI 审计", color: "text-indigo-500", border: "border-indigo-200", shadow: "shadow-indigo-100" },
      ].map((p, idx) => (
        <div
          key={idx}
          className={`bg-white p-8 rounded-3xl shadow-lg border-t-4 ${p.border} flex flex-col items-center text-center anim-scale-in group hover:-translate-y-3 hover:shadow-2xl hover:bg-gradient-to-b hover:from-white hover:to-slate-50 transition-all duration-500`}
          style={{ animationDelay: `${idx * 150}ms` }}
        >
          <div className={`mb-6 animate-float ${p.color} bg-slate-50 p-4 rounded-full group-hover:bg-white group-hover:shadow-md transition-all`}>{React.cloneElement(p.icon as React.ReactElement<{ className?: string }>, { className: "w-10 h-10" })}</div>
          <h3 className="text-xl font-bold text-slate-800 mb-2 group-hover:text-black transition-colors">{p.title}</h3>
          <p className="text-sm text-slate-500 leading-snug">{p.desc}</p>
        </div>
      ))}
    </div>
  </SlideLayout>
);

export const OrchestrationPage = () => (
  <SlideLayout title="能力二：自动化运维与协同" subtitle="降低成本，沉淀智慧">
    <div className="flex flex-col md:flex-row gap-12 mt-8">
      <div className="flex-1 space-y-6 anim-fade-right delay-200">
        <div className="p-6 bg-white rounded-2xl border border-slate-100 shadow-sm transition-all hover:bg-rose-50 hover:border-rose-200 hover:shadow-lg group">
          <div className="flex items-center gap-3 mb-4 text-rose-500 font-bold group-hover:scale-105 transition-transform">
            <Calendar className="w-6 h-6" /> 监管日历与业务看板
          </div>
          <p className="text-slate-600 text-sm leading-relaxed">
            以日历视图聚合展示“1104 报送”等强关联节点。系统自动联动报送系统状态，通过高亮超期提醒，确保关键窗口零延误。
          </p>
        </div>
        <div className="p-6 bg-white rounded-2xl border border-slate-100 shadow-sm transition-all hover:bg-indigo-50 hover:border-indigo-200 hover:shadow-lg group">
          <div className="flex items-center gap-3 mb-4 text-indigo-500 font-bold group-hover:scale-105 transition-transform">
            <Workflow className="w-6 h-6" /> 可视化任务调度
          </div>
          <p className="text-slate-600 text-sm leading-relaxed">
            负责复杂工作流编排与执行器状态刷新，监控核心取数任务生命周期。
          </p>
        </div>
      </div>
      <div className="flex-1 anim-scale-in delay-500">
        <div className="bg-slate-900 rounded-3xl p-8 text-white h-full relative group overflow-hidden shadow-2xl">
          {/* Background decoration */}
          <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-500/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>

          {/* Scan line for chart area */}
          <div className="absolute top-1/2 left-0 w-full h-1 bg-gradient-to-r from-transparent via-white/10 to-transparent animate-[moveHorizontal_4s_linear_infinite] pointer-events-none"></div>

          <h4 className="text-lg font-bold mb-8 flex items-center gap-2 relative z-10">
            <Activity className="w-5 h-5 text-indigo-400 animate-pulse" />
            监管批量作业监控
          </h4>

          {/* Bar Chart Area */}
          <div className="relative z-10 flex items-end justify-between h-48 px-6 pb-6 border-b border-white/10">
            {[
              {
                label: '1104 报送',
                val: 82,
                color: 'bg-emerald-400',
                delay: '0ms',
                details: [
                  { l: '月报一批', v: '100% (已完成)' },
                  { l: '月报二批', v: '100% (已完成)' },
                  { l: '季报一批', v: '45% (计算中)' }
                ]
              },
              { label: '大集中', val: 100, color: 'bg-indigo-400', delay: '150ms', details: [{ l: '状态', v: '已完成' }] },
              { label: '金融基础', val: 80, color: 'bg-blue-400', delay: '300ms', details: [{ l: '状态', v: '校验中' }] },
              { label: 'EAST', val: 0, color: 'bg-slate-600', delay: '450ms', details: [{ l: '状态', v: '未开始' }] },
            ].map((item, i) => (
              <div key={i} className="flex flex-col items-center gap-2 group/bar w-1/4">
                <div className="relative w-full flex justify-center items-end h-32">
                  {/* Tooltip */}
                  <div className="absolute bottom-full mb-2 opacity-0 group-hover/bar:opacity-100 transition-all duration-300 translate-y-2 group-hover/bar:translate-y-0 text-xs bg-slate-800/90 backdrop-blur px-3 py-2 rounded-lg border border-white/20 whitespace-nowrap z-20 shadow-xl pointer-events-none">
                    <div className="font-bold mb-1 border-b border-white/10 pb-1">{item.label}</div>
                    {item.details.map((d, idx) => (
                      <div key={idx} className="flex justify-between gap-4 text-slate-300">
                        <span>{d.l}</span>
                        <span className="font-mono text-white">{d.v}</span>
                      </div>
                    ))}
                  </div>
                  {/* Bar */}
                  <div
                    className={`w-4 md:w-8 rounded-t-lg transition-all duration-1000 ease-out ${item.color} shadow-[0_0_15px_rgba(255,255,255,0.3)] relative overflow-hidden`}
                    style={{ height: `${item.val}%`, animation: `grow-y 1s ease-out ${item.delay} backwards` }}
                  >
                    {/* Shine effect */}
                    <div className="absolute inset-0 bg-gradient-to-tr from-transparent via-white/20 to-transparent translate-y-full hover:translate-y-[-200%] transition-transform duration-1000"></div>
                  </div>
                </div>
                <div className="text-[10px] md:text-sm font-medium text-slate-300 text-center truncate w-full">
                  {item.label}
                </div>
              </div>
            ))}
          </div>

          <div className="mt-6 flex justify-between items-center relative z-10">
            <div className="flex gap-4">
              <div className="flex items-center gap-2 text-xs text-slate-400">
                <div className="w-2 h-2 rounded-full bg-emerald-400"></div> 已完成
              </div>
              <div className="flex items-center gap-2 text-xs text-slate-400">
                <div className="w-2 h-2 rounded-full bg-amber-400 animate-pulse"></div> 计算中
              </div>
            </div>
            <div className="text-right">
              <div className="text-[10px] text-slate-500 uppercase tracking-wider">Total Progress</div>
              <div className="text-xl font-mono font-bold text-white">85.4%</div>
            </div>
          </div>

          <style>{`
            @keyframes grow-y {
                from { height: 0; opacity: 0; }
            }
             @keyframes moveHorizontal {
                0% { left: -100%; }
                100% { left: 100%; }
             }
          `}</style>
        </div>
      </div>
    </div>
  </SlideLayout>
);

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

export const ReleaseManagementPage = () => (
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
);

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

export const LineagePage = () => (
  <SlideLayout title="血缘可视化：一眼洞穿监管生命周期">
    <div className="w-full max-w-5xl mx-auto space-y-12">
      <div className="anim-scale-in delay-200">
        <ActiveLineageGraph />
      </div>
      <div className="grid md:grid-cols-3 gap-6">
        <div className="p-6 bg-indigo-900 text-white rounded-2xl shadow-xl">
          <h5 className="font-bold mb-2">字段级溯源</h5>
          <p className="text-[10px] opacity-70">基于 Neo4j 图存储实现报表指标到底层字段的穿透追踪。</p>
        </div>
        <div className="p-6 bg-slate-100 rounded-2xl">
          <h5 className="font-bold mb-2">资产自动更新</h5>
          <p className="text-[10px] text-slate-500">定时同步物理模型，元数据与现实环境永远一致。</p>
        </div>
        <div className="p-6 bg-slate-100 rounded-2xl">
          <h5 className="font-bold mb-2">代码值域管理</h5>
          <p className="text-[10px] text-slate-500">维护业务标准的字典项，统一全行监管资产认知。</p>
        </div>
      </div>
    </div>
  </SlideLayout>
);

export const AiPillarPage = () => (
  <SlideLayout title="能力一：AI 原生增强" subtitle="Ark 智能体赋能全场景">
    <div className="flex flex-col md:flex-row items-center gap-16 mt-8">
      <div className="flex-1 space-y-6 anim-fade-right delay-200">
        <div className="p-6 bg-amber-50 rounded-2xl border border-amber-100">
          <h5 className="font-bold text-amber-900 mb-2 flex items-center gap-2">
            <Bot className="w-5 h-5" /> Ark 助手 (RAG & Agent)
          </h5>
          <p className="text-xs text-amber-800/80 leading-relaxed">
            支持 BM25 + 语义向量混合检索。通过对话获取精准上下文建议，绑定专属知识库。
          </p>
        </div>
        <div className="p-6 bg-slate-50 rounded-2xl border border-slate-200">
          <h5 className="font-bold text-slate-800 mb-2">多场景化智能体</h5>
          <div className="flex gap-2 mt-3">
            <span className="text-[10px] px-2 py-1 bg-white rounded border">1104 填报 Agent</span>
            <span className="text-[10px] px-2 py-1 bg-white rounded border">调度故障 Agent</span>
            <span className="text-[10px] px-2 py-1 bg-white rounded border">发布合规 Agent</span>
          </div>
        </div>
      </div>
      <div className="flex-1 anim-scale-in delay-500">
        <div className="w-80 h-80 bg-gradient-to-br from-amber-400 to-orange-500 rounded-full flex items-center justify-center text-white shadow-2xl animate-pulse">
          <Bot className="w-40 h-40" />
        </div>
      </div>
    </div>
  </SlideLayout>
);

export const ArkAssistantPage = () => (
  <SlideLayout >
    <div className="grid md:grid-cols-2 gap-12 mt-4 items-center">
      <div className="bg-white p-8 rounded-[2rem] shadow-2xl border border-slate-100 min-h-[400px] flex flex-col anim-scale-in delay-200">
        <div className="flex-1 space-y-6">
          <div className="flex items-start gap-3 justify-end anim-fade-up delay-500">
            <div className="bg-indigo-600 text-white p-4 rounded-2xl rounded-tr-none max-w-xs text-sm">
              G0102 五级分类是怎么算出来的？
            </div>
            <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center shrink-0">
              <UserCircle2 className="w-5 h-5 text-slate-400" />
            </div>
          </div>
          <div className="flex items-start gap-3 anim-fade-up delay-1000">
            <div className="w-10 h-10 rounded-full bg-amber-500 flex items-center justify-center shrink-0 shadow-lg text-white">
              <Bot className="w-6 h-6" />
            </div>
            <div className="bg-slate-50 p-4 rounded-2xl rounded-tl-none border border-slate-200 text-sm space-y-4">
              <p className="font-medium">AI 解析取数代码：</p>
              <p className="text-xs text-slate-600 italic">“AI 解析：基于‘贷款分户账’(L_ACCT_LOAN)，根据贷款五级分类映射 G0102 报表项。指标口径为汇率折算后的贷款余额合计，并剔除了委托贷款账户、核销及已转让资产。”</p>
              <div className="p-3 bg-white rounded-lg border border-slate-100 text-xs font-mono whitespace-pre-wrap">
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
AND U.BASIC_CCY = a.CURR_CD --基准币种
AND U.FORWARD_CCY = 'CNY' --折算币种
AND U.DATA_DATE = I_DATADATE
WHERE A.ACCT_TYP NOT LIKE '90%'
AND A.DATA_DATE = I_DATADATE
AND A.ACCT_STS <> '3'
AND A.CANCEL_FLG <> 'Y'
AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
GROUP BY a.org_num, a.LOAN_GRADE_CD, a.data_date`}
              </div>
              <div className="p-3 bg-white rounded-lg border border-slate-100 text-xs">
                <div className="font-bold text-slate-400 mb-2 uppercase">数据依据</div>
                <div className="flex items-center gap-2 text-indigo-600 text-[10px]">
                  <Network className="w-3 h-3" /> 表关系血缘图谱
                </div>
                <div className="flex items-center gap-2 text-indigo-600 text-[10px] mt-1">
                  <BookOpen className="w-3 h-3" /> 监管手册 v4.2 知识库
                </div>
              </div>
            </div>
          </div>
        </div>
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

export const AiWorkflowPage = () => (
  <SlideLayout title="能力联动：智能工作流闭环">
    <div className="grid md:grid-cols-3 gap-8 mt-12">
      {[
        { title: "代码“翻译”器", desc: "利用 AI 将复杂的 SQL 代码翻译为自然语言描述，赋能业务理解。", icon: <Zap className="text-indigo-500" /> },
        { title: "故障自动转知识", desc: "问题解决后‘一键’总结为‘现象-原因-对策’存入知识库。", icon: <BookOpen className="text-teal-500" /> },
        { title: "场景 Agent 联动", desc: "1104 填报助手在填报页面自动弹出合规建议。", icon: <Bot className="text-amber-500" /> }
      ].map((card, i) => (
        <div key={i} className="bg-white p-8 rounded-3xl shadow-lg border border-slate-100 hover:shadow-xl transition-all anim-scale-in" style={{ animationDelay: `${(i + 2) * 200}ms` }}>
          <div className="p-4 bg-slate-50 w-fit rounded-2xl mb-6 animate-float">{card.icon}</div>
          <h4 className="text-xl font-bold text-slate-800 mb-4">{card.title}</h4>
          <p className="text-slate-500 text-sm leading-relaxed">{card.desc}</p>
        </div>
      ))}
    </div>
  </SlideLayout>
);

export const RolesPage = () => (
  <SlideLayout title="URGS+: 赋能多元角色生态">
    <div className="grid md:grid-cols-2 gap-8 mt-8">
      {[
        { role: "业务人员 (Business)", value: "理解指标口径，监管填报助手，公告协同。", icon: <Users />, color: "bg-indigo-600" },
        { role: "研发运维 (Dev/Ops)", value: "全流程发布，风险事前阻断，故障探针。", icon: <Code2 />, color: "bg-rose-600" },
        { role: "资产经理 (Asset Mgr)", value: "管理数据资产，掌控全血缘，资产轨迹追踪。", icon: <Network />, color: "bg-teal-600" },
        { role: "管理员 (Admin)", value: "管控资源分配，管理场景 AI 智能体。", icon: <ShieldCheck />, color: "bg-slate-700" },
      ].map((p, i) => (
        <div key={i} className="bg-white p-8 rounded-3xl shadow-md border border-slate-100 flex items-center gap-6 group hover:border-indigo-300 transition-colors anim-fade-up" style={{ animationDelay: `${(i + 2) * 150}ms` }}>
          <div className={`p-4 rounded-2xl text-white group-hover:scale-110 transition-transform ${p.color}`}>
            {/* Fix: cast p.icon as React.ReactElement<{ className?: string }> to provide known property 'className' for cloneElement */}
            {React.cloneElement(p.icon as React.ReactElement<{ className?: string }>, { className: "w-8 h-8" })}
          </div>
          <div>
            <h4 className="text-2xl font-bold text-indigo-900">{p.role}</h4>
            <p className="text-slate-600 mt-1 text-sm">{p.value}</p>
          </div>
        </div>
      ))}
    </div>
  </SlideLayout>
);

export const ConclusionPage = () => {
  const [showAIJourney, setShowAIJourney] = useState(false);

  return (
    <SlideLayout title="开启智能监管新范式" subtitle="构建韧性、敏捷、智慧的运营平台">
      <div className="grid md:grid-cols-3 gap-8 mt-12 mb-16">
        {[
          { title: "极致效率", items: ["端到端发布流水线", "AI 知识检索与翻译"] },
          { title: "极致稳健", items: ["图谱驱动事前风险阻断", "全量血缘覆盖审计"] },
          { title: "极致智慧", items: ["RAG 引擎沉淀经验", "多场景 Agent 伴随"] }
        ].map((card, i) => (
          <div key={i} className="bg-white p-10 rounded-[3rem] shadow-xl border-b-8 border-indigo-600 flex flex-col items-center text-center anim-scale-in" style={{ animationDelay: `${(i + 2) * 200}ms` }}>
            <h4 className="text-2xl font-bold text-slate-800 mb-8">{card.title}</h4>
            <ul className="space-y-4 text-slate-500 text-lg">
              {card.items.map((item, j) => (
                <li key={j} className="flex gap-2 anim-fade-right" style={{ animationDelay: `${(i + 2) * 200 + (j * 150)}ms` }}>
                  <span className="text-indigo-600 font-bold">•</span>
                  {item}
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      <div className="text-center anim-scale-in delay-1000">
        <button
          onClick={() => setShowAIJourney(true)}
          className="group inline-flex items-center gap-4 px-12 py-6 bg-indigo-600 text-white rounded-full text-3xl font-bold shadow-2xl shadow-indigo-200 hover:scale-105 hover:bg-indigo-500 transition-all cursor-pointer animate-float"
        >
          <Sparkles className="w-8 h-8 animate-pulse text-amber-300" />
          立即开启 URGS+ 智能之旅
        </button>
      </div>

      {showAIJourney && <AIJourneyOverlay onClose={() => setShowAIJourney(false)} />}
    </SlideLayout>
  );
};
