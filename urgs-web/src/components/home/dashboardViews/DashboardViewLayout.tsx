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

interface DashboardViewLayoutProps {
  sections: DashboardSectionKey[];
}

const DashboardViewLayout: React.FC<DashboardViewLayoutProps> = ({ sections }) => {
  const [batchData, setBatchData] = useState<TaskStatsVO[]>([]);
  const [loadingBatch, setLoadingBatch] = useState(false);
  const canViewNotice = hasPermission('dash:notice:view');
  const canViewStats = hasPermission('dash:stats');
  const canViewSystems = hasPermission('dash:systems');
  const hasOverviewSection = sections.includes('overview');

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

  useSmartPolling(loadBatchData, 30000, { enabled: hasOverviewSection && canViewStats });

  const renderOverviewSection = () => {
    if (!canViewNotice && !canViewStats && !canViewSystems) return null;

    return (
      <section key="overview" className="animate-fade-in-up">
        <div className="grid grid-cols-1 xl:grid-cols-12 gap-8 relative z-10 items-start">
          {(canViewNotice || canViewStats) && (
            <div className={`grid grid-cols-1 gap-8 ${canViewSystems ? 'xl:col-span-8' : 'xl:col-span-12'}`}>
              <Auth code="dash:notice:view">
                <div className="relative transform transition-transform duration-500 hover:-translate-y-1">
                  <Notices />
                </div>
              </Auth>

              <Auth code="dash:stats">
                <div className="relative transform transition-transform duration-500 hover:-translate-y-1" style={{ animationDelay: '100ms' }}>
                  <BatchStatusChart data={batchData} loading={loadingBatch} onRefresh={loadBatchData} />
                </div>
              </Auth>
            </div>
          )}

          {canViewSystems && (
            <div className={`h-full ${(canViewNotice || canViewStats) ? 'xl:col-span-4' : 'xl:col-span-12'}`}>
              <div className="relative h-full transform transition-transform duration-500 hover:-translate-y-1" style={{ animationDelay: '200ms' }}>
                <SystemLinks fullWidth={!(canViewNotice || canViewStats)} />
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
              <BatchMonitoring />
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

  return (
    <div className="space-y-12 pb-12 pt-4">
      {sections.map(renderSection)}

      <footer className="text-center text-slate-400 text-[10px] py-16 relative mt-16">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-48 h-px bg-gradient-to-r from-transparent via-slate-200 to-transparent"></div>
        <div className="flex flex-col items-center gap-2 opacity-40">
          <p className="font-black tracking-[0.2em] uppercase">Financial Portal V2.4.0</p>
          <p className="font-medium tracking-tight">Copyright © 2026 Bank of Jilin. High Performance Cloud Infrastructure.</p>
        </div>
      </footer>
    </div>
  );
};

export default DashboardViewLayout;
