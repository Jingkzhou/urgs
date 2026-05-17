import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { Activity, BarChart3, ChevronDown, RefreshCw, TrendingUp } from 'lucide-react';
import {
  fetchMetricSystems,
  fetchMetricTrend,
  fetchMetricTypes,
  MetricChartType,
  MetricTrendVO,
  MetricTypeVO,
} from '../../api/metrics';
import MetricChartRenderer, { MetricChartPoint } from './MetricChartRenderer';

const chartTypeLabels: Record<MetricChartType, string> = {
  area: '面积图',
  line: '折线图',
  bar: '柱状图',
  pie: '饼状图',
};

function formatNumber(val: number): string {
  if (val >= 10000) return (val / 10000).toFixed(1) + 'w';
  if (val >= 1000) return (val / 1000).toFixed(1) + 'k';
  return val.toFixed(val % 1 === 0 ? 0 : 2);
}

function normalizeChartType(value?: string): MetricChartType {
  return ['area', 'line', 'bar', 'pie'].includes(value || '') ? (value as MetricChartType) : 'area';
}

const TrendAnalysisChart: React.FC = () => {
  const [systems, setSystems] = useState<{ clientId: string; name: string }[]>([]);
  const [selectedSystemId, setSelectedSystemId] = useState<string>('');
  const [metricTypes, setMetricTypes] = useState<MetricTypeVO[]>([]);
  const [selectedTypeCode, setSelectedTypeCode] = useState<string>('');
  const [trendData, setTrendData] = useState<MetricTrendVO[]>([]);
  const [startDate, setStartDate] = useState<string>(`${new Date().getFullYear()}-01-01`);
  const [endDate, setEndDate] = useState<string>(`${new Date().getFullYear()}-12-31`);
  const [loading, setLoading] = useState(false);
  const [systemDropdownOpen, setSystemDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const refreshTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const currentMetric = useMemo(
    () => metricTypes.find((m) => m.typeCode === selectedTypeCode),
    [metricTypes, selectedTypeCode]
  );

  const chartColor = currentMetric?.color || '#ef4444';
  const configuredChartType = normalizeChartType(currentMetric?.defaultChartType);

  const stats = useMemo(() => {
    if (trendData.length === 0) return null;
    const values = trendData.map((d) => d.avgValue);
    const maxVal = Math.max(...trendData.map((d) => d.maxValue));
    const minVal = Math.min(...trendData.map((d) => d.minValue));
    const avg = values.reduce((a, b) => a + b, 0) / values.length;
    const latest = values[values.length - 1];
    const prev = values.length > 1 ? values[values.length - 2] : latest;
    const changePercent = prev !== 0 ? ((latest - prev) / prev) * 100 : 0;
    return { maxVal, minVal, avg, latest, changePercent };
  }, [trendData]);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setSystemDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  useEffect(() => {
    const loadSystems = async () => {
      try {
        const list = await fetchMetricSystems();
        if (!list || list.length === 0) return;
        setSystems(list);
        setSelectedSystemId(list[0].clientId);
      } catch (err) {
        console.error('Failed to load systems for metrics', err);
      }
    };
    loadSystems();
  }, []);

  useEffect(() => {
    if (!selectedSystemId) return;
    const loadTypes = async () => {
      const types = await fetchMetricTypes(selectedSystemId);
      setMetricTypes(types);
      if (types.length > 0) {
        setSelectedTypeCode(types[0].typeCode);
      } else {
        setSelectedTypeCode('');
        setTrendData([]);
      }
    };
    loadTypes();
  }, [selectedSystemId]);

  const loadTrend = useCallback(async () => {
    if (!selectedSystemId || !selectedTypeCode) return;
    setLoading(true);
    try {
      const data = await fetchMetricTrend({
        systemId: selectedSystemId,
        typeCode: selectedTypeCode,
        startTime: startDate,
        endTime: endDate,
        granularity: 'MONTH',
      });
      setTrendData(data);
    } catch (err) {
      console.error('Failed to load trend data', err);
    } finally {
      setTimeout(() => setLoading(false), 300);
    }
  }, [selectedSystemId, selectedTypeCode, startDate, endDate]);

  useEffect(() => {
    loadTrend();
  }, [loadTrend]);

  useEffect(() => {
    refreshTimerRef.current = setInterval(loadTrend, 60000);
    return () => {
      if (refreshTimerRef.current) clearInterval(refreshTimerRef.current);
    };
  }, [loadTrend]);

  const selectedSystemName = systems.find((s) => s.clientId === selectedSystemId)?.name || '';

  const chartData: MetricChartPoint[] = useMemo(
    () =>
      trendData.map((d) => ({
        name: d.timeLabel,
        value: d.avgValue,
        max: d.maxValue,
        min: d.minValue,
      })),
    [trendData]
  );

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const row = payload[0].payload;
      return (
        <motion.div
          initial={{ opacity: 0, scale: 0.9, y: 10 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          className="bg-slate-900/90 backdrop-blur-xl border border-white/10 p-4 rounded-2xl shadow-2xl"
        >
          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3 border-b border-white/5 pb-2">
            {label || row.name}
          </p>
          <div className="space-y-2">
            <div className="flex items-center justify-between gap-8">
              <span className="text-[11px] text-slate-300 font-bold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full shadow-[0_0_8px]" style={{ backgroundColor: chartColor }} />
                {currentMetric?.typeName || '均值'}
              </span>
              <span className="text-sm font-black text-white">
                {formatNumber(payload[0].value)} {currentMetric?.unit || ''}
              </span>
            </div>
            <div className="flex items-center justify-between gap-8">
              <span className="text-[11px] text-slate-300 font-bold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-amber-500 shadow-[0_0_8px_rgba(245,158,11,0.8)]" />
                MAX
              </span>
              <span className="text-sm font-black text-white">
                {formatNumber(row.max)} {currentMetric?.unit || ''}
              </span>
            </div>
            <div className="flex items-center justify-between gap-8">
              <span className="text-[11px] text-slate-300 font-bold flex items-center gap-2">
                <div className="w-1.5 h-1.5 rounded-full bg-sky-400 shadow-[0_0_8px_rgba(56,189,248,0.8)]" />
                MIN
              </span>
              <span className="text-sm font-black text-white">
                {formatNumber(row.min)} {currentMetric?.unit || ''}
              </span>
            </div>
          </div>
        </motion.div>
      );
    }
    return null;
  };

  const gradientId = `metric-gradient-${selectedSystemId}-${selectedTypeCode || 'default'}`;
  const glowId = `metric-glow-${selectedSystemId}-${selectedTypeCode || 'default'}`;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.8, ease: 'easeOut' }}
      className="relative bg-white/80 backdrop-blur-xl border border-slate-200/60 rounded-[3rem] shadow-[0_32px_64px_-16px_rgba(0,0,0,0.08)] flex flex-col group transition-all duration-700 hover:shadow-[0_48px_96px_-24px_rgba(0,0,0,0.12)] hover:-translate-y-1 min-h-[480px] h-full"
    >
      <div className="absolute -top-24 -right-24 w-64 h-64 rounded-full blur-[80px] transition-colors duration-1000 pointer-events-none" style={{ backgroundColor: `${chartColor}08` }} />

      <div className="flex flex-col xl:flex-row xl:items-center xl:justify-between gap-5 px-9 pt-8 pb-4 relative z-50">
        <div className="flex items-center gap-6">
          <div className="relative">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
              className="absolute -inset-2 rounded-full blur-md opacity-0 group-hover:opacity-100 transition-opacity duration-1000"
              style={{ background: `linear-gradient(to right, ${chartColor}33, transparent, #f59e0b33)` }}
            />
            <div className="relative p-3.5 bg-slate-900 rounded-2xl shadow-2xl shadow-slate-900/20 overflow-hidden group-hover:scale-110 transition-transform duration-500">
              <TrendingUp className="w-5 h-5 text-white" />
              <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-tr from-white/10 to-transparent" />
            </div>
          </div>
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight leading-none mb-2.5">指标走势</h2>
            <div className="flex items-center gap-3">
              <span className="px-2 py-0.5 text-[9px] font-black rounded-md border uppercase tracking-widest" style={{ backgroundColor: `${chartColor}10`, color: chartColor, borderColor: `${chartColor}30` }}>
                Live Flow
              </span>
              <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em] flex items-center gap-2">
                <Activity className="w-3 h-3 text-slate-300" />
                Metrics Monitor
              </p>
            </div>
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-end gap-4">
          {stats && (
            <div className="flex flex-col items-end">
              <div className="flex items-baseline gap-1.5">
                <span className="text-3xl font-black text-slate-900 leading-none tabular-nums">
                  {formatNumber(stats.latest)}
                </span>
                {stats.changePercent !== 0 && (
                  <span className={`text-xs font-black flex items-center gap-0.5 ${stats.changePercent > 0 ? 'text-emerald-500' : 'text-red-500'}`}>
                    <TrendingUp size={12} className={stats.changePercent < 0 ? 'rotate-180' : ''} />
                    {Math.abs(stats.changePercent).toFixed(1)}%
                  </span>
                )}
              </div>
              <span className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] mt-2">
                {currentMetric?.typeName || 'Latest'} {currentMetric?.unit ? `(${currentMetric.unit})` : ''}
              </span>
            </div>
          )}

          {systems.length > 0 && (
            <div className="relative" ref={dropdownRef}>
              <button
                onClick={() => setSystemDropdownOpen(!systemDropdownOpen)}
                className="flex items-center gap-2.5 px-5 py-2.5 bg-slate-50 border border-slate-200/80 rounded-2xl hover:border-slate-300 transition-all duration-300 group/sys"
              >
                <div className="relative">
                  <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: chartColor }} />
                  <div className="absolute inset-0 w-2.5 h-2.5 rounded-full animate-ping scale-150 opacity-40" style={{ backgroundColor: chartColor }} />
                </div>
                <span className="text-xs font-black text-slate-800 max-w-[100px] truncate">{selectedSystemName}</span>
                <ChevronDown size={14} className={`text-slate-400 transition-transform duration-300 ${systemDropdownOpen ? 'rotate-180' : ''}`} />
              </button>

              <AnimatePresence>
                {systemDropdownOpen && (
                  <motion.div
                    initial={{ opacity: 0, y: -8, scale: 0.96 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: -8, scale: 0.96 }}
                    transition={{ duration: 0.2 }}
                    className="absolute right-0 top-full mt-2 bg-white/95 backdrop-blur-xl border border-slate-200 rounded-2xl shadow-2xl py-2 min-w-[180px] max-h-[320px] overflow-y-auto z-50"
                  >
                    {systems.map((sys) => (
                      <button
                        key={sys.clientId}
                        onClick={() => {
                          setSelectedSystemId(sys.clientId);
                          setSystemDropdownOpen(false);
                        }}
                        className={`w-full text-left px-4 py-2.5 text-xs font-bold transition-colors ${
                          sys.clientId === selectedSystemId
                            ? 'bg-slate-100 text-slate-900'
                            : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                        }`}
                      >
                        <div className="flex items-center gap-2.5">
                          {sys.clientId === selectedSystemId && (
                            <div className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: chartColor }} />
                          )}
                          <span className={sys.clientId === selectedSystemId ? '' : 'ml-4'}>{sys.name}</span>
                        </div>
                      </button>
                    ))}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          )}

          <button
            onClick={loadTrend}
            disabled={loading}
            className="p-2.5 bg-slate-100/50 hover:bg-slate-200/50 rounded-2xl border border-slate-200/50 transition-all duration-300 disabled:opacity-50"
          >
            <RefreshCw size={14} className={`text-slate-500 hover:text-slate-800 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 px-9 pb-4 relative z-10">
        <div className="flex items-center gap-2 overflow-x-auto scrollbar-hide">
          {metricTypes.length > 0 ? (
            metricTypes.map((mt) => (
              <button
                key={mt.typeCode}
                onClick={() => setSelectedTypeCode(mt.typeCode)}
                className={`relative flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-[11px] font-black tracking-wide whitespace-nowrap transition-all duration-300 border ${
                  mt.typeCode === selectedTypeCode
                    ? 'text-white shadow-lg'
                    : 'bg-white/60 text-slate-600 border-slate-200/60 hover:border-slate-300'
                }`}
                style={
                  mt.typeCode === selectedTypeCode
                    ? { backgroundColor: mt.color || '#ef4444', borderColor: mt.color || '#ef4444', boxShadow: `0 4px 14px ${mt.color || '#ef4444'}40` }
                    : {}
                }
              >
                <div
                  className={`w-1.5 h-1.5 rounded-full ${mt.typeCode === selectedTypeCode ? 'bg-white/60' : ''}`}
                  style={mt.typeCode !== selectedTypeCode ? { backgroundColor: mt.color || '#94a3b8' } : {}}
                />
                {mt.typeName}
              </button>
            ))
          ) : (
            <span className="text-[11px] text-slate-400 font-medium">暂无指标类型</span>
          )}
        </div>

        <div className="flex flex-wrap items-center gap-3 shrink-0">
          <div className="px-3 py-2 rounded-xl bg-slate-100/60 border border-slate-200/40 text-[11px] font-black text-slate-500">
            {chartTypeLabels[configuredChartType]}
          </div>
          <div className="flex items-center gap-2 bg-slate-100/60 rounded-xl p-1 border border-slate-200/40">
            <input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="px-2 py-1 text-[11px] font-black text-slate-600 bg-transparent border-none outline-none cursor-pointer"
            />
            <span className="text-slate-400 text-[10px] font-black">-</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="px-2 py-1 text-[11px] font-black text-slate-600 bg-transparent border-none outline-none cursor-pointer"
            />
          </div>
        </div>
      </div>

      <div className="flex-1 w-full px-4 pb-6 relative z-10 overflow-hidden min-h-[240px]">
        <AnimatePresence mode="wait">
          {loading ? (
            <motion.div
              key="loading"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="flex items-center justify-center h-full"
            >
              <RefreshCw className="w-8 h-8 text-slate-200 animate-spin" />
            </motion.div>
          ) : chartData.length === 0 ? (
            <motion.div
              key="empty"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="flex flex-col items-center justify-center h-full gap-4 opacity-60"
            >
              <div className="relative">
                <div className="w-16 h-16 rounded-full bg-slate-100/50 flex items-center justify-center relative z-10 shadow-sm border border-white">
                  <BarChart3 className="w-6 h-6 text-slate-400" />
                </div>
                <div className="absolute inset-0 bg-slate-200 rounded-full animate-ping opacity-20" />
              </div>
              <div className="text-center">
                <p className="text-sm font-black text-slate-500 tracking-wide">暂无指标数据</p>
                <p className="text-[10px] font-bold text-slate-400 mt-1 uppercase tracking-widest">No Metrics Available</p>
              </div>
            </motion.div>
          ) : (
            <motion.div
              key={`chart-${selectedTypeCode}-${configuredChartType}-${startDate}-${endDate}`}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.4 }}
              className="w-full h-[320px]"
            >
              <MetricChartRenderer
                data={chartData}
                chartType={configuredChartType}
                color={chartColor}
                gradientId={gradientId}
                glowId={glowId}
                tooltip={<CustomTooltip />}
              />
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div className="px-9 py-5 border-t border-slate-50 bg-slate-50/30 flex items-center justify-between">
        {stats ? (
          <div className="flex gap-8">
            <div className="flex flex-col">
              <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">
                {currentMetric?.typeName || ''} MAX
              </span>
              <span className="text-xs font-bold text-slate-700">
                {formatNumber(stats.maxVal)} {currentMetric?.unit || ''}
              </span>
            </div>
            <div className="flex flex-col">
              <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">AVG</span>
              <span className="text-xs font-bold text-slate-700">
                {formatNumber(stats.avg)} {currentMetric?.unit || ''}
              </span>
            </div>
            <div className="flex flex-col">
              <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1">MIN</span>
              <span className="text-xs font-bold text-slate-700">
                {formatNumber(stats.minVal)} {currentMetric?.unit || ''}
              </span>
            </div>
          </div>
        ) : (
          <div className="text-[10px] text-slate-400 font-bold">--</div>
        )}
        <div className="flex items-center gap-3">
          <div className="w-1.5 h-1.5 rounded-full animate-pulse" style={{ backgroundColor: chartColor }} />
          <span className="text-[10px] font-black text-slate-500">
            {selectedSystemName} {currentMetric?.typeName ? `/ ${currentMetric.typeName}` : ''}
          </span>
        </div>
      </div>
    </motion.div>
  );
};

export default TrendAnalysisChart;
