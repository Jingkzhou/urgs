import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Alert, Button, Card, Descriptions, Drawer, Empty, Input, message, Modal, Popconfirm, Space, Spin, Tag } from 'antd';
import {
    clearLineageReviewHistory,
    decideLineageReviewIssue,
    downloadLineageReviewReportMarkdown,
    getLineageReviewIssue,
    getLineageReviewMemories,
    getLineageReviewIssues,
    getLineageReviewRecords,
    getLineageReviewTaskSqlPreview,
    getLineageReviewTasks,
    triggerLineageReview,
    updateLineageReviewMemory,
    LineageAnalysisRecordItem,
    LineageReviewIssue,
    LineageReviewMemory,
    LineageReviewTask
} from '@/api/lineage';
import { hasPermission } from '@/utils/permission';
import ReviewIssueTable from './lineage-review/ReviewIssueTable';
import ReviewIssueDetail from './lineage-review/ReviewIssueDetail';
import ReviewMetricCards from './lineage-review/ReviewMetricCards';
import ReviewRecordList from './lineage-review/ReviewRecordList';
import ReviewTaskTable from './lineage-review/ReviewTaskTable';
import {
    confirmedProblemTypeLabelMap,
    issueTypeLabelMap,
    reviewStatusLabelMap,
    ruleHitLabelMap,
    severityLabelMap,
    toDisplayLabel,
    verdictLabelMap
} from './lineage-review/reviewConstants';
import { buildShardLabel, buildTaskSourceMeta } from './lineage-review/reviewUtils';

const { TextArea } = Input;

const statementAuditStatusLabelMap: Record<string, string> = {
    PENDING: '待处理',
    SCREENING: '初筛中',
    SCREENED_NO_ISSUE: '初筛无疑点',
    WAITING_VERIFICATION: '待精审',
    VERIFIED_ISSUE: '精审有疑点',
    VERIFIED_NO_ISSUE: '精审无疑点',
    CACHED: '命中缓存',
    FAILED: '审核失败',
    SKIPPED_BUDGET: '预算跳过'
};

const statementAuditStatusColorMap: Record<string, string> = {
    PENDING: 'default',
    SCREENING: 'processing',
    SCREENED_NO_ISSUE: 'success',
    WAITING_VERIFICATION: 'processing',
    VERIFIED_ISSUE: 'warning',
    VERIFIED_NO_ISSUE: 'success',
    CACHED: 'cyan',
    FAILED: 'error',
    SKIPPED_BUDGET: 'error'
};

const statementRiskReasonLabelMap: Record<string, string> = {
    METADATA_AMBIGUITY: '元数据歧义',
    LOW_CONFIDENCE_RELATION: '低置信关系',
    IMPLICIT_TARGET_MAPPING: '目标映射不明确',
    SELECT_STAR: '使用 SELECT *',
    DYNAMIC_SQL: '动态 SQL',
    PARSER_VALIDATION_WARNING: '解析校验告警',
    LONG_SQL: '超长 SQL',
    HIGH_RELATION_COMPLEXITY: '关系复杂度高'
};

