import React, { useMemo } from 'react';
import { Alert, Card, Collapse, Descriptions, Empty, Space, Tag } from 'antd';
import type { LineageReviewEvidenceItem, LineageReviewIssue } from '@/api/lineage';
import {
    confirmedProblemTypeLabelMap,
    issueTypeLabelMap,
    reviewStatusColorMap,
    reviewStatusLabelMap,
    ruleHitLabelMap,
    severityColorMap,
    severityLabelMap,
    toDisplayLabel,
    verdictLabelMap
} from './reviewConstants';

interface ReviewIssueDetailProps {
    issue: LineageReviewIssue;
}

const describeRelation = (item: LineageReviewEvidenceItem, scope: string) => {
    const source = [item.sourceTable, item.sourceColumn].filter(Boolean).join('.');
    const target = [item.targetTable, item.targetColumn].filter(Boolean).join('.');
    return `${scope}：${source || '-'} → ${target || '-'} [${item.relationType || 'UNKNOWN'}]`;
};

const buildEvidenceLookup = (issue: LineageReviewIssue) => {
    const snapshot = issue.graphSnapshot || {};
    const entries: Array<[string, string]> = [];
    (snapshot.sqlLines || []).forEach(item => {
        if (item.evidenceId) {
            entries.push([item.evidenceId, `SQL 第 ${item.lineNumber || '-'} 行：${item.text || ''}`]);
        }
    });
    (snapshot.programRelations || []).forEach(item => {
        if (item.evidenceId) {
            entries.push([item.evidenceId, describeRelation(item, '程序解析')]);
        }
    });
    (snapshot.graphFieldRelations || []).forEach(item => {
        if (item.evidenceId) {
            entries.push([item.evidenceId, describeRelation(item, '图谱结果')]);
        }
    });
    return new Map(entries);
};

const ReviewIssueDetail: React.FC<ReviewIssueDetailProps> = ({ issue }) => {
    const presentation = issue.graphSnapshot?.aiReview;
    const evidenceLookup = useMemo(() => buildEvidenceLookup(issue), [issue]);
    const evidenceRefs = presentation?.evidenceRefs || issue.evidenceRefs || [];
    const isStructured = presentation?.schemaVersion === 'two-pass-evidence-v3';
    const summary = presentation?.summary || issue.reason?.split(/\r?\n/)[0]?.replace(/^结论：/, '') || '需要人工复核该血缘疑点';

    return (
        <div className="space-y-5">
            <Alert
                showIcon
                type={issue.verdict === 'CONFIRMED' ? 'warning' : 'info'}
                message={summary}
                description={isStructured
                    ? 'AI 已完成候选发现、独立复核和证据编号校验。人工只需核对下方当前解析 vs SQL 期待以及引用证据。'
                    : '这是历史格式结果，请结合原因说明和原始证据人工核对。'}
            />

            <Descriptions column={2} size="small" bordered>
                <Descriptions.Item label="目标对象" span={2}>
                    {issue.tableName}{issue.columnName ? `.${issue.columnName}` : ''}
                </Descriptions.Item>
                <Descriptions.Item label="疑点类型">
                    {toDisplayLabel(issue.issueType, issueTypeLabelMap)}
                </Descriptions.Item>
                <Descriptions.Item label="严重级别">
                    <Tag color={severityColorMap[issue.severity] || 'default'}>
                        {toDisplayLabel(issue.severity, severityLabelMap)}
                    </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="AI 判定">
                    {toDisplayLabel(issue.verdict, verdictLabelMap)} / {Math.round(Number(issue.confidence || 0) * 100)}%
                </Descriptions.Item>
                <Descriptions.Item label="人工状态">
                    <Tag color={reviewStatusColorMap[issue.reviewStatus || ''] || 'default'}>
                        {toDisplayLabel(issue.reviewStatus, reviewStatusLabelMap, '待处理')}
                    </Tag>
                </Descriptions.Item>
            </Descriptions>

            <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
                <Card size="small" title="当前解析结果" className="border-slate-200 bg-slate-50">
                    <div className="whitespace-pre-wrap text-sm leading-6 text-slate-700">
                        {presentation?.currentState || issue.reason || '-'}
                    </div>
                </Card>
                <Card size="small" title="SQL 期待结果" className="border-blue-200 bg-blue-50/50">
                    <div className="whitespace-pre-wrap text-sm leading-6 text-slate-700">
                        {presentation?.expectedState || '请根据 SQL 原文确认正确的字段级关系。'}
                    </div>
                    {presentation?.expectedRelationType && (
                        <Tag color="blue" className="mt-3">期待关系 {presentation.expectedRelationType}</Tag>
                    )}
                </Card>
            </div>

            <Card size="small" title="关键差异">
                <div className="whitespace-pre-wrap text-sm leading-6 text-slate-700">
                    {presentation?.difference || issue.reason || '-'}
                </div>
            </Card>

            <Card size="small" title={`核对证据（${evidenceRefs.length}）`}>
                {evidenceRefs.length === 0 ? (
                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="没有可定位的证据编号" />
                ) : (
                    <div className="space-y-2">
                        {evidenceRefs.map(ref => (
                            <div key={ref} className="rounded-lg border border-slate-200 bg-white px-3 py-2">
                                <div className="mb-1 font-mono text-xs font-semibold text-blue-600">{ref}</div>
                                <div className="whitespace-pre-wrap text-sm text-slate-600">
                                    {evidenceLookup.get(ref) || ref}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </Card>

            <Card size="small" title="处置建议">
                <div className="space-y-3">
                    <Space wrap>
                        <Tag color="purple">{presentation?.disposition || '人工复核'}</Tag>
                        {(presentation?.suggestedSources || issue.suggestedSources || []).map(source => (
                            <Tag key={source}>{source}</Tag>
                        ))}
                    </Space>
                    <div className="text-sm leading-6 text-slate-700">
                        {presentation?.recommendation || '核对 SQL 与程序关系后，选择确认问题或标记误报。'}
                    </div>
                </div>
            </Card>

            <Descriptions column={1} size="small" bordered title="人工处理记录">
                <Descriptions.Item label="确认问题类型">
                    {toDisplayLabel(issue.confirmedProblemType, confirmedProblemTypeLabelMap)}
                </Descriptions.Item>
                <Descriptions.Item label="确认问题描述">{issue.confirmedProblemDescription || '-'}</Descriptions.Item>
                <Descriptions.Item label="人工备注">{issue.reviewerNote || '-'}</Descriptions.Item>
            </Descriptions>

            <Collapse
                ghost
                items={[{
                    key: 'technical-evidence',
                    label: '查看技术证据与规则详情',
                    children: (
                        <div className="space-y-4">
                            <Space wrap>
                                {(issue.ruleHits || []).map(item => (
                                    <Tag key={item}>{toDisplayLabel(item, ruleHitLabelMap)}</Tag>
                                ))}
                            </Space>
                            <pre className="max-h-96 overflow-auto rounded-xl bg-slate-900 p-4 text-xs text-slate-100">
                                {JSON.stringify(issue.graphSnapshot || {}, null, 2)}
                            </pre>
                        </div>
                    )
                }]}
            />
        </div>
    );
};

export default ReviewIssueDetail;
