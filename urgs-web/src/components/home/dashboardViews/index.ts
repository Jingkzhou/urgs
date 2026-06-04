import type { ComponentType } from 'react';
import BusinessDashboardView from './BusinessDashboardView';
import DevDashboardView from './DevDashboardView';
import OpsDashboardView from './OpsDashboardView';

export type DashboardViewKey = 'business' | 'dev' | 'ops';

export interface DashboardViewDefinition {
  key: DashboardViewKey;
  label: string;
  permission: string;
  component: ComponentType;
}

export const dashboardViewDefinitions: DashboardViewDefinition[] = [
  {
    key: 'business',
    label: '业务首页',
    permission: 'dash:view:business',
    component: BusinessDashboardView,
  },
  {
    key: 'dev',
    label: '研发首页',
    permission: 'dash:view:dev',
    component: DevDashboardView,
  },
  {
    key: 'ops',
    label: '运维首页',
    permission: 'dash:view:ops',
    component: OpsDashboardView,
  },
];
