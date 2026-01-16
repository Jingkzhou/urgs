import React, { useMemo, useState } from 'react';
import { Table, Tag, Tooltip, Empty, Typography, Button } from 'antd';
import { NodeData, LinkData, RELATION_STYLES } from '../types';
import { FileTextOutlined } from '@ant-design/icons';
import CodeModal from './CodeModal';

const { Text } = Typography;

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

        nodes.forEach(node => {
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
            const relationStyle = link.type ? RELATION_STYLES[link.type] : null;

            // Handle source file
            const sourceFiles = link.properties?.sourceFiles;
            const sourceFile = Array.isArray(sourceFiles)
                ? sourceFiles[0]
                : (sourceFiles || link.properties?.source_file || link.properties?.sourceFile);

            return {
                key: link.id || `${index}`,
                sourceTable: sourceCol?.tableName || 'Unknown',
                sourceColumn: sourceCol?.colName || 'Unknown',
                relationType: link.type || 'UNKNOWN',
                relationLabel: relationStyle?.label || link.type || '未知关系',
                relationColor: relationStyle?.color || '#8c8c8c',
                targetTable: targetCol?.tableName || 'Unknown',
                targetColumn: targetCol?.colName || 'Unknown',
                snippet: link.properties?.snippet,
                sourceFile: sourceFile,
                isHighlighted: (selectedField && (link.sourceColumnId === selectedField.colId || link.targetColumnId === selectedField.colId)) ||
                    (!selectedField && selectedTable && (sourceCol?.tableName === selectedTable || targetCol?.tableName === selectedTable))
            };
        });
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
            render: (text: string) => <Tag color="blue">{text}</Tag>,
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
            render: (text: string) => <Tag color="green">{text}</Tag>,
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
