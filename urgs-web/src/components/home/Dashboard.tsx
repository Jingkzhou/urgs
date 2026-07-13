import React, { useEffect, useState } from 'react';
import { LayoutDashboard } from 'lucide-react';
import { hasPermission } from '../../utils/permission';
import { DashboardViewKey, dashboardViewDefinitions } from './dashboardViews';

const DASHBOARD_VIEW_STORAGE_KEY = 'urgs_dashboard_view';

const getStoredDashboardView = (): DashboardViewKey | null => {
  if (typeof window === 'undefined') return null;
  const viewFromHash = new URLSearchParams(window.location.hash.split('?')[1] || '').get('view');
  if (dashboardViewDefinitions.some(view => view.key === viewFromHash)) return viewFromHash as DashboardViewKey;
  const stored = window.localStorage.getItem(DASHBOARD_VIEW_STORAGE_KEY);
  return dashboardViewDefinitions.some(view => view.key === stored) ? stored as DashboardViewKey : null;
};

const Dashboard: React.FC = () => {
  const [selectedViewKey, setSelectedViewKey] = useState<DashboardViewKey | null>(getStoredDashboardView);
  const allowedViews = dashboardViewDefinitions.filter(view => hasPermission(view.permission));
  const activeView = allowedViews.find(view => view.key === selectedViewKey) || allowedViews[0];

  useEffect(() => {
    if (!activeView) return;
    if (selectedViewKey !== activeView.key) {
      setSelectedViewKey(activeView.key);
    }
  }, [activeView, selectedViewKey]);

  useEffect(() => {
    const syncSelectedView = () => setSelectedViewKey(getStoredDashboardView());
    window.addEventListener('hashchange', syncSelectedView);
    return () => window.removeEventListener('hashchange', syncSelectedView);
  }, []);

  if (!activeView) {
    return (
      <div className="flex min-h-[420px] items-center justify-center">
        <div className="max-w-md rounded-[2rem] border border-slate-200/70 bg-white/80 p-8 text-center shadow-[0_24px_60px_-36px_rgba(15,23,42,0.4)]">
          <div className="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-100 text-slate-400">
            <LayoutDashboard size={24} strokeWidth={2.5} />
          </div>
          <h2 className="text-lg font-black tracking-tight text-slate-800">暂无首页视图权限</h2>
          <p className="mt-2 text-sm font-medium leading-6 text-slate-500">
            请在角色管理中授予业务首页、研发首页或运维首页权限。
          </p>
        </div>
      </div>
    );
  }

  const ActiveDashboardView = activeView.component;

  return (
    <ActiveDashboardView />
  );
};

export default Dashboard;
