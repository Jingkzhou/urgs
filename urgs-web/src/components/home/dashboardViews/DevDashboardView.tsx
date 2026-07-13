import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { motion } from 'framer-motion';
import {
  ArrowUpRight,
  BarChart3,
  Boxes,
  CircleAlert,
  ClipboardCheck,
  Code2,
  Database,
  GitBranch,
  History,
  LayoutGrid,
  ListTodo,
  RefreshCw,
  Search,
  ShieldCheck,
  Table2,
} from 'lucide-react';
import { getOverviewStats, getVersionOverview } from '../../../api/version';
import {
  getWorkStatistics,
  listAssetMaintenanceRecords,
  listModelAssetTables,
  listRegAssetTables,
  WorkStatistics,
} from '../../../api/marketplace';
import { hasPermission } from '../../../utils/permission';

interface VersionSnapshot {
  totalApps: number;
  totalRepos: number;
  pendingReleases: number;
  thisMonthReleases: number;
}

interface AssetSnapshot {
  regulatoryTables: number;
  modelTables: number;
  maintenanceRecords: number;
}

interface QuickEntry {
  label: string;
  description: string;
  hash: string;
  permission: string;
  icon: React.ElementType;
  tone: string;
}

const getMonthRange = () => {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const format = (date: Date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };
  return { startDate: format(start), endDate: format(now) };
};

const quickEntries: QuickEntry[] = [
  { label: '版本概览', description: '应用与发布全景', hash: '#/version', permission: 'version', icon: LayoutGrid, tone: 'bg-indigo-50 text-indigo-600' },
  { label: '仓库管理', description: '代码仓库与分支', hash: '#/version?tab=repos', permission: 'version:repo:list', icon: GitBranch, tone: 'bg-violet-50 text-violet-600' },
  { label: '发布统计', description: '研发绩效与趋势', hash: '#/version?tab=stats', permission: 'version:stats', icon: BarChart3, tone: 'bg-blue-50 text-blue-600' },
  { label: '任务大厅', description: '查看与认领任务', hash: '#/marketplace?tab=market', permission: 'marketplace:market', icon: ListTodo, tone: 'bg-amber-50 text-amber-600' },
  { label: '个人看板', description: '我的任务与进度', hash: '#/marketplace?tab=mine', permission: 'marketplace:mine', icon: ClipboardCheck, tone: 'bg-orange-50 text-orange-600' },
  { label: 'KPI 看板', description: '积分与交付表现', hash: '#/marketplace?tab=stats', permission: 'marketplace:stats', icon: BarChart3, tone: 'bg-rose-50 text-rose-600' },
  { label: '数据资产', description: '监管资产目录', hash: '#/metadata?subtab=asset', permission: 'metadata:asset', icon: Database, tone: 'bg-emerald-50 text-emerald-600' },
  { label: '物理模型', description: '表结构与元数据', hash: '#/metadata?subtab=model', permission: 'metadata:model', icon: Table2, tone: 'bg-teal-50 text-teal-600' },
  { label: '数据查询', description: '快速检索与验证', hash: '#/metadata?subtab=query', permission: 'metadata:query', icon: Search, tone: 'bg-cyan-50 text-cyan-600' },
];

