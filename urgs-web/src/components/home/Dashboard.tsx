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

      {/* 1. 运营概览 (System Jump Zone, Stats & Notices) */}
      <section className="animate-fade-in-up">
        {/* Header */}
        <div className="flex items-center gap-4 mb-6 px-2">
          <div className="h-8 w-1.5 bg-red-500 rounded-full shadow-[0_0_10px_rgba(239,68,68,0.5)]"></div>
          <div>
            <h2 className="text-2xl font-black text-slate-800 tracking-tight italic uppercase">运营概览</h2>
            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em] mt-0.5">Operational Overview</p>
          </div>
        </div>
        
        {/* Glass Container */}
        <div className="bg-white/40 backdrop-blur-2xl border border-white/60 p-6 md:p-8 rounded-[2.5rem] shadow-[0_20px_50px_-12px_rgba(0,0,0,0.05)] space-y-8 relative overflow-hidden group/opt">
          {/* Decorative Bloom */}
          <div className="absolute -top-40 -right-40 w-96 h-96 bg-red-100/40 rounded-full blur-[100px] pointer-events-none group-hover/opt:bg-red-200/40 transition-colors duration-1000"></div>
          
          <Auth code="dash:systems">
             <div className="relative z-10"><SystemLinks /></div>
          </Auth>

          <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 relative z-10">
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
        </div>
      </section>

      {/* 2. 研发态势 (Developer Workbench) */}
      <section className="animate-fade-in-up" style={{ animationDelay: '100ms' }}>
        {/* Header */}
        <div className="flex items-center gap-4 mb-6 px-2">
          <div className="h-8 w-1.5 bg-indigo-500 rounded-full shadow-[0_0_10px_rgba(99,102,241,0.5)]"></div>
          <div>
            <h2 className="text-2xl font-black text-slate-800 tracking-tight italic uppercase">重点业务概览</h2>
            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em] mt-0.5">Key Operations & Modules</p>
          </div>
        </div>

        {/* Glass Container */}
        <div className="bg-white/40 backdrop-blur-2xl border border-white/60 p-6 md:p-8 rounded-[2.5rem] shadow-[0_20px_50px_-12px_rgba(0,0,0,0.05)] relative overflow-hidden group/dev">
          <div className="absolute -bottom-40 -left-40 w-96 h-96 bg-indigo-100/40 rounded-full blur-[100px] pointer-events-none group-hover/dev:bg-indigo-200/40 transition-colors duration-1000"></div>

          <Auth code="dash:dev">
            <div className="relative z-10 -m-4 xl:-m-0"><DevWorkbench /></div>
          </Auth>
        </div>
      </section>

      {/* 3. 批处理监控 (Batch Process Monitoring) */}
      <section className="animate-fade-in-up" style={{ animationDelay: '200ms' }}>
        {/* Header */}
        <div className="flex items-center gap-4 mb-6 px-2">
          <div className="h-8 w-1.5 bg-emerald-500 rounded-full shadow-[0_0_10px_rgba(16,185,129,0.5)]"></div>
          <div>
            <h2 className="text-2xl font-black text-slate-800 tracking-tight italic uppercase">批处理监控</h2>
            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-[0.2em] mt-0.5">Batch Monitoring</p>
          </div>
        </div>

        {/* Glass Container */}
        <div className="bg-white/40 backdrop-blur-2xl border border-white/60 p-6 md:p-8 rounded-[2.5rem] shadow-[0_20px_50px_-12px_rgba(0,0,0,0.05)] relative overflow-hidden group/batch">
           <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[400px] bg-emerald-50/40 rounded-full blur-[120px] pointer-events-none group-hover/batch:bg-emerald-100/40 transition-colors duration-1000"></div>
          
           <Auth code="dash:Batch-monitoring">
             <div className="relative z-10"><BatchMonitoring /></div>
           </Auth>
        </div>
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