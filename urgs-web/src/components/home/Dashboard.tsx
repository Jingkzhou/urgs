import React, { useEffect, useState } from 'react';
import { Activity, BriefcaseBusiness, Code2, LayoutDashboard } from 'lucide-react';
import { hasPermission } from '../../utils/permission';
import { DashboardViewDefinition, DashboardViewKey, dashboardViewDefinitions } from './dashboardViews';

const DASHBOARD_VIEW_STORAGE_KEY = 'urgs_dashboard_view';

const dashboardViewIcons: Record<DashboardViewKey, React.ReactNode> = {
  business: <BriefcaseBusiness size={14} strokeWidth={2.5} />,
  dev: <Code2 size={14} strokeWidth={2.5} />,
  ops: <Activity size={14} strokeWidth={2.5} />,
};

const getStoredDashboardView = (): DashboardViewKey | null => {
  if (typeof window === 'undefined') return null;
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

  const handleSelectView = (view: DashboardViewDefinition) => {
    setSelectedViewKey(view.key);
    if (typeof window !== 'undefined') {
      window.localStorage.setItem(DASHBOARD_VIEW_STORAGE_KEY, view.key);
    }
  };

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
    <div className="space-y-6">
      {allowedViews.length > 1 && (
        <div className="flex justify-end">
          <div className="inline-flex flex-wrap items-center gap-1 rounded-2xl border border-slate-200/70 bg-white/80 p-1 shadow-sm">
            {allowedViews.map(view => {
              const isActive = activeView.key === view.key;
              return (
                <button
                  key={view.key}
                  type="button"
                  onClick={() => handleSelectView(view)}
                  className={`flex items-center gap-2 rounded-xl px-3 py-2 text-xs font-black transition-all ${
                    isActive
                      ? 'bg-red-50 text-red-600 shadow-sm'
                      : 'text-slate-500 hover:bg-slate-100 hover:text-slate-800'
                  }`}
                >
                  {dashboardViewIcons[view.key]}
                  <span>{view.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      )}

      <ActiveDashboardView />
    </div>
  );
};

export default Dashboard;
