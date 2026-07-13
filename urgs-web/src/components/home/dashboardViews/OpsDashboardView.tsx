import React from 'react';
import DashboardViewLayout, { DashboardSectionKey } from './DashboardViewLayout';
import OpsWelcomeCard from './OpsWelcomeCard';

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
      showFooter={false}
      batchMonitoringLeadingContent={<OpsWelcomeCard />}
    />
  );
};

export default OpsDashboardView;
