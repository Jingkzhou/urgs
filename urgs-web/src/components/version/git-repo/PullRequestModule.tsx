import React, { useState, useEffect } from 'react';
import { useBreadcrumbs } from '../../../context/BreadcrumbContext';
import PullRequestList from './PullRequestList';
import PullRequestDetail from './PullRequestDetail';
import CreatePullRequest from './CreatePullRequest';

interface PullRequestModuleProps {
    repoId: number;
    ssoId: number; // pass ssoId if needed for context
    repoName?: string;
    onBack: () => void;
    onBackToRepoList?: () => void;
}

const PullRequestModule: React.FC<PullRequestModuleProps> = ({ repoId, ssoId, repoName, onBack, onBackToRepoList }) => {
    const [view, setView] = useState<'list' | 'detail' | 'create'>('list');
    const [selectedPRId, setSelectedPRId] = useState<number | null>(null);

    const { setBreadcrumbs } = useBreadcrumbs();

    useEffect(() => {
        const crumbs = [
            { id: 'root', label: '版本管理中心' },
            { id: 'list', label: '仓库管理', onClick: onBackToRepoList },
            { id: 'repo', label: repoName || 'Repository', onClick: onBack },
            { id: 'pr-list', label: 'Pull Request', onClick: () => handleBackToList() }
        ];

        if (view === 'create') {
            crumbs.push({ id: 'pr-create', label: '新建' });
        } else if (view === 'detail' && selectedPRId) {
            crumbs.push({ id: 'pr-detail', label: `PR #${selectedPRId}` });
        }

        setBreadcrumbs(crumbs);
    }, [view, selectedPRId, repoName, onBack, onBackToRepoList]);

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
