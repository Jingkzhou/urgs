import React, { useMemo, useState } from 'react';
import { Table, Tag, Tooltip, Empty, Typography, Button } from 'antd';
import { NodeData, LinkData, RELATION_STYLES } from '../types';
import { FileTextOutlined } from '@ant-design/icons';
import CodeModal from './CodeModal';
import { buildNodeRanks, splitQualifiedTitle, sameTableLoose } from '../utils/lineageGraphDensity';

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
    selectedTable: string | null;
    selectedField: { nodeId: string, colId: string } | null;
}

const LineageListView: React.FC<LineageListViewProps> = ({
    nodes,
    links,
    selectedTable,
    selectedField
}) => {
    const [codeModalVisible, setCodeModalVisible] = useState(false);
    const [selectedCode, setSelectedCode] = useState<{
        code: string;
        sourceFile?: string;
        linkType?: string;
        searchTerm?: string;
    } | null>(null);

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
            const sourceFile = Array.isArray(sourceFiles)
                ? sourceFiles[0]
                : (sourceFiles || link.properties?.source_file || link.properties?.sourceFile);

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

    const handleViewCode = (record: any) => {
        setSelectedCode({
            code: record.snippet,
            sourceFile: record.sourceFile,
            linkType: record.relationType,
            searchTerm: record.sourceColumn
        });
        setCodeModalVisible(true);
    };

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
            render: (text: string) => (
                text ? (
                    <Tooltip title={text}>
                        <Text type="secondary" style={{ fontSize: 12 }}>
                            {text.split('/').pop()}
                        </Text>
                    </Tooltip>
                ) : <Text type="secondary" style={{ fontSize: 12 }}>-</Text>
            ),
            sorter: (a: any, b: any) => (a.sourceFile || '').localeCompare(b.sourceFile || ''),
        },
        {
            title: '逻辑/源码',
            key: 'action',
            width: 100,
            align: 'center' as const,
            render: (_: any, record: any) => (
                record.snippet ? (
                    <Tooltip title="查看源码逻辑">
                        <Button
                            type="text"
                            icon={<FileTextOutlined style={{ color: '#1890ff' }} />}
                            onClick={() => handleViewCode(record)}
                        />
                    </Tooltip>
                ) : <Text type="secondary" style={{ fontSize: 12 }}>-</Text>
            ),
        }
    ];


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
            {selectedCode && (
                <CodeModal
                    visible={codeModalVisible}
                    onClose={() => setCodeModalVisible(false)}
                    code={selectedCode.code}
                    sourceFile={selectedCode.sourceFile}
                    linkType={selectedCode.linkType}
                    searchTerm={selectedCode.searchTerm}
                />
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
