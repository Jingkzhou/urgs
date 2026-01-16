import React, { useState, useEffect, useMemo } from 'react';
import { getAICodeReviews, AICodeReview } from '../../api/version';
import {
    Bot, CheckCircle, Clock, GitCommit, Search, RefreshCw, FileCode,
    Shield, Activity, Zap, Layers, AlertTriangle, Terminal, User,
    ArrowUpRight, Loader, Check
} from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { Progress, Badge, Modal, Select, Button } from 'antd';

interface Props {
    ssoId?: number;
    repoId?: number;
}

// 独立的问题接口
interface AuditIssue {
    severity: 'critical' | 'major' | 'minor';
    title: string;
    line?: number;
    description?: string;
    recommendation?: string;
    codeSnippet?: string;
}

// 扩展的 Review 接口
interface ExtendedReview extends AICodeReview {
    scoreBreakdown: {
        security: number;
        reliability: number;
        maintainability: number;
        performance: number;
    };
    issues: AuditIssue[];
    language?: string;
}

const AICodeAudit: React.FC<Props> = ({ ssoId, repoId }) => {
    const [reviews, setReviews] = useState<ExtendedReview[]>([]);
    const [loading, setLoading] = useState(false);
    const [selectedReview, setSelectedReview] = useState<ExtendedReview | null>(null);
    const [selectedIssue, setSelectedIssue] = useState<AuditIssue | null>(null);
    const [isIssueModalOpen, setIsIssueModalOpen] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [filterStatus, setFilterStatus] = useState<string>('ALL');
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [auditConfig, setAuditConfig] = useState({
        branch: 'main',
        depth: 'standard',
        type: 'diff',
        schedule: 'manual',
        rulesets: ['security', 'performance'],
        selectedFiles: [],
        prId: null
    });

    const mockPRs = [
        { id: 'PR-2042', title: 'feat: 接入支付网关 v2 接口', author: 'Zhang San', branch: 'feat-payment' },
        { id: 'PR-1985', title: 'fix: 修复登录页移动端适配问题', author: 'Li Si', branch: 'fix-login' },
        { id: 'PR-2103', title: 'refactor: 重构工具类函数并添加注释', author: 'Wang Wu', branch: 'refactor-utils' },
    ];

    const mockFilesMap: Record<string, { path: string, type: string }[]> = {
        'PR-2042': [
            { path: 'src/api/payment.ts', type: 'modified' },
            { path: 'src/components/PaymentForm.tsx', type: 'modified' },
            { path: 'configs/gateway.json', type: 'modified' },
        ],
        'PR-1985': [
            { path: 'src/styles/responsive.css', type: 'modified' },
            { path: 'src/components/Login/MobileView.tsx', type: 'new' },
        ],
        'PR-2103': [
            { path: 'src/utils/common.ts', type: 'modified' },
            { path: 'src/utils/date.ts', type: 'modified' },
            { path: 'src/utils/string.ts', type: 'modified' },
        ],
    };

    const currentFiles = auditConfig.prId ? (mockFilesMap[auditConfig.prId] || []) : [];

    // 模拟数据适配器
    const adaptReviewData = (data: AICodeReview[]): ExtendedReview[] => {
        return data.map(r => ({
            ...r,
            language: 'TypeScript',
            scoreBreakdown: {
                security: r.score ? Math.min(100, r.score + 5) : 85,
                reliability: r.score || 80,
                maintainability: r.score ? Math.max(60, r.score - 5) : 75,
                performance: r.score || 90,
            },
            issues: r.score && r.score > 80 ? [] : [
                { severity: 'critical', title: 'Potential SQL Injection in query builder', line: 42 },
                { severity: 'major', title: 'Unused variable "tempData"', line: 12 },
                { severity: 'minor', title: 'Missing return type annotation', line: 85 },
            ]
        }));
    };

    // 丰富多彩的 Mock 数据
    const MOCK_REVIEWS_DATA: ExtendedReview[] = [
        {
            id: 101,
            repoId: 1,
            commitSha: '8f3a2b1',
            branch: 'feat/payment-gateway-v2',
            score: 96,
            status: 'COMPLETED',
            summary: 'Stripe V2 支付接口实现与健壮异常处理',
            developerEmail: 'zhangsan@jlbank.com',
            createdAt: '2024-03-20T10:30:00Z',
            language: 'TypeScript',
            scoreBreakdown: { security: 98, reliability: 95, maintainability: 92, performance: 99 },
            issues: [],
            content: '## 🌟 卓越的代码质量\n\n支付网关 V2 的实现展示了高标准的编码实践。\n\n### 关键亮点\n- **安全性**: 强大的参数验证和输出编码。\n- **性能**: 高效使用 async/await 模式。\n- **文档**: 全面的 JSDoc 注释。'
        },
        {
            id: 102,
            repoId: 1,
            commitSha: '7c2d9e4',
            branch: 'fix/login-race-condition',
            score: 72,
            status: 'COMPLETED',
            summary: '修复认证流程中潜在的竞态条件',
            developerEmail: 'lisi@jlbank.com',
            createdAt: '2024-03-19T14:15:00Z',
            language: 'TypeScript',
            scoreBreakdown: { security: 88, reliability: 65, maintainability: 70, performance: 65 },
            issues: [
                {
                    severity: 'major',
                    title: '认证中间件中存在潜在的未处理 Promise 拒绝',
                    line: 45,
                    description: '在 `validateToken` 函数中，异步操作没有正确捕获可能的异常，导致未处理的 Promise Rejection。',
                    recommendation: '建议使用 try-catch 包裹 await 调用，或在 Promise 链末尾添加 .catch() 处理。',
                    codeSnippet: `async function validateToken(token: string) {
    // 🔴 Missing try-catch block for async operation
    const user = await db.findUserByToken(token);
    if (!user) throw new Error("Invalid token");
    return user;
}`
                },
                {
                    severity: 'major',
                    title: '复杂的嵌套条件判断降低了可读性',
                    line: 89,
                    description: '`checkPermission` 方法中存在超过 4 层的 if-else 嵌套，圈复杂度过高。',
                    recommendation: '建议使用卫语句 (Guard Clauses) 提前返回，或将逻辑提取为独立的验证函数。',
                    codeSnippet: `if (user.role === 'admin') {
    if (resource.type === 'document') {
        if (resource.status === 'active') {
            if (action === 'edit') {
                return true;
            }
        }
    }
}`
                },
                {
                    severity: 'minor',
                    title: '缺少边界情况的单元测试',
                    line: 120,
                    description: '当前的测试套件仅覆盖了 happy path，缺少 token 过期或无效时的测试用例。',
                    recommendation: '补充针对边界条件的 jest 测试用例。'
                }
            ],
            content: '## ⚠️ 检测到中等风险\n\n虽然竞态条件已解决，但解决方案引入了一些复杂性和潜在的不稳定性。\n\n### 建议\n1. **重构**: 简化 `AuthService.ts` 中的嵌套 `if-else` 块。\n2. **错误处理**: 为认证 promise 链添加全局 catch 块。'
        },
        {
            id: 103,
            repoId: 1,
            commitSha: 'a1b2c3d',
            branch: 'chore/legacy-cleanup',
            score: 45,
            status: 'FAILED',
            summary: '移除遗留的 XML 解析器和工具函数',
            developerEmail: 'wangwu@jlbank.com',
            createdAt: '2024-03-18T09:00:00Z',
            language: 'JavaScript',
            scoreBreakdown: { security: 30, reliability: 50, maintainability: 40, performance: 60 },
            issues: [
                {
                    severity: 'critical',
                    title: '在已删除文件历史中发现硬编码凭证',
                    line: 12,
                    description: '检测到 AWS AK/SK 曾直接硬编码在源码中，虽然文件已删除，但 git 历史中仍可追溯。',
                    recommendation: '立即轮换相关密钥，并使用 BFG Repo-Cleaner 清理 git 历史。',
                    codeSnippet: `// 🚨 CRITICAL: Hardcoded credentials
const AWS_CONFIG = {
    accessKey: "AKIAIOSFODNN7EXAMPLE",
    secretKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
};`
                },
                {
                    severity: 'critical',
                    title: '"LegacyUserSearch" 中存在 SQL 注入漏洞',
                    line: 230,
                    description: '用户输入直接拼接到 SQL 查询字符串中，未经过参数化处理。',
                    recommendation: '使用 PreparedStatement 或 ORM 框架的参数化查询功能。',
                    codeSnippet: `// 🚨 SQL Injection Vulnerability
const query = "SELECT * FROM users WHERE name = '" + userName + "'";
db.execute(query);`
                },
                { severity: 'major', title: '检测到直接的 DOM 操作', line: 56 },
                { severity: 'major', title: '全局变量污染 "userData"', line: 15 }
            ],
            content: '## 🚨 发现严重问题\n\n检测到多个高严重性漏洞。合并前必须立即采取行动。\n\n> [!IMPORTANT]\n> **阻塞问题**: 硬编码机密和 SQL 注入漏洞必须立即解决。'
        },
        {
            id: 104,
            repoId: 1,
            commitSha: 'e5f6g7h',
            branch: 'feat/user-dashboard',
            score: 88,
            status: 'COMPLETED',
            summary: '新用户仪表盘小组件和图表',
            developerEmail: 'zhaoliu@jlbank.com',
            createdAt: '2024-03-17T16:45:00Z',
            language: 'React/TSX',
            scoreBreakdown: { security: 90, reliability: 85, maintainability: 88, performance: 80 },
            issues: [
                { severity: 'minor', title: '大型组件 "DashboardGrid" 需要拆分', line: 150 },
                { severity: 'minor', title: '直接导入未优化的 SVG 资源', line: 22 }
            ],
            content: '## ✅ 良好质量\n\n仪表盘实现稳固。一些小的优化可以进一步提高可维护性。\n\n- **组件结构**: 考虑将 `DashbaordGrid` 拆分为更小的子组件。\n- **资源**: 使用图标字体或精灵图以获得更好的有效缓存。'
        },
        {
            id: 105,
            repoId: 1,
            commitSha: '9i8j0k1',
            branch: 'docs/api-specs',
            score: 99,
            status: 'COMPLETED',
            summary: '更新 v2 端点的 OpenAPI 规范',
            developerEmail: 'devops@jlbank.com',
            createdAt: '2024-03-16T11:20:00Z',
            language: 'YAML',
            scoreBreakdown: { security: 100, reliability: 100, maintainability: 98, performance: 98 },
            issues: [],
            content: '## 🏆 完美规范\n\nAPI 文档清晰、完整，并遵循所有组织标准。未发现问题。'
        }
    ];

    const fetchReviews = async () => {
        setLoading(true);
        try {
            // 优先使用 Mock 数据展示页面效果
            // const data = await getAICodeReviews({ repoId });
            // setReviews(adaptReviewData(data || []));
            await new Promise(resolve => setTimeout(resolve, 800)); // Simulate loading
            setReviews(MOCK_REVIEWS_DATA);
            if (MOCK_REVIEWS_DATA.length > 0) {
                setSelectedReview(MOCK_REVIEWS_DATA[0]);
            }
        } catch (error) {
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchReviews();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [repoId]);

    const filteredReviews = useMemo(() => {
        return reviews.filter(r => {
            const matchesSearch =
                r.commitSha.includes(searchTerm) ||
                r.branch?.includes(searchTerm) ||
                r.developerEmail?.includes(searchTerm);
            const matchesStatus = filterStatus === 'ALL' || r.status === filterStatus;
            return matchesSearch && matchesStatus;
        });
    }, [reviews, searchTerm, filterStatus]);

    const stats = useMemo(() => {
        const total = reviews.length;
        const avgScore = total > 0 ? Math.round(reviews.reduce((acc, r) => acc + (r.score || 0), 0) / total) : 0;
        const criticalIssues = reviews.reduce((acc, r) => acc + (r.status === 'FAILED' ? 1 : 0), 0);
        return { total, avgScore, criticalIssues };
    }, [reviews]);

    const getScoreColor = (score?: number) => {
        if (!score) return 'text-slate-400';
        if (score >= 90) return 'text-emerald-500';
        if (score >= 75) return 'text-indigo-500';
        if (score >= 60) return 'text-amber-500';
        return 'text-rose-500';
    };

    const getScoreBg = (score?: number) => {
        if (!score) return 'bg-slate-100';
        if (score >= 90) return 'bg-emerald-50';
        if (score >= 75) return 'bg-indigo-50';
        if (score >= 60) return 'bg-amber-50';
        return 'bg-rose-50';
    };

    const getSeverityColor = (severity: string) => {
        switch (severity) {
            case 'critical': return 'text-rose-600 bg-rose-50 border-rose-100';
            case 'major': return 'text-amber-600 bg-amber-50 border-amber-100';
            case 'minor': return 'text-blue-600 bg-blue-50 border-blue-100';
            default: return 'text-slate-600 bg-slate-50 border-slate-100';
        }
    };

    return (
        <div className="h-[calc(100vh-140px)] flex flex-col gap-5 bg-slate-50/50 p-6 rounded-3xl overflow-hidden border border-slate-100">
            {/* Dashboard Header */}
            <div className="flex-none grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-white p-4 rounded-2xl border border-slate-200/60 shadow-sm flex items-center justify-between group hover:shadow-md transition-all duration-300">
                    <div>
                        <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">代码平均质量</div>
                        <div className="text-2xl font-bold text-slate-800 flex items-center gap-2">
                            {stats.avgScore}
                            <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-md bg-emerald-50 text-emerald-600 flex items-center border border-emerald-100">
                                <ArrowUpRight size={10} className="mr-0.5" /> +2.4%
                            </span>
                        </div>
                    </div>
                    <div className="w-10 h-10 rounded-xl bg-indigo-50 flex items-center justify-center group-hover:scale-110 transition-transform">
                        <Activity size={20} className="text-indigo-600" />
                    </div>
                </div>
                <div className="bg-white p-4 rounded-2xl border border-slate-200/60 shadow-sm flex items-center justify-between group hover:shadow-md transition-all duration-300">
                    <div>
                        <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">总审查次数</div>
                        <div className="text-2xl font-bold text-slate-800">{stats.total}</div>
                    </div>
                    <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center group-hover:scale-110 transition-transform">
                        <Layers size={20} className="text-blue-600" />
                    </div>
                </div>
                <div className="bg-white p-4 rounded-2xl border border-slate-200/60 shadow-sm flex items-center justify-between group hover:shadow-md transition-all duration-300">
                    <div>
                        <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">拦截高危风险</div>
                        <div className="text-2xl font-bold text-slate-800 flex items-center gap-2">
                            {stats.criticalIssues}
                            {stats.criticalIssues > 0 && (
                                <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-md bg-rose-50 text-rose-600 border border-rose-100">需要注意</span>
                            )}
                        </div>
                    </div>
                    <div className="w-10 h-10 rounded-xl bg-rose-50 flex items-center justify-center group-hover:scale-110 transition-transform">
                        <Shield size={20} className="text-rose-600" />
                    </div>
                </div>
                <div className="bg-gradient-to-br from-indigo-600 to-purple-600 p-4 rounded-2xl shadow-lg shadow-indigo-200 text-white flex flex-col justify-center items-start cursor-pointer hover:shadow-xl hover:translate-y-[-2px] transition-all duration-300"
                    onClick={() => setIsModalVisible(true)}>
                    <div className="flex items-center gap-2 mb-2">
                        <Bot size={18} className="text-indigo-100" />
                        <span className="font-bold text-sm">开始新智查</span>
                    </div>
                    <div className="text-[10px] text-indigo-100 opacity-80 uppercase tracking-wider font-semibold">配置并运行审查</div>
                </div>
            </div>

            {/* AI Audit Config Modal */}
            <Modal
                title={
                    <div className="flex items-center gap-2 py-1">
                        <div className="w-8 h-8 rounded-lg bg-indigo-50 flex items-center justify-center">
                            <Bot size={18} className="text-indigo-600" />
                        </div>
                        <span className="text-base font-bold text-slate-800">初始化智能代码审查</span>
                    </div>
                }
                open={isModalVisible}
                onCancel={() => setIsModalVisible(false)}
                footer={null}
                width={650}
                className="crystal-modal"
                centered
            >
                <div className="py-2 space-y-6">
                    <section>
                        <h4 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                            <ArrowUpRight size={14} /> 1. 选择审查目标
                        </h4>
                        <div className="grid grid-cols-1 gap-4">
                            {/* 1. Audit Mode */}
                            <div className="space-y-1.5">
                                <label className="text-[11px] font-bold text-slate-500 ml-1">审查模式</label>
                                <Select
                                    className="w-full crystal-select"
                                    value={auditConfig.type}
                                    onChange={(v) => setAuditConfig({ ...auditConfig, type: v })}
                                >
                                    <Select.Option value="diff">增量扫描 (Diff-based)</Select.Option>
                                    <Select.Option value="full">全量扫描 (Full Repository)</Select.Option>
                                </Select>
                            </div>

                            {/* 2. Branch Selection */}
                            <div className="space-y-1.5">
                                <label className="text-[11px] font-bold text-slate-500 ml-1">目标分支/版本</label>
                                <Select
                                    className="w-full crystal-select"
                                    value={auditConfig.branch}
                                    onChange={(v) => setAuditConfig({ ...auditConfig, branch: v })}
                                >
                                    <Select.Option value="main">main (Production)</Select.Option>
                                    <Select.Option value="develop">develop (Dev)</Select.Option>
                                    <Select.Option value="feature/audit">feature/audit</Select.Option>
                                    <Select.Option value="feat-payment">feat-payment</Select.Option>
                                    <Select.Option value="fix-login">fix-login</Select.Option>
                                </Select>
                            </div>

                            {/* 3. PR Selection (Conditional) */}
                            {auditConfig.type === 'diff' && (
                                <div className="space-y-1.5 p-4 bg-indigo-50/30 rounded-2xl border border-indigo-100/50 animate-in fade-in slide-in-from-top-1">
                                    <label className="text-[11px] font-bold text-indigo-600 ml-1 flex items-center gap-1.5">
                                        <GitCommit size={12} /> 关联 Pull Request (PR)
                                    </label>
                                    <Select
                                        className="w-full crystal-select"
                                        placeholder="请搜索或选择要审计的 PR"
                                        value={auditConfig.prId}
                                        onChange={(v) => {
                                            setAuditConfig({
                                                ...auditConfig,
                                                prId: v,
                                                // 仅加载文件，不强制更改分支，分支由用户在上一步明确
                                                selectedFiles: mockFilesMap[v]?.map(f => f.path) || []
                                            });
                                        }}
                                    >
                                        {mockPRs.map(pr => (
                                            <Select.Option key={pr.id} value={pr.id}>
                                                <div className="flex items-center justify-between gap-4">
                                                    <span className="font-bold text-slate-700">{pr.title}</span>
                                                    <span className="text-[10px] text-slate-400 bg-slate-100 px-1.5 py-0.5 rounded">{pr.id}</span>
                                                </div>
                                                <div className="text-[10px] text-slate-400 mt-0.5">Author: {pr.author} · Branch: {pr.branch}</div>
                                            </Select.Option>
                                        ))}
                                    </Select>
                                </div>
                            )}
                        </div>
                    </section>

                    <section>
                        <h4 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                            <Zap size={14} /> 2. 智查策略与规则集
                        </h4>
                        <div className="bg-slate-50 p-4 rounded-2xl border border-slate-100 space-y-4">
                            <div className="grid grid-cols-2 gap-6">
                                <div className="space-y-2">
                                    <label className="text-[11px] font-bold text-slate-400">扫描深度</label>
                                    <div className="flex gap-2">
                                        {[
                                            { id: 'light', label: '基础', color: 'bg-emerald-500' },
                                            { id: 'standard', label: '标准', color: 'bg-indigo-500' },
                                            { id: 'deep', label: '全链路', color: 'bg-purple-600' }
                                        ].map(d => (
                                            <div
                                                key={d.id}
                                                onClick={() => setAuditConfig({ ...auditConfig, depth: d.id })}
                                                className={`flex-1 py-1.5 rounded-lg border text-[10px] font-bold text-center cursor-pointer transition-all
                                                    ${auditConfig.depth === d.id
                                                        ? 'bg-white border-indigo-200 text-indigo-600 shadow-sm'
                                                        : 'bg-white/50 border-transparent text-slate-400 hover:text-slate-500'}`}
                                            >
                                                {d.label}
                                            </div>
                                        ))}
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <label className="text-[11px] font-bold text-slate-400">并行扫描限制</label>
                                    <Select defaultValue="4" size="small" className="w-full crystal-select text-[10px]">
                                        <Select.Option value="2">2 Threads (Focus)</Select.Option>
                                        <Select.Option value="4">4 Threads (Standard)</Select.Option>
                                        <Select.Option value="8">8 Threads (Performance)</Select.Option>
                                    </Select>
                                </div>
                            </div>

                            <div className="space-y-2 pt-2 border-t border-slate-200/50">
                                <label className="text-[11px] font-bold text-slate-400">规则集激活</label>
                                <div className="flex flex-wrap gap-2">
                                    {[
                                        { id: 'security', label: 'Security & Auth', icon: Shield },
                                        { id: 'performance', label: 'Performance', icon: Zap },
                                        { id: 'reliability', label: 'Robustness', icon: Activity },
                                        { id: 'compliance', label: 'Finance Compliance', icon: AlertTriangle },
                                    ].map(rule => (
                                        <div
                                            key={rule.id}
                                            onClick={() => {
                                                const sets = new Set(auditConfig.rulesets);
                                                if (sets.has(rule.id)) sets.delete(rule.id);
                                                else sets.add(rule.id);
                                                setAuditConfig({ ...auditConfig, rulesets: Array.from(sets) });
                                            }}
                                            className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg border text-[10px] font-bold cursor-pointer transition-all
                                                ${auditConfig.rulesets.includes(rule.id)
                                                    ? 'bg-indigo-50 border-indigo-200 text-indigo-600'
                                                    : 'bg-white border-slate-200 text-slate-400 opacity-60'}`}
                                        >
                                            <rule.icon size={10} />
                                            {rule.label}
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>
                    </section>

                    {auditConfig.type === 'diff' && (
                        <section className="animate-in fade-in slide-in-from-top-2 duration-300">
                            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                                <FileCode size={14} /> 3. 选择变更文件 (Selective Audit)
                            </h4>
                            <div className="bg-slate-50 rounded-2xl border border-slate-100 overflow-hidden shadow-inner">
                                <div className="max-h-[160px] overflow-y-auto p-3 space-y-1">
                                    {currentFiles.length > 0 ? currentFiles.map(file => (
                                        <div
                                            key={file.path}
                                            onClick={() => {
                                                const files = new Set(auditConfig.selectedFiles);
                                                if (files.has(file.path)) files.delete(file.path);
                                                else files.add(file.path);
                                                setAuditConfig({ ...auditConfig, selectedFiles: Array.from(files) });
                                            }}
                                            className={`p-2 rounded-xl flex items-center justify-between group cursor-pointer transition-all
                                                ${auditConfig.selectedFiles.includes(file.path)
                                                    ? 'bg-white shadow-sm'
                                                    : 'hover:bg-white/50 opacity-70'}`}
                                        >
                                            <div className="flex items-center gap-2.5">
                                                <div className={`w-4 h-4 rounded flex items-center justify-center border transition-all
                                                    ${auditConfig.selectedFiles.includes(file.path) ? 'bg-indigo-500 border-indigo-500' : 'bg-white border-slate-300'}`}>
                                                    {auditConfig.selectedFiles.includes(file.path) && <Check size={10} className="text-white" />}
                                                </div>
                                                <span className="text-[11px] font-mono font-medium text-slate-600">{file.path}</span>
                                            </div>
                                            <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded uppercase ${file.type === 'new' ? 'text-emerald-500 bg-emerald-50' : 'text-indigo-500 bg-indigo-50'}`}>
                                                {file.type}
                                            </span>
                                        </div>
                                    )) : (
                                        <div className="py-8 flex flex-col items-center justify-center text-slate-300">
                                            <GitCommit size={24} className="mb-2 opacity-20" />
                                            <span className="text-[10px] font-bold uppercase tracking-wider">请先选择 PR 以加载变更文件</span>
                                        </div>
                                    )}
                                </div>
                                <div className="bg-slate-100/50 px-4 py-2 border-t border-slate-100 flex items-center justify-between">
                                    <span className="text-[10px] text-slate-400 font-bold uppercase tracking-tight">已选 {auditConfig.selectedFiles.length} 个文件</span>
                                    <button
                                        className="text-[10px] text-indigo-600 font-bold hover:underline disabled:opacity-30"
                                        disabled={currentFiles.length === 0}
                                        onClick={() => setAuditConfig({ ...auditConfig, selectedFiles: currentFiles.map(f => f.path) })}
                                    >
                                        全选变更
                                    </button>
                                </div>
                            </div>
                        </section>
                    )}

                    <section className="bg-slate-900 rounded-3xl p-5 text-white flex items-center justify-between shadow-2xl shadow-indigo-500/10">
                        <div>
                            <div className="text-sm font-bold flex items-center gap-2">
                                <Terminal size={14} className="text-indigo-400" />
                                确认智查指令
                            </div>
                            <div className="text-[10px] text-white/40 font-mono mt-1 uppercase tracking-tighter">
                                audit-ai run --mode={auditConfig.type} --rules={auditConfig.rulesets.join(',')} --scope={auditConfig.selectedFiles.length} files
                            </div>
                        </div>
                        <Button
                            type="primary"
                            size="large"
                            className="bg-indigo-500 border-none shadow-xl shadow-indigo-500/30 font-bold px-10 h-11 rounded-2xl hover:scale-105 transition-all"
                            onClick={() => {
                                setIsModalVisible(false);
                                fetchReviews();
                            }}
                        >
                            执行分析流程
                        </Button>
                    </section>
                </div>
            </Modal>

            {/* Issue Detail Modal */}
            <Modal
                title={null}
                open={isIssueModalOpen}
                onCancel={() => setIsIssueModalOpen(false)}
                footer={null}
                width={500}
                className="crystal-modal"
                centered
                destroyOnClose
            >
                {selectedIssue && (
                    <div className="pt-2">
                        <div className="flex items-start gap-3 mb-5">
                            <div className={`mt-1 flex-none px-2.5 py-1 rounded-md text-[10px] font-extrabold uppercase tracking-wide border ${getSeverityColor(selectedIssue.severity)}`}>
                                {selectedIssue.severity}
                            </div>
                            <h3 className="text-lg font-bold text-slate-800 leading-snug">
                                {selectedIssue.title}
                            </h3>
                        </div>

                        <div className="space-y-6">
                            <div className="bg-slate-50 p-4 rounded-xl border border-slate-100/80">
                                <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                    <AlertTriangle size={12} /> 问题描述
                                </h4>
                                <p className="text-sm text-slate-600 leading-relaxed">
                                    {selectedIssue.description || '暂无详细描述。'}
                                </p>
                            </div>

                            {selectedIssue.line && (
                                <div>
                                    <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                        <FileCode size={12} /> 代码位置
                                    </h4>
                                    <div className="font-mono text-xs text-slate-600 bg-white border border-slate-200 px-3 py-2 rounded-lg flex items-center gap-2">
                                        <Terminal size={12} className="text-slate-400" />
                                        Line {selectedIssue.line}
                                    </div>
                                </div>
                            )}

                            {selectedIssue.codeSnippet && (
                                <div>
                                    <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                        <FileCode size={12} /> 问题代码片段
                                    </h4>
                                    <div className="bg-slate-800 rounded-xl overflow-hidden border border-slate-700 shadow-inner">
                                        <div className="flex items-center gap-1.5 px-3 py-2 bg-slate-900/50 border-b border-white/5">
                                            <div className="w-2.5 h-2.5 rounded-full bg-rose-500/20 border border-rose-500/50"></div>
                                            <div className="w-2.5 h-2.5 rounded-full bg-amber-500/20 border border-amber-500/50"></div>
                                            <div className="w-2.5 h-2.5 rounded-full bg-emerald-500/20 border border-emerald-500/50"></div>
                                            <span className="text-[10px] text-slate-500 ml-2 font-mono">source.ts</span>
                                        </div>
                                        <div className="p-4 overflow-x-auto">
                                            <pre className="font-mono text-[11px] leading-relaxed text-slate-300">
                                                <code>{selectedIssue.codeSnippet}</code>
                                            </pre>
                                        </div>
                                    </div>
                                </div>
                            )}

                            <div>
                                <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1.5">
                                    <Zap size={12} className="text-amber-500 fill-amber-500" /> AI 修复建议
                                </h4>
                                <div className="bg-amber-50/50 p-4 rounded-xl border border-amber-100/50">
                                    <p className="text-sm text-slate-700 leading-relaxed before:content-['💡'] before:mr-2">
                                        {selectedIssue.recommendation || 'AI 正在分析最佳修复方案...'}
                                    </p>
                                </div>
                            </div>
                        </div>

                        <div className="mt-8 flex justify-end gap-3">
                            <Button onClick={() => setIsIssueModalOpen(false)} className="rounded-xl border-slate-200 text-slate-500 text-xs font-bold hover:text-slate-700 hover:border-slate-300">
                                关闭
                            </Button>
                            <Button type="primary" className="bg-indigo-600 rounded-xl shadow-lg shadow-indigo-200 text-xs font-bold flex items-center gap-1.5">
                                <Zap size={12} />
                                自动修复
                            </Button>
                        </div>
                    </div>
                )}
            </Modal>

            <div className="flex-1 flex gap-5 overflow-hidden">
                {/* Left Listing */}
                <div className="w-[340px] flex-none flex flex-col bg-white rounded-2xl border border-slate-200/60 shadow-sm overflow-hidden">
                    <div className="p-4 border-b border-slate-100 space-y-3 bg-slate-50/30">
                        <div className="flex items-center gap-2 bg-white px-3 py-2.5 rounded-xl border border-slate-200 focus-within:border-indigo-300 focus-within:ring-2 focus-within:ring-indigo-100 transition-all shadow-sm">
                            <Search size={14} className="text-slate-400" />
                            <input
                                type="text"
                                placeholder="搜索 Commit, Branch..."
                                className="bg-transparent border-none outline-none text-xs w-full placeholder:text-slate-400 text-slate-700 font-medium"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
                            {['ALL', 'COMPLETED', 'FAILED', 'PENDING'].map(status => (
                                <button
                                    key={status}
                                    onClick={() => setFilterStatus(status)}
                                    className={`px-3 py-1 text-[10px] font-bold rounded-full border whitespace-nowrap transition-all duration-200
                                        ${filterStatus === status
                                            ? 'bg-indigo-50 border-indigo-200 text-indigo-600 shadow-sm'
                                            : 'bg-white border-slate-200 text-slate-400 hover:border-slate-300 hover:text-slate-500'}`}
                                >
                                    {status}
                                </button>
                            ))}
                        </div>
                    </div>
                    <div className="flex-1 overflow-y-auto p-3 space-y-2.5">
                        {loading && reviews.length === 0 ? (
                            <div className="flex flex-col items-center justify-center p-10 text-slate-300 gap-2">
                                <Loader className="animate-spin" size={20} />
                                <span className="text-xs font-medium">Loading data...</span>
                            </div>
                        ) : filteredReviews.map(review => (
                            <div
                                key={review.id}
                                onClick={() => setSelectedReview(review)}
                                className={`group p-3.5 rounded-xl border cursor-pointer transition-all duration-200 relative overflow-hidden
                                    ${selectedReview?.id === review.id
                                        ? 'border-indigo-500 bg-indigo-50/20 ring-1 ring-indigo-500/20 shadow-sm'
                                        : 'border-slate-100 bg-white hover:border-indigo-200 hover:shadow-md hover:-translate-y-0.5'}`}
                            >
                                {selectedReview?.id === review.id && (
                                    <div className="absolute left-0 top-3 bottom-3 w-1 bg-indigo-500 rounded-r-full" />
                                )}
                                <div className="flex justify-between items-start mb-2 pl-2">
                                    <div className="flex items-center gap-2">
                                        <div className={`w-2 h-2 rounded-full ring-2 ring-white shadow-sm ${review.status === 'COMPLETED' ? 'bg-emerald-400' : 'bg-amber-400'}`} />
                                        <span className="text-xs font-mono font-bold text-slate-700 bg-slate-100 px-1.5 py-0.5 rounded text-[10px]">
                                            {review.commitSha.substring(0, 7)}
                                        </span>
                                    </div>
                                    <div className={`text-sm font-bold ${getScoreColor(review.score)}`}>
                                        {review.score ?? '-'}
                                    </div>
                                </div>
                                <div className="pl-2 mb-2">
                                    <h4 className="text-xs text-slate-700 line-clamp-1 font-semibold">{review.summary || '等待分析...'}</h4>
                                    <div className="flex items-center gap-1.5 mt-1.5">
                                        <GitCommit size={10} className="text-slate-400" />
                                        <span className="text-[10px] font-medium text-slate-400 truncate max-w-[140px] bg-slate-50 px-1.5 py-0.5 rounded border border-slate-100">
                                            {review.branch}
                                        </span>
                                    </div>
                                </div>
                                <div className="pl-2 flex items-center justify-between text-[10px] text-slate-400 pt-2 border-t border-slate-50 mt-2">
                                    <div className="flex items-center gap-1.5">
                                        <User size={10} />
                                        <span className="font-medium">{review.developerEmail?.split('@')[0] || 'Unknown'}</span>
                                    </div>
                                    <span className="font-mono opacity-80">{review.createdAt ? new Date(review.createdAt).toLocaleDateString() : ''}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Right Detail Pane */}
                <div className="flex-1 bg-white rounded-2xl border border-slate-200/60 shadow-sm flex flex-col overflow-hidden relative">
                    {selectedReview ? (
                        <>
                            {/* Detail Header */}
                            <div className="p-6 border-b border-slate-100 bg-slate-50/20 backdrop-blur-sm">
                                <div className="flex flex-wrap gap-6 items-start justify-between">
                                    <div className="flex items-center gap-5">
                                        <div className={`relative w-20 h-20 rounded-2xl flex items-center justify-center text-3xl font-bold shadow-lg shadow-slate-200/50 ${getScoreBg(selectedReview.score)} ${getScoreColor(selectedReview.score)}`}>
                                            <svg className="absolute inset-0 w-full h-full -rotate-90 pointer-events-none p-1" viewBox="0 0 100 100">
                                                <circle className="text-slate-200 opacity-20" strokeWidth="6" stroke="currentColor" fill="transparent" r="42" cx="50" cy="50" />
                                                <circle
                                                    className={`transition-all duration-1000 ease-out ${selectedReview.score && selectedReview.score >= 90 ? 'text-emerald-500' : 'text-indigo-500'}`}
                                                    strokeWidth="6"
                                                    strokeDasharray={264}
                                                    strokeDashoffset={264 - (264 * (selectedReview.score || 0)) / 100}
                                                    strokeLinecap="round"
                                                    stroke="currentColor"
                                                    fill="transparent"
                                                    r="42"
                                                    cx="50"
                                                    cy="50"
                                                />
                                            </svg>
                                            {selectedReview.score || '?'}
                                        </div>
                                        <div>
                                            <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-2">
                                                代码质量评估报告
                                                {selectedReview.score && selectedReview.score >= 90 && (
                                                    <Badge status="success" text={<span className="text-emerald-600 text-xs font-bold uppercase tracking-wider bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-100">卓越</span>} />
                                                )}
                                            </h2>
                                            <div className="flex items-center gap-3 text-xs text-slate-500">
                                                <div className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-white border border-slate-200 shadow-sm">
                                                    <FileCode size={12} className="text-slate-400" />
                                                    <span className="font-mono text-slate-700 font-semibold">{selectedReview.language || 'TypeScript'}</span>
                                                </div>
                                                <div className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-white border border-slate-200 shadow-sm">
                                                    <GitCommit size={12} className="text-slate-400" />
                                                    <span className="font-mono text-slate-700 font-semibold">{selectedReview.commitSha.substring(0, 7)}</span>
                                                </div>
                                                <div className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-white border border-slate-200 shadow-sm">
                                                    <Clock size={12} className="text-slate-400" />
                                                    <span className="font-mono text-slate-700 font-semibold">{new Date(selectedReview.createdAt || '').toLocaleString()}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Multi-dim Score */}
                                    <div className="flex items-center gap-4 bg-white p-2 rounded-xl border border-slate-100 shadow-sm">
                                        {[
                                            { label: '安全性', score: selectedReview.scoreBreakdown?.security, icon: Shield },
                                            { label: '可靠性', score: selectedReview.scoreBreakdown?.reliability, icon: AlertTriangle },
                                            { label: '可维护', score: selectedReview.scoreBreakdown?.maintainability, icon: Layers },
                                            { label: '高性能', score: selectedReview.scoreBreakdown?.performance, icon: Zap },
                                        ].map(item => (
                                            <div key={item.label} className="flex flex-col items-center gap-1 px-2 border-r last:border-0 border-slate-100">
                                                <div className="relative w-8 h-8">
                                                    <Progress
                                                        type="circle"
                                                        percent={item.score}
                                                        width={32}
                                                        strokeWidth={10}
                                                        showInfo={false}
                                                        strokeColor={item.score && item.score >= 80 ? '#10b981' : item.score && item.score >= 60 ? '#f59e0b' : '#ef4444'}
                                                        trailColor="#f1f5f9"
                                                    />
                                                    <div className="absolute inset-0 flex items-center justify-center">
                                                        <item.icon size={10} className="text-slate-400" />
                                                    </div>
                                                </div>
                                                <span className="text-[9px] font-bold text-slate-400 uppercase tracking-tight mt-1">{item.label}</span>
                                                <span className="text-[10px] font-bold text-slate-700">{item.score}</span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            </div>

                            {/* Detail Content */}
                            <div className="flex-1 overflow-y-auto p-6 grid grid-cols-1 xl:grid-cols-3 gap-6 bg-slate-50/20">
                                {/* Main Content - MD Render */}
                                <div className="xl:col-span-2 space-y-6">
                                    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                                        <div className="bg-slate-50/50 px-5 py-3 border-b border-slate-100 flex items-center gap-2">
                                            <Bot size={16} className="text-indigo-500" />
                                            <span className="text-xs font-bold text-indigo-900 uppercase tracking-wide">AI 分析报告</span>
                                        </div>
                                        <div className="p-6 prose prose-sm prose-slate max-w-none prose-headings:font-bold prose-h3:text-indigo-600 prose-pre:bg-slate-900 prose-pre:text-slate-50 prose-a:text-indigo-500 hover:prose-a:text-indigo-600">
                                            {selectedReview.content ? (
                                                <ReactMarkdown>{selectedReview.content}</ReactMarkdown>
                                            ) : (
                                                <div className="flex flex-col items-center justify-center py-16 opacity-50">
                                                    <Loader size={32} className="animate-spin text-indigo-500 mb-3" />
                                                    <span className="font-medium text-slate-500">正在分析代码结构...</span>
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>

                                {/* Sidebar - Issues & Stats */}
                                <div className="space-y-6">
                                    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                                        <div className="bg-slate-50/50 px-5 py-3 border-b border-slate-100 flex items-center justify-between">
                                            <span className="text-xs font-bold text-slate-700 uppercase flex items-center gap-2 tracking-wide">
                                                <AlertTriangle size={14} className="text-amber-500" />
                                                检测到的问题
                                            </span>
                                            <div className="px-2 py-0.5 bg-slate-100 rounded-full text-[10px] font-bold text-slate-500">
                                                {selectedReview.issues?.length || 0}
                                            </div>
                                        </div>
                                        <div className="divide-y divide-slate-50">
                                            {selectedReview.issues?.map((issue, idx) => (
                                                <div
                                                    key={idx}
                                                    className="p-4 transition-all group border-l-2 cursor-pointer hover:bg-slate-50 border-transparent hover:border-indigo-300"
                                                    onClick={() => {
                                                        setSelectedIssue(issue);
                                                        setIsIssueModalOpen(true);
                                                    }}
                                                >
                                                    <div className="flex items-start gap-2.5">
                                                        <span className={`mt-0.5 px-2 py-0.5 rounded text-[9px] font-extrabold uppercase tracking-wide border ${getSeverityColor(issue.severity)}`}>
                                                            {issue.severity}
                                                        </span>
                                                        <span className="text-xs font-semibold leading-relaxed transition-colors flex-1 text-slate-700 group-hover:text-indigo-700">
                                                            {issue.title}
                                                        </span>
                                                        <ArrowUpRight size={12} className="text-slate-300 transition-transform duration-300 group-hover:text-indigo-300 group-hover:rotate-45" />
                                                    </div>

                                                    {issue.line && (
                                                        <div className="mt-2 ml-1 pl-3 border-l-2 border-slate-200 text-[10px] font-mono text-slate-500 flex items-center gap-1 group-hover:border-indigo-100">
                                                            <Terminal size={10} />
                                                            Line {issue.line}
                                                        </div>
                                                    )}
                                                </div>
                                            ))}
                                            {(!selectedReview.issues || selectedReview.issues.length === 0) && (
                                                <div className="p-10 text-center text-xs text-slate-400 bg-slate-50/30">
                                                    <CheckCircle size={32} className="mx-auto mb-3 text-emerald-400 opacity-80" />
                                                    <div className="font-semibold text-slate-500">代码库整洁</div>
                                                    <div className="mt-1 opacity-70">本次审查未发现重大问题</div>
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    <div className="bg-gradient-to-br from-indigo-600 via-indigo-500 to-purple-600 rounded-2xl p-6 text-white shadow-lg shadow-indigo-200 relative overflow-hidden group">
                                        <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity duration-500">
                                            <Bot size={100} />
                                        </div>
                                        <h3 className="font-bold mb-2 relative z-10 flex items-center gap-2">
                                            <Zap size={16} className="text-yellow-300" />
                                            AI 智能优化
                                        </h3>
                                        <p className="text-xs text-indigo-100 mb-5 relative z-10 opacity-90 leading-relaxed">
                                            AI 可以自动为检测到的 {selectedReview.issues?.length || 0} 个问题生成修复方案。
                                        </p>
                                        <button className="relative z-10 w-full bg-white/10 hover:bg-white/20 border border-white/30 text-white text-xs font-bold py-2.5 rounded-xl transition-all backdrop-blur-md flex items-center justify-center gap-2 shadow-inner">
                                            <span>应用自动修复</span>
                                            <ArrowUpRight size={12} />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </>
                    ) : (
                        <div className="absolute inset-0 flex flex-col items-center justify-center text-slate-300 bg-slate-50/30">
                            <div className="w-24 h-24 bg-white rounded-full flex items-center justify-center mb-6 shadow-sm border border-slate-100">
                                <Search size={40} className="text-slate-200" />
                            </div>
                            <h3 className="text-lg font-bold text-slate-700 mb-2">准备开始分析</h3>
                            <p className="text-sm font-medium text-slate-400 max-w-xs text-center leading-relaxed">从左侧选择一个审查记录以查看详细的 AI 分析和质量指标。</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default AICodeAudit;