const DevDashboardView: React.FC = () => {
  const [version, setVersion] = useState<VersionSnapshot>({ totalApps: 0, totalRepos: 0, pendingReleases: 0, thisMonthReleases: 0 });
  const [work, setWork] = useState<WorkStatistics | null>(null);
  const [assets, setAssets] = useState<AssetSnapshot>({ regulatoryTables: 0, modelTables: 0, maintenanceRecords: 0 });
  const [loading, setLoading] = useState(true);

  const canViewVersion = hasPermission('version');
  const canViewMarketplace = hasPermission('marketplace');
  const canViewMetadata = hasPermission('metadata');
  const visibleEntries = useMemo(() => quickEntries.filter(entry => hasPermission(entry.permission)), []);

  const loadData = useCallback(async () => {
    setLoading(true);
    const monthRange = getMonthRange();
    const [versionOverviewResult, versionStatsResult, workResult, regulatoryResult, modelResult, maintenanceResult] = await Promise.allSettled([
      canViewVersion ? getVersionOverview() : Promise.resolve(null),
      canViewVersion ? getOverviewStats() : Promise.resolve(null),
      canViewMarketplace ? getWorkStatistics(monthRange) : Promise.resolve(null),
      canViewMetadata ? listRegAssetTables({ page: 1, size: 1 }) : Promise.resolve(null),
      canViewMetadata ? listModelAssetTables({ page: 1, size: 1 }) : Promise.resolve(null),
      canViewMetadata ? listAssetMaintenanceRecords({ page: 1, size: 1 }) : Promise.resolve(null),
    ]);

    const versionOverview = versionOverviewResult.status === 'fulfilled' ? versionOverviewResult.value : null;
    const versionStats = versionStatsResult.status === 'fulfilled' ? versionStatsResult.value : null;
    const workStats = workResult.status === 'fulfilled' ? workResult.value : null;
    const regulatoryTables = regulatoryResult.status === 'fulfilled' ? regulatoryResult.value : null;
    const modelTables = modelResult.status === 'fulfilled' ? modelResult.value : null;
    const maintenanceRecords = maintenanceResult.status === 'fulfilled' ? maintenanceResult.value : null;

    setVersion({
      totalApps: Number(versionOverview?.totalApps || versionStats?.totalApps || 0),
      totalRepos: Number(versionOverview?.totalRepos || 0),
      pendingReleases: Number(versionStats?.pendingReleases || 0),
      thisMonthReleases: Number(versionStats?.thisMonthReleases || 0),
    });
    setWork(workStats);
    setAssets({
      regulatoryTables: Number(regulatoryTables?.total || 0),
      modelTables: Number(modelTables?.total || 0),
      maintenanceRecords: Number(maintenanceRecords?.total || 0),
    });
    setLoading(false);
  }, [canViewMarketplace, canViewMetadata, canViewVersion]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const domainCount = [canViewVersion, canViewMarketplace, canViewMetadata].filter(Boolean).length;
  const attentionItems = [
    { label: '待发布版本', value: version.pendingReleases, tone: 'text-indigo-600 bg-indigo-50', visible: canViewVersion },
    { label: '逾期任务', value: work?.overdueTasks || 0, tone: 'text-red-600 bg-red-50', visible: canViewMarketplace },
    { label: '风险任务', value: work?.riskTasks || 0, tone: 'text-amber-600 bg-amber-50', visible: canViewMarketplace },
    { label: '资产维护记录', value: assets.maintenanceRecords, tone: 'text-emerald-600 bg-emerald-50', visible: canViewMetadata },
  ].filter(item => item.visible);

  const navigate = (hash: string) => {
    window.location.hash = hash;
  };

  return (
    <div className="-mt-2 space-y-4 pb-10">
      <section className="relative overflow-hidden rounded-[2rem] border border-slate-200/70 bg-white/80 px-6 py-5 shadow-[0_18px_50px_-28px_rgba(15,23,42,0.3)] backdrop-blur-xl">
        <div className="pointer-events-none absolute -right-20 -top-24 h-64 w-64 rounded-full bg-indigo-500/5 blur-3xl" />
        <div className="relative flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-4">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-indigo-500 to-violet-600 text-white shadow-lg shadow-indigo-500/20">
              <Code2 className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-xl font-black tracking-tight text-slate-800">研发工作台</h1>
              <p className="mt-1 text-xs font-medium text-slate-500">版本交付、研发任务与数据资产统一入口</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-[11px] font-bold text-slate-500">已连接 {domainCount} 个研发域</span>
            <button type="button" onClick={loadData} disabled={loading} className="flex h-9 w-9 items-center justify-center rounded-xl border border-slate-200 bg-white text-slate-500 transition hover:border-indigo-200 hover:text-indigo-600 disabled:opacity-50" aria-label="刷新研发首页数据">
              <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
      </section>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        {canViewVersion && (
          <DomainCard title="版本交付" subtitle="Version Delivery" icon={GitBranch} tone="indigo" onClick={() => navigate('#/version')} metrics={[
            { label: '应用系统', value: version.totalApps },
            { label: '代码仓库', value: version.totalRepos },
            { label: '本月发布', value: version.thisMonthReleases },
          ]} loading={loading} />
        )}
        {canViewMarketplace && (
          <DomainCard title="任务中心" subtitle="Delivery Tasks" icon={ListTodo} tone="amber" onClick={() => navigate('#/marketplace')} metrics={[
            { label: '本月工作', value: work?.totalWorks || 0 },
            { label: '进行任务', value: work?.activeTasks || 0 },
            { label: '完成率', value: `${work?.completionRate || 0}%` },
          ]} loading={loading} />
        )}
        {canViewMetadata && (
          <DomainCard title="数据资产" subtitle="Data Assets" icon={Database} tone="emerald" onClick={() => navigate('#/metadata?subtab=asset')} metrics={[
            { label: '监管表', value: assets.regulatoryTables },
            { label: '物理模型', value: assets.modelTables },
            { label: '维护记录', value: assets.maintenanceRecords },
          ]} loading={loading} />
        )}
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-12">
        <section className="rounded-[2rem] border border-slate-200/70 bg-white/80 p-5 shadow-[0_18px_45px_-30px_rgba(15,23,42,0.25)] xl:col-span-8">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h2 className="text-base font-black text-slate-800">快捷入口</h2>
              <p className="mt-1 text-[10px] font-bold uppercase tracking-[0.16em] text-slate-400">Developer Shortcuts</p>
            </div>
            <span className="text-[11px] font-bold text-slate-400">{visibleEntries.length} 项可用</span>
          </div>
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 lg:grid-cols-3">
            {visibleEntries.map(entry => {
              const Icon = entry.icon;
              return (
                <button key={entry.label} type="button" onClick={() => navigate(entry.hash)} className="group flex items-center gap-3 rounded-2xl border border-slate-100 bg-slate-50/60 p-3 text-left transition-all hover:-translate-y-0.5 hover:border-slate-200 hover:bg-white hover:shadow-md">
                  <span className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${entry.tone}`}><Icon className="h-4.5 w-4.5" /></span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-sm font-black text-slate-700">{entry.label}</span>
                    <span className="mt-0.5 block truncate text-[10px] font-medium text-slate-400">{entry.description}</span>
                  </span>
                  <ArrowUpRight className="h-4 w-4 text-slate-300 transition-colors group-hover:text-indigo-500" />
                </button>
              );
            })}
          </div>
        </section>

        <section className="rounded-[2rem] border border-slate-200/70 bg-white/80 p-5 shadow-[0_18px_45px_-30px_rgba(15,23,42,0.25)] xl:col-span-4">
          <div className="mb-4 flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-slate-100 text-slate-600"><CircleAlert className="h-4 w-4" /></div>
            <div>
              <h2 className="text-base font-black text-slate-800">近期关注</h2>
              <p className="mt-0.5 text-[10px] font-bold uppercase tracking-[0.16em] text-slate-400">Attention</p>
            </div>
          </div>
          <div className="space-y-2">
            {attentionItems.map(item => (
              <div key={item.label} className="flex items-center justify-between rounded-xl border border-slate-100 bg-slate-50/60 px-3 py-2.5">
                <span className="text-xs font-bold text-slate-500">{item.label}</span>
                <span className={`min-w-9 rounded-lg px-2 py-1 text-center text-xs font-black tabular-nums ${item.tone}`}>{loading ? '-' : item.value}</span>
              </div>
            ))}
            {!loading && attentionItems.every(item => item.value === 0) && (
              <div className="flex items-center gap-2 rounded-xl border border-emerald-100 bg-emerald-50 px-3 py-2.5 text-xs font-bold text-emerald-600">
                <ShieldCheck className="h-4 w-4" />当前没有需要立即处理的事项
              </div>
            )}
          </div>
        </section>
      </div>
    </div>
  );
};

interface DomainCardProps {
  title: string;
  subtitle: string;
  icon: React.ElementType;
  tone: 'indigo' | 'amber' | 'emerald';
  metrics: Array<{ label: string; value: number | string }>;
  loading: boolean;
  onClick: () => void;
}

const DomainCard: React.FC<DomainCardProps> = ({ title, subtitle, icon: Icon, tone, metrics, loading, onClick }) => {
  const tones = {
    indigo: { icon: 'bg-indigo-50 text-indigo-600', line: 'from-indigo-500 to-violet-400' },
    amber: { icon: 'bg-amber-50 text-amber-600', line: 'from-amber-500 to-orange-400' },
    emerald: { icon: 'bg-emerald-50 text-emerald-600', line: 'from-emerald-500 to-teal-400' },
  };
  const currentTone = tones[tone];

  return (
    <motion.button initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} type="button" onClick={onClick} className="group relative overflow-hidden rounded-[2rem] border border-slate-200/70 bg-white/80 p-5 text-left shadow-[0_18px_45px_-30px_rgba(15,23,42,0.25)] transition hover:-translate-y-0.5 hover:shadow-lg">
      <div className={`absolute inset-x-0 top-0 h-1 bg-gradient-to-r ${currentTone.line}`} />
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <span className={`flex h-10 w-10 items-center justify-center rounded-xl ${currentTone.icon}`}><Icon className="h-5 w-5" /></span>
          <div><h2 className="text-base font-black text-slate-800">{title}</h2><p className="mt-0.5 text-[9px] font-bold uppercase tracking-[0.16em] text-slate-400">{subtitle}</p></div>
        </div>
        <ArrowUpRight className="h-4 w-4 text-slate-300 transition-colors group-hover:text-slate-600" />
      </div>
      <div className="mt-5 grid grid-cols-3 divide-x divide-slate-100">
        {metrics.map(metric => (
          <div key={metric.label} className="px-3 first:pl-0 last:pr-0">
            <span className="block text-xl font-black tracking-tight text-slate-800 tabular-nums">{loading ? '-' : metric.value}</span>
            <span className="mt-1 block text-[10px] font-bold text-slate-400">{metric.label}</span>
          </div>
        ))}
      </div>
    </motion.button>
  );
};

export default DevDashboardView;
