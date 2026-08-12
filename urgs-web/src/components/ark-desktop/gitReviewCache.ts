import type { GrokGitBranch, GrokGitDiff, GrokGitStatus } from '@/services/grokDesktop';

export interface WorkspaceReviewCache {
    status?: GrokGitStatus;
    statusSignature?: string;
    selectedPath?: string;
    diffs: Map<string, GrokGitDiff>;
    updatedAt?: number;
    branches?: GrokGitBranch[];
    branchesUpdatedAt?: number;
    commitMessage?: string;
}

const MAX_WORKSPACE_CACHE_ENTRIES = 12;
const workspaceCaches = new Map<string, WorkspaceReviewCache>();

export const normalizeGitWorkspaceKey = (value: string) => {
    let normalized = value.trim().replace(/^\\\\\?\\/, '').replace(/\\/g, '/').replace(/\/+$/, '');
    if (/^[A-Za-z]:\//.test(normalized)) normalized = normalized.toLowerCase();
    return normalized;
};

export const gitStatusSignature = (status: GrokGitStatus) => JSON.stringify({
    branch: status.branch,
    headCommit: status.headCommit,
    ahead: status.ahead,
    behind: status.behind,
    files: status.files.map((file) => [
        file.path,
        file.indexStatus,
        file.worktreeStatus,
        file.staged,
        file.modified,
        file.untracked,
        file.conflicted,
    ]),
});

export const gitReviewCacheFor = (workspaceKey: string) => {
    let cache = workspaceCaches.get(workspaceKey);
    if (!cache) {
        cache = { diffs: new Map() };
        workspaceCaches.set(workspaceKey, cache);
        if (workspaceCaches.size > MAX_WORKSPACE_CACHE_ENTRIES) {
            const oldestKey = workspaceCaches.keys().next().value;
            if (oldestKey) workspaceCaches.delete(oldestKey);
        }
    }
    return cache;
};
