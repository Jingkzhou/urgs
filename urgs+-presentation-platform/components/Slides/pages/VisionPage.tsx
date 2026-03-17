import React from 'react';
import { AgentEcosystemFlow } from './AgentEcosystemFlow';

interface VisionPageProps {
    onNavigate?: (index: number) => void;
}

export const VisionPage = ({ onNavigate }: VisionPageProps) => (
    <div className="relative w-screen h-screen overflow-hidden">
        <AgentEcosystemFlow onNavigate={onNavigate} />
    </div>
);
