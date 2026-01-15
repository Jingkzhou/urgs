
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
  GitBranch,
  FileCode,
  BookOpen,
  FileText,
  Lightbulb,
  PenTool,
  GitCommit,
  ArrowRight,
  MessageSquare,
  Settings,
  PlayCircle,
  CheckCircle2,
  ClipboardList,
  FileSearch,
  Sparkles,
  PieChart,
  AlertCircle,
  X,
  Calendar,
  Terminal,
  Activity
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
  <div className="relative w-screen h-screen overflow-hidden bg-slate-50 flex flex-col items-center justify-center text-center perspective-grid selection:bg-indigo-100">

    {/* Background - Elegant Light Abstract */}
    <div className="absolute inset-0 z-0 bg-slate-50">
      {/* Soft Gradients */}
      <div className="absolute top-[-20%] right-[-10%] w-[800px] h-[800px] bg-indigo-100/50 rounded-full blur-3xl opacity-60 animate-pulse duration-[8000ms]"></div>
      <div className="absolute bottom-[-20%] left-[-10%] w-[600px] h-[600px] bg-teal-100/50 rounded-full blur-3xl opacity-60 animate-pulse duration-[6000ms] delay-1000"></div>

      {/* Subtle Grid */}
      <div className="absolute inset-0 opacity-[0.03]"
        style={{ backgroundImage: 'linear-gradient(#4f46e5 1px, transparent 1px), linear-gradient(to right, #4f46e5 1px, transparent 1px)', backgroundSize: '40px 40px' }}>
      </div>
    </div>

    {/* Floating Elements (Glassmorphism) */}
    <div className="absolute top-32 left-10 hidden md:block anim-fade-right">
      <div className="glass-card px-4 py-3 rounded-xl flex flex-col gap-1 border border-white/50 shadow-lg shadow-indigo-100/50">
        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">System Status</span>
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse"></div>
          <span className="text-xs font-bold text-slate-600">Online / Stable</span>
        </div>
      </div>
    </div>

    <div className="absolute bottom-32 right-10 hidden md:block anim-fade-right delay-200">
      <div className="glass-card px-4 py-3 rounded-xl flex flex-col gap-1 border border-white/50 shadow-lg shadow-teal-100/50 text-right">
        <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">AI Core</span>
        <div className="flex items-center gap-2 justify-end">
          <span className="text-xs font-bold text-slate-600">RAG Engine Active</span>
          <Bot className="w-3 h-3 text-indigo-500" />
        </div>
      </div>
    </div>

    {/* Central Visual */}
    <div className="relative z-10 mb-12 scale-110 md:scale-125">
      <div className="relative w-48 h-48 flex items-center justify-center">
        {/* Spinning Rings - Light Theme */}
        <div className="absolute inset-0 border border-indigo-200 rounded-full animate-spin-slow"></div>
        <div className="absolute inset-4 border border-teal-200 rounded-full animate-spin-reverse-slower border-dashed"></div>
        <div className="absolute inset-0 bg-white/40 backdrop-blur-sm rounded-full shadow-2xl shadow-indigo-200/50"></div>

        {/* Center Icon */}
        <div className="relative z-20 bg-white p-5 rounded-full border border-white shadow-[0_10px_40px_rgba(79,70,229,0.15)] animate-float">
          <div className="bg-gradient-to-br from-indigo-500 to-indigo-600 p-4 rounded-full text-white">
            <Bot className="w-12 h-12" />
          </div>
        </div>

        {/* Orbiting DOT */}
        <div className="absolute -top-4 left-1/2 -translate-x-1/2">
          <div className="w-3 h-3 bg-indigo-500 rounded-full shadow-lg shadow-indigo-300 animate-bounce"></div>
        </div>
      </div>
    </div>

    {/* Main Title Group */}
    <div className="relative z-20 space-y-4">
      <h1 className="text-7xl md:text-9xl font-black text-slate-900 tracking-tighter relative inline-block">
        URGS<span className="text-indigo-600">+</span>
        {/* Subtle reflection/shadow */}
        <span className="absolute -bottom-4 left-0 w-full h-8 bg-gradient-to-t from-white via-white/50 to-transparent blur-[2px] transform scale-y-[-0.3] opacity-20 origin-bottom pointer-events-none select-none">URGS+</span>
      </h1>

      <div className="h-1.5 w-24 mx-auto bg-gradient-to-r from-indigo-500 to-teal-400 rounded-full mt-2 mb-8 shadow-sm"></div>

      <h2 className="text-3xl md:text-5xl font-extrabold text-slate-800 mb-6 anim-fade-up leading-tight" style={{ animationDelay: '0.2s' }}>
        <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-indigo-500">智能</span>监管运营新范式
      </h2>

      <p className="text-lg md:text-xl text-slate-500 max-w-2xl mx-auto font-medium leading-relaxed anim-fade-up" style={{ animationDelay: '0.4s' }}>
        一体化 · 智能化 · 可视化
        <span className="block text-sm font-normal text-slate-400 mt-2">Enterprise Resource Governance System Plus</span>
      </p>
    </div>

    {/* CTA Button */}
    <div className="mt-16 z-20 anim-scale-in" style={{ animationDelay: '0.6s' }}>
      <button className="group relative px-8 py-3 bg-white border border-indigo-100 rounded-full overflow-hidden transition-all hover:border-indigo-200 hover:shadow-xl hover:shadow-indigo-100/50 hover:-translate-y-1">
        <span className="relative flex items-center gap-2 text-indigo-900 font-bold text-sm tracking-wide group-hover:gap-3 transition-all">
          INITIALIZE SYSTEM <ChevronRight className="w-4 h-4 text-indigo-500" />
        </span>
      </button>
    </div>

  </div>
);

