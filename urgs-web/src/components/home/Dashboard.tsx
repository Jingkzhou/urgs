import React, { useState, useEffect } from 'react';
import SystemLinks from './SystemLinks';
import { BatchStatusChart, TrendAnalysisChart } from './StatsSection';
import Notices from './Notices';
import Auth from '../Auth';
import { hasPermission } from '../../utils/permission';
import BatchMonitoring from './BatchMonitoring';
import DevWorkbench from './DevWorkbench';
import { fetchBatchStatusStats, TaskStatsVO } from '../../api/stats';

const Dashboard: React.FC = () => {
  const [batchData, setBatchData] = useState<TaskStatsVO[]>([]);
  const [loadingBatch, setLoadingBatch] = useState(false);

  const loadBatchData = async () => {
    setLoadingBatch(true);
    try {
      const data = await fetchBatchStatusStats();
      setBatchData(data);
    } catch (err) {
      console.error('Failed to fetch stats in dashboard', err);
    } finally {
      setLoadingBatch(false);
    }
  };

  useEffect(() => {
    loadBatchData();
  }, []);

  return (
    <div className="space-y-12 pb-12 pt-4">

      {/* Main Bento Grid Hub */}
      {(hasPermission('dash:notice:view') || hasPermission('dash:stats') || hasPermission('dash:systems')) && (
        <section className="animate-fade-in-up">
          <div className="grid grid-cols-1 xl:grid-cols-12 gap-8 relative z-10 items-start">

            {/* Left Side: Information & Operations (Stacked) */}
            {(hasPermission('dash:notice:view') || hasPermission('dash:stats')) && (
              <div className={`grid grid-cols-1 gap-8 ${hasPermission('dash:systems') ? 'xl:col-span-8' : 'xl:col-span-12'}`}>
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

            {/* Right Side: Navigation Launchpad (Tall) */}
            {hasPermission('dash:systems') && (
              <div className={`h-full ${(hasPermission('dash:notice:view') || hasPermission('dash:stats')) ? 'xl:col-span-4' : 'xl:col-span-12'}`}>
                <div className="relative h-full transform transition-transform duration-500 hover:-translate-y-1" style={{ animationDelay: '200ms' }}>
                  <SystemLinks fullWidth={!(hasPermission('dash:notice:view') || hasPermission('dash:stats'))} />
                </div>
              </div>
            )}
          </div>
        </section>
      )}

      {/* Full Width Trends */}
      <Auth code="dash:stats">
        <section className="animate-fade-in-up" style={{ animationDelay: '300ms' }}>
          <div className="relative z-10 w-full group">
            <div className="absolute -inset-1 bg-gradient-to-r from-red-500/5 to-amber-500/5 rounded-[2.5rem] blur-2xl opacity-0 group-hover:opacity-100 transition duration-1000"></div>
            <TrendAnalysisChart />
          </div>
        </section>
      </Auth>

      {/* Detailed Batch Monitoring */}
      <Auth code="dash:Batch-monitoring">
        <section className="animate-fade-in-up" style={{ animationDelay: '400ms' }}>
          <div className="relative z-10">
            <BatchMonitoring />
          </div>
        </section>
      </Auth>

      {/* Workbench Section */}
      <Auth code="dash:dev">
        <section className="animate-fade-in-up" style={{ animationDelay: '500ms' }}>
          <div className="relative z-10">
            <DevWorkbench />
          </div>
        </section>
      </Auth>

      {/* Minimal Footer */}
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

export default Dashboard;