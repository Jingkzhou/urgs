import React from 'react';
import SystemLinks from './SystemLinks';
import StatsSection from './StatsSection';
import Notices from './Notices';
import Auth from '../Auth';
import BatchMonitoring from './BatchMonitoring';
import DevWorkbench from './DevWorkbench';

const Dashboard: React.FC = () => {
  return (
    <div className="space-y-10 pb-12 pt-4">

      {/* 1. 运营核心区 (System Jump Zone, Stats & Notices) */}
      <section className="animate-fade-in-up space-y-12">
        <Auth code="dash:systems">
          <div className="relative z-10">
            <SystemLinks />
          </div>
        </Auth>

        <div className="grid grid-cols-1 xl:grid-cols-3 gap-8 relative z-10">
          <div className="xl:col-span-2">
            <Auth code="dash:stats">
              <StatsSection />
            </Auth>
          </div>
          <div className="xl:col-span-1 h-[400px] xl:h-auto">
            <Auth code="dash:notice:view">
              <Notices />
            </Auth>
          </div>
        </div>
      </section>

      {/* 2. 业务态势区 (Developer Workbench) */}
      <section className="animate-fade-in-up" style={{ animationDelay: '100ms' }}>
        <Auth code="dash:dev">
          <div className="relative z-10">
            <DevWorkbench />
          </div>
        </Auth>
      </section>

      {/* 3. 任务监控区 (Batch Process Monitoring) */}
      <section className="animate-fade-in-up" style={{ animationDelay: '200ms' }}>
        <Auth code="dash:Batch-monitoring">
          <div className="relative z-10">
            <BatchMonitoring />
          </div>
        </Auth>
      </section>

      {/* Footer */}
      <footer className="text-center text-slate-400 text-sm py-10 relative mt-10">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-64 h-px bg-gradient-to-r from-transparent via-slate-300 to-transparent"></div>
        <p className="font-bold tracking-tight">金融监管统一门户系统 V2.4.0</p>
        <p className="text-xs uppercase tracking-widest mt-1 opacity-60 font-black">Copyright © Bank of Jilin</p>
      </footer>

    </div>
  );
};

export default Dashboard;