import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
    Activity,
    AlertCircle,
    Archive,
    ArrowUpRight,
    CheckCircle2,
    Clock3,
    GitBranch,
    GitCommitHorizontal,
    GitPullRequest,
    RefreshCw,
    Server,
    ShieldAlert
} from 'lucide-react';
import {
    getGitRepositories,
    getOverviewStats,
    getRepoLatestCommit,
    getRepoPrCounts,
    GitCommit,
    GitRepository
} from '@/api/version';
import { formatCommitTime } from '@/utils/dateUtils';

interface OverviewStats {
    totalReleases: number;
    pendingReleases: number;
    successRate: number;
}

interface RepositoryActivity {
    repository: GitRepository;
    commit: GitCommit | null;
    openPullRequests: number;
    loadFailed: boolean;
}

interface MetricCardProps {
    label: string;
    value: string | number;
    detail: string;
    icon: React.ElementType;
    tone: 'blue' | 'violet' | 'emerald' | 'amber';
}

const toneClasses = {
    blue: 'bg-blue-50 text-blue-600 border-blue-100',
    violet: 'bg-violet-50 text-violet-600 border-violet-100',
    emerald: 'bg-emerald-50 text-emerald-600 border-emerald-100',
    amber: 'bg-amber-50 text-amber-600 border-amber-100'
};

const platformClasses: Record<string, string> = {
    github: 'bg-slate-900 text-white',
    gitlab: 'bg-orange-50 text-orange-700 border border-orange-100',
    gitee: 'bg-red-50 text-red-700 border border-red-100'
};

const MetricCard: React.FC<MetricCardProps> = ({ label, value, detail, icon: Icon, tone }) => (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
            <div>
                <div className="text-sm font-medium text-slate-500">{label}</div>
                <div className="mt-2 text-3xl font-semibold tracking-tight text-slate-900">{value}</div>
            </div>
            <div className={`rounded-lg border p-2.5 ${toneClasses[tone]}`}>
                <Icon size={19} />
            </div>
        </div>
        <div className="mt-3 text-xs text-slate-500">{detail}</div>
    </div>
);

const getCommitTime = (commit: GitCommit | null) => {
    if (!commit?.committedAt) return 0;
    const timestamp = new Date(commit.committedAt).getTime();
    return Number.isNaN(timestamp) ? 0 : timestamp;
};

const isOlderThanDays = (commit: GitCommit | null, days: number) => {
    const timestamp = getCommitTime(commit);
    return timestamp > 0 && timestamp < Date.now() - days * 24 * 60 * 60 * 1000;
};

const getRepositoryWebUrl = (repository: GitRepository) => {
    const url = repository.cloneUrl || '';
    return /^https?:\/\//i.test(url) ? url.replace(/\.git$/, '') : '';
};

