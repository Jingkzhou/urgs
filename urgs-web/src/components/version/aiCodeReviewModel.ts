import { AICodeReview } from '@/api/version';

export type AuditSeverity = 'critical' | 'major' | 'minor';

export interface AuditIssue {
    severity: AuditSeverity;
    title: string;
    line?: number;
    description?: string;
    recommendation?: string;
    codeSnippet?: string;
}

export interface AuditScoreBreakdown {
    security: number;
    reliability: number;
    maintainability: number;
    performance: number;
}

export interface ParsedAICodeReview extends AICodeReview {
    scoreBreakdown: AuditScoreBreakdown;
    issues: AuditIssue[];
    reportContent: string;
    displaySummary: string;
}

export interface ReviewStats {
    total: number;
    completed: number;
    pending: number;
    failed: number;
    averageScore: number;
    criticalIssues: number;
    majorIssues: number;
    minorIssues: number;
}

const DEFAULT_BREAKDOWN: AuditScoreBreakdown = {
    security: 0,
    reliability: 0,
    maintainability: 0,
    performance: 0,
};

const normalizeScore = (value: unknown, fallback = 0) => {
    const num = Number(value);
    if (!Number.isFinite(num)) {
        return fallback;
    }
    return Math.max(0, Math.min(100, Math.round(num)));
};

const normalizeSeverity = (value: unknown): AuditSeverity => {
    const text = String(value || '').toLowerCase();
    if (text.includes('critical') || text.includes('严重') || text.includes('高危')) {
        return 'critical';
    }
    if (text.includes('major') || text.includes('主要') || text.includes('中等')) {
        return 'major';
    }
    return 'minor';
};

const stripMarkdownFence = (content: string) => {
    const trimmed = content.trim();
    if (!trimmed.startsWith('```')) {
        return trimmed;
    }
    return trimmed
        .replace(/^```(?:json)?\s*/i, '')
        .replace(/\s*```$/i, '')
        .trim();
};

const parseContentJson = (content?: string) => {
    if (!content) {
        return null;
    }
    const normalized = stripMarkdownFence(content);
    if (!normalized.startsWith('{')) {
        return null;
    }
    try {
        return JSON.parse(normalized);
    } catch (error) {
        console.warn('Failed to parse AI code review content', error);
        return null;
    }
};

const normalizeIssues = (issues: unknown): AuditIssue[] => {
    if (!Array.isArray(issues)) {
        return [];
    }
    return issues
        .map((issue): AuditIssue | null => {
            if (!issue || typeof issue !== 'object') {
                return null;
            }
            const raw = issue as Record<string, unknown>;
            const title = String(raw.title || '').trim();
            if (!title) {
                return null;
            }
            const lineValue = Number(raw.line);
            return {
                severity: normalizeSeverity(raw.severity),
                title,
                line: Number.isFinite(lineValue) ? lineValue : undefined,
                description: raw.description ? String(raw.description) : undefined,
                recommendation: raw.recommendation ? String(raw.recommendation) : undefined,
                codeSnippet: raw.codeSnippet ? String(raw.codeSnippet) : undefined,
            };
        })
        .filter((issue): issue is AuditIssue => Boolean(issue));
};

export const parseAICodeReview = (review: AICodeReview): ParsedAICodeReview => {
    const parsed = parseContentJson(review.content);
    const score = normalizeScore(parsed?.score, review.score ?? 0);
    const fallbackBreakdown = {
        security: score,
        reliability: score,
        maintainability: score,
        performance: score,
    };
    const scoreBreakdown: AuditScoreBreakdown = {
        security: normalizeScore(parsed?.scoreBreakdown?.security, fallbackBreakdown.security),
        reliability: normalizeScore(parsed?.scoreBreakdown?.reliability, fallbackBreakdown.reliability),
        maintainability: normalizeScore(parsed?.scoreBreakdown?.maintainability, fallbackBreakdown.maintainability),
        performance: normalizeScore(parsed?.scoreBreakdown?.performance, fallbackBreakdown.performance),
    };
    const issues = normalizeIssues(parsed?.issues);
    const reportContent = String(parsed?.content || review.content || '').trim();
    const displaySummary = String(parsed?.summary || review.summary || reportContent || '等待 AI 完成报告').trim();

    return {
        ...review,
        score: score || review.score,
        summary: parsed?.summary || review.summary,
        scoreBreakdown: review.status === 'COMPLETED' ? scoreBreakdown : DEFAULT_BREAKDOWN,
        issues,
        reportContent,
        displaySummary,
    };
};

