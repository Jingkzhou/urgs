import React from 'react';
import DashboardViewLayout, { DashboardSectionKey } from './DashboardViewLayout';

const businessDashboardSections: DashboardSectionKey[] = [
  'overview',
  'trend',
  'batchMonitoring',
  'devWorkbench',
];

const BusinessDashboardView: React.FC = () => {
  return <DashboardViewLayout sections={businessDashboardSections} />;
};

export default BusinessDashboardView;
