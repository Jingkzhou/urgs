import React, { useMemo, useState } from 'react';
import { Table, Tag, Tooltip, Empty, Typography, Button, Modal } from 'antd';
import { NodeData, LinkData, RELATION_STYLES } from '../types';
import { FileTextOutlined } from '@ant-design/icons';
import RelationEvidencePanel, { getLinkEvidenceCount } from './RelationEvidencePanel';
import { buildNodeRanks, splitQualifiedTitle, sameTableLoose } from '../utils/lineageGraphDensity';
import type { EndToEndRelation, LineageDisplayMode } from '../utils/endToEndLineage';

const { Text } = Typography;

const normalizeArray = (value: any): string[] => {
    if (Array.isArray(value)) {
        return value.filter(Boolean).map(String);
    }
    return value ? [String(value)] : [];
};

const formatColumnSummary = (columns: string[], fallback: string) => {
    if (columns.length === 0) {
        return fallback;
    }
    if (columns.length <= 2) {
        return columns.join('、');
    }
    return `${columns.slice(0, 2).join('、')} 等 ${columns.length} 个字段`;
};

const formatRankLabel = (rank: number) => {
    if (rank < 0) {
        return `上游 ${Math.abs(rank)}`;
    }
    if (rank > 0) {
        return `下游 ${rank}`;
    }
    return '当前';
};

const formatLevelPath = (sourceRank: number, targetRank: number) => {
    const sourceLabel = formatRankLabel(sourceRank);
    const targetLabel = formatRankLabel(targetRank);
    return sourceLabel === targetLabel ? sourceLabel : `${sourceLabel} → ${targetLabel}`;
};

interface LineageListViewProps {
    nodes: NodeData[];
    links: LinkData[];
    displayMode: LineageDisplayMode;
    endToEndRelations: EndToEndRelation[];
    selectedTable: string | null;
    selectedField: { nodeId: string, colId: string } | null;
}

