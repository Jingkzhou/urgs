import React, { useEffect, useMemo, useState } from 'react';
import { Alert, Empty, Modal, Spin, Tag, Typography } from 'antd';
import hljs from 'highlight.js/lib/core';
import sql from 'highlight.js/lib/languages/sql';
import 'highlight.js/styles/atom-one-dark.css';
import { getLineageRelationEvidence, LineageRelationEvidence } from '@/api/lineage';
import { LinkData } from '../types';

const { Text } = Typography;

hljs.registerLanguage('sql', sql);

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

type HighlightRole = 'source-table' | 'target-table' | 'source-field' | 'target-field';

const escapeRegExp = (value: string) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const buildTermPattern = (term: string) => {
    const escaped = escapeRegExp(term);
    return /^[a-zA-Z_][a-zA-Z0-9_$]*$/.test(term) ? `\\b${escaped}\\b` : escaped;
};

const getTableTerms = (table: string) => {
    const normalized = table.trim();
    if (!normalized || normalized === '-') {
        return [];
    }
    const shortName = normalized.split('.').pop();
    return Array.from(new Set([normalized, shortName].filter((item): item is string => Boolean(item))));
};

const buildHighlightedSqlHtml = (
    snippet: string,
    sourceTable: string,
    targetTable: string,
    sourceFields: string[],
    targetFields: string[]
) => {
    const termRoles = new Map<string, Set<HighlightRole>>();
    const addTerms = (terms: string[], role: HighlightRole) => {
        terms.filter(Boolean).forEach(term => {
            const key = term.toLowerCase();
            const roles = termRoles.get(key) || new Set<HighlightRole>();
            roles.add(role);
            termRoles.set(key, roles);
        });
    };

    addTerms(getTableTerms(sourceTable), 'source-table');
    addTerms(getTableTerms(targetTable), 'target-table');
    addTerms(sourceFields, 'source-field');
    addTerms(targetFields, 'target-field');

    const syntaxHighlightedHtml = hljs.highlight(snippet, { language: 'sql' }).value;
    const terms = Array.from(termRoles.keys()).sort((left, right) => right.length - left.length);
    if (terms.length === 0) {
        return syntaxHighlightedHtml;
    }

    const matcher = new RegExp(`(${terms.map(buildTermPattern).join('|')})`, 'gi');
    return syntaxHighlightedHtml.split(/(<[^>]+>)/g).map(part => {
        if (part.startsWith('<')) {
            return part;
        }
        return part.replace(matcher, matchedTerm => {
            const roles = termRoles.get(matchedTerm.toLowerCase());
            if (!roles) {
                return matchedTerm;
            }
            const role = roles.size > 1 ? 'overlap' : Array.from(roles)[0];
            const style = role === 'source-table'
                ? 'background: rgba(56, 189, 248, 0.35); color: #e0f2fe;'
                : role === 'target-table'
                    ? 'background: rgba(52, 211, 153, 0.35); color: #d1fae5;'
                    : role === 'source-field'
                        ? 'background: rgba(251, 191, 36, 0.35); color: #fef3c7;'
                        : role === 'target-field'
                            ? 'background: rgba(251, 113, 133, 0.35); color: #ffe4e6;'
                            : 'background: rgba(167, 139, 250, 0.35); color: #ede9fe;';
            return `<mark style="${style} padding: 0 2px; border-radius: 2px; font-weight: 600;">${matchedTerm}</mark>`;
        });
    }).join('');
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
    const [selectedEvidenceIndex, setSelectedEvidenceIndex] = useState<number | null>(null);
    const statementUids = useMemo(
        () => normalizeArray(link.properties?.statementUids),
        [link.properties?.statementUids]
    );

    useEffect(() => {
        if (!active) {
            setSelectedEvidenceIndex(null);
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

    const selectedEvidence = selectedEvidenceIndex === null ? null : evidence[selectedEvidenceIndex];
    const selectedSourceFields = selectedEvidence
        ? (selectedEvidence.sourceColumns.length > 0 ? selectedEvidence.sourceColumns : (sourceColumn ? [sourceColumn] : []))
        : [];
    const selectedTargetFields = selectedEvidence
        ? (selectedEvidence.targetColumns.length > 0 ? selectedEvidence.targetColumns : (targetColumn ? [targetColumn] : []))
        : [];

    return (
        <div className="lineage-relation-evidence mt-4">
            <div className="lineage-relation-evidence-header mb-3">
                <Text strong>SQL 证据（{evidence.length || getLinkEvidenceCount(link)}）</Text>
                <Text type="secondary" className="lineage-relation-evidence-hint text-xs">选择一条 SQL，全屏查看对应代码</Text>
            </div>
            {error && <Alert className="mb-3" type="warning" showIcon message={error} />}
            {evidence.length === 0 ? (
                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="当前关系未关联可展示的 SQL 语句" />
            ) : (
                <div className="lineage-relation-evidence-list max-h-72 space-y-2 overflow-auto">
                    {evidence.map((item, index) => {
                        const sourceFields = item.sourceColumns.length > 0 ? item.sourceColumns : (sourceColumn ? [sourceColumn] : []);
                        const targetFields = item.targetColumns.length > 0 ? item.targetColumns : (targetColumn ? [targetColumn] : []);
                        return (
                            <button
                                key={item.statementUid || String(index)}
                                type="button"
                                aria-label={`打开 SQL ${index + 1}：${fileLabel(item)}`}
                                className="lineage-relation-evidence-item flex w-full items-center justify-between gap-4 rounded-lg border border-slate-200 bg-white px-4 py-3 text-left transition hover:border-blue-300 hover:bg-blue-50/40"
                                onClick={() => setSelectedEvidenceIndex(index)}
                            >
                                <div className="lineage-relation-evidence-main min-w-0">
                                    <div className="mb-1 flex flex-wrap items-center gap-2">
                                        <span className="font-medium text-slate-800">SQL {index + 1}</span>
                                        <Tag className="lineage-relation-evidence-file" title={item.sourceFiles.join('、') || '未记录文件'}>{fileLabel(item)}</Tag>
                                        <span className="text-xs text-slate-400">语句序号 {(item.statementIndex || 0) + 1}</span>
                                        {item.ambiguityCodes.length > 0 && <Tag color="warning">存在歧义</Tag>}
                                    </div>
                                    <div className="lineage-relation-evidence-fields truncate text-xs text-slate-500" title={`${sourceFields.join('、') || '-'} → ${targetFields.join('、') || '-'}`}>
                                        <span>{sourceFields.join('、') || '-'}</span>
                                        <span className="lineage-relation-evidence-arrow" aria-hidden="true">→</span>
                                        <span>{targetFields.join('、') || '-'}</span>
                                    </div>
                                </div>
                                <span className="lineage-relation-evidence-action shrink-0 text-xs font-medium text-blue-600">全屏查看</span>
                            </button>
                        );
                    })}
                </div>
            )}
            <Modal
                open={Boolean(selectedEvidence)}
                title={selectedEvidence ? `SQL ${selectedEvidenceIndex! + 1} · ${fileLabel(selectedEvidence)}` : 'SQL 证据'}
                footer={null}
                width="100vw"
                zIndex={1200}
                rootClassName="lineage-sql-evidence-modal"
                className="lineage-sql-evidence-dialog"
                transitionName=""
                maskTransitionName=""
                style={{ top: 0, maxWidth: '100vw', paddingBottom: 0 }}
                styles={{
                    container: { height: '100vh', borderRadius: 0 },
                    body: { height: 'calc(100vh - 56px)', overflow: 'auto' },
                }}
                onCancel={() => setSelectedEvidenceIndex(null)}
            >
                {selectedEvidence ? (
                    <div className="lineage-sql-evidence-body">
                        <div className="mb-4 flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-slate-500">
                            <span>来源文件：{selectedEvidence.sourceFiles.join('、') || '未记录'}</span>
                            <span>语句序号：{(selectedEvidence.statementIndex || 0) + 1}</span>
                            <span>关系字段：{selectedSourceFields.join('、') || '-'} {' → '} {selectedTargetFields.join('、') || '-'}</span>
                        </div>
                        <div className="mb-3 flex flex-wrap items-center gap-4 text-xs text-slate-500">
                            <span><i className="mr-1 inline-block h-2 w-2 rounded-sm bg-sky-400" />源表</span>
                            <span><i className="mr-1 inline-block h-2 w-2 rounded-sm bg-emerald-400" />目标表</span>
                            <span><i className="mr-1 inline-block h-2 w-2 rounded-sm bg-amber-400" />源字段</span>
                            <span><i className="mr-1 inline-block h-2 w-2 rounded-sm bg-rose-400" />目标字段</span>
                            <span><i className="mr-1 inline-block h-2 w-2 rounded-sm bg-violet-400" />重合关键字</span>
                        </div>
                        <pre className="lineage-sql-code-block min-h-[calc(100vh-180px)] overflow-auto whitespace-pre-wrap rounded-lg bg-slate-900 p-5 text-sm leading-7 text-slate-100">
                            <code
                                className="hljs sql"
                                style={{ background: 'transparent', padding: 0, fontSize: 'inherit', lineHeight: 'inherit' }}
                                dangerouslySetInnerHTML={{
                                    __html: buildHighlightedSqlHtml(
                                        selectedEvidence.snippet || '未记录 SQL 内容',
                                        sourceTable,
                                        targetTable,
                                        selectedSourceFields,
                                        selectedTargetFields
                                    ),
                                }}
                            />
                        </pre>
                    </div>
                ) : null}
            </Modal>
        </div>
    );
};

export default RelationEvidencePanel;
