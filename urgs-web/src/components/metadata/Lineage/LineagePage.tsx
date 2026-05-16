import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Layout, Input, Button, Drawer, message, Empty, Tag, Pagination, Tooltip, Segmented, Checkbox } from 'antd';
import {
    SearchOutlined,
    TableOutlined,
    RightOutlined,
    DownOutlined,
    FileTextOutlined,
    DownloadOutlined,
    UserOutlined,
    RobotOutlined,
} from '@ant-design/icons';
import {
    searchTables,
    exportLineage,
    LineageSearchOwnerGroup,
    LineageSearchTableItem,
    LineageGraphDirection,
} from '@/api/lineage';
import LineageReportModal from './analysis/components/LineageReportModal';
import LineageGraphContent from './analysis/components/LineageGraphContent';
import LineageEngineToolbar from './analysis/components/LineageEngineToolbar';
import { useLineageEngineController } from './analysis/hooks/useLineageEngineController';
import { useLineageGraphLoader } from './analysis/hooks/useLineageGraphLoader';
import { hasPermission } from '@/utils/permission';
import AICodeReport from '@/components/version/AICodeReport';

const { Sider, Content } = Layout;

interface LineagePageProps {
    mode?: 'trace' | 'impact';
}

type DirectionOption = 'upstream' | 'downstream';

