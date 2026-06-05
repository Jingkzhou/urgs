import React, { useCallback, useState } from 'react';
import SystemLinks from '../SystemLinks';
import { BatchStatusChart, TrendAnalysisChart } from '../StatsSection';
import Notices from '../Notices';
import Auth from '../../Auth';
import { hasPermission } from '../../../utils/permission';
import BatchMonitoring from '../BatchMonitoring';
import DevWorkbench from '../DevWorkbench';
import { fetchBatchStatusStats, TaskStatsVO } from '../../../api/stats';
import { useSmartPolling } from '../../../hooks/useSmartPolling';

export type DashboardSectionKey = 'overview' | 'trend' | 'batchMonitoring' | 'devWorkbench';
export type DashboardOverviewSlotKey = 'notice' | 'batchStatus' | 'systems';
export type DashboardOverviewLayout = 'default' | 'compact';
export type DashboardSectionGap = 'default' | 'compact';

interface DashboardViewLayoutProps {
  sections: DashboardSectionKey[];
  overviewSlots?: DashboardOverviewSlotKey[];
  overviewLayout?: DashboardOverviewLayout;
  batchMonitoringDensity?: 'default' | 'compact';
  sectionGap?: DashboardSectionGap;
  fitViewport?: boolean;
  showFooter?: boolean;
}

const defaultOverviewSlots: DashboardOverviewSlotKey[] = ['notice', 'batchStatus', 'systems'];

const DashboardViewLayout: React.FC<DashboardViewLayoutProps> = ({
  sections,
  overviewSlots = defaultOverviewSlots,
  overviewLayout = 'default',
  batchMonitoringDensity = 'default',
  sectionGap = 'default',
  fitViewport = false,
  showFooter = true,
}) => {
  const [batchData, setBatchData] = useState<TaskStatsVO[]>([]);
  const [loadingBatch, setLoadingBatch] = useState(false);
  const hasOverviewSection = sections.includes('overview');
  const canViewNotice = overviewSlots.includes('notice') && hasPermission('dash:notice:view');
  const canViewBatchStatus = overviewSlots.includes('batchStatus') && hasPermission('dash:stats');
  const canViewSystems = overviewSlots.includes('systems') && hasPermission('dash:systems');

  const loadBatchData = useCallback(async () => {
    setLoadingBatch(true);
    try {
      const data = await fetchBatchStatusStats();
      setBatchData(data);
    } catch (err) {
      console.error('Failed to fetch stats in dashboard', err);
    } finally {
      setLoadingBatch(false);
    }
  }, []);

  useSmartPolling(loadBatchData, 30000, { enabled: hasOverviewSection && canViewBatchStatus });

  const renderOverviewSection = () => {
    if (!canViewNotice && !canViewBatchStatus && !canViewSystems) return null;

    const isCompactOverview = overviewLayout === 'compact';
    const overviewGridClass = isCompactOverview
      ? 'grid grid-cols-1 xl:grid-cols-5 gap-6 relative z-10 items-stretch'
      : 'grid grid-cols-1 xl:grid-cols-12 gap-8 relative z-10 items-start';
    const contentColumnClass = isCompactOverview
      ? `${canViewSystems ? 'xl:col-span-3' : 'xl:col-span-5'} grid grid-cols-1 gap-6`
      : `grid grid-cols-1 gap-8 ${canViewSystems ? 'xl:col-span-8' : 'xl:col-span-12'}`;
    const systemsColumnClass = isCompactOverview
      ? `${(canViewNotice || canViewBatchStatus) ? 'xl:col-span-2' : 'xl:col-span-5'} min-w-0`
      : `h-full ${(canViewNotice || canViewBatchStatus) ? 'xl:col-span-4' : 'xl:col-span-12'}`;
    const systemsFullWidth = isCompactOverview || !(canViewNotice || canViewBatchStatus);

    return (
      <section key="overview" className="animate-fade-in-up">
        <div className={overviewGridClass}>
          {(canViewNotice || canViewBatchStatus) && (
            <div className={contentColumnClass}>
              {overviewSlots.includes('notice') && (
                <Auth code="dash:notice:view">
                  <div className="relative transform transition-transform duration-500 hover:-translate-y-1">
                    <Notices />
                  </div>
                </Auth>
              )}

              {overviewSlots.includes('batchStatus') && (
                <Auth code="dash:stats">
                  <div className="relative transform transition-transform duration-500 hover:-translate-y-1" style={{ animationDelay: '100ms' }}>
                    <BatchStatusChart data={batchData} loading={loadingBatch} onRefresh={loadBatchData} />
                  </div>
                </Auth>
              )}
            </div>
          )}

          {canViewSystems && (
            <div className={systemsColumnClass}>
              <div className="relative h-full transform transition-transform duration-500 hover:-translate-y-1" style={{ animationDelay: '200ms' }}>
                <SystemLinks
                  fullWidth={systemsFullWidth}
                  compact={isCompactOverview}
                  showStatusFooter={!isCompactOverview}
                />
              </div>
            </div>
          )}
        </div>
      </section>
    );
  };

  const renderSection = (section: DashboardSectionKey, index: number) => {
    const animationDelay = `${300 + index * 100}ms`;

    if (section === 'overview') {
      return renderOverviewSection();
    }

    if (section === 'trend') {
      return (
        <Auth key="trend" code="dash:stats">
          <section className="animate-fade-in-up" style={{ animationDelay }}>
            <div className="relative z-10 w-full group">
              <div className="absolute -inset-1 bg-gradient-to-r from-red-500/5 to-amber-500/5 rounded-[2.5rem] blur-2xl opacity-0 group-hover:opacity-100 transition duration-1000"></div>
              <TrendAnalysisChart />
            </div>
          </section>
        </Auth>
      );
    }

    if (section === 'batchMonitoring') {
      return (
        <Auth key="batchMonitoring" code="dash:Batch-monitoring">
          <section className="animate-fade-in-up" style={{ animationDelay }}>
            <div className="relative z-10">
              <BatchMonitoring density={batchMonitoringDensity} />
            </div>
          </section>
        </Auth>
      );
    }

    return (
      <Auth key="devWorkbench" code="dash:dev">
        <section className="animate-fade-in-up" style={{ animationDelay }}>
          <div className="relative z-10">
            <DevWorkbench />
          </div>
        </section>
      </Auth>
    );
  };

  const rootSpacingClass = sectionGap === 'compact' ? 'space-y-4' : 'space-y-12';
  const rootViewportClass = fitViewport ? 'h-full min-h-0 overflow-hidden pb-0 pt-0' : 'pb-12 pt-4';

  return (
    <div className={`${rootSpacingClass} ${rootViewportClass}`}>
      {sections.map(renderSection)}

      {showFooter && (
        <footer className="text-center text-slate-400 text-[10px] py-16 relative mt-16">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-48 h-px bg-gradient-to-r from-transparent via-slate-200 to-transparent"></div>
          <div className="flex flex-col items-center gap-2 opacity-40">
            <p className="font-black tracking-[0.2em] uppercase">Financial Portal V2.4.0</p>
            <p className="font-medium tracking-tight">Copyright © 2026 Bank of Jilin. High Performance Cloud Infrastructure.</p>
          </div>
        </footer>
      )}
    </div>
  );
};

export default DashboardViewLayout;
