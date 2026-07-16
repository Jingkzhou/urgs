import React, { useEffect, useMemo, useState } from 'react';
import { Button, Empty, Modal, Spin, Tag } from 'antd';
import { ExternalLink, GitPullRequest, GitCommitHorizontal, FileCode2 } from 'lucide-react';
import type { TaskVersionChangeSnapshot } from '@/api/marketplace';
import { getMyGitIdentity, getUserGitIdentity, UserGitIdentity } from '@/api/user';
import {
    getGitRepositories,
    getPullRequest,
    getPullRequestCommits,
    getPullRequestFiles,
    getPullRequests,
    getRepoCommitDetail,
    GitCommit,
    GitCommitDiff,
    GitPullRequest as VersionPullRequest,
    GitRepository,
} from '@/api/version';

type MatchSource = 'commit' | 'pullRequestAuthor' | 'requirementOnly';

const TARGET_BRANCH = 'master';

type ParsedDiffLine = {
    type: 'hunk' | 'add' | 'del' | 'normal' | 'note';
    content: string;
    oldLineNo?: number;
    newLineNo?: number;
};

type MatchedPullRequest = VersionPullRequest & {
    repoId: number;
    repoName: string;
    matchSource: MatchSource;
    matchedCommits?: GitCommit[];
    snapshot?: TaskVersionChangeSnapshot;
    snapshotPayload?: VersionChangeSnapshotPayload;
};

type VersionChangeSnapshotPayload = {
    capturedAt?: string;
    matchSource?: string;
    repo?: {
        id?: number;
        name?: string;
        fullName?: string;
        platform?: string;
    };
    pullRequest?: Partial<VersionPullRequest>;
    commits?: GitCommit[];
    allCommits?: GitCommit[];
    matchedCommits?: GitCommit[];
    files?: GitCommitDiff[];
};

interface TaskVersionMergeRequestsProps {
    requirementNumber?: string;
    assigneeId?: string | number;
    useCurrentUserGitIdentity?: boolean;
    snapshots?: TaskVersionChangeSnapshot[];
    detailFullscreen?: boolean;
    onMatchCountChange?: (count: number) => void;
    onLoadingChange?: (loading: boolean) => void;
}

const extractRequirementNumbers = (value?: string) => (
    Array.from(new Set((value || '').match(/\d{6,}/g) || []))
);

const normalizeState = (state?: string) => {
    if (state === 'opened') return 'open';
    return state || 'unknown';
};

const stateLabel: Record<string, string> = {
    open: '开启中',
    closed: '已关闭',
    merged: '已合并',
    locked: '已锁定',
    unknown: '未知',
};

const stateColor: Record<string, string> = {
    open: 'green',
    closed: 'red',
    merged: 'purple',
    locked: 'default',
    unknown: 'default',
};

const matchSourceLabel: Record<MatchSource, string> = {
    commit: '提交作者',
    pullRequestAuthor: 'MR 作者',
    requirementOnly: '需求号',
};

const normalizeMatchSource = (value?: string): MatchSource => {
    if (value === 'commit' || value === 'pullRequestAuthor' || value === 'requirementOnly') {
        return value;
    }
    return 'requirementOnly';
};

const formatTime = (value?: string) => {
    if (!value) return '-';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
};

const firstLine = (value?: string) => (value || '').split('\n')[0] || '-';

const normalizeComparable = (value?: string | number | null) => String(value ?? '').trim().toLowerCase();

const hasGitIdentity = (identity?: UserGitIdentity | null) => Boolean(
    normalizeComparable(identity?.gitUsername)
    || normalizeComparable(identity?.gitEmail)
    || normalizeComparable(identity?.gitUserId)
);

const matchesIdentityText = (source?: string | null, expected?: string | null) => {
    const sourceText = normalizeComparable(source);
    const expectedText = normalizeComparable(expected);
    if (!sourceText || !expectedText) return false;
    return sourceText === expectedText || sourceText.includes(expectedText);
};

const commitMatchesGitIdentity = (commit: GitCommit, identity?: UserGitIdentity | null) => {
    if (!hasGitIdentity(identity)) return false;

    const authorEmail = normalizeComparable(commit.authorEmail);
    const gitEmail = normalizeComparable(identity?.gitEmail);
    if (gitEmail && authorEmail === gitEmail) {
        return true;
    }

    return matchesIdentityText(commit.authorName, identity?.gitUsername)
        || matchesIdentityText(commit.authorName, identity?.gitUserId);
};

