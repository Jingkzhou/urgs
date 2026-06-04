import React from 'react';
import DashboardViewLayout, { DashboardSectionKey } from './DashboardViewLayout';

const opsDashboardSections: DashboardSectionKey[] = [
  'overview',
  'trend',
  'batchMonitoring',
  'devWorkbench',
];

const OpsDashboardView: React.FC = () => {
  return <DashboardViewLayout sections={opsDashboardSections} />;
};

export default OpsDashboardView;
