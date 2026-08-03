import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Layout, Input, Button, Drawer, message, Empty, Tag, Pagination, Tooltip, Checkbox, Space } from 'antd';
import * as XLSX from 'xlsx';
import {
    SearchOutlined,
    TableOutlined,
    LeftOutlined,
    RightOutlined,
    DownOutlined,
    DownloadOutlined,
    UserOutlined,
    FullscreenOutlined,
    FullscreenExitOutlined,
} from '@ant-design/icons';
import {
    searchTables,
    exportLineage,
    LineageSearchOwnerGroup,
    LineageSearchTableItem,
    LineageGraphDirection,
    LineageSearchNodeItem,
    LineageSearchNodeType,
    searchLineageNodes,
} from '@/api/lineage';
import LineageGraphContent from './analysis/components/LineageGraphContent';
import LineagePageActionBar, { LineageDirectionOption, LineageViewMode } from './analysis/components/LineagePageActionBar';
import { useLineageEngineController } from './analysis/hooks/useLineageEngineController';
import { useLineageGraphLoader } from './analysis/hooks/useLineageGraphLoader';
import { buildEndToEndRelations, type LineageDisplayMode } from './analysis/utils/endToEndLineage';
import { LinkData, NodeData, RELATION_STYLES } from './analysis/types';
import { hasPermission } from '@/utils/permission';
import AICodeReport from '@/components/version/AICodeReport';
import './LineagePage.css';

const { Content } = Layout;

interface LineagePageProps {
    mode?: 'trace' | 'impact';
}