const pullRequestMatchesGitIdentity = (pullRequest: VersionPullRequest, identity?: UserGitIdentity | null) => {
    if (!hasGitIdentity(identity)) return false;
    return matchesIdentityText(pullRequest.authorName, identity?.gitUsername)
        || matchesIdentityText(pullRequest.authorName, identity?.gitUserId);
};

const isTargetBranchPullRequest = (pullRequest: VersionPullRequest) => (
    (pullRequest.baseRef || '').trim() === TARGET_BRANCH
);

const getCommitSha = (commit: GitCommit) => commit.fullSha || commit.sha;

const dedupeFiles = (files: GitCommitDiff[]) => {
    const seen = new Set<string>();
    return files.filter(file => {
        const key = `${file.oldPath || ''}|${file.newPath || ''}|${file.status || ''}|${file.diff || ''}`;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
    });
};

const parseDiff = (diff?: string): ParsedDiffLine[] => {
    if (!diff) return [];
    const lines = diff.split('\n');
    const parsed: ParsedDiffLine[] = [];
    let oldLineNo = 0;
    let newLineNo = 0;
    let inHunk = false;

    lines.forEach(line => {
        if (line.startsWith('@@')) {
            inHunk = true;
            const match = line.match(/@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/);
            if (match) {
                oldLineNo = Number(match[1]) - 1;
                newLineNo = Number(match[2]) - 1;
            }
            parsed.push({ type: 'hunk', content: line });
            return;
        }

        if (!inHunk) {
            if (line.startsWith('diff --git') || line.startsWith('index ') || line.startsWith('---') || line.startsWith('+++')) {
                parsed.push({ type: 'note', content: line });
            }
            return;
        }

        if (line.startsWith('\\')) {
            parsed.push({ type: 'note', content: line });
            return;
        }

        if (line.startsWith('+') && !line.startsWith('+++')) {
            newLineNo += 1;
            parsed.push({ type: 'add', content: line.slice(1), newLineNo });
            return;
        }

        if (line.startsWith('-') && !line.startsWith('---')) {
            oldLineNo += 1;
            parsed.push({ type: 'del', content: line.slice(1), oldLineNo });
            return;
        }

        oldLineNo += 1;
        newLineNo += 1;
        parsed.push({
            type: 'normal',
            content: line.startsWith(' ') ? line.slice(1) : line,
            oldLineNo,
            newLineNo,
        });
    });

    return parsed;
};

const getFilePath = (file: GitCommitDiff) => file.newPath || file.oldPath || '未知文件';

const getFileStatus = (file: GitCommitDiff) => {
    const status = (file.status || '').toLowerCase();
    if (file.newFile || status === 'added' || status === 'new') return '新增';
    if (file.deletedFile || status === 'deleted' || status === 'removed') return '删除';
    if (file.renamedFile || status === 'renamed') return '重命名';
    return '修改';
};

const getStatusClassName = (status: string) => {
    if (status === '新增') return 'border-emerald-200 bg-emerald-50 text-emerald-700';
    if (status === '删除') return 'border-rose-200 bg-rose-50 text-rose-700';
    if (status === '重命名') return 'border-amber-200 bg-amber-50 text-amber-700';
    return 'border-blue-200 bg-blue-50 text-blue-700';
};

const getDiffLineClassName = (type: ParsedDiffLine['type']) => {
    if (type === 'add') return 'bg-emerald-50 hover:bg-emerald-100/70';
    if (type === 'del') return 'bg-rose-50 hover:bg-rose-100/70';
    if (type === 'hunk') return 'bg-blue-50 text-blue-700';
    if (type === 'note') return 'bg-slate-50 text-slate-400';
    return 'hover:bg-slate-50';
};

const getDiffMarker = (type: ParsedDiffLine['type']) => {
    if (type === 'add') return '+';
    if (type === 'del') return '-';
    if (type === 'hunk') return '@@';
    return '';
};

