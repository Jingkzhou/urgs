import React, { useState } from 'react';
import PullRequestList from './PullRequestList';
import PullRequestDetail from './PullRequestDetail';
import CreatePullRequest from './CreatePullRequest';

interface PullRequestModuleProps {
    repoId: number;
    ssoId: number; // pass ssoId if needed for context
    onBack: () => void;
}

const PullRequestModule: React.FC<PullRequestModuleProps> = ({ repoId, ssoId, onBack }) => {
    const [view, setView] = useState<'list' | 'detail' | 'create'>('list');
    const [selectedPRId, setSelectedPRId] = useState<number | null>(null);

    const handleCreateClick = () => {
        setView('create');
    };

    const handlePRClick = (prId: number) => {
        setSelectedPRId(prId);
        setView('detail');
    };

    const handleBackToList = () => {
        setView('list');
        setSelectedPRId(null);
    };

    if (view === 'create') {
        return (
            <CreatePullRequest
                repoId={repoId}
                onCancel={handleBackToList}
                onSuccess={(newPRId) => {
                    // In a real app, reload list or navigate to new PR
                    handleBackToList(); // or navigate to detail
                }}
            />
        );
    }

    if (view === 'detail' && selectedPRId) {
        return (
            <PullRequestDetail
                repoId={repoId}
                prId={selectedPRId}
                onBack={handleBackToList}
            />
        );
    }

    return (
        <PullRequestList
            repoId={repoId}
            onBack={onBack}
            onCreateClick={handleCreateClick}
            onPRClick={handlePRClick}
        />
    );
};

export default PullRequestModule;