export const parseAICodeReviews = (reviews: AICodeReview[] = []) => {
    return reviews.map(parseAICodeReview);
};

export const getSeverityLabel = (severity: AuditSeverity) => {
    switch (severity) {
        case 'critical':
            return '高危';
        case 'major':
            return '主要';
        default:
            return '一般';
    }
};

export const getSeverityClassName = (severity: AuditSeverity) => {
    switch (severity) {
        case 'critical':
            return 'bg-rose-50 text-rose-700 border-rose-200';
        case 'major':
            return 'bg-amber-50 text-amber-700 border-amber-200';
        default:
            return 'bg-sky-50 text-sky-700 border-sky-200';
    }
};

export const getScoreTone = (score?: number) => {
    if (!score) {
        return {
            text: 'text-slate-400',
            bg: 'bg-slate-100',
            border: 'border-slate-200',
            stroke: '#94a3b8',
            label: '待评分',
        };
    }
    if (score >= 90) {
        return {
            text: 'text-emerald-700',
            bg: 'bg-emerald-50',
            border: 'border-emerald-200',
            stroke: '#10b981',
            label: '可合并',
        };
    }
    if (score >= 75) {
        return {
            text: 'text-sky-700',
            bg: 'bg-sky-50',
            border: 'border-sky-200',
            stroke: '#0284c7',
            label: '低风险',
        };
    }
    if (score >= 60) {
        return {
            text: 'text-amber-700',
            bg: 'bg-amber-50',
            border: 'border-amber-200',
            stroke: '#f59e0b',
            label: '需复核',
        };
    }
    return {
        text: 'text-rose-700',
        bg: 'bg-rose-50',
        border: 'border-rose-200',
        stroke: '#e11d48',
        label: '阻断',
    };
};

export const getStatusLabel = (status: AICodeReview['status']) => {
    switch (status) {
        case 'COMPLETED':
            return '已完成';
        case 'PENDING':
            return '分析中';
        case 'FAILED':
            return '失败';
        default:
            return status;
    }
};

export const getStatusClassName = (status: AICodeReview['status']) => {
    switch (status) {
        case 'COMPLETED':
            return 'bg-emerald-50 text-emerald-700 border-emerald-200';
        case 'PENDING':
            return 'bg-amber-50 text-amber-700 border-amber-200';
        case 'FAILED':
            return 'bg-rose-50 text-rose-700 border-rose-200';
        default:
            return 'bg-slate-50 text-slate-600 border-slate-200';
    }
};

export const summarizeReviews = (reviews: ParsedAICodeReview[]): ReviewStats => {
    const completed = reviews.filter((review) => review.status === 'COMPLETED');
    const averageScore = completed.length
        ? Math.round(completed.reduce((sum, review) => sum + (review.score || 0), 0) / completed.length)
        : 0;

    return {
        total: reviews.length,
        completed: completed.length,
        pending: reviews.filter((review) => review.status === 'PENDING').length,
        failed: reviews.filter((review) => review.status === 'FAILED').length,
        averageScore,
        criticalIssues: reviews.reduce((sum, review) => sum + review.issues.filter((issue) => issue.severity === 'critical').length, 0),
        majorIssues: reviews.reduce((sum, review) => sum + review.issues.filter((issue) => issue.severity === 'major').length, 0),
        minorIssues: reviews.reduce((sum, review) => sum + review.issues.filter((issue) => issue.severity === 'minor').length, 0),
    };
};
