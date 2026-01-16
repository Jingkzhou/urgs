import React from 'react';
import LineagePage from '../LineagePage';

interface LineageAnalysisPageProps {
    mode?: 'trace' | 'impact';
}

const LineageAnalysisPage: React.FC<LineageAnalysisPageProps> = ({ mode = 'impact' }) => {
    return <LineagePage mode={mode} />;
};

export default LineageAnalysisPage;