const AICodeReport: React.FC = () => {
    const [records, setRecords] = useState<LineageAnalysisRecordItem[]>([]);
    const [tasks, setTasks] = useState<LineageReviewTask[]>([]);
    const [taskSummaryMap, setTaskSummaryMap] = useState<Record<string, LineageReviewTask[]>>({});
    const [issues, setIssues] = useState<LineageReviewIssue[]>([]);
    const [recordLoading, setRecordLoading] = useState(false);
    const [taskLoading, setTaskLoading] = useState(false);
    const [issueLoading, setIssueLoading] = useState(false);
    const [triggerLoading, setTriggerLoading] = useState(false);
    const [selectedRecordId, setSelectedRecordId] = useState<string>();
    const [selectedTaskId, setSelectedTaskId] = useState<number>();
    const [severityFilter, setSeverityFilter] = useState<string>();
    const [reviewStatusFilter, setReviewStatusFilter] = useState<string>('PENDING');
    const [searchTerm, setSearchTerm] = useState('');
    const [recordPage, setRecordPage] = useState(1);
    const [recordPageSize, setRecordPageSize] = useState(6);
    const [taskPage, setTaskPage] = useState(1);
    const [taskPageSize, setTaskPageSize] = useState(10);
    const [selectedIssue, setSelectedIssue] = useState<LineageReviewIssue | null>(null);
    const [issueDetailLoading, setIssueDetailLoading] = useState(false);
    const issueDetailRequestRef = useRef(0);
    const [decisionLoading, setDecisionLoading] = useState<string>('');
    const [sqlPreviewOpen, setSqlPreviewOpen] = useState(false);
    const [sqlPreviewLoading, setSqlPreviewLoading] = useState(false);
    const [sqlPreviewTask, setSqlPreviewTask] = useState<LineageReviewTask | null>(null);
    const [reportDownloading, setReportDownloading] = useState(false);
    const [clearHistoryLoading, setClearHistoryLoading] = useState(false);
    const [confirmProblemModalOpen, setConfirmProblemModalOpen] = useState(false);
    const [confirmedProblemType, setConfirmedProblemType] = useState('SQL_STANDARD');
    const [confirmedProblemDescription, setConfirmedProblemDescription] = useState('');
    const [falsePositiveModalOpen, setFalsePositiveModalOpen] = useState(false);
    const [falsePositiveReason, setFalsePositiveReason] = useState('');
    const [memoryOpen, setMemoryOpen] = useState(false);
    const [memoryLoading, setMemoryLoading] = useState(false);
    const [memorySaving, setMemorySaving] = useState(false);
    const [memories, setMemories] = useState<LineageReviewMemory[]>([]);
    const [selectedMemoryId, setSelectedMemoryId] = useState<number>();
    const [memoryDraft, setMemoryDraft] = useState({ title: '', content: '', status: 'ACTIVE' });
    const [sqlPreviews, setSqlPreviews] = useState<Array<{
        statementUid?: string;
        snippet: string;
        sourceFiles: string[];
        relationCount: number;
        auditStatus?: string;
        riskScore?: number;
        riskReasons: string[];
        highRisk?: boolean;
        screeningCandidate?: boolean;
        aiCallCount?: number;
        auditIssueCount?: number;
        skipReason?: string;
    }>>([]);

    const canTrigger = hasPermission('version:ai:trigger');
    const canExport = hasPermission('version:ai:export');

    const selectedRecord = useMemo(
        () => records.find(item => item.id === selectedRecordId),
        [records, selectedRecordId]
    );

    const selectedTask = useMemo(
        () => tasks.find(item => item.id === selectedTaskId),
        [tasks, selectedTaskId]
    );

    const selectedTaskSourceMeta = useMemo(
        () => selectedTask ? buildTaskSourceMeta(selectedTask, records) : undefined,
        [records, selectedTask]
    );

    const selectedMemory = useMemo(
        () => memories.find(item => item.id === selectedMemoryId),
        [memories, selectedMemoryId]
    );

    const pagedRecords = useMemo(() => {
        const start = (recordPage - 1) * recordPageSize;
        return records.slice(start, start + recordPageSize);
    }, [records, recordPage, recordPageSize]);

    const filteredIssues = useMemo(() => {
        const keyword = searchTerm.trim().toLowerCase();
        if (!keyword) {
            return issues;
        }
        return issues.filter(issue => {
            const target = [
                issue.tableName,
                issue.columnName,
                issue.issueType,
                issue.reason,
                issue.graphSnapshot?.aiReview?.summary,
                issue.graphSnapshot?.aiReview?.currentState,
                issue.graphSnapshot?.aiReview?.expectedState
            ]
                .filter(Boolean)
                .join(' ')
                .toLowerCase();
            return target.includes(keyword);
        });
    }, [issues, searchTerm]);

    const downloadBlob = (blob: Blob, fileName: string) => {
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
    };

    const normalizeMarkdownValue = (value?: string | number | null) => {
        if (value === undefined || value === null || value === '') {
            return '-';
        }
        return String(value);
    };

    const normalizeMarkdownBlock = (value?: string | number | null) => {
        return normalizeMarkdownValue(value).split(/\r?\n/).map(line => line.trimEnd()).join('\n');
    };

    const appendMarkdownList = (lines: string[], title: string, items?: string[]) => {
        lines.push(`## ${title}`, '');
        if (!items || items.length === 0) {
            lines.push('- -', '');
            return;
        }
        items.forEach(item => lines.push(`- ${item}`));
        lines.push('');
    };

    const appendMarkdownCodeBlock = (
        lines: string[],
        title: string,
        language: string,
        content?: string | null
    ) => {
        lines.push(`## ${title}`, '', `\`\`\`\`${language}`, content || '-', '\`\`\`\`', '');
    };

    const buildIssueMarkdownReport = (issue: LineageReviewIssue) => {
        const target = `${issue.tableName || '-'}${issue.columnName ? `.${issue.columnName}` : ''}`;
        const snapshot = issue.graphSnapshot || {};
        const presentation = snapshot.aiReview;
        const ruleHits = (issue.ruleHits || []).map(item => `${toDisplayLabel(item, ruleHitLabelMap)} (${item})`);
        const sourceFiles = Array.isArray(snapshot.sourceFiles)
            ? snapshot.sourceFiles.map(item => String(item))
            : [];
        const evidenceRefs = presentation?.evidenceRefs || issue.evidenceRefs || [];
        const lines = [
            `# SQL 血缘解析程序独立自检任务 - ${target}`,
            '',
            '> 使用方式：将本文完整发送给能够阅读代码的 AI，并同时提供 SQL 血缘解析程序仓库。',
            '> 本文中的“已有疑点”和“已有 AI 判断”都只是待验证假设，不是正确答案。',
            '',
            '## 给 AI 的任务话术',
            '',
            '你是一名资深 SQL 解析器与字段级数据血缘工程师。请根据本文提供的 SQL 原文、程序解析关系、图谱查询结果和证据编号，独立检查 SQL 血缘解析程序是否存在问题。',
            '',
            '不要复述或默认接受已有疑点结论。你必须先独立推导 SQL 的正确字段级语义，再与程序输出逐项比较，并在能够访问代码仓库时继续定位到具体解析阶段、代码位置和可复现测试。',
            '',
            '你需要回答以下核心问题：',
            '',
            '1. 根据 SQL 本身，目标字段应有哪些直接值来源、条件影响、过滤、关联、分组或排序依赖？',
            '2. `programRelations` 是否准确表达这些关系？是否存在遗漏来源、错误来源、错误目标、字段错位或关系类型错误？',
            '3. `graphFieldRelations` 与 `programRelations` 是否一致？若不一致，问题更可能发生在解析、事实持久化、入图还是查询投影阶段？',
            '4. 已有疑点是否成立？如果不成立，明确说明它为什么是误报。',
            '5. 如果程序存在问题，给出最小修复方向、应检查的代码路径以及可直接加入测试集的最小 SQL 回归用例和期望关系。',
            '',
            '## 强制检查规则',
            '',
            '- 只依据本文证据和仓库代码判断；证据不足时必须明确写出缺失项，不得臆造表、字段或关系。',
            '- SQL 原文是语义真值来源；已有 AI 结论、疑点类型、严重级别和建议来源只能作为待验证线索。',
            '- 必须区分值级派生与条件影响。`CASE_WHEN`、`FILTERS`、`JOINS`、`GROUPS`、`ORDERS` 不应被一律当成 `DERIVES_TO`。',
            '- 表级关系或字段摘要不能证明一一字段映射；只有明确的源字段和目标字段才能作为字段级关系证据。',
            '- 对 INSERT/SELECT、CTE、子查询、别名、星号展开、窗口函数、CASE/IF、UNION、JOIN USING、GROUP BY/HAVING 等结构，必须检查作用域和目标列位置映射。',
            '- 如果 SQL 片段不完整、依赖动态 SQL、缺少 DDL/字段元数据或无法确定目标列顺序，应判定为证据不足，并说明还需要什么。',
            '',
            '## 必须采用的检查步骤',
            '',
            '1. 独立阅读 SQL，识别语句类型、目标表、目标字段、各层查询作用域和别名绑定。',
            '2. 针对本疑点目标字段，人工推导期望的字段级关系集合，并给每条关系标注关系类型。',
            '3. 用证据编号逐条对比 `programRelations`，找出缺失、冗余、错连、错位或类型错误。',
            '4. 再对比 `graphFieldRelations`，判断解析输出是否在后续持久化或查询阶段发生丢失或变形。',
            '5. 阅读仓库代码，定位最可能的处理阶段和条件分支；不要仅根据类名猜测。',
            '6. 构造最小可复现 SQL，并给出精确的期望关系断言，用它验证修复前后行为。',
            '',
            '## 结论分类',
            '',
            '最终结论必须从以下分类中选择一个主分类，必要时附带次分类：',
            '',
            '- `PARSER_DEFECT`：AST、作用域、字段解析或关系生成错误。',
            '- `FACT_PERSISTENCE_DEFECT`：解析正确，但事实落库、去重、过滤或转换时丢失/变形。',
            '- `GRAPH_PROJECTION_DEFECT`：事实正确，但入图或图谱查询投影错误。',
            '- `METADATA_INSUFFICIENT`：缺少 DDL、字段顺序、星号展开或物理模型信息，无法可靠判定。',
            '- `SQL_AMBIGUITY`：SQL 或动态拼接本身无法静态确定。',
            '- `EXISTING_REVIEW_FALSE_POSITIVE`：程序结果正确，已有疑点不成立。',
            '',
            '## 要求的回答格式',
            '',
            '请严格按以下结构回答：',
            '',
            '### 1. 最终结论',
            '- 主分类、是否确认程序存在问题、置信度、两三句话结论。',
            '',
            '### 2. SQL 独立语义推导',
            '- 用表格列出：源字段、目标字段、期望关系类型、SQL 行号/表达式、推导理由。',
            '',
            '### 3. 程序输出逐项核对',
            '- 用表格列出：证据编号、程序关系、期望结果、是否正确、问题说明。',
            '',
            '### 4. 图谱结果逐项核对',
            '- 说明图谱结果是否与程序事实一致，以及差异首次出现在哪个阶段。',
            '',
            '### 5. 根因定位',
            '- 给出仓库文件、类/函数、关键分支及调用链证据；无法访问代码时列出必须检查的位置和原因。',
            '',
            '### 6. 最小修复方案',
            '- 只修改造成问题的职责边界，说明修复逻辑和可能影响面。',
            '',
            '### 7. 回归测试',
            '- 给出最小 SQL、输入元数据、期望关系集合以及应断言不存在的错误关系。',
            '',
            '### 8. 仍缺少的证据',
            '- 没有则写“无”；不得用猜测补齐。',
            '',
            '## 案例定位信息',
            '',
            `- 疑点 ID: ${issue.id}`,
            `- 任务 ID: ${issue.taskId}`,
            `- 分析记录 ID: ${normalizeMarkdownValue(issue.analysisRecordId)}`,
            `- 版本 ID: ${normalizeMarkdownValue(issue.versionId)}`,
            `- 系统分片: ${normalizeMarkdownValue(issue.systemKey)}`,
            `- 路径前缀: ${normalizeMarkdownValue(issue.pathPrefix)}`,
            `- 目标对象: ${target}`,
            `- 对象类型: ${normalizeMarkdownValue(issue.objectType)}`,
            ''
        ];
        appendMarkdownList(lines, '源文件', sourceFiles);
        lines.push(
            '## 已有疑点假设（必须独立验证）',
            '',
            `- 疑点类型: ${toDisplayLabel(issue.issueType, issueTypeLabelMap)} (${normalizeMarkdownValue(issue.issueType)})`,
            `- 严重级别: ${toDisplayLabel(issue.severity, severityLabelMap)} (${normalizeMarkdownValue(issue.severity)})`,
            `- 已有 AI 判定: ${toDisplayLabel(issue.verdict, verdictLabelMap)} / ${Number(issue.confidence || 0).toFixed(2)}`,
            `- 已有 AI 摘要: ${normalizeMarkdownValue(presentation?.summary)}`,
            `- 当前解析描述: ${normalizeMarkdownValue(presentation?.currentState)}`,
            `- SQL 期待描述: ${normalizeMarkdownValue(presentation?.expectedState)}`,
            `- 关键差异描述: ${normalizeMarkdownValue(presentation?.difference)}`,
            `- 已有处置建议: ${normalizeMarkdownValue(presentation?.recommendation)}`,
            `- 人工状态: ${toDisplayLabel(issue.reviewStatus, reviewStatusLabelMap, '待处理')}`,
            `- 确认问题类型: ${toDisplayLabel(issue.confirmedProblemType, confirmedProblemTypeLabelMap)}`,
            `- 确认问题描述: ${normalizeMarkdownValue(issue.confirmedProblemDescription)}`,
            `- 人工备注: ${normalizeMarkdownValue(issue.reviewerNote)}`,
            ''
        );
        lines.push('## 已有复核原因（待验证）', '', normalizeMarkdownBlock(issue.reason), '');
        appendMarkdownList(lines, '规则命中', ruleHits);
        appendMarkdownList(lines, '建议来源', issue.suggestedSources);
        appendMarkdownList(lines, '已有结论引用的证据编号', evidenceRefs);
        appendMarkdownCodeBlock(lines, 'SQL 原文（语义真值来源）', 'sql', String(snapshot.sqlSnippet || '-'));
        appendMarkdownCodeBlock(lines, 'SQL 逐行证据', 'json', JSON.stringify(snapshot.sqlLines || [], null, 2));
        appendMarkdownCodeBlock(lines, '程序解析关系 programRelations', 'json', JSON.stringify(snapshot.programRelations || [], null, 2));
        appendMarkdownCodeBlock(lines, '图谱字段关系 graphFieldRelations', 'json', JSON.stringify(snapshot.graphFieldRelations || [], null, 2));
        appendMarkdownCodeBlock(lines, '关系类型定义', 'json', JSON.stringify(snapshot.relationTypeDescriptions || {}, null, 2));
        appendMarkdownCodeBlock(lines, '系统原始审核指令（仅作背景）', 'text', String(snapshot.auditInstruction || '-'));
        appendMarkdownCodeBlock(lines, '完整原始证据包（用于防止结构化摘录丢失信息）', 'json', JSON.stringify(snapshot, null, 2));
        return lines.join('\n');
    };

    const buildIssueMarkdownFileName = (issue: LineageReviewIssue) => {
        const target = `${issue.tableName || 'unknown'}${issue.columnName ? `_${issue.columnName}` : ''}`;
        const safeTarget = target.replace(/[\\/:*?"<>|]+/g, '_').replace(/\s+/g, '_').slice(0, 120);
        return `lineage-parser-self-check-${issue.id || 'detail'}-${safeTarget}.md`;
    };

    const handleDownloadIssueMarkdown = () => {
        if (!selectedIssue) {
            return;
        }
        const blob = new Blob(['\uFEFF', buildIssueMarkdownReport(selectedIssue)], {
            type: 'text/markdown;charset=utf-8'
        });
        downloadBlob(blob, buildIssueMarkdownFileName(selectedIssue));
        message.success('AI 自检 Markdown 下载开始');
    };

    const loadTaskSummaries = async () => {
        try {
            const data = await getLineageReviewTasks();
            const grouped = (data || []).reduce<Record<string, LineageReviewTask[]>>((acc, item) => {
                const key = item.analysisRecordId || 'UNKNOWN';
                if (!acc[key]) {
                    acc[key] = [];
                }
                acc[key].push(item);
                return acc;
            }, {});
            setTaskSummaryMap(grouped);
        } catch (error: any) {
            message.error(error?.message || '加载走查状态失败');
        }
    };

    const loadRecords = async () => {
        setRecordLoading(true);
        try {
            const data = await getLineageReviewRecords();
            setRecords(data || []);
            await loadTaskSummaries();
            setRecordPage(1);
            if (!selectedRecordId && data?.length) {
                setSelectedRecordId(data[0].id);
            }
        } catch (error: any) {
            message.error(error?.message || '加载分析记录失败');
        } finally {
            setRecordLoading(false);
        }
    };

    const loadTasks = async (analysisRecordId?: string) => {
        setTaskLoading(true);
        try {
            const data = await getLineageReviewTasks({ analysisRecordId });
            setTasks(data || []);
            setTaskPage(1);
            if (!selectedTaskId || !(data || []).some(item => item.id === selectedTaskId)) {
                setSelectedTaskId(data?.[0]?.id);
            }
        } catch (error: any) {
            message.error(error?.message || '加载校验任务失败');
        } finally {
            setTaskLoading(false);
        }
    };

    const loadIssues = async (taskId?: number) => {
        if (!taskId) {
            setIssues([]);
            return;
        }
        setIssueLoading(true);
        try {
            const data = await getLineageReviewIssues({
                taskId,
                severity: severityFilter,
                reviewStatus: reviewStatusFilter
            });
            setIssues(data || []);
        } catch (error: any) {
            message.error(error?.message || '加载疑点失败');
        } finally {
            setIssueLoading(false);
        }
    };

    const handleSelectIssue = async (issue: LineageReviewIssue) => {
        const requestId = ++issueDetailRequestRef.current;
        setSelectedIssue(issue);
        setIssueDetailLoading(true);
        try {
            const detail = await getLineageReviewIssue(issue.id);
            if (issueDetailRequestRef.current === requestId) {
                setSelectedIssue(detail);
            }
        } catch (error: any) {
            if (issueDetailRequestRef.current === requestId) {
                message.error(error?.message || '加载疑点详情失败');
            }
        } finally {
            if (issueDetailRequestRef.current === requestId) {
                setIssueDetailLoading(false);
            }
        }
    };

    const selectMemoryForEdit = (memory?: LineageReviewMemory) => {
        setSelectedMemoryId(memory?.id);
        setMemoryDraft({
            title: memory?.title || '',
            content: memory?.content || '',
            status: memory?.status || 'ACTIVE'
        });
    };

    const loadMemories = async () => {
        setMemoryLoading(true);
        try {
            const data = await getLineageReviewMemories({ status: 'ACTIVE' });
            const activeSummaries = (data || []).filter(item => !item.sourceIssueId);
            setMemories(activeSummaries);
            const current = activeSummaries.find(item => item.id === selectedMemoryId) || activeSummaries[0];
            selectMemoryForEdit(current);
        } catch (error: any) {
            message.error(error?.message || '加载走查记忆失败');
        } finally {
            setMemoryLoading(false);
        }
    };

    const handleOpenMemory = async () => {
        setMemoryOpen(true);
        await loadMemories();
    };

    useEffect(() => {
        loadRecords();
    }, []);

    useEffect(() => {
        if (selectedRecordId) {
            loadTasks(selectedRecordId);
        }
    }, [selectedRecordId]);

    useEffect(() => {
        loadIssues(selectedTaskId);
    }, [selectedTaskId, severityFilter, reviewStatusFilter]);

    const handleTrigger = async (forceRerun: boolean) => {
        if (!selectedRecordId) {
            message.warning('请先选择一个血缘分析记录');
            return;
        }
        setTriggerLoading(true);
        try {
            const result = await triggerLineageReview({ analysisRecordId: selectedRecordId, forceRerun });
            message.success(result.message || '校验任务已提交');
            await loadTaskSummaries();
            await loadTasks(selectedRecordId);
        } catch (error: any) {
            message.error(error?.message || '触发校验失败');
        } finally {
            setTriggerLoading(false);
        }
    };

    const handleClearHistory = async () => {
        setClearHistoryLoading(true);
        try {
            const result = await clearLineageReviewHistory();
            setTasks([]);
            setIssues([]);
            setTaskSummaryMap({});
            setSelectedTaskId(undefined);
            setSelectedIssue(null);
            await loadTaskSummaries();
            message.success(result.message || '已清空历史校验结果');
        } catch (error: any) {
            message.error(error?.message || '清空历史校验结果失败');
        } finally {
            setClearHistoryLoading(false);
        }
    };

    const handleDecision = async (
        reviewStatus: string,
        note = '',
        extra?: { confirmedProblemType?: string; confirmedProblemDescription?: string }
    ) => {
        if (!selectedIssue) {
            return;
        }
        setDecisionLoading(reviewStatus);
        try {
            const updated = await decideLineageReviewIssue(selectedIssue.id, {
                reviewStatus,
                reviewerNote: note,
                falsePositiveReason: reviewStatus === 'FALSE_POSITIVE' ? note : undefined,
                confirmedProblemType: extra?.confirmedProblemType,
                confirmedProblemDescription: extra?.confirmedProblemDescription
            });
            setSelectedIssue(updated);
            await loadIssues(selectedTaskId);
            await loadTaskSummaries();
            if (selectedRecordId) {
                await loadTasks(selectedRecordId);
            }
            if (reviewStatus === 'FALSE_POSITIVE') {
                await loadMemories();
            }
            message.success(reviewStatus === 'FALSE_POSITIVE' ? '误报原因已保存，并已更新误报复盘汇总' : '人工判定已保存');
        } catch (error: any) {
            message.error(error?.message || '保存判定失败');
        } finally {
            setDecisionLoading('');
        }
    };

    const handleOpenConfirmProblemModal = () => {
        if (!selectedIssue) {
            return;
        }
        setConfirmedProblemType(selectedIssue.confirmedProblemType || 'SQL_STANDARD');
        setConfirmedProblemDescription(selectedIssue.confirmedProblemDescription || selectedIssue.reviewerNote || '');
        setConfirmProblemModalOpen(true);
    };

    const handleSubmitConfirmProblem = async () => {
        if (!confirmedProblemType) {
            message.warning('请选择问题类型');
            return;
        }
        const description = confirmedProblemDescription.trim();
        await handleDecision('CONFIRMED', description, {
            confirmedProblemType,
            confirmedProblemDescription: description
        });
        setConfirmProblemModalOpen(false);
    };

    const handleOpenFalsePositiveModal = () => {
        if (!selectedIssue) {
            return;
        }
        setFalsePositiveReason(selectedIssue.reviewerNote || '');
        setFalsePositiveModalOpen(true);
    };

    const handleSubmitFalsePositive = async () => {
        const reason = falsePositiveReason.trim();
        if (!reason) {
            message.warning('请填写误报原因');
            return;
        }
        await handleDecision('FALSE_POSITIVE', reason);
        setFalsePositiveModalOpen(false);
    };

    const handleSaveMemory = async () => {
        if (!selectedMemoryId) {
            return;
        }
        const title = memoryDraft.title.trim();
        const content = memoryDraft.content.trim();
        if (!title || !content) {
            message.warning('标题和记忆内容不能为空');
            return;
        }
        setMemorySaving(true);
        try {
            const updated = await updateLineageReviewMemory(selectedMemoryId, {
                title,
                content,
                status: memoryDraft.status
            });
            setMemories(prev => prev.map(item => item.id === updated.id ? updated : item));
            selectMemoryForEdit(updated);
            message.success('走查记忆已更新');
        } catch (error: any) {
            message.error(error?.message || '保存走查记忆失败');
        } finally {
            setMemorySaving(false);
        }
    };

    const handleOpenSqlPreview = async (task: LineageReviewTask) => {
        setSqlPreviewTask(task);
        setSqlPreviewOpen(true);
        setSqlPreviewLoading(true);
        try {
            const data = await getLineageReviewTaskSqlPreview(task.id);
            const normalized = (data || [])
                .map(item => ({
                    statementUid: item.statementUid,
                    snippet: String(item.snippet || '').trim(),
                    sourceFiles: Array.from(new Set((item.sourceFiles || []).filter(Boolean))),
                    relationCount: item.relationCount || 0,
                    auditStatus: item.auditStatus,
                    riskScore: item.riskScore,
                    riskReasons: item.riskReasons || [],
                    highRisk: item.highRisk,
                    screeningCandidate: item.screeningCandidate,
                    aiCallCount: item.aiCallCount,
                    auditIssueCount: item.auditIssueCount,
                    skipReason: item.skipReason
                }))
                .filter(item => item.snippet.length > 0);
            setSqlPreviews(normalized);
        } catch (error: any) {
            message.error(error?.message || '加载 SQL 片段失败');
            setSqlPreviews([]);
        } finally {
            setSqlPreviewLoading(false);
        }
    };

    const handleDownloadMarkdownReport = async () => {
        if (!selectedTask) {
            return;
        }
        setReportDownloading(true);
        try {
            const blob = await downloadLineageReviewReportMarkdown(selectedTask.id);
            downloadBlob(blob, `lineage-review-${selectedTask.id}.md`);
            message.success('Markdown 报告下载开始');
        } catch (error: any) {
            message.error(error?.message || '下载 Markdown 报告失败');
        } finally {
            setReportDownloading(false);
        }
    };

    return (
        <div className="space-y-6">
            <div className="flex justify-end gap-2">
                <Button onClick={handleOpenMemory}>
                    走查记忆
                </Button>
                <Popconfirm
                    title="清空历史校验结果"
                    description="将删除所有事后校验任务、语句审核明细、疑点和 AI 校验缓存，血缘分析批次会保留。"
                    okText="清空"
                    cancelText="取消"
                    okButtonProps={{ danger: true, loading: clearHistoryLoading }}
                    onConfirm={handleClearHistory}
                >
                    <Button
                        danger
                        loading={clearHistoryLoading}
                        disabled={!canTrigger}
                        title={canTrigger ? '' : '缺少 version:ai:trigger 权限'}
                    >
                        清空历史
                    </Button>
                </Popconfirm>
            </div>

            <ReviewMetricCards
                records={records}
                tasks={tasks}
                selectedTask={selectedTask}
                selectedTaskSourceMeta={selectedTaskSourceMeta}
            />

            <div className="grid grid-cols-1 gap-6 xl:grid-cols-[360px_minmax(0,1fr)]">
                <ReviewRecordList
                    records={records}
                    pagedRecords={pagedRecords}
                    taskSummaryMap={taskSummaryMap}
                    selectedRecordId={selectedRecordId}
                    loading={recordLoading}
                    triggerLoading={triggerLoading}
                    canTrigger={canTrigger}
                    recordPage={recordPage}
                    recordPageSize={recordPageSize}
                    onRefresh={loadRecords}
                    onTrigger={() => handleTrigger(false)}
                    onSelectRecord={setSelectedRecordId}
                    onPageChange={(page, size) => {
                        setRecordPage(page);
                        if (size && size !== recordPageSize) {
                            setRecordPageSize(size);
                        }
                    }}
                />

                <div className="space-y-6">
                    <ReviewTaskTable
                        selectedRecord={selectedRecord}
                        selectedTask={selectedTask}
                        selectedTaskId={selectedTaskId}
                        tasks={tasks}
                        loading={taskLoading}
                        triggerLoading={triggerLoading}
                        reportDownloading={reportDownloading}
                        canTrigger={canTrigger}
                        canExport={canExport}
                        taskPage={taskPage}
                        taskPageSize={taskPageSize}
                        getTaskSourceMeta={task => buildTaskSourceMeta(task, records)}
                        onRefresh={() => loadTasks(selectedRecordId)}
                        onForceRerun={() => handleTrigger(true)}
                        onDownloadMarkdown={handleDownloadMarkdownReport}
                        onOpenSqlPreview={handleOpenSqlPreview}
                        onTaskSelect={setSelectedTaskId}
                        onPageChange={(page, size) => {
                            setTaskPage(page);
                            if (size && size !== taskPageSize) {
                                setTaskPageSize(size);
                            }
                        }}
                    />

                    <ReviewIssueTable
                        issues={filteredIssues}
                        loading={issueLoading}
                        selectedTaskId={selectedTaskId}
                        searchTerm={searchTerm}
                        severityFilter={severityFilter}
                        reviewStatusFilter={reviewStatusFilter}
                        onSearchChange={setSearchTerm}
                        onSeverityChange={setSeverityFilter}
                        onReviewStatusChange={setReviewStatusFilter}
                        onSelectIssue={handleSelectIssue}
                    />
                </div>
            </div>

            <Drawer
                open={!!selectedIssue}
                onClose={() => {
                    issueDetailRequestRef.current += 1;
                    setIssueDetailLoading(false);
                    setSelectedIssue(null);
                }}
                size="large"
                title="疑点详情"
                extra={
                    selectedIssue && (
                        <Space>
                            <Button size="small" loading={issueDetailLoading} onClick={handleDownloadIssueMarkdown}>
                                下载 AI 自检版
                            </Button>
                            <Button
                                size="small"
                                loading={decisionLoading === 'CONFIRMED'}
                                onClick={handleOpenConfirmProblemModal}
                            >
                                确认问题
                            </Button>
                            <Button
                                size="small"
                                loading={decisionLoading === 'FALSE_POSITIVE'}
                                onClick={handleOpenFalsePositiveModal}
                            >
                                标记误报
                            </Button>
                            <Button
                                size="small"
                                loading={decisionLoading === 'RESOLVED'}
                                onClick={() => handleDecision('RESOLVED')}
                            >
                                已处理
                            </Button>
                        </Space>
                    )
                }
            >
                {selectedIssue ? (
                    issueDetailLoading ? <Spin className="flex justify-center py-12" /> : <ReviewIssueDetail issue={selectedIssue} />
                ) : null}
            </Drawer>

            <Drawer
                open={sqlPreviewOpen}
                onClose={() => setSqlPreviewOpen(false)}
                size="large"
                title={`源码 SQL 片段${sqlPreviewTask ? ` · ${buildShardLabel(sqlPreviewTask)}` : ''}`}
            >
                {sqlPreviewLoading ? (
                    <div className="flex items-center justify-center py-20">
                        <Spin />
                    </div>
                ) : sqlPreviews.length === 0 ? (
                    <Empty description="当前分片暂未记录可展示的 SQL 片段" />
                ) : (
                    <div className="space-y-4">
                        {sqlPreviews.map((item, index) => (
                            <Card
                                key={item.statementUid || `${index}-${item.relationCount}`}
                                size="small"
                                title={
                                    <div className="flex items-center gap-2">
                                        <span>SQL 片段 {index + 1}</span>
                                        {item.auditStatus && (
                                            <Tag color={statementAuditStatusColorMap[item.auditStatus] || 'default'}>
                                                {statementAuditStatusLabelMap[item.auditStatus] || item.auditStatus}
                                            </Tag>
                                        )}
                                        {item.highRisk && <Tag color="volcano">高风险</Tag>}
                                    </div>
                                }
                                extra={<span className="text-xs text-slate-400">关联关系 {item.relationCount}</span>}
                            >
                                {item.auditStatus && (
                                    <div className="mb-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-500">
                                        <span>风险分 {item.riskScore || 0}</span>
                                        <span>AI 调用 {item.aiCallCount || 0}</span>
                                        <span>疑点 {item.auditIssueCount || 0}</span>
                                        <span>{item.screeningCandidate ? '初筛命中候选' : '初筛未命中候选'}</span>
                                        {item.riskReasons.length > 0 && (
                                            <span>
                                                风险原因 {item.riskReasons
                                                    .map(reason => statementRiskReasonLabelMap[reason] || reason)
                                                    .join('、')}
                                            </span>
                                        )}
                                    </div>
                                )}
                                {item.skipReason && (
                                    <Alert className="mb-3" type="warning" showIcon message={item.skipReason} />
                                )}
                                <div className="mb-3 text-xs text-slate-500">
                                    来源文件：{item.sourceFiles?.length ? item.sourceFiles.join('、') : '未记录'}
                                </div>
                                <pre className="max-h-96 overflow-auto whitespace-pre-wrap rounded-xl bg-slate-900 p-4 text-xs text-slate-100">
                                    {item.snippet || '未返回 SQL 片段内容'}
                                </pre>
                            </Card>
                        ))}
                    </div>
                )}
            </Drawer>

            <Modal
                open={confirmProblemModalOpen}
                title="确认问题"
                okText="保存确认"
                cancelText="取消"
                confirmLoading={decisionLoading === 'CONFIRMED'}
                onOk={handleSubmitConfirmProblem}
                onCancel={() => setConfirmProblemModalOpen(false)}
            >
                <div className="space-y-4">
                    <div>
                        <div className="mb-2 text-sm font-medium text-slate-700">问题类型</div>
                        <Space>
                            <Button
                                type={confirmedProblemType === 'SQL_STANDARD' ? 'primary' : 'default'}
                                onClick={() => setConfirmedProblemType('SQL_STANDARD')}
                            >
                                SQL 书写规范
                            </Button>
                            <Button
                                type={confirmedProblemType === 'PARSER_BUG' ? 'primary' : 'default'}
                                onClick={() => setConfirmedProblemType('PARSER_BUG')}
                            >
                                解析程序 BUG
                            </Button>
                        </Space>
                    </div>
                    <div>
                        <div className="mb-2 text-sm font-medium text-slate-700">问题描述</div>
                        <TextArea
                            rows={5}
                            value={confirmedProblemDescription}
                            placeholder="补充具体字段、SQL 片段、解析偏差或规范问题说明"
                            onChange={event => setConfirmedProblemDescription(event.target.value)}
                        />
                    </div>
                </div>
            </Modal>

            <Modal
                open={falsePositiveModalOpen}
                title="填写误报原因"
                okText="保存并复盘"
                cancelText="取消"
                confirmLoading={decisionLoading === 'FALSE_POSITIVE'}
                onOk={handleSubmitFalsePositive}
                onCancel={() => setFalsePositiveModalOpen(false)}
            >
                <div className="space-y-3">
                    <Alert
                        type="info"
                        showIcon
                        message="误报原因会保存到本条疑点，并与历史误报一起汇总成一条走查记忆。后续血缘走查会自动参考这条汇总。"
                    />
                    <TextArea
                        rows={5}
                        value={falsePositiveReason}
                        placeholder="例如：这是多步骤条件覆盖，不是同一句 SQL 内的同名字段歧义。"
                        onChange={event => setFalsePositiveReason(event.target.value)}
                    />
                </div>
            </Modal>

            <Drawer
                open={memoryOpen}
                onClose={() => setMemoryOpen(false)}
                size="large"
                title="血缘走查记忆"
                extra={
                    <Space>
                        <Button onClick={loadMemories} loading={memoryLoading}>
                            刷新
                        </Button>
                        <Button
                            type="primary"
                            disabled={!selectedMemoryId || !canTrigger}
                            loading={memorySaving}
                            onClick={handleSaveMemory}
                        >
                            保存
                        </Button>
                    </Space>
                }
            >
                {memoryLoading ? (
                    <div className="flex items-center justify-center py-20">
                        <Spin />
                    </div>
                ) : memories.length === 0 ? (
                    <Empty description="暂无走查记忆。标记误报并填写原因后会自动汇总生成。" />
                ) : (
                    <div className="grid grid-cols-1 gap-4 lg:grid-cols-[260px_minmax(0,1fr)]">
                        <div className="space-y-2">
                            {memories.map(memory => (
                                <button
                                    key={memory.id}
                                    type="button"
                                    className={`w-full rounded-md border px-3 py-2 text-left text-sm ${
                                        memory.id === selectedMemoryId
                                            ? 'border-blue-300 bg-blue-50 text-blue-700'
                                            : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300'
                                    }`}
                                    onClick={() => selectMemoryForEdit(memory)}
                                >
                                    <div className="font-medium">{memory.title}</div>
                                    <div className="mt-1 text-xs text-slate-400">
                                        {toDisplayLabel(memory.status, { ACTIVE: '生效中', ARCHIVED: '已归档' })}
                                    </div>
                                </button>
                            ))}
                        </div>

                        <div className="space-y-4">
                            <Descriptions column={1} size="small" bordered>
                                <Descriptions.Item label="适用对象">
                                    {selectedMemory?.targetPattern || '-'}
                                </Descriptions.Item>
                                <Descriptions.Item label="来源疑点">
                                    {selectedMemory?.sourceIssueId ? `#${selectedMemory.sourceIssueId}` : '-'}
                                </Descriptions.Item>
                                <Descriptions.Item label="更新时间">
                                    {selectedMemory?.updateTime || '-'}
                                </Descriptions.Item>
                            </Descriptions>

                            <Input
                                value={memoryDraft.title}
                                placeholder="记忆标题"
                                disabled={!canTrigger}
                                onChange={event => setMemoryDraft(prev => ({ ...prev, title: event.target.value }))}
                            />
                            <Space>
                                <Button
                                    type={memoryDraft.status === 'ACTIVE' ? 'primary' : 'default'}
                                    disabled={!canTrigger}
                                    onClick={() => setMemoryDraft(prev => ({ ...prev, status: 'ACTIVE' }))}
                                >
                                    生效中
                                </Button>
                                <Button
                                    type={memoryDraft.status === 'ARCHIVED' ? 'primary' : 'default'}
                                    disabled={!canTrigger}
                                    onClick={() => setMemoryDraft(prev => ({ ...prev, status: 'ARCHIVED' }))}
                                >
                                    已归档
                                </Button>
                            </Space>
                            <TextArea
                                rows={18}
                                value={memoryDraft.content}
                                disabled={!canTrigger}
                                placeholder="Markdown 形式的走查记忆"
                                onChange={event => setMemoryDraft(prev => ({ ...prev, content: event.target.value }))}
                            />
                        </div>
                    </div>
                )}
            </Drawer>
        </div>
    );
};

export default AICodeReport;