const LineagePage: React.FC<LineagePageProps> = () => {
    const containerRef = useRef<HTMLDivElement>(null);
    const lastDirectionRef = useRef<LineageGraphDirection>('both');
    const [searchText, setSearchText] = useState('');
    const [searchResults, setSearchResults] = useState<LineageSearchOwnerGroup[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(20);
    const [total, setTotal] = useState(0);
    const [totalOwners, setTotalOwners] = useState(0);
    const [loading, setLoading] = useState(false);
    const [expandedTables, setExpandedTables] = useState<Set<string>>(new Set());
    const [expandedOwners, setExpandedOwners] = useState<Set<string>>(new Set());
    const [showReportModal, setShowReportModal] = useState(false);
    const [viewMode, setViewMode] = useState<'canvas' | 'list'>('list');
    const [directionOptions, setDirectionOptions] = useState<DirectionOption[]>(['upstream', 'downstream']);
    const queryDirection = useMemo<LineageGraphDirection>(() => (
        directionOptions.length === 2 ? 'both' : directionOptions[0] || 'both'
    ), [directionOptions]);
    const canExport = true;
    const canOpenAuditBoard = hasPermission('version:ai:audit');
    const engineController = useLineageEngineController();
    const [showAuditBoard, setShowAuditBoard] = useState(false);
    const {
        selectedTable,
        selectedQualifiedName,
        selectedField,
        nodes,
        links,
        listNodes,
        listLinks,
        graphMeta,
        graphLoading,
        listLoading,
        listDetailsLoaded,
        handleSelectTable,
        loadListDetails,
    } = useLineageGraphLoader(queryDirection);

    const toggleTableExpand = (qualifiedName: string) => {
        setExpandedTables(prev => {
            const next = new Set(prev);
            if (next.has(qualifiedName)) {
                next.delete(qualifiedName);
            } else {
                next.add(qualifiedName);
            }
            return next;
        });
    };

    const toggleOwnerExpand = (ownerName: string) => {
        setExpandedOwners(prev => {
            const next = new Set(prev);
            if (next.has(ownerName)) {
                next.delete(ownerName);
            } else {
                next.add(ownerName);
            }
            return next;
        });
    };

    useEffect(() => {
        handleSearch();
    }, []);

    useEffect(() => {
        if (viewMode === 'list' && selectedTable && !listDetailsLoaded && !listLoading) {
            loadListDetails();
        }
    }, [listDetailsLoaded, listLoading, loadListDetails, selectedTable, viewMode]);

    useEffect(() => {
        if (lastDirectionRef.current === queryDirection) {
            return;
        }
        lastDirectionRef.current = queryDirection;
        if (selectedTable) {
            handleSelectTable(selectedTable, selectedQualifiedName || undefined);
        }
    }, [handleSelectTable, queryDirection, selectedQualifiedName, selectedTable]);

    const handleDirectionChange = (checkedValues: any[]) => {
        const next = checkedValues as DirectionOption[];
        if (next.length === 0) {
            message.warning('至少选择一个查询方向');
            return;
        }
        setDirectionOptions(next);
    };

    const handleSearch = async (page: number = 1) => {
        setLoading(true);
        try {
            const res = await searchTables(searchText, page, pageSize);
            if (res && res.groupedList) {
                setSearchResults(res.groupedList);
                setTotal(res.total || 0);
                setTotalOwners(res.totalOwners || 0);
                setCurrentPage(page);
                setExpandedOwners(new Set((res.groupedList || []).map(group => group.ownerName)));
            } else {
                setSearchResults([]);
                setTotal(0);
                setTotalOwners(0);
                if (searchText.trim()) {
                    message.info('未找到相关表');
                }
            }
        } catch (error: any) {
            message.error(`查询失败: ${error.message || '未知错误'}`);
        } finally {
            setLoading(false);
        }
    };

    const handleExport = async (tableName: string, e: React.MouseEvent, columnName?: string, qualifiedName?: string) => {
        e.stopPropagation();
        if (!canExport) {
            return;
        }
        try {
            message.loading({ content: '正在导出...', key: 'export' });
            const blob = await exportLineage(tableName, columnName, qualifiedName);
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            let filename = `${qualifiedName || tableName}`;
            if (columnName) {
                filename += `_${columnName}`;
            }
            filename += `_血缘导出.xlsx`;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
            message.success({ content: '导出成功', key: 'export' });
        } catch (error) {
            message.error({ content: '导出失败', key: 'export' });
        }
    };

    return (
        <div
            ref={containerRef}
            style={{
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                minHeight: 0
            }}
        >
            <style>{`
                .ant-spin-nested-loading, .ant-spin-container {
                    height: 100% !important;
                }
            `}</style>
            <div style={{ padding: '12px 16px', borderBottom: '1px solid #f0f0f0', background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div>
                            <div style={{ fontSize: 14, fontWeight: 600, color: '#1f2937' }}>SQL Lineage</div>
                            <div style={{ fontSize: 12, color: '#8c8c8c' }}>血缘模块</div>
                        </div>
                    {selectedQualifiedName && <Tag color="blue">{selectedQualifiedName}</Tag>}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                    <Segmented
                        options={[
                            { label: '流程图', value: 'canvas', icon: <TableOutlined /> },
                            { label: '列表', value: 'list', icon: <FileTextOutlined /> },
                        ]}
                        value={viewMode}
                        onChange={(val: any) => setViewMode(val)}
                    />
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '4px 12px', border: '1px solid #e5e7eb', borderRadius: 8, background: '#f8fafc' }}>
                        <span style={{ fontSize: 13, color: '#4b5563', whiteSpace: 'nowrap' }}>查询方向</span>
                        <Checkbox.Group value={directionOptions} onChange={handleDirectionChange}>
                            <Checkbox value="upstream">上游</Checkbox>
                            <Checkbox value="downstream">下游</Checkbox>
                        </Checkbox.Group>
                    </div>
                    <Button
                        icon={<RobotOutlined />}
                        disabled={!canOpenAuditBoard}
                        title={canOpenAuditBoard ? '在当前血缘页面打开 SQL 血缘事后校验看板' : '缺少 version:ai:audit 权限'}
                        onClick={() => setShowAuditBoard(true)}
                    >
                        打开事后校验
                    </Button>
                    <LineageEngineToolbar controller={engineController} />
                </div>
            </div>
            <Layout style={{ flex: 1, minHeight: 0 }}>
                <Sider width={300} theme="light" style={{ borderRight: '1px solid #f0f0f0' }}>

                    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
                        <div style={{ padding: '16px', borderBottom: '1px solid #f0f0f0' }}>
                            <div style={{ marginBottom: 16 }}>
                                <h3>血缘搜索</h3>
                                <p style={{ color: '#888', fontSize: '12px' }}>按用户/Schema 分组浏览，支持搜索用户、表、字段</p>
                            </div>
                            <div style={{ display: 'flex', gap: '8px' }}>
                                <Input
                                    placeholder="输入用户、表或字段关键词"
                                    value={searchText}
                                    onChange={e => setSearchText(e.target.value)}
                                    onPressEnter={() => handleSearch(1)}
                                />
                                <Button type="primary" icon={<SearchOutlined />} onClick={() => handleSearch(1)} loading={loading}>
                                </Button>
                            </div>
                        </div>
                        <div style={{ flex: 1, overflowY: 'auto', padding: '0' }}>
                            {(() => {
                                return [...searchResults]
                                    .sort((a, b) => a.ownerName.localeCompare(b.ownerName))
                                    .map((group) => (
                                        <div key={group.ownerName} style={{ borderBottom: '1px solid #f0f0f0' }}>
                                            <div
                                                onClick={() => toggleOwnerExpand(group.ownerName)}
                                                style={{
                                                    padding: '12px 16px',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    gap: '8px',
                                                    background: '#fafafa',
                                                    cursor: 'pointer'
                                                }}
                                            >
                                                {expandedOwners.has(group.ownerName)
                                                    ? <DownOutlined style={{ fontSize: 10, color: '#666' }} />
                                                    : <RightOutlined style={{ fontSize: 10, color: '#666' }} />}
                                                <UserOutlined style={{ color: '#8c8c8c' }} />
                                                <span style={{ fontWeight: 600, flex: 1 }}>{group.ownerName}</span>
                                                <Tag>{group.tableCount} 张表</Tag>
                                            </div>
                                            {expandedOwners.has(group.ownerName) && group.tables
                                                .slice()
                                                .sort((a, b) => a.tableName.localeCompare(b.tableName))
                                                .map((item: LineageSearchTableItem) => (
                                                    <div key={item.qualifiedName} style={{ borderTop: '1px solid #f5f5f5' }}>
                                                        <div
                                                            style={{
                                                                padding: '12px 16px 12px 32px',
                                                                display: 'flex',
                                                                alignItems: 'center',
                                                                gap: '8px'
                                                            }}
                                                        >
                                                            <div
                                                                onClick={(e) => {
                                                                    e.stopPropagation();
                                                                    toggleTableExpand(item.qualifiedName);
                                                                }}
                                                                style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', padding: '4px' }}
                                                            >
                                                                {expandedTables.has(item.qualifiedName)
                                                                    ? <DownOutlined style={{ fontSize: 10, color: '#666' }} />
                                                                    : <RightOutlined style={{ fontSize: 10, color: '#666' }} />}
                                                            </div>
                                                            <div
                                                                onClick={() => handleSelectTable(item.tableName, item.qualifiedName)}
                                                                className="hover:text-blue-500 cursor-pointer transition-colors"
                                                                style={{ display: 'flex', alignItems: 'center', gap: '8px', flex: 1 }}
                                                            >
                                                                <TableOutlined style={{ color: '#1890ff' }} />
                                                                <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                                                                    <span style={{ fontWeight: 500 }}>{item.tableName}</span>
                                                                    <span style={{ color: '#999', fontSize: 12 }}>{item.qualifiedName}</span>
                                                                </div>
                                                            </div>
                                                            {canExport ? (
                                                                <Tooltip title="导出血缘 Excel">
                                                                    <Button
                                                                        type="text"
                                                                        size="small"
                                                                        icon={<DownloadOutlined />}
                                                                        onClick={(e) => handleExport(item.tableName, e, undefined, item.qualifiedName)}
                                                                    />
                                                                </Tooltip>
                                                            ) : null}
                                                        </div>
                                                        {expandedTables.has(item.qualifiedName) && item.columns && item.columns.length > 0 && (
                                                            <div style={{ padding: '0 16px 12px 52px', display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                                                                {item.columns.map((col: string) => (
                                                                    <Tag
                                                                        key={`${item.qualifiedName}.${col}`}
                                                                        onClick={(e) => {
                                                                            e.stopPropagation();
                                                                            handleSelectTable(item.tableName, item.qualifiedName, col);
                                                                        }}
                                                                        className="group hover:text-blue-500 hover:border-blue-500"
                                                                        style={{
                                                                            cursor: 'pointer',
                                                                            margin: 0,
                                                                            display: 'inline-flex',
                                                                            alignItems: 'center',
                                                                            gap: '4px',
                                                                            ...(searchText && col.toLowerCase().includes(searchText.toLowerCase()) ? {
                                                                                backgroundColor: '#e6f7ff',
                                                                                borderColor: '#1890ff'
                                                                            } : {})
                                                                        }}
                                                                    >
                                                                        {col}
                                                                        {canExport ? (
                                                                            <Tooltip title="导出字段血缘">
                                                                                <DownloadOutlined
                                                                                    className="opacity-0 group-hover:opacity-100 transition-opacity"
                                                                                    style={{ fontSize: '10px', color: '#666' }}
                                                                                    onClick={(e) => handleExport(item.tableName, e, col, item.qualifiedName)}
                                                                                />
                                                                            </Tooltip>
                                                                        ) : null}
                                                                    </Tag>
                                                                ))}
                                                            </div>
                                                        )}
                                                    </div>
                                                ))}
                                        </div>
                                    ));
                            })()}
                            {searchResults.length === 0 && !loading && (
                                <div style={{ padding: '24px 0' }}>
                                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无搜索结果" />
                                </div>
                            )}
                        </div>
                        <div style={{ padding: '8px 16px', borderTop: '1px solid #f0f0f0', textAlign: 'center' }}>
                            <div style={{ color: '#999', fontSize: 12, marginBottom: 8 }}>
                                共 {totalOwners} 个用户/Schema，{total} 张表
                            </div>
                            <Pagination
                                simple
                                size="small"
                                current={currentPage}
                                pageSize={pageSize}
                                total={total}
                                onChange={(page) => handleSearch(page)}
                            />
                        </div>
                    </div>
                </Sider>
                <Content style={{ background: '#fff', position: 'relative', minHeight: 0 }}>
                    <LineageGraphContent
                        graphLoading={graphLoading}
                        nodes={nodes}
                        links={links}
                        listLoading={listLoading}
                        listNodes={listNodes}
                        listLinks={listLinks}
                        mode={queryDirection === 'downstream' ? 'impact' : 'trace'}
                        viewMode={viewMode}
                        selectedTable={selectedTable}
                        selectedField={selectedField}
                        graphMeta={graphMeta}
                        onGenerateReport={canExport ? () => setShowReportModal(true) : undefined}
                    />
                </Content>
                {canExport && showReportModal && selectedField && (
                    <LineageReportModal
                        visible={showReportModal}
                        tableName={nodes.find(n => n.id === selectedField.nodeId)?.title || ''}
                        columnName={nodes.find(n => n.id === selectedField.nodeId)?.columns.find(c => c.id === selectedField.colId)?.name || ''}
                        onClose={() => setShowReportModal(false)}
                    />
                )}
                <Drawer
                    title="SQL 血缘事后校验"
                    open={showAuditBoard}
                    onClose={() => setShowAuditBoard(false)}
                    size="92vw"
                    destroyOnHidden
                    styles={{ body: { padding: 16, background: '#f8fafc' } }}
                >
                    <AICodeReport />
                </Drawer>
            </Layout>
        </div>
    );
};

export default LineagePage;
