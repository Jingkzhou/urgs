import React, { useState, useEffect, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ShieldCheck,
  Cpu,
  Layout,
  ArrowUpRight,
  Sparkles,
  Monitor,
  ChevronRight,
  ChevronLeft
} from 'lucide-react';
import { getSystemList, jumpSystem } from '@/api/ops';

interface SystemLinksProps {
  fullWidth?: boolean;
  compact?: boolean;
  showStatusFooter?: boolean;
}

const SystemLinks: React.FC<SystemLinksProps> = ({
  fullWidth = false,
  compact = false,
  showStatusFooter = true,
}) => {
  const [systems, setSystems] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(0);
  const [columnsPerRow, setColumnsPerRow] = useState(6);
  const gridRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchSystems();
  }, []);

  // 全宽模式下动态计算每行能放多少列
  const updateColumns = useCallback(() => {
    if (!fullWidth || !gridRef.current) return;
    const containerWidth = gridRef.current.offsetWidth;
    const cardWidth = compact ? 120 : 160;
    const maxColumns = compact ? 6 : 8;
    const cols = Math.max(3, Math.min(maxColumns, Math.floor((containerWidth + 16) / (cardWidth + 16))));
    setColumnsPerRow(cols);
  }, [compact, fullWidth]);

  useEffect(() => {
    if (!fullWidth) return;
    updateColumns();
    const observer = new ResizeObserver(updateColumns);
    if (gridRef.current) observer.observe(gridRef.current);
    return () => observer.disconnect();
  }, [fullWidth, updateColumns]);

  // 翻页时重置到有效范围
  useEffect(() => {
    if (fullWidth && systems.length > 0) {
      const totalPages = Math.ceil(systems.length / columnsPerRow);
      if (currentPage >= totalPages) setCurrentPage(totalPages - 1);
    }
  }, [columnsPerRow, systems.length, fullWidth, currentPage]);

  const fetchSystems = async () => {
    setLoading(true);
    try {
      const data = await getSystemList();
      setSystems(data || []);
    } catch (err) {
      console.error('Failed to fetch systems', err);
    } finally {
      setLoading(false);
    }
  };

  const getSystemIcon = (name: string) => {
    if (name.includes('RAG')) return <Cpu className="w-5 h-5" />;
    if (name.includes('血缘')) return <Sparkles className="w-5 h-5" />;
    if (name.includes('仓库')) return <Layout className="w-5 h-5" />;
    if (name.includes('监管')) return <ShieldCheck className="w-5 h-5" />;
    return <Monitor className="w-5 h-5" />;
  };

  const getSystemColor = (index: number) => {
    const colors = [
      'from-rose-500 to-red-600',
      'from-indigo-500 to-blue-600',
      'from-emerald-500 to-teal-600',
      'from-amber-500 to-orange-600',
      'from-violet-500 to-purple-600'
    ];
    return colors[index % colors.length];
  };

  const handleSystemClick = async (system: any) => {
    if (!system?.id) {
      alert('系统配置缺少 ID，无法跳转');
      return;
    }
    if (!system.callbackUrl) {
      alert(`${system.name || '该系统'} 未配置回调地址，无法单点跳转`);
      return;
    }

    const jumpWindow = window.open('about:blank', '_blank');
    try {
      const result = await jumpSystem(system.id);
      if (!result?.targetUrl) {
        jumpWindow?.close();
        alert('跳转接口未返回目标地址');
        return;
      }

      if (jumpWindow) {
        jumpWindow.location.href = result.targetUrl;
      } else {
        window.location.href = result.targetUrl;
      }
    } catch (err: any) {
      jumpWindow?.close();
      alert(err?.message || '系统跳转失败');
      console.error('Failed to jump system', err);
    }
  };

  if (loading) {
    return (
      <div className="bg-white/70 backdrop-blur-md rounded-2xl shadow-[0_25px_50px_-12px_rgba(0,0,0,0.08)] border border-slate-200/50 flex flex-col h-[600px] overflow-hidden p-6 gap-4">
        <div className="h-8 bg-slate-100 rounded w-1/3 animate-pulse"></div>
        <div className="grid grid-cols-2 gap-4">
          {[1, 2, 3, 4, 5, 6].map(i => (
            <div key={i} className="aspect-square bg-slate-100 rounded-3xl animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  // 全宽分页逻辑
  const totalPages = fullWidth ? Math.ceil(systems.length / columnsPerRow) : 1;
  const visibleSystems = fullWidth
    ? systems.slice(currentPage * columnsPerRow, (currentPage + 1) * columnsPerRow)
    : systems;

  // 渲染单个系统卡片
  const renderCard = (system: any, idx: number, originalIndex: number) => (
    <motion.div
      key={system.id || originalIndex}
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay: idx * 0.05, type: 'spring', stiffness: 200 }}
      whileHover={{ scale: 1.05, y: -5 }}
      whileTap={{ scale: 0.95 }}
      className={`relative cursor-pointer ${fullWidth ? '' : 'aspect-square'}`}
      onClick={() => handleSystemClick(system)}
    >
      <div className={`${fullWidth ? '' : 'absolute inset-0'} bg-white border border-slate-200/60 ${compact ? 'rounded-2xl' : 'rounded-[1.75rem]'} shadow-[0_4px_12px_-4px_rgba(0,0,0,0.05)] overflow-hidden transition-all duration-500 group-hover:border-slate-300`}>
        <div className={`absolute -inset-px opacity-0 hover:opacity-10 transition-opacity bg-gradient-to-br ${getSystemColor(originalIndex)}`} />
        <div className={`w-full flex flex-col items-center justify-center relative z-10 ${fullWidth ? (compact ? 'py-4 px-2' : 'py-6 px-3') : 'h-full p-3'}`}>
          <div className={`${compact ? 'w-9 h-9 rounded-xl mb-2' : 'w-11 h-11 rounded-2xl mb-3'} bg-gradient-to-br ${getSystemColor(originalIndex)} flex items-center justify-center text-white shadow-lg shadow-inherit/20 transform transition-transform duration-500 group-hover:rotate-12 group-hover:scale-110`}>
            {getSystemIcon(system.name)}
          </div>
          <span className="text-[11px] font-black text-slate-700 tracking-tight text-center leading-tight">
            {system.name}
          </span>
          <span className="text-[8px] text-slate-400 font-bold tracking-widest uppercase mt-1.5 opacity-60">
            {system.code || 'SVC'}
          </span>
        </div>
        <div className="absolute bottom-2 right-2 opacity-0 hover:opacity-100 transition-opacity">
          <ArrowUpRight className="w-3 h-3 text-slate-300" />
        </div>
      </div>
    </motion.div>
  );

  const containerHeightClass = compact ? 'h-[260px]' : (fullWidth ? 'h-auto' : 'h-[600px]');

  return (
    <div className={`relative bg-white/70 backdrop-blur-md ${compact ? 'pt-5 pb-5 px-5 rounded-[1.75rem]' : 'pt-7 pb-8 px-6 rounded-[2rem]'} shadow-[0_25px_50px_-12px_rgba(0,0,0,0.08)] border border-slate-200/50 overflow-hidden flex flex-col group transition-all duration-700 hover:shadow-[0_45px_90px_-20px_rgba(0,0,0,0.15)] ${containerHeightClass}`}>
      {/* Abstract Background Decoration */}
      <div className="absolute -top-24 -right-24 w-64 h-64 bg-red-500/5 rounded-full blur-3xl pointer-events-none group-hover:bg-red-500/10 transition-colors duration-1000" />

      {/* Header Area */}
      <div className={`flex items-center justify-between ${compact ? 'mb-4' : 'mb-8'} relative z-10`}>
        <div>
          <h2 className={`${compact ? 'text-lg' : 'text-xl'} font-black text-slate-800 tracking-tight flex items-center gap-2`}>
            系统入口
            <div className="flex items-center justify-center w-5 h-5 bg-red-50 rounded-md border border-red-100">
              <div className="w-1.5 h-1.5 bg-red-500 rounded-full animate-pulse" />
            </div>
          </h2>
          <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em] mt-1.5">Launchpad Matrix</p>
        </div>

        <div className="flex items-center gap-2">
          {/* 全宽模式下的翻页控件 */}
          {fullWidth && totalPages > 1 && (
            <div className="flex items-center gap-1.5">
              <button
                onClick={() => setCurrentPage(p => Math.max(0, p - 1))}
                disabled={currentPage === 0}
                className="p-2 rounded-xl transition-all border border-slate-200/50 disabled:opacity-30 disabled:cursor-not-allowed bg-slate-100/50 hover:bg-slate-200/50 text-slate-500 hover:text-slate-800"
              >
                <ChevronLeft size={14} />
              </button>
              <span className="text-[11px] font-bold text-slate-400 tabular-nums min-w-[3rem] text-center">
                {currentPage + 1} / {totalPages}
              </span>
              <button
                onClick={() => setCurrentPage(p => Math.min(totalPages - 1, p + 1))}
                disabled={currentPage === totalPages - 1}
                className="p-2 rounded-xl transition-all border border-slate-200/50 disabled:opacity-30 disabled:cursor-not-allowed bg-slate-100/50 hover:bg-slate-200/50 text-slate-500 hover:text-slate-800"
              >
                <ChevronRight size={14} />
              </button>
            </div>
          )}

        </div>
      </div>

      {/* Grid Content */}
      <div ref={gridRef} className={`relative z-10 ${fullWidth ? '' : 'flex-1 overflow-y-auto custom-scrollbar pr-1'}`}>
        {fullWidth ? (
          /* 全宽模式：单行 + 翻页 */
          <AnimatePresence mode="wait">
            <motion.div
              key={currentPage}
              initial={{ opacity: 0, x: 30 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -30 }}
              transition={{ duration: 0.25 }}
              className="grid gap-4"
              style={{ gridTemplateColumns: `repeat(${columnsPerRow}, minmax(0, 1fr))` }}
            >
              {visibleSystems.map((system, idx) => renderCard(system, idx, currentPage * columnsPerRow + idx))}
            </motion.div>
          </AnimatePresence>
        ) : (
          /* 窄列模式：原始滚动网格 */
          <div className="grid grid-cols-2 gap-4 pb-4">
            {systems.map((system, idx) => renderCard(system, idx, idx))}
          </div>
        )}
      </div>

      {showStatusFooter && (
        <div className={`${compact ? 'mt-3 pt-3' : 'mt-4 pt-5'} border-t border-slate-100/80 flex items-center justify-between text-slate-400 relative z-10`}>
          <div className="flex flex-col gap-0.5">
            <span className="text-xl font-black text-slate-800 leading-none">{systems.length}</span>
            <span className="text-[8px] font-bold uppercase tracking-widest text-slate-400">Total Units</span>
          </div>
          <div className="flex flex-col items-end gap-0.5">
            <div className="flex items-center gap-1.5 text-emerald-500">
              <div className="w-1.5 h-1.5 bg-emerald-500 rounded-full shadow-[0_0_8px_rgba(16,185,129,0.5)]" />
              <span className="text-[10px] font-black leading-none">Healthy</span>
            </div>
            <span className="text-[8px] font-bold uppercase tracking-widest text-slate-400">Active Node</span>
          </div>
        </div>
      )}
    </div>
  );
};

export default SystemLinks;
