import React from 'react';
import DashboardViewLayout, { DashboardSectionKey } from './DashboardViewLayout';

const devDashboardSections: DashboardSectionKey[] = [
  'overview',
  'trend',
  'batchMonitoring',
  'devWorkbench',
];

const DevDashboardView: React.FC = () => {
  return <DashboardViewLayout sections={devDashboardSections} />;
};

export default DevDashboardView;
