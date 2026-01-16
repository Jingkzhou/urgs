import React from 'react';
import SystemLinks from './SystemLinks';
import StatsSection from './StatsSection';
import Notices from './Notices';
import Auth from '../Auth';
import BatchMonitoring from './BatchMonitoring';
import DevWorkbench from './DevWorkbench';

const Dashboard: React.FC = () => {
  return (
    <div className="space-y-6">
      {/* 1. System Jump Zone */}
      <section className="animate-fade-in-up">
        <Auth code="dash:systems">
          <SystemLinks />
        </Auth>
      </section>

      {/* 1.5 Developer Workbench */}
      <section className="animate-fade-in-up" style={{ animationDelay: '50ms' }}>
        <Auth code="dash:dev">
          <DevWorkbench />
        </Auth>
      </section>

      {/* 2. Stats & Notices Grid */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 animate-fade-in-up" style={{ animationDelay: '100ms' }}>
        {/* Stats take up 2 columns on large screens */}
        <div className="xl:col-span-2">
          <Auth code="dash:stats">
            <StatsSection />
          </Auth>
        </div>

        {/* Notices take up 1 column */}
        <div className="xl:col-span-1 h-[400px] xl:h-auto">
          <Auth code="dash:notice:view">
            <Notices />
          </Auth>
        </div>
      </div>

      {/* 3. Batch Process Monitoring */}
      <section className="animate-fade-in-up" style={{ animationDelay: '200ms' }}>
        <Auth code="dash:Batch-monitoring">
          <BatchMonitoring />
        </Auth>
      </section>

      {/* Footer */}
      <footer className="text-center text-slate-400 text-sm py-8">
        <p>吉林银行金融监管统一门户系统 V2.4.0 | Copyright © Bank of Jilin</p>
      </footer>

    </div>
  );
};

export default Dashboard;