export const TableOfContentsPage = ({ onNavigate }: { onNavigate: (index: number) => void }) => (
  <div className="relative w-screen h-screen overflow-hidden bg-slate-50 flex flex-col items-center justify-center text-slate-800">
    {/* Clean, light background with subtle pattern */}
    <div className="absolute inset-0 bg-slate-50 z-0"></div>
    <div className="absolute inset-0 z-0 opacity-[0.03]"
      style={{ backgroundImage: 'radial-gradient(circle at 50% 50%, #4f46e5 1px, transparent 1px)', backgroundSize: '24px 24px' }}>
    </div>

    {/* Decoration Blobs */}
    <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-indigo-100/40 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>
    <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-teal-100/40 rounded-full blur-3xl translate-y-1/2 -translate-x-1/2"></div>

    <div className="relative z-10 w-full max-w-7xl px-8 h-full flex flex-col pt-16 md:pt-24">
      <div className="text-center mb-12 space-y-3">
        <h2 className="text-4xl md:text-5xl font-black tracking-tight text-slate-900">
          SYSTEM MODULES
        </h2>
        <p className="text-slate-400 text-sm font-bold uppercase tracking-[0.2em]">
          Select Activation Node
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {[
          { id: "01", title: "背景与挑战", sub: "Operational Pain Points", index: 2, color: "text-rose-500", bg: "bg-rose-50 hover:bg-rose-100", border: "border-rose-100 hover:border-rose-200", icon: <ShieldAlert className="w-8 h-8" /> },
          { id: "02", title: "产品愿景", sub: "Core Vision & Philosophy", index: 3, color: "text-indigo-500", bg: "bg-indigo-50 hover:bg-indigo-100", border: "border-indigo-100 hover:border-indigo-200", icon: <Zap className="w-8 h-8" /> },
          { id: "03", title: "技术架构", sub: "System Architecture", index: 4, color: "text-slate-600", bg: "bg-slate-50 hover:bg-slate-100", border: "border-slate-200 hover:border-slate-300", icon: <Cpu className="w-8 h-8" /> },
          { id: "04", title: "四大支柱", sub: "Core Capability Matrix", index: 5, color: "text-teal-600", bg: "bg-teal-50 hover:bg-teal-100", border: "border-teal-100 hover:border-teal-200", icon: <Boxes className="w-8 h-8" /> },
          { id: "05", title: "AI 赋能", sub: "RAG & Agent System", index: 6, color: "text-amber-500", bg: "bg-amber-50 hover:bg-amber-100", border: "border-amber-100 hover:border-amber-200", icon: <Bot className="w-8 h-8" /> },
          { id: "06", title: "自动化协同", sub: "Automation & Cockpit", index: 9, color: "text-indigo-600", bg: "bg-indigo-50 hover:bg-indigo-100", border: "border-indigo-100 hover:border-indigo-200", icon: <LayoutDashboard className="w-8 h-8" /> },
          { id: "07", title: "资产管理", sub: "Data Assets & Lineage", index: 11, color: "text-cyan-600", bg: "bg-cyan-50 hover:bg-cyan-100", border: "border-cyan-100 hover:border-cyan-200", icon: <Network className="w-8 h-8" /> },
          { id: "08", title: "风险防控", sub: "Risk Control & Versioning", index: 13, color: "text-blue-600", bg: "bg-blue-50 hover:bg-blue-100", border: "border-blue-100 hover:border-blue-200", icon: <ShieldCheck className="w-8 h-8" /> },
          { id: "09", title: "生态价值", sub: "Ecosystem Value", index: 14, color: "text-violet-600", bg: "bg-violet-50 hover:bg-violet-100", border: "border-violet-100 hover:border-violet-200", icon: <Users className="w-8 h-8" /> },
        ].map((item, idx) => (
          <div
            key={idx}
            onClick={() => onNavigate(item.index)}
            className={`group relative ${item.bg} p-6 rounded-2xl border ${item.border} transition-all duration-300 cursor-pointer flex items-center gap-6 anim-fade-up shadow-sm hover:shadow-xl hover:-translate-y-1 overflow-hidden`}
            style={{ animationDelay: `${idx * 50}ms` }}
          >
            {/* Icon Box */}
            <div className={`${item.color} p-3 bg-white rounded-xl shadow-sm border border-white group-hover:scale-110 transition-transform duration-300`}>
              {item.icon}
            </div>

            <div className="flex-1 z-10">
              <div className="flex justify-between items-center mb-1">
                <h3 className={`text-lg font-bold text-slate-800 transition-colors tracking-tight`}>{item.title}</h3>
                <span className="text-[10px] font-bold opacity-40 text-slate-500 bg-white px-1.5 py-0.5 rounded-full shadow-sm">{item.id}</span>
              </div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-tight truncate">{item.sub}</p>
            </div>

            <ChevronRight className={`w-5 h-5 text-slate-300 group-hover:text-slate-500 group-hover:translate-x-1 transition-all`} />
          </div>
        ))}
      </div>
    </div>
  </div>
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
  <div className="relative w-screen h-screen overflow-hidden">
    <AgentEcosystemFlow />
  </div>
);