const LineageListView: React.FC<LineageListViewProps> = ({
    nodes,
    links,
    displayMode,
    endToEndRelations,
    selectedTable,
    selectedField
}) => {
    const [selectedEvidence, setSelectedEvidence] = useState<any | null>(null);

    const endToEndTableData = useMemo(() => endToEndRelations.map((relation) => ({
        key: relation.key,
        targetCategory: relation.targetCategory,
        endpoint: `${relation.target.tableName}.${relation.target.columnName}`,
        source: `${relation.source.tableName}.${relation.source.columnName}`,
        current: relation.current ? `${relation.current.tableName}.${relation.current.columnName}` : '-',
        pathCount: relation.pathCount,
        minLevel: relation.minLevel,
        maxLevel: relation.maxLevel,
        schemaPath: relation.schemaPath,
        tableCount: relation.tableCount,
        fieldCount: relation.fieldCount,
        taskCount: relation.taskCount,
        relationTypeSummary: relation.relationTypeSummary,
        completeness: relation.completeness,
        paths: relation.paths,
    })), [endToEndRelations]);

    const tableData = useMemo(() => {
        const colMap = new Map<string, { tableId: string, tableName: string, colName: string }>();
        const nodeMap = new Map<string, NodeData>();
        const ranks = buildNodeRanks(nodes, links, selectedTable, selectedField);

        nodes.forEach(node => {
            nodeMap.set(node.id, node);
            node.columns.forEach(col => {
                colMap.set(col.id, {
                    tableId: node.id,
                    tableName: node.title,
                    colName: col.name
                });
            });
        });

        return links.map((link, index) => {
            const sourceCol = colMap.get(link.sourceColumnId);
            const targetCol = colMap.get(link.targetColumnId);
            const sourceNode = nodeMap.get(link.sourceNodeId);
            const targetNode = nodeMap.get(link.targetNodeId);
            const sourceTable = sourceCol?.tableName || sourceNode?.title || link.properties?.sourceTable || 'Unknown';
            const targetTable = targetCol?.tableName || targetNode?.title || link.properties?.targetTable || 'Unknown';
            const sourceSchema = splitQualifiedTitle(sourceTable).owner || '-';
            const targetSchema = splitQualifiedTitle(targetTable).owner || '-';
            const sourceRank = ranks.get(sourceCol?.tableId || sourceNode?.id || link.sourceNodeId) ?? 0;
            const targetRank = ranks.get(targetCol?.tableId || targetNode?.id || link.targetNodeId) ?? 0;
            const relationStyle = link.type ? RELATION_STYLES[link.type] : null;
            const relationCount = Number(link.properties?.relationCount || 0);
            const sourceColumns = normalizeArray(link.properties?.sourceColumns);
            const targetColumns = normalizeArray(link.properties?.targetColumns);
            const sourceColumn = sourceCol?.colName || link.properties?.sourceColumn || link.properties?.sourceColumnName
                || formatColumnSummary(sourceColumns, link.sourceColumnId || `表级关系(${relationCount || 1})`);
            const targetColumn = targetCol?.colName || link.properties?.targetColumn || link.properties?.targetColumnName
                || formatColumnSummary(targetColumns, link.targetColumnId || `表级关系(${relationCount || 1})`);

            // Handle source file
            const sourceFiles = link.properties?.sourceFiles;
            const normalizedSourceFiles = normalizeArray(
                sourceFiles || link.properties?.source_file || link.properties?.sourceFile
            );
            const sourceFile = normalizedSourceFiles[0];

            return {
                key: link.id || `${index}`,
                levelPath: formatLevelPath(sourceRank, targetRank),
                levelSort: Math.min(sourceRank, targetRank),
                sourceRank,
                targetRank,
                schemaPath: sourceSchema === targetSchema ? sourceSchema : `${sourceSchema} → ${targetSchema}`,
                sourceSchema,
                targetSchema,
                sourceTable,
                sourceColumn,
                relationType: link.type || 'UNKNOWN',
                relationLabel: relationStyle?.label || link.type || '未知关系',
                relationColor: relationStyle?.color || '#8c8c8c',
                targetTable,
                targetColumn,
                sourceColumnTooltip: sourceColumns.join('、'),
                targetColumnTooltip: targetColumns.join('、'),
                snippet: link.properties?.snippet,
                sourceFile: sourceFile,
                sourceFiles: normalizedSourceFiles,
                evidenceCount: getLinkEvidenceCount(link),
                link,
                isHighlighted: (selectedField && (link.sourceColumnId === selectedField.colId || link.targetColumnId === selectedField.colId)) ||
                    (!selectedField && selectedTable && (sameTableLoose(sourceTable, selectedTable) || sameTableLoose(targetTable, selectedTable)))
            };
        }).sort((a, b) => (
            a.levelSort - b.levelSort
            || a.sourceRank - b.sourceRank
            || a.targetRank - b.targetRank
            || a.sourceSchema.localeCompare(b.sourceSchema)
            || a.sourceTable.localeCompare(b.sourceTable)
            || a.targetTable.localeCompare(b.targetTable)
        ));
    }, [nodes, links, selectedTable, selectedField]);

    const handleViewEvidence = (record: any) => setSelectedEvidence(record);

    const columns = [
        {
            title: '层级',
            dataIndex: 'levelPath',
            key: 'levelPath',
            width: 130,
            fixed: 'left' as const,
            render: (text: string) => <Tag color="geekblue">{text}</Tag>,
            sorter: (a: any, b: any) => (
                a.levelSort - b.levelSort
                || a.sourceRank - b.sourceRank
                || a.targetRank - b.targetRank
            ),
            defaultSortOrder: 'ascend' as const,
        },
        {
            title: 'Schema',
            dataIndex: 'schemaPath',
            key: 'schemaPath',
            width: 180,
            render: (text: string, record: any) => (
                <Tooltip title={`源: ${record.sourceSchema} / 目标: ${record.targetSchema}`}>
                    <Text type="secondary" style={{ fontSize: 12 }}>{text}</Text>
                </Tooltip>
            ),
            sorter: (a: any, b: any) => (
                a.sourceSchema.localeCompare(b.sourceSchema)
                || a.targetSchema.localeCompare(b.targetSchema)
            ),
        },
        {
            title: '源表',
            dataIndex: 'sourceTable',
            key: 'sourceTable',
            render: (text: string) => <Text strong>{text}</Text>,
            sorter: (a: any, b: any) => a.sourceTable.localeCompare(b.sourceTable),
        },
        {
            title: '源字段',
            dataIndex: 'sourceColumn',
            key: 'sourceColumn',
            render: (text: string, record: any) => (
                <Tooltip title={record.sourceColumnTooltip || text}>
                    <Tag color="blue">{text}</Tag>
                </Tooltip>
            ),
        },
        {
            title: '关联类型',
            dataIndex: 'relationLabel',
            key: 'relationLabel',
            width: 120,
            render: (text: string, record: any) => (
                <Tag color={record.relationColor} style={{ borderRadius: 4 }}>
                    {text}
                </Tag>
            ),
            filters: Array.from(new Set(tableData.map(item => item.relationLabel))).map(label => ({ text: label, value: label })),
            onFilter: (value: any, record: any) => record.relationLabel === value,
        },
        {
            title: '目标表',
            dataIndex: 'targetTable',
            key: 'targetTable',
            render: (text: string) => <Text strong>{text}</Text>,
            sorter: (a: any, b: any) => a.targetTable.localeCompare(b.targetTable),
        },
        {
            title: '目标字段',
            dataIndex: 'targetColumn',
            key: 'targetColumn',
            render: (text: string, record: any) => (
                <Tooltip title={record.targetColumnTooltip || text}>
                    <Tag color="green">{text}</Tag>
                </Tooltip>
            ),
        },
        {
            title: '源文件',
            dataIndex: 'sourceFile',
            key: 'sourceFile',
            width: 150,
            render: (text: string, record: any) => (
                text ? (
                    <Tooltip title={record.sourceFiles.join('\n')}>
                        <Text type="secondary" style={{ fontSize: 12 }}>
                            {record.sourceFiles.length > 1
                                ? `${record.sourceFiles.length} 个文件`
                                : text.split('/').pop()}
                        </Text>
                    </Tooltip>
                ) : <Text type="secondary" style={{ fontSize: 12 }}>-</Text>
            ),
            sorter: (a: any, b: any) => (a.sourceFile || '').localeCompare(b.sourceFile || ''),
        },
        {
            title: 'SQL 证据',
            key: 'action',
            width: 130,
            align: 'center' as const,
            render: (_: any, record: any) => (
                record.evidenceCount > 0 || record.snippet ? (
                    <Tooltip title={`查看 ${record.evidenceCount || 1} 段 SQL 证据`}>
                        <Button
                            type="link"
                            size="small"
                            icon={<FileTextOutlined style={{ color: '#1890ff' }} />}
                            onClick={() => handleViewEvidence(record)}
                        >
                            {record.evidenceCount || 1} 段
                        </Button>
                    </Tooltip>
                ) : <Text type="secondary" style={{ fontSize: 12 }}>-</Text>
            ),
        }
    ];

    const endToEndColumns = [
        {
            title: '目标对象',
            dataIndex: 'endpoint',
            key: 'endpoint',
            fixed: 'left' as const,
            render: (text: string, record: any) => (
                <div>
                    <Text strong>{text}</Text>
                    <div style={{ marginTop: 4 }}>
                        <Tag color="blue" style={{ borderRadius: 4 }}>{record.targetCategory}</Tag>
                        <Tag color={record.completeness === '完整路径' ? 'green' : 'orange'} style={{ borderRadius: 4 }}>
                            {record.completeness}
                        </Tag>
                    </div>
                </div>
            ),
            sorter: (a: any, b: any) => a.endpoint.localeCompare(b.endpoint),
        },
        {
            title: '起点 / 当前字段',
            key: 'sourceCurrent',
            width: 260,
            render: (_: any, record: any) => (
                <div>
                    <Tooltip title={record.source}>
                        <Text>{record.source}</Text>
                    </Tooltip>
                    <div>
                        <Text type="secondary" style={{ fontSize: 12 }}>当前: {record.current}</Text>
                    </div>
                </div>
            ),
        },
        {
            title: '路径数',
            dataIndex: 'pathCount',
            key: 'pathCount',
            width: 90,
            render: (value: number) => <Tag color="geekblue">{value}</Tag>,
            sorter: (a: any, b: any) => a.pathCount - b.pathCount,
        },
        {
            title: '层级',
            key: 'level',
            width: 120,
            render: (_: any, record: any) => `${record.minLevel} - ${record.maxLevel}`,
            sorter: (a: any, b: any) => a.minLevel - b.minLevel || a.maxLevel - b.maxLevel,
        },
        {
            title: '摘要证据',
            key: 'summaryEvidence',
            width: 260,
            render: (_: any, record: any) => (
                <div style={{ lineHeight: 1.8 }}>
                    <Text type="secondary">中间表 {Math.max(0, record.tableCount - 2)} / 中间字段 {Math.max(0, record.fieldCount - 2)}</Text>
                    <br />
                    <Text type="secondary">任务数 {record.taskCount}</Text>
                    <br />
                    <Tooltip title={record.relationTypeSummary}>
                        <Text type="secondary">{record.relationTypeSummary}</Text>
                    </Tooltip>
                </div>
            ),
        },
        {
            title: 'Schema路径',
            dataIndex: 'schemaPath',
            key: 'schemaPath',
            width: 220,
            render: (text: string) => (
                <Tooltip title={text}>
                    <Text type="secondary" style={{ fontSize: 12 }}>{text}</Text>
                </Tooltip>
            ),
            sorter: (a: any, b: any) => a.schemaPath.localeCompare(b.schemaPath),
        },
    ];

    const renderExpandedPath = (record: any) => (
        <div style={{ padding: '8px 16px' }}>
            {record.paths.slice(0, 5).map((path: any[], index: number) => (
                <div key={`${record.key}-${index}`} style={{ marginBottom: 8 }}>
                    <Tag color="default">路径 {index + 1}</Tag>
                    <Text>{path.map(step => `${step.tableName}.${step.columnName}`).join(' -> ')}</Text>
                </div>
            ))}
            {record.paths.length > 5 ? (
                <Text type="secondary" style={{ fontSize: 12 }}>仅展示前 5 条，中间明细可切回完整链路查看。</Text>
            ) : null}
        </div>
    );

    if (displayMode !== 'full') {
        if (endToEndTableData.length === 0) {
            return <Empty description="暂无端到端关系" style={{ marginTop: 100 }} />;
        }

        return (
            <div style={{ padding: '16px', height: '100%', overflow: 'auto' }}>
                <Table
                    dataSource={endToEndTableData}
                    columns={endToEndColumns}
                    size="middle"
                    expandable={{ expandedRowRender: renderExpandedPath }}
                    pagination={{
                        pageSize: 20,
                        showSizeChanger: true,
                        showTotal: (total) => `共 ${total} 个目标对象`
                    }}
                />
            </div>
        );
    }


    if (tableData.length === 0) {
        return <Empty description="暂无关联数据" style={{ marginTop: 100 }} />;
    }

    return (
        <div style={{ padding: '16px', height: '100%', overflow: 'auto' }}>
            <Table
                dataSource={tableData}
                columns={columns}
                size="middle"
                pagination={{
                    pageSize: 20,
                    showSizeChanger: true,
                    showTotal: (total) => `共 ${total} 条关系`
                }}
                rowClassName={(record) => record.isHighlighted ? 'bg-blue-50' : ''}
            />
            {selectedEvidence && (
                <Modal
                    open
                    title={`${selectedEvidence.sourceTable}.${selectedEvidence.sourceColumn} → ${selectedEvidence.targetTable}.${selectedEvidence.targetColumn}`}
                    footer={null}
                    width={920}
                    onCancel={() => setSelectedEvidence(null)}
                >
                    <RelationEvidencePanel
                        active
                        link={selectedEvidence.link}
                        sourceTable={selectedEvidence.sourceTable}
                        targetTable={selectedEvidence.targetTable}
                        sourceColumn={selectedEvidence.sourceColumn}
                        targetColumn={selectedEvidence.targetColumn}
                    />
                </Modal>
            )}
            <style>{`
                .bg-blue-50 {
                    background-color: #f0f7ff !important;
                }
            `}</style>
        </div>
    );
};

export default LineageListView;
