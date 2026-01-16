import React from 'react';
import LineagePage from '../LineagePage';

interface LineageOriginPageProps {
    mode?: 'trace' | 'impact';
}

const LineageOriginPage: React.FC<LineageOriginPageProps> = ({ mode = 'trace' }) => {
    return <LineagePage mode={mode} />;
};

export default LineageOriginPage;