const LineagePage: React.FC<LineagePageProps> = () => {
    const containerRef = useRef<HTMLDivElement>(null);
    const canvasRef = useRef<HTMLElement>(null);
    const lastDirectionRef = useRef<LineageGraphDirection>('downstream');
    const initialLineageTargetLoadedRef = useRef(false);
    const [searchText, setSearchText] = useState('');
    const [searchResults, setSearchResults] = useState<LineageSearchOwnerGroup[]>([]);
    const [currentPage, setCurrentPage] = useState(1);
    const pageSize = 20;
    const [total, setTotal] = useState(0);
    const [totalOwners, setTotalOwners] = useState(0);
    const [selectedOwnerTotal, setSelectedOwnerTotal] = useState(0);
    const [selectedOwnerName, setSelectedOwnerName] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);
    const [quickNodeTypes, setQuickNodeTypes] = useState<LineageSearchNodeType[]>(['TABLE', 'COLUMN', 'SQL_TASK', 'ANALYSIS']);
    const [quickResults, setQuickResults] = useState<LineageSearchNodeItem[]>([]);
    const [quickResultTotal, setQuickResultTotal] = useState(0);
    const [selectedQuickNode, setSelectedQuickNode] = useState<LineageSearchNodeItem | null>(null);
    const [expandedTables, setExpandedTables] = useState<Set<string>>(new Set());
    const [searchDrawerOpen, setSearchDrawerOpen] = useState(false);
    const [workspaceMode, setWorkspaceMode] = useState<'catalog' | 'canvas'>('catalog');
    const [canvasMaximized, setCanvasMaximized] = useState(false);
    const [viewMode, setViewMode] = useState<LineageViewMode>('canvas');
    const [displayMode, setDisplayMode] = useState<LineageDisplayMode>('full');
    const [directionOptions, setDirectionOptions] = useState<LineageDirectionOption[]>(['downstream']);
    const [lineageReturnHash, setLineageReturnHash] = useState<string | null>(null);
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
        selectedObjectUid,
        selectedColumnName,
        selectedField,
        nodes,
        links,
        listNodes,
        listLinks,
        graphLoading,
        listLoading,
        listDetailsLoaded,
        handleSelectTable,
        loadListDetails,
    } = useLineageGraphLoader(queryDirection);
    const selectedDisplayName = useMemo(() => {
        if (!selectedQualifiedName) {
            return null;
        }
        return selectedColumnName ? `${selectedQualifiedName}.${selectedColumnName}` : selectedQualifiedName;
    }, [selectedColumnName, selectedQualifiedName]);
    const exportDataLoading = (displayMode === 'endToEnd' || viewMode === 'list') && listLoading;

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

    useEffect(() => {
        handleSearch();
    }, []);

    useEffect(() => {
        if ((viewMode === 'list' || displayMode !== 'full') && selectedTable && !listDetailsLoaded && !listLoading) {
            loadListDetails();
        }
    }, [displayMode, listDetailsLoaded, listLoading, loadListDetails, selectedTable, viewMode]);

    useEffect(() => {
        if (lastDirectionRef.current === queryDirection) {
            return;
        }
        lastDirectionRef.current = queryDirection;
        if (selectedTable) {
            handleSelectTable(
                selectedTable,
                selectedQualifiedName || undefined,
                selectedColumnName || undefined,
                undefined,
                selectedObjectUid || undefined,
            );
        }
    }, [handleSelectTable, queryDirection, selectedColumnName, selectedObjectUid, selectedQualifiedName, selectedTable]);

    useEffect(() => {
        const handleFullscreenChange = () => {
            setCanvasMaximized(document.fullscreenElement === canvasRef.current);
        };
        document.addEventListener('fullscreenchange', handleFullscreenChange);
        return () => document.removeEventListener('fullscreenchange', handleFullscreenChange);
    }, []);

    const handleDirectionChange = (checkedValues: LineageDirectionOption[]) => {
        const next = checkedValues;
        if (next.length === 0) {
            message.warning('至少选择一个查询方向');
            return;
        }
        setDirectionOptions(next);
    };

    const handleCanvasMaximize = async () => {
        const canvasElement = canvasRef.current;
        if (!canvasElement) {
            return;
        }
        if (canvasMaximized) {
            if (document.fullscreenElement) {
                await document.exitFullscreen();
            } else {
                setCanvasMaximized(false);
            }
            return;
        }
        try {
            await canvasElement.requestFullscreen();
            setCanvasMaximized(true);
        } catch (error) {
            setCanvasMaximized(true);
        }
    };

    const handleGraphTableDoubleClick = useCallback((tableName: string, qualifiedName: string, objectUid?: string) => {
        setWorkspaceMode('canvas');
        setViewMode('canvas');
        handleSelectTable(tableName, qualifiedName, undefined, undefined, objectUid);
    }, [handleSelectTable]);

    const handleGraphFieldDoubleClick = useCallback((tableName: string, qualifiedName: string, columnName: string, objectUid?: string) => {
        setWorkspaceMode('canvas');
        setViewMode('canvas');
        handleSelectTable(tableName, qualifiedName, columnName, undefined, objectUid);
    }, [handleSelectTable]);

    const handleLineageSelect = useCallback((tableName: string, qualifiedName: string, columnName?: string, objectUid?: string) => {
        setWorkspaceMode('canvas');
        setViewMode('canvas');
        setSearchDrawerOpen(false);
        handleSelectTable(tableName, qualifiedName, columnName, undefined, objectUid);
    }, [handleSelectTable]);

    useEffect(() => {
        if (initialLineageTargetLoadedRef.current) {
            return;
        }
        const hashQuery = window.location.hash.includes('?') ? window.location.hash.split('?')[1] : '';
        const params = new URLSearchParams(hashQuery);
        const tableName = params.get('lineageTable');
        if (!tableName) {
            initialLineageTargetLoadedRef.current = true;
            return;
        }

        initialLineageTargetLoadedRef.current = true;
        const qualifiedName = params.get('lineageQualifiedName') || tableName;
        const columnName = params.get('lineageColumn') || undefined;
        const returnHash = params.get('lineageReturn') === 'regAsset'
            ? (params.get('lineageReturnHash') || '/metadata?subtab=asset')
            : null;
        const directionParam = params.get('lineageDirection');
        const initialDirection: LineageGraphDirection | undefined = (
            directionParam === 'upstream' || directionParam === 'downstream' || directionParam === 'both'
                ? directionParam
                : undefined
        );

        setWorkspaceMode('canvas');
        setViewMode('canvas');
        setSearchDrawerOpen(false);
        setSearchText(columnName || tableName);
        setLineageReturnHash(returnHash);
        if (initialDirection === 'both') {
            lastDirectionRef.current = 'both';
            setDirectionOptions(['upstream', 'downstream']);
        } else if (initialDirection === 'upstream') {
            lastDirectionRef.current = 'upstream';
            setDirectionOptions(['upstream']);
        } else if (initialDirection === 'downstream') {
            lastDirectionRef.current = 'downstream';
            setDirectionOptions(['downstream']);
        }
        handleSelectTable(tableName, qualifiedName, columnName, initialDirection);
    }, [handleSelectTable]);

    const handleBackFromCanvas = () => {
        if (lineageReturnHash) {
            window.location.hash = lineageReturnHash;
            return;
        }
        setWorkspaceMode('catalog');
    };

    const sortedOwnerGroups = useMemo(() => (
        [...searchResults].sort((a, b) => a.ownerName.localeCompare(b.ownerName))
    ), [searchResults]);

    const selectedOwnerGroup = useMemo(() => (
        sortedOwnerGroups.find(group => group.ownerName === selectedOwnerName) || null
    ), [selectedOwnerName, sortedOwnerGroups]);

    const selectedOwnerTables = useMemo(() => (
        selectedOwnerGroup?.tables?.slice().sort((a, b) => a.tableName.localeCompare(b.tableName)) || []
    ), [selectedOwnerGroup]);
    const showQuickResults = Boolean(searchText.trim() && quickResults.length > 0);
    const totalColumnCount = useMemo(() => (
        sortedOwnerGroups.reduce((sum, group) => sum + (group.columnCount || 0), 0)
    ), [sortedOwnerGroups]);

    const handleSearch = async (page: number = 1, ownerName: string | null = selectedOwnerName) => {
        setLoading(true);
        try {
            const [res, nodeRes] = await Promise.all([
                searchTables(searchText, page, pageSize, ownerName || undefined),
                searchText.trim()
                    ? searchLineageNodes(searchText, 1, 20, quickNodeTypes)
                    : Promise.resolve({ total: 0, page: 1, size: 20, list: [] as LineageSearchNodeItem[] }),
            ]);
            setQuickResults(nodeRes.list || []);
            setQuickResultTotal(nodeRes.total || 0);
            if (res && res.groupedList) {
                setSearchResults(res.groupedList);
                setTotal(res.total || 0);
                setTotalOwners(res.totalOwners || 0);
                setSelectedOwnerTotal(res.selectedOwnerTotal || 0);
                setCurrentPage(page);
                setExpandedTables(new Set());
            } else {
                setSearchResults([]);
                setTotal(0);
                setTotalOwners(0);
                setSelectedOwnerTotal(0);
                setExpandedTables(new Set());
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

    const handleQuickNodeSelect = (item: LineageSearchNodeItem) => {
        if (item.nodeType === 'TABLE') {
            handleLineageSelect(
                item.properties.tableName || item.displayName,
                item.properties.qualifiedName || item.qualifiedName || item.displayName,
                undefined,
                item.properties.objectUid,
            );
            return;
        }
        if (item.nodeType === 'COLUMN') {
            const qualifiedTable = String(item.properties.table || '');
            const tableName = qualifiedTable.includes('.')
                ? qualifiedTable.slice(qualifiedTable.lastIndexOf('.') + 1)
                : qualifiedTable;
            handleLineageSelect(
                tableName,
                qualifiedTable || tableName,
                item.properties.name || item.displayName,
                item.properties.tableObjectUid,
            );
            return;
        }
        setSelectedQuickNode(item);
    };

    const handleKeywordSearch = () => {
        setSelectedOwnerName(null);
        handleSearch(1, null);
    };

    const handleSearchSubmit = () => {
        if (selectedOwnerName) {
            handleSearch(1, selectedOwnerName);
            return;
        }
        handleKeywordSearch();
    };

    const handleOwnerSelect = (ownerName: string) => {
        setSelectedOwnerName(ownerName);
        handleSearch(1, ownerName);
    };

    const handleOwnerBack = () => {
        setSelectedOwnerName(null);
        setSelectedOwnerTotal(0);
        setCurrentPage(1);
        setExpandedTables(new Set());
        handleSearch(1, null);
    };

    const downloadLineage = async (tableName: string, columnName?: string, qualifiedName?: string) => {
        if (!canExport) {
            return;
        }
        try {
            message.loading({ content: '正在导出...', key: 'export' });
            const blob = await exportLineage(
                tableName,
                columnName,
                qualifiedName,
                queryDirection,
                columnName ? 'column' : 'table'
            );
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

    const handleExport = (tableName: string, e: React.MouseEvent, columnName?: string, qualifiedName?: string) => {
        e.stopPropagation();
        void downloadLineage(tableName, columnName, qualifiedName);
    };

    const getColumnName = (node: NodeData | undefined, columnId: string) => (
        node?.columns.find(column => column.id === columnId)?.name || (columnId || '-')
    );

    const handleExportVisibleRelations = () => {
        if (!selectedTable) {
            return;
        }

        const sourceNodes = listDetailsLoaded ? listNodes : nodes;
        const sourceLinks = listDetailsLoaded ? listLinks : links;
        const nodeMap = new Map(sourceNodes.map(node => [node.id, node]));
        const rows = displayMode === 'endToEnd'
            ? buildEndToEndRelations(sourceNodes, sourceLinks, selectedTable, selectedField).map(relation => ({
                '源对象': `${relation.source.tableName}.${relation.source.columnName}`,
                '目标对象': `${relation.target.tableName}.${relation.target.columnName}`,
                '关系类型': relation.relationTypeSummary,
                '路径数量': relation.pathCount,
                '层级范围': `${relation.minLevel}-${relation.maxLevel}`,
                '涉及表数': relation.tableCount,
                '涉及字段数': relation.fieldCount,
                'Schema 路径': relation.schemaPath,
            }))
            : (viewMode === 'canvas' ? links : listLinks).map((link: LinkData) => {
                const sourceNode = nodeMap.get(link.sourceNodeId);
                const targetNode = nodeMap.get(link.targetNodeId);
                return {
                    '源表': sourceNode?.title || link.sourceNodeId,
                    '源字段': getColumnName(sourceNode, link.sourceColumnId),
                    '关系类型': RELATION_STYLES[link.type || 'DERIVES_TO']?.label || link.type || '数据流',
                    '目标表': targetNode?.title || link.targetNodeId,
                    '目标字段': getColumnName(targetNode, link.targetColumnId),
                };
            });

        if (rows.length === 0) {
            message.info('当前筛选条件下没有可导出的血缘关系');
            return;
        }

        const workbook = XLSX.utils.book_new();
        const worksheet = XLSX.utils.json_to_sheet(rows);
        XLSX.utils.book_append_sheet(workbook, worksheet, displayMode === 'endToEnd' ? '端到端关系' : '血缘明细');
        XLSX.writeFile(workbook, `${selectedDisplayName || selectedTable}_${displayMode === 'endToEnd' ? '端到端' : '完整'}血缘导出.xlsx`);
        message.success('导出成功');
    };

    const renderSearchControls = () => (
        <div className="lineage-quick-search-section">
            <div className="lineage-quick-filter-row">
                <Input
                    size="large"
                    placeholder="搜索用户、表名、qualifiedName 或字段名"
                    value={searchText}
                    onChange={e => setSearchText(e.target.value)}
                    onPressEnter={handleSearchSubmit}
                    allowClear
                />
                <Button type="primary" size="large" icon={<SearchOutlined />} onClick={handleSearchSubmit} loading={loading}>
                    查询
                </Button>
                <Checkbox.Group
                    value={quickNodeTypes}
                    options={[
                        { label: '表', value: 'TABLE' },
                        { label: '字段', value: 'COLUMN' },
                        { label: 'SQL 任务', value: 'SQL_TASK' },
                        { label: '解析记录', value: 'ANALYSIS' },
                    ]}
                    onChange={values => setQuickNodeTypes(values as LineageSearchNodeType[])}
                />
                {searchText.trim() ? <span className="lineage-quick-result-count">匹配 {quickResultTotal} 个对象</span> : null}
            </div>
        </div>
    );

    const renderSearchPanel = (inDrawer = false) => (
        <div className={`lineage-search-panel ${inDrawer ? 'lineage-search-panel-drawer' : ''}`}>
            {inDrawer ? renderSearchControls() : null}
            <div className={`lineage-catalog-layout ${showQuickResults ? 'lineage-catalog-layout-with-quick-results' : ''}`}>
                <aside className="lineage-owner-rail">
                    <div className="lineage-section-label">用户 / Schema</div>
                    <div className="lineage-owner-list">
                        {sortedOwnerGroups.map((group) => (
                            <button
                                key={group.ownerName}
                                type="button"
                                onClick={() => handleOwnerSelect(group.ownerName)}
                                className={`lineage-owner-item ${selectedOwnerName === group.ownerName ? 'lineage-owner-item-active' : ''}`}
                            >
                                <UserOutlined style={{ color: selectedOwnerName === group.ownerName ? '#1677ff' : '#8c8c8c' }} />
                                <span className="lineage-owner-name">{group.ownerName}</span>
                                <Tag color={selectedOwnerName === group.ownerName ? 'blue' : undefined} style={{ margin: 0 }}>{group.tableCount}</Tag>
                                <RightOutlined style={{ color: '#cbd5e1', fontSize: 12 }} />
                            </button>
                        ))}
                    </div>
                    {searchResults.length === 0 && !loading ? (
                        <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="暂无 Schema" />
                    ) : null}
                </aside>
                <main className="lineage-table-pane">
                    {selectedOwnerName ? (
                        <>
                            <div className="lineage-table-pane-header">
                                <div>
                                    <div className="lineage-pane-eyebrow">当前 Schema</div>
                                    <div className="lineage-pane-title">{selectedOwnerName}</div>
                                    <div className="lineage-pane-subtitle">展开表查看字段，点击表或字段进入画布。</div>
                                </div>
                                <div className="lineage-pane-actions">
                                    <Tag color="blue" style={{ margin: 0 }}>{selectedOwnerTotal} 张表</Tag>
                                    <Button type="text" size="small" icon={<LeftOutlined />} onClick={handleOwnerBack}>
                                        全部 Schema
                                    </Button>
                                </div>
                            </div>
                            {selectedOwnerTables.length > 0 ? (
                                <div className="lineage-table-list">
                                    {selectedOwnerTables.map((item: LineageSearchTableItem) => (
                                        <div key={item.qualifiedName} className="lineage-table-item">
                                            <div className="lineage-table-row">
                                                <button
                                                    type="button"
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        toggleTableExpand(item.qualifiedName);
                                                    }}
                                                    className="lineage-expand-button"
                                                    aria-label={expandedTables.has(item.qualifiedName) ? '收起字段' : '展开字段'}
                                                >
                                                    {expandedTables.has(item.qualifiedName)
                                                        ? <DownOutlined style={{ fontSize: 10, color: '#666' }} />
                                                        : <RightOutlined style={{ fontSize: 10, color: '#666' }} />}
                                                </button>
                                                <button
                                                    type="button"
                                                    onClick={() => handleLineageSelect(item.tableName, item.qualifiedName, undefined, item.objectUid)}
                                                    className="lineage-table-main"
                                                >
                                                    <span className="lineage-table-icon"><TableOutlined /></span>
                                                    <span className="lineage-table-text">
                                                        <span className="lineage-table-name">{item.tableName}</span>
                                                        <span className="lineage-table-qualified">{item.qualifiedName}</span>
                                                    </span>
                                                </button>
                                                <Button type="primary" size="small" onClick={() => handleLineageSelect(item.tableName, item.qualifiedName, undefined, item.objectUid)}>
                                                    打开画布
                                                </Button>
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
                                                <div className="lineage-column-list">
                                                    {item.columns.map((col: string) => (
                                                        <Tag
                                                            key={`${item.qualifiedName}.${col}`}
                                                            onClick={(e) => {
                                                                e.stopPropagation();
                                                                handleLineageSelect(item.tableName, item.qualifiedName, col, item.objectUid);
                                                            }}
                                                            className="lineage-column-tag group hover:text-blue-500 hover:border-blue-500"
                                                            style={searchText && col.toLowerCase().includes(searchText.toLowerCase()) ? {
                                                                backgroundColor: '#e6f7ff',
                                                                borderColor: '#1890ff'
                                                            } : undefined}
                                                        >
                                                            <span className="lineage-column-name">{col}</span>
                                                            {canExport ? (
                                                                <Tooltip title="导出字段血缘">
                                                                    <DownloadOutlined
                                                                        className="opacity-0 group-hover:opacity-100 transition-opacity"
                                                                        style={{ fontSize: 10, color: '#666' }}
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
                            ) : (
                                <div className="lineage-pane-empty">
                                    <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="该 Schema 暂无匹配表" />
                                </div>
                            )}
                        </>
                    ) : (
                        <div className="lineage-pane-empty lineage-pane-empty-large">
                            <TableOutlined style={{ fontSize: 34, color: '#1677ff' }} />
                            <div className="lineage-pane-empty-title">选择左侧 Schema 查看表和字段</div>
                            <div className="lineage-pane-empty-desc">字段很多时先展开目标表，再点击字段进入字段级血缘画布。</div>
                        </div>
                    )}
                </main>
                {showQuickResults ? (
                    <aside className="lineage-quick-result-pane">
                        <div className="lineage-quick-result-pane-header">
                            <div>
                                <div className="lineage-pane-eyebrow">快速定位</div>
                                <div className="lineage-quick-result-pane-title">匹配对象</div>
                            </div>
                            <Tag color="blue" style={{ margin: 0 }}>{quickResultTotal} 个</Tag>
                        </div>
                        <div className="lineage-quick-result-pane-hint">点击对象进入画布或查看解析详情</div>
                        <div className="lineage-quick-result-list">
                            {quickResults.map(item => (
                                <button
                                    key={item.id}
                                    type="button"
                                    className="lineage-quick-result-item"
                                    title={item.displayName}
                                    onClick={() => handleQuickNodeSelect(item)}
                                >
                                    <Tag color={item.nodeType === 'ANALYSIS' && item.properties.status !== 'EXACT' ? 'gold' : 'blue'}>
                                        {item.nodeType}
                                    </Tag>
                                    <span className="lineage-quick-result-item-label">{item.displayName}</span>
                                    <RightOutlined className="lineage-quick-result-item-arrow" />
                                </button>
                            ))}
                        </div>
                    </aside>
                ) : null}
            </div>
            <div className="lineage-search-footer">
                <div style={{ color: '#64748b', fontSize: 12 }}>
                    {selectedOwnerName
                        ? `${selectedOwnerName}：${selectedOwnerTotal} 张表，${selectedOwnerGroup?.columnCount || 0} 个字段`
                        : sortedOwnerGroups.length === 1
                            ? `${sortedOwnerGroups[0].ownerName}：${sortedOwnerGroups[0].tableCount} 张表，${sortedOwnerGroups[0].columnCount || 0} 个字段`
                            : `共 ${totalOwners} 个用户/Schema，${total} 张表，${totalColumnCount} 个字段`}
                </div>
                {selectedOwnerName ? (
                    <Pagination
                        simple
                        size="small"
                        current={currentPage}
                        pageSize={pageSize}
                        total={selectedOwnerTotal}
                        onChange={(page) => handleSearch(page, selectedOwnerName)}
                    />
                ) : null}
            </div>
        </div>
    );

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
            <div className="lineage-page-toolbar" style={{ padding: '12px 16px', borderBottom: '1px solid #f0f0f0', background: '#fff' }}>
                <div className="lineage-page-toolbar-brand" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <div>
                            <div style={{ fontSize: 14, fontWeight: 600, color: '#1f2937' }}>SQL Lineage</div>
                            <div style={{ fontSize: 12, color: '#8c8c8c' }}>血缘模块</div>
                        </div>
                    {selectedDisplayName && <Tag color="blue">{selectedDisplayName}</Tag>}
                    {workspaceMode === 'canvas' ? (
                        <div className="lineage-canvas-toolbar-actions">
                            <Button
                                icon={<LeftOutlined />}
                                onClick={handleBackFromCanvas}
                            >
                                返回列表
                            </Button>
                            <Button
                                type="primary"
                                icon={<SearchOutlined />}
                                onClick={() => setSearchDrawerOpen(true)}
                                className="lineage-canvas-search-button"
                            >
                                切换表/字段
                            </Button>
                            <Tooltip title={
                                !selectedTable
                                    ? '请先选择表或字段'
                                    : exportDataLoading
                                        ? '正在加载当前筛选数据'
                                        : '导出当前筛选后的血缘关系 Excel'
                            }>
                                <Button
                                    icon={<DownloadOutlined />}
                                    disabled={!selectedTable || exportDataLoading}
                                    onClick={handleExportVisibleRelations}
                                >
                                    导出 Excel
                                </Button>
                            </Tooltip>
                        </div>
                    ) : null}
                </div>
                {workspaceMode === 'catalog' ? renderSearchControls() : null}
                <LineagePageActionBar
                    viewMode={viewMode}
                    displayMode={displayMode}
                    directionOptions={directionOptions}
                    controller={engineController}
                    canOpenAuditBoard={canOpenAuditBoard}
                    onViewModeChange={setViewMode}
                    onDisplayModeChange={setDisplayMode}
                    onDirectionChange={handleDirectionChange}
                    onOpenAuditBoard={() => setShowAuditBoard(true)}
                />
            </div>
            <Layout style={{ flex: 1, minHeight: 0, background: '#f8fafc' }}>
                {workspaceMode === 'catalog' ? (
                    <Content className="lineage-entry-content">
                        <div className="lineage-entry-shell">
                            {renderSearchPanel(false)}
                        </div>
                    </Content>
                ) : (
                    <Content
                        ref={canvasRef}
                        className={`lineage-canvas-content ${canvasMaximized ? 'lineage-canvas-content-maximized' : ''}`}
                    >
                        {canvasMaximized ? (
                            <Button
                                className="lineage-canvas-exit-fullscreen"
                                icon={<FullscreenExitOutlined />}
                                onClick={handleCanvasMaximize}
                            >
                                退出最大化
                            </Button>
                        ) : null}
                        <LineageGraphContent
                            graphLoading={graphLoading}
                            nodes={nodes}
                            links={links}
                            listLoading={listLoading}
                            listNodes={listNodes}
                            listLinks={listLinks}
                            listDetailsLoaded={listDetailsLoaded}
                            viewMode={viewMode}
                            displayMode={displayMode}
                            selectedTable={selectedTable}
                            selectedField={selectedField}
                            onLoadFieldDetails={loadListDetails}
                            onTableDoubleClick={handleGraphTableDoubleClick}
                            onFieldDoubleClick={handleGraphFieldDoubleClick}
                        />
                    </Content>
                )}
                <Drawer
                    title="血缘列表"
                    open={searchDrawerOpen}
                    onClose={() => setSearchDrawerOpen(false)}
                    placement="left"
                    width={560}
                    destroyOnHidden
                    styles={{ body: { padding: 0, background: '#fff' } }}
                >
                    {renderSearchPanel(true)}
                </Drawer>
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
                <Drawer
                    title={selectedQuickNode?.nodeType === 'ANALYSIS' ? '解析结果详情' : 'SQL 任务详情'}
                    open={!!selectedQuickNode}
                    onClose={() => setSelectedQuickNode(null)}
                    width={620}
                    destroyOnHidden
                >
                    {selectedQuickNode ? (
                        <div style={{ display: 'grid', gap: 16 }}>
                            <div>
                                <div style={{ color: '#64748b', fontSize: 12 }}>对象</div>
                                <div style={{ marginTop: 4, fontSize: 16, fontWeight: 600, wordBreak: 'break-all' }}>
                                    {selectedQuickNode.displayName}
                                </div>
                            </div>
                            <Space wrap>
                                <Tag color="blue">{selectedQuickNode.nodeType}</Tag>
                                <Tag color={selectedQuickNode.properties.status === 'EXACT' || selectedQuickNode.properties.parseStatus === 'EXACT' ? 'green' : 'gold'}>
                                    {selectedQuickNode.properties.status || selectedQuickNode.properties.parseStatus || '状态未知'}
                                </Tag>
                                <Tag>置信度 {selectedQuickNode.properties.confidence || selectedQuickNode.properties.parseConfidence || '未知'}</Tag>
                            </Space>
                            {selectedQuickNode.properties.sqlText ? (
                                <div>
                                    <div style={{ marginBottom: 6, color: '#64748b', fontSize: 12 }}>原始 SQL</div>
                                    <pre style={{ margin: 0, maxHeight: 360, overflow: 'auto', padding: 12, borderRadius: 8, background: '#0f172a', color: '#e2e8f0', whiteSpace: 'pre-wrap' }}>
                                        {selectedQuickNode.properties.sqlText}
                                    </pre>
                                </div>
                            ) : null}
                            {selectedQuickNode.properties.diagnosticsJson ? (
                                <div>
                                    <div style={{ marginBottom: 6, color: '#64748b', fontSize: 12 }}>失败或不完整说明</div>
                                    <pre style={{ margin: 0, maxHeight: 300, overflow: 'auto', padding: 12, borderRadius: 8, background: '#fff7e6', color: '#92400e', whiteSpace: 'pre-wrap' }}>
                                        {selectedQuickNode.properties.diagnosticsJson}
                                    </pre>
                                </div>
                            ) : null}
                        </div>
                    ) : null}
                </Drawer>
            </Layout>
        </div>
    );
};

export default LineagePage;