const getDiffStats = (file: GitCommitDiff, lines = parseDiff(file.diff)) => {
    const parsedAdditions = lines.filter(line => line.type === 'add').length;
    const parsedDeletions = lines.filter(line => line.type === 'del').length;
    return {
        additions: typeof file.additions === 'number' && file.additions > 0 ? file.additions : parsedAdditions,
        deletions: typeof file.deletions === 'number' && file.deletions > 0 ? file.deletions : parsedDeletions,
    };
};

const FileDiffPanel: React.FC<{ file: GitCommitDiff; index: number }> = ({ file, index }) => {
    const lines = useMemo(() => parseDiff(file.diff), [file.diff]);
    const { additions, deletions } = useMemo(() => getDiffStats(file, lines), [file, lines]);
    const status = getFileStatus(file);

    return (
        <details open={index === 0} className="overflow-hidden rounded-lg border border-slate-200 bg-white">
            <summary className="flex cursor-pointer items-center justify-between gap-3 border-b border-slate-100 bg-slate-50 px-3 py-2 text-sm hover:bg-slate-100">
                <div className="flex min-w-0 items-center gap-2">
                    <FileCode2 size={15} className="shrink-0 text-slate-500" />
                    <span className="min-w-0 truncate font-mono font-bold text-slate-800">{getFilePath(file)}</span>
                    <span className={`shrink-0 rounded border px-1.5 py-0.5 text-[11px] font-bold ${getStatusClassName(status)}`}>
                        {status}
                    </span>
                </div>
                <div className="shrink-0 font-mono text-xs">
                    <span className="rounded bg-emerald-50 px-1.5 py-0.5 font-bold text-emerald-700">+{additions}</span>
                    <span className="ml-1 rounded bg-rose-50 px-1.5 py-0.5 font-bold text-rose-700">-{deletions}</span>
                </div>
            </summary>

            {lines.length === 0 ? (
                <div className="px-4 py-6 text-center text-xs text-slate-400">暂无可展示的文本 diff</div>
            ) : (
                <div className="max-h-[520px] overflow-auto bg-white">
                    <table className="min-w-full border-collapse text-[12px] leading-5">
                        <tbody>
                            {lines.map((line, lineIndex) => (
                                <tr key={`${line.type}-${lineIndex}`} className={getDiffLineClassName(line.type)}>
                                    <td className="w-12 select-none border-r border-slate-100 bg-slate-50/70 px-2 text-right font-mono text-slate-400">
                                        {line.type !== 'add' && line.type !== 'hunk' && line.type !== 'note' ? line.oldLineNo : ''}
                                    </td>
                                    <td className="w-12 select-none border-r border-slate-100 bg-slate-50/70 px-2 text-right font-mono text-slate-400">
                                        {line.type !== 'del' && line.type !== 'hunk' && line.type !== 'note' ? line.newLineNo : ''}
                                    </td>
                                    <td className={`w-8 select-none px-2 text-center font-mono font-bold ${
                                        line.type === 'add' ? 'text-emerald-700' : line.type === 'del' ? 'text-rose-700' : 'text-slate-400'
                                    }`}>
                                        {getDiffMarker(line.type)}
                                    </td>
                                    <td className="min-w-[760px] whitespace-pre px-2 py-0.5 font-mono text-slate-800">
                                        {line.content || ' '}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </details>
    );
};

const loadCommitFiles = async (repoId: number, commits: GitCommit[]) => {
    const results = await Promise.allSettled(
        commits
            .map(getCommitSha)
            .filter((sha): sha is string => Boolean(sha))
            .map(sha => getRepoCommitDetail(repoId, sha))
    );
    return dedupeFiles(
        results
            .filter((result): result is PromiseFulfilledResult<GitCommit> => result.status === 'fulfilled')
            .flatMap(result => result.value?.diffs || [])
    );
};

const parseSnapshotPayload = (snapshot: TaskVersionChangeSnapshot): VersionChangeSnapshotPayload => {
    if (!snapshot.snapshotJson) return {};
    try {
        return JSON.parse(snapshot.snapshotJson) || {};
    } catch (error) {
        console.error('Failed to parse version change snapshot', error);
        return {};
    }
};

const matchedPullRequestKey = (pullRequest: MatchedPullRequest) => (
    `${pullRequest.repoId || normalizeComparable(pullRequest.repoName)}|${pullRequest.number || ''}`
);

const dedupeMatchedPullRequests = (items: MatchedPullRequest[]) => {
    const seen = new Set<string>();
    return items.filter(item => {
        const key = matchedPullRequestKey(item);
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
    });
};

const buildRecordsFromSnapshots = (snapshots: TaskVersionChangeSnapshot[] = []): MatchedPullRequest[] => (
    dedupeMatchedPullRequests(
        snapshots.map(snapshot => {
            const payload = parseSnapshotPayload(snapshot);
            const pr = payload.pullRequest || {};
            const repoId = snapshot.repoId || payload.repo?.id || 0;
            const number = Number(snapshot.prNumber || pr.number || snapshot.id);
            const repoName = snapshot.repoName || payload.repo?.name || payload.repo?.fullName || `仓库 ${repoId || '-'}`;
            return {
                id: String(pr.id || `${repoId}-${number}`),
                number,
                title: snapshot.prTitle || pr.title || '未命名合并请求',
                state: snapshot.state || pr.state || (snapshot.merged ? 'merged' : 'unknown'),
                body: pr.body || '',
                htmlUrl: snapshot.prUrl || pr.htmlUrl || '',
                headRef: snapshot.sourceBranch || pr.headRef || '',
                headSha: pr.headSha || '',
                baseRef: snapshot.targetBranch || pr.baseRef || TARGET_BRANCH,
                baseSha: pr.baseSha || '',
                authorName: pr.authorName || '',
                authorAvatar: pr.authorAvatar,
                createdAt: pr.createdAt || snapshot.createdAt || '',
                updatedAt: pr.updatedAt || snapshot.createdAt || '',
                closedAt: pr.closedAt,
                mergedAt: snapshot.mergedAt || pr.mergedAt,
                comments: pr.comments,
                commits: snapshot.commitCount ?? pr.commits,
                additions: snapshot.additions ?? pr.additions,
                deletions: snapshot.deletions ?? pr.deletions,
                changedFiles: snapshot.fileCount ?? pr.changedFiles,
                labels: pr.labels,
                reviewers: pr.reviewers,
                assignees: pr.assignees,
                repoId,
                repoName,
                matchSource: normalizeMatchSource(snapshot.matchSource || payload.matchSource),
                matchedCommits: payload.matchedCommits || [],
                snapshot,
                snapshotPayload: payload,
            };
        })
    )
);

const matchPullRequestsForRepo = async (
    repo: GitRepository & { id: number },
    matchTokens: string[],
    identity?: UserGitIdentity | null
): Promise<MatchedPullRequest[]> => {
    const pullRequests = await getPullRequests(repo.id, { state: 'all', perPage: 100 });
    const candidates = (pullRequests || [])
        .filter(isTargetBranchPullRequest)
        .filter(pr => matchTokens.some(token => (pr.title || '').includes(token)));

    const repoName = repo.name || repo.fullName || `仓库 ${repo.id}`;
    if (!hasGitIdentity(identity)) {
        return candidates.map(pr => ({
            ...pr,
            repoId: repo.id,
            repoName,
            matchSource: 'requirementOnly',
        }));
    }

    const checked = await Promise.all(candidates.map(async pr => {
        const commits = await getPullRequestCommits(repo.id, pr.number).catch(() => []);
        const matchedCommits = (commits || []).filter(commit => commitMatchesGitIdentity(commit, identity));
        const prAuthorMatched = pullRequestMatchesGitIdentity(pr, identity);

        if (matchedCommits.length === 0 && !prAuthorMatched) {
            return null;
        }

        return {
            ...pr,
            repoId: repo.id,
            repoName,
            matchSource: matchedCommits.length > 0 ? 'commit' : 'pullRequestAuthor',
            matchedCommits,
        } as MatchedPullRequest;
    }));

    return checked.filter((item): item is MatchedPullRequest => Boolean(item));
};

const TaskVersionMergeRequests: React.FC<TaskVersionMergeRequestsProps> = ({
    requirementNumber,
    assigneeId,
    useCurrentUserGitIdentity = false,
    snapshots,
    detailFullscreen = false,
    onMatchCountChange,
    onLoadingChange,
}) => {
    const [loading, setLoading] = useState(false);
    const [matchedPullRequests, setMatchedPullRequests] = useState<MatchedPullRequest[]>([]);
    const [error, setError] = useState('');
    const [gitIdentity, setGitIdentity] = useState<UserGitIdentity | null>(null);
    const [gitIdentityLoadFailed, setGitIdentityLoadFailed] = useState(false);
    const [activePr, setActivePr] = useState<MatchedPullRequest | null>(null);
    const [detailLoading, setDetailLoading] = useState(false);
    const [detailPr, setDetailPr] = useState<VersionPullRequest | null>(null);
    const [detailCommits, setDetailCommits] = useState<GitCommit[]>([]);
    const [detailFiles, setDetailFiles] = useState<GitCommitDiff[]>([]);

    const identityRequired = useCurrentUserGitIdentity
        || (assigneeId !== undefined && assigneeId !== null && String(assigneeId).trim() !== '');
    const snapshotRecords = useMemo(() => buildRecordsFromSnapshots(snapshots), [snapshots]);
    const hasSnapshotRecords = snapshotRecords.length > 0;

    const matchTokens = useMemo(() => {
        const tokens = [
            (requirementNumber || '').trim(),
            ...extractRequirementNumbers(requirementNumber),
        ].filter(Boolean);
        return Array.from(new Set(tokens));
    }, [requirementNumber]);

    const matchTokenKey = useMemo(() => matchTokens.join('|'), [matchTokens]);

    const identityText = useMemo(() => {
        if (!hasGitIdentity(gitIdentity)) return '';
        return gitIdentity?.gitUsername || gitIdentity?.gitEmail || gitIdentity?.gitUserId || '';
    }, [gitIdentity]);

    const detailFileStats = useMemo(() => (
        detailFiles.reduce((acc, file) => {
            const stats = getDiffStats(file);
            return {
                additions: acc.additions + stats.additions,
                deletions: acc.deletions + stats.deletions,
            };
        }, { additions: 0, deletions: 0 })
    ), [detailFiles]);

    useEffect(() => {
        let cancelled = false;

        const loadMatchedPullRequests = async () => {
            setMatchedPullRequests(snapshotRecords);
            setError('');
            setGitIdentity(null);
            setGitIdentityLoadFailed(false);
            if (matchTokens.length === 0) {
                setLoading(false);
                onMatchCountChange?.(snapshotRecords.length);
                onLoadingChange?.(false);
                return;
            }

            setLoading(true);
            onLoadingChange?.(true);
            try {
                let identity: UserGitIdentity | null = null;
                if (identityRequired) {
                    try {
                        identity = useCurrentUserGitIdentity
                            ? await getMyGitIdentity()
                            : await getUserGitIdentity(assigneeId as string | number);
                    } catch (loadError) {
                        console.error('Failed to load user git identity', loadError);
                        if (!cancelled) {
                            setGitIdentityLoadFailed(true);
                            setError('Git 身份读取失败，请刷新后重试；这不代表承接人未配置 Git 身份');
                            onMatchCountChange?.(snapshotRecords.length);
                        }
                        return;
                    }
                    if (cancelled) return;
                    setGitIdentity(identity);
                    if (!hasGitIdentity(identity)) {
                        setError(useCurrentUserGitIdentity
                            ? '当前账号未配置 Git 身份，无法确认本人的版本变更'
                            : '当前任务承接人未配置 Git 身份，无法确认该人员的版本变更');
                        onMatchCountChange?.(snapshotRecords.length);
                        return;
                    }
                }

                const repos = await getGitRepositories();
                const enabledRepos = (repos || [])
                    .filter((repo): repo is GitRepository & { id: number } => Boolean(repo.id) && repo.enabled !== false);
                const results = await Promise.allSettled(
                    enabledRepos.map(repo => matchPullRequestsForRepo(repo, matchTokens, identity))
                );

                if (cancelled) return;

                const matches = results
                    .filter((result): result is PromiseFulfilledResult<MatchedPullRequest[]> => result.status === 'fulfilled')
                    .flatMap(result => result.value)
                    .sort((a, b) => new Date(b.updatedAt || b.createdAt).getTime() - new Date(a.updatedAt || a.createdAt).getTime());
                const dedupedMatches = dedupeMatchedPullRequests([...snapshotRecords, ...matches]);
                setMatchedPullRequests(dedupedMatches);
                onMatchCountChange?.(dedupedMatches.length);

                const failedCount = results.filter(result => result.status === 'rejected').length;
                if (dedupedMatches.length === 0 && failedCount > 0) {
                    setError('部分仓库合并请求加载失败，未匹配到版本记录');
                }
            } catch (loadError) {
                if (!cancelled) {
                    console.error('Failed to load matched pull requests', loadError);
                    setError('版本合并请求加载失败');
                    onMatchCountChange?.(snapshotRecords.length);
                }
            } finally {
                if (!cancelled) {
                    setLoading(false);
                    onLoadingChange?.(false);
                }
            }
        };

        loadMatchedPullRequests();
        return () => {
            cancelled = true;
        };
    }, [matchTokenKey, assigneeId, identityRequired, snapshotRecords, useCurrentUserGitIdentity]);

    const openDetail = async (pullRequest: MatchedPullRequest) => {
        setActivePr(pullRequest);
        setDetailPr(null);
        setDetailCommits([]);
        setDetailFiles([]);
        if (pullRequest.snapshot) {
            const payload = pullRequest.snapshotPayload || {};
            setDetailPr({
                ...pullRequest,
                ...(payload.pullRequest || {}),
            });
            setDetailCommits(payload.commits || pullRequest.matchedCommits || []);
            setDetailFiles(payload.files || []);
            setDetailLoading(false);
            return;
        }
        setDetailLoading(true);
        try {
            const [prDetail, commits, files] = await Promise.all([
                getPullRequest(pullRequest.repoId, pullRequest.number),
                getPullRequestCommits(pullRequest.repoId, pullRequest.number),
                getPullRequestFiles(pullRequest.repoId, pullRequest.number),
            ]);

            let visibleCommits = commits || [];
            let visibleFiles = files || [];
            if (hasGitIdentity(gitIdentity)) {
                let matchedCommits = visibleCommits.filter(commit => commitMatchesGitIdentity(commit, gitIdentity));
                if (matchedCommits.length === 0 && pullRequest.matchedCommits && pullRequest.matchedCommits.length > 0) {
                    matchedCommits = pullRequest.matchedCommits;
                }
                if (matchedCommits.length > 0) {
                    visibleCommits = matchedCommits;
                    const commitFiles = await loadCommitFiles(pullRequest.repoId, matchedCommits);
                    if (commitFiles.length > 0) {
                        visibleFiles = commitFiles;
                    }
                }
            }

            setDetailPr(prDetail || pullRequest);
            setDetailCommits(visibleCommits);
            setDetailFiles(visibleFiles);
        } catch (detailError) {
            console.error('Failed to load pull request detail', detailError);
            setDetailPr(pullRequest);
        } finally {
            setDetailLoading(false);
        }
    };

    const closeDetail = () => {
        setActivePr(null);
        setDetailPr(null);
        setDetailCommits([]);
        setDetailFiles([]);
        setDetailLoading(false);
    };

    const renderStateTag = (state?: string) => {
        const normalized = normalizeState(state);
        return <Tag color={stateColor[normalized] || 'default'} className="!m-0">{stateLabel[normalized] || normalized}</Tag>;
    };

    const emptyDescription = error || (identityRequired ? '未匹配到当前承接人的 master 版本变更记录' : '未匹配到合入 master 的合并请求');

    return (
        <section className="overflow-hidden rounded-xl border border-slate-200 bg-white">
            <div className="flex items-center justify-between gap-4 border-b border-slate-100 bg-slate-50 px-4 py-3">
                <div>
                    <div className="flex items-center gap-2 text-sm font-bold text-slate-800">
                        <GitPullRequest size={16} className="text-purple-500" />
                        {hasSnapshotRecords ? '版本变更记录' : '版本合并请求'}
                    </div>
                    <div className="mt-1 text-xs text-slate-400">
                        {hasSnapshotRecords
                            ? '展示审核通过时固化的快照，并继续显示当前仍匹配的合并请求'
                            : '仅查看合入 master 的合并请求，再按需求编号和承接人 Git 身份匹配'}
                    </div>
                </div>
                <div className="flex flex-wrap justify-end gap-1">
                    {hasSnapshotRecords && <Tag color="cyan" className="!m-0">已固化 {snapshotRecords.length} 条</Tag>}
                    {matchTokens.length > 0 ? matchTokens.slice(0, 4).map(token => (
                        <Tag key={token} color="blue" className="!m-0 font-mono">{token}</Tag>
                    )) : (
                        <Tag className="!m-0">无需求号</Tag>
                    )}
                    {matchTokens.length > 4 && <Tag className="!m-0">+{matchTokens.length - 4}</Tag>}
                    {identityRequired && identityText && <Tag color="purple" className="!m-0 font-mono">{identityText}</Tag>}
                    {identityRequired && !loading && !identityText && !hasSnapshotRecords && !gitIdentityLoadFailed && (
                        <Tag color="orange" className="!m-0">
                            {useCurrentUserGitIdentity ? '当前账号未配置 Git 身份' : '承接人未配置 Git 身份'}
                        </Tag>
                    )}
                </div>
            </div>

            <div className="p-4">
                {loading ? (
                    <div className="flex min-h-28 items-center justify-center">
                        <Spin tip="正在匹配版本记录..." />
                    </div>
                ) : matchTokens.length === 0 ? (
                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="当前任务没有可用于匹配的需求号" />
                ) : matchedPullRequests.length === 0 ? (
                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={emptyDescription} />
                ) : (
                    <div className="overflow-hidden rounded-lg border border-slate-200">
                        <div className="overflow-x-auto">
                            <table className="w-full min-w-[860px] text-xs">
                                <thead className="bg-slate-50 text-slate-500">
                                    <tr>
                                        <th className="px-3 py-2 text-left">合并请求</th>
                                        <th className="px-3 py-2 text-left">仓库</th>
                                        <th className="px-3 py-2 text-left">分支</th>
                                        <th className="px-3 py-2 text-left">作者</th>
                                        <th className="px-3 py-2 text-left">匹配依据</th>
                                        <th className="px-3 py-2 text-left">状态</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {matchedPullRequests.map(pullRequest => (
                                        <tr
                                            key={`${pullRequest.repoId}-${pullRequest.number}`}
                                            className="cursor-pointer border-t border-slate-100 align-top hover:bg-purple-50/50"
                                            onClick={() => openDetail(pullRequest)}
                                        >
                                            <td className="min-w-[260px] px-3 py-3">
                                                <div className="font-bold text-slate-800">{pullRequest.title}</div>
                                                <div className="mt-1 font-mono text-slate-400">#{pullRequest.number}</div>
                                            </td>
                                            <td className="whitespace-nowrap px-3 py-3 text-slate-600">{pullRequest.repoName}</td>
                                            <td className="min-w-[170px] px-3 py-3 text-slate-600">
                                                <span className="font-mono text-blue-600">{pullRequest.baseRef}</span>
                                                <span className="mx-1 text-slate-300">←</span>
                                                <span className="font-mono text-blue-600">{pullRequest.headRef}</span>
                                            </td>
                                            <td className="whitespace-nowrap px-3 py-3 text-slate-600">
                                                <div>{pullRequest.authorName || '-'}</div>
                                                <div className="mt-1 text-slate-400">{formatTime(pullRequest.updatedAt || pullRequest.createdAt)}</div>
                                            </td>
                                            <td className="whitespace-nowrap px-3 py-3">
                                                <Tag color={pullRequest.snapshot ? 'cyan' : pullRequest.matchSource === 'commit' ? 'purple' : 'default'} className="!m-0">
                                                    {pullRequest.snapshot
                                                        ? `审批快照 · ${matchSourceLabel[pullRequest.matchSource]}`
                                                        : matchSourceLabel[pullRequest.matchSource]}
                                                </Tag>
                                            </td>
                                            <td className="whitespace-nowrap px-3 py-3">{renderStateTag(pullRequest.state)}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}
            </div>

            <Modal
                title={activePr ? `合并请求 #${activePr.number}` : '合并请求'}
                open={!!activePr}
                onCancel={closeDetail}
                footer={activePr?.htmlUrl ? (
                    <Button href={activePr.htmlUrl} target="_blank" icon={<ExternalLink size={14} />}>
                        打开原始页面
                    </Button>
                ) : null}
                width={detailFullscreen ? 'calc(100vw - 32px)' : 920}
                style={detailFullscreen ? { top: 16, maxWidth: 'none' } : undefined}
                destroyOnHidden
            >
                {detailLoading ? (
                    <div className="flex min-h-48 items-center justify-center">
                        <Spin tip="正在加载合并请求详情..." />
                    </div>
                ) : (
                    <div className={`${detailFullscreen ? 'max-h-[calc(100vh-150px)]' : 'max-h-[72vh]'} space-y-4 overflow-y-auto pr-1`}>
                        <section className="rounded-lg border border-slate-200">
                            <div className="border-b border-slate-100 bg-slate-50 px-4 py-3">
                                <div className="text-base font-bold text-slate-900">{detailPr?.title || activePr?.title}</div>
                                <div className="mt-2 flex flex-wrap gap-2 text-xs text-slate-500">
                                    {renderStateTag(detailPr?.state || activePr?.state)}
                                    <Tag className="!m-0">仓库：{activePr?.repoName}</Tag>
                                    {activePr && <Tag className="!m-0">匹配：{matchSourceLabel[activePr.matchSource]}</Tag>}
                                    {activePr?.snapshot && (
                                        <Tag color="cyan" className="!m-0">固化：{formatTime(activePr.snapshot.createdAt)}</Tag>
                                    )}
                                    <Tag className="!m-0">提交：{detailCommits.length}</Tag>
                                    <Tag className="!m-0">文件：{detailFiles.length}</Tag>
                                    <Tag color="green" className="!m-0 font-mono">+{detailFileStats.additions}</Tag>
                                    <Tag color="red" className="!m-0 font-mono">-{detailFileStats.deletions}</Tag>
                                </div>
                            </div>
                            <div className="space-y-3 px-4 py-3 text-sm text-slate-600">
                                <div>
                                    <span className="font-bold text-slate-700">分支：</span>
                                    <span className="font-mono text-blue-600">{detailPr?.baseRef || activePr?.baseRef}</span>
                                    <span className="mx-1 text-slate-300">←</span>
                                    <span className="font-mono text-blue-600">{detailPr?.headRef || activePr?.headRef}</span>
                                </div>
                                <div className="whitespace-pre-wrap">{detailPr?.body || activePr?.body || '暂无描述'}</div>
                            </div>
                        </section>

                        <section className="rounded-lg border border-slate-200">
                            <div className="flex items-center gap-2 border-b border-slate-100 bg-slate-50 px-4 py-2 text-sm font-bold text-slate-700">
                                <GitCommitHorizontal size={15} />
                                提交记录
                            </div>
                            {detailCommits.length === 0 ? (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无提交记录" className="py-4" />
                            ) : (
                                <div className="divide-y divide-slate-100">
                                    {detailCommits.map(commit => (
                                        <div key={commit.fullSha || commit.sha} className="px-4 py-3 text-sm">
                                            <div className="font-bold text-slate-800">{firstLine(commit.message)}</div>
                                            <div className="mt-1 flex flex-wrap gap-2 text-xs text-slate-400">
                                                <span className="font-mono text-blue-600">{commit.sha}</span>
                                                <span>{commit.authorName || '-'}</span>
                                                {commit.authorEmail && <span>{commit.authorEmail}</span>}
                                                <span>{formatTime(commit.committedAt)}</span>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </section>

                        <section className="overflow-hidden rounded-lg border border-slate-200">
                            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 bg-slate-50 px-4 py-2">
                                <div className="flex items-center gap-2 text-sm font-bold text-slate-700">
                                    <FileCode2 size={15} />
                                    文件变更对比
                                </div>
                                <div className="flex items-center gap-2 text-xs">
                                    <span className="font-mono font-bold text-slate-600">{detailFiles.length} 个文件</span>
                                    <span className="rounded bg-emerald-50 px-1.5 py-0.5 font-mono font-bold text-emerald-700">+{detailFileStats.additions}</span>
                                    <span className="rounded bg-rose-50 px-1.5 py-0.5 font-mono font-bold text-rose-700">-{detailFileStats.deletions}</span>
                                </div>
                            </div>
                            {detailFiles.length === 0 ? (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无文件变更" className="py-4" />
                            ) : (
                                <div className="space-y-3 bg-slate-50/60 p-3">
                                    {detailFiles.map((file, index) => (
                                        <FileDiffPanel key={`${getFilePath(file)}-${index}`} file={file} index={index} />
                                    ))}
                                </div>
                            )}
                        </section>
                    </div>
                )}
            </Modal>
        </section>
    );
};

export default TaskVersionMergeRequests;
