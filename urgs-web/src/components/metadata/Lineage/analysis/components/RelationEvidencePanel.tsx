import React, { useEffect, useMemo, useState } from 'react';
import { Alert, Collapse, Empty, Spin, Tag, Typography } from 'antd';
import { getLineageRelationEvidence, LineageRelationEvidence } from '@/api/lineage';
import { LinkData } from '../types';

const { Text } = Typography;

interface RelationEvidencePanelProps {
    active: boolean;
    link: LinkData;
    sourceTable: string;
    targetTable: string;
    sourceColumn?: string;
    targetColumn?: string;
}

const normalizeArray = (value: unknown): string[] => {
    if (Array.isArray(value)) {
        return Array.from(new Set(value.filter(Boolean).map(String)));
    }
    return value ? [String(value)] : [];
};

export const getLinkEvidenceCount = (link: LinkData) => {
    const explicit = Number(link.properties?.evidenceCount || 0);
    if (explicit > 0) {
        return explicit;
    }
    const statementUids = normalizeArray(link.properties?.statementUids);
    if (statementUids.length > 0) {
        return statementUids.length;
    }
    const snippets = normalizeArray(link.properties?.snippets);
    if (snippets.length > 0) {
        return snippets.length;
    }
    return link.properties?.snippet ? 1 : 0;
};

const fallbackEvidence = (link: LinkData): LineageRelationEvidence[] => {
    const snippets = normalizeArray(link.properties?.snippets);
    const values = snippets.length > 0 ? snippets : normalizeArray(link.properties?.snippet);
    return values.map((snippet, index) => ({
        statementUid: `legacy-${index}`,
        statementIndex: index,
        snippet,
        sourceFiles: normalizeArray(link.properties?.sourceFiles),
        sourceColumns: normalizeArray(link.properties?.sourceColumns),
        targetColumns: normalizeArray(link.properties?.targetColumns),
        relationTypes: link.type ? [link.type] : [],
        confidences: normalizeArray(link.properties?.confidence),
        ambiguityCodes: normalizeArray(link.properties?.ambiguityCode),
    }));
};

const fileLabel = (evidence: LineageRelationEvidence) => {
    const sourceFile = evidence.sourceFiles[0];
    return sourceFile ? sourceFile.split('/').pop() || sourceFile : '未记录文件';
};

const RelationEvidencePanel: React.FC<RelationEvidencePanelProps> = ({
    active,
    link,
    sourceTable,
    targetTable,
    sourceColumn,
    targetColumn,
}) => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [evidence, setEvidence] = useState<LineageRelationEvidence[]>([]);
    const statementUids = useMemo(
        () => normalizeArray(link.properties?.statementUids),
        [link.properties?.statementUids]
    );

    useEffect(() => {
        if (!active) {
            return;
        }
        let cancelled = false;
        setLoading(true);
        setError('');
        getLineageRelationEvidence({
            relationId: link.id.includes('::') ? undefined : link.id,
            statementUids,
            sourceTable,
            sourceColumn,
            targetTable,
            targetColumn,
            relationType: link.type,
        }).then(items => {
            if (!cancelled) {
                setEvidence(items.length > 0 ? items : fallbackEvidence(link));
            }
        }).catch((requestError: any) => {
            if (!cancelled) {
                setError(requestError?.message || '关系证据加载失败');
                setEvidence(fallbackEvidence(link));
            }
        }).finally(() => {
            if (!cancelled) {
                setLoading(false);
            }
        });
        return () => {
            cancelled = true;
        };
    }, [active, link, sourceColumn, sourceTable, statementUids, targetColumn, targetTable]);

    if (loading) {
        return <div className="flex justify-center py-10"><Spin /></div>;
    }

    return (
        <div className="mt-4">
            <div className="mb-3 flex items-center justify-between">
                <Text strong>SQL 证据（{evidence.length || getLinkEvidenceCount(link)}）</Text>
                <Text type="secondary" className="text-xs">每段 SQL 独立对应当前关系</Text>
            </div>
            {error && <Alert className="mb-3" type="warning" showIcon message={error} />}
            {evidence.length === 0 ? (
                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="当前关系未关联可展示的 SQL 语句" />
            ) : (
                <Collapse
                    size="small"
                    defaultActiveKey={evidence.length === 1 ? [evidence[0].statementUid] : []}
                    items={evidence.map((item, index) => ({
                        key: item.statementUid || String(index),
                        label: (
                            <div className="flex flex-wrap items-center gap-2">
                                <span>SQL {index + 1}</span>
                                <Tag>{fileLabel(item)}</Tag>
                                <Text type="secondary" className="text-xs">
                                    语句序号 {(item.statementIndex || 0) + 1}
                                </Text>
                                {item.ambiguityCodes.length > 0 && <Tag color="warning">存在歧义</Tag>}
                            </div>
                        ),
                        children: (
                            <div>
                                <div className="mb-3 space-y-1 text-xs text-slate-500">
                                    <div>来源文件：{item.sourceFiles.join('、') || '未记录'}</div>
                                    <div>
                                        关系字段：{item.sourceColumns.join('、') || sourceColumn || '-'}
                                        {' → '}
                                        {item.targetColumns.join('、') || targetColumn || '-'}
                                    </div>
                                    <div>
                                        关系类型：{item.relationTypes.join('、') || link.type || '-'}
                                        {item.confidences.length > 0 ? ` · 置信度 ${item.confidences.join('、')}` : ''}
                                    </div>
                                </div>
                                <pre className="max-h-[420px] overflow-auto whitespace-pre-wrap rounded-lg bg-slate-900 p-4 text-xs leading-6 text-slate-100">
                                    {item.snippet || '未记录 SQL 内容'}
                                </pre>
                            </div>
                        ),
                    }))}
                />
            )}
        </div>
    );
};

export default RelationEvidencePanel;
