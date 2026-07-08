import React, { useEffect, useMemo, useState } from 'react';
import { Button, Empty, Modal, Spin, Tag } from 'antd';
import { ExternalLink, GitPullRequest, GitCommitHorizontal, FileCode2 } from 'lucide-react';
import { getUserGitIdentity, UserGitIdentity } from '@/api/user';
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

type MatchedPullRequest = VersionPullRequest & {
    repoId: number;
    repoName: string;
    matchSource: MatchSource;
    matchedCommits?: GitCommit[];
};

interface TaskVersionMergeRequestsProps {
    requirementNumber?: string;
    assigneeId?: string | number;
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
    onMatchCountChange,
    onLoadingChange,
}) => {
    const [loading, setLoading] = useState(false);
    const [matchedPullRequests, setMatchedPullRequests] = useState<MatchedPullRequest[]>([]);
    const [error, setError] = useState('');
    const [gitIdentity, setGitIdentity] = useState<UserGitIdentity | null>(null);
    const [activePr, setActivePr] = useState<MatchedPullRequest | null>(null);
    const [detailLoading, setDetailLoading] = useState(false);
    const [detailPr, setDetailPr] = useState<VersionPullRequest | null>(null);
    const [detailCommits, setDetailCommits] = useState<GitCommit[]>([]);
    const [detailFiles, setDetailFiles] = useState<GitCommitDiff[]>([]);

    const identityRequired = assigneeId !== undefined && assigneeId !== null && String(assigneeId).trim() !== '';

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

    useEffect(() => {
        let cancelled = false;

        const loadMatchedPullRequests = async () => {
            setMatchedPullRequests([]);
            setError('');
            setGitIdentity(null);
            if (matchTokens.length === 0) {
                onMatchCountChange?.(0);
                return;
            }

            setLoading(true);
            onLoadingChange?.(true);
            try {
                let identity: UserGitIdentity | null = null;
                if (identityRequired) {
                    identity = await getUserGitIdentity(assigneeId as string | number).catch(loadError => {
                        console.error('Failed to load user git identity', loadError);
                        return null;
                    });
                    if (cancelled) return;
                    setGitIdentity(identity);
                    if (!hasGitIdentity(identity)) {
                        setError('当前任务承接人未配置 Git 身份，无法确认该人员的版本变更');
                        onMatchCountChange?.(0);
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
                setMatchedPullRequests(matches);
                onMatchCountChange?.(matches.length);

                const failedCount = results.filter(result => result.status === 'rejected').length;
                if (matches.length === 0 && failedCount > 0) {
                    setError('部分仓库合并请求加载失败，未匹配到版本记录');
                }
            } catch (loadError) {
                if (!cancelled) {
                    console.error('Failed to load matched pull requests', loadError);
                    setError('版本合并请求加载失败');
                    onMatchCountChange?.(0);
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
    }, [matchTokenKey, assigneeId, identityRequired]);

    const openDetail = async (pullRequest: MatchedPullRequest) => {
        setActivePr(pullRequest);
        setDetailPr(null);
        setDetailCommits([]);
        setDetailFiles([]);
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
                        版本合并请求
                    </div>
                    <div className="mt-1 text-xs text-slate-400">
                        仅查看合入 master 的合并请求，再按需求编号和承接人 Git 身份匹配
                    </div>
                </div>
                <div className="flex flex-wrap justify-end gap-1">
                    {matchTokens.length > 0 ? matchTokens.slice(0, 4).map(token => (
                        <Tag key={token} color="blue" className="!m-0 font-mono">{token}</Tag>
                    )) : (
                        <Tag className="!m-0">无需求号</Tag>
                    )}
                    {matchTokens.length > 4 && <Tag className="!m-0">+{matchTokens.length - 4}</Tag>}
                    {identityRequired && identityText && <Tag color="purple" className="!m-0 font-mono">{identityText}</Tag>}
                    {identityRequired && !loading && !identityText && <Tag color="orange" className="!m-0">未配置 Git 身份</Tag>}
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
                                                <Tag color={pullRequest.matchSource === 'commit' ? 'purple' : 'default'} className="!m-0">
                                                    {matchSourceLabel[pullRequest.matchSource]}
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
                width={920}
                destroyOnHidden
            >
                {detailLoading ? (
                    <div className="flex min-h-48 items-center justify-center">
                        <Spin tip="正在加载合并请求详情..." />
                    </div>
                ) : (
                    <div className="max-h-[72vh] space-y-4 overflow-y-auto pr-1">
                        <section className="rounded-lg border border-slate-200">
                            <div className="border-b border-slate-100 bg-slate-50 px-4 py-3">
                                <div className="text-base font-bold text-slate-900">{detailPr?.title || activePr?.title}</div>
                                <div className="mt-2 flex flex-wrap gap-2 text-xs text-slate-500">
                                    {renderStateTag(detailPr?.state || activePr?.state)}
                                    <Tag className="!m-0">仓库：{activePr?.repoName}</Tag>
                                    {activePr && <Tag className="!m-0">匹配：{matchSourceLabel[activePr.matchSource]}</Tag>}
                                    <Tag className="!m-0">提交：{detailCommits.length}</Tag>
                                    <Tag className="!m-0">文件：{detailFiles.length}</Tag>
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

                        <section className="rounded-lg border border-slate-200">
                            <div className="flex items-center gap-2 border-b border-slate-100 bg-slate-50 px-4 py-2 text-sm font-bold text-slate-700">
                                <FileCode2 size={15} />
                                文件变更
                            </div>
                            {detailFiles.length === 0 ? (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无文件变更" className="py-4" />
                            ) : (
                                <div className="divide-y divide-slate-100">
                                    {detailFiles.map((file, index) => (
                                        <details key={`${file.newPath || file.oldPath}-${index}`} className="group px-4 py-3">
                                            <summary className="flex cursor-pointer items-center justify-between gap-3 text-sm">
                                                <span className="min-w-0 truncate font-mono text-slate-700">{file.newPath || file.oldPath}</span>
                                                <span className="shrink-0 text-xs text-slate-400">
                                                    +{file.additions || 0} / -{file.deletions || 0}
                                                </span>
                                            </summary>
                                            <pre className="mt-3 max-h-80 overflow-auto rounded bg-slate-900 p-3 text-xs leading-5 text-slate-100">
                                                {file.diff || '暂无 diff 内容'}
                                            </pre>
                                        </details>
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