const VersionOverview: React.FC = () => {
    const [repositories, setRepositories] = useState<GitRepository[]>([]);
    const [activities, setActivities] = useState<RepositoryActivity[]>([]);
    const [stats, setStats] = useState<OverviewStats | null>(null);
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);
    const [error, setError] = useState('');
    const [updatedAt, setUpdatedAt] = useState<Date | null>(null);
    const [prCountsAvailable, setPrCountsAvailable] = useState(true);
    const [releaseStatsAvailable, setReleaseStatsAvailable] = useState(true);

    const loadOverview = useCallback(async (silent = false) => {
        if (silent) {
            setRefreshing(true);
        } else {
            setLoading(true);
        }
        setError('');
        setPrCountsAvailable(true);
        setReleaseStatsAvailable(true);

        try {
            const [repoData, prCountResult, statsResult] = await Promise.all([
                getGitRepositories(),
                getRepoPrCounts().catch(error => {
                    console.error('获取 Pull Request 统计失败', error);
                    setPrCountsAvailable(false);
                    return {} as Record<string, number>;
                }),
                getOverviewStats().catch(error => {
                    console.error('获取发布统计失败', error);
                    setReleaseStatsAvailable(false);
                    return null;
                })
            ]);

            const nextRepositories = repoData || [];
            const repositoriesWithId = nextRepositories.filter(
                (repository): repository is GitRepository & { id: number } => typeof repository.id === 'number'
            );
            const commitResults = await Promise.allSettled(
                repositoriesWithId.map(repository => (
                    getRepoLatestCommit(repository.id, repository.defaultBranch || '')
                ))
            );

            const nextActivities = repositoriesWithId.map((repository, index) => {
                const result = commitResults[index];
                const commit = result.status === 'fulfilled' ? result.value || null : null;
                return {
                    repository,
                    commit,
                    openPullRequests: Number(prCountResult[String(repository.id)] || 0),
                    loadFailed: result.status === 'rejected'
                };
            });

            setRepositories(nextRepositories);
            setActivities(nextActivities);
            setStats(statsResult);
            setUpdatedAt(new Date());
        } catch (loadError) {
            console.error('加载版本概览失败', loadError);
            setError('概览数据加载失败，请检查仓库访问权限后重试。');
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    }, []);

    useEffect(() => {
        loadOverview();
    }, [loadOverview]);

    const sortedActivities = useMemo(() => (
        [...activities].sort((left, right) => getCommitTime(right.commit) - getCommitTime(left.commit))
    ), [activities]);

    const openPullRequestCount = useMemo(() => (
        activities.reduce((total, item) => total + item.openPullRequests, 0)
    ), [activities]);

    const repositoriesWithPullRequests = useMemo(() => (
        activities.filter(item => item.openPullRequests > 0).length
    ), [activities]);

    const activeRepositories = useMemo(() => {
        const threshold = Date.now() - 7 * 24 * 60 * 60 * 1000;
        return activities.filter(item => item.repository.enabled !== false && getCommitTime(item.commit) >= threshold).length;
    }, [activities]);

    const enabledRepositories = repositories.filter(repository => repository.enabled !== false).length;
    const staleRepositories = activities.filter(item => item.repository.enabled !== false && !item.loadFailed && isOlderThanDays(item.commit, 30)).length;
    const failedRepositories = activities.filter(item => item.repository.enabled !== false && item.loadFailed).length;
    const disabledRepositories = repositories.length - enabledRepositories;

    const platformCounts = useMemo(() => {
        const counts: Record<string, number> = {};
        repositories.forEach(repository => {
            const platform = (repository.platform || 'unknown').toLowerCase();
            counts[platform] = (counts[platform] || 0) + 1;
        });
        return Object.entries(counts).sort((left, right) => right[1] - left[1]);
    }, [repositories]);

    if (loading) {
        return (
            <div className="space-y-6">
                <div className="h-20 animate-pulse rounded-xl bg-slate-100" />
                <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
                    {[0, 1, 2, 3].map(item => <div key={item} className="h-32 animate-pulse rounded-xl bg-slate-100" />)}
                </div>
                <div className="h-80 animate-pulse rounded-xl bg-slate-100" />
            </div>
        );
    }

    return (
        <div className="mx-auto max-w-[1500px] space-y-6">
            <header className="flex flex-col justify-between gap-4 border-b border-slate-200 pb-5 sm:flex-row sm:items-end">
                <div>
                    <div className="flex items-center gap-2 text-xs font-medium text-emerald-600">
                        <span className="h-2 w-2 rounded-full bg-emerald-500" />
                        数据来自当前用户可访问的代码仓库
                    </div>
                    <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-900">系统概览</h1>
                    <p className="mt-1 text-sm text-slate-500">集中查看仓库活跃度、待合并请求和版本发布情况。</p>
                </div>
                <div className="flex items-center gap-3">
                    <span className="text-xs text-slate-400">
                        {updatedAt ? `更新于 ${updatedAt.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })}` : '尚未更新'}
                    </span>
                    <button
                        type="button"
                        onClick={() => loadOverview(true)}
                        disabled={refreshing}
                        className="inline-flex items-center gap-2 rounded-md border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-50 disabled:cursor-wait disabled:opacity-60"
                    >
                        <RefreshCw size={15} className={refreshing ? 'animate-spin' : ''} />
                        刷新
                    </button>
                </div>
            </header>

            {error && (
                <div className="flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    <AlertCircle size={17} />
                    {error}
                </div>
            )}

            <section className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
                <MetricCard
                    label="代码仓库"
                    value={repositories.length}
                    detail={`${enabledRepositories} 个已启用，${disabledRepositories} 个未启用`}
                    icon={Archive}
                    tone="blue"
                />
                <MetricCard
                    label="待合并请求"
                    value={prCountsAvailable ? openPullRequestCount : '—'}
                    detail={prCountsAvailable ? `分布在 ${repositoriesWithPullRequests} 个仓库` : 'Pull Request 统计暂不可用'}
                    icon={GitPullRequest}
                    tone="violet"
                />
                <MetricCard
                    label="近 7 日活跃仓库"
                    value={activeRepositories}
                    detail={`${enabledRepositories > 0 ? Math.round(activeRepositories / enabledRepositories * 100) : 0}% 的已启用仓库近期有提交`}
                    icon={Activity}
                    tone="emerald"
                />
                <MetricCard
                    label="发布成功率"
                    value={releaseStatsAvailable ? `${Math.round(stats?.successRate || 0)}%` : '—'}
                    detail={releaseStatsAvailable ? `累计 ${stats?.totalReleases || 0} 次发布，${stats?.pendingReleases || 0} 次待处理` : '发布统计暂不可用'}
                    icon={CheckCircle2}
                    tone="amber"
                />
            </section>

            <section className="grid grid-cols-1 gap-6 xl:grid-cols-3">
                <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm xl:col-span-2">
                    <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
                        <div>
                            <h2 className="flex items-center gap-2 text-base font-semibold text-slate-900">
                                <GitCommitHorizontal size={18} className="text-slate-500" />
                                最近仓库动态
                            </h2>
                            <p className="mt-1 text-xs text-slate-500">按各仓库最新一次提交时间排序</p>
                        </div>
                        <span className="text-xs text-slate-400">显示前 {Math.min(sortedActivities.length, 8)} 个仓库</span>
                    </div>

                    {sortedActivities.length === 0 ? (
                        <div className="flex min-h-64 flex-col items-center justify-center text-slate-400">
                            <GitBranch size={32} className="mb-3 opacity-40" />
                            <span className="text-sm">暂无可访问的仓库动态</span>
                        </div>
                    ) : (
                        <div className="divide-y divide-slate-100">
                            {sortedActivities.slice(0, 8).map(item => (
                                <div key={item.repository.id} className="flex flex-col gap-3 px-5 py-4 transition-colors hover:bg-slate-50/80 sm:flex-row sm:items-center">
                                    <div className="flex min-w-0 flex-1 items-start gap-3">
                                        <div className="mt-0.5 rounded-md border border-slate-200 bg-slate-50 p-2 text-slate-500">
                                            <Archive size={16} />
                                        </div>
                                        <div className="min-w-0 flex-1">
                                            <div className="flex flex-wrap items-center gap-2">
                                                <span className="truncate text-sm font-semibold text-slate-900">{item.repository.name}</span>
                                                <span className={`rounded px-1.5 py-0.5 text-[10px] font-semibold uppercase ${platformClasses[item.repository.platform] || 'bg-slate-100 text-slate-600'}`}>
                                                    {item.repository.platform}
                                                </span>
                                                {item.repository.enabled === false && (
                                                    <span className="rounded bg-slate-100 px-1.5 py-0.5 text-[10px] font-medium text-slate-500">未启用</span>
                                                )}
                                                {item.openPullRequests > 0 && (
                                                    <span className="inline-flex items-center gap-1 rounded-full bg-violet-50 px-2 py-0.5 text-[11px] font-medium text-violet-700">
                                                        <GitPullRequest size={11} />{item.openPullRequests}
                                                    </span>
                                                )}
                                            </div>
                                            {item.commit ? (
                                                <>
                                                    <div className="mt-1 truncate text-sm text-slate-600" title={item.commit.message}>{item.commit.message?.split('\n')[0]}</div>
                                                    <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-slate-400">
                                                        <span>{item.commit.authorName || '未知提交人'}</span>
                                                        <span className="font-mono">{item.repository.defaultBranch || '默认分支'} · {item.commit.sha?.slice(0, 8)}</span>
                                                        <span>{formatCommitTime(item.commit.committedAt)}</span>
                                                    </div>
                                                </>
                                            ) : (
                                                <div className="mt-1 text-sm text-slate-400">
                                                    {item.loadFailed ? '最新提交读取失败' : '暂无提交记录'}
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                    {getRepositoryWebUrl(item.repository) && (
                                        <a
                                            href={getRepositoryWebUrl(item.repository)}
                                            target="_blank"
                                            rel="noreferrer"
                                            className="inline-flex shrink-0 items-center gap-1 text-xs font-medium text-blue-600 hover:text-blue-700"
                                        >
                                            打开仓库 <ArrowUpRight size={13} />
                                        </a>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                <div className="space-y-6">
                    <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
                        <div className="border-b border-slate-200 px-5 py-4">
                            <h2 className="flex items-center gap-2 text-base font-semibold text-slate-900">
                                <ShieldAlert size={18} className="text-amber-500" />
                                需要关注
                            </h2>
                            <p className="mt-1 text-xs text-slate-500">优先处理可能影响协作效率的事项</p>
                        </div>
                        <div className="divide-y divide-slate-100 px-5">
                            {[
                                { label: '开放 Pull Request', value: prCountsAvailable ? openPullRequestCount : '—', icon: GitPullRequest, tone: 'text-violet-600 bg-violet-50' },
                                { label: '超过 30 天无提交', value: staleRepositories, icon: Clock3, tone: 'text-amber-600 bg-amber-50' },
                                { label: '未启用仓库', value: disabledRepositories, icon: Server, tone: 'text-slate-600 bg-slate-100' },
                                { label: '动态读取失败', value: failedRepositories, icon: AlertCircle, tone: 'text-red-600 bg-red-50' }
                            ].map(item => (
                                <div key={item.label} className="flex items-center justify-between py-3.5">
                                    <div className="flex items-center gap-3 text-sm text-slate-600">
                                        <span className={`rounded-md p-1.5 ${item.tone}`}><item.icon size={15} /></span>
                                        {item.label}
                                    </div>
                                    <span className="text-sm font-semibold text-slate-900">{item.value}</span>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                        <div className="mb-4 flex items-center justify-between">
                            <div>
                                <h2 className="text-base font-semibold text-slate-900">托管平台</h2>
                                <p className="mt-1 text-xs text-slate-500">当前仓库的平台分布</p>
                            </div>
                            <span className="text-xs text-slate-400">共 {repositories.length} 个</span>
                        </div>
                        <div className="space-y-4">
                            {platformCounts.length === 0 ? (
                                <div className="py-6 text-center text-sm text-slate-400">暂无平台数据</div>
                            ) : platformCounts.map(([platform, count]) => {
                                const percentage = repositories.length > 0 ? count / repositories.length * 100 : 0;
                                return (
                                    <div key={platform}>
                                        <div className="mb-1.5 flex items-center justify-between text-sm">
                                            <span className="font-medium capitalize text-slate-700">{platform}</span>
                                            <span className="text-xs text-slate-500">{count} 个 · {Math.round(percentage)}%</span>
                                        </div>
                                        <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                                            <div className="h-full rounded-full bg-blue-500" style={{ width: `${percentage}%` }} />
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default VersionOverview;
