import React from 'react';
import DashboardViewLayout, { DashboardSectionKey } from './DashboardViewLayout';

const opsDashboardSections: DashboardSectionKey[] = [
  'batchMonitoring',
  'overview',
];

const OpsDashboardView: React.FC = () => {
  return (
    <DashboardViewLayout
      sections={opsDashboardSections}
      overviewSlots={['notice', 'systems']}
      overviewLayout="compact"
      batchMonitoringDensity="compact"
      sectionGap="compact"
      fitViewport
      showFooter={false}
    />
  );
};

export default OpsDashboardView;
