import type { GrokGitBranch, GrokGitDiff, GrokGitStatus } from '@/services/grokDesktop';

export interface WorkspaceReviewCache {
    status?: GrokGitStatus;
    statusSignature?: string;
    selectedPath?: string;
    diffs: Map<string, GrokGitDiff>;
    snapshotSignature?: string;
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

export const invalidateGitDiffPaths = (cache: WorkspaceReviewCache, changedPaths: string[]) => {
    const normalized = new Set(changedPaths.map((path) => path.replace(/\\/g, '/')));
    for (const path of cache.diffs.keys()) {
        if (normalized.has(path)) cache.diffs.delete(path);
    }
    if (normalized.size > 0) cache.snapshotSignature = undefined;
};

export const cacheGitDiffSnapshot = (
    cache: WorkspaceReviewCache,
    snapshot: GrokGitDiff,
    files: GrokGitStatus['files'],
) => {
    const starts: number[] = [];
    const marker = 'diff --git ';
    let offset = snapshot.patch.indexOf(marker);
    while (offset >= 0) {
        starts.push(offset);
        offset = snapshot.patch.indexOf(`\n${marker}`, offset + marker.length);
        if (offset >= 0) offset += 1;
    }
    starts.forEach((start, index) => {
        if (snapshot.truncated && index === starts.length - 1) return;
        const patch = snapshot.patch.slice(start, starts[index + 1] ?? snapshot.patch.length).trimEnd();
        const header = patch.slice(0, patch.indexOf('\n') >= 0 ? patch.indexOf('\n') : undefined);
        // Rename/copy patches use different old/new paths in the header. Git status exposes
        // the destination path, so match the b/ side instead of requiring both sides equal.
        const file = files.find((candidate) => header.endsWith(` b/${candidate.path}`));
        if (!file) return;
        cache.diffs.set(file.path, {
            ...snapshot,
            path: file.path,
            patch: `${patch}\n`,
            truncated: false,
        });
    });
};

export const cachedGitDiffSnapshot = (
    cache: WorkspaceReviewCache,
    status: GrokGitStatus,
): GrokGitDiff | undefined => {
    const signature = gitStatusSignature(status);
    if (cache.snapshotSignature !== signature || status.files.length === 0) return undefined;
    const fileDiffs = status.files.map((file) => cache.diffs.get(file.path));
    if (fileDiffs.some((diff) => !diff || diff.truncated || !diff.patch.trim())) return undefined;
    return {
        workspacePath: status.workspacePath,
        path: undefined,
        staged: false,
        patch: fileDiffs.map((diff) => diff?.patch.trimEnd() || '').join('\n'),
        truncated: false,
        files: status.files,
    };
};

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