const AgentEcosystemFlow = () => {
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
            const start = nodes.find(n => n.id === conn.from)!;
            const end = nodes.find(n => n.id === conn.to)!;
            const isFeedback = conn.dashed;

            // 计算起点和终点
            const x1 = start.x + 32;
            const y1 = start.y + 32;
            const x2 = end.x + 32;
            const y2 = end.y + 32;

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
      {/* Modal 弹窗 - High Tech Light Theme */}
      {selectedNode && (() => {
        const detailNode = nodes.find(n => n.id === selectedNode)!;
        // 动态计算主题色，用于光晕效果 (从 tailwind class 提取颜色名，简化处理)
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

              {/* Left Identity Column - 科技感侧栏 */}
              <div className="relative md:w-2/5 p-10 flex flex-col justify-between overflow-hidden bg-gradient-to-br from-slate-50 to-white border-r border-slate-100">
                {/* 动态背景装饰 */}
                <div className="absolute inset-0 opacity-[0.03] pointer-events-none"
                  style={{ backgroundImage: 'radial-gradient(#64748b 1px, transparent 1px)', backgroundSize: '20px 20px' }}>
                </div>
                <div className={`absolute top-0 left-0 w-full h-1 bg-${themeColor}-500 shadow-[0_0_15px_rgba(var(--${themeColor}-500),0.5)]`}></div>

                {/* 动态扫描线 */}
                <div className={`absolute top-0 left-0 w-full h-20 bg-gradient-to-b from-transparent via-${themeColor}-500/10 to-transparent -translate-y-full animate-[scan_4s_ease-in-out_infinite] pointer-events-none`}></div>

                <div className="relative z-10">
                  <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-100 border border-slate-200 text-[10px] font-mono text-slate-500 mb-8 tracking-widest uppercase animate-in slide-in-from-left-4 fade-in duration-700">
                    ID: {String(detailNode.id).padStart(3, '0')} // SYSTEM_NODE
                  </div>

                  <div className="relative mb-8 group animate-in zoom-in-50 duration-700 delay-100 fill-mode-backwards">
                    <div className={`active-node-icon w-20 h-20 rounded-2xl bg-white border border-slate-200 flex items-center justify-center shadow-lg shadow-slate-200/50 group-hover:scale-105 transition-transform duration-500`}>
                      {React.cloneElement(detailNode.icon as React.ReactElement, { className: `w-10 h-10 text-${themeColor}-600` })}
                    </div>
                    {/* 呼吸光晕 */}
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
                </div>
              </div>

              {/* Right Content Column - 数据面板 */}
              <div className="flex-1 p-10 bg-white relative">
                {/* 顶部淡入光效 */}
                <div className={`absolute top-0 right-0 w-[300px] h-[300px] bg-${themeColor}-500/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 pointer-events-none animate-pulse duration-[5000ms]`}></div>

                <div className="space-y-10 relative z-10">

                  {/* Features Section */}
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

                  {/* Goals Section */}
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

                  {/* Tech Stack Section */}
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

      {/* 底部智能体矩阵展示 (仅在未选中时显示，防止遮挡) */}
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
    </div>
  );
};

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

const SimulatedAIChat = ({ scenario }: { scenario: { role: 'user' | 'ai'; content: string; extra?: React.ReactNode }[] }) => {
  const [messages, setMessages] = useState<{ role: 'user' | 'ai'; content: string; displayContent?: string; extra?: React.ReactNode }[]>([]);
  const [isThinking, setIsThinking] = useState(false);
  const [step, setStep] = useState(0);

  useEffect(() => {
    if (step < scenario.length) {
      const currentMsg = scenario[step];

      if (currentMsg.role === 'user') {
        const timer = setTimeout(() => {
          setMessages(prev => {
            if (prev.find(m => m.role === 'user' && m.content === currentMsg.content)) return prev;
            return [...prev, { ...currentMsg, displayContent: currentMsg.content }];
          });
          setStep(prev => prev + 1);
        }, 1000);
        return () => clearTimeout(timer);
      }

      if (currentMsg.role === 'ai') {
        const thinkingTimer = setTimeout(() => {
          setIsThinking(true);

          const responseTimer = setTimeout(() => {
            setIsThinking(false);

            setMessages(prev => [...prev, { ...currentMsg, displayContent: '' }]);

            let charIndex = 0;
            const fullText = currentMsg.content;

            const typingInterval = setInterval(() => {
              charIndex++;
              if (charIndex <= fullText.length) {
                setMessages(prev => {
                  const newMsgs = [...prev];
                  const lastIdx = newMsgs.length - 1;
                  if (newMsgs[lastIdx] && newMsgs[lastIdx].role === 'ai') {
                    newMsgs[lastIdx] = {
                      ...newMsgs[lastIdx],
                      displayContent: fullText.slice(0, charIndex)
                    };
                  }
                  return newMsgs;
                });
              } else {
                clearInterval(typingInterval);
                setStep(prev => prev + 1);
              }
            }, 30);
          }, 1500);

          return () => clearTimeout(responseTimer);
        }, 1000);
        return () => clearTimeout(thinkingTimer);
      }
    }
  }, [step, scenario]);


  return (
    <div className="w-full max-w-2xl bg-white rounded-3xl shadow-2xl border border-slate-100 overflow-hidden flex flex-col h-[500px]">
      <div className="bg-slate-50 px-6 py-4 border-b border-slate-100 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-indigo-600 rounded-full flex items-center justify-center text-white shadow-lg">
            <Bot className="w-6 h-6" />
          </div>
          <div>
            <div className="text-sm font-bold text-slate-800">URGS+ Ark Assistant</div>
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></span>
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Active Now</span>
            </div>
          </div>
        </div>
        <Zap className="w-5 h-5 text-amber-400" />
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6 bg-gradient-to-b from-white to-slate-50/30">
        {messages.map((msg, i) => (
          <div key={i} className={`flex items-start gap-3 ${msg.role === 'user' ? 'justify-end' : ''} anim-fade-up`}>
            {msg.role === 'ai' && (
              <div className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center shrink-0 border border-amber-200">
                <Bot className="w-4 h-4 text-amber-600" />
              </div>
            )}
            <div className={`p-4 rounded-2xl max-w-[85%] text-sm ${msg.role === 'user'
              ? 'bg-indigo-600 text-white rounded-tr-none shadow-indigo-100'
              : 'bg-white border border-slate-200 text-slate-700 rounded-tl-none shadow-sm'
              }`}>
              <div className="relative">
                {msg.displayContent}
                {msg.extra && msg.displayContent === msg.content && (
                  <div className="mt-4 animate-in fade-in slide-in-from-bottom-2 duration-500">
                    {msg.extra}
                  </div>
                )}
                {msg.role === 'ai' && i === messages.length - 1 && msg.displayContent !== msg.content && (
                  <span className="inline-block w-1.5 h-4 bg-indigo-400 ml-1 animate-pulse align-middle"></span>
                )}
              </div>
            </div>
            {msg.role === 'user' && (
              <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center shrink-0">
                <UserCircle2 className="w-5 h-5 text-slate-400" />
              </div>
            )}
          </div>
        ))}
        {isThinking && (
          <div className="flex items-start gap-3 anim-fade-up">
            <div className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center shrink-0 border border-amber-200">
              <Bot className="w-4 h-4 text-amber-600 animate-bounce" />
            </div>
            <div className="bg-white border border-slate-200 p-4 rounded-2xl rounded-tl-none shadow-sm space-x-1 flex">
              <div className="w-1.5 h-1.5 bg-slate-300 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
              <div className="w-1.5 h-1.5 bg-slate-400 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
              <div className="w-1.5 h-1.5 bg-slate-300 rounded-full animate-bounce"></div>
            </div>
          </div>
        )}
      </div>

      <div className="px-6 py-4 bg-white border-t border-slate-100">
        <div className="bg-slate-50 rounded-full px-5 py-2.5 flex items-center justify-between border border-slate-200">
          <span className="text-slate-400 text-sm">Ask URGS+ a question...</span>
          <div className="flex gap-2">
            <Terminal className="w-4 h-4 text-slate-300" />
            <Search className="w-4 h-4 text-slate-300" />
          </div>
        </div>
      </div>
    </div>
  );
};

export const AIExperiencePage = () => (
  <SlideLayout title="AI 原生问答体验" subtitle="自然语言驱动的监管资产探索">
    <div className="flex flex-col lg:flex-row items-center justify-center gap-12 w-full mt-4">
      <div className="flex-1 space-y-8 anim-fade-right delay-200 max-w-xl">
        <div className="space-y-4">
          <h4 className="text-3xl font-bold text-slate-800 leading-tight">
            像聊天一样<br />
            <span className="text-indigo-600">掌控监管合规</span>
          </h4>
          <p className="text-slate-500 text-lg leading-relaxed">
            无需编写 SQL，无需翻阅厚重的手册。通过 Ark Agent，直接对话生产环境元数据。
          </p>
        </div>

        <div className="grid grid-cols-1 gap-4">
          {[
            { title: "跨域知识检索", desc: "混合语义检索，打通监管规章与技术资产。", color: "text-amber-500" },
            { title: "自动代码解析", desc: "实时将 OLAP 逻辑降维展示。", color: "text-indigo-500" },
            { title: "预测性建议", desc: "根据历史数据，自动推送可能的操作风险点。", color: "text-teal-500" }
          ].map((item, i) => (
            <div key={i} className="flex gap-4 p-5 bg-white rounded-2xl border border-slate-100 shadow-sm hover:shadow-md transition-shadow">
              <div className={`shrink-0 w-1 p-0.5 rounded-full ${item.color.replace('text', 'bg')}`}></div>
              <div>
                <h5 className="font-bold text-slate-800 text-sm">{item.title}</h5>
                <p className="text-xs text-slate-500 mt-1">{item.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="flex-1 flex justify-center items-center anim-scale-in delay-500">
        <SimulatedAIChat scenario={[
          { role: 'user', content: 'URGS+，请分析 2024 年第四季度监管报表中的数据异常。' },
          { role: 'ai', content: '正在扫描 Q4 监管报送集群... 发现 G0102 报表与底层 A 类模型存在 3.2% 的金额偏差。可能原因：12月15日的 SQL 变更移除了部分抵押物过滤逻辑。建议回溯血缘图谱或运行 AI 发布审计。' }
        ]} />
      </div>
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
